/* board.cpp - the Star Wars machine as the oracle runs it: the two 6809 cores
 * (cpu/cpu_m6809.cpp) on the hardware of hw.cpp, one timeline.
 *
 * The hardware model - the contract the C port's seam has to reproduce - is
 * the header of hw.cpp.  What is here is the 6809s' side of it:
 *  - each CPU's memory map: RAM and ROM here, everything else in hw.cpp;
 *  - a bus access is taken to happen at the START of its instruction;
 *  - the sound CPU is stepped after each main-CPU step until it has caught up,
 *    so it is never more than one instruction behind;
 *  - the IRQ is requested every 6,144 cycles; the request stays until the 6809
 *    takes it or IRCLR is written.
 */
#include <cstdarg>
#include <cstdio>
#include <cstring>
#include "cpu/cpu_m6809.h"
#include "board.h"

static cpu_m6809 *cpu0, *cpu1;

extern "C" void sw_cpu_log(const char *fmt, ...)
{
    if (SW.n_cpu_log < 4) {
        va_list ap;
        va_start(ap, fmt);
        vsnprintf(SW.first_log[SW.n_cpu_log], sizeof SW.first_log[0], fmt, ap);
        va_end(ap);
    }
    SW.n_cpu_log++;
}

/* ------------------------------------------------------------------ */
/* the two memory maps                                                  */
/* ------------------------------------------------------------------ */

static UINT8 main_read(UINT32 a, struct MemoryReadByte *)
{
    if (a < 0x4000) {                                       /* vector RAM, vector ROM */
        if (SW.mem_hook && a < 0x3000) SW.mem_hook(a, 0);
        return SW.mem[a];
    }
    if (a >= 0x8000) return SW.mem[a];
    if (a >= 0x6000) return SW.bank ? SW.bank1[a - 0x6000] : SW.mem[a];
    if (a >= 0x4800) {
        if (SW.mem_hook) SW.mem_hook(a, 0);
        return SW.mem[a];
    }
    return sw_hw_read(a);
}

static void main_write(UINT32 a, UINT8 d, struct MemoryWriteByte *)
{
    if (a < 0x3000 || (a >= 0x4800 && a < 0x6000)) {
        if (SW.mem_hook) SW.mem_hook(a, 1);
        SW.mem[a] = d;
        return;
    }
    sw_hw_write(a, d);
}

static UINT8 snd_read(UINT32 a, struct MemoryReadByte *)
{
    a &= 0x7fff;
    if (a >= 0x4000) return SW.snd[a];
    if ((a >= 0x2000 && a < 0x2800) || (a >= 0x1000 && a < 0x1080)) {
        if (SW.snd_mem_hook) SW.snd_mem_hook(a, 0);
        return SW.snd[a];
    }
    return sw_snd_hw_read(a);
}

static void snd_write(UINT32 a, UINT8 d, struct MemoryWriteByte *)
{
    a &= 0x7fff;
    if ((a >= 0x2000 && a < 0x2800) || (a >= 0x1000 && a < 0x1080)) {
        if (SW.snd_mem_hook) SW.snd_mem_hook(a, 1);
        SW.snd[a] = d;
        return;
    }
    sw_snd_hw_write(a, d);
}

static MemoryReadByte main_r[] = { { 0x0000, 0xffff, main_read, nullptr }, { 0xffffffff, 0, nullptr, nullptr } };
static MemoryWriteByte main_w[] = { { 0x0000, 0xffff, main_write, nullptr }, { 0xffffffff, 0, nullptr, nullptr } };
static MemoryReadByte snd_r[] = { { 0x0000, 0xffff, snd_read, nullptr }, { 0xffffffff, 0, nullptr, nullptr } };
static MemoryWriteByte snd_w[] = { { 0x0000, 0xffff, snd_write, nullptr }, { 0xffffffff, 0, nullptr, nullptr } };

/* ------------------------------------------------------------------ */
/* machine                                                              */
/* ------------------------------------------------------------------ */

