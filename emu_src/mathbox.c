/* mathbox.c - Star Wars matrix processor, divider and random byte (mathbox.h).
 *
 * Matrix processor and divider: MAME's machine/starwars.cpp ("This file is
 * Copyright 1997, Steve Baines", with the later MAME matrix-processor, divider
 * and busy-flag work), from AAE's starwars_machine.cpp; the arithmetic is
 * unchanged.  The microcode it runs is Atari's SWMP.MAC, which the source
 * archive's SWMP.LDA shows to be exactly the four PROMs.
 *
 * Random byte: MAME describes the circuit (a 23-bit LFSR, taps at bits 4 and
 * 22, feedback inverted so it can start from zero, clocked at 3 MHz, bits
 * 15-8 readable) but returns a host random number, as AAE does.  An oracle
 * needs a deterministic one, so the register is modelled as described.
 * Atari's equates give the control: P.IRND "0 INITS, 80 RUNS IT".
 */
#include <string.h>
#include "mathbox.h"

/* instruction strobes, PROM bits 15-8 */
#define LAC       0x01
#define READ_ACC  0x02
#define M_HALT    0x04
#define INC_BIC   0x08
#define CLEAR_ACC 0x10
#define LDC       0x20
#define LDB       0x40
#define LDA       0x80

#define STEP_CAP  100000          /* MAME's limit on one run */

void mb_init(mathbox *m, const uint8_t *proms, uint8_t *mathram)
{
    int i;
    memset(m, 0, sizeof *m);
    m->ram = mathram;
    for (i = 0; i < 1024; i++) {
        int val = (proms[0x0c00 + i] & 0x0f)
                | ((proms[0x0800 + i] << 4) & 0x00f0)
                | ((proms[0x0400 + i] << 8) & 0x0f00)
                | ((proms[0x0000 + i] << 12) & 0xf000);
        m->prom_str[i] = (uint8_t)((val >> 8) & 0xff);
        m->prom_mas[i] = (uint8_t)(val & 0x7f);
        m->prom_am[i] = (uint8_t)((val >> 7) & 1);
    }
}

void mb_reset(mathbox *m)
{
    m->MPA = m->BIC = 0;
    m->busy_until = 0;
}

static void run_mproc(mathbox *m, uint64_t now)
{
    int steps = 0, mptime = 0, halted = 0;

    while (steps < STEP_CAP) {
        int IP15_8, IP7, IP6_0, MA, MA_byte, RAMWORD, tmp;

        /* each step of the matrix processor takes five clock cycles */
        mptime += 5;
        steps++;

        IP15_8 = m->prom_str[m->MPA];
        IP7 = m->prom_am[m->MPA];
        IP6_0 = m->prom_mas[m->MPA];

        /* RAM address: direct, or block index in MA10-2 */
        if (IP7 == 0)
            MA = (IP6_0 & 3) | ((m->BIC & 0x01ff) << 2);
        else
            MA = IP6_0;
        MA_byte = MA << 1;
        RAMWORD = (m->ram[MA_byte + 1] & 0x00ff) | ((m->ram[MA_byte] & 0x00ff) << 8);

        if (IP15_8 & CLEAR_ACC)
            m->ACC = 0;
        if (IP15_8 & LAC)
            m->ACC = (int32_t)((uint32_t)RAMWORD << 16);
        if (IP15_8 & READ_ACC) {
            m->ram[MA_byte + 1] = (uint8_t)((m->ACC >> 16) & 0xff);
            m->ram[MA_byte] = (uint8_t)((m->ACC >> 24) & 0xff);
        }
        if (IP15_8 & M_HALT)
            halted = 1;
        if (IP15_8 & INC_BIC)
            m->BIC = (m->BIC + 1) & 0x1ff;
        if (IP15_8 & LDC) {
            m->C = (int16_t)RAMWORD;
            /* serial subtractor - multiplier - accumulator:
             * ACC = ACC + (A - B) * C, with the pipeline's two shifts */
            m->ACC = (int32_t)((uint32_t)m->ACC +
                     ((uint32_t)((int64_t)(m->A - m->B) * 2 * m->C) << 1));
            /* A and B are sign extended; after the multiply they hold the sign */
            m->A = (int16_t)((m->A & 0x8000) ? 0xffff : 0);
            m->B = (int16_t)((m->B & 0x8000) ? 0xffff : 0);
            /* the multiply-add holds the counter for 33 cycles */
            mptime += 33;
        }
        if (IP15_8 & LDB)
            m->B = (int16_t)RAMWORD;
        if (IP15_8 & LDA)
            m->A = (int16_t)RAMWORD;

        /* the top two bits are not part of the counter: each page wraps */
        tmp = m->MPA + 1;
        m->MPA = (m->MPA & 0x0300) | (tmp & 0x00ff);

        if (halted)
            break;
    }
    if (!halted)
        m->n_runaway++;
    m->n_runs++;
    m->last_steps = (uint32_t)steps;
    if ((uint32_t)steps > m->max_steps)
        m->max_steps = (uint32_t)steps;
    m->busy_until = now + (uint64_t)mptime;
}

