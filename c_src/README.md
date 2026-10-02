# c_src — Star Wars in C

**Both of the machine's programs are C here, and it plays**: the main program
(both banks, 590 routines) and the sound board's program (108 routines), one C
function per routine, running on models of the board's chips in a window with
sound and the flight yoke on the mouse. There is no 6809 in `sw_win.exe`.

Also here: the **oracle** — the real ROMs on a 6809 core — and the verifier
that runs every C routine against it. (The oracle with a window, the emulator
twin, is a separate program with its own copy of every file:
[`../emu_src`](../emu_src/README.md).)

## Playing

```bat
python ..\disasm\image.py             &rem once: ROM images from your MAME starwars set in ..\roms
build_win.bat                         &rem Visual Studio 2022
sw_win.exe
```

No ROM data is in the exe: it reads the images from `..\disasm\build`.

| action | keys |
|---|---|
| flight yoke | mouse (it moves the yoke, which stays where it is put); arrow keys (spring back to centre); joystick |
| triggers | left mouse button / Left Ctrl (right trigger), right mouse button / Left Alt (left trigger) |
| thumb buttons | Space (right), Shift (left) |
| coins | 5 left, 6 right, 7 aux |
| start | any trigger or thumb button, with a credit in; then aim at a Death Star and fire |
| self-test switch | **F2**, a latching switch: in the attract mode it shows the statistics page (7, the aux coin, goes on to the options page; 7 again resets into the self test); closed at power-on (`--test`) it runs Atari's self test |
| diagnostic switch | **F1** (with the self-test switch, at power-on: the diagnostics the option switches select) |
| slam | F3 |
| sound board test switch | **F4**: the sound board plays every sound, tune and phrase in turn |
| other | F8 mouse capture on/off, Alt+Enter fullscreen, Esc quit |

`sw_win.ini` beside the exe is read at start and written back with the values
that took effect: `[dips] dsw0 dsw1` (the two option switch banks, raw),
`[vector]` brightness, line width and smoothing, phosphor, `[input]` mouse
sensitivity, key rate, `invert_pitch`, `[sound]` volumes and latency, `[main]`
`vsync` and `rom_dir`. The NOVRAM (high scores, statistics, options) is
`starwars.nv`.

Command line: `--test` (self-test switch closed at power-on), `--rev 1|2`,
`--romdir DIR`, `--nvram FILE`, `--no-nvram`; and for testing `--script FILE`
(a `tests\scenarios` script), `--passes N`, `--quit-after-ms MS`, `--turbo`
(no pacing, no window), `--hidden`, `--shot N FILE.png` (the picture at pass N;
`pN` = at picture N), `--wav FILE`, `--stats FILE`.

## Verifying

```bat
build_all.bat                 &rem tests\refrun.exe, tests\lockstep.exe, tests\cyctab.exe
python tools\run_gates.py     &rem the oracle: six scenarios, every gate
python tools\run_lockstep.py  &rem both C programs against the ROMs, 23 scenarios, then the coverage
```

Results, conventions and what is not verified: [`../docs/PORT.md`](../docs/PORT.md).

## What is where

The two programs:

| | |
|---|---|
| [`gen/`](gen/) | the main program: one `.c` per Atari source module, `sw_defs.h` (every identifier of the listings), `sw_proto.h`, `registry.c` (every routine by address, and every checkpoint) |
| [`hand/mainline.c`](hand/mainline.c) | the two routines of it written by hand: the frame wait and `MAIN` |
| [`gen_snd/`](gen_snd/) | the sound program, the same way (`snd_defs.h`, `snd_proto.h`) |
| [`sw.h`](sw.h), [`sw_rt.c`](sw_rt.c) | the runtime both are written against: machine state, the 6809 registers as globals, memory access, flag helpers, the cycle clock, the hardware seam. The sound program's files compile it with `SW_SND_PROGRAM` |
| [`tools/xlate.py`](tools/xlate.py) | the translator: the verified listing in, structured C out (`xlate.py`, `xlate.py sound`) |

`gen/` and `gen_snd/` are generated: a fix goes into `tools/xlate.py` or into
`hand/`, never into a generated file.

The machine they run on:

| | |
|---|---|
| [`port.cpp`](port.cpp) | the hardware seam for a real run: each program on a fiber of its own, interrupts taken at checkpoints, the two cycle clocks |
| [`app.cpp`](app.cpp) | the machine for the host: runs it up to the wall clock, makes the picture and the sound from the chips |
| [`hw.cpp`](hw.cpp) | the hardware without CPUs; its header is the hardware model |
| [`avg.c`](avg.c) | the vector generator, driven by the state PROM, exact to the master-clock tick |
| [`mathbox.c`](mathbox.c) | matrix processor (on its microcode PROMs), divider, random byte |
| [`x2212.c`](x2212.c), [`riot6532.c`](riot6532.c), [`tms5220.cpp`](tms5220.cpp), [`c012294.c`](c012294.c) | NOVRAM, 6532, speech chip (from AAE), POKEY (from the Tempest port) |
| [`platform/`](platform/) | the platform contract and the Windows backend, from the Tempest port |

The oracle and the verifier:

| | |
|---|---|
| [`board.cpp`](board.cpp), [`cpu/`](cpu/README.md) | the two 6809 cores (AAE's, unmodified) on `hw.cpp` |
| [`tests/refrun.cpp`](tests/refrun.cpp) | the harness: script in, schedule, dumps, logs and a verdict out |
| [`tests/lockstep.cpp`](tests/lockstep.cpp) | the verifier, linked with the harness into `tests\lockstep.exe`, compiled once for each program |
| [`tests/cyctab.cpp`](tests/cyctab.cpp) | the cycle count of every instruction, measured on the oracle's core, for the translator |
| [`tools/`](tools/) | `run_gates.py`, `run_lockstep.py`, `avg_prom_sim.py` (the vector generator again, in Python), `gen_play_script.py` (writes the played-game scenarios) |
| [`tests/scenarios/`](tests/scenarios/) | the scripts |
| [`tests/lockstep_coverage.txt`](tests/lockstep_coverage.txt), [`tests/lockstep_coverage_sound.txt`](tests/lockstep_coverage_sound.txt) | every routine: how it was compared, and the instructions no scenario executed |

Gate results of the oracle, what Atari's self test proves about the model, and
the timing it measured are in [`../docs/ORACLE.md`](../docs/ORACLE.md); the
board, with the source of every fact, is in
[`../docs/HARDWARE.md`](../docs/HARDWARE.md).
