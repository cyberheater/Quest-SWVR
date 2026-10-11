"""Translate the Star Wars main program to C (docs/PORT.md).

Reads the same analysis the listing generator makes (disasm/emit.py: every
instruction with its ROM decode, its source statement and Atari's comment) and
writes, into c_src/gen/:

    <module>.c     one C function per routine of that source module
    sw_defs.h      every identifier of the listings as a constant
    sw_proto.h     the function prototypes
    registry.c     address -> function, for indirect calls and for the verifier

A routine becomes `void name(void)` working on the global 6809 registers of
sw.h.  The structure comes from Atari's HLL69F source: an IFxx / ELSE / ENDIF
is an if, a BEGIN ... xxEND a loop; any other branch is a goto.  A condition
code is computed only where something reads it; a compare or test followed
directly by its branch becomes one C condition.

A routine the translator cannot express is emitted as a ROM thunk and listed.

    python tools/xlate.py            (from c_src; needs ../disasm/build)
"""
import os, re, sys, collections, subprocess
HERE = os.path.dirname(os.path.abspath(__file__))
CSRC = os.path.normpath(os.path.join(HERE, ".."))
sys.path.insert(0, os.path.normpath(os.path.join(CSRC, "..", "disasm")))
import emit, m6809
from m6809 import INH, IMM8, IMM16, DIR, IDX, EXT, REL8, REL16, REGS, STK

# Two programs: "main" (root and overlay, the default) and "sound" (the sound
# board's 6809: python tools/xlate.py sound).  They are separate C programs with
# separate machine states; the sound one is compiled with SW_SND_PROGRAM (sw.h) and its
# routines carry the prefix s_.
TARGET = "sound" if "sound" in sys.argv[1:] else "main"
SOUND = TARGET == "sound"
GEN = os.path.join(CSRC, "gen_snd" if SOUND else "gen")
IMAGES = ("sound",) if SOUND else ("program", "overlay")
BANK = {"sound": 0} if SOUND else {"program": 0, "overlay": 1}
IMAGE_OF = {"sound": "sound"} if SOUND else {"root": "program", "overlay": "overlay"}
FPREFIX = "s_" if SOUND else ""
DEFS_H, PROTO_H = ("snd_defs.h", "snd_proto.h") if SOUND else ("sw_defs.h", "sw_proto.h")

# checkpoints (see sw.h): where the program can be interrupted.  The translator
# puts one at every routine entry, loop top and label (the machine state there
# is exactly the 6809's at that instruction, with nothing half evaluated).  The
# ones listed here are the extra ones: the head of a loop that waits for the
# interrupt, places where the mainline reads two cells the interrupt writes with
# nothing else in between that fixes when the interrupt came (tests/lockstep.cpp
# lists the interrupts it could not anchor, and the accesses in the way), and
# the ones of the routines written by hand.
CHECKPOINTS = {
    ("sound", 0x7D4C),          # MAIN: the wait for SYNC, 4 ms    (hand_snd/mainline.c)
} if SOUND else {
    ("program", 0x6005),        # WAITFRAME's entry and loop top    (hand/mainline.c)
    ("program", 0x6036),        # MAIN's entry                      (hand/mainline.c)
    ("program", 0x600F),        # WAITFRAME: LSR GMSYNC             (hand/mainline.c)
    ("program", 0x601A),        # WAITFRAME: LDA PT.DLY             (hand/mainline.c)
    ("program", 0x601E),        # WAITFRAME: LDA IN.SW2             (hand/mainline.c)
    ("program", 0x6032),        # LDA VGSYNC / BMI                  (hand/mainline.c)
    ("program", 0x6101),        # LDA R.THMB ... LDA R.FIRE
    ("program", 0xF720),        # HANG: BRA to itself, waiting for the watchdog
}

# the top of a mainline loop the translator expresses itself: sw_pass() there
# (the main program's is in hand/mainline.c)
PASSES = {("sound", 0x7D47)} if SOUND else set()

# instructions that reach hardware through a register (the translator cannot
# see it): the cycle clock is brought up to date before them, as it is before
# every access it can see.  tests/lockstep.cpp reports an access whose time is off.
FLUSH = {("sound", 0x74A3)} if SOUND else {("program", a) for a in (
    0xC276, 0xC2BE, 0xC2EF, 0xC2F7, 0xC340, 0xC3BF, 0xC40B, 0xC562, 0xC56B, 0xC57E, 0xC584, 0xC5CB,
    0xC5D4, 0xC607, 0xC6E4, 0xC6FE, 0xC704,                      # the NOVRAM through X or U
    0xF46C, 0xF470, 0xF4A0, 0xF4C5,                              # the self test's NOVRAM test
    0xFF01, 0xFF12)}                                             # LEDFLSH: the LED latches through U

# routines written by hand in c_src/hand/*.c, each marked there with a
# "/* @hand NAME */" comment: the translator emits nothing for them
HAND = set()
HAND_DIR = os.path.join(CSRC, "hand_snd" if SOUND else "hand")
if os.path.isdir(HAND_DIR):
    for _f in sorted(os.listdir(HAND_DIR)):
        if _f.endswith(".c"):
            HAND |= set(re.findall(r"@hand\s+(\w+)", open(os.path.join(HAND_DIR, _f)).read()))

N, Z, V, C, H = 8, 4, 2, 1, 16
FLAGNAME = {N: "N", Z: "Z", V: "V", C: "C", H: "H"}

class Cannot(Exception):
    """A construct the translator does not express."""

# ---------------------------------------------------------------- names
C_RESERVED = set("""auto break case char const continue default do double else enum extern float
for goto if inline int long register restrict return short signed sizeof static struct switch
typedef union unsigned void volatile while main exit abs div rand time signal remove rename
free malloc abort assert near far pascal cdecl min max errno environ stdin stdout stderr
A B D X Y U S DP CCN CCZ CCV CCC CCH M8 JSR RTS CK EOF NULL TRUE FALSE""".split())

def cname(ident):
    return ident + "_" if ident in C_RESERVED else ident

def fname(ident):
    n = ident.lower()
    if FPREFIX:
        return FPREFIX + n
    return n + "_" if n in C_RESERVED else n

def csafe(s):
    return s.replace("*/", "* /").replace("/*", "/ *")

def to_c(sym):
    """Listing expression -> C expression (same operators; $hex -> 0xhex)."""
    out = re.sub(r"\$([0-9A-Fa-f]+)", lambda m: "0x" + m.group(1), sym)
    # 0x4E-0x5C is one pp-number to GCC and Clang (E- reads as an exponent):
    # keep a hex literal ending in E apart from a following + or -.
    out = re.sub(r"(0x[0-9A-Fa-f]*[eE])([-+])", r"\1 \2", out)
    return re.sub(r"[A-Za-z_][A-Za-z0-9_]*", lambda m: m.group(0) if m.group(0).startswith("0x")
                  else cname(m.group(0)), out)

def simple(s):
    return bool(re.match(r"^[A-Za-z_0-9]+$", s))

def par(s):
    return s if simple(s) else "(" + s + ")"

# ---------------------------------------------------------------- program model
class Insn:
    __slots__ = ("img", "addr", "len", "d", "u", "next", "target", "kind", "macro", "comment",
                 "use", "defs", "live_out", "fuse", "labels", "pops_caller")

class Func:
    def __init__(self, img, addr, name):
        self.img, self.addr, self.name = img, addr, name
        self.insns = []
        self.live_in = 0
        self.live_out = 0
        self.thunk = None
        self.module = None

COND = {"RA": None, "RN": None, "HI": (C | Z), "LS": (C | Z), "CC": C, "CS": C, "NE": Z, "EQ": Z,
        "VC": V, "VS": V, "PL": N, "MI": N, "GE": (N | V), "LT": (N | V), "GT": (N | V | Z), "LE": (N | V | Z)}
