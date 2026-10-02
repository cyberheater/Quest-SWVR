"""MAC69 assembler for Atari's Star Wars source (22-JUN-83 link).

Assembles the three link images of the archive

    sound    SNDAUX.LNK   sound CPU, $4000-$7FFF
    root     WSROOT.LNK   main CPU, $6000-$FFFF bank 0 and the vector ROM
    overlay  WSOVLY.LNK   main CPU, $6000-$7FFF bank 1

with every control section placed at the base Atari's link map gives it, resolves
the globals across the modules (root and overlay share one symbol pool, as the
three-pass LINKIT.COM arranges), and compares the result with Atari's link
image, with the link map and with the ROMs.

Dialect implemented (MACRO-11 family): radix switches, left-to-right
expressions, six-character symbols, local N$ symbols, .MACRO with nested
definitions and ' concatenation, \\value arguments, .NARG/.NCHR/.MEXIT,
.REPT/.IRP/.IRPC, .IF/.IFF/.IFT/.IFTF/.IIF with IDN/DIF/B/NB/DF/NDF, named
.CSECTs, .ASECT, .GLOBL/.GLOBB, .DPAGE, location-counter back-patching, and
the assembler stacks (.DEFSTACK/.PUSH/.POP/.GETPOINTER) that HLL69F is built on.

Outputs (disasm/build): symbols_<image>.json, srclines_<image>.json,
macasm69_report.md.     Run:  python macasm69.py [image ...] [-v N]
"""
import os, sys, re, json
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import m6809, macsrc, paths, lda, linkmap, image
from m6809 import INH, IMM8, IMM16, DIR, IDX, EXT, REL8, REL16, REGS, STK
from macsrc import (split_comment, parse_stmt, split_args, split_macro_args,
                    substitute, read_source)
from rtexpr import Evaluator, ExprError, s16

IMAGES = {
    "sound": dict(map="SNDAUX.MAP", lda="SNDAUX.LDA", rom="starwars_sound.bin", romoff=0,
                  modules=["SNDGLB", "SWVOC3", "SWMUS", "SNDAUD", "SNDPM", "SNDSPK",
                           "SNDAUX", "SNFILL", "SNDSUM"]),
    "root": dict(map="WSROOT.MAP", lda="WSROOT.LDA", rom="starwars_main_rev1.bin", romoff=0,
                 modules=["WSPROG", "WSMAIN", "WSFIL0", "WSBASE", "WSCPU", "WSFIL1", "WSGAS",
                          "WSGLOW", "WSGRND", "WSGUNS", "WSLAZR", "WSFIL2", "WSPANL", "WSSITE",
                          "WSXPLD", "WSXMT", "TCEROM", "TCHSCR", "WSROOT", "WSMATH", "WSFIL3",
                          "WSVROM", "TCSPLS", "WSCOIN", "TCMES", "WSSTUB", "WSINT", "TCTEST",
                          "WSFIL4", "WSCKSM"]),
    "overlay": dict(map="WSOVLY.MAP", lda="WSOVLY.LDA", rom="starwars_bank1.bin", romoff=0x6000,
                    # WSGLOB is in the first-pass link (WSOVLX.LNK); it emits no ROM
                    # bytes and supplies the RAM globals the root imports as WSOVLX.SYM.
                    modules=["WSGLOB", "WSPROG", "WSOVLY", "WSOBJ", "WSFIL9", "WSSTAR"]),
}
GROUPS = [["sound"], ["root", "overlay"]]

ABS = "\0ABS"
OPENERS = {".MACRO", ".REPT", ".IRPC", ".IRP"}
CLOSERS = {".ENDM", ".ENDR"}
LOCAL_RE = re.compile(r"^\d+\$$")
IDX_RE = re.compile(r"^(@?)\s*(.*?)\s*\(\s*(X|Y|U|S|PC|PCR)\s*\)\s*(\+{0,2})$", re.I)
SHIFT = 0x0100          # relocation probe: an expression that moves with it is relocatable

def sym6(n):
    return n.upper()[:6]

class AsmError(Exception):
    pass

class Reader:
    def __init__(self, lines, kind, fname=None, narg=0, cond_depth=0):
        self.lines, self.kind, self.pos = lines, kind, 0
        self.fname, self.narg, self.cond_depth = fname, narg, cond_depth

