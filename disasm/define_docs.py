"""Descriptions written for this disassembly, for the defines files.

Used by emit_defines.py only for a symbol whose definition carries no comment in
Atari's source (or only a ditto mark), or carries one that is about something else
(REPLACE, and the counters a macro steps).  Atari's comments are upper case; these are
not, which is how the two are told apart in the defines files.  Each was written
from the source statement that defines the symbol and from the code that uses it.
Keyed by defines file ("main", "sound"), then by the identifier as the file prints it.

emit_defines.py reports a note whose identifier is not in the file, or whose
definition has a comment of Atari's after all.
"""

def _hl(d, base, text):
    """A math RAM word and its two halves."""
    d[base] = text
    d[base + "H"] = text[:-1] + ", high byte."
    d[base + "L"] = text[:-1] + ", low byte."

MAIN = {
    # ---- hardware registers
    "R_BYT0": "Read: switch byte 0, active low. D7 left fire/start, D6 right fire/start, D5 spare 1, D4 self test, D3 slam, D2 aux coin, D1 left coin, D0 right coin.",
    "IN0": "R_BYT0 under its other name; the self test reads the fire switches here.",
    "S_LAM": "Port the coin routine reads the slam switch from (bit S_LMBIT of R_BYT0).",
    "R_BYT1": "Read: switch byte 1. D7 math box running, D6 VG halted, D5 left thumb, D4 right thumb, D3 spare 2, D2 diagnostic step; D1, D0 unused. Switches active low.",
    "IN1": "R_BYT1 under its other name; the self test reads the thumb switches here.",
    "DIAGSW": "Port with the diagnostic switch (bit DIAGBT of R_BYT1).",
    "EEROM": "NVRAM under the name the accounting code uses; the four checksummed areas are laid out from here.",
    "NVRAMZ": "End of the non-volatile RAM (limit of the self test's loops).",
    "EEROMZ": "End of the non-volatile RAM (limit of the EEROM copy and swap loops).",
    "W_LED3": "LED 3, D7=0 turns it on (Atari's comment is a ditto mark under W_LED1).",
    "W_LED2": "LED 2, D7=0 turns it on (Atari's comment is a ditto mark under W_LED1).",
    "M_QUO": "Read: the divider's 16-bit quotient (M_QUOH, M_QUOL). With the numerator left at $0200 it is the reciprocal used for perspective.",
    "M_DVD": "Write: the divider's 16-bit denominator (M_DVDH, M_DVDL); writing the low byte starts the divide.",
    "M_DVN": "Write: the divider's 16-bit numerator (M_DVNH, M_DVNL); normally left at $0200.",

    # ---- block index (BIC) values and sizes
    "MS_S1BC": "BIC of the player's ship block (the 4 blocks starting at M_S1-$10); IS1UV downloads it as ship 1.",
    "PNLWS_IZ": "Size of the left wall panel table (PNLWZ-PNLW); the view backs up by it to wrap around.",
    "PNRWS_IZ": "Size of the right wall panel table (PNRWZ-PNRW).",
    "MS_EYEBC": "BIC of the M_EYE block. Not used.",
    "MS_MUNBC": "BIC of the munge block M_MUN, the unit vectors the explosion pieces are turned with.",
    "MS_ALBC": "BIC of the first alien's unit vector block (M_AL); each alien record gets the next 4 blocks.",
    "MS_GNBC": "BIC of the first gun shot point (M_GN); each gun record gets the next block.",

    # ---- CPU RAM
    "R_CTRL": "Debounced switch byte 0 (IN_SW0) as the control switches. Not used.",
    "R_FIRE": "Debounced switch byte 0 (IN_SW0) as the fire switches, bits FIREBT.",
    "R_THMB": "Debounced switch byte 1 (IN_SW1) as the thumb switches, bits THMBT.",
    "PT_VL": "Filtered pot values, PTS_IZ bytes each: PT_VL1 then PT_VL2. DOPOTS indexes from here.",
    "PT_VLZ": "End of the pot values.",
    "GMTIMR": "IRQ countdown to the next game frame: reloaded with 11, so every 12th IRQ (50 ms) bumps GMSYNC.",
    "VGSYNC": "Display list buffer handshake. VGDONE stores $FF when the list is finished; the IRQ then swaps buffers and stores the high address byte of the buffer the mainline may build in.",
    "VGTIMR": "IRQ countdown for the vector generator: set to 5 when it is started; once minus, the next field starts as soon as the VG has halted; on overflow the VG is stopped and the pseudo ROM reloaded.",
    "PHASE": "Game phase: index into TPHASE, which the mainline executes each frame. PHS_xxx is a phase's init entry; init steps PHASE on to its execute entry.",
    "FRAME": "Game frame counter, 16 bits, bumped by IFRAME; the high byte restarts at $80 when the word overflows.",
    "FRAMEH": "Game frame counter, high byte.",
    "FRAMEL": "Game frame counter, low byte; its bits time the flashing and alternating displays.",
    "RND_S1": "Newest of the three saved random bytes; RND8 reads P_RND1 into it.",
    "RND_S2": "Second saved random byte (the previous RND_S1).",
    "RND_S3": "Third saved random byte (the previous RND_S2).",
    "S1_PRM": "Pointer to the alien record the computer-drone routines (CPU, CPUAL) are working on.",
    "S2_PRM": "Pointer to the record the view and aim routines are working on: an alien (SNVW, S2VW, AIM) or a wall panel (PNVLW, PNVRW).",
    "RHEO": "Rheostat (yoke pot) blocks, RHS_IZ bytes each: pitch RHEOP, then yaw RHEOY.",
    "ST_CNT": "Stars left to convert in VWSTAR / VWSTRG (count from the star BICs).",
    "GN_SWO": "Gun control switches (fire, thumb, aux) as IFRAME saw them last frame.",
    "GN_SWN": "Gun control switches as IFRAME sees them this frame.",
    "GN_SWE": "Gun control switch edges this frame: a 1 is a switch that just went on. Start, aux and option handling test this.",
    "TTEMP2": "Self test temp: the message number being shown (hardware errors, switch names).",
    "ERRPNT": "Self test: pointer into BITS, the error bit the sound-off display has reached.",
    "ERRCNT": "Self test: frames to the next error sound ($10 between bits, $20 before starting over).",
    "WV_LVL": "Level within the current set of space waves (index NWNSHP and ADASHP use). The Death Star select screen uses it as the cursor flag, minus when on no Death Star.",
    "ZSUM": "End of the CHKSUM words.",
    "ALIENZ": "End of the alien records.",
    "GUNS": "The gun shot records under the name the gun routines use: GS_EQ records of GS_IZE bytes.",
    "GUNA": "The gun shot records again. Not used.",
    "GUNSZ": "End of the gun shot records. Not used.",
    "GUNAZ": "End of the gun shot records. Not used.",
    "GUNZ": "End of the gun shot records (limit of every gun loop).",
    "BJBIC": "One byte per object shape (BJS_EQ of them): the BIC of its points in math RAM, 0 while they are not loaded.",
    "BJBICZ": "End of the object BIC list.",
    "PANEL": "Trench wall panel flags: 16 bytes for the left wall (PNLW), then 16 for the right (PNRW).",
    "PNLWZ": "End of the left wall panels.",
    "PNRWZ": "End of the right wall panels.",
    "PANELZ": "End of the panel flags.",
    "GDRAMZ": "End of the ground RAM values.",
    "XPQUEZ": "End of the explosion queue.",
    "MESBLK": "Numbers of the messages now on, up to MESS_EQ of them; MESLST points past the last.",
    "SPMBLK": "Special (moving banner) messages now on: SPMS_EQ entries of SPMS_IZ bytes; SPMLST points past the last.",
    "SPMBLZ": "End of the special message block.",
    "HSCORS": "High score table: NHSCRS scores of NDIGTS BCD bytes, best first.",
    "HSCORZ": "End of the high score table.",
    "INITLS": "High score initials: NINTLS bytes per score (0-26).",
    "INITLZ": "End of the initials.",
    "NXTMES": "Next message number to turn on in a page that appears line by line (VWPAGE); $80 when there are no more.",
    "LSTMES": "Last message number + 1 of that page.",
    "BN_CNT": "Banner frame counter: under $40 STAR WARS brightens in place, to $F8 it shrinks away (the count is its scale), then the story messages run.",
    "BN_COL": "Banner colour instruction: the brightness rises by 3 a frame, then dims as the banner shrinks.",
    "BN_SCL": "Banner scale instruction, written into the banner's display list.",
    "TEMP": "Four bytes of scratch: BCD sums of the accounting, EEROM values on their way in and out, distances in the Death Star select hit test.",
    "TEMP2": "Four more bytes of scratch: the second operand of the accounting sums.",
    "TMPCNT": "Scratch counter and carry of the BCD and EEROM routines.",
    "PH_YOF": "Message Y offset of the current phase (scroll); copied to MSYOFF.",
    "PH_TIM": "Phase timer: set by a phase's init entry and counted by its execute entry, which moves on when it runs out.",
    "PH_COL": "Colour instruction for the current phase's messages; its brightness byte is stepped down to fade a page out.",
    "RPIEZ": "End of the random pies.",
    "ST_QU": "Star queues: STS_EQQ screen sectors of STS_IZQ bytes each. Shares the large temp area with BJ_PNT, LZPNT and EEBUF.",
    "ST_QUZ": "End of the star queues.",
    "ST_PNT": "Vectorized star points: STS_EQP entries of STS_IZP bytes.",
    "ST_PNZ": "End of the star points.",
    "EEBUF": "256 byte buffer the EEROM is copied to and swapped with while it is recalled and checked.",
    "LZPNTZ": "End of the lazar points.",

    # ---- math RAM
    "M_X1": "Start of the unit vector blocks ($20 bytes each: player, eye, munge, aliens). M_S1 points $10 in.",
    "M_EYE": "Unit vector block after the player's (pointer to its middle). Not used.",
    "M_MUN": "Munge unit vector block (pointer to its middle): the matrix the explosion pieces tumble with.",
    "M_AL": "First of the alien unit vector blocks (pointer to its middle; room for four); IPGEN hands one to each alien record.",
    "M_ALZ": "Middle pointer one block past the last alien block.",
    "M_GN": "Gun shot points, one 8 byte block (X, Y, Z) per gun record, right after the alien blocks.",
    "M_GNZ": "End of the gun shot points.",

    # ---- labels another listing defines
    "VGSITE": "Player's gun site picture. Its first word is a JSRL to the picture at VGSITE+2, which VWCURC copies into the display list.",
    "IRQ": "The IRQ handler (4 ms): coins, switches, pots, sound board check, and the vector generator restart.",
    "RESET": "The RESET entry: stops the VG, clears RAM, reads the option switches, then self test or game.",
    "JADBOBJ": "ADBOBJ: add object B's points to the math box (BJ_ID = B, then ADOBJ).",
    "JADOBJ": "ADOBJ: copy the points of object BJ_ID from ROM to math RAM unless BJBIC says they are there.",
    "JBJCNTR": "BJCNTR: project an object's centre. Expects the VG at centre and the divide started; same entry as OBJCEN.",
    "JOBJCEN": "OBJCEN: project an object's centre (quotient to M_XP, MS_PERS) and draw to it; leaves BJ_CX, BJ_CY.",
    "JOBJBPNT": "OBJBPNT: perspective every point of object B into BJ_PNT (BJ_ID = B, then OBJPNT).",
    "JOBJPNT": "OBJPNT: perspective every point of object BJ_ID into BJ_PNT (MS_PAD, 1/X, MS_PERS).",
    "JOBJDRW": "OBJDRW: draw object BJ_ID from its line list (TDRWLN) and the points in BJ_PNT.",
    "JBJGDRW": "BJGDRW: draw ground type object BJ_ID by running the code in its TDRWLN entry.",
    "JVWSTAR": "VWSTAR: view the stars in space, sorted into the screen sector queues.",
    "JVWSTRG": "VWSTRG: view the stars over the ground.",

    # ---- constants: TCEROM
    "CNT": "SUMMIT's stack frame: bytes left to sum.",
    "NEWSUM": "SUMMIT's stack frame: the checksum being formed.",
    "OLDSUM": "SUMMIT's stack frame: the checksum stored in the EEROM area, to compare with.",

    # ---- constants: checksums, bits, direct page
    "VGCKS0": "Checksum word of the vector ROM, its first word ($3000).",
    "PCKS1": "Checksum word of program ROM 1, assembled at CHKSM1.",
    "PCKS2": "Checksum word of program ROM 2, assembled at CHKSM2.",
    "PCKS3": "Checksum word of program ROM 3, assembled at CHKSM3.",
    "PCKS4": "Checksum word of program ROM 4, assembled at CHKSM4 ($FFF0).",
    "DPRAM": "Direct page base: the first 256 bytes of CPU RAM.",

    # ---- constants: WSCPU choreography
    "CS_R1": "Choreography status: random bit 1, taken from P_RND1 on every pass and tested by .CIF.",
    "CS_R2": "Choreography status: random bit 2.",
    "CS_RL": "Twirl flag (AS_CHTW): roll left.",
    "CS_RR": "Twirl flag: roll right.",
    "CS_PU": "Twirl flag: pitch up.",
    "CS_PD": "Twirl flag: pitch down.",
    "CS_YR": "Twirl flag: yaw right.",
    "CS_YL": "Twirl flag: yaw left.",
    "CS_T9": "Twirl flag: aim in front of the player (the target point is moved $1000 ahead).",
    "CS_T0": "Twirl flag: aim at the player.",
    "CS_MF3": "Move flags (AS_CHMV): forward and forward twice together.",
    "CS_MU3": "Move flags: up and up twice together.",
    "CS_MD3": "Move flags: down and down twice together.",

    # ---- constants: WSGLOB equates
    "RAMZ": "End of CPU RAM (limit of RESET's clear loop).",
    "VGBASE": "Base address of the vector generator's address space; a VG opcode holds (address - VGBASE) / 2.",
    "VGRAM": "Start of vector RAM. The first word is the JMPL to the buffer being drawn; the VR variables follow it.",
    "VGRAMZ": "End of the two display list buffers.",
    "VGROM": "Start of the pseudo vector ROM in vector RAM (same as VGPSROM); RESET clears vector RAM up to here.",
    "VGROMZ": "End of the vector ROM.",
    "AUXBIT": "Aux coin switch bit in AUXSW (and in the debounced copy).",
    "DIAGBT": "Diagnostic switch bit in DIAGSW.",

    # ---- constants: math processor
    "M_BASE": "Start of math RAM (RESET's clear loop).",
    "M_FIN": "End of math RAM.",
    "MS_U1BC": "BIC of the ship 1 download block (M_AX1, $5028) that roll, pitch and yaw work on.",
    "MS_BJBC": "BIC of M_OBJ, the first object point; JINOBJ starts the allocation here.",
    "MS_GDBC": "BIC of M_GD, the ground transform block.",
    "MS_GDNM": "Number of 8 byte blocks from M_GD to M_GDZ. Not used.",
    "MS_STBC": "BIC of M_STAD, the first star.",
    "MS_AX": "Offset from a unit vector block's middle pointer (M_S1, M_U1, AS_UVP) to unit vector A, X. Offsets are signed: $FFF0 is -16.",
    "MS_AY": "Offset to unit vector A, Y.",
    "MS_AZ": "Offset to unit vector A, Z.",
    "MS_BX": "Offset to unit vector B, X.",
    "MS_BY": "Offset to unit vector B, Y.",
    "MS_BZ": "Offset to unit vector B, Z.",
    "MS_CX": "Offset to unit vector C, X.",
    "MS_CY": "Offset to unit vector C, Y.",
    "MS_CZ": "Offset to unit vector C, Z.",
    "MS_TX": "Offset to the universe location, X (the T block).",
    "MS_TY": "Offset to the universe location, Y.",
    "MS_TZ": "Offset to the universe location, Z.",
    "MS_VX": "Offset to the X velocity, kept in the spare fourth word of the A block.",
    "MS_VY": "Offset to the Y velocity, kept in the spare fourth word of the B block.",
    "MS_VZ": "Offset to the Z velocity, kept in the spare fourth word of the C block.",

    # ---- constants: record sizes and counts
    "PTS_IZ": "Bytes per pot value.",
    "GS_IZE": "Bytes per gun shot record.",
    "GS_EQ": "Number of gun shot records.",
    "BJS_EQ": "Number of BJBIC slots, the most object shapes there can be.",
    "GDS_TYP": "Offset in a ground RAM entry: the tower's TYPS_ flags (alive, view, damaged, aim, bunker).",
    "GDS_IZ": "Bytes per ground RAM entry.",
    "GDS_EQ": "Number of ground RAM entries.",
    "XPS_IZE": "Bytes per explosion queue entry.",
    "MESS_EQ": "Most messages on at once (size of MESBLK).",
    "SPMS_EQ": "Number of special message entries.",
    "SPMS_IZ": "Bytes per special message entry.",
    "NHSCRS": "Number of high scores kept.",
    "NINTLS": "Initials per high score.",
    "NDIGTS": "BCD bytes per high score (8 digits).",
    "STS_IZQ": "Bytes per star queue (one per screen sector).",
    "STS_IZP": "Bytes per vectorized star point.",

    # ---- constants: guns
    "MOVS_ST": "Gun move routine number (GS_MOV, index into TMOVE): stay in place.",
    "MOVS_AM": "Gun move routine: aim at the player (an alien's shot).",
    "MOVS_WF": "Gun move routine: tower gun, forward.",
    "MOVS_WL": "Gun move routine: tower gun, left diagonal.",
    "MOVS_WR": "Gun move routine: tower gun, right diagonal.",
    "MOVS_BL": "Gun move routine: left bunker gun.",
    "MOVS_BR": "Gun move routine: right bunker gun.",
    "MOVS_PL": "Gun move routine: left wall panel gun.",
    "MOVS_PR": "Gun move routine: right wall panel gun.",
    "GDS_MNT": "Minimum player height over the ground; a bunker's shot starts at this height.",

    # ---- constants: routine temps (TEMP macro: direct page $4801-$4808, shared by all)
    "TMPCOL": "Temp of VWHSCR: the colour of the line being drawn, for the initial that flashes while it is entered.",
    "TMPABS": "Temp of GETINT: absolute X distance from the cursor to a letter, for the octagon hit test.",
    "TMPLP": "Temp of CPHTSA (alien hit by the player): loop counter over the three axes.",
    "TMPGRM": "Temp of FRBFGN: pointer to the gun record being set up.",
    "TMPBIN": "Temp of GN1DRW: binary scale for the gun shot picture.",
    "TMPLIN": "Temp of GN1DRW: linear scale for the gun shot picture.",
    "TMPDX": "Temp of VWLAZ: X distance the lazar line still has to draw.",
    "TMPDY": "Temp of VWLAZ: Y distance the lazar line still has to draw.",
    "TMPTX": "Temp of CLBLZ: X of the lazar's far end in the trench, then of the point it hits.",
    "TMPTY": "Temp of CLBLZ: Y (left/right) of the lazar's far end, then of the point it hits.",
    "TMPTZ": "Temp of CLBLZ: Z (up/down) of the lazar's far end, then of the point it hits.",
    "TMPMSK": "Temp of LZCPNW / LZHPN: 2-bit mask of the wall panel under test.",
    "TMPFLG": "Temp of LZHPN: that panel's type bits.",
    "TMPSCL": "Temp of DTHVW: scale instruction for the Death Star stamps.",
    "TMPVX": "Temp of DTHVW: second word of the vector to the Death Star's centre.",
    "TMPVY": "Temp of DTHVW: first word of the vector to the Death Star's centre.",
    "TMPSIZ_4801": "Temp of S2VW: the alien's size on screen plus the cursor's, for the lazar hit test.",
    "TMPOCT_4803": "Temp of S2VW: X distance + Y distance, for the octagon test.",
    "TMPXD": "Temp of S2VW: absolute X distance from the alien's centre to the lazar.",
    "TMPYD": "Temp of S2VW: absolute Y distance from the alien's centre to the lazar.",
    "TMPCNT_4801": "Temp of ADOBJ and OBJPNT: points left to do.",
    "TMPTP1": "Temp of the explosion starters (BGBKXP, BGTWXP): piece type for the left piece.",
    "TMPTP2": "Temp of the explosion starters: piece type for the centre piece.",
    "TMPTP3": "Temp of the explosion starters: piece type for the right piece.",
    "TMPVZ": "Temp of the explosion starters: high byte of the pieces' upward speed.",

    # ---- constants: objects and explosion pieces
    "TDS_TIE": "Object number: TIE fighter.",
    "TDS_RTH": "Object number: Darth Vader's TIE fighter.",
    "TDS_WFG": "Object number: the wall force field's points again, drawn bright when it is hit.",
    "TPS_BK1": "Explosion piece type (index into TMV and TVW): bunker piece 1.",
    "TPS_BK2": "Explosion piece type: bunker piece 2.",
    "TPS_BK3": "Explosion piece type: bunker piece 3.",
    "TPS_TW1": "Explosion piece type: tower top piece 1.",
    "TPS_TW2": "Explosion piece type: tower top piece 2.",
    "TPS_TW3": "Explosion piece type: tower top piece 3.",
    "TPS_TI1": "Explosion piece type: TIE fighter piece 1.",
    "TPS_TI2": "Explosion piece type: TIE fighter piece 2.",
    "TPS_TI3": "Explosion piece type: TIE fighter piece 3.",

    # ---- constants: vector ROM
    "CHAR_0": "Character picture for 0: the letter O's.",
    "CHAR_5": "Character picture for 5: the letter S's.",
    "VJPERD": "JSRL to the period.",
    "VGCURB": "Cursor limit, bottom, in pot units (screen units / 4).",
    "VGCURL": "Cursor limit, left, in pot units.",
    "VGCURR": "Cursor limit, right, in pot units.",
    "VGCURT": "Cursor limit, top, in pot units.",
    "ON": "Brightness of a visible vector in the picture macros (.BRITE; 1 while the Death Star lights are assembled).",
    "OFF": "Brightness of a blank vector.",
    "D_": "Divisor of the multiscaled vector macros (VONM, AON ...); each picture sets it, this is the last value.",
    "M_": "Multiplier of the multiscaled vector macros; each picture sets it, this is the last value.",
    "GNB0": "Alien gun shot, sparkle base, picture 0 (in the pseudo ROM).",
    "VRLZFZ": "End of the 16 lazar fire slots in vector RAM.",
    "VJINIT": "JSRL to VGINIT, which starts every display list: centre, scale, and a blue dot at each corner of the view.",
    "VJBTRN": "JSRL to the Death Star's trench stamp (white).",
    "VJBDSH": "JSRL to the Death Star's dish outline stamp (red).",
    "VJBNSD": "JSRL to the stamp for the inside of the dish (red).",
    "VJBFRM": "JSRL to the Death Star's farmland stamp (green).",
    "VJBMIN": "JSRL to the miniature Death Star.",
    "INLEN": "Self test: length of an intensity bar.",
    "SEPY": "Self test: Y step between intensity bars.",
    "VJINTN": "JSRL to the colour bar (intensity) pattern.",
    "MAX": "Self test: half the screen width, for the crosshatch and the boundary box.",
    "MAY": "Self test: half the screen height, for the crosshatch and the boundary box.",
    "CM": "Multiplier of the SCVEC test pattern macro.",
    "CD": "Divisor of the SCVEC test pattern macro.",
    "VJHTCH": "JSRL to the crosshatch pattern, which runs on into the alphabet.",
    "XSCRN": "Self test: half the checkerboard's width.",
    "YSCRN": "Self test: half the checkerboard's height.",
    "VJCHKR": "JSRL to the checkerboard pattern (12 horizontal and 16 vertical lines).",
    "BONDRY": "Screen boundary picture: dim green, then the box at the edge of the screen.",
    "VJBONDRY": "JSRL to the screen boundary picture.",
    "VJBIP": "JSRL to the BIP (hysteresis) test pattern, the same picture as the boundary.",
    "BOX": "The boundary box without its colour instruction.",
    "VJBOX": "JSRL to the box without its colour instruction.",
    "VJBIP2": "JSRL to the four sides of the box alone, with no scale, centre or move first.",
    "VJSQR": "JSRL to the square for the scale test.",
    "VJRSTR": "JSRL to the start of the raster test: the box, then a move to the left side.",
    "VJRST2": "JSRL to one pair of raster lines, across and back.",
    "VJPOTP": "JSRL to the pattern around the pot test line.",
}

