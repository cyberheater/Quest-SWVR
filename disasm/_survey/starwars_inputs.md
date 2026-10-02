# Star Wars — survey of the inputs

What the disassembly started from, measured on 2026-10-01. Every number here is
printed by a tool in `disasm/`; none is taken from memory.

## ROM sets

Chips are found by CRC32 (`image.py`).

| part | CRC32 | size | where |
|---|---|---|---|
| 136021-214.1f | 04F1876E | 16K | rev 2: `$6000` bank 0 (first half), bank 1 (second half) |
| 136021-114.1f | E75FF867 | 16K | rev 1, same layout |
| 136021-102.1hj | F725E344 | 8K | `$8000` |
| 136021-203.1jk | F6DA0A00 | 8K | `$A000` |
| 136021-104.1kl | 7E406703 | 8K | `$C000` |
| 136021-206.1m | C7E51237 | 8K | `$E000` |
| 136021-105.1l | 538E7D2F | 4K | vector ROM `$3000` |
| 136021-107.1jk | DBF3AEA2 | 8K | sound `$4000` |
| 136021-208.1h | E38070A8 | 8K | sound `$6000` |
| 136021-110.7h, -111.7j, -112.7k, -113.7l | 810E040E, AE69881C, ECF22628, 83FEBFDE | 1K × 4 bits | matrix processor microcode |
| 136021-109.4b | 82FC3EB2 | 256 × 4 bits | AVG state PROM |

MAME's parent `starwars` is rev 2 (214 at 1F); `starwars1` is rev 1 (114 at 1F).
The two differ in two bytes of the bank-0 half:

| address | rev 1 | rev 2 | what |
|---|---|---|---|
| `$6164` | `B1` | `B0` | `CMPA P.RND1` becomes `SUBA P.RND1` in IPGEN's test for a stuck random-number generator |
| `$7A7C` | `9C` | `9D` | low byte of the ROM-0 checksum word `PCKS0` at `CHKSM0` |

## Atari's source archive

