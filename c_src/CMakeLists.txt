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

find_package(SDL2 REQUIRED)
find_package(OpenGL REQUIRED)

file(GLOB GEN_SRC     ${CMAKE_CURRENT_SOURCE_DIR}/gen/*.c ${CMAKE_CURRENT_SOURCE_DIR}/hand/*.c)
file(GLOB GEN_SND_SRC ${CMAKE_CURRENT_SOURCE_DIR}/gen_snd/*.c)

# The two programs: each compiles sw_rt.c its own way (the sound one through
# platform/sdl/sw_rt_snd.c, with SW_SND_PROGRAM), so each is a library of its own.
add_library(sw_main_prog STATIC ${GEN_SRC} sw_rt.c)
target_include_directories(sw_main_prog PUBLIC ${CMAKE_CURRENT_SOURCE_DIR})

add_library(sw_snd_prog STATIC ${GEN_SND_SRC} platform/sdl/sw_rt_snd.c)
target_include_directories(sw_snd_prog PUBLIC ${CMAKE_CURRENT_SOURCE_DIR})

add_executable(sw_sdl
    platform/sdl/plat_sdl.cpp
    hw.cpp app.cpp port.cpp
    avg.c mathbox.c x2212.c riot6532.c c012294.c tms5220.cpp)
target_include_directories(sw_sdl PRIVATE ${CMAKE_CURRENT_SOURCE_DIR})
target_link_libraries(sw_sdl PRIVATE sw_main_prog sw_snd_prog SDL2::SDL2 OpenGL::GL)
if(APPLE)
    target_compile_definitions(sw_sdl PRIVATE GL_SILENCE_DEPRECATION)
endif()

# The executable lands in c_src/, where the ini, log and NOVRAM live and the
# default rom_dir (../disasm/build) points.
set_target_properties(sw_sdl PROPERTIES RUNTIME_OUTPUT_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR})