static void cpu_reset(int cpu)
{
    if (cpu == SW_MAIN) {
        cpu0->reset();
        cpu0->irq_line(false);
    } else {
        cpu1->reset();
    }
}
static void irq_ack(void) { cpu0->irq_line(false); }
static unsigned last_pc(int cpu) { return cpu ? cpu1->GetPPC() : cpu0->GetPPC(); }

void sw_init(const sw_roms *r)
{
    static uint8_t dummy[0x10000];

    sw_hw_init(r);
    cpu0 = new cpu_m6809(dummy, main_r, main_w, 0);
    cpu1 = new cpu_m6809(dummy, snd_r, snd_w, 1);
    cpu0->mame_memory_handling(true);
    cpu1->mame_memory_handling(true);
    SW.cpu_reset_hook = cpu_reset;
    SW.irq_ack_hook = irq_ack;
    SW.pc_hook = last_pc;
}

static void sound_catch_up(void)
{
    while (SW.snd_cyc < SW.cyc) {
        sw_snd_chips_advance();
        cpu1->irq_line(riot_irq(&SW.riot) != 0);
        if (SW.snd_step_hook)
            SW.snd_step_hook(riot_irq(&SW.riot) != 0 && !(cpu1->GetCC() & cpu_m6809::CC_I));
        unsigned pc = cpu1->GetPC();
        SW.pc_hit[SW_SOUND][pc >> 3] |= (uint8_t)(1u << (pc & 7));
        SW.snd_cyc += (uint64_t)cpu1->step();
        SW.n_steps[SW_SOUND]++;
    }
}

/* Everything that is due before the main CPU's next step: the watchdog, the
 * periodic interrupt, the vector generator.  Returns 1 if that step will be
 * the 6809 taking the interrupt and not the instruction at PC. */
int sw_begin_step(void)
{
    if (SW.cyc - SW.last_kick > SW.wd_cycles) {
        SW.n_wd_bites++;
        SW.wd_bite_pc = (uint16_t)cpu0->GetPC();
        sw_machine_reset(SW_RST_WATCHDOG);
    }
    while (SW.cyc >= SW.next_irq) {
        if (SW.irq_pending) {
            if (SW.n_irq_lost < 8) SW.first_lost_pc[SW.n_irq_lost] = (uint16_t)cpu0->GetPC();
            SW.n_irq_lost++;
        }
        cpu0->irq_line(true);
        SW.irq_pending = 1;
        SW.n_irq++;
        SW.next_irq += SW_IRQ_CYCLES;
    }
    avg_run(&SW.vg, sw_ticks());
    return SW.irq_pending && !(cpu0->GetCC() & cpu_m6809::CC_I);
}

int sw_exec_step(void)
{
    int c, irq = SW.irq_pending && !(cpu0->GetCC() & cpu_m6809::CC_I);
    unsigned pc = cpu0->GetPC();

    if (irq) {
        SW.irq_pending = 0;               /* the core lowers the request as it takes it */
        SW.n_irq_taken++;
    } else {
        SW.pc_hit[SW_MAIN][pc >> 3] |= (uint8_t)(1u << (pc & 7));
    }
    c = cpu0->step();
    SW.cyc += (uint64_t)c;
    SW.n_steps[SW_MAIN]++;
    sound_catch_up();
    return c;
}

int sw_step(void)
{
    sw_begin_step();
    return sw_exec_step();
}

unsigned sw_pc(int cpu) { return cpu ? cpu1->GetPC() : cpu0->GetPC(); }

void sw_regs(int cpu, uint16_t out[8])
{
    cpu_m6809 *c = cpu ? cpu1 : cpu0;
    out[0] = c->GetPC(); out[1] = c->GetS(); out[2] = c->GetU(); out[3] = c->GetX();
    out[4] = c->GetY();  out[5] = c->GetD(); out[6] = c->GetDP(); out[7] = c->GetCC();
}

