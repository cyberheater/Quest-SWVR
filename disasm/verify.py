"""Read back the four Star Wars listings (+ their defines files) and prove each
reproduces its ROM byte for byte.

Independent of emit.py: it parses only the text files.  Every address line is
re-encoded at the address its label states - instruction operands and
.byte/.word expressions are evaluated from the .alias equates and the labels in
the files - and compared with the ROM image; the address lines must also cover
the listing's range exactly once.  Operand sizes are chosen as an assembler
would choose them:

  direct     when the address's high byte is the .dpage in force, else extended
  indexed    the smallest offset that holds the value, as 16-bit two's complement:
             none for 0, 5 bits for -16..15 (not when indirect), 8 bits, 16 bits
  ,PCR       8 bits when the target is in reach, else 16
  < and >    force the short and the long form

so a prefix is required wherever the ROM holds another encoding.  Comment-only
lines, routine headers and blank lines are ignored.  Exit status 1 on any mismatch.
"""
import os, re, sys
HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
import m6809
from m6809 import INH, IMM8, IMM16, DIR, IDX, EXT, REL8, REL16, REGS, STK

BUILD = os.path.join(HERE, "build")
# listing, defines, ROM image, first address, end address, image offset of address 0
LISTINGS = [
    ("starwars_program_rom.asm", "starwars_defines.asm", "starwars_main_rev2.bin", 0x6000, 0x10000, 0),
    ("starwars_overlay_rom.asm", "starwars_defines.asm", "starwars_bank1.bin", 0x6000, 0x8000, 0x6000),
    ("starwars_vector_rom.asm", "starwars_defines.asm", "starwars_main_rev2.bin", 0x3000, 0x4000, 0),
    ("starwars_sound_rom.asm", "starwars_sound_defines.asm", "starwars_sound.bin", 0x4000, 0x8000, 0),
]

LINE = re.compile(r"^([LK][0-9A-F]{4}):\s+(\S+)\s*(.*)$")
LABEL = re.compile(r"^([A-Za-z_][A-Za-z0-9_]*):\s*(;.*)?$")
ALIAS = re.compile(r"^\.alias\s+([A-Za-z_][A-Za-z0-9_]*)\s+([^;\s]+)\s*(;.*)?$")
DPAGE = re.compile(r"^\.dpage\s+\$([0-9A-F]{2})\s*$")

class EvalError(Exception):
    pass

def strip_comment(s):
    return s.split(";", 1)[0].rstrip()

def tokenize(s):
    toks, i, n = [], 0, len(s)
    while i < n:
        c = s[i]
        if c.isspace():
            i += 1
        elif c == "$":
            j = i + 1
            while j < n and s[j] in "0123456789ABCDEFabcdef":
                j += 1
            if j == i + 1:
                raise EvalError("bad hex number in %r" % s)
            toks.append(("num", int(s[i + 1:j], 16)))
            i = j
        elif c.isdigit():
            j = i
            while j < n and s[j].isdigit():
                j += 1
            toks.append(("num", int(s[i:j])))
            i = j
        elif c.isalpha() or c == "_":
            j = i
            while j < n and (s[j].isalnum() or s[j] == "_"):
                j += 1
            toks.append(("id", s[i:j]))
            i = j
        elif c in "+-*/&|^~()":
            toks.append(("op", c))
            i += 1
        else:
            raise EvalError("bad character %r in %r" % (c, s))
    return toks

def evaluate(s, syms):
    """Expression value (unbounded int).  Unary - ~ bind tightest, then * / &,
    then + - | ^.  ( ) groups."""
    toks = tokenize(s)
    pos = [0]

    def peek():
        return toks[pos[0]] if pos[0] < len(toks) else (None, None)

    def unary():
        t, v = peek()
        if t == "op" and v in "-~":
            pos[0] += 1
            x = unary()
            return -x if v == "-" else ~x
        if t == "op" and v == "(":
            pos[0] += 1
            x = add()
            if peek() != ("op", ")"):
                raise EvalError("missing ) in %r" % s)
            pos[0] += 1
            return x
        if t == "num":
            pos[0] += 1
            return v
        if t == "id":
            pos[0] += 1
            if v not in syms:
                raise EvalError("undefined symbol %s" % v)
            return syms[v]
        raise EvalError("bad expression %r" % s)

    def wrap(v):
        v &= 0xFFFF
        return v - 0x10000 if v & 0x8000 else v

    def mul():
        x = unary()
        while True:
            t, v = peek()
            if t == "op" and v in "*/&":
                pos[0] += 1
                y = unary()
                x, y = wrap(x), wrap(y)             # 16-bit operands, as MAC69 holds them
                if v == "*":
                    x *= y
                elif v == "&":
                    x &= y
                else:
                    if y == 0:
                        raise EvalError("division by zero")
                    q = abs(x) // abs(y)
                    x = q if (x < 0) == (y < 0) else -q
            else:
                return x

    def add():
        x = mul()
        while True:
            t, v = peek()
            if t == "op" and v in "+-|^":
                pos[0] += 1
                y = mul()
                if v == "+":
                    x += y
                elif v == "-":
                    x -= y
                elif v == "|":
                    x = wrap(x) | wrap(y)
                else:
                    x = wrap(x) ^ wrap(y)
            else:
                return x

    x = add()
    if pos[0] != len(toks):
        raise EvalError("junk in %r" % s)
    return x

