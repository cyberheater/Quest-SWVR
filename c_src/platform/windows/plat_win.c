/* plat_win.c - Star Wars: the Windows backend (platform/sw_platform.h).
 *
 * Adapted from the Tempest port's plat_win.c.  Win32 + OpenGL 3.3 on the
 * framework files in this directory: raw input (key[] buffer, mouse mickeys),
 * the XAudio2 mixer's stream voice, the shader beam renderer, DirectInput
 * joystick, DPI-aware window with ALT+ENTER borderless fullscreen, ini config.
 *
 * Star Wars differences from the Tempest backend:
 *  - the monitor is a 4:3 tube in landscape; the vector generator's window
 *    (x 0..250, y 0..280, y down) fills it;
 *  - 3-bit colour and an 8-bit brightness per vector;
 *  - one picture per display list the vector generator draws (a VGGO), swapped
 *    at once (vsync = 0) or on the display's refresh;
 *  - the flight yoke: mouse (it moves the yoke, which stays where it is put),
 *    arrow keys (spring back to centre), or a joystick's two axes;
 *  - four POKEYs and a speech chip in one mono stream;
 *  - files next to the exe, named after it: <exe>.ini, <exe>.log, and
 *    starwars.nv;
 *  - verification options (--script, --shot, --hidden, --turbo, --stats).
 *
 * The same file serves the C port (c_src, sw_win.exe) and the emulator twin
 * (emu_src, sw_emu.exe); each has its own copy.
 */
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <math.h>
#include "../sw_platform.h"
#include "framework.h"     /* Windows.h, glew, log */
#include "sys_gl.h"
#include "rawinput.h"
#include "joystick.h"
#include "mixer.h"
#include "vector_draw.h"
#include "mat4.h"
#include "ini.h"
#include "colordefs.h"
#include "miniz.h"
#include <mmsystem.h>
#pragma comment(lib, "winmm.lib")
#pragma comment(lib, "user32.lib")
#pragma comment(lib, "gdi32.lib")

#define APP_NAME "Star Wars"
#define KEY_HELP "mouse/arrows/stick = yoke, LMB/Ctrl + RMB/Alt = triggers, Space/Shift = thumbs (any fires, " \
                 "and starts), 5/6 coin, 7 aux coin, F2 self test, F1 diag, F4 sound test, F8 mouse capture, Esc quit"

/* ------------------------------------------------------------------ */
/* files next to the exe                                               */
/* ------------------------------------------------------------------ */

static char exe_dir[MAX_PATH];
static char path_ini[MAX_PATH], path_log[MAX_PATH], path_nv[MAX_PATH], path_roms[MAX_PATH];

static void resolve_paths(void)
{
    char *slash;
    DWORD n = GetModuleFileNameA(NULL, exe_dir, (DWORD)sizeof exe_dir);
    if (n == 0 || n >= sizeof exe_dir) exe_dir[0] = '\0';
    char stem[64] = "sw_win";
    slash = strrchr(exe_dir, '\\');
    if (slash) {
        char *dot;
        snprintf(stem, sizeof stem, "%s", slash + 1);
        dot = strrchr(stem, '.');
        if (dot) *dot = '\0';
        slash[1] = '\0';
    } else exe_dir[0] = '\0';
    snprintf(path_ini, sizeof path_ini, "%s%s.ini", exe_dir, stem);
    snprintf(path_log, sizeof path_log, "%s%s.log", exe_dir, stem);
    snprintf(path_nv,  sizeof path_nv,  "%sstarwars.nv", exe_dir);
}

/* ------------------------------------------------------------------ */
/* command line                                                        */
/* ------------------------------------------------------------------ */

#define MAX_SHOTS 16
typedef struct { unsigned long pass; int by_picture; char path[MAX_PATH]; } shot_req;   /* --shot N: at pass N; --shot pN: at picture N */

static shot_req shots[MAX_SHOTS];
static int      n_shots, shots_done;
static int      shot_w = 960, shot_h = 720;
static int      turbo;                  /* no pacing, no audio, hidden window */
static int      hidden_mode;            /* real clock, window never shown, audio muted */
static double   quit_after_ms;
static unsigned long quit_after_passes;
static int      no_nvram;
static char     nv_override[MAX_PATH], script_path[MAX_PATH], stats_path[MAX_PATH], romdir_cli[MAX_PATH];
static int      rev_cli = 2;
static int      test_cli;

/* ------------------------------------------------------------------ */
/* option switches                                                     */
/* ------------------------------------------------------------------ */
/* [dips] dsw0 / dsw1: the two banks raw, as $4340 and $4360 read them
 * (MAME's starwars DSW0 / DSW1).  Defaults = the oracle's: $84 (6 shields,
 * moderate, no bonus shields, attract music on, normal) and $02 (1 coin 1
 * credit).  The option page of the self test (F2 in the attract mode, then 7)
 * sets most of what a player wants and keeps it in the NOVRAM. */
static uint8_t dsw0 = 0x84, dsw1 = 0x02;
uint8_t plat_dsw0(void) { return dsw0; }
uint8_t plat_dsw1(void) { return dsw1; }

/* ------------------------------------------------------------------ */
/* geometry: the vector generator's window -> the 4:3 picture          */
/* ------------------------------------------------------------------ */
#define AVG_W      250.0f
#define AVG_H      280.0f
#define PIC_HH     300.0f                      /* picture half-height, units */
#define PIC_HW     (PIC_HH * 4.0f / 3.0f)      /* 4:3 */

static void xform_point(float x, float y, float *px, float *py)
{
    *px = (x / AVG_W * 2.0f - 1.0f) * PIC_HW;
    *py = (1.0f - y / AVG_H * 2.0f) * PIC_HH;
}