for _b in ("X", "Y", "Z"):
    _hl(MAIN, "M_B" + _b, "Concat result, unit vector B, %s." % _b)
    _hl(MAIN, "M_C" + _b, "Concat result, unit vector C, %s." % _b)
    for _n in ("1", "2"):
        _hl(MAIN, "M_B%s%s" % (_b, _n), "Ship %s unit vector B, %s." % (_n, _b))
        _hl(MAIN, "M_C%s%s" % (_b, _n), "Ship %s unit vector C, %s." % (_n, _b))
MAIN["M_X1H"] = "High byte of the first word of the unit vector blocks. Not used."
MAIN["M_X1L"] = "Low byte of the first word of the unit vector blocks. Not used."

# the debounce triples the IRQ keeps for the four input bytes
for _n, _p in enumerate(("R_BYT0, the switches", "R_BYT1, thumbs and diagnostic",
                         "R_BYT2, option bank 1", "R_BYT3, option bank 2")):
    MAIN["IN_NW%d" % _n] = "Newest read of %s." % _p
    MAIN["IN_OL%d" % _n] = "Read of %s before that." % _p.split(",")[0]
    MAIN["IN_SW%d" % _n] = "Debounced %s: a bit changes when two reads running agree." % _p.split(",")[0]

# text rows
for _n, _y in ((2, 504), (3, 480), (4, 456), (5, 432), (7, 384), (8, 360), (9, 336),
               (10, 312), (11, 288), (12, 264)):
    MAIN["VGRW%d" % _n] = "Row %d Y placement (%d)." % (_n, _y)

