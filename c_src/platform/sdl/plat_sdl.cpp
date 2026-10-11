/* plat_sdl.cpp - the Star Wars host on SDL2 + OpenGL 3.2 core: macOS and
 * Linux (it also builds on Windows, where plat_win.c remains the reference).
 *
 * The same contract as platform/windows/plat_win.c (../sw_platform.h), kept
 * small: a window with the vector picture, the yoke on the mouse, keys, a game
 * controller, one mono audio stream, the NOVRAM beside the executable, and the
 * testing switches the scenario tools use (--script, --passes, --turbo,
 * --quit-after-ms, --hidden) plus --dump, which writes every picture's lines.
 *
 * Paths: the executable's own folder (SDL_GetBasePath) holds sw_sdl.ini and
 * starwars.nv; the ROM images are read from <exe>/../disasm/build unless
 * [main] rom_dir or --romdir say otherwise.
 */
#include <SDL.h>
#ifdef __APPLE__
#define GL_SILENCE_DEPRECATION
#include <OpenGL/gl3.h>
#else
#define GL_GLEXT_PROTOTYPES
#include <GL/gl.h>
#include <GL/glext.h>
#endif
#include <cmath>
#include <cstdarg>
#include <cstdio>
#include <cstdlib>
#include <cstring>
#include <string>
#include <vector>
#include "../sw_platform.h"

#define APP_NAME "Star Wars"

/* ------------------------------------------------------------------ */
/* files, log, settings                                                */
/* ------------------------------------------------------------------ */

static std::string exe_dir, path_ini, path_nv, path_roms, path_log;
static FILE *log_file;

static void logf(const char *fmt, ...)
{
    char s[1024];
    va_list ap;
    va_start(ap, fmt);
    vsnprintf(s, sizeof s, fmt, ap);
    va_end(ap);
    fprintf(stderr, "%s\n", s);
    if (log_file) { fprintf(log_file, "%s\n", s); fflush(log_file); }
}

void plat_log(const char *text) { logf("%s", text); }

/* A minimal reader for the [section] key=value file plat_win.c writes. */
struct ini_entry { std::string sec, key, val; };
static std::vector<ini_entry> ini;

static void ini_load(const std::string &path)
{
    FILE *f = fopen(path.c_str(), "r");
    char line[512];
    std::string sec;
    if (!f) return;
    while (fgets(line, sizeof line, f)) {
        char *p = line, *e;
        while (*p == ' ' || *p == '\t') p++;
        for (e = p + strlen(p); e > p && (e[-1] == '\n' || e[-1] == '\r' || e[-1] == ' '); ) *--e = '\0';
        if (*p == ';' || *p == '#' || !*p) continue;
        if (*p == '[') { e = strchr(p, ']'); if (e) *e = '\0'; sec = p + 1; continue; }
        e = strchr(p, '=');
        if (!e) continue;
        *e = '\0';
        ini.push_back({ sec, p, e + 1 });
    }
    fclose(f);
}

static const char *ini_get(const char *sec, const char *key)
{
    for (auto &e : ini)
        if (e.sec == sec && e.key == key) return e.val.c_str();
    return nullptr;
}
static int ini_int(const char *sec, const char *key, int def)
{
    const char *v = ini_get(sec, key);
    return v ? (int)strtol(v, nullptr, 0) : def;
}
static double ini_dbl(const char *sec, const char *key, double def)
{
    const char *v = ini_get(sec, key);
    return v ? atof(v) : def;
}

/* ------------------------------------------------------------------ */
/* command line                                                        */
/* ------------------------------------------------------------------ */

static int      turbo, hidden_mode, no_nvram, test_cli, rev_cli = 2;
static double   quit_after_ms;
static unsigned long quit_after_passes;
static std::string nv_override, script_path, romdir_cli, dump_path;
static FILE    *dump_file;

