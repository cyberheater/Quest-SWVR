"""Run every oracle gate (docs/ORACLE.md).  Needs tests/refrun.exe (build_all.bat)
and the ROM images in ../disasm/build (python ../disasm/image.py).

For each scenario:
  1. run it into tests/ref_<name>/, with the display lists dumped to
     tests/avg_out/<name>/
  2. run it again into a scratch directory: the summary hashes, the schedule
     and the vector-generator log must be identical (determinism)
  3. cross-check the dumped display lists with avg_prom_sim.py
  4. scenario-specific checks on the PCs the ROM executed

    python tools/run_gates.py [scenario ...]
Exit status 1 if any gate fails.
"""
import filecmp, json, os, shutil, subprocess, sys

HERE = os.path.dirname(os.path.abspath(__file__))
CSRC = os.path.normpath(os.path.join(HERE, ".."))
REFRUN = os.path.join(CSRC, "tests", "refrun.exe")

# Atari's self test decides at these branches (disasm/starwars_program_rom.asm)
SELFTEST_MUST = {
    0xF5AA: '"NO ERRORS DETECTED" (RAM, NOVRAM, ROM checksums)',
    0xFA2A: '"NO DIVIDER ERRORS"',
    0xFAD2: '"NO MATRIX ERRORS"',
    0xF720: "HANG: test switch opened, waiting for the watchdog",
}
SELFTEST_MUST_NOT = {
    0xF5B1: "a hardware error message",
    0xF97F: '"BAD MATHBOX READY LINE"',
    0xFA2E: '"DIVIDER ERRORS"',
    0xFAD6: '"MATRIX ERRORS"',
}

SCENARIOS = [
    # name, script, extra args, passes
    ("boot", None, [], 300),
    ("boot_rev1", None, ["--rev", "1"], 300),
    ("attract", "attract.txt", [], 1500),
    ("coin_start", "coin_start.txt", [], 400),
    ("play", "play.txt", [], 1400),
    ("selftest", "selftest.txt", ["--diag-pc", "F65C", "--allow-watchdog"], 420),
]

def run(name, script, extra, passes, outdir, avgdir=None):
    cmd = [REFRUN, "--frames", str(passes), "--outdir", outdir] + extra
    if script:
        cmd += ["--script", os.path.join("tests", "scenarios", script)]
    if avgdir:
        cmd += ["--avg-dump", avgdir]
    p = subprocess.run(cmd, cwd=CSRC, capture_output=True, text=True)
    return p.returncode, p.stdout

def coverage(outdir):
    return set(int(l, 16) for l in open(os.path.join(outdir, "coverage_main.txt")))

def main(argv):
    if not os.path.exists(REFRUN):
        sys.exit("!! missing %s (run build_all.bat)" % REFRUN)
    want = argv or [s[0] for s in SCENARIOS]
    scratch = os.path.join(CSRC, "tests", "_scratch")
    rows, failed = [], 0
    for name, script, extra, passes in SCENARIOS:
        if name not in want:
            continue
        ref = os.path.join(CSRC, "tests", "ref_" + name)
        avgdir = os.path.join(CSRC, "tests", "avg_out", name)
        for d in (ref, avgdir, scratch):
            shutil.rmtree(d, ignore_errors=True)
        os.makedirs(os.path.dirname(avgdir), exist_ok=True)
        notes = []
        rc, out = run(name, script, extra, passes, ref, avgdir)
        ok = rc == 0
        if not ok:
            notes.append("refrun failed")
            print(out)
        idx = json.load(open(os.path.join(ref, "ref_index.json")))
        # determinism
        rc2, _ = run(name, script, extra, passes, scratch)
        idx2 = json.load(open(os.path.join(scratch, "ref_index.json")))
        same = rc2 == rc and all(idx[k] == idx2[k] for k in idx) and all(
            filecmp.cmp(os.path.join(ref, f), os.path.join(scratch, f), shallow=False)
            for f in ("frame_sched.txt", "avg_runs.txt", "coverage_main.txt", "coverage_sound.txt"))
        if not same:
            ok = False
            notes.append("second run differs")
        # AVG cross-check
        p = subprocess.run([sys.executable, os.path.join(HERE, "avg_prom_sim.py"), avgdir],
                           capture_output=True, text=True)
        avg_line = p.stdout.strip().splitlines()[-1] if p.stdout.strip() else "no output"
        if p.returncode:
            ok = False
            notes.append("AVG cross-check: " + avg_line)
        nlists = avg_line.split(":")[1].split(" lists")[0].strip() if "lists" in avg_line else "?"
        # scenario checks
        if name == "selftest":
            cov = coverage(ref)
            for a, what in SELFTEST_MUST.items():
                if a not in cov:
                    ok = False
                    notes.append("self test never reached $%04X %s" % (a, what))
            for a, what in SELFTEST_MUST_NOT.items():
                if a in cov:
                    ok = False
                    notes.append("self test reported $%04X %s" % (a, what))
            if idx["watchdog_bites"] != 1:
                ok = False
                notes.append("expected exactly one watchdog bite, got %d" % idx["watchdog_bites"])
        rows.append((name, idx["passes"], idx["cycles"], idx["pcs_main"], idx["pcs_sound"],
                     idx["vg_runs"], nlists, "PASS" if ok else "FAIL", "; ".join(notes)))
        failed += not ok
        shutil.rmtree(scratch, ignore_errors=True)
    print("%-11s %6s %11s %9s %10s %8s %9s  %s" % (
        "scenario", "passes", "cycles", "main PCs", "sound PCs", "VG runs", "AVG lists", "result"))
    for r in rows:
        print("%-11s %6d %11d %9d %10d %8d %9s  %s %s" % r)
    print("gates: %d scenarios, %d failed (each run twice and compared; display lists checked "
          "against avg_prom_sim.py)" % (len(rows), failed))
    return 1 if failed else 0

if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