[historicalsource/star-wars](https://github.com/historicalsource/star-wars),
unzipped at `star-wars-main/`: 67 `.MAC` files (39,084 lines), link command
files, link maps and `.LDA` link images. Files are CRLF text padded with NULs
to 512-byte blocks; `WSROOT.MAP` and `WSOVLY.MAP` have lost their line
terminators.

### Link images against the ROMs

| image | date | loads | equals |
|---|---|---|---|
| `WSROOT.LDA` | 22-JUN-83 | `$3000-$3FED`, `$6000-$EB93`, `$EBB4-$EE49`, `$EE5A-$FFFF` — 44,990 bytes | `starwars1`, 0 differ |
| `WSOVLY.LDA` | 22-JUN-83 | `$6000-$7FFF` — 8,192 bytes | bank 1, 0 differ |
| `SNDAUX.LDA` | 15-JUN-83 | `$4000-$7FFF`, `$FFF8-$FFF9`, `$FFFE-$FFFF` — 16,388 bytes | sound ROMs, 0 differ |
| `AVGROM.LDA` | | 256 bytes | AVG state PROM 136021-109, 0 differ |
| `SWMP.LDA` | | `$0000-$02C3` and `$0400-$06C3` in three runs each, 640 bytes per half | the four microcode PROMs: the byte at `$0400+n` is PROM 110 (high nibble) and 111 (low nibble) at `n`; the byte at `$0000+n` is PROM 112 and 113. All 640 loaded addresses match in all four. |

`WSOVLX.LDA` is the first-pass overlay link and differs from the shipped bank 1
in 38 bytes. `JUN11*`, `JUN15*` and `JUN22*` are dated copies; `JUN22R.LDA`
equals `WSROOT.LDA`. The bytes `WSROOT.LDA` does not load are ROM fill:
`$3FEE-$3FFF`, `$EB94-$EBB3`, `$EE4A-$EE59`.

So the 22-JUN-83 source is revision 1, and it also carries the source of the
AVG state PROM and of the matrix processor microcode.

### Link structure

`LINKIT.COM` links three times: the overlay first (`WSOVLX`) to get its symbol
table, then the root with the overlay's symbols, then the overlay again with
the root's. The root and the overlay therefore share one pool of globals.

| image | modules, in link order |
|---|---|
| root | WSPROG WSMAIN WSFIL0 WSBASE WSCPU WSFIL1 WSGAS WSGLOW WSGRND WSGUNS WSLAZR WSFIL2 WSPANL WSSITE WSXPLD WSXMT TCEROM TCHSCR WSROOT WSMATH WSFIL3 WSVROM TCSPLS WSCOIN TCMES WSSTUB WSINT TCTEST WSFIL4 WSCKSM |
| overlay | WSPROG WSOVLY WSOBJ WSFIL9 WSSTAR, with WSGLOB in the first pass (it emits no ROM bytes and supplies the RAM globals) |
| sound | SNDGLB SWVOC3 SWMUS SNDAUD SNDPM SNDSPK SNDAUX SNFILL SNDSUM |

Includes: `WSCOMN` (which includes `HLL69F` and `MOP69`), `WSVGMC`, `WSVGAN`,
`WSVCTR`, `COIN69`, `DPCOIN`, `SNDCMN`, `SNDPBX`.

The maps give 33 root sections, 5 overlay sections and 12 sound sections (47
relocatable, plus the absolute section of each image), and 1,461 main and 185
sound globals. `macasm69.py` reproduces every one.

## The MAC69 dialect

What `macasm69.py` had to implement to reach zero differences:

- **MACRO-11 family.** Left-to-right expressions with `< >` grouping; `!` is
  OR and `?` is exclusive OR; six-character symbol significance, which also
  applies to macro and directive names (`.SBTTLE` is `.SBTTL`, `CONTINUE` is
  `CONTIN`); local `nn$` labels; `'c` character constants, folded to upper
  case.
- **Macros.** Arguments are separated by commas or blanks; `'` concatenates;
  a `\value` argument is passed as a **decimal** number (the page labels run
  `.PGX9`, `.PGX10`); macros define macros (`DEFIF`, `DEFEND`, `DEFTRR`);
  `.REPT`, `.IRP`, `.IRPC`, `.NARG`, `.MEXIT`.
- **Assembler stacks.** `.DEFSTACK`, `.PUSH`, `.POP`, `.GETPOINTER`: the
  structured-programming macros of `HLL69F` (`IFxx`, `ELSE`, `ENDIF`, `BEGIN`,
  `xxEND`) keep their branch fix-ups on them and patch each branch offset
  with `. = address`.
- **Sections.** `.ASECT`, named `.CSECT`s placed by the linker; `.GLOBL`,
  `.GLOBB`, `=`, `==`, `::`.
- **Data.** `.BYTE`, `.WORD` (big-endian), `.BLKB`, `.ASCII`, `.ASCIN` (bit 7
  set on the last character), `.VCTRS address,words`.
- **6809 operands.** Atari's own syntax, not Motorola's: `n(X)`, `(X)+`,
  `(X)++`, `-(X)`, `--(X)`, `A(X)`, `B(X)`, `D(X)`, `@` for indirection;
  register names `CCR` and `DPR`.
- **Addressing-mode choice.** Direct when the value is absolute, already
  defined, and its high byte is the `.DPAGE` in force; a `.GLOBB` external is
  direct too. Anything else — a forward reference, a relocatable label, a
  `.GLOBL` external — is extended. An indexed offset that is absolute and
  already defined takes the smallest form (none for 0, 5 bits, 8 bits); a
  `.GLOBB` external takes 8 bits; anything else takes 16.

No rule had to be guessed against the bytes beyond these; each was read from
the first statement where the assembly diverged from Atari's link image.

## Hardware, as the source and the AAE driver give it

Main 6809: vector RAM `$0000-$2FFF` (the top 2K, from `$2800`, holds display
lists the program copies down from ROM and runs as "pseudo vector ROM"),
vector ROM `$3000-$3FFF`, inputs `$4300-$439F`, sound latch `$4400-$4401`,
NVRAM `$4500-$45FF`, output latches `$4600-$46FF`, matrix processor and
divider `$4700-$4707`, CPU RAM `$4800-$4FFF`, matrix processor RAM
`$5000-$5FFF`, banked ROM `$6000-$7FFF`, ROM `$8000-$FFFF`.

Sound 6809 (`SNDCMN.MAC`): output latch `$0000`, input latch `$0800`, 6532
RAM `$1000-$107F` (direct page and stack), 6532 I/O `$1080-$109F`, four POKEYs
`$1800-$183F`, RAM `$2000-$27FF`, ROM `$4000-$7FFF`; A15 is not decoded.

Cross-checked against `starwars.cpp` of the
[AAE emulator](https://github.com/tcottrill/AAE).