class Module:
    """Two-pass assembly of one linked module."""
    def __init__(self, name, image_name, lmap, ext):
        self.name, self.image, self.lmap, self.ext = name, image_name, lmap, ext

    # ------------------------------------------------------------ passes
    def assemble(self):
        self.p1, self.p1loc, self.p1rel = {}, {}, set()
        self.run(1)
        self.p1, self.p1loc, self.p1rel = dict(self.cur), dict(self.locals), set(self.relsyms)
        self.p1labels = dict(self.labelvals)
        self.run(2)
        self.phase = [(k, self.p1labels[k], v) for k, v in self.labelvals.items()
                      if k in self.p1labels and self.p1labels[k] != v]
        return self

    def run(self, pas):
        self.pas = pas
        self.cur, self.resolved, self.locals = {}, set(), {}
        self.relsyms, self.locrel = set(), set()
        self.labelvals = {}
        self.globl, self.globb = set(), set()
        self.macros, self.stacks = {}, {}
        self.radix = 8
        self.dpage = 0
        self.sect = ""
        self.loc, self.hi, self.lo = {}, {}, {}
        self.nobase = set()
        self.block = 0
        self.scope_label = ""
        self.gensym = 30000
        self.shift = 0
        self.conds = []           # [parent_active, cond, active]
        self.sbttl = ""
        self.errors, self.undefined = [], {}
        self.mem, self.owner, self.events = {}, {}, []
        self.defs, self.pending = [], []
        self.block_comments = {}
        self.origin = (self.name, 0)
        self.comment = ""
        self.in_exp = False
        self.refs = []
        self.readers = [Reader(read_source(self.name), "file", fname=self.name)]
        while self.readers:
            r = self.readers[-1]
            if r.pos >= len(r.lines):
                self.pop_reader()
                continue
            text = r.lines[r.pos]
            r.pos += 1
            if r.kind == "file":
                self.origin = (r.fname, r.pos)
                self.in_exp = False
                code, comment = split_comment(text)
                self.comment = comment.strip()
            else:
                code = text
                self.in_exp = True
            try:
                self.statement(code, r, comment_only=(r.kind == "file" and not code.strip()))
            except (AsmError, ExprError, ValueError, KeyError, IndexError) as e:
                self.error("%s: %s" % (type(e).__name__, e), code)

    def pop_reader(self):
        r = self.readers.pop()
        if r.kind != "file" and len(self.conds) > r.cond_depth:
            del self.conds[r.cond_depth:]
        if r.kind == "file" and getattr(r, "saved_sbttl", None) is not None:
            self.sbttl = r.saved_sbttl

    def error(self, msg, code=""):
        if self.pas == 2:
            self.errors.append("%s:%d: %s  [%s]" % (self.origin[0], self.origin[1], msg, code.strip()))

    def active(self):
        return not self.conds or self.conds[-1][2]

    # ------------------------------------------------------------ location
    def ensure(self, sect):
        if sect not in self.loc:
            if sect == ABS:
                base = 0
            else:
                base = self.lmap.base(self.name, sect)
                if base is None:            # an empty csect is not in the map;
                    self.nobase.add(sect)   # emitting into it is an error (emit)
                    base = 0
            self.loc[sect] = self.hi[sect] = self.lo[sect] = base

    def here(self):
        self.ensure(self.sect)
        return self.loc[self.sect]

    def setloc(self, v):
        self.ensure(self.sect)
        self.loc[self.sect] = v & 0xFFFF
        self.hi[self.sect] = max(self.hi[self.sect], v & 0xFFFF)

    def advance(self, n):
        self.setloc(self.here() + n)

    # ------------------------------------------------------------ symbols
    def resolve(self, name):
        name = name.upper()
        if LOCAL_RE.match(name):
            key = (self.block, name)
            if key in self.locals:
                return self.locals[key] + (self.shift if key in self.locrel else 0), True
            if key in self.p1loc:
                return self.p1loc[key], False
            raise KeyError(name)
        k = sym6(name)
        self.refs.append(k)
        if k in self.cur:
            return self.cur[k] + (self.shift if k in self.relsyms else 0), k in self.resolved
        if k in self.p1:
            return self.p1[k], False
        if k in self.ext:
            return self.ext[k], False
        raise KeyError(name)

    def ev(self, text, radix=None):
        self.refs = []
        dot = self.here() + (self.shift if self.sect != ABS else 0)
        e = Evaluator(self.resolve, self.radix if radix is None else radix, dot)
        v = e.eval(text)
        if e.undefined and self.pas == 2 and not self.shift:
            for u in e.undefined:
                self.undefined.setdefault(u, "%s:%d" % self.origin)
        return v, e.known

    def ev2(self, text):
        """(value, known, absolute): absolute is False for an expression whose
        value moves with the control section it was assembled in."""
        v, known = self.ev(text)
        refs = self.refs
        self.shift = SHIFT
        try:
            v2, _ = self.ev(text)
        finally:
            self.shift = 0
        self.refs = refs
        return v, known, v2 == v

    def define(self, name, value, known, kind, glob=False, rel=False, expr=None):
        k = sym6(name)
        self.cur[k] = value & 0xFFFF
        (self.resolved.add if known else self.resolved.discard)(k)
        (self.relsyms.add if rel else self.relsyms.discard)(k)
        if glob:
            self.globl.add(k)
        if self.pas == 2:
            self.defs.append(dict(name=k, src_name=name.upper(), value=value & 0xFFFF, how=kind,
                                  file=self.origin[0], line=self.origin[1], sbttl=self.sbttl,
                                  comment=self.comment, in_exp=self.in_exp, sect=self.sect,
                                  glob=glob, rel=rel,
                                  refs=list(self.refs) if kind == "assign" else [],
                                  block=list(self.pending) if not self.in_exp else []))

    def define_label(self, name, glob):
        v = self.here()
        rel = self.sect != ABS
        if LOCAL_RE.match(name):
            self.locals[(self.block, name)] = v
            if rel:
                self.locrel.add((self.block, name))
            if self.pas == 2:
                self.defs.append(dict(name=name, src_name=name, value=v, how="local",
                                      file=self.origin[0], line=self.origin[1], sbttl=self.sbttl,
                                      comment=self.comment, in_exp=self.in_exp, sect=self.sect,
                                      glob=False, rel=rel, refs=[], block=[],
                                      scope=self.scope_label))
            return
        self.block += 1
        self.scope_label = sym6(name)
        self.labelvals[sym6(name)] = v
        self.refs = []
        self.define(name, v, True, "label", glob, rel)

    # ------------------------------------------------------------ emission
    def emit(self, data, kind, text="", addr=None):
        a = self.here() if addr is None else addr
        if addr is None and self.sect in self.nobase:
            self.error("bytes emitted in csect '%s', which has no link-map base" % self.sect, text)
        if self.pas == 2:
            ev = len(self.events)
            self.events.append(dict(addr=a, len=len(data), origin=self.origin, kind=kind,
                                    text=text.strip(), exp=self.in_exp, sect=self.sect,
                                    dpage=self.dpage, radix=self.radix))
            for i, b in enumerate(data):
                ad = (a + i) & 0xFFFF
                self.mem[ad] = b & 0xFF
                if ad not in self.owner:
                    self.owner[ad] = ev
            if self.pending:
                if a not in self.block_comments:
                    self.block_comments[a] = list(self.pending)
                self.pending = []
        if addr is None:
            self.advance(len(data))

    # ------------------------------------------------------------ statements
    def statement(self, code, r, comment_only=False):
        if comment_only:
            if self.comment and self.active():
                self.pending.append(self.comment)
            return
        st = parse_stmt(code)
        if not self.active():
            if st.kind == "op":
                op = sym6(st.op)
                if op == ".IF":
                    self.conds.append([False, False, False])
                elif op in (".IFF", ".IFT", ".IFTF"):
                    self.cond_switch(op)
                elif op == ".ENDC":
                    if self.conds:
                        self.conds.pop()
            return
        for name, glob in st.labels:
            self.define_label(name, glob)
        if st.kind == "assign":
            self.refs = []
            if st.name == ".":
                v, _ = self.ev(st.operand)
                self.setloc(v)
                return
            v, known, absol = self.ev2(st.operand)
            self.define(st.name, v, known, "assign", st.glob, rel=not absol)
            if not self.in_exp:
                self.pending = []
            return
        if st.kind != "op":
            return
        op = st.op
        k = sym6(op)
        if k in self.macros and k not in (".ENDM", ".ENDR", ".ENDC"):
            self.expand_macro(self.macros[k], st.operand, r)
            return
        if op in m6809.TAB:
            self.instruction(op, st.operand)
            return
        h = DIRECTIVES.get(k)
        if h is None:
            if op == "." or op[:1].isdigit() or k in self.cur or k in self.p1 or k in self.ext:
                d_word(self, code.strip(), r, code)       # bare expression = implicit .WORD
                return
            raise AsmError("unknown op %s" % op)
        n = len(self.events)
        h(self, st.operand, r, code)
        if not self.in_exp and len(self.events) == n and h is not d_include:
            self.pending = []         # a comment block belongs to the statement right below it

    def cond_switch(self, op):
        if not self.conds:
            return
        c = self.conds[-1]
        if op == ".IFF":
            c[2] = c[0] and not c[1]
        elif op == ".IFT":
            c[2] = c[0] and c[1]
        else:
            c[2] = c[0]

    def test_cond(self, cond, arg):
        cond = cond.upper()
        if cond in ("B", "NB"):
            a = arg.strip()
            if a.startswith("<") and a.endswith(">"):
                a = a[1:-1].strip()
            return (a == "") == (cond == "B")
        if cond in ("IDN", "DIF"):
            xs = split_args(arg)
            a = xs[0].strip() if xs else ""
            b = xs[1].strip() if len(xs) > 1 else ""
            return (a.upper() == b.upper()) == (cond == "IDN")
        if cond in ("DF", "NDF"):
            names = re.split(r"[&!]", arg)
            d = all(self.is_defined(n.strip()) for n in names if n.strip())
            return d == (cond == "DF")
        v, _ = self.ev(arg)
        v = s16(v)
        return {"EQ": v == 0, "NE": v != 0, "GT": v > 0, "LT": v < 0, "GE": v >= 0,
                "LE": v <= 0, "Z": v == 0, "NZ": v != 0, "G": v > 0, "L": v < 0}[cond]

    def is_defined(self, n):
        n = n.upper()
        if LOCAL_RE.match(n):
            return (self.block, n) in self.locals
        k = sym6(n)
        return k in self.cur or k in self.ext

    @staticmethod
    def split_cond(operand):
        m = re.match(r"^\s*([A-Za-z]+)\s*[, \t]\s*(.*)$", operand)
        if not m:
            return operand.strip(), ""
        return m.group(1), m.group(2)

    @staticmethod
    def split_expr(s):
        """First argument of .IIF: ends at a top-level comma or blank."""
        depth, i, n = 0, 0, len(s)
        while i < n:
            c = s[i]
            if c == "'" and i + 1 < n:
                i += 2
                continue
            if c == "<":
                depth += 1
            elif c == ">":
                depth -= 1
            elif depth == 0 and (c == "," or c.isspace()):
                rest = s[i + 1:]
                if c.isspace():
                    rest = rest.lstrip()
                    if rest.startswith(","):
                        rest = rest[1:]
                return s[:i], rest
            i += 1
        return s, ""

    # ------------------------------------------------------------ macros
    def collect_body(self, r):
        body, depth = [], 1
        while r.pos < len(r.lines):
            text = r.lines[r.pos]
            r.pos += 1
            code = split_comment(text)[0] if r.kind == "file" else text
            st = parse_stmt(code)
            if st.kind == "op":
                if st.op in OPENERS:
                    depth += 1
                elif st.op in CLOSERS:
                    depth -= 1
                    if depth == 0:
                        return body
            body.append(code.rstrip())
        raise AsmError("unterminated macro/repeat body")

    def fmt(self, v):
        return "%d" % v            # MAC69 passes a \value argument in decimal (.PGX9, .PGX10)

    def expand_macro(self, mac, operand, r):
        formals, body = mac
        args = split_macro_args(operand) if operand.strip() else []
        table = {}
        for i, f in enumerate(formals):
            a = args[i] if i < len(args) else ""
            if f.startswith("?"):
                f = f[1:]
                if not a:
                    a = "%d$" % self.gensym
                    self.gensym += 1
            if a.startswith("\\"):
                v, _ = self.ev(a[1:])
                a = self.fmt(v)
            table[f] = a
        lines = [substitute(l, table) for l in body]
        self.readers.append(Reader(lines, "macro", narg=len(args), cond_depth=len(self.conds)))

    def cur_narg(self):
        for rd in reversed(self.readers):
            if rd.kind == "macro":
                return rd.narg
        return 0

    # ------------------------------------------------------------ 6809
    def direct_ok(self, v, known, absol):
        """MAC69 picks direct addressing for an absolute value already defined
        whose high byte is the .DPAGE in force, and for a .GLOBB external."""
        if known and absol:
            return (v >> 8) == self.dpage
        return any(k in self.globb for k in self.refs)

    def instruction(self, mn, operand):
        modes = m6809.TAB[mn]
        o = operand.strip()
        text = ("%s %s" % (mn, o)).strip()
        if REL8 in modes or REL16 in modes:
            mode = REL8 if REL8 in modes else REL16
            ob = m6809.opbytes(modes[mode])
            v, _ = self.ev(o)
            n = len(ob) + (1 if mode == REL8 else 2)
            d = (v - (self.here() + n)) & 0xFFFF
            if mode == REL8:
                if self.pas == 2 and not -128 <= s16(d) <= 127:
                    self.error("branch out of range to $%04X" % v, text)
                self.emit(ob + [d & 0xFF], "insn", text)
            else:
                self.emit(ob + [d >> 8, d & 0xFF], "insn", text)
            return
        if INH in modes:
            self.emit(m6809.opbytes(modes[INH]), "insn", text)
            return
        if REGS in modes:
            a, b = [x.strip().upper() for x in o.split(",")]
            self.emit(m6809.opbytes(modes[REGS]) +
                      [(m6809.TFR_REG[a] << 4) | m6809.TFR_REG[b]], "insn", text)
            return
        if STK in modes:
            post = 0
            for x in o.split(","):
                post |= m6809.STK_BIT[x.strip().upper()]
            self.emit(m6809.opbytes(modes[STK]) + [post], "insn", text)
            return
        if o.startswith("#"):
            mode = IMM8 if IMM8 in modes else IMM16
            if mode not in modes:
                raise AsmError("no immediate form of %s" % mn)
            v, _ = self.ev(o[1:])
            data = [v & 0xFF] if mode == IMM8 else [v >> 8, v & 0xFF]
            self.emit(m6809.opbytes(modes[mode]) + data, "insn", text)
            return
        m = IDX_RE.match(o)
        if m or o.startswith("@"):
            if IDX not in modes:
                raise AsmError("no indexed form of %s" % mn)
            self.emit(m6809.opbytes(modes[IDX]) + self.indexed(m, o, len(m6809.opbytes(modes[IDX]))),
                      "insn", text)
            return
        v, known, absol = self.ev2(o)
        if DIR in modes and self.direct_ok(v, known, absol):
            self.emit(m6809.opbytes(modes[DIR]) + [v & 0xFF], "insn", text)
        else:
            if EXT not in modes:
                raise AsmError("no extended form of %s" % mn)
            self.emit(m6809.opbytes(modes[EXT]) + [v >> 8, v & 0xFF], "insn", text)

    def indexed(self, m, o, oplen):
        if not m:                                   # @expr : extended indirect
            v, _ = self.ev(o[1:])
            return [0x9F, v >> 8, v & 0xFF]
        ind = 0x10 if m.group(1) else 0
        pre, reg, inc = m.group(2).strip(), m.group(3).upper(), m.group(4)
        if reg in ("PC", "PCR"):
            v, known, absol = self.ev2(pre)
            pc = self.here()
            d8 = (v - (pc + oplen + 2)) & 0xFFFF
            if known and -128 <= s16(d8) <= 127:
                return [0x8C | ind, d8 & 0xFF]
            d = (v - (pc + oplen + 3)) & 0xFFFF
            return [0x8D | ind, d >> 8, d & 0xFF]
        rr = m6809.IDX_REG[reg] << 5
        if inc:
            if pre and self.ev(pre)[0]:
                raise AsmError("offset with auto-increment")
            return [0x80 | rr | ind | (0 if inc == "+" else 1)]
        if pre in ("-", "--"):
            return [0x80 | rr | ind | (2 if pre == "-" else 3)]
        if pre == "":
            return [0x84 | rr | ind]
        if pre.upper() in ("A", "B", "D") and sym6(pre) not in self.cur:
            return [0x80 | rr | ind | {"A": 6, "B": 5, "D": 0xB}[pre.upper()]]
        v, known, absol = self.ev2(pre)
        sv = s16(v)
        if known and absol:
            if sv == 0:
                return [0x84 | rr | ind]
            if -16 <= sv <= 15 and not ind:
                return [rr | (sv & 0x1F)]
            if -128 <= sv <= 127:
                return [0x88 | rr | ind, sv & 0xFF]
        elif any(k in self.globb for k in self.refs):     # .GLOBB external: a byte
            return [0x88 | rr | ind, v & 0xFF]
        return [0x89 | rr | ind, v >> 8, v & 0xFF]

