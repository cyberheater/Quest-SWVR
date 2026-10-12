/* plat_openxr.cpp - the Star Wars host in a headset: OpenXR + OpenGL, with
 * SDL2 for the window, the sound and the keys.  Windows (a Quest over Quest
 * Link or Air Link, or any PC headset whose OpenXR runtime takes OpenGL).
 *
 * The same contract as platform/sdl/plat_sdl.cpp (../sw_platform.h).  The
 * machine is asked for its 3-D lines always (plat_video_3d), and each picture
 * is kept as two lists: the world, in the game's viewer space, and the HUD, on
 * the tube.  Every headset frame draws the last picture again for each eye
 * from where the head is now, so the head moves at the headset's rate while
 * the game makes pictures at its own.
 *
 * The cockpit: the game's camera is where the head was when the view was last
 * centred (at the start, and on Home / B / Y), looking the way the head faced.
 * A point (x ahead, y right, z up) of the game is unit_metres * (y, z, -x) in
 * front of it.  The HUD - scores, messages, the sight, the cockpit - is drawn
 * on a panel hud_distance ahead, at the size at which a point of it covers
 * the world exactly as it does on the tube, so the sight stays on what the
 * guns hit.
 *
 * Controls in the headset (Touch controllers): the two controllers are the
 * yoke's two handles.  Held level side by side they are the yoke at rest;
 * turned like a steering wheel (one hand up, the other down) they are the
 * yoke turned, and both tilted forward or back they are its handles tilted.
 * The triggers are the triggers, the grips the thumb buttons, A or X a coin,
 * B or Y centres the view and takes the handles' tilt now as the yoke's rest.
 * The thumbsticks move the yoke too.  F9 (or [vr] aim) steps through yoke,
 * point (the right controller alone: point it where the sight should go) and
 * stick (the thumbsticks only).  The mouse, the
 * keys and a game controller work as in sw_sdl while the window has the focus.
 * PageUp / PageDown change unit_metres, F10 moves the HUD panel.
 *
 * --flat runs without a headset: one eye at the cockpit's own camera, in the
 * window.  The window shows the left eye otherwise.
 *
 * Paths: the executable's own folder holds sw_xr.ini, sw_xr.log and
 * starwars.nv; the ROM images are read from <exe>/../disasm/build unless
 * [main] rom_dir or --romdir say otherwise.
 */
#ifndef _WIN32
#error "plat_openxr.cpp: the OpenGL session binding here is the Win32 one"
#endif
#define WIN32_LEAN_AND_MEAN
#define NOMINMAX
#include <windows.h>
#include <unknwn.h>
#include "../windows/glew.h"
#define SDL_MAIN_HANDLED
#include <SDL.h>
#define XR_USE_PLATFORM_WIN32
#define XR_USE_GRAPHICS_API_OPENGL
#include <openxr/openxr.h>
#include <openxr/openxr_platform.h>
#include <algorithm>
#include <cmath>
#include <cstdarg>
#include <cstdio>
#include <cstdlib>
#include <cstring>
#include <string>
#include <vector>
#include "../sw_platform.h"

#define APP_NAME "Star Wars VR"

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

static int      turbo, hidden_mode, no_nvram, test_cli, rev_cli = 2, flat;
static double   quit_after_ms;
static unsigned long quit_after_passes;
static std::string nv_override, script_path, romdir_cli;

/* the cockpit in the room */
static float unit_metres = 0.02f;     /* one of the game's units */
static float hud_distance = 3.0f;     /* the HUD panel, metres ahead */
static float hud_scale = 1.0f;        /* 1: the HUD covers the world as on the tube */
enum { AIM_YOKE, AIM_POINT, AIM_STICK };
static const char *const aim_names[] = { "yoke", "point", "stick" };
static int   aim_mode = AIM_YOKE;     /* what the controllers' poses do */
static float aim_range = 30.0f;       /* point: degrees off straight ahead for the yoke's full travel */
static float yoke_turn = 40.0f;       /* yoke: degrees of turn, and of tilt, for its full travel */
static float yoke_tilt = 30.0f;

