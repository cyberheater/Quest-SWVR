# Star Wars — the C port

Both of the machine's programs as C, with no 6809 core at run time:

| | routines | instructions | written by hand |
|---|---|---|---|
| main program, both banks (`c_src/gen/`, `hand/`) | 590 | 13,009 | 2 (the frame wait and `MAIN`) |
| sound program (`c_src/gen_snd/`) | 108 | 989 | none |

One C function per routine, generated from the verified listings by
`c_src/tools/xlate.py`. They are verified against the oracle
([ORACLE.md](ORACLE.md)) call by call, pass by pass and from RESET, cycle for
cycle, by `c_src/tests/lockstep.exe`.

They play: `c_src/sw_win.exe` runs the two programs on models of the board's
chips, in a window, with sound ([c_src/README.md](../c_src/README.md)). The
real ROMs behind the same window are a separate program,
[`emu_src/sw_emu.exe`](../emu_src/README.md).

## Running the verification

```bat
cd c_src
build_all.bat                 &rem tests\refrun.exe, tests\cyctab.exe, tests\lockstep.exe
python tools\xlate.py         &rem the listings -> gen\*.c      (checked in; reproduces them)
python tools\xlate.py sound   &rem                -> gen_snd\*.c
python tools\run_lockstep.py  &rem all 23 scenarios, both programs, then the coverage
```

`lockstep.exe` takes `refrun.exe`'s options (it is the same harness with the
verifier linked in, once for each program), plus `--lk-verbose N` and
`--lk-reached FILE`.

## Results

`tools/run_lockstep.py`, revision 2 ROMs (and one boot on revision 1). Each
scenario verifies both programs in the same run: the main program on the
oracle's main 6809, the sound program on its sound 6809.

| scenario | passes | main: calls | interrupts | passes | sound: calls | interrupts | passes |
|---|---|---|---|---|---|---|---|
| boot | 300 | 133,672 | 5,113 | 299 | 51,334 | 5,398 | 5,399 |
| boot, rev 1 | 300 | 133,672 | 5,113 | 299 | 51,334 | 5,398 | 5,399 |
| attract | 1,500 | 510,259 | 22,561 | 1,499 | 215,893 | 22,720 | 22,721 |
| coin and start | 400 | 128,581 | 5,533 | 399 | 55,723 | 5,822 | 5,819 |
| played game | 1,400 | 681,352 | 20,693 | 1,399 | 280,206 | 21,214 | 20,869 |
| self test | 420 | 78,869 | 2,839 | 159 | 68,259 | 7,176 | 7,176 |
| waves (kept alive: surface, trench, two explosions) | 9,000 | 5,502,663 | 160,225 | 8,999 | 1,947,565 | 162,599 | 159,396 |
| waves, easy Death Star | 2,500 | 1,357,943 | 40,184 | 2,499 | 516,472 | 41,011 | 40,219 |
| waves, hard Death Star | 7,000 | 4,237,148 | 121,661 | 6,999 | 1,534,528 | 124,138 | 121,110 |
| waves, late wave numbers | 5,000 | 3,040,624 | 87,956 | 4,999 | 1,111,452 | 89,787 | 87,648 |
| first space wave straight to the trench | 1,600 | 918,041 | 26,862 | 1,599 | 323,560 | 27,403 | 26,993 |
| the trench flown on the Force | 2,400 | 1,363,092 | 39,817 | 2,399 | 495,782 | 40,566 | 39,855 |
| space wave five | 1,000 | 505,735 | 14,789 | 999 | 189,786 | 15,202 | 15,007 |
| wave six (bishop buildings) | 1,500 | 769,903 | 22,497 | 1,499 | 294,986 | 23,185 | 22,660 |
| alien ships that take five hits | 1,000 | 473,831 | 14,169 | 999 | 183,908 | 14,574 | 14,392 |
| game over, initials, high scores | 3,600 | 1,463,329 | 61,006 | 3,599 | 688,182 | 61,309 | 60,889 |
| lost in the space wave | 900 | 336,609 | 14,857 | 899 | 169,140 | 15,100 | 15,074 |
| lost in the trench | 2,200 | 1,045,217 | 35,732 | 2,199 | 433,915 | 36,279 | 35,799 |
| operator's statistics and option pages | 900 | 305,030 | 12,159 | 899 | 117,787 | 12,393 | 12,394 |
| a game, then statistics, options, the NOVRAM test | 1,300 | 447,077 | 17,521 | 1,299 | 194,258 | 17,745 | 17,718 |
| power-on with the NOVRAM that run left | 500 | 189,991 | 6,865 | 499 | 67,840 | 7,136 | 7,136 |
| diagnostics, every test number | 780 | 57,834 | 2,119 | 119 | 318,345 | 33,443 | 33,466 |
| the sound board's test switch: every sound in turn | 2,600 | 879,413 | 38,305 | 2,599 | 414,366 | 38,352 | 38,353 |
| **total, 23 scenarios** | | **24,559,885** | **778,576** | **47,157** | **9,724,621** | **827,949** | **815,492** |