# ---------------------------------------------------------------- directives
def d_ignore(a, operand, r, code):
    pass

def d_sbttl(a, operand, r, code):
    m = re.match(r"^\s*(?:[A-Za-z0-9$._]+::?\s*)*\.SBTTLE?\s?(.*)$", code, re.I)
    a.sbttl = (m.group(1) if m else operand).strip()

def d_radix(a, operand, r, code):
    a.radix = a.ev(operand, radix=10)[0]

def d_dpage(a, operand, r, code):
    a.dpage = a.ev(operand)[0] & 0xFF

def d_include(a, operand, r, code):
    name = operand.strip().split()[0].upper()
    if name.endswith(".MAC"):
        name = name[:-4]
    rd = Reader(read_source(name), "file", fname=name)
    rd.saved_sbttl = a.sbttl
    a.readers.append(rd)

def d_asect(a, operand, r, code):
    a.sect = ABS
    a.block += 1

def d_csect(a, operand, r, code):
    a.sect = sym6(operand.strip())
    a.block += 1

def d_blkb(a, operand, r, code):
    a.advance(a.ev(operand)[0])

def d_byte(a, operand, r, code):
    data = []
    for x in split_args(operand):
        v, _ = a.ev(x) if x.strip() else (0, True)
        data.append(v & 0xFF)
    a.emit(data, "byte", ".BYTE " + operand)

