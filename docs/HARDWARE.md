# Star Wars — the hardware, as the oracle models it

Every fact below has a source: Atari's own equates and comments (the listings
in `disasm/`), the driver and chip models of the
[AAE emulator](https://github.com/tcottrill/AAE) (which carry MAME's), or a
measurement on the oracle. Where two sources disagree, both are given and the
choice is stated. The model itself is the header of
[`c_src/board.cpp`](../c_src/board.cpp).

## Clocks

| | |
|---|---|
| Master clock | 12.096 MHz |
| Both 6809s | master / 8 = 1.512 MHz |
| Main IRQ | every 6,144 CPU cycles = 246.09 Hz (3 kHz / 12) |
| AVG state clock | master / 8: one state every 8 master ticks |
| Random generator | master / 4 = 3.024 MHz |
| TMS5220 sample | every 189 CPU cycles = 8 kHz |

Atari's source agrees on the IRQ: the handler's game-frame divider is commented
"12.*4.2MS==>50. MS, 20 PER SECOND", and its every-fourth-interrupt branch
"EVERY 16 MILS". AAE runs the IRQ at 180 Hz, with a note that 246 Hz "ran the
game about 37% too fast"; with the vector generator's draw time counted from
the state PROM the program paces itself, and 246 Hz gives the 20 passes a
second the comment describes whenever the picture is light (see
[ORACLE.md](ORACLE.md)).

## Main CPU memory map

Names are Atari's (`disasm/starwars_defines.asm`).

| Address | Read | Write |
|---|---|---|
| `$0000-$2FFF` | vector RAM | vector RAM |
| `$3000-$3FFF` | vector ROM | |
| `$4300-$431F` | `IN0`: D0 right coin, D1 left coin, D2 aux coin, D3 slam, D4 self test, D6 right fire, D7 left fire — all active low | |
| `$4320-$433F` | `IN1`: D2 diagnostic step, D4 right thumb, D5 left thumb (active low); D6 `VGHALT`; D7 `M.BUSY` | |
| `$4340-$435F` | option bank 1 (`R.BYT2`) | |
| `$4360-$437F` | option bank 2 (`R.BYT3`) | |
| `$4380-$439F` | `R.CHN`: A-to-D result | |
| `$4400` | `R.RCVS`: byte from the sound board | `W.XMTS`: byte to the sound board |
| `$4401` | `R.STAS`: D7 main flag, D6 sound flag | |
| `$4500-$45FF` | NOVRAM, low nibble | NOVRAM |
| `$4600-$461F` | | `VGGO` |
| `$4620-$463F` | | `VGSTOP` |
| `$4640-$465F` | | `WTCHDG` |
| `$4660-$467F` | | `IRCLR` |
| `$4680-$4687` | | D7 latches: coin counters, LEDs 3 and 2, `W.BANK`, `P.IRND`, LED 1, `NVRRCL` |
| `$46A0-$46BF` | | `NSTORE` |
| `$46C0-$46C3` | | `W.CHN0-3`: start a conversion |
| `$46E0` | | `W.RSTS`: reset the sound board |
| `$4700-$4707` | `M.QUO` (0-1), `P.RND` (3) | `M.PCGO`, `M.BIC`, divisor, dividend |
| `$4800-$4FFF` | CPU RAM | CPU RAM |
| `$5000-$5FFF` | math RAM | math RAM |
| `$6000-$7FFF` | ROM, bank 0 or 1 | |
| `$8000-$FFFF` | ROM | |

## Where the sources disagree, or the oracle had to choose

**Watchdog.** Atari's equate: `WTCHDG` "RESETS IF NOT HIT OFTEN - EVERY 8*4
IRQS". The oracle bites after 32 IRQ periods (196,608 cycles) without a write.
AAE uses its own 750 ms; the value in MAME's driver was not checked for this
work. Measured on the oracle: the longest gap between writes in any scenario
is 24,295 cycles, an eighth of the limit, and the only bite is the one the
self test asks for at `HANG`.

**NOVRAM recall.** Atari's equate: `NVRRCL` "D7 HI RECALLS DATA", and the code
says "D7 = 1 PUTS NOVRAM IN RECALL MODE". The oracle recalls when D7 goes
from 0 to 1. AAE (after MAME) drives the chip's recall input with the
inverse, so it recalls on the write of `$00` that ends the pulse. The program
reads the NOVRAM only after the whole pulse, so both give it the same data.

**Vector generator and RESET.** At `RESET` the program writes `VGSTOP` with
the comment "GATE ARRAY ONLY LISTENS TO STOP, NOT RESET LINE". The oracle's
RESET therefore leaves the vector generator alone. AAE resets it with the
machine.

**Random byte.** Atari: `P.RND` "RANDOM BYTE GENERATOR (3 MHZ, 24 BIT)",
`P.IRND` "CONTROL GENERATOR, 0 INITS, 80 RUNS IT". MAME's source describes the
circuit as a 23-bit LFSR with taps at 4 and 22 and inverted feedback, bits
15-8 readable, but returns a host random number, as AAE does. The oracle
implements the register as MAME describes it, held at zero while `P.IRND` D7
is 0. **This is the least certain part of the model**: the two descriptions
differ on the length (23 or 24 bits), and the tap positions and shift
direction are not confirmed against a schematic here. What the program needs
from it is only that two successive reads differ (IPGEN's test for a stuck
generator); what the C port needs is that it reproduces the oracle's register.

**Reading the write-only latches.** The bank switch is `ORCC #$01` /
`ROR W.BANK`, and `CLR W.BANK` to go back: read-modify-write instructions on a
write-only latch. The read finds nothing driving the bus and its value does
not reach D7. The oracle returns `$00` and counts these reads; AAE has no
handler for them.

**A-to-D converter.** The IRQ handler reads `R.CHN` and then starts the other
channel's conversion for the next interrupt, 4 ms later. The oracle samples
the input at the start write and returns it at the read; the converter's own
conversion time is far shorter than the interval and is not modelled.

**Vector brightness.** A point's brightness in the oracle is MAME's:
`((int_latch >> 1) * intensity) >> 3`. AAE lifts it for its renderer; that is
a display choice and belongs to the host, not the machine.

**Model choices with no hardware counterpart.** A bus access is taken to
happen at the start of its instruction. RAM powers on as zero. The sound CPU
is stepped until it has caught up after every main-CPU instruction.

## Matrix processor and divider

The matrix processor is a microcoded multiplier-accumulator: `M.PCGO` loads
its program counter (the byte × 4) and starts it; it runs microcode from four
1024 × 4 PROMs over the math RAM, indexed by the block index counter `M.BIC`,
until a HALT strobe. Each step takes 5 master ticks and a multiply-accumulate
33 more; `M.BUSY` stays set for that long. The microcode's source is Atari's
`SWMP.MAC`, and `SWMP.LDA` equals the PROMs (see
`disasm/_survey/starwars_inputs.md`).

The divider is a 15-step restoring divider started by the low divisor byte.

Both models are MAME's, by way of AAE. Atari's self test checks them: it
starts program `$5D` and requires `M.BUSY` to read busy at once and ready one
instruction later, then runs its divider and matrix test tables. On the oracle
all three pass ([ORACLE.md](ORACLE.md)).

## Vector generator

Atari's colour AVG with the Star Wars colour and intensity latch. The oracle
runs the state machine from the state PROM (136021-109, whose source
`AVGROM.MAC` is in Atari's archive and equals the PROM): one state every 8
ticks, each vector adding its timer's count. The program builds two display
list buffers in vector RAM and draws from the one it is not writing; the top
2K of vector RAM holds display lists copied down from the program ROM
(`DOWNVG`).

## Sound board

A second 6809 (`disasm/starwars_sound_rom.asm`, `SNDCMN.MAC`'s memory map),
with A15 not decoded:

| Address | |
|---|---|
| `$0000-$07FF` | write `SOUT`: byte to the main CPU, sets the sound flag |
| `$0800-$0FFF` | read `SIN`: byte from the main CPU, clears the main flag |
| `$1000-$107F` | 6532 RAM: the direct page and the stack |
| `$1080-$109F` | 6532 ports and timer |
| `$1800-$183F` | four POKEYs, registers interleaved |
| `$2000-$27FF` | RAM |
| `$4000-$7FFF` | ROM |

6532 port A: D7 main flag, D6 sound flag, D5 speech power, D4 self-test
switch, D3 FM, D2 TMS5220 not-ready, D1 /RS, D0 /WS. Port B is the TMS5220's
data bus. The 6532's timer gives the 4 ms interrupt and its PA7 edge detector
the "byte waiting" interrupt.

The sound program never reads a POKEY, so the oracle records POKEY writes and
does not model the chips; synthesis belongs to step 5. The TMS5220 is AAE's
core, an early MAME one: it is deterministic and paces the speech routine
through its ready line, but its fidelity to the chip has not been examined
here.

## The link between the boards

Two one-byte latches and two flags. The main CPU writes `W.XMTS` (main flag
set, PA7 edge interrupts the sound CPU); the sound CPU reads `SIN` (flag
cleared). The sound CPU writes `SOUT` (sound flag set); the main CPU reads
`R.RCVS` (flag cleared). Once a second the main IRQ handler checks that the
sound board has written its watchdog value `PBX$OK` and resets it through
`W.RSTS` if not. On the oracle the sound board is reset once, at power-on.