# single bits
for _n in range(8):
    MAIN["BT%d" % _n] = "Data bit %d." % _n

# tower mazes: MAZEND gives the number of towers in the maze, in BCD
for _name, _n, _w in (("DIFF", 20, "7"), ("3DIFF", 24, "16"), ("CLUSTR", 16, "4"), ("3CLUSTR", 20, "13"),
                      ("BUNK", 0, "2 only; bunkers alone"), ("TWRCTY", 28, "11"), ("3TWRCTY", 32, "20"),
                      ("SYMTRC", 21, "9"), ("3SYMTRC", 25, "18"), ("TRAP", 21, "8"), ("3TRAP", 25, "17"),
                      ("WEDGE", 20, "6"), ("3WEDGE", 24, "15"), ("SQUARE", 16, "3"), ("3SQUARE", 20, "12"),
                      ("VALLEY", 27, "10"), ("3VALLEY", 31, "19"), ("TURNON", 20, "5"), ("3TURNON", 24, "14")):
    MAIN["Y" + _name] = "Towers in maze T%s, in BCD: %d (wave %s)." % (_name, _n, _w)

# messages
_MESS = {
    "CPY": ('"STAR WARS"', "first of the four copyright lines"),
    "CPZ": ('"LUCASFILM TRADEMARKS USED UNDER LICENSE."', "last copyright line"),
    "GO1": (None, "a position and colour with no text of its own; shows the next message, GAME OVER, at screen centre in bright red"),
    "GVR": ('"GAME OVER"', ""),
    "INS": ('"INSERT COINS"', ""),
    "FRE": ('"FREE PLAY"', "the coin mode lines follow: 2 PLAYS 1 COIN, 1 COIN 1 PLAY, 2 COINS 1 PLAY"),
    "STR": ('"PULL TRIGGER TO START"', ""),
    "CRD": ('"CREDITS"', "the next is CREDIT"),
    "SHG": ('"SHIELD GONE"', ""),
    "FLI": ('"FLIGHT INSTRUCTIONS TO RED FIVE"', "first line of the instruction page"),
    "FLZ": ('"UP THE DEATH STAR."', "last line of the instruction page; the shield counts 6-9 follow"),
    "SCR": ('"SCORING"', "first line of the scoring page"),
    "SCZ": ('"DESTROYING ALL TOWER TOPS 50,000"', "last line of the scoring page"),
    "DS1": ('"SELECT A DEATH STAR"', "first message of that screen"),
    "DSZ": ('"800,000"', "last message of the Death Star select screen"),
    "HS1": ('"MESSAGE FROM REBEL COMMAND POST"', "first of the enter-your-initials messages"),
    "HSZ": ('"SHOOT YOUR INITIALS"', "last of the enter-your-initials messages"),
    "RF1": (None, "a position and colour with no text of its own; shows the next message, PRINCESS LEIA'S REBEL FORCE, in the flashing colour"),
    "RF2": ('"PRINCESS LEIA\'S REBEL FORCE"', "title of the high score table"),
    "NXT": ('"POINTS NEXT TOWER"', ""),
    "TWR": ('"TOWERS"', ""),
    "ATP": ('"CLEARED ALL LASER TOWERS"', ""),
    "RWD": ('"50,000 FOR SHOOTING ALL TOWERS"', ""),
    "EXH": ('"EXHAUST PORT AHEAD"', ""),
    "DSD": ('"DEATH STAR DESTROYED"', ""),
    "MSD": ('"EXHAUST PORT MISSED"', ""),
    "BRE": ('"BONUS FOR REMAINING ENERGY"', "the next is 5,000 X"),
    "BSE": ('"ADDED TO DEFLECTOR SHIELD"', "the next is SHIELD AT FULL STRENGTH"),
    "BON": ('"STARTING WAVE BONUS"', ""),
    "SFB": ('"SHOOT FIREBALLS"', ""),
    "STF": ('"SHOOT TIE FIGHTERS"', ""),
    "ACW": ('"AVOID CATWALKS"', ""),
    "USE": ('"USE THE FORCE"', "the next is FOR USING THE FORCE"),
    "ACC": ('"ACCOUNTING INFORMATION"', "first line of the statistics page"),
    "OPT": ('"GAME OPTIONS"', "first line of the options page"),
    "VLC": ('"FREE PLAY"', "first of the VALUE OF A COIN settings"),
    "LMV": ('"1"', "first of the LEFT MECH VALUE settings"),
    "RMV": ('"1"', "first of the RIGHT MECH VALUE settings"),
    "BAV": ('"NONE"', "first of the BONUS ADDER settings"),
    "SLV": ('"6"', "first of the STARTING SHIELD settings"),
    "DIF": ('"EASY"', "first of the PLAY DIFFICULTY settings"),
    "BSV": ('"0"', "first of the BONUS SHIELD settings"),
    "MUV": ('"YES"', "first of the MUSIC IN ATTRACT settings"),
    "RHS": ('"NO"', "first of the RESET HIGH SCORES settings"),
    "RAC": ('"NO"', "first of the RESET TIMING INFO settings"),
    "ROP": ('"NO"', "first of the RESET OPTIONS settings"),
    "TER": ('"NO"', "first of the TEST NOVRAM settings"),
    "GNV": ('"NO ERRORS"', "NOVRAM test passed"),
    "BNV": ('"ERROR AT"', "NOVRAM test failed"),
    "SWT": ('"SWITCH TEST"', "the switch names follow"),
    "POT": ('"POT TEST"', ""),
    "RAM": ('"HARDWARE ERRORS"', "then NO ERRORS DETECTED, then one message per RAM and ROM chip"),
    "MBT": ('"MATHBOX TESTS"', ""),
    "MBN": ('"BAD MATHBOX READY LINE"', ""),
    "DIV": ('"DIVIDER ERRORS"', "then NO DIVIDER ERRORS and the error table heading"),
    "MTX": ('"MATRIX ERRORS"', "the next is NO MATRIX ERRORS"),
    "BIP": ('"BIP TEST"', "the next is ALIGN THE BOXES"),
    "SCL": ('"SCALE TEST"', "then LINEAR and LINEAR AND BINARY"),
    "INT": ('"0. OFF"', "first of the four intensity test lines, each at its own brightness"),
    "XIT": ('"PRESS AUX COIN TO CONTINUE"', ""),
    "TST": ('"PRESS AUX COIN FOR SELF TEST"', ""),
    "RES": ('"PULL RIGHT FIRE TO PERFORM RESETS"', ""),
}
for _k, (_t, _x) in _MESS.items():
    if _t is None:
        MAIN["MS_" + _k] = "Message number: %s." % _x
    else:
        MAIN["MS_" + _k] = "Message number: %s%s." % (_t, "; " + _x if _x else "")
