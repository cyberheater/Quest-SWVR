"""Parser for Atari LINKM load maps (WSROOT.MAP, WSOVLY.MAP, SNDAUX.MAP).

Two of the three maps in the archive have lost their line terminators, so the
map is parsed as one stream by its fixed 8-column fields instead of by line.

  sections : list of dict(name, addr, size, rel, ovr, files)   in map order
  globals  : dict name -> value
  definer  : dict name -> file that defines it (the one marked '#')
"""
import re
import paths

HEADER_RE = re.compile(r"ATARI LINKM V[\d.]+ LOAD MAP\s+\S+\s+\S+\s+\S+\.LDA ?")
SECT_RE = re.compile(r"(\. ABS\.  |[A-Z0-9$.]{1,6} {2,7}| {8})([0-9A-F]{4}) {4}([0-9A-F]{4}) {4}"
                     r"(ABS|REL),(OVR|CON)")
SYM_RE = re.compile(r"([A-Z0-9$.]{1,6}) {1,7}([0-9A-F]{4}) {5}")
FILE_RE = re.compile(r"([A-Z0-9]{1,6})(#?)")

class LinkMap:
    def __init__(self, name):
        raw = open(paths.src(name), "rb").read().replace(b"\0", b"").decode("latin-1")
        raw = raw.replace("\f", "").replace("\r", "").replace("\n", "").replace("\t", "    ")
        txt = HEADER_RE.sub("", raw)
        i = txt.index("Section Summary:")
        j = txt.index("Global Symbol Summary:")
        self.sections = self._sections(txt[i:j])
        self.globals, self.definer = self._symbols(txt[j:])

    @staticmethod
    def _sections(t):
        out = []
        ms = [m for m in SECT_RE.finditer(t) if len(m.group(1)) == 8]
        for k, m in enumerate(ms):
            end = ms[k + 1].start() if k + 1 < len(ms) else len(t)
            files = [f for f, _ in FILE_RE.findall(t[m.end():end])]
            name = m.group(1).strip()
            out.append(dict(name="" if not name else name, addr=int(m.group(2), 16),
                            size=int(m.group(3), 16), rel=m.group(4) == "REL",
                            ovr=m.group(5) == "OVR", files=files))
        return out

    @staticmethod
    def _symbols(t):
        glob, definer = {}, {}
        # WSROOT/SNDAUX: one symbol per entry, name padded to 8, then the files.
        # WSOVLY: eight "Name Value" columns per line, name padded to 7, no files.
        wide = 7 if "Name  Value     Name  Value" in t else 8
        ms = [m for m in SYM_RE.finditer(t) if m.start(2) - m.start(1) == wide]
        for k, m in enumerate(ms):
            end = ms[k + 1].start() if k + 1 < len(ms) else len(t)
            glob[m.group(1)] = int(m.group(2), 16)
            for f, mark in FILE_RE.findall(t[m.end():end]):
                if mark:
                    definer[m.group(1)] = f
        return glob, definer

    def base(self, module, csect):
        """Base address of a module's control section."""
        for s in self.sections:
            if not s["rel"]:
                continue
            if csect and s["name"] == csect:
                return s["addr"]
            if not csect and not s["name"] and s["files"][:1] == [module]:
                return s["addr"]
        return None

    def section(self, module, csect):
        for s in self.sections:
            if s["rel"] and ((csect and s["name"] == csect) or
                             (not csect and not s["name"] and s["files"][:1] == [module])):
                return s
        return None

if __name__ == "__main__":
    import sys
    for n in sys.argv[1:] or ["SNDAUX.MAP", "WSROOT.MAP", "WSOVLY.MAP"]:
        m = LinkMap(n)
        print("%s: %d sections, %d globals" % (n, len(m.sections), len(m.globals)))
        for s in m.sections:
            print("  %-6s %04X %04X %s %s  %s" % (s["name"] or "-", s["addr"], s["size"],
                  "REL" if s["rel"] else "ABS", "OVR" if s["ovr"] else "CON", " ".join(s["files"])))