def d_word(a, operand, r, code):
    data = []
    for x in split_args(operand):
        v, _ = a.ev(x) if x.strip() else (0, True)
        data += [(v >> 8) & 0xFF, v & 0xFF]
    a.emit(data, "word", ".WORD " + operand)

def d_ascii(a, operand, r, code):
    s = operand.strip()
    data = []
    while s:
        if s[0] == "<":
            j = macsrc.matching_close(s, 0)
            data.append(a.ev(s[1:j])[0] & 0xFF)
            s = s[j + 1:].lstrip()
        else:
            j = s.index(s[0], 1)
            data += [ord(c) for c in s[1:j]]
            s = s[j + 1:].lstrip()
    return data

def d_ascii_plain(a, operand, r, code):
    a.emit(d_ascii(a, operand, r, code), "byte", ".ASCII " + operand)

def d_ascin(a, operand, r, code):
    """.ASCII with bit 7 set on the last character."""
    data = d_ascii(a, operand, r, code)
    if data:
        data[-1] |= 0x80
    a.emit(data, "byte", ".ASCIN " + operand)

def d_vctrs(a, operand, r, code):
    args = split_args(operand)
    addr, _ = a.ev(args[0])
    data = []
    for x in args[1:]:
        v, _ = a.ev(x)
        data += [(v >> 8) & 0xFF, v & 0xFF]
    a.emit(data, "word", ".VCTRS " + operand, addr=addr)

