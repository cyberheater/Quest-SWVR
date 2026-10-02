"""Emit the annotated listings of the Star Wars CPU ROMs.

    starwars_program_rom.asm   main CPU $6000-$FFFF, bank 0 at $6000   (root link image)
    starwars_overlay_rom.asm   main CPU $6000-$7FFF, bank 1            (overlay link image)
    starwars_vector_rom.asm    vector ROM $3000-$3FFF                  (root link image)
    starwars_sound_rom.asm     sound CPU $4000-$7FFF                   (sound link image)

Format follows the Tempest / Space Duel listings: every code/data line carries an
address label, named labels sit on their own line, `.byte`/`.word` data, a
comment header before every routine.  6809 changes: Motorola operand syntax,
big-endian `.word`, ( ) for grouping (since [ ] is indirection), `.dpage` lines.

Where everything comes from
  * macasm69.py re-assembles Atari's source byte-exact; each assembler event
    (one instruction / one data directive, macro expansions included) becomes
    one listing unit, so the listing follows the source statement for statement.
  * Operands: the source operand expression translated to listing syntax, with
    the source's own symbol names.  It is used only if it evaluates to exactly
    the operand in the ROM; otherwise the operand is hex and the source text is
    kept in the comment.  Branch targets are always labels.
  * The instruction itself is decoded from the ROM, so the two bytes rev 2
    changes show what the rev-2 ROM holds, with a note of the rev-1 value.
  * Comments: Atari's inline comments verbatim, the macro call for expanded
    statements, Atari's comment blocks.
  * Routine headers: .SBTTL / label comment / comment block above the label /
    comment at the call; else routine_docs.DOCS, tagged [note].

Run:  python emit.py [program|overlay|vector|sound ...]
Also writes build/refs_<listing>.json (identifiers used) for emit_defines.py.
"""
import os, sys, re, json, collections
HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
import m6809, macasm69, image, paths
from m6809 import INH, IMM8, IMM16, DIR, IDX, EXT, REL8, REL16, REGS, STK
from macsrc import split_comment, parse_stmt, split_args, read_source
from rtexpr import sym6, parse_number

LISTINGS = {
    "program": dict(group="main", image="root", lo=0x6000, hi=0x10000, prefix="L",
                    out="starwars_program_rom.asm", rom="starwars_main_rev2.bin", romoff=0,
                    defines="starwars_defines.asm"),
    "overlay": dict(group="main", image="overlay", lo=0x6000, hi=0x8000, prefix="K",
                    out="starwars_overlay_rom.asm", rom="starwars_bank1.bin", romoff=0x6000,
                    defines="starwars_defines.asm"),
    "vector": dict(group="main", image="root", lo=0x3000, hi=0x4000, prefix="L",
                   out="starwars_vector_rom.asm", rom="starwars_main_rev2.bin", romoff=0,
                   defines="starwars_defines.asm"),
    "sound": dict(group="sound", image="sound", lo=0x4000, hi=0x8000, prefix="L",
                  out="starwars_sound_rom.asm", rom="starwars_sound.bin", romoff=0,
                  defines="starwars_sound_defines.asm"),
}

HEADERS = {
    "program": [
        ";Star Wars (Atari, 1983) - annotated disassembly of the main program ROM,",
        ";$6000-$FFFF with bank 0 at $6000-$7FFF.  Revision 2 (MAME 'starwars':",
        ";136021-214.1f, -102.1hj, -203.1jk, -104.1kl, -206.1m).",
        ";Bank 1 of $6000-$7FFF is in starwars_overlay_rom.asm; the vector ROM is in",
        ";starwars_vector_rom.asm.",
    ],
    "overlay": [
        ";Star Wars (Atari, 1983) - annotated disassembly of bank 1 of the main program",
        ";ROM: the second half of 136021-214.1f, mapped at $6000-$7FFF when the bank",
        ";latch selects it (Atari's 'overlay': the object tables and vector draw",
        ";routines, and the star generators).  Address labels here are Kxxxx, so a",
        ";bank-1 address is never mistaken for the bank-0 address Lxxxx of",
        ";starwars_program_rom.asm.",
    ],
    "vector": [
        ";Star Wars (Atari, 1983) - annotated disassembly of the vector ROM $3000-$3FFF",
        ";(136021-105.1l): AVG display-list subroutines - characters, pictures, tests.",
        ";AVG words are big-endian here, as the 6809 stores them:",
        ";  $0yyy $zxxx  VCTR  draw to dx,dy (13-bit signed), intensity z (0-7)",
        ";  $4...        short VCTR: dy in bits 12-8, z in bits 7-5, dx in bits 4-0 (x2)",
        ";  $2000 HALT   $6ccc STAT/COLOR (colour in bits 10-8, brightness in bits 7-0)",
        ";  $7sll SCAL   $8040 CNTR   $Annn JSRL   $C000 RTSL   $Ennn JMPL",
        ";JSRL/JMPL operands are word addresses: (address - VGBASE)/2.",
    ],
    "sound": [
        ";Star Wars (Atari, 1983) - annotated disassembly of the sound program ROM,",
        ";$4000-$7FFF on the sound board's 6809 (136021-107.1jk at $4000, -208.1h at",
        ";$6000).  A15 is not decoded, so the same ROMs appear at $C000-$FFFF, which",
        ";is where the 6809 finds its vectors (see the end of the file).",
    ],
}
COMMON_TEXT = [
    ";Reconstructed by re-assembling Atari's own source (the 22-JUN-83 link of the",
    ";historicalsource 'star-wars' archive) byte-exact with disasm/macasm69.py, so",
    ";names and upper-case comments are Atari's.  Routine header descriptions come",
    ";from the source (.SBTTL / label comment / comment block / comment at the call),",
    ";else were written for this disassembly (tagged [note]).",
    ";Every line below was re-encoded and byte-compared with the ROM (verify.py).",
    ";Syntax: Motorola 6809 mnemonics and operands; .alias, .byte, .word (big-endian);",
    ";( ) groups expressions, which Atari's MAC69 evaluated strictly left to right;",
    ";~ is one's complement, | is OR, ^ is exclusive OR.  .dpage gives the direct page",
    ";the assembler assumed; < and > before an operand force the short and long form.",
]
REV2_NOTE = {
    0x6164: "rev 2 patch: Atari's 22-JUN-83 source and rev 1 have CMPA here ($B1)",
    0x7A7B: "rev 2 patch: the checksum word; rev 1 and the source's PCKS0 are $F79C",
}

