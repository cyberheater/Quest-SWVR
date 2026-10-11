/* fiber.h - the few fiber calls port.cpp needs, on Win32 fibers or on
 * POSIX ucontext (Linux, macOS).
 *
 * A fiber here is created with a stack reserve, entered with fib_switch(),
 * and deleted only while another fiber runs - port.cpp never deletes the
 * fiber it is on.  The POSIX stacks are mapped lazily (the main program's
 * reserve is 256 MB because the self test never returns from its calls, and
 * only the pages it touches are ever backed).
 */
#ifndef SW_FIBER_H
#define SW_FIBER_H

#include <stddef.h>

#ifdef _WIN32
#include <windows.h>

typedef LPVOID fib_t;
typedef void (*fib_fn)(void);

static inline fib_t fib_self(void) { return ConvertThreadToFiber(nullptr); }
static inline VOID CALLBACK fib_trampoline(LPVOID p) { ((fib_fn)p)(); }
static inline fib_t fib_create(size_t reserve, fib_fn fn)
{
    return CreateFiberEx(64 * 1024, reserve, 0, fib_trampoline, (LPVOID)fn);
}
static inline void fib_switch(fib_t f) { SwitchToFiber(f); }
static inline void fib_delete(fib_t f) { DeleteFiber(f); }

#else
#if defined(__APPLE__) && !defined(_XOPEN_SOURCE)
#define _XOPEN_SOURCE 600       /* ucontext is "deprecated" on macOS but present */
#endif
#include <ucontext.h>
#include <sys/mman.h>
#include <cstdlib>

struct fib_rec {
    ucontext_t ctx;
    void      *stack;
    size_t     size;
};
typedef fib_rec *fib_t;
typedef void (*fib_fn)(void);

static fib_rec *fib_current;

static inline fib_t fib_self(void)
{
    fib_rec *f = (fib_rec *)calloc(1, sizeof *f);
    fib_current = f;
    return f;
}
static inline fib_t fib_create(size_t reserve, fib_fn fn)
{
    fib_rec *f = (fib_rec *)calloc(1, sizeof *f);
    int flags = MAP_PRIVATE | MAP_ANON;
#ifdef MAP_NORESERVE
    flags |= MAP_NORESERVE;
#endif
    f->stack = mmap(nullptr, reserve, PROT_READ | PROT_WRITE, flags, -1, 0);
    if (f->stack == MAP_FAILED) { free(f); return nullptr; }
    f->size = reserve;
    getcontext(&f->ctx);
    f->ctx.uc_stack.ss_sp = f->stack;
    f->ctx.uc_stack.ss_size = reserve;
    f->ctx.uc_link = nullptr;
    makecontext(&f->ctx, fn, 0);
    return f;
}
static inline void fib_switch(fib_t f)
{
    fib_rec *from = fib_current;
    fib_current = f;
    swapcontext(&from->ctx, &f->ctx);
}
static inline void fib_delete(fib_t f)
{
    if (!f) return;
    munmap(f->stack, f->size);
    free(f);
}
#endif

#endif
