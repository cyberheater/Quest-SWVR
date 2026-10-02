# Star Wars (Atari, 1983) - annotated disassembly, revision 2

Byte-exact, fully labelled listings of the Star Wars CPU ROMs (MAME `starwars`),
built by re-assembling Atari's own source and checked against the ROM images
twice: against Atari's own link images, and by an independent read-back verifier.
The format follows the
[Tempest disassembly](https://github.com/tcottrill/Tempest-Full-Disassembly-and-C-Port).

[`shapes_preview.html`](shapes_preview.html) draws every vector object the
listings describe: the character set, the vector ROM pictures, the pictures the
program copies into vector RAM, and the 3-D objects.

## Regenerate and verify

```
cd disasm
python gen_from_roms.py --check                       # ROMs from ../roms
python gen_from_roms.py ../roms/starwars.zip --check  # or a zip / directory
```

`gen_from_roms.py` finds the chips by CRC32 (a MAME zip, a directory of zips or
loose files all work), writes the working images to `build/`, then runs:

1. `image.py` - the images; the two revisions must differ only in the two known
   bytes; Atari's link images must equal the rev-1 ROMs
2. `macasm69.py` - re-assembles the source; must print `0 differ`, `0 errors`,
   `sections 0 bad`, `globals 0/... bad` for all three images
3. `emit.py` - the four listings
4. `emit_defines.py` - the two defines files
5. `verify.py` - must print `MISMATCHES : 0` for all four listings
6. `emit_shapes.py` - `shapes_preview.html`
7. with `--check`: steps 3-6 again, and the output must be byte-identical

Any failing step prints `!!` and the exit status is 1. The individual scripts
can also be run on their own in that order.

Current result:

| | |
|---|---|
| source bytes against Atari's link images | root **44,990**, overlay **8,192**, sound **16,388** - 0 differ |
| relocatable section bases and sizes against the link maps | **47 of 47** |
| global symbols against the link maps | main **1,461**, sound **185** - all equal |
| program listing read-back | **40,960** bytes, 0 mismatches |
| overlay listing read-back | **8,192** bytes, 0 mismatches |
| vector listing read-back | **4,096** bytes, 0 mismatches |
| sound listing read-back | **16,384** bytes, 0 mismatches |
| instructions | 11,209 program, 1,800 overlay, 989 sound |
| routine headers, each with a description | **650** - 559 from Atari's source (139 of them from the comment on a call or on a table entry), 91 written here and marked `[note]` |
| operands printed with Atari's own symbols | 10,331; 16 fall back to hex with the source statement kept |

cc65 has no 6809 assembler, so there is no third-party assembler round trip as
on the 6502 projects. Atari's own link images are the independent check on the
assembler, and `verify.py` is the independent check on the listings.

## Files

| File | What |
|---|---|
| `starwars_program_rom.asm` | main program `$6000-$FFFF`, bank 0 at `$6000` - generated |
| `starwars_overlay_rom.asm` | bank 1 of `$6000-$7FFF` (address labels `Kxxxx`) - generated |
| `starwars_vector_rom.asm` | vector ROM `$3000-$3FFF` - generated |
| `starwars_sound_rom.asm` | sound program `$4000-$7FFF` on the sound CPU - generated |
| `starwars_defines.asm` | main CPU: memory map, hardware registers, RAM variables, constants - generated |
| `starwars_sound_defines.asm` | the same for the sound CPU - generated |
| `shapes_preview.html` | every vector object, drawn from the ROM - generated |
| `gen_from_roms.py` | driver (above) |
| `image.py` | ROM set to working images, by CRC32 |
| `macasm69.py`, `macsrc.py`, `rtexpr.py`, `m6809.py` | assembler for Atari's MAC69 source dialect; writes `build/symbols_*.json`, `build/macasm69_report.md` |
| `linkmap.py`, `lda.py` | readers for Atari's link maps and link images |
| `emit.py` | listing generator; also `build/refs_*.json` (identifiers used, routine list) |
| `routine_docs.py` | hand-written routine descriptions, used only where the source says nothing |
| `emit_defines.py` | defines generator |
| `define_docs.py` | hand-written descriptions for the defines, used only where the source has no comment |
| `verify.py` | independent read-back: re-encodes every line of the listings and compares with the images |
| `avg.py`, `emit_shapes.py` | AVG display-list decoder and the preview page |
| `sgrep.py` | grep for the NUL-padded source files |
| `_survey/starwars_inputs.md` | the survey: ROM sets, link structure, the MAC69 dialect, memory map |

Inputs, none of them distributed here: a ROM set (`../roms/*.zip`, or the path
given on the command line); Atari's source archive,
[historicalsource/star-wars](https://github.com/historicalsource/star-wars),
unzipped so the `.MAC` files are at `../star-wars-main/`. Hardware notes came
from the Star Wars driver of the [AAE emulator](https://github.com/tcottrill/AAE).

## Revision

Atari's 22-JUN-83 source builds **revision 1** (MAME `starwars1`) exactly. The
listings show **revision 2**, MAME's parent set, which differs in two bytes:

- `$6164`: `CMPA P.RND1` became `SUBA P.RND1`, in IPGEN's test for a stuck
  random-number generator;
- `$7A7C`: the low byte of the ROM-0 checksum word, `$F79C` to `$F79D`.

Both lines carry a `rev 2 patch` note with the rev-1 value. The instruction at
`$6164` is decoded from the rev-2 ROM, not taken from the source.

## Conventions (listings)

- Directives: `.org`, `.include`, `.alias NAME $VALUE`, `.byte`, `.word`.
  `.word` is big-endian, as the 6809 stores it.
- Motorola mnemonics and operand syntax (`LDD ,X++`, `JSR [A,X]`, `PSHS A,B,X`,
  `TFR A,DP`), with Atari's spelling of a mnemonic kept where it has two
  (`BHS`, `BLO`, `LSLA`). Atari's source writes operands differently
  (`0(X)++`, `@A(X)`, `PSHS X,CCR,DPR`); the comment on a macro line shows it.
- `( )` groups expressions, because `[ ]` is indirection. `~` is one's
  complement, `|` is OR, `^` is exclusive OR. MAC69 evaluated strictly left to
  right; the listing makes that explicit with parentheses.
- `.dpage $xx` gives the direct page the assembler assumed. An address whose
  high byte is that page is direct; any other is extended. An indexed offset
  takes the smallest form that holds it (none for 0, 5 bits, 8 bits, 16 bits),
  as a 16-bit two's complement value, so an equate of `$FFF0` is -16. `<` and
  `>` before an operand force the short and the long form; they appear exactly
  where the ROM holds another encoding than the natural one - mostly where the
  source referred to a symbol the assembler could not yet size.
- Every code and data line starts with its address label, `Lxxxx:`, or `Kxxxx:`
  in the overlay. Named labels sit on their own line above it. A label that
  falls inside a line is an `.alias` right after that line.
- Names are Atari's (6 significant characters in MAC69), with `.` -> `_` and
  `$` -> `S_` (`AM.PTR` -> `AM_PTR`, `$$CRDT` -> `S_S_CRDT`). Local `10$`
  labels become `SCOPE_10`. A name defined twice with different values keeps
  its name for the main definition; the others get `_ADDR`. The root and the
  overlay each have a bank-switching vector table with the same names; the
  root's keep the plain name.
- Operands are the source's own expressions with the source's symbols. An
  expression is used only if it yields exactly the ROM bytes; otherwise the
  operand is hex and the source statement is kept as `(src: ...)` in the
  comment. Numbers-only expressions are printed as hex. Branch targets are
  always labels.
- Data keeps the source's statement layout (one line per source statement, at
  most 8 bytes or 4 words per line); macro-generated data carries the macro
  call as its comment (`;.P -10,-16,18`, `;VCTR 0,16,.BRITE`, `;JSRL CHAR.A`).
- Module banners mark each linked source module, with its `.TITLE`; `;.SBTTL`
  lines carry Atari's section titles where no routine header does.
- Comments: upper case = Atari's source comment, verbatim; for macro statements
  the macro call comes first (`;IFEQ`, `;HSEND`, `;ELSE` show the HLL69F
  structure). Comment-only lines from Atari's comment blocks are kept above
  the statement they precede.
- Routine headers (a `;----` block before each routine entry: a code label that
  is a JSR/BSR target or a jump-table entry, starts a module, or follows
  RTS/RTI/JMP/BRA): `; NAME - description`. Description sources, in priority
  order:
  1. Atari's source: the `.SBTTL` title starting there, the label's own
     comment, the comment block above the label; else the comment on the calls
     to it, marked `(comment at the call)`; else the comment on its entry in a
     jump table, marked `(comment at its table entry)`;
  2. `[note]`: written for this disassembly from reading the code
     (`routine_docs.py`).
- Bytes no statement assembles (`$3FEE-$3FFF`, `$EB94-$EBB3`, `$EE4A-$EE59`)
  are listed as ROM fill and say so.

## Conventions (defines)

Sections: `Memory map` (descriptive names), `Hardware registers` (Atari's I/O
equates), the RAM regions, the labels one listing uses that another defines,
and `Constants` (every constant of the common files plus every module equate a
listing uses, grouped by file and `.SBTTL`). Format `.alias NAME $VALUE
;comment`. Every identifier the listings use is defined, and every alias has a
description: upper case is Atari's comment on the definition; lower case was
written for this disassembly (`define_docs.py`, 552 for the main CPU and 120
for the sound CPU), from the defining statement and the code that uses the
symbol - where the definition has no comment, or the comment on its line is
about another statement. `emit_defines.py` fails on a note that no alias uses.

## Credits

- **Star Wars** program and source code: Atari, Inc., 1983. Source archive
  [historicalsource/star-wars](https://github.com/historicalsource/star-wars).
  The people the archive names: Ed Logg for the vector macros (VGMC), "updated
  for Star Wars by GregR and Norm A."; Jed Margolin for the hardware, the
  speech and test programs and the matrix processor microcode; Dennis
  Halverson for the AVG state PROM. The ROM fill modules carry scrambled
  credits of their own, which the listings show as the source spells them:
  `GREG RIVERA DID IT` (WSFIL0), `EARL VICKERS DID AUDIO` (WSFIL1), `MIKE
  HALLY WAS THE WHIPCRACKER` (WSFIL2), `ERIC DURFEY GOT WIRED` (WSFIL3), `JED
  MARGOLIN -- ENGINEER EMERITUS` (WSFIL4), `NORMAN AVELLAR WAS FIRST`
  (WSFIL9).
- Hardware notes: the AAE Star Wars driver (`starwars.cpp`).
- Listing format and tooling pattern: the Tempest and Space Duel disassembly
  projects.