static int parse_args(int argc, char **argv)
{
    for (int i = 1; i < argc; i++) {
        const char *a = argv[i];
        if (!strcmp(a, "--rev") && i + 1 < argc) rev_cli = atoi(argv[++i]);
        else if (!strcmp(a, "--romdir") && i + 1 < argc) romdir_cli = argv[++i];
        else if (!strcmp(a, "--script") && i + 1 < argc) script_path = argv[++i];
        else if (!strcmp(a, "--turbo")) turbo = 1;
        else if (!strcmp(a, "--hidden")) hidden_mode = 1;
        else if (!strcmp(a, "--test")) test_cli = 1;
        else if (!strcmp(a, "--flat")) flat = 1;
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
/* video: the picture, kept as the machine sent it                     */
/* ------------------------------------------------------------------ */

static SDL_Window   *win;
static SDL_GLContext glctx;
static GLuint prog, vao, vbo, fbo;
static float  brightness = 1.6f, linewidth = 2.0f;

struct seg  { float x0, y0, x1, y1; uint32_t rgb; int in; };
struct seg3 { float a[3], b[3]; uint32_t rgb; int in; };
static std::vector<seg>  building, shown;
static std::vector<seg3> building3, shown3;
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
    glewExperimental = GL_TRUE;
    if (glewInit() != GLEW_OK) { logf("OpenGL: the functions could not be loaded"); return 1; }
    while (glGetError() != GL_NO_ERROR) { }
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
    glGenFramebuffers(1, &fbo);
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

void plat_video_begin(void) { building.clear(); building3.clear(); }

int plat_video_3d(void) { return 1; }

void plat_video_line(float x0, float y0, float x1, float y1, uint32_t rgb, int intensity)
{
    building.push_back({ x0, y0, x1, y1, rgb, intensity });
}

void plat_video_line3(const float a[3], const float b[3], uint32_t rgb, int intensity)
{
    building3.push_back({ { a[0], a[1], a[2] }, { b[0], b[1], b[2] }, rgb, intensity });
}

void plat_video_present(void)
{
    shown.swap(building);
    shown3.swap(building3);
    present_pending = 1;
    n_pictures++;
}

/* ------------------------------------------------------------------ */
/* video: one eye                                                      */
/* ------------------------------------------------------------------ */
/* An eye: cockpit space (metres; x right, y up, z back, as OpenXR has it) to
 * the eye's own space by m and t, and the tangents of its four field-of-view
 * angles (left and down negative). */
struct eye_xf {
    float m[3][3], t[3];
    float tl, tr, tu, td;
    int   w, h;
};

/* The cockpit's own camera: the tube's window on the world, exactly. */
static eye_xf tube_eye(int w, int h)
{
    eye_xf E = { { { 1, 0, 0 }, { 0, 1, 0 }, { 0, 0, 1 } }, { 0, 0, 0 },
                 -SW_PROJ_X0 / SW_PROJ_XK, (250.0f - SW_PROJ_X0) / SW_PROJ_XK,
                 SW_PROJ_Y0 / SW_PROJ_YK, -(280.0f - SW_PROJ_Y0) / SW_PROJ_YK, w, h };
    return E;
}

static std::vector<float> verts;

/* The picture's lines as this eye sees them, into the bound framebuffer's
 * (0, 0, E.w, E.h). */
static void draw_eye(const eye_xf &E)
{
    const float CLIP = 0.05f;                       /* metres in front of the eye */
    /* half width in NDC, from [vector] linewidth = pixels at a 960-wide tube */
    const float tube_px = (float)E.w * (250.0f / SW_PROJ_XK) / (E.tr - E.tl);
    const float px = std::max(1.0f, linewidth * tube_px / 960.0f);
    const float hx = (px * 0.5f + 1.0f) * 2.0f / (float)E.w;
    const float hy = (px * 0.5f + 1.0f) * 2.0f / (float)E.h;

    verts.clear();
    auto line = [&](const float *ca, const float *cb, uint32_t rgb, int in) {
        float a[3], b[3];
        for (int i = 0; i < 3; i++) {
            a[i] = E.m[i][0] * ca[0] + E.m[i][1] * ca[1] + E.m[i][2] * ca[2] + E.t[i];
            b[i] = E.m[i][0] * cb[0] + E.m[i][1] * cb[1] + E.m[i][2] * cb[2] + E.t[i];
        }
        float da = -a[2], db = -b[2];               /* ahead of the eye */
        if (da < CLIP && db < CLIP) return;
        if (da < CLIP || db < CLIP) {
            float t = (CLIP - da) / (db - da);
            float *n = da < CLIP ? a : b;
            for (int k = 0; k < 3; k++) n[k] = a[k] + (b[k] - a[k]) * t;
            n[2] = -CLIP;
            da = -a[2]; db = -b[2];
        }
        float ax = (2.0f * a[0] / da - (E.tr + E.tl)) / (E.tr - E.tl), ay = (2.0f * a[1] / da - (E.tu + E.td)) / (E.tu - E.td);
        float bx = (2.0f * b[0] / db - (E.tr + E.tl)) / (E.tr - E.tl), by = (2.0f * b[1] / db - (E.tu + E.td)) / (E.tu - E.td);
        /* wholly off one side: most of what is behind a turned head */
        if ((ax < -1.5f && bx < -1.5f) || (ax > 1.5f && bx > 1.5f) || (ay < -1.5f && by < -1.5f) || (ay > 1.5f && by > 1.5f)) return;
        /* direction in pixels, so the width is even whatever the aspect */
        float dx = (bx - ax) / hx, dy = (by - ay) / hy;
        float len = std::sqrt(dx * dx + dy * dy);
        if (len < 1e-4f) { dx = 1.0f; dy = 0.0f; } else { dx /= len; dy /= len; }
        float nx = -dy, ny = dx;
        float r = (rgb & 0xFF) / 255.0f, g = ((rgb >> 8) & 0xFF) / 255.0f, bl = ((rgb >> 16) & 0xFF) / 255.0f;
        float al = (float)in / 255.0f * brightness;
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
            verts.insert(verts.end(), { p[0], p[1], 0.0f, p[3], r, g, bl, al });
        }
    };

    const float S = unit_metres;
    for (auto &s : shown3) {
        float a[3] = { s.a[1] * S, s.a[2] * S, -s.a[0] * S }, b[3] = { s.b[1] * S, s.b[2] * S, -s.b[0] * S };
        line(a, b, s.rgb, s.in);
    }
    const float D = hud_distance, kx = hud_scale * D / SW_PROJ_XK, ky = hud_scale * D / SW_PROJ_YK;
    for (auto &s : shown) {
        float a[3] = { (s.x0 - SW_PROJ_X0) * kx, (SW_PROJ_Y0 - s.y0) * ky, -D };
        float b[3] = { (s.x1 - SW_PROJ_X0) * kx, (SW_PROJ_Y0 - s.y1) * ky, -D };
        line(a, b, s.rgb, s.in);
    }

    glViewport(0, 0, E.w, E.h);
    glDisable(GL_SCISSOR_TEST);
    glDisable(GL_DEPTH_TEST);
    glDisable(GL_FRAMEBUFFER_SRGB);                 /* the tube's values as they are, as in the window */
    glClearColor(0, 0, 0, 1);
    glClear(GL_COLOR_BUFFER_BIT);
    glUseProgram(prog);
    glBindVertexArray(vao);
    glBindBuffer(GL_ARRAY_BUFFER, vbo);
    glEnable(GL_BLEND);
    glBlendFunc(GL_ONE, GL_ONE);
    glBufferData(GL_ARRAY_BUFFER, (GLsizeiptr)(verts.size() * sizeof(float)), verts.data(), GL_STREAM_DRAW);
    glDrawArrays(GL_TRIANGLES, 0, (GLsizei)(verts.size() / 8));
}

/* the largest 4:3 (or w:h) rectangle in the window */
static void fit(int dw, int dh, int w, int h, int *x, int *y, int *vw, int *vh)
{
    *vw = dw; *vh = (int)((int64_t)dw * h / w);
    if (*vh > dh) { *vh = dh; *vw = (int)((int64_t)dh * w / h); }
    *x = (dw - *vw) / 2; *y = (dh - *vh) / 2;
}

/* Without a headset: the cockpit's camera, on the tube's 4:3. */
static void draw_flat(void)
{
    int dw, dh, x, y, vw, vh;
    SDL_GL_GetDrawableSize(win, &dw, &dh);
    fit(dw, dh, 4, 3, &x, &y, &vw, &vh);
    glBindFramebuffer(GL_FRAMEBUFFER, 0);
    glViewport(0, 0, dw, dh);
    glClearColor(0, 0, 0, 1);
    glClear(GL_COLOR_BUFFER_BIT);
    /* an eye's picture of its own size, then into the window */
    static GLuint tex;
    static int tw, th;
    if (!tex || tw != vw || th != vh) {
        if (tex) glDeleteTextures(1, &tex);
        glGenTextures(1, &tex);
        glBindTexture(GL_TEXTURE_2D, tex);
        glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA8, vw, vh, 0, GL_RGBA, GL_UNSIGNED_BYTE, nullptr);
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
        tw = vw; th = vh;
    }
    glBindFramebuffer(GL_FRAMEBUFFER, fbo);
    glFramebufferTexture2D(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_TEXTURE_2D, tex, 0);
    draw_eye(tube_eye(vw, vh));
    glBindFramebuffer(GL_READ_FRAMEBUFFER, fbo);
    glBindFramebuffer(GL_DRAW_FRAMEBUFFER, 0);
    glBlitFramebuffer(0, 0, vw, vh, x, y, x + vw, y + vh, GL_COLOR_BUFFER_BIT, GL_NEAREST);
    glBindFramebuffer(GL_FRAMEBUFFER, 0);
    SDL_GL_SwapWindow(win);
}

