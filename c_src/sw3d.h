/* sw3d.h - the 3-D tap: where each drawn vector came from in the game's own
 * 3-D space.  Built only with SW_3D; it watches and never changes the machine.
 *
 * The game projects a point by running a matrix-processor program that leaves
 * the point relative to the viewer in M_XP, M_YP, M_ZP (X is the depth, Y
 * across, Z up), dividing X into $0200 for 1/X, and multiplying Y and Z by it
 * (MS_PERS).  The projected pair then becomes a relative vector in vector RAM.
 *
 * The tap records the viewer-space point at every divide, tags each vector RAM
 * byte the program writes with the point it was drawn to, and avg.c reports
 * the instruction address behind every beam movement, so a drawn line's end
 * can be looked up here.
 */
#ifndef SW_3D_H
#define SW_3D_H

#include <stdint.h>
#include "avg.h"

#ifdef __cplusplus
extern "C" {
#endif

typedef struct {
    int16_t  x, y, z;     /* viewer space: x depth, y across, z up */
    uint16_t ck;          /* the checkpoint at which the point was recorded */
    uint8_t  valid;       /* 1: x, y, z; 2: the depth x only; 3: a candidate depth;
                             4: x, y, z of a candidate, to be checked against the screen (see sw3d.c) */
    uint16_t dck;         /* the checkpoint of the divide it came from */
    uint16_t src;         /* the first point-table or math RAM byte read for this write */
    uint8_t  blk[16];     /* the 16-byte math RAM block src lies in, as it was */
} sw3d_pt;

void sw3d_divide(uint16_t divisor);         /* the program wrote M_DVD */
void sw3d_read(uint16_t addr);              /* the program read the point table or math RAM */
void sw3d_vram_write(uint16_t addr);        /* the program wrote vector RAM */
const sw3d_pt *sw3d_tag(uint16_t addr);     /* the point the byte at addr was written for */
void sw3d_stats(unsigned long *divides, unsigned long *tagged);

/* Where each point of a finished picture belongs.  The screen is the AVG's,
 * in the units app.cpp draws with (x 0..250 across, y 0..280 down). */
enum { SW3D_HUD, SW3D_WORLD };
typedef struct {
    uint8_t layer;        /* SW3D_HUD: x, y the screen; SW3D_WORLD: x, y, z viewer space */
    float   x, y, z;      /* together, so &x is the point as float[3] */
} sw3d_out;
/* pts: the picture's points, n of them; sx, sy their screen positions; out:
 * one per point.  The line drawn to point i starts at point i-1. */
void sw3d_resolve(const avg_point *pts, uint32_t n, const float *sx, const float *sy, sw3d_out *out);

/* The game flies through its stars: they are as near as the ships.  A host
 * that wants a sky behind everything gives a depth here, and the resolver
 * puts each star at that depth where the tube shows it; 0 is the game's own. */
void sw3d_star_depth(float depth);

#ifdef __cplusplus
}
#endif
#endif
