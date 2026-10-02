"""MC6809 instruction set as data: opcode tables, the indexed postbyte, register
codes, and a decoder.  Documented opcodes only.

Shared by the assembler (macasm69.py, to encode) and by the listing tools (to
decode).  Mnemonics are Motorola's, with the spellings Atari's MAC69 sources use
accepted as aliases (ORA/ORB, ASL/LSL, BHS/BLO, CCR/DPR register names).
"""

# addressing modes
INH, IMM8, IMM16, DIR, IDX, EXT, REL8, REL16, REGS, STK = range(10)
MODE_NAME = ["inh", "imm8", "imm16", "dir", "idx", "ext", "rel8", "rel16", "regs", "stk"]

# TAB[mnemonic][mode] = opcode (page prefix in the high byte: 0x10xx / 0x11xx)
TAB = {}

def _add(mn, mode, op):
    TAB.setdefault(mn, {})[mode] = op

# memory read-modify-write group: direct $0x, indexed $6x, extended $7x, A $4x, B $5x
for lo, mn in [(0x0, "NEG"), (0x3, "COM"), (0x4, "LSR"), (0x6, "ROR"), (0x7, "ASR"),
               (0x8, "ASL"), (0x9, "ROL"), (0xA, "DEC"), (0xC, "INC"), (0xD, "TST"),
               (0xF, "CLR")]:
    _add(mn, DIR, 0x00 | lo)
    _add(mn, IDX, 0x60 | lo)
    _add(mn, EXT, 0x70 | lo)
    _add(mn + "A", INH, 0x40 | lo)
    _add(mn + "B", INH, 0x50 | lo)
_add("JMP", DIR, 0x0E); _add("JMP", IDX, 0x6E); _add("JMP", EXT, 0x7E)

for mn, op in [("NOP", 0x12), ("SYNC", 0x13), ("DAA", 0x19), ("SEX", 0x1D),
               ("RTS", 0x39), ("ABX", 0x3A), ("RTI", 0x3B), ("MUL", 0x3D),
               ("SWI", 0x3F), ("SWI2", 0x103F), ("SWI3", 0x113F)]:
    _add(mn, INH, op)

_add("ORCC", IMM8, 0x1A); _add("ANDCC", IMM8, 0x1C); _add("CWAI", IMM8, 0x3C)
_add("EXG", REGS, 0x1E); _add("TFR", REGS, 0x1F)
_add("PSHS", STK, 0x34); _add("PULS", STK, 0x35)
_add("PSHU", STK, 0x36); _add("PULU", STK, 0x37)
_add("LEAX", IDX, 0x30); _add("LEAY", IDX, 0x31)
_add("LEAS", IDX, 0x32); _add("LEAU", IDX, 0x33)

BRANCH_CC = ["RA", "RN", "HI", "LS", "CC", "CS", "NE", "EQ",
             "VC", "VS", "PL", "MI", "GE", "LT", "GT", "LE"]
for i, cc in enumerate(BRANCH_CC):
    _add("B" + cc, REL8, 0x20 + i)
    if i >= 1:
        _add("LB" + cc, REL16, 0x1020 + i)
_add("LBRA", REL16, 0x16); _add("LBSR", REL16, 0x17); _add("BSR", REL8, 0x8D)

# accumulator / register group: imm $8x/$Cx, direct +$10, indexed +$20, extended +$30
def _grp(mn, base, imm, store=False):
    if not store:
        _add(mn, imm, base)
    _add(mn, DIR, base + 0x10)
    _add(mn, IDX, base + 0x20)
    _add(mn, EXT, base + 0x30)

for lo, mn in [(0x0, "SUB"), (0x1, "CMP"), (0x2, "SBC"), (0x4, "AND"), (0x5, "BIT"),
               (0x6, "LD"), (0x8, "EOR"), (0x9, "ADC"), (0xA, "OR"), (0xB, "ADD")]:
    _grp(mn + "A", 0x80 | lo, IMM8)
    _grp(mn + "B", 0xC0 | lo, IMM8)
