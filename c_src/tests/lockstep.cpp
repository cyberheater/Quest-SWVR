/* lockstep.cpp - call-by-call verification of the C port against the real ROM
 * running in refrun.cpp (build: /DLOCKSTEP, tests\lockstep.exe).  The design is
 * Tempest's lockstep.c.
 *
 * How a routine check works
 *  - ENTRY.  When the ROM CPU arrives at the address of a routine that has a C
 *    function (gen/registry.c), RAM, vector RAM and the registers are
 *    snapshotted.  Checks nest.  A routine arriving at its own entry again at
 *    the same stack level (a loop back to the top) does not open a second
 *    check, and nothing is opened at the top stack level, where there is no
 *    return to wait for.
 *  - DURING.  Every hardware access of the main CPU is logged in order, with
 *    the visits to checkpoint addresses (sw.h CK) and the entry and exit of
 *    every interrupt.
 *  - COMPLETION.  At the instruction boundary where the ROM has returned (S
 *    above the entry S), the snapshot is loaded into the C port's `g`, the C
 *    function runs, and its hw_* calls REPLAY the log: reads get the ROM's
 *    values; writes must match address and value, in order; all events must be
 *    consumed.
 *  - COMPARE.  C RAM == ROM RAM (except the stack bytes below the entry S),
 *    vector RAM equal, I/O sequence equal, A B X Y U S equal, and the condition
 *    codes the routine's callers use (registry flags_out).
 *
 * Interrupts
 *  - The IRQ is a check of its own: opened when the 6809 takes it, completed
 *    after its RTI, with C sw_take_irq() run from the snapshot.
 *  - An IRQ inside an open check is ANCHORED: the C run calls sw_take_irq() as
 *    soon as it has consumed every event logged before the IRQ's own events
 *    (inside the hw_* call or checkpoint that consumes the last one, or at the
 *    start of the run).  That is exact when the ROM instructions between that
 *    event and the interrupted instruction commute with the handler, which the
 *    ROM side proves from memory access sets: they read or wrote no cell the
 *    handler wrote, and wrote none it read (the stack is exempt; they did no
 *    hardware access by construction).  An IRQ that fails the proof TAINTS every
 *    open check: those are counted and not compared.  The report lists where,
 *    which shows where a checkpoint is needed.
 *
 * Thunks
 *  - A routine with no C translation (registry thunk = 1, or an address that is
 *    not a routine) runs as the ROM routine itself on a second 6809 over `g`,
 *    its hardware accesses replayed from the same log.
 */
#include <cstdio>
#include <cstdlib>
#include <cstring>
#include <cstdint>
#include <csetjmp>
#include <vector>
#include <string>
#include <map>
#include <algorithm>
#include "../cpu/cpu_m6809.h"       /* before sw.h: its register macros are single letters */
#include "../board.h"
#include "../sw.h"
#pragma warning(disable : 4611)     /* setjmp in C++: no object with a destructor is live across it */

/* This file is compiled twice: as it stands it verifies the main program on
 * the oracle's main 6809; with SW_SND_PROGRAM (which also switches sw.h to the sound
 * program's state and names) it verifies the sound program on the second 6809.
 * What differs is collected here. */
struct Region { unsigned lo, hi; };
#ifdef SW_SND_PROGRAM
#define LK_CPU      SW_SOUND
#define LK_NOW      (SW.snd_cyc)
#define LK_MEM      (SW.snd)
#define LK_BANK     0
#define STACK_TOP   0x107Fu             /* INIT: LDS #$107F, in the 6532's RAM, above the direct page variables */
#define STACK_LOW   0x1040u             /* S below this is not a stack pointer */
#define RESET_LO    0x1070u             /* stack bytes not compared over a RESET region */
#define PC_RESET    0x7D44u
#define PC_IRQ      0x7DF3u
#define PC_PASS     0x7D47u             /* MAIN */
#define PASS_SKIP   2                   /* the C entry for a pass is MAIN itself: its own sw_pass() comes first */
static const Region REGION[] = { { 0x1000, 0x1080 }, { 0x2000, 0x2800 } };
#define LK_WHAT     "LOCKSTEP, sound program"
#define lk_init     lk_snd_init
#define lk_boundary lk_snd_boundary
#define lk_io       lk_snd_io
#define lk_mem      lk_snd_mem
#define lk_poke     lk_snd_poke
#define lk_report   lk_snd_report
#define lk_reached  lk_snd_reached
#else
#define LK_CPU      SW_MAIN
#define LK_NOW      (SW.cyc)
#define LK_MEM      (SW.mem)
#define LK_BANK     (SW.bank)
#define STACK_TOP   0x4FFFu
#define STACK_LOW   0x4E00u
#define RESET_LO    0x4F00u             /* RESET moves S about before it sets it */
#define PC_RESET    0xF261u
#define PC_IRQ      0xEF56u
#define PC_PASS     0x602Fu
#define PASS_SKIP   1
static const Region REGION[] = { { 0x0000, 0x3000 }, { 0x4800, 0x6000 } };    /* vector RAM; RAM */
#define LK_WHAT     "LOCKSTEP"
#endif
#define SNAP_SIZE 0x4800
#define BANKED(pc) (((pc) >= 0x6000 && (pc) < 0x8000 && LK_BANK) ? 0x10000u : 0u)

