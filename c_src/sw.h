/* sw.h - the Star Wars C port's runtime: machine state, the 6809 registers as
 * globals, memory access, flag helpers and the hardware seam.
 *
 * Every translated routine is `void name(void)` and works on this state the
 * way the ROM routine works on the machine.  See docs/PORT.md.
 */
#ifndef SW_H
#define SW_H

#include <stdint.h>

/* The sound board's program is a second C program of the same kind, with its
 * own machine state.  Its files define SW_SND_PROGRAM before including this header,
 * which then gives every runtime name its sound-side twin, so both programs
 * link into one executable.  Its routines carry the prefix s_. */
#ifdef SW_SND_PROGRAM
#define g               gsnd
#define rd8             snd_rd8
#define wr8             snd_wr8
#define rd16            snd_rd16
#define wr16            snd_wr16
#define hw_rd8          snd_hw_rd8
#define hw_wr8          snd_hw_wr8
#define hw_rd16         snd_hw_rd16
#define hw_wr16         snd_hw_wr16
#define sw_ck           snd_ck
#define sw_pass         snd_pass
#define sw_swi          snd_swi
#define sw_sei          snd_sei
#define sw_cli          snd_cli
#define call_rom        snd_call_rom
#define sw_thunk        snd_thunk
#define sw_routines     snd_routines
#define sw_nroutines    snd_nroutines
#define sw_checkpoints  snd_checkpoints
#define sw_ncheckpoints snd_ncheckpoints
#define sw_find         snd_find
#define sw_take_irq     snd_take_irq
#define irq             s_irq
#endif

