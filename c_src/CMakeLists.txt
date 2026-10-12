# CMake build of the playable C port on SDL2 (macOS, Linux): sw_sdl, next to
# sw_sdl.ini / sw_sdl.log / starwars.nv in c_src/.  The Windows build stays
# build_win.bat (plat_win.c); this one uses platform/sdl/plat_sdl.cpp.
#
#   macOS:  brew install cmake sdl2
#   Linux:  apt install cmake libsdl2-dev libgl-dev
#   cmake -S c_src -B c_src/build -DCMAKE_BUILD_TYPE=Release
#   cmake --build c_src/build -j
#   python3 disasm/image.py            (once: the ROM images from roms/)
#   c_src/sw_sdl
cmake_minimum_required(VERSION 3.16)
project(sw_sdl C CXX)

set(CMAKE_C_STANDARD 11)
set(CMAKE_CXX_STANDARD 17)
if(NOT CMAKE_BUILD_TYPE)
    set(CMAKE_BUILD_TYPE Release)
endif()
if(MSVC)
    add_compile_definitions(_CRT_SECURE_NO_WARNINGS)
endif()

# The 3-D tap (sw3d.h): records where every vector sits in the game's 3-D
# space.  It only watches; off, the build is the plain port.
option(SW_3D "Build the 3-D tap" ON)

if(NOT ANDROID)
    find_package(SDL2 REQUIRED)
    find_package(OpenGL REQUIRED)
endif()

file(GLOB GEN_SRC     ${CMAKE_CURRENT_SOURCE_DIR}/gen/*.c ${CMAKE_CURRENT_SOURCE_DIR}/hand/*.c)
file(GLOB GEN_SND_SRC ${CMAKE_CURRENT_SOURCE_DIR}/gen_snd/*.c)

# The two programs: each compiles sw_rt.c its own way (the sound one through
# platform/sdl/sw_rt_snd.c, with SW_SND_PROGRAM), so each is a library of its own.
add_library(sw_main_prog STATIC ${GEN_SRC} sw_rt.c)
target_include_directories(sw_main_prog PUBLIC ${CMAKE_CURRENT_SOURCE_DIR})

add_library(sw_snd_prog STATIC ${GEN_SND_SRC} platform/sdl/sw_rt_snd.c)
target_include_directories(sw_snd_prog PUBLIC ${CMAKE_CURRENT_SOURCE_DIR})

# In the headset itself (a Quest, which is Android): libstarwars.so, the
# NativeActivity of platform/openxr/android/AndroidManifest.xml, from the same
# plat_openxr.cpp on OpenGL ES.  Configure with the NDK's toolchain file and
# -DOPENXR_ANDROID=<the unpacked org.khronos.openxr:openxr_loader_for_android
# .aar>; platform/openxr/android/build_quest.ps1 does all of it, to an .apk.
if(ANDROID)
    set(OPENXR_ANDROID "" CACHE PATH "The unpacked openxr_loader_for_android .aar")
    set(GLUE ${ANDROID_NDK}/sources/android/native_app_glue)
    add_library(openxr_loader SHARED IMPORTED)
    set_target_properties(openxr_loader PROPERTIES IMPORTED_LOCATION
        ${OPENXR_ANDROID}/prefab/modules/openxr_loader/libs/android.${ANDROID_ABI}/libopenxr_loader.so)
    add_library(starwars SHARED
        platform/openxr/plat_openxr.cpp ${GLUE}/android_native_app_glue.c
        hw.cpp app.cpp port.cpp sw3d.c
        avg.c mathbox.c x2212.c riot6532.c c012294.c tms5220.cpp)
    target_include_directories(starwars PRIVATE
        ${CMAKE_CURRENT_SOURCE_DIR} ${GLUE} ${OPENXR_ANDROID}/prefab/modules/headers/include)
    target_compile_definitions(sw_main_prog PUBLIC SW_3D)
    target_compile_definitions(sw_snd_prog PUBLIC SW_3D)
    target_compile_definitions(starwars PRIVATE SW_3D)
    target_link_libraries(starwars PRIVATE sw_main_prog sw_snd_prog openxr_loader android log EGL GLESv3 aaudio)
    return()
endif()

add_executable(sw_sdl
    platform/sdl/plat_sdl.cpp
    hw.cpp app.cpp port.cpp
    avg.c mathbox.c x2212.c riot6532.c c012294.c tms5220.cpp)
target_include_directories(sw_sdl PRIVATE ${CMAKE_CURRENT_SOURCE_DIR})
target_link_libraries(sw_sdl PRIVATE sw_main_prog sw_snd_prog SDL2::SDL2 OpenGL::GL)
if(SW_3D)
    target_sources(sw_sdl PRIVATE sw3d.c)
    target_compile_definitions(sw_main_prog PUBLIC SW_3D)
    target_compile_definitions(sw_snd_prog PUBLIC SW_3D)
    target_compile_definitions(sw_sdl PRIVATE SW_3D)
endif()
if(APPLE)
    target_compile_definitions(sw_sdl PRIVATE GL_SILENCE_DEPRECATION)
endif()
if(WIN32)
    # Windows' own OpenGL headers stop at 1.1: the vendored GLEW has the rest
    target_sources(sw_sdl PRIVATE platform/windows/glew.c)
endif()

# The executable lands in c_src/, where the ini, log and NOVRAM live and the
# default rom_dir (../disasm/build) points.
set_target_properties(sw_sdl PROPERTIES RUNTIME_OUTPUT_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR})

# The same game in a headset (Windows): sw_xr, platform/openxr/plat_openxr.cpp,
# on OpenXR with OpenGL - a Quest over Quest Link, or any PC headset.  It needs
# the 3-D tap and the OpenXR loader (vcpkg: openxr-loader).
if(WIN32 AND SW_3D)
    find_package(OpenXR CONFIG QUIET)
endif()
if(TARGET OpenXR::openxr_loader)
    add_executable(sw_xr
        platform/openxr/plat_openxr.cpp platform/windows/glew.c
        hw.cpp app.cpp port.cpp sw3d.c
        avg.c mathbox.c x2212.c riot6532.c c012294.c tms5220.cpp)
    target_include_directories(sw_xr PRIVATE ${CMAKE_CURRENT_SOURCE_DIR})
    target_compile_definitions(sw_xr PRIVATE SW_3D)
    target_link_libraries(sw_xr PRIVATE sw_main_prog sw_snd_prog SDL2::SDL2 OpenXR::openxr_loader OpenGL::GL)
    set_target_properties(sw_xr PROPERTIES RUNTIME_OUTPUT_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR})
endif()

# A multi-configuration generator (Visual Studio) would add Release/ to that
foreach(t sw_sdl sw_xr)
    if(TARGET ${t})
        foreach(c DEBUG RELEASE RELWITHDEBINFO MINSIZEREL)
            set_target_properties(${t} PROPERTIES RUNTIME_OUTPUT_DIRECTORY_${c} ${CMAKE_CURRENT_SOURCE_DIR})
        endforeach()
    endif()
endforeach()
