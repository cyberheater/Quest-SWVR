"""Run every scenario through tests/lockstep.exe (the C port verified against the
ROM, docs/PORT.md) and report the routines no scenario reached.  Both programs
are verified in the same runs: the main program on the oracle's main 6809 and
the sound program on its sound 6809.

    python tools/run_lockstep.py [scenario ...]

Needs tests/lockstep.exe (build_all.bat), gen/ and gen_snd/ (tools/xlate.py,
tools/xlate.py sound).  Writes tests/lockstep_coverage.txt and
tests/lockstep_coverage_sound.txt.  Exit status 1 if any scenario fails.
"""
import collections, os, re, subprocess, sys, tempfile

HERE = os.path.dirname(os.path.abspath(__file__))
CSRC = os.path.normpath(os.path.join(HERE, ".."))
EXE = os.path.join(CSRC, "tests", "lockstep.exe")

SCENARIOS = [
    # name, script, extra args, passes
    ("boot", None, [], 300),
    ("boot_rev1", None, ["--rev", "1"], 300),
    ("attract", "attract.txt", [], 1500),
    ("coin_start", "coin_start.txt", [], 400),
    ("play", "play.txt", [], 1400),
    ("selftest", "selftest.txt", ["--diag-pc", "F65C", "--allow-watchdog"], 420),
    ("waves", "waves.txt", [], 9000),
    ("waves_easy", "waves_easy.txt", [], 2500),
    ("waves_hard", "waves_hard.txt", [], 7000),
    ("waves_late", "waves_late.txt", [], 5000),
    ("waves_first", "waves_first.txt", [], 1600),
    ("waves_force", "waves_force.txt", [], 2400),
    ("waves_five", "waves_five.txt", [], 1000),
    ("waves_six", "waves_six.txt", [], 1500),
    ("waves_tough", "waves_tough.txt", [], 1000),
    ("hiscore", "hiscore.txt", [], 3600),
    ("die_space", "die_space.txt", [], 900),
    ("die_trench", "die_trench.txt", [], 2200),
    ("operator", "operator.txt", [], 900),
    # {nv}: a NOVRAM image in the scratch directory; operator_game writes it, nvboot powers up with it
    ("operator_game", "operator_game.txt", ["--nvram-out", "{nv}"], 1300),
    ("nvboot", "nvboot.txt", ["--nvram-in", "{nv}"], 500),
    ("diag", "diag.txt", ["--diag-pc", "FD07", "--allow-watchdog"], 780),
    ("sndtest", "sndtest.txt", [], 2600),
]

def field(out, label):
    m = re.search(r"^\s*%s\s*:\s*(.*)$" % re.escape(label), out, re.M)
    return m.group(1) if m else ""

