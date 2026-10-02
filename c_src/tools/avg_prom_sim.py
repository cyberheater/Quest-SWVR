"""Independent check of c_src/avg.c: the Star Wars AVG state machine written
again in Python and run on display lists the oracle recorded.

For every avg_NNNNNN.bin that `refrun --avg-dump DIR` wrote, this starts from
the generator's registers and the vector memory as VGGO found them, runs the
state PROM until HALT is strobed, and compares with what avg.c produced:

    ticks from VGGO to HALT       (master-clock ticks, 12.096 MHz)
    every beam point              (x, y, colour, brightness)

A dump holds vector memory as it was at VGGO.  If the CPU rewrote a byte the
generator had not yet read, the two would differ; the program avoids that by
drawing from the buffer it is not writing to, and a difference here would say
so.

The state machine follows MAME's avgdvg (Star Wars variant): PROM address =
(not halted) << 7 | op << 4 | state; a state with bit 3 set reads a byte of
vector memory and runs latch 0-3 or strobe 0-3.

    python tools/avg_prom_sim.py DIR [--prom FILE]
Exit status 1 if any list differs.
"""
import glob, os, struct, sys

HERE = os.path.dirname(os.path.abspath(__file__))
PROM = os.path.normpath(os.path.join(HERE, "..", "..", "disasm", "build", "starwars_avgprom.bin"))
XC, YC = 125 << 16, 140 << 16

def i32(v):
    v &= 0xFFFFFFFF
    return v - (1 << 32) if v & 0x80000000 else v

class Avg:
    NAMES = ("pc sp dvx dvy dvy12 timer s0 s1 s2 s3 data latch intl scale bscale "
             "inten color op x y").split()

    def __init__(self, prom, mem, regs):
        self.prom, self.mem = prom, mem
        for n, v in zip(self.NAMES, regs):
            setattr(self, n, v)
        self.stack = [self.s0, self.s1, self.s2, self.s3]
        self.halt = 0
        self.points = []

    def go(self):
        self.pc = 0
        self.sp = 0
        self.halt = 0

    # --- handlers -------------------------------------------------------
    def latch0(self):
        self.dvy = (self.dvy & 0x1F00) | self.data
        self.pc = (self.pc + 1) & 0xFFFF
        return 0

    def latch1(self):
        self.dvy12 = (self.data >> 4) & 1
        self.op = self.data >> 5
        self.intl = 0
        self.dvy = (self.dvy12 << 12) | ((self.data & 0xF) << 8)
        self.dvx = 0
        self.pc = (self.pc + 1) & 0xFFFF
        return 0

    def latch2(self):
        self.dvx = (self.dvx & 0x1F00) | self.data
        self.pc = (self.pc + 1) & 0xFFFF
        return 0

    def latch3(self):
        self.intl = self.data >> 4
        self.dvx = ((self.intl & 1) << 12) | ((self.data & 0xF) << 8) | (self.dvx & 0xFF)
        self.pc = (self.pc + 1) & 0xFFFF
        return 0

    def strobe0(self):
        op1 = self.op & 2
        if self.op & 1:
            self.stack[self.sp & 3] = self.pc
        else:
            i = 0
            while (((self.dvy ^ (self.dvy << 1)) & 0x1000) == 0 and
                   ((self.dvx ^ (self.dvx << 1)) & 0x1000) == 0 and i < 16):
                i += 1
                self.dvy = (self.dvy & 0x1000) | ((self.dvy << 1) & 0x1FFF)
                self.dvx = (self.dvx & 0x1000) | ((self.dvx << 1) & 0x1FFF)
                self.timer = (self.timer >> 1) | 0x4000 | (op1 << 6)
            if op1:
                self.timer &= 0xFF
        return 0

    def strobe1(self):
        op1 = self.op & 2
        if not self.op & 4:
            for _ in range(self.bscale):
                self.timer = (self.timer >> 1) | 0x4000 | (op1 << 6)
            if op1:
                self.timer &= 0xFF
        else:
            self.sp = (self.sp - 1) & 0xF if op1 else (self.sp + 1) & 0xF
        return 0

    def strobe2(self):
        if not self.op & 4 and not self.dvy12:
            self.inten = self.dvy & 0xFF
            self.color = (self.dvy >> 8) & 0xF
        if self.op & 4:
            if self.op & 1:
                self.pc = (self.dvy << 1) & 0xFFFF
            else:
                self.pc = self.stack[self.sp & 3]
        elif self.dvy12:
            self.scale = self.dvy & 0xFF
            self.bscale = (self.dvy >> 8) & 7
        return 0

    def strobe3(self):
        cycles = 0
        self.halt = self.op & 1
        if (self.op & 5) == 0:
            cycles = 0x100 - (self.timer & 0xFF) if self.op & 2 else 0x8000 - self.timer
            self.timer = 0
            k = cycles * (self.scale ^ 0xFF)
            self.x = i32(self.x + ((((self.dvx >> 3) ^ 0x200) - 0x200) * k >> 4))
            self.y = i32(self.y - ((((self.dvy >> 3) ^ 0x200) - 0x200) * k >> 4))
        if self.op & 4:
            cycles = 0x8000 - self.timer
            self.timer = 0
            self.x, self.y = XC, YC
            self.points.append((self.x, self.y, 0, 0))
        if (self.op & 5) == 0:
            z = min(((self.intl >> 1) * self.inten) >> 3, 0xFF)
            self.points.append((self.x, self.y, self.color & 7, z))
        return cycles

    def run(self, limit=4000000):
        """From VGGO to the HALT strobe: returns ticks, or None if it never halts."""
        h = (self.latch0, self.latch1, self.latch2, self.latch3,
             self.strobe0, self.strobe1, self.strobe2, self.strobe3)
        t = states = 0
        while states < limit:
            addr = ((((self.latch >> 4) ^ 1) << 7) | (self.op << 4) | (self.latch & 0xF)) & 0xFF
            self.latch = (self.latch & 0x10) | (self.prom[addr] & 0xF)
            cycles = 0
            if self.latch & 8:
                self.data = self.mem[self.pc & 0x3FFF]
                cycles = h[self.latch & 7]()
            if self.halt and not self.latch & 0x10:
                return t + cycles, states + 1
            self.latch = (self.halt << 4) | (self.latch & 0xF)
            t += cycles + 8
            states += 1
        return None, states

