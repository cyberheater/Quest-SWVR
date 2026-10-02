"""Generate disasm/shapes_preview.html: one self-contained page showing

  1. the character set (the VGMSGA table of the vector ROM)
  2. every picture in the vector ROM $3000-$3FFF
  3. every picture in the pseudo vector ROM - the display lists the program
     copies from FAKEVG in the program ROM down to vector RAM $2800 (DOWNVG)
  4. the 3-D objects of WSOBJ (bank 1): point tables and line lists, as
     wireframes that can be turned
  5. the messages of TCMES with their position and colour

Names, addresses and data come from the byte-exact assembly (macasm69) and the
ROM images; nothing is drawn that is not in the ROM.  The renderer (avg.py)
follows JSRL/JMPL, applies SCAL and tracks the STAT colour.
"""
import html, json, os, re, sys
HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
import avg, image, macasm69
from emit import clean, callsite, words
from macsrc import split_args

OUT = os.path.join(HERE, "shapes_preview.html")
E = html.escape
RGB = ["#555", "#4a7dff", "#3fd45a", "#35d6d6", "#ff4b3e", "#d65cff", "#ffe03a", "#f4f4f4"]

def svg(segs, size=150, pad=6):
    if not segs:
        return '<svg viewBox="0 0 10 10" width="%d" height="%d"></svg>' % (size, size)
    xs = [v for s in segs for v in (s[0], s[2])]
    ys = [v for s in segs for v in (s[1], s[3])]
    x0, x1, y0, y1 = min(xs), max(xs), min(ys), max(ys)
    w, h = max(x1 - x0, 1e-6), max(y1 - y0, 1e-6)
    sc = (size - 2 * pad) / max(w, h)
    ox = pad + ((size - 2 * pad) - w * sc) / 2
    oy = pad + ((size - 2 * pad) - h * sc) / 2
    out = ['<svg viewBox="0 0 %d %d" width="%d" height="%d">' % (size, size, size, size)]
    for a, b, c, d, col, br in segs:
        out.append('<line x1="%.1f" y1="%.1f" x2="%.1f" y2="%.1f" stroke="%s" stroke-opacity="%.2f"/>' % (
            ox + (a - x0) * sc, oy + (y1 - b) * sc, ox + (c - x0) * sc, oy + (y1 - d) * sc,
            RGB[col], 0.35 + 0.65 * br / 255.0))
    out.append("</svg>")
    return "".join(out)

def card(title, sub, body, note=""):
    return ('<div class="card">%s<div class="nm">%s</div><div class="sub">%s</div>%s</div>' % (
        body, E(title), E(sub), ('<div class="note">%s</div>' % E(note)) if note else ""))

