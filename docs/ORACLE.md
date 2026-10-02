# Star Wars — the oracle

`c_src/tests/refrun.exe` runs the real Star Wars ROMs on a 6809 core with the
board modelled around them, from a script, and records what the ROM did. It is
the reference the C port (step 3) will be compared with. The hardware model is
the header of [`c_src/board.cpp`](../c_src/board.cpp); the reasons for each
choice are in [HARDWARE.md](HARDWARE.md).

## Running it

```bat
cd disasm
python image.py              &rem ROM images into disasm\build (needs ..\roms)
cd ..\c_src
build_all.bat                &rem Visual Studio 2022
python tools\run_gates.py    &rem every scenario, every gate
```

`refrun.exe` on its own takes a script and writes a schedule, state dumps, the
vector-generator log and the coverage; its header lists the options.

## Gates

Results of `tools/run_gates.py` on rev 2 (and one boot on rev 1). Each
scenario is run twice and the two runs compared; its recorded display lists
are checked against `tools/avg_prom_sim.py`.

| scenario | passes | CPU cycles | main PCs | sound PCs | VG runs | lists checked | result |
|---|---|---|---|---|---|---|---|
| boot | 300 | 33,454,700 | 1,890 | 290 | 595 | 70 | pass |
| boot, rev 1 | 300 | 33,454,700 | 1,890 | 290 | 595 | 70 | pass |
| attract | 1,500 | 140,659,976 | 2,114 | 290 | 2,800 | 92 | pass |
| coin and start | 400 | 36,053,621 | 2,817 | 527 | 783 | 72 | pass |
| played game | 1,400 | 129,186,264 | 6,593 | 726 | 3,157 | 96 | pass |
| self test | 420 | 44,479,948 | 2,437 | 350 | 837 | 69 | pass |

A scenario passes when the run reaches its end with no unmapped access, no
fault reported by the 6809 core, no `SWI` (the program's own error trap), no
matrix-processor runaway, no vector buffer overflow, and no watchdog bite
other than the one the self test asks for.

### Atari's self test, as a test of the model

With the test switch closed the program runs its own diagnostics, and the
oracle checks which of its result branches the ROM executed:

| reached | never reached |
|---|---|
| `$F5AA` "NO ERRORS DETECTED" — RAM, math RAM, vector RAM, NOVRAM, six ROM checksums | `$F5B1` a hardware error message |
| `$FA2A` "NO DIVIDER ERRORS" | `$FA2E` "DIVIDER ERRORS" |
| `$FAD2` "NO MATRIX ERRORS" | `$FAD6` "MATRIX ERRORS" |
| `$F720` `HANG`, then exactly one watchdog bite | `$F97F` "BAD MATHBOX READY LINE" |

So the divider and the matrix processor give Atari's expected answers for
every entry of Atari's test tables, the matrix processor's busy time is inside
the window Atari's ready-line test allows, and the NOVRAM behaves as a 4-bit
RAM. The ROM checksum loops, the RAM tests and the rest of the run are also
the main evidence for the 6809 core, which has no separate test suite here.

### The vector generator, checked twice

`avg.c` and `avg_prom_sim.py` are two implementations of the same state
machine, in C and in Python. For 469 recorded display lists they agree on the
tick count from `VGGO` to `HALT` and on every beam point. This catches a slip
in either; it does not test the model they share, which is MAME's.

## What the oracle measured

**The picture sets the frame rate.** The IRQ makes a game frame due every 12
interrupts, 48.8 ms: "20 PER SECOND" in Atari's comment. The mainline then
waits for the display buffer, so a heavy picture stretches the frame. From the
played-game scenario:

| phase | passes | mean pass | passes / s | IRQs / pass |
|---|---|---|---|---|
| `$0E` select a Death Star | 217 | 48.8 ms | 20.5 | 12.0 |
| `$06` attract: flight instructions | 37 | 48.8 ms | 20.5 | 12.0 |
| `$08` attract: scoring page | 119 | 57.5 ms | 17.4 | 14.2 |
| `$2A` ground | 438 | 60.7 ms | 16.5 | 14.9 |
| `$20` space wave | 380 | 67.8 ms | 14.7 | 16.7 |
| `$0C` attract: banner | 60 | 73.7 ms | 13.6 | 18.1 |

A display list that draws anything takes 9.4 to 36.2 ms on the oracle (mean
21.3 ms), and `VGGO` follows `VGGO` every 26.6 ms on average. These are
properties of the model — the state PROM's timing as MAME counts it, and the
6809 core's cycle counts — and have not been compared with a real board.

**Interrupts during power-on.** `RESET` keeps interrupts masked for about 1.4
seconds while the NOVRAM settles; 331 of the periodic interrupts arrive in that
time with one already waiting, and are absorbed, as on the board.

## Coverage, and what is missing

The played game executes 6,593 distinct main-CPU PCs and 726 sound-CPU PCs. It
gets through the space wave and the surface approach and dies on the ground:
the scripted player does not shoot well enough to reach the trench, so the
trench, the exhaust port and the Death Star explosion are not exercised yet.
Step 3 needs scenarios that reach them before the routines in those phases can
be verified.

## Files

| | |
|---|---|
| `c_src/board.cpp`, `board.h` | the machine and the contract |
| `c_src/avg.c`, `mathbox.c`, `x2212.c`, `riot6532.c` | chip models, plain C |
| `c_src/tms5220.cpp` | AAE's speech chip core |
| `c_src/cpu/` | AAE's 6809 core, unmodified, with three shim headers |
| `c_src/tests/refrun.cpp` | the harness |
| `c_src/tests/scenarios/` | the scripts |
| `c_src/tests/ref_*/` | per scenario: `frame_sched.txt`, `avg_runs.txt`, `ref_index.json`, coverage |
| `c_src/tools/run_gates.py`, `avg_prom_sim.py`, `gen_play_script.py` | gates, the AVG cross-check, the play script generator |

The state dumps (`frame_NNNN.*`) and display-list dumps are recorded from the
running ROM and are not checked in; `run_gates.py` records them again,
identically.