def check(path, prom):
    d = open(path, "rb").read()
    magic, ticks, nvect, nstates = struct.unpack_from("<4I", d, 0)
    if magic != 0x32475641:
        return "not an AVG2 dump"
    regs = struct.unpack_from("<20i", d, 16)
    mem = d[96:96 + 0x4000]
    want = [struct.unpack_from("<iiBB", d, 96 + 0x4000 + 10 * i) for i in range(nvect)]
    a = Avg(prom, mem, regs)
    a.go()
    got_ticks, _ = a.run()
    if got_ticks is None:
        return "never halts"
    if got_ticks != ticks:
        return "ticks: avg.c %d, here %d" % (ticks, got_ticks)
    if len(a.points) != nvect:
        return "points: avg.c %d, here %d" % (nvect, len(a.points))
    for i, (p, q) in enumerate(zip(a.points, want)):
        if tuple(p) != tuple(q):
            return "point %d: avg.c %r, here %r" % (i, q, p)
    return None

def main(argv):
    prom_path = PROM
    if "--prom" in argv:
        i = argv.index("--prom")
        prom_path = argv[i + 1]
        del argv[i:i + 2]
    if not argv:
        sys.exit(__doc__)
    prom = open(prom_path, "rb").read()
    files = sorted(glob.glob(os.path.join(argv[0], "avg_*.bin")))
    bad = 0
    ticks = points = 0
    for f in files:
        e = check(f, prom)
        d = open(f, "rb").read(12)
        ticks += struct.unpack_from("<I", d, 4)[0]
        points += struct.unpack_from("<I", d, 8)[0]
        if e:
            bad += 1
            if bad <= 10:
                print("!! %s: %s" % (os.path.basename(f), e))
    print("avg_prom_sim: %d lists, %d ticks, %d points; %d differ" % (len(files), ticks, points, bad))
    return 1 if bad or not files else 0

if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
