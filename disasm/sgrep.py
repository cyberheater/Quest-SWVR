"""grep for Atari's sources (they are NUL padded, which ordinary grep treats as binary).

    python sgrep.py REGEX [FILE-GLOB] [-c N]     e.g.  python sgrep.py "PNLW\\$IZ" WS*.MAC -c 2
"""
import sys, re, glob, os
import paths
from macsrc import read_source

def main(argv):
    ctx = 0
    if "-c" in argv:
        i = argv.index("-c")
        ctx = int(argv[i + 1])
        del argv[i:i + 2]
    rx = re.compile(argv[0], re.I)
    pat = argv[1] if len(argv) > 1 else "*.MAC"
    for p in sorted(glob.glob(os.path.join(paths.SRC_DIR, pat))):
        name = os.path.basename(p)
        lines = read_source(name) if name.upper().endswith(".MAC") else \
            open(p, "rb").read().replace(b"\0", b"").decode("latin-1").splitlines()
        for n, l in enumerate(lines):
            if rx.search(l):
                for k in range(max(0, n - ctx), min(len(lines), n + ctx + 1)):
                    print("%s:%d%s %s" % (name, k + 1, ":" if k == n else "-", lines[k]))

if __name__ == "__main__":
    main(sys.argv[1:])
