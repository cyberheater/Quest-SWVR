@echo off
rem Build the playable Star Wars C port (x64, VS2022 cl): sw_win.exe in c_src\,
rem next to sw_win.ini / sw_win.log / starwars.nv.
rem
rem   sw_win.exe   gen\ + hand\ (main program) and gen_snd\ (sound program) on
rem                the chip models (hw.cpp), port.cpp.  No 6809 core is linked.
rem
rem (The emulator twin, the ROMs on 6809 cores, is ..\emu_src\build_emu.bat: a
rem separate program with its own copy of every file.)
rem
rem It reads the ROM images at run time from ..\disasm\build
rem (python ..\disasm\gen_from_roms.py).  gen\ and gen_snd\ are checked in;
rem tools\xlate.py and tools\xlate.py sound regenerate them.
rem
rem Objects go to obj\win\ so they never collide with build_all.bat's.
call "C:\Program Files\Microsoft Visual Studio\2022\Community\Common7\Tools\VsDevCmd.bat" -arch=amd64 -no_logo
cd /d "%~dp0"

if not exist gen\registry.c (echo MISSING gen\ - run python tools\xlate.py & exit /b 1)
if not exist gen_snd\registry.c (echo MISSING gen_snd\ - run python tools\xlate.py sound & exit /b 1)
for %%d in (obj obj\win obj\win\gen obj\win\gen_snd obj\win\fw) do if not exist %%d mkdir %%d

rem ---- vendored framework, chip cores (their own warning level) ------------
cl /nologo /O2 /W3 /MD /D_CRT_SECURE_NO_WARNINGS /DUNICODE /D_UNICODE /c ^
   platform\windows\sys_gl.c platform\windows\glew.c ^
   platform\windows\log.c platform\windows\vector_draw.c ^
   platform\windows\mat4.c platform\windows\rawinput.c ^
   platform\windows\mixer.c platform\windows\fileio.c ^
   platform\windows\miniz.c platform\windows\ini.c ^
   platform\windows\joystick.c ^
   /Foobj\win\fw\ || exit /b 1
cl /nologo /O2 /W3 /std:c11 /MD /D_CRT_SECURE_NO_WARNINGS /I. /c c012294.c /Foobj\win\ || exit /b 1
cl /nologo /O2 /W3 /std:c++17 /EHsc /MD /D_CRT_SECURE_NO_WARNINGS /I. /c tms5220.cpp /Foobj\win\ || exit /b 1

rem ---- the chip models and the two programs ------------------------------
cl /nologo /O2 /W4 /std:c11 /MD /D_CRT_SECURE_NO_WARNINGS /I. /c avg.c mathbox.c x2212.c riot6532.c /Foobj\win\ || exit /b 1
del /q obj\win\gen\*.obj obj\win\gen_snd\*.obj 2>nul
cl /nologo /O2 /W3 /std:c11 /MD /D_CRT_SECURE_NO_WARNINGS /I. /c gen\*.c hand\*.c sw_rt.c /Foobj\win\gen\ || exit /b 1
cl /nologo /O2 /W3 /std:c11 /MD /D_CRT_SECURE_NO_WARNINGS /I. /c gen_snd\*.c /Foobj\win\gen_snd\ || exit /b 1
cl /nologo /O2 /W3 /std:c11 /MD /D_CRT_SECURE_NO_WARNINGS /DSW_SND_PROGRAM /I. /c sw_rt.c /Foobj\win\gen_snd\ || exit /b 1

rem ---- the machine and the backend ------------------------------------------
echo === sw_win.exe
cl /nologo /O2 /W4 /std:c++17 /EHsc /MD /D_CRT_SECURE_NO_WARNINGS /I. /c hw.cpp app.cpp port.cpp /Foobj\win\ || exit /b 1
cl /nologo /O2 /W4 /std:c11 /MD /D_CRT_SECURE_NO_WARNINGS /DUNICODE /D_UNICODE /I. /Foobj\win\ ^
   platform\windows\plat_win.c ^
   obj\win\hw.obj obj\win\app.obj obj\win\port.obj ^
   obj\win\avg.obj obj\win\mathbox.obj obj\win\x2212.obj obj\win\riot6532.obj ^
   obj\win\c012294.obj obj\win\tms5220.obj ^
   obj\win\gen\*.obj obj\win\gen_snd\*.obj obj\win\fw\*.obj ^
   /Fe:sw_win.exe ^
   /link /SUBSYSTEM:WINDOWS user32.lib gdi32.lib winmm.lib ole32.lib dwmapi.lib || exit /b 1

echo WIN BUILD OK