# ---------------------------------------------------------------- helpers
def clean(name):
    """Legal assembler identifier: AM.PTR -> AM_PTR, $COINA -> S_COINA."""
    return name.replace("$", "S_").replace(".", "_")

def tidy(s):
    return re.sub(r"\s+", " ", s.replace("\t", " ")).strip()

def words(s):
    """A comment with the rule-off lines (---, ===, <<<<) dropped."""
    s = tidy(s)
    return s if s.strip("-=*<>;. ") else ""

def hexb(v):
    return "$%02X" % (v & 0xFF)

def hexw(v):
    return "$%04X" % (v & 0xFFFF)

def simple(s):
    return bool(re.match(r"^[A-Za-z_][A-Za-z0-9_]*$|^\$[0-9A-F]+$|^\d+$", s))

def paren(s):
    return s if simple(s) else "(" + s + ")"

# ---------------------------------------------------------------- expressions
class Fail(Exception):
    pass

NUM_RE = re.compile(r"^[-+]?\s*(\^[HDOB])?[0-9][0-9A-Fa-f]*\.?$")

def parse_rt(s, radix=16):
    """MAC69 expression -> AST (strict left to right, <> groups)."""
    s = s.strip()
    n = len(s)

    def skip(i):
        while i < n and s[i].isspace():
            i += 1
        return i

    def term(i, rdx):
        i = skip(i)
        if i >= n:
            raise Fail("missing term")
        c = s[i]
        if c == "<":
            node, i = expr(i + 1, rdx)
            i = skip(i)
            if i < n and s[i] == ">":
                i += 1
            return ("grp", node), i
        if c == "-":
            node, i = term(i + 1, rdx)
            return ("neg", node), i
        if c == "+":
            return term(i + 1, rdx)
        if c == "'":
            if i + 1 >= n:
                raise Fail("char")
            return ("chr", ord(s[i + 1].upper())), i + 2
        if c == '"':
            raise Fail("dchar")
        if c == "^":
            k = s[i + 1].upper() if i + 1 < n else ""
            if k == "C":
                node, i = term(i + 2, rdx)
                return ("com", node), i
            base = {"H": 16, "D": 10, "O": 8, "B": 2}.get(k)
            if base is None:
                raise Fail("^")
            j = skip(i + 2)
            if j < n and s[j] == "<":
                return term(j, base)
            k2 = j
            while k2 < n and s[k2].upper() in "0123456789ABCDEF":
                k2 += 1
            return ("num", int(s[j:k2], base), base == 10), k2
        j = i
        while j < n and s[j].upper() in "ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789$._":
            j += 1
        tok = s[i:j]
        if not tok:
            raise Fail("bad char %r" % c)
        up = tok.upper()
        if up[0].isdigit():
            if up.endswith("$"):
                raise Fail("local")
            try:
                return ("num", parse_number(up, rdx), up.endswith(".") or rdx == 10), j
            except ValueError:
                raise Fail("number")
        if up.startswith("."):
            raise Fail("dot/temp")
        return ("sym", up), j

    def expr(i, rdx):
        acc, i = term(i, rdx)
        while True:
            i = skip(i)
            if i >= n or s[i] not in "+-*/&!?":
                return acc, i
            op = s[i]
            b, i = term(i + 1, rdx)
            acc = ("bin", op, acc, b)

    node, i = expr(0, radix)
    if skip(i) != n:
        raise Fail("junk")
    return node

FAMILY = {"+": "add", "-": "add", "*": "mul", "/": "mul", "&": "and", "!": "or", "?": "xor"}
OUTOP = {"+": "+", "-": "-", "*": "*", "/": "/", "&": "&", "!": "|", "?": "^"}

def tdiv(a, b):
    if b == 0:
        raise Fail("div0")
    q = abs(a) // abs(b)
    return q if (a < 0) == (b < 0) else -q