/* Liang-Barsky against the tube window; 0 = nothing visible. */
static int clip_seg(float *x0, float *y0, float *x1, float *y1)
{
    float t0 = 0.0f, t1 = 1.0f;
    float dx = *x1 - *x0, dy = *y1 - *y0;
    float p[4], q[4];
    int i;
    p[0] = -dx; q[0] = *x0;
    p[1] =  dx; q[1] = AVG_W - *x0;
    p[2] = -dy; q[2] = *y0;
    p[3] =  dy; q[3] = AVG_H - *y0;
    for (i = 0; i < 4; i++) {
        if (p[i] == 0.0f) {
            if (q[i] < 0.0f) return 0;
        } else {
            float t = q[i] / p[i];
            if (p[i] < 0.0f) { if (t > t1) return 0; if (t > t0) t0 = t; }
            else             { if (t < t0) return 0; if (t < t1) t1 = t; }
        }
    }
    if (t1 < 1.0f) { *x1 = *x0 + t1 * dx; *y1 = *y0 + t1 * dy; }
    if (t0 > 0.0f) { *x0 = *x0 + t0 * dx; *y0 = *y0 + t0 * dy; }
    return 1;
}

/* ---- frame store: the newest complete picture is what every present draws;
 * with [vector] phosphor_ms > 0 older ones are replayed under it ---------- */
#define PH_FRAMES  6
#define PH_SEGS    16384
#define PH_FLOOR   0.02

typedef struct { float x0, y0, x1, y1; rgb_t rgb; int intensity; } ph_seg;
typedef struct { ph_seg *seg; int n; double t; int used; } ph_frame;

static ph_frame ph_buf[PH_FRAMES];
static int      ph_cur;
static int      ph_fill = -1;
static double   ph_tau;
static unsigned long seg_total, seg_clipped;

/* ------------------------------------------------------------------ */
/* window                                                              */
/* ------------------------------------------------------------------ */

static HWND hWnd;
static int  g_quit;

int SCREEN_W = 960;
int SCREEN_H = 720;
int DESIGN_W = 960;
int DESIGN_H = 720;

HWND win_get_window(void) { return hWnd; }

static void msg_box(const char *title, const char *message)
{
    LOG_ERROR("%s: %s", title, message);
    if (turbo || hidden_mode) return;
    MessageBoxA(NULL, message, title, MB_ICONEXCLAMATION | MB_OK);
}

static void set_window_title(const char *title) { SetWindowTextA(hWnd, title); }

#ifndef DPI_AWARENESS_CONTEXT_PER_MONITOR_AWARE_V2
#define DPI_AWARENESS_CONTEXT_PER_MONITOR_AWARE_V2 ((DPI_AWARENESS_CONTEXT)-4)
#endif
#ifndef USER_DEFAULT_SCREEN_DPI
#define USER_DEFAULT_SCREEN_DPI 96
#endif
#ifndef WM_DPICHANGED
#define WM_DPICHANGED 0x02E0
#endif

static void enable_dpi_awareness(void)
{
    typedef BOOL(WINAPI *SetProcessDpiAwarenessContext_t)(DPI_AWARENESS_CONTEXT);
    HMODULE user32 = GetModuleHandleW(L"user32.dll");
    if (user32) {
        SetProcessDpiAwarenessContext_t set_ctx = (SetProcessDpiAwarenessContext_t)
            GetProcAddress(user32, "SetProcessDpiAwarenessContext");
        if (set_ctx && set_ctx(DPI_AWARENESS_CONTEXT_PER_MONITOR_AWARE_V2))
            return;
    }
    SetProcessDPIAware();
}

static UINT window_dpi(HWND hwnd)
{
    typedef UINT(WINAPI *GetDpiForWindow_t)(HWND);
    HMODULE user32 = GetModuleHandleW(L"user32.dll");
    UINT dpi = 0;
    if (user32) {
        GetDpiForWindow_t get_dpi = (GetDpiForWindow_t)GetProcAddress(user32, "GetDpiForWindow");
        if (get_dpi) dpi = get_dpi(hwnd);
    }
    return dpi ? dpi : USER_DEFAULT_SCREEN_DPI;
}

/* The 4:3 design size at the window's DPI, shrunk (keeping 4:3) to fit 90% of
 * the monitor's work area. */
static void size_window_for_dpi(HWND hwnd, UINT dpi, DWORD style)
{
    MONITORINFO mi;
    RECT wr;
    int cw = MulDiv(DESIGN_W, (int)dpi, USER_DEFAULT_SCREEN_DPI);
    int ch = MulDiv(DESIGN_H, (int)dpi, USER_DEFAULT_SCREEN_DPI);

    memset(&mi, 0, sizeof mi);
    mi.cbSize = sizeof mi;
    if (GetMonitorInfo(MonitorFromWindow(hwnd, MONITOR_DEFAULTTONEAREST), &mi)) {
        int avail_h = (mi.rcWork.bottom - mi.rcWork.top) * 9 / 10 - 40;
        int avail_w = (mi.rcWork.right - mi.rcWork.left) * 9 / 10;
        if (avail_h > 200 && ch > avail_h) { ch = avail_h; cw = ch * 4 / 3; }
        if (avail_w > 200 && cw > avail_w) { cw = avail_w; ch = cw * 3 / 4; }
    }
    wr.left = 0; wr.top = 0; wr.right = cw; wr.bottom = ch;
    AdjustWindowRect(&wr, style, FALSE);
    SetWindowPos(hwnd, NULL, 0, 0, wr.right - wr.left, wr.bottom - wr.top,
                 SWP_NOMOVE | SWP_NOZORDER | SWP_NOACTIVATE);
}

/* ---- borderless fullscreen, ALT+ENTER ---- */
static int      is_fullscreen;
static RECT     windowed_rect;
static LONG_PTR windowed_style, windowed_exstyle;

int IsFullscreen(void) { return is_fullscreen; }

