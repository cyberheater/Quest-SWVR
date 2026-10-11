/* port.cpp - the C port as a machine: the two translated programs (gen/, hand/
 * and gen_snd/) running on the chip models (hw.cpp) with no 6809.
 *
 * This is the hardware seam of sw.h for a real run - what tests/lockstep.cpp
 * is for a verified one.
 *
 * Time.  Each program has its own cycle clock (g.cyc, gsnd.cyc: sw.h CYC), which
 * the verifier proved equal to the ROM's, routine by routine.  The chips are
 * read and written at those clocks.
 *
 * Interrupts.  The C has no instruction boundaries, so an interrupt that has
 * come due is taken at the next place the program can see one: a hardware
 * access, a checkpoint (CK), SEI, CLI, the start of a pass.  Those are exactly
 * the events the verifier anchors the ROM's interrupts to, and it proved that
 * the code between two of them cannot tell the difference.
 *
 * Control.  Each program is a loop that never returns, so each runs on a fiber
 * of its own.  The main program's fiber hands over to the sound program's
 * whenever that one is behind, and back to the host when the machine has
 * reached the time the host asked for.  A RESET (the watchdog; the main
 * board's reset line to the sound board) throws the fiber away and starts a
 * new one at the reset entry.
 */
#include "fiber.h"
#include <cstdio>
#include <cstring>
#include "board.h"
#include "tms5220.h"
#include "port.h"
extern "C" {
#include "sw.h"
}
#ifdef SW_3D
#include "sw3d.h"
#endif
/* sw.h's register names are single letters: keep them out of this file */
#undef A
#undef B
#undef D
#undef X
#undef Y
#undef U
#undef S
#undef DP

extern "C" {
/* the sound program's side of sw.h (its files are compiled with SW_SND_PROGRAM) */
extern sw_state gsnd;
const sw_routine *snd_find(uint16_t addr, int bank);
void snd_take_irq(uint16_t pc);
}

#define MAIN_RESET  0xF261u
#define SND_RESET   0x7D44u
#define FIBER_STACK (256u * 1024u * 1024u)      /* reserve: the self test never returns from its calls */

static fib_t fib_host, fib_main, fib_snd;
static uint64_t run_target;
static int main_restart;
static void (*on_pass)(void);
static unsigned long n_swi, n_irq_taken;

/* ---- the sound program -------------------------------------------------- */
static void snd_fiber(void)
{
    for (;;) {
        snd_find(SND_RESET, 0)->fn();
        fib_switch(fib_main);                 /* it does not return; if it did, start over */
    }
}

static void snd_restart(void);
static void cpu_reset(int cpu) { if (cpu == SW_SOUND) snd_restart(); }   /* the main one is port_run_until()'s business */

static void snd_restart(void)
{
    if (fib_snd) fib_delete(fib_snd);
    fib_snd = fib_create(8 * 1024 * 1024, snd_fiber);
    gsnd.cyc = SW.snd_cyc;
    gsnd.fi = 1;
    gsnd.dp = 0;
    gsnd.unwind = 0;
}

/* every place the sound program can be interrupted, or sees hardware */
static void snd_sync(void)
{
    SW.snd_cyc = gsnd.cyc;
    sw_snd_chips_advance();
    while (sw_snd_irq() && !gsnd.fi) {
        snd_take_irq(0x7D4C);
        SW.snd_cyc = gsnd.cyc;
        sw_snd_chips_advance();
    }
    if (gsnd.cyc >= g.cyc) fib_switch(fib_main);
    gsnd.poll_at = 0;                            /* the sound program is small: every checkpoint comes here */
}

extern "C" uint8_t snd_hw_rd8(uint16_t a) { snd_sync(); return sw_snd_hw_read(a); }
extern "C" void snd_hw_wr8(uint16_t a, uint8_t v) { snd_sync(); sw_snd_hw_write(a, v); }
extern "C" uint16_t snd_hw_rd16(uint16_t a)
{
    snd_sync();
    uint16_t h = sw_snd_hw_read(a);
    return (uint16_t)((h << 8) | sw_snd_hw_read((uint16_t)(a + 1)));
}
extern "C" void snd_hw_wr16(uint16_t a, uint16_t v)
{
    snd_sync();
    sw_snd_hw_write(a, (uint8_t)(v >> 8));
    sw_snd_hw_write((uint16_t)(a + 1), (uint8_t)v);
}
extern "C" void snd_ck(uint16_t) { snd_sync(); }
extern "C" void snd_pass(uint16_t) { snd_sync(); }
extern "C" void snd_sei(void) { snd_sync(); gsnd.fi = 1; }
extern "C" void snd_cli(void) { gsnd.fi = 0; snd_sync(); }
/* the sound board's SWI vectors all point at its reset entry */
extern "C" void snd_swi(uint16_t) { gsnd.fi = 1; snd_find(SND_RESET, 0)->fn(); }
extern "C" void snd_thunk(uint16_t, int) { gsnd.fi = 1; snd_find(SND_RESET, 0)->fn(); }

