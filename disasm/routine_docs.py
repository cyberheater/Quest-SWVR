"""Routine descriptions written for this disassembly.

Used by emit.py only for a routine the source says nothing about: no .SBTTL
title, no comment on the label, no comment block above it and no comment on any
call to it.  Each appears in the listing tagged [note].  Keyed by listing, then
by the routine's identifier as the listing prints it.
"""
DOCS = {
    "program": {
        # WSMAIN
        "ISTARG": "Setup stars for the ground: each 8-byte block M_STAD..M_STAZ gets random X,Y (P_RND1/P_RND2) and Z = 0",
        "VEWS0D": "View for PHES0D (space to die): messages, gas, stars, explosions, alien ships, guns,\n"
                  "growing GAME OVER message and glow; no site and no lazar collisions",
        "VEWG0D": "View for PHEG0D (ground to die): messages, tower messages, gas, ground stars, guns, ground,\n"
                  "growing GAME OVER message and glow; no site and no lazar collisions",
        "VEWG1B": "View for PHEG1B (next part of ground to base transition): as VEWG0B, but views the star base\n"
                  "(VWBASE) in place of the ground stars",
        "VEWB0D": "View for PHEB0D (base trench to die): messages, MISSED EXHAUST PORT if Q_BSH, gas, star base, guns,\n"
                  "EXHAUST PORT AHEAD if first wave and BS_PFL, growing GAME OVER message and glow",
        "DTHVW": "Draw the Deth Star for VWDTHB: OBJCEN to its center, then the circle, trench, dish, inside and farm\n"
                 "stamps at scale DT_SCL and the city stamps (picked by SP_WAV bit 0) at a larger scale. Y-->VG list",
        # WSCPU
        "SNNEG": "Negative angles for CPU: M_SIN = minus the sine and M_COS = the cosine of the TSNGLE entry at offset $14",
        "CPCHKL": "Check alien's distance away, X-->alien parms: keep the high byte of MS_TX, MS_TY and MS_TZ of its\n"
                  "unit vectors (AS_UVP) in range, limiting to $7CFF (positive) and $8300 (negative)",
        "CPUGON": "One alien gone: decrement WV_LIV (alien lives left in current wave), holding it at zero",
        "CHCN_E": "Control mask matched status (from CHOPDO): skip 3-byte choreography entries at AS_CHPC until one\n"
                  "whose first byte is 0, then go to CHNXT",
        "NWASHP": "Make alien record X a live ship: unit vectors (UNITV) facing the player, hits AS_HTA from WV_SHP,\n"
                  "location from WV_BGP, choreography WV_CHP (NWCHOR), picture AS_PIC; adds its object with ADBOBJ",
        "ADASHP": "Add one alien ship from loop table WV_LP (next WV_LVL of the SP_WAV group when the level ends) into\n"
                  "the first empty ALIEN slot, set up as in NWASHP but with no ADBOBJ; INC WV_LIV; exits if no slot or entry",
        # WSGAS
        "VWGAS": "View the gas gauge: VWGONE if S_GAS is gone and no hit is being handled; else color from TGCLR, title\n"
                 "VJFUEL, the gauge (GSVNEW while GS_HIT animates, else GSVALL) and the S_GAS numeral. Y-->VG list",
        # WSGLOW
        "DO1GLW": "Count S_GLW (glowing from hit) down by one until it reaches zero; DO1QGLW falls into this",
        # WSGRND
        "VWGRND": "View the ground: BJGROT the TDS_GND shape, GRLZIN, then for each entry of the GD_WAV maze (TGDPTR)\n"
                  "allowed by GD_SEQ: if in range and in view, GDVIEW and GDGUN; else set up its GDRAM type backstage",
        # WSGUNS
        "MOVWF": "Move routine MOVS_WF (tower forward gun), X-->gun packet: shot X - $100 (goto player), then TOWRMV",
        "MOVWL": "Move routine MOVS_WL (tower left gun), X-->gun packet: shot X - $100 and Y - $100, then TOWRMV",
        "MOVWR": "Move routine MOVS_WR (tower right gun), X-->gun packet: shot X - $100 and Y + $100, then TOWRMV",
        "SLEWX": "Slew shot X, U-->shot position: B = high byte of shot X minus high byte of MS_TX+M_S1; if plus,\n"
                 "subtract 4*B from shot X",
        "MOVBL": "Move routine MOVS_BL (left bunker gun), X-->gun packet: SLWYR and SLEWX, then slew shot Y toward a\n"
                 "point right of the player (fast to the right, slowly to the left) and move shot Z up toward the player",
        "MOVBR": "Move routine MOVS_BR (right bunker gun), X-->gun packet: SLWYL and SLEWX, then slew shot Y toward a\n"
                 "point left of the player (fast to the left, slowly to the right) and move shot Z up toward the player",
        "MOVBF": "Move routine, TMOVE entry BF, X-->gun packet: shot X - $100 (goto player), move shot Z up toward the\n"
                 "player (at most $180), then BNKRMV",
        "MOVBLC": "As MOVBF but shot Y - $100 as well; nothing in the listing refers to this routine",
        "MOVBRC": "As MOVBF but shot Y + $100 as well; nothing in the listing refers to this routine",
        # WSLAZR
        "CLGA": "Alien test (after the guns in CLGLZ): if CL_ADS is valid and no farther than CL_BDS and CL_TDS, set\n"
                "LZ_HIT = 4 and jump to CPHTSA; else go on to CLGB or CLGT",
        "CLGT": "Tower test: if CL_TDS is valid, LZ_HIT = $FF (no hit, but splash against wall), SP_TYP = full\n"
                "surface, SP_LOC = 3 * high byte of CL_TDS (limit $E0), SP_COL = yellow",
        # WSXPLD
        "BGTWXP": "Begin tower top explosion: TMPTP1..3 = tower piece types TPS_TW1..3 and TMPVZ = 2, then falls into\n"
                  "BGBKN, which queues the three pieces around center M_XT,YT,ZT",
        "MVBK1": "Move a bunker or tower explosion piece, X-->explosion queue entry: add XPS_MX,MY to center with\n"
                 "friction losses (velocity less 1/32), add XPS_MZ to Z (stops at ground level 0), gravity $C8 off XPS_MZ",
        "VWXPL2": "View one explosion piece, X-->explosion queue entry: PSB2 its center; if in view call its TVW\n"
                  "routine (XPS_TYP), then ADOBJ, OBJPNT, OBJDRW; if not visible clear XPS_TMR to turn it off",
        "VWBK1": "View bunker explosion piece 1: A = TDS_BK1, branch to VWBKN",
        "VWBK2": "View bunker explosion piece 2: A = TDS_BK2, branch to VWBKN",
        "VWBK3": "View bunker explosion piece 3: A = TDS_BK3, branch to VWBKN",
        "VWTW1": "View tower explosion piece 1: A = TDS_TW1, branch to VWTWN",
        "VWTW2": "View tower explosion piece 2: A = TDS_TW2, branch to VWTWN",
        "VWTW3": "View tower explosion piece 3: A = TDS_TW3, branch to VWTWN",
        "VWTWN": "Common part for tower pieces: BJ_ID = A, color white, then join VWBKN at VWTWN2",
        "VWBKN": "Common part for bunker pieces: BJ_ID = A, color red. VWTWN2: output color (fades when XPS_TMR <= 7),\n"
                 "PSB2 the piece's shadow point (center X,Y on the ground), OBJCEN, then a scale from M_XT. X-->piece",
        "VWTIN": "Common part for TIE pieces: BJ_ID = B, color from TVWCLE indexed by XPS_TMR (VJFLS flash when beyond\n"
                 "the table), then OBJCEN. X-->explosion queue entry",
        "XP_NUL": "Phase 0 of TXPPHS (XP_PHS = 0 is the flag meaning end): do nothing, RTS. VWXPLN also returns through here",
        # WSXMT
        "PMTST": "Request music channel POKEY test tones: A = IDPTST, jump to DOXMT",
        "SPKI": "Request init of speech chip: A = IDSI, jump to DOXMT",
        "PMDES": "Request descent into Deth Star music: A = IDPDES, jump to DOXMT",
        "AUDNAY": "Request nay (test fail) sound: A = IDANAY, jump to DOXMT",
        "AUDRY": "Request R2 yes sound: A = IDARY, jump to DOXMT",
        # TCEROM
        "EETMP3": "Move EEROM nibbles at (X) to bytes at (U): A = number of bytes less one, two nibbles (upper, lower)\n"
                  "per byte; uses TMPCNT; ends with LEAX -8,X (restores X only for the 8-nibble EETEMP case)",
        # TCHSCR
        "UPDAT2": "Score is a high score (from UPDATE), X-->table entry beaten: PUTHI to make room, clear UPDINT and\n"
                  "INITL for the first initial, and return X = end of HSCORS so UPDATE's loop leaves",
        # WSROOT
        "ADBOBJ": "Bank-switch vector to overlay JADBOBJ (add object points to mbox, B = object #); restores root bank",
        # WSMATH
        # the two shift chains: these notes outrank the comments borrowed from callers
        "ASRD8": "Entry point: arithmetic shift D right 8 bits (falls through ASRD7..ASRD1 to the RTS at ASRD0)",
        "ASRD7": "Entry point: arithmetic shift D right 7 bits (falls through ASRD6..ASRD1 to the RTS at ASRD0)",
        "ASRD6": "Entry point: arithmetic shift D right 6 bits (falls through ASRD5..ASRD1 to the RTS at ASRD0)",
        "ASRD5": "Entry point: arithmetic shift D right 5 bits (falls through ASRD4..ASRD1 to the RTS at ASRD0)",
        "ASRD4": "Entry point: arithmetic shift D right 4 bits (falls through ASRD3..ASRD1 to the RTS at ASRD0)",
        "ASRD3": "Entry point: arithmetic shift D right 3 bits (falls through ASRD2, ASRD1 to the RTS at ASRD0)",
        "ASRD2": "Entry point: arithmetic shift D right 2 bits (falls through ASRD1 to the RTS at ASRD0)",
        "ASRD1": "Entry point: arithmetic shift D right 1 bit (ASRA, RORB), then the RTS at ASRD0",
        "LSLD8": "Entry point: shift D left 8 bits (falls through LSLD7..LSLD1 to the RTS at LSLD0)",
        "LSLD7": "Entry point: shift D left 7 bits (falls through LSLD6..LSLD1 to the RTS at LSLD0)",
        "LSLD6": "Entry point: shift D left 6 bits (falls through LSLD5..LSLD1 to the RTS at LSLD0)",
        "LSLD5": "Entry point: shift D left 5 bits (falls through LSLD4..LSLD1 to the RTS at LSLD0)",
        "LSLD4": "Entry point: shift D left 4 bits (falls through LSLD3..LSLD1 to the RTS at LSLD0)",
        "LSLD3": "Entry point: shift D left 3 bits (falls through LSLD2, LSLD1 to the RTS at LSLD0)",
        "LSLD2": "Entry point: shift D left 2 bits (falls through LSLD1 to the RTS at LSLD0)",
        "LSLD1": "Entry point: shift D left 1 bit (LSLB, ROLA), then the RTS at LSLD0",
        # TCSPLS
        "URQ2": "Up-right quadrant, entry with U already set: copy 3 vector words from the RNDVEC list to (U)+ as is",
        "ULQ2": "Up-left quadrant, entry with U already set: copy 3 vector words from the RNDVEC list to (U)+ with X\n"
                "negated; Z off on the first and third, Z = 7 on the second",
        "DLQ2": "Down-left quadrant, entry with U already set: copy 3 vector words from the RNDVEC list to (U)+ with Y\n"
                "and X negated (remade as SVCTR instructions); Z off on the first and third, Z = 7 on the second",
        "DRQ2": "Down-right quadrant, entry with U already set: copy 3 vector words from the RNDVEC list to (U)+ with Y\n"
                "negated (remade as SVCTR instructions)",
        # WSCOIN
        "S_MUL83": "Center mech: check half-mul - A = 1 if S_CMODE bit $10 is set, else 0; falls into S_MUL85, which\n"
                   "adds A+1 unit coins to S_BCCNT and S_CNCT",
        # TCMES
        "MESSOFF": "Turn message A off: search the list MESBLK..MESLST for message number A and delete it by moving the\n"
                   "last entry into its slot and backing MESLST up one",
        # TCTEST
        "TMULTZ": "End of the TMULT table. MULT9 (its TMULT2 entry): matrix test 9 - set S as return pointer to MT9RT1\n"
                  "and jump to MTST9",
        "MT9RT1": "Return from MTST9: D (M_XP) must be $0001, else to SMULRT with the error; then U = 2, return pointer\n"
                  "S = MT9RT2, and jump to MTST92 to add the accumulator to itself",
        "MT9RT2": "Return from MTST92: D must equal the BITS entry at U, else to SMULRT with the error; U + 2 and repeat\n"
                  "MTST92 until U = $20, then to SMULRT with the last compare equal",
    },
    "overlay": {
        # WSOBJ
        "JINOBJ": "Initialize objects: clear the BIC list BJBIC..BJBICZ, BJ_BIC = MS_BJBC/2 (starting BIC value, pairs of\n"
                  "points), BJ_RAM = M_OBJ (starting RAM address)",
        "JBJLNV": "Draw visible line: M_QUO to M_XP and MS_PERS, then output a vector (Z bits $E0) from current\n"
                  "BJ_CX,BJ_CY to the new point M_YP (left/right), M_ZP (up/down) and make it current. Y-->VG list",
        "JBJLNB": "Draw blank line: as JBJLNV but the vector is output blank (Z bits off); updates BJ_CX,BJ_CY",
        "JOBJBPNT": "Process object points, B = object #: BJ_ID = B, then JOBJPNT - for each point of the object (count\n"
                    "from TDRWNM, BIC from BJBIC) do MS_PAD, 1/X and MS_PERS, saving M_YP,M_ZP in BJ_PNT (4 bytes each)",
        "JOBJDRW": "Draw the object lines: interpret object BJ_ID's line list (TDRWLN, first byte must be 0), drawing\n"
                   "bright or blank vectors between BJ_PNT points until $FF or a damage code not above BJ_DMC",
        "JBJGROT": "Pre-rotate object BJ_ID's ROM points (TDRWPC) with center at zero: MS_PSUB each point through M_GD\n"
                   "and save the result in 16-byte blocks from M_GDFE (MS_GDXR,YR,ZR); restores MS_TX,TY,TZ+M_U1",
        "JBJFROT": "Flipped pre-rotate: as JBJGROT but each point's Y is negated (flip Y direction) before MS_PSUB",
        "JBJGPNT": "Translate and project ground object's points: negate M_XP,YP,ZP, MS_PR2I, then for each point of\n"
                   "object BJ_ID feed 1/X (M_QUO) to M_YT and run MS_PRS2, starting the next divide from M_XT; no clipping",
        "JBJGDRW": "Draw ground type object BJ_ID: its TDRWLN entry must begin with type byte 1 (else SWI); jumps to the\n"
                   "code that follows that byte (direct executing)",
        # WSSTAR
        "JVWSTRG": "View ground stars: as JVWSTAR but in green, with no far limit and without moving the M_U1 position;\n"
                   "stars out of view are regenerated with STRNWG. Stars are queued by screen sector, then drawn",
        "STARNW": "New star at math RAM X: random visual X,Y,Z (RND8), Y and Z signs opposite of current M_YPH, M_ZPH;\n"
                  "MS_S1UN (BIC low = ST_BIC) converts to universe coordinates, stored at 0,2,4(X)",
        "STRNWG": "New ground star at math RAM X: X = random, forced way out there, plus MS_TX+M_U1; Y = random, sign\n"
                  "opposite of current M_YPH, plus MS_TY+M_U1; Z = 0 (on the ground). Uses RND8",
    },
    "vector": {},
    "sound": {
        # SNDPM
        "PKCUT1": "Cut (init) POKEY voice 1: A = VCS_1, branch to POKVI; leaves Y-->voice descriptor table",
        "PKCUT2": "Cut (init) POKEY voice 2: A = VCS_2, branch to POKVI; leaves Y-->voice descriptor table",
        "PKCUT3": "Cut (init) POKEY voice 3: A = VCS_3, branch to POKVI; leaves Y-->voice descriptor table",
        "PKCUT4": "Cut (init) POKEY voice 4: A = VCS_4, branch to POKVI; leaves Y-->voice descriptor table",
        "PKCUT5": "Cut (init) POKEY voice 5: A = VCS_5, branch to POKVI; leaves Y-->voice descriptor table",
        "PKCUT6": "Cut (init) POKEY voice 6: A = VCS_6, branch to POKVI; leaves Y-->voice descriptor table",
        "PKCUT7": "Cut (init) POKEY voice 7: A = VCS_7, branch to POKVI; leaves Y-->voice descriptor table",
        "PKCUT8": "Cut (init) POKEY voice 8: A = VCS_8, branch to POKVI; leaves Y-->voice descriptor table",
        "PKARAT": "Tune function (PKDT entry 0), have a new rate: ORATE = -A (stored pre-negated), then POKNL.\n"
                  "PKCRAT (change rate) falls into this. A = data value, U-->voice RAM block",
        "PKAAMP": "Tune function (PKDT entry 2), have a new median amplitude: VVOL = A, then POKNL.\n"
                  "PKCAMP (change amplitude) falls into this. A = data value, U-->voice RAM block",
        "PKAKEY": "Tune function (PKDT entry 4), have a new key offset: OKEY = A, then POKNL.\n"
                  "PKCKEY (change key) falls into this. A = data value, U-->voice RAM block",
        "PKGOSB": "Tune function, gosub to a subphrase: save the address past this 3 byte instruction in OPTRET, load\n"
                  "OPTR from the instruction's last two bytes, then POKNL. U-->voice RAM block",
        "PKRET": "Tune function, return from gosub: OPTR = OPTRET, then POKNL. U-->voice RAM block",
        # SNDSPK
        "SPITE": "X-->word list: start it with SPKNEW only if the sentence queue is empty (SP_QTP = SP_QBT) and no\n"
                 "voice is currently being spoken (SP_STA = 0); otherwise drop the request",
        # SNDAUX
        "MAIN": "Mainline loop: enable IRQ, wait for SYNC (4 ms), resetting if RAM, DP or IRQ fail; send watchdog\n"
                "PBXS_OK to SOUT, count S_INTCT, step test tones if test switch on, then SPKIRQ, DOCMD, FM bit, AUDDO, PKDR",
    },
}
