/* board.h - the Star Wars machine.
 *
 *   hw.cpp     the hardware without its 6809s: the chips, the ports and
 *              latches, RESET.  Its header states the hardware model - the
 *              contract the C port's hardware seam has to reproduce.
 *   board.cpp  the two 6809 cores on that hardware: the oracle.  A harness
 *              drives it one main-CPU step at a time (sw_step).
 *
 * Both work on the one SW structure.
 */
#ifndef SW_BOARD_H
#define SW_BOARD_H

#include <stdint.h>
#include "avg.h"
#include "mathbox.h"
#include "x2212.h"
#include "riot6532.h"

#define SW_IRQ_CYCLES   6144u            /* 3 kHz / 12 at 1.512 MHz */
#define SW_WD_CYCLES    (32u * 6144u)    /* WTCHDG: "EVERY 8*4 IRQS" */
#define SW_TMS_CYCLES   189u             /* one 8 kHz speech sample */

enum { SW_MAIN = 0, SW_SOUND = 1 };
enum { SW_RST_POWERON, SW_RST_WATCHDOG, SW_RST_SCRIPT, SW_RST_KINDS };

typedef struct {
    const uint8_t *main_rom;      /* 64K main CPU image, bank 0 at $6000 */
    const uint8_t *bank1;         /* 8K */
    const uint8_t *sound_rom;     /* 64K sound CPU image, ROM at $4000 */
    const uint8_t *mathbox_proms; /* 4 x 1024 */
    const uint8_t *avg_prom;      /* 256 */
} sw_roms;

typedef struct {
    /* inputs, as the ports read (active-low switches idle high) */
    uint8_t in0;                  /* $4300 */
    uint8_t in1;                  /* $4320, bits 5-0; bits 7,6 come from the hardware */
    uint8_t dsw0, dsw1;           /* $4340, $4360 */
    uint8_t adc_in[4];            /* pitch, yaw, thrust, channel 3 */
    uint8_t snd_test;             /* sound board self-test switch: 0x10 = off */

    /* memory */
    uint8_t mem[0x10000];         /* main: vector RAM, vector ROM, RAM, ROM with bank 0 */
    uint8_t bank1[0x2000];
    uint8_t snd[0x8000];          /* sound: A15 is not decoded */
    int     bank;                 /* W.BANK D7 */
    uint8_t out_latch[8];         /* $4680-$4687, last value written */
    uint8_t adc_latch;            /* the value the converter sampled at the last start */
    uint8_t pokey[4][16];         /* last value written to each POKEY register */

    /* chips */
    avg      vg;
    mathbox  mb;
    x2212    nv;
    riot6532 riot;
    uint8_t  main_data, sound_data;       /* the two latches between the CPUs */
    uint8_t  riot_pa_prev, tms_status;

    /* time: CPU cycles; one cycle is 8 master-clock ticks */
    uint64_t cyc, snd_cyc;
    uint64_t next_irq, tms_next;
    uint64_t last_kick, wd_cycles;
    int      irq_pending;

    /* statistics and faults */
    uint64_t n_steps[2];
    uint32_t n_irq, n_irq_lost, n_wd_kicks, n_wd_bites, n_snd_resets;
    uint32_t n_reset[SW_RST_KINDS];
    uint64_t max_kick_gap;
    uint32_t n_unmapped_r[2], n_unmapped_w[2], n_cpu_log;
    uint16_t first_unmapped_r[2][8], first_unmapped_w[2][8];
    uint16_t first_unmapped_pc[2][8];
    char     first_log[4][160];
    uint32_t n_main_cmds, n_snd_replies, n_cmd_overrun;
    uint32_t n_pokey_w, n_tms_w, n_tms_r;
    uint8_t  pc_hit[2][0x10000 / 8];

    uint32_t n_irq_taken, n_latch_reads;
    uint16_t wd_bite_pc, first_lost_pc[8];

    /* a harness may watch every access to a hardware register, and the vector
     * generator just before a VGGO (go = 1) or VGSTOP (go = 0) takes effect */
    void (*io_hook)(int cpu, int write, unsigned addr, unsigned data);
    void (*vg_hook)(int go);
    /* ... and every main-CPU access to RAM or vector RAM (the verifier's proof
     * that an interrupt can be anchored) */
    void (*mem_hook)(unsigned addr, int write);
    /* ... the same for the sound CPU's RAM, and the moment before each of its
     * steps (irq_next: that step is the 6809 taking the 6532's interrupt) */
    void (*snd_mem_hook)(unsigned addr, int write);
    void (*snd_step_hook)(int irq_next);
    /* ... for a host that makes the sound: every POKEY register write, and
     * every sample of the speech chip (8 kHz, one per SW_TMS_CYCLES) */
    void (*pokey_hook)(int chip, int reg, uint8_t data);
    void (*tms_hook)(short sample);
    /* What drives the hardware - the 6809 cores (board.cpp) or the C port
     * (port.cpp) - is told of a RESET line going active (the main CPU's at a
     * machine reset; the sound CPU's then too, and at W.RSTS) and of IRCLR, and
     * asked for a PC when an access goes nowhere. */
    void (*cpu_reset_hook)(int cpu);
    void (*irq_ack_hook)(void);
    unsigned (*pc_hook)(int cpu);
} sw_board;

extern sw_board SW;

/* ---- hw.cpp ---- */
void     sw_hw_init(const sw_roms *roms);    /* once: the chips and the memory images, no CPU */
void     sw_power_on(void);                  /* RAM cleared, everything reset, time 0 */
void     sw_machine_reset(int cause);        /* the RESET line: RAM and time are kept */
uint64_t sw_ticks(void);                     /* master-clock ticks */

/* ---- board.cpp ---- */
void     sw_init(const sw_roms *roms);       /* once: sw_hw_init() and the two 6809 cores */
int      sw_begin_step(void);                /* what is due before the next step; 1 = it is an IRQ entry */
int      sw_exec_step(void);                 /* one main-CPU step; the sound CPU catches up */
int      sw_step(void);                      /* both */
unsigned sw_pc(int cpu);
void     sw_regs(int cpu, uint16_t out[8]);  /* PC, S, U, X, Y, D, DP, CC */

/* ---- hw.cpp: the hardware by address, what the 6809 cores' memory handlers
 * and the C port's seam call (the port keeps SW.cyc / SW.snd_cyc at its own
 * cycle clocks).  Addresses are the hardware's:
 * $4300-$47FF on the main side; below $4000, RAM excepted, on the sound side.
 * sw_bind_memory() points the vector generator and the matrix processor at the
 * port's memory in place of SW.mem; call it before sw_power_on(). */
uint8_t  sw_hw_read(unsigned addr);
void     sw_hw_write(unsigned addr, uint8_t data);
uint8_t  sw_snd_hw_read(unsigned addr);
void     sw_snd_hw_write(unsigned addr, uint8_t data);
void     sw_bind_memory(uint8_t *main_mem);
void     sw_snd_chips_advance(void);         /* the speech chip's samples and the 6532's timer, up to SW.snd_cyc */
int      sw_snd_irq(void);                   /* the 6532's /IRQ */

#endif