static int parse_args(int argc, char **argv)
{
    for (int i = 1; i < argc; i++) {
        const char *a = argv[i];
        if (!strcmp(a, "--rev") && i + 1 < argc) rev_cli = atoi(argv[++i]);
        else if (!strcmp(a, "--romdir") && i + 1 < argc) romdir_cli = argv[++i];
        else if (!strcmp(a, "--script") && i + 1 < argc) script_path = argv[++i];
        else if (!strcmp(a, "--dump") && i + 1 < argc) dump_path = argv[++i];
        else if (!strcmp(a, "--turbo")) turbo = 1;
        else if (!strcmp(a, "--hidden")) hidden_mode = 1;
        else if (!strcmp(a, "--test")) test_cli = 1;
        else if (!strcmp(a, "--no-nvram")) no_nvram = 1;
        else if (!strcmp(a, "--nvram") && i + 1 < argc) nv_override = argv[++i];
        else if (!strcmp(a, "--quit-after-ms") && i + 1 < argc) quit_after_ms = atof(argv[++i]);
        else if (!strcmp(a, "--passes") && i + 1 < argc) quit_after_passes = strtoul(argv[++i], nullptr, 0);
        else return 1;
    }
    return 0;
}

/* ------------------------------------------------------------------ */
/* option switches                                                     */
/* ------------------------------------------------------------------ */
/* Defaults as plat_win.c: $84 (6 shields, moderate, attract music on) and
 * $02 (1 coin 1 credit). */
static uint8_t dsw0 = 0x84, dsw1 = 0x02;
uint8_t plat_dsw0(void) { return dsw0; }
uint8_t plat_dsw1(void) { return dsw1; }

/* ------------------------------------------------------------------ */
/* video                                                               */
/* ------------------------------------------------------------------ */

static SDL_Window   *win;
static SDL_GLContext glctx;
static GLuint prog, vao, vbo;
static float  brightness = 1.6f, linewidth = 2.0f;

struct seg { float x0, y0, x1, y1; uint32_t rgb; int in; };
static std::vector<seg> building, shown;
static int present_pending;
static unsigned long n_pictures;

static const char *VS =
    "#version 150\n"
    "in vec2 pos; in vec2 edge; in vec4 col;\n"
    "out vec2 v_edge; out vec4 v_col;\n"
    "void main() { v_edge = edge; v_col = col; gl_Position = vec4(pos, 0.0, 1.0); }\n";
static const char *FS =
    "#version 150\n"
    "in vec2 v_edge; in vec4 v_col; out vec4 o;\n"
    "void main() {\n"
    "  float d = length(v_edge);\n"
    "  float a = clamp(1.0 - d, 0.0, 1.0);\n"
    "  a = a * a * (3.0 - 2.0 * a);\n"
    "  o = vec4(v_col.rgb * v_col.a * a, 1.0);\n"
    "}\n";

static GLuint compile(GLenum type, const char *src)
{
    GLuint s = glCreateShader(type);
    GLint ok = 0;
    glShaderSource(s, 1, &src, nullptr);
    glCompileShader(s);
    glGetShaderiv(s, GL_COMPILE_STATUS, &ok);
    if (!ok) {
        char log[1024];
        glGetShaderInfoLog(s, sizeof log, nullptr, log);
        logf("shader: %s", log);
    }
    return s;
}

static int gl_init(void)
{
    prog = glCreateProgram();
    glAttachShader(prog, compile(GL_VERTEX_SHADER, VS));
    glAttachShader(prog, compile(GL_FRAGMENT_SHADER, FS));
    glBindAttribLocation(prog, 0, "pos");
    glBindAttribLocation(prog, 1, "edge");
    glBindAttribLocation(prog, 2, "col");
    glLinkProgram(prog);
    GLint ok = 0;
    glGetProgramiv(prog, GL_LINK_STATUS, &ok);
    if (!ok) { logf("shader program failed to link"); return 1; }
    glGenVertexArrays(1, &vao);
    glGenBuffers(1, &vbo);
    glBindVertexArray(vao);
    glBindBuffer(GL_ARRAY_BUFFER, vbo);
    glEnableVertexAttribArray(0);
    glEnableVertexAttribArray(1);
    glEnableVertexAttribArray(2);
    glVertexAttribPointer(0, 2, GL_FLOAT, GL_FALSE, 8 * sizeof(float), (void *)0);
    glVertexAttribPointer(1, 2, GL_FLOAT, GL_FALSE, 8 * sizeof(float), (void *)(2 * sizeof(float)));
    glVertexAttribPointer(2, 4, GL_FLOAT, GL_FALSE, 8 * sizeof(float), (void *)(4 * sizeof(float)));
    return 0;
}

void plat_video_begin(void) { building.clear(); }

void plat_video_line(float x0, float y0, float x1, float y1, uint32_t rgb, int intensity)
{
    building.push_back({ x0, y0, x1, y1, rgb, intensity });
}

