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

On **macOS or Linux** the same game builds on SDL2 as `sw_sdl` ([`platform/sdl/plat_sdl.cpp`](platform/sdl/plat_sdl.cpp), [`CMakeLists.txt`](CMakeLists.txt)):

```sh
brew install cmake sdl2                # Linux: apt install cmake libsdl2-dev libgl-dev
python3 ../disasm/image.py             # once: ROM images from your MAME starwars set in ../roms
cmake -S . -B build && cmake --build build -j
./sw_sdl
```

The keys are the same; it reads `sw_sdl.ini` (the same sections as `sw_win.ini`), and `--dump FILE` writes every picture's lines as text.

The CMake build also has the **3-D tap** (`SW_3D`, on by default; [`sw3d.h`](sw3d.h)): it watches the game's own perspective divides and gives every drawn line its point in the game's 3-D space (TIE fighters, Vader, towers, bunkers, the trench, the Death Star, stars, fireballs, lasers), while scores, messages, the sight and the cockpit stay a flat HUD. **F5** shows the world from a camera of your own: J/L turn, I/K look up and down, U/O step aside, Y/H move ahead and back, R/F rise and fall, 0 back to the cockpit (`--view3d YAW,PITCH,SIDE,BACK,UP` starts there). `SW_DUMP3D=FILE` writes each line with its 3-D ends, and `tools/view3d.py` draws a picture of that from elsewhere. The tap only watches: the machine runs cycle for cycle as without it.

On **Windows** the CMake build works with Visual Studio 2022 and vcpkg (`vcpkg install sdl2:x64-windows openxr-loader:x64-windows`):

```bat
cmake -S . -B build -G "Visual Studio 17 2022" -A x64 -DCMAKE_TOOLCHAIN_FILE=<vcpkg>\scripts\buildsystems\vcpkg.cmake
cmake --build build --config Release
```

and, with the OpenXR loader found, it also builds **`sw_xr.exe`**: the game in a headset ([`platform/openxr/plat_openxr.cpp`](platform/openxr/plat_openxr.cpp); OpenXR with OpenGL - a Quest over Quest Link or Air Link, or any PC headset). The world is drawn for each eye from where the head is, at the headset's rate; the HUD is on a panel ahead, at the size at which the sight stays on what the guns hit. The right controller is a flight stick: pushed or tipped forward it dives, pulled or tipped back it climbs, leaned or moved to a side it goes there. The triggers are the triggers, the grips the thumb buttons, A or X a coin, B or Y (or Home) centres the view and takes the handles as they are held for the yoke at rest; the thumbsticks move the yoke too, the mouse and the keys work as in `sw_sdl` while the window has the focus, and the window shows the left eye. The sight is out where the lasers end. F9 steps through the flight stick, a yoke (the two controllers as its handles: turned like a wheel, raised and lowered), pointing the right controller where the sight should go, and the thumbsticks alone; PageUp / PageDown change the size of the world, - and = how large the whole picture is to the eye, F10 moves the HUD panel. `sw_xr.ini` has the sections of `sw_sdl.ini` and `[vr]`: `unit_metres` (one of the game's units, 0.005; smaller is nearer and deeper), `star_depth` (the stars' depth in the game's units, 65536: a sky behind the ships; 0 leaves them among the ships, as the game has them), `view_scale` (the whole picture's size to the eye, 0.675; 1 is the tube's own 90 degrees across), `hud_distance` (3), `hud_scale` (1), `aim` (`flight`, `yoke`, `point` or `stick`), `flight_hand`, `flight_tilt` and `flight_reach` (the stick's hand, and the degrees it tips and metres it moves for full travel, 30 and 0.12), `yoke_turn` and `yoke_lift` (degrees of turn and metres up or down for the yoke's full travel, 40 and 0.15), `aim_range` (the same for pointing, 30), and `runtime` (an OpenXR runtime's `.json`, for when the headset's is not the system's active one). `sw_xr --flat` runs in the window without a headset.

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