def d_globl(a, operand, r, code):
    for x in re.split(r"[,\s]+", operand.strip()):
        if x:
            a.globl.add(sym6(x))

def d_globb(a, operand, r, code):
    for x in re.split(r"[,\s]+", operand.strip()):
        if x:
            a.globb.add(sym6(x))

def d_macro(a, operand, r, code):
    parts = [p for p in re.split(r"[,\s]+", operand.strip()) if p]
    a.macros[sym6(parts[0])] = ([p.upper() for p in parts[1:]], a.collect_body(r))

def d_rept(a, operand, r, code):
    body = a.collect_body(r)
    n = s16(a.ev(operand)[0])
    if n > 0:
        a.readers.append(Reader(body * n, "rept", cond_depth=len(a.conds), narg=a.cur_narg()))

def _irp_head(operand):
    m = re.match(r"^\s*([A-Za-z0-9$._]+)\s*,?\s*(.*)$", operand)
    s = m.group(2).rstrip()
    if s.startswith("<"):
        s = s[1:macsrc.matching_close(s, 0)]
    return m.group(1).upper(), s

def d_irpc(a, operand, r, code):
    body = a.collect_body(r)
    sym, s = _irp_head(operand)
    lines = []
    for ch in s:
        lines += [substitute(l, {sym: ch}) for l in body]
    if lines:
        a.readers.append(Reader(lines, "rept", cond_depth=len(a.conds), narg=a.cur_narg()))