MAIN["SPMS1"] = 'First special (banner story) message: "OBI-WAN KENOBI IS GONE BUT HIS".'
MAIN["SPMSZ"] = "One past the last special message (ALWAYS)."
MAIN["MESSZ"] = "Number of messages."

# lazar fire and splash colours (real vector ROM) and their slots in vector RAM
for _n, _c in enumerate(("turquoise at $FF", "blue at $FF", "blue at $CC", "blue at $80", "blue at $40",
                         "blue at $00", "blue at $00", "blue at $00")):
    for _k in (_n, _n + 8):
        MAIN["LZF%X" % _k] = "Lazar fire colour %X: %s, RTSL. The IRQ steps the VRLZF slots through these." % (_k, _c)
for _n in range(16):
    MAIN["VJLZF%X" % _n] = ("JSRL to lazar fire slot %X in vector RAM (VRLZF+%d), where the IRQ keeps a JMPL to one of LZF0-LZFF."
                            % (_n, 2 * _n))
for _n, _c in enumerate(("white", "white", "yellow", "yellow")):
    MAIN["LZS%d" % _n] = "Lazar splash %d: %s at $FF, then JMPL to the splash picture VGLZS%d." % (_n, _c, _n)

# Death Star lights (pseudo ROM): dot patterns in the shape of letters
_LETTER = "Death Star lights: dots in the shape of the letter %s."
for _c in "LCOBGUTIFEKRADNHMSVWY":
    MAIN["B_" + _c] = _LETTER % _c