class Renderer:
    def __init__(self, names):
        self.names = names

    def render(self, text, modkey, radix=16):
        """-> (listing text, value as unbounded int, used idents) or raise Fail."""
        node = parse_rt(text, radix)
        used = []
        s, v, _ = self._r(node, modkey, used)
        return s, v, used

    def _r(self, node, modkey, used):
        t = node[0]
        if t == "num":
            v = node[1]
            return (str(v) if node[2] or v < 10 else ("$%X" % v)), v, "atom"
        if t == "chr":
            return "$%02X" % node[1], node[1], "atom"
        if t == "sym":
            ident, v = self.names.resolve(modkey, node[1])
            used.append(ident)
            return ident, v, "atom"
        if t == "grp":
            s, v, k = self._r(node[1], modkey, used)
            if k == "bin":
                return "(" + s + ")", v, "atom"
            return s, v, k
        if t in ("neg", "com"):
            s, v, k = self._r(node[1], modkey, used)
            if k == "bin":
                s = "(" + s + ")"
            return ("-" if t == "neg" else "~") + s, (-v if t == "neg" else ~v), "atom"
        if t == "bin":
            op = node[1]
            ls, lv, lk = self._r(node[2], modkey, used)
            rs, rv, rk = self._r(node[3], modkey, used)
            if lk == "bin" and FAMILY[node[2][1]] != FAMILY[op]:
                ls = "(" + ls + ")"
            if rk == "bin":
                rs = "(" + rs + ")"
            # MAC69 arithmetic is 16-bit; multiply, divide and the logical
            # operators see the wrapped value, so wrap before them
            if op in "*/&!?":
                lv, rv = s16w(lv), s16w(rv)
            if op == "+": v = lv + rv
            elif op == "-": v = lv - rv
            elif op == "*": v = lv * rv
            elif op == "/": v = tdiv(lv, rv)
            elif op == "&": v = lv & rv
            elif op == "!": v = lv | rv
            else: v = lv ^ rv
            return ls + OUTOP[op] + rs, v, "bin"
        raise Fail(t)

def s16w(v):
    """Wrap to the signed 16-bit value MAC69 would be holding."""
    v &= 0xFFFF
    return v - 0x10000 if v & 0x8000 else v

# ---------------------------------------------------------------- names
class Names:
    """Identifier registry for one CPU (main: root + overlay; sound)."""
    def __init__(self, symbols, out):
        self.mods = {}
        for im, mods in (out or {}).items():
            for m in mods:
                self.mods[(im, m.name)] = m
        self.by_key = collections.defaultdict(list)
        for s in symbols:
            if s["kind"] != "local":
                self.by_key[s["name"]].append(s)
        self.ident, self.rec = {}, {}
        used = set()

        def rank(s):
            if s.get("redefined") or s.get("from_macro"):
                r = 6
            elif s["file"][:-4] in ("WSGLOB", "WSCOMN", "SNDCMN", "SNDGLB"):
                r = 0
            elif s["kind"] in ("code", "data"):
                r = 1 if s.get("global") else 2
            elif s["kind"] in ("ram", "io"):
                r = 3
            elif s["kind"] == "equate":
                r = 4 if s.get("global") else 5
            else:
                r = 6
            # the root and the overlay each have a bank-switching vector table with
            # the same names (WSROOT / WSOVLY): the root's keeps the plain name
            return (r, s["image"] == "overlay", s["file"], s["line"])

        for key, recs in sorted(self.by_key.items()):
            recs = sorted(recs, key=rank)
            prim = recs[0]
            for s in recs:
                k = (key, s["addr"])
                if k in self.ident:
                    continue
                nm = clean(s.get("source_name", key))
                if s["addr"] != prim["addr"]:
                    nm += "_%04X" % s["addr"]
                base, i = nm, 2
                while nm in used:
                    nm = "%s_%d" % (base, i)
                    i += 1
                used.add(nm)
                self.ident[k] = nm
                self.rec[nm] = s
        self.used = used

    def resolve(self, modkey, token):
        k = sym6(token)
        m = self.mods[modkey]
        if k in m.cur:
            v = m.cur[k]
        elif k in m.ext:
            v = m.ext[k]
        else:
            raise Fail("undefined %s" % token)
        ident = self.ident.get((k, v))
        if ident is None:
            raise Fail("no ident %s=%04X" % (k, v))
        return ident, v

    def new_unique(self, nm):
        base, i = nm, 2
        while nm in self.used:
            nm = "%s_%d" % (base, i)
            i += 1
        self.used.add(nm)
        return nm

# ---------------------------------------------------------------- source helpers
_src_cache = {}

def src_line(f, n):
    if f not in _src_cache:
        _src_cache[f] = read_source(f)
    L = _src_cache[f]
    return L[n - 1] if 0 < n <= len(L) else ""

_sbttl_cache = {}

def sbttl_at(f, n):
    """.SBTTL text in effect at line n of file f (decorative banners ignored)."""
    if f not in _sbttl_cache:
        cur, arr = "", []
        for raw in read_source(f):
            code, _ = split_comment(raw)
            m = re.match(r"^\s*\.SBTTLE?\s*(.*)$", code, re.I)
            if m:
                t = tidy(m.group(1) + (" ;" + split_comment(raw)[1] if split_comment(raw)[1].strip() else ""))
                t = tidy(t.replace(" ;", " - ", 1)) if " ;" in t else t
                if t and not t.startswith("*"):
                    cur = t
            arr.append(cur)
        _sbttl_cache[f] = arr
    arr = _sbttl_cache[f]
    return arr[n - 1] if 0 < n <= len(arr) else ""