/* ------------------------------------------------------------------ */
/* the headset                                                         */
/* ------------------------------------------------------------------ */

static XrInstance xr_inst;
static XrSystemId xr_sys;
static XrSession  xr_sess;
static XrSpace    xr_local, xr_hand_space[2];     /* left, right */
static XrPath     xr_hand_path[2];
static int        xr_running, xr_focused;
static XrViewConfigurationView xr_vcv[2];
struct eye_chain { XrSwapchain sc; int w, h; std::vector<XrSwapchainImageOpenGLKHR> img; };
static eye_chain  xr_eye[2];
static XrActionSet xr_set;
static XrAction    act_yoke, act_fire_r, act_fire_l, act_thumb_r, act_thumb_l, act_coin, act_centre, act_aim;

/* what the controllers say, for plat_input_poll */
static struct {
    float stick_x, stick_y, fire_r, fire_l, thumb_r, thumb_l;
    int   coin, centre;
    int   hand_ok[2];                   /* left, right: pointing and placed */
    float hand_yaw[2], hand_pitch[2];   /* where each points, degrees: right, up, in the cockpit */
    float hand_pos[2][3];               /* where each is, the cockpit's axes */
} xin;
static int   yoke_rest_request = 1;     /* take the handles' tilt now as the yoke's rest */
static float yoke_rest;

/* where the cockpit is in the room: the game's camera, and the way it faces */
static int   centred, centre_request;
static float origin[3], origin_yaw;

static int xr_bad(XrResult r, const char *what)
{
    if (XR_SUCCEEDED(r)) return 0;
    char s[XR_MAX_RESULT_STRING_SIZE] = "";
    if (xr_inst) xrResultToString(xr_inst, r, s);
    logf("OpenXR: %s: %s (%d)", what, s, (int)r);
    return 1;
}

static XrPath xr_path(const char *s)
{
    XrPath p = XR_NULL_PATH;
    xrStringToPath(xr_inst, s, &p);
    return p;
}

static XrAction xr_action(XrActionType type, const char *name, const char *text, int per_hand = 0)
{
    XrActionCreateInfo ci = { XR_TYPE_ACTION_CREATE_INFO };
    XrAction a = XR_NULL_HANDLE;
    ci.actionType = type;
    if (per_hand) { ci.countSubactionPaths = 2; ci.subactionPaths = xr_hand_path; }
    snprintf(ci.actionName, sizeof ci.actionName, "%s", name);
    snprintf(ci.localizedActionName, sizeof ci.localizedActionName, "%s", text);
    xr_bad(xrCreateAction(xr_set, &ci, &a), name);
    return a;
}

static int xr_actions_init(void)
{
    XrActionSetCreateInfo si = { XR_TYPE_ACTION_SET_CREATE_INFO };
    snprintf(si.actionSetName, sizeof si.actionSetName, "cabinet");
    snprintf(si.localizedActionSetName, sizeof si.localizedActionSetName, "Star Wars cabinet");
    if (xr_bad(xrCreateActionSet(xr_inst, &si, &xr_set), "xrCreateActionSet")) return 1;
    xr_hand_path[0] = xr_path("/user/hand/left");
    xr_hand_path[1] = xr_path("/user/hand/right");
    act_yoke    = xr_action(XR_ACTION_TYPE_VECTOR2F_INPUT, "yoke", "Flight yoke");
    act_fire_r  = xr_action(XR_ACTION_TYPE_FLOAT_INPUT, "fire_right", "Right trigger");
    act_fire_l  = xr_action(XR_ACTION_TYPE_FLOAT_INPUT, "fire_left", "Left trigger");
    act_thumb_r = xr_action(XR_ACTION_TYPE_FLOAT_INPUT, "thumb_right", "Right thumb button");
    act_thumb_l = xr_action(XR_ACTION_TYPE_FLOAT_INPUT, "thumb_left", "Left thumb button");
    act_coin    = xr_action(XR_ACTION_TYPE_BOOLEAN_INPUT, "coin", "Insert coin");
    act_centre  = xr_action(XR_ACTION_TYPE_BOOLEAN_INPUT, "centre", "Centre the view");
    act_aim     = xr_action(XR_ACTION_TYPE_POSE_INPUT, "handle", "Yoke handle", 1);

    const XrActionSuggestedBinding b[] = {
        { act_yoke,    xr_path("/user/hand/right/input/thumbstick") },
        { act_yoke,    xr_path("/user/hand/left/input/thumbstick") },
        { act_fire_r,  xr_path("/user/hand/right/input/trigger/value") },
        { act_fire_l,  xr_path("/user/hand/left/input/trigger/value") },
        { act_thumb_r, xr_path("/user/hand/right/input/squeeze/value") },
        { act_thumb_l, xr_path("/user/hand/left/input/squeeze/value") },
        { act_coin,    xr_path("/user/hand/right/input/a/click") },
        { act_coin,    xr_path("/user/hand/left/input/x/click") },
        { act_centre,  xr_path("/user/hand/right/input/b/click") },
        { act_centre,  xr_path("/user/hand/left/input/y/click") },
        { act_aim,     xr_path("/user/hand/left/input/aim/pose") },
        { act_aim,     xr_path("/user/hand/right/input/aim/pose") },
    };
    XrInteractionProfileSuggestedBinding sb = { XR_TYPE_INTERACTION_PROFILE_SUGGESTED_BINDING };
    sb.interactionProfile = xr_path("/interaction_profiles/oculus/touch_controller");
    sb.suggestedBindings = b;
    sb.countSuggestedBindings = (uint32_t)(sizeof b / sizeof b[0]);
    if (xr_bad(xrSuggestInteractionProfileBindings(xr_inst, &sb), "controller bindings")) return 1;

    XrSessionActionSetsAttachInfo ai = { XR_TYPE_SESSION_ACTION_SETS_ATTACH_INFO };
    ai.countActionSets = 1;
    ai.actionSets = &xr_set;
    if (xr_bad(xrAttachSessionActionSets(xr_sess, &ai), "xrAttachSessionActionSets")) return 1;

    for (int h = 0; h < 2; h++) {
        XrActionSpaceCreateInfo sp = { XR_TYPE_ACTION_SPACE_CREATE_INFO };
        sp.action = act_aim;
        sp.subactionPath = xr_hand_path[h];
        sp.poseInActionSpace.orientation.w = 1.0f;
        xr_bad(xrCreateActionSpace(xr_sess, &sp, &xr_hand_space[h]), "xrCreateActionSpace");
    }
    return 0;
}

