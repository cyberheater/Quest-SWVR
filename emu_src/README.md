# sw_emu — the emulator twin of the C port

`sw_emu.exe` runs the **real Star Wars ROMs** on two 6809 cores behind the same
window, beam renderer, audio path, controls, ini and command line as
[`../c_src/sw_win.exe`](../c_src/README.md), so the emulated ROM and the
translated C can be run side by side.

It is the machine the C port was verified against (the oracle of
[`docs/ORACLE.md`](../docs/ORACLE.md)), given a window.

**This directory is self-contained.** Every file in it is its own copy — the
chip models, the board, the Windows backend — and the build takes nothing from
`../c_src`. There is no translated C here, and there is no 6809 in the C
port's `sw_win.exe`.

## Files

| file | |
|---|---|
| `emu_main.cpp` | the machine for the host: runs the board up to the wall clock, makes the picture from the vector generator's display list and the sound from the four POKEYs and the speech chip, reads the switches and the yoke, keeps the NOVRAM |
| `board.cpp`, `board.h` | the two 6809s on the hardware: memory maps, the 246 Hz interrupt, one timeline |
| `hw.cpp` | the hardware without the CPUs: ports, latches, the link between the boards, RESET. Its header is the hardware model |
| `avg.c` | the vector generator, driven by its state PROM, exact to the master-clock tick |
| `mathbox.c` | the matrix processor (on its microcode PROMs), the divider, the random byte |
| `x2212.c`, `riot6532.c`, `tms5220.cpp`, `c012294.c` | NOVRAM, 6532, speech chip, POKEY |
| `cpu/` | the 6809 core, vendored from the [AAE emulator](https://github.com/tcottrill/AAE), unmodified |
| `platform/` | the platform contract and the Windows backend (window, OpenGL beam renderer, XAudio2 stream, raw input, joystick, ini, log, screenshots) |
| `build_emu.bat` | builds `sw_emu.exe`; objects in `obj\` |

The copies are the same files as in `../c_src` at the time of writing; a fix to
one that belongs in both has to be made in both.

## Build and run

    cmd /c ".\build_emu.bat"        (Visual Studio 2022, x64)
    sw_emu.exe

It reads the ROM images from `..\disasm\build` — build them once from your own
MAME `starwars` set in `..\roms` with `python ..\disasm\image.py`. No ROM data is in
the exe.

Keys, ini keys and command line are `sw_win.exe`'s: see the
[c_src README](../c_src/README.md#playing). Its settings are in `sw_emu.ini`
and its NOVRAM in `starwars.nv`, both next to the exe.

## The same game, twice

Run with the same script, the two programs show the same game — but not frame
for frame. The C port takes an interrupt at the next checkpoint (a routine
entry, a loop top, a hardware access), a few instructions later than the 6809
does; from then on the A-to-D converter and the random-number generator are
read a few cycles later than in the emulator, and the two games are two plays
of the same machine. What is identical is everything the verifier
compares routine by routine ([`docs/PORT.md`](../docs/PORT.md)), and the pace:
both run 1.512 million CPU cycles to the second, off the same vector generator
timing.
