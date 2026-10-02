/* hw.cpp - the Star Wars hardware without its 6809s (board.h): the chips, the
 * ports and latches, the link between the boards, RESET and power-on.
 * board.cpp puts the two 6809 cores on it (the oracle); port.cpp puts the C
 * port on it.
 *
 * Hardware model (the CONTRACT - the C port's hardware seam must reproduce it).
 * Atari's names are from the source (disasm/starwars_defines.asm).
 *
 * Time
 *  - Master clock 12.096 MHz.  Both 6809s run at master / 8 = 1.512 MHz; a CPU
 *    cycle is 8 ticks.  Cycle counts are the core's (datasheet values).
 *  - A bus access is taken to happen at the START of its instruction: every
 *    hardware read sees the state as of that cycle, every write acts at it.
 *  - The sound CPU is stepped after each main-CPU step until it has caught up,
 *    so it is never more than one instruction behind.
 *
 * Main CPU, address by address
 *  $0000-$2FFF  vector RAM (read and write)
 *  $3000-$3FFF  vector ROM
 *  $4300-$431F  IN0   D0 right coin, D1 left coin, D2 aux coin, D3 slam,
 *                     D4 self test, D6 right fire, D7 left fire; all active low
 *  $4320-$433F  IN1   D2 diagnostic step, D4 right thumb, D5 left thumb (active
 *                     low); D6 VGHALT (1 = halted); D7 M.BUSY (1 = running)
 *  $4340-$435F  option bank 1       $4360-$437F  option bank 2
 *  $4380-$439F  R.CHN: the A-to-D converter's last result
 *  $4400        read: byte from the sound board, and clears the sound flag;
 *               write: byte to the sound board, and sets the main flag
 *  $4401        D7 main flag (our byte not yet read), D6 sound flag (a byte waits)
 *  $4500-$45FF  X2212 NOVRAM, low nibble; the high nibble reads as ones
 *  $4600-$461F  VGGO      $4620-$463F  VGSTOP
 *  $4640-$465F  WTCHDG: the watchdog bites after 32 IRQ periods without a write
 *  $4660-$467F  IRCLR: clears the IRQ request
 *  $4680-$469F  eight D7 latches, address & 7: 0,1 coin counters, 2 LED 3,
 *               3 LED 2, 4 W.BANK (0 root, 1 overlay), 5 P.IRND (0 holds the
 *               random generator at zero, 1 runs it), 6 LED 1, 7 NVRRCL (the
 *               NOVRAM recalls on its rising edge)
 *               A read of these addresses returns $00 (nothing drives the bus;
 *               the program only does it inside ROR and CLR on W.BANK).
 *  $46A0-$46BF  NSTORE: NOVRAM store strobe
 *  $46C0-$46DF  W.CHNn, address & 3: start a conversion of channel n (0 pitch,
 *               1 yaw); the converter samples the input at this write
 *  $46E0-$46FF  W.RSTS: reset the sound 6809 and clear both flags
 *  $4700-$4707  write: 0 M.PCGO, 1-2 M.BIC, 4-5 divisor (5 starts), 6-7 dividend
 *               read: 0-1 quotient, 3 random byte
 *  $4800-$5FFF  RAM; $5000-$5FFF is also the matrix processor's
 *  $6000-$7FFF  ROM, bank 0 or 1          $8000-$FFFF  ROM
 *  Anything else is unmapped: it reads $00, is counted, and fails the run.
 *
 *  - IRQ: requested every 6,144 cycles from power-on (246.09 Hz); the request
 *    stays until the 6809 takes it or IRCLR is written.  One request can wait;
 *    a second one arriving meanwhile is counted as lost.
 *  - RESET (power-on, watchdog bite, script): both CPUs, the bank latch, the
 *    matrix processor's counters, the 6532 and both flags.  RAM, the NOVRAM,
 *    the matrix registers, the vector generator and the timeline are kept (the
 *    vector generator is not on the RESET line; the program writes VGSTOP).
 *    Power-on also clears RAM and vector RAM to zero, sets the NOVRAM RAM side
 *    to ones, holds the random generator at zero and halts the vector
 *    generator.
 *
 * Sound CPU (A15 not decoded: the map repeats at $8000)
 *  $0000-$07FF  write SOUT: byte to the main CPU, and sets the sound flag
 *  $0800-$0FFF  read SIN: byte from the main CPU, and clears the main flag
 *  $1000-$107F  6532 RAM            $1080-$109F  6532 registers
 *  $1800-$183F  four POKEYs, write only here; writes are recorded
 *  $2000-$27FF  RAM                 $4000-$7FFF  ROM
 *  6532 port A: D7 main flag, D6 sound flag (inputs); D5 speech power; D4 self
 *  test switch (1 = off); D3 FM; D2 TMS5220 not-ready; D1 /RS; D0 /WS.  A
 *  falling edge on /WS writes port B to the TMS5220; a falling edge on /RS
 *  latches its status for port B to read.  The 6532's /IRQ is the 6809's IRQ.
 *  The TMS5220 is clocked one sample every 189 cycles (8 kHz).
 */
