# Star Wars in a headset — installing and playing `sw_xr`

`sw_xr.exe` is the C port of Star Wars (Atari, 1983) played in a VR headset.
You sit in the cockpit: the TIE fighters, towers, trench and Death Star are
drawn in 3-D around you for each eye, the scores and shield display float on a
panel ahead, and a Touch controller is your flight stick.

It was written for a **Meta Quest 3 connected to a Windows PC** (Quest Link,
Air Link or Virtual Desktop). Any PC headset whose OpenXR runtime accepts
OpenGL should work, but only the Quest has been tried.

No ROM data is included. You need your own MAME `starwars` ROM set.

- [What you need](#what-you-need)
- [Install](#install)
- [Start the game](#start-the-game)
- [How to play](#how-to-play)
- [Controls](#controls)
- [The menu: size, depth and stars](#the-menu-size-depth-and-stars)
- [Settings file](#settings-file)
- [Troubleshooting](#troubleshooting)

## What you need

| | |
|---|---|
| PC | Windows 10 or 11, 64-bit, with a graphics card that can run PC VR |
| Headset | Meta Quest 2 / 3 / Pro with Touch controllers, and one of: the **Meta Quest Link** PC app (cable or Air Link), or **Virtual Desktop** with its Streamer app on the PC |
| ROMs | `starwars.zip`, the MAME `starwars` set (revision 2), which you must supply yourself |
| Disk | About 12 GB, nearly all of it Visual Studio |

## Install

Do this once. Open **PowerShell** for every command below.

### 1. Install the build tools

```powershell
winget install -e --id Git.Git
winget install -e --id Python.Python.3.12
winget install -e --id Kitware.CMake
winget install -e --id Microsoft.VisualStudio.2022.Community --override "--add Microsoft.VisualStudio.Workload.NativeDesktop --includeRecommended --passive --norestart"
```

Say yes to the Windows prompts. Visual Studio is several gigabytes and takes a
while. **Close PowerShell and open a new one** afterwards so the new programs
are found.

### 2. Get the source

Pick a folder to work in. These instructions use `C:\SW3D`.

```powershell
mkdir C:\SW3D
cd C:\SW3D
git clone --branch 3d-tap https://github.com/cyberheater/Star-Wars-Full-Disassembly-and-C-Port swc
```

### 3. Get the two libraries (SDL2 and the OpenXR loader)

```powershell
git clone --depth 1 https://github.com/microsoft/vcpkg C:\SW3D\vcpkg
C:\SW3D\vcpkg\bootstrap-vcpkg.bat -disableMetrics
C:\SW3D\vcpkg\vcpkg.exe install sdl2:x64-windows openxr-loader:x64-windows
```

This compiles both libraries and takes five to ten minutes.

### 4. Make the ROM images

Copy your `starwars.zip` to `C:\SW3D` (next to the `swc` folder, **not** inside
it, so it can never be committed by accident), then:

```powershell
cd C:\SW3D\swc\disasm
python image.py C:\SW3D\starwars.zip
```

It lists the fourteen chips it found, each matched by checksum, and writes six
`.bin` files to `disasm\build`. If a chip is reported missing, your zip is not
the MAME `starwars` set.

### 5. Build

```powershell
cd C:\SW3D\swc
cmake -S c_src -B c_src/build -G "Visual Studio 17 2022" -A x64 -DCMAKE_TOOLCHAIN_FILE=C:/SW3D/vcpkg/scripts/buildsystems/vcpkg.cmake
cmake --build c_src/build --config Release
```

When it finishes, `C:\SW3D\swc\c_src` holds:

- `sw_xr.exe` — the game in the headset
- `sw_sdl.exe` — the same game in an ordinary window (mouse as the yoke)
- `SDL2.dll`, `openxr_loader.dll`, `jsoncpp.dll` — keep these beside the exes

To rebuild after updating the source (`git pull`), run only the second `cmake`
line. Quit the game first: Windows will not replace an exe that is running.

## Start the game

1. Put the headset on and connect it to the PC: start **Quest Link** / **Air
   Link**, or connect with **Virtual Desktop**. Wait until you see the PC's VR
   home or desktop in the headset.
2. On the PC, run `C:\SW3D\swc\c_src\sw_xr.exe`.
3. The game appears around you. Sit facing the way you want "forward" to be,
   hold the right controller upright like a joystick, and press **B** to
   centre the view and the stick.

You do not need to change the "active OpenXR runtime" in Windows. The game
asks each runtime installed on the PC in turn (Quest Link, Virtual Desktop,
then SteamVR) and uses the first that has a headset connected.

A window on the PC monitor mirrors the left eye. The keyboard only works while
that window has the focus.

To try it without a headset: `sw_xr.exe --flat`, or `sw_sdl.exe`.

## How to play

Star Wars is the 1983 Atari cabinet: you fly Luke's X-wing against the Death
Star in three stages, then do it again, harder.

1. **Insert a coin**: press **A** (or **X** on the left controller).
2. **Start**: pull a trigger.
3. **Choose a difficulty**: three Death Stars appear. Move the sight onto one
   and fire. The left one is the easy start; the others start on later waves
   for bonus points.
4. **Space**: shoot the TIE fighters and Darth Vader's ship, and shoot the
   fireballs they fire at you before they arrive. Every fireball that reaches
   you costs one shield.
5. **Death Star surface** (from the second wave): shoot the tops off the towers
   and the fireballs from the bunkers. Don't fly into a tower.
6. **Trench**: fly down the trench, dodge or shoot the fireballs and the
   catwalks, and when the exhaust port comes up, fire into it. Hit it and the
   Death Star explodes; miss and you go round again.

You have no lives, only **shields** (the green display at the top centre). The
game ends when you take a hit with none left. Destroying the Death Star gives
one back.

The stick does not steer the ship. It moves the **sight**, and your four lasers
fire to wherever the sight is. In the trench and over the towers it also moves
you up, down and sideways.

## Controls

### Touch controllers

| Action | Control |
|---|---|
| Move the sight | **Flight stick**: the right controller, held upright. Tip or push it forward to aim down (dive), back to aim up (climb), lean or move it left / right |
| Fire | Either trigger |
| Thumb buttons (also fire) | Either grip |
| Insert coin | **A** or **X** |
| Centre the view and the stick | **B** (right hand holds the stick) or **Y** (left hand holds the stick) |
| Menu (pauses the game) | Click either thumbstick |
| Nudge the sight | Either thumbstick |

**Left-handed:** press **Y** on the left controller. The left controller is now
the flight stick. Press **B** to give it back to the right.

**Centring matters.** The pose the controller is in when you press B or Y is
the stick's rest position. If the sight drifts or sits off-centre, hold the
controller comfortably and press it again.

### Keyboard (the PC window must have the focus)

| Key | Action |
|---|---|
| 5, 6 | Insert coin |
| Mouse, arrow keys | Move the sight (click the window to capture the mouse, F8 to release) |
| Left Ctrl, Left Alt, mouse buttons | Fire |
| Space, Shift | Thumb buttons |
| Home | Centre the view and the stick |
| F9 | Change control scheme: flight stick → two-handed yoke → point the controller → thumbsticks only |
| PageDown / PageUp | Bring the world nearer (more depth) / push it farther |
| - / = | Make the whole picture smaller / larger |
| F10 | Move the score panel: 1, 2, 3, 5 or 10 m away |
| F2 | Operator's self-test switch (statistics and options pages) |
| Esc | Quit |

### The other control schemes (F9)

- **Yoke**: both controllers are the handles of the cabinet's yoke. Turn them
  like a steering wheel to go left and right; raise both to aim up, lower both
  to aim down.
- **Point**: point the stick-hand controller where you want the sight.
- **Stick**: the thumbsticks only.

## The menu: size, depth and stars

Click a thumbstick. The game freezes and dims, and three sliders appear in
front of you. Thumbstick **up / down** picks a slider, **left / right** moves
it, and the frozen scene changes as you move it. Click again to close the
menu; the game carries on a quarter of a second later and your settings are
saved.

| Slider | Left | Right |
|---|---|---|
| **SIZE** | Whole picture 20% smaller | 20% larger |
| **DEPTH** | World four times farther away: flatter, feels bigger | Four times nearer: stronger 3-D, feels like a model |
| **STARS** | Stars close, flying past among the ships | Stars a distant sky behind everything |

If the scores at the edges are hard to see, lower SIZE. If things come
uncomfortably close to your face, lower DEPTH.

## Settings file

`sw_xr.ini`, beside `sw_xr.exe`, is read at start. It is optional: without it
the defaults below apply. The menu writes its three sliders into it.

```ini
[vr]
; one game unit in metres: smaller brings everything nearer (middle of DEPTH)
unit_metres=0.005
; the picture's size to the eye; 1 fills about 90 degrees (middle of SIZE)
view_scale=0.675
; the stars' distance in game units at the right of STARS; 0 = as the arcade game
star_depth=4194304
; the score panel, metres ahead
hud_distance=3
; flight, yoke, point or stick
aim=flight
; which hand holds the flight stick at start: right or left
flight_hand=right
; degrees of tilt, and metres of hand movement, for the stick's full travel
flight_tilt=30
flight_reach=0.12

[input]
; 1 swaps up and down
invert_pitch=0

[vector]
brightness=1.6
linewidth=2.0

[sound]
; any part of an output device's name, or "default"; left out, the headset's
;device=Headphones (Oculus Virtual Audio Device)
```

To make the stick more sensitive, lower `flight_tilt` and `flight_reach`. To
use only tilt or only movement, set the other to 0.

High scores are kept in `starwars.nv` in the same folder.

## Troubleshooting

`sw_xr.log`, beside the exe, is rewritten on every run and says what happened.

| Problem | What to do |
|---|---|
| "No headset was found through OpenXR" | The headset is not connected to the PC yet. Start Quest Link, Air Link or Virtual Desktop, wait for the PC view in the headset, then run the game again. The log lists each runtime tried. |
| SteamVR starts up | No other runtime had a headset, so SteamVR was asked last. Connect the headset first. |
| "cannot open ...starwars_main_rev2.bin" | The ROM images were not made. Do step 4 of Install. |
| A missing-DLL error | `SDL2.dll`, `openxr_loader.dll` and `jsoncpp.dll` must be beside `sw_xr.exe`. Build again. |
| No sound in the headset | The log lists the audio outputs and the one chosen. Put part of the right one's name in `[sound] device=`. |
| The sight is off-centre or drifts | Hold the controller at rest and press B (or Y). |
| Up and down are the wrong way round | `invert_pitch=1` under `[input]`. |
| Pressing A gives no credit | Press once and wait a second. The game takes a moment to accept a coin. |
| The sight feels slightly behind your hand | That is the original game: it eases the sight toward the yoke rather than jumping. |
| Everything is too big to take in | Open the menu and lower SIZE. |
| The build cannot write `sw_xr.exe` | The game is still running. Quit it and build again. |