enum { EV_RD, EV_WR, EV_CK, EV_IRQ_BEGIN, EV_IRQ_END, EV_CLI, EV_SEI };
struct Ev { uint8_t type, val; uint16_t addr; uint32_t t; uint16_t pc; };   /* t, pc: the ROM's cycle clock and PC */
static std::vector<Ev> elog;
static uint16_t cur_pc;
static void log_push(Ev e) { e.t = (uint32_t)LK_NOW; e.pc = cur_pc; elog.push_back(e); }

enum { K_ROUTINE, K_IRQ, K_PASS, K_RESET };
struct Check {
    const sw_routine *r;
    int      is_irq;
    int      kind;
    uint16_t entry_s, min_s, irq_pc;
    size_t   ev0;
    uint16_t regs[8];                 /* PC S U X Y D DP CC at entry */
    uint8_t  bank;
    int      tainted, inner_failed;
    int      cut;                     /* a pass or RESET region a RESET ended (watchdog) */
    uint64_t cyc0;                    /* the ROM's cycle clock at entry */
    mathbox  mb;                      /* the matrix processor's registers at entry */
    uint8_t  snap[SNAP_SIZE];
};
/* The matrix processor writes its results into math RAM, so it is hardware the
 * C port needs behind the seam: a second instance working on g.mem, started
 * from the oracle's registers at the check's entry. */
static mathbox gmb;
static std::vector<Check *> open_checks, pool;

struct Stat {
    unsigned long calls, ok, failed, inherited, tainted;
    std::string first;
};
static std::map<const sw_routine *, Stat> stats;
static Stat irq_stat, pass_stat, reset_stat;
static sw_routine irq_routine = { PC_IRQ, 0, 0, 0, nullptr, "IRQ (interrupt)" };
static sw_routine pass_routine = { PC_PASS, 0, 0, 0, nullptr, "mainline pass" };
static sw_routine reset_routine = { PC_RESET, 0, 0, 0, nullptr, "RESET to the first pass" };
static unsigned long n_abandoned;
static uint8_t ck_map[0x20000 / 8];      /* bank << 16 | address of every CK() (the registry's sw_checkpoints) */
static uint8_t insn_hit[0x20000 / 8];    /* bank << 16 | PC of every instruction the ROM executed */
static uint8_t entered[4096];           /* by registry index: the ROM arrived there (1 mainline, 2 in the interrupt) */
static int pass_run;                     /* the C run in progress ends at sw_pass() */
static int pass_seen;

static unsigned long n_checks, n_ok, n_fail, n_inherited, n_tainted, n_irq_seen, n_irq_unplaceable;
static std::map<uint32_t, unsigned long> unplaceable;      /* (pc << 16 | cell) -> count */

/* ---- commutation proof: memory access sets --------------------------- */
static uint32_t rstamp[0x10000], wstamp[0x10000], gen = 1;
static int in_irq;
struct Acc { uint16_t addr; uint8_t write; };
static std::vector<Acc> irq_acc;
static uint16_t stack_floor = STACK_TOP;               /* lowest S ever seen */

static void window_reset(void) { gen++; }
static uint16_t acc_pc[0x10000];               /* the instruction that last touched a cell */
struct Where { uint16_t before, after, cell_after; };  /* for the report: the conflicting accesses */
static std::map<uint32_t, Where> unplaceable_at;

/* An interrupt that cannot be anchored after the event before it may still be
 * anchored BEFORE the event after it: the same proof, on the instructions from
 * its return to that event.  (The wait loops need this: "LDA VGSYNC / BMI" has
 * read the cell the handler is about to write, and then does nothing but branch
 * back to the checkpoint.)  It waits here until that event arrives.
 *
 * Another interrupt may come first.  Then both wait, in order: the first has to
 * commute with the instructions before the second and with those after it, and
 * the second - which the C will take straight after the first, wherever that
 * is - with those after it. */
struct Late { size_t ev; std::vector<Acc> acc; uint32_t key; uint16_t before; };
static std::vector<Late> late;
static size_t irq_begin_ev;
static unsigned long n_irq_late;
#define late_pending (!late.empty())

static int acc_conflict(const std::vector<Acc> &v, uint16_t *cell)
{
    for (const Acc &a : v) {
        if (a.addr >= stack_floor && a.addr <= STACK_TOP) continue;
        if (a.write ? (rstamp[a.addr] == gen || wstamp[a.addr] == gen) : (wstamp[a.addr] == gen)) {
            *cell = a.addr;
            return 1;
        }
    }
    return 0;
}

extern "C" void lk_mem(unsigned addr, int write)
{
    if (in_irq) {
        irq_acc.push_back({ (uint16_t)addr, (uint8_t)write });
    } else if (write) {
        wstamp[addr] = gen;
        acc_pc[addr] = cur_pc;
    } else {
        rstamp[addr] = gen;
        acc_pc[addr] = cur_pc;
    }
}

