"""Build the working ROM images from a MAME ROM set.

Chips are found by CRC32, not by file name, in every zip under ../roms (or in the
zip / directory given on the command line).  Writes to build/:

  starwars_main_rev1.bin, starwars_main_rev2.bin   64K main CPU space, bank 0 at $6000
  starwars_bank1.bin                               8K, the bank-1 half of the ROM at 1F
  starwars_sound.bin                               64K sound CPU space, ROMs at $4000 and mirrored at $C000
  starwars_mathbox.bin, starwars_avgprom.bin       the PROMs, for the later steps

Rev 2 is MAME's parent `starwars` (136021-214 at 1F); rev 1 is `starwars1`
(136021-114), the set Atari's 22-JUN-83 link images reproduce.
"""
import os, sys, zipfile, zlib
import paths

# part -> (crc32, size)
CHIPS = {
    "136021-214.1f": (0x04F1876E, 0x4000),      # rev 2: $6000 bank 0 / bank 1
    "136021-114.1f": (0xE75FF867, 0x4000),      # rev 1
    "136021-102.1hj": (0xF725E344, 0x2000),     # $8000
    "136021-203.1jk": (0xF6DA0A00, 0x2000),     # $A000
    "136021-104.1kl": (0x7E406703, 0x2000),     # $C000
    "136021-206.1m": (0xC7E51237, 0x2000),      # $E000
    "136021-105.1l": (0x538E7D2F, 0x1000),      # vector ROM $3000
    "136021-107.1jk": (0xDBF3AEA2, 0x2000),     # sound $4000
    "136021-208.1h": (0xE38070A8, 0x2000),      # sound $6000
    "136021-110.7h": (0x810E040E, 0x0400),      # mathbox PROMs
    "136021-111.7j": (0xAE69881C, 0x0400),
    "136021-112.7k": (0xECF22628, 0x0400),
    "136021-113.7l": (0x83FEBFDE, 0x0400),
    "136021-109.4b": (0x82FC3EB2, 0x0100),      # AVG state PROM
}
REV2_PATCH = {0x6164: (0xB1, 0xB0), 0x7A7C: (0x9C, 0x9D)}   # address: (rev 1, rev 2)

def scan(where):
    """Yield (label, bytes) for every file in a zip, a directory, or the zips of a directory."""
    if os.path.isdir(where):
        for n in sorted(os.listdir(where)):
            p = os.path.join(where, n)
            if n.lower().endswith(".zip"):
                yield from scan(p)
            elif os.path.isfile(p):
                yield p, open(p, "rb").read()
    else:
        with zipfile.ZipFile(where) as z:
            for n in z.namelist():
                if not n.lower().endswith(".zip"):
                    yield "%s:%s" % (os.path.basename(where), n), z.read(n)

def find_chips(where):
    by_crc = {}
    seen_sizes = {}
    for label, data in scan(where):
        by_crc.setdefault(zlib.crc32(data) & 0xFFFFFFFF, (label, data))
        seen_sizes.setdefault(len(data), []).append((label, zlib.crc32(data) & 0xFFFFFFFF))
    found, missing = {}, []
    for part, (crc, size) in CHIPS.items():
        if crc in by_crc:
            found[part] = by_crc[crc]
        else:
            missing.append(part)
    return found, missing, seen_sizes