COND_C = {"HI": "!(CCC | CCZ)", "LS": "(CCC | CCZ)", "CC": "!CCC", "CS": "CCC", "NE": "!CCZ", "EQ": "CCZ",
          "VC": "!CCV", "VS": "CCV", "PL": "!CCN", "MI": "CCN", "GE": "!(CCN ^ CCV)", "LT": "(CCN ^ CCV)",
          "GT": "!(CCZ | (CCN ^ CCV))", "LE": "(CCZ | (CCN ^ CCV))"}
NEGATE = {"HI": "LS", "LS": "HI", "CC": "CS", "CS": "CC", "NE": "EQ", "EQ": "NE", "VC": "VS", "VS": "VC",
          "PL": "MI", "MI": "PL", "GE": "LT", "LT": "GE", "GT": "LE", "LE": "GT"}

def cond_of(mn):
    mn = m6809.canonical(mn)
    return mn[2:] if mn.startswith("LB") else mn[1:]

REG8 = {"A", "B"}
ARITH8 = {"SUB": N | Z | V | C, "CMP": N | Z | V | C, "SBC": N | Z | V | C, "AND": N | Z | V, "BIT": N | Z | V,
          "LD": N | Z | V, "EOR": N | Z | V, "ADC": N | Z | V | C | H, "OR": N | Z | V, "ADD": N | Z | V | C | H,
          "ST": N | Z | V}
UNARY = {"NEG": N | Z | V | C, "COM": N | Z | V | C, "LSR": N | Z | C, "ROR": N | Z | C, "ASR": N | Z | C,
         "ASL": N | Z | V | C, "ROL": N | Z | V | C, "DEC": N | Z | V, "INC": N | Z | V, "TST": N | Z | V,
         "CLR": N | Z | V | C}

def split_mn(mn):
    """-> (base, register or '') for the accumulator/register instructions."""
    mn = m6809.canonical(mn)
    for b in UNARY:
        if mn == b: return b, ""
        if mn in (b + "A", b + "B"): return b, mn[-1]
    for b in ("SUB", "CMP", "SBC", "AND", "BIT", "LD", "EOR", "ADC", "OR", "ADD", "ST"):
        if mn in (b + "A", b + "B"): return b, mn[-1]
    for b in ("LD", "ST", "CMP", "ADD", "SUB"):
        if mn.startswith(b) and mn[len(b):] in ("D", "X", "Y", "U", "S"): return b + "16", mn[len(b):]
    return mn, ""

def flag_defs(i):
    mn = i.d["mn"]
    b, r = split_mn(mn)
    if b in UNARY: return UNARY[b]
    if b in ARITH8: return ARITH8[b]
    if b in ("LD16", "ST16"): return N | Z | V
    if b in ("CMP16", "ADD16", "SUB16"): return N | Z | V | C
    if mn == "MUL": return Z | C
    if mn == "SEX": return N | Z
    if mn == "DAA": return N | Z | C
    if mn in ("LEAX", "LEAY"): return Z
    if mn in ("ORCC", "ANDCC"): return N | Z | V | C | H
    if mn in ("PULS", "PULU") and i.d["value"] & 1: return N | Z | V | C | H
    return 0

def flag_uses(i):
    mn = i.d["mn"]
    b, r = split_mn(mn)
    if i.d["mode"] in (REL8, REL16) and mn not in ("BSR", "LBSR"):
        return COND.get(cond_of(mn)) or 0
    if b in ("ADC", "SBC", "ROL", "ROR"): return C
    if mn == "DAA": return C | H
    if mn in ("ORCC", "ANDCC"): return N | Z | V | C | H
    if mn in ("PSHS", "PSHU") and i.d["value"] & 1: return N | Z | V | C | H
    if mn in ("TFR", "EXG") and ((i.d["value"] >> 4) == 10 or (i.d["value"] & 15) == 10):
        return N | Z | V | C | H
    return 0

# ---------------------------------------------------------------- load
def load():
    P = {}
    for img in IMAGES:
        ex = {}
        emit.build(img, verbose=False, export=ex)
        P[img] = ex
    return P

def build_model(P):
    insns = {}                       # (img, addr) -> Insn
    for img in IMAGES:
        ex = P[img]
        prev = None
        for u in ex["lines"]:
            if u.kind != "insn":
                prev = None
                continue
            i = Insn()
            i.img, i.addr, i.len, i.u, i.d = img, u.addr, u.len, u, ex["decoded"][u.addr]
            i.next = None
            i.target = None
            i.fuse = None
            i.labels = [nm for nm, _ in ex["labels"].get(u.addr, [])]
            f, n = u.origins[0]
            cst, ccm = emit.callsite(f, n) if f else ("", "")
            i.macro = cst.split()[0].upper() if (u.exp and cst) else ""
            i.comment = ((cst + "  ") if u.exp and cst else "") + ccm
            insns[(img, u.addr)] = i
            if prev is not None and prev.addr + prev.len == u.addr:
                prev.next = (img, u.addr)
            prev = i
    return insns

def target_key(P, i):
    """(img, addr) of a static branch / jump / call target, bank resolved by the
    operand's symbol where the address is in the banked range."""
    d = i.d
    t = d["value"]
    img = i.img
    if 0x6000 <= t < 0x8000:
        # which bank?  the source operand names it
        parts = i.u.text.split(None, 1)
        expr = parts[1].strip() if len(parts) > 1 else ""
        try:
            _, _, used = P[i.img]["R"].render(expr, (P[i.img]["L"]["image"], i.u.module), i.u.radix)
            for ident in used:
                rec = P[i.img]["names"].rec.get(ident)
                if rec and rec["kind"] in ("code", "data") and rec["addr"] == t:
                    img = IMAGE_OF[rec["image"]]
        except emit.Fail:
            pass
    else:
        img = IMAGES[0]
    return (img, t)

def classify(P, insns):
    for i in insns.values():
        mn, mode = i.d["mn"], i.d["mode"]
        if mode in (REL8, REL16):
            i.target = target_key(P, i)
            if mn in ("BSR", "LBSR"): i.kind = "call"
            elif mn in ("BRA", "LBRA"): i.kind = "jump"
            elif mn in ("BRN", "LBRN"): i.kind = "plain"
            else: i.kind = "cond"
        elif mn == "JSR":
            i.kind = "call"
            if mode == EXT or mode == DIR: i.target = target_key(P, i)
        elif mn == "JMP":
            i.kind = "jump"
            if mode == EXT or mode == DIR: i.target = target_key(P, i)
        elif mn in ("RTS", "RTI") or (mn in ("PULS", "PULU") and i.d["value"] & 0x80):
            i.kind = "ret"
        elif mn == "SWI":
            i.kind = "trap"
        else:
            i.kind = "plain"

def partition(P, insns):
    entries = set()
    for img in IMAGES:
        for a in P[img]["entries"]:
            if (img, a) in insns:
                entries.add((img, a))
    for i in insns.values():
        if i.kind == "call" and i.target and i.target in insns:
            entries.add(i.target)
        # "LDS #addr ... JMP ,S": the self test keeps a return address in S
        # where it has no RAM to trust for a stack.  The address is a routine.
        if not SOUND and i.d["mn"] == "LDS" and i.d["mode"] == IMM16 and i.d["value"] >= 0x8000 \
                and ("program", i.d["value"]) in insns:
            entries.add(("program", i.d["value"]))
    order = {img: sorted(a for (g, a) in insns if g == img) for img in IMAGES}

    def owner_map():
        own = {}
        for img in IMAGES:
            cur = None
            prev = None
            for a in order[img]:
                k = (img, a)
                contiguous = prev is not None and insns[prev].next == k
                if k in entries or not contiguous:
                    cur = k
                    entries.add(k)
                own[k] = cur
                prev = k
        return own

    while True:
        own = owner_map()
        new = set()
        for k, i in insns.items():
            if i.kind in ("cond", "jump") and i.target and i.target in insns:
                if own[i.target] != own[k] and i.target not in entries:
                    new.add(i.target)
        if not new:
            break
        entries |= new
    funcs = {}
    for img in IMAGES:
        for a in order[img]:
            k = (img, a)
            if own[k] == k:
                i = insns[k]
                if i.labels:
                    nm = i.labels[0]
                else:
                    nm = "%s%04X" % (P[img]["L"]["prefix"], a)
                f = Func(img, a, nm)
                f.module = i.u.module
                funcs[k] = f
            funcs[own[k]].insns.append(insns[k])
    return funcs, own