/* ---- replay ------------------------------------------------------------- */
static size_t rp, rp_end;
static jmp_buf run_jmp;
static uint16_t c_min_s;                 /* lowest stack byte an anchored interrupt used in the C run */
static int run_err;
static char run_msg[200];
static int in_c_run;

static void run_fail(const char *fmt, unsigned a = 0, unsigned b = 0, unsigned c = 0)
{
    if (!run_err) snprintf(run_msg, sizeof run_msg, fmt, a, b, c);
    run_err = 1;
    longjmp(run_jmp, 1);
}

/* A region that a RESET ended (the watchdog biting on the self test's HANG
 * loop): the C run ends where the log does.  At a checkpoint the two are at the
 * same place and can be compared; anywhere else they are not. */
static int cut_run;
static unsigned long n_cut_uncompared;
static void log_end(int at_ck)
{
    if (cut_run && rp >= rp_end) longjmp(run_jmp, at_ck ? 3 : 4);
}

/* The time of an event: the C clock at a hardware access (or checkpoint, SEI,
 * CLI) against the ROM's.  Comparable while no interrupt has been placed in
 * this run - an anchored interrupt sits at another instruction than the ROM's,
 * which moves the events around it by the instructions between; the routine's
 * total (run_compare) is equal either way.  A difference here is an access the
 * translator did not bring the clock up to date for (xlate.py FLUSH). */
static uint32_t run_t0;
static int run_irqs;
static unsigned long n_evtime, n_evtime_bad;
static std::map<uint16_t, unsigned long> evtime_bad;       /* ROM PC -> count */
static void ev_time(const Ev &e)
{
    if (run_irqs) return;
    n_evtime++;
    if ((uint32_t)g.cyc != (uint32_t)(e.t - run_t0)) {
        n_evtime_bad++;
        evtime_bad[e.pc]++;
    }
}

/* late = 0: after an event was consumed; 1: before the next one is (or at the
 * end of the run), where the interrupts anchored late are due as well. */
static void anchor_irqs(int also_late = 0)
{
    while (rp < rp_end && elog[rp].type == EV_IRQ_BEGIN && (also_late || !elog[rp].val)) {
        uint16_t pc = elog[rp].addr, s0 = g.s;
        rp++;
        run_irqs = 1;
        sw_take_irq(pc);
        if (rp >= rp_end || elog[rp].type != EV_IRQ_END)
            run_fail("C interrupt handler left events unconsumed (next type %u at $%04X)",
                     rp < rp_end ? elog[rp].type : 99, rp < rp_end ? elog[rp].addr : 0);
        /* The anchor can be at another stack depth than the ROM's interrupt was,
         * so the frame and the handler's own stack land on other (dead) stack
         * bytes: the END event carries how deep the handler went. */
        if ((uint16_t)(s0 - elog[rp].addr) < c_min_s) c_min_s = (uint16_t)(s0 - elog[rp].addr);
        rp++;
    }
}

static uint8_t replay_rd(uint16_t a)
{
    anchor_irqs(1);
    log_end(0);
    if (rp >= rp_end) run_fail("C read $%04X after the ROM's last hardware access", a);
    const Ev &e = elog[rp];
    if (e.type != EV_RD || e.addr != a)
        run_fail("C read $%04X where the ROM did type %u at $%04X", a, e.type, e.addr);
    ev_time(e);
    rp++;
    return e.val;
}

static void replay_wr(uint16_t a, uint8_t v)
{
    anchor_irqs(1);
    log_end(0);
    if (rp >= rp_end) run_fail("C wrote $%04X after the ROM's last hardware access", a);
    const Ev &e = elog[rp];
    if (e.type != EV_WR || e.addr != a)
        run_fail("C wrote $%04X where the ROM did type %u at $%04X", a, e.type, e.addr);
    ev_time(e);
    if (e.val != v && !run_err) {
        snprintf(run_msg, sizeof run_msg, "C wrote $%02X to $%04X, the ROM wrote $%02X", v, a, e.val);
        run_err = 2;                             /* keep going: the sequence still lines up */
    }
    rp++;
#ifndef SW_SND_PROGRAM
    if (a >= 0x4680 && a < 0x46a0 && (a & 7) == 4) g.bank = v >> 7;
    if (a >= 0x4700 && a < 0x4708) mb_write(&gmb, (int)(a & 7), v, 0);
#endif
}

