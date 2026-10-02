/* riot6532.c - MOS 6532 RIOT (riot6532.h).
 *
 * Register decoding, the PA7 edge detector and the timer's three states follow
 * MAME's 6532riot device (Aaron Giles; BSD-3-Clause), from AAE's riot6532.cpp.
 * The timer counts the CPU clock: a write of N with divider 2^shift loads
 * 1 + (N << shift) cycles; when it runs out the timer flag is set and the
 * timer goes on at one count a cycle, wrapping every 256.
 */
#include <string.h>
#include "riot6532.h"

#define TIMER_FLAG 0x80
#define PA7_FLAG   0x40

enum { TIMER_IDLE, TIMER_COUNTING, TIMER_FINISHING };

static uint8_t apply_ddr(const riot_port *p)
{
    return (uint8_t)((p->out & p->ddr) | (p->in & ~p->ddr));
}

static void update_pa7_state(riot6532 *r)
{
    uint8_t data = apply_ddr(&r->port[0]) & 0x80;

    /* a change in the selected direction sets the PA7 flag */
    if ((r->pa7prev ^ data) && (r->pa7dir ^ data) == 0)
        r->irqstate |= PA7_FLAG;
    r->pa7prev = data;
}

void riot_init(riot6532 *r)
{
    memset(r, 0, sizeof *r);
}

void riot_reset(riot6532 *r, uint64_t now)
{
    memset(r->port, 0, sizeof r->port);
    r->irqenable = 0;
    r->irqstate = 0;
    r->pa7dir = 0;
    r->pa7prev = 0;
    r->timershift = 10;
    r->timerstate = TIMER_COUNTING;
    r->timer_target = now + ((uint64_t)256 << r->timershift);
}

void riot_advance(riot6532 *r, uint64_t now)
{
    while (r->timerstate != TIMER_IDLE && now >= r->timer_target) {
        if (r->timerstate == TIMER_COUNTING) {
            r->timerstate = TIMER_FINISHING;
            r->irqstate |= TIMER_FLAG;
        }
        r->timer_target += 256;
    }
}

static uint8_t get_timer(const riot6532 *r, uint64_t now)
{
    uint64_t left;

    if (r->timerstate == TIMER_IDLE)
        return 0;
    left = r->timer_target > now ? r->timer_target - now : 0;
    if (r->timerstate == TIMER_COUNTING)
        return (uint8_t)(left >> r->timershift);
    return (uint8_t)left;
}

uint8_t riot_read(riot6532 *r, uint8_t offset, uint64_t now)
{
    uint8_t val;

    riot_advance(r, now);
    if ((offset & 0x05) == 0x05) {
        /* interrupt flags; the read clears the PA7 flag */
        val = r->irqstate;
        r->irqstate &= (uint8_t)~PA7_FLAG;
    } else if ((offset & 0x05) == 0x04) {
        /* timer; A3 is the timer interrupt enable */
        val = get_timer(r, now);
        if (offset & 8)
            r->irqenable |= TIMER_FLAG;
        else
            r->irqenable &= (uint8_t)~TIMER_FLAG;
        if (r->timerstate != TIMER_FINISHING || val != 0xff)
            r->irqstate &= (uint8_t)~TIMER_FLAG;
    } else {
        riot_port *p = &r->port[(offset >> 1) & 1];

        if (offset & 1) {
            val = p->ddr;
        } else {
            if (p == &r->port[0]) {
                if (r->in_a) {
                    p->in = r->in_a(r->ctx);
                    update_pa7_state(r);
                }
            } else if (r->in_b) {
                p->in = r->in_b(r->ctx);
            }
            val = apply_ddr(p);
        }
    }
    return val;
}

void riot_write(riot6532 *r, uint8_t offset, uint8_t data, uint64_t now)
{
    riot_advance(r, now);
    if ((offset & 0x14) == 0x14) {
        static const uint8_t timershift[4] = { 0, 3, 6, 10 };

        r->timershift = timershift[offset & 3];
        if (offset & 8)
            r->irqenable |= TIMER_FLAG;
        else
            r->irqenable &= (uint8_t)~TIMER_FLAG;
        if (r->timerstate != TIMER_FINISHING || get_timer(r, now) != 0xff)
            r->irqstate &= (uint8_t)~TIMER_FLAG;
        r->timerstate = TIMER_COUNTING;
        r->timer_target = now + 1 + ((uint64_t)data << r->timershift);
    } else if ((offset & 0x14) == 0x04) {
        /* edge detect control: A1 enables the PA7 interrupt, A0 picks the edge */
        if (offset & 2)
            r->irqenable |= PA7_FLAG;
        else
            r->irqenable &= (uint8_t)~PA7_FLAG;
        r->pa7dir = (uint8_t)((offset & 1) << 7);
    } else {
        riot_port *p = &r->port[(offset >> 1) & 1];

        if (offset & 1) {
            p->ddr = data;
        } else {
            p->out = data;
            if (p == &r->port[0]) {
                if (r->out_a) r->out_a(r->ctx, data);
            } else {
                if (r->out_b) r->out_b(r->ctx, data);
            }
        }
        if (p == &r->port[0])
            update_pa7_state(r);
    }
}

void riot_porta_in_set(riot6532 *r, uint8_t data, uint8_t mask)
{
    r->port[0].in = (uint8_t)((r->port[0].in & ~mask) | (data & mask));
    update_pa7_state(r);
}

uint8_t riot_porta_in_get(const riot6532 *r) { return r->port[0].in; }
uint8_t riot_portb_out_get(const riot6532 *r) { return r->port[1].out; }
int     riot_irq(const riot6532 *r) { return (r->irqstate & r->irqenable) != 0; }