def title_of(f):
    for raw in read_source(f)[:6]:
        m = re.match(r"^\s*\.TITLE\s+(.*)$", raw, re.I)
        if m:
            t = tidy(m.group(1).replace(";", " "))
            t = re.sub(r"^%s\b[\s-]*" % re.escape(f), "", t, flags=re.I)
            return t
    return ""

def callsite(f, n):
    code, comment = split_comment(src_line(f, n))
    mt = re.sub(r"^\s*(?:[A-Za-z0-9$._]+::?\s*)*", "", code)
    return tidy(mt), words(comment)

def label_only_comment(f, n):
    code, comment = split_comment(src_line(f, n))
    if parse_stmt(code).kind == "label":
        return words(comment)
    return ""

# ---------------------------------------------------------------- units
class Unit:
    __slots__ = ("addr", "len", "kind", "items", "module", "origins", "exp", "text",
                 "dpage", "radix")
    def __init__(self, addr, ln, kind, module, origin, exp, text, items=None, dpage=0, radix=16):
        self.addr, self.len, self.kind, self.module = addr, ln, kind, module
        self.origins, self.exp, self.text, self.items = [origin], exp, text, items or []
        self.dpage, self.radix = dpage, radix

def data_items(e):
    """(arg_text, size) list for a .BYTE/.WORD/.VCTRS event, or None."""
    t = e["text"]
    if e["kind"] == "byte":
        m = re.match(r"^\.BYTE\s*(.*)$", t, re.I)
        args = split_args(m.group(1)) if m else None
        if not args or len(args) != e["len"]:
            return None
        return [(a, 1) for a in args]
    m = re.match(r"^\.(WORD|VCTRS)\s*(.*)$", t, re.I)
    if m:
        args = split_args(m.group(2))
        if m.group(1).upper() == "VCTRS":
            args = args[1:]
    else:
        args = split_args(t)
    if not args or 2 * len(args) != e["len"]:
        return None
    return [(a, 2) for a in args]

RSTAT = collections.Counter()
IDX_SRC = macasm69.IDX_RE
STOP_MN = {"RTS", "RTI", "JMP", "BRA", "LBRA", "SWI"}