extern "C" uint8_t hw_rd8(uint16_t a)
{
    uint8_t v = replay_rd(a);
    anchor_irqs();
    return v;
}
extern "C" void hw_wr8(uint16_t a, uint8_t v)
{
    replay_wr(a, v);
    anchor_irqs();
}
extern "C" uint16_t hw_rd16(uint16_t a)
{
    uint16_t h = replay_rd(a);
    uint16_t v = (uint16_t)((h << 8) | replay_rd((uint16_t)(a + 1)));
    anchor_irqs();
    return v;
}
extern "C" void hw_wr16(uint16_t a, uint16_t v)
{
    replay_wr(a, (uint8_t)(v >> 8));
    replay_wr((uint16_t)(a + 1), (uint8_t)v);
    anchor_irqs();
}
extern "C" void sw_ck(uint16_t pc)
{
    anchor_irqs(1);
    log_end(1);
    if (rp >= rp_end || elog[rp].type != EV_CK || elog[rp].addr != pc)
        run_fail("C checkpoint $%04X where the ROM did type %u at $%04X", pc,
                 rp < rp_end ? elog[rp].type : 99, rp < rp_end ? elog[rp].addr : 0);
    ev_time(elog[rp]);
    rp++;
    anchor_irqs();
}
extern "C" void sw_swi(uint16_t pc) { run_fail("C reached the SWI at $%04X", pc); }
extern "C" void sw_pass(uint16_t pc)
{
    if (!pass_run) {
#if PASS_SKIP > 1
        return;                              /* the mainline loop's own marker, inside a call check of it */
#else
        run_fail("C reached the frame start $%04X inside a routine check", pc);
#endif
    }
    if (++pass_seen < PASS_SKIP) return;
    if (cut_run) run_fail("C reached the frame start $%04X; the ROM was reset before it did", pc);
    anchor_irqs(1);
    longjmp(run_jmp, 2);
}
/* SEI and CLI are events: the program masks interrupts exactly where it copies
 * the cells the handler updates, so an interrupt just before the SEI, or held
 * off until the CLI, has its natural anchor there. */
extern "C" void sw_sei(void)
{
    anchor_irqs(1);
    log_end(0);
    if (rp >= rp_end || elog[rp].type != EV_SEI)
        run_fail("C masked interrupts where the ROM did type %u at $%04X",
                 rp < rp_end ? elog[rp].type : 99, rp < rp_end ? elog[rp].addr : 0);
    rp++;
    g.fi = 1;
}
extern "C" void sw_cli(void)
{
    anchor_irqs(1);
    log_end(0);
    g.fi = 0;
    if (rp >= rp_end || elog[rp].type != EV_CLI)
        run_fail("C enabled interrupts where the ROM did type %u at $%04X",
                 rp < rp_end ? elog[rp].type : 99, rp < rp_end ? elog[rp].addr : 0);
    rp++;
    anchor_irqs();
}

/* ---- thunks ------------------------------------------------------------- */
/* Every routine has a C function now; an address with none is a failure. */
extern "C" void sw_thunk(uint16_t addr, int bank)
{
    (void)bank;
    run_fail("C called $%04X, which is not a routine", addr);
}

/* ---- checks -------------------------------------------------------------- */
static Check *new_check(void)
{
    Check *c;
    if (!pool.empty()) { c = pool.back(); pool.pop_back(); }
    else c = new Check;
    return c;
}

static void snapshot(Check *c)
{
    unsigned o = 0;
    for (const Region &r : REGION) { memcpy(c->snap + o, LK_MEM + r.lo, r.hi - r.lo); o += r.hi - r.lo; }
    sw_regs(LK_CPU, c->regs);
    c->bank = (uint8_t)LK_BANK;
#ifndef SW_SND_PROGRAM
    c->mb = SW.mb;
#endif
}

static void load(const Check *c)
{
    unsigned o = 0;
    for (const Region &r : REGION) { memcpy(g.mem + r.lo, c->snap + o, r.hi - r.lo); o += r.hi - r.lo; }
    g.bank = c->bank;
    g.unwind = 0;
    g.cyc = 0;
    g.poll_at = 0;                               /* every CK() calls sw_ck() */
#ifndef SW_SND_PROGRAM
    gmb = c->mb;
    gmb.ram = g.mem + 0x5000;
#endif
    g.s = c->regs[1]; g.u = c->regs[2]; g.x = c->regs[3]; g.y = c->regs[4];
    g.acc.d = c->regs[5]; g.dp = (uint8_t)c->regs[6];
    cc_unpack((uint8_t)c->regs[7]);
}

