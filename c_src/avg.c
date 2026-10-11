/* avg.c - Atari AVG, Star Wars variant, PROM-driven and tick exact (avg.h).
 *
 * The state machine, the handlers and the timing are MAME's (avgdvg.cpp:
 * "Some parts of this code are based on the original version by Eric Smith,
 * Brad Oliver, Bernd Wiebelt, Aaron Giles, Andrew Caldwell", BSD-3-Clause),
 * taken from AAE's mame_late_avgdvg.cpp.  Handler names are kept so the two
 * can be read side by side.  What differs:
 *
 *  - MAME runs the machine ahead of time in slices of 10,000 ticks and uses a
 *    second timer to make HALT visible at the right moment.  Here each state
 *    is executed at its own tick (avg_run), and HALT becomes visible at the
 *    tick MAME's halt timer would fire: the tick of the state that strobes
 *    it, plus the ticks that state's handler counted.
 *  - Only the Star Wars handlers are here: data = mem[pc], STAT loads an
 *    8-bit intensity and a colour, and a vector's brightness is
 *    ((int_latch >> 1) * intensity) >> 3.
 *  - The beam points are kept in a buffer per run, not handed to a renderer.
 *
 * The state PROM address is (not halted) << 7 | op << 4 | state.  A state
 * with bit 3 set reads vector memory and runs the handler its low 3 bits
 * select: 0-3 latch a byte, 4-7 are the strobes.
 */
#include <string.h>
#include "avg.h"
#ifdef SW_3D
#include "sw3d.h"
#endif

#define OP0 (a->op & 1)
#define OP1 (a->op & 2)
#define OP2 (a->op & 4)
#define ST3 (a->state_latch & 8)

/* MAME: visible area 0..250 x 0..280, centre in 16.16 */
#define XCENTER (125 << 16)
#define YCENTER (140 << 16)
#define XDAC_XOR 0x200
#define YDAC_XOR 0x200

static void add_point(avg *a, int32_t x, int32_t y, uint8_t color, uint8_t z)
{
    if (a->nvect < AVG_MAXVECT) {
        a->vect[a->nvect].x = x;
        a->vect[a->nvect].y = y;
        a->vect[a->nvect].color = color;
        a->vect[a->nvect].z = z;
        a->vect[a->nvect].src = a->ipc;
#ifdef SW_3D
        {
            avg_point *v = &a->vect[a->nvect];
            v->p3_valid = a->ip3_valid;
            v->p3[0] = a->ip3[0];
            v->p3[1] = a->ip3[1];
            v->p3[2] = a->ip3[2];
            v->p3_ck = a->ip3_ck;
            v->p3_dck = a->ip3_dck;
        }
#endif
        a->nvect++;
    } else {
        a->n_overflow++;
    }
}

static int avg_latch0(avg *a)
{
    a->ipc = a->pc;
    a->dvy = (uint16_t)((a->dvy & 0x1f00) | a->data);
    a->pc++;
    return 0;
}

static int avg_latch1(avg *a)
{
    a->dvy12 = (a->data >> 4) & 1;
    a->op = a->data >> 5;
    a->int_latch = 0;
    a->dvy = (uint16_t)((a->dvy12 << 12) | ((a->data & 0xf) << 8));
    a->dvx = 0;
    a->pc++;
    a->n_ops++;
    return 0;
}

static int avg_latch2(avg *a)
{
    a->dvx = (uint16_t)((a->dvx & 0x1f00) | a->data);
    a->pc++;
    return 0;
}

static int avg_latch3(avg *a)
{
#ifdef SW_3D
    {
        /* the tag goes with the bytes as they are read: the program may
         * rewrite them before the beam gets to the end of the vector */
        const sw3d_pt *t = sw3d_tag(a->pc);
        /* a subroutine (vector ROM, or a picture copied into RAM) is
         * where its caller put it: take the tag of the calling JSR */
        for (int d = 1; d <= 4 && (!t || t->valid == 0 || t->valid >= 3) && d <= a->sp; d++) {
            const sw3d_pt *c = sw3d_tag((uint16_t)(a->stack[(a->sp - d) & 3] - 1));
            if (c && c->valid) t = c;
        }
        a->ip3_valid = t ? t->valid : 0;
        a->ip3[0] = t ? t->x : 0;
        a->ip3[1] = t ? t->y : 0;
        a->ip3[2] = t ? t->z : 0;
        a->ip3_ck = t ? t->ck : 0;
        a->ip3_dck = t ? t->dck : 0;
    }
#endif
    a->int_latch = a->data >> 4;
    a->dvx = (uint16_t)(((a->int_latch & 1) << 12) | ((a->data & 0xf) << 8) | (a->dvx & 0xff));
    a->pc++;
    return 0;
}

static int avg_strobe0(avg *a)
{
    int i;

    if (OP0) {
        a->stack[a->sp & 3] = a->pc;
    } else {
        /* normalisation: shift the deltas up until one of them fills its
         * register, halving the timer each time.  The circuit does not check
         * for dvx = dvy = 0; MAME cuts that case off after 16 shifts. */
        i = 0;
        while ((((a->dvy ^ (a->dvy << 1)) & 0x1000) == 0)
            && (((a->dvx ^ (a->dvx << 1)) & 0x1000) == 0)
            && (i++ < 16)) {
            a->dvy = (uint16_t)((a->dvy & 0x1000) | ((a->dvy << 1) & 0x1fff));
            a->dvx = (uint16_t)((a->dvx & 0x1000) | ((a->dvx << 1) & 0x1fff));
            a->timer >>= 1;
            a->timer |= 0x4000 | (OP1 << 6);
        }
        if (OP1)
            a->timer &= 0xff;
    }
    return 0;
}

