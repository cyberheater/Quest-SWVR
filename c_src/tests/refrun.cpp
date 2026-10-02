/* refrun.cpp - Star Wars reference harness: the real ROMs on the board model.
 *
 * The oracle the C port will be diffed against.  The hardware model is in
 * board.cpp's header (the CONTRACT); this file drives it from a script and
 * records what the ROM did.
 *
 *   tests\refrun.exe [--rev 1|2 (2)] [--romdir DIR (..\disasm\build)]
 *                    [--script FILE] [--frames N (600)] [--max-cycles N]
 *                    [--outdir DIR] [--capture-every K (32)] [--no-dumps]
 *                    [--snap-pc HEX (602F)] [--diag-pc HEX (0 = none)]
 *                    [--io-trace FILE] [--avg-dump DIR] [--avg-dump-max N (64)]
 *                    [--nvram-in FILE] [--nvram-out FILE]
 *                    [--watchdog-cycles N] [--allow-watchdog] [--quiet]
 *
 * Pass = one arrival of the main CPU at a loop head with bank 0 selected and
 * no interrupt about to be taken: --snap-pc (default $602F, "JSR IFRAME" in
 * the mainline after the frame wait; kind M) or --diag-pc (the self test's
 * loop head; kind D).  At every pass the script is applied and the schedule
 * line written; passes 1-16 and every K-th are dumped.
 *
 * Output (DIR):
 *   frame_sched.txt   every pass: pass, IRQs raised, CPU cycle, kind, phase
 *   frame_NNNN.ram    $4800-$5FFF (6144 bytes)   .vram  $0000-$2FFF (12288)
 *             .nv     NOVRAM RAM side (256)      .snd   sound RAM: 6532 (128) + $2000-$27FF (2048)
 *   avg_runs.txt      every vector-generator run: start tick, ticks to HALT,
 *                     states, instructions, points, CRC of the points
 *   ref_index.json    the run's parameters and summary
 *   coverage_main.txt, coverage_sound.txt   every PC executed
 *   (--avg-dump DIR)  avg_NNNNNN.bin, for tools\avg_prom_sim.py: "AVG2", ticks to
 *                     HALT, points, states (4 x u32); the generator's 20
 *                     registers at VGGO (i32 each: pc sp dvx dvy dvy12 timer
 *                     stack[4] data state_latch int_latch scale bin_scale
 *                     intensity color op xpos ypos); vector memory
 *                     $0000-$3FFF at VGGO; then each point as x, y (i32),
 *                     colour, z (u8).  The first N runs and every 97th.
 *   (--io-trace FILE) every hardware register access: cycle, CPU, R/W, address, data
 *
 * Script (--script FILE): lines "PASS PORT [VALUE]", '#' comments, PASS in
 * non-decreasing order; the line applies from the start of pass PASS on
 * (PASS 0 = at power-on, before the first instruction).
 *   byte ports   in0 in1 dsw0 dsw1 pitch yaw
 *   switches     VALUE 1 = closed/pressed, 0 = open:
 *                IN0: coinr D0, coinl D1, coinaux D2, slam D3, test D4,
 *                     firer D6, firel D7
 *                IN1: diag D2, thumbr D4, thumbl D5
 *                sound board: sndtest (its self-test switch)
 *   events       "PASS reset" pulses RESET at that pass; "PASS end" stops the run
 *
 * Exit 0 = the run reached its end with every check in the summary passing.
 */
#ifndef _CRT_SECURE_NO_WARNINGS
#define _CRT_SECURE_NO_WARNINGS
#endif
#include <cstdio>
#include <cstdlib>
#include <cstring>
#include <cstdint>
#include <string>
#include <vector>
#include <direct.h>
#include "../board.h"

/* ------------------------------------------------------------------ */
/* small helpers                                                        */
/* ------------------------------------------------------------------ */

static uint32_t crc_table[256];

static void crc_init(void)
{
    for (uint32_t i = 0; i < 256; i++) {
        uint32_t c = i;
        for (int k = 0; k < 8; k++) c = (c & 1) ? 0xedb88320u ^ (c >> 1) : c >> 1;
        crc_table[i] = c;
    }
}