# ---------------------------------------------------------------- liveness
ALLF = N | Z | V | C                    # H never crosses a routine boundary (only ADD -> DAA uses it)

def _flow(insns, funcs, own, mode):
    """One backward dataflow over every routine, to a fixpoint.

    mode "pt"   : which flags can pass through a routine unchanged from entry to
                  return (f.pt).  No instruction uses a flag; every return has
                  all flags live; the answer is what is still live at the entry.
    mode "live" : real liveness.  f.live_in = flags the routine reads before
                  setting them; f.live_out = flags some caller reads after it
                  returns.  A flag survives a call only if it can pass through
                  the callee (f.pt)."""
    pt = mode == "pt"
    live_in = {k: 0 for k in insns}
    for f in funcs.values():
        if pt:
            f.pt = 0
        else:
            f.live_in = 0
            f.live_out = 0
    ind_out = 0                              # flags read after some indirect call
    changed = True
    rounds = 0
    while changed and rounds < 400:
        changed = False
        rounds += 1
        for fk, f in funcs.items():
            fout = ALLF if pt else f.live_out

            def other(g2):
                """live-in at the entry of another routine reached by a jump or by
                falling through: it returns to our caller."""
                nonlocal changed
                if pt:
                    return g2.pt
                if g2.live_out | fout != g2.live_out:
                    g2.live_out |= fout
                    changed = True
                return g2.live_in

            def at(t):
                if t is None or t not in insns:
                    return fout
                return live_in[t] if own[t] == fk else other(funcs[own[t]])

            for i in reversed(f.insns):
                k = (i.img, i.addr)
                nxt = i.next if (i.next and i.next in insns) else None
                use = 0 if pt else i.use
                if i.kind == "ret":
                    out = fout
                elif i.kind == "trap":
                    out = 0
                elif i.kind == "jump":
                    out = at(i.target) if i.target else fout
                elif i.kind == "cond":
                    out = (at(nxt) if nxt else 0) | at(i.target)
                else:
                    out = at(nxt) if nxt else 0
                if i.kind == "call":
                    g2 = funcs.get(i.target) if i.target else None
                    if g2 is None or g2.thunk_hint:
                        through, gin = ALLF, 0
                        if not pt:
                            ind_new = ind_out | (out & ALLF)
                            if ind_new != ind_out:
                                ind_out = ind_new
                                changed = True
                    else:
                        through, gin = g2.pt, (0 if pt else g2.live_in)
                        if not pt and (g2.live_out | (out & ALLF)) != g2.live_out:
                            g2.live_out |= out & ALLF
                            changed = True
                    newin = use | gin | (out & through)
                else:
                    newin = use | (out & ~i.defs)
                if not pt and out != i.live_out:
                    i.live_out = out
                    changed = True
                if newin != live_in[k]:
                    live_in[k] = newin
                    changed = True
            li = live_in[(f.img, f.addr)] & ALLF
            if pt:
                if li != f.pt:
                    f.pt = li
                    changed = True
            elif li != f.live_in:
                f.live_in = li
                changed = True
        if not pt:
            # a routine reached through a table returns to whoever made the indirect call
            for f in funcs.values():
                if f.indirect and (f.live_out | ind_out) != f.live_out:
                    f.live_out |= ind_out
                    changed = True
    return live_in

def liveness(P, insns, funcs, own):
    for i in insns.values():
        i.use = flag_uses(i)
        i.defs = flag_defs(i)
        i.live_out = 0
    for (img, a), f in funcs.items():
        f.indirect = a in P[img]["word_vals"]
        f.thunk_hint = False
    _flow(insns, funcs, own, "pt")
    return _flow(insns, funcs, own, "live")

def find_unwinds(insns, funcs, own):
    """A routine that pops its own return address and then returns ("LEAS 2,S"
    straight before RTS, with nothing of its own on the stack) returns to its
    caller's caller.  In C it sets g.unwind and its callers return at once."""
    for i in insns.values():
        i.pops_caller = False
    for f in funcs.values():
        f.unwinds = False
        pushes = any(i.d["mn"] in ("PSHS", "PSHU") or (i.d["mn"] == "LEAS" and i.d["value"] is not None
                                                        and i.d["value"] < 0) for i in f.insns)
        for n, i in enumerate(f.insns[:-1]):
            if (i.d["mn"] == "LEAS" and i.d["post"] is not None and not i.d["post"] & 0x80
                    and (i.d["post"] >> 5) & 3 == 3 and i.d["value"] == 2
                    and f.insns[n + 1].d["mn"] == "RTS" and not pushes):
                i.pops_caller = True
                f.unwinds = True
    changed = True
    while changed:
        changed = False
        for fk, f in funcs.items():
            if f.unwinds:
                continue
            last = f.insns[-1]
            for i in f.insns:
                t = i.target if i.kind in ("jump", "cond") else None
                if t and t in funcs and own.get(t) != fk and funcs[t].unwinds:
                    f.unwinds = True
                    changed = True
            if not f.unwinds and last.kind not in ("ret", "jump", "trap") and last.next in funcs \
                    and funcs[last.next].unwinds:
                f.unwinds = True
                changed = True

