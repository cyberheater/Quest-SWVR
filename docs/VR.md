# Star Wars in a headset — installing and playing `sw_xr`

`sw_xr.exe` is the C port of Star Wars (Atari, 1983) played in a VR headset.
You sit in the cockpit: the TIE fighters, towers, trench and Death Star are
drawn in 3-D around you for each eye, the scores and shield display float on a
panel ahead, and a Touch controller is your flight stick.

It was written for a **Meta Quest 3 connected to a Windows PC** (Quest Link,
Air Link or Virtual Desktop). Any PC headset whose OpenXR runtime accepts
OpenGL should work, but only the Quest has been tried.

There is also a **native Quest app** that runs in the headset by itself, with
no PC and no cable once it is installed: see
[On the Quest itself](#on-the-quest-itself).

No ROM data is included. You need your own MAME `starwars` ROM set.

- [What you need](#what-you-need)
- [Install](#install)
- [Start the game](#start-the-game)
- [How to play](#how-to-play)
- [Controls](#controls)
- [The menu: size, depth and stars](#the-menu-size-depth-and-stars)
- [Settings file](#settings-file)
- [On the Quest itself](#on-the-quest-itself)
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
git clone https://github.com/cyberheater/Quest-SWVR swc
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

### A flight stick (Thrustmaster T.Flight Hotas X)

Plug the stick in by USB, into the PC or into the Quest itself, before starting
the game or while it runs. While it is plugged in it is the only controller the
game reads: the Touch controllers and any game pad are ignored, so they can
stay on the desk. The headset still tracks your head, and the keyboard still
works. Where the stick rests when it is found is its centre.

| Action | On the T.Flight Hotas X |
|---|---|
| Move the sight | The stick: push forward to dive (sight down), pull back to climb (sight up), left and right |
| Fire | Trigger (button 1), button 3 |
| Thumb button (also fires) | Button 4 |
| Insert coin | Button 2 |
| Menu (pauses the game) | **ST** (button 10) |
| In the menu | The hat: up / down picks a slider, left / right moves it. On QUIT, button 2 leaves |
| Centre the view, and take the stick as it rests now as its centre | Hat down |

The button numbers are the ones printed on the stick. Any other USB joystick
works the same way. If a button does something else, or nothing, press it once
in the game and look in `sw_xr.log`: each button is named there the first time
it is pressed (`[hotas] button 7 pressed`). Then set it under `[hotas]` in
`sw_xr.ini`:

```ini
[hotas]
fire_right=1
thumb_right=4
fire_left=3
thumb_left=0
coin=2
menu=10
; a button that centres, as well as the hat pushed down (0: none)
centre=0
centre_hat_down=1
; the stick's axes, counted from 1 (Windows' order on the PC; on the Quest
; 1 X, 2 Y, 3 Z, 4 RZ, 5 RX, 6 RY, 7 throttle, 8 rudder)
axis_x=1
axis_y=2
; 1 swaps up and down (pushed forward to climb)
invert_pitch=0
deadzone=0.04
```

A button set to 0 does nothing.

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
| **QUIT** | Press **A** or **X** on this row to leave the game | |

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

## On the Quest itself

`StarWarsQuest.apk` is the same game as an app for the headset: the same
cockpit, flight stick and menu, running on the Quest's own processor. It is
not on the Meta store; you install it yourself ("sideloading"), which needs a
PC once.

### What you need

- A Quest: the original, 2, 3, 3S or Pro (tried on the original and on a Quest 3)
- A PC and a USB cable, for the one-time install
- Your own `starwars.zip`, the MAME `starwars` ROM set, as it is

### 1. Turn on developer mode

In the **Meta Horizon** phone app: Menu, Devices, your headset, Headset
settings, **Developer mode**, on. The first time, it asks you to create a
developer organisation, which is free:
<https://developer.oculus.com/manage/organizations/create/>.

### 2. Install the app

Connect the headset to the PC by USB, put it on, and choose **Allow** on the
"Allow USB debugging?" prompt (tick "Always allow from this computer").

Then either:

- **SideQuest** (<https://sidequestvr.com>, the "Advanced Installer"): open
  it, wait for the green dot, and drag `StarWarsQuest.apk` onto its window; or
- **adb**, from Google's
  [platform-tools](https://developer.android.com/tools/releases/platform-tools):

  ```powershell
  adb install -r StarWarsQuest.apk
  ```

### 3. Start it once

In the headset: Library, the filter at the top right, **Unknown Sources**,
**Star Wars**. With no ROM set yet it shows the words **NO ROMS**. That
first start creates the app's folder. Quit with the Meta button.

### 4. Copy your ROM set to the headset

`starwars.zip` goes, as it is, into this folder on the headset:

```
Android/data/com.cyberheater.starwars/files
```

- **adb:**

  ```powershell
  adb push starwars.zip /sdcard/Android/data/com.cyberheater.starwars/files/
  ```

- **SideQuest:** its file browser (the folder icon), go to that folder, and
  drag the zip in.
- **Windows Explorer:** with the headset on USB and "Allow access to data"
  accepted in the headset, open the headset's Internal shared storage and go
  to that folder. Some headset software versions hide `Android/data` here; use
  one of the other two ways if so.

The app looks in every `.zip` in that folder and finds the chips it needs by
their checksums, whatever the files are called, so nothing has to be unpacked
or converted and Python is not needed. The first start with the zip there
writes six `starwars_*.bin` files beside it and uses those from then on.

Start Star Wars again and the game runs. The cable is no longer needed.

### Playing

Everything in [How to play](#how-to-play), [Controls](#controls) (the Touch
controller part) and [The menu](#the-menu-size-depth-and-stars) applies. There
is no keyboard, so:

- **Quit:** the menu's **QUIT** row, or the Meta button and Quit.
- **Settings:** the menu's sliders are saved automatically. The other options
  of the [settings file](#settings-file) work too: put an `sw_xr.ini` in the
  folder above, beside the ROM set. `sw_xr.log` and the high scores
  (`starwars.nv`) are kept there as well.
- Taking the headset off pauses the game.
- **A flight stick** works plugged into the headset's USB-C port (with a USB-C
  to USB-A adapter for the T.Flight): see
  [A flight stick](#a-flight-stick-thrustmaster-tflight-hotas-x).

### Building the app yourself

With the Android SDK (platform-tools, `platforms;android-34`,
`build-tools;34.0.0`, `ndk;26.3.11579264`, `cmake;3.22.1`), a JDK 17 and the
unpacked `org.khronos.openxr:openxr_loader_for_android` package:

```powershell
c_src\platform\openxr\android\build_quest.ps1 -Sdk <the SDK> -OpenXR <the unpacked loader>
```

It writes `c_src\StarWarsQuest.apk`, signed with a key of its own that it
makes on first use. An update only installs over a copy signed with the same
key; uninstall the old one first otherwise (the ROM set goes with it).

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
| Quest app: the words NO ROMS | There is no `.zip` in `Android/data/com.cyberheater.starwars/files`. Copy your `starwars.zip` there. |
| Quest app: the words BAD ROMS | The zip there is not the MAME `starwars` set. `sw_xr.log` in that folder names the chip it could not find. |
| Quest app: it closes at once | `sw_xr.log` in that folder says why. |
| Quest app: the update will not install | It was signed with a different key. Uninstall Star Wars from the headset, install again, and copy the ROM set again. |