def build(where=None, verbose=True):
    where = where or paths.need(paths.ROMS_DIR, "ROM directory")
    paths.need(where, "ROM set")
    found, missing, sizes = find_chips(where)
    if verbose:
        for part in CHIPS:
            if part in found:
                print("  %-15s %08X  %s" % (part, CHIPS[part][0], found[part][0]))
    need = [p for p in missing if p != "136021-114.1f" and p != "136021-214.1f"]
    if "136021-114.1f" in missing and "136021-214.1f" in missing:
        need.append("136021-214.1f")
    if need:
        for p in need:
            crc, size = CHIPS[p]
            cands = ", ".join("%s has %08X" % c for c in sizes.get(size, [])[:6]) or "no file of that size"
            print("!! %s not found: need CRC %08X (%d bytes); %s" % (p, crc, size, cands))
        sys.exit(1)
    rom = {p: found[p][1] for p in found}
    def main(part):
        m = bytearray(b"\xFF" * 0x10000)
        m[0x3000:0x4000] = rom["136021-105.1l"]
        m[0x6000:0x8000] = rom[part][:0x2000]
        m[0x8000:0xA000] = rom["136021-102.1hj"]
        m[0xA000:0xC000] = rom["136021-203.1jk"]
        m[0xC000:0xE000] = rom["136021-104.1kl"]
        m[0xE000:0x10000] = rom["136021-206.1m"]
        return m
    out = {}
    have1, have2 = "136021-114.1f" in rom, "136021-214.1f" in rom
    if have1:
        out["starwars_main_rev1.bin"] = main("136021-114.1f")
    if have2:
        out["starwars_main_rev2.bin"] = main("136021-214.1f")
    # each revision can be derived from the other through the two patched bytes
    for src_rev, dst_rev, idx in (("rev1", "rev2", 1), ("rev2", "rev1", 0)):
        s, d = "starwars_main_%s.bin" % src_rev, "starwars_main_%s.bin" % dst_rev
        if s in out and d not in out:
            m = bytearray(out[s])
            for a, vals in REV2_PATCH.items():
                m[a] = vals[idx]
            out[d] = m
    one = rom.get("136021-214.1f") or rom["136021-114.1f"]
    out["starwars_bank1.bin"] = bytearray(one[0x2000:])
    s = bytearray(b"\xFF" * 0x10000)
    s[0x4000:0x6000] = rom["136021-107.1jk"]; s[0xC000:0xE000] = rom["136021-107.1jk"]
    s[0x6000:0x8000] = rom["136021-208.1h"]; s[0xE000:0x10000] = rom["136021-208.1h"]
    out["starwars_sound.bin"] = s
    out["starwars_mathbox.bin"] = bytearray(b"".join(
        rom[p] for p in ("136021-110.7h", "136021-111.7j", "136021-112.7k", "136021-113.7l")))
    out["starwars_avgprom.bin"] = bytearray(rom["136021-109.4b"])
    for n, data in out.items():
        with open(paths.build(n), "wb") as f:
            f.write(data)
    # revision check
    r1, r2 = out["starwars_main_rev1.bin"], out["starwars_main_rev2.bin"]
    diff = [a for a in range(0x10000) if r1[a] != r2[a]]
    ok = diff == sorted(REV2_PATCH) and all((r1[a], r2[a]) == REV2_PATCH[a] for a in diff)
    if verbose:
        print("  rev 1 vs rev 2: %s" % ", ".join("$%04X %02X->%02X" % (a, r1[a], r2[a]) for a in diff))
    if have1 and have2 and not ok:
        print("!! the two revisions differ in more than the two known bytes")
        sys.exit(1)
    return out

def load(name):
    return open(paths.need(paths.build(name), "image (run image.py)"), "rb").read()

def check_lda(verbose=True):
    """Atari's link images against the rev-1 ROMs."""
    import lda
    bad = 0
    res = []
    for img, ldaname, binname, off in (("root", "WSROOT.LDA", "starwars_main_rev1.bin", 0),
                                      ("overlay", "WSOVLY.LDA", "starwars_bank1.bin", 0x6000),
                                      ("sound", "SNDAUX.LDA", "starwars_sound.bin", 0)):
        mem, _ = lda.read(ldaname)
        rom = load(binname)
        d = sum(1 for a, b in mem.items() if rom[a - off] != b)
        bad += d
        res.append("%d" % len(mem))
    if verbose:
        print("  LDA == starwars1: %s, %d differ" % (" / ".join(res), bad))
    return bad

if __name__ == "__main__":
    build(sys.argv[1] if len(sys.argv) > 1 else None)
    # the images are all the two programs need to run; the comparison with
    # Atari's link images needs the source archive
    if not os.path.isdir(paths.SRC_DIR):
        print("  images written to %s (no source archive at %s: link images not compared)"
              % (paths.BUILD, paths.SRC_DIR))
        sys.exit(0)
    sys.exit(1 if check_lda() else 0)