static uint32_t crc_update(uint32_t crc, const void *data, size_t n)
{
    const uint8_t *p = (const uint8_t *)data;
    crc = ~crc;
    while (n--) crc = crc_table[(crc ^ *p++) & 0xff] ^ (crc >> 8);
    return ~crc;
}

static std::vector<uint8_t> load_file(const std::string &path, size_t want)
{
    std::vector<uint8_t> v;
    FILE *f = fopen(path.c_str(), "rb");
    if (!f) { fprintf(stderr, "REFRUN: cannot open %s (run python disasm\\image.py)\n", path.c_str()); exit(2); }
    v.resize(want);
    size_t n = fread(v.data(), 1, want, f);
    fclose(f);
    if (n != want) { fprintf(stderr, "REFRUN: %s is %zu bytes, expected %zu\n", path.c_str(), n, want); exit(2); }
    return v;
}

static void write_file(const std::string &path, const void *data, size_t n)
{
    FILE *f = fopen(path.c_str(), "wb");
    if (!f) { fprintf(stderr, "REFRUN: cannot write %s\n", path.c_str()); exit(2); }
    fwrite(data, 1, n, f);
    fclose(f);
}

#ifdef LOCKSTEP
/* tests\lockstep.exe: the same run, verifying the C port call by call (lockstep.cpp) */
extern "C" {
void lk_init(void);
void lk_boundary(int irq_next);
void lk_io(int cpu, int write, unsigned addr, unsigned data);
void lk_mem(unsigned addr, int write);
void lk_poke(unsigned addr, unsigned val);
int  lk_report(int verbose);
void lk_reached(const char *path);
/* ... and the sound program on the second 6809 (lockstep.cpp compiled with SW_SOUND) */
void lk_snd_init(void);
void lk_snd_boundary(int irq_next);
void lk_snd_io(int cpu, int write, unsigned addr, unsigned data);
void lk_snd_mem(unsigned addr, int write);
int  lk_snd_report(int verbose);
void lk_snd_reached(const char *path);
}
#endif

/* ------------------------------------------------------------------ */
/* script                                                               */
/* ------------------------------------------------------------------ */

enum { SC_BYTE, SC_BIT_LOW, SC_RESET, SC_END, SC_POKE };
struct port_def { const char *name; int kind; uint8_t *port; uint8_t mask; };
struct script_line { unsigned pass; int kind; uint8_t *port; uint8_t mask, val; };
/* "PASS poke ADDR VALUE" writes a byte of program RAM ($4800-$5FFF) at the
 * start of that pass: a test's way to a game state the scripted player does not
 * reach by playing (shields kept up, a later phase).  The oracle and the C port
 * both start the pass from the poked state. */
static std::vector<script_line> script;
static size_t script_pos;

static const port_def *find_port(const char *name)
{
    static const port_def ports[] = {
        { "in0", SC_BYTE, &SW.in0, 0 },       { "in1", SC_BYTE, &SW.in1, 0 },
        { "dsw0", SC_BYTE, &SW.dsw0, 0 },     { "dsw1", SC_BYTE, &SW.dsw1, 0 },
        { "pitch", SC_BYTE, &SW.adc_in[0], 0 }, { "yaw", SC_BYTE, &SW.adc_in[1], 0 },
        { "coinr", SC_BIT_LOW, &SW.in0, 0x01 }, { "coinl", SC_BIT_LOW, &SW.in0, 0x02 },
        { "coinaux", SC_BIT_LOW, &SW.in0, 0x04 }, { "slam", SC_BIT_LOW, &SW.in0, 0x08 },
        { "test", SC_BIT_LOW, &SW.in0, 0x10 },
        { "firer", SC_BIT_LOW, &SW.in0, 0x40 }, { "firel", SC_BIT_LOW, &SW.in0, 0x80 },
        { "diag", SC_BIT_LOW, &SW.in1, 0x04 },
        { "thumbr", SC_BIT_LOW, &SW.in1, 0x10 }, { "thumbl", SC_BIT_LOW, &SW.in1, 0x20 },
        { "sndtest", SC_BIT_LOW, &SW.snd_test, 0x10 },
        { "reset", SC_RESET, nullptr, 0 },    { "end", SC_END, nullptr, 0 },
    };
    for (const port_def &p : ports)
        if (!strcmp(name, p.name)) return &p;
    return nullptr;
}