for _k, _c in (("L2", "L"), ("L3", "L"), ("C2", "C"), ("T2", "T"), ("F2", "F"), ("K2", "K"),
               ("A2", "A"), ("M2", "M"), ("W2", "W"), ("Y2", "Y")):
    MAIN["B_" + _k] = "Death Star lights: entry inside the letter %s that other letters jump to." % _c
for _k, _w, _t in (("UB1", "upper hemisphere, block city 1", "MAY THE FORCE"),
                   ("UB2", "upper hemisphere, block city 2", "MARGOLIN"),
                   ("UB3", "upper hemisphere, block city 3", "RIVERA"),
                   ("UB4", "upper hemisphere, block city 4", "HALLY"),
                   ("LB1", "lower hemisphere, block city 1", "BE WITH YOU"),
                   ("LB2", "lower hemisphere, block city 2", "AVELLAR"),
                   ("LB3", "lower hemisphere, block city 3", "VICKERS"),
                   ("LB4", "lower hemisphere, block city 4", "DURFEY")):
    MAIN["VJ" + _k] = "JSRL to the Death Star lights, %s: the dots spell %s." % (_w, _t)

# gas gauge
MAIN["VJG0"] = "JSRL to gas gauge base line 0, both halves. TGDRW steps through VJG0-VJG9 to animate a loss."
for _n in range(1, 10):
    MAIN["VJG%dA" % _n] = "JSRL to gas gauge base line %d without the tic, both halves." % _n
    MAIN["VJG%d" % _n] = "JSRL to gas gauge base line %d, both halves." % _n