# ---------------------------------------------------------------- emission
class Emitter:
    def __init__(self, P, insns, funcs, own, live_in, cycles):
        self.P, self.insns, self.funcs, self.own, self.live_in = P, insns, funcs, own, live_in
        self.cycles = cycles                 # (img, addr) -> (cycles, cycles with a long branch taken)
        self.ckpts = set()                   # every CK() emitted

    # ---- operands
    def sym(self, i, expr):
        """(C text, value) of a source expression, or (None, None)."""
        if not expr or emit.is_number(expr):
            return None, None
        ex = self.P[i.img]
        try:
            s, v, used = ex["R"].render(expr, (ex["L"]["image"], i.u.module), i.u.radix)
        except emit.Fail:
            return None, None
        if not used or "/" in s:
            return None, None
        return to_c(s), v

    def src_expr(self, i):
        parts = i.u.text.split(None, 1)
        srcop = parts[1].strip() if len(parts) > 1 else ""
        mode = i.d["mode"]
        if mode in (IMM8, IMM16):
            return srcop[1:] if srcop.startswith("#") else ""
        if mode == IDX:
            m = emit.IDX_SRC.match(srcop)
            if m:
                e = m.group(2).strip()
                if e in ("-", "--") or m.group(4) or e.upper() in ("A", "B", "D"):
                    return ""
                return e
            return srcop[1:] if srcop.startswith("@") else ""
        return srcop

    def imm(self, i):
        d = i.d
        val = d["value"]
        s, v = self.sym(i, self.src_expr(i))
        if d["mode"] == IMM8:
            if s is not None and (v & 0xFF) == val:
                return par(s) if 0 <= v <= 255 else "(uint8_t)(%s)" % s
            return "0x%02X" % val
        if s is not None and (v & 0xFFFF) == val:
            return par(s) if 0 <= v <= 0xFFFF else "(uint16_t)(%s)" % s
        return "0x%04X" % val

    def static_addr(self, i):
        """(C text of the address, numeric address) for direct / extended."""
        d = i.d
        addr = d["value"] if d["mode"] == EXT else ((i.u.dpage << 8) | d["value"])
        s, v = self.sym(i, self.src_expr(i))
        if s is not None and (v & 0xFFFF) == addr and 0 <= v <= 0xFFFF:
            return s, addr
        return "0x%04X" % addr, addr

    def indexed(self, i):
        """-> (pre statements, ea C expression, post statements, register or None)"""
        d = i.d
        post = d["post"]
        val = d["value"]
        if not post & 0x80:
            reg = m6809.IDX_NAME[(post >> 5) & 3]
            s, v = self.sym(i, self.src_expr(i))
            if s is not None and emit.s16w(v) == val:
                off = par(s) if v <= 0x7FFF else "(int16_t)%s" % par(s)
                return [], "(uint16_t)(%s + %s)" % (reg, off), [], reg
            return [], "(uint16_t)(%s %s %d)" % (reg, "-" if val < 0 else "+", abs(val)), [], reg
        reg = m6809.IDX_NAME[(post >> 5) & 3]
        t = post & 0x0F
        ind = bool(post & 0x10)
        pre, pst = [], []
        if post == 0x9F:
            s, v = self.sym(i, self.src_expr(i))
            ea = s if (s is not None and (v & 0xFFFF) == val) else "0x%04X" % val
            return [], "rd16(%s)" % ea, [], None
        if t == 0x0: ea = reg; pst = ["%s = (uint16_t)(%s + 1);" % (reg, reg)]
        elif t == 0x1: ea = reg; pst = ["%s = (uint16_t)(%s + 2);" % (reg, reg)]
        elif t == 0x2: pre = ["%s = (uint16_t)(%s - 1);" % (reg, reg)]; ea = reg
        elif t == 0x3: pre = ["%s = (uint16_t)(%s - 2);" % (reg, reg)]; ea = reg
        elif t == 0x4: ea = reg
        elif t == 0x5: ea = "(uint16_t)(%s + (int8_t)B)" % reg
        elif t == 0x6: ea = "(uint16_t)(%s + (int8_t)A)" % reg
        elif t == 0xB: ea = "(uint16_t)(%s + D)" % reg
        elif t in (0x8, 0x9):
            sval = val if t == 0x8 else (val - 0x10000 if val & 0x8000 else val)
            s, v = self.sym(i, self.src_expr(i))
            ok = s is not None and ((v & 0xFF) == (sval & 0xFF) if t == 0x8 else (v & 0xFFFF) == (sval & 0xFFFF))
            if ok and t == 0x8 and not -128 <= emit.s16w(v) <= 127:
                ok = False
            if ok:
                off = par(s) if 0 <= v <= 0x7FFF else "(int16_t)%s" % par(s)
                ea = "(uint16_t)(%s + %s)" % (reg, off)
            else:
                ea = "(uint16_t)(%s %s 0x%X)" % (reg, "-" if sval < 0 else "+", abs(sval))
        elif t in (0xC, 0xD):
            s, v = self.sym(i, self.src_expr(i))
            ea = s if (s is not None and (v & 0xFFFF) == val) else "0x%04X" % val
            reg = None
        else:
            raise Cannot("indexed postbyte $%02X" % post)
        if ind:
            ea = "rd16(%s)" % ea
        return pre, ea, pst, reg

    @staticmethod
    def klass(addr):
        if SOUND:
            addr &= 0x7FFF                       # A15 is not decoded
            if 0x1000 <= addr < 0x1080 or 0x2000 <= addr < 0x2800: return "ram"
            if addr < 0x4000: return "hw"        # SOUT/SIN, the 6532, the POKEYs
            return "rom"
        if addr < 0x3000 or 0x4800 <= addr < 0x6000: return "ram"
        if 0x4300 <= addr < 0x4800: return "hw"
        return "rom"

    def mem(self, i, size):
        """Memory operand of a direct / extended / indexed instruction.
        -> dict(pre, post, rd, wr(v), static, reg)"""
        d = i.d
        if d["mode"] in (DIR, EXT):
            s, addr = self.static_addr(i)
            k = self.klass(addr)
            if size == 1:
                if k == "ram": rd, wr = "M8(%s)" % s, lambda v: "M8(%s) = %s;" % (s, v)
                elif k == "hw": rd, wr = "hw_rd8(%s)" % s, lambda v: "hw_wr8(%s, %s);" % (s, v)
                else: rd, wr = "rd8(%s)" % s, lambda v: "wr8(%s, %s);" % (s, v)
            else:
                if k == "hw": rd, wr = "hw_rd16(%s)" % s, lambda v: "hw_wr16(%s, %s);" % (s, v)
                else: rd, wr = "rd16(%s)" % s, lambda v: "wr16(%s, %s);" % (s, v)
            return dict(pre=[], post=[], rd=rd, wr=wr, klass=k, addr=addr, reg=None, s=s)
        pre, ea, pst, reg = self.indexed(i)
        if size == 1:
            rd, wr = "rd8(%s)" % ea, lambda v: "wr8(%s, %s);" % (ea, v)
        else:
            rd, wr = "rd16(%s)" % ea, lambda v: "wr16(%s, %s);" % (ea, v)
        return dict(pre=pre, post=pst, rd=rd, wr=wr, klass="dyn", addr=None, reg=reg, s=ea, ea=ea)

    def value(self, i, size):
        """Source value of a load / arithmetic instruction -> (pre, expr, post, reg)."""
        if i.d["mode"] in (IMM8, IMM16):
            return [], self.imm(i), [], None
        m = self.mem(i, size)
        return m["pre"], m["rd"], m["post"], m["reg"]

    # ---- one function
    def function(self, f):
        out = []
        W = out.append
        self.f = f
        self.temps = set()
        ins = f.insns
        fk = (f.img, f.addr)
        addrs = {i.addr for i in ins}
        P = self.P[f.img]
        # ---- labels wanted
        gotos = set()
        # ---- structure from the HLL69F macros
        opens = collections.defaultdict(list)     # addr -> [text] before the instruction
        closes = collections.defaultdict(int)     # addr -> number of '}' before the instruction
        role = {}                                  # addr -> ('if', T) / ('else', T) / ('loopend', top) / ('cont', top)
        loops = {}                                 # top -> has a CONT
        structured = True
        try:
            stack = []                             # [kind, close address]
            for i in ins:
                a = i.addr
                while stack and stack[-1][0] == "if" and stack[-1][1] == a:
                    stack.pop()
                    closes[a] += 1
                if any(s[0] == "if" and s[1] == a for s in stack):
                    raise Cannot("IF blocks do not nest at $%04X" % a)
                mac = i.macro
                tgt = i.target[1] if (i.target and i.target[0] == f.img) else None
                if not mac or i.d["mode"] not in (REL8, REL16) or tgt is None:
                    continue
                if mac == "ELSE" and i.kind == "jump" and stack and stack[-1][0] == "if" \
                        and stack[-1][1] == a + i.len and tgt > a and tgt in addrs | {ins[-1].addr + ins[-1].len}:
                    stack[-1][1] = tgt
                    role[a] = ("else", tgt)
                elif (mac.startswith("IF") and i.kind == "cond" and tgt > a
                      and (tgt in addrs or tgt == ins[-1].addr + ins[-1].len)):
                    stack.append(["if", tgt])
                    role[a] = ("if", tgt)
                elif (mac.endswith("END") or mac == "LOOP") and tgt <= a and tgt in addrs:
                    role[a] = ("loopend", tgt)
                    loops.setdefault(tgt, False)
                elif mac.endswith("CONT") and tgt <= a and tgt in addrs:
                    role[a] = ("cont", tgt)
                    loops[tgt] = True
            end = ins[-1].addr + ins[-1].len
            while stack and stack[-1][1] == end:
                stack.pop()
                closes[end] += 1
            if stack:
                raise Cannot("unclosed IF")
            # loops must nest with the ifs: check by simulation
            depth_at = {}
            st = []
            loop_bottom = {}
            for a, r in role.items():
                if r[0] == "loopend":
                    loop_bottom[r[1]] = max(loop_bottom.get(r[1], 0), a)
            for a, r in list(role.items()):
                if r[0] == "loopend" and loop_bottom[r[1]] != a:
                    role[a] = ("cont", r[1])       # an inner xxEND to the same top: a continue
                    loops[r[1]] = True
            for a, r in role.items():
                if r[0] == "cont" and r[1] not in loop_bottom:
                    raise Cannot("CONT without a loop")
            for i in ins:
                a = i.addr
                for _ in range(closes.get(a, 0)):
                    if not st or st.pop() != "if":
                        raise Cannot("brace nesting at $%04X" % a)
                if a in loop_bottom:
                    st.append("loop")
                r = role.get(a)
                if r and r[0] == "if":
                    st.append("if")
                elif r and r[0] == "else":
                    if not st or st[-1] != "if":
                        raise Cannot("ELSE nesting")
                elif r and r[0] == "loopend":
                    if not st or st.pop() != "loop":
                        raise Cannot("loop nesting at $%04X" % a)
                elif r and r[0] == "cont":
                    if "loop" not in st:
                        raise Cannot("continue outside its loop")
                    # continue must refer to the innermost loop
                    inner = [x for x in st if x == "loop"]
                    tops = sorted(t for t in loop_bottom if t <= a <= loop_bottom[t])
                    if not tops or max(tops) != r[1]:
                        raise Cannot("continue to an outer loop")
        except Cannot:
            structured = False
            role, closes, loops, loop_bottom = {}, collections.defaultdict(int), {}, {}

        gotos_end = set()
        # ---- which instructions need a label
        for i in ins:
            if i.kind in ("cond", "jump") and i.target and i.target[0] == f.img and i.target[1] in addrs \
                    and self.own[i.target] == fk and i.addr not in role:
                gotos.add(i.target[1])

        def label(a):
            for nm in self.insns[(f.img, a)].labels:
                return "l_" + nm.lower()
            return "l_%04x" % a

        # ---- fusion of a flag setter with the branch after it
        self.fused = {}
        for n, i in enumerate(ins[:-1]):
            j = ins[n + 1]
            if j.addr != i.addr + i.len or j.kind != "cond" or j.addr in gotos or j.labels and j.addr in gotos:
                continue
            if any(k.kind in ("cond", "jump") and k.target == (f.img, j.addr) for k in ins):
                continue
            cc = cond_of(j.d["mn"])
            need = COND[cc]
            if not i.defs or need & ~i.defs:
                continue
            if j.live_out & i.defs:
                continue                      # someone else still wants these flags
            c = self.fuse_cond(i, cc)
            if c is not None:
                self.fused[j.addr] = i
                if i.fuse is None:
                    i.fuse = True

        body = []
        ind = [1]
        def E(s, i=None, cm=None):
            pad = "    " * ind[0]
            if i is not None and cm is None:
                cm = "L%04X  %s" % (i.addr, i.comment) if i.comment else "L%04X" % i.addr
            if cm:
                line = "%s%s" % (pad, s)
                body.append("%-52s /* %s */" % (line, csafe(cm)) if len(line) < 52 else "%s /* %s */" % (line, csafe(cm)))
            else:
                body.append(pad + s)

        self.E = E
        # ---- the cycle clock: CYC(n) charges the instructions since the last
        # CYC, and stands before anything that can see the time or leaves the
        # straight line - a hardware access, SEI/CLI, a checkpoint, a branch, a
        # call, a return, a label, the end of a block.
        pend = [0]
        def flush(at=None):
            if pend[0]:
                line = "    " * ind[0] + "CYC(%d);" % pend[0]
                if at is None: body.append(line)
                else: body.insert(at, line)
                pend[0] = 0
        cyc = self.cycles

        for i in ins:
            a = i.addr
            if closes.get(a, 0) or a in gotos or a == f.addr or a in loop_bottom or (f.img, a) in CHECKPOINTS \
                    or (f.img, a) in PASSES:
                flush()
            for _ in range(closes.get(a, 0)):
                ind[0] -= 1
                E("}")
            if a in gotos or (a == f.addr and any(k.kind in ("cond", "jump") and k.target == fk and k.addr not in role
                                                   for k in ins)):
                if a == f.addr:
                    gotos.add(a)
                body.append("%s:;" % label(a))
            if a in loop_bottom:
                E("for (;;) {" if (loops.get(a) or self.insns[(f.img, loop_bottom[a])].kind == "jump") else "do {")
                ind[0] += 1
            if (f.img, a) in PASSES:
                E("sw_pass(0x%04X);" % a)
            if (f.img, a) in CHECKPOINTS or a == f.addr or a in gotos or a in loop_bottom:
                E("CK(0x%04X);" % a)
                self.ckpts.add((f.img, a))
            for x in P["block_comments"].get(a, []) if a != f.addr else []:
                if emit.words(x):
                    E("/* %s */" % csafe(emit.words(x)))
            r = role.get(a)
            lo, hi = cyc[(f.img, a)]
            if r or i.kind in ("cond", "jump", "call", "ret", "trap"):
                # the instruction's own cycles are charged before control leaves
                pend[0] += lo
                if hi != lo:                      # a long conditional branch: one more when taken
                    if hi != lo + 1 or i.kind != "cond":
                        raise Cannot("cycle count of $%04X depends on the flags" % a)
                    body.append("    " * ind[0] + "CYC(%d + ((%s) ? 1 : 0));" % (pend[0], self.cond(i)))
                    pend[0] = 0
                else:
                    flush()
                if r:
                    self.branch_structured(i, r, loops, loop_bottom, ind, E)
                else:
                    self.insn(i, label, fk, addrs)
            else:
                n0 = len(body)
                self.insn(i, label, fk, addrs)
                if any(("hw_" in x or "sw_sei" in x or "sw_cli" in x) for x in body[n0:]) or (f.img, a) in FLUSH:
                    flush(n0)                     # the time this access sees
                pend[0] += lo
        end = ins[-1].addr + ins[-1].len
        flush()
        for _ in range(closes.get(end, 0)):
            ind[0] -= 1
            E("}")
        last = ins[-1]
        if last.kind not in ("ret", "jump", "trap") or closes.get(end) or end in gotos_end:
            nxt = last.next
            if nxt and nxt in self.funcs:
                E("%s();" % fname(self.funcs[nxt].name), cm="falls into %s" % self.funcs[nxt].name)
            elif nxt:
                raise Cannot("falls into the middle of another routine")
            else:
                raise Cannot("runs off the end at $%04X" % end)

        # ---- header
        desc = P["docs"].get(f.name)
        if not desc:
            blk = [emit.words(x) for x in P["block_comments"].get(f.addr, []) if emit.words(x)]
            cc = [c for c, _ in P["caller_comments"].get(f.addr, collections.Counter()).most_common(1)]
            tc = [c for c, _ in P["table_comments"].get(f.addr, collections.Counter()).most_common(1)]
            desc = "\n".join(blk) or (cc[0] if cc else "") or (tc[0] if tc else "")
        W("/* %s ($%04X%s)%s" % (f.name, f.addr, ", bank 1" if f.img == "overlay" else "",
                                 (" - " + csafe(desc.split("\n")[0])) if desc else ""))
        for x in (desc.split("\n")[1:] if desc else []):
            W(" *   " + csafe(x))
        fl = "".join(FLAGNAME[b] for b in (N, Z, V, C) if f.live_out & b)
        fi = "".join(FLAGNAME[b] for b in (N, Z, V, C, H) if f.live_in & b)
        if fi or fl:
            W(" * Condition codes%s%s." % ((" in: " + fi) if fi else "", ((";" if fi else "") + " out: " + fl) if fl else ""))
        if not structured:
            W(" * (branches kept as gotos: the macro structure does not map to C blocks here)")
        W(" */")
        W("void %s(void)" % fname(f.name))
        W("{")
        if self.temps:
            decl = []
            if "t8" in self.temps: decl.append("uint8_t t8;")
            if "t16" in self.temps: decl.append("uint16_t t16;")
            if "ea" in self.temps: decl.append("uint16_t ea;")
            W("    " + " ".join(decl))
        out += body
        W("}")
        return out

    # ---- conditions
    def fuse_cond(self, i, cc):
        """C condition for branch condition cc taken right after instruction i,
        or None.  Sets up self.fuse_expr[i.addr] for the instruction's emission."""
        mn = i.d["mn"]
        b, r = split_mn(mn)
        mode = i.d["mode"]
        if b in ("CMP", "CMP16"):
            reg = r
            bits = 8 if b == "CMP" else 16
            if cc in ("VC", "VS"):
                return None                       # before any side effect on i.fuse
            try:
                pre, e, pst, ireg = self.value(i, 1 if bits == 8 else 2)
            except Cannot:
                return None
            if pre or pst or "hw_rd" in e or e.startswith("rd"):
                # read once, before the side effects
                t = "t8" if bits == 8 else "t16"
                self.temps.add(t)
                self.pending_cmp = None
                i.fuse = ("cmptemp", t)
                e2 = t
            else:
                e2 = e
            ops = {"EQ": "==", "NE": "!=", "HI": ">", "CC": ">=", "CS": "<", "LS": "<="}
            if cc in ops:
                return "%s %s %s" % (reg, ops[cc], e2)
            sops = {"GE": ">=", "LT": "<", "GT": ">", "LE": "<="}
            if cc in sops:
                return "(int%d_t)%s %s (int%d_t)%s" % (bits, reg, sops[cc], bits, par(e2))
            # MI / PL: the sign of the difference (not a signed compare: no overflow term)
            sign = "((%s - %s) & %s)" % (reg, par(e2), "0x80" if bits == 8 else "0x8000")
            return sign if cc == "MI" else "!" + sign
        if cc not in ("EQ", "NE", "MI", "PL"):
            return None
        res = None
        if b in ("LD", "ADD", "ADC", "SUB", "SBC", "AND", "OR", "EOR") and r: res, bits = r, 8
        elif b == "ST" and r: res, bits = r, 8
        elif b in ("LD16", "ADD16", "SUB16", "ST16"): res, bits = r, 16
        elif b in UNARY and r and b != "CLR": res, bits = r, 8
        elif b in UNARY and not r and b != "CLR":
            try:
                m = self.mem(i, 1)
            except Cannot:
                return None
            if m["klass"] == "ram":
                res, bits = m["rd"], 8          # a RAM cell can be read back
                i.fuse = ("ram",)
            else:
                self.temps.add("t8")
                res, bits = "t8", 8
                i.fuse = ("t8",)
        elif b == "BIT":
            self.temps.add("t8")
            res, bits = "t8", 8
        elif mn in ("LEAX", "LEAY") and cc in ("EQ", "NE"): res, bits = mn[-1], 16
        if res is None:
            return None
        if res == "S":
            return None
        if cc == "EQ": return "%s == 0" % res
        if cc == "NE": return "%s != 0" % res
        mask = "0x80" if bits == 8 else "0x8000"
        return "(%s & %s)" % (res, mask) if cc == "MI" else "!(%s & %s)" % (res, mask)

    def cond(self, i, neg=False):
        """C condition under which the branch is taken (neg: not taken)."""
        cc = cond_of(i.d["mn"])
        if neg:
            cc = NEGATE[cc]
        if i.addr in self.fused:
            return self.fuse_cond(self.fused[i.addr], cc)
        return COND_C[cc]

    def branch_structured(self, i, r, loops, loop_bottom, ind, E):
        kind, tgt = r
        if kind == "if":
            E("if (%s) {" % self.cond(i, neg=True), i)
            ind[0] += 1
        elif kind == "else":
            ind[0] -= 1
            E("} else {", i)
            ind[0] += 1
        elif kind == "loopend":
            ind[0] -= 1
            top = tgt
            if i.kind == "jump":
                E("}", i)
            elif loops.get(top):
                ind[0] += 1
                E("if (%s) continue;" % self.cond(i), i)
                E("break;")
                ind[0] -= 1
                E("}")
            else:
                E("} while (%s);" % self.cond(i), i)
        elif kind == "cont":
            E("if (%s) continue;" % self.cond(i) if i.kind == "cond" else "continue;", i)

    # ---- instructions
    def flags_live(self, i):
        return bool(i.defs & i.live_out) and not (i.fuse and True and i.fuse is True and False)

    def insn(self, i, label, fk, addrs):
        E = self.E
        d = i.d
        mn = m6809.canonical(d["mn"])
        mode = d["mode"]
        b, r = split_mn(mn)
        want = bool(i.defs & i.live_out)         # some flag this instruction sets is read later
        if i.fuse and not (i.defs & i.live_out & ~self.fused_need(i)):
            want = False
        f = self.f

        # ---------- flow
        if i.kind in ("cond", "jump") and mode in (REL8, REL16, EXT, DIR) and mn != "JSR":
            t = i.target
            if i.kind == "cond":
                c = self.cond(i)
                if t in self.insns and self.own[t] == fk:
                    E("if (%s) goto %s;" % (c, label(t[1])), i)
                elif t in self.funcs:
                    E("if (%s) { %s(); return; }" % (c, fname(self.funcs[t].name)), i)
                else:
                    raise Cannot("branch to $%04X, not code" % t[1])
            else:
                if t in self.insns and self.own[t] == fk:
                    E("goto %s;" % label(t[1]), i)
                elif t in self.funcs:
                    E("%s(); return;" % fname(self.funcs[t].name), i)
                else:
                    raise Cannot("jump to $%04X, not code" % t[1])
            return
        if mn == "JMP":                               # indexed
            pre, ea, pst, reg = self.indexed(i)
            if reg == "S" and ea != "S":
                raise Cannot("JMP through the stack pointer")
            for x in pre: E(x)
            E("call_rom(%s); return;" % ea, i)
            return
        if i.kind == "call":
            if i.target is not None:
                if i.target not in self.funcs:
                    raise Cannot("call to $%04X, not a routine" % i.target[1])
                E("JSR(%s);" % fname(self.funcs[i.target].name), i)
                if self.funcs[i.target].unwinds:
                    E("if (g.unwind) { g.unwind = 0; return; }",
                      cm="%s can pop this routine's return too" % self.funcs[i.target].name)
            else:
                pre, ea, pst, reg = self.indexed(i)
                for x in pre: E(x)
                self.temps.add("ea")
                E("ea = %s;" % ea, i)
                for x in pst: E(x)
                E("S = (uint16_t)(S - 2); call_rom(ea);")
            return
        if mn == "RTS":
            E("RTS;", i); return
        if mn == "RTI":
            E("return;", i); return
        if mn == "SWI":
            E("sw_swi(0x%04X);" % i.addr, i); return
        if mn in ("BRN", "LBRN", "NOP"):
            E("/* %s */" % mn, i); return

        # ---------- stack, transfers
        if mn in ("PSHS", "PULS"):
            post = d["value"]
            if mn == "PSHS":
                if post & 0x80: raise Cannot("PSHS PC")
                seq = [(0x40, "push16(U);"), (0x20, "push16(Y);"), (0x10, "push16(X);"), (0x08, "push8(DP);"),
                       (0x04, "push8(B);"), (0x02, "push8(A);"), (0x01, "push8(cc_pack());")]
            else:
                seq = [(0x01, "cc_unpack(pull8());"), (0x02, "A = pull8();"), (0x04, "B = pull8();"),
                       (0x08, "DP = pull8();"), (0x10, "X = pull16();"), (0x20, "Y = pull16();"),
                       (0x40, "U = pull16();")]
            first = True
            for bit, s in seq:
                if post & bit:
                    E(s, i if first else None)
                    first = False
            if mn == "PULS" and post & 0x80:
                E("RTS;", i if first else None)
            return
        if mn in ("PSHU", "PULU"):
            raise Cannot(mn)
        if mn in ("TFR", "EXG"):
            a, c = d["value"] >> 4, d["value"] & 15
            nm = {0: "D", 1: "X", 2: "Y", 3: "U", 4: "S", 8: "A", 9: "B", 11: "DP"}
            if a not in nm or c not in nm or (a < 8) != (c < 8):
                raise Cannot("%s %s" % (mn, m6809.fmt_regs(d["value"])))
            if mn == "TFR":
                E("%s = %s;" % (nm[c], nm[a]), i)
            else:
                t = "t8" if a >= 8 else "t16"
                self.temps.add(t)
                E("%s = %s; %s = %s; %s = %s;" % (t, nm[a], nm[a], nm[c], nm[c], t), i)
            return
        if mn in ("ORCC", "ANDCC"):
            v = d["value"]
            if mn == "ORCC":
                parts = []
                if v & 0x10: parts.append("sw_sei();")
                if v & 0x01: parts.append("CCC = 1;")
                if v & 0x02: parts.append("CCV = 1;")
                if v & 0x04: parts.append("CCZ = 1;")
                if v & 0x08: parts.append("CCN = 1;")
                if v & 0xE0 and v & 0xE0 != 0: raise Cannot("ORCC #$%02X" % v)
                E(" ".join(parts) or "/* ORCC #0 */", i)
            else:
                parts = []
                if not v & 0x10: parts.append("sw_cli();")
                if not v & 0x01: parts.append("CCC = 0;")
                if not v & 0x02: parts.append("CCV = 0;")
                if not v & 0x04: parts.append("CCZ = 0;")
                if not v & 0x08: parts.append("CCN = 0;")
                E(" ".join(parts) or "/* ANDCC #$FF */", i)
            return
        if mn == "ABX":
            E("X = (uint16_t)(X + B);", i); return
        if mn == "MUL":
            E("mul_ab();" if want else "D = (uint16_t)(A * B);", i); return
        if mn == "SEX":
            E("sex_b();" if want else "A = (B & 0x80) ? 0xFF : 0x00;", i); return
        if mn == "DAA":
            E("daa_a();", i); return
        if mn == "LEAS" and getattr(i, "pops_caller", False):
            E("S = (uint16_t)(S + 2); g.unwind = 1;", i)
            return
        if mn in ("LEAX", "LEAY", "LEAU", "LEAS"):
            reg = mn[-1]
            pre, ea, pst, ireg = self.indexed(i)
            if pre or pst:
                self.temps.add("ea")
                for x in pre: E(x)
                E("ea = %s;" % ea, i)
                for x in pst: E(x)
                E("%s = ea;" % reg)
            else:
                E("%s = %s;" % (reg, ea), i)
            if want and reg in ("X", "Y"):
                E("CCZ = (%s == 0);" % reg)
            return

        # ---------- register unary
        if b in UNARY and r:
            R = r
            plain = {"NEG": "%s = (uint8_t)(0 - %s);", "COM": "%s = (uint8_t)~%s;", "LSR": "%s = (uint8_t)(%s >> 1);",
                     "ASR": "%s = (uint8_t)((%s >> 1) | (%s & 0x80));", "ASL": "%s = (uint8_t)(%s << 1);",
                     "DEC": "%s = (uint8_t)(%s - 1);", "INC": "%s = (uint8_t)(%s + 1);"}
            fn = {"NEG": "neg8", "COM": "com8", "LSR": "lsr8", "ROR": "ror8", "ASR": "asr8", "ASL": "asl8",
                  "ROL": "rol8", "DEC": "dec8", "INC": "inc8"}
            if b == "TST":
                E("nz8(%s);" % R if want else "/* TST%s */" % R, i)
            elif b == "CLR":
                E("%s = 0;%s" % (R, " clrf();" if want else ""), i)
            elif want or b in ("ROL", "ROR"):
                E("%s = %s(%s);" % (R, fn[b], R), i)
            else:
                E(plain[b] % ((R,) * plain[b].count("%s")), i)
            return
        # ---------- memory unary
        if b in UNARY and not r:
            m = self.mem(i, 1)
            fn = {"NEG": "neg8", "COM": "com8", "LSR": "lsr8", "ROR": "ror8", "ASR": "asr8", "ASL": "asl8",
                  "ROL": "rol8", "DEC": "dec8", "INC": "inc8"}
            latch = not SOUND and m["klass"] == "hw" and 0x4680 <= m["addr"] < 0x46A0
            for x in m["pre"]: E(x)
            usetemp = isinstance(i.fuse, tuple) and i.fuse[0] == "t8"
            if b == "TST":
                if usetemp:
                    E("t8 = %s;" % m["rd"], i)
                elif want:
                    E("nz8(%s);" % m["rd"], i)
                elif m["klass"] in ("hw", "dyn"):
                    E("(void)%s;" % m["rd"], i)
                elif i.comment:
                    E("/* TST %s */" % csafe(m["s"]), i)
            elif b == "CLR":
                # the 6809 reads the cell before clearing it; the oracle's core
                # only writes, and nothing the program clears minds either way
                E(m["wr"]("0") + (" clrf();" if want else ""), i)
            else:
                src = "0" if latch else m["rd"]
                if want or b in ("ROL", "ROR") or usetemp:
                    val = "%s(%s)" % (fn[b], src)
                else:
                    val = {"NEG": "(uint8_t)(0 - %s)", "COM": "(uint8_t)~%s", "LSR": "(uint8_t)(%s >> 1)",
                           "ASR": "(uint8_t)((%s >> 1) | (%s & 0x80))", "ASL": "(uint8_t)(%s << 1)",
                           "DEC": "(uint8_t)(%s - 1)", "INC": "(uint8_t)(%s + 1)"}[b]
                    val = val % ((src,) * val.count("%s"))
                if usetemp or (m["klass"] in ("dyn", "hw") and src.count("(") and b == "ASR"):
                    self.temps.add("t8")
                    E("t8 = %s;" % ("%s(%s)" % (fn[b], src)), i)
                    E(m["wr"]("t8"))
                else:
                    E(m["wr"](val), i)
            for x in m["post"]: E(x)
            return

        # ---------- 8-bit accumulator
        if b in ARITH8 and r:
            R = r
            if b == "ST":
                m = self.mem(i, 1)
                for x in m["pre"]: E(x)
                E(m["wr"](R), i)
                for x in m["post"]: E(x)
                if want: E("nz8(%s);" % R)
                return
            pre, e, pst, ireg = self.value(i, 1)
            for x in pre: E(x)
            fuse_tmp = isinstance(i.fuse, tuple)
            if b == "LD":
                E("%s = %s;" % (R, e), i)
                if want: E("nz8(%s);" % R)
            elif b == "CMP":
                if fuse_tmp:
                    E("%s = %s;" % (i.fuse[1], e), i)
                elif i.fuse:
                    if i.comment: E("/* CMP%s %s */" % (R, csafe(e)), i)
                else:
                    E("cmp8(%s, %s);" % (R, e), i)
            elif b == "BIT":
                if i.fuse:
                    E("t8 = (uint8_t)(%s & %s);" % (R, e), i)
                else:
                    E("nz8((uint8_t)(%s & %s));" % (R, e), i)
            elif b in ("ADC", "SBC"):
                E("%s = %s(%s, %s);" % (R, {"ADC": "adc8", "SBC": "sbc8"}[b], R, e), i)
            elif want:
                E("%s = %s(%s, %s);" % (R, {"ADD": "add8", "SUB": "sub8", "AND": "and8", "OR": "or8", "EOR": "eor8"}[b],
                                         R, e), i)
            else:
                op = {"ADD": "%s = (uint8_t)(%s + %s);", "SUB": "%s = (uint8_t)(%s - %s);", "AND": "%s &= %s;",
                      "OR": "%s |= %s;", "EOR": "%s ^= %s;"}[b]
                E(op % ((R, R, e) if op.count("%s") == 3 else (R, e)), i)
            for x in pst: E(x)
            return

        # ---------- 16-bit
        if b in ("LD16", "ST16", "CMP16", "ADD16", "SUB16"):
            R = r
            if b == "ST16":
                m = self.mem(i, 2)
                for x in m["pre"]: E(x)
                E(m["wr"](R), i)
                for x in m["post"]: E(x)
                if want: E("nz16(%s);" % R)
                return
            pre, e, pst, ireg = self.value(i, 2)
            for x in pre: E(x)
            fuse_tmp = isinstance(i.fuse, tuple)
            if b == "LD16":
                if ireg == R and pst:
                    self.temps.add("t16")
                    E("t16 = %s;" % e, i)
                    for x in pst: E(x)
                    pst = []
                    E("%s = t16;" % R)
                else:
                    E("%s = %s;" % (R, e), i)
                if want: E("nz16(%s);" % R)
            elif b == "CMP16":
                if fuse_tmp:
                    E("%s = %s;" % (i.fuse[1], e), i)
                elif i.fuse:
                    if i.comment: E("/* CMP%s %s */" % (R, csafe(e)), i)
                else:
                    E("cmp16(%s, %s);" % (R, e), i)
            elif want:
                E("%s = %s(%s, %s);" % (R, "add16" if b == "ADD16" else "sub16", R, e), i)
            else:
                E("%s = (uint16_t)(%s %s %s);" % (R, R, "+" if b == "ADD16" else "-", e), i)
            for x in pst: E(x)
            return
        raise Cannot("instruction %s" % d["mn"])

    def fused_need(self, i):
        return i.defs

    def fused_res(self, i):
        b, r = split_mn(i.d["mn"])
        return "t8" if (b in UNARY and not r) or b == "BIT" else r