RESET regions: 25 for the main program, 210 for the sound program (the
diagnostics reset the sound board over and over).

**Every one compared equal, none left uncompared** (`tainted` 0), **and every
one took exactly the ROM's CPU cycles.**

What "equal" means:

- **Routine call.** From the ROM's arrival at the routine to its return, the C
  function run from the same machine state leaves the same RAM (and math RAM
  and vector RAM), makes the same hardware accesses with the same values in
  the same order, passes the same checkpoints in the same order, returns the
  same A, B, X, Y, U, S and DP and the condition codes its callers read, and
  has charged the same number of CPU cycles.
- **Interrupt.** The same, for the interrupt handler from the interrupt to its
  `RTI`.
- **Whole pass.** The mainline itself, from one start of it to the next: for
  the main program from `$602F` (the start of a game frame) round to `$602F`;
  for the sound program from `MAIN` round to `MAIN`, every 4 ms.
- **RESET region.** From RESET to the first pass, or — with the self-test
  switch on — from RESET through the whole self test or the whole diagnostic
  session to the `HANG` loop where the watchdog bites.

And at every hardware access and checkpoint the C's cycle clock was compared
with the ROM's: 440 million for the main program and 193 million for the sound
program, none at another cycle.

### Coverage

| | main program | sound program |
|---|---|---|
| routines | 590 | 108 |
| reached by a scenario | **570** | **105** |
| — with call checks of their own, all equal | 517 | 101 |
| — compared only inside a pass, a RESET region or the interrupt | 53 | 4 |
| not reached | 20 | 3 |
| instructions | 13,009 | 989 |
| executed by the ROM in a run that compared equal | **12,267 (94.3 %)** | **885 (89.5 %)** |
| not executed: in the routines not reached | 138 | 83 |
| not executed: untaken paths of reached routines | 604 | 21 |

`c_src/tests/lockstep_coverage.txt` and `lockstep_coverage_sound.txt` list
every routine with how it was compared and the addresses of its instructions
that no scenario executed.

The 20 main-program routines not reached. "No reference" was checked three
ways for each: no call, jump or branch to it in either bank; nothing falls
into it; and its address does not occur as a word anywhere in the program ROM,
in code or in a table (the two chance matches, inside unrelated data, were
looked at).

| why | routines |
|---|---|
| no reference of any kind: dead code, in the game and in test mode alike | `MESSOFF` `SCRALL` `GDHTGT` `MOVBLC` `MOVBRC` `BCDBIN` `ASRD8` `AUDTST` `PMTST` `SPKI` `AUDNAY` `AUDYEA` |
| in the gun move table `TMOVE`, but no code ever stores their index (`MOVS_LV`, `MOVS_BF`) | `MOVLV` `MOVBF` |
| `JMP RESET` at the start of each bank, for the development system; nothing jumps there | `L6000` `K6000` |
| the program's own fault traps | `INTDIS` (the SWI, NMI and FIRQ vectors), `CHERR` (an unassigned alien command) |
| **live, test mode:** the failure branch of the NOVRAM test on the option page | `RESTOR` |
| **live, game:** "I'm on the leader", said on a random bit when Darth Vader's ship is first seen in an even space wave; the scenarios that saw him drew the other phrase | `SPKIMO` |

The 3 sound-program routines not reached: `TEST`, the sound board's own RAM
and ROM test, which it runs when its test switch is closed at power-on (on the
oracle that test writes to ROM addresses, which the board model counts as a
fault, so no scenario runs it); `PKPKC`, a music-script command (set POKEY 1's
control bits) that is in the command table but that no tune played used; and
`RCS` (set the reconfiguration flag, all voices 8-bit), which nothing in the
listing refers to by name — not checked further.

Test mode otherwise: every routine of the main board's self test, the
diagnostics, the statistics page, the option page and the NOVRAM test is
reached and equal. Their untaken instructions are fault displays — `RAMTST`
117 (a RAM error), `SDIVRT` 56 and `SMULRT` 51 (a divider or matrix processor
error), `CHKEE` 21 and `EETSTR` 9 (NOVRAM errors) — which need faulty hardware
to run; and 34 instructions of `EEACCT` (the accounting page), whose condition
was not looked into.

