/* sw_rt.c - the C port's runtime (sw.h): the state, memory access by address,
 * the registry lookup and the interrupt frame.  Compiled twice: as it stands
 * for the main program, and with SW_SND_PROGRAM for the sound board's. */
#include <string.h>
#include "sw.h"
#if defined(SW_3D) && !defined(SW_SND_PROGRAM)
#include "sw3d.h"
#endif

sw_state g;

#ifdef SW_SND_PROGRAM
/* the sound board: A15 is not decoded.  $1000-$107F and $2000-$27FF are RAM,
 * $4000-$7FFF ROM, everything else below $4000 the hardware seam */
#define ADDR(a)   ((uint16_t)((a) & 0x7fff))
#define IS_HW(a)  ((a) < 0x4000 && !IS_RAM(a))
#define IS_RAM(a) (((a) >= 0x1000 && (a) < 0x1080) || ((a) >= 0x2000 && (a) < 0x2800))
#define ROM8(a)   (g.mem[a])
#else
#define ADDR(a)   (a)
#define IS_HW(a)  ((a) >= 0x4300 && (a) < 0x4800)
#define IS_RAM(a) ((a) < 0x3000 || ((a) >= 0x4800 && (a) < 0x6000))
#define ROM8(a)   (((a) >= 0x6000 && (a) < 0x8000 && g.bank) ? g.bank1[(a) - 0x6000] : g.mem[a])
#endif

uint8_t rd8(uint16_t a)
{
    a = ADDR(a);
    if (IS_HW(a)) return hw_rd8(a);
#if defined(SW_3D) && !defined(SW_SND_PROGRAM)
    if (a >= 0x4C00 && a < 0x6000) sw3d_read(a);
#endif
    return ROM8(a);
}

void wr8(uint16_t a, uint8_t v)
{
    a = ADDR(a);
    if (IS_HW(a)) { hw_wr8(a, v); return; }
#if defined(SW_3D) && !defined(SW_SND_PROGRAM)
    if (a < 0x3000) sw3d_vram_write(a);
#endif
    if (IS_RAM(a)) g.mem[a] = v;
    /* a write to ROM or to nothing does nothing */
}

uint16_t rd16(uint16_t a)
{
    uint16_t h;
    a = ADDR(a);
    if (IS_HW(a)) return hw_rd16(a);
    h = rd8(a);
    return (uint16_t)((h << 8) | rd8((uint16_t)(a + 1)));
}

void wr16(uint16_t a, uint16_t v)
{
    a = ADDR(a);
    if (IS_HW(a)) { hw_wr16(a, v); return; }
    wr8(a, (uint8_t)(v >> 8));
    wr8((uint16_t)(a + 1), (uint8_t)v);
}

const sw_routine *sw_find(uint16_t addr, int bank)
{
    unsigned lo = 0, hi = sw_nroutines;
    int b;

    addr = ADDR(addr);
    b = (addr >= 0x6000 && addr < 0x8000) ? (bank != 0) : 0;

    /* the table is sorted by bank, then address */
    while (lo < hi) {
        unsigned mid = (lo + hi) / 2;
        const sw_routine *r = &sw_routines[mid];
        if (r->bank < b || (r->bank == b && r->addr < addr)) lo = mid + 1;
        else hi = mid;
    }
    if (lo < sw_nroutines && sw_routines[lo].addr == addr && sw_routines[lo].bank == b)
        return &sw_routines[lo];
    return 0;
}

void call_rom(uint16_t addr)
{
    const sw_routine *r = sw_find(addr, g.bank);
    if (r) r->fn();
    else sw_thunk(addr, g.bank);
}

/* The 6809 takes an IRQ: the whole register set is pushed (E set), I is set,
 * the handler runs, and RTI pulls the registers back. */
void sw_take_irq(uint16_t pc)
{
    push16(pc);
    push16(U);
    push16(Y);
    push16(X);
    push8(DP);
    push8(B);
    push8(A);
    push8((uint8_t)(cc_pack() | 0x80));
    CYC(SW_IRQ_ENTRY_CYCLES);
    g.fi = 1;
#ifdef SW_3D
    uint16_t ck = g.ck;              /* the 3-D tap goes by where the program was */
#endif
    irq();
#ifdef SW_3D
    g.ck = ck;
#endif
    cc_unpack(pull8());
    A = pull8();
    B = pull8();
    DP = pull8();
    X = pull16();
    Y = pull16();
    U = pull16();
    S = (uint16_t)(S + 2);
}
