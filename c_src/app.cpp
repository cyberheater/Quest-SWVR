/* app.cpp - the Star Wars C port as a machine for a host
 * (platform/sw_platform.h): the two translated programs (port.cpp) on the chip
 * models (hw.cpp).  There is no 6809 in it.  (The emulator twin, the ROMs on
 * 6809 cores behind the same window, is a separate program with its own copy of
 * every file: ../emu_src.)
 *
 * Everything a player sees and hears is made here from the chips: the picture
 * from the vector generator's display list (avg.c, timed by its state PROM),
 * the sound from four POKEYs and the speech chip on the sound board's cycle
 * clock.
 *
 * Pacing: machine time is CPU cycles at 1.512 MHz, and sw_app_run() runs the
 * machine up to the wall clock.  Nothing else sets the speed: the 246 Hz
 * interrupt, the vector generator's HALT and the game's frame rate all come
 * from the cycle clock.
 */
#include <cstdio>
#include <cstdlib>
#include <cstring>
#include <string>
#include <vector>
#include "board.h"
#include "port.h"
#include "platform/sw_platform.h"
extern "C" {
#include "c012294.h"
#ifdef SW_3D
#include "sw3d.h"
#endif
}

#define CPU_HZ      1512000.0
#define PHASE       0x4841u

static sw_app_opts opt;
static char err[300];
static std::vector<uint8_t> rom_main, rom_bank1, rom_snd, rom_mb, rom_avg;
static sw_roms roms;
static sw_app_stats st;
static double t0_ms;
static uint64_t cyc0;
static int started;

const char *sw_app_error(void) { return err; }

static uint8_t *main_mem(void) { return port_main_mem(); }

/* ------------------------------------------------------------------ */
/* ROM images                                                           */
/* ------------------------------------------------------------------ */
static int load(const char *name, std::vector<uint8_t> &v, size_t want)
{
    std::string path = std::string(opt.rom_dir) + "/" + name;     /* "/" works on Windows too */
    FILE *f = fopen(path.c_str(), "rb");
    if (!f) {
        snprintf(err, sizeof err, "cannot open %s\n\nBuild the ROM images first:  python disasm\\gen_from_roms.py "
                 "(or disasm\\image.py) with a MAME starwars ROM set in roms\\", path.c_str());
        return 1;
    }
    v.resize(want);
    size_t n = fread(v.data(), 1, want, f);
    fclose(f);
    if (n != want) { snprintf(err, sizeof err, "%s is %u bytes, expected %u", path.c_str(), (unsigned)n, (unsigned)want); return 1; }
    return 0;
}

/* ------------------------------------------------------------------ */
/* sound: four POKEYs and the speech chip, on the sound board's clock   */
/* ------------------------------------------------------------------ */
static ad_pokey pokey[4];
static uint64_t pokey_cyc;                  /* the sound-board cycle the POKEYs have been clocked to */
static int audio_live;
#define TMS_RING 16384
static short tms_ring[TMS_RING];
static uint64_t tms_w;                      /* speech samples received (8 kHz) */
static uint64_t out_n;                      /* output samples pushed */
static short tms_last;

static void pokeys_to(uint64_t cyc)
{
    if (cyc <= pokey_cyc) return;
    uint64_t n = cyc - pokey_cyc;
    if (n > 1512000) n = 1512000;
    for (int i = 0; i < 4; i++) ad_pokey_advance(&pokey[i], (uint32_t)n);
    pokey_cyc = cyc;
}

static void pokey_hook(int chip, int reg, uint8_t v)
{
    pokeys_to(SW.snd_cyc);
    ad_pokey_write(&pokey[chip & 3], (uint8_t)reg, v);
}

static void tms_hook(short s) { tms_ring[tms_w++ & (TMS_RING - 1)] = s; }