void ToggleFullscreen(void)
{
    if (is_fullscreen) {
        SetWindowLongPtr(hWnd, GWL_STYLE, windowed_style);
        SetWindowLongPtr(hWnd, GWL_EXSTYLE, windowed_exstyle);
        SetWindowPos(hWnd, HWND_NOTOPMOST, windowed_rect.left, windowed_rect.top,
                     windowed_rect.right - windowed_rect.left, windowed_rect.bottom - windowed_rect.top,
                     SWP_FRAMECHANGED | SWP_SHOWWINDOW);
        is_fullscreen = 0;
    } else {
        MONITORINFO mi = { sizeof(mi) };
        GetMonitorInfo(MonitorFromWindow(hWnd, MONITOR_DEFAULTTONEAREST), &mi);
        GetWindowRect(hWnd, &windowed_rect);
        windowed_style = GetWindowLongPtr(hWnd, GWL_STYLE);
        windowed_exstyle = GetWindowLongPtr(hWnd, GWL_EXSTYLE);
        SetWindowLongPtr(hWnd, GWL_STYLE, WS_POPUP | WS_VISIBLE);
        SetWindowLongPtr(hWnd, GWL_EXSTYLE, WS_EX_APPWINDOW | WS_EX_TOPMOST);
        SetWindowPos(hWnd, HWND_TOPMOST, mi.rcMonitor.left, mi.rcMonitor.top,
                     mi.rcMonitor.right - mi.rcMonitor.left, mi.rcMonitor.bottom - mi.rcMonitor.top,
                     SWP_FRAMECHANGED | SWP_SHOWWINDOW);
        is_fullscreen = 1;
    }
}

/* ---- beam width: [vector] linewidth = pixels at the default 960-wide window,
 * scaling with the picture; line_smoothing = the AA feather in pixels ---- */
static float beam_px = 2.0f;
static float beam_feather_px = 1.0f;
static float beam_proj[16];

static void update_beam_width_for(double vw)
{
    double span = (double)PIC_HW * 2.0, feather_du, core_px;
    if (vw < 1.0) vw = 1.0;
    feather_du = beam_feather_px * span / vw;
    beam_set_smoothing((float)feather_du);
    core_px = beam_px - beam_feather_px;
    if (core_px < 0.0) core_px = 0.0;
    beam_set_linewidth((float)(core_px * span / (double)DESIGN_W + feather_du));
}

static void update_beam_width(void)
{
    double vw = (double)SCREEN_W;
    if ((double)SCREEN_H * DESIGN_W < vw * DESIGN_H)
        vw = (double)SCREEN_H * DESIGN_W / (double)DESIGN_H;
    update_beam_width_for(vw);
}

/* ---- mouse capture ---- */
static int capture_enabled = 1;
static int window_active;

static void apply_capture(void)
{
    if (!hWnd) return;
    if (capture_enabled && window_active && !turbo && !hidden_mode) {
        RECT rc;
        POINT tl = { 0, 0 }, br;
        GetClientRect(hWnd, &rc);
        br.x = rc.right; br.y = rc.bottom;
        ClientToScreen(hWnd, &tl);
        ClientToScreen(hWnd, &br);
        rc.left = tl.x; rc.top = tl.y; rc.right = br.x; rc.bottom = br.y;
        ClipCursor(&rc);
    } else {
        ClipCursor(NULL);
    }
}

/* ------------------------------------------------------------------ */
/* presentation                                                        */
/* ------------------------------------------------------------------ */

static int    swap_mode;
static int    present_pending;
static unsigned long n_swaps, n_frames_in;
static int    last_nsegs;
static double gamma_gain = 1.0;         /* [vector] brightness: multiplies every vector's brightness */

static void ph_replay(void)
{
    double now = plat_now_ms();
    int i;

    beam_clear();
    for (i = 0; i < PH_FRAMES; i++) {
        int idx = (ph_cur + 1 + i) % PH_FRAMES;            /* oldest first */
        ph_frame *f = &ph_buf[idx];
        double fac;
        int k;

        if (!f->used || idx == ph_fill) continue;
        if (idx == ph_cur) fac = 1.0;
        else if (ph_tau <= 0.0) continue;
        else {
            fac = exp(-(now - f->t) / ph_tau);
            if (fac < PH_FLOOR) continue;
        }
        for (k = 0; k < f->n; k++) {
            const ph_seg *s = &f->seg[k];
            double b = (double)s->intensity / 255.0 * fac * gamma_gain;
            int r, gg, bl;
            if (b > 1.0) b = 1.0;
            r = (int)(RGB_RED(s->rgb) * b + 0.5);
            gg = (int)(RGB_GREEN(s->rgb) * b + 0.5);
            bl = (int)(RGB_BLUE(s->rgb) * b + 0.5);
            if (r <= 0 && gg <= 0 && bl <= 0) continue;
            beam_add_line(s->x0, s->y0, s->x1, s->y1, 0xFF, MAKE_RGB(r, gg, bl));
        }
    }
    beam_draw_all(beam_proj);
}

static void present_now(void)
{
    glClearColor(0.0f, 0.0f, 0.0f, 1.0f);
    glClear(GL_COLOR_BUFFER_BIT);
    ph_replay();
    glSwap();
    present_pending = 0;
    n_swaps++;
}

/* ------------------------------------------------------------------ */
/* window procedure                                                    */
/* ------------------------------------------------------------------ */

static int test_latch, diag_latch, sndtest_latch;