for _n in range(10):
    MAIN["VJGA%d" % _n] = "JSRL to the whole gas gauge at level %d: top, upstroke and base line, both halves (TGALL)." % _n
    MAIN["VJGU%d" % _n] = ("JSRL to the gas gauge at level %d, upstroke and base line (TGUP); the source gives it the same pictures as VJGA%d."
                           % (_n, _n))

SOUND = {
    # ---- hardware registers
    "SOUT": "Write: byte to the main CPU; sets the sound flag. The main loop writes PBXS_OK here as its watchdog.",
    "SIN": "Read: byte from the main CPU; resets the main flag.",
    "PAD": "6532 port A data. D0 /WS and D1 /RS speech strobes, D2 speech /RDY (in), D3 /FM, D4 self test switch (in, 1=off), D5 5220 power (1=off), D6 sound flag (in), D7 main flag (in).",
    "TESTSW": "Port with the self test switch (bit TESTBT of PAD).",
    "DPRAMZ": "End of the 6532 RAM (limit of INIT's clear loop).",
    "PADD": "6532 port A direction; INIT writes $2B (D0, D1, D3, D5 outputs).",
    "PBD": "6532 port B data: the speech chip's data bus.",
    "PBDD": "6532 port B direction; INIT writes $FF.",
    "DINED": "Write: disable the PA7 interrupt, negative edge detect.",
    "RTDI": "Read: timer, and disable the timer interrupt.",
    "DIPED": "Write: disable the PA7 interrupt, positive edge detect.",
    "RIF": "Read: interrupt flags, D7 timer, D6 PA7 (the main CPU has sent a byte); reading resets the PA7 flag.",
    "EINED": "Write: enable the PA7 interrupt, negative edge detect.",
    "EIPED": "Write: enable the PA7 interrupt, positive edge detect; INIT's choice.",
    "RTEI": "Read: timer, and enable the timer interrupt.",
    "D1T": "Write: timer, 1 clock per count, timer interrupt disabled.",
    "D8T": "Write: timer, 8 clocks per count, timer interrupt disabled.",
    "D64T": "Write: timer, 64 clocks per count, timer interrupt disabled.",
    "D1024T": "Write: timer, 1024 clocks per count, timer interrupt disabled.",
    "E1T": "Write: timer, 1 clock per count, timer interrupt enabled.",
    "E8T": "Write: timer, 8 clocks per count, timer interrupt enabled.",
    "E64T": "Write: timer, 64 clocks per count, timer interrupt enabled.",
    "E1024T": "Write: timer, 1024 clocks per count, timer interrupt enabled; INIT and the IRQ write 6 for the 4 ms interrupt.",
    "P_BASE": "Base of the four POKEYs (chips 0-3 in SNDCMN's map; registers 0-7 of each at $1800, 8-F at $1820).",
    "P_POT0": "Read: POT0 of chip 0. Not used.",
    "P_POT1": "Read: POT1 of chip 0. Not used.",
    "P_POTZ": "End of the pot registers. Not used.",
    "P_SNDZ": "End of the 8 sound effect channels: the AUDF/AUDC pairs of chips 0 and 1.",
    "PKFL3": "Music voice 3, frequency low: AUDF1 of chip 2.",
    "PKVX3": "AUDC1 of chip 2, the control of voice 3's low half.",
    "PKFH3": "Music voice 3, frequency high: AUDF2 of chip 2.",
    "PKV3": "Music voice 3, volume and control: AUDC2 of chip 2.",
    "PKFL4": "Music voice 4, frequency low: AUDF3 of chip 2. Voices 5-8 share it until reconfigured.",
    "PKVX4": "AUDC3 of chip 2, the control of voice 4's low half.",
    "PKFH4": "Music voice 4, frequency high: AUDF4 of chip 2.",
    "PKV4": "Music voice 4, volume and control: AUDC4 of chip 2.",
    "PKFL1": "Music voice 1, frequency low: AUDF1 of chip 3.",
    "PKVX1": "AUDC1 of chip 3, the control of voice 1's low half.",
    "PKFH1": "Music voice 1, frequency high: AUDF2 of chip 3.",
    "PKV1": "Music voice 1, volume and control: AUDC2 of chip 3.",
    "PKFL2": "Music voice 2, frequency low: AUDF3 of chip 3.",
    "PKVX2": "AUDC3 of chip 3, the control of voice 2's low half.",
    "PKFH2": "Music voice 2, frequency high: AUDF4 of chip 3.",
    "PKV2": "Music voice 2, volume and control: AUDC4 of chip 3.",
    "P_SNDZ_1820": "SNDAUX's P.SNDZ: end of the AUDF/AUDC registers of all four chips (limit of INIT's clear loop).",
    "P_PSW2": "ALLPOT of chip 1. Not used.",
    "P_ACT3": "AUDCTL of chip 2, cleared by INIT.",
    "PKC1": "AUDCTL of chip 2: $78 joins its channels in pairs for 16-bit voices, 0 leaves all four apart (dynamic reconfiguration).",
    "PKR1": "RANDOM of chip 2. Not used.",
    "POTGO1": "POTGO of chip 2. Not used.",
    "P_BGN3": "SKCTL of chip 2: INIT writes 0, then 7.",
    "PKI1": "SKCTL of chip 2: ISND writes 0, then 3, to initialize the chip.",
    "P_ACT4": "AUDCTL of chip 3, cleared by INIT.",
    "PKC2": "AUDCTL of chip 3: $78 joins its channels in pairs for 16-bit voices, 0 leaves all four apart.",
    "PKR2": "RANDOM of chip 3. Not used.",
    "POTGO2": "POTGO of chip 3. Not used.",
    "P_BGN4": "SKCTL of chip 3: INIT writes 0, then 7.",
    "PKI2": "SKCTL of chip 3: ISND writes 0, then 3, to initialize the chip.",

    # ---- RAM
    "DREF": "Dynamic reconfiguration flag: 0 = normal (16-bit voices), 1 = every voice 8 bits on its VCS_PKD register (RCS sets it, RCN clears it).",
    "AU_BLK": "Sound effect channel blocks: AUS_EQ sets of AUS_IZ bytes, one per hardware channel.",
    "VOICE5": "Music voice 5 RAM block: priority 2 on voice 4's output.",
    "VOICE6": "Music voice 6 RAM block: priority 3 on voice 4's output.",
    "VOICE7": "Music voice 7 RAM block: priority 4 on voice 4's output.",
    "VOICE8": "Music voice 8 RAM block: priority 5 on voice 4's output.",
    "SPKQUE": "Speech sentence FIFO: 16 word list pointers, indexed by SP_QTP and SP_QBT.",

    # ---- constants
    "TESTBT": "Self test switch bit in TESTSW; 0 = on.",
    "PROG": "Start of the program ROM.",
    "ROM0": "Start of ROM 0 (8K); its first word is the checksum word.",
    "ROM1": "Start of ROM 1 (8K), and the end of ROM 0 for the checksum routine.",
    "RAM": "Start of program RAM.",
    "RAMZ": "End of program RAM (limit of INIT's clear loop).",
    "VCS_RAM": "Offset in a voice descriptor (TVC): pointer to the voice's RAM block.",
    "VCS_BIT": "Offset in a voice descriptor: the voice's mask bit (VC1-VC8).",
    "VCS_PKF": "Offset in a voice descriptor: the POKEY frequency register it normally uses.",
    "VCS_PRI": "Offset in a voice descriptor: priority mask, the voices that take its output away when in use.",
    "VCS_PKD": "Offset in a voice descriptor: the POKEY register to use instead when dynamically reconfigured.",
    "PGCKS0": "Checksum word of ROM 0, assembled at CKSUM0 ($4000).",
    "PGCKS1": "Checksum word of ROM 1, assembled at $7FF0.",
    "P0S": "Start of phrase 0's speech data: phrase 1's (the table entry is a placeholder, PLEASE START AT ZERO).",
    "P0E": "End of phrase 0's speech data: phrase 1's.",
}
for _n in range(8):
    SOUND["BT%d" % _n] = "Data bit %d." % _n
