"""Reader for DEC absolute-loader (.LDA) images, the format of Atari's LINKM output.

A record is  01 00  count(lo,hi)  address(lo,hi)  data...  checksum, where count
covers the six header bytes and the data, and the sum of every byte including
the checksum is zero mod 256.  A record with no data is the transfer record.
"""
import paths

def read(name):
    """Return (mem, records): mem maps address -> byte."""
    d = open(paths.src(name), "rb").read()
    mem, recs, i = {}, 0, 0
    while i + 6 <= len(d):
        if d[i] != 1 or d[i + 1] != 0:
            i += 1
            continue
        cnt = d[i + 2] | (d[i + 3] << 8)
        addr = d[i + 4] | (d[i + 5] << 8)
        if cnt < 6 or i + cnt + 1 > len(d) or sum(d[i:i + cnt + 1]) & 0xFF:
            i += 1
            continue
        for k in range(cnt - 6):
            mem[(addr + k) & 0xFFFF] = d[i + 6 + k]
        recs += 1
        i += cnt + 1
    return mem, recs

def ranges(mem):
    out = []
    for a in sorted(mem):
        if out and out[-1][1] == a - 1:
            out[-1][1] = a
        else:
            out.append([a, a])
    return out

if __name__ == "__main__":
    import sys
    for n in sys.argv[1:]:
        mem, recs = read(n)
        print("%s: %d records, %d bytes: %s" % (
            n, recs, len(mem), " ".join("%04X-%04X" % tuple(r) for r in ranges(mem))))
