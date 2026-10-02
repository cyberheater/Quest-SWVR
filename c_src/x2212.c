/* x2212.c - Xicor X2212 NOVRAM (x2212.h). */
#include <string.h>
#include "x2212.h"

void x2212_init(x2212 *n)
{
    memset(n, 0, sizeof *n);
    memset(n->eeprom, 0xff, sizeof n->eeprom);
    x2212_power_on(n);
}

void x2212_power_on(x2212 *n)
{
    memset(n->sram, 0xff, sizeof n->sram);
    n->recall_line = 0;
}

uint8_t x2212_read(const x2212 *n, uint8_t addr)
{
    return (uint8_t)((n->sram[addr] & 0x0f) | 0xf0);
}

void x2212_write(x2212 *n, uint8_t addr, uint8_t data)
{
    n->sram[addr] = data & 0x0f;
    n->n_write++;
}

void x2212_store(x2212 *n)
{
    memcpy(n->eeprom, n->sram, sizeof n->eeprom);
    n->n_store++;
}

void x2212_recall(x2212 *n, int line)
{
    line = line != 0;
    if (line && !n->recall_line) {
        memcpy(n->sram, n->eeprom, sizeof n->sram);
        n->n_recall++;
    }
    n->recall_line = line;
}
