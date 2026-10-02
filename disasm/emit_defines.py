"""Emit starwars_defines.asm (main CPU) and starwars_sound_defines.asm (sound CPU):
memory map, hardware registers, RAM variables and equates, in .alias form.

Layout as the Tempest defines file: a hand-written memory map with descriptive
names, then sections generated from macasm69's symbol table - Atari's names, with
Atari's own comments on the definitions as the descriptions:

  Hardware registers   every I/O equate
  RAM sections         every RAM variable, by region
  ROM labels           labels one listing uses that another listing defines
                       (the main CPU's program, overlay and vector listings
                       share one defines file)
  Constants            every constant of the common files, plus every module
                       equate a listing uses, grouped by file and .SBTTL

Identifiers are the ones the listings use (emit.Names), so each file defines every
symbol its listings need; build/refs_<listing>.json lists them.

A definition Atari left without a comment (or with only a ditto mark), or whose
line carries a comment about something else, takes its description from
define_docs.py; those are in lower case, Atari's in upper case.

Run:  python emit_defines.py     (after emit.py)
"""
import os, sys, json, collections
HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
import macasm69, paths, define_docs
from emit import Names, tidy, words

FILES = {
    "main": dict(
        out="starwars_defines.asm", listings=["program", "overlay", "vector"],
        common={"WSGLOB", "WSCOMN", "WSVROM"},
        title=[";Star Wars (Atari, 1983) - hardware map, RAM variables and equates of the main",
               ";6809, for starwars_program_rom.asm, starwars_overlay_rom.asm and",
               ";starwars_vector_rom.asm."],
        memory_map=[
            ("VectorRam", 0x0000, "Through $2FFF. AVG display lists; from VGROM ($2800) up it holds the pseudo vector ROM the program copies down."),
            ("VectorRom", 0x3000, "Through $3FFF (starwars_vector_rom.asm)."),
            ("InputPorts", 0x4300, "Through $439F. Switch inputs $4300 and $4320, option switches $4340 and $4360, ADC $4380."),
            ("SoundLatch", 0x4400, "$4400 data to and from the sound CPU, $4401 the two ready flags."),
            ("NvRam", 0x4500, "Through $45FF. Non-volatile RAM: high scores and bookkeeping."),
            ("OutputLatches", 0x4600, "Through $46FF. VG go $4600, VG reset $4620, watchdog $4640, IRQ clear $4660, output bits $4680, NVRAM store $46A0, ADC channel $46C0, sound reset $46E0."),
            ("MathBox", 0x4700, "Through $4707. Matrix processor start and block index, divider; reads give the quotient and the random number."),
            ("CpuRam", 0x4800, "Through $4FFF. Program RAM; the direct page is here and the stack grows down from the top."),
            ("MathRam", 0x5000, "Through $5FFF. Matrix processor RAM, shared with the CPU."),
            ("BankedRom", 0x6000, "Through $7FFF. Bank 0 is in starwars_program_rom.asm, bank 1 in starwars_overlay_rom.asm."),
            ("ProgramRom", 0x8000, "Through $FFFF (starwars_program_rom.asm); the 6809 vectors are at $FFF2."),
        ],
        ram=[("Vector RAM", 0x0000, 0x3000), ("CPU RAM", 0x4800, 0x5000), ("Math RAM", 0x5000, 0x6000)],
        rom=[("Vector ROM labels the program uses", "root", 0x3000, 0x4000),
             ("Program ROM labels the overlay and vector listings use", "root", 0x6000, 0x10000),
             ("Overlay ROM (bank 1) labels the program uses", "overlay", 0x6000, 0x8000)]),
    "sound": dict(
        out="starwars_sound_defines.asm", listings=["sound"],
        common={"SNDCMN", "SNDGLB"},
        title=[";Star Wars (Atari, 1983) - hardware map, RAM variables and equates of the sound",
               ";board's 6809, for starwars_sound_rom.asm."],
        memory_map=[
            ("SoundOut", 0x0000, "Write: data latch read by the main CPU (sets the sound flag)."),
            ("SoundIn", 0x0800, "Read: data latch written by the main CPU (clears the main flag)."),
            ("RiotRam", 0x1000, "Through $107F. 6532 RAM: the direct page and the stack."),
            ("RiotIo", 0x1080, "Through $109F. 6532 ports and timer: speech strobes and data, flags, the 4 ms interrupt."),
            ("Pokeys", 0x1800, "Through $183F. Four POKEYs, registers interleaved."),
            ("ProgramRam", 0x2000, "Through $27FF."),
            ("ProgramRom", 0x4000, "Through $7FFF (starwars_sound_rom.asm), also seen at $C000-$FFFF."),
        ],
        ram=[("6532 RAM", 0x1000, 0x1080), ("Program RAM", 0x2000, 0x2800)],
        rom=[]),
}

def banner(t):
    return ";" + "-" * 34 + "[ " + t + " ]" + "-" * 34