static int xr_init(void)
{
    /* [vr] runtime: an OpenXR runtime's .json, for this program only (the
     * system's active runtime otherwise) */
    const char *rt = ini_get("vr", "runtime");
    if (rt && *rt && !getenv("XR_RUNTIME_JSON")) _putenv_s("XR_RUNTIME_JSON", rt);

    uint32_t n = 0;
    int have_gl = 0;
    if (xr_bad(xrEnumerateInstanceExtensionProperties(nullptr, 0, &n, nullptr), "no OpenXR runtime")) return 1;
    std::vector<XrExtensionProperties> ext(n, { XR_TYPE_EXTENSION_PROPERTIES });
    xrEnumerateInstanceExtensionProperties(nullptr, n, &n, ext.data());
    for (auto &e : ext) if (!strcmp(e.extensionName, XR_KHR_OPENGL_ENABLE_EXTENSION_NAME)) have_gl = 1;
    if (!have_gl) { logf("OpenXR: the runtime does not take OpenGL (XR_KHR_opengl_enable)"); return 1; }

    const char *exts[] = { XR_KHR_OPENGL_ENABLE_EXTENSION_NAME };
    XrInstanceCreateInfo ci = { XR_TYPE_INSTANCE_CREATE_INFO };
    snprintf(ci.applicationInfo.applicationName, sizeof ci.applicationInfo.applicationName, "Star Wars");
    ci.applicationInfo.applicationVersion = 1;
    ci.applicationInfo.apiVersion = XR_MAKE_VERSION(1, 0, 0);
    ci.enabledExtensionCount = 1;
    ci.enabledExtensionNames = exts;
    if (xr_bad(xrCreateInstance(&ci, &xr_inst), "xrCreateInstance")) return 1;
    XrInstanceProperties ip = { XR_TYPE_INSTANCE_PROPERTIES };
    if (XR_SUCCEEDED(xrGetInstanceProperties(xr_inst, &ip)))
        logf("OpenXR runtime: %s %u.%u.%u", ip.runtimeName, XR_VERSION_MAJOR(ip.runtimeVersion),
             XR_VERSION_MINOR(ip.runtimeVersion), XR_VERSION_PATCH(ip.runtimeVersion));

    XrSystemGetInfo sgi = { XR_TYPE_SYSTEM_GET_INFO };
    sgi.formFactor = XR_FORM_FACTOR_HEAD_MOUNTED_DISPLAY;
    if (xr_bad(xrGetSystem(xr_inst, &sgi, &xr_sys), "no headset (xrGetSystem)")) return 1;

    /* the runtime insists on being asked, and the loader does not export an extension's functions */
    XrGraphicsRequirementsOpenGLKHR req = { XR_TYPE_GRAPHICS_REQUIREMENTS_OPENGL_KHR };
    PFN_xrGetOpenGLGraphicsRequirementsKHR get_req = nullptr;
    if (xr_bad(xrGetInstanceProcAddr(xr_inst, "xrGetOpenGLGraphicsRequirementsKHR", (PFN_xrVoidFunction *)&get_req),
               "xrGetOpenGLGraphicsRequirementsKHR") || !get_req) return 1;
    if (xr_bad(get_req(xr_inst, xr_sys, &req), "OpenGL requirements")) return 1;

    XrGraphicsBindingOpenGLWin32KHR gb = { XR_TYPE_GRAPHICS_BINDING_OPENGL_WIN32_KHR };
    gb.hDC = wglGetCurrentDC();
    gb.hGLRC = wglGetCurrentContext();
    XrSessionCreateInfo sci = { XR_TYPE_SESSION_CREATE_INFO };
    sci.next = &gb;
    sci.systemId = xr_sys;
    if (xr_bad(xrCreateSession(xr_inst, &sci, &xr_sess), "xrCreateSession")) return 1;

    XrReferenceSpaceCreateInfo rs = { XR_TYPE_REFERENCE_SPACE_CREATE_INFO };
    rs.referenceSpaceType = XR_REFERENCE_SPACE_TYPE_LOCAL;
    rs.poseInReferenceSpace.orientation.w = 1.0f;
    if (xr_bad(xrCreateReferenceSpace(xr_sess, &rs, &xr_local), "xrCreateReferenceSpace")) return 1;

    xr_vcv[0].type = xr_vcv[1].type = XR_TYPE_VIEW_CONFIGURATION_VIEW;
    if (xr_bad(xrEnumerateViewConfigurationViews(xr_inst, xr_sys, XR_VIEW_CONFIGURATION_TYPE_PRIMARY_STEREO, 2, &n, xr_vcv),
               "view configuration") || n != 2) return 1;

    /* the eyes' pictures: 8-bit, sRGB by choice (what is written is shown as
     * a monitor shows it) */
    if (xr_bad(xrEnumerateSwapchainFormats(xr_sess, 0, &n, nullptr), "swapchain formats") || !n) return 1;
    std::vector<int64_t> fmts(n);
    xrEnumerateSwapchainFormats(xr_sess, n, &n, fmts.data());
    int64_t fmt = fmts[0];
    static const int64_t wanted[] = { GL_SRGB8_ALPHA8, GL_RGBA8 };
    for (int k = 1; k >= 0; k--)
        if (std::find(fmts.begin(), fmts.end(), wanted[k]) != fmts.end()) fmt = wanted[k];
    for (int e = 0; e < 2; e++) {
        XrSwapchainCreateInfo sc = { XR_TYPE_SWAPCHAIN_CREATE_INFO };
        sc.usageFlags = XR_SWAPCHAIN_USAGE_COLOR_ATTACHMENT_BIT | XR_SWAPCHAIN_USAGE_SAMPLED_BIT;
        sc.format = fmt;
        sc.sampleCount = 1;
        sc.width = xr_vcv[e].recommendedImageRectWidth;
        sc.height = xr_vcv[e].recommendedImageRectHeight;
        sc.faceCount = sc.arraySize = sc.mipCount = 1;
        if (xr_bad(xrCreateSwapchain(xr_sess, &sc, &xr_eye[e].sc), "xrCreateSwapchain")) return 1;
        xr_eye[e].w = (int)sc.width;
        xr_eye[e].h = (int)sc.height;
        xrEnumerateSwapchainImages(xr_eye[e].sc, 0, &n, nullptr);
        xr_eye[e].img.assign(n, { XR_TYPE_SWAPCHAIN_IMAGE_OPENGL_KHR });
        if (xr_bad(xrEnumerateSwapchainImages(xr_eye[e].sc, n, &n, (XrSwapchainImageBaseHeader *)xr_eye[e].img.data()),
                   "swapchain images")) return 1;
    }
    logf("OpenXR: each eye %d x %d, format %04X", xr_eye[0].w, xr_eye[0].h, (unsigned)fmt);
    return xr_actions_init();
}

