"""Build the working images from a ROM set and regenerate and verify every listing.

    python gen_from_roms.py                     # ROMs from ../roms
    python gen_from_roms.py PATH [--check]      # a MAME zip, or a directory of zips / loose files

Steps, in order; any failing step prints `!!` and the exit status is 1:

  1. image.py        find the chips by CRC32, build the images, check the two
                     revisions differ only in the two known bytes, and that
                     Atari's link images equal the rev-1 ROMs
  2. macasm69.py     re-assemble Atari's source; bytes, section bases and sizes
                     and every global must equal the link images and maps
  3. emit.py         the four listings
  4. emit_defines.py the two defines files
  5. verify.py       independent read-back; every listing must show MISMATCHES : 0
  6. emit_shapes.py  shapes_preview.html

--check runs steps 3-6 a second time and requires byte-identical output.
Atari's source archive must be unzipped at ../star-wars-main.
"""
import hashlib, os, sys
HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)

OUTPUTS = ["starwars_program_rom.asm", "starwars_overlay_rom.asm", "starwars_vector_rom.asm",
           "starwars_sound_rom.asm", "starwars_defines.asm", "starwars_sound_defines.asm",
           "shapes_preview.html"]

def digest():
    h = {}
    for n in OUTPUTS:
        h[n] = hashlib.sha1(open(os.path.join(HERE, n), "rb").read()).hexdigest()
    return h

def step(title):
    print("\n== %s" % title)

def fail(msg):
    print("!! " + msg)
    sys.exit(1)

def generate():
    import emit, emit_defines, verify, emit_shapes
    step("emit.py")
    none = 0
    for w in emit.LISTINGS:
        d = emit.build(w)
        none += sum(1 for v in d.values() if v[1] == "none")
    step("emit_defines.py")
    if emit_defines.main():
        fail("emit_defines.py: define_docs.py has notes that are not used")
    step("verify.py")
    bad = sum(verify.run(*L) for L in verify.LISTINGS)
    if bad:
        fail("verify.py: %d mismatches" % bad)
    step("emit_shapes.py")
    emit_shapes.emit()
    return none

def main(argv):
    check = "--check" in argv
    args = [a for a in argv if not a.startswith("--")]
    import paths, image, macasm69
    paths.need(paths.SRC_DIR, "Atari source archive (unzip historicalsource/star-wars here)")
    step("image.py")
    image.build(args[0] if args else None)
    if image.check_lda():
        fail("Atari's link images differ from the rev-1 ROMs")
    step("macasm69.py")
    if macasm69.main([]):
        fail("macasm69.py: the source does not re-assemble to the link images")
    none = generate()
    if check:
        first = digest()
        step("second run (--check)")
        generate()
        diff = [n for n, h in digest().items() if first[n] != h]
        if diff:
            fail("output differs between two runs: %s" % ", ".join(diff))
        print("\nreproducible: %d files byte-identical over two runs" % len(first))
    print("\nall steps passed%s" % (
        "; %d routine headers still without a description" % none if none else ""))
    return 0

if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