def build(which, verbose=True, export=None):
    L = LISTINGS[which]
    LO, HI, P = L["lo"], L["hi"], L["prefix"]
    g = macasm69.assemble(L["group"])
    mods = g["out"][L["image"]]
    symbols = g["symbols"]
    names = Names(symbols, g["out"])
    R = Renderer(names)
    rom = image.load(L["rom"])
    off = L["romoff"]
    mem = {a: rom[a - off] for a in range(LO, HI)}

    # ---- events -> units (owner of every byte)
    events, block_comments = [], {}
    for m in mods:
        for e in m.events:
            if LO <= e["addr"] < HI:
                e = dict(e)
                e["module"] = m.name
                events.append(e)
        for a, c in m.block_comments.items():
            if LO <= a < HI:
                block_comments.setdefault(a, c)
    owner = {}
    for i, e in enumerate(events):
        for k in range(e["len"]):
            owner.setdefault(e["addr"] + k, i)
    units = []
    for j in sorted(range(len(events)), key=lambda j: (events[j]["addr"], j)):
        ev = events[j]
        own = [owner.get(ev["addr"] + k) == j for k in range(ev["len"])]
        if not any(own):
            continue                      # HLL69F back-patch of an earlier branch
        if not all(own):
            raise SystemExit("partially overwritten statement at $%04X: %s" % (ev["addr"], ev["text"]))
        if ev["kind"] == "insn":
            units.append(Unit(ev["addr"], ev["len"], "insn", ev["module"], ev["origin"], ev["exp"],
                              ev["text"], dpage=ev["dpage"], radix=ev["radix"]))
        else:
            items = data_items(ev)
            units.append(Unit(ev["addr"], ev["len"], "data", ev["module"], ev["origin"], ev["exp"],
                              ev["text"], items if items is not None else [(None, 1)] * ev["len"],
                              dpage=ev["dpage"], radix=ev["radix"]))
    covered = set(owner)
    for a in range(LO, HI):
        if a not in covered:
            units.append(Unit(a, 1, "hole", None, ("", 0), False, "", [(None, 1)]))
    units.sort(key=lambda u: u.addr)

    # ---- labels by address
    labels = collections.defaultdict(list)
    for s in symbols:
        a = s["addr"]
        if s["image"] != L["image"] or not (LO <= a < HI) or s["kind"] not in ("code", "data", "local"):
            continue
        if s["kind"] == "local":
            nm = names.new_unique(clean(s.get("scope") or P) + "_" + s["name"].rstrip("$"))
        else:
            nm = names.ident.get((s["name"], a))
            if nm is None or names.rec[nm]["image"] != L["image"]:
                continue
        if nm not in [x[0] for x in labels[a]]:
            labels[a].append((nm, s))
    for a in labels:
        labels[a].sort(key=lambda x: (x[1]["kind"] == "local", not x[1].get("global"), x[1]["line"]))

    # ---- merge consecutive byte data from the same source line
    merged = []
    for u in units:
        p = merged[-1] if merged else None
        if (p and u.kind in ("data", "hole") and p.kind == u.kind and p.origins[-1] == u.origins[0]
                and p.addr + p.len == u.addr and u.addr not in labels
                and all(sz == 1 for _, sz in p.items + u.items)):
            p.len += u.len
            p.items = p.items + u.items
            continue
        merged.append(u)
    units = merged

    # ---- code references (split points and routine entries)
    jsr_targets, jmp_targets, word_vals, br_targets = set(), set(), set(), set()
    caller_comments = collections.defaultdict(collections.Counter)
    table_comments = collections.defaultdict(collections.Counter)
    decoded = {}
    for u in units:
        if u.kind == "insn":
            d = m6809.decode(mem, u.addr)
            if d is None or d["len"] != u.len:
                raise SystemExit("cannot decode source instruction at $%04X: %s" % (u.addr, u.text))
            decoded[u.addr] = d
            if d["mode"] in (REL8, REL16):
                (jsr_targets if d["mn"] in ("BSR", "LBSR") else br_targets).add(d["value"])
            elif d["mn"] == "JSR" and d["mode"] == EXT:
                jsr_targets.add(d["value"])
            elif d["mn"] == "JMP" and d["mode"] == EXT:
                jmp_targets.add(d["value"])
            if d["mn"] in ("JSR", "JMP", "BSR", "LBSR") and d["mode"] != IDX and not u.exp:
                c = callsite(*u.origins[0])[1]
                if c:
                    caller_comments[d["value"]][c] += 1
        elif u.kind == "data":
            k = u.addr
            c = callsite(*u.origins[0])[1] if u.origins[0][0] else ""
            for _, sz in u.items:
                if sz == 2:
                    w = (mem[k] << 8) | mem[k + 1]
                    word_vals.add(w)
                    if c:
                        table_comments[w][c] += 1
                k += sz
    splits = set(labels) | br_targets | jsr_targets | jmp_targets

    # ---- split data units into lines (8 bytes / 4 words, at split points)
    lines = []
    for u in units:
        if u.kind == "insn":
            lines.append(u)
            continue
        cur, a = None, u.addr
        for it in u.items:
            sz = it[1]
            if cur is None or a in splits or len(cur.items) >= (8 if sz == 1 else 4) or cur.items[0][1] != sz:
                cur = Unit(a, 0, u.kind, u.module, u.origins[0], u.exp, u.text, dpage=u.dpage, radix=u.radix)
                cur.items = []
                lines.append(cur)
            cur.items.append(it)
            cur.len += sz
            a += sz
    starts = {u.addr: u for u in lines}

    def label_for(addr):
        if addr in labels and addr in starts:
            return labels[addr][0][0]
        if addr in starts:
            return "%s%04X" % (P, addr)
        return None

    refs = set()

    # ---- routine entries
    entries = set()
    prev = None
    for u in lines:
        if u.kind == "insn" and u.addr in labels and any(r["kind"] == "code" for _, r in labels[u.addr]):
            pd = decoded.get(prev.addr) if prev is not None and prev.kind == "insn" else None
            stop = pd and (pd["mn"] in STOP_MN or (pd["mn"] in ("PULS", "PULU") and pd["value"] & 0x80))
            if (u.addr in jsr_targets or u.addr in word_vals or prev is None or prev.kind != "insn"
                    or stop or u.module != prev.module):
                entries.add(u.addr)
        prev = u

    import routine_docs
    DOCS = routine_docs.DOCS.get(which, {})

    if export is not None:
        # the analysis, for a tool that wants it without the listing (c_src/tools/xlate.py)
        export.update(lines=lines, labels=labels, decoded=decoded, starts=starts, entries=entries,
                      jsr_targets=jsr_targets, jmp_targets=jmp_targets, br_targets=br_targets,
                      word_vals=word_vals, block_comments=block_comments, names=names, R=R,
                      mem=mem, L=L, docs=DOCS, caller_comments=caller_comments,
                      table_comments=table_comments, symbols=symbols)
        return None

    # ---- render
    out = []
    W = out.append
    for x in HEADERS[which] + COMMON_TEXT:
        W(x)
    W("")
    W(".org $%04X" % LO)
    W("")
    W('.include "%s"' % L["defines"])
    W("")
    stats = collections.Counter()
    desc_src = collections.Counter()
    desc_list = {}
    seen_mod = set()
    last_mod = last_origin = last_sbttl = None
    last_dpage = None
    header_used_block = set()
    aliases_after = collections.defaultdict(list)
    for a, labs in labels.items():
        if a not in starts:
            host = max(x for x in starts if x < a)
            for nm, r in labs:
                aliases_after[host].append((nm, a))
    for a in list(labels):
        if a not in starts:
            del labels[a]

    def comment_join(parts):
        return "  ".join(p for p in parts if p)

    def emit_line(prefix, comment):
        if comment:
            W("%-35s ;%s" % (prefix, comment) if len(prefix) < 35 else "%s ;%s" % (prefix, comment))
        else:
            W(prefix.rstrip())

    for u in lines:
        a = u.addr
        mod = u.module or last_mod
        if mod != last_mod:
            W("")
            W(";" + "=" * 78)
            cont = " (continued)" if mod in seen_mod else ""
            W("; MODULE %s%s   %s.MAC" % (mod, cont, mod))
            for ln in wrap(title_of(mod), 74):
                W(";   " + ln)
            W(";" + "=" * 78)
            seen_mod.add(mod)
            last_mod = mod
        f, n = u.origins[0]
        sb = sbttl_at(f, n) if f else last_sbttl
        sb_changed = sb and sb != last_sbttl
        last_sbttl = sb
        is_entry = a in entries
        labs = labels.get(a, [])
        if is_entry:
            name = labs[0][0]
            src = []
            if sb_changed:
                src.append(sb)
            for nm, r in labs:
                c = label_only_comment(r["file"][:-4], r["line"])
                if c and c not in src:
                    src.append(c)
            blk = [words(x) for x in block_comments.get(a, []) if words(x)]
            if blk:
                header_used_block.add(a)
            # a note written for a routine outranks a comment borrowed from its
            # callers, which says why they call it and not what it does
            if not src and not blk and name not in DOCS and caller_comments.get(a):
                cc = [c for c, _ in caller_comments[a].most_common(3)]
                src = ["%s  (comment at the call%s)" % (cc[0], "s" if caller_comments[a][cc[0]] > 1 else "")]
                src += ["%s  (another call)" % c for c in cc[1:]]
                desc_src["source: call-site comment"] += 1
            if not src and not blk and name not in DOCS and table_comments.get(a):
                c = table_comments[a].most_common(1)[0][0]
                src = ["%s  (comment at its table entry)" % c]
                desc_src["source: call-site comment"] += 1
            if src or blk:
                kind = "source"
                first = (src or blk)[0]
                rest = (src[1:] + blk) if src else blk[1:]
            elif name in DOCS:
                kind = "written"
                d = DOCS[name].split("\n")
                first, rest = "[note] " + d[0], d[1:]
            else:
                kind = "none"
                first, rest = "", []
            desc_src[kind] += 1
            desc_list[name] = (a, kind, u.module)
            W("")
            W(";" + "-" * 78)
            W("; %s%s" % (name, (" - " + first) if first else ""))
            for x in rest:
                W(";   " + x)
            aka = [nm for nm, _ in labs[1:]]
            if aka:
                W(";   (also: %s)" % ", ".join(aka))
            W(";" + "-" * 78)
            for nm, r in labs:
                W("%s:" % nm)
        else:
            if sb_changed and u.kind != "hole":
                W("")
                W(";.SBTTL " + sb)
            if labs:
                W("")
                for nm, r in labs:
                    c = label_only_comment(r["file"][:-4], r["line"])
                    W("%s:%s" % (nm, (" " * max(1, 16 - len(nm)) + ";" + c) if c else ""))
        if a in block_comments and a not in header_used_block:
            for x in block_comments[a]:
                if words(x):
                    W(";" + words(x))

        parts = []
        new_origin = u.origins[0] != last_origin
        if f and new_origin:
            cst, ccm = callsite(f, n)
            if u.exp or (u.kind == "data" and u.items[0][0] is None):
                parts.append(cst)
            parts.append(ccm)
        last_origin = u.origins[0]
        note = " ".join(REV2_NOTE[x] for x in range(a, a + max(1, u.len))
                        if which == "program" and x in REV2_NOTE)

        if u.kind == "insn":
            if u.dpage != last_dpage:
                W(".dpage $%02X" % u.dpage)
                last_dpage = u.dpage
            txt, extra = render_insn(u, decoded[a], R, (L["image"], u.module), label_for, refs,
                                     note != "")
            stats["insn"] += 1
            emit_line("%s%04X:  %s" % (P, a, txt), comment_join([extra] + parts + [note]))
        else:
            items, extra = render_data(u, mem, R, (L["image"], u.module), refs, label_for)
            stats["data_bytes"] += u.len
            d = ".byte" if u.items[0][1] == 1 else ".word"
            if u.kind == "hole":
                parts = ["not assembled by any source statement (ROM fill)"]
            emit_line("%s%04X:  %s %s" % (P, a, d, ", ".join(items)), comment_join(parts + [extra, note]))
        for nm, la in aliases_after.get(a, []):
            W(".alias %-16s $%04X    ;inside the line at %s%04X (%s%04X+%d)" % (nm, la, P, a, P, a, la - a))
            stats["aliases"] += 1
        stats["lines"] += 1

    W("")
    for x in FOOTERS.get(which, []):
        W(x)
    with open(os.path.join(HERE, L["out"]), "w", newline="\n") as fp:
        fp.write("\n".join(out) + "\n")

    # identifiers the defines file must supply (everything that is not a label here)
    label_idents = set(nm for labs in labels.values() for nm, _ in labs)
    label_idents |= set(nm for v in aliases_after.values() for nm, _ in v)
    need = {}
    for nm in sorted(refs):
        if nm in label_idents or re.match(r"^[LK][0-9A-F]{4}$", nm):
            continue
        r = names.rec.get(nm)
        if r is None:
            continue
        need[nm] = dict(addr=r["addr"], kind=r["kind"], name=r["name"], module=r["module"],
                        file=r["file"], line=r["line"], comment=r["comment"], image=r["image"],
                        sbttl=r.get("sbttl", ""))
    with open(paths.build("refs_%s.json" % which), "w") as fp:
        json.dump({"refs": need,
                   "labels": sorted(label_idents),
                   "routines": {k: {"addr": "$%04X" % v[0], "desc": v[1], "module": v[2]}
                                for k, v in sorted(desc_list.items(), key=lambda kv: kv[1][0])}},
                  fp, indent=1)
    if verbose:
        print("wrote %s: %d lines, %d instructions, %d data bytes, %d inner aliases" %
              (L["out"], stats["lines"], stats["insn"], stats["data_bytes"], stats["aliases"]))
        print("  routines with headers: %d  (source %d [%d from call-site comments], written %d, none %d)" %
              (len(entries), desc_src["source"], desc_src["source: call-site comment"],
               desc_src["written"], desc_src["none"]))
        print("  symbolic operands: %d, hex fallbacks with symbols in source: %d" %
              (RSTAT["sym"], RSTAT["fallback"]))
        RSTAT.clear()
    return desc_list