static void audio_pump(void)
{
    static int16_t buf[4][2048], mix[2048];
    pokeys_to(SW.snd_cyc);
    for (;;) {
        uint32_t n = 2048;
        for (int i = 0; i < 4; i++) {
            uint32_t a = ad_pokey_audio_available(&pokey[i]);
            if (a < n) n = a;
        }
        if (n == 0) break;
        for (int i = 0; i < 4; i++) ad_pokey_audio_read(&pokey[i], buf[i], (int)n);
        for (uint32_t k = 0; k < n; k++) {
            /* the speech sample for this output sample: 8 kHz held, a few samples behind */
            uint64_t idx = (out_n + k) * 8000u / SW_AUDIO_RATE;
            if (idx < tms_w && tms_w - idx < TMS_RING) tms_last = tms_ring[idx & (TMS_RING - 1)];
            int v = ((int)buf[0][k] + buf[1][k] + buf[2][k] + buf[3][k]) * opt.pokey_volume / 400
                  + (int)tms_last * opt.speech_volume / 200;
            mix[k] = (int16_t)(v > 32767 ? 32767 : v < -32768 ? -32768 : v);
        }
        out_n += n;
        plat_audio_push(mix, (int)n);            /* the backend drops it when it has no stream */
    }
}

/* ------------------------------------------------------------------ */
/* picture: the display list the vector generator has just drawn        */
/* ------------------------------------------------------------------ */
static uint64_t shown_run = ~0ull;

static void vg_hook(int go)
{
    (void)go;
    const avg *a = &SW.vg;
    if (a->nvect == 0 || a->run_start == shown_run) return;
    shown_run = a->run_start;
    plat_video_begin();
#ifdef SW_3D
    static FILE *d3 = (FILE *)-1;
    if (d3 == (FILE *)-1) { const char *e = getenv("SW_DUMP3D"); d3 = e ? fopen(e, "w") : nullptr; }
    if (d3) fprintf(d3, "P %lu %u\n", st.pictures + 1, a->nvect);
    const avg_point *pt_prev = nullptr;
    static float r_sx[AVG_MAXVECT], r_sy[AVG_MAXVECT];
    static sw3d_out r3[AVG_MAXVECT];
    const int view3 = plat_video_3d();
    if (d3 || view3) {
        for (uint32_t i = 0; i < a->nvect; i++) {
            r_sx[i] = (float)a->vect[i].x / 65536.0f;
            r_sy[i] = (float)a->vect[i].y / 65536.0f;
        }
        sw3d_resolve(a->vect, a->nvect, r_sx, r_sy, r3);
    }
    sw3d_out r_start = { SW3D_HUD, 125.0f, 140.0f, 0 };
#endif
    float px = 125.0f, py = 140.0f;
    int lit = 0;
    for (uint32_t i = 0; i < a->nvect; i++) {
        const avg_point *p = &a->vect[i];
        float x = (float)p->x / 65536.0f, y = (float)p->y / 65536.0f;
        if (p->z) {
            uint32_t rgb = 0xFF000000u | ((p->color & 4) ? 0xFFu : 0) | ((p->color & 2) ? 0xFF00u : 0)
                         | ((p->color & 1) ? 0xFF0000u : 0);
#ifdef SW_3D
            if (view3 && i && r3[i - 1].layer == SW3D_WORLD && r3[i].layer == SW3D_WORLD)
                plat_video_line3(&r3[i - 1].x, &r3[i].x, rgb, p->z);
            else
#endif
            plat_video_line(px, py, x, y, rgb, p->z);
            lit++;
#ifdef SW_3D
            if (d3) {
                const avg_point *s = pt_prev;
                fprintf(d3, "%g %g %g %g %06X %d %04X %d %d %d %d %04X %d %d %d %d %04X %04X %04X", px, py, x, y,
                        (unsigned)(rgb & 0xFFFFFF), p->z, p->src,
                        s ? s->p3_valid : 0, s ? s->p3[0] : 0, s ? s->p3[1] : 0, s ? s->p3[2] : 0, s ? s->p3_ck : 0,
                        p->p3_valid, p->p3[0], p->p3[1], p->p3[2], p->p3_ck, p->p3_dck, s ? s->p3_dck : 0);
                const sw3d_out *rs = i ? &r3[i - 1] : &r_start, *rt = &r3[i];
                fprintf(d3, " R %d %g %g %g %d %g %g %g\n", rs->layer, rs->x, rs->y, rs->z, rt->layer, rt->x, rt->y, rt->z);
            }
#endif
        }
#ifdef SW_3D
        pt_prev = p;
#endif
        px = x; py = y;
    }
    plat_video_present();
    st.pictures++;
    st.points = lit;
}