static void run_compare(Check *c)
{
    Stat &st = c->kind == K_IRQ ? irq_stat : c->kind == K_PASS ? pass_stat :
               c->kind == K_RESET ? reset_stat : stats[c->r];
    char msg[260] = "";
    int bad = 0;
    int whole = c->kind == K_PASS || c->kind == K_RESET;

    if (!whole) n_checks++;
    st.calls++;
    if (c->tainted) { st.tainted++; if (!whole) n_tainted++; return; }

    load(c);
    rp = c->ev0;
    rp_end = elog.size();
    run_err = 0;
    run_msg[0] = 0;
    c_min_s = c->min_s;
    run_t0 = (uint32_t)c->cyc0;
    run_irqs = 0;
    in_c_run = 1;
    pass_run = whole;
    pass_seen = (c->kind == K_RESET) ? PASS_SKIP - 1 : 0;
    cut_run = c->cut;
    {
        int j = setjmp(run_jmp);
        if (j == 4) {                                    /* cut somewhere the two cannot be compared */
            in_c_run = pass_run = cut_run = 0;
            st.calls--;
            n_cut_uncompared++;
            return;
        }
        if (j == 0) {
            if (c->kind == K_IRQ) {
                sw_take_irq(c->irq_pc);
            } else if (c->kind == K_PASS) {
                anchor_irqs();
#ifdef SW_SND_PROGRAM
                sw_find(PC_PASS, 0)->fn();
#else
                sw_resume_frame();
#endif
            } else if (c->kind == K_RESET) {
                sw_find(PC_RESET, 0)->fn();
            } else {
                anchor_irqs();
                c->r->fn();
                anchor_irqs(1);
            }
            if (whole && !run_err) {
                snprintf(run_msg, sizeof run_msg, "C returned without reaching the next frame start");
                run_err = 1;
            }
        }
        if (rp != rp_end && !run_err) {
            snprintf(run_msg, sizeof run_msg, "C made %u fewer hardware accesses than the ROM (next: type %u at $%04X)",
                     (unsigned)(rp_end - rp), elog[rp].type, elog[rp].addr);
            run_err = 1;
        }
    }
    in_c_run = 0;
    pass_run = 0;
    cut_run = 0;
    if (run_err) { bad = 1; snprintf(msg, sizeof msg, "%s", run_msg); }

    if (!bad) {
        uint16_t now[8];
        const uint8_t *R = LK_MEM;
        unsigned lo = c_min_s < c->min_s ? c_min_s : c->min_s;   /* stack bytes the call itself used: */
        unsigned hi;                                              /* everything below the S it returned with */
        sw_regs(LK_CPU, now);
        hi = now[1] > c->entry_s ? now[1] : c->entry_s;
        if (whole) hi = STACK_TOP + 1;                   /* a whole pass: the stack area up to its top */
        if (c->kind == K_RESET) lo = RESET_LO;
        for (const Region &rg : REGION)
            for (unsigned a = rg.lo; a < rg.hi && !bad; a++) {
                if (a >= lo && a < hi) continue;
                if (g.mem[a] != R[a]) {
                    bad = 1;
                    snprintf(msg, sizeof msg, "$%04X: C $%02X, ROM $%02X", a, g.mem[a], R[a]);
                }
            }
        if (!bad && !c->cut) {
            const char *nm[6] = { "S", "U", "X", "Y", "D", "DP" };
            uint16_t cv[6] = { g.s, g.u, g.x, g.y, g.acc.d, g.dp };
            for (int i = 0; i < 6 && !bad; i++)
                if (cv[i] != now[i + 1]) {
                    bad = 1;
                    snprintf(msg, sizeof msg, "%s: C $%04X, ROM $%04X", nm[i], cv[i], now[i + 1]);
                }
        }
        if (!bad && !c->cut && g.cyc != LK_NOW - c->cyc0) {
            bad = 1;
            snprintf(msg, sizeof msg, "cycles: C %llu, ROM %llu", (unsigned long long)g.cyc,
                     (unsigned long long)(LK_NOW - c->cyc0));
        }
        if (!bad && c->kind == K_ROUTINE) {
            uint8_t cc = (uint8_t)now[7], m = c->r->flags_out;
            uint8_t mine = (uint8_t)((g.fn << 3) | (g.fz << 2) | (g.fv << 1) | g.fc);
            if ((cc ^ mine) & m & 0x0f) {
                bad = 1;
                snprintf(msg, sizeof msg, "condition codes NZVC: C %X, ROM %X (callers use mask %X)",
                         mine & m, cc & m & 0x0f, m);
            }
        }
    }
    if (bad && !c->inner_failed && getenv("LK_DUMP") && st.failed < 2) {
        /* the log of the failing check, for the person looking into it */
        static const char *const tn[] = { "RD", "WR", "CK", "IRQ<", "IRQ>", "CLI", "SEI" };
        printf("--- %s fails: %s; its log (C stopped at event %u):\n", c->r->name, msg, (unsigned)(rp - c->ev0));
        for (size_t i = c->ev0; i < elog.size() && i < c->ev0 + 400; i++)
            printf("  %4u %-4s %04X %02X  pc %04X  +%u%s\n", (unsigned)(i - c->ev0), tn[elog[i].type], elog[i].addr,
                   elog[i].val, elog[i].pc, (unsigned)(elog[i].t - (uint32_t)c->cyc0), i == rp ? "   <== C here" : "");
    }
    if (bad) {
        if (c->inner_failed) { st.inherited++; if (!whole) n_inherited++; }
        else {
            st.failed++; if (!whole) n_fail++;
            if (st.first.empty()) {
                char where[64];
                snprintf(where, sizeof where, " [cycle %llu]", (unsigned long long)LK_NOW);
                st.first = std::string(msg) + where;
            }
        }
        for (Check *o : open_checks) if (o != c) o->inner_failed = 1;
    } else {
        st.ok++; if (!whole) n_ok++;
    }
}

static void open_check(int kind, const sw_routine *r, uint16_t pc, uint16_t s)
{
    Check *c = new_check();
    c->r = r; c->kind = kind; c->is_irq = kind == K_IRQ;
    c->entry_s = (kind == K_PASS || kind == K_RESET) ? 0xFFFF : s;
    c->min_s = s; c->irq_pc = pc;
    c->ev0 = elog.size(); c->tainted = 0; c->inner_failed = 0; c->cut = 0;
    c->cyc0 = LK_NOW;
    snapshot(c);
    open_checks.push_back(c);
}

static void log_clear(void)
{
    elog.clear();
    late.clear();
}

static void taint_open(uint32_t key)
{
    n_irq_unplaceable++;
    unplaceable[key]++;
    for (Check *o : open_checks) o->tainted = 1;
}

