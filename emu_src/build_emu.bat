@echo off
rem Build the Star Wars emulator twin (x64, VS2022 cl): sw_emu.exe in emu_src\,
rem next to sw_emu.ini / sw_emu.log / starwars.nv.
rem
rem   sw_emu.exe   the real ROMs on two 6809 cores (cpu\, AAE's core) on the chip
rem                models (hw.cpp, board.cpp), behind the same window, sound and
rem                controls as ..\c_src\sw_win.exe (the C port).
rem
rem Everything it is built from is in this directory: its own copies of the chip
rem models, the board and the Windows backend.  Nothing under ..\c_src is used.
rem
rem It reads the ROM images at run time from ..\disasm\build
rem (python ..\disasm\gen_from_roms.py).
call "C:\Program Files\Microsoft Visual Studio\2022\Community\Common7\Tools\VsDevCmd.bat" -arch=amd64 -no_logo
cd /d "%~dp0"

for %%d in (obj obj\fw) do if not exist %%d mkdir %%d

rem ---- vendored framework, chip cores, the 6809 core (their own warning level)
cl /nologo /O2 /W3 /MD /D_CRT_SECURE_NO_WARNINGS /DUNICODE /D_UNICODE /c ^
   platform\windows\sys_gl.c platform\windows\glew.c ^
   platform\windows\log.c platform\windows\vector_draw.c ^
   platform\windows\mat4.c platform\windows\rawinput.c ^
   platform\windows\mixer.c platform\windows\fileio.c ^
   platform\windows\miniz.c platform\windows\ini.c ^
   platform\windows\joystick.c ^
   /Foobj\fw\ || exit /b 1
cl /nologo /O2 /W3 /std:c11 /MD /D_CRT_SECURE_NO_WARNINGS /I. /c c012294.c /Foobj\ || exit /b 1
cl /nologo /O2 /W3 /std:c++17 /EHsc /MD /D_CRT_SECURE_NO_WARNINGS /I. /Icpu /c cpu\cpu_m6809.cpp tms5220.cpp /Foobj\ || exit /b 1

rem ---- the chip models, the board, the machine and the backend ---------------
cl /nologo /O2 /W4 /std:c11 /MD /D_CRT_SECURE_NO_WARNINGS /I. /c avg.c mathbox.c x2212.c riot6532.c /Foobj\ || exit /b 1
echo === sw_emu.exe
cl /nologo /O2 /W4 /std:c++17 /EHsc /MD /D_CRT_SECURE_NO_WARNINGS /I. /Icpu /c hw.cpp board.cpp emu_main.cpp /Foobj\ || exit /b 1
cl /nologo /O2 /W4 /std:c11 /MD /D_CRT_SECURE_NO_WARNINGS /DUNICODE /D_UNICODE /I. /Foobj\ ^
   platform\windows\plat_win.c ^
   obj\hw.obj obj\board.obj obj\emu_main.obj ^
   obj\avg.obj obj\mathbox.obj obj\x2212.obj obj\riot6532.obj ^
   obj\c012294.obj obj\cpu_m6809.obj obj\tms5220.obj ^
   obj\fw\*.obj ^
   /Fe:sw_emu.exe ^
   /link /SUBSYSTEM:WINDOWS user32.lib gdi32.lib winmm.lib ole32.lib dwmapi.lib || exit /b 1

echo EMU BUILD OK
