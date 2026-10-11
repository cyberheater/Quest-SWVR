/* sw3d.c - the 3-D tap (sw3d.h). */
#include <string.h>
#include "sw.h"
#include "sw3d.h"

/* Math RAM cells and the object point table (sw_defs.h) */
#define T_M_XP   0x5000
#define T_M_YP   0x5002
#define T_M_ZP   0x5004
#define T_BJ_PNT 0x4C00

/* JBJGPNT and JBJBCLP (ground objects: one divide per point, in point
 * order, the divisor being the point's translated depth Xr+Xp) */
#define CK_JBJGPNT      0x692D
#define CK_JBJGPNT_END  0x6977
#define CK_JBJBCLP      0x6978
#define CK_JBJBCLP_END  0x6A0B
#define T_M_GD          0x5E00

/* the span of JOBJDRW (wsobj.c) */
#define CK_JOBJDRW_LO   0x6819
#define CK_JOBJDRW_HI   0x6863

static sw3d_pt last;                 /* the point of the latest divide */
static sw3d_pt bj[64];               /* JOBJPNT's points, by BJ_PNT index */
static sw3d_pt gd[32];               /* JBJGPNT's points (depth only), by M_GD block */
static unsigned gd_n;
static sw3d_pt tag[0x3000];          /* per vector RAM byte */
static unsigned long n_div, n_tag;
static uint16_t pending_src;         /* first source byte read since the last vector RAM word */

void sw3d_read(uint16_t addr)
{
    if (!pending_src) pending_src = addr;
}

static int16_t m16(uint16_t a) { return (int16_t)((g.mem[a] << 8) | g.mem[a + 1]); }

void sw3d_divide(uint16_t divisor)
{
    n_div++;
    last.ck = last.dck = g.ck;
    /* the usual case: the divisor is the viewer-space depth just computed */
    if (divisor == (uint16_t)m16(T_M_XP)) {
        last.x = m16(T_M_XP);
        last.y = m16(T_M_YP);
        last.z = m16(T_M_ZP);
        last.valid = 1;
    } else {
        /* most other divides are a depth too, but not all: a candidate */
        last.x = (int16_t)divisor;
        last.y = last.z = 0;
        last.valid = 3;
    }
    /* ground objects: the points' depths, in order */
    if (g.ck >= CK_JBJGPNT && g.ck <= CK_JBJBCLP_END) {
        if (g.ck == CK_JBJGPNT || g.ck == CK_JBJBCLP) gd_n = 0;
        if (gd_n < 32) {
            gd[gd_n].x = (int16_t)divisor;
            gd[gd_n].y = gd[gd_n].z = 0;
            gd[gd_n].valid = 2;
            gd[gd_n].dck = g.ck;
            gd_n++;
        }
        last.valid = 0;
        return;
    }
    /* JOBJPNT: X walks BJ_PNT, four bytes a point (g.ck is MGOWT's by now) */
    if ((uint16_t)(g.x - T_BJ_PNT) < 0x100) {
        unsigned i = (unsigned)(uint16_t)(g.x - T_BJ_PNT) / 4u;
        if (i < 64) bj[i] = last;
    }
}

void sw3d_vram_write(uint16_t addr)
{
    sw3d_pt t;
    if (g.ck >= CK_JOBJDRW_LO && g.ck <= CK_JOBJDRW_HI) {
        unsigned i = (unsigned)(uint16_t)(g.x - T_BJ_PNT) / 4u;
        t = i < 64 ? bj[i] : last;
    } else if (pending_src >= T_M_GD && pending_src < T_M_GD + 0x200 && (pending_src & 0xC) == 0xC) {
        /* a ground object's screen point: block i of M_GD */
        t = gd[(pending_src - T_M_GD) >> 4];
    } else {
        /* anything else drawn after a divide: only a candidate until the
         * writer is known to draw what it divided for */
        t = last;
        if (t.valid) t.valid = 3;
    }
    t.ck = g.ck;                     /* where the vector was written */
    t.src = pending_src;
    if (pending_src >= 0x5000) memcpy(t.blk, &g.mem[pending_src & 0xFFF0], 16);
    else memset(t.blk, 0, 16);
    if (addr & 1) pending_src = 0;   /* a word is written high byte first */
    tag[addr] = t;
    if (t.valid) n_tag++;
}

const sw3d_pt *sw3d_tag(uint16_t addr)
{
    return addr < 0x3000 ? &tag[addr] : 0;
}

void sw3d_stats(unsigned long *divides, unsigned long *tagged)
{
    *divides = n_div;
    *tagged = n_tag;
}