static LRESULT CALLBACK WndProc(HWND hwnd, UINT message, WPARAM wParam, LPARAM lParam)
{
    switch (message) {
    case WM_SIZE:
        if (wParam != SIZE_MINIMIZED) {
            SCREEN_W = LOWORD(lParam);
            SCREEN_H = HIWORD(lParam);
            ViewOrthoScaled(SCREEN_W, SCREEN_H, DESIGN_W, DESIGN_H);
            update_beam_width();
            present_pending = 1;
            apply_capture();
        }
        return 0;

    case WM_MOVE:
        apply_capture();
        return 0;

    case WM_DPICHANGED: {
        const RECT *suggested = (const RECT *)lParam;
        SetWindowPos(hwnd, NULL, suggested->left, suggested->top,
                     suggested->right - suggested->left, suggested->bottom - suggested->top,
                     SWP_NOZORDER | SWP_NOACTIVATE);
        return 0;
    }

    case WM_ACTIVATE:
        window_active = LOWORD(wParam) != WA_INACTIVE;
        if (!window_active) memset(key, 0, sizeof key);
        apply_capture();
        return 0;

    case WM_SYSKEYDOWN:
        if (wParam == VK_RETURN && (lParam & (1 << 29))) {
            ToggleFullscreen();
            key[KEY_ENTER] = 0;
            return 0;
        }
        return DefWindowProc(hwnd, message, wParam, lParam);

    case WM_ERASEBKGND:
        return 1;

    case WM_PAINT:
        ValidateRect(hwnd, NULL);
        present_pending = 1;
        return 0;

    case WM_SYSCOMMAND:
        if ((wParam & 0xFFF0) == SC_KEYMENU) return 0;        /* Alt is a trigger: no window menu */
        return DefWindowProc(hwnd, message, wParam, lParam);

    case WM_SETCURSOR:
        if (LOWORD(lParam) == HTCLIENT && (is_fullscreen || (capture_enabled && window_active))) {
            SetCursor(NULL);
            return 1;
        }
        return DefWindowProc(hwnd, message, wParam, lParam);

    case WM_CLOSE:
        g_quit = 1;
        return 0;

    case WM_INPUT:
        RawInput_ProcessInput(hwnd, wParam, lParam);
        return DefWindowProc(hwnd, message, wParam, lParam);

    case WM_DEVICECHANGE:
        joystick_device_change();
        return DefWindowProc(hwnd, message, wParam, lParam);

    case WM_DESTROY:
        return 0;

    case WM_KEYDOWN:
        if (lParam & (1 << 30)) return 0;                     /* auto-repeat */
        if (wParam == VK_ESCAPE) { g_quit = 1; return 0; }
        if (wParam == VK_F2) {
            test_latch = !test_latch;
            LOG_INFO("self-test switch %s (F2)", test_latch ? "CLOSED" : "open");
            set_window_title(test_latch ? APP_NAME "  self-test switch ON: statistics (7 = options) in the attract mode; "
                                                   "the self test after a reset"
                                        : APP_NAME "  self-test switch off");
        }
        if (wParam == VK_F1) {
            diag_latch = !diag_latch;
            LOG_INFO("diagnostic switch %s (F1)", diag_latch ? "CLOSED" : "open");
        }
        if (wParam == VK_F4) {
            sndtest_latch = !sndtest_latch;
            LOG_INFO("sound board test switch %s (F4)", sndtest_latch ? "CLOSED" : "open");
            set_window_title(sndtest_latch ? APP_NAME "  sound board test switch ON: it plays every sound in turn"
                                           : APP_NAME "  sound board test switch off");
        }
        if (wParam == VK_F8) {
            capture_enabled = !capture_enabled;
            apply_capture();
        }
        return 0;

    default:
        return DefWindowProc(hwnd, message, wParam, lParam);
    }
}

static void pump_messages(void)
{
    MSG msg;
    while (PeekMessage(&msg, NULL, 0, 0, PM_REMOVE)) {
        if (msg.message == WM_QUIT) { g_quit = 1; break; }
        TranslateMessage(&msg);
        DispatchMessage(&msg);
    }
}

/* ------------------------------------------------------------------ */
/* lifecycle                                                           */
/* ------------------------------------------------------------------ */

static int   pokey_volume = 100, speech_volume = 100, master_volume = 100;
static int   audio_prime_blocks = 6;
static float mouse_sens = 0.25f;          /* [input] mouse_sensitivity: A-to-D counts per mickey */
static float key_rate = 400.0f;           /* [input] key_rate: counts per second on the arrow keys */
static int   invert_pitch;

