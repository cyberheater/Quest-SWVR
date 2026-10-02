"""Star Wars AVG display-list decoder and a simple renderer for the shape preview.

Words are big-endian.  The top three bits are the opcode:

  0  VCTR  $0yyy $zxxx   dy, dx 13-bit signed; z = intensity 0-7 (0 = beam off)
  1  HALT  $2000
  2  SVEC  $4...         dy/2 in bits 12-8, z in bits 7-5, dx/2 in bits 4-0
  3  STAT  $6cll         colour in bits 10-8 (4 red, 2 green, 1 blue), brightness ll
     SCAL  $7bll         bit 12 set: binary scale b (size / 2^b), linear scale ll
  4  CNTR  $8040
  5  JSRL  $Annn         word address: target = nnn * 2
  6  RTSL  $C000
  7  JMPL  $Ennn

This renderer is for pictures only: it is not the timing model.  The oracle and
the C port take the AVG from MAME's state-PROM-exact renderer (roadmap step 2).
"""

def sx(v, bits):
    return v - (1 << bits) if v & (1 << (bits - 1)) else v

def word(mem, a):
    return (mem[a] << 8) | mem[a + 1]

def decode(mem, a):
    """-> dict(op, len, ...) for the instruction at address a."""
    w = word(mem, a)
    op = w >> 13
    if op == 0:
        w2 = word(mem, a + 2)
        return dict(op="VCTR", len=4, dy=sx(w & 0x1FFF, 13), dx=sx(w2 & 0x1FFF, 13), z=w2 >> 13)
    if op == 1:
        return dict(op="HALT", len=2)
    if op == 2:
        return dict(op="SVEC", len=2, dy=sx((w >> 8) & 0x1F, 5) * 2, dx=sx(w & 0x1F, 5) * 2,
                    z=(w >> 5) & 7)
    if op == 3:
        if w & 0x1000:
            return dict(op="SCAL", len=2, bin=(w >> 8) & 7, lin=w & 0xFF)
        return dict(op="STAT", len=2, color=(w >> 8) & 7, fuzz=bool(w & 0x800), lum=w & 0xFF)
    if op == 4:
        return dict(op="CNTR", len=2)
    if op == 5:
        return dict(op="JSRL", len=2, target=(w & 0x1FFF) * 2)
    if op == 6:
        return dict(op="RTSL", len=2)
    return dict(op="JMPL", len=2, target=(w & 0x1FFF) * 2)

def text(d):
    o = d["op"]
    if o in ("VCTR", "SVEC"):
        return "%s %d,%d,%d" % (o, d["dx"], d["dy"], d["z"])
    if o == "STAT":
        return "STAT colour %d, brightness $%02X%s" % (d["color"], d["lum"], ", fuzz" if d["fuzz"] else "")
    if o == "SCAL":
        return "SCAL %d,$%02X" % (d["bin"], d["lin"])
    if o in ("JSRL", "JMPL"):
        return "%s $%04X" % (o, d["target"])
    return o

def render(mem, start, lo=0x2800, hi=0x4000, one=False, limit=4000):
    """Run the display list at `start` as a subroutine.  Returns (segments,
    notes): segments are (x0, y0, x1, y1, colour 0-7, brightness 0-255).
    Calls into vector RAM (below `lo`: the program's own variables) are skipped."""
    segs, notes = [], []
    x = y = 0.0
    color, lum, binsc, lin = 7, 0x80, 2, 0
    stack, pc, steps = [], start, 0
    while steps < limit:
        steps += 1
        if not lo <= pc < hi - 1:
            notes.append("ran outside the vector ROM at $%04X" % pc)
            break
        d = decode(mem, pc)
        pc += d["len"]
        o = d["op"]
        if o in ("VCTR", "SVEC"):
            f = (256 - lin) / 256.0 / (1 << binsc)
            nx, ny = x + d["dx"] * f, y + d["dy"] * f
            if d["z"]:
                segs.append((x, y, nx, ny, color, min(255, lum * d["z"] // 7)))
            x, y = nx, ny
        elif o == "STAT":
            color, lum = d["color"], d["lum"]
        elif o == "SCAL":
            binsc, lin = d["bin"], d["lin"]
        elif o == "CNTR":
            x = y = 0.0
        elif o == "JSRL":
            if lo <= d["target"] < hi:
                if len(stack) >= 4:
                    notes.append("JSRL nested too deep")
                    break
                stack.append(pc)
                pc = d["target"]
            else:
                notes.append("JSRL to vector RAM $%04X skipped" % d["target"])
        elif o == "JMPL":
            if lo <= d["target"] < hi:
                pc = d["target"]
            else:
                notes.append("JMPL to vector RAM $%04X" % d["target"])
                break
        elif o == "RTSL":
            if not stack:
                break
            pc = stack.pop()
        else:
            break
        if one and not stack:
            break
    return segs, notes