void mb_write(mathbox *m, int reg, uint8_t data, uint64_t now)
{
    int i;

    switch (reg & 7) {
    case 0:                                   /* M.PCGO: start address and go */
        m->MPA = data << 2;
        run_mproc(m, now);
        break;
    case 1:                                   /* M.BICH */
        m->BIC = (m->BIC & 0x00ff) | ((data & 0x01) << 8);
        break;
    case 2:                                   /* M.BICL */
        m->BIC = (m->BIC & 0x0100) | data;
        break;
    case 4:                                   /* M.DVDH: divisor high */
        m->divisor = (uint16_t)((m->divisor & 0x00ff) | (data << 8));
        m->dvd_shift = m->dividend;
        m->quotient_shift = 0;
        break;
    case 5:                                   /* M.DVDL: divisor low, and start */
        m->divisor = (uint16_t)((m->divisor & 0xff00) | data);
        /* restoring division as in the schematics; it gives the hardware's own
         * "wrong" results when the dividend is not below twice the divisor */
        for (i = 1; i < 16; i++) {
            m->quotient_shift <<= 1;
            if (((int32_t)m->dvd_shift + (m->divisor ^ 0xffff) + 1) & 0x10000) {
                m->quotient_shift |= 1;
                m->dvd_shift = (uint16_t)((m->dvd_shift + (m->divisor ^ 0xffff) + 1) << 1);
            } else {
                m->dvd_shift <<= 1;
            }
        }
        m->n_divides++;
        break;
    case 6:                                   /* M.DVNH: dividend high */
        m->dividend = (uint16_t)((m->dividend & 0x00ff) | (data << 8));
        break;
    case 7:                                   /* M.DVNL */
        m->dividend = (uint16_t)((m->dividend & 0xff00) | data);
        break;
    default:
        break;
    }
}

uint8_t mb_quotient_hi(const mathbox *m) { return (uint8_t)(m->quotient_shift >> 8); }
uint8_t mb_quotient_lo(const mathbox *m) { return (uint8_t)(m->quotient_shift & 0xff); }

int mb_busy(const mathbox *m, uint64_t now) { return now < m->busy_until; }

/* bring the shift register up to `now`: one shift every 4 ticks */
static void rnd_advance(mathbox *m, uint64_t now)
{
    uint64_t n = (now >> 2) - (m->rnd_t >> 2);
    m->rnd_t = now;
    if (!m->rnd_run) {
        m->lfsr = 0;
        return;
    }
    while (n--) {
        uint32_t bit = (~((m->lfsr >> 4) ^ (m->lfsr >> 22))) & 1u;
        m->lfsr = ((m->lfsr << 1) | bit) & 0x7fffffu;
    }
}

uint8_t mb_random(mathbox *m, uint64_t now)
{
    rnd_advance(m, now);
    m->n_rnd_reads++;
    return (uint8_t)(m->lfsr >> 8);
}

void mb_random_ctl(mathbox *m, uint8_t data, uint64_t now)
{
    rnd_advance(m, now);
    m->rnd_run = (data & 0x80) != 0;
    if (!m->rnd_run)
        m->lfsr = 0;
}