for _n in range(2, 9):
    SOUND["VC%d" % _n] = "Voice %d mask bit." % _n
for _n in range(1, 9):
    SOUND["VCS_%d" % _n] = "Offset of voice %d's descriptor in TVC (8 bytes each)." % _n

# counters a macro steps: the comment on the last call that stepped them is not theirs
MAIN["PHS_EQ"] = "Number of entries in TPHASE; the mainline hangs on a PHASE that is not below it."
MAIN["VGVARB"] = ("Size of the variable block at the start of vector RAM (the JMPL and the VR slots); a display list buffer's "
                  "first instruction is at this offset. The source steps it from 2 as each slot is declared; this is the final value.")
MAIN["DASP"] = "Divisor of the Y aspect ratio in the picture macros: 2 inside ASPECT, 1 otherwise; this is the last value."
MAIN["MASP"] = "Multiplier of the Y aspect ratio in the picture macros: 3 inside ASPECT, 1 otherwise; this is the last value."
SOUND["PBXS_EQ"] = "One more than the highest command number (IDAYEA); a command byte above it is dropped."

NOTES = {"main": MAIN, "sound": SOUND}

# Definitions whose line in the source carries a comment about something else: the
# comment on a TEMP statement is about the code that follows it, and the one on the
# .IRPC that makes OPTRn and VIUn is about the loop.  These replace it.
REPLACE = {
    "main": {
        "TMPOCT": "Temp of VWGUN: X distance + Y distance from the gun shot's centre to the lazar, for the octagon test.",
        "TMPSIZ": "Temp of VWGUN: the gun shot's size on screen plus the cursor's, for the lazar hit test.",
    },
    "sound": {},
}
for _n in range(1, 9):
    REPLACE["sound"]["OPTR%d" % _n] = "Voice %d's OPTR: pointer to the start of its current tune or sound." % _n
    REPLACE["sound"]["VIU%d" % _n] = "The same word as OPTR%d: non-zero says voice %d is in use." % (_n, _n)