def s16(v):
    v &= 0xFFFF
    return v - 0x10000 if v & 0x8000 else v

def last_comma(s):
    depth = 0
    for i in range(len(s) - 1, -1, -1):
        if s[i] == ")":
            depth += 1
        elif s[i] == "(":
            depth -= 1
        elif s[i] == "," and depth == 0:
            return i
    return -1

def encode(mn, oper, syms, dpage, pc):
    """Bytes of one instruction, or raise EvalError."""
    if mn not in m6809.TAB:
        raise EvalError("unknown mnemonic %s" % mn)
    modes = m6809.TAB[mn]
    o = oper.strip()

    def op(mode):
        if mode not in modes:
            raise EvalError("%s has no %s form" % (mn, m6809.MODE_NAME[mode]))
        return m6809.opbytes(modes[mode])

    if REL8 in modes or REL16 in modes:
        mode = REL8 if REL8 in modes else REL16
        ob = op(mode)
        v = evaluate(o, syms)
        if mode == REL8:
            d = v - (pc + len(ob) + 1)
            if not -128 <= d <= 127:
                raise EvalError("branch out of range")
            return ob + [d & 0xFF]
        d = (v - (pc + len(ob) + 2)) & 0xFFFF
        return ob + [d >> 8, d & 0xFF]
    if INH in modes:
        if o:
            raise EvalError("operand on %s" % mn)
        return op(INH)
    if REGS in modes:
        a, b = [x.strip() for x in o.split(",")]
        return op(REGS) + [(m6809.TFR_REG[a] << 4) | m6809.TFR_REG[b]]
    if STK in modes:
        post = 0
        for x in o.split(","):
            post |= m6809.STK_BIT[x.strip()]
        return op(STK) + [post]
    if o.startswith("#"):
        v = evaluate(o[1:], syms)
        if IMM8 in modes:
            if not -128 <= v <= 255:
                raise EvalError("immediate out of range: %s" % o)
            return op(IMM8) + [v & 0xFF]
        if not -32768 <= v <= 65535:
            raise EvalError("immediate out of range: %s" % o)
        return op(IMM16) + [(v >> 8) & 0xFF, v & 0xFF]
    ind = 0
    if o.startswith("[") and o.endswith("]"):
        ind, o = 0x10, o[1:-1].strip()
    k = last_comma(o)
    if k < 0 and ind:                               # [address]
        v = evaluate(o, syms)
        return op(IDX) + [0x9F, (v >> 8) & 0xFF, v & 0xFF]
    if k >= 0:
        ob = op(IDX)
        left, right = o[:k].strip(), o[k + 1:].strip()
        force = ""
        if left[:1] in "<>" and left:
            force, left = left[0], left[1:]
        if right == "PCR":
            v = evaluate(left, syms)
            d8 = v - (pc + len(ob) + 2)
            if force == "<" or (not force and -128 <= d8 <= 127):
                if not -128 <= d8 <= 127:
                    raise EvalError("PCR offset out of range")
                return ob + [0x8C | ind, d8 & 0xFF]
            d = (v - (pc + len(ob) + 3)) & 0xFFFF
            return ob + [0x8D | ind, d >> 8, d & 0xFF]
        m = re.match(r"^(-{0,2})([XYUS])(\+{0,2})$", right)
        if not m:
            raise EvalError("bad index register in %r" % oper)
        rr = m6809.IDX_REG[m.group(2)] << 5
        if m.group(1) or m.group(3):
            if left or force or (m.group(1) and m.group(3)):
                raise EvalError("bad auto increment/decrement in %r" % oper)
            t = {"+": 0, "++": 1, "-": 2, "--": 3}[m.group(1) or m.group(3)]
            if ind and t in (0, 2):
                raise EvalError("no indirect form of %r" % oper)
            return ob + [0x80 | rr | ind | t]
        if left in ("A", "B", "D") and not force:
            return ob + [0x80 | rr | ind | {"A": 6, "B": 5, "D": 0xB}[left]]
        if left == "":
            return ob + [0x84 | rr | ind]
        v = evaluate(left, syms)
        if not -65536 < v < 65536:
            raise EvalError("offset out of range in %r" % oper)
        sv = s16(v)
        if force == "<":
            return ob + [0x88 | rr | ind, v & 0xFF]
        if force == ">":
            return ob + [0x89 | rr | ind, (v >> 8) & 0xFF, v & 0xFF]
        if sv == 0:
            return ob + [0x84 | rr | ind]
        if -16 <= sv <= 15 and not ind:
            return ob + [rr | (sv & 0x1F)]
        if -128 <= sv <= 127:
            return ob + [0x88 | rr | ind, sv & 0xFF]
        return ob + [0x89 | rr | ind, (v >> 8) & 0xFF, v & 0xFF]
    force = ""
    if o[:1] in "<>" and o:
        force, o = o[0], o[1:]
    v = evaluate(o, syms)
    if not 0 <= v <= 0xFFFF:
        raise EvalError("address out of range: %s" % oper)
    if force == "<" or (not force and DIR in modes and (v >> 8) == dpage):
        return op(DIR) + [v & 0xFF]
    return op(EXT) + [v >> 8, v & 0xFF]