class Side:
    """one program's results over all the scenarios"""
    def __init__(self, title, gen, cov_file):
        self.title, self.gen, self.cov_file = title, gen, cov_file
        self.tot = collections.Counter()
        self.how = {}                             # (bank, addr) -> best comparison seen
        self.hit = set()                          # (bank, addr) of every instruction the ROM executed
        self.late = set()                         # instructions whose hardware access saw the clock late

    def scenario(self, out, reached):
        """-> (row text, ok) from one program's section of the verifier's output"""
        calls = re.match(r"(\d+) checked: (\d+) equal, (\d+) failed, (\d+) failed only through a callee, (\d+) tainted",
                         field(out, "routine calls"))
        irq = re.match(r"(\d+) taken; handler checked (\d+) times: (\d+) equal, (\d+) failed", field(out, "interrupt"))
        wp = re.match(r"(\d+) from frame start to frame start: (\d+) equal, (\d+) failed, (\d+) failed only through a "
                      r"callee, (\d+) tainted", field(out, "whole passes"))
        rs = re.match(r"(\d+) regions to the first frame: (\d+) equal, (\d+) failed, (\d+) tainted",
                      field(out, "RESET"))
        ev = re.match(r"(\d+) hardware accesses and checkpoints timed against the ROM's cycle clock: (\d+) differ",
                      field(out, "event times"))
        if not (calls and irq and wp and rs and ev):
            return None, False
        t = self.tot
        for k, v in (("calls", calls.group(1)), ("equal", calls.group(2)), ("tainted", calls.group(5)),
                     ("irqs", irq.group(2)), ("irq_equal", irq.group(3)), ("passes", wp.group(1)),
                     ("pass_equal", wp.group(2)), ("pass_tainted", wp.group(5)), ("resets", rs.group(1)),
                     ("reset_equal", rs.group(2)), ("evt", ev.group(1)), ("evt_bad", ev.group(2))):
            t[k] += int(v)
        for m in re.finditer(r"time differs at the access of the instruction at \$([0-9A-F]{4})", out):
            self.late.add(m.group(1))
        ok = (calls.group(1) == calls.group(2) and irq.group(4) == "0" and wp.group(3) == "0" and wp.group(4) == "0"
              and rs.group(3) == "0")
        rank = {"FAIL": 3, "call": 2, "region": 1}
        if os.path.exists(reached):
            for l in open(reached):
                if l.startswith("I "):
                    _, b, a = l.split()
                    self.hit.add((b, a))
                    continue
                b, a, nm, h = l.split()
                if rank[h] > rank.get(self.how.get((b, a)), 0):
                    self.how[(b, a)] = h
        return "%9s %9s %7s %8s %7s %7s %5s" % (calls.group(1), calls.group(2), calls.group(5), irq.group(1),
                                                 wp.group(1), wp.group(2), rs.group(2) + "/" + rs.group(1)), ok

    def report(self, failed, full):
        t = self.tot
        gen = os.path.join(CSRC, self.gen)
        routines = [l.split() for l in open(os.path.join(gen, "routines.txt"))]
        insns = collections.defaultdict(list)
        for l in open(os.path.join(gen, "insns.txt")):
            b, a, r = l.split()
            insns[(b, r)].append(a)
        print("\n%s" % self.title)
        print("  routine calls %d, equal %d, tainted %d; interrupts %d, equal %d; whole passes %d, equal %d, tainted "
              "%d; RESET regions %d, equal %d" % (t["calls"], t["equal"], t["tainted"], t["irqs"], t["irq_equal"],
                                                   t["passes"], t["pass_equal"], t["pass_tainted"], t["resets"],
                                                   t["reset_equal"]))
        print("  cycle clock: every equal call, interrupt, pass and region took the ROM's cycles; %d hardware accesses "
              "timed, %d at another cycle than the ROM's%s" % (
                  t["evt"], t["evt_bad"],
                  (" (xlate.py FLUSH wants: %s)" % " ".join("0x" + a for a in sorted(self.late))) if self.late else ""))
        bymod = collections.defaultdict(list)
        n = collections.Counter()
        partial = []
        # the checked-in coverage file is the full run's: a run of some scenarios leaves it alone
        with open(os.path.join(CSRC, "tests", self.cov_file) if full else os.devnull, "w", newline="\n") as fp:
            fp.write("# bank address routine module instructions executed compared-as  [instructions not executed]\n"
                     "#   call   = its own call checks, all equal\n"
                     "#   region = only inside a whole pass, a RESET region or the interrupt (it does not return by RTS)\n"
                     "#   -      = no scenario reached it\n")
            for b, a, nm, mod, ni in routines:
                h = self.how.get((b, a), "-")
                miss = [x for x in insns[(b, a)] if (b, x) not in self.hit]
                n[h] += 1
                n["insn"] += int(ni)
                n["miss"] += len(miss)
                if h == "-":
                    bymod[mod].append(nm)
                    n["miss_unreached"] += len(miss)
                elif miss:
                    partial.append((len(miss), nm))
                fp.write("%s %s %-10s %-8s %4s %4d %-6s %s\n" % (b, a, nm, mod, ni, int(ni) - len(miss), h,
                                                                 " ".join(miss)))
        print("  routines: %d; by call checks %d, inside regions only %d, failing %d, not reached %d" % (
            len(routines), n["call"], n["region"], n["FAIL"], n["-"]))
        print("  instructions: %d; executed by the ROM in a compared run %d (%.1f%%); not executed %d: %d in the "
              "routines not reached, %d on untaken paths of %d other routines" % (
                  n["insn"], n["insn"] - n["miss"], 100.0 * (n["insn"] - n["miss"]) / max(1, n["insn"]), n["miss"],
                  n["miss_unreached"], n["miss"] - n["miss_unreached"], len(partial)))
        if bymod:
            print("  not reached:")
            for mod in sorted(bymod):
                print("    %-8s %3d  %s" % (mod, len(bymod[mod]), " ".join(bymod[mod])))
        partial.sort(reverse=True)
        if partial:
            print("  most untaken instructions: " + ", ".join("%s %d" % (nm, k) for k, nm in partial[:24]))

