/* x2212.h - Xicor X2212 NOVRAM, 256 x 4 bits: a static RAM the CPU reads and
 * writes, and an EEPROM array behind it that only moves in bulk - a STORE
 * pulse copies RAM to EEPROM, the ARRAY RECALL line copies EEPROM to RAM.
 * After MAME's x2212 device, by way of AAE's starwars.cpp.
 */
#ifndef SW_X2212_H
#define SW_X2212_H

#include <stdint.h>

#ifdef __cplusplus
extern "C" {
#endif

typedef struct {
    uint8_t sram[256];
    uint8_t eeprom[256];          /* what survives power-off */
    int     recall_line;
    uint32_t n_store, n_recall, n_write;
} x2212;

void    x2212_init(x2212 *n);                     /* blank chip: EEPROM all ones */
void    x2212_power_on(x2212 *n);                 /* RAM side all ones, lines idle */
uint8_t x2212_read(const x2212 *n, uint8_t addr); /* high nibble reads as ones */
void    x2212_write(x2212 *n, uint8_t addr, uint8_t data);
void    x2212_store(x2212 *n);                    /* NSTORE strobe */
void    x2212_recall(x2212 *n, int line);         /* NVRRCL D7; recalls on its rising edge */

#ifdef __cplusplus
}
#endif
#endif