def d_irp(a, operand, r, code):
    body = a.collect_body(r)
    sym, s = _irp_head(operand)
    lines = []
    for x in split_macro_args(s):
        lines += [substitute(l, {sym: x}) for l in body]
    if lines:
        a.readers.append(Reader(lines, "rept", cond_depth=len(a.conds), narg=a.cur_narg()))

def d_if(a, operand, r, code):
    cond, rest = Module.split_cond(operand)
    parent = a.active()
    val = a.test_cond(cond, rest)
    a.conds.append([parent, val, parent and val])

def d_iff(a, operand, r, code):
    a.cond_switch(".IFF")

def d_ift(a, operand, r, code):
    a.cond_switch(".IFT")

def d_iftf(a, operand, r, code):
    a.cond_switch(".IFTF")

def d_endc(a, operand, r, code):
    if a.conds:
        a.conds.pop()

def d_iif(a, operand, r, code):
    cond, rest = Module.split_cond(operand)
    if cond.upper() in ("IDN", "DIF"):
        x, rest2 = Module.split_expr(rest)
        y, stmt = Module.split_expr(rest2)
        arg = x + "," + y
    else:
        arg, stmt = Module.split_expr(rest)
    if a.test_cond(cond, arg):
        a.statement(stmt, r)

def d_narg(a, operand, r, code):
    a.refs = []
    a.define(operand.strip(), a.cur_narg(), True, "assign")

def d_nchr(a, operand, r, code):
    m = re.match(r"^\s*([A-Za-z0-9$._]+)\s*,\s?(.*)$", operand)
    s = m.group(2)
    if s.startswith("<"):
        s = s[1:macsrc.matching_close(s, 0)]
    a.refs = []
    a.define(m.group(1), len(s), True, "assign")

def d_mexit(a, operand, r, code):
    while a.readers:
        rd = a.readers[-1]
        if rd.kind == "file":
            return
        a.pop_reader()
        if rd.kind in ("macro", "rept"):
            return

def d_end(a, operand, r, code):
    a.readers.clear()

def d_error(a, operand, r, code):
    a.error(".ERROR " + operand, code)

# assembler stacks: .DEFSTACK name,size   .PUSH name,sym,...   .POP name,sym,...
def d_defstack(a, operand, r, code):
    xs = split_args(operand)
    a.stacks[sym6(xs[0].strip())] = dict(size=a.ev(xs[1])[0], items=[])

def d_push(a, operand, r, code):
    xs = [x.strip() for x in split_args(operand)]
    st = a.stacks[sym6(xs[0])]
    for x in xs[1:]:
        v, known, absol = a.ev2(x)
        st["items"].append((v, not absol))

def d_pop(a, operand, r, code):
    xs = [x.strip() for x in split_args(operand)]
    st = a.stacks[sym6(xs[0])]
    for x in xs[1:]:
        if not st["items"]:
            raise AsmError("assembler stack %s underflow" % xs[0])
        v, rel = st["items"].pop()
        a.refs = []
        a.define(x, v, True, "assign", rel=rel)

def d_getpointer(a, operand, r, code):
    xs = [x.strip() for x in split_args(operand)]
    st = a.stacks[sym6(xs[0])]
    a.refs = []
    a.define(xs[1], st["size"] - len(st["items"]), True, "assign")

_D = {
    ".TITLE": d_ignore, ".SBTTL": d_sbttl, ".PAGE": d_ignore, ".RADIX": d_radix,
    ".ENABL": d_ignore, ".DSABL": d_ignore, ".NLIST": d_ignore, ".LIST": d_ignore,
    ".NOCROSS": d_ignore, ".CROSS": d_ignore, ".PRINT": d_ignore, ".COPY": d_ignore,
    ".INCLUDE": d_include, ".ASECT": d_asect, ".CSECT": d_csect, ".BLKB": d_blkb,
    ".BYTE": d_byte, ".WORD": d_word, ".ASCII": d_ascii_plain, ".ASCIN": d_ascin, ".VCTRS": d_vctrs,
    ".GLOBL": d_globl, ".GLOBB": d_globb, ".DPAGE": d_dpage,
    ".MACRO": d_macro, ".ENDM": d_ignore, ".ENDR": d_ignore, ".REPT": d_rept,
    ".IRPC": d_irpc, ".IRP": d_irp, ".IF": d_if, ".IFF": d_iff, ".IFT": d_ift,
    ".IFTF": d_iftf, ".ENDC": d_endc, ".IIF": d_iif, ".NARG": d_narg, ".NCHR": d_nchr,
    ".MEXIT": d_mexit, ".END": d_end, ".ERROR": d_error,
    ".DEFSTACK": d_defstack, ".PUSH": d_push, ".POP": d_pop, ".GETPOINTER": d_getpointer,
}
DIRECTIVES = {sym6(k): v for k, v in _D.items()}

# ---------------------------------------------------------------- link
def link(group, verbose=True):
    """Assemble every module of the images in `group` until the globals settle.
    Returns {image: [Module, ...]}, globals."""
    maps = {im: linkmap.LinkMap(IMAGES[im]["map"]) for im in group}
    ext = {}
    for rnd in range(1, 8):
        out, glob = {}, {}
        for im in group:
            mods = []
            for name in IMAGES[im]["modules"]:
                m = Module(name, im, maps[im], ext).assemble()
                for d in m.defs:
                    if d["how"] != "local" and (d["glob"] or d["name"] in m.globl) \
                            and d["name"] in m.cur:
                        glob.setdefault(d["name"], m.cur[d["name"]])
                mods.append(m)
            out[im] = mods
        if verbose:
            print("  link %s round %d: %d globals" % ("+".join(group), rnd, len(glob)))
        if glob == ext:
            break
        ext = glob
    return out, glob, maps

