/* avg.h - Atari Analog Vector Generator, Star Wars variant, driven by its
 * state PROM and exact to the master-clock tick.
 *
 * Translated from the AVG of MAME's later avgdvg (the timer-driven state
 * machine; AAE's mame_late_avgdvg.cpp, BSD-3-Clause, see avg.c) with the
 * emulator's frame slicing removed: here the machine advances one state at a
 * time on the caller's timeline and reads vector memory at the moment each
 * state needs it.
 *
 * Time is in master-clock ticks (12.096 MHz).  One state takes 8 ticks; a
 * vector or a centre adds its timer's count on top.
 */
#ifndef SW_AVG_H
#define SW_AVG_H

#include <stdint.h>

#ifdef __cplusplus
extern "C" {
#endif

#define AVG_MAXVECT 16384

typedef struct {
    int32_t x, y;        /* beam position after the instruction, 16.16 */
    uint8_t color;       /* 3 bits: 4 red, 2 green, 1 blue */
    uint8_t z;           /* 0 = beam off */
    uint16_t src;        /* vector memory address of the instruction that drew it */
#ifdef SW_3D
    int16_t  p3[3];      /* sw3d.h: the 3-D point the beam went to, as tagged when drawn */
    uint8_t  p3_valid;
    uint16_t p3_ck;
#endif
} avg_point;

typedef struct {
    /* the vector generator's registers (MAME's vgdata) */
    uint16_t pc;
    uint16_t ipc;                  /* address of the instruction being executed */
#ifdef SW_3D
    int16_t  ip3[3];               /* sw3d.h: its 3-D tag, read with its last byte */
    uint8_t  ip3_valid;
    uint16_t ip3_ck;
#endif
    uint8_t  sp;
    uint16_t dvx, dvy;
    uint8_t  dvy12;
    uint16_t timer;
    uint16_t stack[4];
    uint8_t  data;
    uint8_t  state_latch;
    uint8_t  int_latch;
    uint8_t  scale, bin_scale;
    uint8_t  intensity, color;
    uint8_t  op;
    uint8_t  halt;                 /* the state machine's halt flip-flop */
    int32_t  xpos, ypos;

    const uint8_t *prom;           /* 256 x 4 state PROM */
    const uint8_t *mem;            /* $0000-$3FFF: vector RAM and vector ROM */

    uint64_t t;                    /* tick of the next state */
    uint64_t halt_at;              /* tick at which HALT becomes visible to the CPU */
    int      sync_halt;            /* what the CPU reads at VGHALT */

    /* the current run (VGGO to HALT) */
    uint64_t  run_start;
    uint32_t  nvect;
    avg_point vect[AVG_MAXVECT];
    uint32_t  n_states, n_ops;

    /* totals */
    uint32_t n_go, n_reset, n_halts, n_overflow, n_jump0;
} avg;

void avg_init(avg *a, const uint8_t *prom, const uint8_t *mem);
void avg_reset(avg *a, uint64_t now);          /* VGSTOP, and power-on */
void avg_go(avg *a, uint64_t now);             /* VGGO */
void avg_run(avg *a, uint64_t now);            /* advance every state due before `now` */
int  avg_halted(avg *a, uint64_t now);         /* VGHALT as the CPU reads it at `now` */

#ifdef __cplusplus
}
#endif
#endif