static int plat_init(void)
{
    WNDCLASS wc;
    DWORD dwStyle;
    RECT wr = { 0, 0, 960, 720 };
    HINSTANCE hInstance = GetModuleHandle(NULL);
    int i;

    resolve_paths();
    if (nv_override[0]) snprintf(path_nv, sizeof path_nv, "%s", nv_override);
    log_open(path_log);
    log_set_level(LOG_LEVEL_INFO);
    LOG_INFO("starting%s%s", turbo ? " (turbo: no pacing, no audio, hidden)" : "",
             hidden_mode ? " (hidden)" : "");

    for (i = 0; i < PH_FRAMES; i++) {
        ph_buf[i].seg = (ph_seg *)malloc(sizeof(ph_seg) * PH_SEGS);
        if (!ph_buf[i].seg) return 1;
    }

    enable_dpi_awareness();

    memset(&wc, 0, sizeof wc);
    wc.style = CS_OWNDC;
    wc.lpfnWndProc = WndProc;
    wc.hInstance = hInstance;
    wc.hIcon = LoadIcon(NULL, IDI_APPLICATION);
    wc.hCursor = LoadCursor(NULL, IDC_ARROW);
    wc.hbrBackground = (HBRUSH)GetStockObject(BLACK_BRUSH);
    wc.lpszClassName = L"StarWarsWin";
    if (!RegisterClass(&wc)) { msg_box(APP_NAME, "Failed to register the window class."); return 1; }

    dwStyle = WS_CAPTION | WS_POPUPWINDOW | WS_CLIPSIBLINGS
            | WS_CLIPCHILDREN | WS_SYSMENU | WS_MINIMIZEBOX | WS_MAXIMIZEBOX | WS_THICKFRAME;
    AdjustWindowRect(&wr, dwStyle, FALSE);
    hWnd = CreateWindow(L"StarWarsWin", L"Star Wars", dwStyle,
                        CW_USEDEFAULT, CW_USEDEFAULT, wr.right - wr.left, wr.bottom - wr.top,
                        NULL, NULL, hInstance, NULL);
    if (!hWnd) { msg_box(APP_NAME, "Failed to create the main window."); return 1; }
    size_window_for_dpi(hWnd, window_dpi(hWnd), dwStyle);

    set_config_file(path_ini);

    {
        char *s = get_config_string("main", "rom_dir", "..\\disasm\\build");
        if (s && s[0] && (s[1] == ':' || s[0] == '\\')) snprintf(path_roms, sizeof path_roms, "%s", s);
        else snprintf(path_roms, sizeof path_roms, "%s%s", exe_dir, s ? s : "..\\disasm\\build");
        set_config_string("main", "rom_dir", s ? s : "..\\disasm\\build");
        if (s) free(s);
        if (romdir_cli[0]) snprintf(path_roms, sizeof path_roms, "%s", romdir_cli);
    }
    swap_mode = get_config_int("main", "vsync", 0);
    set_config_int("main", "vsync", swap_mode);

    dsw0 = (uint8_t)get_config_int("dips", "dsw0", 0x84);
    dsw1 = (uint8_t)get_config_int("dips", "dsw1", 0x02);
    set_config_int("dips", "dsw0", dsw0);
    set_config_int("dips", "dsw1", dsw1);

    ph_tau = (double)get_config_float("vector", "phosphor_ms", 0.0f);
    set_config_float("vector", "phosphor_ms", (float)ph_tau);
    gamma_gain = (double)get_config_float("vector", "brightness", 1.6f);
    set_config_float("vector", "brightness", (float)gamma_gain);

    mouse_sens = get_config_float("input", "mouse_sensitivity", 0.25f);
    set_config_float("input", "mouse_sensitivity", mouse_sens);
    key_rate = get_config_float("input", "key_rate", 400.0f);
    set_config_float("input", "key_rate", key_rate);
    invert_pitch = get_config_int("input", "invert_pitch", 0) != 0;
    set_config_int("input", "invert_pitch", invert_pitch);
    capture_enabled = get_config_int("input", "mouse_capture", 1) != 0;
    set_config_int("input", "mouse_capture", capture_enabled);

    if (FAILED(RawInput_Initialize(hWnd))) LOG_ERROR("RawInput_Initialize failed");
    install_joystick();

    master_volume = get_config_int("sound", "volume", 100);
    pokey_volume = get_config_int("sound", "pokey_volume", 100);
    speech_volume = get_config_int("sound", "speech_volume", 100);
    audio_prime_blocks = get_config_int("sound", "latency_blocks", 6);
    if (audio_prime_blocks < 1) audio_prime_blocks = 1;
    if (audio_prime_blocks > 8) audio_prime_blocks = 8;
    set_config_int("sound", "volume", master_volume);
    set_config_int("sound", "pokey_volume", pokey_volume);
    set_config_int("sound", "speech_volume", speech_volume);
    set_config_int("sound", "latency_blocks", audio_prime_blocks);
    if (!turbo && master_volume > 0) {
        if (mixer_init() != 0) LOG_ERROR("mixer_init failed; continuing without audio");
        stream_set_prime_blocks(audio_prime_blocks);
    }

    if (!CreateGLContext()) { msg_box(APP_NAME, "Failed to create an OpenGL context."); return 1; }
    swap_mode = SetSwapMode(turbo ? 0 : swap_mode);
    ViewOrthoScaled(SCREEN_W, SCREEN_H, DESIGN_W, DESIGN_H);

    beam_px = get_config_float("vector", "linewidth", 2.0f);
    beam_feather_px = get_config_float("vector", "line_smoothing", 1.0f);
    if (beam_px < 0.1f) beam_px = 0.1f;
    if (beam_feather_px < 0.0f) beam_feather_px = 0.0f;
    set_config_float("vector", "linewidth", beam_px);
    set_config_float("vector", "line_smoothing", beam_feather_px);

    if (!beam_init()) {
        msg_box(APP_NAME, "Beam renderer failed to build (needs OpenGL 3.3) - see the .log next to the exe.");
        return 1;
    }
    beam_set_color_mode(1);
    update_beam_width();
    mat4_ortho(beam_proj, -PIC_HW, PIC_HW, -PIC_HH, PIC_HH, -1.0f, 1.0f);

    timeBeginPeriod(1);

    if (!turbo && !hidden_mode) {
        set_window_title(APP_NAME " - " KEY_HELP);
        ShowWindow(hWnd, SW_SHOW);
        SetForegroundWindow(hWnd);
        window_active = GetForegroundWindow() == hWnd;
        apply_capture();
    }
    return 0;
}

static void plat_shutdown(void)
{
    ClipCursor(NULL);
    timeEndPeriod(1);
    beam_shutdown();
    remove_joystick();
    mixer_end();
    DeleteGLContext();
    LOG_INFO("closing");
    log_close();
    if (IsWindow(hWnd)) DestroyWindow(hWnd);
}

/* ------------------------------------------------------------------ */
/* video                                                               */
/* ------------------------------------------------------------------ */

void plat_video_begin(void)
{
    ph_fill = (ph_cur + 1) % PH_FRAMES;
    ph_buf[ph_fill].n = 0;
    ph_buf[ph_fill].used = 1;
}

void plat_video_line(float x0, float y0, float x1, float y1, uint32_t rgb, int intensity)
{
    ph_frame *f;
    ph_seg *s;
    if (ph_fill < 0) return;
    seg_total++;
    if (!clip_seg(&x0, &y0, &x1, &y1)) { seg_clipped++; return; }
    f = &ph_buf[ph_fill];
    if (f->n >= PH_SEGS) return;
    s = &f->seg[f->n++];
    xform_point(x0, y0, &s->x0, &s->y0);
    xform_point(x1, y1, &s->x1, &s->y1);
    s->rgb = rgb;
    s->intensity = intensity < 0 ? 0 : intensity > 255 ? 255 : intensity;
}