def fmt(name, value, comment):
    v = ("$%02X" % value) if value < 0x100 else ("$%04X" % value)
    s = ".alias %-16s %s" % (name, v)
    if comment:
        s = "%-32s ;%s" % (s, comment)
    return s

def describe(docs, used, ident, com, s):
    """Atari's comment on the definition; where it has none, the note written here.

    A comment that is about another statement is not the definition's: a counter a
    macro steps (PH$EQ, VGVARB) carries the comment of the last call that stepped
    it, and define_docs.REPLACE names the others."""
    notes, replace = docs
    if s.get("redefined") and s.get("from_macro"):
        com = ""
    if ident in replace and com:
        used.add(ident)
        return replace[ident]
    if com.strip('" '):
        return com
    if ident in notes:
        used.add(ident)
        return notes[ident]
    return ""

def main():
    stale = 0
    for gname, F in FILES.items():
        docs, used = (define_docs.NOTES[gname], define_docs.REPLACE[gname]), set()
        g = macasm69.assemble(gname)
        symbols = g["symbols"]
        names = Names(symbols, g["out"])
        refs = {}
        for l in F["listings"]:
            refs.update(json.load(open(paths.build("refs_%s.json" % l)))["refs"])
        out = F["title"] + [
            ";Names are Atari's identifiers (MAC69 symbols are significant to 6 characters;",
            ";'.' -> '_' and '$' -> 'S_').  A name the source defines with two different",
            ";values keeps the name for the main one; the others get an _ADDR suffix.",
            ";Descriptions in upper case are Atari's comments on the definitions; those in",
            ";lower case were written for this disassembly (define_docs.py), from the source",
            ";and the code that uses the symbol, where the definition has no comment or the",
            ";comment on its line is about something else.",
            ";Generated by disasm/emit_defines.py; every symbol the listings use is here.",
            "",
            banner("Memory map"),
        ]
        for n, a, c in F["memory_map"]:
            out.append(fmt(n, a, c))
        done = set(n for n, _, _ in F["memory_map"])
        rows = collections.defaultdict(list)
        for s in symbols:
            if s["kind"] == "local":
                continue
            ident = names.ident.get((s["name"], s["addr"]))
            if ident is None or ident in done or names.rec[ident] is not s:
                continue
            a, k = s["addr"], s["kind"]
            com = words(s.get("comment") or "")
            sec = None
            if k == "io":
                sec = "Hardware registers"
            elif k == "ram":
                for title, lo, hi in F["ram"]:
                    if lo <= a < hi:
                        sec = title
            elif k in ("code", "data"):
                if ident in refs:
                    for title, im, lo, hi in F["rom"]:
                        if s["image"] == im and lo <= a < hi:
                            sec = title
                if sec is None:
                    continue                              # labels live in the listings
            elif ident in refs or (s["file"][:-4] in F["common"] and not s.get("redefined")
                                   and not s.get("from_macro")):
                sec = "Constants"
            if sec is None:
                if ident in refs:
                    sec = "Constants"
                else:
                    continue
            done.add(ident)
            rows[sec].append((a, ident, com, (s["file"], s["line"]), s))
        missing = [r for r in refs if r not in done]
        for r in missing:
            info = refs[r]
            rows["Constants"].append((info["addr"], r, words(info.get("comment") or ""),
                                      (info["file"], info["line"]), info))
            done.add(r)
        order = ["Hardware registers"] + [t for t, _, _ in F["ram"]] + [t for t, _, _, _ in F["rom"]]
        for sec in order:
            if not rows[sec]:
                continue
            out.append("")
            out.append(banner(sec))
            for a, ident, com, _, s in sorted(rows[sec], key=lambda x: (x[0], x[3])):
                out.append(fmt(ident, a, describe(docs, used, ident, com, s)))
        out.append("")
        out.append(banner("Constants"))
        last = None
        for a, ident, com, key, s in sorted(rows["Constants"], key=lambda x: x[3]):
            head = "%s  %s" % (s["file"], tidy(s.get("sbttl", "") or ""))
            if head != last:
                out.append(";" + head.strip())
                last = head
            out.append(fmt(ident, a, describe(docs, used, ident, com, s)))
        with open(os.path.join(HERE, F["out"]), "w", newline="\n") as fp:
            fp.write("\n".join(out) + "\n")
        cnt = ", ".join("%s %d" % (k, len(v)) for k, v in sorted(rows.items()))
        bare = [l.split()[1] for l in out if l.startswith(".alias") and ";" not in l]
        print("wrote %s: %s; %d identifiers referenced by the listings, all defined; "
              "%d descriptions from define_docs.py; %d aliases without a description%s"
              % (F["out"], cnt, len(refs), len(used), len(bare),
                 (": " + ", ".join(bare)) if bare else ""))
        for ident in sorted((set(docs[0]) | set(docs[1])) - used):
            print("!! define_docs.py: %s note for %s is not used (%s)" % (
                gname, ident, "no such alias" if ident not in done else
                "Atari's comment is there" if ident in docs[0] else "there is no comment to replace"))
            stale += 1
    return stale

if __name__ == "__main__":
    sys.exit(1 if main() else 0)