static int load_script(const char *path)
{
    char line[256], port[32];
    unsigned pass, last = 0;
    int val;
    FILE *f = fopen(path, "r");
    if (!f) { fprintf(stderr, "REFRUN: cannot open script %s\n", path); return 1; }
    while (fgets(line, sizeof line, f)) {
        char *h = strchr(line, '#');
        if (h) *h = 0;
        int nf = sscanf(line, "%u %31s %i", &pass, port, &val);
        if (nf < 2) continue;
        if (!strcmp(port, "poke")) {
            int addr, v;
            if (sscanf(line, "%u %31s %i %i", &pass, port, &addr, &v) != 4 || addr < 0x4800 || addr >= 0x6000 ||
                pass < last || pass == 0) {
                fprintf(stderr, "REFRUN: bad script line: %s", line);
                fclose(f);
                return 1;
            }
            last = pass;
            script.push_back({ pass, SC_POKE, &SW.mem[addr], 0, (uint8_t)v });
            continue;
        }
        const port_def *p = find_port(port);
        int ev = p && (p->kind == SC_RESET || p->kind == SC_END);
        if (!p || (ev ? nf != 2 : nf != 3) || pass < last || (ev && pass == 0) ||
            (p->kind == SC_BIT_LOW && val != 0 && val != 1)) {
            fprintf(stderr, "REFRUN: bad script line: %s", line);
            fclose(f);
            return 1;
        }
        last = pass;
        script.push_back({ pass, p->kind, p->port, p->mask, (uint8_t)(ev ? 0 : val) });
    }
    fclose(f);
    return 0;
}

/* applies the lines up to `pass`; returns SC_RESET / SC_END if one was among them */
static int apply_script(unsigned pass)
{
    int ev = 0;
    while (script_pos < script.size() && script[script_pos].pass <= pass) {
        const script_line &s = script[script_pos++];
        switch (s.kind) {
        case SC_BYTE:    *s.port = s.val; break;
        case SC_POKE:
            *s.port = s.val;
#ifdef LOCKSTEP
            lk_poke((unsigned)(s.port - SW.mem), s.val);     /* the pass that starts here starts poked */
#endif
            break;
        case SC_BIT_LOW: *s.port = (uint8_t)(s.val ? (*s.port & ~s.mask) : (*s.port | s.mask)); break;
        case SC_RESET:   if (ev != SC_END) ev = SC_RESET; break;
        default:         ev = SC_END; break;
        }
    }
    return ev;
}

/* ------------------------------------------------------------------ */
/* recording                                                            */
/* ------------------------------------------------------------------ */

static std::string outdir, avgdir;
static FILE *f_io, *f_avg;
static uint32_t io_crc[2];                 /* running CRC of each CPU's hardware writes */
static uint64_t io_writes[2], io_reads[2];
static unsigned avg_dump_max = 64, avg_dumped;
static uint32_t avg_runs, avg_runs_halted;
static uint64_t avg_ticks_total, avg_ticks_max;
static uint32_t avg_points_max, avg_crc_all;
static std::vector<uint8_t> avg_snap;      /* vector memory at the last VGGO */
static int avg_snap_valid;
static int32_t avg_regs[20];               /* the generator's registers at that VGGO */


static void io_hook(int cpu, int write, unsigned addr, unsigned data)
{
#ifdef LOCKSTEP
    lk_io(cpu, write, addr, data);
    lk_snd_io(cpu, write, addr, data);
#endif
    if (write) {
        uint8_t rec[12];
        uint64_t c = cpu ? SW.snd_cyc : SW.cyc;
        memcpy(rec, &c, 8);
        rec[8] = (uint8_t)(addr >> 8); rec[9] = (uint8_t)addr; rec[10] = (uint8_t)data; rec[11] = (uint8_t)cpu;
        io_crc[cpu] = crc_update(io_crc[cpu], rec, sizeof rec);
        io_writes[cpu]++;
    } else {
        io_reads[cpu]++;
    }
    if (f_io)
        fprintf(f_io, "%llu %c %c %04X %02X\n", (unsigned long long)(cpu ? SW.snd_cyc : SW.cyc),
                cpu ? 'S' : 'M', write ? 'W' : 'R', addr, data);
}

