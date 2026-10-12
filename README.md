# Star Wars 1983 Arcade PCVR and Quest port

**Star Wars** (Atari, 1983) **in a VR headset**: you sit in the cockpit, the
TIE fighters, towers, trench and Death Star are drawn in 3-D around you, and a
Touch controller is your flight stick. It is the arcade game itself, not a
remake: Atari's program translated to C from the ROMs, with every vector it
draws placed where the game's own arithmetic put it in space.

| | |
|---|---|
| **Meta Quest, on its own** (2, 3, 3S, Pro) | `StarWarsQuest.apk`, a native app: no PC or cable once it is installed |
| **PC VR** (Windows; a Quest over Quest Link, Air Link or Virtual Desktop) | `sw_xr.exe`, in `StarWarsVR-win64.zip` |
| **No headset** | `sw_sdl.exe`, in the same zip: the game in a window |

**[Download the latest release](https://github.com/cyberheater/Star-Wars-Full-Disassembly-and-C-Port/releases/latest)**
&nbsp;·&nbsp; **[Install and play, step by step](docs/VR.md)**

**No ROM data is included.** You need your own MAME `starwars` ROM set; the
guide shows how to make the game's images from it.

- Flight stick in your hand: push forward to dive, pull back to climb. Triggers
  fire. Left-handed play is one button press.
- A pause menu in the headset: the size of the picture, how deep the 3-D is,
  how far away the stars are, and quit.
- The sight sits out in space where the lasers meet, not on a flat screen.

The VR source is [`c_src/platform/openxr/plat_openxr.cpp`](c_src/platform/openxr/plat_openxr.cpp)
(one file for both the PC and the Quest) on top of the 3-D tap,
[`c_src/sw3d.c`](c_src/sw3d.c). Everything below is the project it is built
on.

## The disassembly and the C port

An **AI-assisted disassembly of Star Wars** (Atari, 1983): the main 6809
program with both banks, the vector ROM and the sound board's 6809 program, as
plain assembler source that re-encodes to the ROMs byte for byte — and the
main program again **as C**, every routine checked against the ROM running on
a model of the board. The work was done with an AI assistant (Anthropic's
Claude) under one rule: **no invented data**. Every constant, table and branch
traces to a ROM address, and every name and upper-case comment is Atari's own,
placed on the ROM by re-assembling Atari's source.

Beside the port sits its **emulator twin**, [`emu_src/`](emu_src/README.md):
`sw_emu.exe` runs the real ROMs (your own — none is included) on two 6809
cores behind the very same window, sound, controls and chip models as the
port, so the original and the translation can be played side by side.

It follows the
[Tempest](https://github.com/tcottrill/Tempest-Full-Disassembly-and-C-Port),
[Gravitar](https://github.com/tcottrill/Gravitar-Full-Disassembly-and-C-Port),
[Space Duel](https://github.com/tcottrill/Space-Duel-Full-Disassembly-and-C-Port),
[Asteroids](https://github.com/tcottrill/Asteroids-Full-Disassembly-and-C-Port),
[Asteroids Deluxe](https://github.com/tcottrill/Asteroids-Deluxe-Full-Disassembly-and-C-Port),
[Lunar Lander](https://github.com/tcottrill/Lunar-Lander-Full-Disassembly-and-C-Port),
[BattleZone](https://github.com/tcottrill/BattleZone-Full-Disassembly-and-C-Port)
and [Omega Race](https://github.com/tcottrill/Omega-Race-Full-Disassembly-and-C-Port)
projects. This repository holds the disassembly, the oracle, both programs of
the machine as C, and two things to run: **`c_src/sw_win.exe`, the C port,
which plays** — window, sound, the flight yoke on the mouse, no 6809 in it —
and `emu_src/sw_emu.exe`, the real ROMs on 6809 cores behind the same window
(see [Status](#status)).

**[See every vector object in the game](https://tcottrill.github.io/Star-Wars-Full-Disassembly-and-C-Port/disasm/shapes_preview.html)**
— `shapes_preview.html`, drawn from the ROM: the character set, the vector
pictures, the 26 three-dimensional objects as wireframes you can turn, and
the messages.

## Quick start

Nothing here runs without a ROM set, and none is included.

1. Put a MAME `starwars` set (a zip, or loose files) in `roms/`.
2. `python disasm/image.py` — finds the chips by CRC32 and writes the working
   images to `disasm/build/`, where both programs read them at run time.
   (`python disasm/gen_from_roms.py --check` does the same and then rebuilds
   and verifies every listing; that needs Atari's source archive at
   `star-wars-main/`, see below. Reading the checked-in listings needs
   neither.)
3. Run [`c_src/sw_win.exe`](c_src/README.md#playing) (the C port) or
   [`emu_src/sw_emu.exe`](emu_src/README.md) (the ROMs on 6809 cores). Both are
   Windows programs and build from source with Visual Studio 2022
   (`c_src/build_win.bat`, `emu_src/build_emu.bat`).

## What's in the repository

| where | what |
|-------|------|
| [`disasm/`](disasm/README.md) | the four listings, two defines files, the shape preview page, and the Python tools that generate and verify all of it from a ROM set — among them `macasm69.py`, an assembler for Atari's 6809 source dialect |
| [`disasm/shapes_preview.html`](https://tcottrill.github.io/Star-Wars-Full-Disassembly-and-C-Port/disasm/shapes_preview.html) | one self-contained page drawn from the ROM: the 45-character set, 279 vector pictures, the 26 three-dimensional objects as wireframes you can turn, and the 214 messages |
| [`disasm/_survey/starwars_inputs.md`](disasm/_survey/starwars_inputs.md) | the survey the work started from: ROM sets, Atari's link structure, the source dialect, the memory map |
| [`c_src/`](c_src/README.md) | **the C port, playable** (`sw_win.exe`): the main program and the sound program as C — the translator, its output, the two hand-written routines — on models of the chips (the vector generator driven by its state PROM, the matrix processor by its microcode PROMs, 6532, POKEYs, speech chip), with the Windows backend. Also the oracle (the real ROMs on a 6809 core, with a scripted harness and its gates) and the verifier that runs every C routine against it. Builds with Visual Studio 2022 |
| [`emu_src/`](emu_src/README.md) | **the emulator twin** (`sw_emu.exe`): the real ROMs on two 6809 cores behind the same window, sound and controls. A separate program with its own copy of every file; nothing is shared with `c_src` at build time |
| [`docs/`](docs/) | [the hardware](docs/HARDWARE.md), with the source of every fact; [the oracle](docs/ORACLE.md), its gates and what it measured; [the C port](docs/PORT.md), its conventions, results and what is not verified |

## Sources, and what is not included

This is not blind reverse engineering. **Atari's own source code for Star
Wars** — the MAC69 sources, the link maps and the link images — is published
at [historicalsource/star-wars](https://github.com/historicalsource/star-wars).
It is not distributed here. The recovered listings are checked in, so nothing
here needs it to read them; the tools that rebuild them expect the archive
unzipped at `star-wars-main/`.

Hardware facts were cross-checked against the Star Wars driver of the
[AAE emulator](https://github.com/tcottrill/AAE).

## No ROMs included — bring your own

Atari's ROM images are not distributed. Given a MAME `starwars` ROM set in
`roms/`, one script builds the working images and regenerates and verifies
every listing:

```bash
python disasm/gen_from_roms.py --check
```

The chips are found by CRC32, not by file name, so a MAME zip, a directory of
zips or a directory of loose files all work. Regenerating reproduces the
checked-in files byte for byte.

## The listing is Atari's source, re-assembled

`disasm/macasm69.py` is an assembler for the MAC69 dialect Atari's sources are
written in: macros that define macros, the HLL69F structured-programming layer
built on assembler stacks, the vector macros, left-to-right expressions,
six-significant-character symbols, and Atari's own 6809 operand syntax. It
assembles all 45 modules of the three link images at the section bases of
Atari's link maps and compares the result with Atari's link images, with the
maps and with the ROMs.

| | |
|---|---|
| main program, bank 0 and the vector ROM: bytes emitted by the source, all matching | **44,990 / 44,990** |
| main program, bank 1 | **8,192 / 8,192** |
| sound program | **16,388 / 16,388** |
| relocatable sections with base and size equal to Atari's link maps | **47 of 47** |
| global symbols equal to Atari's link maps | **1,461** main, **185** sound |
| listings re-encoded from their text and compared with the ROMs | **69,632 bytes, 0 mismatches** |
| routine headers, each with a description | **650** — 559 from Atari's source, 91 written here and marked `[note]` |
| hardware registers, RAM variables and equates in the two defines files, each with a description | **1,530** — 840 with Atari's own comment (upper case), 690 written here (lower case) |

The 66 bytes that no source statement assembles — 18 at the end of the vector
ROM and 48 in the top program ROM — are ROM fill, and the listings say so.

## Two revisions, two bytes

Atari's source, linked on 22 June 1983, builds **revision 1** — MAME's
`starwars1` — exactly. The listings show **revision 2**, MAME's parent set
`starwars`. The two differ in two bytes: at `$6164` a `CMPA` became a `SUBA`
in the test for a stuck random-number generator, and at `$7A7C` the ROM
checksum word follows. Both lines are marked in the listing with the rev-1
value.

## What the archive also turned out to hold

- **The AVG state PROM.** `AVGROM.LDA` equals PROM 136021-109, all 256 entries.
- **The matrix processor microcode.** `SWMP.LDA` equals the four microcode
  PROMs 136021-110 to -113 at every address it loads, two PROMs to a byte.
- **Scrambled credits** in the ROM fill modules, which the listings show as the
  source spells them: `GREG RIVERA DID IT`, `EARL VICKERS DID AUDIO`, `MIKE
  HALLY WAS THE WHIPCRACKER`, `ERIC DURFEY GOT WIRED`, `JED MARGOLIN --
  ENGINEER EMERITUS`, `NORMAN AVELLAR WAS FIRST`.
- **Words in the Death Star's lights.** The dots on its dark side are letter
  shapes (`B.M`, `B.A`, `B.Y` ... in `WSVROM.MAC`). On alternate waves the
  city blocks spell `MAY THE FORCE` / `BE WITH YOU`, or `MARGOLIN`, `RIVERA`,
  `HALLY`, `AVELLAR`, `VICKERS` and `DURFEY`.

## Hardware, briefly

- **Main CPU:** 6809. `$6000-$7FFF` is banked between two halves of one 16K
  ROM; Atari's source calls bank 1 the overlay and links it separately.
- **Display:** Atari's colour Analog Vector Generator. Vector RAM is at
  `$0000-$2FFF` and vector ROM at `$3000-$3FFF`; the program also copies
  display lists from the program ROM into the top 2K of vector RAM and runs
  them there as "pseudo vector ROM".
- **Matrix processor:** a microcoded multiplier-accumulator with its own RAM at
  `$5000-$5FFF`, shared with the CPU, and a hardware divider.
- **Sound board:** a second 6809 with four POKEYs, a 6532 and a TMS5220 speech
  chip, talking to the main CPU through a pair of latches.

## Status

Steps 1 to 5 of 6 are done. The roadmap:

1. **Disassembly** — [`disasm/`](disasm/README.md).
2. **Oracle** — [`c_src/`](c_src/README.md): the real ROMs on a 6809 core with
   the board modelled, the vector generator timed by exact counting from its
   state PROM. Atari's own self test reports no errors on it, and six scripted
   scenarios run deterministically; see [`docs/ORACLE.md`](docs/ORACLE.md) and
   [`docs/HARDWARE.md`](docs/HARDWARE.md).
3. **C port of the main program** — [`c_src/`](c_src/README.md): all 590
   routines of both banks as C functions, generated from the listing (two
   written by hand), carrying an exact 6809 cycle clock. Against the ROM on
   the oracle, over 23 scripted scenarios — attract, games through the trench
   and the Death Star explosion, game over and initials, the operator's pages,
   the self test and every diagnostic — 24,559,885 routine calls, 778,576
   interrupts, 47,157 whole mainline passes and 25 runs from RESET all compare
   equal and take exactly the ROM's CPU cycles. 94.3 % of the program's
   instructions were executed in those runs; of the 20 routines not reached,
   12 have no reference anywhere in the ROM. See [`docs/PORT.md`](docs/PORT.md),
   including what is not verified.
4. **The sound program in C** — [`c_src/gen_snd/`](c_src/gen_snd/): the sound
   board's 108 routines, the same way, verified in the same runs against the
   oracle's sound 6809: 9,724,621 routine calls, 827,949 interrupts and 815,492
   passes of its 4 ms mainline, all equal and cycle-exact.
5. **Windows host and emulator twin** — two separate programs with the same
   window, sound and controls. [`c_src/sw_win.exe`](c_src/README.md#playing)
   is the C port: the two programs on the chip models, paced by their cycle
   clocks and the vector generator's PROM-counted draw time, with four POKEYs
   and the speech chip for sound. [`emu_src/sw_emu.exe`](emu_src/README.md) is
   the real ROMs on 6809 cores. Both hold machine time to the wall clock
   (measured 10.001 s in 10.003 s), and Atari's self test, run in C, reports
   no errors. Not judged by a player yet: how the yoke feels on a mouse, and
   the sound by ear.
6. The Empire Strikes Back, which has no surviving source: it reuses all of the
   above, and the Star Wars build supplies names for the code the two share.

## License

The disassembly and the tools are released under the **GNU General Public
License, version 2 or later**, the same terms as MAME. The names and comments
recovered from Atari's source archive remain Atari's; the archive itself is
not distributed here. Star Wars is a trademark of its owner, and no ROM images
are included.