def compare(im, mods, lmap, glob, show=0):
    """Hold one assembled image against Atari's link image, the map and the ROM."""
    spec = IMAGES[im]
    want, _ = lda.read(spec["lda"])
    rom = image.load(spec["rom"])
    mem, owner, events = {}, {}, []
    per = {}
    for m in mods:
        off = len(events)
        for e in m.events:
            e["module"] = m.name
            events.append(e)
        for a, b in m.mem.items():
            mem[a] = b
        for a, ev in m.owner.items():
            owner.setdefault(a, off + ev)
    bad = [a for a in sorted(mem) if a in want and want[a] != mem[a]]
    extra = [a for a in sorted(mem) if a not in want]
    missing = [a for a in sorted(want) if a not in mem]
    romdiff = [a for a in sorted(mem) if a in want and rom[a - spec["romoff"]] != mem[a]]
    for a in mem:
        s = per.setdefault(events[owner[a]]["module"], [0, 0])
        s[0 if want.get(a) == mem[a] else 1] += 1
    nerr = sum(len(m.errors) for m in mods)
    # sections
    sect_bad = []
    for m in mods:
        for sect, hi in m.hi.items():
            if sect == ABS or (sect in m.nobase and hi == m.lo[sect]):
                continue
            s = lmap.section(m.name, sect)
            if s is None:
                sect_bad.append("%s csect '%s' not in map" % (m.name, sect))
            elif not s["ovr"] or len(s["files"]) == 1:
                if hi - s["addr"] != s["size"]:
                    sect_bad.append("%s csect '%s' size %04X, map %04X" % (
                        m.name, sect, hi - s["addr"], s["size"]))
    # globals
    glob_bad = []
    for nm, val in sorted(lmap.globals.items()):
        if glob.get(nm) != val:
            glob_bad.append("%s map=%04X asm=%s" % (nm, val,
                            "%04X" % glob[nm] if nm in glob else "missing"))
    print("%s: %d bytes emitted, %d differ from %s, %d not in image, %d of image not emitted, "
          "%d differ from ROM; %d errors; sections %d bad; globals %d/%d bad" % (
              im, len(mem), len(bad), spec["lda"], len(extra), len(missing), len(romdiff),
              nerr, len(sect_bad), len(glob_bad), len(lmap.globals)))
    if show:
        for m in mods:
            s = per.get(m.name, [0, 0])
            print("  %-7s ok %6d  bad %5d  errors %4d  phase %d" % (
                m.name, s[0], s[1], len(m.errors), len(m.phase)))
        n = 0
        for m in mods:
            for e in m.errors:
                if n >= show:
                    break
                print("  ERR", e)
                n += 1
        seen, n = set(), 0
        for a in bad:
            ev = owner[a]
            if ev in seen:
                continue
            seen.add(ev)
            e = events[ev]
            got = " ".join("%02X" % mem[x] for x in range(e["addr"], e["addr"] + e["len"]))
            exp = " ".join("%02X" % want.get(x, 0x100) if x in want else "--"
                           for x in range(e["addr"], e["addr"] + e["len"]))
            print("  %04X %s:%d  %-28s got %s  want %s" % (
                e["addr"], e["origin"][0], e["origin"][1], e["text"][:28], got[:40], exp[:40]))
            n += 1
            if n >= show:
                break
        for x in sect_bad[:show]:
            print("  SECT", x)
        for x in glob_bad[:show]:
            print("  GLOB", x)
        if missing:
            print("  not emitted:", " ".join("%04X-%04X" % tuple(r) for r in
                                             lda.ranges({a: 0 for a in missing})[:12]))
        if extra:
            print("  not in image:", " ".join("%04X-%04X" % tuple(r) for r in
                                              lda.ranges({a: 0 for a in extra})[:12]))
    ok = not (bad or extra or missing or romdiff or nerr or sect_bad or glob_bad)
    return ok, dict(mem=mem, owner=owner, events=events)

# ---------------------------------------------------------------- symbols
# address classes, per CPU
SPACE = {
    "main": dict(rom=[(0x3000, 0x4000), (0x6000, 0x10000)],
                 ram=[(0x0000, 0x3000), (0x4800, 0x6000)], io=[(0x4300, 0x4800)]),
    "sound": dict(rom=[(0x4000, 0x8000)],
                  ram=[(0x1000, 0x1080), (0x2000, 0x2800)], io=[(0x0000, 0x1000), (0x1080, 0x2000)]),
}
CPU_OF = {"sound": "sound", "root": "main", "overlay": "main"}
COMMON_FILES = {"WSCOMN", "HLL69F", "MOP69", "WSVGMC", "WSVGAN", "WSVCTR", "COIN69", "DPCOIN",
                "SNDCMN", "SNDPBX"}

def _in(v, spans):
    return any(lo <= v < hi for lo, hi in spans)

