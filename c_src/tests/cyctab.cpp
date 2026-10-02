/* cyctab.cpp - the cycle count of every instruction of a program, taken from
 * the 6809 core the oracle runs (cpu/cpu_m6809.cpp): the C port charges exactly
 * what the oracle's CPU is charged.
 *
 *     cyctab main  INSNS OUT      (gen\insns.txt   -> gen\cycles.txt)
 *     cyctab sound INSNS OUT      (gen_snd\insns.txt -> gen_snd\cycles.txt)
 *
 * INSNS: "bank address ..." per line.  OUT: "bank address min max" - the cost
 * with each of the sixteen N Z V C combinations; min and max differ only for
 * the long conditional branches (5 not taken, 6 taken).
 *
 * A 6809 instruction's cost depends on its opcode and postbyte only (and, for
 * RTI, on the E flag it pulls: the stack here reads $FF, a full frame, as every
 * RTI of these programs returns from IRQ).
 */
#include <cstdio>
#include <cstdlib>
#include <cstring>
#include <cstdint>
#include <string>
#include <vector>
#include "../cpu/cpu_m6809.h"

static uint8_t rom[0x10000], bank1[0x2000];
static int bank, sound;

extern "C" void sw_cpu_log(const char *, ...) {}

static UINT8 rd(UINT32 a, struct MemoryReadByte *)
{
    if (sound) {
        a &= 0x7fff;
        return a >= 0x4000 ? rom[a] : 0xff;
    }
    if (a >= 0x6000 && a < 0x8000 && bank) return bank1[a - 0x6000];
    if (a >= 0x6000 || (a >= 0x3000 && a < 0x4000)) return rom[a];
    return 0xff;
}
static void wr(UINT32, UINT8, struct MemoryWriteByte *) {}
static MemoryReadByte r_[] = { { 0x0000, 0xffff, rd, nullptr }, { 0xffffffff, 0, nullptr, nullptr } };
static MemoryWriteByte w_[] = { { 0x0000, 0xffff, wr, nullptr }, { 0xffffffff, 0, nullptr, nullptr } };

static void load(const char *path, uint8_t *dst, size_t n)
{
    FILE *f = fopen(path, "rb");
    if (!f || fread(dst, 1, n, f) != n) { fprintf(stderr, "cyctab: cannot read %s\n", path); exit(2); }
    fclose(f);
}

int main(int argc, char **argv)
{
    static uint8_t dummy[0x10000];
    if (argc != 4) { fprintf(stderr, "usage: cyctab main|sound INSNS OUT\n"); return 2; }
    sound = !strcmp(argv[1], "sound");
    if (sound) load("..\\disasm\\build\\starwars_sound.bin", rom, 0x10000);
    else {
        load("..\\disasm\\build\\starwars_main_rev2.bin", rom, 0x10000);
        load("..\\disasm\\build\\starwars_bank1.bin", bank1, 0x2000);
    }
    cpu_m6809 cpu(dummy, r_, w_, 0);
    cpu.mame_memory_handling(true);

    FILE *in = fopen(argv[2], "r"), *out = fopen(argv[3], "w");
    if (!in || !out) { fprintf(stderr, "cyctab: cannot open %s / %s\n", argv[2], argv[3]); return 2; }
    char line[128];
    unsigned n = 0;
    while (fgets(line, sizeof line, in)) {
        unsigned b, a;
        if (sscanf(line, "%u %x", &b, &a) != 2) continue;
        int lo = 1000, hi = 0;
        bank = (int)b;
        for (int f = 0; f < 16; f++) {
            cpu.reset();
            cpu.SetPC((uint16_t)a); cpu.SetS(0x4f80); cpu.SetU(0x4e80); cpu.SetX(0x4900); cpu.SetY(0x4a00);
            cpu.SetD(0x0102); cpu.SetDP(0x48);
            cpu.SetCC((uint8_t)(0xd0 | f));
            int c = cpu.step();
            if (c < lo) lo = c;
            if (c > hi) hi = c;
        }
        fprintf(out, "%u %04X %d %d\n", b, a, lo, hi);
        n++;
    }
    fclose(in);
    fclose(out);
    printf("cyctab: %u instructions\n", n);
    return 0;
}
