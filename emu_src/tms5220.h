/* tms5220.h - the chip core of AAE's TMS5220 (see tms5220.cpp for the notice).
 * One chip.  The board clocks it with tms5220_process(), one sample at a time. */
#ifndef tms5220_h
#define tms5220_h

void tms5220_reset(void);
void tms5220_set_irq(void (*func)(void));

void tms5220_data_write(int data);
int  tms5220_status_read(void);
int  tms5220_ready_read(void);          /* 1 = ready for a byte */
int  tms5220_int_read(void);

void tms5220_process(short* buffer, unsigned int size);

#endif