FOOTERS = {
    "program": [
        ";" + "=" * 78,
        "; The 6809 vectors are the .VCTRS words at $FFF2-$FFFF above (SWI3, SWI2, FIRQ,",
        "; IRQ, SWI, NMI, RESET).  $6000-$7FFF is banked: this file holds bank 0, and",
        "; starwars_overlay_rom.asm holds bank 1.",
        ";" + "=" * 78,
    ],
    "sound": [
        ";" + "=" * 78,
        "; A15 is a don't-care on the sound board, so this ROM is also at $C000-$FFFF and",
        "; the 6809 reads its vectors at $FFF2-$FFFF from the .VCTRS words at $7FF2-$7FFF",
        "; above.  Atari's link image also loads IRQ at $FFF8 and RESET at $FFFE, for the",
        "; development system; those four bytes are the same as $7FF8 and $7FFE.",
        ";" + "=" * 78,
    ],
}

def wrap(text, width):
    words, lines, cur = text.split(), [], ""
    for w in words:
        if cur and len(cur) + 1 + len(w) > width:
            lines.append(cur)
            cur = w
        else:
            cur = (cur + " " + w) if cur else w
    if cur:
        lines.append(cur)
    return lines

def is_number(expr):
    return bool(NUM_RE.match(expr.strip()))