void plat_video_present(void)
{
    shown.swap(building);
    present_pending = 1;
    n_pictures++;
    if (dump_file) {
        fprintf(dump_file, "P %lu %zu\n", n_pictures, shown.size());
        for (auto &s : shown)
            fprintf(dump_file, "%g %g %g %g %06X %d\n", s.x0, s.y0, s.x1, s.y1, (unsigned)(s.rgb & 0xFFFFFF), s.in);
    }
}

/* The tube shows x 0..250, y 0..280 (top to bottom) on a 4:3 screen. */
static void draw_picture(void)
{
    int dw, dh;
    SDL_GL_GetDrawableSize(win, &dw, &dh);
    int vw = dw, vh = dw * 3 / 4;
    if (vh > dh) { vh = dh; vw = dh * 4 / 3; }
    glViewport(0, 0, dw, dh);
    glClearColor(0, 0, 0, 1);
    glClear(GL_COLOR_BUFFER_BIT);
    glViewport((dw - vw) / 2, (dh - vh) / 2, vw, vh);

    /* half width in NDC, from [vector] linewidth = pixels at a 960-wide picture */
    const float px = linewidth * (float)vw / 960.0f;
    const float hx = (px * 0.5f + 1.0f) * 2.0f / (float)vw;
    const float hy = (px * 0.5f + 1.0f) * 2.0f / (float)vh;

    std::vector<float> v;
    v.reserve(shown.size() * 6 * 8);
    for (auto &s : shown) {
        float ax = s.x0 / 250.0f * 2.0f - 1.0f, ay = 1.0f - s.y0 / 280.0f * 2.0f;
        float bx = s.x1 / 250.0f * 2.0f - 1.0f, by = 1.0f - s.y1 / 280.0f * 2.0f;
        /* direction in pixels, so the width is even whatever the aspect */
        float dx = (bx - ax) / hx, dy = (by - ay) / hy;
        float len = std::sqrt(dx * dx + dy * dy);
        if (len < 1e-4f) { dx = 1.0f; dy = 0.0f; } else { dx /= len; dy /= len; }
        float nx = -dy, ny = dx;
        float r = (s.rgb & 0xFF) / 255.0f, g = ((s.rgb >> 8) & 0xFF) / 255.0f, b = ((s.rgb >> 16) & 0xFF) / 255.0f;
        float a = (float)s.in / 255.0f * brightness;
        /* the four corners, each end extended by one half width */
        float P[4][4] = {
            { ax + (-dx + nx) * hx, ay + (-dy + ny) * hy, -1.0f,  1.0f },
            { ax + (-dx - nx) * hx, ay + (-dy - ny) * hy, -1.0f, -1.0f },
            { bx + ( dx + nx) * hx, by + ( dy + ny) * hy,  1.0f,  1.0f },
            { bx + ( dx - nx) * hx, by + ( dy - ny) * hy,  1.0f, -1.0f },
        };
        /* the edge attribute is (0, across): the beam fades across its width */
        static const int idx[6] = { 0, 1, 2, 2, 1, 3 };
        for (int k = 0; k < 6; k++) {
            const float *p = P[idx[k]];
            v.insert(v.end(), { p[0], p[1], 0.0f, p[3], r, g, b, a });
        }
    }
    glUseProgram(prog);
    glBindVertexArray(vao);
    glBindBuffer(GL_ARRAY_BUFFER, vbo);
    glBufferData(GL_ARRAY_BUFFER, (GLsizeiptr)(v.size() * sizeof(float)), v.data(), GL_STREAM_DRAW);
    glEnable(GL_BLEND);
    glBlendFunc(GL_ONE, GL_ONE);
    glDrawArrays(GL_TRIANGLES, 0, (GLsizei)(v.size() / 8));
    SDL_GL_SwapWindow(win);
}

/* ------------------------------------------------------------------ */
/* input                                                               */
/* ------------------------------------------------------------------ */

static int g_quit, test_latch, diag_latch, sndtest_latch, mouse_captured = 1;
static double yoke_x = 128.0, yoke_y = 128.0, key_x, key_y, input_last_ms;
static double mouse_sens = 0.25, key_rate = 400.0;
static int invert_pitch, mouse_b;
static int mickey_x, mickey_y;
static SDL_GameController *pad;