static void xr_events(int *quit)
{
    XrEventDataBuffer ev = { XR_TYPE_EVENT_DATA_BUFFER };
    while (xrPollEvent(xr_inst, &ev) == XR_SUCCESS) {
        if (ev.type == XR_TYPE_EVENT_DATA_SESSION_STATE_CHANGED) {
            const XrEventDataSessionStateChanged *s = (const XrEventDataSessionStateChanged *)&ev;
            xr_focused = s->state == XR_SESSION_STATE_FOCUSED;
            if (s->state == XR_SESSION_STATE_READY) {
                XrSessionBeginInfo bi = { XR_TYPE_SESSION_BEGIN_INFO };
                bi.primaryViewConfigurationType = XR_VIEW_CONFIGURATION_TYPE_PRIMARY_STEREO;
                if (!xr_bad(xrBeginSession(xr_sess, &bi), "xrBeginSession")) xr_running = 1;
            } else if (s->state == XR_SESSION_STATE_STOPPING) {
                xrEndSession(xr_sess);
                xr_running = 0;
            } else if (s->state == XR_SESSION_STATE_EXITING || s->state == XR_SESSION_STATE_LOSS_PENDING) {
                *quit = 1;
            }
        } else if (ev.type == XR_TYPE_EVENT_DATA_INSTANCE_LOSS_PENDING) {
            *quit = 1;
        }
        ev = { XR_TYPE_EVENT_DATA_BUFFER };
    }
}

static float xr_float(XrAction a)
{
    XrActionStateGetInfo gi = { XR_TYPE_ACTION_STATE_GET_INFO };
    XrActionStateFloat s = { XR_TYPE_ACTION_STATE_FLOAT };
    gi.action = a;
    return XR_SUCCEEDED(xrGetActionStateFloat(xr_sess, &gi, &s)) && s.isActive ? s.currentState : 0.0f;
}
static int xr_bool(XrAction a)
{
    XrActionStateGetInfo gi = { XR_TYPE_ACTION_STATE_GET_INFO };
    XrActionStateBoolean s = { XR_TYPE_ACTION_STATE_BOOLEAN };
    gi.action = a;
    return XR_SUCCEEDED(xrGetActionStateBoolean(xr_sess, &gi, &s)) && s.isActive && s.currentState;
}

/* a room vector into the cockpit: the turn about the vertical undone */
static void room_to_cockpit(const float *r, float *c)
{
    const float cs = cosf(origin_yaw), sn = sinf(origin_yaw);
    c[0] = r[0] * cs - r[2] * sn;
    c[1] = r[1];
    c[2] = r[0] * sn + r[2] * cs;
}

static void q_rotate(const XrQuaternionf &q, const float *v, float *o)
{
    const float x = q.x, y = q.y, z = q.z, w = q.w;
    o[0] = (1 - 2 * (y * y + z * z)) * v[0] + 2 * (x * y - z * w) * v[1] + 2 * (x * z + y * w) * v[2];
    o[1] = 2 * (x * y + z * w) * v[0] + (1 - 2 * (x * x + z * z)) * v[1] + 2 * (y * z - x * w) * v[2];
    o[2] = 2 * (x * z - y * w) * v[0] + 2 * (y * z + x * w) * v[1] + (1 - 2 * (x * x + y * y)) * v[2];
}