def natural_idx(sv, ind):
    """Offset size an assembler picks for a known constant offset."""
    if sv == 0:
        return 0
    if -16 <= sv <= 15 and not ind:
        return 5
    return 8 if -128 <= sv <= 127 else 16

def render_insn(u, d, R, modkey, label_for, refs, patched):
    """-> (instruction text, extra comment)."""
    mn, mode, val = d["mn"], d["mode"], d["value"]
    parts = u.text.split(None, 1)
    srcmn = parts[0].upper()
    srcop = parts[1].strip() if len(parts) > 1 else ""
    if m6809.canonical(srcmn) == mn:
        mn = srcmn                                   # keep Atari's spelling (BHS, LSLB)
    elif not patched:
        raise SystemExit("mnemonic mismatch at $%04X: %s vs %s" % (u.addr, u.text, mn))
    M = "%-4s " % mn
    if mode == INH:
        return mn, ""
    if mode == REGS:
        return M + m6809.fmt_regs(val), ""
    if mode == STK:
        return M + m6809.fmt_stack(val, mn), ""
    if mode in (REL8, REL16):
        t = label_for(val) or hexw(val)
        refs.add(t)
        return M + t, ""

    # the expression part of the source operand
    ind = False
    if mode in (IMM8, IMM16):
        expr = srcop[1:] if srcop.startswith("#") else ""
    elif mode == IDX:
        m = IDX_SRC.match(srcop)
        if m:
            expr = m.group(2).strip()
            if expr in ("-", "--") or m.group(4) or (expr.upper() in ("A", "B", "D")):
                expr = ""
        else:
            expr = srcop[1:] if srcop.startswith("@") else ""
    else:
        expr = srcop
    sym = v = None
    used = []
    quiet = u.exp or not expr or is_number(expr)     # no (src: ...) note wanted
    if expr and not is_number(expr):
        try:
            s, v, used = R.render(expr, modkey, u.radix)
            if not used:
                quiet = True                        # numbers only: plain hex reads better
                raise Fail("numbers only")
            sym = s
        except Fail:
            sym = v = None
        if sym is None and re.match(r"^\d+\$$", expr) and mode != IDX and label_for(val):
            sym, v = label_for(val), val                # a local label used as a value
            used = [sym]

    def accept(ok):
        nonlocal sym
        if sym is not None and not ok:
            sym = None
        if sym is not None:
            for x in used:
                refs.add(x)
            RSTAT["sym"] += 1
        elif not quiet:
            RSTAT["fallback"] += 1
            return "(src: %s %s)" % (srcmn, tidy(srcop))
        return ""

    if mode == IMM8:
        extra = accept(v is not None and (v & 0xFF) == val)
        if sym is None:
            return M + "#" + hexb(val), extra
        return M + "#" + (sym if -128 <= v <= 255 else paren(sym) + "&$FF"), extra
    if mode == IMM16:
        extra = accept(v is not None and (v & 0xFFFF) == val)
        if sym is None:
            return M + "#" + hexw(val), extra
        return M + "#" + (sym if -32768 <= v <= 65535 else paren(sym) + "&$FFFF"), extra
    if mode == EXT:
        extra = accept(v is not None and (v & 0xFFFF) == val)
        if sym is None and label_for(val) and mn in ("JSR", "JMP"):
            sym = label_for(val)
            refs.add(sym)
        if sym is None:
            sym = hexw(val)
        elif not 0 <= v <= 0xFFFF and sym != label_for(val):
            sym = paren(sym) + "&$FFFF"
        # written without a prefix an address in the direct page would assemble direct
        return M + (">" if (val >> 8) == u.dpage else "") + sym, extra
    if mode == DIR:
        extra = accept(v is not None and (v & 0xFF) == val)
        if sym is None:
            return M + hexw((u.dpage << 8) | val), extra
        full = v & 0xFFFF
        return M + ("" if (full >> 8) == u.dpage and 0 <= v <= 0xFFFF else "<") + \
            (sym if 0 <= v <= 0xFFFF else paren(sym) + "&$FF"), extra
    # indexed
    post = d["post"]
    ind = bool(post & 0x80 and post & 0x10)
    wrapi = (lambda s: "[" + s + "]") if ind else (lambda s: s)
    if not post & 0x80:
        size, sval, reg = 5, val, m6809.IDX_NAME[(post >> 5) & 3]
    else:
        t, reg = post & 0x0F, m6809.IDX_NAME[(post >> 5) & 3]
        if post == 0x9F:
            extra = accept(v is not None and (v & 0xFFFF) == val)
            return M + "[" + (sym or hexw(val)) + "]", extra
        if t in (0x0, 0x1, 0x2, 0x3, 0x5, 0x6, 0xB):
            body = {0x0: ",%s+", 0x1: ",%s++", 0x2: ",-%s", 0x3: ",--%s",
                    0x5: "B,%s", 0x6: "A,%s", 0xB: "D,%s"}[t] % reg
            return M + wrapi(body), ""
        if t in (0xC, 0xD):
            extra = accept(v is not None and (v & 0xFFFF) == val)
            tgt = sym or label_for(val) or hexw(val)
            if sym is None and label_for(val):
                refs.add(tgt)
            d8 = val - (u.addr + u.len - (1 if t == 0xD else 0))
            nat8 = -128 <= d8 <= 127
            pre = "" if nat8 == (t == 0xC) else ("<" if t == 0xC else ">")
            return M + wrapi(pre + tgt + ",PCR"), extra
        if t == 0x4:
            extra = accept(v is not None and (v & 0xFFFF) == 0)
            return M + wrapi((sym or "") + "," + reg), extra
        size = 8 if t == 0x8 else 16
        sval = val if size == 8 else (val - 0x10000 if val & 0x8000 else val)
    # constant offset: 5, 8 or 16 bits.  An offset is a 16-bit two's complement
    # value, so M$AX = $FFF0 is -16; the natural size is the smallest that holds it.
    if size == 16:
        ok = v is not None and (v & 0xFFFF) == (sval & 0xFFFF)
    elif size == 8:
        ok = v is not None and (v & 0xFF) == (sval & 0xFF)
    else:
        ok = v is not None and s16w(v) == sval
    extra = accept(ok)
    if sym is None:
        nat = natural_idx(sval, ind)
        txt = ("-$%X" % -sval) if sval < 0 else ("$%X" % sval if sval > 9 else str(sval))
    else:
        nat = natural_idx(s16w(v), ind)
        txt = sym
    pre = "" if nat == size else {8: "<", 16: ">"}.get(size, "?")
    return M + wrapi(pre + txt + "," + reg), extra