/* called just before a VGGO or VGSTOP acts: the run that is ending is complete */
static void vg_hook(int go)
{
    const avg *a = &SW.vg;

    if (a->n_go) {                                     /* there was a run */
        int halted = a->sync_halt;
        uint64_t ticks = halted ? a->halt_at - a->run_start : sw_ticks() - a->run_start;
        uint32_t crc = crc_update(0, a->vect, a->nvect * sizeof(avg_point));

        avg_runs++;
        if (halted) {
            avg_runs_halted++;
            avg_ticks_total += ticks;
            if (ticks > avg_ticks_max) avg_ticks_max = ticks;
        }
        if (a->nvect > avg_points_max) avg_points_max = a->nvect;
        avg_crc_all = crc_update(avg_crc_all, &crc, 4);
        avg_crc_all = crc_update(avg_crc_all, &ticks, 8);
        if (f_avg)
            fprintf(f_avg, "%u %llu %llu %c %u %u %u %08X\n", avg_runs, (unsigned long long)a->run_start,
                    (unsigned long long)ticks, halted ? 'H' : (go ? 'G' : 'S'),
                    a->n_states, a->n_ops, a->nvect, crc);
        if (!avgdir.empty() && halted && avg_snap_valid &&
            (avg_dumped < avg_dump_max || (avg_runs % 97) == 0)) {
            char name[64];
            uint32_t hdr[4] = { 0x32475641u /* "AVG2" */, (uint32_t)ticks, a->nvect, a->n_states };
            snprintf(name, sizeof name, "\\avg_%06u.bin", avg_runs);
            FILE *f = fopen((avgdir + name).c_str(), "wb");
            if (f) {
                fwrite(hdr, 4, 4, f);
                fwrite(avg_regs, 4, 20, f);
                fwrite(avg_snap.data(), 1, 0x4000, f);
                for (uint32_t i = 0; i < a->nvect; i++) {
                    int32_t xy[2] = { a->vect[i].x, a->vect[i].y };
                    uint8_t cz[2] = { a->vect[i].color, a->vect[i].z };
                    fwrite(xy, 4, 2, f);
                    fwrite(cz, 1, 2, f);
                }
                fclose(f);
                avg_dumped++;
            }
        }
    }
    if (go) {
        /* the generator's registers and vector memory as VGGO finds them */
        int32_t r[20] = { a->pc, a->sp, a->dvx, a->dvy, a->dvy12, a->timer,
                          a->stack[0], a->stack[1], a->stack[2], a->stack[3],
                          a->data, a->state_latch, a->int_latch, a->scale, a->bin_scale,
                          a->intensity, a->color, a->op, a->xpos, a->ypos };
        memcpy(avg_regs, r, sizeof r);
        avg_snap.assign(SW.mem, SW.mem + 0x4000);
        avg_snap_valid = 1;
    } else {
        avg_snap_valid = 0;
    }
}

static void dump_pass(unsigned pass)
{
    char name[64];
    uint8_t snd[0x80 + 0x800];

    snprintf(name, sizeof name, "\\frame_%04u", pass);
    std::string base = outdir + name;
    write_file(base + ".ram", SW.mem + 0x4800, 0x1800);
    write_file(base + ".vram", SW.mem, 0x3000);
    write_file(base + ".nv", SW.nv.sram, 0x100);
    memcpy(snd, SW.snd + 0x1000, 0x80);
    memcpy(snd + 0x80, SW.snd + 0x2000, 0x800);
    write_file(base + ".snd", snd, sizeof snd);
}

