/* mainline.c - WAITFRAME ($6005) and MAIN ($6036), written by hand.
 *
 * The ROM's mainline is one endless loop built from two labels:
 *
 *     WAITFRAME: wait for the interrupt's frame tick (GMSYNC)
 *                if S is not the top of the stack, RTS      <- called for a delay
 *                freeze / single-step switches
 *                JSR IFRAME, wait for the display buffer (VGSYNC)
 *     MAIN:      JSR [phase table]
 *                BRA WAITFRAME
 *
 * WAITFRAME is also called as a subroutine: a routine that wants one frame's
 * delay does JSR WAITFRAME, and "CMPS #STACK" tells the two uses apart.  The
 * translator would turn the BRA into a call and recurse forever, so the loop is
 * written out here.  Statement for statement it is what the translator emits,
 * the cycle counts included (gen/cycles.txt).
 *
 * sw_pass() marks the start of a game frame ($602F): the verifier compares
 * whole passes between two of them, and the host presents a frame there.
 */
#include "../sw.h"
#include "../gen/sw_defs.h"
#include "../gen/sw_proto.h"

/* L6036-L6042: run the current phase's routine, and back to WAITFRAME */
static void main_body(void)
{
    uint16_t ea;
    CK(0x6036);
    A = M8(PHASE);                                   /* L6036  EXECUTE PHASE */
    CYC(9);
    if (A >= PHS_EQ)                                 /* L6038  CMPA #PH$EQ */
        sw_swi(0x603A);                              /* L603A  BHS to itself: DIE ON BAD PHASE (hangs for the watchdog) */
    A = (uint8_t)(A << 1);                           /* L603C */
    X = TPHASE;                                      /* L603D */
    ea = rd16((uint16_t)(X + (int8_t)A));            /* L6040  JSR [A,X] */
    CYC(16);
    S = (uint16_t)(S - 2); call_rom(ea);
    CYC(3);                                          /* L6042  BRA WAITFRAME */
}

/* L602F-L6040: one game frame */
static void frame_body(void)
{
    CYC(8);
    JSR(iframe);                                     /* L602F  INIT GAME FRAME */
    do {
        CK(0x6032);
        A = M8(VGSYNC);                              /* L6032  NON-NEGATIVE VALUE INDICATES BUFFER READY */
        CYC(7);
    } while (A & 0x80);                              /* L6034  PLEND */
    main_body();
}

/* @hand WAITFRAME */
void waitframe(void)
{
    for (;;) {
        CK(0x6005);
        X = 0x0000;                                  /* L6005  TALK TO DEV SYS */
        D = 0xF800;                                  /* L6008  PATCH TO 0BD TO TURN ON (JSR) */
        A = DPRAM / 0x100;                           /* L600B */
        DP = A;                                      /* L600D */
        CYC(14);
        CK(0x600F);
        M8(GMSYNC) = lsr8(M8(GMSYNC));               /* L600F  PROCESS GAME FRAMES IN TIMELY FASHION */
        CYC(9);
        if (!CCC) continue;                          /* L6011  BCC WAITFRAME */
        cmp16(S, STACK);                             /* L6013  CMPS #STACK */
        CYC(8);
        if (!CCZ) {                                  /* L6017  IFNE  ?SOME FRAME NEEDS A DELAY? */
            CYC(5);
            RTS;                                     /* L6019  THEN LET IT CONTINUE */
        }
        CK(0x601A);
        A = M8(PT_DLY);                              /* L601A */
        CYC(7);
        if (A == 0) {                                /* L601C  IFEQ  ?FAR ENUF INTO POWER ON? */
            /* PREVENT STARTUP BLANK STARES */
            CK(0x601E);
            A = M8(IN_SW2);                          /* L601E  LOOK AT FREEZE SWITCH (BT7 OPTION BANK 1) */
            A &= BT7;                                /* L6021  FREEZE? */
            CYC(10);
            if (A == 0) {                            /* L6023  IFEQ  ?SWITCH ON? THEN FREEZE */
                A = M8(VG_LON);                      /* L6025  USE LEFT FIRE BIT FOR SINGLE STEPPING */
                CYC(9);
                if ((A & LFIRBT) == 0) continue;     /* L6029  B NO LEFT EDGE, SO LOOP FOREVER (ALMOST) */
                /* ELSE SINGLE STEP JUST THIS TIME */
                A &= (uint8_t)(-1 - LFIRBT);         /* L602B  CLEAR OUT THIS BIT ONLY, RIGHT STILL FIRES */
                M8(VG_LON) = A;                      /* L602D  JUST TESTING, SO IGNORE SEI/CLI */
                CYC(6);
            }
        }
        sw_pass(0x602F);
        frame_body();
    }
}

/* @hand MAIN */
void main_(void)
{
    main_body();                                     /* RESET arrives here: JMP MAIN */
    waitframe();
}

/* The verifier's entry for one pass: from $602F round to $602F. */
void sw_resume_frame(void)
{
    frame_body();
    waitframe();
}