def render_data(u, mem, R, modkey, refs, label_for):
    out = []
    fallback = False
    a = u.addr
    for arg, sz in u.items:
        v = mem[a] if sz == 1 else (mem[a] << 8) | mem[a + 1]
        s = None
        numonly = False
        if arg is not None and arg.strip() == "." and sz == 2 and v == a and label_for(a):
            s = label_for(a)
        elif arg and not is_number(arg) and u.module:
            try:
                t, tv, used = R.render(arg, modkey, u.radix)
                if not used:
                    numonly = True
                    raise Fail("numbers only")
                if sz == 1:
                    if (tv & 0xFF) == v:
                        s = t if -128 <= tv <= 255 else paren(t) + "&$FF"
                else:
                    if (tv & 0xFFFF) == v:
                        s = t if -32768 <= tv <= 65535 else paren(t) + "&$FFFF"
                if s is not None:
                    for x in used:
                        refs.add(x)
                    RSTAT["sym"] += 1
            except Fail:
                pass
            if s is None and sz == 2 and re.match(r"^\d+\$$", arg.strip()) and label_for(v):
                s = label_for(v)
                refs.add(s)
            if s is None and not numonly:
                fallback = True
        if s is None:
            s = hexb(v) if sz == 1 else hexw(v)
        out.append(s)
        a += sz
    extra = ""
    if fallback and not u.exp:
        RSTAT["fallback"] += 1
        extra = "(src: %s)" % tidy(u.text)
    return out, extra

if __name__ == "__main__":
    for w in (sys.argv[1:] or list(LISTINGS)):
        build(w)