void plat_video_present(void)
{
    if (ph_fill < 0) return;
    ph_buf[ph_fill].t = plat_now_ms();
    last_nsegs = ph_buf[ph_fill].n;
    ph_cur = ph_fill;
    ph_fill = -1;
    n_frames_in++;
    present_pending = 1;
    if (!turbo && !hidden_mode && hWnd) present_now();
}

/* ---- --shot: the newest picture through the same beam path into an
 * offscreen framebuffer, saved as .png ---- */
static int save_shot(const char *path)
{
    GLuint fbo = 0, rb = 0;
    uint8_t *buf;
    int rc = 1;

    buf = (uint8_t *)malloc((size_t)shot_w * (size_t)shot_h * 3u);
    if (!buf) return 1;
    glGenFramebuffers(1, &fbo);
    glBindFramebuffer(GL_FRAMEBUFFER, fbo);
    glGenRenderbuffers(1, &rb);
    glBindRenderbuffer(GL_RENDERBUFFER, rb);
    glRenderbufferStorage(GL_RENDERBUFFER, GL_RGBA8, shot_w, shot_h);
    glFramebufferRenderbuffer(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_RENDERBUFFER, rb);
    if (glCheckFramebufferStatus(GL_FRAMEBUFFER) != GL_FRAMEBUFFER_COMPLETE) {
        LOG_ERROR("shot: framebuffer incomplete");
    } else {
        size_t png_len = 0;
        void *png;
        glViewport(0, 0, shot_w, shot_h);
        update_beam_width_for((double)shot_w);
        glClearColor(0.0f, 0.0f, 0.0f, 1.0f);
        glClear(GL_COLOR_BUFFER_BIT);
        ph_replay();
        glFinish();
        glPixelStorei(GL_PACK_ALIGNMENT, 1);
        glReadPixels(0, 0, shot_w, shot_h, GL_RGB, GL_UNSIGNED_BYTE, buf);
        png = tdefl_write_image_to_png_file_in_memory_ex(buf, shot_w, shot_h, 3, &png_len, 6, MZ_TRUE);
        if (png) {
            FILE *f = fopen(path, "wb");
            if (f) { rc = fwrite(png, 1, png_len, f) == png_len ? 0 : 1; fclose(f); }
            free(png);
        }
    }
    glBindFramebuffer(GL_FRAMEBUFFER, 0);
    glDeleteRenderbuffers(1, &rb);
    glDeleteFramebuffers(1, &fbo);
    ViewOrthoScaled(SCREEN_W, SCREEN_H, DESIGN_W, DESIGN_H);
    update_beam_width();
    free(buf);
    return rc;
}

/* ------------------------------------------------------------------ */
/* input                                                               */
/* ------------------------------------------------------------------ */

static double yoke_x = 128.0, yoke_y = 128.0;       /* the yoke, in A-to-D counts */
static double key_x, key_y;                         /* the arrow keys' deflection, sprung */
static double input_last_ms;