static void xr_input(XrTime when)
{
    memset(&xin, 0, sizeof xin);
    XrActiveActionSet as = { xr_set, XR_NULL_PATH };
    XrActionsSyncInfo si = { XR_TYPE_ACTIONS_SYNC_INFO };
    si.countActiveActionSets = 1;
    si.activeActionSets = &as;
    if (xrSyncActions(xr_sess, &si) != XR_SUCCESS) return;      /* not focused: nothing held */

    XrActionStateGetInfo gi = { XR_TYPE_ACTION_STATE_GET_INFO };
    XrActionStateVector2f v = { XR_TYPE_ACTION_STATE_VECTOR2F };
    gi.action = act_yoke;
    if (XR_SUCCEEDED(xrGetActionStateVector2f(xr_sess, &gi, &v)) && v.isActive) {
        xin.stick_x = v.currentState.x;
        xin.stick_y = v.currentState.y;
    }
    xin.fire_r = xr_float(act_fire_r);
    xin.fire_l = xr_float(act_fire_l);
    xin.thumb_r = xr_float(act_thumb_r);
    xin.thumb_l = xr_float(act_thumb_l);
    xin.coin = xr_bool(act_coin);
    xin.centre = xr_bool(act_centre);

    for (int h = 0; h < 2 && centred; h++) {
        XrSpaceLocation loc = { XR_TYPE_SPACE_LOCATION };
        const XrSpaceLocationFlags need = XR_SPACE_LOCATION_ORIENTATION_VALID_BIT | XR_SPACE_LOCATION_POSITION_VALID_BIT;
        if (XR_FAILED(xrLocateSpace(xr_hand_space[h], xr_local, when, &loc)) || (loc.locationFlags & need) != need) continue;
        const float ahead[3] = { 0, 0, -1 };
        const float at[3] = { loc.pose.position.x, loc.pose.position.y, loc.pose.position.z };
        float r[3], c[3];
        q_rotate(loc.pose.orientation, ahead, r);
        room_to_cockpit(r, c);
        xin.hand_ok[h] = 1;
        xin.hand_yaw[h] = atan2f(c[0], -c[2]) * 57.29578f;
        xin.hand_pitch[h] = atan2f(c[1], sqrtf(c[0] * c[0] + c[2] * c[2])) * 57.29578f;
        room_to_cockpit(at, xin.hand_pos[h]);
    }
}

/* One headset frame: wait for its time, draw the picture for each eye, hand
 * them over.  The window gets the left eye. */
static void xr_frame(void)
{
    XrFrameWaitInfo wi = { XR_TYPE_FRAME_WAIT_INFO };
    XrFrameState fs = { XR_TYPE_FRAME_STATE };
    if (XR_FAILED(xrWaitFrame(xr_sess, &wi, &fs))) return;
    XrFrameBeginInfo bi = { XR_TYPE_FRAME_BEGIN_INFO };
    if (XR_FAILED(xrBeginFrame(xr_sess, &bi))) return;

    xr_input(fs.predictedDisplayTime);

    XrCompositionLayerProjectionView pv[2] = { { XR_TYPE_COMPOSITION_LAYER_PROJECTION_VIEW }, { XR_TYPE_COMPOSITION_LAYER_PROJECTION_VIEW } };
    XrCompositionLayerProjection layer = { XR_TYPE_COMPOSITION_LAYER_PROJECTION };
    const XrCompositionLayerBaseHeader *layers[1] = { (const XrCompositionLayerBaseHeader *)&layer };
    int drawn = 0;

    if (fs.shouldRender) {
        XrViewLocateInfo li = { XR_TYPE_VIEW_LOCATE_INFO };
        XrViewState vs = { XR_TYPE_VIEW_STATE };
        XrView views[2] = { { XR_TYPE_VIEW }, { XR_TYPE_VIEW } };
        uint32_t n = 0;
        li.viewConfigurationType = XR_VIEW_CONFIGURATION_TYPE_PRIMARY_STEREO;
        li.displayTime = fs.predictedDisplayTime;
        li.space = xr_local;
        if (XR_SUCCEEDED(xrLocateViews(xr_sess, &li, &vs, 2, &n, views)) && n == 2 &&
            (vs.viewStateFlags & XR_VIEW_STATE_ORIENTATION_VALID_BIT) && (vs.viewStateFlags & XR_VIEW_STATE_POSITION_VALID_BIT)) {
            if (!centred || centre_request) {
                const float ahead[3] = { 0, 0, -1 };
                float f[3];
                q_rotate(views[0].pose.orientation, ahead, f);
                origin_yaw = atan2f(-f[0], -f[2]);
                origin[0] = (views[0].pose.position.x + views[1].pose.position.x) * 0.5f;
                origin[1] = (views[0].pose.position.y + views[1].pose.position.y) * 0.5f;
                origin[2] = (views[0].pose.position.z + views[1].pose.position.z) * 0.5f;
                centred = 1;
                centre_request = 0;
            }
            drawn = 1;
            for (int e = 0; e < 2 && drawn; e++) {
                XrSwapchainImageAcquireInfo aq = { XR_TYPE_SWAPCHAIN_IMAGE_ACQUIRE_INFO };
                XrSwapchainImageWaitInfo wt = { XR_TYPE_SWAPCHAIN_IMAGE_WAIT_INFO };
                XrSwapchainImageReleaseInfo rl = { XR_TYPE_SWAPCHAIN_IMAGE_RELEASE_INFO };
                uint32_t idx = 0;
                wt.timeout = XR_INFINITE_DURATION;
                if (XR_FAILED(xrAcquireSwapchainImage(xr_eye[e].sc, &aq, &idx))) { drawn = 0; break; }
                if (XR_FAILED(xrWaitSwapchainImage(xr_eye[e].sc, &wt))) { xrReleaseSwapchainImage(xr_eye[e].sc, &rl); drawn = 0; break; }

                /* the cockpit into this eye: its turn in the room, then the eye's pose undone */
                eye_xf E;
                const XrPosef &p = views[e].pose;
                const XrQuaternionf inv = { -p.orientation.x, -p.orientation.y, -p.orientation.z, p.orientation.w };
                const float cs = cosf(origin_yaw), sn = sinf(origin_yaw);
                const float col[3][3] = { { cs, 0, -sn }, { 0, 1, 0 }, { sn, 0, cs } };     /* the cockpit's axes in the room */
                for (int k = 0; k < 3; k++) {
                    float o[3];
                    q_rotate(inv, col[k], o);
                    for (int i = 0; i < 3; i++) E.m[i][k] = o[i];
                }
                const float d[3] = { origin[0] - p.position.x, origin[1] - p.position.y, origin[2] - p.position.z };
                q_rotate(inv, d, E.t);
                E.tl = tanf(views[e].fov.angleLeft);
                E.tr = tanf(views[e].fov.angleRight);
                E.tu = tanf(views[e].fov.angleUp);
                E.td = tanf(views[e].fov.angleDown);
                E.w = xr_eye[e].w;
                E.h = xr_eye[e].h;

                glBindFramebuffer(GL_FRAMEBUFFER, fbo);
                glFramebufferTexture2D(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_TEXTURE_2D, xr_eye[e].img[idx].image, 0);
                draw_eye(E);
                if (e == 0 && win) {
                    int dw, dh, x, y, vw, vh;
                    SDL_GL_GetDrawableSize(win, &dw, &dh);
                    fit(dw, dh, E.w, E.h, &x, &y, &vw, &vh);
                    glBindFramebuffer(GL_READ_FRAMEBUFFER, fbo);
                    glBindFramebuffer(GL_DRAW_FRAMEBUFFER, 0);
                    glClear(GL_COLOR_BUFFER_BIT);
                    glBlitFramebuffer(0, 0, E.w, E.h, x, y, x + vw, y + vh, GL_COLOR_BUFFER_BIT, GL_LINEAR);
                }
                glBindFramebuffer(GL_FRAMEBUFFER, fbo);
                glFramebufferTexture2D(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_TEXTURE_2D, 0, 0);
                glBindFramebuffer(GL_FRAMEBUFFER, 0);
                xrReleaseSwapchainImage(xr_eye[e].sc, &rl);

                pv[e].pose = views[e].pose;
                pv[e].fov = views[e].fov;
                pv[e].subImage.swapchain = xr_eye[e].sc;
                pv[e].subImage.imageRect.extent.width = E.w;
                pv[e].subImage.imageRect.extent.height = E.h;
            }
        }
    }

    XrFrameEndInfo ei = { XR_TYPE_FRAME_END_INFO };
    ei.displayTime = fs.predictedDisplayTime;
    ei.environmentBlendMode = XR_ENVIRONMENT_BLEND_MODE_OPAQUE;
    if (drawn) {
        layer.space = xr_local;
        layer.viewCount = 2;
        layer.views = pv;
        ei.layerCount = 1;
        ei.layers = layers;
    }
    xrEndFrame(xr_sess, &ei);
    if (drawn && win) SDL_GL_SwapWindow(win);
}