static uint32_t state_crc(void)
{
    uint32_t c = 0;
    uint16_t regs[8];
    c = crc_update(c, SW.mem, 0x3000);
    c = crc_update(c, SW.mem + 0x4800, 0x1800);
    c = crc_update(c, SW.nv.sram, 0x100);
    c = crc_update(c, SW.nv.eeprom, 0x100);
    c = crc_update(c, SW.snd + 0x1000, 0x80);
    c = crc_update(c, SW.snd + 0x2000, 0x800);
    for (int i = 0; i < 2; i++) { sw_regs(i, regs); c = crc_update(c, regs, sizeof regs); }
    c = crc_update(c, &SW.cyc, 8);
    c = crc_update(c, &SW.snd_cyc, 8);
    return c;
}

static unsigned coverage(int cpu, const char *file)
{
    unsigned n = 0;
    FILE *f = file ? fopen((outdir + "\\" + file).c_str(), "w") : nullptr;
    for (unsigned a = 0; a < 0x10000; a++)
        if (SW.pc_hit[cpu][a >> 3] & (1u << (a & 7))) {
            n++;
            if (f) fprintf(f, "%04X\n", a);
        }
    if (f) fclose(f);
    return n;
}

/* ------------------------------------------------------------------ */

int main(int argc, char **argv)
{
    std::string romdir = "..\\disasm\\build", io_path, nv_in, nv_out, lk_reached_path;
    const char *script_path = nullptr;
    unsigned frames = 600, capture_every = 32, snap_pc = 0x602f, diag_pc = 0;
    uint64_t max_cycles = 0;
    int rev = 2, no_dumps = 0, allow_wd = 0, quiet = 0, lk_verbose = 40;
    (void)lk_verbose;
    uint64_t wd_cycles = 0;

    for (int i = 1; i < argc; i++) {
        std::string a = argv[i];
        auto next = [&]() -> const char * {
            if (i + 1 >= argc) { fprintf(stderr, "REFRUN: %s needs a value\n", a.c_str()); exit(2); }
            return argv[++i];
        };
        if (a == "--rev") rev = atoi(next());
        else if (a == "--romdir") romdir = next();
        else if (a == "--script") script_path = next();
        else if (a == "--frames") frames = (unsigned)strtoul(next(), nullptr, 0);
        else if (a == "--max-cycles") max_cycles = strtoull(next(), nullptr, 0);
        else if (a == "--outdir") outdir = next();
        else if (a == "--capture-every") capture_every = (unsigned)strtoul(next(), nullptr, 0);
        else if (a == "--no-dumps") no_dumps = 1;
        else if (a == "--snap-pc") snap_pc = (unsigned)strtoul(next(), nullptr, 16);
        else if (a == "--diag-pc") diag_pc = (unsigned)strtoul(next(), nullptr, 16);
        else if (a == "--io-trace") io_path = next();
        else if (a == "--avg-dump") avgdir = next();
        else if (a == "--avg-dump-max") avg_dump_max = (unsigned)strtoul(next(), nullptr, 0);
        else if (a == "--nvram-in") nv_in = next();
        else if (a == "--nvram-out") nv_out = next();
        else if (a == "--watchdog-cycles") wd_cycles = strtoull(next(), nullptr, 0);
        else if (a == "--allow-watchdog") allow_wd = 1;
        else if (a == "--quiet") quiet = 1;
        else if (a == "--lk-verbose") lk_verbose = atoi(next());
        else if (a == "--lk-reached") lk_reached_path = next();
        else { fprintf(stderr, "REFRUN: unknown option %s\n", a.c_str()); return 2; }
    }
    if (rev != 1 && rev != 2) { fprintf(stderr, "REFRUN: --rev 1 or 2\n"); return 2; }
    if (script_path && load_script(script_path)) return 2;
    if (!max_cycles) max_cycles = (uint64_t)frames * 400000u + 20000000u;

    crc_init();
    auto main_rom = load_file(romdir + (rev == 1 ? "\\starwars_main_rev1.bin" : "\\starwars_main_rev2.bin"), 0x10000);
    auto bank1 = load_file(romdir + "\\starwars_bank1.bin", 0x2000);
    auto snd_rom = load_file(romdir + "\\starwars_sound.bin", 0x10000);
    auto mbprom = load_file(romdir + "\\starwars_mathbox.bin", 0x1000);
    auto avgprom = load_file(romdir + "\\starwars_avgprom.bin", 0x100);
    sw_roms roms = { main_rom.data(), bank1.data(), snd_rom.data(), mbprom.data(), avgprom.data() };

    sw_init(&roms);
    if (wd_cycles) SW.wd_cycles = wd_cycles;
    if (!nv_in.empty()) {
        auto nv = load_file(nv_in, 0x100);
        memcpy(SW.nv.eeprom, nv.data(), 0x100);
    }
    SW.io_hook = io_hook;
    SW.vg_hook = vg_hook;

    FILE *f_sched = nullptr;
    if (!outdir.empty()) {
        _mkdir(outdir.c_str());
        f_sched = fopen((outdir + "\\frame_sched.txt").c_str(), "w");
        f_avg = fopen((outdir + "\\avg_runs.txt").c_str(), "w");
        if (!f_sched || !f_avg) { fprintf(stderr, "REFRUN: cannot write to %s\n", outdir.c_str()); return 2; }
        fprintf(f_sched, "# pass irqs cycle kind phase\n");
        fprintf(f_avg, "# run start_tick ticks end(H halt, G restarted, S stopped) states ops points crc\n");
    }
    if (!avgdir.empty()) _mkdir(avgdir.c_str());
    if (!io_path.empty()) {
        f_io = fopen(io_path.c_str(), "w");
        if (!f_io) { fprintf(stderr, "REFRUN: cannot write %s\n", io_path.c_str()); return 2; }
    }

    apply_script(0);
    sw_power_on();
#ifdef LOCKSTEP
    SW.mem_hook = lk_mem;
    lk_init();
    SW.snd_mem_hook = lk_snd_mem;
    SW.snd_step_hook = lk_snd_boundary;
    lk_snd_init();
#endif

    unsigned pass = 0, n_m = 0, n_d = 0, n_swi = 0, captured = 0;
    unsigned first_swi_pc = 0;
    uint64_t last_pass_cyc = 0, max_pass_cyc = 0;
    int ended = 0;
    std::vector<unsigned> captures;
    uint8_t phases[32] = { 0 };

    while (pass < frames && SW.cyc < max_cycles && !ended) {
        int irq = sw_begin_step();
        unsigned pc = sw_pc(SW_MAIN);
#ifdef LOCKSTEP
        lk_boundary(irq);
#endif

        if (!irq) {
            int kind = (pc == snap_pc && !SW.bank) ? 'M' : (diag_pc && pc == diag_pc) ? 'D' : 0;
            if (kind) {
                pass++;
                if (kind == 'M') n_m++; else n_d++;
                int ev = apply_script(pass);
                uint8_t phase = SW.mem[0x4841];
                phases[phase >> 3 & 31] |= (uint8_t)(1u << (phase & 7));
                if (f_sched)
                    fprintf(f_sched, "%u %u %llu %c %02X\n", pass, SW.n_irq, (unsigned long long)SW.cyc, kind, phase);
                if (pass > 1 && SW.cyc - last_pass_cyc > max_pass_cyc) max_pass_cyc = SW.cyc - last_pass_cyc;
                last_pass_cyc = SW.cyc;
                if (!outdir.empty() && !no_dumps && (pass <= 16 || pass % capture_every == 0)) {
                    dump_pass(pass);
                    captures.push_back(pass);
                    captured++;
                }
                if (ev == SC_END) { ended = 1; break; }
                if (ev == SC_RESET) { sw_machine_reset(SW_RST_SCRIPT); continue; }
            }
            /* SWI is the program's own error trap */
            uint8_t op = (pc >= 0x6000 && pc < 0x8000 && SW.bank) ? SW.bank1[pc - 0x6000] : SW.mem[pc];
            if (op == 0x3f) {
                if (!n_swi) first_swi_pc = pc;
                n_swi++;
            }
        }
        sw_exec_step();
    }
    vg_hook(0);                                  /* close the last vector-generator run */

    unsigned cov_main = coverage(SW_MAIN, outdir.empty() ? nullptr : "coverage_main.txt");
    unsigned cov_snd = coverage(SW_SOUND, outdir.empty() ? nullptr : "coverage_sound.txt");
    unsigned n_phases = 0;
    for (int i = 0; i < 256; i++) if (phases[i >> 3] & (1u << (i & 7))) n_phases++;
    uint32_t crc = state_crc();
    double secs = (double)SW.cyc / 1512000.0;

    int ok = 1;
    const char *why = "";
    auto fail = [&](const char *w) { if (ok) why = w; ok = 0; };
    if (pass < frames && !ended) fail("did not reach the requested passes");
    if (SW.n_unmapped_r[0] || SW.n_unmapped_w[0] || SW.n_unmapped_r[1] || SW.n_unmapped_w[1]) fail("unmapped access");
    if (SW.n_cpu_log) fail("the 6809 core reported a fault");
    if (SW.n_wd_bites && !allow_wd) fail("watchdog bite");
    if (n_swi) fail("the program hit an SWI error trap");
    if (SW.mb.n_runaway) fail("matrix processor ran away");
    if (SW.vg.n_overflow) fail("vector buffer overflow");

    if (!quiet) {
        printf("REFRUN rev %d  %s\n", rev, script_path ? script_path : "(no script)");
        printf("  passes          : %u (mainline %u, self test %u)%s; %u dumped\n", pass, n_m, n_d,
               ended ? ", ended by script" : "", captured);
        printf("  time            : %llu main cycles (%.2f s), %llu sound cycles; longest pass %llu cycles\n",
               (unsigned long long)SW.cyc, secs, (unsigned long long)SW.snd_cyc, (unsigned long long)max_pass_cyc);
        printf("  steps           : main %llu, sound %llu;  PCs executed: main %u, sound %u;  phases seen %u\n",
               (unsigned long long)SW.n_steps[0], (unsigned long long)SW.n_steps[1], cov_main, cov_snd, n_phases);
        printf("  IRQ             : raised %u, taken %u; %u arrived with one still waiting (first at PC $%04X)\n",
               SW.n_irq, SW.n_irq_taken, SW.n_irq_lost, SW.n_irq_lost ? SW.first_lost_pc[0] : 0);
        printf("  watchdog        : %u kicks, longest gap %llu cycles (limit %llu), bites %u%s\n", SW.n_wd_kicks,
               (unsigned long long)SW.max_kick_gap, (unsigned long long)SW.wd_cycles, SW.n_wd_bites,
               SW.n_wd_bites ? " !!" : "");
        printf("  resets          : power-on %u, watchdog %u, script %u; sound board resets %u\n",
               SW.n_reset[SW_RST_POWERON], SW.n_reset[SW_RST_WATCHDOG], SW.n_reset[SW_RST_SCRIPT], SW.n_snd_resets);
        printf("  vector generator: %u VGGO, %u VGSTOP, %u runs (%u to HALT), mean %.0f ticks, longest %llu; most points %u\n",
               SW.vg.n_go, SW.vg.n_reset, avg_runs, avg_runs_halted,
               avg_runs_halted ? (double)avg_ticks_total / avg_runs_halted : 0.0,
               (unsigned long long)avg_ticks_max, avg_points_max);
        printf("  matrix processor: %u runs (longest %u steps, runaways %u), %u divides, %u random reads\n",
               SW.mb.n_runs, SW.mb.max_steps, SW.mb.n_runaway, SW.mb.n_divides, SW.mb.n_rnd_reads);
        printf("  NOVRAM          : %u writes, %u stores, %u recalls\n", SW.nv.n_write, SW.nv.n_store, SW.nv.n_recall);
        printf("  sound link      : %u commands (%u overwrote an unread one), %u replies\n",
               SW.n_main_cmds, SW.n_cmd_overrun, SW.n_snd_replies);
        printf("  sound board     : %u POKEY writes, %u speech bytes, %u speech status reads\n",
               SW.n_pokey_w, SW.n_tms_w, SW.n_tms_r);
        printf("  hardware access : main %llu writes %llu reads, sound %llu writes %llu reads\n",
               (unsigned long long)io_writes[0], (unsigned long long)io_reads[0],
               (unsigned long long)io_writes[1], (unsigned long long)io_reads[1]);
        for (int c = 0; c < 2; c++) {
            for (unsigned i = 0; i < SW.n_unmapped_r[c] && i < 8; i++)
                printf("  !! %s unmapped read  $%04X (PC $%04X)\n", c ? "sound" : "main",
                       SW.first_unmapped_r[c][i], SW.first_unmapped_pc[c][i]);
            for (unsigned i = 0; i < SW.n_unmapped_w[c] && i < 8; i++)
                printf("  !! %s unmapped write $%04X\n", c ? "sound" : "main", SW.first_unmapped_w[c][i]);
            if (SW.n_unmapped_r[c] + SW.n_unmapped_w[c])
                printf("  !! %s unmapped: %u reads, %u writes\n", c ? "sound" : "main",
                       SW.n_unmapped_r[c], SW.n_unmapped_w[c]);
        }
        for (unsigned i = 0; i < SW.n_cpu_log && i < 4; i++) printf("  !! core: %s\n", SW.first_log[i]);
        if (n_swi) printf("  !! SWI executed %u times, first at $%04X\n", n_swi, first_swi_pc);
        if (SW.n_wd_bites) printf("  !! watchdog bit at PC $%04X\n", SW.wd_bite_pc);
        printf("  hashes          : state %08X  main writes %08X  sound writes %08X  vectors %08X\n",
               crc, io_crc[0], io_crc[1], avg_crc_all);
        printf("  RESULT          : %s%s%s\n", ok ? "PASS" : "FAIL", ok ? "" : " - ", why);
    }

    if (!outdir.empty()) {
        FILE *j = fopen((outdir + "\\ref_index.json").c_str(), "w");
        std::string sname = script_path ? script_path : "";
        for (char &ch : sname) if (ch == '\\') ch = '/';
        if (j) {
            fprintf(j, "{\n \"rev\": %d,\n \"script\": \"%s\",\n \"passes\": %u,\n \"mainline_passes\": %u,\n"
                       " \"selftest_passes\": %u,\n \"cycles\": %llu,\n \"sound_cycles\": %llu,\n \"irqs\": %u,\n"
                       " \"watchdog_cycles\": %llu,\n \"watchdog_bites\": %u,\n \"vg_runs\": %u,\n"
                       " \"matrix_runs\": %u,\n \"pcs_main\": %u,\n \"pcs_sound\": %u,\n"
                       " \"state_crc\": \"%08X\",\n \"main_write_crc\": \"%08X\",\n \"sound_write_crc\": \"%08X\",\n"
                       " \"vector_crc\": \"%08X\",\n \"result\": \"%s\",\n \"captures\": [",
                    rev, sname.c_str(), pass, n_m, n_d, (unsigned long long)SW.cyc,
                    (unsigned long long)SW.snd_cyc, SW.n_irq, (unsigned long long)SW.wd_cycles, SW.n_wd_bites,
                    avg_runs, SW.mb.n_runs, cov_main, cov_snd, crc, io_crc[0], io_crc[1], avg_crc_all,
                    ok ? "PASS" : "FAIL");
            for (size_t i = 0; i < captures.size(); i++) fprintf(j, "%s%u", i ? ", " : "", captures[i]);
            fprintf(j, "]\n}\n");
            fclose(j);
        }
    }
#ifdef LOCKSTEP
    if (lk_report(lk_verbose)) ok = 0;
    if (lk_snd_report(lk_verbose)) ok = 0;
    if (!lk_reached_path.empty()) {
        lk_reached(lk_reached_path.c_str());
        lk_snd_reached((lk_reached_path + ".snd").c_str());
    }
#endif
    if (!nv_out.empty()) write_file(nv_out, SW.nv.eeprom, 0x100);
    if (f_sched) fclose(f_sched);
    if (f_avg) fclose(f_avg);
    if (f_io) fclose(f_io);
    return ok ? 0 : 1;
}
