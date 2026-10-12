/* sw3d.c - the 3-D tap (sw3d.h). */
#include <math.h>
#include <string.h>
#include "sw.h"
#include "sw3d.h"
#include "platform/sw_platform.h"

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

/* VWSTAR and VWSTRG: each star is divided for with U at its entry in ST_PNT,
 * and drawn from there in screen-sector order */
#define T_ST_PNT        0x4C80
#define ST_IZP          6
#define ST_N            50
#define CK_VWSTAR_DRAW  0x7E7F
#define CK_VWSTRG_DRAW  0x7F7C

/* the span of JOBJDRW (wsobj.c) */
#define CK_JOBJDRW_LO   0x6819
#define CK_JOBJDRW_HI   0x6863

static sw3d_pt last;                 /* the point of the latest divide */
static sw3d_pt bj[64];               /* JOBJPNT's points, by BJ_PNT index */
static sw3d_pt st[ST_N];             /* the stars' points, by ST_PNT entry */
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
    } else if (last.valid == 1 && (uint16_t)(g.u - T_ST_PNT) < ST_N * ST_IZP) {
        st[(uint16_t)(g.u - T_ST_PNT) / ST_IZP] = last;
    }
}

void sw3d_vram_write(uint16_t addr)
{
    sw3d_pt t;
    if (g.ck >= CK_JOBJDRW_LO && g.ck <= CK_JOBJDRW_HI) {
        unsigned i = (unsigned)(uint16_t)(g.x - T_BJ_PNT) / 4u;
        t = i < 64 ? bj[i] : last;
    } else if (g.ck == CK_VWSTAR_DRAW || g.ck == CK_VWSTRG_DRAW) {
        /* the star's long vector, then the JSR to the star shape, drawn there */
        static sw3d_pt star;
        if ((uint16_t)(pending_src - T_ST_PNT) < ST_N * ST_IZP)
            star = st[(uint16_t)(pending_src - T_ST_PNT) / ST_IZP];
        t = star;
    } else if (pending_src >= T_M_GD && pending_src < T_M_GD + 0x200 && (pending_src & 0xC) == 0xC) {
        /* a ground object's screen point: block i of M_GD */
        t = gd[(pending_src - T_M_GD) >> 4];
    } else {
        /* anything else drawn after a divide: only a candidate until the
         * writer is known to draw what it divided for, or (a full point) its
         * projection is found to land where the beam does (4) */
        t = last;
        if (t.valid == 1) t.valid = 4;
        else if (t.valid) t.valid = 3;
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

/* ------------------------------------------------------------------ */
/* the resolver                                                         */
/* ------------------------------------------------------------------ */

/* The projection as the beam shows it (sw_platform.h):
 * sx = SX0 + SXK * y/x,  sy = SY0 - SYK * z/x */
#define SX0 SW_PROJ_X0
#define SXK SW_PROJ_XK
#define SY0 SW_PROJ_Y0
#define SYK SW_PROJ_YK
#define FIT 2.0f                     /* how near a full point's projection must land */

/* The writers (g.ck at the vector RAM write) by what they draw */
static int laser_writer(uint16_t ck) { return ck >= 0xAEC4 && ck <= 0xB044; }     /* VWLAZ, LAZVW */
/* pictures drawn whole at the point of their divide: a sprite at its depth */
static int sprite_writer(uint16_t ck, uint16_t dck)
{
    return ck == 0xAC65                                  /* GN1DRW: fireballs */
        || ck == 0x7863                                  /* DTHVW: the Death Star */
        || (ck == 0xCDBD && (dck == 0x7765 || dck == 0x77A4));   /* MGOWT after VWDTHA/B */
}

#define LZ_X0   256.0f               /* the guns' depth */
#define LZ_XMAX 16384.0f

/* The sight: the two JSRLs VWCURC writes (to its place, and to its picture
 * at VGSITE+2).  The lasers end under it at LZ_XMAX, so in a picture of the
 * world that is where it is; over a page of text it stays on the tube. */
static int sight_writer(uint16_t ck) { return ck == 0xB6CC; }

static float star_depth;
void sw3d_star_depth(float depth) { star_depth = depth; }
/* the stars of space only: VWSTRG's are the lights on the ground, which is where they belong */
static int star_writer(uint16_t ck) { return ck == CK_VWSTAR_DRAW; }

static void unproject(sw3d_out *o, float x, float sx, float sy)
{
    o->layer = SW3D_WORLD;
    o->x = x;
    o->y = (sx - SX0) / SXK * x;
    o->z = (SY0 - sy) / SYK * x;
}

void sw3d_resolve(const avg_point *pts, uint32_t n, const float *sx, const float *sy, sw3d_out *out)
{
    uint32_t n_world = 0;
    for (uint32_t i = 0; i < n; i++) {
        const avg_point *p = &pts[i];
        sw3d_out *o = &out[i];
        float p3x = p->p3[0], p3y = p->p3[1], p3z = p->p3[2];
        o->layer = SW3D_HUD;
        o->x = sx[i]; o->y = sy[i]; o->z = 0;
        if (laser_writer(p->p3_ck)) {
            /* below, with the rest of its line */
        } else if (p->p3_valid == 1 && p3x > 0) {
            o->layer = SW3D_WORLD;
            o->x = p3x; o->y = p3y; o->z = p3z;
        } else if (p->p3_valid == 2 && p3x > 0) {
            unproject(o, p3x, sx[i], sy[i]);
        } else if (p->p3_valid == 4 && p3x > 0
                   && fabsf(SX0 + SXK * p3y / p3x - sx[i]) + fabsf(SY0 - SYK * p3z / p3x - sy[i]) < FIT) {
            o->layer = SW3D_WORLD;
            o->x = p3x; o->y = p3y; o->z = p3z;
        } else if ((p->p3_valid == 3 || p->p3_valid == 4) && p3x > 0 && sprite_writer(p->p3_ck, p->p3_dck)) {
            unproject(o, p3x, sx[i], sy[i]);
        }
        if (o->layer == SW3D_WORLD && star_depth > 0 && star_writer(p->p3_ck)) unproject(o, star_depth, sx[i], sy[i]);
        if (o->layer == SW3D_WORLD) n_world++;
    }
    if (n_world)
        for (uint32_t i = 0; i < n; i++)
            if (sight_writer(pts[i].p3_ck)) unproject(&out[i], LZ_XMAX, sx[i], sy[i]);

    /* A laser is drawn from a gun to the sight in halves, each half as long
     * as the last: the screen picture of a bolt flying straight ahead.  Its
     * depth at a fraction f of the way is LZ_X0 / (1 - f). */
    for (uint32_t i = 1; i < n; ) {
        if (!(laser_writer(pts[i].p3_ck) && pts[i].z)) { i++; continue; }
        uint32_t a = i - 1, b = i;               /* a: the gun; b: the last lit point */
        while (b + 1 < n && laser_writer(pts[b + 1].p3_ck) && pts[b + 1].z) b++;
        float dx = sx[b] - sx[a], dy = sy[b] - sy[a], len2 = dx * dx + dy * dy;
        for (uint32_t k = a; k <= b; k++) {
            float f = len2 > 0 ? ((sx[k] - sx[a]) * dx + (sy[k] - sy[a]) * dy) / len2 : 0;
            float x = f < 1 ? LZ_X0 / (1 - f) : LZ_XMAX;
            unproject(&out[k], x < LZ_XMAX ? x : LZ_XMAX, sx[k], sy[k]);
        }
        i = b + 1;
    }
}