One scenario bends the game to get at code: `waves_tough` pokes the alien
ships' hit counts so that a hit does not destroy them, which is the code path
for hitting Darth Vader's ship (`SCRDARTH`); the scripted player never hit him.

## Conventions

The port keeps the 6809's view of the machine, so that a routine's C is its
listing line for line and the verifier can compare everything.

- **State** (`c_src/sw.h`): one `sw_state` per program (`g` for the main
  program, `gsnd` for the sound program) — 64K of memory (RAM, and the ROM
  image), the registers, the flags, the cycle clock. `A B D X Y U S DP` and
  `CCN CCZ CCV CCC CCH` are macros onto it. The sound program's files define
  `SW_SND_PROGRAM`, which gives every runtime name its sound-side twin, so
  both link into one executable.
- **Routines** are `void name(void)`, named as Atari named them (lower case;
  `Lxxxx` / `Kxxxx` where the source has no label; the sound program's carry
  the prefix `s_`). Their register protocol is the ROM's.
- **Memory.** `M8(addr)` for an address known to be RAM; `rd8/wr8/rd16/wr16`
  for any address — RAM, ROM by the bank latch, or hardware. Words are
  big-endian.
- **Hardware seam.** `hw_rd8/hw_wr8/hw_rd16/hw_wr16`: `$4300-$47FF` on the
  main board; the links, the 6532 and the POKEYs on the sound board. The
  verifier implements it by replay, the host with the chip models
  (`port.cpp`). Nothing else in the port touches hardware.
- **The stack is kept.** `JSR(f)` is `S -= 2; f()` and `RTS` is `S += 2;
  return`, pushes and pulls write and read memory, so stack-relative operands
  mean what they mean in the ROM. Return addresses themselves are not written.
- **Flags** are computed only where something reads them. A compare or test
  followed by its branch is one C condition (`if (A >= PHS_EQ)`); elsewhere the
  helpers in `sw.h` (`add8`, `cmp16`, `lsr8`, ...) set the flag variables.
- **The cycle clock.** `CYC(n)` charges the n cycles the 6809 spends on the
  instructions since the last `CYC`. It stands before everything that can see
  the time and before control leaves the straight line, so the clock at a
  hardware access is the cycle at which the 6809 starts that instruction. The
  counts are not from a table: `tests/cyctab.exe` measures every instruction
  of both programs on the oracle's own 6809 core.
- **Checkpoints.** `CK(pc)` marks a place where the program can be
  interrupted: every routine entry, loop top and label, and a few listed in
  `xlate.py`. The 6809 can be interrupted between any two instructions; the C
  only where its state is the 6809's with nothing half evaluated, and these are
  such places, close enough together that an interrupt never waits long.
  `sw_sei()` / `sw_cli()` are the program's `ORCC #$10` / `ANDCC #$EF`, and
  `sw_pass()` marks the start of a pass.
- **Indirect calls** — the phase table, the object and command tables — go
  through `call_rom(addr)`, which looks the address up in the registry.

### What the translator does (`c_src/tools/xlate.py`)

- **Functions.** An entry is a call target, a jump-table entry, a vector, the
  target of a branch from another function, or an address loaded into S (see
  below). Falling or jumping into another function is a tail call.
- **Structure.** Atari wrote the programs with the HLL69F macros (`IFxx` /
  `ELSE` / `ENDIF` / `BEGIN` / `xxEND`); the listing records them, and they
  become `if` / `else` / `do ... while` / `for (;;)`. No routine needed the
  unstructured fallback.
- **Operands** are the listing's symbolic expressions, kept only where they
  evaluate to the ROM's operand.
- **`LEAS 2,S` / `RTS`** — a routine that drops its caller's return address —
  sets `g.unwind`, and the caller returns in turn.
- **S as a return-address register.** The self test cannot trust RAM, so it
  does `LDS #SDIVRT` ... `JMP ,S`. `JMP ,S` is `call_rom(S); return;` and the
  address loaded is a routine.
- **A long conditional branch** costs one cycle more when taken:
  `CYC(n + ((condition) ? 1 : 0))`.

### What is written by hand (`c_src/hand/mainline.c`)

`WAITFRAME` and `MAIN` are one endless loop in the ROM, and `WAITFRAME` is
also called as a subroutine for a one-frame delay (`CMPS #STACK` tells the two
apart). A mechanical translation recurses forever; the loop is written out,
statement for statement what the translator emits. The sound program's
mainline is a plain loop and needed nothing.