_grp("STA", 0x87, IMM8, store=True)
_grp("STB", 0xC7, IMM8, store=True)
_grp("SUBD", 0x83, IMM16); _grp("ADDD", 0xC3, IMM16)
_grp("CMPX", 0x8C, IMM16); _grp("LDX", 0x8E, IMM16); _grp("STX", 0x8F, IMM16, store=True)
_grp("LDD", 0xCC, IMM16); _grp("STD", 0xCD, IMM16, store=True)
_grp("LDU", 0xCE, IMM16); _grp("STU", 0xCF, IMM16, store=True)
_grp("JSR", 0x8D, IMM16, store=True)
_grp("CMPD", 0x1083, IMM16); _grp("CMPY", 0x108C, IMM16)
_grp("LDY", 0x108E, IMM16); _grp("STY", 0x108F, IMM16, store=True)
_grp("LDS", 0x10CE, IMM16); _grp("STS", 0x10CF, IMM16, store=True)
_grp("CMPU", 0x1183, IMM16); _grp("CMPS", 0x118C, IMM16)

ALIASES = {"LSL": "ASL", "LSLA": "ASLA", "LSLB": "ASLB",
           "BHS": "BCC", "BLO": "BCS", "LBHS": "LBCC", "LBLO": "LBCS",
           "ORAA": "ORA", "ORAB": "ORB", "LDAA": "LDA", "LDAB": "LDB",
           "STAA": "STA", "STAB": "STB"}
for _a, _m in ALIASES.items():
    TAB[_a] = TAB[_m]

def canonical(mn):
    return ALIASES.get(mn, mn)

MODE_SIZE = {INH: 0, IMM8: 1, IMM16: 2, DIR: 1, EXT: 2, REL8: 1, REL16: 2, REGS: 1, STK: 1}

def opbytes(op):
    return [op >> 8, op & 0xFF] if op > 0xFF else [op]

# ---------------------------------------------------------------- registers
TFR_REG = {"D": 0, "X": 1, "Y": 2, "U": 3, "S": 4, "PC": 5,
           "A": 8, "B": 9, "CC": 10, "CCR": 10, "DP": 11, "DPR": 11}
TFR_NAME = {0: "D", 1: "X", 2: "Y", 3: "U", 4: "S", 5: "PC", 8: "A", 9: "B", 10: "CC", 11: "DP"}
STK_BIT = {"CC": 0x01, "CCR": 0x01, "A": 0x02, "B": 0x04, "D": 0x06, "DP": 0x08,
           "DPR": 0x08, "X": 0x10, "Y": 0x20, "U": 0x40, "S": 0x40, "PC": 0x80}
IDX_REG = {"X": 0, "Y": 1, "U": 2, "S": 3}
IDX_NAME = "XYUS"

# ---------------------------------------------------------------- decoder
DEC = {}        # opcode (with page prefix) -> (mnemonic, mode)
for _mn, _modes in TAB.items():
    if _mn in ALIASES:
        continue
    for _mode, _op in _modes.items():
        DEC[_op] = (_mn, _mode)

def idx_len(post):
    """Extra bytes after an indexed postbyte, or None if the postbyte is undefined."""
    if not post & 0x80:
        return 0
    t = post & 0x1F
    if t in (0x00, 0x02) :                 # ,R+  ,-R  (no indirect form)
        return 0
    if t in (0x01, 0x03, 0x04, 0x05, 0x06, 0x0B,
             0x11, 0x13, 0x14, 0x15, 0x16, 0x1B):
        return 0
    if t in (0x08, 0x0C, 0x18, 0x1C):
        return 1
    if t in (0x09, 0x0D, 0x19, 0x1D):
        return 2
    if post == 0x9F:
        return 2
    return None