def symbol_table(group, out):
    """One record per symbol definition of the images in `group` (see symbols_*.json)."""
    sp = SPACE[CPU_OF[group[0]]]
    symbols, seen, ramnames, ionames = [], set(), {}, set()
    def span(v):
        return next((s for s in sp["ram"] if s[0] <= v < s[1]), None)
    for im in group:
        first = {}
        for m in out[im]:
            for e in m.events:
                first.setdefault(e["addr"], e)
        for m in out[im]:
            vals = {}
            for d in m.defs:
                vals.setdefault(d["name"], set()).add(d["value"])
            for d in m.defs:
                name = d["src_name"]
                if name.startswith("."):
                    continue                           # assembler temporaries and page markers
                # a symbol the source redefines as it goes (a counter such as PH$EQ):
                # keep the definition that gives its final value, the one a
                # reference made before the last redefinition assembles to
                if d["how"] == "assign" and len(vals[d["name"]]) > 1 \
                        and d["value"] != m.cur.get(d["name"]):
                    continue
                key = (d["name"], d["value"], d["file"], d["line"])
                if key in seen:
                    continue
                seen.add(key)
                v = d["value"]
                def romkind():
                    e = first.get(v)
                    return "code" if e and e["kind"] == "insn" else "data"
                if d["how"] == "local":
                    kind = "local"
                elif d["how"] == "label":
                    if d["sect"] == ABS:
                        kind = "ram" if _in(v, sp["ram"]) else "io" if _in(v, sp["io"]) else \
                            romkind() if _in(v, sp["rom"]) else "equate"
                    else:
                        kind = romkind()
                else:
                    refs = d["refs"]
                    if d["rel"] and _in(v, sp["rom"]):
                        kind = romkind()
                    # an address only if it lands in the RAM region of a RAM name it is
                    # made from: M$S1BC (a block index) and PNLW$IZ (a size) are small
                    # numbers that happen to fall in vector RAM
                    elif span(v) and any(ramnames.get(x) == span(v) for x in refs):
                        kind = "ram"
                    elif _in(v, sp["io"]) and (CPU_OF[im] == "main" or v >= 0x0800 or d["name"] == "SOUT"
                                               or any(x in ionames for x in refs)):
                        kind = "io"
                    else:
                        kind = "equate"
                if kind == "ram":
                    ramnames[d["name"]] = span(v)
                elif kind == "io":
                    ionames.add(d["name"])
                rec = dict(name=d["name"], addr=v, kind=kind, image=im,
                           module=d["file"] if d["file"] in COMMON_FILES else m.name,
                           file=d["file"] + ".MAC", line=d["line"], sbttl=d["sbttl"],
                           comment=d["comment"])
                if name != d["name"]:
                    rec["source_name"] = name
                if d["glob"] or d["name"] in m.globl:
                    rec["global"] = True
                if d["how"] == "local":
                    rec["scope"] = d.get("scope")
                if d["block"]:
                    rec["block_comment"] = d["block"]
                if len(vals[d["name"]]) > 1:
                    rec["redefined"] = True
                if d["in_exp"]:
                    rec["from_macro"] = True
                symbols.append(rec)
    symbols.sort(key=lambda s: (s["addr"], s["name"], s["file"], s["line"]))
    return symbols

_cache = {}

def assemble(group_name):
    """group_name 'sound' or 'main' -> dict(out, glob, maps, symbols, group)."""
    if group_name not in _cache:
        group = ["sound"] if group_name == "sound" else ["root", "overlay"]
        out, glob, maps = link(group, verbose=False)
        _cache[group_name] = dict(out=out, glob=glob, maps=maps, group=group,
                                  symbols=symbol_table(group, out))
    return _cache[group_name]

def main(argv):
    show = 0
    if "-v" in argv:
        i = argv.index("-v")
        show = int(argv[i + 1])
        del argv[i:i + 2]
    wanted = argv or list(IMAGES)
    allok = True
    R = ["# macasm69 report (Star Wars, Atari's 22-JUN-83 link)\n"]
    for gname in ("sound", "main"):
        g = assemble(gname)
        if not any(im in wanted for im in g["group"]):
            continue
        for im in g["group"]:
            if im in wanted:
                ok, _ = compare(im, g["out"][im], g["maps"][im], g["glob"], show)
                allok = allok and ok
                mods = g["out"][im]
                R.append("## %s (%s)\n" % (im, IMAGES[im]["lda"]))
                R.append("%s. Modules: %s.\n" % ("All gates pass" if ok else "**GATE FAILED**",
                                                 " ".join(m.name for m in mods)))
                R.append("| Module | Bytes | Errors | Phase errors |")
                R.append("|---|---|---|---|")
                for m in mods:
                    R.append("| %s | %d | %d | %d |" % (m.name, len(m.mem), len(m.errors), len(m.phase)))
                R.append("")
        counts = {}
        for s in g["symbols"]:
            counts[s["kind"]] = counts.get(s["kind"], 0) + 1
        R.append("Symbols (%s): %d - %s.\n" % (gname, len(g["symbols"]),
                 ", ".join("%s %d" % kv for kv in sorted(counts.items()))))
        with open(paths.build("symbols_%s.json" % gname), "w") as fp:
            json.dump(g["symbols"], fp, indent=0)
    with open(paths.build("macasm69_report.md"), "w") as fp:
        fp.write("\n".join(R) + "\n")
    return 0 if allok else 1

if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