/* ---- the main program ---------------------------------------------------- */
static void main_fiber(void)
{
    for (;;) {
        sw_find(MAIN_RESET, 0)->fn();
        fib_switch(fib_host);
    }
}

static void main_cpu_reset(void)
{
    g.fi = 1;
    g.dp = 0;
    g.bank = 0;
    g.unwind = 0;
}

/* every place the main program can be interrupted, or sees hardware */
static void main_sync(void)
{
    for (;;) {
        SW.cyc = g.cyc;
        if (SW.cyc - SW.last_kick > SW.wd_cycles) {
            /* the watchdog bites: RESET.  This fiber is abandoned. */
            SW.n_wd_bites++;
            sw_machine_reset(SW_RST_WATCHDOG);
            main_restart = 1;
            fib_switch(fib_host);
        }
        while (SW.cyc >= SW.next_irq) {
            if (SW.irq_pending) SW.n_irq_lost++;
            SW.irq_pending = 1;
            SW.n_irq++;
            SW.next_irq += SW_IRQ_CYCLES;
        }
        avg_run(&SW.vg, SW.cyc * 8);
        if (gsnd.cyc < g.cyc) fib_switch(fib_snd);
        if (!SW.irq_pending || g.fi) break;
        SW.irq_pending = 0;
        n_irq_taken++;
        sw_take_irq(0x6100);                    /* the handler checks the PC it interrupted is in the program */
    }
    if (g.cyc >= run_target) fib_switch(fib_host);
    /* until then a checkpoint has nothing to do: the next interrupt, or the
     * end of this slice.  (An interrupt that is waiting behind SEI is taken at
     * the CLI.) */
    g.poll_at = SW.next_irq < run_target ? SW.next_irq : run_target;
}

extern "C" uint8_t hw_rd8(uint16_t a) { main_sync(); return sw_hw_read(a); }
extern "C" void hw_wr8(uint16_t a, uint8_t v)
{
    main_sync();
    sw_hw_write(a, v);
    g.bank = (uint8_t)SW.bank;
}
extern "C" uint16_t hw_rd16(uint16_t a)
{
    main_sync();
    uint16_t h = sw_hw_read(a);
    return (uint16_t)((h << 8) | sw_hw_read((uint16_t)(a + 1)));
}
extern "C" void hw_wr16(uint16_t a, uint16_t v)
{
    main_sync();
#ifdef SW_3D
    if (a == 0x4704) sw3d_divide(v);            /* M_DVD: the 3-D tap watches every divide */
#endif
    sw_hw_write(a, (uint8_t)(v >> 8));
    sw_hw_write((uint16_t)(a + 1), (uint8_t)v);
}
extern "C" void sw_ck(uint16_t) { main_sync(); }
extern "C" void sw_pass(uint16_t)
{
    main_sync();
    if (on_pass) on_pass();
}
extern "C" void sw_sei(void) { main_sync(); g.fi = 1; }
extern "C" void sw_cli(void) { g.fi = 0; main_sync(); }

/* SWI is the program's error trap: the 6809 goes to INTDIS, a branch to itself
 * with interrupts off, and the watchdog ends it. */
extern "C" void sw_swi(uint16_t)
{
    n_swi++;
    g.fi = 1;
    for (;;) {
        g.cyc += 3;
        main_sync();
    }
}
extern "C" void sw_thunk(uint16_t, int) { sw_swi(0); }

/* ---- the machine ---------------------------------------------------------- */
void port_power_on(const sw_roms *roms, void (*pass_hook)(void))
{
    on_pass = pass_hook;
    if (!fib_host) fib_host = fib_self();

    memset(&g, 0, sizeof g);
    memcpy(g.mem + 0x3000, roms->main_rom + 0x3000, 0x1000);
    memcpy(g.mem + 0x6000, roms->main_rom + 0x6000, 0xa000);
    memcpy(g.bank1, roms->bank1, 0x2000);
    memset(&gsnd, 0, sizeof gsnd);
    memcpy(gsnd.mem + 0x4000, roms->sound_rom + 0x4000, 0x4000);

    SW.cpu_reset_hook = cpu_reset;
    sw_bind_memory(g.mem);
    sw_power_on();                               /* resets the sound board too: snd_restart() */
    main_cpu_reset();
    if (fib_main) fib_delete(fib_main);
    fib_main = fib_create(FIBER_STACK, main_fiber);
    main_restart = 0;
}

void port_reset(void)
{
    sw_machine_reset(SW_RST_SCRIPT);
    main_restart = 1;
}

void port_run_until(uint64_t target)
{
    run_target = target;
    while (g.cyc < target) {
        if (main_restart) {
            fib_delete(fib_main);
            fib_main = fib_create(FIBER_STACK, main_fiber);
            main_cpu_reset();
            main_restart = 0;
        }
        fib_switch(fib_main);
    }
    SW.cyc = g.cyc;
}

uint8_t *port_main_mem(void) { return g.mem; }
uint64_t port_cycles(void) { return g.cyc; }
unsigned long port_swi(void) { return n_swi; }
