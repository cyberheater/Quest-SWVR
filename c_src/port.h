/* port.h - the C port as a machine (port.cpp), for app.cpp. */
#ifndef SW_PORT_H
#define SW_PORT_H

#include <stdint.h>
#include "board.h"

void     port_power_on(const sw_roms *roms, void (*pass_hook)(void));   /* after sw_hw_init() */
void     port_reset(void);                       /* the RESET line */
void     port_run_until(uint64_t target_cycle);  /* run both programs up to that cycle of the main clock */
uint8_t *port_main_mem(void);                    /* the main program's 64K: RAM, vector RAM, ROM */
uint64_t port_cycles(void);
unsigned long port_swi(void);                    /* times the program hit its own error trap */

#endif