/* ------------------------------------------------------------------ */
/* script: a tests/scenarios file (tests/refrun.cpp's format)           */
/* ------------------------------------------------------------------ */
enum { SC_BYTE, SC_BIT_LOW, SC_RESET, SC_END, SC_POKE };
struct script_line { unsigned pass; int kind; uint8_t *port; uint8_t mask, val; unsigned addr; };
static std::vector<script_line> script;
static size_t script_pos;

static int load_script(const char *path)
{
    static const struct { const char *name; int kind; uint8_t *port; uint8_t mask; } ports[] = {
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
    char line[256], port[32];
    FILE *f = fopen(path, "r");
    if (!f) { snprintf(err, sizeof err, "cannot open script %s", path); return 1; }
    while (fgets(line, sizeof line, f)) {
        unsigned pass;
        int a = 0, b = 0;
        char *h = strchr(line, '#');
        if (h) *h = 0;
        int nf = sscanf(line, "%u %31s %i %i", &pass, port, &a, &b);
        if (nf < 2) continue;
        if (!strcmp(port, "poke") && nf == 4) {
            script.push_back({ pass, SC_POKE, nullptr, 0, (uint8_t)b, (unsigned)a });
            continue;
        }
        int found = 0;
        for (const auto &p : ports)
            if (!strcmp(port, p.name)) {
                script.push_back({ pass, p.kind, p.port, p.mask, (uint8_t)a, 0 });
                found = 1;
            }
        if (!found) { snprintf(err, sizeof err, "bad script line: %s", line); fclose(f); return 1; }
    }
    fclose(f);
    return 0;
}

static int reset_request;

static void apply_script(unsigned pass)
{
    while (script_pos < script.size() && script[script_pos].pass <= pass) {
        const script_line &s = script[script_pos++];
        switch (s.kind) {
        case SC_BYTE:    *s.port = s.val; break;
        case SC_BIT_LOW: *s.port = (uint8_t)(s.val ? (*s.port & ~s.mask) : (*s.port | s.mask)); break;
        case SC_POKE:    if (s.addr >= 0x4800 && s.addr < 0x6000) main_mem()[s.addr] = s.val; break;
        case SC_RESET:   reset_request = 1; break;
        default:         st.script_ended = 1; break;
        }
    }
}

static void on_pass(void)
{
    st.passes++;
    if (!script.empty()) apply_script((unsigned)st.passes);
}

/* ------------------------------------------------------------------ */
/* the machine                                                          */
/* ------------------------------------------------------------------ */
int sw_app_init(const sw_app_opts *o)
{
    opt = *o;
    if (load(opt.rev == 1 ? "starwars_main_rev1.bin" : "starwars_main_rev2.bin", rom_main, 0x10000) ||
        load("starwars_bank1.bin", rom_bank1, 0x2000) || load("starwars_sound.bin", rom_snd, 0x10000) ||
        load("starwars_mathbox.bin", rom_mb, 0x1000) || load("starwars_avgprom.bin", rom_avg, 0x100))
        return 1;
    roms.main_rom = rom_main.data();
    roms.bank1 = rom_bank1.data();
    roms.sound_rom = rom_snd.data();
    roms.mathbox_proms = rom_mb.data();
    roms.avg_prom = rom_avg.data();

    sw_hw_init(&roms);
    SW.dsw0 = plat_dsw0();
    SW.dsw1 = plat_dsw1();
    SW.vg_hook = vg_hook;
    SW.pokey_hook = pokey_hook;
    SW.tms_hook = tms_hook;
    plat_nvram_read(SW.nv.eeprom, 0x100);        /* no file: a blank chip, and the program initialises it */

    for (int i = 0; i < 4; i++) {
        ad_pokey_init(&pokey[i], 1512000, SW_AUDIO_RATE);
        ad_pokey_set_measured_audio(&pokey[i], 20.0, 1.0);
    }
    audio_live = plat_audio_open(SW_AUDIO_RATE) == 0;

    if (opt.script && load_script(opt.script)) return 1;
    apply_script(0);
    port_power_on(&roms, on_pass);
    started = 0;
    return 0;
}

/* The switches and the yoke, as the ports read them (board.cpp's header):
 * every switch is active low. */
static void live_inputs(void)
{
    plat_inputs in;
    plat_input_poll(&in);
    SW.in0 = (uint8_t)(0xdf & ~((in.coin_r ? 0x01 : 0) | (in.coin_l ? 0x02 : 0) | (in.coin_aux ? 0x04 : 0) |
                                (in.slam ? 0x08 : 0) | (in.test ? 0x10 : 0) | (in.fire_r ? 0x40 : 0) |
                                (in.fire_l ? 0x80 : 0)));
    SW.in1 = (uint8_t)(0x34 & ~((in.diag ? 0x04 : 0) | (in.thumb_r ? 0x10 : 0) | (in.thumb_l ? 0x20 : 0)));
    SW.snd_test = in.snd_test ? 0x00 : 0x10;
    SW.adc_in[0] = in.pitch;
    SW.adc_in[1] = in.yaw;
}

void sw_app_run(double now_ms)
{
    uint64_t now_cyc = port_cycles();
    uint64_t target;

    if (script.empty()) live_inputs();

    if (opt.turbo) {
        target = now_cyc + 6144;                 /* one interrupt period per call */
    } else {
        if (!started) { started = 1; t0_ms = now_ms; cyc0 = now_cyc; }
        double want = (double)cyc0 + (now_ms - t0_ms) * (CPU_HZ / 1000.0);
        if (want - (double)now_cyc > CPU_HZ * 0.1) {     /* more than 100 ms behind: do not chase it */
            t0_ms = now_ms;
            cyc0 = now_cyc;
            want = (double)now_cyc + CPU_HZ * 0.004;
        }
        if (want <= (double)now_cyc) return;
        target = (uint64_t)want;
    }
    if (reset_request) { reset_request = 0; port_reset(); }
    port_run_until(target);
    audio_pump();
}

void sw_app_get_stats(sw_app_stats *s)
{
    st.cycles = port_cycles();
    st.irqs = SW.n_irq;
    st.irqs_lost = SW.n_irq_lost;
    st.resets = SW.n_reset[SW_RST_WATCHDOG] + SW.n_reset[SW_RST_SCRIPT];
    st.watchdog_bites = SW.n_wd_bites;
    st.snd_resets = SW.n_snd_resets;
    st.swi = port_swi();
    st.phase = main_mem()[PHASE];
    *s = st;
}

void sw_app_exit(void)
{
    /* The host stores the NOVRAM's RAM side when it closes, so that scores,
     * statistics and options survive.  (The program itself strobes NSTORE only
     * from the option page's NOVRAM test; what stores the chip on a real board
     * at power-down was not examined here.) */
    x2212_store(&SW.nv);
    plat_nvram_write(SW.nv.eeprom, 0x100);
    if (audio_live) plat_audio_close();
}

const char *sw_app_name(void) { return "C port"; }
