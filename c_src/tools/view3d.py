#!/usr/bin/env python3
"""view3d.py - look at a picture of a 3-D tap dump (sw_sdl built with SW_3D,
run with SW_DUMP3D=FILE) from somewhere the cabinet's camera never was.

    python3 tools/view3d.py DUMP PICTURE OUT.png [--yaw DEG] [--pitch DEG] [--side N] [--back N]

Each lit line in the dump ends in "R ls xs ys zs lt xt yt zt": the layer and
point sw3d_resolve gave its two ends (0 HUD: screen x, y; 1 world: viewer
space, x depth, y across, z up).  The sheet has four
panels: the picture as the cabinet drew it; the world re-projected
from the cabinet's own camera with the HUD on top (it should look the same);
the world from the moved camera; and the world from above.
"""
import math
import sys

from PIL import Image, ImageDraw

SX0, SXK, SY0, SYK = 124.4, 126.8, 166.2, 123.75
W, H = 700, 784                       # 250 x 280 AVG units, scaled


def load(path, want):
    lines, pic = [], 0
    with open(path) as f:
        for line in f:
            if line[0] == 'P':
                pic = int(line.split()[1])
                if pic > want:
                    break
                continue
            if pic != want:
                continue
            a = line.split()
            r = a[a.index('R') + 1:]
            lines.append(dict(
                scr=(float(a[0]), float(a[1]), float(a[2]), float(a[3])),
                rgb=int(a[4], 16), z=int(a[5]),
                s=(int(r[0]), float(r[1]), float(r[2]), float(r[3])),
                t=(int(r[4]), float(r[5]), float(r[6]), float(r[7]))))
    return lines


def col(l):
    c, k = l['rgb'], min(1.0, 0.35 + l['z'] / 160)     # app.cpp writes it red low
    return (int((c & 255) * k), int((c >> 8 & 255) * k), int((c >> 16 & 255) * k))


def to_px(sx, sy):
    return (sx / 250 * W, sy / 280 * H)


def camera(yaw, pitch, side, back):
    cy, sy_, cp, sp = math.cos(yaw), math.sin(yaw), math.cos(pitch), math.sin(pitch)

    def view(p, layer):
        x, y, z = p
        x, y = x + back, y - side
        x, y = x * cy - y * sy_, x * sy_ + y * cy
        x, z = x * cp - z * sp, x * sp + z * cp
        return x, y, z
    return view


def clip(a, b, near=20.0):
    if a[0] < near and b[0] < near:
        return None
    if a[0] < near or b[0] < near:
        t = (near - a[0]) / (b[0] - a[0])
        m = tuple(a[i] + (b[i] - a[i]) * t for i in range(3))
        a, b = (m, b) if a[0] < near else (a, m)
    return a, b


def proj(p):
    return to_px(SX0 + SXK * p[1] / p[0], SY0 - SYK * p[2] / p[0])


def draw_3d(d, lines, view, hud):
    for l in lines:
        (ls, *ps), (lt, *pt) = l['s'], l['t']
        if ls == 0 or lt == 0:
            if hud and ls == 0 and lt == 0:
                d.line([to_px(*l['scr'][:2]), to_px(*l['scr'][2:])], fill=col(l), width=2)
            continue
        if l['scr'][:2] == l['scr'][2:]:          # a dot
            ps = pt
        c = clip(view(ps, ls), view(pt, lt))
        if c:
            a, b = proj(c[0]), proj(c[1])
            if a == b:
                d.ellipse([a[0] - 1, a[1] - 1, a[0] + 1, a[1] + 1], fill=col(l))
            else:
                d.line([a, b], fill=col(l), width=2)


def main():
    args = sys.argv[1:]
    opt = dict(yaw=25.0, pitch=0.0, side=0.0, back=0.0)
    pos = []
    while args:
        a = args.pop(0)
        if a.startswith('--'):
            opt[a[2:]] = float(args.pop(0))
        else:
            pos.append(a)
    dump, pic, out = pos[0], int(pos[1]), pos[2]
    lines = load(dump, pic)
    n = [0, 0]
    for l in lines:
        n[l['t'][0]] += 1
    print('picture %d: %d lines, %d HUD, %d world' % (pic, len(lines), *n))

    panels = []
    im = Image.new('RGB', (W, H)); d = ImageDraw.Draw(im)
    for l in lines:
        d.line([to_px(*l['scr'][:2]), to_px(*l['scr'][2:])], fill=col(l), width=2)
    panels.append(im)
    im = Image.new('RGB', (W, H)); d = ImageDraw.Draw(im)
    draw_3d(d, lines, camera(0, 0, 0, 0), True)
    panels.append(im)
    im = Image.new('RGB', (W, H)); d = ImageDraw.Draw(im)
    draw_3d(d, lines, camera(math.radians(opt['yaw']), math.radians(opt['pitch']), opt['side'], opt['back']), False)
    panels.append(im)
    # from above: depth up the page, across along it
    im = Image.new('RGB', (W, H)); d = ImageDraw.Draw(im)
    pts = [p for l in lines for (ly, *p) in (l['s'], l['t']) if ly == 1]
    if pts:
        md = max(p[0] for p in pts) * 1.05
        mx = max(abs(p[1]) for p in pts) * 1.1 + 1
        k = min(H / md, W / 2 / mx)
        for l in lines:
            if l['s'][0] == 1 and l['t'][0] == 1:
                a, b = l['s'][1:], l['t'][1:]
                d.line([(W / 2 + a[1] * k, H - a[0] * k), (W / 2 + b[1] * k, H - b[0] * k)], fill=col(l), width=1)
    panels.append(im)

    sheet = Image.new('RGB', (W * 2 + 8, H * 2 + 8), (40, 40, 40))
    for i, p in enumerate(panels):
        sheet.paste(p, ((i % 2) * (W + 8), (i // 2) * (H + 8)))
    sheet.save(out)


if __name__ == '__main__':
    main()