void plat_input_poll(plat_inputs *in)
{
    double now = plat_now_ms(), dt;
    int mx = 0, my = 0;
    double x, y;

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

    get_mouse_mickeys(&mx, &my);
    if (window_active) {
        yoke_x += (double)mx * mouse_sens;
        yoke_y += (double)my * mouse_sens * (invert_pitch ? -1.0 : 1.0);
        if (yoke_x < 0.0) yoke_x = 0.0;
        if (yoke_x > 255.0) yoke_x = 255.0;
        if (yoke_y < 0.0) yoke_y = 0.0;
        if (yoke_y > 255.0) yoke_y = 255.0;

        in->fire_r  = (key[KEY_LCONTROL] || (mouse_b & 1)) ? 1 : 0;
        in->fire_l  = (key[KEY_ALT] || (mouse_b & 2)) ? 1 : 0;
        in->thumb_r = key[KEY_SPACE] ? 1 : 0;
        in->thumb_l = (key[KEY_LSHIFT] || key[KEY_RSHIFT]) ? 1 : 0;
        in->coin_l  = key[KEY_5] ? 1 : 0;
        in->coin_r  = key[KEY_6] ? 1 : 0;
        in->coin_aux = key[KEY_7] ? 1 : 0;
        in->slam    = key[KEY_F3] ? 1 : 0;

        /* arrow keys: a deflection that builds while held and springs back */
        {
            double step = key_rate * dt / 1000.0;
            double tx = (key[KEY_RIGHT] ? 1.0 : 0.0) - (key[KEY_LEFT] ? 1.0 : 0.0);
            double ty = (key[KEY_DOWN] ? 1.0 : 0.0) - (key[KEY_UP] ? 1.0 : 0.0);
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
    }
    x = yoke_x + key_x;
    y = yoke_y + key_y;

    poll_joystick();
    if (num_joysticks > 0 && joystick_is_connected(0)) {
        x += (double)joy_x;
        y += (double)joy_y * (invert_pitch ? -1.0 : 1.0);
        if (joy[0].num_buttons > 0 && joy[0].button[0].b) in->fire_r = 1;
        if (joy[0].num_buttons > 1 && joy[0].button[1].b) in->fire_l = 1;
        if (joy[0].num_buttons > 2 && joy[0].button[2].b) in->thumb_r = 1;
        if (joy[0].num_buttons > 3 && joy[0].button[3].b) in->thumb_l = 1;
        if (joy[0].num_buttons > 6 && joy[0].button[6].b) in->coin_l = 1;
    }
    if (x < 0.0) x = 0.0;
    if (x > 255.0) x = 255.0;
    if (y < 0.0) y = 0.0;
    if (y > 255.0) y = 255.0;
    in->yaw = (uint8_t)x;
    in->pitch = (uint8_t)y;
    if (key[KEY_ESC]) g_quit = 1;
    in->quit = (uint8_t)g_quit;
}

/* ------------------------------------------------------------------ */
/* audio, time, storage                                                */
/* ------------------------------------------------------------------ */

static int audio_open_ok, audio_peak;
static unsigned long audio_frames, audio_clipped;
static FILE *wav_file;                  /* --wav FILE: everything pushed, 16-bit mono */

static void wav_header(FILE *f, unsigned long frames)
{
    uint8_t h[44];
    unsigned long bytes = frames * 2ul, rate = SW_AUDIO_RATE, fmt = 16ul;
    #define PUT32(o, v) do { h[o] = (uint8_t)(v); h[o+1] = (uint8_t)((v) >> 8); h[o+2] = (uint8_t)((v) >> 16); h[o+3] = (uint8_t)((v) >> 24); } while (0)
    memcpy(h, "RIFF", 4); PUT32(4, 36ul + bytes); memcpy(h + 8, "WAVEfmt ", 8);
    PUT32(16, fmt); h[20] = 1; h[21] = 0; h[22] = 1; h[23] = 0;
    PUT32(24, rate); PUT32(28, rate * 2ul);
    h[32] = 2; h[33] = 0; h[34] = 16; h[35] = 0;
    memcpy(h + 36, "data", 4); PUT32(40, bytes);
    #undef PUT32
    fseek(f, 0, SEEK_SET);
    fwrite(h, 1, sizeof h, f);
}

int plat_audio_open(int sample_rate)
{
    if (turbo || master_volume <= 0) return -1;
    if (stream_open(sample_rate, 1) != 0) {
        LOG_ERROR("audio: stream_open(%d Hz mono) failed; no sound", sample_rate);
        return -1;
    }
    stream_set_volume(hidden_mode ? 0 : mixer_percent_to_byte(master_volume));
    audio_open_ok = 1;
    return 0;
}

void plat_audio_push(const int16_t *pcm, int frames)
{
    int i;
    for (i = 0; i < frames; i++) {
        int v = pcm[i] < 0 ? -(int)pcm[i] : (int)pcm[i];
        if (v > audio_peak) audio_peak = v;
        if (v >= 32767) audio_clipped++;
    }
    if (wav_file) fwrite(pcm, 2, (size_t)frames, wav_file);
    audio_frames += (unsigned long)frames;
    if (audio_open_ok) stream_push(pcm, frames);
}

void plat_audio_close(void)
{
    stream_close();
    audio_open_ok = 0;
}

double plat_now_ms(void)
{
    LARGE_INTEGER cnt;
    static LARGE_INTEGER freq;
    if (!freq.QuadPart) QueryPerformanceFrequency(&freq);
    QueryPerformanceCounter(&cnt);
    return (double)cnt.QuadPart * 1000.0 / (double)freq.QuadPart;
}

int plat_nvram_read(void *buf, unsigned len)
{
    size_t got;
    FILE *f;
    if (no_nvram) return 1;
    f = fopen(path_nv, "rb");
    if (!f) { LOG_INFO("NOVRAM: no %s, a blank chip", path_nv); return 1; }
    got = fread(buf, 1, len, f);
    fclose(f);
    LOG_INFO("NOVRAM: read %s (%u bytes)", path_nv, (unsigned)got);
    return got == len ? 0 : 1;
}

int plat_nvram_write(const void *buf, unsigned len)
{
    FILE *f;
    if (no_nvram) return 0;
    f = fopen(path_nv, "wb");
    if (!f) { LOG_ERROR("NOVRAM: cannot write %s", path_nv); return 1; }
    fwrite(buf, 1, len, f);
    fclose(f);
    LOG_INFO("NOVRAM: wrote %s", path_nv);
    return 0;
}

void plat_log(const char *text) { LOG_INFO("%s", text); }

/* ------------------------------------------------------------------ */
/* main                                                                */
/* ------------------------------------------------------------------ */

static int parse_args(void)
{
    int i;
    for (i = 1; i < __argc; i++) {
        const char *a = __argv[i];
        if (!strcmp(a, "--shot") && i + 2 < __argc && n_shots < MAX_SHOTS) {
            shots[n_shots].by_picture = __argv[i + 1][0] == 'p';
            shots[n_shots].pass = strtoul(__argv[i + 1] + shots[n_shots].by_picture, NULL, 0);
            snprintf(shots[n_shots].path, sizeof shots[n_shots].path, "%s", __argv[i + 2]);
            n_shots++;
            i += 2;
        } else if (!strcmp(a, "--shot-size") && i + 1 < __argc) {
            if (sscanf(__argv[++i], "%dx%d", &shot_w, &shot_h) != 2 || shot_w < 16 || shot_h < 16) { shot_w = 960; shot_h = 720; }
        } else if (!strcmp(a, "--rev") && i + 1 < __argc) rev_cli = atoi(__argv[++i]);
        else if (!strcmp(a, "--romdir") && i + 1 < __argc) snprintf(romdir_cli, sizeof romdir_cli, "%s", __argv[++i]);
        else if (!strcmp(a, "--script") && i + 1 < __argc) snprintf(script_path, sizeof script_path, "%s", __argv[++i]);
        else if (!strcmp(a, "--stats") && i + 1 < __argc) snprintf(stats_path, sizeof stats_path, "%s", __argv[++i]);
        else if (!strcmp(a, "--wav") && i + 1 < __argc) {
            wav_file = fopen(__argv[++i], "wb");
            if (wav_file) wav_header(wav_file, 0);
        }
        else if (!strcmp(a, "--turbo")) turbo = 1;
        else if (!strcmp(a, "--hidden")) hidden_mode = 1;
        else if (!strcmp(a, "--test")) test_cli = 1;
        else if (!strcmp(a, "--no-nvram")) no_nvram = 1;
        else if (!strcmp(a, "--nvram") && i + 1 < __argc) snprintf(nv_override, sizeof nv_override, "%s", __argv[++i]);
        else if (!strcmp(a, "--quit-after-ms") && i + 1 < __argc) quit_after_ms = atof(__argv[++i]);
        else if (!strcmp(a, "--passes") && i + 1 < __argc) quit_after_passes = strtoul(__argv[++i], NULL, 0);
        else return 1;
    }
    if (n_shots > 0) turbo = 1;
    if ((turbo || hidden_mode || script_path[0]) && !nv_override[0]) no_nvram = 1;
    for (i = 1; i < n_shots; i++) {
        int j = i;
        while (j > 0 && shots[j - 1].by_picture == shots[j].by_picture && shots[j - 1].pass > shots[j].pass) {
            shot_req t = shots[j]; shots[j] = shots[j - 1]; shots[j - 1] = t;
            j--;
        }
    }
    return 0;
}

int WINAPI WinMain(HINSTANCE hInstance, HINSTANCE hPrevInstance, LPSTR lpCmdLine, int iCmdShow)
{
    sw_app_opts o;
    sw_app_stats st, st0;
    double t_start, stat_t;
    unsigned long frames0 = 0;
    (void)hInstance; (void)hPrevInstance; (void)lpCmdLine; (void)iCmdShow;

    if (parse_args()) {
        MessageBoxA(NULL,
            "usage: [--rev 1|2] [--romdir DIR] [--test]\n"
            "                  [--nvram FILE] [--no-nvram]\n"
            "  testing:        [--script FILE] [--passes N] [--quit-after-ms MS] [--turbo] [--hidden]\n"
            "                  [--shot PASS FILE.png]... [--shot-size WxH] [--stats FILE] [--wav FILE]",
            APP_NAME, MB_OK);
        return 2;
    }
    if (plat_init()) { log_close(); return 1; }

    memset(&o, 0, sizeof o);
    o.rev = rev_cli == 1 ? 1 : 2;
    o.rom_dir = path_roms;
    o.script = script_path[0] ? script_path : NULL;
    o.turbo = turbo;
    o.pokey_volume = pokey_volume;
    o.speech_volume = speech_volume;
    LOG_INFO("machine: %s, ROM revision %d, images in %s", sw_app_name(), o.rev, path_roms);
    if (sw_app_init(&o)) {
        msg_box(APP_NAME, sw_app_error());
        plat_shutdown();
        return 1;
    }

    t_start = stat_t = plat_now_ms();
    sw_app_get_stats(&st0);

    while (!g_quit) {
        double now;
        if (!turbo) pump_messages();
        if (g_quit) break;
        now = plat_now_ms();
        sw_app_run(now);
        sw_app_get_stats(&st);

        while (shots_done < n_shots && (shots[shots_done].by_picture ? st.pictures : st.passes) >= shots[shots_done].pass) {
            int rc = save_shot(shots[shots_done].path);
            LOG_INFO("shot: pass %lu (PHASE $%02X, %d vectors) -> %s %s", st.passes, st.phase, last_nsegs,
                     shots[shots_done].path, rc ? "FAILED" : "ok");
            shots_done++;
        }
        if (n_shots > 0 && shots_done >= n_shots && !quit_after_passes) g_quit = 1;
        if (quit_after_passes && st.passes >= quit_after_passes) g_quit = 1;
        if (st.script_ended) g_quit = 1;
        if (quit_after_ms > 0.0 && now - t_start >= quit_after_ms) g_quit = 1;

        if (!turbo) {
            if (present_pending && hWnd && !hidden_mode) present_now();
            if (now - stat_t >= 1000.0) {
                char s[400];
                double dt = (now - stat_t) / 1000.0;
                snprintf(s, sizeof s, APP_NAME " (%s)  %.1f pictures/s  machine/wall %.3f  %.1f passes/s  %.1f IRQ/s  "
                         "%d vectors  PHASE $%02X%s%s",
                         sw_app_name(),
                         (double)(n_frames_in - frames0) / dt, (double)(st.cycles - st0.cycles) / 1512000.0 / dt,
                         (double)(st.passes - st0.passes) / dt, (double)(st.irqs - st0.irqs) / dt, st.points, st.phase,
                         test_latch ? "  SELF TEST SWITCH ON" : "", sndtest_latch ? "  SOUND TEST ON" : "");
                if (!hidden_mode) set_window_title(s);
                stat_t = now;
                st0 = st;
                frames0 = n_frames_in;
            }
            Sleep(1);
        }
    }

    sw_app_get_stats(&st);
    {
        double wall = (plat_now_ms() - t_start) / 1000.0;
        char s[700];
        snprintf(s, sizeof s,
                 "machine %s\npasses %lu\ncycles %llu\nseconds %.3f\nwall %.3f\npictures %lu\nirqs %lu\nirqs_lost %lu\n"
                 "resets %lu\nwatchdog_bites %lu\nsound_resets %lu\nswi %lu\nphase %02X\nvectors %lu\nvectors_clipped %lu\n"
                 "audio_frames %lu\naudio_peak %d\naudio_clipped %lu\n",
                 sw_app_name(), st.passes, (unsigned long long)st.cycles, (double)st.cycles / 1512000.0, wall,
                 st.pictures, st.irqs, st.irqs_lost, st.resets, st.watchdog_bites, st.snd_resets, st.swi, st.phase,
                 seg_total, seg_clipped, audio_frames, audio_peak, audio_clipped);
        if (wav_file) { wav_header(wav_file, audio_frames); fclose(wav_file); }
        LOG_INFO("exit:\n%s", s);
        if (stats_path[0]) {
            FILE *f = fopen(stats_path, "w");
            if (f) { fputs(s, f); fclose(f); }
        }
    }
    sw_app_exit();
    plat_shutdown();
    return 0;
}