#include <cstdarg>
#include <cstdio>
#include <cstring>
#include "board.h"
#include "tms5220.h"

sw_board SW;

static sw_roms roms;
static uint8_t *main_mem = SW.mem;     /* what the vector generator and the matrix processor work on */

static inline uint64_t ticks_now() { return SW.cyc * 8; }

static void unmapped(int cpu, int write, unsigned a)
{
    uint32_t *n = write ? &SW.n_unmapped_w[cpu] : &SW.n_unmapped_r[cpu];
    if (*n < 8) {
        (write ? SW.first_unmapped_w : SW.first_unmapped_r)[cpu][*n] = (uint16_t)a;
        if (!write) SW.first_unmapped_pc[cpu][*n] = (uint16_t)(SW.pc_hook ? SW.pc_hook(cpu) : 0);
    }
    (*n)++;
}

/* ------------------------------------------------------------------ */
/* sound board side of the link, the 6532 and the speech chip          */
/* ------------------------------------------------------------------ */

static uint8_t riot_in_a(void *)
{
    /* D7, D6: the flags; D4: self-test switch; D2: TMS5220 not ready */
    int readyq = tms5220_ready_read() ? 0 : 1;
    return (uint8_t)((riot_porta_in_get(&SW.riot) & 0xc0) | (SW.snd_test & 0x10) | (readyq << 2));
}

static void riot_out_a(void *, uint8_t data)
{
    uint8_t prev = SW.riot_pa_prev;

    if ((prev & 0x01) && !(data & 0x01)) {              /* /WS falls: write */
        uint8_t v = riot_portb_out_get(&SW.riot);
        tms5220_data_write(v);
        SW.n_tms_w++;
        if (SW.io_hook) SW.io_hook(SW_SOUND, 1, 0x5220, v);
    }
    if ((prev & 0x02) && !(data & 0x02)) {              /* /RS falls: latch status */
        SW.tms_status = (uint8_t)tms5220_status_read();
        SW.n_tms_r++;
    }
    SW.riot_pa_prev = data;
}

static uint8_t riot_in_b(void *) { return SW.tms_status; }

static void sound_reset_chips(void)
{
    riot_reset(&SW.riot, SW.snd_cyc);
    SW.riot_pa_prev = 0;
    SW.tms_status = 0;
    SW.main_data = SW.sound_data = 0;
}

/* ------------------------------------------------------------------ */
/* main CPU bus                                                         */
/* ------------------------------------------------------------------ */

uint8_t sw_hw_read(unsigned a)
{
    uint8_t v;

    if (a >= 0x4300 && a < 0x43a0) {
        switch ((a >> 5) & 7) {
        case 0: v = SW.in0; break;
        case 1:
            v = (uint8_t)(SW.in1 & 0x3f);
            if (mb_busy(&SW.mb, ticks_now())) v |= 0x80;
            if (avg_halted(&SW.vg, ticks_now())) v |= 0x40;
            break;
        case 2: v = SW.dsw0; break;
        case 3: v = SW.dsw1; break;
        default: v = SW.adc_latch; break;
        }
    } else if (a == 0x4400) {
        riot_porta_in_set(&SW.riot, 0x00, 0x40);
        v = SW.main_data;
    } else if (a == 0x4401) {
        v = (uint8_t)(riot_porta_in_get(&SW.riot) & 0xc0);
    } else if (a >= 0x4500 && a < 0x4600) {
        v = x2212_read(&SW.nv, (uint8_t)a);
    } else if (a == 0x4700) {
        v = mb_quotient_hi(&SW.mb);
    } else if (a == 0x4701) {
        v = mb_quotient_lo(&SW.mb);
    } else if (a == 0x4703) {
        v = mb_random(&SW.mb, ticks_now());
    } else if (a >= 0x4680 && a < 0x46a0) {
        /* the D7 latches are write only.  The bank switch is "SEC / ROR W.BANK"
         * and "CLR W.BANK": read-modify-write instructions whose read finds
         * nothing driving the bus and whose result does not depend on it. */
        SW.n_latch_reads++;
        return 0;
    } else {
        unmapped(SW_MAIN, 0, a);
        return 0;
    }
    if (SW.io_hook) SW.io_hook(SW_MAIN, 0, a, v);
    return v;
}