def main(argv):
    if not os.path.exists(EXE):
        sys.exit("!! missing %s (run build_all.bat)" % EXE)
    want = argv or [s[0] for s in SCENARIOS]
    sides = [Side("MAIN PROGRAM", "gen", "lockstep_coverage.txt"),
             Side("SOUND PROGRAM", "gen_snd", "lockstep_coverage_sound.txt")]
    failed = ran = 0
    tmp = tempfile.mkdtemp(prefix="swlk_")
    hdr = "%9s %9s %7s %8s %7s %7s %5s" % ("calls", "equal", "tainted", "IRQs", "passes", "equal", "RESET")
    print("%-13s %6s | %s | %s  %s" % ("scenario", "passes", hdr, hdr, "result"))
    for name, script, extra, passes in SCENARIOS:
        if name not in want:
            continue
        if script and not os.path.exists(os.path.join(CSRC, "tests", "scenarios", script)):
            print("%-13s (no script %s)" % (name, script))
            continue
        nv = os.path.join(tmp, "nv.bin")
        if "--nvram-in" in extra and not os.path.exists(nv):
            # on its own: make the image first
            subprocess.run([EXE, "--frames", "1300", "--outdir", tmp, "--no-dumps", "--quiet", "--lk-verbose", "0",
                            "--script", "tests/scenarios/operator_game.txt", "--nvram-out", nv],
                           cwd=CSRC, capture_output=True, text=True)
        extra = [nv if x == "{nv}" else x for x in extra]
        reached = os.path.join(tmp, name + ".txt")
        cmd = [EXE, "--frames", str(passes), "--outdir", tmp, "--no-dumps", "--quiet",
               "--lk-verbose", "60", "--lk-reached", reached] + extra
        if script:
            cmd += ["--script", "tests/scenarios/" + script]
        p = subprocess.run(cmd, cwd=CSRC, capture_output=True, text=True)
        out = p.stdout
        cut = out.find("LOCKSTEP, sound program")
        parts = (out[:cut], out[cut:]) if cut >= 0 else (out, "")
        rows = [s.scenario(o, reached + sfx) for s, o, sfx in zip(sides, parts, ("", ".snd"))]
        ok = p.returncode == 0 and all(r[1] for r in rows)
        ran += 1
        if not ok:
            failed += 1
        print("%-13s %6d | %s | %s  %s" % (name, passes, rows[0][0] or "?", rows[1][0] or "?", "PASS" if ok else "FAIL"))
        if not ok:
            for l in out.splitlines():
                if "FAIL " in l or " x interrupt" in l or "first:" in l or "RESULT" in l:
                    print("            " + l.strip()[:260])
            if not rows[0][0] or not rows[1][0]:
                print(out[-2500:])
                print(p.stderr[-1500:])

    print("\ntotal: %d scenarios, %d failed" % (ran, failed))
    for s in sides:
        s.report(failed, not argv)
    return 1 if failed else 0

if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