static void xr_exit(void)
{
    for (auto &e : xr_eye) if (e.sc) xrDestroySwapchain(e.sc);
    if (xr_sess) xrDestroySession(xr_sess);
    if (xr_inst) xrDestroyInstance(xr_inst);
}

/* ------------------------------------------------------------------ */
/* input                                                               */
/* ------------------------------------------------------------------ */

static int g_quit, test_latch, diag_latch, sndtest_latch, mouse_captured;
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
            case SDL_SCANCODE_F9:
                aim_mode = (aim_mode + 1) % 3;
                yoke_rest_request = 1;
                logf("[vr] aim=%s", aim_names[aim_mode]);
                break;
            case SDL_SCANCODE_F10:
                hud_distance = hud_distance < 1.5f ? 2.0f : hud_distance < 2.5f ? 3.0f : hud_distance < 4.0f ? 5.0f :
                               hud_distance < 7.0f ? 10.0f : 1.0f;
                logf("[vr] hud_distance=%g", hud_distance);
                break;
            case SDL_SCANCODE_HOME: centre_request = yoke_rest_request = 1; break;
            case SDL_SCANCODE_PAGEUP: unit_metres *= 1.25f; logf("[vr] unit_metres=%g", unit_metres); break;
            case SDL_SCANCODE_PAGEDOWN: unit_metres /= 1.25f; logf("[vr] unit_metres=%g", unit_metres); break;
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

    /* the Touch controllers: a stick pushed up is the yoke pushed forward,
     * as the arrow keys and the game controller have it */
    {
        const float dz = 0.12f;
        float sx = fabsf(xin.stick_x) < dz ? 0.0f : xin.stick_x, sy = fabsf(xin.stick_y) < dz ? 0.0f : xin.stick_y;
        if (aim_mode == AIM_POINT && xin.hand_ok[1]) {
            sx = xin.hand_yaw[1] / aim_range;
            sy = xin.hand_pitch[1] / aim_range;
        } else if (aim_mode == AIM_YOKE && xin.hand_ok[0] && xin.hand_ok[1]) {
            /* the cabinet's yoke: it turns like a wheel, by the line from
             * hand to hand, and its handles tilt, by where the two point */
            const float *l = xin.hand_pos[0], *r = xin.hand_pos[1];
            const float dx = r[0] - l[0], dy = r[1] - l[1], dz = r[2] - l[2];
            const float turn = atan2f(-dy, sqrtf(dx * dx + dz * dz)) * 57.29578f;     /* the right hand down: to the right */
            const float tilt = (xin.hand_pitch[0] + xin.hand_pitch[1]) * 0.5f;
            if (yoke_rest_request) { yoke_rest = tilt; yoke_rest_request = 0; }
            sx += turn / yoke_turn;
            sy += (tilt - yoke_rest) / yoke_tilt;
        }
        sx = std::max(-1.0f, std::min(1.0f, sx));
        sy = std::max(-1.0f, std::min(1.0f, sy));
        x += sx * 127.0;
        y -= sy * 127.0 * (invert_pitch ? -1.0 : 1.0);
        if (xin.fire_r > 0.5f) in->fire_r = 1;
        if (xin.fire_l > 0.5f) in->fire_l = 1;
        if (xin.thumb_r > 0.5f) in->thumb_r = 1;
        if (xin.thumb_l > 0.5f) in->thumb_l = 1;
        if (xin.coin) in->coin_l = 1;
        if (xin.centre) centre_request = yoke_rest_request = 1;
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
            "usage: %s [--flat] [--rev 1|2] [--romdir DIR] [--test] [--nvram FILE] [--no-nvram]\n"
            "  testing: [--script FILE] [--passes N] [--quit-after-ms MS] [--turbo] [--hidden]\n",
            argv[0]);
        return 2;
    }
    SDL_SetMainReady();

    char *base = SDL_GetBasePath();
    exe_dir = base ? base : "./";
    SDL_free(base);
    path_ini = exe_dir + "sw_xr.ini";
    path_log = exe_dir + "sw_xr.log";
    path_nv = nv_override.empty() ? exe_dir + "starwars.nv" : nv_override;
    log_file = fopen(path_log.c_str(), "w");
    ini_load(path_ini);

    {
        const char *r = ini_get("main", "rom_dir");
        std::string rd = r ? r : "../disasm/build";
        for (auto &c : rd) if (c == '\\') c = '/';
        const bool absolute = !rd.empty() && (rd[0] == '/' || (rd.size() > 1 && rd[1] == ':'));
        path_roms = absolute ? rd : exe_dir + rd;
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
    unit_metres = (float)ini_dbl("vr", "unit_metres", unit_metres);
    hud_distance = (float)ini_dbl("vr", "hud_distance", hud_distance);
    hud_scale = (float)ini_dbl("vr", "hud_scale", hud_scale);
    aim_range = (float)ini_dbl("vr", "aim_range", aim_range);
    yoke_turn = (float)ini_dbl("vr", "yoke_turn", yoke_turn);
    yoke_tilt = (float)ini_dbl("vr", "yoke_tilt", yoke_tilt);
    if (const char *a = ini_get("vr", "aim"))
        for (int k = 0; k < 3; k++) if (!strcmp(a, aim_names[k])) aim_mode = k;

    const int headless = turbo || hidden_mode;
    Uint32 sdl_flags = SDL_INIT_TIMER | SDL_INIT_EVENTS;
    if (!headless) sdl_flags |= SDL_INIT_VIDEO | SDL_INIT_AUDIO | SDL_INIT_GAMECONTROLLER;
    if (SDL_Init(sdl_flags) != 0) { logf("SDL_Init: %s", SDL_GetError()); return 1; }

    if (!headless) {
        SDL_GL_SetAttribute(SDL_GL_CONTEXT_MAJOR_VERSION, 3);
        SDL_GL_SetAttribute(SDL_GL_CONTEXT_MINOR_VERSION, 2);
        SDL_GL_SetAttribute(SDL_GL_CONTEXT_PROFILE_MASK, SDL_GL_CONTEXT_PROFILE_COMPATIBILITY);
        SDL_GL_SetAttribute(SDL_GL_DOUBLEBUFFER, 1);
        win = SDL_CreateWindow(APP_NAME, SDL_WINDOWPOS_CENTERED, SDL_WINDOWPOS_CENTERED, 960, 720,
                               SDL_WINDOW_OPENGL | SDL_WINDOW_RESIZABLE | SDL_WINDOW_ALLOW_HIGHDPI);
        if (!win) { logf("window: %s", SDL_GetError()); return 1; }
        glctx = SDL_GL_CreateContext(win);
        if (!glctx) { logf("OpenGL: %s", SDL_GetError()); return 1; }
        SDL_GL_SetSwapInterval(0);                  /* the headset sets the pace, not the monitor */
        logf("GL_VERSION: %s", (const char *)glGetString(GL_VERSION));
        if (gl_init()) return 1;
        set_capture(ini_int("input", "mouse_capture", flat ? 1 : 0));
        for (int i = 0; i < SDL_NumJoysticks() && !pad; i++)
            if (SDL_IsGameController(i)) pad = SDL_GameControllerOpen(i);
        if (!flat && xr_init()) {
            const char *msg = "No headset was found through OpenXR.\n\nStart Quest Link (or Air Link) first, and make "
                              "the headset's runtime the active OpenXR runtime; sw_xr.log says what failed.\n\n"
                              "sw_xr --flat runs in this window without a headset.";
            logf("%s", msg);
            SDL_ShowSimpleMessageBox(SDL_MESSAGEBOX_ERROR, APP_NAME, msg, win);
            xr_exit();
            return 1;
        }
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
        xr_exit();
        return 1;
    }

    sw_app_stats st, st0;
    double t_start = plat_now_ms(), stat_t = t_start;
    unsigned long pics0 = 0, frames = 0;
    sw_app_get_stats(&st0);

    while (!g_quit) {
        if (win) pump_events();
        if (xr_inst) xr_events(&g_quit);
        if (g_quit) break;
        double now = plat_now_ms();
        sw_app_run(now);
        sw_app_get_stats(&st);
        if (quit_after_passes && st.passes >= quit_after_passes) g_quit = 1;
        if (st.script_ended) g_quit = 1;
        if (quit_after_ms > 0.0 && now - t_start >= quit_after_ms) g_quit = 1;

        if (win) {
            if (xr_running) {
                xr_frame();                         /* waits for the headset's next frame */
                frames++;
            } else {
                if (present_pending) draw_flat();
                SDL_Delay(1);
            }
            present_pending = 0;
            if (now - stat_t >= 1000.0) {
                char s[300];
                double dt = (now - stat_t) / 1000.0;
                snprintf(s, sizeof s, APP_NAME "  %.1f pictures/s  machine/wall %.3f  %d vectors  %s%s%s",
                         (double)(n_pictures - pics0) / dt, (double)(st.cycles - st0.cycles) / 1512000.0 / dt, st.points,
                         xr_running ? (xr_focused ? "in the headset" : "headset idle") : flat ? "flat" : "waiting for the headset",
                         test_latch ? "  SELF TEST SWITCH ON" : "", sndtest_latch ? "  SOUND TEST ON" : "");
                if (xr_running) snprintf(s + strlen(s), sizeof s - strlen(s), "  %.0f Hz", (double)frames / dt);
                SDL_SetWindowTitle(win, s);
                stat_t = now;
                st0 = st;
                pics0 = n_pictures;
                frames = 0;
            }
        }
    }

    sw_app_get_stats(&st);
    logf("exit: passes %lu, cycles %llu (%.3f s machine, %.3f s wall), pictures %lu, irqs %lu, phase %02X",
         st.passes, (unsigned long long)st.cycles, (double)st.cycles / 1512000.0,
         (plat_now_ms() - t_start) / 1000.0, st.pictures, st.irqs, st.phase);
    logf("[vr] unit_metres=%g hud_distance=%g aim=%s", unit_metres, hud_distance, aim_names[aim_mode]);
    sw_app_exit();
    xr_exit();
    if (glctx) SDL_GL_DeleteContext(glctx);
    if (win) SDL_DestroyWindow(win);
    SDL_Quit();
    if (log_file) fclose(log_file);
    return 0;
}
