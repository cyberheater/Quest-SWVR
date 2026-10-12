/* fiber.h - the few fiber calls port.cpp needs, on Win32 fibers, on
 * POSIX ucontext (Linux, macOS), or on a small switch of our own for
 * Android, whose C library has no makecontext/swapcontext (SW_FIBER_ASM,
 * on by default there; aarch64 and x86-64, so the same code can be tested
 * on a desktop with -DSW_FIBER_ASM=1).
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

#if defined(__ANDROID__) && !defined(SW_FIBER_ASM)
#define SW_FIBER_ASM 1
#endif

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

#elif defined(SW_FIBER_ASM) && SW_FIBER_ASM
#include <sys/mman.h>
#include <cstdlib>
#include <cstdint>

/* sw_fib_swap(&from->sp, to->sp): push the callee-saved registers on this
 * stack, park the stack pointer in *from, take up to's stack and pop its
 * registers; the return lands where to last called sw_fib_swap, or, for a
 * new fiber, in fib_entry. */
extern "C" void sw_fib_swap(void **from_sp, void *to_sp);

#if defined(__aarch64__)
/* x19-x28, x29 (fp), x30 (lr), d8-d15: 160 bytes, lr at +88 */
#define SW_FIB_FRAME 160
#define SW_FIB_RET   88
__asm__(
    ".text\n.p2align 2\n.globl sw_fib_swap\n"
#if !defined(__APPLE__)
    ".type sw_fib_swap,%function\n"
#endif
    "sw_fib_swap:\n"
    "  sub sp, sp, #160\n"
    "  stp x19, x20, [sp, #0]\n  stp x21, x22, [sp, #16]\n"
    "  stp x23, x24, [sp, #32]\n  stp x25, x26, [sp, #48]\n"
    "  stp x27, x28, [sp, #64]\n  stp x29, x30, [sp, #80]\n"
    "  stp d8, d9, [sp, #96]\n   stp d10, d11, [sp, #112]\n"
    "  stp d12, d13, [sp, #128]\n stp d14, d15, [sp, #144]\n"
    "  mov x2, sp\n  str x2, [x0]\n  mov sp, x1\n"
    "  ldp x19, x20, [sp, #0]\n  ldp x21, x22, [sp, #16]\n"
    "  ldp x23, x24, [sp, #32]\n  ldp x25, x26, [sp, #48]\n"
    "  ldp x27, x28, [sp, #64]\n  ldp x29, x30, [sp, #80]\n"
    "  ldp d8, d9, [sp, #96]\n   ldp d10, d11, [sp, #112]\n"
    "  ldp d12, d13, [sp, #128]\n ldp d14, d15, [sp, #144]\n"
    "  add sp, sp, #160\n  ret\n");
#elif defined(__x86_64__)
/* rbp, rbx, r12-r15, then the return address: 56 bytes, return at +48 */
#define SW_FIB_FRAME 56
#define SW_FIB_RET   48
__asm__(
    ".text\n.p2align 4\n.globl sw_fib_swap\n.type sw_fib_swap,@function\n"
    "sw_fib_swap:\n"
    "  pushq %rbp\n  pushq %rbx\n  pushq %r12\n  pushq %r13\n  pushq %r14\n  pushq %r15\n"
    "  movq %rsp, (%rdi)\n  movq %rsi, %rsp\n"
    "  popq %r15\n  popq %r14\n  popq %r13\n  popq %r12\n  popq %rbx\n  popq %rbp\n"
    "  ret\n");
#else
#error "SW_FIBER_ASM: no switch for this CPU"
#endif

struct fib_rec {
    void   *sp;
    void   *stack;
    size_t  size;
    void  (*fn)(void);
};
typedef fib_rec *fib_t;
typedef void (*fib_fn)(void);

static fib_rec *fib_current;

static void fib_entry(void)
{
    fib_current->fn();
    abort();                    /* port.cpp's fibers never return */
}
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
    f->fn = fn;
    /* a saved frame at the 16-aligned top, all zero but its return address;
     * on x86-64 the frame starts 16-aligned, so the ret into fib_entry
     * leaves rsp 8 past a boundary, as a call would */
    uintptr_t top = ((uintptr_t)f->stack + reserve - 64) & ~(uintptr_t)15;
    uintptr_t sp = top - SW_FIB_FRAME;
#if defined(__x86_64__)
    sp &= ~(uintptr_t)15;
#endif
    for (int i = 0; i < SW_FIB_FRAME; i += 8) *(uintptr_t *)(sp + i) = 0;
    *(uintptr_t *)(sp + SW_FIB_RET) = (uintptr_t)fib_entry;
    f->sp = (void *)sp;
    return f;
}
static inline void fib_switch(fib_t f)
{
    fib_rec *from = fib_current;
    fib_current = f;
    sw_fib_swap(&from->sp, f->sp);
}
static inline void fib_delete(fib_t f)
{
    if (!f) return;
    munmap(f->stack, f->size);
    free(f);
}

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