## The verifier (`c_src/tests/lockstep.cpp`)

The ROM runs on the oracle. At each arrival at a routine the machine is
snapshotted and every event after it is logged: hardware accesses, the
checkpoints the ROM passes, SEI and CLI, interrupts. When the ROM returns, the
C function runs from the snapshot with the log replayed — reads get the ROM's
values, writes must match in address, value and order, every event must be
consumed — and the results and the cycle clock are compared. Checks nest; a
failure is attributed to the innermost routine that failed.

**Interrupts** are the hard part: the ROM takes them between any two
instructions and the C has no instruction boundaries. An interrupt inside an
open check is *anchored* to a logged event: the C handler runs right after the
last event before it, or, failing that, right before the first event after it.
The ROM side proves each anchor from memory access sets — the instructions
between the event and the interrupt read or wrote nothing the handler wrote,
and wrote nothing it read. An interrupt that follows another with no event
between waits with it, and has to commute with everything the first one has
to. An interrupt with no provable anchor taints the open checks, which are
then counted and not compared, and the report names the two instructions in
the way. That count is zero in every scenario.

So the interrupt *timing* the port is proved against is "at an event", not "at
a cycle" — which is exactly what the port does when it runs (below).

**Scripted pokes.** `PASS poke ADDR VALUE` in a scenario writes a RAM byte at
the start of a pass, for both sides. The scenarios use it to keep the shield
count up, to set the wave numbers, for a score worth a place in the table, and
(one scenario) for alien ships that survive a hit. The Death Star explosions
are not poked: the scripted player hits the exhaust port.

## Running for real (`c_src/port.cpp`, `app.cpp`)

- Each program is a loop that never returns, so each runs on a fiber of its
  own. The main program's hands over to the sound program's whenever that one
  is behind, and back to the host when the machine has reached the time the
  host asked for.
- **Time** is the two cycle clocks. The chips are read and written at them:
  the vector generator's HALT (its own state PROM count), the matrix
  processor's BUSY, the 6532's timer, the 246 Hz interrupt, the watchdog. The
  host runs the machine up to the wall clock at 1.512 MHz and nothing else
  sets the speed.
- **An interrupt** that has come due is taken at the next event: a hardware
  access, a checkpoint, SEI, CLI, the start of a pass.
- **RESET** (the watchdog; the main board's reset line to the sound board)
  throws a fiber away and starts a new one at the reset entry.

Measured, headless: 10.001 s of machine time in 10.003 s of wall time; no
interrupt lost beyond the 331 the ROM itself loses with interrupts masked at
power-on (the same count as the ROMs on the 6809 cores); the scripted game
runs 1,400 passes with no error trap and no watchdog bite; Atari's self test,
run in C, shows NO ERRORS DETECTED.

## What is not verified

- **Untaken paths.** 742 instructions of the main program (5.7 %) and 104 of
  the sound program were never executed in a compared run; their C is
  mechanical translation only. A real bug was found this way late on — `CMPD`
  followed by `BPL` in `MVPTGN`, wrong in 5 calls of 1,684, and only in the
  late-wave scenario — so untaken paths are not assumed correct.
- **The port's own run is not the oracle's run.** Routine by routine the C is
  equal to the ROM, but the port takes each interrupt a few instructions later
  than the 6809 does, so the random-number generator and the A-to-D converter
  are read at other cycles and a whole game is another play of the same
  machine, not the same frames. There is no frame-for-frame comparison of the
  two programs.
- **The sound, by ear.** The POKEY writes and speech bytes are verified; the
  synthesis (the POKEY core from the Tempest port, AAE's TMS5220 core) and the
  mix levels were checked only for presence and for not clipping.
- **The live controls.** The window, the audio device and the input path start
  and run; how the yoke feels on a mouse has not been judged by a player.
- **Flags no caller reads** are not compared at a return, and the half-carry
  only through `DAA` results. **Stack bytes below a routine's entry S** are
  not compared (the C does not write return addresses).
- **The self test and the diagnostics** are continuation-passing code (`JMP`
  from routine to routine, never returning), which in C is tail calls. They
  compare equal and they run in the port, on a fiber with a 256 MB stack
  reserve and the compiler's tail-call elimination; a long enough diagnostic
  session could still exhaust it.
- **The hardware model** is the oracle's ([HARDWARE.md](HARDWARE.md)); the
  port is proved equal to the ROM *on that model*. The random-number byte is
  its least certain part.