def emit(verbose=True):
    g = macasm69.assemble("main")
    symbols = g["symbols"]
    rom = image.load("starwars_main_rev2.bin")
    bank1 = image.load("starwars_bank1.bin")
    root = {m.name: m for m in g["out"]["root"]}
    ovl = {m.name: m for m in g["out"]["overlay"]}
    vrom = root["WSVROM"]
    fake, zfake = vrom.cur["FAKEVG"], vrom.cur["ZFAKEV"]
    psrom = vrom.cur["VGPSRO"]
    mem = bytearray(0x4000)
    mem[0x3000:0x4000] = rom[0x3000:0x4000]
    mem[psrom:psrom + (zfake - fake)] = rom[fake:zfake]

    # ---- picture names: labels in the real ROM, PSLABL / VJ names for both ROMs
    at = {}
    def add(a, nm):
        if psrom <= a < 0x4000 and nm not in at.setdefault(a, []):
            at[a].append(nm)
    for s in symbols:
        if s["image"] != "root" or s["file"] != "WSVROM.MAC":
            continue
        v = s["addr"]
        nm = s.get("source_name", s["name"])
        if s["kind"] == "data" and 0x3000 <= v < 0x4000:
            add(v, nm)
        elif nm.startswith("VJ") and (v & 0xE000) == 0xA000:
            add((v & 0x1FFF) * 2, nm[2:] + " (JSRL VJ%s)" % nm[2:])
        elif s["kind"] in ("equate", "ram") and psrom <= v < 0x3000 and s.get("from_macro"):
            add(v, nm)
    # ---- 1. character set
    tab = vrom.cur["VGMSGA"]
    chars = []
    a = tab
    while True:
        d = avg.decode(mem, a)
        if d["op"] != "JSRL":
            break
        nm = (at.get(d["target"]) or ["$%04X" % d["target"]])[0]
        segs, _ = avg.render(mem, d["target"])
        chars.append(card(nm, "$%04X  code %d" % (d["target"], (a - tab) // 2), svg(segs, 70, 8)))
        a += 2
    # ---- 2/3. pictures
    skip = {tab}
    real, pseudo = [], []
    for a in sorted(at):
        if a in skip or a == 0x3000:
            continue
        segs, notes = avg.render(mem, a)
        if not segs:
            continue
        c = card(" / ".join(at[a][:3]), "$%04X  %d vectors" % (a, len(segs)), svg(segs),
                 "; ".join(sorted(set(notes)))[:120])
        (real if a >= 0x3000 else pseudo).append(c)

    # ---- 4. 3-D objects
    wo = ovl["WSOBJ"]
    objs = []
    for k, n in sorted(wo.cur.items(), key=lambda kv: kv[1]):
        if not k.startswith("TD$") or k in ("TD$EQ",):
            continue
        pc, nm, ln = wo.cur.get("TD%dPC" % n), wo.cur.get("TD%dNM" % n), wo.cur.get("TD%dLN" % n)
        if pc is None or nm is None:
            continue
        b = lambda x: bank1[x - 0x6000]
        w16 = lambda x: avg.sx((b(x) << 8) | b(x + 1), 16)
        pts = [[w16(pc + 6 * i), w16(pc + 6 * i + 2), w16(pc + 6 * i + 4)] for i in range(nm)]
        lines, kind = [], "no line list"
        if ln is not None:
            if b(ln) == 0:
                kind = "line list at $%04X" % ln
                p, cur = ln + 1, None
                while b(p) != 0xFF and p < ln + 400:
                    v = b(p)
                    p += 1
                    if v & 3 == 2:
                        continue                       # damage level marker
                    i = v >> 2
                    if v & 3 == 0 and cur is not None and i < nm and cur < nm:
                        lines.append([cur, i])
                    cur = i
            else:
                kind = "ground object: drawn by code at $%04X" % ln
        objs.append(dict(name=k[3:], n=n, pc=pc, pts=pts, lines=lines, kind=kind))
    objcards = []
    for o in objs:
        objcards.append('<div class="card obj"><canvas width="220" height="220" data-o="%d"></canvas>'
                        '<div class="nm">%s</div><div class="sub">object %d, %d points at $%04X (bank 1)'
                        '</div><div class="note">%s</div></div>' % (
                            o["n"], E(o["name"]), o["n"], len(o["pts"]), o["pc"], E(o["kind"])))
    objdata = {o["n"]: dict(p=o["pts"], l=o["lines"]) for o in objs}

    # ---- 5. messages
    tm = root["TCMES"]
    ev_at = {e["addr"]: e for e in tm.events if e["text"].upper().startswith(".ASCIN")}
    rows = []
    for k, a in sorted(((k, v) for k, v in tm.cur.items() if re.match(r"^MES\d+$", k)),
                       key=lambda kv: int(kv[0][3:])):
        e = ev_at.get(a)
        if not e:
            continue
        txt = "".join(chr(rom[a + i] & 0x7F) for i in range(e["len"]))
        call, com = callsite(*e["origin"])
        m = re.match(r"^\.(\w+)\s+(.*)$", call)
        args = split_args(m.group(2)) if m else []
        kindm = m.group(1).upper() if m else ""
        if kindm == "MESS" and len(args) >= 4:
            x, y, col, name = args[0], args[1], args[2], (args[4] if len(args) > 4 else "")
        elif kindm.startswith("NEXTM") and len(args) >= 3:
            x, y, col, name = args[0], args[1], args[2], (args[3] if len(args) > 3 else "")
        else:
            x = y = col = ""
            name = args[1] if len(args) > 1 else ""
        rows.append("<tr><td>%d</td><td>$%04X</td><td>%s</td><td>%s</td><td>%s</td><td>%s</td>"
                    "<td class=t>%s</td></tr>" % (int(k[3:]), a, E("MS." + name if name else ""),
                                                  E(x), E(y), E(col), E(txt)))

    page = TEMPLATE % dict(
        nchar=len(chars), chars="".join(chars), nreal=len(real), real="".join(real),
        npseudo=len(pseudo), pseudo="".join(pseudo), fake="$%04X-$%04X" % (fake, zfake - 1),
        nobj=len(objs), objs="".join(objcards), objdata=json.dumps(objdata, separators=(",", ":")),
        nmsg=len(rows), msgs="".join(rows))
    with open(OUT, "w", newline="\n", encoding="utf-8") as fp:
        fp.write(page)
    if verbose:
        print("wrote shapes_preview.html: %d characters, %d vector ROM pictures, %d pseudo ROM pictures, "
              "%d objects, %d messages" % (len(chars), len(real), len(pseudo), len(objs), len(rows)))

TEMPLATE = """<!doctype html>
<html lang="en"><head><meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>Star Wars (Atari, 1983) - vector shapes</title>
<style>
:root{color-scheme:dark}
body{background:#0b0d12;color:#cfd6e4;font:14px/1.45 system-ui,Segoe UI,sans-serif;margin:0;padding:16px}
h1{font-size:20px;margin:0 0 4px}h2{font-size:16px;margin:28px 0 4px;color:#fff}
p{max-width:900px;margin:4px 0 12px;color:#9aa5b8}
.grid{display:flex;flex-wrap:wrap;gap:8px}
.card{background:#12151d;border:1px solid #232838;border-radius:6px;padding:6px;width:150px}
.card.obj{width:220px}.chars .card{width:70px}
.card svg,.card canvas{display:block;background:#000;border-radius:4px}
.card line{stroke-width:1.2;stroke-linecap:round}
.nm{font:12px/1.3 ui-monospace,Consolas,monospace;color:#fff;margin-top:4px;word-break:break-all}
.sub,.note{font-size:11px;color:#7f8aa0}.note{color:#b08a4a}
table{border-collapse:collapse;font:12px ui-monospace,Consolas,monospace}
td,th{border-bottom:1px solid #232838;padding:2px 8px;text-align:left;white-space:nowrap}
td.t{white-space:normal;color:#fff}
.wrap{overflow-x:auto}
</style></head><body>
<h1>Star Wars (Atari, 1983) &mdash; vector shapes</h1>
<p>Generated from the ROM by <code>disasm/emit_shapes.py</code>. Names are Atari's, from the
re-assembled source. Colours are the AVG's eight: the STAT instruction carries red, green and
blue bits and a brightness.</p>

<h2>Character set &mdash; %(nchar)d characters (VGMSGA)</h2>
<div class="grid chars">%(chars)s</div>

<h2>Vector ROM pictures &mdash; %(nreal)d ($3000-$3FFF)</h2>
<p>Each labelled display list run as a subroutine, from the default scale. A call into vector
RAM (the program's own colour and position variables) is skipped and noted.</p>
<div class="grid">%(real)s</div>

<h2>Pseudo vector ROM pictures &mdash; %(npseudo)d</h2>
<p>Display lists stored in the program ROM at %(fake)s (FAKEVG) and copied down to vector RAM
$2800 by DOWNVG, where the vector generator runs them like ROM.</p>
<div class="grid">%(pseudo)s</div>

<h2>3-D objects &mdash; %(nobj)d (WSOBJ, bank 1)</h2>
<p>Point tables (x, y, z words) and line lists: a byte is point&times;4, plus 1 for a move with
the beam off, plus 2 for a damage-level marker; $FF ends the list. Drag to turn an object.
Ground objects are drawn by code instead of a line list, so only their points are shown.</p>
<div class="grid">%(objs)s</div>

<h2>Messages &mdash; %(nmsg)d (TCMES)</h2>
<div class="wrap"><table><tr><th>#</th><th>address</th><th>name</th><th>x</th><th>y</th>
<th>colour</th><th>text</th></tr>%(msgs)s</table></div>

<script>
const OBJ=%(objdata)s;
document.querySelectorAll('canvas[data-o]').forEach(cv=>{
  const o=OBJ[cv.dataset.o],g=cv.getContext('2d');let ax=-1.1,az=0.6,drag=null;
  let r=1;for(const p of o.p)r=Math.max(r,Math.hypot(p[0],p[1],p[2]));
  function pr(p){const x=p[0],y=p[1],z=p[2];
    const x1=x*Math.cos(az)-y*Math.sin(az),y1=x*Math.sin(az)+y*Math.cos(az);
    const y2=y1*Math.cos(ax)-z*Math.sin(ax);const z2=y1*Math.sin(ax)+z*Math.cos(ax);
    const s=100/r;return[110+x1*s,110-z2*s]}
  function draw(){g.clearRect(0,0,220,220);g.strokeStyle='#3fd45a';g.lineWidth=1.1;g.beginPath();
    for(const l of o.l){const a=pr(o.p[l[0]]),b=pr(o.p[l[1]]);g.moveTo(a[0],a[1]);g.lineTo(b[0],b[1])}
    g.stroke();if(!o.l.length){g.fillStyle='#ffe03a';for(const p of o.p){const a=pr(p);g.fillRect(a[0]-1,a[1]-1,2,2)}}}
  cv.onpointerdown=e=>{drag=[e.clientX,e.clientY];cv.setPointerCapture(e.pointerId)};
  cv.onpointerup=()=>drag=null;
  cv.onpointermove=e=>{if(!drag)return;az+=(e.clientX-drag[0])*0.01;ax+=(e.clientY-drag[1])*0.01;
    drag=[e.clientX,e.clientY];draw()};
  draw()});
</script>
</body></html>
"""

if __name__ == "__main__":
    emit()