static void set_capture(int on)
{
    mouse_captured = on;
    SDL_SetRelativeMouseMode(on ? SDL_TRUE : SDL_FALSE);
}

static void pump_events(void)
{
    SDL_Event e;
    while (SDL_PollEvent(&e)) {
        switch (e.type) {
        case SDL_QUIT: g_quit = 1; break;
        case SDL_MOUSEMOTION:
            if (mouse_captured) { mickey_x += e.motion.xrel; mickey_y += e.motion.yrel; }
            break;
        case SDL_MOUSEBUTTONDOWN:
            if (!mouse_captured) { set_capture(1); break; }
            if (e.button.button == SDL_BUTTON_LEFT) mouse_b |= 1;
            if (e.button.button == SDL_BUTTON_RIGHT) mouse_b |= 2;
            break;
        case SDL_MOUSEBUTTONUP:
            if (e.button.button == SDL_BUTTON_LEFT) mouse_b &= ~1;
            if (e.button.button == SDL_BUTTON_RIGHT) mouse_b &= ~2;
            break;
        case SDL_KEYDOWN:
            if (e.key.repeat) break;
            switch (e.key.keysym.scancode) {
            case SDL_SCANCODE_ESCAPE: g_quit = 1; break;
            case SDL_SCANCODE_F1: diag_latch = !diag_latch; break;
            case SDL_SCANCODE_F2: test_latch = !test_latch; break;
            case SDL_SCANCODE_F4: sndtest_latch = !sndtest_latch; break;
            case SDL_SCANCODE_F8: set_capture(!mouse_captured); break;
            case SDL_SCANCODE_RETURN:
                if (e.key.keysym.mod & (KMOD_ALT | KMOD_GUI)) {
                    Uint32 fs = SDL_GetWindowFlags(win) & SDL_WINDOW_FULLSCREEN_DESKTOP;
                    SDL_SetWindowFullscreen(win, fs ? 0 : SDL_WINDOW_FULLSCREEN_DESKTOP);
                }
                break;
            default: break;
            }
            break;
        case SDL_CONTROLLERDEVICEADDED:
            if (!pad) pad = SDL_GameControllerOpen(e.cdevice.which);
            break;
        case SDL_CONTROLLERDEVICEREMOVED:
            if (pad && SDL_GameControllerGetAttached(pad) == SDL_FALSE) { SDL_GameControllerClose(pad); pad = nullptr; }
            break;
        case SDL_WINDOWEVENT:
            if (e.window.event == SDL_WINDOWEVENT_FOCUS_LOST) set_capture(0);
            if (e.window.event == SDL_WINDOWEVENT_EXPOSED) present_pending = 1;
            break;
        default: break;
        }
    }
}

