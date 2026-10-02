/* mathbox.h - the Star Wars math hardware at $4700-$4707: the matrix
 * processor (a microcoded multiplier-accumulator working on the math RAM at
 * $5000-$5FFF), the divider, and the random byte generator.
 *
 * The matrix processor and the divider are MAME's (machine/starwars.cpp, by
 * Steve Baines and later MAME contributors), taken from AAE's
 * starwars_machine.cpp.  Time is in master-clock ticks (12.096 MHz).
 */
#ifndef SW_MATHBOX_H
#define SW_MATHBOX_H

#include <stdint.h>

#ifdef __cplusplus
extern "C" {
#endif

typedef struct {
    /* matrix processor */
    int      MPA;                 /* microcode PROM address counter, 10 bits */
    int      BIC;                 /* block index counter, 9 bits */
    int16_t  A, B, C;
    int32_t  ACC;
    uint64_t busy_until;          /* M.BUSY reads set before this tick */
    uint8_t  prom_str[1024];      /* instruction strobes   (PROM bits 15-8) */
    uint8_t  prom_mas[1024];      /* direct address        (bits 6-0) */
    uint8_t  prom_am[1024];       /* address mode select   (bit 7) */
    uint8_t *ram;                 /* math RAM, $5000-$5FFF as the CPU sees it */

    /* divider */
    uint16_t dvd_shift, quotient_shift, divisor, dividend;

    /* random byte generator: 23-bit LFSR at 3.024 MHz (4 ticks a shift) */
    uint32_t lfsr;
    int      rnd_run;             /* P.IRND D7: 0 holds the register at zero */
    uint64_t rnd_t;               /* tick the register was last brought up to */

    /* statistics */
    uint32_t n_runs, n_runaway, n_divides, n_rnd_reads;
    uint32_t last_steps, max_steps;
} mathbox;

/* proms: the four 1024 x 4 PROMs in the order 110, 111, 112, 113 */
void    mb_init(mathbox *m, const uint8_t *proms, uint8_t *mathram);
void    mb_reset(mathbox *m);                         /* machine reset: MPA, BIC, busy */
void    mb_write(mathbox *m, int reg, uint8_t data, uint64_t now);   /* $4700 + reg */
uint8_t mb_quotient_hi(const mathbox *m);             /* $4700 read */
uint8_t mb_quotient_lo(const mathbox *m);             /* $4701 read */
int     mb_busy(const mathbox *m, uint64_t now);      /* IN1 D7 */
uint8_t mb_random(mathbox *m, uint64_t now);          /* $4703 read */
void    mb_random_ctl(mathbox *m, uint8_t data, uint64_t now);       /* $4685 write */

#ifdef __cplusplus
}
#endif
#endif