# ---------------------------------------------------------------- output
HEADER = """/* %s - generated by c_src/tools/xlate.py from Atari's %s.MAC as it stands in
 * the ROM (disasm/starwars_%s_rom.asm).  Do not edit: fix the translator, or
 * replace a routine in c_src/hand/.
 *
 * %s
 */
%s#include "../sw.h"
#include "%s"
#include "%s"
"""

def chunks(seq, n):
    return [seq[k:k + n] for k in range(0, len(seq), n)] or [[]]

def cycle_table():
    """(img, addr) -> (cycles, cycles when a long conditional branch is taken),
    measured on the oracle's own 6809 core by tests/cyctab.exe."""
    exe = os.path.join(CSRC, "tests", "cyctab.exe")
    if not os.path.exists(exe):
        sys.exit("!! missing %s (build_all.bat tools)" % exe)
    out = os.path.join(GEN, "cycles.txt")
    p = subprocess.run([exe, TARGET, os.path.join(GEN, "insns.txt"), out], cwd=CSRC, capture_output=True, text=True)
    if p.returncode:
        sys.exit("!! cyctab failed: " + p.stdout + p.stderr)
    img = {v: k for k, v in BANK.items()}
    t = {}
    for l in open(out):
        b, a, lo, hi = l.split()
        t[(img[int(b)], int(a, 16))] = (int(lo), int(hi))
    return t