def run(listing, defines, rom_name, LO, HI, off, quiet=False):
    rom = open(os.path.join(BUILD, rom_name), "rb").read()
    text = open(os.path.join(HERE, listing)).read().splitlines()
    dpath = os.path.join(HERE, defines)
    dtext = open(dpath).read().splitlines() if os.path.exists(dpath) else []
    syms, errors = {}, []

    def define(name, value, where):
        if name in syms and syms[name] != value:
            errors.append("%s redefined (%s): $%X and $%X" % (name, where, syms[name], value))
        syms[name] = value

    pending_alias = []
    for ln in dtext + text:
        m = ALIAS.match(ln.strip())
        if m:
            pending_alias.append((m.group(1), m.group(2)))
    pending = []
    for ln in text:
        m = LINE.match(ln)
        if m:
            a = int(m.group(1)[1:], 16)
            for nm in pending:
                define(nm, a, "label")
            pending = []
            define(m.group(1), a, "address label")
            continue
        m = LABEL.match(ln.strip())
        if m:
            pending.append(m.group(1))
    if pending:
        errors.append("labels at end of file: %s" % pending)
    left = pending_alias
    for _ in range(6):
        nxt = []
        for nm, ex in left:
            try:
                define(nm, evaluate(ex, syms), "alias")
            except EvalError:
                nxt.append((nm, ex))
        left = nxt
    for nm, ex in left:
        errors.append("cannot evaluate .alias %s %s" % (nm, ex))

    covered = {}
    total = bad = data = insn = 0
    dpage = 0
    for no, ln in enumerate(text, 1):
        m = LINE.match(ln)
        if not m:
            s = ln.strip()
            d = DPAGE.match(s)
            if d:
                dpage = int(d.group(1), 16)
            elif s and not s.startswith(";") and not LABEL.match(s) and not ALIAS.match(s) \
                    and not s.startswith(".org") and not s.startswith(".include"):
                errors.append("line %d not understood: %s" % (no, s))
            continue
        a, mn, oper = int(m.group(1)[1:], 16), m.group(2), strip_comment(m.group(3))
        try:
            if mn in (".byte", ".word"):
                out = []
                for it in oper.split(","):
                    v = evaluate(it, syms)
                    if mn == ".byte":
                        if not -128 <= v <= 255:
                            raise EvalError(".byte value out of range: %s" % it)
                        out.append(v & 0xFF)
                    else:
                        if not -32768 <= v <= 65535:
                            raise EvalError(".word value out of range: %s" % it)
                        out += [(v >> 8) & 0xFF, v & 0xFF]
                data += len(out)
            else:
                out = encode(mn, oper, syms, dpage, a)
                insn += 1
        except (EvalError, KeyError, ValueError) as e:
            bad += 1
            errors.append("line %d $%04X: %s  [%s %s]" % (no, a, e, mn, oper))
            continue
        for i, b in enumerate(out):
            ad = a + i
            if ad in covered:
                errors.append("$%04X emitted twice (lines %d and %d)" % (ad, covered[ad], no))
            covered[ad] = no
            total += 1
            if LO <= ad < HI and rom[ad - off] != b:
                bad += 1
                errors.append("line %d $%04X: %s %s -> $%02X, ROM has $%02X" % (no, ad, mn, oper, b, rom[ad - off]))
    missing = [x for x in range(LO, HI) if x not in covered]
    outside = [x for x in covered if not LO <= x < HI]
    if missing:
        errors.append("%d ROM bytes not covered, first $%04X" % (len(missing), missing[0]))
    if outside:
        errors.append("%d bytes outside $%04X-$%04X" % (len(outside), LO, HI - 1))
    nerr = bad + len(missing) + len(outside) + len(
        [e for e in errors if "redefined" in e or "not understood" in e or "cannot evaluate" in e
         or "twice" in e or "end of file" in e])
    if not quiet:
        print("%s" % listing)
        print("  verified bytes : %d of %d ($%04X-$%04X)" % (total, HI - LO, LO, HI - 1))
        print("  instructions   : %d    data bytes: %d    symbols: %d" % (insn, data, len(syms)))
        print("  MISMATCHES     : %d" % nerr)
        for e in errors[:25]:
            print("     " + e)
    return nerr

if __name__ == "__main__":
    want = sys.argv[1:]
    n = 0
    for L in LISTINGS:
        if not want or any(w in L[0] for w in want):
            n += run(*L)
    sys.exit(1 if n else 0)
