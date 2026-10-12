# Quest SWVR

**Star Wars** (Atari, 1983) as a native app for the **Meta Quest**: you sit in
the cockpit, the TIE fighters, towers, trench and Death Star are drawn in 3-D
around you, and a Touch controller is your flight stick. It runs in the
headset by itself, with no PC and no cable once it is installed.

It is the arcade game itself, not a remake: Atari's program translated to C
from the ROMs, with every vector it draws placed where the game's own
arithmetic put it in space.

**[Download StarWarsQuest.apk](https://github.com/cyberheater/Quest-SWVR/releases/latest)**
&nbsp;·&nbsp; **[Full guide](docs/VR.md#on-the-quest-itself)**

**No ROM data is included.** You need your own MAME `starwars` ROM set.

Tried on a Quest 3. It should run on a Quest 2, 3S and Pro as well.

## Install

You install the app yourself ("sideloading"), which needs a PC and a USB cable
once. The [guide](docs/VR.md#on-the-quest-itself) has every step in detail.

1. **Developer mode.** In the Meta Horizon phone app: Menu, Devices, your
   headset, Headset settings, Developer mode, on.
2. **Install the app.** Connect the headset by USB, allow USB debugging in the
   headset, then drag `StarWarsQuest.apk` onto
   [SideQuest](https://sidequestvr.com), or run `adb install -r StarWarsQuest.apk`.
3. **Start it once.** Library, Unknown Sources, Star Wars. It shows **NO ROMS**
   and makes its folder. Quit with the Meta button.
4. **Copy your `starwars.zip` to the headset**, as it is, into

   ```
   Android/data/com.cyberheater.starwars/files
   ```

   with SideQuest's file browser, or:

   ```powershell
   adb push starwars.zip /sdcard/Android/data/com.cyberheater.starwars/files/
   ```

Start Star Wars again and the game runs: the app finds the chips it needs in
the zip by itself. Nothing has to be unpacked or converted.

## Play

Hold the right controller upright like a joystick and press **B**: that
centres the view and the stick.

| Action | Control |
|---|---|
| Move the sight | **Flight stick**: tip or push the controller forward to dive, back to climb, lean or move it left / right |
| Fire | Either trigger, either grip |
| Insert coin | **A** or **X** |
| Centre the view and the stick | **B**, or **Y** to hold the stick in the left hand |
| Menu (pauses the game) | Click either thumbstick |

Insert a coin, pull a trigger to start, then aim at one of the three Death
Stars and fire to choose the difficulty. You have shields, not lives: shoot
the fireballs before they reach you.

**The menu** has sliders for the **SIZE** of the picture, the **DEPTH** of the
3-D and how far away the **STARS** are, and a **QUIT** row (press A). Thumbstick
up and down picks a row, left and right moves it; click again to go on. The
settings are kept.

Taking the headset off pauses the game.

## Build it yourself

The app is [`c_src/platform/openxr/plat_openxr.cpp`](c_src/platform/openxr/plat_openxr.cpp)
on the C port in [`c_src`](c_src/README.md). With the Android SDK
(platform-tools, `platforms;android-34`, `build-tools;34.0.0`,
`ndk;26.3.11579264`, `cmake;3.22.1`), a JDK 17 and the unpacked
`org.khronos.openxr:openxr_loader_for_android` package, on Windows:

```powershell
c_src\platform\openxr\android\build_quest.ps1 -Sdk <the SDK> -OpenXR <the unpacked loader>
```

writes `c_src\StarWarsQuest.apk`.

## Where it comes from

This repository is the Quest side of
[Star Wars Arcade PCVR](https://github.com/cyberheater/Star-Wars-Arcade-PCVR),
which also has the Windows PC VR version (`sw_xr.exe`) and the game in a
desktop window. Both are built on the
[Star Wars full disassembly and C port](https://github.com/tcottrill/Star-Wars-Full-Disassembly-and-C-Port):
the annotated disassembly of the ROMs, the C translation of both of the
machine's programs, and the models of its chips. That work, with its history,
is all here: [`disasm`](disasm/README.md), [`c_src`](c_src/README.md),
[`emu_src`](emu_src/README.md) and [`docs`](docs).

Star Wars, the 1983 arcade game, is the work of Atari, Inc., and Star Wars is
the property of its owners. This is a fan project. It contains none of the
game's ROM data and will not run without a ROM set you supply yourself.

The code is under the GPL, version 2: see [LICENSE](LICENSE).