void sw_hw_write(unsigned a, uint8_t d)
{
    if (a == 0x4400) {
        if (riot_porta_in_get(&SW.riot) & 0x80) SW.n_cmd_overrun++;
        riot_porta_in_set(&SW.riot, 0x80, 0x80);
        SW.sound_data = d;
        SW.n_main_cmds++;
    } else if (a >= 0x4500 && a < 0x4600) {
        x2212_write(&SW.nv, (uint8_t)a, d);
    } else if (a >= 0x4600 && a < 0x4700) {
        switch ((a >> 5) & 7) {
        case 0:
            avg_run(&SW.vg, ticks_now());
            if (SW.vg_hook) SW.vg_hook(1);
            avg_go(&SW.vg, ticks_now());
            break;
        case 1:
            avg_run(&SW.vg, ticks_now());
            if (SW.vg_hook) SW.vg_hook(0);
            avg_reset(&SW.vg, ticks_now());
            break;
        case 2: {
            uint64_t gap = SW.cyc - SW.last_kick;
            if (gap > SW.max_kick_gap) SW.max_kick_gap = gap;
            SW.last_kick = SW.cyc;
            SW.n_wd_kicks++;
            break;
        }
        case 3:
            if (SW.irq_ack_hook) SW.irq_ack_hook();
            SW.irq_pending = 0;
            break;
        case 4:
            SW.out_latch[a & 7] = d;
            switch (a & 7) {
            case 4: SW.bank = (d & 0x80) != 0; break;
            case 5: mb_random_ctl(&SW.mb, d, ticks_now()); break;
            case 7: x2212_recall(&SW.nv, d & 0x80); break;
            default: break;
            }
            break;
        case 5: x2212_store(&SW.nv); break;
        case 6: SW.adc_latch = SW.adc_in[a & 3]; break;
        default:
            riot_porta_in_set(&SW.riot, 0x00, 0xc0);
            SW.snd_cyc = SW.cyc;
            SW.tms_next = SW.snd_cyc + SW_TMS_CYCLES;
            SW.n_snd_resets++;
            if (SW.cpu_reset_hook) SW.cpu_reset_hook(SW_SOUND);
            break;
        }
    } else if (a >= 0x4700 && a < 0x4708) {
        mb_write(&SW.mb, (int)(a & 7), d, ticks_now());
    } else {
        unmapped(SW_MAIN, 1, a);
        return;
    }
    if (SW.io_hook) SW.io_hook(SW_MAIN, 1, a, d);
}

/* ------------------------------------------------------------------ */
/* sound CPU bus                                                        */
/* ------------------------------------------------------------------ */

uint8_t sw_snd_hw_read(unsigned a)
{
    uint8_t v;

    if (a >= 0x0800 && a < 0x1000) {
        riot_porta_in_set(&SW.riot, 0x00, 0x80);
        v = SW.sound_data;
    } else if (a >= 0x1080 && a < 0x10a0) {
        v = riot_read(&SW.riot, (uint8_t)(a & 0x1f), SW.snd_cyc);
    } else {
        unmapped(SW_SOUND, 0, a);
        return 0;
    }
    if (SW.io_hook) SW.io_hook(SW_SOUND, 0, a, v);
    return v;
}

