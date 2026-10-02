# c_src/cpu — the oracle's 6809 core

`cpu_m6809.cpp` and `cpu_m6809.h` are the MC6809 core of the
[AAE emulator](https://github.com/tcottrill/AAE) (Tim Cottrill, 2026), copied
unmodified. It is the only CPU core in this project and is used only by the
oracle and, later, the emulator twin; the C port has no CPU core at run time.

The other three files exist so the core compiles outside AAE:

| file | what |
|---|---|
| `deftypes.h` | AAE's integer types and memory-handler structs (as vendored for Tempest's `emu_src`) |
| `sys_log.h` | `LOG_INFO` and friends forwarded to `sw_cpu_log()`, which the board implements; the oracle treats any core message as a fault |
| `timer.h` | `timer_update()` as a no-op; the board keeps the timeline from the cycle count `step()` returns |

What the oracle relies on from the core, and how it is used:

- `step()` executes one instruction, or takes one pending interrupt, and
  returns its cycle count. Interrupts are taken only at the top of `step()`.
- `irq_line(true)` latches a request that the core clears when it takes the
  interrupt. The board re-asserts a line that is still active before every
  step, which gives level-sensitive behaviour.
- Documented opcodes only; cycle counts are the datasheet's, including the
  indexed-mode extras.