void plat_input_poll(plat_inputs *in)
{
    double now = plat_now_ms(), dt;
    memset(in, 0, sizeof *in);
    in->pitch = in->yaw = 0x80;
    in->test = (uint8_t)(test_latch || test_cli);
    in->diag = (uint8_t)diag_latch;
    in->snd_test = (uint8_t)sndtest_latch;
    in->quit = (uint8_t)g_quit;
    if (turbo || hidden_mode) return;

    dt = input_last_ms > 0.0 ? now - input_last_ms : 0.0;
    if (dt < 0.0) dt = 0.0;
    if (dt > 100.0) dt = 100.0;
    input_last_ms = now;

    const Uint8 *k = SDL_GetKeyboardState(nullptr);
    yoke_x += mickey_x * mouse_sens;
    yoke_y += mickey_y * mouse_sens * (invert_pitch ? -1.0 : 1.0);
    mickey_x = mickey_y = 0;
    if (yoke_x < 0.0) yoke_x = 0.0;
    if (yoke_x > 255.0) yoke_x = 255.0;
    if (yoke_y < 0.0) yoke_y = 0.0;
    if (yoke_y > 255.0) yoke_y = 255.0;

    in->fire_r  = (k[SDL_SCANCODE_LCTRL] || (mouse_b & 1)) ? 1 : 0;
    in->fire_l  = (k[SDL_SCANCODE_LALT] || (mouse_b & 2)) ? 1 : 0;
    in->thumb_r = k[SDL_SCANCODE_SPACE] ? 1 : 0;
    in->thumb_l = (k[SDL_SCANCODE_LSHIFT] || k[SDL_SCANCODE_RSHIFT]) ? 1 : 0;
    in->coin_l  = k[SDL_SCANCODE_5] ? 1 : 0;
    in->coin_r  = k[SDL_SCANCODE_6] ? 1 : 0;
    in->coin_aux = k[SDL_SCANCODE_7] ? 1 : 0;
    in->slam    = k[SDL_SCANCODE_F3] ? 1 : 0;

    /* arrow keys: a deflection that builds while held and springs back */
    {
        double step = key_rate * dt / 1000.0;
        double tx = (k[SDL_SCANCODE_RIGHT] ? 1.0 : 0.0) - (k[SDL_SCANCODE_LEFT] ? 1.0 : 0.0);
        double ty = (k[SDL_SCANCODE_DOWN] ? 1.0 : 0.0) - (k[SDL_SCANCODE_UP] ? 1.0 : 0.0);
        if (invert_pitch) ty = -ty;
        if (tx != 0.0) key_x += tx * step; else if (key_x > 0.0) { key_x -= step * 2.0; if (key_x < 0.0) key_x = 0.0; }
        else if (key_x < 0.0) { key_x += step * 2.0; if (key_x > 0.0) key_x = 0.0; }
        if (ty != 0.0) key_y += ty * step; else if (key_y > 0.0) { key_y -= step * 2.0; if (key_y < 0.0) key_y = 0.0; }
        else if (key_y < 0.0) { key_y += step * 2.0; if (key_y > 0.0) key_y = 0.0; }
        if (key_x > 127.0) key_x = 127.0;
        if (key_x < -128.0) key_x = -128.0;
        if (key_y > 127.0) key_y = 127.0;
        if (key_y < -128.0) key_y = -128.0;
    }
    double x = yoke_x + key_x, y = yoke_y + key_y;

    if (pad) {
        const int dz = 4000;
        int ax = SDL_GameControllerGetAxis(pad, SDL_CONTROLLER_AXIS_LEFTX);
        int ay = SDL_GameControllerGetAxis(pad, SDL_CONTROLLER_AXIS_LEFTY);
        if (ax > -dz && ax < dz) ax = 0;
        if (ay > -dz && ay < dz) ay = 0;
        x += ax / 256.0;
        y += ay / 256.0 * (invert_pitch ? -1.0 : 1.0);
        if (SDL_GameControllerGetButton(pad, SDL_CONTROLLER_BUTTON_A) ||
            SDL_GameControllerGetAxis(pad, SDL_CONTROLLER_AXIS_TRIGGERRIGHT) > 16000) in->fire_r = 1;
        if (SDL_GameControllerGetButton(pad, SDL_CONTROLLER_BUTTON_B) ||
            SDL_GameControllerGetAxis(pad, SDL_CONTROLLER_AXIS_TRIGGERLEFT) > 16000) in->fire_l = 1;
        if (SDL_GameControllerGetButton(pad, SDL_CONTROLLER_BUTTON_RIGHTSHOULDER)) in->thumb_r = 1;
        if (SDL_GameControllerGetButton(pad, SDL_CONTROLLER_BUTTON_LEFTSHOULDER)) in->thumb_l = 1;
        if (SDL_GameControllerGetButton(pad, SDL_CONTROLLER_BUTTON_BACK)) in->coin_l = 1;
    }
    if (x < 0.0) x = 0.0;
    if (x > 255.0) x = 255.0;
    if (y < 0.0) y = 0.0;
    if (y > 255.0) y = 255.0;
    in->yaw = (uint8_t)x;
    in->pitch = (uint8_t)y;
    in->quit = (uint8_t)g_quit;
}

/* ------------------------------------------------------------------ */
/* audio, time, storage                                                */
/* ------------------------------------------------------------------ */

static SDL_AudioDeviceID audio_dev;
static int volume = 100;

int plat_audio_open(int sample_rate)
{
    if (turbo || hidden_mode || volume <= 0) return -1;
    SDL_AudioSpec want, have;
    memset(&want, 0, sizeof want);
    want.freq = sample_rate;
    want.format = AUDIO_S16SYS;
    want.channels = 1;
    want.samples = 512;
    audio_dev = SDL_OpenAudioDevice(nullptr, 0, &want, &have, 0);
    if (!audio_dev) { logf("audio: %s; no sound", SDL_GetError()); return -1; }
    SDL_PauseAudioDevice(audio_dev, 0);
    return 0;
}