/* The waiting interrupts against the instructions since the last interrupt
 * returned.  final: the event after them is about to be logged - they are
 * anchored before it.  Not final: another interrupt is about to be taken, and
 * they go on waiting.  A conflict taints the open checks. */
static void check_late(int final)
{
    uint16_t cell;
    if (in_irq) return;                      /* an event of the handler's own */
    for (const Late &l : late)
        if (acc_conflict(l.acc, &cell)) {
            unplaceable_at[l.key] = { l.before, acc_pc[cell], cell };
            taint_open(l.key);
            late.clear();
            return;
        }
    if (final) {
        for (const Late &l : late) { elog[l.ev].val = 1; n_irq_late++; }
        late.clear();
    }
}
static void resolve_late(void) { check_late(1); }

static void close_top(void)
{
    Check *c = open_checks.back();
    /* a routine returning while an interrupt waits: for this check the
     * interrupt is anchored at the return, on the proof so far */
    if (late_pending && !c->is_irq) {
        check_late(0);
        for (const Late &l : late) elog[l.ev].val = 1;
    }
    run_compare(c);
    open_checks.pop_back();
    if (!open_checks.empty()) {
        Check *p = open_checks.back();
        if (c->min_s < p->min_s) p->min_s = c->min_s;
    } else {
        log_clear();
    }
    pool.push_back(c);
}

static int prev_was_rti, prev_was_ret, prev_was_lds;

extern "C" void lk_io(int cpu, int write, unsigned addr, unsigned data)
{
    if (cpu != LK_CPU) return;
    if (addr == 0x5220) return;                  /* the oracle's note of a byte reaching the speech chip: not a bus access */
    if (!open_checks.empty()) {
        resolve_late();
        log_push({ (uint8_t)(write ? EV_WR : EV_RD), (uint8_t)data, (uint16_t)addr });
    }
    if (!in_irq) window_reset();
}

/* Called at every main-CPU instruction boundary, before the step executes.
 * irq_next: that step is the 6809 taking the interrupt. */