static int avg_strobe1(avg *a)
{
    int i;

    if (OP2 == 0) {
        for (i = a->bin_scale; i > 0; i--) {
            a->timer >>= 1;
            a->timer |= 0x4000 | (OP1 << 6);
        }
        if (OP1)
            a->timer &= 0xff;
    }
    if (OP2) {
        if (OP1)
            a->sp = (a->sp - 1) & 0xf;
        else
            a->sp = (a->sp + 1) & 0xf;
    }
    return 0;
}

static int starwars_strobe2(avg *a)
{
    if ((OP2 == 0) && (a->dvy12 == 0)) {
        a->intensity = a->dvy & 0xff;
        a->color = (a->dvy >> 8) & 0xf;
    }
    if (OP2) {
        if (OP0) {
            a->pc = (uint16_t)(a->dvy << 1);
            if (a->dvy == 0)
                a->n_jump0++;
        } else {
            a->pc = a->stack[a->sp & 3];
        }
    } else if (a->dvy12) {
        a->scale = a->dvy & 0xff;
        a->bin_scale = (a->dvy >> 8) & 7;
    }
    return 0;
}

static int starwars_strobe3(avg *a)
{
    int cycles = 0;

    a->halt = OP0;

    if ((a->op & 5) == 0) {
        if (OP1)
            cycles = 0x100 - (a->timer & 0xff);
        else
            cycles = 0x8000 - a->timer;
        a->timer = 0;

        a->xpos += ((((a->dvx >> 3) ^ XDAC_XOR) - 0x200) * cycles * (a->scale ^ 0xff)) >> 4;
        a->ypos -= ((((a->dvy >> 3) ^ YDAC_XOR) - 0x200) * cycles * (a->scale ^ 0xff)) >> 4;
    }
    if (OP2) {
        cycles = 0x8000 - a->timer;
        a->timer = 0;
        a->xpos = XCENTER;
        a->ypos = YCENTER;
        add_point(a, a->xpos, a->ypos, 0, 0);
    }
    if ((a->op & 5) == 0) {
        int z = ((a->int_latch >> 1) * a->intensity) >> 3;
        if (z > 0xff) z = 0xff;
        add_point(a, a->xpos, a->ypos, a->color & 7, (uint8_t)z);
    }
    return cycles;
}

static int (*const handler[8])(avg *) = {
    avg_latch0, avg_latch1, avg_latch2, avg_latch3,
    avg_strobe0, avg_strobe1, starwars_strobe2, starwars_strobe3
};

static uint8_t state_addr(const avg *a)
{
    return (uint8_t)((((a->state_latch >> 4) ^ 1) << 7) | (a->op << 4) | (a->state_latch & 0xf));
}

void avg_init(avg *a, const uint8_t *prom, const uint8_t *mem)
{
    memset(a, 0, sizeof *a);
    a->prom = prom;
    a->mem = mem;
    a->xpos = XCENTER;
    a->ypos = YCENTER;
    avg_reset(a, 0);
    a->n_reset = 0;
}

/* VGSTOP: MAME's avg_vgrst() and vg_set_halt(1) */
void avg_reset(avg *a, uint64_t now)
{
    avg_run(a, now);
    a->state_latch = 0;
    a->bin_scale = 0;
    a->scale = 0;
    a->color = 0;
    a->halt = 1;
    a->sync_halt = 1;
    a->n_reset++;
}

/* VGGO: MAME's avg_vggo(), vg_set_halt(0), and the state machine restarted
 * at once */
void avg_go(avg *a, uint64_t now)
{
    avg_run(a, now);
    a->pc = 0;
    a->sp = 0;
    a->halt = 0;
    a->sync_halt = 0;
    a->t = now;
    a->run_start = now;
    a->nvect = 0;
    a->n_states = a->n_ops = 0;
    a->n_go++;
}

void avg_run(avg *a, uint64_t now)
{
    while (a->t < now) {
        int cycles = 0;

        a->state_latch = (uint8_t)((a->state_latch & 0x10) | (a->prom[state_addr(a)] & 0xf));
        if (ST3) {
            a->data = a->mem[a->pc & 0x3fff];
            cycles = handler[a->state_latch & 7](a);
        }
        /* the halt flag was just strobed: the CPU sees it once the ticks this
         * state counted have passed */
        if (a->halt && !(a->state_latch & 0x10)) {
            a->halt_at = a->t + (uint64_t)cycles;
            a->n_halts++;
        }
        a->state_latch = (uint8_t)((a->halt << 4) | (a->state_latch & 0xf));
        a->t += (uint64_t)cycles + 8;
        a->n_states++;
    }
    if (a->halt && !a->sync_halt && now >= a->halt_at)
        a->sync_halt = 1;
}

int avg_halted(avg *a, uint64_t now)
{
    avg_run(a, now);
    return a->sync_halt;
}