void plat_audio_push(const int16_t *pcm, int frames)
{
    if (!audio_dev) return;
    /* keep the queue short: drop when it backs up beyond ~150 ms */
    if (SDL_GetQueuedAudioSize(audio_dev) > (Uint32)(SW_AUDIO_RATE * 2 * 15 / 100)) return;
    if (volume >= 100) {
        SDL_QueueAudio(audio_dev, pcm, (Uint32)frames * 2);
    } else {
        std::vector<int16_t> t(pcm, pcm + frames);
        for (auto &s : t) s = (int16_t)(s * volume / 100);
        SDL_QueueAudio(audio_dev, t.data(), (Uint32)frames * 2);
    }
}

void plat_audio_close(void)
{
    if (audio_dev) SDL_CloseAudioDevice(audio_dev);
    audio_dev = 0;
}

double plat_now_ms(void)
{
    static Uint64 freq;
    if (!freq) freq = SDL_GetPerformanceFrequency();
    return (double)SDL_GetPerformanceCounter() * 1000.0 / (double)freq;
}

int plat_nvram_read(void *buf, unsigned len)
{
    if (no_nvram) return 1;
    FILE *f = fopen(path_nv.c_str(), "rb");
    if (!f) { logf("NOVRAM: no %s, a blank chip", path_nv.c_str()); return 1; }
    size_t got = fread(buf, 1, len, f);
    fclose(f);
    return got == len ? 0 : 1;
}

int plat_nvram_write(const void *buf, unsigned len)
{
    if (no_nvram) return 0;
    FILE *f = fopen(path_nv.c_str(), "wb");
    if (!f) { logf("NOVRAM: cannot write %s", path_nv.c_str()); return 1; }
    fwrite(buf, 1, len, f);
    fclose(f);
    return 0;
}

/* ------------------------------------------------------------------ */
/* main                                                                */
/* ------------------------------------------------------------------ */