def decode(mem, a):
    """Decode one instruction at address a.  mem maps address -> byte (dict or
    bytes).  Returns dict(mn, mode, len, op, post, value) or None if undefined.
    value: operand value (immediate, address, branch target, or indexed offset)."""
    def rd(x):
        try:
            return mem[x & 0xFFFF]
        except (KeyError, IndexError):
            return None
    b = rd(a)
    if b is None:
        return None
    n = 1
    op = b
    if b in (0x10, 0x11):
        c = rd(a + 1)
        if c is None:
            return None
        op = (b << 8) | c
        n = 2
    if op not in DEC:
        return None
    mn, mode = DEC[op]
    r = dict(mn=mn, mode=mode, op=op, post=None, value=None)
    def need(k):
        bs = [rd(a + n + i) for i in range(k)]
        return None if None in bs else bs
    if mode == INH:
        pass
    elif mode in (IMM8, DIR, REGS, STK):
        bs = need(1)
        if bs is None:
            return None
        r["value"] = bs[0]
        n += 1
    elif mode in (IMM16, EXT):
        bs = need(2)
        if bs is None:
            return None
        r["value"] = (bs[0] << 8) | bs[1]
        n += 2
    elif mode == REL8:
        bs = need(1)
        if bs is None:
            return None
        d = bs[0] - 256 if bs[0] & 0x80 else bs[0]
        n += 1
        r["value"] = (a + n + d) & 0xFFFF
    elif mode == REL16:
        bs = need(2)
        if bs is None:
            return None
        d = (bs[0] << 8) | bs[1]
        n += 2
        r["value"] = (a + n + d) & 0xFFFF
    elif mode == IDX:
        bs = need(1)
        if bs is None:
            return None
        post = bs[0]
        n += 1
        k = idx_len(post)
        if k is None:
            return None
        r["post"] = post
        if not post & 0x80:
            v = post & 0x1F
            r["value"] = v - 32 if v & 0x10 else v
        elif k:
            bs = need(k)
            if bs is None:
                return None
            if k == 1:
                r["value"] = bs[0] - 256 if bs[0] & 0x80 else bs[0]
            else:
                r["value"] = (bs[0] << 8) | bs[1]
            n += k
            if (post & 0x0F) in (0x0C, 0x0D):          # PC relative: make it a target
                d = r["value"]
                if k == 2 and d & 0x8000:
                    d -= 0x10000
                r["value"] = (a + n + d) & 0xFFFF
    r["len"] = n
    return r

def fmt_regs(post):
    return "%s,%s" % (TFR_NAME.get(post >> 4, "?"), TFR_NAME.get(post & 15, "?"))

def fmt_stack(post, mn):
    other = "U" if mn.endswith("S") else "S"
    names = []
    for bit, nm in [(0x01, "CC"), (0x02, "A"), (0x04, "B"), (0x08, "DP"),
                    (0x10, "X"), (0x20, "Y"), (0x40, other), (0x80, "PC")]:
        if post & bit:
            names.append(nm)
    return ",".join(names)

def fmt_idx(post, operand):
    """Motorola text of an indexed operand; `operand` is the already formatted
    offset / target text (ignored for forms that have none)."""
    if not post & 0x80:
        return "%s,%s" % (operand, IDX_NAME[(post >> 5) & 3])
    r = IDX_NAME[(post >> 5) & 3]
    t = post & 0x0F
    s = {0x0: ",%s+" % r, 0x1: ",%s++" % r, 0x2: ",-%s" % r, 0x3: ",--%s" % r,
         0x4: ",%s" % r, 0x5: "B,%s" % r, 0x6: "A,%s" % r, 0xB: "D,%s" % r,
         0x8: "<%s,%s" % (operand, r), 0x9: ">%s,%s" % (operand, r),
         0xC: "<%s,PCR" % operand, 0xD: ">%s,PCR" % operand,
         0xF: "%s" % operand}[t]
    return "[%s]" % s if post & 0x10 else s

if __name__ == "__main__":
    print("%d mnemonics, %d opcodes" % (len([m for m in TAB if m not in ALIASES]), len(DEC)))