void sw_snd_hw_write(unsigned a, uint8_t d)
{
    if (a < 0x0800) {
        riot_porta_in_set(&SW.riot, 0x40, 0x40);
        SW.main_data = d;
        SW.n_snd_replies++;
    } else if (a >= 0x1080 && a < 0x10a0) {
        riot_write(&SW.riot, (uint8_t)(a & 0x1f), d, SW.snd_cyc);
    } else if (a >= 0x1800 && a < 0x1840) {
        /* four POKEYs, registers interleaved: A5 = register bit 3, A4-A3 = chip */
        int chip = (a >> 3) & 3, reg = (a & 7) | ((a >> 2) & 8);
        SW.pokey[chip][reg] = d;
        SW.n_pokey_w++;
        if (SW.pokey_hook) SW.pokey_hook(chip, reg, d);
    } else {
        unmapped(SW_SOUND, 1, a);
        return;
    }
    if (SW.io_hook) SW.io_hook(SW_SOUND, 1, a, d);
}

/* ------------------------------------------------------------------ */
/* machine                                                              */
/* ------------------------------------------------------------------ */

void sw_hw_init(const sw_roms *r)
{
    roms = *r;
    memset(&SW, 0, sizeof SW);
    memcpy(SW.mem + 0x3000, r->main_rom + 0x3000, 0x1000);
    memcpy(SW.mem + 0x6000, r->main_rom + 0x6000, 0xa000);
    memcpy(SW.bank1, r->bank1, 0x2000);
    memcpy(SW.snd + 0x4000, r->sound_rom + 0x4000, 0x4000);

    SW.in0 = 0xdf;                /* every switch open; D5 is not connected */
    SW.in1 = 0x34;                /* diagnostic step and both thumbs open */
    SW.dsw0 = 0x84;               /* 6 shields, moderate, no bonus, music, normal */
    SW.dsw1 = 0x02;               /* 1 coin 1 credit */
    SW.adc_in[0] = SW.adc_in[1] = 0x80;
    SW.snd_test = 0x10;
    SW.wd_cycles = SW_WD_CYCLES;

    x2212_init(&SW.nv);
    riot_init(&SW.riot);
    SW.riot.in_a = riot_in_a;
    SW.riot.out_a = riot_out_a;
    SW.riot.in_b = riot_in_b;
    avg_init(&SW.vg, r->avg_prom, main_mem);
    mb_init(&SW.mb, r->mathbox_proms, main_mem + 0x5000);
}

void sw_bind_memory(uint8_t *mem)
{
    main_mem = mem;
    avg_init(&SW.vg, roms.avg_prom, main_mem);
    mb_init(&SW.mb, roms.mathbox_proms, main_mem + 0x5000);
}

void sw_machine_reset(int cause)
{
    SW.n_reset[cause]++;
    SW.bank = 0;
    memset(SW.out_latch, 0, sizeof SW.out_latch);
    mb_reset(&SW.mb);
    /* the vector generator is not on the RESET line ("GATE ARRAY ONLY LISTENS
     * TO STOP, NOT RESET LINE", at RESET in WSINT): the program stops it itself */
    SW.irq_pending = 0;
    SW.snd_cyc = SW.cyc;
    SW.tms_next = SW.snd_cyc + SW_TMS_CYCLES;
    sound_reset_chips();
    tms5220_reset();
    if (SW.cpu_reset_hook) {
        SW.cpu_reset_hook(SW_MAIN);
        SW.cpu_reset_hook(SW_SOUND);
    }
    SW.last_kick = SW.cyc;
}

void sw_power_on(void)
{
    memset(SW.mem, 0, 0x3000);
    memset(SW.mem + 0x4800, 0, 0x1800);
    memset(SW.snd, 0, 0x4000);
    memset(SW.pokey, 0, sizeof SW.pokey);
    x2212_power_on(&SW.nv);
    SW.cyc = SW.snd_cyc = 0;
    SW.next_irq = SW_IRQ_CYCLES;
    SW.adc_latch = SW.adc_in[0];
    mb_random_ctl(&SW.mb, 0, 0);
    avg_init(&SW.vg, roms.avg_prom, main_mem);
    sw_machine_reset(SW_RST_POWERON);
}

void sw_snd_chips_advance(void)
{
    while (SW.snd_cyc >= SW.tms_next) {
        short s;
        tms5220_process(&s, 1);
        if (SW.tms_hook) SW.tms_hook(s);
        SW.tms_next += SW_TMS_CYCLES;
    }
    riot_advance(&SW.riot, SW.snd_cyc);
}

int sw_snd_irq(void) { return riot_irq(&SW.riot) != 0; }

uint64_t sw_ticks(void) { return ticks_now(); }