def main():
    os.makedirs(GEN, exist_ok=True)
    P = load()
    insns = build_model(P)
    classify(P, insns)
    funcs, own = partition(P, insns)
    live_in = liveness(P, insns, funcs, own)
    find_unwinds(insns, funcs, own)
    allf = [funcs[k] for k in sorted(funcs, key=lambda k: (IMAGES.index(k[0]), k[1]))]
    with open(os.path.join(GEN, "insns.txt"), "w", newline="\n") as fp:
        for f in allf:
            for i in f.insns:
                fp.write("%d %04X %04X\n" % (BANK[f.img], i.addr, f.addr))
    cycles = cycle_table()
    em = Emitter(P, insns, funcs, own, live_in, cycles)

    by_mod = collections.OrderedDict()
    thunks = []
    ngoto = 0
    for fk in sorted(funcs, key=lambda k: (IMAGES.index(k[0]), k[1])):
        f = funcs[fk]
        if f.name in HAND:
            continue
        for i in f.insns:
            i.fuse = None
        try:
            text = em.function(f)
            if any("branches kept as gotos" in l for l in text[:8]):
                ngoto += 1
        except Cannot as e:
            f.thunk = str(e)
            thunks.append(f)
            text = ["/* %s ($%04X%s) - not translated: %s.  Runs as a ROM thunk. */" % (
                        f.name, f.addr, ", bank 1" if f.img == "overlay" else "", csafe(str(e))),
                    "void %s(void)" % fname(f.name), "{",
                    "    sw_thunk(0x%04X, %d);" % (f.addr, BANK[f.img]), "}"]
        by_mod.setdefault((f.img, f.module), []).append(text)

    files = []
    for (img, mod), texts in by_mod.items():
        fn = "%s%s.c" % (mod.lower(), "_ovl" if img == "overlay" and mod in ("WSPROG",) else "")
        title = emit.title_of(mod)
        with open(os.path.join(GEN, fn), "w", newline="\n") as fp:
            fp.write(HEADER % (fn, mod, img, csafe(title) or mod, "#define SW_SND_PROGRAM\n" if SOUND else "", DEFS_H, PROTO_H))
            for t in texts:
                fp.write("\n" + "\n".join(t) + "\n")
        files.append(fn)

    # ---- identifiers
    names = P[IMAGES[0]]["names"]
    defs = {}
    for (key, val), ident in names.ident.items():
        defs[cname(ident)] = val
    for img in IMAGES:
        for a, labs in P[img]["labels"].items():
            for nm, rec in labs:
                defs.setdefault(cname(nm), a)
    with open(os.path.join(GEN, DEFS_H), "w", newline="\n") as fp:
        fp.write("/* sw_defs.h - generated by c_src/tools/xlate.py: every identifier of the\n"
                 " * listings (Atari's names) with its value.  A RAM or ROM name is its address. */\n"
                 "#ifndef SW_DEFS_H\n#define SW_DEFS_H\n\n")
        for nm in sorted(defs, key=lambda n: (defs[n], n)):
            fp.write("#define %-18s 0x%04X\n" % (nm, defs[nm]))
        fp.write("\n#endif\n")
    with open(os.path.join(GEN, PROTO_H), "w", newline="\n") as fp:
        fp.write("/* sw_proto.h - generated by c_src/tools/xlate.py: one function per routine. */\n"
                 "#ifndef SW_PROTO_H\n#define SW_PROTO_H\n\n")
        for f in allf:
            fp.write("void %s(void);%s/* %s $%04X%s */\n" % (
                fname(f.name), " " * max(1, 24 - len(fname(f.name))), f.name, f.addr,
                " bank 1" if f.img == "overlay" else ""))
        fp.write("\n#endif\n")
    with open(os.path.join(GEN, "registry.c"), "w", newline="\n") as fp:
        fp.write("/* registry.c - generated by c_src/tools/xlate.py: every routine by address. */\n" +
                 ("#define SW_SND_PROGRAM\n" if SOUND else "") + '#include "../sw.h"\n#include "%s"\n\n' % PROTO_H +
                 "const sw_routine sw_routines[] = {\n")
        for f in allf:
            fp.write("    { 0x%04X, %d, 0x%X, %d, %s, \"%s\" },\n" % (
                f.addr, BANK[f.img], f.live_out & 15, 1 if f.thunk else 0, fname(f.name), f.name))
        fp.write("};\nconst unsigned sw_nroutines = sizeof sw_routines / sizeof sw_routines[0];\n\n"
                 "/* the CK() checkpoints: bank << 16 | address */\n"
                 "const uint32_t sw_checkpoints[] = { %s };\n"
                 "const unsigned sw_ncheckpoints = sizeof sw_checkpoints / sizeof sw_checkpoints[0];\n" %
                 ",\n    ".join(", ".join("0x%05X" % (BANK[i] << 16 | a) for i, a in row)
                               for row in chunks(sorted(CHECKPOINTS | em.ckpts), 12)))
    with open(os.path.join(GEN, "routines.txt"), "w", newline="\n") as fp:
        for f in allf:
            fp.write("%d %04X %s %s %d\n" % (BANK[f.img], f.addr, f.name, f.module, len(f.insns)))
    with open(os.path.join(GEN, "files.txt"), "w", newline="\n") as fp:
        fp.write("\n".join(sorted(set(files)) + ["registry.c"]) + "\n")

    ninsn = sum(len(f.insns) for f in allf)
    print("xlate: %d routines, %d instructions, into %d files" % (len(allf), ninsn, len(set(files))))
    print("  translated %d (%d keep their branches as gotos), thunks %d, by hand %d" % (
        len(allf) - len(thunks) - len([f for f in allf if f.name in HAND]), ngoto, len(thunks),
        len([f for f in allf if f.name in HAND])))
    reasons = collections.Counter(f.thunk for f in thunks)
    for r, n in reasons.most_common():
        print("    %3d  %s: %s" % (n, r, " ".join(f.name for f in thunks if f.thunk == r)[:100]))
    return 0

if __name__ == "__main__":
    sys.exit(main())