extern "C" void lk_boundary(int irq_next)
{
    uint16_t r[8];
    sw_regs(LK_CPU, r);
    uint16_t pc = r[0], s = r[1];

    cur_pc = pc;
    if (!irq_next) {
        unsigned k = pc | BANKED(pc);
        insn_hit[k >> 3] |= (uint8_t)(1u << (k & 7));
    }
    /* S was loaded outright (the self test: "LDS #STACK" at each state, and
     * "LDS #return" where it keeps a return address in S): the routines open on
     * the old stack never return.  They are compared inside the region. */
    if (prev_was_lds && !in_irq) {
        while (!open_checks.empty() && open_checks.back()->kind == K_ROUTINE) {
            pool.push_back(open_checks.back());
            open_checks.pop_back();
            n_abandoned++;
        }
    }
    prev_was_lds = 0;
    if (s < stack_floor && s > STACK_LOW) stack_floor = s;
    if (!open_checks.empty() && s < open_checks.back()->min_s) open_checks.back()->min_s = s;

    /* completions */
    while (!open_checks.empty()) {
        Check *c = open_checks.back();
        if (c->is_irq) {
            if (!(prev_was_rti && s == c->entry_s)) break;
            /* the handler has returned: prove the anchor, then check the handler */
            uint16_t cell = 0;
            int conflict = acc_conflict(irq_acc, &cell);
            in_irq = 0;
            uint16_t depth = (uint16_t)(c->entry_s - c->min_s);
            close_top();
            int waits = 0;
            if (!open_checks.empty()) {
                log_push({ EV_IRQ_END, 0, depth });
                if (conflict || late_pending) {          /* not after the event before it: before the next? */
                    late.push_back({ irq_begin_ev, irq_acc, ((uint32_t)c->irq_pc << 16) | cell,
                                     conflict ? acc_pc[cell] : (uint16_t)0 });
                    waits = 1;
                }
            }
            irq_acc.clear();
            /* A waiting interrupt's proof is on the instructions from here on.
             * One anchored after the last event leaves the window as it is: an
             * interrupt straight after it is anchored to that same event, and
             * has to commute with everything since. */
            if (waits || open_checks.empty()) window_reset();
        } else {
            /* returned: an RTS (or PULS ..,PC) has taken S above the entry S.
             * A routine may raise S itself first (LEAS 2,S to drop its own
             * return address), so S alone does not say it has returned. */
            if (!(prev_was_ret && s > c->entry_s)) break;
            close_top();
        }
    }
    prev_was_rti = 0;
    prev_was_ret = 0;

    if (irq_next) {
        n_irq_seen++;
        if (!open_checks.empty()) {
            check_late(0);
            irq_begin_ev = elog.size();
            log_push({ EV_IRQ_BEGIN, 0, pc });
        }
        open_check(K_IRQ, &irq_routine, pc, s);
        in_irq = 1;
        irq_acc.clear();
        return;
    }

    /* RESET arrives (power-on, watchdog, script): whatever was open never
     * returns.  The region from here to the first frame start is one check. */
    if (pc == PC_RESET) {
        in_irq = 0;
        irq_acc.clear();
        resolve_late();
        while (open_checks.size() > 1 || (!open_checks.empty() && open_checks[0]->kind < K_PASS)) {
            pool.push_back(open_checks.back());
            open_checks.pop_back();
            n_abandoned++;
        }
        if (!open_checks.empty()) {                      /* the pass or RESET region it cut short */
            open_checks[0]->cut = 1;
            run_compare(open_checks[0]);
            pool.push_back(open_checks[0]);
            open_checks.clear();
        }
        log_clear();
        window_reset();
        open_check(K_RESET, &reset_routine, pc, s);
    }
    /* a frame starts at the top level: the pass that was open is complete */
    if (pc == PC_PASS && s == STACK_TOP && !LK_BANK && !in_irq) {
        if (open_checks.size() == 1 && open_checks[0]->kind >= K_PASS) {
            close_top();
        } else if (!open_checks.empty()) {
            n_abandoned += (unsigned long)open_checks.size();
            for (Check *o : open_checks) pool.push_back(o);
            open_checks.clear();
            log_clear();
        }
        window_reset();
        open_check(K_PASS, &pass_routine, pc, s);
    }

    /* a routine begins (before its first instruction's own events are logged).
     * Not as routine calls: the interrupt handler (checked as the interrupt)
     * and RESET (it never returns). */
    const sw_routine *rt0 = sw_find(pc, LK_BANK);
    if (rt0 && !in_irq) entered[rt0 - sw_routines] = 1;
    if (rt0 && in_irq) entered[rt0 - sw_routines] |= 2;
    const sw_routine *rt = (pc == PC_IRQ || pc == PC_RESET || pc == PC_PASS) ? nullptr : rt0;
    if (rt && !rt->thunk && s > STACK_LOW && s < STACK_TOP) {   /* called: there is a return address on the stack */
        Check *top = open_checks.empty() ? nullptr : open_checks.back();
        if (!(top && top->r == rt && top->entry_s == s))
            open_check(K_ROUTINE, rt, 0, s);
    }

    /* a checkpoint: the ROM is at an address where the C has a CK() */
    {
        unsigned k = pc | BANKED(pc);
        if (ck_map[k >> 3] & (1u << (k & 7))) {
            if (!open_checks.empty()) { resolve_late(); log_push({ EV_CK, 0, pc }); }
            if (!in_irq) window_reset();
        }
    }

    /* the instruction about to run */
    {
        uint8_t op = BANKED(pc) ? SW.bank1[pc - 0x6000] : LK_MEM[pc & (sizeof LK_MEM - 1)];
        uint16_t p1 = (uint16_t)(pc + 1);
        uint8_t post = BANKED(p1) ? SW.bank1[p1 - 0x6000] : LK_MEM[p1 & (sizeof LK_MEM - 1)];
        if (op == 0x3b) prev_was_rti = 1;
        if (op == 0x39) prev_was_ret = 1;
        if (op == 0x35 && (post & 0x80)) prev_was_ret = 1;
        if (op == 0x10 && (post == 0xce || post == 0xde || post == 0xee || post == 0xfe)) prev_was_lds = 1;
        if (op == 0x1c && !(post & 0x10)) {              /* ANDCC that clears I: CLI */
            if (!open_checks.empty()) { resolve_late(); log_push({ EV_CLI, 0, pc }); }
            if (!in_irq) window_reset();
        }
        if (op == 0x1a && (post & 0x10)) {               /* ORCC that sets I: SEI */
            if (!open_checks.empty()) { resolve_late(); log_push({ EV_SEI, 0, pc }); }
            if (!in_irq) window_reset();
        }
    }
}

extern "C" void lk_init(void)
{
    static uint8_t dummy[0x10000];
    (void)dummy;
    memcpy(g.mem, LK_MEM, sizeof LK_MEM < 0x10000 ? sizeof LK_MEM : 0x10000);
#ifndef SW_SND_PROGRAM
    memcpy(g.bank1, SW.bank1, 0x2000);
#endif
    irq_routine.fn = nullptr;
    for (unsigned i = 0; i < sw_ncheckpoints; i++)
        ck_map[sw_checkpoints[i] >> 3] |= (uint8_t)(1u << (sw_checkpoints[i] & 7));
}

/* A script poke, at the start of a pass (refrun.cpp): the pass that has just
 * been opened starts from the poked RAM. */
extern "C" void lk_poke(unsigned addr, unsigned val)
{
    unsigned o = 0;
    for (const Region &r : REGION) {
        if (addr >= r.lo && addr < r.hi)
            for (Check *c : open_checks) c->snap[o + (addr - r.lo)] = (uint8_t)val;
        o += r.hi - r.lo;
    }
}

/* One line per routine the ROM entered: bank, address, name, and how it was
 * compared: "call" = by its own call checks, all equal; "region" = only as part
 * of a whole pass, a RESET region or the interrupt (it does not return by RTS,
 * or runs at the top stack level); "FAIL". */
