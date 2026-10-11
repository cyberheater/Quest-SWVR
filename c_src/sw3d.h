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

#ifdef __cplusplus
extern "C" {
#endif

typedef struct {
    int16_t  x, y, z;     /* viewer space: x depth, y across, z up */
    uint16_t ck;          /* the checkpoint at which the point was recorded */
    uint8_t  valid;       /* 1: x, y, z; 2: the depth x only; 3: a candidate depth (see sw3d.c) */
    uint16_t dck;         /* the checkpoint of the divide it came from */
    uint16_t src;         /* the first point-table or math RAM byte read for this write */
    uint8_t  blk[16];     /* the 16-byte math RAM block src lies in, as it was */
} sw3d_pt;

void sw3d_divide(uint16_t divisor);         /* the program wrote M_DVD */
void sw3d_read(uint16_t addr);              /* the program read the point table or math RAM */
void sw3d_vram_write(uint16_t addr);        /* the program wrote vector RAM */
const sw3d_pt *sw3d_tag(uint16_t addr);     /* the point the byte at addr was written for */
void sw3d_stats(unsigned long *divides, unsigned long *tagged);

#ifdef __cplusplus
}
#endif
#endif
