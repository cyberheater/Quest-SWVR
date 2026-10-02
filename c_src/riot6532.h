/* riot6532.h - MOS 6532 RIOT: two ports with data-direction registers, PA7
 * edge detect, and the interval timer.  After MAME's 6532riot device, by way
 * of AAE's riot6532.cpp, with the timer expressed as a target on the owning
 * CPU's cycle count instead of an emulator timer.
 *
 * `now` is the owning CPU's cycle count.  Call riot_advance() before the CPU
 * executes at cycle `now`, and pass the same `now` to the register accesses.
 */
#ifndef SW_RIOT6532_H
#define SW_RIOT6532_H

#include <stdint.h>

#ifdef __cplusplus
extern "C" {
#endif

typedef struct {
    uint8_t in, out, ddr;
} riot_port;

typedef struct riot6532 {
    riot_port port[2];
    uint8_t irqstate;            /* D7 timer flag, D6 PA7 flag */
    uint8_t irqenable;
    uint8_t pa7dir, pa7prev;
    uint8_t timershift;
    int     timerstate;          /* 0 idle, 1 counting, 2 finishing */
    uint64_t timer_target;       /* cycle at which the current phase ends */

    uint8_t (*in_a)(void *ctx);  /* port A read: the external pins */
    void    (*out_a)(void *ctx, uint8_t data);
    uint8_t (*in_b)(void *ctx);
    void    (*out_b)(void *ctx, uint8_t data);
    void    *ctx;
} riot6532;

void    riot_init(riot6532 *r);
void    riot_reset(riot6532 *r, uint64_t now);
void    riot_advance(riot6532 *r, uint64_t now);
uint8_t riot_read(riot6532 *r, uint8_t offset, uint64_t now);
void    riot_write(riot6532 *r, uint8_t offset, uint8_t data, uint64_t now);
void    riot_porta_in_set(riot6532 *r, uint8_t data, uint8_t mask);   /* drive input pins */
uint8_t riot_porta_in_get(const riot6532 *r);
uint8_t riot_portb_out_get(const riot6532 *r);
int     riot_irq(const riot6532 *r);                                   /* /IRQ asserted */

#ifdef __cplusplus
}
#endif
#endif