int main(int argc, char **argv)
{
    if (parse_args(argc, argv)) {
        fprintf(stderr,
            "usage: %s [--rev 1|2] [--romdir DIR] [--test] [--nvram FILE] [--no-nvram]\n"
            "  testing: [--script FILE] [--passes N] [--quit-after-ms MS] [--turbo] [--hidden] [--dump FILE]\n",
            argv[0]);
        return 2;
    }

    char *base = SDL_GetBasePath();
    exe_dir = base ? base : "./";
    SDL_free(base);
    path_ini = exe_dir + "sw_sdl.ini";
    path_log = exe_dir + "sw_sdl.log";
    path_nv = nv_override.empty() ? exe_dir + "starwars.nv" : nv_override;
    log_file = fopen(path_log.c_str(), "w");
    ini_load(path_ini);

    {
        const char *r = ini_get("main", "rom_dir");
        std::string rd = r ? r : "../disasm/build";
        for (auto &c : rd) if (c == '\\') c = '/';
        path_roms = (!rd.empty() && rd[0] == '/') ? rd : exe_dir + rd;
        if (!romdir_cli.empty()) path_roms = romdir_cli;
    }
    dsw0 = (uint8_t)ini_int("dips", "dsw0", 0x84);
    dsw1 = (uint8_t)ini_int("dips", "dsw1", 0x02);
    brightness = (float)ini_dbl("vector", "brightness", 1.6);
    linewidth = (float)ini_dbl("vector", "linewidth", 2.0);
    mouse_sens = ini_dbl("input", "mouse_sensitivity", 0.25);
    key_rate = ini_dbl("input", "key_rate", 400.0);
    invert_pitch = ini_int("input", "invert_pitch", 0);
    volume = ini_int("sound", "volume", 100);

    if (!dump_path.empty()) dump_file = fopen(dump_path.c_str(), "w");

    Uint32 sdl_flags = SDL_INIT_TIMER | SDL_INIT_EVENTS;
    if (!turbo && !hidden_mode) sdl_flags |= SDL_INIT_VIDEO | SDL_INIT_AUDIO | SDL_INIT_GAMECONTROLLER;
    if (SDL_Init(sdl_flags) != 0) { logf("SDL_Init: %s", SDL_GetError()); return 1; }

    if (!turbo && !hidden_mode) {
        SDL_GL_SetAttribute(SDL_GL_CONTEXT_MAJOR_VERSION, 3);
        SDL_GL_SetAttribute(SDL_GL_CONTEXT_MINOR_VERSION, 2);
        SDL_GL_SetAttribute(SDL_GL_CONTEXT_PROFILE_MASK, SDL_GL_CONTEXT_PROFILE_CORE);
        SDL_GL_SetAttribute(SDL_GL_CONTEXT_FLAGS, SDL_GL_CONTEXT_FORWARD_COMPATIBLE_FLAG);
        SDL_GL_SetAttribute(SDL_GL_DOUBLEBUFFER, 1);
        win = SDL_CreateWindow(APP_NAME, SDL_WINDOWPOS_CENTERED, SDL_WINDOWPOS_CENTERED, 960, 720,
                               SDL_WINDOW_OPENGL | SDL_WINDOW_RESIZABLE | SDL_WINDOW_ALLOW_HIGHDPI);
        if (!win) { logf("window: %s", SDL_GetError()); return 1; }
        glctx = SDL_GL_CreateContext(win);
        if (!glctx) { logf("OpenGL: %s", SDL_GetError()); return 1; }
        SDL_GL_SetSwapInterval(ini_int("main", "vsync", 0));
        logf("GL_VERSION: %s", (const char *)glGetString(GL_VERSION));
        if (gl_init()) return 1;
        set_capture(ini_int("input", "mouse_capture", 1));
        for (int i = 0; i < SDL_NumJoysticks() && !pad; i++)
            if (SDL_IsGameController(i)) pad = SDL_GameControllerOpen(i);
    }

    sw_app_opts o;
    memset(&o, 0, sizeof o);
    o.rev = rev_cli == 1 ? 1 : 2;
    o.rom_dir = path_roms.c_str();
    o.script = script_path.empty() ? nullptr : script_path.c_str();
    o.turbo = turbo;
    o.pokey_volume = ini_int("sound", "pokey_volume", 100);
    o.speech_volume = ini_int("sound", "speech_volume", 100);
    logf("machine: %s, ROM revision %d, images in %s", sw_app_name(), o.rev, path_roms.c_str());
    if (sw_app_init(&o)) {
        logf("%s", sw_app_error());
        if (win) SDL_ShowSimpleMessageBox(SDL_MESSAGEBOX_ERROR, APP_NAME, sw_app_error(), win);
        return 1;
    }

    sw_app_stats st, st0;
    double t_start = plat_now_ms(), stat_t = t_start;
    unsigned long pics0 = 0;
    sw_app_get_stats(&st0);

    while (!g_quit) {
        if (win) pump_events();
        if (g_quit) break;
        double now = plat_now_ms();
        sw_app_run(now);
        sw_app_get_stats(&st);
        if (quit_after_passes && st.passes >= quit_after_passes) g_quit = 1;
        if (st.script_ended) g_quit = 1;
        if (quit_after_ms > 0.0 && now - t_start >= quit_after_ms) g_quit = 1;

        if (win) {
            if (present_pending) { draw_picture(); present_pending = 0; }
            if (now - stat_t >= 1000.0) {
                char s[300];
                double dt = (now - stat_t) / 1000.0;
                snprintf(s, sizeof s, APP_NAME "  %.1f pictures/s  machine/wall %.3f  %d vectors%s%s%s",
                         (double)(n_pictures - pics0) / dt, (double)(st.cycles - st0.cycles) / 1512000.0 / dt,
                         st.points, test_latch ? "  SELF TEST SWITCH ON" : "",
                         sndtest_latch ? "  SOUND TEST ON" : "", mouse_captured ? "" : "  (click to capture the mouse)");
                SDL_SetWindowTitle(win, s);
                stat_t = now;
                st0 = st;
                pics0 = n_pictures;
            }
            SDL_Delay(1);
        }
    }

    sw_app_get_stats(&st);
    logf("exit: passes %lu, cycles %llu (%.3f s machine, %.3f s wall), pictures %lu, irqs %lu, phase %02X",
         st.passes, (unsigned long long)st.cycles, (double)st.cycles / 1512000.0,
         (plat_now_ms() - t_start) / 1000.0, st.pictures, st.irqs, st.phase);
    sw_app_exit();
    if (dump_file) fclose(dump_file);
    if (glctx) SDL_GL_DeleteContext(glctx);
    if (win) SDL_DestroyWindow(win);
    SDL_Quit();
    if (log_file) fclose(log_file);
    return 0;
}