#ifdef __cplusplus
extern "C" {
#endif

typedef struct {
    uint8_t mem[0x10000];        /* vector RAM, RAM, and the ROM image with bank 0 */
    uint8_t bank1[0x2000];       /* the other half of the banked ROM */
    uint8_t bank;                /* W.BANK D7: 0 root, 1 overlay */
    union { uint16_t d; struct { uint8_t b, a; } r; } acc;   /* D = A:B */
    uint16_t x, y, u, s;
    uint8_t dp;
    uint8_t fn, fz, fv, fc, fh;  /* condition codes, 0 or 1 each */
    uint8_t fi;                  /* interrupt mask */
    uint8_t unwind;              /* set by a routine that popped its caller's return address too */
    uint64_t cyc;                /* the 6809's cycle clock (1.512 MHz): see CYC */
    uint64_t poll_at;            /* the cycle from which a checkpoint calls the host: see CK */
#ifdef SW_3D
    uint16_t ck;                 /* the last checkpoint passed (sw3d.h) */
#endif
} sw_state;

extern sw_state g;

#define A   (g.acc.r.a)
#define B   (g.acc.r.b)
#define D   (g.acc.d)
#define X   (g.x)
#define Y   (g.y)
#define U   (g.u)
#define S   (g.s)
#define DP  (g.dp)
#define CCN (g.fn)
#define CCZ (g.fz)
#define CCV (g.fv)
#define CCC (g.fc)
#define CCH (g.fh)

/* ---- time ------------------------------------------------------------
 * CYC(n) charges the n cycles the 6809 spends on the instructions since the
 * last CYC.  It stands before everything that can see the time (a hardware
 * access, SEI/CLI, a checkpoint) and before control leaves the straight line,
 * so g.cyc there is the cycle at which the 6809 starts that instruction.  The
 * counts are the oracle core's (tests/cyctab.cpp); the verifier requires every
 * routine to take exactly the cycles the ROM routine took. */
#define CYC(n) (g.cyc += (uint64_t)(n))
#define SW_IRQ_ENTRY_CYCLES 19           /* the 6809 taking IRQ: 7 + the 12 bytes it pushes */

/* ---- memory ----------------------------------------------------------
 * M8(addr) is an lvalue for an address known to be RAM.  rd8/wr8/rd16/wr16
 * take any address: RAM, ROM (by the bank latch) or the hardware seam. */
#define M8(a) (g.mem[(uint16_t)(a)])

uint8_t  rd8(uint16_t a);
void     wr8(uint16_t a, uint8_t v);
uint16_t rd16(uint16_t a);
void     wr16(uint16_t a, uint16_t v);

/* ---- the hardware seam: $4300-$47FF ----------------------------------
 * Implemented by a harness (replaying the oracle) or by the host. */
uint8_t  hw_rd8(uint16_t a);
void     hw_wr8(uint16_t a, uint8_t v);
uint16_t hw_rd16(uint16_t a);            /* high byte first, as the 6809 does */
void     hw_wr16(uint16_t a, uint16_t v);

/* A checkpoint: a place where the program can be interrupted - every routine
 * entry, loop top and label, and the few places listed in tools/xlate.py.  The
 * 6809 can be interrupted between any two instructions; the C can only where
 * its state is the 6809's, and these are such places, close enough together
 * that an interrupt never waits long.  The host takes a pending interrupt
 * here (it sets g.poll_at to the cycle the next one is due); the verifier
 * logs the ROM passing each of them and requires the C to pass the same ones
 * in the same order. */
void     sw_ck(uint16_t pc);
#ifdef SW_3D
#define  CK(pc) do { g.ck = (pc); if (g.cyc >= g.poll_at) sw_ck(pc); } while (0)
#else
#define  CK(pc) do { if (g.cyc >= g.poll_at) sw_ck(pc); } while (0)
#endif

/* The start of a game frame in the mainline ($602F).  The host presents a
 * frame here; the verifier ends a pass here. */
void     sw_pass(uint16_t pc);
void     sw_resume_frame(void);          /* hand/mainline.c: one pass, from $602F round to $602F */

void     sw_swi(uint16_t pc);            /* the program's error trap; does not return */
void     sw_sei(void);                   /* ORCC #$10 */
void     sw_cli(void);                   /* ANDCC #$EF */

/* ---- calls -----------------------------------------------------------
 * The 6809 stack is kept, so stack-relative operands mean what they mean in
 * the ROM: a call moves S down two bytes and a return moves it back. */
#define JSR(f) (S = (uint16_t)(S - 2), f())
#define RTS    do { S = (uint16_t)(S + 2); return; } while (0)

/* An indirect call or jump: the routine at a ROM address (and the bank in
 * force, for $6000-$7FFF). */
void     call_rom(uint16_t addr);
/* A routine with no C function yet: the harness runs the ROM routine itself. */
void     sw_thunk(uint16_t addr, int bank);

typedef struct {
    uint16_t addr;
    uint8_t  bank;               /* 0 root (and everything outside $6000-$7FFF), 1 overlay */
    uint8_t  flags_out;          /* condition codes its callers use: N 8, Z 4, V 2, C 1 */
    uint8_t  thunk;              /* 1 = no C translation; runs as a ROM thunk */
    void   (*fn)(void);
    const char *name;
} sw_routine;

extern const sw_routine sw_routines[];
extern const unsigned   sw_nroutines;
extern const uint32_t   sw_checkpoints[];    /* bank << 16 | address of every CK() */
extern const unsigned   sw_ncheckpoints;
const sw_routine *sw_find(uint16_t addr, int bank);

/* The interrupt: pushes the 6809's frame (with `pc` as the interrupted PC),
 * runs the handler, and restores the registers from the frame as RTI does. */
void     sw_take_irq(uint16_t pc);
void     irq(void);              /* the handler itself (IRQ, $EF56) */

/* ---- stack -------------------------------------------------------------- */
static inline void    push8(uint8_t v)   { S = (uint16_t)(S - 1); g.mem[S] = v; }
static inline uint8_t pull8(void)        { uint8_t v = g.mem[S]; S = (uint16_t)(S + 1); return v; }
static inline void    push16(uint16_t v) { push8((uint8_t)v); push8((uint8_t)(v >> 8)); }
static inline uint16_t pull16(void)      { uint16_t h = pull8(); return (uint16_t)((h << 8) | pull8()); }

static inline uint8_t cc_pack(void)
{
    return (uint8_t)(CCC | (CCV << 1) | (CCZ << 2) | (CCN << 3) | (g.fi << 4) | (CCH << 5));
}
static inline void cc_unpack(uint8_t v)
{
    CCC = v & 1; CCV = (v >> 1) & 1; CCZ = (v >> 2) & 1; CCN = (v >> 3) & 1;
    g.fi = (v >> 4) & 1; CCH = (v >> 5) & 1;
}

/* ---- condition codes -----------------------------------------------------
 * The translator uses these only where a flag an instruction sets is read
 * later; elsewhere it writes the plain C operation. */
static inline void nz8(uint8_t v)   { CCN = v >> 7; CCZ = (v == 0); CCV = 0; }
static inline void nz16(uint16_t v) { CCN = (uint8_t)(v >> 15); CCZ = (v == 0); CCV = 0; }

static inline uint8_t add8(uint8_t a, uint8_t b)
{
    unsigned r = (unsigned)a + b;
    CCH = (uint8_t)(((a ^ b ^ r) >> 4) & 1);
    CCC = (uint8_t)(r >> 8);
    CCV = (uint8_t)(((a ^ r) & (b ^ r) & 0x80) >> 7);
    CCN = (uint8_t)((r >> 7) & 1); CCZ = ((r & 0xff) == 0);
    return (uint8_t)r;
}
static inline uint8_t adc8(uint8_t a, uint8_t b)
{
    unsigned r = (unsigned)a + b + CCC;
    CCH = (uint8_t)(((a ^ b ^ r) >> 4) & 1);
    CCC = (uint8_t)(r >> 8);
    CCV = (uint8_t)(((a ^ r) & (b ^ r) & 0x80) >> 7);
    CCN = (uint8_t)((r >> 7) & 1); CCZ = ((r & 0xff) == 0);
    return (uint8_t)r;
}
static inline uint8_t sub8(uint8_t a, uint8_t b)
{
    unsigned r = (unsigned)a - b;
    CCC = (uint8_t)((r >> 8) & 1);
    CCV = (uint8_t)(((a ^ b) & (a ^ r) & 0x80) >> 7);
    CCN = (uint8_t)((r >> 7) & 1); CCZ = ((r & 0xff) == 0);
    return (uint8_t)r;
}
static inline uint8_t sbc8(uint8_t a, uint8_t b)
{
    unsigned r = (unsigned)a - b - CCC;
    CCC = (uint8_t)((r >> 8) & 1);
    CCV = (uint8_t)(((a ^ b) & (a ^ r) & 0x80) >> 7);
    CCN = (uint8_t)((r >> 7) & 1); CCZ = ((r & 0xff) == 0);
    return (uint8_t)r;
}
static inline void    cmp8(uint8_t a, uint8_t b) { (void)sub8(a, b); }
static inline uint8_t and8(uint8_t a, uint8_t b) { a &= b; nz8(a); return a; }
static inline uint8_t or8(uint8_t a, uint8_t b)  { a |= b; nz8(a); return a; }
static inline uint8_t eor8(uint8_t a, uint8_t b) { a ^= b; nz8(a); return a; }
static inline uint8_t neg8(uint8_t v)
{
    uint8_t r = (uint8_t)(0 - v);
    CCC = (v != 0); CCV = (v == 0x80); CCN = r >> 7; CCZ = (r == 0);
    return r;
}
static inline uint8_t com8(uint8_t v) { v = (uint8_t)~v; nz8(v); CCC = 1; return v; }
static inline uint8_t inc8(uint8_t v) { v = (uint8_t)(v + 1); CCN = v >> 7; CCZ = (v == 0); CCV = (v == 0x80); return v; }
static inline uint8_t dec8(uint8_t v) { v = (uint8_t)(v - 1); CCN = v >> 7; CCZ = (v == 0); CCV = (v == 0x7f); return v; }
static inline uint8_t asl8(uint8_t v)
{
    uint8_t r = (uint8_t)(v << 1);
    CCC = v >> 7; CCN = r >> 7; CCZ = (r == 0); CCV = (uint8_t)(CCN ^ CCC);
    return r;
}
static inline uint8_t lsr8(uint8_t v) { CCC = v & 1; v >>= 1; CCN = 0; CCZ = (v == 0); return v; }
static inline uint8_t asr8(uint8_t v)
{
    CCC = v & 1; v = (uint8_t)((v >> 1) | (v & 0x80)); CCN = v >> 7; CCZ = (v == 0);
    return v;
}
static inline uint8_t rol8(uint8_t v)
{
    uint8_t r = (uint8_t)((v << 1) | CCC);
    CCC = v >> 7; CCN = r >> 7; CCZ = (r == 0); CCV = (uint8_t)(CCN ^ CCC);
    return r;
}
static inline uint8_t ror8(uint8_t v)
{
    uint8_t r = (uint8_t)((v >> 1) | (CCC << 7));
    CCC = v & 1; CCN = r >> 7; CCZ = (r == 0);
    return r;
}
static inline void clrf(void) { CCN = 0; CCZ = 1; CCV = 0; CCC = 0; }

static inline uint16_t add16(uint16_t a, uint16_t b)
{
    uint32_t r = (uint32_t)a + b;
    CCC = (uint8_t)(r >> 16);
    CCV = (uint8_t)(((a ^ r) & (b ^ r) & 0x8000) >> 15);
    CCN = (uint8_t)((r >> 15) & 1); CCZ = ((r & 0xffff) == 0);
    return (uint16_t)r;
}
static inline uint16_t sub16(uint16_t a, uint16_t b)
{
    uint32_t r = (uint32_t)a - b;
    CCC = (uint8_t)((r >> 16) & 1);
    CCV = (uint8_t)(((a ^ b) & (a ^ r) & 0x8000) >> 15);
    CCN = (uint8_t)((r >> 15) & 1); CCZ = ((r & 0xffff) == 0);
    return (uint16_t)r;
}
static inline void cmp16(uint16_t a, uint16_t b) { (void)sub16(a, b); }
static inline void mul_ab(void) { D = (uint16_t)(A * B); CCZ = (D == 0); CCC = B >> 7; }
static inline void sex_b(void)  { A = (B & 0x80) ? 0xff : 0x00; CCN = A & 1; CCZ = (D == 0); }
static inline void daa_a(void)
{
    uint8_t lsn = A & 0x0f, msn = A & 0xf0, cf = 0;
    if (lsn > 0x09 || CCH) cf |= 0x06;
    if (msn > 0x80 && lsn > 0x09) cf |= 0x60;
    if (msn > 0x90 || CCC) cf |= 0x60;
    {
        unsigned t = (unsigned)A + cf;
        CCC = (uint8_t)(CCC | ((t >> 8) & 1));
        A = (uint8_t)t;
    }
    CCN = A >> 7; CCZ = (A == 0);
}

#ifdef __cplusplus
}
#endif
#endif