extern "C" void lk_reached(const char *path)
{
    FILE *f = fopen(path, "w");
    if (!f) { fprintf(stderr, "LOCKSTEP: cannot write %s\n", path); return; }
    for (unsigned i = 0; i < sw_nroutines; i++) {
        if (!entered[i]) continue;
        auto it = stats.find(&sw_routines[i]);
        const char *how = "region";
        if (it != stats.end()) {
            if (it->second.failed) how = "FAIL";
            else if (it->second.ok) how = "call";
        }
        fprintf(f, "%u %04X %s %s\n", sw_routines[i].bank, sw_routines[i].addr, sw_routines[i].name, how);
    }
    /* and every instruction the ROM executed: "I bank address" */
    for (unsigned k = 0; k < 0x20000; k++)
        if (insn_hit[k >> 3] & (1u << (k & 7))) fprintf(f, "I %u %04X\n", k >> 16, k & 0xffff);
    fclose(f);
}

extern "C" int lk_report(int verbose)
{
    std::vector<std::pair<const sw_routine *, Stat *>> v;
    unsigned routines_ok = 0, routines_bad = 0, routines_tainted_only = 0;
    for (auto &kv : stats) v.push_back({ kv.first, &kv.second });
    std::sort(v.begin(), v.end(), [](auto &a, auto &b) {
        return a.first->bank != b.first->bank ? a.first->bank < b.first->bank : a.first->addr < b.first->addr; });
    for (auto &p : v) {
        if (p.second->failed) routines_bad++;
        else if (p.second->ok && !p.second->inherited) routines_ok++;
        else routines_tainted_only++;
    }
    unsigned translated = 0;
    for (unsigned i = 0; i < sw_nroutines; i++) if (!sw_routines[i].thunk) translated++;
    printf(LK_WHAT "\n");
    printf("  routine calls   : %lu checked: %lu equal, %lu failed, %lu failed only through a callee, %lu tainted\n",
           n_checks, n_ok, n_fail, n_inherited, n_tainted);
    unsigned n_entered = 0;
    for (unsigned i = 0; i < sw_nroutines; i++) if (entered[i]) n_entered++;
    printf("  routines        : the ROM entered %u of %u; %u have call checks of their own: %u all equal, %u with a "
           "failure of their own, %u not yet shown equal (tainted, or failing through a callee); the other %u are "
           "compared only inside a whole pass, a RESET region or the interrupt\n",
           n_entered, translated, (unsigned)v.size(), routines_ok, routines_bad, routines_tainted_only,
           n_entered - (unsigned)v.size());
    printf("  interrupt       : %lu taken; handler checked %lu times: %lu equal, %lu failed%s%s\n",
           n_irq_seen, irq_stat.calls, irq_stat.ok, irq_stat.failed,
           irq_stat.first.empty() ? "" : "; first: ", irq_stat.first.c_str());
    printf("  whole passes    : %lu from frame start to frame start: %lu equal, %lu failed, %lu failed only through a "
           "callee, %lu tainted%s%s\n", pass_stat.calls, pass_stat.ok, pass_stat.failed, pass_stat.inherited,
           pass_stat.tainted, pass_stat.first.empty() ? "" : "; first: ", pass_stat.first.c_str());
    printf("  RESET           : %lu regions to the first frame: %lu equal, %lu failed, %lu tainted%s%s; %lu checks "
           "abandoned at a RESET, %lu regions it cut short not compared\n", reset_stat.calls, reset_stat.ok, reset_stat.failed + reset_stat.inherited,
           reset_stat.tainted, reset_stat.first.empty() ? "" : "; first: ", reset_stat.first.c_str(), n_abandoned,
           n_cut_uncompared);
    printf("  anchors         : %lu interrupts anchored before the next event instead of after the last; %lu "
           "could not be anchored\n", n_irq_late, n_irq_unplaceable);
    printf("  event times     : %lu hardware accesses and checkpoints timed against the ROM's cycle clock: %lu differ\n",
           n_evtime, n_evtime_bad);
    if (verbose) {
        int k = 0;
        for (auto &kv : evtime_bad)
            if (k++ < 40) printf("     time differs at the access of the instruction at $%04X (%lu times)\n", kv.first, kv.second);
    }
    if (verbose) {
        std::vector<std::pair<unsigned long, uint32_t>> u;
        for (auto &kv : unplaceable) u.push_back({ kv.second, kv.first });
        std::sort(u.rbegin(), u.rend());
        for (size_t i = 0; i < u.size() && i < 12; i++)
            printf("     %6lu x interrupt at PC $%04X: cell $%04X touched before it at $%04X, cell $%04X after it "
                   "at $%04X\n", u[i].first, u[i].second >> 16, u[i].second & 0xffff,
                   unplaceable_at[u[i].second].before, unplaceable_at[u[i].second].cell_after,
                   unplaceable_at[u[i].second].after);
        int shown = 0;
        for (auto &p : v)
            if (p.second->failed && shown++ < verbose)
                printf("  FAIL %-10s $%04X%s  %lu of %lu calls: %s\n", p.first->name, p.first->addr,
                       p.first->bank ? " (bank 1)" : "", p.second->failed, p.second->calls,
                       p.second->first.c_str());
    }
    return (n_fail || irq_stat.failed || pass_stat.failed || reset_stat.failed || reset_stat.inherited) ? 1 : 0;
}
