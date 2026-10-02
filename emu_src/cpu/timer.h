// timer.h - shim for the vendored cpu_m6809 core (AAE).  The core tells AAE's
// timer system how many cycles each step took; the board keeps its own
// timeline from the value step() returns, so this does nothing.
#pragma once

static inline void timer_update(int /*cycles*/, int /*cpu*/) {}
