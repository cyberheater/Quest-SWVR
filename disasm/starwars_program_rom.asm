;Star Wars (Atari, 1983) - annotated disassembly of the main program ROM,
;$6000-$FFFF with bank 0 at $6000-$7FFF.  Revision 2 (MAME 'starwars':
;136021-214.1f, -102.1hj, -203.1jk, -104.1kl, -206.1m).
;Bank 1 of $6000-$7FFF is in starwars_overlay_rom.asm; the vector ROM is in
;starwars_vector_rom.asm.
;Reconstructed by re-assembling Atari's own source (the 22-JUN-83 link of the
;historicalsource 'star-wars' archive) byte-exact with disasm/macasm69.py, so
;names and upper-case comments are Atari's.  Routine header descriptions come
;from the source (.SBTTL / label comment / comment block / comment at the call),
;else were written for this disassembly (tagged [note]).
;Every line below was re-encoded and byte-compared with the ROM (verify.py).
;Syntax: Motorola 6809 mnemonics and operands; .alias, .byte, .word (big-endian);
;( ) groups expressions, which Atari's MAC69 evaluated strictly left to right;
;~ is one's complement, | is OR, ^ is exclusive OR.  .dpage gives the direct page
;the assembler assumed; < and > before an operand force the short and long form.

.org $6000

.include "starwars_defines.asm"


;==============================================================================
; MODULE WSPROG   WSPROG.MAC
;   PROG PROGRAM START
;==============================================================================
.dpage $48
L6000:  JMP  RESET                  ;HELP DEVELOPMENT SYSTEM WORK
L6003:  .word IRQ

;==============================================================================
; MODULE WSMAIN   WSMAIN.MAC
;   GAME PLAY
;==============================================================================

;------------------------------------------------------------------------------
; WAITFRAME - MAINLINE
;------------------------------------------------------------------------------
WAITFRAME:
L6005:  LDX  #$0000                 ;TALK TO DEV SYS
L6008:  LDD  #$F800                 ;PATCH TO 0BD TO TURN ON (JSR)
L600B:  LDA  #DPRAM/$100
L600D:  TFR  A,DP
L600F:  LSR  GMSYNC                 ;PROCESS GAME FRAMES IN TIMELY FASHION
L6011:  BCC  WAITFRAME
L6013:  CMPS #STACK
L6017:  BEQ  L601A                  ;IFNE  ?SOME FRAME NEEDS A DELAY?
L6019:  RTS                         ;THEN LET IT CONTINUE
L601A:  LDA  PT_DLY
L601C:  BNE  L602F                  ;IFEQ  ?FAR ENUF INTO POWER ON?
;PREVENT STARTUP BLANK STARES
L601E:  LDA  >IN_SW2                ;LOOK AT FREEZE SWITCH (BT7 OPTION BANK 1)
L6021:  ANDA #BT7                   ;FREEZE?
L6023:  BNE  L602F                  ;IFEQ  ?SWITCH ON? THEN FREEZE
L6025:  LDA  VG_LON                 ;USE LEFT FIRE BIT FOR SINGLE STEPPING
L6027:  BITA #LFIRBT
L6029:  BEQ  WAITFRAME              ;B NO LEFT EDGE, SO LOOP FOREVER (ALMOST)
;ELSE SINGLE STEP JUST THIS TIME
L602B:  ANDA #(-1-LFIRBT)&$FF       ;CLEAR OUT THIS BIT ONLY, RIGHT STILL FIRES
L602D:  STA  VG_LON                 ;JUST TESTING, SO IGNORE SEI/CLI
L602F:  JSR  IFRAME                 ;INIT GAME FRAME
L6032:  LDA  VGSYNC                 ;NON-NEGATIVE VALUE INDICATES BUFFER READY
L6034:  BMI  L6032                  ;PLEND

MAIN:
L6036:  LDA  PHASE                  ;EXECUTE PHASE
L6038:  CMPA #PHS_EQ

MAIN_30:
L603A:  BHS  MAIN_30                ;DIE ON BAD PHASE
L603C:  LSLA
L603D:  LDX  #TPHASE
L6040:  JSR  [A,X]
L6042:  BRA  WAITFRAME              ;NEXT MAIN FRAME

TPHASE:          ;GAME PHASE TABLE
L6044:  .word PHERES                ;P. RES  RESET
L6046:  .word PHISTS                ;P. STS,I  STATISTICS
L6048:  .word PHESTS
L604A:  .word PHIOPT                ;P. OPT,I  OPTION SWITCH
L604C:  .word PHEOPT
L604E:  .word PHIBNR                ;P. BNR,I  BANNER
L6050:  .word PHEBNR
L6052:  .word PHIINS                ;P. INS,I  FLIGHT INSTRUCTIONS
L6054:  .word PHEINS
L6056:  .word PHISCR                ;P. SCR,I  SCORING PAGE
L6058:  .word PHESCR
L605A:  .word PHIHIS                ;P. HIS,I  HI SCORE TABLE DISPLAY
L605C:  .word PHEHIS
L605E:  .word PHISDS                ;P. SDS,I  SELECT A DEATH STAR
L6060:  .word PHESDS
L6062:  .word PHIENT                ;P. ENT,I  ENTER INITIALS
L6064:  .word PHEENT
L6066:  .word PHIDX1                ;P. DX1,I  DEATH STAR EXPLOSION, FIRST PHASE
L6068:  .word PHEDX1
L606A:  .word PHIDX2                ;P. DX2,I  DEATH STAR EXPLOSION, SECOND PHASE
L606C:  .word PHEDX2
L606E:  .word PHIDX3                ;P. DX3,I  DEATH STAR EXPLOSION, THIRD PHASE
L6070:  .word PHEDX3
L6072:  .word PHICN1                ;P. CN1,I  FIRST COIN
L6074:  .word PHECN1
L6076:  .word PHISG1                ;P. SG1,I  START GAME PART 1
L6078:  .word PHESG1
L607A:  .word PHISG2                ;P. SG2,I  START GAME PART 2
L607C:  .word PHESG2
L607E:  .word PHIBGN                ;P. BGN,I  BEGIN ACT
L6080:  .word PHEBGN
L6082:  .word PHISP1                ;P. SP1,I  SPACE WAVE 1
L6084:  .word PHESP1
L6086:  .word PHISP2                ;P. SP2,I  SPACE WAVE 2
L6088:  .word PHESP2
L608A:  .word PHIS0G                ;P. S0G,I  SPACE TO GROUND TRANSITION
L608C:  .word PHES0G
L608E:  .word PHIS1G                ;P. S1G,I  NEXT PART
L6090:  .word PHES1G
L6092:  .word PHIS0B                ;P. S0B,I  SPACE TO BASE TRENCH TRANSITION
L6094:  .word PHES0B
L6096:  .word PHIGD                 ;P. GD,I  GROUND PHASE
L6098:  .word PHEGD
L609A:  .word PHIG0B                ;P. G0B,I  GROUND TO BASE TRENCH TRANSITION
L609C:  .word PHEG0B
L609E:  .word PHIG1B                ;P. G1B,I  NEXT PART
L60A0:  .word PHEG1B
L60A2:  .word PHIBS                 ;P. BS,I  BASE STAR
L60A4:  .word PHEBS
L60A6:  .word PHIB0B                ;P. B0B,I  BASE TRENCH REPEAT TRANSITION
L60A8:  .word PHEB0B
L60AA:  .word PHINXT                ;P. NXT,I  NEXT ACT
L60AC:  .word PHENXT
L60AE:  .word PHIS0D                ;P. S0D,I  SPACE TO DIE, TRANSITION
L60B0:  .word PHES0D
L60B2:  .word PHIG0D                ;P. G0D,I  GROUND TO DIE, TRANSITION
L60B4:  .word PHEG0D
L60B6:  .word PHIB0D                ;P. B0D,I  BASE TRENCH TO DIE, TRANSITION
L60B8:  .word PHEB0D
L60BA:  .word PHIEGM                ;P. EGM,I  END GAME
L60BC:  .word PHEEGM

;------------------------------------------------------------------------------
; IFRAME - INIT GAME FRAME  (comment at the call)
;------------------------------------------------------------------------------
IFRAME:
L60BE:  INC  FRAME+1
L60C0:  BNE  L60CA                  ;IFEQ  ?OVERFLOW?
L60C2:  INC  FRAME                  ;KEEP TRACK
L60C4:  BNE  L60CA                  ;IFEQ  ?OVERFLOWED HI BYTE ALSO?
L60C6:  LDA  #$80                   ;?WORD OVERFLOW?
L60C8:  STA  FRAME                  ;THEN STICK
L60CA:  LDA  >S_S_CRDT
L60CD:  BNE  L60D4                  ;IFEQ
L60CF:  STA  COINSP                 ;0 ==> START OVER AGAIN
L60D2:  BRA  L60F4                  ;ELSE  ELSE GOT SOME COINS
L60D4:  LDA  COINSP
L60D7:  BNE  L60E4                  ;IFEQ  ?FIRST TIME?
L60D9:  JSR  SPKFOR                 ;'THE FORCE WILL BE WITH YOU'
L60DC:  LDA  >S_S_CRDT
L60DF:  STA  COINSP                 ;REMEMBER WHY WE SPOKE
L60E2:  BRA  L60F4                  ;ELSE  ELSE NOT FIRST TIME
L60E4:  LDA  COINSP
L60E7:  CMPA >S_S_CRDT
L60EA:  BHS  L60F4                  ;IFLO  ?GOT SOME NEW CREDIT AGAIN?
L60EC:  JSR  SPKALW                 ;'ALWAYS'
L60EF:  LDA  #$FF
L60F1:  STA  COINSP                 ;SAY NO MORE TILL COINS GONE
L60F4:  JSR  VGTOSITE               ;PULL VG(IRQ) CURSOR COORDS INTO SI.*
;GET EDGE OF SWITCHES-- LFIRE,RFIRE,AUX,TEST,COINS
L60F7:  LDA  GN_SWN                 ;PREVIOUS NEW VALUE
L60F9:  STA  GN_SWO                 ;IS CURRENT OLD VALUE
L60FB:  LDA  R_THMB
L60FD:  ANDA #THMBT                 ;ISOLATE THUMB BITS
L60FF:  PSHS A                      ;TEMP
L6101:  LDA  R_FIRE                 ;GET THIS NEWEST VALUE
L6103:  ANDA #-1-THMBT              ;OPEN UP SPACE FOR THUMBS
L6105:  ORA  ,S+                    ;ORA WITH POP
L6107:  ANDA #FIREBT|THMBT|AUXBIT   ;ONLY CONCERNED WITH GUN CONTROLS
L6109:  STA  GN_SWN                 ;AND SAY SO
L610B:  EORA GN_SWO                 ;CATCH ANY CHANGES
L610D:  ANDA GN_SWO                 ;FROM AN OLD '1'
L610F:  STA  GN_SWE                 ;1==>FALLING EDGE (WENT ON)
L6111:  RTS

;------------------------------------------------------------------------------
; IVGEN1 - SETUP VG  (comment at the calls)
;   SETUP VECTOR GENERATOR AND Y AS POINTER  (another call)
;   SETUP VG AND Y AS POINTER  (another call)
;------------------------------------------------------------------------------
IVGEN1:
L6112:  LDA  VGSYNC
L6114:  LDB  #(VGRAM&$FF)+VGVARB
L6116:  TFR  D,Y                    ;Y-->VG BUFFER

IVGEN:
L6118:  LDD  #VJINIT                ;INIT VECTOR GENERATOR
L611B:  STD  ,Y++
L611D:  RTS

;------------------------------------------------------------------------------
; DOWNVG - DOWNLOAD FAKEVGROM TO VGRAM
;------------------------------------------------------------------------------
DOWNVG:
L611E:  LDX  #FAKEVG                ;ROM ADDRESS OF VG INSTRUCTIONS
L6121:  LDU  #VGPSROM               ;ADDRESS OF WHERE THEY BELONG
L6124:  LDD  ,X++
L6126:  STD  ,U++
L6128:  CMPU #VGRROM                ;STOP AT VG REAL ROM
L612C:  BLO  L6124                  ;HSEND
L612E:  RTS

;------------------------------------------------------------------------------
; VGDONE - DONE WITH THE VG IN THIS PHASE  (comment at the calls)
;   ALL DONE WITH THE VG THIS PHASE  (another call)
;------------------------------------------------------------------------------
VGDONE:
L612F:  LDD  #VGCNTR                ;CENTER
L6132:  STD  ,Y++
L6134:  LDD  #$2020
L6137:  STD  ,Y++                   ;ASK FOR HALT
L6139:  STD  ,Y+                    ;FORCE HALT, POINT TO LAST ADDRESS USED
L613B:  TFR  Y,D                    ;CHECK FOR OVERFLOW
L613D:  SUBA VGSYNC                 ;END-BEGIN
L613F:  SUBA #VGBFSZ/$100           ;CMP WITH MAX SIZE
L6141:  BLO  L6155                  ;IFHS  ?OVERFLOW?
;;; SWI ;DIE--OVER RUN VG RAM
L6143:  JSR  DOWNVG                 ;RELOAD RAM COPY OF PSUEDOVGRAM
L6146:  LDD  #$2020
L6149:  STD  VGBFSZ+VGRAM-2
L614C:  STD  VGBFSZ+VGRAM-4
L614F:  STD  (2*VGBFSZ)+VGRAM-2
L6152:  STD  (2*VGBFSZ)+VGRAM-4
L6155:  LDA  #$FF                   ;FINISHED WITH BUFFER
L6157:  STA  VGSYNC                 ;MINUS INDICATES DONE WITH BUFFER
L6159:  RTS

;------------------------------------------------------------------------------
; IPARM - INIT SHIP AND ALIEN PARMS  (comment at the call)
;   INIT ALL PARMS  (another call)
;------------------------------------------------------------------------------
IPARM:
L615A:  JSR  IPGEN                  ;INIT PARAMETERS, GENERAL
L615D:  JSR  NW1SHP                 ;INIT PLAYERS SHIP
L6160:  RTS

;------------------------------------------------------------------------------
; IPGEN - INIT GENERAL PARMS
;------------------------------------------------------------------------------
IPGEN:
L6161:  LDA  P_RND1
L6164:  SUBA P_RND1                 ;rev 2 patch: Atari's 22-JUN-83 source and rev 1 have CMPA here ($B1)
L6167:  BNE  L6171                  ;IFEQ  ?# GENERATOR STUCK?
L6169:  STA  P_IRND                 ;INIT POLY COUNTER
L616C:  LDA  #$80                   ;START IT RUNNING
L616E:  STA  P_IRND
L6171:  LDA  #$80
L6173:  STA  ST_BRT                 ;STAR BRITENESS
L6175:  LDX  #ALIEN
L6178:  LDU  #M_AL
L617B:  LDB  #MS_ALBC

IPGEN_30:
L617D:  STU  AS_UVP,X
L617F:  STB  AS_BIC,X
L6181:  LEAU $20,U
L6184:  ADDB #$04
L6186:  LEAX AS_IZE,X
L6189:  CMPX #ALIENZ
L618C:  BLO  IPGEN_30
L618E:  LDX  #GUN
L6191:  LDU  #M_GN
L6194:  LDB  #MS_GNBC

IPGEN_40:
L6196:  STU  GS_UVP,X
L6198:  STB  GS_BIC,X
L619A:  CLR  GS_TYP,X
L619C:  LEAU 8,U
L619E:  ADDB #$01
L61A0:  LEAX GS_IZE,X
L61A2:  CMPX #GUNZ
L61A5:  BLO  IPGEN_40
L61A7:  JSR  NWNSHP
L61AA:  LDB  #TDS_RTH               ;ADD DARTH TO THE LIST
L61AC:  JSR  ADBOBJ
L61AF:  LDB  #TDS_GND               ;ALSO GROUND OBJECT
L61B1:  JSR  ADBOBJ
L61B4:  RTS

;------------------------------------------------------------------------------
; IMATH - RESTORE MATH BOX  (comment at the calls)
;------------------------------------------------------------------------------
IMATH:
L61B5:  LDD  #$0000
L61B8:  STD  M_ZRO
L61BB:  LDD  #$4000
L61BE:  STD  M_ONE                  ;CONSTANT '1'
L61C1:  LDD  #$E000                 ;CONSTANT DIVIDE BY 2
L61C4:  STD  M_HLF
L61C7:  LDD  #$0080                 ;ROUNDING CONSTANTS
L61CA:  STD  M_C80                  ;0080
L61CD:  LDD  #$0040
L61D0:  STD  M_C40                  ;0040
L61D3:  LDD  #$021F                 ;SIN,COS ANGLES
L61D6:  STD  M_SINH                 ;FOR .895 DEGREES
L61D9:  LDD  #$3FF7
L61DC:  STD  M_COS
L61DF:  LDD  #$4000                 ;SCALE
L61E2:  STD  M_SCL
L61E5:  LDD  #$0200
L61E8:  STD  M_DVN                  ;RECIPROCAL PERSPECTIVE
L61EB:  RTS

;------------------------------------------------------------------------------
; ISTAR - SETUP STARS  (comment at the call)
;------------------------------------------------------------------------------
ISTAR:
L61EC:  LDA  #$80
L61EE:  STA  ST_BRT                 ;INITIAL BRITENESS
L61F0:  LDX  #M_STAD

ISTAR_10:
L61F3:  LDA  P_RND2                 ;REVERSE OF INITING ORDER FOR RANDOMNESS
L61F6:  LDB  P_RND1                 ;TRY TO POPULATE EVENLY
L61F9:  STD  ,X
L61FB:  MUL
L61FC:  LDA  P_RND2
L61FF:  STD  2,X
L6201:  MUL
L6202:  LDA  P_RND2
L6205:  STD  4,X
L6207:  LEAX 8,X
L6209:  CMPX #M_STAZ
L620C:  BLO  ISTAR_10
L620E:  RTS

;------------------------------------------------------------------------------
; ISTARG - [note] Setup stars for the ground: each 8-byte block M_STAD..M_STAZ gets random X,Y (P_RND1/P_RND2) and Z = 0
;------------------------------------------------------------------------------
ISTARG:
L620F:  LDX  #M_STAD

ISTARG_10:
L6212:  LDA  P_RND2                 ;REVERSE OF INITING ORDER FOR RANDOMNESS
L6215:  LDB  P_RND1                 ;TRY TO POPULATE EVENLY
L6218:  STD  ,X
L621A:  MUL
L621B:  LDA  P_RND2
L621E:  STD  2,X
L6220:  LDD  #$0000                 ;CLRD
L6223:  STD  4,X
L6225:  LEAX 8,X
L6227:  CMPX #M_STAZ
L622A:  BLO  ISTARG_10
L622C:  RTS

;------------------------------------------------------------------------------
; STRTCK - CHECK FOR START SWITCH AND SELF TEST ( STATS )
;   THIS ROUTINE SHOULD ONLY BE CALLED DURING ATTRACT PHASES
;------------------------------------------------------------------------------
STRTCK:
L622D:  LDB  SI_RSX                 ;SITE POSITION X
L622F:  CMPB #$A0                   ;EXTREME LEFT?
L6231:  BGT  L623E                  ;IFLE  YES, MAY GO TO INSTRUCTION PHASE
L6233:  LDA  #PHS_INS+1
L6235:  CMPA PHASE                  ;ALREADY THERE?
L6237:  BEQ  L623C                  ;IFNE  NO, THEN GO THERE
L6239:  DECA                        ;INITIALIZER FRO THE PHASE
L623A:  STA  PHASE
L623C:  BRA  L624B                  ;ELSE
L623E:  CMPB #$60                   ;EXTREME RIGHT?
L6240:  BLT  L624B                  ;IFGE  YES, THEN MAYBE WE'LL GO TO HIGH SCORE TABLE
L6242:  LDA  #PHS_HIS+1
L6244:  CMPA PHASE                  ;ALREADY THERE?
L6246:  BEQ  L624B                  ;IFNE  NOPE, OK DOIT
L6248:  DECA                        ;INITIALIZER
L6249:  STA  PHASE
L624B:  LDA  OPTS0+1                ;LOW NIBBLE OF COIN OPTIONS
L624E:  ANDA #$03                   ;COIN MODE
L6250:  BNE  L6257                  ;IFEQ  FREE PLAY
L6252:  LDA  #$01                   ;GIVE FREE CREDIT ( NO 2 COIN MINIMUM )
L6254:  STA  >S_S_CRDT
L6257:  LDA  >S_S_CRDT              ;AVOID TEMPTATION TO DECA
L625A:  BEQ  TSTCK                  ;IFNE  MAYBE WE'LL START A GAME
L625C:  LDA  GN_SWE                 ;SWITCH EDGES
L625E:  ANDA #STRTBT                ;START SWITCH(ES)?
L6260:  BEQ  TSTCK                  ;IFNE  YES, OH BOY!!
L6262:  LDA  #PHS_SG1               ;START THE GAME
L6264:  STA  PHASE
L6266:  DEC  >S_S_CRDT

TSTCK:
L6269:  LDA  >IN_SW0                ;CHECK FOR SELF-TEST SWITCH
L626C:  ANDA #TESTBT
L626E:  BNE  L6274                  ;IFEQ  GO TO STATS PHASE
L6270:  LDA  #PHS_STS
L6272:  STA  PHASE
L6274:  RTS

;------------------------------------------------------------------------------
; PHERES - RESET
;------------------------------------------------------------------------------
PHERES:
L6275:  ORCC #$10                   ;SEI
L6277:  LDX  #POTSAV
L627A:  JSR  EETEMP                 ;GET POT VALUES FROM EEROM
L627D:  LDX  #TEMP
L6280:  JSR  PHERES_100
L6283:  STA  >RHEOP+RHS_LO
L6286:  LDX  #TEMP+1
L6289:  JSR  PHERES_100
L628C:  STA  >RHEOP+RHS_SP
L628F:  LDX  #TEMP+2
L6292:  JSR  PHERES_100
L6295:  STA  >RHEOY+RHS_LO
L6298:  LDX  #TEMP+3
L629B:  JSR  PHERES_100
L629E:  STA  >RHEOY+RHS_SP
L62A1:  ANDCC #$EF                  ;CLI
L62A3:  LDA  #PHS_HIS
L62A5:  STA  PHASE
L62A7:  LDA  #$FF                   ;DON'T PLAY MUSIC ON POWER UP
L62A9:  STA  MUSTIM
L62AC:  JSR  IMATH
L62AF:  JSR  IPARM
L62B2:  JSR  DOWNVG                 ;SETUP VG PSUEDO-ROM
L62B5:  JSR  ISTAR
L62B8:  JSR  ALLOFF                 ;TURN ALL MESSAGES OFF
L62BB:  LDA  #$00
L62BD:  STA  S_SC87
L62BF:  STA  S_SC65
L62C1:  STA  S_SC43
L62C3:  STA  S_SC21
L62C5:  STA  GS_GLW
L62C7:  STA  GS_HIT
L62C9:  JSR  SETINT                 ;SET UP HI SCORES AND INITIALS (HI KIDS!)
L62CC:  LDA  #$FF
L62CE:  STA  UPDFLG                 ;NO HIGH SCORES YET
L62D1:  STA  >MOOTIM                ;ALLOW COIN ROUTINE TO INIT ITSELF
L62D4:  RTS

PHERES_100:      ;ADJUST THE POTS
L62D5:  LDA  #$40                   ;ADJUST VALUES
L62D7:  CMPA ,X
L62D9:  BLS  L62E3                  ;IFHI
L62DB:  SUBA ,X
L62DD:  LSRA
L62DE:  LSRA
L62DF:  LSRA
L62E0:  INCA
L62E1:  ADDA ,X
L62E3:  RTS

;------------------------------------------------------------------------------
; PHIINS - INSTRUCTION PAGE
;------------------------------------------------------------------------------
PHIINS:
L62E4:  LDD  #$0000                 ;WAS 380 FOR SCROLLING
L62E7:  STD  PH_YOF                 ;PHASE Y OFFSET
L62EA:  LDD  #$0200
L62ED:  STD  PH_TIM
L62F0:  LDA  #MS_FLI                ;"FLIGHT INSTRUCTIONS..."
L62F2:  STA  NXTMES
L62F5:  LDA  #MS_FLZ+1
L62F7:  STA  LSTMES
L62FA:  LDD  #VGCOLR+(VGCRED*$100)  ;RED
L62FD:  STD  PH_COL
L6300:  JSR  ALLOFF                 ;TURN OFF ALL MESSAGES
L6303:  INC  PHASE
L6305:  RTS

;------------------------------------------------------------------------------
; PHEINS - FLIGHT INSTRUCTIONS  (comment at its table entry)
;------------------------------------------------------------------------------
PHEINS:
L6306:  JSR  IVGEN1                 ;SETUP VECTOR GENERATOR AND Y AS POINTER
L6309:  JSR  VWMES                  ;SCORE AND STUFF
L630C:  JSR  VWCOIN                 ;"INSERT COIN", ETC.
L630F:  JSR  VWPAGE                 ;VIEW INSTRUCTION OR SCORING SCREEN
L6312:  JSR  VWSTAR                 ;SHOW THEM STARS
L6315:  JSR  VGDONE                 ;DONE WITH THE VG IN THIS PHASE
L6318:  JSR  SMVINS                 ;MOVE THE STARS FOR INSTRUCTION SCREEN
L631B:  LDD  PH_TIM                 ;DONE?
L631E:  BPL  L6322                  ;IFMI  YES, THEN GO ON TO THE NEXT PHASE
L6320:  INC  PHASE
L6322:  JSR  STRTCK                 ;CHECK FOR START SWITCH
L6325:  RTS

;------------------------------------------------------------------------------
; PHISCR - SCORING PAGE
;------------------------------------------------------------------------------
PHISCR:
L6326:  LDD  #$03C0                 ;FOR SCROLLING
L6329:  STD  PH_YOF
L632C:  LDD  #$0200
L632F:  STD  PH_TIM
L6332:  LDA  #MS_SCR                ;"SCORING"
L6334:  STA  NXTMES
L6337:  LDA  #MS_SCZ+1
L6339:  STA  LSTMES
L633C:  LDD  #VGCOLR+(VGCPRP*$100)  ;PURPLE
L633F:  STD  PH_COL
L6342:  JSR  ALLOFF
L6345:  INC  PHASE
L6347:  RTS

;------------------------------------------------------------------------------
; PHESCR - SCORING PAGE  (comment at its table entry)
;------------------------------------------------------------------------------
PHESCR:
L6348:  JSR  IVGEN1                 ;SETUP VECTOR GENERATOR AND Y AS POINTER
L634B:  JSR  VWMES                  ;SCORE AND STUFF
L634E:  JSR  VWCOIN                 ;"INSERT COIN", ETC.
L6351:  JSR  VWPAGE                 ;VIEW INSTRUCTION OR SCORING SCREEN
L6354:  JSR  VWSTAR                 ;SHOW THEM STARS
L6357:  JSR  VGDONE                 ;DONE WITH THE VG IN THIS PHASE
L635A:  JSR  SMVSCR                 ;MOVE THE STARS FOR SCORING SCREEN
L635D:  LDD  PH_TIM                 ;DONE?
L6360:  BPL  L6364                  ;IFMI  YES, THEN GO ON TO THE NEXT PHASE
L6362:  INC  PHASE
L6364:  JSR  STRTCK                 ;CHECK FOR START SWITCH
L6367:  RTS

;------------------------------------------------------------------------------
; VWPAGE - VIEW INSTRUCTION OR SCORING SCREEN  (comment at the calls)
;------------------------------------------------------------------------------
VWPAGE:
L6368:  LDD  PH_TIM                 ;UPDATE PHASE TIMER ( DOWNDATE ??? )
L636B:  SUBD #$0001
L636E:  STD  PH_TIM
L6371:  ANDB #$07                   ;READY TO START NEXT LINE?
L6373:  BNE  L639D                  ;IFEQ  YES
L6375:  LDA  NXTMES
L6378:  BMI  L637D                  ;IFPL  A NEGATIVE VALUE MEANS NO MORE LINES
L637A:  JSR  MESSON
L637D:  LDA  NXTMES
L6380:  CMPA #MS_FLI+3              ;SHIELD STRENGTH MESSAGE
L6382:  BNE  L638E                  ;IFEQ  INSERT CORRECT STRENGTH
L6384:  LDA  OPTS1+1                ;LOW NIBBLE OF 2ND OPTION SWITCH BANK
L6387:  ANDA #$03
L6389:  ADDA #MS_FLZ+1              ;SHOULD GIVE STRENGTH FROM 6 TO 9
L638B:  JSR  MESSON
L638E:  LDA  NXTMES                 ;INC NEXT MESSAGE
L6391:  ADDA #$01
L6393:  CMPA LSTMES                 ;NO MORE FOR THIS PHASE?
L6396:  BLO  L639A                  ;IFHS  THAT'S ALL FOLKS
L6398:  LDA  #$80                   ;FLAG IT AS NO MORE
L639A:  STA  NXTMES
L639D:  LDD  PH_YOF                 ;UPDATE MESSAGE Y OFFSET ( SCROLL )
L63A0:  SUBD #$0008
L63A3:  BPL  L63A8                  ;IFMI  TOO FAR
L63A5:  LDD  #$0000
L63A8:  STD  PH_YOF
L63AB:  LDD  PH_TIM
L63AE:  CMPD #$00C0
L63B2:  BHS  L63C6                  ;IFLO  START FADING MESSAGES OUT
L63B4:  LDB  PH_COL+1               ;DECREMENT Z
L63B7:  SUBB #$01
L63B9:  CMPB #$10                   ;DIM ENOUGH AT 10 DON'T WASTE TIME GOING TO 0
L63BB:  BHS  L63C3                  ;IFLO
L63BD:  LDD  #$0000
L63C0:  STD  PH_TIM                 ;PHASE OVER
L63C3:  STB  PH_COL+1
L63C6:  LDD  PH_YOF
L63C9:  STD  >MSYOFF
L63CC:  LDD  PH_COL                 ;COLOR AND BRIGHTNESS
L63CF:  STD  ,Y++
L63D1:  JSR  VWMES2                 ;VIEW MESAGES (NO COLOR COMMAND )
L63D4:  RTS

;------------------------------------------------------------------------------
; VWCOIN - "INSERT COIN", ETC.  (comment at the calls)
;   "GAME OVER", ETC.  (another call)
;   COIN STUFF  (another call)
;------------------------------------------------------------------------------
VWCOIN:
L63D5:  LDA  >S_S_CRDT              ;DO THE FIRST OF TWO LINES
L63D8:  BNE  L63EB                  ;IFEQ  NO CREDIT--FLASH "GAME OVER"+"INSERT COINS"
L63DA:  LDA  FRAME+1
L63DC:  ANDA #$10                   ;PICK A RATE FOR FLASH
L63DE:  BNE  L63E4                  ;IFEQ
L63E0:  LDB  #MS_INS                ;"INSERT COINS" ON
L63E2:  BRA  L63E6                  ;ELSE
L63E4:  LDB  #MS_GVR                ;"GAME OVER" ON
L63E6:  JSR  DOMESS
L63E9:  BRA  L63F0                  ;ELSE  ELSE WE HAVE ENUF CREDIT
;WE GOT THEIR MONEY SO TELL THEM TO...
L63EB:  LDB  #MS_STR                ;"PRESS FIRE TO START"
L63ED:  JSR  DOMESS
;NOW DO SECOND OF TWO LINES
L63F0:  LDA  >S_S_CRDT
L63F3:  BNE  VWCOIN_50              ;IFEQ  ?NO CREDITS YET?
L63F5:  LDA  >S_CNCT
L63F8:  BEQ  VWCOIN_30              ;IFNE  ?ANY PARTIAL CREDITS?
L63FA:  LDA  FRAMEL
L63FC:  ANDA #$10
L63FE:  BEQ  VWCOIN_30              ;B INSERT COINS GOES WITH COIN COST
L6400:  BRA  VWCOIN_50              ;B GAME OVER GOES WITH # OF CREDITS
L6402:  BRA  L640E                  ;ELSE  ELSE NO PARTIAL CREDITS

VWCOIN_30:
;NOW TELL THEM HOW MUCH ITS GONNA COST
L6404:  LDB  OPTS0+1                ;LOW NIBBLE OF COIN OPTIONS
L6407:  ANDB #$03                   ;0=FREE,1=2 PLAYS/COIN,2=1PLAY/COIN,3=2COINS/PLAY
L6409:  ADDB #MS_FRE                ;GET CORRECT MESSAGE NUMBER
L640B:  JSR  DOMESS                 ;DOIT
L640E:  BRA  L6458                  ;ELSE  ELSE WE HAVE SOME CREDITS

VWCOIN_50:
L6410:  LDA  >S_S_CRDT              ;SHOW HOW MANY "CREDITS" THEY HAVE
L6413:  ADDA >S_CNCT
L6416:  CMPA #$01
L6418:  BNE  L641E                  ;IFEQ  ?GOT HALF OR ONE CREDITS?
L641A:  LDB  #MS_CRD+1              ;THEN SAY SINGULAR CREDIT
L641C:  BRA  L6420                  ;ELSE  ELSE USE PLURAL
L641E:  LDB  #MS_CRD
L6420:  JSR  DOMESS
L6423:  LDD  #$01B0
L6426:  ANDA #$1F
L6428:  STD  ,Y++
L642A:  LDD  #$FF80
L642D:  TST  >S_CNCT
L6430:  BEQ  L6435                  ;IFNE  ?HAVE A PARTIAL CREDIT?
L6432:  SUBD #$0018                 ;THEN BACK UP, PREPARE FOR HALF SIGN
L6435:  ANDA #$1F
L6437:  STD  ,Y++
L6439:  LDA  >S_S_CRDT              ;00-12 HEX
L643C:  CMPA #$0A
L643E:  BLO  L6442                  ;IFHS  CONVERT 0A-12 TO 10-18
L6440:  ADDA #$06
L6442:  LDB  #$02                   ;SUPPRESS BOTH DIGITS
L6444:  STB  BT_SUP
L6446:  JSR  VWBYTE                 ;SHOW THEM
L6449:  LDA  >S_CNCT
L644C:  BEQ  L6453                  ;IFNE  ?STILL HAVE A PARTIAL CREDIT?
L644E:  LDD  #VJHALF                ;THEN SAY SO
L6451:  STD  ,Y++
L6453:  LDD  #VGCNTR                ;ALWAYS DO A CENTER AFTER YOU'RE DONE
L6456:  STD  ,Y++
L6458:  RTS

;------------------------------------------------------------------------------
; PHIHIS - HIGH SCORE DISPLAY
;------------------------------------------------------------------------------
PHIHIS:
L6459:  LDD  #$0000
L645C:  STD  PH_YOF
L645F:  STD  >MSYOFF
L6462:  LDD  #$0100
L6465:  STD  PH_TIM
L6468:  LDD  #VGCOLR+(VGCBLU*$100)
L646B:  STD  PH_COL
L646E:  JSR  ALLOFF
L6471:  JSR  IMATH                  ;RESTORE MATH BOX
L6474:  JSR  IPARM
L6477:  LDU  #M_U1                  ;STARS ASSUME UV1 MATRIX
L647A:  JSR  UNITV                  ;SETUP FACING FORWARD
L647D:  JSR  CHKHIS                 ;CHECK HI SCORE FOR REASONABLENESS
L6480:  INC  PHASE
L6482:  RTS

;------------------------------------------------------------------------------
; PHEHIS - HI SCORE TABLE DISPLAY  (comment at its table entry)
;------------------------------------------------------------------------------
PHEHIS:
L6483:  JSR  IVGEN1                 ;SETUP VG AND Y AS POINTER
L6486:  JSR  CPYRGHT                ;SHOW COPYRIGHT MESSAGE
;***COPYRIGHT FIRST FOR SECURITY CHECK
L6489:  JSR  VWSTAR                 ;SHOW THOSE STARS
L648C:  JSR  VWMES                  ;SCORE AND STUFF
L648F:  JSR  VWCOIN                 ;"GAME OVER", ETC.
L6492:  LDD  PH_TIM                 ;FADER?
L6495:  CMPD #$0050
L6499:  BHS  L64A9                  ;IFLO  YEP, DIM IT DOWN
L649B:  LDB  PH_COL+1
L649E:  SUBB #$01
L64A0:  CMPB #$F0
L64A2:  BLO  L64A6                  ;IFHS  PROBABLY WRAPPED
L64A4:  LDB  #$00
L64A6:  STB  PH_COL+1
L64A9:  LDD  PH_COL                 ;PUT THE COLOR OUT
L64AC:  STD  ,Y++
L64AE:  JSR  VWHSCR                 ;PUT THE HIGH SCORES ON THE SCREEN
L64B1:  JSR  VWMESS                 ;SHOW MESSAGES
L64B4:  JSR  VGDONE                 ;ALL DONE WITH THE VG THIS PHASE
L64B7:  JSR  SMVHIS                 ;MOVE THE STARS APPROPRIATLY FOR HIGH SCORES
L64BA:  LDD  PH_TIM                 ;UPDATE TIMER
L64BD:  SUBD #$0001
L64C0:  STD  PH_TIM
L64C3:  BPL  L64C9                  ;IFMI  THATS LONG ENOUGH
L64C5:  LDA  #PHS_BNR               ;SHOW 'EM THE BANNER
L64C7:  STA  PHASE
L64C9:  JSR  STRTCK                 ;CHECK FOR START OR STATS
L64CC:  RTS

;------------------------------------------------------------------------------
; CPYRGHT - SHOW COPYRIGHT MESSAGE  (comment at the call)
;------------------------------------------------------------------------------
CPYRGHT:
L64CD:  LDB  #MS_CPY                ;COPYRIGHT MESSAGES
L64CF:  JSR  DOMESS                 ;MESSAGE AND SETS COLOR
L64D2:  LDB  #MS_CPY+1
L64D4:  JSR  DOMESS
L64D7:  LDB  #MS_CPY+2
L64D9:  JSR  DOMESS
L64DC:  LDB  #MS_CPZ                ;LAST ONE
L64DE:  JSR  DOMESS
L64E1:  RTS

;------------------------------------------------------------------------------
; PHISTS - STATISTICS DISPLAY
;------------------------------------------------------------------------------
PHISTS:
L64E2:  JSR  ALLOFF
L64E5:  LDD  #$0000                 ;NO Y OFFSET FOR MESSAGES
L64E8:  STD  PH_YOF
L64EB:  STD  >MSYOFF
L64EE:  INC  PHASE
L64F0:  RTS

;------------------------------------------------------------------------------
; PHESTS - STATISTICS  (comment at its table entry)
;------------------------------------------------------------------------------
PHESTS:
L64F1:  JSR  IVGEN1                 ;SETUP VG
L64F4:  JSR  EEACC                  ;DISPLAY STATS AND ACCOUNTING INFO
L64F7:  JSR  VWMESS
L64FA:  JSR  VGDONE
L64FD:  LDA  GN_SWE                 ;CHECK FOR AUX SWITCH
L64FF:  ANDA #AUXBIT
L6501:  BEQ  L6507                  ;IFNE  GOTO NEXT PHASE
L6503:  LDA  #PHS_OPT               ;OPTIONS PAGE
L6505:  STA  PHASE
L6507:  LDA  >IN_SW0                ;CHECK FOR SELF TEST SWITCH
L650A:  ANDA #TESTBT
L650C:  BEQ  L6512                  ;IFNE  SWITCH OFF, GO BACK TO ATTRACT MODE
L650E:  LDA  #PHS_BNR               ;BANNER PHASE
L6510:  STA  PHASE
L6512:  RTS

;------------------------------------------------------------------------------
; PHIOPT - OPTION SWITCH  (comment at its table entry)
;------------------------------------------------------------------------------
PHIOPT:
L6513:  JSR  ALLOFF                 ;TURN OFF ALL MESSAGES
L6516:  LDA  #$0A                   ;HIGH LITE INDEX STARTS WITH MESSAGE
L6518:  STA  EEINDX
L651B:  LDA  #$00
L651D:  STA  RESETS                 ;START WITH A CLEAN SHEET
L6520:  STA  NVTSTR                 ;NOVRAM TEST RESULTS ( 0 MEANS NO TEST DONE )
L6523:  LDA  #NAREA
L6525:  JSR  SUMMIT                 ;CHECK FOR PROPER CHECKSUM
L6528:  BEQ  L652F                  ;IFNE  ?BAD CHECKSUM?
L652A:  LDA  #NAREA
L652C:  JSR  EEINI0                 ;THEN RE-INIT IT
L652F:  INC  PHASE
L6531:  RTS

;------------------------------------------------------------------------------
; PHEOPT - OPTION SWITCH  (comment at its table entry)
;------------------------------------------------------------------------------
PHEOPT:
L6532:  JSR  IVGEN1                 ;SETUP VG
L6535:  JSR  EEOPT                  ;DISPLAY ALL OPTIONS
L6538:  LDD  #VGCOLR+(VGCWHT*$100)  ;HILITE COLOR
L653B:  STD  ,Y++
L653D:  LDB  #MS_OPT+1              ;BASE MESSAGE NUMBER
L653F:  ADDB EEINDX
L6542:  JSR  DOMES2                 ;OUTPUT OPTION MESSAGE IN HILITE
L6545:  LDA  EEINDX                 ;HILITE THIS OPTION'S VALUE
L6548:  JSR  EEOPT3                 ;OUTPUT OPTION VALUE
L654B:  JSR  EEOPT1                 ;MAKE CHANGES TO OPTIONS
L654E:  JSR  VWMESS
L6551:  JSR  VGDONE
L6554:  LDA  GN_SWE                 ;CHECK FOR AUX SWITCH
L6556:  ANDA #AUXBIT
L6558:  BEQ  L655D                  ;IFNE  GOTO NEXT PHASE
L655A:  JMP  RESET                  ;DO RESET AND SELF TEST
L655D:  LDA  >IN_SW0                ;CHECK FOR SELF TEST SWITCH
L6560:  ANDA #TESTBT
L6562:  BEQ  L656B                  ;IFNE  SWITCH OFF, GO BACK TO ATTRACT MODE
L6564:  JSR  ALLOFF                 ;TURN OFF ALL MESSAGES
L6567:  LDA  #PHS_BNR               ;BANNER PHASE
L6569:  STA  PHASE
L656B:  RTS

;------------------------------------------------------------------------------
; PHISDS - SELECT A DEATH STAR
;------------------------------------------------------------------------------
PHISDS:
L656C:  LDD  #$0100
L656F:  STD  PH_TIM
L6572:  LDD  #$0000
L6575:  STD  PH_YOF
L6578:  STD  >MSYOFF
L657B:  LDD  #VGCOLR+(VGCRED*$100)  ;RED
L657E:  STD  PH_COL
L6581:  JSR  ALLOFF                 ;TURN OFF ALL MESSAGES
L6584:  LDB  #MS_DS1
L6586:  TFR  B,A
L6588:  JSR  MESSON
L658B:  INCB
L658C:  CMPB #MS_DSZ+1
L658E:  BLO  L6586                  ;HSEND
L6590:  INC  PHASE
L6592:  RTS

TDTH:            ;X,Y POS
L6593:  .word $0064, $FE70
;;; .WORD -100.,-200.
L6597:  .word $FED4, $0000
;;; .WORD -100.,200.
L659B:  .word $0064, $0190

;------------------------------------------------------------------------------
; TDTHZ - SELECT A DEATH STAR  (comment at its table entry)
;   (also: PHESDS)
;------------------------------------------------------------------------------
TDTHZ:
PHESDS:
L659F:  LDD  PH_TIM
L65A2:  SUBD #$0001
L65A5:  STD  PH_TIM
L65A8:  BPL  L65BD                  ;IFMI  PLAYER DIDN'T DECIDE, START AT EASY
L65AA:  LDA  #$00
L65AC:  STA  GM_WAV
L65AF:  LDA  #PHS_SG2               ;START THE GAME
L65B1:  STA  PHASE
L65B3:  CLR  >GTIME+2
L65B6:  CLR  >GTIME+1               ;CLEAR GAME TIMES AT START OF GAME
L65B9:  CLR  >GTIME                 ;KEEP CORRECT ORDER (IRQ INTERACTION)
L65BC:  RTS
L65BD:  JSR  IVGEN1                 ;SETUP VG
L65C0:  LDX  #TDTH                  ;TABLE FOR DEATH STAR SETUP
L65C3:  LDD  ,X++                   ;Y POS
L65C5:  ANDA #$1F
L65C7:  STD  ,Y++
L65C9:  LDD  ,X++                   ;X POS
L65CB:  ANDA #$1F
L65CD:  STD  ,Y++
L65CF:  LDD  #VGSCAL+0              ;SIZE THE DEATH STAR
L65D2:  STD  ,Y++
L65D4:  LDD  #VJBMIN                ;MINIATURE BASE
L65D7:  STD  ,Y++
L65D9:  CMPX #TDTHZ                 ;END OF TABLE?
L65DC:  BLO  L65C3                  ;HSEND
L65DE:  LDA  WV_LVL                 ;WHAT COLOR FOR THE CURSOR
L65E0:  BPL  L65E7                  ;IFMI  NOT ON ANY PLANETOID
L65E2:  LDD  #VGCOLR+(VGCTRQ*$100)  ;SO MAKE IT THE STANDARD CURSOR COLOR
L65E5:  BRA  L65EA                  ;ELSE  ZEROED IN ON A FAVORITE
L65E7:  LDD  #VGCOLR+(VGCYLW*$100)  ;LET THEM SEE THE LIGHT
L65EA:  STD  ,Y++
L65EC:  JSR  VWSITC                 ;SITE WITHOUT COLOR INSTRUCTIONS
L65EF:  JSR  VWMESS                 ;LOOK AT THE MESSAGES
L65F2:  LDD  #$00C8                 ;POSITION FOR COUNTDOWN
L65F5:  STD  ,Y++
L65F7:  LDD  #$1FF0
L65FA:  STD  ,Y++
L65FC:  LDD  PH_TIM
L65FF:  ASLB                        ;ASLD
L6600:  ROLA
L6601:  ASLB                        ;ASLD
L6602:  ROLA
L6603:  ASLB                        ;ASLD  RESULTS ARE 00-10 HEX
L6604:  ROLA
L6605:  CMPA #$0A
L6607:  BLO  L660B                  ;IFHS  CONVERT 0A-10 (HEX) TO 10-16 (DEC)
L6609:  ADDA #$06
L660B:  JSR  VWBYTE
L660E:  JSR  VGDONE
L6611:  LDA  #$FF
L6613:  STA  WV_LVL                 ;FLAG
L6615:  LDX  #TDTH
L6618:  LDD  SI_CY                  ;Y POS OF CURSOR
L661A:  ADDD #VGOFFY                ;ADD BACK THE SCREEN OFFSET
L661D:  SUBD ,X                     ;MINUS SCREEN CO-ORD FOR DEATH STAR
L661F:  TSTA                        ;ABSD
L6620:  BPL  L6626
L6622:  COMA
L6623:  NEGB
L6624:  SBCA #$FF
L6626:  STD  TEMP
L6629:  CMPD #$0048
L662D:  BHS  L6668                  ;IFLO  POSSIBLE HIT
L662F:  LDD  SI_CX                  ;X POS OF CURSOR
L6631:  SUBD 2,X
L6633:  TSTA                        ;ABSD
L6634:  BPL  L663A
L6636:  COMA
L6637:  NEGB
L6638:  SBCA #$FF
L663A:  CMPD #$0034
L663E:  BHS  L6668                  ;IFLO  GETTING CLOSER
L6640:  ADDD TEMP
L6643:  CMPD #$0050
L6647:  BHS  L6668                  ;IFLO  DEFINITE HIT
L6649:  TFR  X,D
L664B:  SUBD #TDTH
L664E:  LSRB                        ;CONVERT 0->0,4->2,8->4
L664F:  STB  WV_LVL                 ;FLAG FOR YELLOW CURSOR
L6651:  STB  GM_WAV
L6654:  LDA  GN_SWE
L6656:  ANDA #FIREBT|THMBT          ;EITHER TRIGGER OR THUMB SWITCH
L6658:  BEQ  L6667                  ;IFNE  YUP, BUT DID PLAYER HIT ANYTHING
L665A:  LDA  #PHS_SG2               ;FINISH STARTING THE GAME
L665C:  STA  PHASE
L665E:  CLR  >GTIME+2               ;CLEAR GAME TIMES AT START OF GAME
L6661:  CLR  >GTIME+1
L6664:  CLR  >GTIME                 ;DO IN CORRECT ORDER (IRQ INTERACTION)
L6667:  RTS                         ;LEAVE
L6668:  LEAX 4,X
L666A:  CMPX #TDTHZ
L666D:  BLO  L6618                  ;HSEND
L666F:  RTS

;------------------------------------------------------------------------------
; PHIENT - ENTER INITIALS
;------------------------------------------------------------------------------
PHIENT:
L6670:  LDD  #$0000
L6673:  STD  PH_TIM
L6676:  STD  PH_YOF
L6679:  STD  >MSYOFF
L667C:  LDD  #VGCOLR+(VGCBLU*$100)
L667F:  STD  PH_COL
L6682:  JSR  ALLOFF
L6685:  LDA  #MS_HS1
L6687:  JSR  MESSON
L668A:  LDA  #MS_HS1+1
L668C:  JSR  MESSON
L668F:  LDA  #MS_HS1+2
L6691:  JSR  MESSON
L6694:  LDA  #MS_HS1+3
L6696:  JSR  MESSON
L6699:  LDA  #MS_HS1+4
L669B:  JSR  MESSON
L669E:  LDA  #MS_HSZ
L66A0:  JSR  MESSON
L66A3:  JSR  PMCNT                  ;CANTINA MUSIC
L66A6:  JSR  CHKHIS                 ;CHECK EAROM HI SCORES FOR REASONABLENESS
L66A9:  INC  PHASE
L66AB:  RTS

;------------------------------------------------------------------------------
; PHEENT - ENTER INITIALS  (comment at its table entry)
;------------------------------------------------------------------------------
PHEENT:
L66AC:  JSR  IVGEN1                 ;ENTER INITIALS FOR HIGH SCORE
L66AF:  JSR  VWMES                  ;SCORE AND STUFF
L66B2:  JSR  VWCOIN                 ;COIN STUFF
L66B5:  JSR  VWHSCR
L66B8:  JSR  VWMESS
L66BB:  JSR  VGDONE
L66BE:  JSR  GETINT                 ;GET THE PLAYER'S INITIALS
L66C1:  LDA  >IN_SW0                ;CHECK FOR TEST SWITCH
L66C4:  ANDA #TESTBT
L66C6:  BNE  L66CE                  ;IFEQ  YES
L66C8:  LDD  #$0300                 ;THEN ATTEMPT TO LEAVE THIS MODE GRACEFULLY
L66CB:  STD  PH_TIM                 ;SAYS TIME'S UP, NO MORE INITIALS
L66CE:  LDD  PH_TIM
L66D1:  ADDD #$0001
L66D4:  STD  PH_TIM
L66D7:  CMPD #$0280                 ;GIVE 'EM ABOUT 30 SECONDS
L66DB:  BLO  L66E3                  ;IFHS
L66DD:  LDD  #$FFFF
L66E0:  STD  UPDFLG
L66E3:  LDD  UPDFLG
L66E6:  BPL  L6707                  ;IFMI  DONE
L66E8:  LDA  #PHS_HIS               ;LOOK AT HIGH SCORE TABLE NOW
L66EA:  STA  PHASE
L66EC:  LDU  #INITLS                ;TRANSFER TOP 3 HIGH SCORES TO NON-VOLATILE RAM
L66EF:  LDX  #SAVINT
L66F2:  LDA  #$08
L66F4:  JSR  TMPEE3
L66F7:  LDU  #HSCORS
L66FA:  LDX  #SAVSCR
L66FD:  LDA  #$0B
L66FF:  JSR  TMPEE3
L6702:  LDA  #$01                   ;EEROM AREA 1
L6704:  JSR  EECKSM
L6707:  RTS

;------------------------------------------------------------------------------
; PHIBNR - COIN1
;   (also: PHICN1)
;------------------------------------------------------------------------------
PHIBNR:
PHICN1:
L6708:  INC  PHASE
L670A:  JSR  DOWNVG                 ;DOWNLOAD PSUEDO VGROM TO VGRAM
L670D:  JSR  ALLOFF                 ;TURN OFF ALL MESSAGES
L6710:  LDD  #$0000                 ;SET Y OFFSETS FOR MESSAGES TO 0
L6713:  STD  PH_YOF
L6716:  STD  >MSYOFF
L6719:  JSR  BGBNNR                 ;START UP THE BANNER
L671C:  JSR  IMATH                  ;RESTORE MATH BOX
L671F:  JSR  IPARM
L6722:  LDU  #M_U1                  ;STARS ASSUME UV1 MATRIX
L6725:  JSR  UNITV                  ;SETUP FACING FORWARD
L6728:  LDA  MUSTIM
L672B:  CMPA #$FF                   ;SPECIAL FLAG FOR SKIPPING MUSIC THIS TIME
L672D:  BNE  L6737                  ;IFEQ  SKIP IT
L672F:  LDA  TIMER+2                ;PREPARE FOR NEXT CYCLE
L6732:  STA  MUSTIM
L6735:  BRA  L6758                  ;ELSE
L6737:  LDA  TIMER+2
L673A:  CMPA MUSTIM
L673D:  BEQ  L6758                  ;IFNE  APROX 6.66666 MINS.
L673F:  STA  MUSTIM                 ;FOR NEXT TIME
L6742:  JSR  EEUTIM                 ;TIME TO UPDATE TIMEON
L6745:  LDA  OPTS1                  ;HIGH NIBBLE OF 2ND OPTION BANK
L6748:  ANDA #$04                   ;THE OPERATOR SICK AND TIRED OF THE MUSIC YET?
L674A:  BNE  L6758                  ;IFEQ  NO! THEN GIVE SOME MORE TO HEAR
L674C:  LDX  #TMUSIC
L674F:  LDA  P_RND1
L6752:  LDB  #(ZMUSIC-TMUSIC)/2     ;# OF ENTRIES
L6754:  MUL
L6755:  LSLA                        ;WORD POINTER
L6756:  JSR  [A,X]
L6758:  RTS

TMUSIC:
L6759:  .word PMBEN, PMCNT, PMEND, PMRRP
L6761:  .word PMTHB, PMTH5, PMREB, PM4TH
L6769:  .word PMDAR

;------------------------------------------------------------------------------
; ZMUSIC - BANNER  (comment at its table entry)
;   (also: PHEBNR, PHECN1)
;------------------------------------------------------------------------------
ZMUSIC:
PHEBNR:
PHECN1:
L676B:  JSR  IVGEN1
L676E:  JSR  VWSTAR
L6771:  JSR  VWBNNR                 ;VIEW BANNER
L6774:  JSR  VWSPMS                 ;WITH CLOSE COUPLED SPECIAL MESSAGES
L6777:  JSR  VWCOIN
L677A:  JSR  VWMES                  ;SCORE AND STUFF
L677D:  JSR  VGDONE
L6780:  JSR  SMVBNR                 ;MOVE THE STARS IN BACK OF THE BANNER
L6783:  JSR  STRTCK                 ;LOOK FOR STARTUP OR STATS OR TEST OR ?
L6786:  RTS

;------------------------------------------------------------------------------
; PHISG1 - START GAME A
;------------------------------------------------------------------------------
PHISG1:
L6787:  LDA  #$05
L6789:  STA  PH_TIM
L678C:  LDA  #$FF                   ;DON'T PLAY MUSIC RIGHT AFTER WE FINISH A GAME
L678E:  STA  MUSTIM
L6791:  JSR  ALLOFF
L6794:  JSR  SPKRED
L6797:  INC  PHASE
L6799:  RTS

;------------------------------------------------------------------------------
; PHESG1 - START GAME PART 1  (comment at its table entry)
;------------------------------------------------------------------------------
PHESG1:
L679A:  LDA  #PHS_SDS               ;SELECT DETH STAR NEXT
L679C:  STA  PHASE
L679E:  LDD  #$0000
L67A1:  STD  FRAME
L67A3:  STA  WV_LVL                 ;START AT LEVEL 0
L67A5:  LDA  OPTS1+1                ;LOW NIBBLE OF OPTION SWITCH BANK 2
L67A8:  ANDA #$03                   ;GAS OPTION
L67AA:  ADDA #$06                   ;GIVES 6 TO 9 UNITS OF SHIELD STRENGTH
L67AC:  STA  S_GAS
L67AE:  STA  GS_OLD                 ;SET UP OLD VALUE ALSO
L67B0:  LDA  OPTS1+1
L67B3:  LSRA
L67B4:  LSRA
L67B5:  ANDA #$03                   ;ISOLATE GAME DIFFICULTY OPTION
L67B7:  STA  GM_DIF                 ;CURRENT DEFAULT DIFFICULTY, STARTS AT 0(EASY)
L67BA:  LDA  #$00
L67BC:  STA  GM_BMP                 ;DETECT RINGERS THAT START TOO EASY
L67BF:  STA  GS_GLW
L67C1:  STA  GS_HIT
L67C3:  STA  S_SC87
L67C5:  STA  S_SC65
L67C7:  STA  S_SC43
L67C9:  STA  S_SC21
L67CB:  STA  SC_FWV                 ;ZERO FLAG FOR FIRST WAVE ONLY
L67CE:  STA  Q_GHIT                 ;SOUNDOUT ON FIRST GUNHIT
L67D1:  STA  Q_ATP                  ;NO TOPS CLEARED WHEN FIRST STARTING UP
L67D4:  ORCC #$10                   ;SEI
L67D6:  INC  >RHEOY+RHS_LO          ;PERTURB RKEOSTAT LIMITS
L67D9:  INC  >RHEOP+RHS_LO
L67DC:  INC  >RHEOY+RHS_SP
L67DF:  INC  >RHEOP+RHS_SP
L67E2:  ANDCC #$EF                  ;CLI
L67E4:  RTS

;------------------------------------------------------------------------------
; PHISG2 - FINISH STARTING UP THE GAME
;------------------------------------------------------------------------------
PHISG2:
L67E5:  JSR  IMATH
L67E8:  JSR  IPARM
L67EB:  JSR  ISTAR
L67EE:  LDA  #$C0                   ;FACE BACKWARDS
L67F0:  STA  (MS_AX+M_S1)&$FFFF
L67F3:  STA  (MS_BY+M_S1)&$FFFF
L67F6:  LDA  #$00
L67F8:  STA  >S_BCCNT               ;NO MORE BONUS COINS THIS TIME AROUND
L67FB:  INC  PHASE

;------------------------------------------------------------------------------
; PHESG2 - START GAME PART 2  (comment at its table entry)
;------------------------------------------------------------------------------
PHESG2:
L67FD:  LDA  #PHS_BGN
L67FF:  STA  PHASE
L6801:  RTS

;------------------------------------------------------------------------------
; PHIBGN - BEGIN ACT
;------------------------------------------------------------------------------
PHIBGN:
L6802:  JSR  OLD1SHP                ;USE OLD SHIPS UNIT VECTORS
L6805:  LDX  #$0008                 ;CONVERT 8 BITS
L6808:  LDA  GM_WAV
L680B:  INCA                        ;VIEW WAVE STARTS AT 1
L680C:  JSR  BINBCD
L680F:  LDA  BCD+2
L6812:  STA  GM_DWAV                ;DECIMAL FOR VIEWING
L6815:  LDA  GM_WAV
L6818:  CMPA #$1F
L681A:  BLS  L681E                  ;IFHI
L681C:  LDA  #$1F                   ;LIMIT
L681E:  STA  SP_WAV                 ;LOCAL SPACE USE
L6821:  ADDA GM_DIF                 ;INCLUDE OVERALL DIFFICULTY
L6824:  CMPA #$0F
L6826:  BLS  L682A                  ;IFHI
L6828:  LDA  #$0F
L682A:  STA  WV_HRD                 ;CURRENT WAVES DIFFICULTY
L682D:  INC  PHASE

;------------------------------------------------------------------------------
; PHEBGN - BEGIN ACT  (comment at its table entry)
;------------------------------------------------------------------------------
PHEBGN:
L682F:  LDA  #PHS_SP1
L6831:  STA  PHASE
L6833:  LDA  #$00
L6835:  STA  WV_LVL
L6837:  RTS

;------------------------------------------------------------------------------
; PHISP1 - SPACE WAVES
;------------------------------------------------------------------------------
PHISP1:
L6838:  JSR  IPGEN                  ;JUST GENERAL PARMS, NOT PLAYER OR STARS
L683B:  JSR  IXPLD
L683E:  LDD  #$0000
L6841:  STD  PH_TIM
L6844:  STA  Q_RTHV                 ;DARTH IN VIEW, FIRST TIME -- SOUNDOFF
L6847:  LDA  #$09
L6849:  STA  Q_SHK                  ;# OF SHOTS BEFORE 'I CANT SHAKE HIM'
L684C:  LDA  SC_FWV
L684F:  BNE  L6857                  ;IFEQ  ?THE PLAYERS FIRST WAVE?
L6851:  LDD  #$0027                 ;THEN START A BIT AHEAD
L6854:  STD  PH_TIM
L6857:  INC  PHASE

;------------------------------------------------------------------------------
; PHESP1 - SPACE WAVE 1  (comment at its table entry)
;------------------------------------------------------------------------------
PHESP1:
L6859:  JSR  VIEW
L685C:  LDA  S_GAS
L685E:  LBMI PHIS0D                 ;B EXIT WHEN PLAYER DIES
L6862:  JSR  MVGUN                  ;MOVE GUN SHOTS
L6865:  JSR  DONGLW
L6868:  JSR  DOXPLD
L686B:  JSR  DO1GLW
L686E:  JSR  DO1GAS
L6871:  JSR  CPU                    ;COMPUTER DRONES
;TWIRL THE PLAYER
L6874:  JSR  VGTOSITE               ;PULL IN SITE COORDS FROM IRQ RHEOSTATS
L6877:  JSR  STWSP1                 ;TWIRL PLAYER
L687A:  LDA  #MS_S1BC               ;DOWNLOAD UNIT VECTORS TO MATH-BOX ( RESIDU )
L687C:  JSR  IS1UV
L687F:  JSR  SMVSP1                 ;MOVE PLAYER
L6882:  LDD  PH_TIM
L6885:  ADDD #$0001
L6888:  STD  PH_TIM
L688B:  CMPD #$0028
L688F:  BNE  L68A6                  ;IFEQ
L6891:  LDA  GM_WAV
L6894:  CMPA #$03
L6896:  BLT  L68A1                  ;IFGE  ?WAVE 4 OR HIGHER?
L6898:  ANDA #$01
L689A:  BEQ  L68A1                  ;IFNE  ?ANDIF EVEN (ODD-1) WAVE?
L689C:  JSR  PMDAR                  ;THEN DO DARTH THEME
L689F:  BRA  PHESP1_33
L68A1:  JSR  PMTH5                  ;THEME MUSIC

PHESP1_33:
L68A4:  BRA  L68C6                  ;ELSE
L68A6:  CMPD #$00C8                 ;SHORTLY AFTER THEME
L68AA:  BNE  L68B1                  ;IFEQ
L68AC:  JSR  PMTHB                  ;THEME B FOLLOWS MAIN THEME
L68AF:  BRA  L68C6                  ;ELSE
L68B1:  CMPD #$0190                 ;FOLLOWED BY DESCENT MUSIC
L68B5:  BNE  L68BC                  ;IFEQ
L68B7:  JSR  PMDES
L68BA:  BRA  L68C6                  ;ELSE
L68BC:  CMPD #$01A4                 ;RIGHT AFTER DESCENT MUSIC
L68C0:  BLO  L68C6                  ;IFHS
L68C2:  LDA  #PHS_SP2               ;GO AHEAD AND DESCEND
L68C4:  STA  PHASE
L68C6:  LDA  WV_LIV
L68C8:  CMPA #$03                   ;3 ALIENS ALIVE?
L68CA:  BHS  L68CF                  ;IFLO  NO, THEN THROW ANOTHER ONE AT THE PLAYER
L68CC:  JSR  ADASHP
L68CF:  RTS

;------------------------------------------------------------------------------
; PHISP2 - SPACE WAVE 2  (comment at its table entry)
;------------------------------------------------------------------------------
PHISP2:
L68D0:  INC  Q_RTHV                 ;NO MORE SOUNDOFF IF DARTH GETS VISIBLE
L68D3:  INC  PHASE

;------------------------------------------------------------------------------
; PHESP2 - SPACE WAVE 2  (comment at its table entry)
;------------------------------------------------------------------------------
PHESP2:
L68D5:  JSR  VIEW
L68D8:  LDA  S_GAS
L68DA:  LBMI PHIS0D                 ;B EXIT WHEN PLAYER DIES
L68DE:  JSR  MVGUN                  ;MOVE GUN SHOTS
L68E1:  JSR  DONGLW
L68E4:  JSR  DOXPLD
L68E7:  JSR  DO1GLW
L68EA:  JSR  DO1GAS
L68ED:  JSR  CPURET                 ;COMPUTER DRONES RUN AWAY
;TWIRL THE PLAYER
L68F0:  JSR  VGTOSITE               ;PULL IN SITE COORDS FROM IRQ RHEOSTATS
L68F3:  JSR  STWSP2                 ;TWIRL PLAYER
L68F6:  LDA  #MS_S1BC
L68F8:  JSR  IS1UV
L68FB:  JSR  SMVSP2                 ;MOVE PLAYER
L68FE:  LDX  #ALIEN
L6901:  LDA  AS_TYP,X
L6903:  BNE  PHESP2_40              ;STILL SOME RUNNING AWAY
L6905:  LEAX AS_IZE,X               ;TEST NEXT ALIEN
L6908:  CMPX #ALIENZ
L690B:  BLO  L6901                  ;HSEND
L690D:  LDA  #PHS_S0G               ;GOTO DETH STAR GROUND IF NONE LEFT
L690F:  STA  PHASE

PHESP2_40:
L6911:  RTS

;------------------------------------------------------------------------------
; PHIS0G - TRANSITION FROM SPACE TO GROUND
;------------------------------------------------------------------------------
PHIS0G:
L6912:  LDD  #VGSCAL+$500+$80
L6915:  STD  DT_SCL                 ;START WITH MATCHING SIZE DETH STARS
L6917:  LDD  #$0100
L691A:  STD  DT_STP                 ;STEP SIZE FOR SCALING THE DETH STAR
L691C:  LDA  SC_FWV
L691F:  BNE  L692A                  ;IFEQ  ?FIRST TIME THRU?
L6921:  LDA  SP_WAV
L6924:  CMPA #$04
L6926:  BNE  L692A                  ;IFEQ  ?AND SELECTED SPACE WAVE FIVE?
;THEN SPECIAL PROCESSING WITH PH$S1B
;/LOOK AT THE SIZE OF THAT THING/
L6928:  BRA  PHIS0G_25              ;SAY ONLY THE PREVIOUS
;ELSE
L692A:  JSR  SPKTHI                 ;THIS IS RED FIVE, I'M GOING IN
L692D:  JSR  AUDRY

PHIS0G_25:
L6930:  INC  PHASE
L6932:  RTS

;------------------------------------------------------------------------------
; PHES0G - SPACE TO GROUND TRANSITION  (comment at its table entry)
;------------------------------------------------------------------------------
PHES0G:
L6933:  JSR  VEWHPA
L6936:  JSR  DOXPLD
L6939:  JSR  DO1GLW
L693C:  JSR  DO1GAS
L693F:  JSR  S1TW                   ;TURN TOWARDS DETH STAR
L6942:  JSR  S1MVHP
L6945:  LDD  (MS_AX+M_S1)&$FFFF
L6948:  CMPD #$3F00
L694C:  BLT  PHES0G_40              ;IFGE  ?AIMING TOWARDS DETH STAR YET?
L694E:  LDA  #PHS_S1G               ;READY TO DO HYPER INTO DETH STAR
L6950:  STA  PHASE

PHES0G_40:
L6952:  RTS

;------------------------------------------------------------------------------
; PHIS1G - NEXT PART  (comment at its table entry)
;------------------------------------------------------------------------------
PHIS1G:
L6953:  LDA  SC_FWV
L6956:  BNE  L6962                  ;IFEQ  ?FIRST TIME THRU?
L6958:  LDA  SP_WAV
L695B:  CMPA #$04
L695D:  BNE  L6962                  ;IFEQ  ?AND SELECTED SPACE WAVE FIVE?
;THEN SPECIAL PROCESSING WITH PH$S1B
L695F:  JSR  SPKSIZ                 ;/LOOK AT THE SIZE OF THAT THING/
L6962:  JSR  AUDTH                  ;THRUST TOWARDS DETH STAR
L6965:  INC  PHASE                  ;GO AHEAD AND EXECUTE GROWING DETH STAR
L6967:  RTS

;------------------------------------------------------------------------------
; PHES1G - NEXT PART  (comment at its table entry)
;------------------------------------------------------------------------------
PHES1G:
L6968:  JSR  VEWHPB                 ;VIEW THE GROWING DETH STAR
L696B:  JSR  DONGLW
L696E:  JSR  DO1GLW
L6971:  JSR  DO1GAS
L6974:  JSR  S1TW
L6977:  JSR  S1MVHP
L697A:  LDB  DT_STP
L697C:  NEGB
L697D:  SEX
L697E:  ADDD DT_SCL
L6980:  ANDB #$7F
L6982:  STD  DT_SCL
L6984:  CMPD #VGSCAL+$100+$10
L6988:  BHI  L6997                  ;IFLS  ?OBJECT BIG ENOUGH?
L698A:  LDA  SP_WAV
L698D:  BNE  L6993                  ;IFEQ  ?FIRST SPACE WAVE?
L698F:  LDA  #PHS_S0B               ;THEN SKIP AHEAD TO TRENCH
L6991:  BRA  L6995                  ;ELSE  ELSE ALLOW GROUND
L6993:  LDA  #PHS_GD                ;DO GROUND FLYING
L6995:  STA  PHASE
L6997:  LDD  DT_STP                 ;CHANGE STEP SIZE
L6999:  ADDD #$0060
L699C:  STD  DT_STP
L699E:  LDA  ST_BRT                 ;DIM OUT THE STARS
L69A0:  SUBA #$02
L69A2:  BHI  L69A6                  ;IFLS
L69A4:  LDA  #$00
L69A6:  STA  ST_BRT
L69A8:  RTS

;------------------------------------------------------------------------------
; PHIGD - GROUND TERRAIN FOLLOWING
;------------------------------------------------------------------------------
PHIGD:
L69A9:  LDA  GM_WAV                 ;BUMP TO NEXT GROUND WAVE
L69AC:  DECA                        ;ALWAYS SKIPPED ON FIRST GAME WAVE
L69AD:  CMPA #$1F
L69AF:  BLO  L69B3                  ;IFHS
L69B1:  LDA  #$1F
L69B3:  STA  GD_WAV
L69B6:  ADDA GM_DIF
L69B9:  CMPA #$0F
L69BB:  BLS  L69BF                  ;IFHI
L69BD:  LDA  #$0F
L69BF:  STA  WV_HRD
L69C2:  JSR  IPARM                  ;INIT SHIP AND ALIEN PARMS
L69C5:  JSR  ISTARG
L69C8:  JSR  IGRND
L69CB:  JSR  IXPLD
L69CE:  LDD  #$0100                 ;INITIAL PLAYER SPEED
L69D1:  STD  (MS_VX+M_S1)&$FFFF
L69D4:  ASRA                        ;ASRD
L69D5:  RORB
L69D6:  STD  MS_TX+M_S1             ;OFFSET POSITION INTO MIDDLE FOR COLLISION DETECT
L69D9:  LDD  #$2000                 ;INITIAL HITE
L69DC:  STD  MS_TZ+M_S1
L69DF:  LDA  #$00
L69E1:  STA  GD_SEQ
L69E3:  STA  Q_ATP                  ;NOT YET CLEARED ALL TOWER TOPS
L69E6:  STA  Q_KTW                  ;NO KILL TOWERS
L69E9:  LDA  #$00
L69EB:  STA  PH_TIM
L69EE:  JSR  PM4TH                  ;BATTLE MUSIC IN FOURTHS
L69F1:  INC  PHASE
L69F3:  RTS

;------------------------------------------------------------------------------
; PHEGD - DO GROUND FLYING
;------------------------------------------------------------------------------
PHEGD:
L69F4:  JSR  VEWGD
L69F7:  LDA  S_GAS
L69F9:  LBMI PHIG0D                 ;J EXIT WHEN DEAD
L69FD:  JSR  MVGUN
L6A00:  JSR  DO1GLW
L6A03:  JSR  DO1GAS
L6A06:  JSR  DOXPLD
;TWIRL THE SHIP THRU GROUND FLYING
L6A09:  JSR  VGTOSITE               ;PULL IN SITE COORDS FROM IRQ RHEOSTATS
L6A0C:  JSR  S1TWGD
L6A0F:  LDA  #MS_S1BC
L6A11:  JSR  IS1UV
L6A14:  JSR  S1MVGD
L6A17:  LDD  (MS_VX+M_S1)&$FFFF
L6A1A:  ADDD #$0001
L6A1D:  CMPD #$0400
L6A21:  BHI  L6A26                  ;IFLS
L6A23:  STD  (MS_VX+M_S1)&$FFFF
L6A26:  LDA  FRAME+1
L6A28:  ANDA #$0F
L6A2A:  BNE  L6A39                  ;IFEQ
L6A2C:  LDA  PH_TIM
L6A2F:  CMPA #$0E
L6A31:  BNE  L6A36                  ;IFEQ
L6A33:  JSR  PMREB                  ;FINISH GROUND WITH REBEL
L6A36:  INC  PH_TIM                 ;ONE MORE PSUEDO-SECOND
L6A39:  LDA  GD_SEQ
L6A3B:  CMPA #$05                   ;ONLY GO SO FAR INTO GROUND SEQUENCES
L6A3D:  BLO  L6A4F                  ;IFHS
L6A3F:  LDA  #$01                   ;CLEAR TOWERS FROM GROUND
L6A41:  STA  Q_KTW
L6A44:  LDA  MS_TX+M_S1
L6A47:  CMPA #$80                   ;SEQUENCE RUNS 80 TO 80
L6A49:  BHS  L6A4F                  ;IFLO  ?ONE FULL PASS INTO BLANKED SECTION 5?
L6A4B:  LDA  #PHS_G0B               ;BASE TRENCH FOLLOWS GROUND TOWERS
L6A4D:  STA  PHASE
L6A4F:  RTS

;------------------------------------------------------------------------------
; PHIS0B - BASE STAR TRENCH
;   SPACE TO BASE TRANSITION
;   (also: PHIG0B)
;------------------------------------------------------------------------------
PHIS0B:
PHIG0B:
L6A50:  LDA  #$00                   ;FIRST TIME THIS WAVE
L6A52:  STA  BS_RPT                 ;FIRST TIME THRU
L6A54:  STA  Q_FRC                  ;ALLOWED TO USE THE FORCE
L6A57:  LDA  GM_WAV
L6A5A:  CMPA #$1F
L6A5C:  BLS  L6A60                  ;IFHI
L6A5E:  LDA  #$1F
L6A60:  STA  BS_WAV
L6A63:  ADDA GM_DIF
L6A66:  CMPA #$0F
L6A68:  BLS  L6A6C                  ;IFHI
L6A6A:  LDA  #$0F
L6A6C:  STA  WV_HRD
L6A6F:  JSR  GNBASE                 ;GEN A NEW BASE TRENCH
L6A72:  JSR  SPKUSE                 ;USE THE FORCE LUKE
L6A75:  LDD  #$0000
L6A78:  STD  PH_TIM
L6A7B:  INC  PHASE
L6A7D:  RTS

;------------------------------------------------------------------------------
; PHES0B - SPACE TO BASE TRENCH TRANSITION  (comment at its table entry)
;------------------------------------------------------------------------------
PHES0B:
L6A7E:  JSR  IPARM
L6A81:  JSR  NWBASE
L6A84:  LDA  #PHS_BS
L6A86:  STA  PHASE
L6A88:  RTS

;------------------------------------------------------------------------------
; PHEG0B - GROUND TO BASE TRENCH TRANSITION  (comment at its table entry)
;------------------------------------------------------------------------------
PHEG0B:
L6A89:  JSR  VEWG0B
L6A8C:  JSR  DO1GLW
L6A8F:  JSR  DO1GAS
L6A92:  JSR  DOXPLD
L6A95:  JSR  SMVG0B
L6A98:  LDD  PH_TIM
L6A9B:  ADDD #$0001
L6A9E:  STD  PH_TIM
L6AA1:  SUBD #$0011                 ;34. COUNTS FOR 360 TURNOVER, DO HALF HERE
L6AA4:  BLO  L6AAA                  ;IFHS
L6AA6:  LDA  #PHS_G1B
L6AA8:  STA  PHASE
L6AAA:  RTS

;------------------------------------------------------------------------------
; PHIG1B - NEXT PART  (comment at its table entry)
;------------------------------------------------------------------------------
PHIG1B:
L6AAB:  LDD  #$0000
L6AAE:  STD  MS_TX+M_S1
L6AB1:  STD  MS_TY+M_S1             ;GET US AT START OF TRENCH
L6AB4:  STD  PH_TIM                 ;TIMER
L6AB7:  JSR  SMVG1B                 ;ROLL AGAIN TO SKIP JERK
L6ABA:  JSR  NWBASE
L6ABD:  INC  PHASE

;------------------------------------------------------------------------------
; PHEG1B - NEXT PART  (comment at its table entry)
;------------------------------------------------------------------------------
PHEG1B:
L6ABF:  JSR  VEWG1B
L6AC2:  JSR  DO1GLW
L6AC5:  JSR  DO1GAS
L6AC8:  JSR  DOXPLD
L6ACB:  JSR  SMVG1B
L6ACE:  LDD  PH_TIM
L6AD1:  ADDD #$0001
L6AD4:  STD  PH_TIM
L6AD7:  SUBD #$0011                 ;34. COUNTS FOR 360 TURNOVER, DO HALF HERE
L6ADA:  BLO  L6AFE                  ;IFHS  ?TIME TO GOTO BASE?
L6ADC:  LDX  MS_TX+M_S1             ;SAVE OUR LOCATION
L6ADF:  LDU  MS_TY+M_S1
L6AE2:  LDD  MS_TZ+M_S1
L6AE5:  PSHS A,B,X,U
L6AE7:  JSR  IPARM                  ;INIT ALL PARMS
L6AEA:  PULS A,B,X,U                ;RESTORE OUR LOCATION
L6AEC:  STX  MS_TX+M_S1
L6AEF:  STU  MS_TY+M_S1
L6AF2:  STD  MS_TZ+M_S1
L6AF5:  LDA  #$00
L6AF7:  STA  Q_FRC                  ;ALLOWED TO USE THE FORCE (MAKING SURE)
L6AFA:  LDA  #PHS_BS
L6AFC:  STA  PHASE
L6AFE:  RTS

;------------------------------------------------------------------------------
; PHIB0B - BASE TO BASE TRANSITION
;------------------------------------------------------------------------------
PHIB0B:
L6AFF:  LDA  #$01                   ;REPEATING THIS WAVE
L6B01:  STA  BS_RPT
L6B03:  JSR  IPARM
;DO NOT GENERATE A NEW BASE
L6B06:  JSR  NWBASE                 ;JUST INIT THE CURRENT SELECTION
L6B09:  LDA  #$FF
L6B0B:  STA  Q_FRC                  ;NO FORCE ALLOWED ON RERUNS
L6B0E:  LDA  WV_HRD                 ;MAKE TRENCH HARDER ON REPEAT PASSES
L6B11:  ADDA GM_BMP                 ;BUMP UP THE DIFFICULTY
L6B14:  CMPA #$0F
L6B16:  BLS  L6B1A                  ;IFHI
L6B18:  LDA  #$0F
L6B1A:  STA  WV_HRD

;------------------------------------------------------------------------------
; PHEB0B - BASE TRENCH REPEAT TRANSITION  (comment at its table entry)
;------------------------------------------------------------------------------
PHEB0B:
L6B1D:  LDA  #PHS_BS
L6B1F:  STA  PHASE
L6B21:  RTS

;------------------------------------------------------------------------------
; PHIBS - BASE STAR  (comment at its table entry)
;------------------------------------------------------------------------------
PHIBS:
L6B22:  LDA  #$00                   ;TIMER FOR BASE STAR A
L6B24:  STA  Q_BSH                  ;NOT YET BASHED OUR NOSES
L6B27:  STA  PH_TIM
L6B2A:  LDD  #$0300                 ;INITIAL PLAYER SPEED
L6B2D:  STD  (MS_VX+M_S1)&$FFFF
L6B30:  INC  PHASE

;------------------------------------------------------------------------------
; PHEBS - ---DROP THRU -- DECREASE SCREEN FREEZE
;------------------------------------------------------------------------------
PHEBS:
L6B32:  JSR  VEWBS                  ;VIEW BASE TRENCH
L6B35:  LDA  S_GAS
L6B37:  LBMI PHIB0D                 ;J EXIT WHEN PLAYER DIES
L6B3B:  JSR  MVGUN
L6B3E:  JSR  MVPTGN                 ;PLAYERS PROTON TORP GUN
L6B41:  JSR  DOBASE                 ;FIRES BASES SHOTS
L6B44:  JSR  DO1QGLW                ;QUICKER GLOW IN TRENCH SEQUENCES
L6B47:  JSR  DO1GAS
;TWIRL THE SHIP THRU THE WORMHOLE
L6B4A:  JSR  VGTOSITE               ;PULL IN SITE COORDS FROM IRQ RHEOSTATS
L6B4D:  JSR  S1TWBS
L6B50:  LDA  #MS_S1BC
L6B52:  JSR  IS1UV
L6B55:  JSR  S1MVBS                 ;BASE TRENCH CONTROLS MOTION
L6B58:  LDA  FRAME+1
L6B5A:  ANDA #$0F
L6B5C:  BNE  L6B99                  ;IFEQ  ?PSUEDO SECOND PASSED?
L6B5E:  LDA  PH_TIM
L6B61:  CMPA #$02
L6B63:  BNE  L6B68                  ;IFEQ  ?FINISHED WITH VOICE OR CURSING R2?
L6B65:  JSR  PMRRP                  ;THEN DO REBEL REPEAT THEME
L6B68:  LDA  BS_WAV
L6B6B:  LSRA
L6B6C:  BCS  L6B83                  ;IFCC  BEGIN WITH WAVE 0 SAYING . . .
L6B6E:  LDA  PH_TIM
L6B71:  CMPA #$10
L6B73:  BNE  L6B7A                  ;IFEQ
L6B75:  JSR  SPKTRU                 ;LUKE, TRUST ME
L6B78:  BRA  L6B81                  ;ELSE
L6B7A:  CMPA #$18
L6B7C:  BNE  L6B81                  ;IFEQ
L6B7E:  JSR  SPKYAU                 ;YAHOO, YOURE ALL CLEAR KID
L6B81:  BRA  L6B96                  ;ELSE  ELSE ALTERNATE WAVE
L6B83:  LDA  PH_TIM                 ;OCCURS A BIT SOONER
L6B86:  CMPA #$10
L6B88:  BNE  L6B8F                  ;IFEQ
L6B8A:  JSR  SPKLET                 ;LET GO LUKE
L6B8D:  BRA  L6B96                  ;ELSE
L6B8F:  CMPA #$16
L6B91:  BNE  L6B96                  ;IFEQ
L6B93:  JSR  SPKSTR                 ;THE FORCE IS STRONG WITH THIS ONE
L6B96:  INC  PH_TIM
L6B99:  LDA  BS_EFL
L6B9B:  BEQ  PHEBS_80               ;IFNE  ?STARTING TO VIEW END OF TRENCH?
L6B9D:  LDD  BS_ELC
L6B9F:  SUBD MS_TX+M_S1
L6BA2:  SUBD #$0800
L6BA5:  BHI  PHEBS_80               ;IFLS  ?ABOUT TO BASH OUR NOSE IN THE END WALL?
L6BA7:  LDA  >PT_LIV                ;DID WE KILL IT??
L6BAA:  BNE  L6BC6                  ;IFEQ  NO, TOO BAD--NO EXPLOSION
L6BAC:  LDA  #$01
L6BAE:  STA  Q_BSH                  ;FLAG FOR BASHED OUR NOSE
L6BB1:  JSR  AUDCR                  ;CRASHED
L6BB4:  JSR  BG1GLW                 ;BASHED OUR NOSE -- LIMITS REPEATS
L6BB7:  LDA  S_GAS                  ;?WILL THIS KILL PLAYER?
L6BB9:  LBLE PHIB0D                 ;THEN EXIT
;ELSE
L6BBD:  LDA  #PHS_B0B               ;TRY TRENCH AGAIN UNTIL SUCCESSFUL
L6BBF:  STA  PHASE
L6BC1:  JSR  SPKR2N                 ;R2 SWEARS AT PLAYER FOR MISSING EXHAUST PORT
L6BC4:  BRA  PHEBS_80               ;ELSE  YES, LET'S WATCH IT EXPLODE!
L6BC6:  LDA  #PHS_DX1
L6BC8:  STA  PHASE
L6BCA:  LDA  GM_WAV
L6BCD:  CMPA #$03
L6BCF:  BLT  PHEBS_80               ;IFGE  ?WAVE 4 OR HIGHER?
L6BD1:  ANDA #$01
L6BD3:  BEQ  PHEBS_80               ;IFNE  ?ANDIF AN EVEN(ODD-1) WAVE?
L6BD5:  JSR  SPKGRE                 ;GREAT SHOT KID, THAT WAS 1 IN A MILLION
L6BD8:  BRA  PHEBS_80

PHEBS_80:
L6BDA:  RTS

;------------------------------------------------------------------------------
; PHINXT - GO TO NEXT SET OF WAVES
;------------------------------------------------------------------------------
PHINXT:
L6BDB:  JSR  IMATH
L6BDE:  JSR  IPARM
L6BE1:  LDA  #$C0                   ;TURN PLAYER AWAY FROM NEW DETH STAR
L6BE3:  STA  (MS_AX+M_S1)&$FFFF
L6BE6:  STA  (MS_BY+M_S1)&$FFFF
L6BE9:  LDA  #$04
L6BEB:  STA  PH_TIM
L6BEE:  INC  PHASE
L6BF0:  RTS

;------------------------------------------------------------------------------
; PHENXT - NEXT ACT  (comment at its table entry)
;------------------------------------------------------------------------------
PHENXT:
L6BF1:  LDA  FRAMEL
L6BF3:  ANDA #$0F
L6BF5:  BNE  L6C2C                  ;IFEQ  ABOUT A SECOND
L6BF7:  DEC  PH_TIM
L6BFA:  LDA  PH_TIM
L6BFD:  CMPA #$03
L6BFF:  BNE  L6C09                  ;IFEQ
L6C01:  LDA  >PT_LIV
L6C04:  BEQ  L6C09                  ;IFNE  ?FIRED AT THE EXHAUST PORT?
L6C06:  JSR  SCRPORT                ;SCORE THE EXHAUST PORT
L6C09:  LDA  PH_TIM
L6C0C:  CMPA #$02
L6C0E:  BNE  L6C13                  ;IFEQ
L6C10:  JSR  SCRSHLD                ;ADD SHIELD ENERGY BONUS
L6C13:  LDA  PH_TIM
L6C16:  CMPA #$01
L6C18:  BNE  L6C22                  ;IFEQ  ADD BONUS ENERGY TO SHIELDS IF DESERVED
L6C1A:  LDA  >PT_LIV                ;DID PLAYER KILL DETH STAR?
L6C1D:  BEQ  L6C22                  ;IFNE  YES, SO ADD BONUS ENERGY
L6C1F:  JSR  ADCGAS                 ;ADD CANNED GAS
L6C22:  LDA  PH_TIM
L6C25:  CMPA #$00
L6C27:  BNE  L6C2C                  ;IFEQ  ?ALMOST AT END OF NEXT PHASE?
L6C29:  JSR  SCRWAV                 ;AND ALSO ADD WAV BONUS
L6C2C:  JSR  VEWNXT                 ;VIEW NXT PHASE STUFF
L6C2F:  JSR  DO1GAS                 ;WE MIGHT INC GAS
L6C32:  JSR  SMVNXT                 ;MOVE PLAYER (STARS)
L6C35:  LDA  PH_TIM
L6C38:  CMPA #$FE
L6C3A:  BNE  L6C75                  ;IFEQ  WRAP TO NEXT DETH STAR
L6C3C:  LDA  GM_WAV
L6C3F:  INCA
L6C40:  CMPA #$62                   ;MAX OUT YET?
L6C42:  BLS  L6C46                  ;IFHI  YES, LIMIT IT
L6C44:  LDA  #$62
L6C46:  STA  GM_WAV
L6C49:  LDA  GM_WAV
L6C4C:  CMPA #$05                   ;IGNORE BUMP WHEN ABOVE SELECTALEVEL
L6C4E:  BHS  L6C5D                  ;IFLO  ?STARTING WAVE 0 TO 5?
L6C50:  LDA  GM_BMP                 ;USED TO KILL OFF RINGERS WHO START TO EASY
L6C53:  INCA
L6C54:  CMPA #$04
L6C56:  BLS  L6C5A                  ;IFHI
L6C58:  LDA  #$04                   ;MAX TO BUMP
L6C5A:  STA  GM_BMP
L6C5D:  LDA  GM_DIF
L6C60:  ADDA GM_BMP                 ;GAME DEFAULT DIFFICULTY GOES UP EACH WAVE
L6C63:  CMPA #$0F
L6C65:  BLS  L6C69                  ;IFHI
L6C67:  LDA  #$0F                   ;0F MAX DIFFICULTY LEVELS (WORKS TO WAVE 10.)
L6C69:  STA  GM_DIF
L6C6C:  LDA  #$FF                   ;NO MORE FIRST WAVES
L6C6E:  STA  SC_FWV
L6C71:  LDA  #PHS_BGN               ;GO TO BEGINNING OF NEW WAVE
L6C73:  STA  PHASE
L6C75:  RTS

;------------------------------------------------------------------------------
; PHIS0D - SPACE TO ENDGAME TRANSITION
;------------------------------------------------------------------------------
PHIS0D:
L6C76:  JSR  SPKSKP                 ;SKIP ANY OTHER VOICES
L6C79:  LDA  #PHS_S0D+1
L6C7B:  STA  PHASE                  ;EXECUTE THIS PHASE
L6C7D:  LDD  #$0000
L6C80:  STD  PH_TIM                 ;NEW PHASE TIMER JUST STARTED
L6C83:  RTS

;------------------------------------------------------------------------------
; PHES0D - SPACE TO DIE, TRANSITION  (comment at its table entry)
;------------------------------------------------------------------------------
PHES0D:
L6C84:  JSR  VEWS0D
L6C87:  JSR  MVGUN
L6C8A:  JSR  KPGLOW
L6C8D:  JSR  DONGLW
L6C90:  JSR  DOXPLD
L6C93:  LDD  #$FB01                 ;FLIP DIRECTION OF ROLL CUZ WE ARE DIEING
L6C96:  STD  M_SIN
L6C99:  LDD  #$3FCE
L6C9C:  STD  M_COS
L6C9F:  JSR  S1RL
L6CA2:  LDD  PH_TIM
L6CA5:  ADDD #$0001
L6CA8:  STD  PH_TIM
L6CAB:  CMPD #$0028                 ;2 SECONDS
L6CAF:  BLO  L6CB5                  ;IFHS
L6CB1:  LDA  #PHS_EGM
L6CB3:  STA  PHASE
L6CB5:  RTS

;------------------------------------------------------------------------------
; PHIG0D - GROUND TO ENDGAME TRANSITION
;------------------------------------------------------------------------------
PHIG0D:
L6CB6:  JSR  SPKSKP                 ;SKIP ANY WAITING VOICES
L6CB9:  LDA  #PHS_G0D+1
L6CBB:  STA  PHASE                  ;EXECUTE THIS PHASE
L6CBD:  LDD  #$0000
L6CC0:  STD  PH_TIM                 ;NEW PHASE TIMER JUST STARTED
L6CC3:  RTS

;------------------------------------------------------------------------------
; PHEG0D - GROUND TO DIE, TRANSITION  (comment at its table entry)
;------------------------------------------------------------------------------
PHEG0D:
L6CC4:  JSR  VEWG0D
L6CC7:  JSR  MVGUN
L6CCA:  JSR  KPGLOW
L6CCD:  LDD  PH_TIM
L6CD0:  ADDD #$0001
L6CD3:  STD  PH_TIM
L6CD6:  CMPD #$0028                 ;2 SECONDS
L6CDA:  BLO  L6CE0                  ;IFHS
L6CDC:  LDA  #PHS_EGM
L6CDE:  STA  PHASE
L6CE0:  RTS

;------------------------------------------------------------------------------
; PHIB0D - BASE TRENCH TO ENDGAME TRANSITION
;------------------------------------------------------------------------------
PHIB0D:
L6CE1:  JSR  SPKSKP                 ;SKIP ANY WAITING VOICES
L6CE4:  LDA  #PHS_B0D+1
L6CE6:  STA  PHASE                  ;EXECUTE THIS PHASE
L6CE8:  LDD  #$0000
L6CEB:  STD  PH_TIM                 ;NEW PHASE TIMER JUST STARTED
L6CEE:  RTS

;------------------------------------------------------------------------------
; PHEB0D - BASE TRENCH TO DIE, TRANSITION  (comment at its table entry)
;------------------------------------------------------------------------------
PHEB0D:
L6CEF:  JSR  VEWB0D
L6CF2:  JSR  MVGUN
L6CF5:  JSR  KPGLOW
L6CF8:  LDD  PH_TIM
L6CFB:  ADDD #$0001
L6CFE:  STD  PH_TIM
L6D01:  CMPD #$0028                 ;2 SECONDS
L6D05:  BLO  L6D0B                  ;IFHS
L6D07:  LDA  #PHS_EGM
L6D09:  STA  PHASE
L6D0B:  RTS

;------------------------------------------------------------------------------
; PHIEGM - END OF GAME
;   INIT END OF GAME
;   PREVIOUS PHASE HAS ALREADY SKIPPED OLD SPEECH
;------------------------------------------------------------------------------
PHIEGM:
L6D0C:  JSR  SPKREM                 ;SAY "REMEMBER..."
L6D0F:  JSR  SPKFOA                 ;SAY FORCE WILL BE WITH YOU ALWAYS
L6D12:  INC  PHASE                  ;TRANSFER TO END OF GAME
L6D14:  RTS

;------------------------------------------------------------------------------
; PHEEGM - END OF GAME
;------------------------------------------------------------------------------
PHEEGM:
L6D15:  JSR  IMATH
L6D18:  JSR  IPARM
L6D1B:  JSR  ISTAR
L6D1E:  LDU  #M_U1
L6D21:  JSR  UNITV
L6D24:  JSR  EEACCT                 ;UPDATE GAME TIME, GAMES PLAYED AND HISTORY
L6D27:  JSR  UPDATE                 ;CHECK FOR NEW HI SCORE
L6D2A:  LDA  UPDFLG
L6D2D:  BMI  L6D33                  ;IFPL  ?NEW HI SCORE?
L6D2F:  LDA  #PHS_ENT               ;THEN ENTER INITIALS
L6D31:  BRA  L6D38                  ;ELSE  ELSE NO LUCK
L6D33:  JSR  PMBEN                  ;BEN'S THEME WHEN LOSE GAME WITH NO HIGH SCORE
L6D36:  LDA  #PHS_BNR
L6D38:  STA  PHASE

PHEEGM_90:
L6D3A:  RTS

;------------------------------------------------------------------------------
; PHIDX1 - DEATH STAR EXPLOSION
;------------------------------------------------------------------------------
PHIDX1:
L6D3B:  LDD  #VGSCAL+$100+4         ;START DEATH STAR AT VERY LARGE
L6D3E:  STD  DT_SCL
L6D40:  LDD  #$0AFF                 ;STEP SIZE
L6D43:  STD  DT_STP
L6D45:  JSR  ISTAR                  ;SETUP STARS
L6D48:  LDU  #M_U1
L6D4B:  JSR  UNITV
L6D4E:  INC  PHASE
L6D50:  JSR  PMEND                  ;START END OF DETH STAR MUSIC
L6D53:  RTS

;------------------------------------------------------------------------------
; PHEDX1 - DEATH STAR EXPLOSION, FIRST PHASE  (comment at its table entry)
;------------------------------------------------------------------------------
PHEDX1:
L6D54:  JSR  VEWDX1
L6D57:  JSR  DO1GAS
L6D5A:  JSR  DO1GLW
;JSR SMVDX1 ;MOVE BACKWARDS
L6D5D:  LDB  DT_STP
L6D5F:  SEX
L6D60:  ADDD DT_SCL
L6D62:  ADDD #$0080                 ;D7 IS WRAP
L6D65:  ANDB #$7F
L6D67:  STD  DT_SCL
L6D69:  CMPD #VGSCAL+$400+$80
L6D6D:  BLO  L6D73                  ;IFHS
L6D6F:  LDA  #PHS_DX2
L6D71:  STA  PHASE
L6D73:  LDD  DT_STP                 ;CHANGE STEP SIZE
L6D75:  SUBD #$0010
L6D78:  BPL  L6D7D                  ;IFMI
L6D7A:  LDD  #$0000
L6D7D:  STD  DT_STP
L6D7F:  RTS

;------------------------------------------------------------------------------
; PHIDX2 - DEATH STAR EXPLOSION, SECOND PHASE  (comment at its table entry)
;------------------------------------------------------------------------------
PHIDX2:
L6D80:  JSR  BGXPLN                 ;START EXPLOSION
L6D83:  INC  PHASE
L6D85:  RTS

;------------------------------------------------------------------------------
; PHEDX2 - DEATH STAR EXPLOSION, SECOND PHASE  (comment at its table entry)
;------------------------------------------------------------------------------
PHEDX2:
L6D86:  JSR  VEWDX2
;JSR SMVDX2
L6D89:  LDA  >XP_PHS
L6D8C:  CMPA #$01
L6D8E:  BLO  L6D94                  ;IFHS  GOTO NEXT PHASE
L6D90:  LDA  #PHS_DX3
L6D92:  STA  PHASE
L6D94:  RTS

;------------------------------------------------------------------------------
; PHIDX3 - DEATH STAR EXPLOSION, THIRD PHASE  (comment at its table entry)
;------------------------------------------------------------------------------
PHIDX3:
L6D95:  INC  PHASE
L6D97:  RTS

;------------------------------------------------------------------------------
; PHEDX3 - DEATH STAR EXPLOSION, THIRD PHASE  (comment at its table entry)
;------------------------------------------------------------------------------
PHEDX3:
L6D98:  JSR  VEWDX3
;JSR SMVDX3
L6D9B:  LDA  >XP_PHS
L6D9E:  BNE  L6DA4                  ;IFEQ  DEATH STAR FINISHED EXPLODING
L6DA0:  LDA  #PHS_NXT
L6DA2:  STA  PHASE
L6DA4:  RTS

;------------------------------------------------------------------------------
; SMVBNR - MOVE STARS IN SOME DIRECTION
;   PLAYER 1 MOVE DURING BANNER
;------------------------------------------------------------------------------
SMVBNR:
L6DA5:  LDD  ST_UX                  ;RELATIVE MOVEMENT FOR STARS
L6DA7:  ADDD #$0080                 ;45 DEGREES UP X
L6DAA:  STD  ST_UX
L6DAC:  LDD  ST_UZ
L6DAF:  ADDD #$0080                 ;45 DEGREES UP Z
L6DB2:  STD  ST_UZ
L6DB5:  RTS

;------------------------------------------------------------------------------
; SMVINS - STAR MOVEMENT DURING FLIGHT INSTRUCTION PHASE
;------------------------------------------------------------------------------
SMVINS:
L6DB6:  LDD  ST_UY
L6DB9:  ADDD #$FF80                 ;SIDEWAYS
L6DBC:  STD  ST_UY
L6DBF:  RTS

;------------------------------------------------------------------------------
; SMVSCR - STAR MOVEMENT DURING SCORING SCREEN PHASE
;------------------------------------------------------------------------------
SMVSCR:
L6DC0:  LDD  ST_UZ
L6DC3:  ADDD #$0080                 ;UP
L6DC6:  STD  ST_UZ
L6DC9:  RTS

;------------------------------------------------------------------------------
; SMVHIS - STAR MOVEMENT DURING HIGH SCORE DISPLAY
;------------------------------------------------------------------------------
SMVHIS:
L6DCA:  LDD  ST_UX
L6DCC:  ADDD #$0080                 ;FORWARD
L6DCF:  STD  ST_UX
L6DD1:  RTS

;------------------------------------------------------------------------------
; STWSP1 - MOVE THE PLAYER
;   ROLL IF HIT
;   (also: S1TW)
;------------------------------------------------------------------------------
STWSP1:
S1TW:
L6DD2:  LDA  S_ROL
L6DD4:  BEQ  L6DF0                  ;IFNE  ?ANY ROLLING TO DO?
L6DD6:  BLE  L6DDF                  ;IFGT  ?POSITIVE?
L6DD8:  DEC  S_ROL
L6DDA:  LDD  #$04FF
L6DDD:  BRA  L6DE4                  ;ELSE  ELSE NEGATIVE
L6DDF:  INC  S_ROL
L6DE1:  LDD  #$FB01
L6DE4:  STD  M_SIN
L6DE7:  LDD  #$3FCE                 ;4.48 DEGREES
L6DEA:  STD  M_COS
L6DED:  JSR  S1RL
L6DF0:  JSR  AIM                    ;AIM AT ALIEN OR DETH STAR
L6DF3:  JSR  S1RHPT
L6DF6:  JSR  S1RHYW
L6DF9:  RTS

;------------------------------------------------------------------------------
; STWSP2 - FOR THE LAST OF A GROUP OF THREE ALIENS
;   ROLL IF HIT
;------------------------------------------------------------------------------
STWSP2:
L6DFA:  LDA  S_ROL
L6DFC:  BEQ  L6E18                  ;IFNE  ?ANY ROLLING TO DO?
L6DFE:  BLE  L6E07                  ;IFGT  ?POSITIVE?
L6E00:  DEC  S_ROL
L6E02:  LDD  #$04FF
L6E05:  BRA  L6E0C                  ;ELSE  ELSE NEGATIVE
L6E07:  INC  S_ROL
L6E09:  LDD  #$FB01
L6E0C:  STD  M_SIN
L6E0F:  LDD  #$3FCE                 ;4.48 DEGREES
L6E12:  STD  M_COS
L6E15:  JSR  S1RL
L6E18:  JSR  AIMDTH
L6E1B:  JSR  S1RHPT
L6E1E:  JSR  S1RHYW
L6E21:  RTS

;------------------------------------------------------------------------------
; S1TWGD - TWIRL THE GROUND FLYER
;------------------------------------------------------------------------------
S1TWGD:
L6E22:  LDA  S_ROL
L6E24:  BEQ  L6E2E                  ;IFNE  ?TIME TO ROLL PLAYER?
L6E26:  BLE  L6E2B                  ;IFGT
L6E28:  DECA                        ;GO TOWARDS ZERO
L6E29:  BRA  L6E2C                  ;ELSE
L6E2B:  INCA                        ;GO TOWARDS ZERO
L6E2C:  STA  S_ROL
L6E2E:  LDA  S_ROL
L6E30:  BPL  L6E33                  ;IFMI
L6E32:  NEGA                        ;ABS FOR MULTIPLIER
L6E33:  LDB  #$20                   ;15 PER DEGREE PER COUNT
L6E35:  MUL
L6E36:  TST  S_ROL
L6E38:  BPL  L6E3E                  ;IFMI
L6E3A:  COMA                        ;NEGD  RESTORE SIGN
L6E3B:  NEGB
L6E3C:  SBCA #$FF
L6E3E:  STD  GD_ROL                 ;AMOUNT OF OFFSET TO ROLL
L6E40:  LDA  SI_RSX                 ;NOW ROLL CUZ OF PLAYER AIM
L6E42:  BPL  L6E45                  ;IFMI
L6E44:  COMA
L6E45:  LDB  #$02                   ;MAX COUNT OF 5*128=45 DEGREES(78 PER 5 DEGREES)
;USE 4 MAX SO DOUBLE SHIFT GET 8 BITS
L6E47:  MUL
L6E48:  TST  SI_RSX
L6E4A:  BPL  L6E50                  ;IFMI
L6E4C:  COMA                        ;NEGD  RESTORE SIGN
L6E4D:  NEGB
L6E4E:  SBCA #$FF
L6E50:  ADDD GD_ROL
L6E52:  TST  S_ROL
L6E54:  BNE  UNTWGD                 ;IFEQ  ?NO FANCY COLLISION ROLL?THEN GO SLOW
L6E56:  SUBD GD_ACT                 ;COMPARE WITH ACTUAL ROLL AMOUNT
L6E58:  BLE  L6E65                  ;IFGT  ?ROLL PLUS?
L6E5A:  CMPD #$0010                 ;LIMIT PLUS ROLL
L6E5E:  BLE  L6E63                  ;IFGT
L6E60:  LDD  #$0010                 ;127.(BYTE MAX)-77.(RESIDU MOST)=50.(MAX INCREASE ALLOWED)
L6E63:  BRA  L6E6E                  ;ELSE
L6E65:  CMPD #$FFF0                 ;LIMIT MINUS ROLL
L6E69:  BGE  L6E6E                  ;IFLT
L6E6B:  LDD  #$FFF0
L6E6E:  BRA  L6E88                  ;ELSE  ELSE IS FANCY ROLL

;------------------------------------------------------------------------------
; UNTWGD - D;= NEG(GD.ACT) FOR FAST UNROLL
;------------------------------------------------------------------------------
UNTWGD:
L6E70:  SUBD GD_ACT                 ;COMPARE WITH ACTUAL ROLL AMOUNT
L6E72:  BLE  L6E7F                  ;IFGT  ?ROLL PLUS?
L6E74:  CMPD #$0032                 ;LIMIT PLUS ROLL
L6E78:  BLE  L6E7D                  ;IFGT
L6E7A:  LDD  #$0032                 ;127.(BYTE MAX)-77.(RESIDU MOST)=50.(MAX INCREASE ALLOWED)
L6E7D:  BRA  L6E88                  ;ELSE
L6E7F:  CMPD #$FFCE                 ;LIMIT MINUS ROLL
L6E83:  BGE  L6E88                  ;IFLT
L6E85:  LDD  #$FFCE
L6E88:  TFR  B,A                    ;SAVE A COPY
L6E8A:  ADDA >RHS_RSD+RHEOR         ;TICS TO ROLL
L6E8D:  STA  >RHS_RSD+RHEOR
L6E90:  SEX                         ;GET BACK TO 16 BITS
L6E91:  ADDD GD_ACT                 ;AND KEEP TRACK OF ACTUAL ROLL
L6E93:  STD  GD_ACT
L6E95:  LDX  #RHEOR
L6E98:  JSR  RHRSDU
L6E9B:  BEQ  L6EA0                  ;IFNE  ?HAVE SOME ROLLING TO DO?
L6E9D:  JSR  S1RL
L6EA0:  RTS

;------------------------------------------------------------------------------
; S1TWBS - TWIRL IN BASE TRENCH
;------------------------------------------------------------------------------
S1TWBS:
L6EA1:  RTS

;------------------------------------------------------------------------------
; AIM - AIM AT ALIEN OR DEATH STAR
;------------------------------------------------------------------------------
AIM:
L6EA2:  LDX  AM_PTR
L6EA5:  BNE  L6EAA                  ;IFEQ  CYCLE THRU STARTING AT CURRENT POSITION
L6EA7:  LDX  #ALIEN
L6EAA:  LDA  AS_TYP,X
L6EAC:  CMPA #$01
L6EAE:  BNE  L6EB9                  ;IFEQ  ?FOUND OUR FIRST LIVE ALIEN?
L6EB0:  LDA  AS_GLW,X
L6EB2:  BNE  L6EB9                  ;IFEQ  ?AND NOT GLOWING FROM A HIT?
L6EB4:  STX  S2_PRM                 ;SAVE ALIEN POINTER
L6EB6:  JMP  AIMA
L6EB9:  LDA  Q_SHK
L6EBC:  BLE  L6EC3                  ;IFGT  ?STILL WAITING FOR GOOD OPPONENT?
L6EBE:  LDA  #$09
L6EC0:  STA  Q_SHK                  ;# OF SHOTS BEFORE 'I CANT SHAKE HIM'
L6EC3:  LEAX AS_IZE,X               ;GET NEW ALIEN TO AIM AT
L6EC6:  CMPX #ALIENZ
L6EC9:  BLO  L6EAA                  ;HSEND  LOOP TILL DONE

;------------------------------------------------------------------------------
; AIMDTH - ---WHEN NO ALIENS TO LOOK AT, USE DETH STAR
;------------------------------------------------------------------------------
AIMDTH:
L6ECB:  LDD  #$0000
L6ECE:  STD  AM_PTR                 ;NO CURRENT POINTER TO ALIEN BEING TRACKED
L6ED1:  LDA  (MS_AX+M_S1)&$FFFF
L6ED4:  BMI  L6EDB                  ;IFPL  ?DETH STAR IN FRONT?
L6ED6:  LDB  (MS_AZ+M_S1)&$FFFF     ;THEN SLEW NORMALLY(USE HITE OF DETHSTAR)
L6ED9:  BRA  L6EE0                  ;ELSE  ELSE DETH STAR IN BACK
L6EDB:  LDB  #$7F                   ;STRAIGHT IN BACK GIVES LARGE VALUE
L6EDD:  SUBB (MS_AZ+M_S1)&$FFFF
L6EE0:  STB  >RHS_RAT+RHEOP
L6EE3:  LDA  (MS_AX+M_S1)&$FFFF
L6EE6:  BMI  L6EED                  ;IFPL  ?DETH STAR IN FRONT?
L6EE8:  LDB  (MS_AY+M_S1)&$FFFF     ;THEN SLEW NORMALLY(USE WIDTH OF DETHSTAR)
L6EEB:  BRA  L6EF2                  ;ELSE  ELSE DETH STAR IN BACK
L6EED:  LDB  #$7F                   ;STRAIGHT IN BACK GIVES LARGE VALUE
L6EEF:  SUBB (MS_AY+M_S1)&$FFFF
L6EF2:  COMB
L6EF3:  STB  >RHS_RAT+RHEOY
L6EF6:  RTS

;------------------------------------------------------------------------------
; AIMA - AIM AT ALIEN
;------------------------------------------------------------------------------
AIMA:
L6EF7:  LDA  #MS_S1BC
L6EF9:  JSR  IS1UV                  ;DOWNLOAD LATEST UNIT VECTOR
L6EFC:  JSR  RESIDU                 ;AND HANDLE RESIDU
L6EFF:  LDX  S2_PRM                 ;GET THE ALIEN TO AIM AT
L6F01:  STX  AM_PTR                 ;SAVE OUR CURRENT ALIEN
L6F04:  CLRA
L6F05:  LDB  AS_BIC,X
L6F07:  ADDB #$03
L6F09:  STD  M_BIC
L6F0C:  LDA  #MS_PSB2
L6F0E:  JSR  MGOWT                  ;GET ALIENS LATEST LOC VIA PLAYER
L6F11:  LDA  M_XP
L6F14:  BLE  L6F39                  ;IFGT  ?ALIEN IN FRONT?
L6F16:  LDD  M_YP                   ;THEN SCALE USING X
L6F19:  LSL  M_XP+1
L6F1C:  ROL  M_XP
L6F1F:  BVS  AIMA_26                ;B WHEN X OVERFLOWS
L6F21:  LSLB                        ;LSLD  NOW DO Y
L6F22:  ROLA
L6F23:  BVC  L6F29                  ;IFVS  ?Y AT MAX SCALE?
L6F25:  RORA                        ;RORD  THEN RESTORE SIGN
L6F26:  RORB
L6F27:  BRA  AIMA_26                ;J AND SKIP OUT
L6F29:  LSL  M_ZP+1
L6F2C:  ROL  M_ZP
L6F2F:  BVC  L6F19                  ;VSEND
L6F31:  ROR  M_ZP                   ;RESTORE CORRECT SIGN
L6F34:  ROR  M_ZP+1
L6F37:  BRA  AIMA_26                ;ELSE  ELSE ALIEN IS BEHIND -- USE LARGEST SCALE
L6F39:  LDD  M_YP                   ;PREPARE DREG FOR SPEED
L6F3C:  ORB  #$01                   ;FORCE END TO LOOP
L6F3E:  LSLB                        ;LSLD  NOW DO Y
L6F3F:  ROLA
L6F40:  BVC  L6F46                  ;IFVS  ?Y AT MAX SCALE?
L6F42:  RORA                        ;RORD  THEN RESTORE SIGN
L6F43:  RORB
L6F44:  BRA  AIMA_26                ;J AND SKIP OUT
L6F46:  LSL  M_ZP+1
L6F49:  ROL  M_ZP
L6F4C:  BVC  L6F3E                  ;VSEND
L6F4E:  ROR  M_ZP                   ;RESTORE CORRECT SIGN
L6F51:  ROR  M_ZP+1

AIMA_26:
L6F54:  COMA                        ;DREG := SHIFTED Y
L6F55:  STA  >RHS_RAT+RHEOY         ;LEFT/RIGHT YAW
L6F58:  LDB  M_ZP
L6F5B:  STB  >RHS_RAT+RHEOP         ;UP/DOWN PITCH
L6F5E:  RTS

;------------------------------------------------------------------------------
; SMVSP1 - MOVE PLAYER AS PER SPACE WAVE TYPE 1
;   MOVE PLAYER AS PER SPACE WAVE TYPE 2
;   MOVE PALYER ( HYPER TO NEXT DETH STAR )
;   PLAYER 1 MOVE
;   (also: SMVSP2, SMVNXT, S1MV)
;------------------------------------------------------------------------------
SMVSP1:
SMVSP2:
SMVNXT:
S1MV:
L6F5F:  LDD  FRAME
L6F61:  JSR  LSLD7
L6F64:  STD  ST_UX                  ;STARS RELATIVE MOVEMENT
L6F66:  RTS

;------------------------------------------------------------------------------
; S1MVHP - MOVE DURING HYPER
;------------------------------------------------------------------------------
S1MVHP:
L6F67:  LDD  FRAME
L6F69:  JSR  LSLD8
L6F6C:  STD  ST_UX
L6F6E:  RTS

;------------------------------------------------------------------------------
; S1MVGD - GROUND FLYING PLAYER MOVEMENT
;------------------------------------------------------------------------------
S1MVGD:
L6F6F:  LDD  (MS_VX+M_S1)&$FFFF     ;PLAYERS FORWARD MOVEMENT
L6F72:  ADDD MS_TX+M_S1
L6F75:  BVC  L6F7D                  ;IFVS  ?WRAPPED AROUND?
L6F77:  INC  GD_SEQ                 ;THEN START UP NEXT SEQUENCE
L6F79:  BVC  L6F7D                  ;IFVS
L6F7B:  DEC  GD_SEQ                 ;PREVENT ITS OVERFLOW
L6F7D:  STD  MS_TX+M_S1
L6F80:  STD  MS_TX+M_U1
L6F83:  LDD  (MS_VX+M_S1)&$FFFF     ;FASTEST IS AT 45 DEGREES
L6F86:  JSR  LSLD4
L6F89:  LDB  SI_RSX                 ;RESPOND IMMEDIATELY TO CONTROL POSITION--SLALOM
L6F8B:  BPL  L6F8E                  ;IFMI
L6F8D:  COMB                        ;HANDLE 80 CORRECTLY,ABSB
L6F8E:  LSLB                        ;FULL SCALE VALUE
L6F8F:  MUL
L6F90:  TST  SI_RSX                 ;REMEMBER TO FLIP DIRECTIONS
L6F92:  BGE  L6F98                  ;IFLT
L6F94:  COMA                        ;NEGD
L6F95:  NEGB
L6F96:  SBCA #$FF
L6F98:  JSR  ASRD4
L6F9B:  STD  (MS_VY+M_S1)&$FFFF     ;ALLOW OTHERS TO KNOW OUR SPEED
L6F9E:  ADDD MS_TY+M_S1
L6FA1:  STD  MS_TY+M_S1
L6FA4:  STD  MS_TY+M_U1
L6FA7:  LDD  (MS_VX+M_S1)&$FFFF
L6FAA:  JSR  LSLD4
L6FAD:  LDB  SI_RSY
L6FAF:  BPL  L6FB2                  ;IFMI
L6FB1:  COMB                        ;HANDLE 80 CORRECTLY,ABSB
L6FB2:  NOP                         ;SLOWER RANGE
L6FB3:  MUL
L6FB4:  TST  SI_RSY                 ;REMEMBER TO FLIP DIRECTIONS
L6FB6:  BPL  L6FBC                  ;IFMI
L6FB8:  COMA                        ;NEGD
L6FB9:  NEGB
L6FBA:  SBCA #$FF
L6FBC:  JSR  ASRD4
L6FBF:  STD  MS_VZ+M_S1
L6FC2:  ADDD MS_TZ+M_S1
L6FC5:  CMPD #$1C00                 ;USE BELOW IN GD$MDT
L6FC9:  BLE  L6FD0                  ;IFGT
L6FCB:  LDD  #$1C00
L6FCE:  BRA  L6FD9                  ;ELSE
L6FD0:  CMPD #$0200                 ;USE BELOW IN GD$MDT
L6FD4:  BGE  L6FD9                  ;IFLT
L6FD6:  LDD  #$0200
L6FD9:  STD  MS_TZ+M_S1
L6FDC:  STD  MS_TZ+M_U1
L6FDF:  RTS

;------------------------------------------------------------------------------
; SMVG0B - GROUND TO BASE TRENCH TRANSITION
;------------------------------------------------------------------------------
SMVG0B:
L6FE0:  LDD  MS_TZ+M_S1
L6FE3:  CMPD #$0380
L6FE7:  BLE  L6FEF                  ;IFGT  ?PLAYER TOO HI?
L6FE9:  SUBD #$0180
L6FEC:  STD  MS_TZ+M_S1             ;DROP HIM DOWN
L6FEF:  BRA  SMVG9B                 ;REST OF G*B TRANSITION

;------------------------------------------------------------------------------
; SMVG1B - ROLL AGAIN TO SKIP JERK  (comment at the call)
;------------------------------------------------------------------------------
SMVG1B:
L6FF1:  LDD  MS_TZ+M_S1
L6FF4:  CMPD #$F300                 ;JUST ABOVE BOTTOM OF TRENCH
L6FF8:  BLE  SMVG9B                 ;IFGT
L6FFA:  SUBD #$0100
L6FFD:  STD  MS_TZ+M_S1             ;DROP PLAYER INTO TRENCH

;------------------------------------------------------------------------------
; SMVG9B - REST OF G*B TRANSITION
;------------------------------------------------------------------------------
SMVG9B:
L7000:  LDD  (MS_VX+M_S1)&$FFFF
L7003:  ADDD MS_TX+M_S1             ;MOVE PLAYER FORWARD
L7006:  STD  MS_TX+M_S1
L7009:  LDD  #$0300
L700C:  SUBD (MS_VX+M_S1)&$FFFF
L700F:  JSR  ASRD3
L7012:  ADDD (MS_VX+M_S1)&$FFFF
L7015:  STD  (MS_VX+M_S1)&$FFFF
L7018:  LDA  GM_WAV
L701B:  LSRA                        ;VARY WHICH WAY WE ROTATE
L701C:  BCC  L7023                  ;IFCS
L701E:  LDD  #$0BB8                 ;10.55 DEGREES *34. GIVES A 360
L7021:  BRA  L7026                  ;ELSE
L7023:  LDD  #$F448
L7026:  STD  M_SIN
L7029:  LDD  #$3EEB                 ;10.55 DEGREES, *34. TURNS DOES A 360
L702C:  STD  M_COS
L702F:  JSR  S1RL                   ;LETS ROLLEM
L7032:  LDD  #$0000
L7035:  SUBD GD_ACT
L7037:  JSR  UNTWGD                 ;REMEMBER TO UNTWIST ANY GROUND MOVEMENT
L703A:  RTS

;------------------------------------------------------------------------------
; S1MVBS - WORMHOLE PLAYER MOVEMENT
;------------------------------------------------------------------------------
S1MVBS:
L703B:  LDD  (MS_VX+M_S1)&$FFFF     ;PLAYERS FORWARD MOVEMENT
L703E:  ADDD MS_TX+M_S1
L7041:  STD  MS_TX+M_S1
L7044:  STD  MS_TX+M_U1
L7047:  LDD  (MS_VX+M_S1)&$FFFF     ;FASTEST IS AT 45 DEGREES
L704A:  JSR  LSLD4
L704D:  LDB  SI_RSX                 ;RESPOND IMMEDIATELY TO CONTROL POSITION--SLALOM
L704F:  BPL  L7052                  ;IFMI
L7051:  COMB                        ;HANDLE 80 CORRECTLY,ABSB
L7052:  MUL
L7053:  TST  SI_RSX                 ;REMEMBER TO FLIP DIRECTIONS
L7055:  BGE  L705B                  ;IFLT
L7057:  COMA                        ;NEGD
L7058:  NEGB
L7059:  SBCA #$FF
L705B:  JSR  ASRD4
L705E:  STD  (MS_VY+M_S1)&$FFFF     ;ALLOW OTHERS TO KNOW OUR SPEED
L7061:  ADDD MS_TY+M_S1
L7064:  CMPD #$01FF
L7068:  BLE  S1MVBS_35
L706A:  LDD  #$01FF

S1MVBS_35:
L706D:  CMPD #$FE01
L7071:  BGE  S1MVBS_38
L7073:  LDD  #$FE01

S1MVBS_38:
L7076:  STD  MS_TY+M_S1
L7079:  STD  MS_TY+M_U1
L707C:  LDD  (MS_VX+M_S1)&$FFFF
L707F:  LSLB                        ;LSLD
L7080:  ROLA
L7081:  LSLB                        ;LSLD
L7082:  ROLA
L7083:  LSLB                        ;LSLD
L7084:  ROLA
L7085:  LSLB                        ;LSLD  SCALE UP *16.
L7086:  ROLA
L7087:  LDB  SI_RSY
L7089:  BPL  L708C                  ;IFMI
L708B:  COMB                        ;HANDLE 80 CORRECTLY,ABSB
L708C:  LSLB                        ;*2 FOR MAX SPEED SLALOM(45 DEGREE)
L708D:  MUL
L708E:  TST  SI_RSY                 ;REMEMBER TO FLIP DIRECTIONS
L7090:  BPL  L7096                  ;IFMI
L7092:  COMA                        ;NEGD
L7093:  NEGB
L7094:  SBCA #$FF
L7096:  ASRA                        ;ASRD
L7097:  RORB
L7098:  ASRA                        ;ASRD
L7099:  RORB
L709A:  ASRA                        ;ASRD
L709B:  RORB
L709C:  ASRA                        ;ASRD  SCALE BACK DOWN/16.
L709D:  RORB
L709E:  STD  MS_VZ+M_S1
L70A1:  ADDD MS_TZ+M_S1
L70A4:  CMPD #$FEFF
L70A8:  BLE  S1MVBS_45
L70AA:  LDD  #$FEFF

S1MVBS_45:
L70AD:  CMPD #$F201
L70B1:  BGE  S1MVBS_48
L70B3:  LDD  #$F201

S1MVBS_48:
L70B6:  STD  MS_TZ+M_S1
L70B9:  STD  MS_TZ+M_U1
L70BC:  RTS

;------------------------------------------------------------------------------
; S1RHPT - ---SHIP 1 RHEOSTAT PITCH
;------------------------------------------------------------------------------
S1RHPT:
L70BD:  LDX  #RHEOP
L70C0:  JSR  RHTRIG                 ;CONVERT TO TRIG VALUES
L70C3:  JSR  RHRSDU
L70C6:  BEQ  S1RHPT_30              ;?ROTATE?
L70C8:  JSR  S1PT                   ;PITCH APPROPRIATELY

S1RHPT_30:
L70CB:  RTS

;------------------------------------------------------------------------------
; S1RHYW - ---SHIP 1 RHEOSTAT YAW
;------------------------------------------------------------------------------
S1RHYW:
L70CC:  LDX  #RHEOY
L70CF:  JSR  RHTRIG                 ;PROCESS INTO TRIG VALUES
L70D2:  JSR  RHRSDU                 ;PROCESS MAJOR RHEOSTAT RESIDU
L70D5:  BEQ  S1RHYW_30              ;?ROTATE?
L70D7:  JSR  S1YW                   ;YAW (N) APPROPRIATELY

S1RHYW_30:
L70DA:  RTS

;------------------------------------------------------------------------------
; VGTOSITE - PULLS IRQ RHEO VALS INTO SITE VALS FOR NORMAL USE
;   ********* SPECIAL INTERFACE WITH IRQ RHEOSTATS
;------------------------------------------------------------------------------
VGTOSITE:
L70DB:  ORCC #$10                   ;SEI
L70DD:  LDD  VG_RSY                 ;PITCH GOES TO REAL UP/DOWN Y
L70DF:  STD  SI_RSY
L70E1:  LDD  VG_RSX                 ;YAW GOES TO REAL LEFT/RIGHT X
L70E3:  STD  SI_RSX
L70E5:  LDD  VG_CY
L70E7:  STD  SI_CY
L70E9:  LDD  VG_CX
L70EB:  STD  SI_CX
L70ED:  ANDCC #$EF                  ;CLI  ***PERRY NOYD GETS IRQ'D
L70EF:  RTS

;------------------------------------------------------------------------------
; RHTRIG - X-->RAM BLOCK
;   OUTPUT
;   SETUP M.SIN, M.COS
;------------------------------------------------------------------------------
RHTRIG:
L70F0:  LDA  RHS_RAT,X
L70F2:  BPL  RHTRIG_20
L70F4:  COMA                        ;WIDER BALANCED ZERO, ALLOW -80

RHTRIG_20:
L70F5:  LDB  #$80                   ;FROM +-128. TO ?
L70F7:  MUL
L70F8:  NOP
L70F9:  NOP
L70FA:  NOP

RHTRIG_40:
L70FB:  LDB  RHS_RAT,X
L70FD:  BMI  L7107                  ;IFPL
L70FF:  ADDA RHS_RSD,X
L7101:  BVC  L7105                  ;IFVS
L7103:  LDA  #$7F
L7105:  BRA  L710E                  ;ELSE  GO IN NEGATIVE DIRECTION
L7107:  NEGA
L7108:  ADDA RHS_RSD,X
L710A:  BVC  L710E                  ;IFVS
L710C:  LDA  #$81
L710E:  STA  RHS_RSD,X              ;SIGNED VALUE
L7110:  RTS

;------------------------------------------------------------------------------
; RHRSDU - PROCESS MAJOR RHEOSTAT RESIDU  (comment at the call)
;------------------------------------------------------------------------------
RHRSDU:
L7111:  LDA  RHS_RSD,X
L7113:  BPL  RHRSDU_48
L7115:  NEGA                        ;ABSOLUTE VALUE

RHRSDU_48:
L7116:  CMPA #$4E                   ;?PASSED THE LARGE MAGIC ANGLE?
L7118:  BLO  RHRSDU_60
L711A:  LDD  #$3FC2                 ;HS. 78., ROTATE 4.99 LARGE MAGIC ANGLE DEGREES
L711D:  STD  M_COS
L7120:  LDA  RHS_RSD,X
L7122:  BPL  RHRSDU_54
L7124:  ADDA #$4E                   ;NEGATIVE ROTATE
L7126:  STA  RHS_RSD,X
L7128:  LDD  #$FA70
L712B:  STD  M_SIN
L712E:  RTS

RHRSDU_54:
L712F:  SUBA #$4E                   ;POSITIVE ROTATE
L7131:  STA  RHS_RSD,X              ;CORRECT THE RESIDUE
L7133:  LDD  #$0590
L7136:  STD  M_SIN
L7139:  RTS

RHRSDU_60:       ;---CHECK FOR SMALLER MAGIC ANGLE
L713A:  CMPA #$0E                   ;.895 MARK
L713C:  BLO  RHRSDU_70              ;?BEYOND .895 MAGIC ANGLE?
L713E:  LDD  #$3FFE
L7141:  STD  M_COS
L7144:  LDA  RHS_RSD,X              ;THEN STEP TOWARDS IT
L7146:  BPL  RHRSDU_64              ;?NEGATIVE ROTATE?
L7148:  ADDA #$0E
L714A:  STA  RHS_RSD,X
L714C:  LDD  #$FF00
L714F:  STD  M_SIN
L7152:  RTS

RHRSDU_64:       ;---POSITIVE,ROTATE
L7153:  SUBA #$0E                   ;CORRECT THE RESIDUE
L7155:  STA  RHS_RSD,X
L7157:  LDD  #$0100
L715A:  STD  M_SIN
L715D:  RTS

RHRSDU_70:
L715E:  CLRB                        ;NO ROTATE
L715F:  RTS

;------------------------------------------------------------------------------
; RESIDU - HANDLE RESIDUE ROTATIONS UPON DOWNLOADED UNIT VECTORS
;------------------------------------------------------------------------------
RESIDU:
L7160:  LDA  >RHS_RSD+RHEOP         ;PITCH TICS LEFT
L7163:  BEQ  RESIDU_40              ;RESIDUE LEFT?
L7165:  JSR  RESCNV                 ;CONVERT RESIDUE TO SIN/COS
L7168:  LDA  >RHS_RSD+RHEOP
L716B:  BPL  RESIDU_35              ;?TURNING BACKWARDS?
L716D:  LDD  #$0000                 ;THEN INVERT SINE
L7170:  SUBD M_SIN
L7173:  STD  M_SIN

RESIDU_35:
L7176:  CLRA
L7177:  LDB  #MS_U1BC               ;PITCH DOWNLOADED UNIT VECTORS
L7179:  STD  M_BIC
L717C:  LDA  #MS_PTCH
L717E:  JSR  MGOWT

RESIDU_40:       ;HANDLE YAW RESIDUE
L7181:  LDA  >RHS_RSD+RHEOY
L7184:  BEQ  RESIDU_60
L7186:  JSR  RESCNV                 ;CONVERT RESIDUE
L7189:  LDA  >RHS_RSD+RHEOY
L718C:  BPL  RESIDU_45              ;?TURNING BACKWARDS?
L718E:  LDD  #$0000                 ;THEN INVERT SINE
L7191:  SUBD M_SIN
L7194:  STD  M_SIN

RESIDU_45:
L7197:  CLRA
L7198:  LDB  #MS_U1BC               ;YAW DOWNLOADED UNIT VECTORS
L719A:  STD  M_BIC
L719D:  LDA  #MS_YAW
L719F:  JSR  MGOWT

RESIDU_60:
L71A2:  LDA  >RHS_RSD+RHEOR         ;ROLL TICS LEFT
L71A5:  BEQ  RESIDU_70              ;RESIDUE LEFT?
L71A7:  JSR  RESCNV                 ;CONVERT RESIDUE TO SIN/COS
L71AA:  LDA  >RHS_RSD+RHEOR
L71AD:  BPL  RESIDU_65              ;?TURNING BACKWARDS?
L71AF:  LDD  #$0000                 ;THEN INVERT SINE
L71B2:  SUBD M_SIN
L71B5:  STD  M_SIN

RESIDU_65:
L71B8:  CLRA
L71B9:  LDB  #MS_U1BC               ;ROLL DOWNLOADED UNIT VECTORS
L71BB:  STD  M_BIC
L71BE:  LDA  #MS_ROLL
L71C0:  JSR  MGOWT

RESIDU_70:
L71C3:  RTS

;------------------------------------------------------------------------------
; RESCNV - CONVERT A=RESIDUE TO SIN,COS
;------------------------------------------------------------------------------
RESCNV:
L71C4:  BPL  RESCNV_22
L71C6:  NEGA                        ;ABSOLUTE VALUE

RESCNV_22:
L71C7:  LDB  #$03
L71C9:  MUL
L71CA:  LDX  #TRHTIC                ;TABLE OF TIC SIN AND COS
L71CD:  ABX                         ;X-->ENTRY
L71CE:  LDD  ,X                     ;SIN AS WORD ENTRY
L71D0:  STD  M_SIN
L71D3:  LDB  2,X                    ;ONE BYTE COS OFFSET FROM 1
L71D5:  SEX
L71D6:  ADDD #$4000                 ;GET WORD COSISNE
L71D9:  STD  M_COS
.alias TRHTIC           $71DA    ;inside the line at L71D9 (L71D9+1)
L71DC:  RTS
;SINE COSINE FOR MAGIC TICS, 4000(16384.) IS UNITY
;# DEGREES SINE COSINE
L71DD:  .word $0012                 ;TIC 18 16384  # 1 .064 18 16384
L71DF:  .byte $00
L71E0:  .word $0025                 ;TIC 37 16384  # 2 .128 37 16384
L71E2:  .byte $00
L71E3:  .word $0037                 ;TIC 55 16384  # 3 .192 55 16384
L71E5:  .byte $00
L71E6:  .word $0049                 ;TIC 73 16384  # 4 .256 73 16384
L71E8:  .byte $00
L71E9:  .word $005B                 ;TIC 91 16384  # 5 .32 91 16384
L71EB:  .byte $00
L71EC:  .word $006E                 ;TIC 110 16384  # 6 .384 110 16384
L71EE:  .byte $00
L71EF:  .word $0080                 ;TIC 128 16384  # 7 .447 128 16384
L71F1:  .byte $00
L71F2:  .word $0092                 ;TIC 146 16383  # 8 .511 146 16383
L71F4:  .byte $FF
L71F5:  .word $00A5                 ;TIC 165 16383  # 9 .575 165 16383
L71F7:  .byte $FF
L71F8:  .word $00B7                 ;TIC 183 16383  # 10 .639 183 16383
L71FA:  .byte $FF
L71FB:  .word $00C9                 ;TIC 201 16383  # 11 .703 201 16383
L71FD:  .byte $FF
L71FE:  .word $00DB                 ;TIC 219 16383  # 12 .767 219 16383
L7200:  .byte $FF
L7201:  .word $00EE                 ;TIC 238 16382  # 13 .831 238 16382
L7203:  .byte $FE
L7204:  .word $0100                 ;TIC 256 16382  # 14 .895 256 16382
L7206:  .byte $FE
L7207:  .word $0112                 ;TIC 274 16382  # 15 .959 274 16382
L7209:  .byte $FE
L720A:  .word $0124                 ;TIC 292 16381  # 16 1.023 292 16381
L720C:  .byte $FD
L720D:  .word $0137                 ;TIC 311 16381  # 17 1.087 311 16381
L720F:  .byte $FD
L7210:  .word $0149                 ;TIC 329 16381  # 18 1.151 329 16381
L7212:  .byte $FD
L7213:  .word $015B                 ;TIC 347 16380  # 19 1.215 347 16380
L7215:  .byte $FC
L7216:  .word $016E                 ;TIC 366 16380  # 20 1.278 366 16380
L7218:  .byte $FC
L7219:  .word $0180                 ;TIC 384 16380  # 21 1.342 384 16380
L721B:  .byte $FC
L721C:  .word $0192                 ;TIC 402 16379  # 22 1.406 402 16379
L721E:  .byte $FB
L721F:  .word $01A4                 ;TIC 420 16379  # 23 1.47 420 16379
L7221:  .byte $FB
L7222:  .word $01B7                 ;TIC 439 16378  # 24 1.534 439 16378
L7224:  .byte $FA
L7225:  .word $01C9                 ;TIC 457 16378  # 25 1.598 457 16378
L7227:  .byte $FA
L7228:  .word $01DB                 ;TIC 475 16377  # 26 1.662 475 16377
L722A:  .byte $F9
L722B:  .word $01ED                 ;TIC 493 16377  # 27 1.726 493 16377
L722D:  .byte $F9
L722E:  .word $0200                 ;TIC 512 16376  # 28 1.79 512 16376
L7230:  .byte $F8
L7231:  .word $0212                 ;TIC 530 16375  # 29 1.854 530 16375
L7233:  .byte $F7
L7234:  .word $0224                 ;TIC 548 16375  # 30 1.918 548 16375
L7236:  .byte $F7
L7237:  .word $0237                 ;TIC 567 16374  # 31 1.982 567 16374
L7239:  .byte $F6
L723A:  .word $0249                 ;TIC 585 16374  # 32 2.046 585 16374
L723C:  .byte $F6
L723D:  .word $025B                 ;TIC 603 16373  # 33 2.109 603 16373
L723F:  .byte $F5
L7240:  .word $026D                 ;TIC 621 16372  # 34 2.173 621 16372
L7242:  .byte $F4
L7243:  .word $0280                 ;TIC 640 16372  # 35 2.237 640 16372
L7245:  .byte $F4
L7246:  .word $0292                 ;TIC 658 16371  # 36 2.301 658 16371
L7248:  .byte $F3
L7249:  .word $02A4                 ;TIC 676 16370  # 37 2.365 676 16370
L724B:  .byte $F2
L724C:  .word $02B6                 ;TIC 694 16369  # 38 2.429 694 16369
L724E:  .byte $F1
L724F:  .word $02C9                 ;TIC 713 16368  # 39 2.493 713 16368
L7251:  .byte $F0
L7252:  .word $02DB                 ;TIC 731 16368  # 40 2.557 731 16368
L7254:  .byte $F0
L7255:  .word $02ED                 ;TIC 749 16367  # 41 2.621 749 16367
L7257:  .byte $EF
L7258:  .word $02FF                 ;TIC 767 16366  # 42 2.685 767 16366
L725A:  .byte $EE
L725B:  .word $0312                 ;TIC 786 16365  # 43 2.749 786 16365
L725D:  .byte $ED
L725E:  .word $0324                 ;TIC 804 16364  # 44 2.813 804 16364
L7260:  .byte $EC
L7261:  .word $0336                 ;TIC 822 16363  # 45 2.877 822 16363
L7263:  .byte $EB
L7264:  .word $0348                 ;TIC 840 16362  # 46 2.94 840 16362
L7266:  .byte $EA
L7267:  .word $035B                 ;TIC 859 16361  # 47 3.004 859 16361
L7269:  .byte $E9
L726A:  .word $036D                 ;TIC 877 16361  # 48 3.068 877 16361
L726C:  .byte $E9
L726D:  .word $037F                 ;TIC 895 16360  # 49 3.132 895 16360
L726F:  .byte $E8
L7270:  .word $0391                 ;TIC 913 16359  # 50 3.196 913 16359
L7272:  .byte $E7
L7273:  .word $03A4                 ;TIC 932 16357  # 51 3.26 932 16357
L7275:  .byte $E5
L7276:  .word $03B6                 ;TIC 950 16356  # 52 3.324 950 16356
L7278:  .byte $E4
L7279:  .word $03C8                 ;TIC 968 16355  # 53 3.388 968 16355
L727B:  .byte $E3
L727C:  .word $03DA                 ;TIC 986 16354  # 54 3.452 986 16354
L727E:  .byte $E2
L727F:  .word $03ED                 ;TIC 1005 16353  # 55 3.516 1005 16353
L7281:  .byte $E1
L7282:  .word $03FF                 ;TIC 1023 16352  # 56 3.58 1023 16352
L7284:  .byte $E0
L7285:  .word $0411                 ;TIC 1041 16351  # 57 3.644 1041 16351
L7287:  .byte $DF
L7288:  .word $0423                 ;TIC 1059 16350  # 58 3.708 1059 16350
L728A:  .byte $DE
L728B:  .word $0436                 ;TIC 1078 16349  # 59 3.771 1078 16349
L728D:  .byte $DD
L728E:  .word $0448                 ;TIC 1096 16347  # 60 3.835 1096 16347
L7290:  .byte $DB
L7291:  .word $045A                 ;TIC 1114 16346  # 61 3.899 1114 16346
L7293:  .byte $DA
L7294:  .word $046C                 ;TIC 1132 16345  # 62 3.963 1132 16345
L7296:  .byte $D9
L7297:  .word $047F                 ;TIC 1151 16344  # 63 4.027 1151 16344
L7299:  .byte $D8
L729A:  .word $0491                 ;TIC 1169 16342  # 64 4.091 1169 16342
L729C:  .byte $D6
L729D:  .word $04A3                 ;TIC 1187 16341  # 65 4.155 1187 16341
L729F:  .byte $D5
L72A0:  .word $04B5                 ;TIC 1205 16340  # 66 4.219 1205 16340
L72A2:  .byte $D4
L72A3:  .word $04C8                 ;TIC 1224 16338  # 67 4.283 1224 16338
L72A5:  .byte $D2
L72A6:  .word $04DA                 ;TIC 1242 16337  # 68 4.347 1242 16337
L72A8:  .byte $D1
L72A9:  .word $04EC                 ;TIC 1260 16335  # 69 4.411 1260 16335
L72AB:  .byte $CF
L72AC:  .word $04FE                 ;TIC 1278 16334  # 70 4.475 1278 16334
L72AE:  .byte $CE
L72AF:  .word $0510                 ;TIC 1296 16333  # 71 4.539 1296 16333
L72B1:  .byte $CD
L72B2:  .word $0523                 ;TIC 1315 16331  # 72 4.602 1315 16331
L72B4:  .byte $CB
L72B5:  .word $0535                 ;TIC 1333 16330  # 73 4.666 1333 16330
L72B7:  .byte $CA
L72B8:  .word $0547                 ;TIC 1351 16328  # 74 4.73 1351 16328
L72BA:  .byte $C8
L72BB:  .word $0559                 ;TIC 1369 16327  # 75 4.794 1369 16327
L72BD:  .byte $C7
L72BE:  .word $056C                 ;TIC 1388 16325  # 76 4.858 1388 16325
L72C0:  .byte $C5
L72C1:  .word $057E                 ;TIC 1406 16324  # 77 4.922 1406 16324
L72C3:  .byte $C4
L72C4:  .word $0590                 ;TIC 1424 16322  # 78 4.986 1424 16322
L72C6:  .byte $C2

;------------------------------------------------------------------------------
; VIEW - VIEW ROUTINES FOR THE PHASES
;------------------------------------------------------------------------------
VIEW:
L72C7:  JSR  IVGEN1
L72CA:  LDA  #MS_S1BC
L72CC:  JSR  IS1UV                  ;MATH BOX, PRIMARY INIT
L72CF:  JSR  RESIDU
L72D2:  JSR  VWMES
L72D5:  LDA  SC_FWV
L72D8:  BNE  L72F0                  ;IFEQ  ?FIRST TIME THRU?
L72DA:  LDD  PH_TIM                 ;THEN GIVE INSTRUCTIONS TO PLAYER
L72DD:  CMPD #$00A0                 ;LOOK AT EACH MESSAGE 5 TIMES, ONE CYCLE TAKES 20
L72E1:  BHS  L72F0                  ;IFLO
L72E3:  ANDB #$10
L72E5:  BNE  L72EB                  ;IFEQ
L72E7:  LDB  #MS_SFB                ;SHOOT FIREBALLS
L72E9:  BRA  L72ED                  ;ELSE
L72EB:  LDB  #MS_STF                ;SHOOT TIE FIGHTERS
L72ED:  JSR  DOMESS
L72F0:  JSR  VWGAS
L72F3:  JSR  VWDTHA                 ;VIEW DETH STAR, MINIATURE
L72F6:  JSR  VWSITE
L72F9:  JSR  VWSTAR
L72FC:  JSR  VWXPLD                 ;CAN SEE PARTS ONCE ORIGINAL IS GONE FROM VIEW
L72FF:  JSR  TSTLAZ                 ;PREPARE FOR LAZAR HITS
L7302:  JSR  SNVW
L7305:  JSR  VWGUN
L7308:  JSR  CLSLZ                  ;PROCESS COLLISIONS
L730B:  JSR  VWLAZ                  ;AND SEE RESULT
L730E:  JSR  VWGLW
L7311:  JSR  VGDONE
L7314:  RTS

;------------------------------------------------------------------------------
; VEWS0D - [note] View for PHES0D (space to die): messages, gas, stars, explosions, alien ships, guns,
;   growing GAME OVER message and glow; no site and no lazar collisions
;------------------------------------------------------------------------------
VEWS0D:
L7315:  JSR  IVGEN1
L7318:  LDA  #MS_S1BC
L731A:  JSR  IS1UV                  ;MATH BOX, PRIMARY INIT
L731D:  JSR  RESIDU
L7320:  JSR  VWMES
L7323:  JSR  VWGAS
L7326:  JSR  VWSTAR
L7329:  JSR  VWXPLD                 ;SHOW PARTS AFTER TIE GONE FROM DISPLAY
L732C:  JSR  SNVW
L732F:  JSR  VWGUN
L7332:  JSR  VWMOVR                 ;VIEW EXPANDING GAME OVER MESSAGE
L7335:  JSR  VWGLW
L7338:  JSR  VGDONE
L733B:  RTS

;------------------------------------------------------------------------------
; VEWHPA - VIEW HYPER INTO SMALL DETH STAR
;------------------------------------------------------------------------------
VEWHPA:
L733C:  JSR  IVGEN1
L733F:  LDA  #MS_S1BC
L7341:  JSR  IS1UV                  ;MATH BOX, PRIMARY INIT
L7344:  JSR  RESIDU
L7347:  JSR  VWMES
L734A:  JSR  VWGAS
L734D:  JSR  VWSITE
L7350:  JSR  VWSTAR
L7353:  JSR  VWDTHA                 ;VIEW DETH STAR, MINIATURE
L7356:  JSR  VWXPLD                 ;PLACE AFTER TIE NO LONGER SHOWN
L7359:  JSR  TSTLAZ                 ;PREPARE FOR LAZAR HITS
L735C:  JSR  SNVW
L735F:  JSR  VWGUN
L7362:  JSR  CLSLZ                  ;PROCESS COLLISIONS
L7365:  JSR  VWLAZ                  ;AND SEE RESULT
L7368:  JSR  VWGLW
L736B:  JSR  VGDONE
L736E:  RTS

;------------------------------------------------------------------------------
; VEWHPB - VIEW HYPER INTO LARGE DETH STAR
;------------------------------------------------------------------------------
VEWHPB:
L736F:  JSR  IVGEN1
L7372:  LDA  #MS_S1BC
L7374:  JSR  IS1UV                  ;MATH BOX, PRIMARY INIT
L7377:  JSR  RESIDU
L737A:  JSR  VWMES
L737D:  JSR  VWGAS
L7380:  JSR  VWSITE
L7383:  JSR  VWSTAR
L7386:  JSR  VWDTHB                 ;VIEW DETH STAR, ENLARGING
L7389:  JSR  VWGLW
L738C:  JSR  VGDONE
L738F:  RTS

;------------------------------------------------------------------------------
; VEWGD - VIEW GROUND FLYING
;------------------------------------------------------------------------------
VEWGD:
L7390:  JSR  IVGEN1
L7393:  LDA  #MS_S1BC
L7395:  JSR  IS1UV                  ;MATH BOX, PRIMARY INIT
L7398:  JSR  RESIDU
L739B:  JSR  VWMES
L739E:  JSR  VWMTWR                 ;TOWER RELATED MESSAGES
L73A1:  JSR  VWGAS
L73A4:  JSR  VWSITE
L73A7:  JSR  VWSTRG                 ;VIEW GROUND STARS
L73AA:  JSR  TSTLAZ                 ;PREPARE FOR LAZAR HITS
L73AD:  JSR  VWGUN
L73B0:  JSR  VWGRND
L73B3:  JSR  CLGLZ                  ;PROCESS COLLISIONS
L73B6:  JSR  VWLAZ                  ;AND SEE RESULT
L73B9:  JSR  VWXPLD
L73BC:  JSR  VWGLW
L73BF:  JSR  VGDONE
L73C2:  RTS

;------------------------------------------------------------------------------
; VEWG0D - [note] View for PHEG0D (ground to die): messages, tower messages, gas, ground stars, guns, ground,
;   growing GAME OVER message and glow; no site and no lazar collisions
;------------------------------------------------------------------------------
VEWG0D:
L73C3:  JSR  IVGEN1
L73C6:  LDA  #MS_S1BC
L73C8:  JSR  IS1UV                  ;MATH BOX, PRIMARY INIT
L73CB:  JSR  RESIDU
L73CE:  JSR  VWMES
L73D1:  JSR  VWMTWR                 ;TOWER RELATED MESSAGES
L73D4:  JSR  VWGAS
L73D7:  JSR  VWSTRG                 ;VIEW GROUND STARS
L73DA:  JSR  VWGUN
L73DD:  JSR  VWGRND
L73E0:  JSR  VWMOVR                 ;VIEW EXPANDING GAME OVER MESSAGE
L73E3:  JSR  VWGLW
L73E6:  JSR  VGDONE
L73E9:  RTS

;------------------------------------------------------------------------------
; VEWG0B - GROUND TO BASE TRANSITION
;------------------------------------------------------------------------------
VEWG0B:
L73EA:  JSR  IVGEN1
L73ED:  LDA  #MS_S1BC
L73EF:  JSR  IS1UV                  ;MATH BOX, PRIMARY INIT
L73F2:  JSR  RESIDU
L73F5:  JSR  VWMES
L73F8:  JSR  VWMTWZ                 ;TOWER DONE, END MESSAGES ONLY
L73FB:  LDB  #MS_USE                ;USE THE FORCE
L73FD:  JSR  DOMESS
L7400:  JSR  VWGAS
L7403:  JSR  VWSITE
L7406:  JSR  VWSTRG                 ;VIEW GROUND STARS
L7409:  JSR  VWXPLD
L740C:  JSR  VWGLW
L740F:  JSR  VGDONE
L7412:  RTS

;------------------------------------------------------------------------------
; VEWG1B - [note] View for PHEG1B (next part of ground to base transition): as VEWG0B, but views the star base
;   (VWBASE) in place of the ground stars
;------------------------------------------------------------------------------
VEWG1B:
L7413:  JSR  IVGEN1
L7416:  LDA  #MS_S1BC
L7418:  JSR  IS1UV                  ;MATH BOX, PRIMARY INIT
L741B:  JSR  RESIDU
L741E:  JSR  VWMES
L7421:  JSR  VWMTWZ                 ;TOWER DONE, END MESSAGES ONLY
L7424:  LDB  #MS_USE                ;USE THE FORCE
L7426:  JSR  DOMESS
L7429:  JSR  VWGAS
L742C:  JSR  VWSITE
L742F:  JSR  VWBASE
L7432:  JSR  VWXPLD
L7435:  JSR  VWGLW
L7438:  JSR  VGDONE
L743B:  RTS

;------------------------------------------------------------------------------
; VEWBS - BASE TRENCH VIEW
;   VIEW BASE TRENCH
;------------------------------------------------------------------------------
VEWBS:
L743C:  JSR  IVGEN1
L743F:  LDA  #MS_S1BC
L7441:  JSR  IS1UV                  ;MATH BOX, PRIMARY INIT
L7444:  JSR  RESIDU
L7447:  JSR  VWMES
L744A:  LDA  PH_TIM
L744D:  CMPA #$04
L744F:  BHI  L7464                  ;IFLS
L7451:  LDA  BS_RPT
L7453:  BNE  L745A                  ;IFEQ  ?FIRST TIME THRU THIS TRENCH?
L7455:  JSR  VWMTWZ                 ;SOME TOWER PHASE MESSAGES SEEN STILL
L7458:  BRA  L7464                  ;ELSE  ELSE MUST HAVE MISSED AND AM REPEATING
L745A:  LDD  #VGSCAL-$100           ;DOUBLE SIZE
L745D:  STD  ,Y++
L745F:  LDB  #MS_MSD                ;MISSED EXHAUST PORT
L7461:  JSR  DOMESS                 ;SCALE RESET AUTOMATICALLY
L7464:  LDA  SC_FWV
L7467:  BNE  L7491                  ;IFEQ  ?FIRST WAVE?
L7469:  LDA  PH_TIM
L746C:  CMPA #$08
L746E:  BHI  L7491                  ;IFLS
L7470:  LDA  BS_RPT
L7472:  BNE  L7491                  ;IFEQ  ?FIRST TIME THRU THIS TRENCH?
L7474:  LDA  Q_ATP
L7477:  BNE  L7491                  ;IFEQ  ?SPACE CLEAR SINCE NOT HIT ALL TOWER TOPS?
L7479:  LDA  BS_WAV
L747C:  BNE  L7482                  ;IFEQ  ?FIRST WAVE WITHOUT CATWALKS?
L747E:  LDB  #MS_SFB                ;SHOOT FIREBALLS
L7480:  BRA  L748E                  ;ELSE  ELSE ALTERNATE WITH CATWALK ALSO
L7482:  LDA  FRAMEL
L7484:  ANDA #$10
L7486:  BNE  L748C                  ;IFEQ  ?TIME TO SWITCH TWEEN MESSAGES?
L7488:  LDB  #MS_SFB                ;SHOOT FIREBALLS
L748A:  BRA  L748E                  ;ELSE
L748C:  LDB  #MS_ACW                ;AVOID CATWALKS
L748E:  JSR  DOMESS
L7491:  LDA  SC_FWV                 ;FIRST WAVE?
L7494:  BNE  L74A5                  ;IFEQ  YES, THEN MAY SHOW MESSAGE
L7496:  LDA  >BS_PFL
L7499:  BEQ  L74A5                  ;IFNE
L749B:  LDD  #VGSCAL-$100           ;DOUBLE SIZE
L749E:  STD  ,Y++
L74A0:  LDB  #MS_EXH                ;"EXHAUST PORT AHEAD"
L74A2:  JSR  DOMESS                 ;SCALE RESET AUTOMATICALLY
L74A5:  LDA  Q_FRC
L74A8:  BLT  L74B6                  ;IFGE  ?USING THE FORCE?
L74AA:  BNE  L74B3                  ;IFEQ  ?BUT STILL WAITING?
L74AC:  LDB  #MS_USE
L74AE:  JSR  DOMESS
L74B1:  BRA  L74B6                  ;ELSE  ELSE WAS SUCCESSFUL
L74B3:  JSR  VWFRC                  ;VIEW FORCE SCORING
L74B6:  JSR  VWGAS
L74B9:  JSR  VWSITE
L74BC:  JSR  VWBASE                 ;VIEW STAR BASE
L74BF:  JSR  TSTLAZ                 ;PREPARE FOR LAZAR HITS
L74C2:  JSR  VWGUN
L74C5:  JSR  CLBLZ                  ;PROCESS COLLISIONS
L74C8:  JSR  VWLAZ                  ;AND SEE RESULT
L74CB:  JSR  VWPTGN                 ;SEE THE PROTON TORPS IMMEDIATELY
L74CE:  JSR  VWGLW
L74D1:  JSR  VGDONE
L74D4:  RTS

;------------------------------------------------------------------------------
; VEWB0D - [note] View for PHEB0D (base trench to die): messages, MISSED EXHAUST PORT if Q_BSH, gas, star base, guns,
;   EXHAUST PORT AHEAD if first wave and BS_PFL, growing GAME OVER message and glow
;------------------------------------------------------------------------------
VEWB0D:
L74D5:  JSR  IVGEN1
L74D8:  LDA  #MS_S1BC
L74DA:  JSR  IS1UV                  ;MATH BOX, PRIMARY INIT
L74DD:  JSR  RESIDU
L74E0:  JSR  VWMES
L74E3:  LDA  Q_BSH                  ;TEST IF WE BASHED OUR NOSES
L74E6:  BEQ  L74F2                  ;IFNE  ?HIT BACK WALL?
L74E8:  LDD  #VGSCAL-$100           ;DOUBLE SIZE
L74EB:  STD  ,Y++
L74ED:  LDB  #MS_MSD                ;MISSED EXHAUST PORT
L74EF:  JSR  DOMESS
L74F2:  JSR  VWGAS
L74F5:  JSR  VWBASE                 ;VIEW STAR BASE
L74F8:  JSR  VWGUN
L74FB:  LDA  SC_FWV                 ;FIRST WAVE PLAYED?
L74FE:  BNE  L750F                  ;IFEQ  YES, THEN MAY SHOW MESSAGE
L7500:  LDA  >BS_PFL
L7503:  BEQ  L750F                  ;IFNE
L7505:  LDD  #VGSCAL-$100           ;DOUBLE SIZE
L7508:  STD  ,Y++
L750A:  LDB  #MS_EXH                ;"EXHAUST PORT AHEAD"
L750C:  JSR  DOMESS
L750F:  JSR  VWMOVR                 ;VIEW EXPANDING GAME OVER MESSAGE
L7512:  JSR  VWGLW
L7515:  JSR  VGDONE
L7518:  RTS

;------------------------------------------------------------------------------
; VEWNXT - VIEW NXT PHASE STUFF  (comment at the call)
;------------------------------------------------------------------------------
VEWNXT:
L7519:  JSR  IVGEN1
L751C:  LDA  #MS_S1BC
L751E:  JSR  IS1UV                  ;MATH BOX, PRIMARY INIT
L7521:  JSR  RESIDU
L7524:  JSR  VWMES
L7527:  JSR  VWGAS
L752A:  JSR  VWSITE
L752D:  JSR  VWSTAR
L7530:  LDB  #MS_DSD                ;"DEATH STAR DESTROYED"
L7532:  JSR  DOMESS
L7535:  LDA  PH_TIM
L7538:  CMPA #$02
L753A:  BGT  L755A                  ;IFLE
L753C:  LDB  #MS_BRE                ;"BONUS FOR REMAINING ENERGY"
L753E:  JSR  DOMESS
L7541:  LDB  #MS_BRE+1              ;"5,000 X "
L7543:  JSR  DOMESS
L7546:  LDD  #$0090                 ;Y POS
L7549:  STD  ,Y++
L754B:  LDD  #$0070                 ;X POS
L754E:  STD  ,Y++
L7550:  LDA  GS_OLD                 ;SHOW ENERGY LEFT
L7552:  JSR  VWNIBL
L7555:  LDD  #VGCNTR
L7558:  STD  ,Y++
L755A:  LDA  PH_TIM
L755D:  CMPA #$01
L755F:  BGT  L759C                  ;IFLE
L7561:  LDA  >PT_LIV                ;DID PLAYER GET KILL DETH STAR
L7564:  BEQ  L759C                  ;IFNE  YES, THEN GIVE BONUS TYPE MESSAGE
L7566:  LDA  OPTS1                  ;HIGH BYTE OF 2ND OPTION BANK
L7569:  ANDA #$03                   ;BONUS FUEL UPON KILLING DETH STAR
L756B:  BEQ  L759C                  ;IFNE
L756D:  LDB  OPTS1+1
L7570:  ANDB #$03
L7572:  ADDB #$06
L7574:  CMPB S_GAS
L7576:  BHI  L757C                  ;IFLS  ?ARE WE FULL UP ON GAS?
L7578:  LDB  #MS_BSE+1              ;SHIELD AT FULL STRENGTH
L757A:  BRA  L7599                  ;ELSE  ELSE TELL HOW MANY ADDED
L757C:  LDU  #VJMFL                 ;MAKE IT FLASHY LIKE THE REST OF THE MESSAGE
L757F:  STU  ,Y++
L7581:  LDU  #$0048                 ;SHOW THE AMOUNT
L7584:  STU  ,Y++
L7586:  LDU  #$1EC0                 ;X POS
L7589:  STU  ,Y++
L758B:  LDB  #$01
L758D:  STB  BT_SUP
L758F:  JSR  VWNIBL
L7592:  LDD  #VGCNTR
L7595:  STD  ,Y++
L7597:  LDB  #MS_BSE                ;"X ADDED TO DEFLECTOR SHIELD"
L7599:  JSR  DOMESS
L759C:  LDA  PH_TIM
L759F:  CMPA #$00
L75A1:  BGT  L75B2                  ;IFLE
L75A3:  LDA  SC_FWV                 ;FIRST WAVE?
L75A6:  BNE  L75B2                  ;IFEQ  YES
L75A8:  LDB  GM_WAV
L75AB:  BEQ  L75B2                  ;IFNE  WASN'T WAVE 0, SO GIVE THEM MESSAGE
L75AD:  LDB  #MS_BON                ;"DEATH STAR BONUS EARNED"
L75AF:  JSR  DOMESS
L75B2:  JSR  VWGLW
L75B5:  JSR  VGDONE
L75B8:  RTS

;------------------------------------------------------------------------------
; VEWDX1 - DETH STAR PARTIAL PHASE 1
;------------------------------------------------------------------------------
VEWDX1:
L75B9:  JSR  IVGEN1
L75BC:  LDA  #MS_S1BC
L75BE:  JSR  IS1UV                  ;MATH BOX, PRIMARY INIT
L75C1:  JSR  VWMES
L75C4:  LDA  Q_FRC
L75C7:  BLE  L75CC                  ;IFGT  ?SUCCESSFUL USE OF THE FORCE?
L75C9:  JSR  VWFRC
L75CC:  JSR  VWGAS
L75CF:  JSR  VWSITE
L75D2:  JSR  VWDTHB                 ;VIEW DETH STAR, ENLARGING
L75D5:  JSR  VGDONE
L75D8:  RTS

;------------------------------------------------------------------------------
; VEWDX2 - DETH STAR PARTIAL PHASE 2
;------------------------------------------------------------------------------
VEWDX2:
L75D9:  JSR  IVGEN1
L75DC:  LDA  #MS_S1BC
L75DE:  JSR  IS1UV                  ;MATH BOX, PRIMARY INIT
L75E1:  JSR  VWMES
L75E4:  JSR  VWGAS
L75E7:  JSR  VWSITE
;VIEW DETH STAR MINIATURE
L75EA:  LDD  #VGOFFY&$1FFF          ;Y OFFSET
L75ED:  STD  ,Y++
L75EF:  LDD  #$0000                 ;NO X OFFSET
L75F2:  STD  ,Y++
L75F4:  LDD  #$7200                 ;SCALE FOR MINIATURE
L75F7:  STD  ,Y++
L75F9:  LDD  #VJBMIN                ;GET JSRL TO MINNY BASE OF DETH STAR
L75FC:  STD  ,Y++
L75FE:  LDD  #VGSCAL                ;RESTORE BASE
L7601:  STD  ,Y++
L7603:  JSR  VWXPLN                 ;DETH STAR PRETTY STARTING
L7606:  JSR  VGDONE
L7609:  RTS

;------------------------------------------------------------------------------
; VEWDX3 - DETH STAR PARTIAL PHASE 3
;------------------------------------------------------------------------------
VEWDX3:
L760A:  JSR  IVGEN1
L760D:  JSR  VWMES
L7610:  JSR  VWGAS
L7613:  JSR  VWSITE
L7616:  JSR  VWXPLN
L7619:  JSR  VGDONE
L761C:  RTS

;------------------------------------------------------------------------------
; VWMES - SCORE AND STUFF  (comment at the calls)
;------------------------------------------------------------------------------
VWMES:
L761D:  LDD  #VJTITL
L7620:  STD  ,Y++
L7622:  LDD  #(VGCGRN*$100)+VGCOPC  ;BRITE
L7625:  STD  ,Y++
L7627:  LDD  #VGRW3&$1FFF           ;HI UP
L762A:  STD  ,Y++
L762C:  LDD  #(VGLIML+(0*VGS_CW))&$1FFF ;LEFT
L762F:  STD  ,Y++
L7631:  LDA  #$06                   ;ZERO SUPPRESS TOP 6 DIGITS
L7633:  STA  BT_SUP
L7635:  LDX  #S_SC87
L7638:  JSR  VW8DIG                 ;COMPLETE WITH COMMAS
L763B:  LDD  #VGCNTR
L763E:  STD  ,Y++
;SHOW LAST SCORE ADDED IN
L7640:  LDB  SC_ADT                 ;TIMER
L7643:  BEQ  L766E                  ;IFNE  STILL VISIBLE, SHOW IT
L7645:  SUBB #$08
L7647:  CMPB #$20
L7649:  BHS  L764D                  ;IFLO
L764B:  LDB  #$00
L764D:  STB  SC_ADT                 ;USE TIMER FOR BRIGHTNESS
L7650:  LSRB
L7651:  LDA  #(VGCOPC/$100)+VGCYLW
L7653:  STD  ,Y++
L7655:  LDD  #VGRW5&$1FFF           ;Y POS
L7658:  STD  ,Y++
L765A:  LDD  #(VGLIML+(2*VGS_CW))&$1FFF ;X POS
L765D:  STD  ,Y++
L765F:  LDA  #$05                   ;SUPRESS 5 LEADING ZEROES
L7661:  STA  BT_SUP
L7663:  LDX  #SC_ADD-1              ;X-->8 DIGIT FIELD, EVEN THO ONLY LO 6 SHOW
L7666:  JSR  VW6DIG                 ;6 DIGITS WITH COMMAS
L7669:  LDD  #VGCNTR
L766C:  STD  ,Y++
;SHOW WAVE NUMBER
L766E:  LDD  #(VGCGRN*$100)+VGCOPC  ;COLOR BRITE
L7671:  STD  ,Y++
L7673:  LDD  #VGRW1&$1FFF           ;Y UP HI
L7676:  STD  ,Y++
L7678:  LDD  #(VGLIMR-((2+5)*VGS_CW))&$1FFF ;X RIGHT
L767B:  STD  ,Y++
L767D:  LDA  #$01                   ;ZERO SUPPRES TOP 1 DIGIT
L767F:  STA  BT_SUP
L7681:  LDA  GM_DWAV                ;BCD WAVE NUMBER
L7684:  JSR  VWBYTE
L7687:  LDD  #VGCNTR
L768A:  STD  ,Y++
L768C:  RTS

;------------------------------------------------------------------------------
; VWMTWR - VEIW MESSAGES RELATED TO TOWERS
;------------------------------------------------------------------------------
VWMTWR:
L768D:  LDA  GD_WAV
L7690:  BLE  L76FC                  ;IFGT  LOWEST WAVE GETS NO MESSAGES ( NO TOWERS )
L7692:  LDA  GD_TWL
L7695:  BEQ  VWMTWZ                 ;IFNE  ?MORE TOWERS TO HIT?
L7697:  LDA  FRAMEL
L7699:  ANDA #$30
L769B:  BEQ  L76CE                  ;IFNE  ?SHOW NEXT TOWERS WORTH?
L769D:  LDB  #MS_NXT                ;"XXXXX POINTS NEXT TOWER"
L769F:  JSR  DOMESS
L76A2:  LDD  #VGCOLR+(VGCGRN*$100)
L76A5:  STD  ,Y++
L76A7:  LDD  #VGRW7&$1FFF           ;Y POS
L76AA:  STD  ,Y++
L76AC:  LDD  #$1ED0                 ;X POS
L76AF:  STD  ,Y++
L76B1:  LDA  #$04                   ;SUPRESS 4 ZEROES
L76B3:  STA  BT_SUP
L76B5:  LDA  TWRMUL
L76B8:  JSR  VWBYTE
L76BB:  LDA  TWRMUL+1
L76BE:  JSR  VWBYTE
L76C1:  LDA  TWRMUL+2
L76C4:  JSR  VWBYTE
L76C7:  LDD  #VGCNTR
L76CA:  STD  ,Y++
L76CC:  BRA  VWMTWZ                 ;ELSE  ELSE SHOW ALL TOWERS WORTH
L76CE:  LDB  #MS_RWD                ;"50,000 FOR SHOOTING ALL TOWERS"
L76D0:  JSR  DOMESS

;------------------------------------------------------------------------------
; VWMTWZ - MESSAGES STILL SEEN IN TRENCH
;------------------------------------------------------------------------------
VWMTWZ:
L76D3:  LDA  GD_WAV                 ;NO MESSAGES IN FIRST WAVE TRENCH
L76D6:  BLE  L76FC                  ;IFGT
L76D8:  LDD  #MS_TWR                ;"TOWERS"
L76DB:  JSR  DOMESS
L76DE:  LDD  #VGCOLR+(VGCGRN*$100)
L76E1:  STD  ,Y++
L76E3:  LDD  #VGRW6&$1FFF
L76E6:  STD  ,Y++
L76E8:  LDD  #(VGLIMR-(5*VGS_CW))&$1FFF
L76EB:  STD  ,Y++
L76ED:  LDA  #$01
L76EF:  STA  BT_SUP
L76F1:  LDA  GD_TWL                 ;TOWERS LEFT
L76F4:  JSR  VWBYTE
L76F7:  LDD  #VGCNTR
L76FA:  STD  ,Y++
L76FC:  LDA  Q_ATP
L76FF:  BEQ  L7706                  ;IFNE  GOT THEM ALL, PROCLAIM SUCH
L7701:  LDB  #MS_ATP                ;"ALL TOWER TOPS"
L7703:  JSR  DOMESS
L7706:  RTS

;------------------------------------------------------------------------------
; VWMOVR - VIEW GROWING GAME OVER MESSAGE
;------------------------------------------------------------------------------
VWMOVR:
L7707:  LDA  PH_TIM+1
L770A:  CMPA #$20                   ;STOP GROWING
L770C:  BLS  L7710                  ;IFHI
L770E:  LDA  #$20
L7710:  LDB  #$06                   ;EXPAND AT 6 PER FRAME
L7712:  MUL
L7713:  NEGB
L7714:  ADDB #$C0                   ;SMALL IS 0C0, LARGE IS 000
L7716:  LDA  #(VGSCAL&$F000)/$100   ;FRONT PART OF SCALE INSTRUCTION
L7718:  STD  ,Y++
L771A:  LDB  #MS_GO1                ;"GAME OVER" IN CENTER OF SCREEN
L771C:  JSR  DOMESS
L771F:  RTS

;------------------------------------------------------------------------------
; BINBCD - BIN TO BCD, BCD TO BIN, AND VIEW BYTES
;   CONVERT POSITIVE BINARY TO BCD
;   INPUT BINARY IN D, NUMBER OF SHIFTS IN X
;   OUTPUT IS BCD IN BCD,BCD+1,BCD+2
;------------------------------------------------------------------------------
BINBCD:
L7720:  STD  BIN
L7723:  LDD  #$0000
L7726:  STD  BCD
L7729:  STA  BCD+2
L772C:  ASL  BIN+1
L772F:  ROL  BIN
L7732:  LDA  BCD+2
L7735:  ADCA BCD+2
L7738:  DAA
L7739:  STA  BCD+2
L773C:  LDA  BCD+1
L773F:  ADCA BCD+1
L7742:  DAA
L7743:  STA  BCD+1
L7746:  ROL  BCD
L7749:  LEAX -$1,X
L774B:  BNE  L772C                  ;EQEND
L774D:  RTS

;------------------------------------------------------------------------------
; BCDBIN - CONVERT 2 POSITIVE BCD DIGITS TO BINARY
;   INPUT A, OUTPUT BIN
;------------------------------------------------------------------------------
BCDBIN:
L774E:  STA  BIN
L7751:  ANDA #$F0                   ;USE FIRST NYBBLE
L7753:  LDB  #$A0
L7755:  MUL                         ;ACC A CONTAINS FIRST DIGIT*10.
L7756:  LDB  BIN
L7759:  ANDB #$0F
L775B:  STB  BIN
L775E:  ADDA BIN
L7761:  STA  BIN
L7764:  RTS

;------------------------------------------------------------------------------
; VWDTHA - VIEW DETH STAR
;   VIEW DETH STAR, VERSION A (MINIATURE)
;------------------------------------------------------------------------------
VWDTHA:
L7765:  LDD  (MS_AX+M_U1)&$FFFF     ;X POSITION AT FAR(4000,0,0) DISTANCE
L7768:  BLE  L77A3                  ;IFGT  ?IN FRONT OF PLAYER?
L776A:  STD  M_DVD                  ;PREPARE DIVIDER,PERSPECTIVE
L776D:  LDD  (MS_AY+M_U1)&$FFFF
L7770:  STD  M_YP
L7773:  TSTA                        ;ABSD
L7774:  BPL  L777A
L7776:  COMA
L7777:  NEGB
L7778:  SBCA #$FF
L777A:  SUBD (MS_AX+M_U1)&$FFFF
L777D:  BGE  L77A3                  ;IFLT  ?Y WITHIN X FIELD OF VIEW?
L777F:  LDD  (MS_AZ+M_U1)&$FFFF
L7782:  STD  M_ZP                   ;ASSUME OK, THEN TEST
L7785:  TSTA                        ;ABSD
L7786:  BPL  L778C
L7788:  COMA
L7789:  NEGB
L778A:  SBCA #$FF
L778C:  SUBD (MS_AX+M_U1)&$FFFF
L778F:  BGE  L77A3                  ;IFLT  ?Z WITHIN X FIELD OF VIEW?
L7791:  JSR  OBJCEN                 ;THEN PROCESS THE CENTER POINT
L7794:  LDD  #VGSCAL+$100
L7797:  STD  ,Y++
L7799:  LDD  #VJBMIN                ;GET JSRL TO MINNY BASE OF DETH STAR
L779C:  STD  ,Y++
L779E:  LDD  #VGSCAL                ;RESTORE BASE
L77A1:  STD  ,Y++
L77A3:  RTS

;------------------------------------------------------------------------------
; VWDTHB - VIEW DEATH STAR, VERSION B (WITH SCALING)
;------------------------------------------------------------------------------
VWDTHB:
L77A4:  LDD  (MS_AX+M_U1)&$FFFF     ;X POSITION AT FAR(4000,0,0) DISTANCE
L77A7:  BLE  L77D3                  ;IFGT  ?IN FRONT OF PLAYER?
L77A9:  STD  M_DVD                  ;PREPARE DIVIDER,PERSPECTIVE
L77AC:  LDD  (MS_AY+M_U1)&$FFFF
L77AF:  STD  M_YP
L77B2:  TSTA                        ;ABSD
L77B3:  BPL  L77B9
L77B5:  COMA
L77B6:  NEGB
L77B7:  SBCA #$FF
L77B9:  SUBD (MS_AX+M_U1)&$FFFF
L77BC:  BGE  L77D3                  ;IFLT  ?Y WITHIN X FIELD OF VIEW?
L77BE:  LDD  (MS_AZ+M_U1)&$FFFF
L77C1:  STD  M_ZP                   ;ASSUME OK, THEN TEST
L77C4:  TSTA                        ;ABSD
L77C5:  BPL  L77CB
L77C7:  COMA
L77C8:  NEGB
L77C9:  SBCA #$FF
L77CB:  SUBD (MS_AX+M_U1)&$FFFF
L77CE:  BGE  L77D3                  ;IFLT  ?Z WITHIN X FIELD OF VIEW?
L77D0:  JSR  DTHVW
L77D3:  RTS

;------------------------------------------------------------------------------
; DTHVW - [note] Draw the Deth Star for VWDTHB: OBJCEN to its center, then the circle, trench, dish, inside and farm
;   stamps at scale DT_SCL and the city stamps (picked by SP_WAV bit 0) at a larger scale. Y-->VG list
;------------------------------------------------------------------------------
DTHVW:
L77D4:  JSR  OBJCEN                 ;THEN PROCESS THE CENTER POINT
L77D7:  LDD  -$4,Y                  ;SAVE CENTER POINT LOCATION
L77D9:  STD  TMPVY
L77DB:  LDD  -$2,Y
L77DD:  STD  TMPVX
L77DF:  LDD  DT_SCL
L77E1:  STD  TMPSCL
L77E3:  LDU  #VJBCIR                ;CIRCLE
L77E6:  JSR  DTHVW_104
L77E9:  LDU  #VJBTRN                ;TRENCH
L77EC:  JSR  DTHVW_100
L77EF:  LDU  #VJBDSH                ;DISH
L77F2:  JSR  DTHVW_100
L77F5:  LDU  #VJBNSD                ;INSIDE
L77F8:  JSR  DTHVW_100
L77FB:  LDU  #VJBFRM                ;FARM
L77FE:  JSR  DTHVW_100
L7801:  LDD  DT_SCL
L7803:  SUBA #$03                   ;SCALE UP THE SIZE OF THE CITY BLOCKS
L7805:  CMPD #VGSCAL-$200
L7809:  BHS  L780E                  ;IFLO  NO LONGER A SCALE INSTRUCTION
L780B:  LDD  #VGSCAL-$200           ;MAX SIZE
L780E:  STD  TMPSCL
L7810:  CMPA #(VGSCAL-$200)/$100    ;BINARY SCALE = 00?
L7812:  BNE  L7819                  ;IFEQ  YES
L7814:  LDD  #(((VGCYLW*$100)+VGCOLR)&$FF00)|$60 ;BRIGHTER FOR BINARY=0
L7817:  BRA  L781C                  ;ELSE  NOT BINARY SCALE OF 0
L7819:  LDD  #(((VGCYLW*$100)+VGCOLR)&$FF00)|$30 ;CITY LIGHTS
L781C:  STD  ,Y++
L781E:  LDA  SP_WAV
L7821:  BITA #$01
L7823:  BNE  L782A                  ;IFEQ
L7825:  LDU  #VJUB1
L7828:  BRA  L7839                  ;ELSE
L782A:  LDU  #VJUB2                 ;CITIES 2,3, AND 4 GO TOGETHER
L782D:  JSR  DTHVW_100
L7830:  LDU  #VJUB3
L7833:  JSR  DTHVW_100
L7836:  LDU  #VJUB4
L7839:  JSR  DTHVW_100
L783C:  LDA  SP_WAV
L783F:  BITA #$01
L7841:  BNE  L7848                  ;IFEQ
L7843:  LDU  #VJLB1
L7846:  BRA  L7857                  ;ELSE
L7848:  LDU  #VJLB2                 ;CITIES 2,3, AND 4 GO TOGETHER
L784B:  JSR  DTHVW_100
L784E:  LDU  #VJLB3
L7851:  JSR  DTHVW_100
L7854:  LDU  #VJLB4
L7857:  JSR  DTHVW_100
L785A:  RTS

DTHVW_100:       ;DRAW TO CENTER, SCALE, THEN DO STAMP
;U:=STAMP
L785B:  LDD  TMPVY                  ;CENTER OF PLANET ON SCREEN
L785D:  STD  ,Y++
L785F:  LDD  TMPVX
L7861:  STD  ,Y++

DTHVW_104:
L7863:  LDD  TMPSCL                 ;SCALE THE STAMP
L7865:  STD  ,Y++
L7867:  STU  ,Y++                   ;VIEW THE STAMP
L7869:  RTS

;------------------------------------------------------------------------------
; SNVW - SNVW VIEW ALIEN SHIP
;------------------------------------------------------------------------------
SNVW:
L786A:  LDX  #ALIEN                 ;SHIP PARAMS

SNVW_10:         ;---LOOP THRU SHIPS
L786D:  STX  S2_PRM
L786F:  LDA  AS_TYP,X
L7871:  BEQ  SNVW_90                ;?SOMEWHAT ALIVE?
L7873:  JSR  S2VW                   ;VIEW THE SHIP

SNVW_90:
L7876:  LDX  S2_PRM                 ;NEXT SHIP
L7878:  LEAX AS_IZE,X
L787B:  CMPX #ALIENZ
L787E:  BLO  SNVW_10

RTS1:
SNVW_96:
L7880:  RTS

;------------------------------------------------------------------------------
; S2VW - VIEW THE SHIP  (comment at the call)
;------------------------------------------------------------------------------
S2VW:
L7881:  LDX  S2_PRM
L7883:  CLRA
L7884:  LDB  AS_BIC,X
L7886:  ADDB #$03
L7888:  STD  M_BIC
L788B:  LDA  #MS_PSB2
L788D:  JSR  MGOWT
L7890:  LDA  M_XP
L7893:  LSLA                        ;-4000<X<4000 FOR VALID SQUARING
L7894:  BVS  S2VW_12
L7896:  LDA  M_YP
L7899:  LSLA
L789A:  BVS  S2VW_12
L789C:  LDA  M_ZP
L789F:  LSLA
L78A0:  BVS  S2VW_12
L78A2:  LDD  M_XPS                  ;CHECK FOR COLLISION
L78A5:  ADDD M_YPS
L78A8:  ADDD M_ZPS
L78AB:  TFR  D,U

S2VW_114:
L78AD:  CMPU #$0900
L78B1:  BHI  L78BB                  ;IFLS  ?PLAYER AT MIDDISTANCE?
L78B3:  LDD  AS_CHST,X
L78B6:  ORA  #((CS_PM&$FF00)/$100)  ;CHSET C$PM  THEN SET PLAYER MIDDLE DISTANCE
L78B8:  STD  AS_CHST,X
L78BB:  CMPU #$0100
L78BF:  BHI  L78C9                  ;IFLS  ?PLAYER NEARBY?
L78C1:  LDD  AS_CHST,X
L78C4:  ORA  #((CS_PN&$FF00)/$100)  ;CHSET C$PN  THEN SET PLAYER NEAR
L78C6:  STD  AS_CHST,X
L78C9:  CMPU #$00A0
L78CD:  BHI  L78FF                  ;IFLS  ?PLAYER NEARBY?
L78CF:  LDA  Q_PBB
L78D2:  BNE  L78E4                  ;IFEQ  ?NO SHIP CURRENTLY PASSING BY?
L78D4:  LDA  AS_BIC,X
L78D6:  STA  Q_PBB                  ;THEN START THIS SHIP PASSING BY
L78D9:  JSR  SPKELE                 ;ELEPHANT PASSBY
L78DC:  JSR  AUDPB                  ;APPROACH OF PASSBY SOUND
L78DF:  STU  Q_PBD                  ;INIT CURRENT DISTANCE
L78E2:  BRA  L78FD                  ;ELSE  ELSE IS BIC OF SHIP IS PASSING BY
L78E4:  CMPA AS_BIC,X
L78E6:  BNE  L78FD                  ;IFEQ  ?IS THIS THE SHIP CURRENTLY PASSINGBY?
L78E8:  CMPU Q_PBD                  ;THEN CHECK FOR CHANGES IN DISTANCE AWAY
L78EC:  BGT  L78F3                  ;IFLE  ?NOT MOVING AWAY YET? NOTE SIGNED FLAG TEST
L78EE:  STU  Q_PBD                  ;THEN SAVE THIS LATEST DISTANCE
L78F1:  BRA  L78FD                  ;ELSE  ELSE IS DEFINITLY MOVING AWAY
L78F3:  BLO  L78FD                  ;IFHS  ?MINUS FLAG STILL CLEAR? ONE TIME ONLY
L78F5:  LDA  #$FF
L78F7:  STA  Q_PBD                  ;SET DISTANCE TO MINUS, END PASSBY FLAG
L78FA:  JSR  AUDPS                  ;SHORT PASSBY EXIT DOPPLER SOUND
L78FD:  BRA  S2VW_12                ;ELSE  ELSE NOT NEAR TO PLAYER
L78FF:  LDA  AS_BIC,X
L7901:  CMPA Q_PBB
L7904:  BNE  S2VW_12                ;IFEQ  ?WAS THIS THE SHIP DOING A PASSBY?
L7906:  CLR  Q_PBB                  ;THEN PREPARE FOR NEXT SHIP

S2VW_12:
L7909:  LDD  M_XP
L790C:  CMPD #$0010
L7910:  LBLE RTS1
L7914:  CMPD #$7F00
L7918:  LBHI RTS1

S2VW_19:         ;----SAVE NEW X
L791C:  STD  M_DVD
L791F:  STD  M_XT
L7922:  LDD  M_YP
L7925:  STD  M_YT
L7928:  LDD  M_YPS
L792B:  SUBD M_XPS                  ;X SQUARED
L792E:  LBHS RTS1                   ;B OUT OF VIEW

S2VW_28:
L7932:  LDD  M_ZP
L7935:  STD  M_ZT
L7938:  LDD  M_ZPS
L793B:  SUBD M_XPS                  ;X SQUARED
L793E:  LBHS RTS1

S2VW_31:
L7942:  LDX  S2_PRM
L7944:  LDD  AS_CHST,X
L7947:  ORA  #((CS_PV&$FF00)/$100)  ;CHSET C$PV  WITHIN PLAYERS VIEW SCREEN
L7949:  STD  AS_CHST,X
L794C:  LDA  Q_RTHV
L794F:  BNE  L7972                  ;IFEQ  ?DARTH NOT YET VISIBLE?
L7951:  LDA  AS_PIC,X
L7953:  CMPA #TDS_RTH
L7955:  BNE  L7972                  ;IFEQ  ?IS THIS DARTH?
L7957:  INC  Q_RTHV                 ;ONE TIME ONLY
L795A:  LDA  SP_WAV
L795D:  LSRA
L795E:  BCS  L796F                  ;IFCC  ?EVEN , SELECT A LEVEL FIRST WAVE?
L7960:  LDA  P_RND1
L7963:  BPL  L796A                  ;IFMI  ?RANDOM?
L7965:  JSR  SPKSTA                 ;STAY IN ATTACK FORMATION
L7968:  BRA  L796D                  ;ELSE
L796A:  JSR  SPKIMO                 ;I'M ON THE LEADER
L796D:  BRA  L7972                  ;ELSE  ELSE ODD, HAVE LOWER ENERGY NOW
L796F:  JSR  SPKHAV                 ;I HAVE YOU NOW
L7972:  LDA  AS_BIC,X
L7974:  JSR  IS2UV                  ;DOWNLOAD SHIP 2 UNIT VECTORS
;SHIP 2 VISIBLE
L7977:  JSR  OBJCEN                 ;PROCESS CENTER OF SHIP
L797A:  LDD  #$0050                 ;JUST TRY IT -- SHUT DOWN CPU AND TEST
L797D:  STD  M_YP                   ;GET SHIP SIZE
L7980:  LDA  #MS_PERS
L7982:  JSR  MGOWT
L7985:  LDD  M_YP
L7988:  ADDD #$000A                 ;ADDIN CURSOR SIZE
L798B:  STD  TMPSIZ_4801
L798D:  LDD  BJ_CX                  ;OBJECT CENTER
L798F:  SUBD LZ_CX                  ;LAZAR CENTER
L7991:  BPL  L7997                  ;IFMI
L7993:  COMA                        ;NEGD  ABSD
L7994:  NEGB
L7995:  SBCA #$FF
L7997:  STD  TMPXD                  ;SAVE X DISTANCE
L7999:  STD  TMPOCT_4803            ;PREPARE FOR OCTAGON COLLISION DETECT
L799B:  LDD  BJ_CY
L799D:  SUBD LZ_CY                  ;NOW CHECKING Y COORDS
L799F:  BPL  L79A5                  ;IFMI
L79A1:  COMA                        ;NEGD
L79A2:  NEGB
L79A3:  SBCA #$FF
L79A5:  STD  TMPYD                  ;SAVE Y DISTANCE
L79A7:  ADDD TMPOCT_4803
L79A9:  STD  TMPOCT_4803            ;OCTAGON CHECK
L79AB:  LDD  TMPXD
L79AD:  SUBD TMPSIZ_4801
L79AF:  BGT  L79CF                  ;IFLE  LE FOR LIBERALITY
L79B1:  LDD  TMPYD
L79B3:  SUBD TMPSIZ_4801
L79B5:  BGT  L79CF                  ;IFLE  ?WITHIN Y ALSO?
L79B7:  LDD  TMPSIZ_4801
L79B9:  LSRA                        ;LSRD
L79BA:  RORB
L79BB:  ADDD TMPSIZ_4801            ;MAKE 1.5 FOR OCTAGON
L79BD:  SUBD TMPOCT_4803
L79BF:  BLT  L79CF                  ;IFGE  ?ALSO WITHIN OCTAGON?
L79C1:  LDD  M_XT                   ;THEN SEE IF WE ARE THE CLOSEST ALIEN
L79C4:  CMPD CL_ADS                 ;SHIP DISTANCE
L79C7:  BHS  L79CF                  ;IFLO  ?ALSO THE NEAREST SHIP SO FAR?
L79C9:  STD  CL_ADS                 ;REMEMBER ITS DISTANCE
L79CB:  LDX  S2_PRM                 ;THEN WE GOT A HIT
L79CD:  STX  CL_AP                  ;RECORD WHO WE ARE
L79CF:  LDD  TMPSIZ_4801            ;?AIM IS NEARING ALIEN?
L79D1:  ADDD TMPSIZ_4801
L79D3:  ADDD TMPSIZ_4801            ;ALLOW LARGER WARNING AREA
L79D5:  SUBD TMPOCT_4803
L79D7:  BLO  S2VW_86                ;IFHS
L79D9:  LDX  S2_PRM
L79DB:  LDA  AS_TYP,X
L79DD:  CMPA #$01
L79DF:  BNE  S2VW_86                ;?ALIVE?
L79E1:  LDD  AS_CHST,X
L79E4:  ORA  #((CS_PS&$FF00)/$100)  ;CHSET C$PS  STATUS: ALIEN IN PLAYER SITES
L79E6:  STD  AS_CHST,X

S2VW_86:
;SET BRITENESS
;ELSE HANDLE GLOW
L79E9:  LDX  S2_PRM
L79EB:  LDB  AS_GLW,X
L79ED:  LDU  #TVWCL                 ;GET GLOW COLORS
L79F0:  LSLB
L79F1:  LDD  B,U
L79F3:  STD  ,Y++

S2VW_55:
L79F5:  LDA  #MS_CNCT
L79F7:  JSR  MGOWT
L79FA:  LDB  AS_PIC,X
L79FC:  JSR  OBJBPNT                ;PROCESS OBJECT POINTS
L79FF:  JSR  OBJDRW                 ;DRAW THE OBJECT LINES
L7A02:  LDD  #VGCNTR                ;CENTER
L7A05:  STD  ,Y++

S2VW_90:
L7A07:  RTS

TVWCL:           ;VIEW SHIP COLOR BRITE IF HIT
L7A08:  .word (VGCOPC&$F000)+(($82&$F)*$100)+($82&$F0) ;TVWBYT 082,037,82,37,82,47,82,47
L7A0A:  .word (VGCOPC&$F000)+(($37&$F)*$100)+($37&$F0)
L7A0C:  .word (VGCOPC&$F000)+(($82&$F)*$100)+($82&$F0)
L7A0E:  .word (VGCOPC&$F000)+(($37&$F)*$100)+($37&$F0)
L7A10:  .word (VGCOPC&$F000)+(($82&$F)*$100)+($82&$F0)
L7A12:  .word (VGCOPC&$F000)+(($47&$F)*$100)+($47&$F0)
L7A14:  .word (VGCOPC&$F000)+(($82&$F)*$100)+($82&$F0)
L7A16:  .word (VGCOPC&$F000)+(($47&$F)*$100)+($47&$F0)
L7A18:  .word (VGCOPC&$F000)+(($82&$F)*$100)+($82&$F0) ;TVWBYT 082,057,82,057,082,067,082,067
L7A1A:  .word (VGCOPC&$F000)+(($57&$F)*$100)+($57&$F0)
L7A1C:  .word (VGCOPC&$F000)+(($82&$F)*$100)+($82&$F0)
L7A1E:  .word (VGCOPC&$F000)+(($57&$F)*$100)+($57&$F0)
L7A20:  .word (VGCOPC&$F000)+(($82&$F)*$100)+($82&$F0)
L7A22:  .word (VGCOPC&$F000)+(($67&$F)*$100)+($67&$F0)
L7A24:  .word (VGCOPC&$F000)+(($82&$F)*$100)+($82&$F0)
L7A26:  .word (VGCOPC&$F000)+(($67&$F)*$100)+($67&$F0)
L7A28:  .word (VGCOPC&$F000)+(($82&$F)*$100)+($82&$F0) ;TVWBYT 082,077,082,077,082,087,082,087
L7A2A:  .word (VGCOPC&$F000)+(($77&$F)*$100)+($77&$F0)
L7A2C:  .word (VGCOPC&$F000)+(($82&$F)*$100)+($82&$F0)
L7A2E:  .word (VGCOPC&$F000)+(($77&$F)*$100)+($77&$F0)
L7A30:  .word (VGCOPC&$F000)+(($82&$F)*$100)+($82&$F0)
L7A32:  .word (VGCOPC&$F000)+(($87&$F)*$100)+($87&$F0)
L7A34:  .word (VGCOPC&$F000)+(($82&$F)*$100)+($82&$F0)
L7A36:  .word (VGCOPC&$F000)+(($87&$F)*$100)+($87&$F0)
L7A38:  .word (VGCOPC&$F000)+(($82&$F)*$100)+($82&$F0) ;TVWBYT 082,087,082,087,082,087,0C7,0C7
L7A3A:  .word (VGCOPC&$F000)+(($87&$F)*$100)+($87&$F0)
L7A3C:  .word (VGCOPC&$F000)+(($82&$F)*$100)+($82&$F0)
L7A3E:  .word (VGCOPC&$F000)+(($87&$F)*$100)+($87&$F0)
L7A40:  .word (VGCOPC&$F000)+(($82&$F)*$100)+($82&$F0)
L7A42:  .word (VGCOPC&$F000)+(($87&$F)*$100)+($87&$F0)
L7A44:  .word (VGCOPC&$F000)+(($C7&$F)*$100)+($C7&$F0)
L7A46:  .word (VGCOPC&$F000)+(($C7&$F)*$100)+($C7&$F0)

;------------------------------------------------------------------------------
; NW1SHP - RESET UNITVECTORS ALSO
;------------------------------------------------------------------------------
NW1SHP:
L7A48:  LDU  #M_S1
L7A4B:  JSR  UNITV
L7A4E:  LDD  #$0000
L7A51:  STD  MS_TX+M_S1
L7A54:  STD  MS_TY+M_S1
L7A57:  STD  MS_TZ+M_S1

;------------------------------------------------------------------------------
; OLD1SHP - USE OLD UNIT VECTORS
;------------------------------------------------------------------------------
OLD1SHP:
L7A5A:  LDD  #$0000
L7A5D:  STA  S_GLW
L7A5F:  STA  S_ROL
L7A61:  STA  VG_LON
L7A63:  STA  LZ_ON                  ;TURN OFF LAZARS
L7A65:  STA  LZ_EDG
L7A67:  STA  LZ_HIT
L7A69:  STD  GD_ACT
L7A6B:  STA  >RHS_RSD+RHEOR         ;SPECIAL ROLL
L7A6E:  STA  >RHS_RSD+RHEOP         ;CLEAR OUT MAGIC RESIDUE
L7A71:  STA  >RHS_RSD+RHEOY
L7A74:  STD  >RHS_POS+RHEOY         ;RESTART IN CENTER OF SCREEN
L7A77:  STD  >RHS_POS+RHEOP
L7A7A:  RTS

;==============================================================================
; MODULE WSFIL0   WSFIL0.MAC
;==============================================================================

;.SBTTL STAR WARS FILLER FOR ROM 0

CHKSM0:
L7A7B:  .word $F79D                 ;(src: .WORD PCKS0)  rev 2 patch: the checksum word; rev 1 and the source's PCKS0 are $F79C

MORSE0:
L7A7D:  .byte $02, $BB, $5A, $30    ;"COPYRIGHT 1983 ATARI" IN MORSE CODE
L7A81:  .byte $5F, $EE, $0D, $A8    ;1=DASH, 0=DOT,RIGHT JUSTIFY

FILL0:
L7A85:  .byte $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF ;.REPT 73  FILL WITH FF'S
L7A8D:  .byte $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
L7A95:  .byte $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
L7A9D:  .byte $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
L7AA5:  .byte $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
L7AAD:  .byte $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
L7AB5:  .byte $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
L7ABD:  .byte $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
L7AC5:  .byte $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
L7ACD:  .byte $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
L7AD5:  .byte $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
L7ADD:  .byte $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
L7AE5:  .byte $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
L7AED:  .byte $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
L7AF5:  .byte $FF, $FF, $FF

CPYRT0:
L7AF8:  .byte $43, $4F, $50, $59, $52, $49, $47, $48 ;.ASCII /COPYRIGHT 1983 ATARI/
L7B00:  .byte $54, $20, $31, $39, $38, $33, $20, $41
L7B08:  .byte $54, $41, $52, $49
L7B0C:  .byte $B8, $AD, $BA, $B8, $DF, $AD, $B6, $A9 ;.IRPC .A,<GREG RIVERA DID IT>
L7B14:  .byte $BA, $AD, $BE, $DF, $BB, $B6, $BB, $DF
L7B1C:  .byte $B6, $AB

;==============================================================================
; MODULE WSBASE   WSBASE.MAC
;   BASE STAR(DEATH STAR FRAMEWORK)
;==============================================================================

;.SBTTL PIES TRENCH SEQUENCES

PIE1:            ;MOSTLY GUNS.
L7B1E:  .word TWDG10                ;.PIE 10,95,54,95,04,95,42,95
L7B20:  .word TWDG95
L7B22:  .word TWDG54
L7B24:  .word TWDG95
L7B26:  .word TWDG04
L7B28:  .word TWDG95
L7B2A:  .word TWDG42
L7B2C:  .word TWDG95
L7B2E:  .word TWDG41                ;.PIE 41,95,53,95,43,95,42,98
L7B30:  .word TWDG95
L7B32:  .word TWDG53
L7B34:  .word TWDG95
L7B36:  .word TWDG43
L7B38:  .word TWDG95
L7B3A:  .word TWDG42
L7B3C:  .word TWDG98

PIE2:            ;TOP AND BOOTOM EXTREMES ONLY
L7B3E:  .word TWDG10                ;.PIE 10,95,04,93,07,93,31,95
L7B40:  .word TWDG95
L7B42:  .word TWDG04
L7B44:  .word TWDG93
L7B46:  .word TWDG07
L7B48:  .word TWDG93
L7B4A:  .word TWDG31
L7B4C:  .word TWDG95
L7B4E:  .word TWDG21                ;.PIE 21,95,22,95,41,94,07,98
L7B50:  .word TWDG95
L7B52:  .word TWDG22
L7B54:  .word TWDG95
L7B56:  .word TWDG41
L7B58:  .word TWDG94
L7B5A:  .word TWDG07
L7B5C:  .word TWDG98

PIE3:            ;SMOOTH FLYING WITH GOOD VISIBILITY
L7B5E:  .word TWDG10                ;.PIE 10,95,02,93,08,95,28,96
L7B60:  .word TWDG95
L7B62:  .word TWDG02
L7B64:  .word TWDG93
L7B66:  .word TWDG08
L7B68:  .word TWDG95
L7B6A:  .word TWDG28
L7B6C:  .word TWDG96
L7B6E:  .word TWDG27                ;.PIE 27,92,31,93,12,94,53,99
L7B70:  .word TWDG92
L7B72:  .word TWDG31
L7B74:  .word TWDG93
L7B76:  .word TWDG12
L7B78:  .word TWDG94
L7B7A:  .word TWDG53
L7B7C:  .word TWDG99

PIE4:            ;ROLLERS -- FULL UP-DOWN FLYING REQUIRED
L7B7E:  .word TWDG10                ;.PIE 10,95,05,93,17,97,14,94
L7B80:  .word TWDG95
L7B82:  .word TWDG05
L7B84:  .word TWDG93
L7B86:  .word TWDG17
L7B88:  .word TWDG97
L7B8A:  .word TWDG14
L7B8C:  .word TWDG94
L7B8E:  .word TWDG34                ;.PIE 34,94,44,93,17,97,14,99
L7B90:  .word TWDG94
L7B92:  .word TWDG44
L7B94:  .word TWDG93
L7B96:  .word TWDG17
L7B98:  .word TWDG97
L7B9A:  .word TWDG14
L7B9C:  .word TWDG99

PIE5:            ;SINGLE CITY
L7B9E:  .word TWDG10                ;.PIE 10,95,44,93,33,94,27,92
L7BA0:  .word TWDG95
L7BA2:  .word TWDG44
L7BA4:  .word TWDG93
L7BA6:  .word TWDG33
L7BA8:  .word TWDG94
L7BAA:  .word TWDG27
L7BAC:  .word TWDG92
L7BAE:  .word TWDG28                ;.PIE 28,96,12,94,11,94,01,99
L7BB0:  .word TWDG96
L7BB2:  .word TWDG12
L7BB4:  .word TWDG94
L7BB6:  .word TWDG11
L7BB8:  .word TWDG94
L7BBA:  .word TWDG01
L7BBC:  .word TWDG99

PIE6:            ;ROLLERS -- FULL UP-DOWN FLYING REQUIRED
L7BBE:  .word TWDG10                ;.PIE 10,95,05,93,33,94,23,93
L7BC0:  .word TWDG95
L7BC2:  .word TWDG05
L7BC4:  .word TWDG93
L7BC6:  .word TWDG33
L7BC8:  .word TWDG94
L7BCA:  .word TWDG23
L7BCC:  .word TWDG93
L7BCE:  .word TWDG34                ;.PIE 34,94,14,94,31,93,17,99
L7BD0:  .word TWDG94
L7BD2:  .word TWDG14
L7BD4:  .word TWDG94
L7BD6:  .word TWDG31
L7BD8:  .word TWDG93
L7BDA:  .word TWDG17
L7BDC:  .word TWDG99

PIE7:            ;LOTS OF HALVES
L7BDE:  .word TWDG10                ;.PIE 10,95,26,97,09,96,19,93
L7BE0:  .word TWDG95
L7BE2:  .word TWDG26
L7BE4:  .word TWDG97
L7BE6:  .word TWDG09
L7BE8:  .word TWDG96
L7BEA:  .word TWDG19
L7BEC:  .word TWDG93
L7BEE:  .word TWDG23                ;.PIE 23,93,32,92,45,93,13,29
L7BF0:  .word TWDG93
L7BF2:  .word TWDG32
L7BF4:  .word TWDG92
L7BF6:  .word TWDG45
L7BF8:  .word TWDG93
L7BFA:  .word TWDG13
L7BFC:  .word TWDG29

PIE8:            ;LOTS OF ROLLERS
L7BFE:  .word TWDG10                ;.PIE 10,95,03,94,37,96,06,96
L7C00:  .word TWDG95
L7C02:  .word TWDG03
L7C04:  .word TWDG94
L7C06:  .word TWDG37
L7C08:  .word TWDG96
L7C0A:  .word TWDG06
L7C0C:  .word TWDG96
L7C0E:  .word TWDG25                ;.PIE 25,94,16,94,20,94,18,29
L7C10:  .word TWDG94
L7C12:  .word TWDG16
L7C14:  .word TWDG94
L7C16:  .word TWDG20
L7C18:  .word TWDG94
L7C1A:  .word TWDG18
L7C1C:  .word TWDG29

PIE9:            ;JOGS AND SLANTS
L7C1E:  .word TWDG10                ;.PIE 10,95,15,97,24,97,30,97
L7C20:  .word TWDG95
L7C22:  .word TWDG15
L7C24:  .word TWDG97
L7C26:  .word TWDG24
L7C28:  .word TWDG97
L7C2A:  .word TWDG30
L7C2C:  .word TWDG97
L7C2E:  .word TWDG36                ;.PIE 36,96,55,97,37,97,43,29
L7C30:  .word TWDG96
L7C32:  .word TWDG55
L7C34:  .word TWDG97
L7C36:  .word TWDG37
L7C38:  .word TWDG97
L7C3A:  .word TWDG43
L7C3C:  .word TWDG29

PIE10:           ;EASY ROLLERS-JOGS-HARD ROLLERS
L7C3E:  .word TWDG10                ;.PIE 10,95,05,93,17,97,24,97
L7C40:  .word TWDG95
L7C42:  .word TWDG05
L7C44:  .word TWDG93
L7C46:  .word TWDG17
L7C48:  .word TWDG97
L7C4A:  .word TWDG24
L7C4C:  .word TWDG97
L7C4E:  .word TWDG55                ;.PIE 55,97,06,96,37,97,36,29
L7C50:  .word TWDG97
L7C52:  .word TWDG06
L7C54:  .word TWDG96
L7C56:  .word TWDG37
L7C58:  .word TWDG97
L7C5A:  .word TWDG36
L7C5C:  .word TWDG29

PIE11:           ;NASTY MIXED-UP FLYING
L7C5E:  .word TWDG10                ;.PIE 10,95,15,97,24,97,35,93
L7C60:  .word TWDG95
L7C62:  .word TWDG15
L7C64:  .word TWDG97
L7C66:  .word TWDG24
L7C68:  .word TWDG97
L7C6A:  .word TWDG35
L7C6C:  .word TWDG93
L7C6E:  .word TWDG16                ;.PIE 16,94,20,94,18,92,06,29
L7C70:  .word TWDG94
L7C72:  .word TWDG20
L7C74:  .word TWDG94
L7C76:  .word TWDG18
L7C78:  .word TWDG92
L7C7A:  .word TWDG06
L7C7C:  .word TWDG29

PIEXX:           ;RANDOM
L7C7E:  .word TWDG10                ;.PIE 10,95,XX,94,XX,97,XX,94
L7C80:  .word TWDG95
L7C82:  .word TWDGXX
L7C84:  .word TWDG94
L7C86:  .word TWDGXX
L7C88:  .word TWDG97
L7C8A:  .word TWDGXX
L7C8C:  .word TWDG94
L7C8E:  .word TWDGXX                ;.PIE XX,97,XX,94,XX,97,XX,29
L7C90:  .word TWDG97
L7C92:  .word TWDGXX
L7C94:  .word TWDG94
L7C96:  .word TWDGXX
L7C98:  .word TWDG97
L7C9A:  .word TWDGXX
L7C9C:  .word TWDG29

TWDGXX:
;***** CHOOSE XX'S FROM TABLE BELOW
L7C9E:  .word TWDG03                ;.PIE 03,06,09,15,14,16,18,20
L7CA0:  .word TWDG06
L7CA2:  .word TWDG09
L7CA4:  .word TWDG15
L7CA6:  .word TWDG14
L7CA8:  .word TWDG16
L7CAA:  .word TWDG18
L7CAC:  .word TWDG20
L7CAE:  .word TWDG24                ;.PIE 24,25,26,30,32,35,36,37
L7CB0:  .word TWDG25
L7CB2:  .word TWDG26
L7CB4:  .word TWDG30
L7CB6:  .word TWDG32
L7CB8:  .word TWDG35
L7CBA:  .word TWDG36
L7CBC:  .word TWDG37
L7CBE:  .word TWDG55                ;.PIE 55

TWDGXZ:
TPIE:            ;TABLE FULL OF PIES ( THIS SURE MAKES ME HUNGRY! )
L7CC0:  .word PIE1, PIE2, PIE3, PIE4
L7CC8:  .word PIE5
L7CCA:  .word PIE6, PIE7, PIE8, PIE9
L7CD2:  .word PIE10
L7CD4:  .word PIE11

;.SBTTL WEDGES --- PIECES OF PIE

TPIEZ:
TWDG01:          ;8 GUNS - 7 SINGLES ACROSS - EASY TO MEDIUM FLYING
L7CD6:  .byte TYPS_SHORT, $08, $08  ;SHORT 0,0,2,0 0,0,2,0
L7CD9:  .byte TYPS_LONG, $00, $03   ;LONG 0,0,0,0 0,0,0,3
L7CDC:  .byte TYPS_LONG, $20, $20   ;LONG 0,2,0,0 0,2,0,0
L7CDF:  .byte TYPS_SHORT, $03, $30  ;SHORT 0,0,0,3 0,3,0,0
L7CE2:  .byte TYPS_SHORT, $02, $02  ;SHORT 0,0,0,2 0,0,0,2
L7CE5:  .byte TYPS_LONG, $80, $8C   ;LONG 2,0,0,0 2,0,3,0
L7CE8:  .byte TYPS_LONG, $38, $08   ;LONG 0,3,2,0 0,0,2,0
L7CEB:  .byte TYPS_SHORT, $00, $00  ;SHORT 0,0,0,0 0,0,0,0
L7CEE:  .byte TYPS_SHORT, $0E, $C2  ;SHORT 0,0,3,2 3,0,0,2
L7CF1:  .byte TYPS_SHORT, $C0, $00  ;SHORT 3,0,0,0 0,0,0,0
L7CF4:  .byte TYPS_LONG, $80, $80   ;LONG 2,0,0,0 2,0,0,0
L7CF7:  .byte TYPS_NXT              ;NEXT

TWDG02:          ;8 GUNS - 4 SINGLES ACROSS - EASY FLYING
L7CF8:  .byte TYPS_LONG, $00, $00   ;LONG 0,0,0,0 0,0,0,0
L7CFB:  .byte TYPS_LONG, $38, $08   ;LONG 0,3,2,0 0,0,2,0
L7CFE:  .byte TYPS_LONG, $03, $03   ;LONG 0,0,0,3 0,0,0,3
L7D01:  .byte TYPS_LONG, $80, $B0   ;LONG 2,0,0,0 2,3,0,0
L7D04:  .byte TYPS_LONG, $0C, $0C   ;LONG 0,0,3,0 0,0,3,0
L7D07:  .byte TYPS_LONG, $C2, $C2   ;LONG 3,0,0,2 3,0,0,2
L7D0A:  .byte TYPS_LONG, $00, $00   ;LONG 0,0,0,0 0,0,0,0
L7D0D:  .byte TYPS_LONG, $08, $08   ;LONG 0,0,2,0 0,0,2,0
L7D10:  .byte TYPS_NXT              ;NEXT

TWDG03:          ;8 GUNS - SEMI-ROLLER COASTER - HARD FLYING
L7D11:  .byte TYPS_SHORT, $00, $00  ;SHORT 0,0,0,0 0,0,0,0
L7D14:  .byte TYPS_SHORT, $A0, $A0  ;SHORT 2,2,0,0 2,2,0,0
L7D17:  .byte TYPS_SHORT, $03, $03  ;SHORT 0,0,0,3 0,0,0,3
L7D1A:  .byte TYPS_SHORT, $0A, $0A  ;SHORT 0,0,2,2 0,0,2,2
L7D1D:  .byte TYPS_SHORT, $00, $00  ;SHORT 0,0,0,0 0,0,0,0
L7D20:  .byte TYPS_SHORT, $38, $38  ;SHORT 0,3,2,0 0,3,2,0
L7D23:  .byte TYPS_SHORT, $20, $20  ;SHORT 0,2,0,0 0,2,0,0
L7D26:  .byte TYPS_SHORT, $C0, $C0  ;SHORT 3,0,0,0 3,0,0,0
L7D29:  .byte TYPS_SHORT, $00, $00  ;SHORT 0,0,0,0 0,0,0,0
L7D2C:  .byte TYPS_SHORT, $00, $00  ;SHORT 0,0,0,0 0,0,0,0
L7D2F:  .byte TYPS_SHORT, $0E, $0E  ;SHORT 0,0,3,2 0,0,3,2
L7D32:  .byte TYPS_SHORT, $08, $08  ;SHORT 0,0,2,0 0,0,2,0
L7D35:  .byte TYPS_SHORT, $00, $00  ;SHORT 0,0,0,0 0,0,0,0
L7D38:  .byte TYPS_SHORT, $08, $08  ;SHORT 0,0,2,0 0,0,2,0
L7D3B:  .byte TYPS_SHORT, $20, $20  ;SHORT 0,2,0,0 0,2,0,0
L7D3E:  .byte TYPS_SHORT, $80, $80  ;SHORT 2,0,0,0 2,0,0,0
L7D41:  .byte TYPS_NXT              ;NEXT

TWDG04:          ;8 GUNS ALL LEVELS L & R - EASY FLYING
L7D42:  .byte TYPS_LONG, $00, $30   ;LONG 0,0,0,0 0,3,0,0
L7D45:  .byte TYPS_LONG, $0C, $00   ;LONG 0,0,3,0 0,0,0,0
L7D48:  .byte TYPS_LONG, $00, $03   ;LONG 0,0,0,0 0,0,0,3
L7D4B:  .byte TYPS_LONG, $C0, $00   ;LONG 3,0,0,0 0,0,0,0
L7D4E:  .byte TYPS_LONG, $00, $C0   ;LONG 0,0,0,0 3,0,0,0
L7D51:  .byte TYPS_LONG, $03, $00   ;LONG 0,0,0,3 0,0,0,0
L7D54:  .byte TYPS_LONG, $00, $0C   ;LONG 0,0,0,0 0,0,3,0
L7D57:  .byte TYPS_LONG, $30, $00   ;LONG 0,3,0,0 0,0,0,0
L7D5A:  .byte TYPS_NXT              ;NEXT

TWDG05:          ;8 GUNS - EASY ROLLER COASTER - MEDIUM FLYING
L7D5B:  .byte TYPS_SHORT, $00, $00  ;SHORT 0,0,0,0 0,0,0,0
L7D5E:  .byte TYPS_LONG, $A0, $A0   ;LONG 2,2,0,0 2,2,0,0
L7D61:  .byte TYPS_SHORT, $00, $00  ;SHORT 0,0,0,0 0,0,0,0
L7D64:  .byte TYPS_SHORT, $03, $03  ;SHORT 0,0,0,3 0,0,0,3
L7D67:  .byte TYPS_LONG, $0A, $0A   ;LONG 0,0,2,2 0,0,2,2
L7D6A:  .byte TYPS_SHORT, $00, $00  ;SHORT 0,0,0,0 0,0,0,0
L7D6D:  .byte TYPS_SHORT, $C0, $C0  ;SHORT 3,0,0,0 3,0,0,0
L7D70:  .byte TYPS_LONG, $A0, $A0   ;LONG 2,2,0,0 2,2,0,0
L7D73:  .byte TYPS_SHORT, $03, $03  ;SHORT 0,0,0,3 0,0,0,3
L7D76:  .byte TYPS_SHORT, $00, $00  ;SHORT 0,0,0,0 0,0,0,0
L7D79:  .byte TYPS_LONG, $3A, $3A   ;LONG 0,3,2,2 0,3,2,2
L7D7C:  .byte TYPS_SHORT, $00, $00  ;SHORT 0,0,0,0 0,0,0,0
L7D7F:  .byte TYPS_NXT              ;NEXT

TWDG06:          ;0 GUNS - TIGHT ROLLER COASTER - HARD FLYING
L7D80:  .byte TYPS_SHORT, $0A, $0A  ;SHORT 0,0,2,2 0,0,2,2
L7D83:  .byte TYPS_SHORT, $00, $00  ;SHORT 0,0,0,0 0,0,0,0
L7D86:  .byte TYPS_SHORT, $A0, $A0  ;SHORT 2,2,0,0 2,2,0,0
L7D89:  .byte TYPS_SHORT, $00, $00  ;SHORT 0,0,0,0 0,0,0,0
L7D8C:  .byte TYPS_SHORT, $0A, $0A  ;SHORT 0,0,2,2 0,0,2,2
L7D8F:  .byte TYPS_SHORT, $00, $00  ;SHORT 0,0,0,0 0,0,0,0
L7D92:  .byte TYPS_SHORT, $A0, $A0  ;SHORT 2,2,0,0 2,2,0,0
L7D95:  .byte TYPS_SHORT, $00, $00  ;SHORT 0,0,0,0 0,0,0,0
L7D98:  .byte TYPS_SHORT, $0A       ;SHORT 0,0,2,2 0,0,2,2
L7D9A:  .byte $0A
L7D9B:  .byte TYPS_SHORT, $00, $00  ;SHORT 0,0,0,0 0,0,0,0
L7D9E:  .byte TYPS_SHORT, $A0, $A0  ;SHORT 2,2,0,0 2,2,0,0
L7DA1:  .byte TYPS_SHORT, $00, $00  ;SHORT 0,0,0,0 0,0,0,0
L7DA4:  .byte TYPS_SHORT, $0A, $0A  ;SHORT 0,0,2,2 0,0,2,2
L7DA7:  .byte TYPS_SHORT, $00, $00  ;SHORT 0,0,0,0 0,0,0,0
L7DAA:  .byte TYPS_SHORT, $A0, $A0  ;SHORT 2,2,0,0 2,2,0,0
L7DAD:  .byte TYPS_SHORT, $00, $00  ;SHORT 0,0,0,0 0,0,0,0
L7DB0:  .byte TYPS_NXT              ;NEXT

TWDG07:          ;8 GUNS - 8 SINGLES TOP AND BOTTOM - EASY FLYING
L7DB1:  .byte TYPS_LONG, $80, $80   ;LONG 2,0,0,0 2,0,0,0
L7DB4:  .byte TYPS_LONG, $8C, $83   ;LONG 2,0,3,0 2,0,0,3
L7DB7:  .byte TYPS_LONG, $B0, $80   ;LONG 2,3,0,0 2,0,0,0
L7DBA:  .byte TYPS_LONG, $80, $B0   ;LONG 2,0,0,0 2,3,0,0
L7DBD:  .byte TYPS_LONG, $02, $02   ;LONG 0,0,0,2 0,0,0,2
L7DC0:  .byte TYPS_LONG, $32, $0E   ;LONG 0,3,0,2 0,0,3,2
L7DC3:  .byte TYPS_LONG, $0E, $C2   ;LONG 0,0,3,2 3,0,0,2
L7DC6:  .byte TYPS_LONG, $02, $02   ;LONG 0,0,0,2 0,0,0,2
L7DC9:  .byte TYPS_NXT              ;NEXT

TWDG08:          ;6 GUNS - 8 SINGLES BOTTOM TO TOP - EASY TO MEDIUM FLYING
L7DCA:  .byte TYPS_LONG, $02, $02   ;LONG 0,0,0,2 0,0,0,2
L7DCD:  .byte TYPS_LONG, $32, $32   ;LONG 0,3,0,2 0,3,0,2
L7DD0:  .byte TYPS_LONG, $02, $02   ;LONG 0,0,0,2 0,0,0,2
L7DD3:  .byte TYPS_LONG, $C8, $C8   ;LONG 3,0,2,0 3,0,2,0
L7DD6:  .byte TYPS_LONG, $08, $08   ;LONG 0,0,2,0 0,0,2,0
L7DD9:  .byte TYPS_LONG, $08, $08   ;LONG 0,0,2,0 0,0,2,0
L7DDC:  .byte TYPS_LONG, $E0, $E0   ;LONG 3,2,0,0 3,2,0,0
L7DDF:  .byte TYPS_LONG, $20, $20   ;LONG 0,2,0,0 0,2,0,0
L7DE2:  .byte TYPS_NXT              ;NEXT

TWDG09:          ;6 GUNS - 24 HALVES - MEDIUM TO HARD FLYING
L7DE3:  .byte TYPS_SHORT, $22, $88  ;SHORT 0,2,0,2 2,0,2,0
L7DE6:  .byte TYPS_SHORT, $00, $00  ;SHORT 0,0,0,0 0,0,0,0
L7DE9:  .byte TYPS_SHORT, $88, $22  ;SHORT 2,0,2,0 0,2,0,2
L7DEC:  .byte TYPS_SHORT, $33, $CC  ;SHORT 0,3,0,3 3,0,3,0
L7DEF:  .byte TYPS_SHORT, $A0, $0A  ;SHORT 2,2,0,0 0,0,2,2
L7DF2:  .byte TYPS_SHORT, $00, $00  ;SHORT 0,0,0,0 0,0,0,0
L7DF5:  .byte TYPS_SHORT, $0A, $A0  ;SHORT 0,0,2,2 2,2,0,0
L7DF8:  .byte TYPS_SHORT, $C0, $03  ;SHORT 3,0,0,0 0,0,0,3
L7DFB:  .byte TYPS_LONG, $28, $82   ;LONG 0,2,2,0 2,0,0,2
L7DFE:  .byte TYPS_LONG, $00, $00   ;LONG 0,0,0,0 0,0,0,0
L7E01:  .byte TYPS_LONG, $88, $28   ;LONG 2,0,2,0 0,2,2,0
L7E04:  .byte TYPS_LONG, $00, $00   ;LONG 0,0,0,0 0,0,0,0
L7E07:  .byte TYPS_NXT              ;NEXT

TWDG10:          ;8 GUNS - 24 PANELS -- INTRO WEDGE - EASY FLYING
L7E08:  .byte TYPS_LONG, $41, $41   ;LONG 1,0,0,1 1,0,0,1
L7E0B:  .byte TYPS_LONG, $41, $41   ;LONG 1,0,0,1 1,0,0,1
L7E0E:  .byte TYPS_LONG, $14, $14   ;LONG 0,1,1,0 0,1,1,0
L7E11:  .byte TYPS_LONG, $14, $14   ;LONG 0,1,1,0 0,1,1,0
L7E14:  .byte TYPS_LONG, $41, $41   ;LONG 1,0,0,1 1,0,0,1
L7E17:  .byte TYPS_LONG, $41, $41   ;LONG 1,0,0,1 1,0,0,1
L7E1A:  .byte TYPS_SHORT, $3C, $3C  ;SHORT 0,3,3,0 0,3,3,0
L7E1D:  .byte TYPS_SHORT, $C3, $C3  ;SHORT 3,0,0,3 3,0,0,3
L7E20:  .byte TYPS_NXT              ;NEXT

TWDG11:          ;8 GUNS - 5 SINGLES ACROSS - EASY TO MEDIUM FLYING
L7E21:  .byte TYPS_LONG, $80, $80   ;LONG 2,0,0,0 2,0,0,0
L7E24:  .byte TYPS_LONG, $00, $00   ;LONG 0,0,0,0 0,0,0,0
L7E27:  .byte TYPS_LONG, $08, $08   ;LONG 0,0,2,0 0,0,2,0
L7E2A:  .byte TYPS_SHORT, $00, $00  ;SHORT 0,0,0,0 0,0,0,0
L7E2D:  .byte TYPS_LONG, $E0, $E0   ;LONG 3,2,0,0 3,2,0,0
L7E30:  .byte TYPS_LONG, $03, $03   ;LONG 0,0,0,3 0,0,0,3
L7E33:  .byte TYPS_LONG, $0E, $0E   ;LONG 0,0,3,2 0,0,3,2
L7E36:  .byte TYPS_LONG, $B0, $B0   ;LONG 2,3,0,0 2,3,0,0
L7E39:  .byte TYPS_SHORT, $00, $00  ;SHORT 0,0,0,0 0,0,0,0
L7E3C:  .byte TYPS_NXT              ;NEXT

TWDG12:          ;8 GUNS - 3 DOUBLES ACROSS - EASY TO MEDIUM FLYING
L7E3D:  .byte TYPS_LONG, $00, $00   ;LONG 0,0,0,0 0,0,0,0
L7E40:  .byte TYPS_LONG, $0A, $0A   ;LONG 0,0,2,2 0,0,2,2
L7E43:  .byte TYPS_LONG, $30, $30   ;LONG 0,3,0,0 0,3,0,0
L7E46:  .byte TYPS_LONG, $00, $00   ;LONG 0,0,0,0 0,0,0,0
L7E49:  .byte TYPS_LONG, $2B, $2B   ;LONG 0,2,2,3 0,2,2,3
L7E4C:  .byte TYPS_LONG, $00, $00   ;LONG 0,0,0,0 0,0,0,0
L7E4F:  .byte TYPS_LONG, $C0, $C0   ;LONG 3,0,0,0 3,0,0,0
L7E52:  .byte TYPS_LONG, $AC, $AC   ;LONG 2,2,3,0 2,2,3,0
L7E55:  .byte TYPS_NXT              ;NEXT

TWDG13:          ;8 GUNS - 8 ALTERNATING HALVES ON BOTTOM - EASY FLYING
L7E56:  .byte TYPS_LONG, $03, $03   ;LONG 0,0,0,3 0,0,0,3
L7E59:  .byte TYPS_LONG, $02, $00   ;LONG 0,0,0,2 0,0,0,0
L7E5C:  .byte TYPS_SHORT, $C0, $02  ;SHORT 3,0,0,0 0,0,0,2
L7E5F:  .byte TYPS_LONG, $02, $30   ;LONG 0,0,0,2 0,3,0,0
L7E62:  .byte TYPS_SHORT, $30, $02  ;SHORT 0,3,0,0 0,0,0,2
L7E65:  .byte TYPS_LONG, $02, $0C   ;LONG 0,0,0,2 0,0,3,0
L7E68:  .byte TYPS_SHORT, $0C, $02  ;SHORT 0,0,3,0 0,0,0,2
L7E6B:  .byte TYPS_LONG, $02, $C0   ;LONG 0,0,0,2 3,0,0,0
L7E6E:  .byte TYPS_SHORT, $00, $02  ;SHORT 0,0,0,0 0,0,0,2
L7E71:  .byte TYPS_LONG, $00, $00   ;LONG 0,0,0,0 0,0,0,0
L7E74:  .byte TYPS_NXT              ;NEXT

TWDG14:          ;8 GUNS - 4 SINGLES ACROSS - 1 TRIPLE - MEDIUM FLYING
L7E75:  .byte TYPS_SHORT, $02, $02  ;SHORT 0,0,0,2 0,0,0,2
L7E78:  .byte TYPS_SHORT, $00, $00  ;SHORT 0,0,0,0 0,0,0,0
L7E7B:  .byte TYPS_SHORT, $02, $02  ;SHORT 0,0,0,2 0,0,0,2
L7E7E:  .byte TYPS_SHORT, $00, $00  ;SHORT 0,0,0,0 0,0,0,0
L7E81:  .byte TYPS_SHORT, $00, $00  ;SHORT 0,0,0,0 0,0,0,0
L7E84:  .byte TYPS_LONG, $F2, $F2   ;LONG 3,3,0,2 3,3,0,2
L7E87:  .byte TYPS_SHORT, $0C, $0C  ;SHORT 0,0,3,0 0,0,3,0
L7E8A:  .byte TYPS_SHORT, $02, $02  ;SHORT 0,0,0,2 0,0,0,2
L7E8D:  .byte TYPS_SHORT, $00, $00  ;SHORT 0,0,0,0 0,0,0,0
L7E90:  .byte TYPS_SHORT, $A8, $A8  ;SHORT 2,2,2,0 2,2,2,0
L7E93:  .byte TYPS_LONG, $00, $00   ;LONG 0,0,0,0 0,0,0,0
L7E96:  .byte TYPS_LONG, $03, $03   ;LONG 0,0,0,3 0,0,0,3
L7E99:  .byte TYPS_SHORT, $00, $00  ;SHORT 0,0,0,0 0,0,0,0
L7E9C:  .byte TYPS_NXT              ;NEXT

TWDG15:          ;3 GUNS - 4 TRIPLES - 4 HALVES -- QUICK SLANT - HARD FLYING
L7E9D:  .byte TYPS_LONG, $2A, $AA   ;LONG 0,2,2,2 2,2,2,2
L7EA0:  .byte TYPS_SHORT, $00, $00  ;SHORT 0,0,0,0 0,0,0,0
L7EA3:  .byte TYPS_LONG, $AA, $A8   ;LONG 2,2,2,2 2,2,2,0
L7EA6:  .byte TYPS_LONG, $00, $03   ;LONG 0,0,0,0 0,0,0,3
L7EA9:  .byte TYPS_LONG, $00, $0C   ;LONG 0,0,0,0 0,0,3,0
L7EAC:  .byte TYPS_LONG, $00, $03   ;LONG 0,0,0,0 0,0,0,3
L7EAF:  .byte TYPS_LONG, $AA, $A8   ;LONG 2,2,2,2 2,2,2,0
L7EB2:  .byte TYPS_SHORT, $00, $00  ;SHORT 0,0,0,0 0,0,0,0
L7EB5:  .byte TYPS_LONG, $2A, $AA   ;LONG 0,2,2,2 2,2,2,2
L7EB8:  .byte TYPS_NXT              ;NEXT

TWDG16:          ;8 GUNS - 6 DOUBLES - TIGHT HUMP, SEMI-ROLLER - HARD FLYING
L7EB9:  .byte TYPS_LONG, $0C, $0C   ;LONG 0,0,3,0 0,0,3,0
L7EBC:  .byte TYPS_LONG, $03, $03   ;LONG 0,0,0,3 0,0,0,3
L7EBF:  .byte TYPS_LONG, $A0, $A0   ;LONG 2,2,0,0 2,2,0,0
L7EC2:  .byte TYPS_SHORT, $03, $03  ;SHORT 0,0,0,3 0,0,0,3
L7EC5:  .byte TYPS_SHORT, $0A, $0A  ;SHORT 0,0,2,2 0,0,2,2
L7EC8:  .byte TYPS_SHORT, $28, $28  ;SHORT 0,2,2,0 0,2,2,0
L7ECB:  .byte TYPS_SHORT, $0A, $0A  ;SHORT 0,0,2,2 0,0,2,2
L7ECE:  .byte TYPS_LONG, $A0, $A0   ;LONG 2,2,0,0 2,2,0,0
L7ED1:  .byte TYPS_LONG, $00, $00   ;LONG 0,0,0,0 0,0,0,0
L7ED4:  .byte TYPS_LONG, $A3, $A3   ;LONG 2,2,0,3 2,2,0,3
L7ED7:  .byte TYPS_NXT              ;NEXT

TWDG17:          ;0 GUNS - 4 TRIPLES - MEDIUM FLYING
L7ED8:  .byte TYPS_LONG, $A8, $A8   ;LONG 2,2,2,0 2,2,2,0
L7EDB:  .byte TYPS_LONG, $00, $00   ;LONG 0,0,0,0 0,0,0,0
L7EDE:  .byte TYPS_LONG, $2A, $2A   ;LONG 0,2,2,2 0,2,2,2
L7EE1:  .byte TYPS_LONG, $00, $00   ;LONG 0,0,0,0 0,0,0,0
L7EE4:  .byte TYPS_LONG, $A8, $A8   ;LONG 2,2,2,0 2,2,2,0
L7EE7:  .byte TYPS_LONG, $00, $00   ;LONG 0,0,0,0 0,0,0,0
L7EEA:  .byte TYPS_LONG, $2A, $2A   ;LONG 0,2,2,2 0,2,2,2
L7EED:  .byte TYPS_LONG, $00, $00   ;LONG 0,0,0,0 0,0,0,0
L7EF0:  .byte TYPS_NXT              ;NEXT

TWDG18:          ;4 GUNS - 6 SINGLES, 1 DOUBLE, 8 HALVES, 2 TRIPLES - HARD FLYING
L7EF1:  .byte TYPS_LONG, $88, $88   ;LONG 2,0,2,0 2,0,2,0
L7EF4:  .byte TYPS_SHORT, $22, $22  ;SHORT 0,2,0,2 0,2,0,2
L7EF7:  .byte TYPS_SHORT, $00, $00  ;SHORT 0,0,0,0 0,0,0,0
L7EFA:  .byte TYPS_LONG, $CC, $CC   ;LONG 3,0,3,0 3,0,3,0
L7EFD:  .byte TYPS_LONG, $82, $82   ;LONG 2,0,0,2 2,0,0,2
L7F00:  .byte TYPS_SHORT, $28, $28  ;SHORT 0,2,2,0 0,2,2,0
L7F03:  .byte TYPS_SHORT, $00, $00  ;SHORT 0,0,0,0 0,0,0,0
L7F06:  .byte TYPS_SHORT, $AA, $00  ;SHORT 2,2,2,2 0,0,0,0
L7F09:  .byte TYPS_SHORT, $00, $AA  ;SHORT 0,0,0,0 2,2,2,2
L7F0C:  .byte TYPS_SHORT, $00, $00  ;SHORT 0,0,0,0 0,0,0,0
L7F0F:  .byte TYPS_LONG, $A8, $A8   ;LONG 2,2,2,0 2,2,2,0
L7F12:  .byte TYPS_SHORT, $2A, $2A  ;SHORT 0,2,2,2 0,2,2,2
L7F15:  .byte TYPS_NXT              ;NEXT

TWDG19:          ;8 GUNS - 16 HALVES, 1 DOUBLE, 2 SINGLES - MEDIUM FLYING
L7F16:  .byte TYPS_SHORT, $0A, $A0  ;SHORT 0,0,2,2 2,2,0,0
L7F19:  .byte TYPS_SHORT, $C0, $0C  ;SHORT 3,0,0,0 0,0,3,0
L7F1C:  .byte TYPS_SHORT, $A0, $0A  ;SHORT 2,2,0,0 0,0,2,2
L7F1F:  .byte TYPS_SHORT, $00, $00  ;SHORT 0,0,0,0 0,0,0,0
L7F22:  .byte TYPS_SHORT, $28, $00  ;SHORT 0,2,2,0 0,0,0,0
L7F25:  .byte TYPS_SHORT, $03, $C0  ;SHORT 0,0,0,3 3,0,0,0
L7F28:  .byte TYPS_SHORT, $28, $28  ;SHORT 0,2,2,0 0,2,2,0
L7F2B:  .byte TYPS_SHORT, $00, $00  ;SHORT 0,0,0,0 0,0,0,0
L7F2E:  .byte TYPS_SHORT, $80, $80  ;SHORT 2,0,0,0 2,0,0,0
L7F31:  .byte TYPS_SHORT, $30, $03  ;SHORT 0,3,0,0 0,0,0,3
L7F34:  .byte TYPS_SHORT, $02, $02  ;SHORT 0,0,0,2 0,0,0,2
L7F37:  .byte TYPS_SHORT, $0C, $00  ;SHORT 0,0,3,0 0,0,0,0
L7F3A:  .byte TYPS_SHORT, $28, $00  ;SHORT 0,2,2,0 0,0,0,0
L7F3D:  .byte TYPS_SHORT, $00, $30  ;SHORT 0,0,0,0 0,3,0,0
L7F40:  .byte TYPS_SHORT, $82, $28  ;SHORT 2,0,0,2 0,2,2,0
L7F43:  .byte TYPS_SHORT, $00, $00  ;SHORT 0,0,0,0 0,0,0,0
L7F46:  .byte TYPS_NXT              ;NEXT

TWDG20:          ;10 GUNS - 2 TRIPLES, 8 SINGLES - HARD FLYING
L7F47:  .byte TYPS_SHORT, $80, $80  ;SHORT 2,0,0,0 2,0,0,0
L7F4A:  .byte TYPS_SHORT, $20, $20  ;SHORT 0,2,0,0 0,2,0,0
L7F4D:  .byte TYPS_SHORT, $08, $08  ;SHORT 0,0,2,0 0,0,2,0
L7F50:  .byte TYPS_SHORT, $30, $0C  ;SHORT 0,3,0,0 0,0,3,0
L7F53:  .byte TYPS_SHORT, $2A, $2A  ;SHORT 0,2,2,2 0,2,2,2
L7F56:  .byte TYPS_SHORT, $C0, $C0  ;SHORT 3,0,0,0 3,0,0,0
L7F59:  .byte TYPS_SHORT, $20, $20  ;SHORT 0,2,0,0 0,2,0,0
L7F5C:  .byte TYPS_SHORT, $00, $00  ;SHORT 0,0,0,0 0,0,0,0
L7F5F:  .byte TYPS_SHORT, $20, $20  ;SHORT 0,2,0,0 0,2,0,0
L7F62:  .byte TYPS_SHORT, $C0, $C0  ;SHORT 3,0,0,0 3,0,0,0
L7F65:  .byte TYPS_SHORT, $20, $20  ;SHORT 0,2,0,0 0,2,0,0
L7F68:  .byte TYPS_SHORT, $C0, $C0  ;SHORT 3,0,0,0 3,0,0,0
L7F6B:  .byte TYPS_SHORT, $A8, $A8  ;SHORT 2,2,2,0 2,2,2,0
L7F6E:  .byte TYPS_SHORT, $08, $08  ;SHORT 0,0,2,0 0,0,2,0
L7F71:  .byte TYPS_SHORT, $03, $03  ;SHORT 0,0,0,3 0,0,0,3
L7F74:  .byte TYPS_SHORT, $08, $08  ;SHORT 0,0,2,0 0,0,2,0
L7F77:  .byte TYPS_NXT              ;NEXT

TWDG21:          ;8 GUNS - 6 SINGLES ACROSS - EASY TO MEDIUM FLYING
L7F78:  .byte TYPS_LONG, $00, $00   ;LONG 0,0,0,0 0,0,0,0
L7F7B:  .byte TYPS_LONG, $02, $02   ;LONG 0,0,0,2 0,0,0,2
L7F7E:  .byte TYPS_LONG, $00, $00   ;LONG 0,0,0,0 0,0,0,0
L7F81:  .byte TYPS_SHORT, $82, $82  ;SHORT 2,0,0,2 2,0,0,2
L7F84:  .byte TYPS_SHORT, $3C, $3C  ;SHORT 0,3,3,0 0,3,3,0
L7F87:  .byte TYPS_SHORT, $3C, $3C  ;SHORT 0,3,3,0 0,3,3,0
L7F8A:  .byte TYPS_SHORT, $82, $82  ;SHORT 2,0,0,2 2,0,0,2
L7F8D:  .byte TYPS_LONG, $00, $00   ;LONG 0,0,0,0 0,0,0,0
L7F90:  .byte TYPS_LONG, $02, $02   ;LONG 0,0,0,2 0,0,0,2
L7F93:  .byte TYPS_LONG, $00, $00   ;LONG 0,0,0,0 0,0,0,0
L7F96:  .byte TYPS_NXT              ;NEXT

TWDG22:          ;8 GUNS - 10 SINGLES ACROSS TOP AND BOTTOM - EASY TO MEDIUM FLYING
L7F97:  .byte TYPS_SHORT, $00, $00  ;SHORT 0,0,0,0 0,0,0,0
L7F9A:  .byte TYPS_SHORT, $02, $02  ;SHORT 0,0,0,2 0,0,0,2
L7F9D:  .byte TYPS_LONG, $8C, $8C   ;LONG 2,0,3,0 2,0,3,0
L7FA0:  .byte TYPS_SHORT, $02, $02  ;SHORT 0,0,0,2 0,0,0,2
L7FA3:  .byte TYPS_LONG, $B0, $B0   ;LONG 2,3,0,0 2,3,0,0
L7FA6:  .byte TYPS_SHORT, $02, $02  ;SHORT 0,0,0,2 0,0,0,2
L7FA9:  .byte TYPS_LONG, $8C, $8C   ;LONG 2,0,3,0 2,0,3,0
L7FAC:  .byte TYPS_SHORT, $02, $02  ;SHORT 0,0,0,2 0,0,0,2
L7FAF:  .byte TYPS_LONG, $B0, $B0   ;LONG 2,3,0,0 2,3,0,0
L7FB2:  .byte TYPS_SHORT, $02, $02  ;SHORT 0,0,0,2 0,0,0,2
L7FB5:  .byte TYPS_LONG, $80, $80   ;LONG 2,0,0,0 2,0,0,0
L7FB8:  .byte TYPS_NXT              ;NEXT

TWDG23:          ;12 GUNS - 6 SINGLES - 1 DOUBLE -- LONG DOWN-UP - MEDIUM FLYING
L7FB9:  .byte TYPS_LONG, $0A, $0A   ;LONG 0,0,2,2 0,0,2,2
L7FBC:  .byte TYPS_LONG, $B0, $B0   ;LONG 2,3,0,0 2,3,0,0
L7FBF:  .byte TYPS_LONG, $2C, $2C   ;LONG 0,2,3,0 0,2,3,0
L7FC2:  .byte TYPS_LONG, $0B, $0B   ;LONG 0,0,2,3 0,0,2,3
L7FC5:  .byte TYPS_LONG, $00, $00   ;LONG 0,0,0,0 0,0,0,0
L7FC8:  .byte TYPS_LONG, $0E, $0E   ;LONG 0,0,3,2 0,0,3,2
L7FCB:  .byte TYPS_LONG, $38, $38   ;LONG 0,3,2,0 0,3,2,0
L7FCE:  .byte TYPS_LONG, $E0, $E0   ;LONG 3,2,0,0 3,2,0,0
L7FD1:  .byte TYPS_NXT              ;NEXT

TWDG24:          ;0 GUNS - 32 HALVES -- R AND L JOGS - HARD FLYING
L7FD2:  .byte TYPS_SHORT, $00, $AA  ;SHORT 0,0,0,0 2,2,2,2
L7FD5:  .byte TYPS_SHORT, $00, $00  ;SHORT 0,0,0,0 0,0,0,0
L7FD8:  .byte TYPS_SHORT, $AA, $00  ;SHORT 2,2,2,2 0,0,0,0
L7FDB:  .byte TYPS_SHORT, $00, $00  ;SHORT 0,0,0,0 0,0,0,0
L7FDE:  .byte TYPS_SHORT, $00, $AA  ;SHORT 0,0,0,0 2,2,2,2
L7FE1:  .byte TYPS_SHORT, $00, $00  ;SHORT 0,0,0,0 0,0,0,0
L7FE4:  .byte TYPS_SHORT, $AA, $00  ;SHORT 2,2,2,2 0,0,0,0
L7FE7:  .byte TYPS_SHORT, $00, $00  ;SHORT 0,0,0,0 0,0,0,0
L7FEA:  .byte TYPS_SHORT, $00, $AA  ;SHORT 0,0,0,0 2,2,2,2
L7FED:  .byte TYPS_SHORT, $00, $00  ;SHORT 0,0,0,0 0,0,0,0
L7FF0:  .byte TYPS_SHORT, $AA, $00  ;SHORT 2,2,2,2 0,0,0,0
L7FF3:  .byte TYPS_SHORT, $00, $00  ;SHORT 0,0,0,0 0,0,0,0
L7FF6:  .byte TYPS_SHORT, $00, $AA  ;SHORT 0,0,0,0 2,2,2,2
L7FF9:  .byte TYPS_SHORT, $00, $00  ;SHORT 0,0,0,0 0,0,0,0
L7FFC:  .byte TYPS_SHORT, $AA, $00  ;SHORT 2,2,2,2 0,0,0,0
L7FFF:  .byte TYPS_SHORT, $00, $00  ;SHORT 0,0,0,0 0,0,0,0
L8002:  .byte TYPS_NXT              ;NEXT

TWDG25:          ;8 GUNS - 6 SINGLES - 3 DOUBLES -- DOWN HUMP DOWN - HARD FLYING
L8003:  .byte TYPS_SHORT, $B0, $B0  ;SHORT 2,3,0,0 2,3,0,0
L8006:  .byte TYPS_SHORT, $2C, $2C  ;SHORT 0,2,3,0 0,2,3,0
L8009:  .byte TYPS_SHORT, $08, $08  ;SHORT 0,0,2,0 0,0,2,0
L800C:  .byte TYPS_LONG, $00, $00   ;LONG 0,0,0,0 0,0,0,0
L800F:  .byte TYPS_LONG, $0A, $0A   ;LONG 0,0,2,2 0,0,2,2
L8012:  .byte TYPS_LONG, $A0, $A0   ;LONG 2,2,0,0 2,2,0,0
L8015:  .byte TYPS_LONG, $0A, $0A   ;LONG 0,0,2,2 0,0,2,2
L8018:  .byte TYPS_LONG, $00, $00   ;LONG 0,0,0,0 0,0,0,0
L801B:  .byte TYPS_SHORT, $B0, $B0  ;SHORT 2,3,0,0 2,3,0,0
L801E:  .byte TYPS_SHORT, $2C, $2C  ;SHORT 0,2,3,0 0,2,3,0
L8021:  .byte TYPS_SHORT, $08, $08  ;SHORT 0,0,2,0 0,0,2,0
L8024:  .byte TYPS_NXT              ;NEXT

TWDG26:          ;0 GUNS - 3 DOUBLES - 20 HALVES -- HALVES UP DOWN HALVES - HARD FLYING
L8025:  .byte TYPS_SHORT, $AA, $00  ;SHORT 2,2,2,2 0,0,0,0
L8028:  .byte TYPS_SHORT, $00, $00  ;SHORT 0,0,0,0 0,0,0,0
L802B:  .byte TYPS_SHORT, $00, $AA  ;SHORT 0,0,0,0 2,2,2,2
L802E:  .byte TYPS_SHORT, $00, $00  ;SHORT 0,0,0,0 0,0,0,0
L8031:  .byte TYPS_LONG, $AA, $00   ;LONG 2,2,2,2 0,0,0,0
L8034:  .byte TYPS_SHORT, $0A, $0A  ;SHORT 0,0,2,2 0,0,2,2
L8037:  .byte TYPS_LONG, $00, $00   ;LONG 0,0,0,0 0,0,0,0
L803A:  .byte TYPS_SHORT, $A0, $A0  ;SHORT 2,2,0,0 2,2,0,0
L803D:  .byte TYPS_LONG, $0A, $0A   ;LONG 0,0,2,2 0,0,2,2
L8040:  .byte TYPS_SHORT, $00, $AA  ;SHORT 0,0,0,0 2,2,2,2
L8043:  .byte TYPS_SHORT, $00, $00  ;SHORT 0,0,0,0 0,0,0,0
L8046:  .byte TYPS_SHORT, $AA, $00  ;SHORT 2,2,2,2 0,0,0,0
L8049:  .byte TYPS_SHORT, $00, $00  ;SHORT 0,0,0,0 0,0,0,0
L804C:  .byte TYPS_NXT              ;NEXT

TWDG27:          ;4 GUNS - 6 SINGLES BOTTOM TO TOP - EASY TO MEDIUM FLYING
L804D:  .byte TYPS_LONG, $00, $00   ;LONG 0,0,0,0 0,0,0,0
L8050:  .byte TYPS_LONG, $32, $0E   ;LONG 0,3,0,2 0,0,3,2
L8053:  .byte TYPS_LONG, $02, $02   ;LONG 0,0,0,2 0,0,0,2
L8056:  .byte TYPS_LONG, $08, $08   ;LONG 0,0,2,0 0,0,2,0
L8059:  .byte TYPS_LONG, $C8, $C8   ;LONG 3,0,2,0 3,0,2,0
L805C:  .byte TYPS_LONG, $20, $20   ;LONG 0,2,0,0 0,2,0,0
L805F:  .byte TYPS_LONG, $20, $20   ;LONG 0,2,0,0 0,2,0,0
L8062:  .byte TYPS_LONG, $00, $00   ;LONG 0,0,0,0 0,0,0,0
L8065:  .byte TYPS_NXT              ;NEXT

TWDG28:          ;6 GUNS - 6 SINGLES TOP TO BOTTOM - EASY TO MEDIUM FLYING
L8066:  .byte TYPS_LONG, $00, $00   ;LONG 0,0,0,0 0,0,0,0
L8069:  .byte TYPS_LONG, $8C, $8C   ;LONG 2,0,3,0 2,0,3,0
L806C:  .byte TYPS_LONG, $80, $80   ;LONG 2,0,0,0 2,0,0,0
L806F:  .byte TYPS_LONG, $23, $23   ;LONG 0,2,0,3 0,2,0,3
L8072:  .byte TYPS_LONG, $20, $20   ;LONG 0,2,0,0 0,2,0,0
L8075:  .byte TYPS_LONG, $08, $08   ;LONG 0,0,2,0 0,0,2,0
L8078:  .byte TYPS_LONG, $0B, $0B   ;LONG 0,0,2,3 0,0,2,3
L807B:  .byte TYPS_LONG, $00, $00   ;LONG 0,0,0,0 0,0,0,0
L807E:  .byte TYPS_NXT              ;NEXT

TWDG29:          ;16 GUNS - HARDER PORT - PROTECT YOURSELF
L807F:  .byte TYPS_SHORT, $00, $00  ;SHORT 0,0,0,0 0,0,0,0
L8082:  .byte TYPS_LONG, $2A, $2A   ;LONG 0,2,2,2 0,2,2,2
L8085:  .byte TYPS_SHORT, $20, $20  ;SHORT 0,2,0,0 0,2,0,0
L8088:  .byte TYPS_LONG, $C0, $C0   ;LONG 3,0,0,0 3,0,0,0
L808B:  .byte TYPS_LONG, $30, $30   ;LONG 0,3,0,0 0,3,0,0
L808E:  .byte TYPS_LONG, $CC, $CC   ;LONG 3,0,3,0 3,0,3,0
L8091:  .byte TYPS_LONG, $33, $33   ;LONG 0,3,0,3 0,3,0,3
L8094:  .byte TYPS_SHORT, $0C, $0C  ;SHORT 0,0,3,0 0,0,3,0
L8097:  .byte TYPS_PORT, $03, $03   ;PORT 0,0,0,3 0,0,0,3
L809A:  .byte TYPS_END              ;END

TWDG30:          ;2 GUNS - 26 HALVES, 1 TRIPLE, 2 DOUBLES, 1 SINGLE - HARD FLYING
L809B:  .byte TYPS_SHORT, $A8, $AA  ;SHORT 2,2,2,0 2,2,2,2
L809E:  .byte TYPS_SHORT, $00, $00  ;SHORT 0,0,0,0 0,0,0,0
L80A1:  .byte TYPS_SHORT, $03, $AA  ;SHORT 0,0,0,3 2,2,2,2
L80A4:  .byte TYPS_LONG, $AA, $03   ;LONG 2,2,2,2 0,0,0,3
L80A7:  .byte TYPS_SHORT, $00, $AA  ;SHORT 0,0,0,0 2,2,2,2
L80AA:  .byte TYPS_SHORT, $00, $00  ;SHORT 0,0,0,0 0,0,0,0
L80AD:  .byte TYPS_SHORT, $00, $00  ;SHORT 0,0,0,0 0,0,0,0
L80B0:  .byte TYPS_SHORT, $A2, $AA  ;SHORT 2,2,0,2 2,2,2,2
L80B3:  .byte TYPS_SHORT, $00, $00  ;SHORT 0,0,0,0 0,0,0,0
L80B6:  .byte TYPS_SHORT, $00, $00  ;SHORT 0,0,0,0 0,0,0,0
L80B9:  .byte TYPS_SHORT, $00, $AA  ;SHORT 0,0,0,0 2,2,2,2
L80BC:  .byte TYPS_LONG, $AA, $00   ;LONG 2,2,2,2 0,0,0,0
L80BF:  .byte TYPS_SHORT, $00, $AA  ;SHORT 0,0,0,0 2,2,2,2
L80C2:  .byte TYPS_SHORT, $00, $00  ;SHORT 0,0,0,0 0,0,0,0
L80C5:  .byte TYPS_NXT              ;NEXT

TWDG31:          ;10 GUNS - 3 DOUBLES ACROSS BOTTOM - MEDIUM FLYING
L80C6:  .byte TYPS_SHORT, $00, $00  ;SHORT 0,0,0,0 0,0,0,0
L80C9:  .byte TYPS_SHORT, $C0, $30  ;SHORT 3,0,0,0 0,3,0,0
L80CC:  .byte TYPS_LONG, $0A, $0A   ;LONG 0,0,2,2 0,0,2,2
L80CF:  .byte TYPS_SHORT, $30, $C0  ;SHORT 0,3,0,0 3,0,0,0
L80D2:  .byte TYPS_SHORT, $00, $00  ;SHORT 0,0,0,0 0,0,0,0
L80D5:  .byte TYPS_SHORT, $C0, $30  ;SHORT 3,0,0,0 0,3,0,0
L80D8:  .byte TYPS_LONG, $0A, $0A   ;LONG 0,0,2,2 0,0,2,2
L80DB:  .byte TYPS_SHORT, $30, $C0  ;SHORT 0,3,0,0 3,0,0,0
L80DE:  .byte TYPS_SHORT, $00, $00  ;SHORT 0,0,0,0 0,0,0,0
L80E1:  .byte TYPS_SHORT, $C0, $30  ;SHORT 3,0,0,0 0,3,0,0
L80E4:  .byte TYPS_LONG, $0A, $0A   ;LONG 0,0,2,2 0,0,2,2
L80E7:  .byte TYPS_SHORT, $00, $00  ;SHORT 0,0,0,0 0,0,0,0
L80EA:  .byte TYPS_SHORT, $00, $00  ;SHORT 0,0,0,0 0,0,0,0
L80ED:  .byte TYPS_NXT              ;NEXT

TWDG32:          ;6 GUNS - 5 SINGLES - 6 HALVES -- STAY L, THEN STAY R - MEDIUM FLYING
L80EE:  .byte TYPS_SHORT, $02, $02  ;SHORT 0,0,0,2 0,0,0,2
L80F1:  .byte TYPS_LONG, $30, $80   ;LONG 0,3,0,0 2,0,0,0
L80F4:  .byte TYPS_LONG, $0C, $20   ;LONG 0,0,3,0 0,2,0,0
L80F7:  .byte TYPS_LONG, $C2, $0A   ;LONG 3,0,0,2 0,0,2,2
L80FA:  .byte TYPS_SHORT, $02, $02  ;SHORT 0,0,0,2 0,0,0,2
L80FD:  .byte TYPS_LONG, $0A, $C2   ;LONG 0,0,2,2 3,0,0,2
L8100:  .byte TYPS_LONG, $20, $0C   ;LONG 0,2,0,0 0,0,3,0
L8103:  .byte TYPS_LONG, $80, $30   ;LONG 2,0,0,0 0,3,0,0
L8106:  .byte TYPS_LONG, $02, $02   ;LONG 0,0,0,2 0,0,0,2
L8109:  .byte TYPS_NXT              ;NEXT

TWDG33:          ;10 GUNS - 10 SINGLES - MEDIUM FLYING
L810A:  .byte TYPS_SHORT, $02, $02  ;SHORT 0,0,0,2 0,0,0,2
L810D:  .byte TYPS_SHORT, $C0, $C0  ;SHORT 3,0,0,0 3,0,0,0
L8110:  .byte TYPS_SHORT, $20, $20  ;SHORT 0,2,0,0 0,2,0,0
L8113:  .byte TYPS_SHORT, $0E, $0E  ;SHORT 0,0,3,2 0,0,3,2
L8116:  .byte TYPS_SHORT, $08, $08  ;SHORT 0,0,2,0 0,0,2,0
L8119:  .byte TYPS_LONG, $00, $00   ;LONG 0,0,0,0 0,0,0,0
L811C:  .byte TYPS_SHORT, $02, $02  ;SHORT 0,0,0,2 0,0,0,2
L811F:  .byte TYPS_SHORT, $2C, $2C  ;SHORT 0,2,3,0 0,2,3,0
L8122:  .byte TYPS_SHORT, $80, $80  ;SHORT 2,0,0,0 2,0,0,0
L8125:  .byte TYPS_SHORT, $02, $02  ;SHORT 0,0,0,2 0,0,0,2
L8128:  .byte TYPS_LONG, $00, $00   ;LONG 0,0,0,0 0,0,0,0
L812B:  .byte TYPS_SHORT, $8C, $8C  ;SHORT 2,0,3,0 2,0,3,0
L812E:  .byte TYPS_SHORT, $20, $20  ;SHORT 0,2,0,0 0,2,0,0
L8131:  .byte TYPS_SHORT, $03, $03  ;SHORT 0,0,0,3 0,0,0,3
L8134:  .byte TYPS_NXT              ;NEXT

TWDG34:          ;10 GUNS - 9 SINGLES - MEDIUM FLYING
L8135:  .byte TYPS_SHORT, $03, $03  ;SHORT 0,0,0,3 0,0,0,3
L8138:  .byte TYPS_LONG, $02, $02   ;LONG 0,0,0,2 0,0,0,2
L813B:  .byte TYPS_SHORT, $08, $08  ;SHORT 0,0,2,0 0,0,2,0
L813E:  .byte TYPS_LONG, $B0, $B0   ;LONG 2,3,0,0 2,3,0,0
L8141:  .byte TYPS_LONG, $08, $08   ;LONG 0,0,2,0 0,0,2,0
L8144:  .byte TYPS_SHORT, $32, $32  ;SHORT 0,3,0,2 0,3,0,2
L8147:  .byte TYPS_LONG, $C8, $C8   ;LONG 3,0,2,0 3,0,2,0
L814A:  .byte TYPS_LONG, $80, $80   ;LONG 2,0,0,0 2,0,0,0
L814D:  .byte TYPS_SHORT, $20, $20  ;SHORT 0,2,0,0 0,2,0,0
L8150:  .byte TYPS_LONG, $0B, $0B   ;LONG 0,0,2,3 0,0,2,3
L8153:  .byte TYPS_NXT              ;NEXT

TWDG35:          ;10 GUNS - 2 SINGLES - 4 DOUBLES - 10 HALVES - HARD FLYING
L8154:  .byte TYPS_SHORT, $0E, $0E  ;SHORT 0,0,3,2 0,0,3,2
L8157:  .byte TYPS_LONG, $0A, $00   ;LONG 0,0,2,2 0,0,0,0
L815A:  .byte TYPS_SHORT, $A0, $A0  ;SHORT 2,2,0,0 2,2,0,0
L815D:  .byte TYPS_LONG, $00, $0A   ;LONG 0,0,0,0 0,0,2,2
L8160:  .byte TYPS_SHORT, $FA, $FA  ;SHORT 3,3,2,2 3,3,2,2
L8163:  .byte TYPS_LONG, $0A, $00   ;LONG 0,0,2,2 0,0,0,0
L8166:  .byte TYPS_SHORT, $A0, $A0  ;SHORT 2,2,0,0 2,2,0,0
L8169:  .byte TYPS_LONG, $00, $0A   ;LONG 0,0,0,0 0,0,2,2
L816C:  .byte TYPS_SHORT, $FA, $FA  ;SHORT 3,3,2,2 3,3,2,2
L816F:  .byte TYPS_LONG, $0A, $00   ;LONG 0,0,2,2 0,0,0,0
L8172:  .byte TYPS_SHORT, $02, $02  ;SHORT 0,0,0,2 0,0,0,2
L8175:  .byte TYPS_NXT              ;NEXT

TWDG36:          ;2 GUNS - 26 HALVES, 1 TRIPLE, 2 DOUBLES, 1 SINGLE - HARD FLYING
L8176:  .byte TYPS_SHORT, $AA, $2A  ;SHORT 2,2,2,2 0,2,2,2
L8179:  .byte TYPS_SHORT, $00, $00  ;SHORT 0,0,0,0 0,0,0,0
L817C:  .byte TYPS_SHORT, $AA, $03  ;SHORT 2,2,2,2 0,0,0,3
L817F:  .byte TYPS_LONG, $03, $AA   ;LONG 0,0,0,3 2,2,2,2
L8182:  .byte TYPS_SHORT, $AA, $00  ;SHORT 2,2,2,2 0,0,0,0
L8185:  .byte TYPS_SHORT, $00, $00  ;SHORT 0,0,0,0 0,0,0,0
L8188:  .byte TYPS_SHORT, $00, $00  ;SHORT 0,0,0,0 0,0,0,0
L818B:  .byte TYPS_SHORT, $AA, $8A  ;SHORT 2,2,2,2 2,0,2,2
L818E:  .byte TYPS_SHORT, $00, $00  ;SHORT 0,0,0,0 0,0,0,0
L8191:  .byte TYPS_SHORT, $00, $00  ;SHORT 0,0,0,0 0,0,0,0
L8194:  .byte TYPS_SHORT, $AA, $00  ;SHORT 2,2,2,2 0,0,0,0
L8197:  .byte TYPS_LONG, $00, $AA   ;LONG 0,0,0,0 2,2,2,2
L819A:  .byte TYPS_SHORT, $AA, $00  ;SHORT 2,2,2,2 0,0,0,0
L819D:  .byte TYPS_SHORT, $00, $00  ;SHORT 0,0,0,0 0,0,0,0
L81A0:  .byte TYPS_NXT              ;NEXT

TWDG37:          ;0 GUNS - 4 TRIPLES, 2 DOUBLES, 2 SINGLES, 2 HALFS - HARD FLYING
L81A1:  .byte TYPS_LONG, $2A, $2A   ;LONG 0,2,2,2 0,2,2,2
L81A4:  .byte TYPS_SHORT, $00, $00  ;SHORT 0,0,0,0 0,0,0,0
L81A7:  .byte TYPS_LONG, $A8, $A8   ;LONG 2,2,2,0 2,2,2,0
L81AA:  .byte TYPS_SHORT, $00, $00  ;SHORT 0,0,0,0 0,0,0,0
L81AD:  .byte TYPS_LONG, $2A, $2A   ;LONG 0,2,2,2 0,2,2,2
L81B0:  .byte TYPS_SHORT, $00, $00  ;SHORT 0,0,0,0 0,0,0,0
L81B3:  .byte TYPS_LONG, $A8, $A8   ;LONG 2,2,2,0 2,2,2,0
L81B6:  .byte TYPS_SHORT, $00, $00  ;SHORT 0,0,0,0 0,0,0,0
L81B9:  .byte TYPS_LONG, $8A, $AA   ;LONG 2,0,2,2 2,2,2,2
L81BC:  .byte TYPS_SHORT, $00, $00  ;SHORT 0,0,0,0 0,0,0,0
L81BF:  .byte TYPS_SHORT, $AA, $A2  ;SHORT 2,2,2,2 2,2,0,2
L81C2:  .byte TYPS_NXT              ;NEXT

TWDG41:          ;8 GUNS ONLY MIDDLE LEVELS - EASY FLYING
L81C3:  .byte TYPS_SHORT, $00, $00  ;SHORT 0,0,0,0 0,0,0,0
L81C6:  .byte TYPS_LONG, $30, $0C   ;LONG 0,3,0,0 0,0,3,0
L81C9:  .byte TYPS_SHORT, $00, $00  ;SHORT 0,0,0,0 0,0,0,0
L81CC:  .byte TYPS_LONG, $00, $00   ;LONG 0,0,0,0 0,0,0,0
L81CF:  .byte TYPS_LONG, $0C, $30   ;LONG 0,0,3,0 0,3,0,0
L81D2:  .byte TYPS_SHORT, $00, $00  ;SHORT 0,0,0,0 0,0,0,0
L81D5:  .byte TYPS_LONG, $30, $0C   ;LONG 0,3,0,0 0,0,3,0
L81D8:  .byte TYPS_SHORT, $00, $00  ;SHORT 0,0,0,0 0,0,0,0
L81DB:  .byte TYPS_LONG, $00, $00   ;LONG 0,0,0,0 0,0,0,0
L81DE:  .byte TYPS_LONG, $0C, $30   ;LONG 0,0,3,0 0,3,0,0
L81E1:  .byte TYPS_NXT              ;NEXT

TWDG42:          ;8 GUNS ALL LEVELS - EASY FLYING
L81E2:  .byte TYPS_LONG, $00, $00   ;LONG 0,0,0,0 0,0,0,0
L81E5:  .byte TYPS_SHORT, $00, $00  ;SHORT 0,0,0,0 0,0,0,0
L81E8:  .byte TYPS_SHORT, $00, $00  ;SHORT 0,0,0,0 0,0,0,0
L81EB:  .byte TYPS_SHORT, $00, $00  ;SHORT 0,0,0,0 0,0,0,0
L81EE:  .byte TYPS_LONG, $00, $00   ;LONG 0,0,0,0 0,0,0,0
L81F1:  .byte TYPS_LONG, $3C, $3C   ;LONG 0,3,3,0 0,3,3,0
L81F4:  .byte TYPS_LONG, $00, $00   ;LONG 0,0,0,0 0,0,0,0
L81F7:  .byte TYPS_LONG, $C3, $C3   ;LONG 3,0,0,3 3,0,0,3
L81FA:  .byte TYPS_SHORT, $00, $00  ;SHORT 0,0,0,0 0,0,0,0
L81FD:  .byte TYPS_LONG, $00, $00   ;LONG 0,0,0,0 0,0,0,0
L8200:  .byte TYPS_NXT              ;NEXT

TWDG43:          ;16 GUNS ALL LEVELS - EASY FLYING - MANY SHOTS
L8201:  .byte TYPS_SHORT, $00, $00  ;SHORT 0,0,0,0 0,0,0,0
L8204:  .byte TYPS_SHORT, $C0, $C0  ;SHORT 3,0,0,0 3,0,0,0
L8207:  .byte TYPS_LONG, $30, $30   ;LONG 0,3,0,0 0,3,0,0
L820A:  .byte TYPS_SHORT, $0C, $0C  ;SHORT 0,0,3,0 0,0,3,0
L820D:  .byte TYPS_SHORT, $03, $03  ;SHORT 0,0,0,3 0,0,0,3
L8210:  .byte TYPS_LONG, $00, $00   ;LONG 0,0,0,0 0,0,0,0
L8213:  .byte TYPS_SHORT, $C0, $C0  ;SHORT 3,0,0,0 3,0,0,0
L8216:  .byte TYPS_LONG, $30, $30   ;LONG 0,3,0,0 0,3,0,0
L8219:  .byte TYPS_SHORT, $0C, $0C  ;SHORT 0,0,3,0 0,0,3,0
L821C:  .byte TYPS_SHORT, $03, $03  ;SHORT 0,0,0,3 0,0,0,3
L821F:  .byte TYPS_LONG, $00, $00   ;LONG 0,0,0,0 0,0,0,0
L8222:  .byte TYPS_SHORT, $00, $00  ;SHORT 0,0,0,0 0,0,0,0
L8225:  .byte TYPS_NXT              ;NEXT

TWDG44:          ;8 GUNS - 6 SINGLES, 1 DOUBLE - MEDIUM FLYING
L8226:  .byte TYPS_LONG, $00, $00   ;LONG 0,0,0,0 0,0,0,0
L8229:  .byte TYPS_LONG, $02, $02   ;LONG 0,0,0,2 0,0,0,2
L822C:  .byte TYPS_LONG, $38, $38   ;LONG 0,3,2,0 0,3,2,0
L822F:  .byte TYPS_SHORT, $A3, $A3  ;SHORT 2,2,0,3 2,2,0,3
L8232:  .byte TYPS_SHORT, $02, $02  ;SHORT 0,0,0,2 0,0,0,2
L8235:  .byte TYPS_LONG, $8C, $8C   ;LONG 2,0,3,0 2,0,3,0
L8238:  .byte TYPS_LONG, $02, $02   ;LONG 0,0,0,2 0,0,0,2
L823B:  .byte TYPS_LONG, $38, $38   ;LONG 0,3,2,0 0,3,2,0
L823E:  .byte TYPS_LONG, $00, $00   ;LONG 0,0,0,0 0,0,0,0
L8241:  .byte TYPS_NXT              ;NEXT

TWDG45:          ;12 GUNS - 1 SINGLE - 8 STAGGERED HALVES - MEDIUM FLYING
L8242:  .byte TYPS_SHORT, $02, $02  ;SHORT 0,0,0,2 0,0,0,2
L8245:  .byte TYPS_SHORT, $00, $00  ;SHORT 0,0,0,0 0,0,0,0
L8248:  .byte TYPS_LONG, $32, $0C   ;LONG 0,3,0,2 0,0,3,0
L824B:  .byte TYPS_SHORT, $C0, $32  ;SHORT 3,0,0,0 0,3,0,2
L824E:  .byte TYPS_LONG, $00, $00   ;LONG 0,0,0,0 0,0,0,0
L8251:  .byte TYPS_SHORT, $83, $E3  ;SHORT 2,0,0,3 3,2,0,3
L8254:  .byte TYPS_SHORT, $30, $00  ;SHORT 0,3,0,0 0,0,0,0
L8257:  .byte TYPS_LONG, $03, $00   ;LONG 0,0,0,3 0,0,0,0
L825A:  .byte TYPS_SHORT, $00, $B2  ;SHORT 0,0,0,0 2,3,0,2
L825D:  .byte TYPS_SHORT, $AC, $0C  ;SHORT 2,2,3,0 0,0,3,0
L8260:  .byte TYPS_LONG, $00, $00   ;LONG 0,0,0,0 0,0,0,0
L8263:  .byte TYPS_SHORT, $00, $00  ;SHORT 0,0,0,0 0,0,0,0
L8266:  .byte TYPS_NXT              ;NEXT

TWDG53:          ;16 GUNS ONLY TOP AND BOTTOM - EASY FLYING
L8267:  .byte TYPS_LONG, $00, $00   ;LONG 0,0,0,0 0,0,0,0
L826A:  .byte TYPS_LONG, $00, $00   ;LONG 0,0,0,0 0,0,0,0
L826D:  .byte TYPS_SHORT, $C3, $C3  ;SHORT 3,0,0,3 3,0,0,3
L8270:  .byte TYPS_LONG, $00, $00   ;LONG 0,0,0,0 0,0,0,0
L8273:  .byte TYPS_SHORT, $C3, $C3  ;SHORT 3,0,0,3 3,0,0,3
L8276:  .byte TYPS_LONG, $00, $00   ;LONG 0,0,0,0 0,0,0,0
L8279:  .byte TYPS_SHORT, $C3, $C3  ;SHORT 3,0,0,3 3,0,0,3
L827C:  .byte TYPS_LONG, $00, $00   ;LONG 0,0,0,0 0,0,0,0
L827F:  .byte TYPS_SHORT, $C3, $C3  ;SHORT 3,0,0,3 3,0,0,3
L8282:  .byte TYPS_LONG, $00, $00   ;LONG 0,0,0,0 0,0,0,0
L8285:  .byte TYPS_NXT              ;NEXT

TWDG54:          ;8 GUNS LEFT SIDE THEN RIGHT - EASY FLYING
L8286:  .byte TYPS_SHORT, $00, $00  ;SHORT 0,0,0,0 0,0,0,0
L8289:  .byte TYPS_LONG, $00, $00   ;LONG 0,0,0,0 0,0,0,0
L828C:  .byte TYPS_SHORT, $C3, $00  ;SHORT 3,0,0,3 0,0,0,0
L828F:  .byte TYPS_LONG, $00, $00   ;LONG 0,0,0,0 0,0,0,0
L8292:  .byte TYPS_LONG, $3C, $00   ;LONG 0,3,3,0 0,0,0,0
L8295:  .byte TYPS_SHORT, $00, $C3  ;SHORT 0,0,0,0 3,0,0,3
L8298:  .byte TYPS_LONG, $00, $00   ;LONG 0,0,0,0 0,0,0,0
L829B:  .byte TYPS_SHORT, $00, $3C  ;SHORT 0,0,0,0 0,3,3,0
L829E:  .byte TYPS_LONG, $00, $00   ;LONG 0,0,0,0 0,0,0,0
L82A1:  .byte TYPS_LONG, $00, $00   ;LONG 0,0,0,0 0,0,0,0
L82A4:  .byte TYPS_NXT              ;NEXT

TWDG55:          ;3 GUNS - 4 SINGLES - 4 DOUBLES - 4 HALVES -- JOG R,L,R,L - HARD FLYING
L82A5:  .byte TYPS_LONG, $AA, $8A   ;LONG 2,2,2,2 2,0,2,2
L82A8:  .byte TYPS_LONG, $00, $00   ;LONG 0,0,0,0 0,0,0,0
L82AB:  .byte TYPS_LONG, $BA, $AA   ;LONG 2,3,2,2 2,2,2,2
L82AE:  .byte TYPS_LONG, $00, $00   ;LONG 0,0,0,0 0,0,0,0
L82B1:  .byte TYPS_LONG, $AA, $AB   ;LONG 2,2,2,2 2,2,2,3
L82B4:  .byte TYPS_LONG, $00, $00   ;LONG 0,0,0,0 0,0,0,0
L82B7:  .byte TYPS_LONG, $AE, $AA   ;LONG 2,2,3,2 2,2,2,2
L82BA:  .byte TYPS_LONG, $00, $00   ;LONG 0,0,0,0 0,0,0,0
L82BD:  .byte TYPS_NXT              ;NEXT

TWDG92:          ;6 GUNS - 8 PANEL DIVIDER WITH CATWALK AT TOP
L82BE:  .byte TYPS_SHORT, $14, $14  ;SHORT 0,1,1,0 0,1,1,0
L82C1:  .byte TYPS_SHORT, $BF, $BF  ;SHORT 2,3,3,3 2,3,3,3
L82C4:  .byte TYPS_SHORT, $14, $14  ;SHORT 0,1,1,0 0,1,1,0
L82C7:  .byte TYPS_NXT              ;NEXT

TWDG93:          ;0 GUNS - DIVIDER WITH ONE CATWALK AT TOP
L82C8:  .byte TYPS_SHORT, $00, $00  ;SHORT 0,0,0,0 0,0,0,0
L82CB:  .byte TYPS_SHORT, $95, $95  ;SHORT 2,1,1,1 2,1,1,1
L82CE:  .byte TYPS_SHORT, $00, $00  ;SHORT 0,0,0,0 0,0,0,0
L82D1:  .byte TYPS_NXT              ;NEXT

TWDG94:          ;0 GUNS - DIVIDER WITH ONE CATWALK AT BOTTOM
L82D2:  .byte TYPS_SHORT, $00, $00  ;SHORT 0,0,0,0 0,0,0,0
L82D5:  .byte TYPS_SHORT, $56, $56  ;SHORT 1,1,1,2 1,1,1,2
L82D8:  .byte TYPS_SHORT, $00, $00  ;SHORT 0,0,0,0 0,0,0,0
L82DB:  .byte TYPS_NXT              ;NEXT

TWDG95:          ;0 GUNS - 8 PANEL DIVIDER
L82DC:  .byte TYPS_SHORT, $00, $00  ;SHORT 0,0,0,0 0,0,0,0
L82DF:  .byte TYPS_SHORT, $55, $55  ;SHORT 1,1,1,1 1,1,1,1
L82E2:  .byte TYPS_SHORT, $00, $00  ;SHORT 0,0,0,0 0,0,0,0
L82E5:  .byte TYPS_NXT              ;NEXT

TWDG96:          ;6 GUNS - 8 PANEL DIVDER WITH CATWALK AT BOTTOM
L82E6:  .byte TYPS_SHORT, $14, $14  ;SHORT 0,1,1,0 0,1,1,0
L82E9:  .byte TYPS_SHORT, $FE, $FE  ;SHORT 3,3,3,2 3,3,3,2
L82EC:  .byte TYPS_SHORT, $14, $14  ;SHORT 0,1,1,0 0,1,1,0
L82EF:  .byte TYPS_NXT              ;NEXT

TWDG97:          ;8 GUNS - 8 PANELS -- HARD DIVIDER
L82F0:  .byte TYPS_SHORT, $14, $14  ;SHORT 0,1,1,0 0,1,1,0
L82F3:  .byte TYPS_SHORT, $FF, $FF  ;SHORT 3,3,3,3 3,3,3,3
L82F6:  .byte TYPS_SHORT, $14, $14  ;SHORT 0,1,1,0 0,1,1,0
L82F9:  .byte TYPS_NXT              ;NEXT

TWDG98:          ;0 GUNS - 34 PANELS -- EASY PORT
L82FA:  .byte TYPS_SHORT, $55, $55  ;SHORT 1,1,1,1 1,1,1,1
L82FD:  .byte TYPS_SHORT, $15, $15  ;SHORT 0,1,1,1 0,1,1,1
L8300:  .byte TYPS_SHORT, $05, $05  ;SHORT 0,0,1,1 0,0,1,1
L8303:  .byte TYPS_SHORT, $00, $00  ;SHORT 0,0,0,0 0,0,0,0
L8306:  .byte TYPS_SHORT, $05, $05  ;SHORT 0,0,1,1 0,0,1,1
L8309:  .byte TYPS_SHORT, $00, $00  ;SHORT 0,0,0,0 0,0,0,0
L830C:  .byte TYPS_SHORT, $05, $05  ;SHORT 0,0,1,1 0,0,1,1
L830F:  .byte TYPS_SHORT, $00, $00  ;SHORT 0,0,0,0 0,0,0,0
L8312:  .byte TYPS_SHORT, $05, $05  ;SHORT 0,0,1,1 0,0,1,1
L8315:  .byte TYPS_SHORT, $00, $00  ;SHORT 0,0,0,0 0,0,0,0
L8318:  .byte TYPS_SHORT, $01, $01  ;SHORT 0,0,0,1 0,0,0,1
L831B:  .byte TYPS_SHORT, $00, $00  ;SHORT 0,0,0,0 0,0,0,0
L831E:  .byte TYPS_SHORT, $01, $01  ;SHORT 0,0,0,1 0,0,0,1
L8321:  .byte TYPS_PORT, $00, $00   ;PORT 0,0,0,0 0,0,0,0
L8324:  .byte TYPS_END              ;END

TWDG99:          ;16 GUNS - 8 PANELS -- HARD PORT
L8325:  .byte TYPS_SHORT, $00, $00  ;SHORT 0,0,0,0 0,0,0,0
L8328:  .byte TYPS_LONG, $2A, $2A   ;LONG 0,2,2,2 0,2,2,2
L832B:  .byte TYPS_SHORT, $00, $00  ;SHORT 0,0,0,0 0,0,0,0
L832E:  .byte TYPS_LONG, $40, $40   ;LONG 1,0,0,0 1,0,0,0
L8331:  .byte TYPS_LONG, $10, $10   ;LONG 0,1,0,0 0,1,0,0
L8334:  .byte TYPS_LONG, $04, $04   ;LONG 0,0,1,0 0,0,1,0
L8337:  .byte TYPS_LONG, $01, $01   ;LONG 0,0,0,1 0,0,0,1
L833A:  .byte TYPS_SHORT, $FF, $FF  ;SHORT 3,3,3,3 3,3,3,3
L833D:  .byte TYPS_PORT, $FF, $FF   ;PORT 3,3,3,3 3,3,3,3
L8340:  .byte TYPS_END              ;END

;------------------------------------------------------------------------------
; NWBASE - VIEW STARBASE--VWBASE,BSGNDT,BSVBOT,BSVSID,BSVSDS,BSVFAR
;------------------------------------------------------------------------------
NWBASE:
L8341:  LDA  #$00                   ;SETUP PROTON TORP INFO
L8343:  STA  PT_LZF                 ;NO FIRE VIA LAZAR YET
L8345:  STA  PT_LIV                 ;PROTON TORP NOT LIVE YET
L8347:  LDX  #PANEL
L834A:  LDA  #$00                   ;CLEAR OUT ALL PANELS
L834C:  STA  ,X+
L834E:  CMPX #PANELZ
L8351:  BLO  L834C                  ;HSEND
L8353:  LDB  BS_WAV                 ;WHICH TRENCH TO USE
L8356:  LSLB
L8357:  LDX  #TPIE                  ;START OF TABLE
L835A:  ABX
L835B:  CMPX #TPIEZ                 ;TABLE LIMIT
L835E:  BLO  L8365                  ;IFHS  ?PAST END OF TABLE?
L8360:  LDU  #RPIE                  ;THEN DO RANDOM PIE
L8363:  BRA  L8367                  ;ELSE  ELSE USE PRE-DEFINED PIES
L8365:  LDU  ,X                     ;START OF PIE
L8367:  STU  PI_NRW                 ;NEAR POINTER STARTS HERE
L836A:  STU  PI_FRW                 ;FAR POINTER BEGINS HERE ALSO
L836D:  LDU  ,U                     ;U-->NOW SETUP WEDGE INFO
L836F:  LDD  #$0000
L8372:  STA  WG_FCU                 ;START COLOR AT SAME SPOT
L8375:  STD  WG_NRL                 ;NEAR LOC STARTS AT ZERO
L8378:  STD  WG_FRL                 ;FAR LOC STARTS AT ZERO
L837B:  STA  BS_EFL                 ;NO END IN SIGHT YET
L837D:  STA  BS_PFL                 ;NO PORT IN SIGHT YET
L837F:  STU  WG_NRP
L8382:  STU  WG_FRP                 ;FAR POINTER STARTS AT BEGINNING
L8385:  JSR  IWEDGE                 ;INIT THE WEDGE HERE
L8388:  JSR  NWFAR                  ;GET A NEW FAR(MIN PIE SIZE IS TWO WEDGES)
L838B:  JSR  DOFAR                  ;.REPT 8  START OFF WITH SOME WEDGES DEFINED
L838E:  JSR  DOFAR
L8391:  JSR  DOFAR
L8394:  JSR  DOFAR
L8397:  JSR  DOFAR
L839A:  JSR  DOFAR
L839D:  JSR  DOFAR
L83A0:  JSR  DOFAR
L83A3:  RTS

;------------------------------------------------------------------------------
; GNBASE - GEN A NEW BASE PIE
;------------------------------------------------------------------------------
GNBASE:
L83A4:  LDU  #RPIE                  ;NEW RAM PIE
L83A7:  LDX  #PIEXX                 ;FORMAT CONTROL
L83AA:  LDD  ,X++
L83AC:  STD  ,U++
L83AE:  CMPU #RPIEZ
L83B2:  BLO  L83AA                  ;HSEND
L83B4:  LDU  #RPIE+4
L83B7:  LDX  #TWDGXX                ;LIST OF WEDGES TO USE
L83BA:  LDA  #(TWDGXZ-TWDGXX)/2     ;# OF ENTRIES
L83BC:  LDB  P_RND1
L83BF:  MUL
L83C0:  LSLA                        ;WORD ENTRIES
L83C1:  LDD  A,X
L83C3:  STD  ,U                     ;PUT ENTRY AWAY
L83C5:  LEAU 4,U                    ;SKIP PAST DIVIDER PANEL
L83C7:  CMPU #RPIEZ
L83CB:  BLO  L83BA                  ;HSEND
L83CD:  RTS

;------------------------------------------------------------------------------
; DOFAR - UPDATE FAR INFO IF ROOM
;   PAINFUL MATH -- 8000 WRAPAROUND HANDLER
;------------------------------------------------------------------------------
DOFAR:
L83CE:  LDA  BS_EFL
L83D0:  BNE  L8407                  ;IFEQ  ?STILL IN VALID TRENCH?
L83D2:  LDU  WG_FRP
L83D5:  LEAU WGS_IZ,U               ;POINT TO POTENTIAL FUTURE WEDGE
L83D7:  LDA  WGS_TYP,U
L83D9:  CMPA #TYPS_NXT
L83DB:  BNE  L83E2                  ;IFEQ  ?GOTO NEXT PIE?
L83DD:  LDU  PI_FRW
L83E0:  LDU  PIS_WDG+PIS_IZ,U       ;NEXT WEDGE POINTER
L83E2:  LDB  WGS_TYP,U
L83E4:  CMPB #TYPS_SHORT
L83E6:  BNE  L83ED                  ;IFEQ  ?SHORT WEDGE?
L83E8:  LDD  #$0800
L83EB:  BRA  L83F9                  ;ELSE  ELSE IS LONG WEDGE
L83ED:  CMPB #TYPS_END
L83EF:  BNE  L83F6                  ;IFEQ  ?END WEDGE?
L83F1:  LDD  #$0000                 ;DO HIM IMMEDIATELY
L83F4:  BRA  L83F9                  ;ELSE  ALL ELSE NEEDS 1000 SPACE FOR SAFETY
L83F6:  LDD  #$1000
L83F9:  ADDD WG_FTL                 ;LOC + LENGTH GIVES NEW FUTURE POSITION
L83FC:  SUBD WG_NRL                 ;MINUS NEAR LOC FOR DISTANCE SPREAD
L83FF:  SUBD #$6000
L8402:  BHI  L8407                  ;IFLS  ?WILL ALL OF NEW WEDGES FIT INTO 8000?
L8404:  JSR  NWFAR
L8407:  RTS

;------------------------------------------------------------------------------
; NWFAR - ROOM EXISTS, FIND NEW FAR
;------------------------------------------------------------------------------
NWFAR:
L8408:  LDU  WG_FRP
L840B:  LDB  WGS_TYP,U
L840D:  CMPB #TYPS_SHORT
L840F:  BNE  L8416                  ;IFEQ  ?SHORT WEDGE?
L8411:  LDD  #$0800
L8414:  BRA  L8419                  ;ELSE  ELSE IS LONG WEDGE
L8416:  LDD  #$1000
L8419:  ADDD WG_FRL
L841C:  STD  WG_FRL                 ;NEW LOC FOR NEXT FAR WEDGE
L841F:  LEAU WGS_IZ,U
L8421:  LDB  WGS_TYP,U
L8423:  CMPB #TYPS_NXT
L8425:  BNE  L8431                  ;IFEQ  ?CONTINUE TO NEXT PIE SECTION?
L8427:  LDU  PI_FRW
L842A:  LEAU PIS_IZ,U
L842C:  STU  PI_FRW                 ;GET NEXT PI SECTION
L842F:  LDU  PIS_WDG,U
L8431:  STU  WG_FRP                 ;NEXT FAR WEDGE

;------------------------------------------------------------------------------
; IWEDGE - INIT FAR WEDGE INFO
;------------------------------------------------------------------------------
IWEDGE:
L8434:  LDU  WG_FRP
L8437:  LDB  WGS_TYP,U
L8439:  CMPB #TYPS_END
L843B:  BNE  L8447                  ;IFEQ  ?END OF TRENCH?
L843D:  LDD  WG_FRL                 ;NEW FAR LOCATION
L8440:  STD  BS_ELC                 ;SETS END LOCATION
L8442:  LDA  #$FF
L8444:  STA  BS_EFL                 ;SET END FLAG
L8446:  RTS
L8447:  LDB  WGS_TYP,U
L8449:  CMPB #TYPS_PORT
L844B:  BNE  L846A                  ;IFEQ  ?GENUINE THERMAL EXHAUST PORT?
L844D:  LDD  WG_FRL
L8450:  STD  BS_PLC                 ;LOCATION OF THE PORT
L8452:  LDA  #$FF
L8454:  STA  BS_PFL                 ;SET PANEL FLAG
L8456:  LDA  #$00                   ;SETUP PROTON TORP INFO
L8458:  STA  PT_LZF                 ;NO FIRE VIA LAZAR YET
L845A:  STA  PT_LIV                 ;PROTON TORP NOT LIVE YET
L845C:  LDA  Q_FRC
L845F:  BNE  L846A                  ;IFEQ  ?DID THE PLAYER USE THE FORCE IN THE TRENCH?
L8461:  INC  Q_FRC                  ;MARK SUCCESS
L8464:  JSR  SCRFRC                 ;SCORE ONE FOR ASSERTIVENESS TRAINING(FORCEFUL)
L8467:  LDU  WG_FRP                 ;RESTORE MAJOR POINTER
L846A:  LDB  WGS_TYP,U
L846C:  CMPB #TYPS_SHORT
L846E:  BNE  L8475                  ;IFEQ  ?SHORT WEDGE?
L8470:  LDD  #$0800
L8473:  BRA  L8478                  ;ELSE  ELSE IS LONG WEDGE
L8475:  LDD  #$1000
L8478:  ADDD WG_FRL                 ;ADD CURRENT LOC TO CURRENT SIZE
L847B:  STD  WG_FTL                 ;CALC FUTURE LOC
L847E:  LDB  WG_FRL                 ;LOC OF NEW FAR PANEL
L8481:  LSRB                        ;/8 TO HANDLE 800 LENGTHS
L8482:  LSRB
L8483:  LSRB
L8484:  ANDB #$0F                   ;DEPTH ONLY SEES 8000 FORWARD
L8486:  LDX  #PNLW
L8489:  LDA  WGS_PNL,U
L848B:  STA  B,X                    ;SAVE NEW PANEL DESCRIPTORS
L848D:  LDX  #PNRW                  ;RIGHT WALL
L8490:  LDA  WGS_PNR,U
L8492:  STA  B,X
L8494:  RTS

;------------------------------------------------------------------------------
; DOBASE - FIRES BASES SHOTS  (comment at the call)
;------------------------------------------------------------------------------
DOBASE:
L8495:  LDA  PT_LIV                 ;?NO PROTON YET?
L8497:  BNE  L84B5                  ;IFEQ  THEN ALLOW SHOTS
L8499:  LDB  WV_HRD
L849C:  CMPB #$07
L849E:  BLS  L84A2                  ;IFHI  ?MAX DIFFICULTY?
L84A0:  LDB  #$07
L84A2:  LSLB                        ;2 BYTE ENTRIES
L84A3:  LDU  #TGPROB
L84A6:  LEAU B,U                    ;ACCESS INTO PROBABILITY TABLE
L84A8:  LDA  FRAME+1
L84AA:  ANDA ,U
L84AC:  BNE  L84B5                  ;IFEQ  ?APPROPRIATE TIME INTERVAL?
L84AE:  LDA  1,U
L84B0:  STA  BS_PRB                 ;PROB FOR ANY ONE GUN TO FIRE
L84B2:  JSR  BSGUN                  ;TRY FOR A BASE GUN
L84B5:  RTS

TGPROB:          ;GUN SHOOTING PROB, TIMER MASK(0F=1 SEC)
;PROB COMPARE (0C0 = 25%)
L84B6:  .byte $0F, $80
L84B8:  .byte $0F, $60
L84BA:  .byte $0F, $40
L84BC:  .byte $0F, $20
L84BE:  .byte $07, $60
L84C0:  .byte $07, $20
L84C2:  .byte $03, $60
L84C4:  .byte $03, $20

;------------------------------------------------------------------------------
; BSGUN - TRY FOR A BASE GUN  (comment at the call)
;------------------------------------------------------------------------------
BSGUN:
L84C6:  LDD  #$F800
L84C9:  ANDA MS_TX+M_S1             ;GET BEGINNING OF CLOSEST PANEL
L84CC:  ADDA #$24                   ;(DONT SHOOT IF TOO CLOSE)+(OFFSET TO CENTER)
L84CE:  STD  M_X0                   ;USE X0,Y0,Z0 FOR GUN POSITION
L84D1:  LDA  M_X0
L84D4:  LSRA
L84D5:  LSRA
L84D6:  LSRA
L84D7:  ANDA #$0F
L84D9:  STA  BS_DSP
L84DB:  LDD  #$FE00
L84DE:  STD  M_Z0                   ;START AT MID OF BOTTOM PANEL
L84E1:  LDD  #$FC80
L84E4:  STD  M_Y0                   ;GUN BARREL ON LEFT WALL
L84E7:  LDX  #PNLW                  ;PROCESS LEFT WALL PANELS
L84EA:  LDB  BS_DSP
L84EC:  LDA  B,X
L84EE:  STA  BS_FLG
L84F0:  ANDA #$C0
L84F2:  CMPA #$C0
L84F4:  BNE  L8522                  ;IFEQ  ?FOUND A LEFT PANEL BUNKER?
L84F6:  LDD  MS_TZ+M_S1
L84F9:  SUBD M_Z0
L84FC:  BLT  L8522                  ;IFGE  ?PLAYER ABOVE BUNKER?
L84FE:  SUBD #$0400
L8501:  BGE  L850F                  ;IFLT  ?AND CLOSE BY?
L8503:  LDA  P_RND1
L8506:  CMPA BS_PRB
L8508:  BLO  L850D                  ;IFHS  ?PROB SAYS TO FIRE THIS ONE?
L850A:  JSR  FRPLGN                 ;FIRE LEFT PANEL GUN
L850D:  BRA  L8522                  ;ELSE  ELSE PLAYER IS FAR ABOVE, SHOOT LESS OFTEN
L850F:  SUBD #$0400
L8512:  BGE  L8522                  ;IFLT  ?WITHIN ONE LOWER RANGE?
L8514:  LDA  P_RND1
L8517:  LDB  P_RND1
L851A:  MUL
L851B:  CMPA BS_PRB
L851D:  BLO  L8522                  ;IFHS  ?PROB SAYS TO FIRE THIS ONE?
L851F:  JSR  FRPLGN                 ;FIRE LEFT PANEL GUN
L8522:  LDD  M_Z0
L8525:  SUBD #$0400
L8528:  STD  M_Z0
L852B:  LDA  BS_FLG
L852D:  LSLA
L852E:  LSLA
L852F:  BNE  L84EE                  ;EQEND  LOOP TILL NO MORE PANELS IN THIS SECTION
L8531:  LDD  #$FE00
L8534:  STD  M_Z0                   ;START AT MID OF BOTTOM PANEL
L8537:  LDD  #$0380
L853A:  STD  M_Y0                   ;GUN BARREL ON RIGHT WALL
L853D:  LDX  #PNRW                  ;PROCESS RIGHT WALL PANELS
L8540:  LDB  BS_DSP
L8542:  LDA  B,X
L8544:  STA  BS_FLG
L8546:  ANDA #$C0
L8548:  CMPA #$C0
L854A:  BNE  L8578                  ;IFEQ  ?FOUND A RIGHT PANEL BUNKER?
L854C:  LDD  MS_TZ+M_S1
L854F:  SUBD M_Z0
L8552:  BLT  L8578                  ;IFGE  ?PLAYER ABOVE BUNKER?
L8554:  SUBD #$0400
L8557:  BGE  L8565                  ;IFLT  ?AND CLOSE BY?
L8559:  LDA  P_RND1
L855C:  CMPA BS_PRB
L855E:  BLO  L8563                  ;IFHS  ?PROB SAYS TO FIRE THIS ONE?
L8560:  JSR  FRPRGN                 ;FIRE RIGHT PANEL GUN
L8563:  BRA  L8578                  ;ELSE  ELSE PLAYER IS FAR ABOVE, SHOOT LESS OFTEN
L8565:  SUBD #$0400
L8568:  BGE  L8578                  ;IFLT  ?WITHIN RANGE OF ONE LOWER?
L856A:  LDA  P_RND1
L856D:  LDB  P_RND1
L8570:  MUL
L8571:  CMPA BS_PRB
L8573:  BLO  L8578                  ;IFHS  ?PROB SAYS TO FIRE THIS ONE?
L8575:  JSR  FRPRGN                 ;FIRE RIGHT PANEL GUN
L8578:  LDD  M_Z0
L857B:  SUBD #$0400                 ;GO DOWN ONE PANEL
L857E:  STD  M_Z0
L8581:  LDA  BS_FLG
L8583:  LSLA
L8584:  LSLA
L8585:  BNE  L8544                  ;EQEND  LOOP TILL NO MORE PANELS IN THIS SECTION
L8587:  LDD  M_X0
L858A:  ADDD #$0800                 ;GET NEXT PANEL
L858D:  STD  M_X0
L8590:  SUBD MS_TX+M_S1
L8593:  SUBD #$6000                 ;FURTHEST AWAY FIRING BUNKER
L8596:  LBLO L84D1                  ;HSEND  FINISH WITH LAST PANEL
L859A:  RTS

;------------------------------------------------------------------------------
; VWBASE - VIEW STAR BASE  (comment at the calls)
;------------------------------------------------------------------------------
VWBASE:
L859B:  LDA  MS_TX+M_U1
L859E:  LSRA
L859F:  LSRA
L85A0:  LSRA
L85A1:  ANDA #$0F                   ;GEN CURRENT DISP INTO PANEL BLOCKS
L85A3:  CMPA WG_FCD
L85A6:  BEQ  L85DE                  ;IFNE  ?DIFFERENT FROM CURRENT WEDGE DISP?
L85A8:  LDB  WG_FCD                 ;PROCESS OLD WEDGE
L85AB:  STA  WG_FCD                 ;SAVE NEW WEDGE DISP
L85AE:  LDX  #PNLW                  ;CHECK LEFT WALL FIRST
L85B1:  LDA  B,X
L85B3:  LSLA                        ;ONE BIT IN CARRY, OTHER IN SIGN
L85B4:  BCC  L85BD                  ;IFCS  ?2 OR 3?
L85B6:  BMI  L85BD                  ;IFPL  ?FORCE FIELD (MUST BE A 2)
L85B8:  INC  WG_FCU                 ;THEN UPDATE FORCE FIELD DISTANCE CUE
L85BB:  BRA  VWBASE_30              ;J ONE IS ENUF
L85BD:  LSLA                        ;MOVE OVER SECOND BIT
L85BE:  BNE  L85B3                  ;EQEND  NEXT PANEL
L85C0:  LDX  #PNRW                  ;CHECK RIGHT WALL LAST
L85C3:  LDA  B,X
L85C5:  LSLA                        ;HI BIT IN CARRY, LO BIT IN SIGN
L85C6:  BCC  L85CF                  ;IFCS  ?A 2 OR 3?
L85C8:  BMI  L85CF                  ;IFPL  ?FORCE FIELD IN THIS WEDGE (MUST BE A 2)?
L85CA:  INC  WG_FCU                 ;THEN UPDATE FORCE FIELD DISTANCE CUE
L85CD:  BRA  VWBASE_30              ;J ONE FF IS SUFFICIENT
L85CF:  LSLA                        ;MOVE SECOND OF TWO BIT TYPE OUT OF BYTE
L85D0:  BNE  L85C5                  ;EQEND  NEXT PANEL

VWBASE_30:
L85D2:  LDA  #$00                   ;CLEAR OUT OLD WALL
L85D4:  LDX  #PNLW
L85D7:  STA  B,X
L85D9:  LDX  #PNRW
L85DC:  STA  B,X
L85DE:  JSR  VWPANEL
L85E1:  JSR  BSVBOT                 ;VIEW BOTTOM LINES
L85E4:  JSR  BSVSID                 ;VIEW SIDES
L85E7:  JSR  BSVFAR
L85EA:  LDA  BS_PFL
L85EC:  BEQ  L85F1                  ;IFNE
L85EE:  JSR  BSVPORT                ;VIEW PORTHOLE
L85F1:  LDA  BS_EFL
L85F3:  BEQ  L85F8                  ;IFNE
L85F5:  JSR  BSVEND                 ;VIEW FINAL END OF TRENCH
L85F8:  RTS                         ;*** NEED NEW STAR VIEW VIA TOP SLOT IN TRENCH

;------------------------------------------------------------------------------
; BSVBOT - VIEW BOTTOM OF BASE TRENCH
;------------------------------------------------------------------------------
BSVBOT:
L85F9:  LDD  #$0000
L85FC:  STD  MS_TX+M_U1             ;KEEP VIEWER AT START OF TRENCH
L85FF:  LDD  #(VGCGRN*$100)+VGCOPC-$10
L8602:  STD  ,Y++
L8604:  LDU  #TBSBL                 ;BOTTOM LINE TABLE

BSVBOT_10:
L8607:  LDA  BS_EFL
L8609:  BEQ  BSVBOT_16              ;IFNE  ?END IN VIEW YET?
L860B:  LDD  BS_ELC
L860D:  SUBD MS_TX+M_S1
L8610:  CMPD #$7000
L8614:  BHI  BSVBOT_16              ;?LS? LESS THAN 7000 AWAY?
L8616:  BRA  L861B                  ;ELSE  ELSE NO END IN VIEW

BSVBOT_16:
L8618:  LDD  #$7000
L861B:  STD  M_X0
L861E:  LDD  ,U                     ;Y OFFSET
L8620:  STD  M_Y0
L8623:  LDD  2,U                    ;Z OFFSET
L8625:  STD  M_Z0
L8628:  LDD  #MS_X0BC
L862B:  STD  M_BIC
L862E:  LDA  #MS_PSB2
L8630:  JSR  MGOWT                  ;PRESUB 2
L8633:  LDD  M_XP
L8636:  STD  M_DVD                  ;FORCED POSITIVE BY TABLE
L8639:  JSR  BJCNTR                 ;START FROM CENTER SCREEN
L863C:  LDD  #$0200                 ;CLOSEST PRESUB2 HANDLES WITH RECIPROCAL VG
L863F:  STD  M_X0
L8642:  LDD  M_Y0                   ;CLIP CLOSE LINES
L8645:  SUBD MS_TY+M_S1
L8648:  BPL  L864E                  ;IFMI
L864A:  COMA                        ;NEGD  ABSOLUTE VALUE
L864B:  NEGB
L864C:  SBCA #$FF
L864E:  CMPD M_X0
L8652:  BLE  L8657                  ;IFGT  ?NEED TO MATCH Y COORD?
L8654:  STD  M_X0
L8657:  LDD  M_Z0                   ;NOW CLIP Z COORD
L865A:  SUBD MS_TZ+M_S1
L865D:  BPL  L8663                  ;IFMI
L865F:  COMA                        ;NEGD  ABSOLUTE VALUE
L8660:  NEGB
L8661:  SBCA #$FF
L8663:  CMPD M_X0
L8667:  BLE  L866C                  ;IFGT  ?NEED TO CLIP TO MATCH Z COORD?
L8669:  STD  M_X0
L866C:  LDD  #MS_X0BC
L866F:  STD  M_BIC
L8672:  LDA  #MS_PSB2
L8674:  JSR  MGOWT
L8677:  LDD  M_XP
L867A:  STD  M_DVD
L867D:  JSR  BJLNV                  ;DRAW VISIBLE LINE
L8680:  LDD  #VGCNTR                ;RECENTER
L8683:  STD  ,Y++
L8685:  LEAU 4,U                    ;NEXT TABLE ENTRY
L8687:  CMPU #TBSBLZ
L868B:  LBLO BSVBOT_10              ;LOOP
L868F:  LDD  MS_TX+M_S1             ;RESTORE X
L8692:  STD  MS_TX+M_U1
L8695:  RTS

TBSBL:           ;BASE BOTTOM LINES
L8696:  .word $FC00, $0000          ;TOP LEFT PANEL
L869A:  .word $0400, $0000          ;TOP OF RIGHT PANEL
L869E:  .word $FC00, $F000          ;FAR LEFT BOTTOM
L86A2:  .word $FE00, $F000          ;LEFT THIRD
L86A6:  .word $0200, $F000          ;RIGHT THIRD
L86AA:  .word $0400, $F000          ;FAR RIGHT BOTTOM

;------------------------------------------------------------------------------
; TBSBLZ - VIEW FAR END OF BASE TRENCH
;   (also: BSVFAR)
;------------------------------------------------------------------------------
TBSBLZ:
BSVFAR:
L86AE:  LDD  #$0000
L86B1:  STD  MS_TX+M_U1             ;KEEP VIEWER AT START OF TRENCH
L86B4:  LDD  #(VGCGRN*$100)+VGCOPC-$30
L86B7:  STD  ,Y++
L86B9:  LDU  #TBSBF                 ;FAR END LINE TABLE

BSVFAR_10:
L86BC:  LDA  BS_EFL
L86BE:  BEQ  BSVFAR_16              ;IFNE  ?END IN VIEW YET?
L86C0:  LDD  BS_ELC
L86C2:  SUBD MS_TX+M_S1
L86C5:  CMPD #$7000
L86C9:  BHI  BSVFAR_16              ;?LS? LESS THAN 7000 AWAY?
L86CB:  BRA  L86D0                  ;ELSE  ELSE NO END IN VIEW

BSVFAR_16:
L86CD:  LDD  #$7000
L86D0:  STD  M_X0
L86D3:  LDD  ,U                     ;Y OFFSET
L86D5:  STD  M_Y0
L86D8:  LDD  2,U                    ;Z OFFSET
L86DA:  STD  M_Z0
L86DD:  LDD  #MS_X0BC
L86E0:  STD  M_BIC
L86E3:  LDA  #MS_PSB2
L86E5:  JSR  MGOWT                  ;PRESUB 2
L86E8:  LDD  M_XP
L86EB:  STD  M_DVD                  ;FORCED POSITIVE BY TABLE
L86EE:  JSR  BJCNTR                 ;START FROM CENTER SCREEN
L86F1:  BRA  BSVFAR_60

BSVFAR_20:
L86F3:  LDD  ,U
L86F5:  STD  M_Y0
L86F8:  LDD  2,U
L86FA:  STD  M_Z0
L86FD:  LDD  #MS_X0BC
L8700:  STD  M_BIC
L8703:  LDA  #MS_PSB2
L8705:  JSR  MGOWT
L8708:  LDD  M_XP
L870B:  STD  M_DVD
L870E:  JSR  BJLNV                  ;DRAW VISIBLE LINE

BSVFAR_60:
L8711:  LEAU 4,U                    ;NEXT TABLE ENTRY
L8713:  CMPU #TBSBFZ
L8717:  BLO  BSVFAR_20              ;LOOP
L8719:  LDD  #VGCNTR                ;RECENTER
L871C:  STD  ,Y++
L871E:  LDD  MS_TX+M_S1             ;RESTORE X
L8721:  STD  MS_TX+M_U1
L8724:  RTS

TBSBF:           ;FAR END LINE POINTS
L8725:  .word $FC00, $0000          ;TOP LEFT PANEL
L8729:  .word $FC00, $F000          ;FAR LEFT BOTTOM
L872D:  .word $0400, $F000          ;FAR RIGHT BOTTOM
L8731:  .word $0400, $0000          ;TOP OF RIGHT PANEL

;------------------------------------------------------------------------------
; TBSBFZ - VIEW SIDE OF BASE TRENCH
;   (also: BSVSID)
;------------------------------------------------------------------------------
TBSBFZ:
BSVSID:
L8735:  LDU  WG_NRP
L8738:  LDB  WGS_TYP,U
L873A:  CMPB #TYPS_END
L873C:  BNE  L873F                  ;IFEQ
L873E:  RTS
L873F:  CMPB #TYPS_SHORT
L8741:  BNE  L8748                  ;IFEQ
L8743:  LDD  #$0800
L8746:  BRA  L874B                  ;ELSE
L8748:  LDD  #$1000
L874B:  ADDD WG_NRL
L874E:  SUBD MS_TX+M_U1
L8751:  BPL  L8786                  ;IFMI  ?ARE WE PAST THIS WEDGE? REMEMBER WRAPAROUND
L8753:  LDB  WGS_TYP,U              ;UPDATE OUR LOCATION
L8755:  CMPB #TYPS_SHORT
L8757:  BNE  L875E                  ;IFEQ
L8759:  LDD  #$0800
L875C:  BRA  L8761                  ;ELSE
L875E:  LDD  #$1000
L8761:  ADDD WG_NRL
L8764:  STD  WG_NRL
L8767:  LEAU WGS_IZ,U               ;ACCESS NEXT WEDGE
L8769:  STU  WG_NRP
L876C:  LDB  WGS_TYP,U
L876E:  CMPB #TYPS_END
L8770:  BNE  L8773                  ;IFEQ
L8772:  RTS                         ;REACHED END OF WEDGES, QUIT
L8773:  LDB  WGS_TYP,U
L8775:  CMPB #TYPS_NXT              ;?GOTO NEXT PIE?
L8777:  BNE  L8783                  ;IFEQ
L8779:  LDU  PI_NRW
L877C:  LEAU PIS_IZ,U
L877E:  STU  PI_NRW
L8781:  LDU  PIS_WDG,U
L8783:  STU  WG_NRP
L8786:  LDD  #(VGCGRN*$100)+VGCOPC-$20
L8789:  STD  ,Y++
L878B:  JSR  DOFAR                  ;DO FAR WEDGE IF ROOM
L878E:  LDD  PI_NRW
L8791:  STD  PI_CRW
L8794:  LDD  WG_NRP
L8797:  STD  WG_CRP
L879A:  LDD  WG_NRL
L879D:  STD  WG_CRL
L87A0:  STD  M_X0
L87A3:  LDD  #$FC00                 ;LEFT SIDE
L87A6:  STD  M_Y0
L87A9:  JSR  BSVSDW                 ;VIEW WHOLE LEFT SIDE
L87AC:  LDD  PI_NRW
L87AF:  STD  PI_CRW
L87B2:  LDD  WG_NRP
L87B5:  STD  WG_CRP
L87B8:  LDD  WG_NRL
L87BB:  STD  WG_CRL
L87BE:  STD  M_X0
L87C1:  LDD  #$0400                 ;RIGHT SIDE
L87C4:  STD  M_Y0
L87C7:  JSR  BSVSDW
L87CA:  RTS

;------------------------------------------------------------------------------
; BSVSDW - VIEW WHOLE OF ONE SIDE
;------------------------------------------------------------------------------
BSVSDW:
L87CB:  LDD  WG_CRL
L87CE:  STD  M_X0
L87D1:  SUBD MS_TX+M_U1
L87D4:  LBMI BSVSDW_80              ;B SKIP FIRST ONE IF PAST IT (BEWARE WRAPAROUND)
L87D8:  CMPD #$0800
L87DC:  BGE  BSVSDW_10              ;B PROCESS FIRST ONE NORMALLY IF FAR ENUF AWAY
L87DE:  LSLB                        ;LSLD  *2 FOR GENEROUS DROP
L87DF:  ROLA
L87E0:  COMA                        ;NEGD  REVERSE SUBTRACT
L87E1:  NEGB
L87E2:  SBCA #$FF
L87E4:  ADDD MS_TZ+M_U1             ;ALLOW >45 DEGREE DROP
L87E7:  CMPD #$F000
L87EB:  BGE  L87F0                  ;IFLT
L87ED:  LDD  #$F000                 ;LIMIT TO BOTTOM
L87F0:  STD  M_Z0
L87F3:  BRA  BSVSDW_11              ;J CONTINUE WITH FIRST OBJECT

BSVSDW_10:       ;---LOOP PER OBJECT
L87F5:  LDD  WG_CRL
L87F8:  STD  M_X0
L87FB:  LDD  #$F000                 ;BOTTOM EDGE
L87FE:  STD  M_Z0

BSVSDW_11:
L8801:  LDA  BS_EFL
L8803:  BEQ  L880E                  ;IFNE  ?END IN VIEW?
L8805:  LDD  M_X0
L8808:  SUBD BS_ELC
L880A:  LBPL BSVSDW_90              ;B EXIT IF AT END OF TRENCH
L880E:  LDD  M_X0
L8811:  SUBD MS_TX+M_S1
L8814:  SUBD #$7000                 ;CHECK AGAINST NORMAL END TOO
L8817:  LBPL BSVSDW_90              ;B EXIT IF BEYOND MAX RANGE
L881B:  LDD  #MS_X0BC
L881E:  STD  M_BIC
L8821:  LDA  #MS_PSB2
L8823:  JSR  MGOWT                  ;PRESUB 2
L8826:  LDD  M_YP                   ;CLIP THE LINE OUT
L8829:  BPL  BSVSDW_34
L882B:  COMA                        ;NEGD
L882C:  NEGB
L882D:  SBCA #$FF

BSVSDW_34:
L882F:  SUBD M_XP
L8832:  BGT  BSVSDW_80              ;B NO GOOD IF NOT VISIBLE
L8834:  LDD  M_XP
L8837:  STD  M_DVD                  ;FORCED POSITIVE BY TABLE
L883A:  LDD  #$0000
L883D:  STD  BJ_CX                  ;INIT VECTOR POS TO ZERO
L883F:  LDD  #(-VGOFFY)&$FFFF
L8842:  STD  BJ_CY
L8844:  JSR  BJLNB                  ;START FROM CENTER SCREEN
L8847:  LDD  #$0000
L884A:  STD  M_Z0                   ;TOP OF SIDE PANELS
L884D:  LDD  #MS_X0BC
L8850:  STD  M_BIC
L8853:  LDA  #MS_PSB2
L8855:  JSR  MGOWT
L8858:  LDD  M_XP
L885B:  STD  M_DVD
L885E:  JSR  BJLNV                  ;DRAW VISIBLE LINE
L8861:  LDD  #VGCNTR                ;RECENTER
L8864:  STD  ,Y++

BSVSDW_80:
L8866:  LDU  WG_CRP
L8869:  LDB  WGS_TYP,U
L886B:  CMPB #TYPS_SHORT
L886D:  BNE  L8874                  ;IFEQ
L886F:  LDD  #$0800
L8872:  BRA  L8877                  ;ELSE
L8874:  LDD  #$1000
L8877:  ADDD WG_CRL
L887A:  STD  WG_CRL
L887D:  SUBD MS_TX+M_U1
L8880:  BMI  BSVSDW_90              ;B EXIT IF WRAPPED TOO FAR
L8882:  LEAU WGS_IZ,U
L8884:  LDB  WGS_TYP,U
L8886:  CMPB #TYPS_END
L8888:  BEQ  BSVSDW_90              ;B EXIT IF END
L888A:  CMPB #TYPS_NXT
L888C:  BNE  L8898                  ;IFEQ
L888E:  LDU  PI_CRW
L8891:  LEAU PIS_IZ,U
L8893:  STU  PI_CRW
L8896:  LDU  PIS_WDG,U
L8898:  STU  WG_CRP
L889B:  JMP  BSVSDW_10              ;J LOOP UNTIL DONE

BSVSDW_90:
L889E:  RTS

;------------------------------------------------------------------------------
; BSVPORT - VIEW THE EXHAUST PORT
;------------------------------------------------------------------------------
BSVPORT:
L889F:  LDB  #TDS_PORT              ;GET A WALL PANEL FOR NOW
L88A1:  STB  BJ_ID
L88A3:  JSR  BJGROT                 ;ROTATE IT IN FRONT OF US
L88A6:  LDD  #$F000
L88A9:  STD  M_GD+4                 ;Z HITE ON BOTTOM OF TRENCH
L88AC:  LDD  #$0000
L88AF:  STD  M_GD+2                 ;Y WIDTH IN CENTER
L88B2:  LDD  BS_PLC
L88B4:  STD  M_GD+0                 ;X LOCATION
L88B7:  LDD  #MS_GDBC
L88BA:  STD  M_BIC
L88BD:  LDA  #MS_PSB2
L88BF:  JSR  MGOWT
L88C2:  LDD  M_XP
L88C5:  CMPD #$FE00
L88C9:  BGT  L88D0                  ;IFLE  ?TOO FAR IN BACK?
L88CB:  LDA  #$00
L88CD:  STA  BS_PFL                 ;TURN OFF THE PORT
L88CF:  RTS                         ;J AND EXIT
L88D0:  SUBD #$7000
L88D3:  BGT  L88F4                  ;IFLE  ?CLOSE ENUF TO SEE?
L88D5:  LDD  #VJFLS
L88D8:  STD  M_GDCT                 ;SET UP BUNKERS COLOR
L88DB:  LDD  #VGSCAL
L88DE:  STD  M_GDSC                 ;SET UP BUNKERS SCALE
L88E1:  LDD  M_XP
L88E4:  SUBD #$1000
L88E7:  BGE  L88EE                  ;IFLT  ?TOO CLOSE?
L88E9:  JSR  BJBCLP                 ;THEN PROCESS POINTS WITH CLIPPING
L88EC:  BRA  L88F1                  ;ELSE
L88EE:  JSR  BJGPNT                 ;ELSE USE REGULAR
L88F1:  JSR  BJGDRW                 ;DRAW THE LINES
L88F4:  RTS

;------------------------------------------------------------------------------
; BSVEND - THE VERY END OF THE TRENCH
;------------------------------------------------------------------------------
BSVEND:
L88F5:  LDD  #(VGCGRN*$100)+VGCOPC
L88F8:  STD  ,Y++
L88FA:  LDA  BS_EFL
L88FC:  BEQ  L8950                  ;IFNE  ?END IN VIEW YET?
L88FE:  LDD  BS_ELC
L8900:  STD  M_X0
L8903:  SUBD MS_TX+M_S1
L8906:  SUBD #$7000
L8909:  BMI  L8911                  ;IFPL
L890B:  COMA                        ;NEGD  FURTHEST AWAY IS LO, CLOSEST IS AT ZERO
L890C:  NEGB
L890D:  SBCA #$FF
L890F:  BRA  L8914                  ;ELSE
L8911:  LDD  #$0000
L8914:  STD  M_Z0
L8917:  LDD  #$FC00                 ;LEFT POINT
L891A:  STD  M_Y0
L891D:  LDD  #MS_X0BC
L8920:  STD  M_BIC
L8923:  LDA  #MS_PSB2
L8925:  JSR  MGOWT                  ;PRESUB 2
L8928:  LDD  M_XP
L892B:  STD  M_DVD                  ;FORCED POSITIVE BY TABLE
L892E:  JSR  BJCNTR                 ;START FROM CENTER SCREEN
L8931:  LDD  #$0400                 ;RIGHT POINT
L8934:  STD  M_Y0
L8937:  LDD  #MS_X0BC
L893A:  STD  M_BIC
L893D:  LDA  #MS_PSB2
L893F:  JSR  MGOWT
L8942:  LDD  M_XP
L8945:  STD  M_DVD
L8948:  JSR  BJLNV                  ;DRAW VISIBLE LINE
L894B:  LDD  #VGCNTR                ;RECENTER
L894E:  STD  ,Y++
L8950:  RTS

;==============================================================================
; MODULE WSCPU   WSCPU.MAC
;   CPU ALIEN CONTROL AND CHOREOGRAPHY
;==============================================================================

;------------------------------------------------------------------------------
; SNPTU - PITCH UP
;   ALIEN USAGE ONLY
;------------------------------------------------------------------------------
SNPTU:
L8951:  JSR  SNPOS
L8954:  INC  CP_PT
L8956:  JMP  SNPT

;------------------------------------------------------------------------------
; SNPTD - PITCH DOWN
;------------------------------------------------------------------------------
SNPTD:
L8959:  JSR  SNNEG
L895C:  DEC  CP_PT
L895E:  JMP  SNPT

;------------------------------------------------------------------------------
; SNRLL - ROLL LEFT
;------------------------------------------------------------------------------
SNRLL:
L8961:  JSR  SNNEG
L8964:  DEC  CP_RL
L8966:  JMP  SNRL

;------------------------------------------------------------------------------
; SNRLR - ROLL RIGHT
;------------------------------------------------------------------------------
SNRLR:
L8969:  JSR  SNPOS
L896C:  INC  CP_RL
L896E:  JMP  SNRL

;------------------------------------------------------------------------------
; SNYWL - YAW LEFT
;------------------------------------------------------------------------------
SNYWL:
L8971:  JSR  SNPOS
L8974:  DEC  CP_YW
L8976:  JMP  SNYW

;------------------------------------------------------------------------------
; SNYWR - YAW RIGHT
;------------------------------------------------------------------------------
SNYWR:
L8979:  JSR  SNNEG
L897C:  INC  CP_YW
L897E:  JMP  SNYW

;------------------------------------------------------------------------------
; SNPOS - POSITIVE ANGLES FOR CPU
;------------------------------------------------------------------------------
SNPOS:
L8981:  LDA  #$14
L8983:  LDU  #TSNGLE
L8986:  LEAU A,U
L8988:  LDD  ,U
L898A:  STD  M_SIN
L898D:  LDD  2,U
L898F:  STD  M_COS
L8992:  RTS

;------------------------------------------------------------------------------
; SNNEG - [note] Negative angles for CPU: M_SIN = minus the sine and M_COS = the cosine of the TSNGLE entry at offset $14
;------------------------------------------------------------------------------
SNNEG:
L8993:  LDA  #$14
L8995:  LDU  #TSNGLE                ;8 ENTRIES, DOUBLEWORD EACH
L8998:  LEAU A,U
L899A:  LDD  #$0000
L899D:  SUBD ,U
L899F:  STD  M_SIN
L89A2:  LDD  2,U
L89A4:  STD  M_COS
L89A7:  RTS

TSNGLE:          ;CPU ANGLES
L89A8:  .word $00B5, $3FFF          ;.63
L89AC:  .word $0100, $3FFE          ;.90
L89B0:  .word $016A, $3FFC          ;1.27
L89B4:  .word $021F, $3FF7          ;1.90
L89B8:  .word $03DF, $3FE2          ;3.47
L89BC:  .word $04FF, $3FCE          ;4.48
L89C0:  .word $0590, $3FC2          ;4.99
L89C4:  .word $0590, $3FC2          ;4.99

;------------------------------------------------------------------------------
; SNRL - ROLL ALIEN SHIP
;------------------------------------------------------------------------------
SNRL:
L89C8:  CLRA
L89C9:  LDB  AS_BIC,X
L89CB:  STD  M_BIC
L89CE:  LDA  #MS_ROLL
L89D0:  JMP  MGOWT

;------------------------------------------------------------------------------
; SNPT - PITCH ALIEN SHIP
;------------------------------------------------------------------------------
SNPT:
L89D3:  CLRA
L89D4:  LDB  AS_BIC,X
L89D6:  STD  M_BIC
L89D9:  LDA  #MS_PTCH
L89DB:  JMP  MGOWT

;------------------------------------------------------------------------------
; SNYW - YAW ALIEN SHIP
;------------------------------------------------------------------------------
SNYW:
L89DE:  CLRA
L89DF:  LDB  AS_BIC,X
L89E1:  STD  M_BIC
L89E4:  LDA  #MS_YAW
L89E6:  JMP  MGOWT

;------------------------------------------------------------------------------
; SNMVF2 - MOVE FORWARD TWICE AS FAST
;------------------------------------------------------------------------------
SNMVF2:
L89E9:  LDD  MS_AX,U                ;X VECTOR
L89EB:  JSR  ASRD5
L89EE:  ADDD MS_VX,U
L89F0:  STD  MS_VX,U
L89F2:  LDD  MS_BX,U
L89F4:  JSR  ASRD5
L89F7:  ADDD MS_VY,U
L89F9:  STD  MS_VY,U
L89FB:  LDD  MS_CX,U
L89FD:  JSR  ASRD5
L8A00:  ADDD MS_VZ,U
L8A02:  STD  MS_VZ,U
L8A04:  RTS

;------------------------------------------------------------------------------
; SNMVF - MOVE FORWARD
;------------------------------------------------------------------------------
SNMVF:
L8A05:  LDD  MS_AX,U                ;X VECTOR
L8A07:  JSR  ASRD6
L8A0A:  ADDD MS_VX,U
L8A0C:  STD  MS_VX,U
L8A0E:  LDD  MS_BX,U
L8A10:  JSR  ASRD6
L8A13:  ADDD MS_VY,U
L8A15:  STD  MS_VY,U
L8A17:  LDD  MS_CX,U
L8A19:  JSR  ASRD6
L8A1C:  ADDD MS_VZ,U
L8A1E:  STD  MS_VZ,U
L8A20:  RTS

;------------------------------------------------------------------------------
; SNMVU - MOVE UP
;------------------------------------------------------------------------------
SNMVU:
L8A21:  LDD  MS_AZ,U                ;Z VECTOR
L8A23:  JSR  ASRD6
L8A26:  ADDD MS_VX,U
L8A28:  STD  MS_VX,U
L8A2A:  LDD  MS_BZ,U
L8A2C:  JSR  ASRD6
L8A2F:  ADDD MS_VY,U
L8A31:  STD  MS_VY,U
L8A33:  LDD  MS_CZ,U
L8A35:  JSR  ASRD6
L8A38:  ADDD MS_VZ,U
L8A3A:  STD  MS_VZ,U
L8A3C:  RTS

;------------------------------------------------------------------------------
; SNMVU2 - MOVE UP TWICE AS FAST
;------------------------------------------------------------------------------
SNMVU2:
L8A3D:  LDD  MS_AZ,U                ;Z VECTOR
L8A3F:  JSR  ASRD5
L8A42:  ADDD MS_VX,U
L8A44:  STD  MS_VX,U
L8A46:  LDD  MS_BZ,U
L8A48:  JSR  ASRD5
L8A4B:  ADDD MS_VY,U
L8A4D:  STD  MS_VY,U
L8A4F:  LDD  MS_CZ,U
L8A51:  JSR  ASRD5
L8A54:  ADDD MS_VZ,U
L8A56:  STD  MS_VZ,U
L8A58:  RTS

;------------------------------------------------------------------------------
; SNMVD - MOVE DOWN
;------------------------------------------------------------------------------
SNMVD:
L8A59:  LDD  #$0000                 ;NEGATE Z VECTOR
L8A5C:  SUBD MS_AZ,U
L8A5E:  JSR  ASRD6
L8A61:  ADDD MS_VX,U
L8A63:  STD  MS_VX,U
L8A65:  LDD  #$0000
L8A68:  SUBD MS_BZ,U
L8A6A:  JSR  ASRD6
L8A6D:  ADDD MS_VY,U
L8A6F:  STD  MS_VY,U
L8A71:  LDD  #$0000
L8A74:  SUBD MS_CZ,U
L8A76:  JSR  ASRD6
L8A79:  ADDD MS_VZ,U
L8A7B:  STD  MS_VZ,U
L8A7D:  RTS

;------------------------------------------------------------------------------
; SNMVD2 - MOVE DOWN TWICE AS FAST
;------------------------------------------------------------------------------
SNMVD2:
L8A7E:  LDD  #$0000                 ;NEGATE Z VECTOR
L8A81:  SUBD MS_AZ,U
L8A83:  JSR  ASRD5
L8A86:  ADDD MS_VX,U
L8A88:  STD  MS_VX,U
L8A8A:  LDD  #$0000
L8A8D:  SUBD MS_BZ,U
L8A8F:  JSR  ASRD5
L8A92:  ADDD MS_VY,U
L8A94:  STD  MS_VY,U
L8A96:  LDD  #$0000
L8A99:  SUBD MS_CZ,U
L8A9B:  JSR  ASRD5
L8A9E:  ADDD MS_VZ,U
L8AA0:  STD  MS_VZ,U
L8AA2:  RTS

S_CPY1:
L8AA3:  .byte $54, $CD, $E5, $2D, $3F, $14, $12, $CD ;.IRPC .A,<GREGR did THIS also>
L8AAB:  .byte $69, $F6, $AD, $33, $AA, $28, $A6, $0B
L8AB3:  .byte $F7, $58, $D1

;------------------------------------------------------------------------------
; DOAMOV - MOVE ALIEN
;   PLAYER SHIP
;   X--> A. PARAMETER
;   U--> UVP
;   VELOCITIES ALREADY SET
;------------------------------------------------------------------------------
DOAMOV:
L8AB6:  LDD  MS_VX,U
L8AB8:  ADDD MS_TX,U
L8ABA:  BVS  DOAMOV_50              ;IFVC
L8ABC:  STD  MS_TX,U                ;NEW LOCAL POSITION

DOAMOV_50:       ;---HANDLE Y TRANSLATION
L8ABE:  LDD  MS_VY,U
L8AC0:  ADDD MS_TY,U
L8AC2:  BVS  DOAMOV_60              ;IFVC
L8AC4:  STD  MS_TY,U                ;NEW TRANSLATION LOCATION

DOAMOV_60:       ;--- TRANSLATE Y
L8AC6:  LDD  MS_TZ,U
L8AC8:  ADDD MS_VZ,U                ;COMPUTE NEW Z
L8ACA:  BVS  DOAMOV_68              ;IFVC
L8ACC:  STD  MS_TZ,U

DOAMOV_68:
L8ACE:  RTS

;------------------------------------------------------------------------------
; CPHTSA - COLLISION
;   SPACE LAZAR HIT ALIEN SHIP
;------------------------------------------------------------------------------
CPHTSA:
L8ACF:  LDX  CL_AP                  ;X-->ALIEN PARMS
L8AD1:  LDA  AS_TYP,X
L8AD3:  CMPA #$01
L8AD5:  BNE  CPHTSA_5               ;NO DOUBLE JEOPARDY IF NOT ALIVE
L8AD7:  LDA  AS_GLW,X
L8AD9:  BEQ  L8ADC                  ;IFNE  ?OR IS IT GLOWING FROM A HIT?

CPHTSA_5:
L8ADB:  RTS                         ;LEAVE ALONE FOR A WHILE
;ELSE PROCESS THE HIT
L8ADC:  JSR  RND8
L8ADF:  LDA  AS_TYP,X
L8AE1:  CMPA #$01
L8AE3:  BNE  CPHTSA_30              ;?A LIVE ALIEN?
L8AE5:  LDD  AS_CHST,X
L8AE8:  ORB  #(CS_AH&$FF)           ;CHSET C$AH  STATUS: THIS ALIEN DAMAGED
L8AEA:  STD  AS_CHST,X

CPHTSA_30:
L8AED:  LDX  CL_AP                  ;X--> HIT ALIEN PARM
L8AEF:  INC  AS_DMC,X               ;RECORD SOME MORE DAMAGE
L8AF1:  DEC  AS_HTA,X               ;DECREASE HITS LEFT
L8AF3:  LBLE XPSA                   ;NO HITS LEFT - EXPLODE SPACE ALIEN
;INDICATE DAMAGE
;IMPART GUN VELOCITY TO SHIP
L8AF7:  LDA  #$05
L8AF9:  STA  AS_HTA,X               ;KEEP DARTH ALIVE
L8AFB:  JSR  SCRDARTH               ;ADD SCORE FOR HITTING DARTH
;FORCE GLOW
L8AFE:  LDA  #$1F                   ;TWO OR SO SECONDS
L8B00:  STA  AS_ROL,X
L8B02:  STA  AS_GLW,X
L8B04:  LDX  #M_S1
L8B07:  LDU  CL_AP
L8B09:  LDU  AS_UVP,U               ;ALIEN UVP
;=== THROW SHIP FOR A LOOP
L8B0B:  LDD  #$0000                 ;CLRD
L8B0E:  STD  MS_VX,U                ;THRO SHIP INDEPENDENT OF PREVIOUS MOTION
L8B10:  STD  MS_VY,U
L8B12:  STD  MS_VZ,U
L8B14:  LDA  #$02
L8B16:  STA  TMPLP

CPHTSA_40:
L8B18:  LDD  #$4000
L8B1B:  SUBD CL_ADS
L8B1D:  LDB  MS_AX,X
L8B1F:  MUL
L8B20:  TFR  A,B
L8B22:  LSLB                        ;LSLD
L8B23:  ROLA
L8B24:  SEX
L8B25:  ADDD MS_VX,U
L8B27:  STD  MS_VX,U                ;PORTION OF FORWARD VELOCITY
L8B29:  LDA  RND_S1
L8B2B:  ORA  #$80                   ;AT LEAST SOME ANGLE
L8B2D:  LDB  MS_BX,X
L8B2F:  MUL
L8B30:  BCS  CPHTSA_43              ;RANDOM BIT
L8B32:  NEGA

CPHTSA_43:
L8B33:  TFR  A,B
L8B35:  NOP
L8B36:  SEX
L8B37:  ADDD MS_VY,U
L8B39:  STD  MS_VY,U                ;PORTION OF Y VELOCITY
L8B3B:  LDA  RND_S2
L8B3D:  ORA  #$80
L8B3F:  LDB  MS_CX,X
L8B41:  MUL
L8B42:  BCS  CPHTSA_53              ;RANDOM BIT
L8B44:  NEGA

CPHTSA_53:
L8B45:  TFR  A,B
L8B47:  NOP
L8B48:  SEX                         ;FULL WORD
L8B49:  ADDD MS_VZ,U
L8B4B:  STD  MS_VZ,U
L8B4D:  LEAX 2,X
L8B4F:  DEC  TMPLP
L8B51:  BPL  CPHTSA_40
L8B53:  JSR  AUDSX
L8B56:  RTS

;------------------------------------------------------------------------------
; XPSA - EXPLODE SPACE ALIEN
;------------------------------------------------------------------------------
XPSA:
L8B57:  LDX  CL_AP                  ;X-->HIT ALIEN
L8B59:  JSR  AUDSX                  ;SMALL EXPLOSION
L8B5C:  LDA  AS_BIC,X
L8B5E:  CMPA Q_PBB
L8B61:  BNE  L8B66                  ;IFEQ  ?SAME GUY DOING CURRENT PASSBY?
L8B63:  JSR  AUDPBZ                 ;THEN KILL ANY PASSBY SOUND
L8B66:  JSR  BGAXPLD
L8B69:  JSR  SCRTIES                ;ADD SCORE FOR KILLING TIE FIGHTER
L8B6C:  RTS

;------------------------------------------------------------------------------
; CPU - CPU-COMPUTER DRONES
;   COMPUTER
;------------------------------------------------------------------------------
CPU:
L8B6D:  LDX  #ALIEN

CPU_20:
L8B70:  STX  S1_PRM
L8B72:  LDU  AS_UVP,X
L8B74:  LDA  AS_TYP,X               ;IGNORE DEAD ONES
L8B76:  BEQ  CPU_40
L8B78:  JSR  CPUAL                  ;ALIEN CPU, LOCAL

CPU_40:
L8B7B:  LDX  S1_PRM
L8B7D:  LEAX AS_IZE,X
L8B80:  CMPX #ALIENZ
L8B83:  BLO  CPU_20

CPU_90:
L8B85:  RTS

;------------------------------------------------------------------------------
; CPURET - COMPUTER DRONES RUN AWAY  (comment at the call)
;------------------------------------------------------------------------------
CPURET:
L8B86:  LDX  #ALIEN
L8B89:  STX  S1_PRM
L8B8B:  LDU  AS_UVP,X
L8B8D:  LDA  AS_TYP,X
L8B8F:  CMPA #$01
L8B91:  BNE  L8BD6                  ;IFEQ  ?ALIVE?
;MOVE Y AND Z TO CENTER
L8B93:  LDA  MS_TY,U
L8B95:  CMPA #$09
L8B97:  BLT  L8B9B                  ;IFGE
L8B99:  SUBA #$02
L8B9B:  CMPA #$F7
L8B9D:  BGT  L8BA1                  ;IFLE
L8B9F:  ADDA #$02
L8BA1:  STA  MS_TY,U                ;SAVE RESULT
L8BA3:  LDA  MS_TZ,U
L8BA5:  CMPA #$09
L8BA7:  BLT  L8BAB                  ;IFGE
L8BA9:  SUBA #$03
L8BAB:  CMPA #$F7
L8BAD:  BGT  L8BB1                  ;IFLE
L8BAF:  ADDA #$03
L8BB1:  STA  MS_TZ,U                ;SAVE RESULT
L8BB3:  LDD  MS_TX,U
L8BB5:  ADDD #$0400                 ;RACE BACK TO DETH STAR
L8BB8:  BVS  L8BBE                  ;IFVC
L8BBA:  STD  MS_TX,U
L8BBC:  BRA  L8BD6                  ;ELSE  ELSE OVERFLOWED TO DETH STAR, SO TURN OFF
L8BBE:  LDA  MS_TY,U
L8BC0:  TSTA                        ;ABSA
L8BC1:  BPL  L8BC4
L8BC3:  NEGA
L8BC4:  CMPA #$08
L8BC6:  BGT  L8BD6                  ;IFLE
L8BC8:  LDA  MS_TZ,U
L8BCA:  TSTA                        ;ABSA
L8BCB:  BPL  L8BCE
L8BCD:  NEGA
L8BCE:  CMPA #$08
L8BD0:  BGT  L8BD6                  ;IFLE  ?BOTH Y AND Z CLOSE TO DETH STAR ALSO?
L8BD2:  LDA  #$00                   ;THEN TURN OFF ALIEN
L8BD4:  STA  AS_TYP,X
L8BD6:  LDX  S1_PRM                 ;LOOP WITH NEXT ALIEN
L8BD8:  LEAX AS_IZE,X
L8BDB:  CMPX #ALIENZ
L8BDE:  BLO  L8B89                  ;HSEND
L8BE0:  RTS

;------------------------------------------------------------------------------
; CPUAL - ALIEN CPU, LOCAL  (comment at the call)
;------------------------------------------------------------------------------
CPUAL:
L8BE1:  JSR  CHOPDO
L8BE4:  LDD  #$0000                 ;CLEAR ACTIONS REQUESTED
L8BE7:  STA  CP_AC
L8BE9:  STA  CP_RL
L8BEB:  STA  CP_PT
L8BED:  STA  CP_YW
L8BEF:  LDA  AS_CHST,X
L8BF2:  ANDA #CS_PV/$100            ;SAVE IF IN VIEW FOR GUNS
L8BF4:  LDB  P_RND1
L8BF7:  ANDB #CS_R1+CS_R2
L8BF9:  STD  AS_CHST,X              ;PREPARE NEW CHOREG STATUS
L8BFC:  LDA  AS_ROL,X
L8BFE:  DECA
L8BFF:  BMI  CPUAL_18
L8C01:  STA  AS_ROL,X
L8C03:  LDD  #$1640                 ;20.34 DEGREES
L8C06:  STD  M_SIN
L8C09:  LDD  #$3C02
L8C0C:  STD  M_COS
L8C0F:  JSR  SNRL
L8C12:  JMP  CPUAL_26               ;SKIP OVER AIM AND SHOOT

CPUAL_18:
L8C15:  LDB  AS_CHTW,X              ;TWIRL INFO
L8C18:  STB  CP_SHF

CPUAL_20:
L8C1A:  LSR  CP_SHF
L8C1C:  BCC  CPUAL_21
L8C1E:  JSR  SNRLL

CPUAL_21:
L8C21:  LSR  CP_SHF
L8C23:  BCC  CPUAL_22
L8C25:  JSR  SNRLR

CPUAL_22:
L8C28:  LSR  CP_SHF
L8C2A:  BCC  CPUAL_23
L8C2C:  JSR  SNPTU

CPUAL_23:
L8C2F:  LSR  CP_SHF
L8C31:  BCC  CPUAL_24
L8C33:  JSR  SNPTD

CPUAL_24:
L8C36:  LSR  CP_SHF
L8C38:  BCC  CPUAL_25
L8C3A:  JSR  SNYWR

CPUAL_25:
L8C3D:  LSR  CP_SHF
L8C3F:  BCC  CPUAL_26
L8C41:  JSR  SNYWL

CPUAL_26:
CPUAL_28:
CPUAL_30:
L8C44:  JSR  CPUMVL                 ;MOVE LOCALLY
L8C47:  JSR  CPCHKL
L8C4A:  LDA  AS_TYP,X
L8C4C:  CMPA #$01                   ;?NOT LIVE SHIP?
L8C4E:  LBNE CPUAL_60               ;B THEN NO SHOTS
L8C52:  LDA  AS_BIC,X
L8C54:  JSR  IS1UV                  ;DOWNLOAD VECTORS
L8C57:  LDX  S1_PRM
L8C59:  CLR  AS_AIM,X
L8C5B:  CLRA
L8C5C:  LDB  #MS_S1BC+3             ;CHASE PLAYER'S ONE SHIP
L8C5E:  STD  M_BIC
L8C61:  LDA  AS_CHTW,X              ;AIM IN FRONT OF PLAYER
L8C64:  BITA #CS_T9
L8C66:  BEQ  L8C81                  ;IFNE
L8C68:  LDD  MS_TX+M_S1
L8C6B:  ADDD #$1000                 ;GO IN FRONT OF PLAYER
L8C6E:  STD  MS_TX+M_S1
L8C71:  LDA  #MS_PSB2               ;NOW VIEW PLAYER'S SHIP
L8C73:  JSR  MGOWT
L8C76:  LDD  MS_TX+M_S1
L8C79:  SUBD #$1000                 ;RESTORE M$TX
L8C7C:  STD  MS_TX+M_S1
L8C7F:  BRA  L8C86                  ;ELSE
L8C81:  LDA  #MS_PSB2               ;VIEW PLAYERS SHIP
L8C83:  JSR  MGOWT
L8C86:  LDD  M_XP                   ;?PLAYER IN FRONT?
L8C89:  BMI  CPUAL_140              ;B IGNORE GUNS IF IN BACK
L8C8B:  INC  AS_AIM,X
L8C8D:  SUBD #$4000
L8C90:  BGE  CPUAL_140              ;IGNORE GUN IF TOO FAR AWAY
L8C92:  LDD  AS_CHST,X              ;SET PLAYER IN ALIENS VIEW
L8C95:  ORB  #(CS_AV&$FF)           ;CHSET C$AV
L8C97:  STD  AS_CHST,X
L8C9A:  LDD  M_YPS
L8C9D:  ADDD M_ZPS
L8CA0:  CMPD #$0020                 ;?AIMING NEAR SHIP?
L8CA4:  BHI  CPUAL_140
L8CA6:  LDD  AS_CHST,X              ;PLAYER IN ALIENS SITES
L8CA9:  ORB  #(CS_AS&$FF)           ;CHSET C$AS
L8CAB:  STD  AS_CHST,X

CPUAL_140:
L8CAE:  LDD  AS_CHST,X
L8CB1:  BITA #CS_PV/$100
L8CB3:  BEQ  CPUAL_38               ;NO SHOOTING GUNS IF PLAYER CANT SEE US
L8CB5:  LDD  AS_CHTW,X
L8CB8:  BITA #CS_T9
L8CBA:  BNE  CPUAL_38               ;B NO SHOOT IF AIMMING IN FRONT
L8CBC:  LDD  M_XP
L8CBF:  SUBD #$0800
L8CC2:  BLE  CPUAL_38               ;B TOO CLOSE
L8CC4:  LDA  AS_GLW,X               ;IF ALIEN BEING HIT
L8CC6:  BNE  CPUAL_38               ;B THEN DELAY SHOOTING
;WAIT FOR SHIELDS TO STOP
L8CC8:  LDB  WV_HRD
L8CCB:  CMPB #(TGPROZ-TGPROB_8D71)/4 ;# OF WAVES DEFINED IN PROBABILITY TABLE
L8CCD:  BLO  L8CD4                  ;IFHS
L8CCF:  LDU  #TGPROZ-4
L8CD2:  BRA  L8CDB                  ;ELSE
L8CD4:  LSLB
L8CD5:  LSLB
L8CD6:  LDU  #TGPROB_8D71
L8CD9:  LEAU B,U                    ;ACCESS INTO PROBABILITY TABLE
L8CDB:  LDA  FRAME+1                ;FIRE SHELL
L8CDD:  ANDA ,U                     ;SPACE THEM OUT
L8CDF:  BNE  CPUAL_38
L8CE1:  LDA  P_RND1
L8CE4:  CMPA 1,U
L8CE6:  BLS  CPUAL_38               ;MATCHES FRAME, LOWER VAL IS MORE OFTEN
L8CE8:  LDU  2,U                    ;# OF GUNS ALLOWED, TABLE HAS POINTER INTO GUN AREA

CPUAL_32:
L8CEA:  LDA  GS_TYP,U               ;GUN FREE TO START?
L8CEC:  BNE  CPUAL_36               ;NO, THEN GO TO NEXT GUN
L8CEE:  LDX  S1_PRM                 ;YES, GUN READY TO START
L8CF0:  LDD  AS_CHST,X              ;TELL ALIEN HE FIRED A GUN
L8CF3:  ORB  #(CS_AG&$FF)           ;CHSET C$AG
L8CF5:  STD  AS_CHST,X
L8CF8:  JSR  FRAGUN
L8CFB:  BRA  CPUAL_38

CPUAL_36:
L8CFD:  LEAU GS_IZE,U               ;NEXT POTENTIAL GUN
L8CFF:  CMPU #GUNZ
L8D03:  BLO  CPUAL_32

CPUAL_38:
CPUAL_40:
;AIM AT PLAYER
L8D05:  LDX  S1_PRM
L8D07:  LDA  AS_CHTW,X
L8D0A:  BITA #CS_T0
L8D0C:  BEQ  CPUAL_60

CPUAL_41:
L8D0E:  LDA  CP_YW
L8D10:  BNE  CPUAL_50
L8D12:  LDA  M_YP
L8D15:  BMI  CPUAL_42
L8D17:  JSR  SNYWR
L8D1A:  BRA  CPUAL_45

CPUAL_42:
L8D1C:  JSR  SNYWL

CPUAL_45:
L8D1F:  LDA  CP_RL
L8D21:  BNE  CPUAL_50               ;?HELP YAW BY ROLLING?
L8D23:  LDB  M_ZP
L8D26:  SEX
L8D27:  ADDB #$01
L8D29:  CMPB #$01
L8D2B:  BLS  CPUAL_50               ;?FAR ENOUGH AWAY? AVOID JITTER
L8D2D:  EORA M_YP                   ;INVOLVE GUADRANT
L8D30:  BMI  CPUAL_48
L8D32:  JSR  SNRLL                  ;+Z UP, +Y RIGHT QUAD
L8D35:  BRA  CPUAL_50

CPUAL_48:
L8D37:  JSR  SNRLR

CPUAL_50:
L8D3A:  LDA  CP_PT
L8D3C:  BNE  CPUAL_60
L8D3E:  LDA  M_ZP
L8D41:  BMI  CPUAL_52
L8D43:  JSR  SNPTU
L8D46:  BRA  CPUAL_55

CPUAL_52:
L8D48:  JSR  SNPTD

CPUAL_55:
L8D4B:  LDA  CP_RL
L8D4D:  BNE  CPUAL_60               ;?ROLL AVAILABLE TO HELP PITCH?
L8D4F:  LDB  M_YP
L8D52:  SEX
L8D53:  ADDB #$01
L8D55:  CMPB #$01
L8D57:  BLS  CPUAL_60               ;AVOID JITTER
L8D59:  EORA M_ZP                   ;INVOLVE QUADRANTS
L8D5C:  BMI  CPUAL_58
L8D5E:  JSR  SNRLR                  ;+Z UP, +Y RIGHT QUAD
L8D61:  BRA  CPUAL_60

CPUAL_58:
L8D63:  JSR  SNRLL

CPUAL_60:
CPUAL_80:
CPUAL_90:
L8D66:  LDX  S1_PRM
L8D68:  LDD  AS_CHST,X
L8D6B:  ANDA #-1-(CS_PV/$100)
L8D6D:  STD  AS_CHST,X
L8D70:  RTS

TGPROB_8D71:     ;GUN SHOOTING PROB, TIMER MASK(0F=1 SECOND)
;PROB COMPARE (C0=25%)
L8D71:  .byte $0F, $80              ;.PROB 0F,080,1  0
L8D73:  .word (1*-1*GS_IZE)+GUNZ
L8D75:  .byte $0F, $80              ;.PROB 0F,080,1  1
L8D77:  .word (1*-1*GS_IZE)+GUNZ
L8D79:  .byte $0F, $80              ;.PROB 0F,080,2  2
L8D7B:  .word (2*-1*GS_IZE)+GUNZ
L8D7D:  .byte $0F, $40              ;.PROB 0F,040,3  3
L8D7F:  .word (3*-1*GS_IZE)+GUNZ
L8D81:  .byte $07, $80              ;.PROB 07,080,4  4
L8D83:  .word (4*-1*GS_IZE)+GUNZ
L8D85:  .byte $07, $20              ;.PROB 07,020,5  5
L8D87:  .word (5*-1*GS_IZE)+GUNZ
L8D89:  .byte $07, $20              ;.PROB 07,020,6  6
L8D8B:  .word (6*-1*GS_IZE)+GUNZ
L8D8D:  .byte $03, $80              ;.PROB 03,080,6  7
L8D8F:  .word (6*-1*GS_IZE)+GUNZ
L8D91:  .byte $03, $60              ;.PROB 03,060,6  8
L8D93:  .word (6*-1*GS_IZE)+GUNZ
L8D95:  .byte $03, $40              ;.PROB 03,040,6  9
L8D97:  .word (6*-1*GS_IZE)+GUNZ
L8D99:  .byte $03, $30              ;.PROB 03,030,6  10
L8D9B:  .word (6*-1*GS_IZE)+GUNZ

;------------------------------------------------------------------------------
; TGPROZ - MOVE LOCALLY  (comment at the call)
;   (also: CPUMVL)
;------------------------------------------------------------------------------
TGPROZ:
CPUMVL:
L8D9D:  LDX  S1_PRM
L8D9F:  LDU  AS_UVP,X
L8DA1:  LDA  AS_GLW,X
L8DA3:  BNE  CPUMVL_32              ;B NO NEW VELOCITY IF HIT
L8DA5:  LDB  AS_CHMV,X              ;MOVE INFO
L8DA8:  STB  CP_SHF
L8DAA:  LDU  AS_UVP,X
L8DAC:  LDD  #$0000                 ;SET VELOCITY TO ZERO
L8DAF:  STD  MS_VX,U
L8DB1:  STD  MS_VY,U
L8DB3:  STD  MS_VZ,U                ;NOW LET US SLIP

CPUMVL_20:
L8DB5:  LSR  CP_SHF
L8DB7:  BCC  CPUMVL_22
L8DB9:  JSR  SNMVD

CPUMVL_22:
L8DBC:  LSR  CP_SHF
L8DBE:  BCC  CPUMVL_24
L8DC0:  JSR  SNMVD2

CPUMVL_24:
L8DC3:  LSR  CP_SHF
L8DC5:  BCC  CPUMVL_26
L8DC7:  JSR  SNMVU

CPUMVL_26:
L8DCA:  LSR  CP_SHF
L8DCC:  BCC  CPUMVL_28
L8DCE:  JSR  SNMVU2

CPUMVL_28:
L8DD1:  LSR  CP_SHF
L8DD3:  BCC  CPUMVL_30
L8DD5:  JSR  SNMVF

CPUMVL_30:
L8DD8:  LSR  CP_SHF
L8DDA:  BCC  CPUMVL_32
L8DDC:  JSR  SNMVF2

CPUMVL_32:
CPUMVL_40:
L8DDF:  JSR  DOAMOV                 ;AN ALIEN MOVE
L8DE2:  RTS

;------------------------------------------------------------------------------
; CPCHKL - [note] Check alien's distance away, X-->alien parms: keep the high byte of MS_TX, MS_TY and MS_TZ of its
;   unit vectors (AS_UVP) in range, limiting to $7CFF (positive) and $8300 (negative)
;------------------------------------------------------------------------------
CPCHKL:
L8DE3:  LDU  AS_UVP,X               ;ALIEN UNIT VECTORS
L8DE5:  LDD  MS_TX,U                ;.IRPC .1,<XYZ>  DO FOR 3 AXIS
L8DE7:  CMPA #$7D
L8DE9:  BLT  L8DEE
L8DEB:  LDD  #$7CFF
L8DEE:  CMPA #$82
L8DF0:  BGT  L8DF5
L8DF2:  LDD  #$8300
L8DF5:  STD  MS_TX,U
L8DF7:  LDD  MS_TY,U
L8DF9:  CMPA #$7D
L8DFB:  BLT  L8E00
L8DFD:  LDD  #$7CFF
L8E00:  CMPA #$82
L8E02:  BGT  L8E07
L8E04:  LDD  #$8300
L8E07:  STD  MS_TY,U
L8E09:  LDD  MS_TZ,U
L8E0B:  CMPA #$7D
L8E0D:  BLT  L8E12
L8E0F:  LDD  #$7CFF
L8E12:  CMPA #$82
L8E14:  BGT  L8E19
L8E16:  LDD  #$8300
L8E19:  STD  MS_TZ,U
L8E1B:  RTS

;------------------------------------------------------------------------------
; CPUGON - [note] One alien gone: decrement WV_LIV (alien lives left in current wave), holding it at zero
;------------------------------------------------------------------------------
CPUGON:
L8E1C:  DEC  WV_LIV
L8E1E:  BGT  L8E22                  ;IFLE  NO LIVES LEFT IN CURRENT SET
L8E20:  CLR  WV_LIV                 ;MR. PERRY NOID SUGGESTS THIS PROCEDURE
L8E22:  RTS

;------------------------------------------------------------------------------
; NWCHOR - CHOREOGRAPHY ROUTINES
;   NEW CHOREOG
;------------------------------------------------------------------------------
NWCHOR:
L8E23:  LDD  #$0000
L8E26:  STD  AS_CHTW,X              ;NO TWIST OR MOVE
L8E29:  STA  AS_CHTM,X              ;TIME LEFT PER ROUTINE
L8E2C:  STD  AS_CHCN,X              ;UNTIL CONTROL MASK
L8E2F:  STD  AS_CHST,X              ;STATUS FLAGS

CHNXT:
L8E32:  LDU  AS_CHPC,X
L8E34:  LDA  ,U
L8E36:  STA  AS_CHOP,X
L8E38:  BEQ  CHCN_D                 ;DECODE CONTROL IMMEDIATELY

;------------------------------------------------------------------------------
; CHOPDO - DO THE OP-CODE
;------------------------------------------------------------------------------
CHOPDO:
L8E3A:  LDD  AS_CHST,X              ;CHECK CONTROL FLAGS FIRST
L8E3D:  ANDA AS_CHCN,X
L8E40:  BNE  CHCN_E                 ;DO CONTROL
L8E42:  ANDB AS_CHCN+1,X
L8E45:  BNE  CHCN_E                 ;DO CONTROL
L8E47:  LDA  AS_CHOP,X
L8E49:  ANDA #$07
L8E4B:  LSLA
L8E4C:  LDU  #TCHOP
L8E4F:  JMP  [A,U]

;------------------------------------------------------------------------------
; CHCN_D - DECODE CONTROL
;------------------------------------------------------------------------------
CHCN_D:
L8E51:  LDD  1,U                    ;U--> CHINST
L8E53:  STD  AS_CHCN,X
L8E56:  LEAU 3,U
L8E58:  STU  AS_CHPC,X
L8E5A:  BRA  CHNXT

;------------------------------------------------------------------------------
; CHCN_E - [note] Control mask matched status (from CHOPDO): skip 3-byte choreography entries at AS_CHPC until one
;   whose first byte is 0, then go to CHNXT
;------------------------------------------------------------------------------
CHCN_E:
L8E5C:  LDU  AS_CHPC,X

CHCN_E_10:
L8E5E:  LDA  ,U                     ;U--> CHINST
L8E60:  BEQ  CHNXT
L8E62:  LEAU 3,U                    ;CONTROL STATUS CHECK
L8E64:  STU  AS_CHPC,X              ;SKIP UNTIL PROPER ROUTINE FOUND
L8E66:  BRA  CHCN_E_10

TCHOP:
L8E68:  .word CHIF_D                ;0:IF
L8E6A:  .word CHGO_D                ;1: GOTO
L8E6C:  .word CHGS_D                ;2: GOSUB
L8E6E:  .word CHRT_D                ;3: RETURN
L8E70:  .word CHTW_D, CHTW_E        ;4,5: TWIRL
L8E74:  .word CHERR, CHERR          ;6,7: UNASSIGNED

;------------------------------------------------------------------------------
; CHERR - 6,7: UNASSIGNED  (comment at its table entry)
;------------------------------------------------------------------------------
CHERR:
L8E78:  SWI                         ;ERROR

;------------------------------------------------------------------------------
; CHIF_D - IF MASK IS TRUE
;------------------------------------------------------------------------------
CHIF_D:
L8E79:  LDU  AS_CHPC,X

CHIF_D_10:
L8E7B:  LDD  1,U
L8E7D:  BEQ  CHIF_D_50              ;B DEFAULT IF, ALWAYS TRUE
L8E7F:  ANDA AS_CHST,X
L8E82:  BNE  CHIF_D_50              ;B HI MASK IS TRUE
L8E84:  ANDB AS_CHST+1,X
L8E87:  BNE  CHIF_D_50              ;B LO MASK IS TRUE

CHIF_D_20:       ;SKIP TO NEXT IF
L8E89:  LEAU 3,U
L8E8B:  LDA  ,U
L8E8D:  LSLA
L8E8E:  BNE  CHIF_D_20              ;NON-ZERO OP==>TRY AGAIN
L8E90:  BCC  CHIF_D_20              ;ALL ZERO==>UNTIL OP
L8E92:  BRA  CHIF_D_10              ;J OP=80==>'IF' FOUND

CHIF_D_50:
L8E94:  LEAU 3,U
L8E96:  STU  AS_CHPC,X
L8E98:  JMP  CHNXT

;------------------------------------------------------------------------------
; CHGO_D - GOTO
;------------------------------------------------------------------------------
CHGO_D:
L8E9B:  LDU  AS_CHPC,X
L8E9D:  LDU  1,U                    ;SET NEW PC
L8E9F:  STU  AS_CHPC,X
L8EA1:  JMP  CHNXT

;------------------------------------------------------------------------------
; CHGS_D - GOSUB
;------------------------------------------------------------------------------
CHGS_D:
L8EA4:  LDU  AS_CHPC,X              ;SAVE RETURN ADDRESS
L8EA6:  LEAU 3,U                    ;RETURN ADDRESS
L8EA8:  STU  AS_CHRT,X
L8EAB:  LDU  -$2,U                  ;PREVIOUS PARM IS GOSUB ADDRESS
L8EAD:  STU  AS_CHPC,X
L8EAF:  JMP  CHNXT

;------------------------------------------------------------------------------
; CHRT_D - RETURN
;------------------------------------------------------------------------------
CHRT_D:
L8EB2:  LDU  AS_CHRT,X              ;RESTORE PC
L8EB5:  STU  AS_CHPC,X
L8EB7:  JMP  CHNXT

;------------------------------------------------------------------------------
; CHTW_D - TWIRL, DECODE
;------------------------------------------------------------------------------
CHTW_D:
L8EBA:  LDU  AS_CHPC,X
L8EBC:  LDB  ,U                     ;PULL IN TIMER IN QUARTER SECONDS
L8EBE:  LSRB
L8EBF:  STB  AS_CHTM,X
L8EC2:  LDD  1,U                    ;TWIRL AND MOVE
L8EC4:  STD  AS_CHTW,X
L8EC7:  LEAU 3,U
L8EC9:  STU  AS_CHPC,X
L8ECB:  INC  AS_CHOP,X              ;BUMP TO EXECUTE PHASE
L8ECD:  RTS

;------------------------------------------------------------------------------
; CHTW_E - TWIRL, EXECUTE
;------------------------------------------------------------------------------
CHTW_E:
L8ECE:  DEC  AS_CHTM,X              ;TRICK OFF TIMER
L8ED1:  LBMI CHNXT                  ;B IF DONE, GET NEXT OP
L8ED5:  RTS                         ;ELSE WAIT FOR NEXT FRAME

;------------------------------------------------------------------------------
; NWNSHP - CHOREOG MACROS
;------------------------------------------------------------------------------
NWNSHP:
L8ED6:  JSR  INOBJ                  ;INITIALIZE OBJECTS
L8ED9:  LDB  SP_WAV                 ;CURRENT SPACE WAVE
L8EDC:  LSLB
L8EDD:  LDX  #TSPWAV                ;TABLE OF SPACE WAVE GROUPS
L8EE0:  ABX
L8EE1:  CMPX #ZSPWAV                ;PAST END OF TABLE?
L8EE4:  BLO  L8EF4                  ;IFHS  YEP
L8EE6:  LDA  SP_WAV
L8EE9:  LSRA
L8EEA:  BCS  L8EF1                  ;IFCC  EVEN ==> ODD SELECTED WAVE
L8EEC:  LDX  #ZSPWAV-4              ;DARTH COMES SECOND ON SELECTED ODD WAVES
L8EEF:  BRA  L8EF4                  ;ELSE
L8EF1:  LDX  #ZSPWAV-2              ;USE LAST ENTRY IN TABLE, DARTH FIRST WITH MUSIC
L8EF4:  LDX  ,X                     ;POINTS TO CURRENT SET OF WAVES
L8EF6:  LDB  WV_LVL                 ;INDEX INTO SET OF WAVES
L8EF8:  CMPB ,X+                    ;GET SIZE OF THIS SET
L8EFA:  BLS  L8EFE                  ;IFHI  KEEP IT WITHIN RANGE
L8EFC:  LDB  -$1,X
L8EFE:  LSLB                        ;INDEX INTO WORD TABLE
L8EFF:  LDD  B,X
L8F01:  STD  WV_LP                  ;LOOP TABLE POINTER
L8F03:  CLR  WV_LIV                 ;NO ALIENS CURRENTLY ALIVE
L8F05:  LDX  #ALIEN

NWNSHP_20:
L8F08:  STX  S1_PRM
L8F0A:  CLR  AS_TYP,X               ;KILL ALL ALIENS FIRST
L8F0C:  LDU  WV_LP
L8F0E:  BEQ  NWNSHP_90              ;IGNORE ALIEN IF NO CHOREOG SET
L8F10:  LDA  ,U
L8F12:  BEQ  NWNSHP_90              ;?CONSTRUCT THIS SHIP?
L8F14:  INC  WV_LIV                 ;ONE MORE LIFE IN THIS WAVE
L8F16:  LDD  ,U
L8F18:  STD  WV_SHP                 ;SHIP SHAPE AND PARMS
L8F1A:  LDD  2,U
L8F1C:  STD  WV_CHP                 ;CHOREOGRAPHY
L8F1E:  LDD  4,U
L8F20:  STD  WV_BGP                 ;BEGIN LOCATION
L8F22:  LEAU 6,U
L8F24:  STU  WV_LP
L8F26:  JSR  NWASHP

NWNSHP_90:       ;---NEXT ALIEN
L8F29:  LDX  S1_PRM
L8F2B:  LEAX AS_IZE,X
L8F2E:  CMPX #ALIENZ
L8F31:  BLO  NWNSHP_20
L8F33:  RTS

;------------------------------------------------------------------------------
; NWASHP - [note] Make alien record X a live ship: unit vectors (UNITV) facing the player, hits AS_HTA from WV_SHP,
;   location from WV_BGP, choreography WV_CHP (NWCHOR), picture AS_PIC; adds its object with ADBOBJ
;------------------------------------------------------------------------------
NWASHP:
L8F34:  LDA  #$01
L8F36:  STA  AS_TYP,X               ;LIVE ALIEN
L8F38:  LDU  AS_UVP,X
L8F3A:  JSR  UNITV
L8F3D:  LDU  AS_UVP,X
L8F3F:  LDA  #$C0                   ;FACE ALIEN TOWARDS PLAYER
L8F41:  STA  MS_AX,U
L8F43:  STA  MS_BY,U
L8F45:  CLRA
L8F46:  STA  AS_ROL,X
L8F48:  STA  AS_DMC,X
L8F4A:  STA  AS_GLW,X
L8F4C:  STA  AS_DIE,X
L8F4E:  STA  AS_TRGT,X
L8F50:  LDU  WV_SHP
L8F52:  LDA  1,U                    ;DRONES DIE ON N HITS
L8F54:  STA  AS_HTA,X
L8F56:  LDU  AS_UVP,X
L8F58:  LDX  WV_BGP                 ;BEGINNING LOCATION
L8F5A:  LDD  ,X
L8F5C:  STD  MS_TX,U
L8F5E:  LDD  2,X
L8F60:  STD  MS_TY,U
L8F62:  LDD  4,X
L8F64:  STD  MS_TZ,U
L8F66:  LDX  S1_PRM
L8F68:  LDD  WV_CHP
L8F6A:  STD  AS_CHPC,X
L8F6C:  JSR  NWCHOR
L8F6F:  LDX  S1_PRM
L8F71:  LDB  [WV_SHP]
L8F75:  STB  AS_PIC,X               ;CURRENT SHIP PICTURE
L8F77:  JSR  ADBOBJ
L8F7A:  RTS

;------------------------------------------------------------------------------
; ADASHP - [note] Add one alien ship from loop table WV_LP (next WV_LVL of the SP_WAV group when the level ends) into
;   the first empty ALIEN slot, set up as in NWASHP but with no ADBOBJ; INC WV_LIV; exits if no slot or entry
;------------------------------------------------------------------------------
ADASHP:
L8F7B:  LDU  WV_LP
L8F7D:  BEQ  ADASHP_20              ;RESTART IF INVALID WITHIN WAVES
L8F7F:  LDA  ,U
L8F81:  BNE  L8FB1                  ;IFEQ  ?END OF CURRENT LEVEL IN WAVE?

ADASHP_20:
L8F83:  INC  WV_LVL                 ;GET NEXT LEVEL WITHIN WAVE
L8F85:  LDB  SP_WAV                 ;CURRENT SPACE WAVE
L8F88:  LSLB
L8F89:  LDX  #TSPWAV                ;TABLE OF SPACE WAVE GROUPS
L8F8C:  ABX
L8F8D:  CMPX #ZSPWAV                ;PAST END OF TABLE?
L8F90:  BLO  L8FA0                  ;IFHS  YEP
L8F92:  LDA  SP_WAV
L8F95:  LSRA
L8F96:  BCS  L8F9D                  ;IFCC  EVEN ==> ODD SELECTED WAVE
L8F98:  LDX  #ZSPWAV-4              ;DARTH COMES SECOND ON SELECTED ODD WAVES
L8F9B:  BRA  L8FA0                  ;ELSE
L8F9D:  LDX  #ZSPWAV-2              ;USE LAST ENTRY IN TABLE, DARTH FIRST WITH MUSIC
L8FA0:  LDX  ,X                     ;POINTS TO CURRENT SET OF WAVES
L8FA2:  LDB  WV_LVL                 ;INDEX INTO SET OF WAVES
L8FA4:  CMPB ,X+                    ;GET SIZE OF THIS SET
L8FA6:  BLS  L8FAA                  ;IFHI  KEEP IT WITHIN RANGE
L8FA8:  LDB  -$1,X
L8FAA:  STB  WV_LVL                 ;KEEP IT CORRECT
L8FAC:  LSLB                        ;INDEX INTO WORD TABLE
L8FAD:  LDD  B,X
L8FAF:  STD  WV_LP                  ;LOOP TABLE POINTER
L8FB1:  LDX  #ALIEN
L8FB4:  STX  S1_PRM
L8FB6:  LDA  AS_TYP,X
L8FB8:  BEQ  ADASHP_50              ;DO IT IF AN EMPTY SLOT
L8FBA:  LDX  S1_PRM
L8FBC:  LEAX AS_IZE,X
L8FBF:  CMPX #ALIENZ
L8FC2:  BLO  L8FB4                  ;HSEND
L8FC4:  BRA  ADASHP_90              ;IF NO SLOTS AVAILABLE, EXIT NOW

ADASHP_50:
L8FC6:  LDU  WV_LP
L8FC8:  BEQ  ADASHP_90              ;IGNORE ALIEN IF NO CHOREOG SET
L8FCA:  LDA  ,U
L8FCC:  BEQ  ADASHP_90              ;?CONSTRUCT THIS SHIP?
L8FCE:  INC  WV_LIV                 ;ONE MORE LIFE IN THIS WAVE
L8FD0:  LDD  ,U
L8FD2:  STD  WV_SHP                 ;SHIP SHAPE AND PARMS
L8FD4:  LDD  2,U
L8FD6:  STD  WV_CHP                 ;CHOREOGRAPHY
L8FD8:  LDD  4,U
L8FDA:  STD  WV_BGP                 ;BEGIN LOCATION
L8FDC:  LEAU 6,U
L8FDE:  STU  WV_LP
L8FE0:  LDA  #$01
L8FE2:  STA  AS_TYP,X               ;LIVE ALIEN
L8FE4:  LDU  AS_UVP,X
L8FE6:  JSR  UNITV
L8FE9:  LDU  AS_UVP,X
L8FEB:  LDA  #$C0                   ;FACE ALIEN TOWARDS PLAYER
L8FED:  STA  MS_AX,U
L8FEF:  STA  MS_BY,U
L8FF1:  CLRA
L8FF2:  STA  AS_ROL,X
L8FF4:  STA  AS_DMC,X
L8FF6:  STA  AS_GLW,X
L8FF8:  STA  AS_DIE,X
L8FFA:  STA  AS_TRGT,X
L8FFC:  LDU  WV_SHP
L8FFE:  LDA  1,U                    ;DRONES DIE ON N HITS
L9000:  STA  AS_HTA,X
L9002:  LDU  AS_UVP,X
L9004:  LDX  WV_BGP                 ;BEGINNING LOCATION
L9006:  LDD  ,X
L9008:  STD  MS_TX,U
L900A:  LDD  2,X
L900C:  STD  MS_TY,U
L900E:  LDD  4,X
L9010:  STD  MS_TZ,U
L9012:  LDX  S1_PRM
L9014:  LDD  WV_CHP
L9016:  STD  AS_CHPC,X
L9018:  JSR  NWCHOR
L901B:  LDX  S1_PRM
L901D:  LDB  [WV_SHP]
L9021:  STB  AS_PIC,X               ;CURRENT SHIP PICTURE

ADASHP_90:
L9023:  RTS

;.SBTTL SHAPE TABLE

TS_TIE:
L9024:  .byte TDS_TIE, $01          ;.WS TIE,1

TS_RTH:
L9026:  .byte TDS_RTH, $04          ;.WS RTH,4

;.SBTTL STARTING LOCATIONS

TBG1A1:
;FRONT TO BACK, LEFT TO RIGHT, TOP TO BOTTOM
L9028:  .word $7C00                 ;.WB 1A1,0,0,1
L902A:  .word $0000
L902C:  .word $0400

TBG1A2:
L902E:  .word $7C00                 ;.WB 1A2,0,-1,0
L9030:  .word $FC00
L9032:  .word $0000

TBG1A3:
L9034:  .word $7C00                 ;.WB 1A3,0,1,0
L9036:  .word $0400
L9038:  .word $0000

TBG1B1:
L903A:  .word $7C00                 ;.WB 1B1,0,0,1
L903C:  .word $0000
L903E:  .word $0400

TBG1B2:
L9040:  .word $7C00                 ;.WB 1B2,0,-1,0
L9042:  .word $FC00
L9044:  .word $0000

TBG1B3:
L9046:  .word $7C00                 ;.WB 1B3,0,1,0
L9048:  .word $0400
L904A:  .word $0000

TBG1C1:
L904C:  .word $7C00                 ;.WB 1C1,0,0,1
L904E:  .word $0000
L9050:  .word $0400

TBG1C2:
L9052:  .word $7C00                 ;.WB 1C2,0,-1,0
L9054:  .word $FC00
L9056:  .word $0000

TBG1C3:
L9058:  .word $7C00                 ;.WB 1C3,0,1,0
L905A:  .word $0400
L905C:  .word $0000

TBG1D1:
L905E:  .word $7C00                 ;.WB 1D1,0,-2,0
L9060:  .word $F800
L9062:  .word $0000

TBG1D2:
L9064:  .word $7C00                 ;.WB 1D2,0,2,0
L9066:  .word $0800
L9068:  .word $0000

TBG1D3:
L906A:  .word $7C00                 ;.WB 1D3,0,0,2
L906C:  .word $0000
L906E:  .word $0800

;.SBTTL WAVE DATA

TSPWAV:          ;TABLE OF SPACE WAVE SETS
L9070:  .word SETA1
L9072:  .word SETA2
L9074:  .word SETA3
L9076:  .word SETA4
L9078:  .word SETA5
L907A:  .word SETA6

ZSPWAV:
SETA1:
;LAST ENTRY MUST HAVE DARTH FIRST
;NEXT TO LAST HAS DARTH SECOND
L907C:  .byte ((SEZA1-SETA1-1)/2)-1 ;SET A1 TWV1A,TWV2B,TWV2C,TWV2Z
L907D:  .word TWV1A
L907F:  .word TWV2B
L9081:  .word TWV2C
L9083:  .word TWV2Z

SEZA1:
SETA2:
L9085:  .byte ((SEZA2-SETA2-1)/2)-1 ;SET A2 TWV1B,TRTH1D,TWV2D,TWV2C,TWV2Z
L9086:  .word TWV1B
L9088:  .word TRTH1D
L908A:  .word TWV2D
L908C:  .word TWV2C
L908E:  .word TWV2Z

SEZA2:
SETA3:
L9090:  .byte ((SEZA3-SETA3-1)/2)-1 ;SET A3 TWV1C,TRTH1D,TWV2D,TWV2A,TWV2B,TWV2C,TWV2Z
L9091:  .word TWV1C
L9093:  .word TRTH1D
L9095:  .word TWV2D
L9097:  .word TWV2A
L9099:  .word TWV2B
L909B:  .word TWV2C
L909D:  .word TWV2Z

SEZA3:
SETA4:
L909F:  .byte ((SEZA4-SETA4-1)/2)-1 ;SET A4 TRTH1D,TWV2D,TWV2A,TWV2B,TWV2C,TWV2Z
L90A0:  .word TRTH1D
L90A2:  .word TWV2D
L90A4:  .word TWV2A
L90A6:  .word TWV2B
L90A8:  .word TWV2C
L90AA:  .word TWV2Z

SEZA4:
SETA5:
L90AC:  .byte ((SEZA5-SETA5-1)/2)-1 ;SET A5 TWV1D,TRTH1D,TWV2C,TWV2D,TWV2B,TWV2Z
L90AD:  .word TWV1D
L90AF:  .word TRTH1D
L90B1:  .word TWV2C
L90B3:  .word TWV2D
L90B5:  .word TWV2B
L90B7:  .word TWV2Z

SEZA5:
SETA6:
L90B9:  .byte ((SEZA6-SETA6-1)/2)-1 ;SET A6 TRTH1D,TWV2D,TWV2B,TWV2D,TWV2C,TWV2Z
L90BA:  .word TRTH1D
L90BC:  .word TWV2D
L90BE:  .word TWV2B
L90C0:  .word TWV2D
L90C2:  .word TWV2C
L90C4:  .word TWV2Z

SEZA6:
TWV1A:
L90C6:  .word TS_TIE                ;.WV TIE,1A1,1A1
L90C8:  .word TCH1A1
L90CA:  .word TBG1A1
L90CC:  .word TS_TIE                ;.WV TIE,1A2,1A2
L90CE:  .word TCH1A2
L90D0:  .word TBG1A2
L90D2:  .word TS_TIE                ;.WV TIE,1A3,1A3
L90D4:  .word TCH1A3
L90D6:  .word TBG1A3
L90D8:  .byte $00                   ;.WVZ

TWV1B:
L90D9:  .word TS_TIE                ;.WV TIE,1B1,1B1
L90DB:  .word TCH1B1
L90DD:  .word TBG1B1
L90DF:  .word TS_TIE                ;.WV TIE,1B2,1B2
L90E1:  .word TCH1B2
L90E3:  .word TBG1B2
L90E5:  .word TS_TIE                ;.WV TIE,1B3,1B3
L90E7:  .word TCH1B3
L90E9:  .word TBG1B3
L90EB:  .byte $00                   ;.WVZ

TWV1C:
L90EC:  .word TS_TIE                ;.WV TIE,1C1,1C1
L90EE:  .word TCH1C1
L90F0:  .word TBG1C1
L90F2:  .word TS_TIE                ;.WV TIE,1C2,1C2
L90F4:  .word TCH1C2
L90F6:  .word TBG1C2
L90F8:  .word TS_TIE                ;.WV TIE,1C3,1C3
L90FA:  .word TCH1C3
L90FC:  .word TBG1C3
L90FE:  .byte $00                   ;.WVZ

TWV1D:
L90FF:  .word TS_TIE                ;.WV TIE,1D1,1D1
L9101:  .word TCH1D1
L9103:  .word TBG1D1
L9105:  .word TS_TIE                ;.WV TIE,1D2,1D2
L9107:  .word TCH1D2
L9109:  .word TBG1D2
L910B:  .word TS_TIE                ;.WV TIE,1D3,1D3
L910D:  .word TCH1D3
L910F:  .word TBG1D3
L9111:  .byte $00                   ;.WVZ

TRTH1D:
L9112:  .word TS_TIE                ;.WV TIE,1D1,1D1
L9114:  .word TCH1D1
L9116:  .word TBG1D1
L9118:  .word TS_TIE                ;.WV TIE,1D2,1D2
L911A:  .word TCH1D2
L911C:  .word TBG1D2
L911E:  .word TS_RTH                ;.WV RTH,1D3,1D3
L9120:  .word TCH1D3
L9122:  .word TBG1D3
L9124:  .byte $00                   ;.WVZ

TWV2A:
L9125:  .word TS_TIE                ;.WV TIE,2A1,1A1
L9127:  .word TCH2A1
L9129:  .word TBG1A1
L912B:  .word TS_TIE                ;.WV TIE,2A2,1A2
L912D:  .word TCH2A2
L912F:  .word TBG1A2
L9131:  .word TS_TIE                ;.WV TIE,2A3,1A3
L9133:  .word TCH2A3
L9135:  .word TBG1A3
L9137:  .byte $00                   ;.WVZ

TWV2B:
L9138:  .word TS_TIE                ;.WV TIE,2B1,1B1
L913A:  .word TCH2B1
L913C:  .word TBG1B1
L913E:  .word TS_TIE                ;.WV TIE,2B2,1B2
L9140:  .word TCH2B2
L9142:  .word TBG1B2
L9144:  .word TS_TIE                ;.WV TIE,2B3,1B3
L9146:  .word TCH2B3
L9148:  .word TBG1B3
L914A:  .byte $00                   ;.WVZ

TWV2C:
L914B:  .word TS_TIE                ;.WV TIE,2C1,1C1
L914D:  .word TCH2C1
L914F:  .word TBG1C1
L9151:  .word TS_TIE                ;.WV TIE,2C2,1C2
L9153:  .word TCH2C2
L9155:  .word TBG1C2
L9157:  .word TS_TIE                ;.WV TIE,2C3,1C3
L9159:  .word TCH2C3
L915B:  .word TBG1C3
L915D:  .byte $00                   ;.WVZ

TWV2D:
L915E:  .word TS_TIE                ;.WV TIE,2D1,1D1
L9160:  .word TCH2D1
L9162:  .word TBG1D1
L9164:  .word TS_TIE                ;.WV TIE,2D2,1D2
L9166:  .word TCH2D2
L9168:  .word TBG1D2
L916A:  .word TS_TIE                ;.WV TIE,2D3,1D3
L916C:  .word TCH2D3
L916E:  .word TBG1D3
L9170:  .byte $00                   ;.WVZ

TWV2Z:
L9171:  .word TS_TIE                ;.WV TIE,2A1,1A1
L9173:  .word TCH2A1
L9175:  .word TBG1A1
L9177:  .word TS_TIE                ;.WV TIE,2A2,1A2
L9179:  .word TCH2A2
L917B:  .word TBG1A2
L917D:  .word TS_TIE                ;.WV TIE,2A3,1A3
L917F:  .word TCH2A3
L9181:  .word TBG1A3
L9183:  .word TS_TIE                ;.WV TIE,2D1,1D1
L9185:  .word TCH2D1
L9187:  .word TBG1D1
L9189:  .word TS_TIE                ;.WV TIE,2D2,1D2
L918B:  .word TCH2D2
L918D:  .word TBG1D2
L918F:  .word TS_TIE                ;.WV TIE,2D3,1D3
L9191:  .word TCH2D3
L9193:  .word TBG1D3
L9195:  .word TS_TIE                ;.WV TIE,2B1,1B1
L9197:  .word TCH2B1
L9199:  .word TBG1B1
L919B:  .word TS_TIE                ;.WV TIE,2B2,1B2
L919D:  .word TCH2B2
L919F:  .word TBG1B2
L91A1:  .word TS_TIE                ;.WV TIE,2B3,1B3
L91A3:  .word TCH2B3
L91A5:  .word TBG1B3
L91A7:  .word TS_TIE                ;.WV TIE,2D1,1D1
L91A9:  .word TCH2D1
L91AB:  .word TBG1D1
L91AD:  .word TS_TIE                ;.WV TIE,2D2,1D2
L91AF:  .word TCH2D2
L91B1:  .word TBG1D2
L91B3:  .word TS_TIE                ;.WV TIE,2D3,1D3
L91B5:  .word TCH2D3
L91B7:  .word TBG1D3
L91B9:  .word TS_TIE                ;.WV TIE,2C1,1C1
L91BB:  .word TCH2C1
L91BD:  .word TBG1C1
L91BF:  .word TS_TIE                ;.WV TIE,2C2,1C2
L91C1:  .word TCH2C2
L91C3:  .word TBG1C2
L91C5:  .word TS_TIE                ;.WV TIE,2C3,1C3
L91C7:  .word TCH2C3
L91C9:  .word TBG1C3
L91CB:  .word TS_TIE                ;.WV TIE,2D1,1D1
L91CD:  .word TCH2D1
L91CF:  .word TBG1D1
L91D1:  .word TS_TIE                ;.WV TIE,2D2,1D2
L91D3:  .word TCH2D2
L91D5:  .word TBG1D2
L91D7:  .word TS_TIE                ;.WV TIE,2D3,1D3
L91D9:  .word TCH2D3
L91DB:  .word TBG1D3
L91DD:  .byte $00                   ;.WVZ

;.SBTTL CHOREOGRAPHY TABLES

TCH2A1:
L91DE:  .byte $02                   ;.CGOSUB SPLIT
L91DF:  .word SPLIT

TCH1A1:
L91E1:  .byte $84, $00, CS_MF       ;.CT 40,0,C$MF  TAKES ME HALFWAY TO PLAYER
L91E4:  .byte $84, $00, CS_MF2      ;.CT 40,0,C$MF2
L91E7:  .byte $44, CS_PU, CS_MF     ;.CT 20,C$PU,C$MF  PREPARE FOR TURNOVER
L91EA:  .byte $00                   ;.CUNTIL C$AS
L91EB:  .word CS_AS
L91ED:  .byte $44, CS_T0, $00       ;.CT 20,C$T0,0
L91F0:  .byte $00                   ;.CUNTIL C$PN
L91F1:  .word CS_PN
L91F3:  .byte $84, CS_RL+CS_T0, CS_MF ;.CT 40,C$RL+C$T0,C$MF
L91F6:  .byte $00                   ;.CUNTIL C$AS
L91F7:  .word CS_AS
L91F9:  .byte $44, CS_T0, $00       ;.CT 20,C$T0,0
L91FC:  .byte $00                   ;.CUNTIL 0
L91FD:  .word $0000
L91FF:  .byte $01                   ;.CGOTO TCH1AZ
L9200:  .word TCH1AZ

TCH2A2:
L9202:  .byte $02                   ;.CGOSUB SPLIT
L9203:  .word SPLIT

TCH1A2:
L9205:  .byte $84, CS_RR, CS_MF2    ;.CT 40,C$RR,C$MF2  GO FAST TO OTHER WALL
L9208:  .byte $44, CS_YR, CS_MF     ;.CT 20,C$YR,C$MF
L920B:  .byte $00                   ;.CUNTIL C$AS
L920C:  .word CS_AS
L920E:  .byte $44, CS_YR+CS_T0, CS_MF ;.CT 20,C$YR+C$T0,C$MF
L9211:  .byte $00                   ;.CUNTIL 0
L9212:  .word $0000
L9214:  .byte $84, CS_RR, CS_MF     ;.CT 40,C$RR,C$MF
L9217:  .byte $00                   ;.CUNTIL C$AS
L9218:  .word CS_AS
L921A:  .byte $44, CS_YR+CS_T0, CS_MF ;.CT 20,C$YR+C$T0,C$MF
L921D:  .byte $00                   ;.CUNTIL 0
L921E:  .word $0000
L9220:  .byte $44, CS_RR, CS_MF2    ;.CT 20,C$RR,C$MF2
L9223:  .byte $00                   ;.CUNTIL C$AS
L9224:  .word CS_AS
L9226:  .byte $44, CS_YR+CS_T0, CS_MF ;.CT 20,C$YR+C$T0,C$MF
L9229:  .byte $00                   ;.CUNTIL 0
L922A:  .word $0000
L922C:  .byte $01                   ;.CGOTO TCH1AZ
L922D:  .word TCH1AZ

TCH2A3:
L922F:  .byte $02                   ;.CGOSUB SPLIT
L9230:  .word SPLIT

TCH1A3:
L9232:  .byte $84, CS_RL, CS_MF2    ;.CT 40,C$RL,C$MF2  GO FAST TO OTHER WALL
L9235:  .byte $44, CS_YL, CS_MF     ;.CT 20,C$YL,C$MF
L9238:  .byte $00                   ;.CUNTIL C$AS
L9239:  .word CS_AS
L923B:  .byte $44, CS_YL+CS_T0, CS_MF ;.CT 20,C$YL+C$T0,C$MF
L923E:  .byte $00                   ;.CUNTIL 0
L923F:  .word $0000
L9241:  .byte $84, CS_RL, CS_MF     ;.CT 40,C$RL,C$MF
L9244:  .byte $00                   ;.CUNTIL C$AS
L9245:  .word CS_AS
L9247:  .byte $44, CS_YL+CS_T0, CS_MF ;.CT 20,C$YL+C$T0,C$MF
L924A:  .byte $00                   ;.CUNTIL 0
L924B:  .word $0000
L924D:  .byte $44, CS_RL, CS_MF2    ;.CT 20,C$RL,C$MF2
L9250:  .byte $00                   ;.CUNTIL C$AS
L9251:  .word CS_AS
L9253:  .byte $44, CS_YL+CS_T0, CS_MF ;.CT 20,C$YL+C$T0,C$MF
L9256:  .byte $00                   ;.CUNTIL 0
L9257:  .word $0000
L9259:  .byte $01                   ;.CGOTO TCH1AZ
L925A:  .word TCH1AZ

TCH1AZ:          ;BE MEAN TO PLAYER
TCH1AZ_10:
L925C:  .byte $00                   ;.CUNTIL C$AS+C$AG
L925D:  .word CS_AS+CS_AG
L925F:  .byte $44, CS_RR+CS_T0, CS_MF2 ;.CT 20,C$RR+C$T0,C$MF2
L9262:  .byte $00                   ;.CUNTIL C$AG
L9263:  .word CS_AG
L9265:  .byte $44, CS_RL, CS_MF2    ;.CT 20,C$RL,C$MF2
L9268:  .byte $01                   ;.CGOTO 10$
L9269:  .word TCH1AZ
L926B:  .byte $00                   ;.CUNTIL 0
L926C:  .word $0000
L926E:  .byte $24, $00, CS_MU2      ;.CT 10,0,C$MU2
L9271:  .byte $01                   ;.CGOTO 10$
L9272:  .word TCH1AZ

TCH2B1:
L9274:  .byte $02                   ;.CGOSUB SPLIT
L9275:  .word SPLIT

TCH1B1:
L9277:  .byte $44, $00, CS_MF+CS_MU ;.CT 20,0,C$MF+C$MU
L927A:  .byte $44, $00, CS_MF+CS_MD ;.CT 20,0,C$MF+C$MD  PARTNERS PASS PLAYER
L927D:  .byte $44, $00, CS_MF+CS_MU ;.CT 20,0,C$MF+C$MU
L9280:  .byte $44, $00, CS_MF+CS_MD ;.CT 20,0,C$MF+C$MD  PARTNERS PASS PLAYER
L9283:  .byte $44, CS_PU, CS_MF     ;.CT 20,C$PU,C$MF  PREPARE FOR TURNOVER
L9286:  .byte $00                   ;.CUNTIL C$AS
L9287:  .word CS_AS
L9289:  .byte $44, CS_T0, $00       ;.CT 20,C$T0,0
L928C:  .byte $00                   ;.CUNTIL 0
L928D:  .word $0000
L928F:  .byte $44, $00, CS_MF+CS_MU ;.CT 20,0,C$MF+C$MU  GOTO EDGE
L9292:  .byte $44, $00, CS_MF+CS_MD ;.CT 20,0,C$MF+C$MD
L9295:  .byte $84, CS_T0, CS_MF+CS_MU ;.CT 40,C$T0,C$MF+C$MU
L9298:  .byte $44, $00, CS_MF+CS_MU ;.CT 20,0,C$MF+C$MU
L929B:  .byte $44, $00, CS_MF+CS_MD ;.CT 20,0,C$MF+C$MD
L929E:  .byte $00                   ;.CUNTIL C$AS
L929F:  .word CS_AS
L92A1:  .byte $44, CS_T0, CS_MU     ;.CT 20,C$T0,C$MU
L92A4:  .byte $00                   ;.CUNTIL 0
L92A5:  .word $0000
L92A7:  .byte $01                   ;.CGOTO TCH1BZ
L92A8:  .word TCH1BZ

TCH2B2:
L92AA:  .byte $02                   ;.CGOSUB SPLIT
L92AB:  .word SPLIT

TCH1B2:
L92AD:  .byte $24, $00, CS_MF+CS_MU2 ;.CT 10,0,C$MF+C$MU2  GOTO OTHER WALL
L92B0:  .byte $24, $00, CS_MF+CS_MD2 ;.CT 10,0,C$MF+C$MD2
L92B3:  .byte $24, $00, CS_MF2+CS_MU2 ;.CT 10,0,C$MF2+C$MU2
L92B6:  .byte $24, $00, CS_MF2+CS_MD2 ;.CT 10,0,C$MF2+C$MD2
L92B9:  .byte $00                   ;.CUNTIL C$AS
L92BA:  .word CS_AS
L92BC:  .byte $44, CS_T0, CS_MF+CS_MD ;.CT 20,C$T0,C$MF+C$MD
L92BF:  .byte $00                   ;.CUNTIL 0
L92C0:  .word $0000
L92C2:  .byte $00                   ;.CUNTIL C$AS
L92C3:  .word CS_AS
L92C5:  .byte $44, CS_T0, CS_MF+CS_MU ;.CT 20,C$T0,C$MF+C$MU
L92C8:  .byte $00                   ;.CUNTIL 0
L92C9:  .word $0000
L92CB:  .byte $01                   ;.CGOTO TCH1BZ
L92CC:  .word TCH1BZ

TCH2B3:
L92CE:  .byte $02                   ;.CGOSUB SPLIT
L92CF:  .word SPLIT

TCH1B3:
L92D1:  .byte $24, $00, CS_MF+CS_MU2 ;.CT 10,0,C$MF+C$MU2  GOTO OTHER WALL
L92D4:  .byte $24, $00, CS_MF+CS_MD2 ;.CT 10,0,C$MF+C$MD2
L92D7:  .byte $24, $00, CS_MF2+CS_MU2 ;.CT 10,0,C$MF2+C$MU2
L92DA:  .byte $24, $00, CS_MF2+CS_MD2 ;.CT 10,0,C$MF2+C$MD2
L92DD:  .byte $00                   ;.CUNTIL C$AS
L92DE:  .word CS_AS
L92E0:  .byte $44, CS_T0, CS_MF+CS_MD ;.CT 20,C$T0,C$MF+C$MD
L92E3:  .byte $00                   ;.CUNTIL 0
L92E4:  .word $0000
L92E6:  .byte $01                   ;.CGOTO TCH1BZ
L92E7:  .word TCH1BZ

TCH1BZ:          ;BE MEAN TO PLAYER
TCH1BZ_10:
L92E9:  .byte $00                   ;.CUNTIL C$AS+C$AG
L92EA:  .word CS_AS+CS_AG
L92EC:  .byte $44, CS_RR+CS_T0, CS_MF2 ;.CT 20,C$RR+C$T0,C$MF2
L92EF:  .byte $00                   ;.CUNTIL C$AG
L92F0:  .word CS_AG
L92F2:  .byte $44, CS_RR, CS_MF2    ;.CT 20,C$RR,C$MF2
L92F5:  .byte $01                   ;.CGOTO 10$
L92F6:  .word TCH1BZ
L92F8:  .byte $00                   ;.CUNTIL 0
L92F9:  .word $0000
L92FB:  .byte $24, $00, CS_MU2      ;.CT 10,0,C$MU2
L92FE:  .byte $00                   ;.CUNTIL C$PN
L92FF:  .word CS_PN
L9301:  .byte $FC, CS_RR+CS_T0, CS_MF ;.CT 80,C$RR+C$T0,C$MF
L9304:  .byte $00                   ;.CUNTIL 0
L9305:  .word $0000
L9307:  .byte $44, CS_RR+CS_T0, CS_MU2 ;.CT 20,C$RR+C$T0,C$MU2
L930A:  .byte $44, CS_RL+CS_T0, CS_MD2 ;.CT 20,C$RL+C$T0,C$MD2
L930D:  .byte $44, CS_RL+CS_T0, CS_MU2 ;.CT 20,C$RL+C$T0,C$MU2
L9310:  .byte $44, CS_RR+CS_T0, CS_MD2 ;.CT 20,C$RR+C$T0,C$MD2
L9313:  .byte $01                   ;.CGOTO 10$
L9314:  .word TCH1BZ

TCH2C1:
L9316:  .byte $02                   ;.CGOSUB SPLIT
L9317:  .word SPLIT

TCH1C1:
L9319:  .byte $24, $00, CS_MF+CS_MU ;.CT 10,0,C$MF+C$MU
L931C:  .byte $24, $00, CS_MF+CS_MD ;.CT 10,0,C$MF+C$MD  PARTNERS PASS PLAYER
L931F:  .byte $24, $00, CS_MF+CS_MU ;.CT 10,0,C$MF+C$MU
L9322:  .byte $24, $00, CS_MF+CS_MD ;.CT 10,0,C$MF+C$MD
L9325:  .byte $44, CS_PU, CS_MF     ;.CT 20,C$PU,C$MF  PREPARE FOR TURNOVER
L9328:  .byte $00                   ;.CUNTIL C$AS
L9329:  .word CS_AS
L932B:  .byte $44, CS_T0, $00       ;.CT 20,C$T0,0
L932E:  .byte $00                   ;.CUNTIL 0
L932F:  .word $0000
L9331:  .byte $00                   ;.CUNTIL C$AS
L9332:  .word CS_AS
L9334:  .byte $44, CS_T0, CS_MU     ;.CT 20,C$T0,C$MU
L9337:  .byte $00                   ;.CUNTIL 0
L9338:  .word $0000

TCH2C2:
L933A:  .byte $02                   ;.CGOSUB SPLIT
L933B:  .word SPLIT

TCH1C2:
L933D:  .byte $44, CS_RR+CS_T0, CS_MF+CS_MU ;.CT 20,C$RR+C$T0,C$MF+C$MU  GO FAST TO OTHER WALL
L9340:  .byte $44, CS_RR+CS_T0, CS_MF2+CS_MU ;.CT 20,C$RR+C$T0,C$MF2+C$MU  GO FAST TO OTHER WALL
L9343:  .byte $44, CS_YR, CS_MF+CS_MU ;.CT 20,C$YR,C$MF+C$MU
L9346:  .byte $00                   ;.CUNTIL C$AS
L9347:  .word CS_AS
L9349:  .byte $44, CS_YR+CS_T0, CS_MF+CS_MU ;.CT 20,C$YR+C$T0,C$MF+C$MU
L934C:  .byte $00                   ;.CUNTIL 0
L934D:  .word $0000
L934F:  .byte $01                   ;.CGOTO TCH1CZ
L9350:  .word TCH1CZ

TCH2C3:
L9352:  .byte $02                   ;.CGOSUB SPLIT
L9353:  .word SPLIT

TCH1C3:
L9355:  .byte $44, CS_RL+CS_T0, CS_MF+CS_MU ;.CT 20,C$RL+C$T0,C$MF+C$MU  GO FAST TO OTHER WALL
L9358:  .byte $44, CS_RL+CS_T0, CS_MF2+CS_MU ;.CT 20,C$RL+C$T0,C$MF2+C$MU  GO FAST TO OTHER WALL
L935B:  .byte $44, CS_YL, CS_MF+CS_MU ;.CT 20,C$YL,C$MF+C$MU
L935E:  .byte $00                   ;.CUNTIL C$AS
L935F:  .word CS_AS
L9361:  .byte $44, CS_YL+CS_T0, CS_MF+CS_MU ;.CT 20,C$YL+C$T0,C$MF+C$MU
L9364:  .byte $00                   ;.CUNTIL 0
L9365:  .word $0000
L9367:  .byte $01                   ;.CGOTO TCH1CZ
L9368:  .word TCH1CZ

TCH1CZ:          ;BE MEAN TO PLAYER
TCH1CZ_10:
L936A:  .byte $00                   ;.CUNTIL C$AS+C$AG
L936B:  .word CS_AS+CS_AG
L936D:  .byte $44, CS_RR+CS_T0, CS_MF2+CS_MU ;.CT 20,C$RR+C$T0,C$MF2+C$MU
L9370:  .byte $00                   ;.CUNTIL C$AG
L9371:  .word CS_AG
L9373:  .byte $44, CS_RL, CS_MF2    ;.CT 20,C$RL,C$MF2
L9376:  .byte $01                   ;.CGOTO 10$
L9377:  .word TCH1CZ
L9379:  .byte $00                   ;.CUNTIL 0
L937A:  .word $0000
L937C:  .byte $24, $00, CS_MD2      ;.CT 10,0,C$MD2
L937F:  .byte $01                   ;.CGOTO 10$
L9380:  .word TCH1CZ

TCH2D1:
L9382:  .byte $02                   ;.CGOSUB SPLIT
L9383:  .word SPLIT

TCH1D1:
;.CT 10,C$RL+C$T0,C$MD2+C$MD
;.CUNTIL C$AS
;.CT 20,C$RL+C$T0,C$MD
;.CUNTIL 0
L9385:  .byte $00                   ;.CUNTIL C$PN
L9386:  .word CS_PN
L9388:  .byte $FC, CS_RR+CS_T0, CS_MF+CS_MU2 ;.CT 80,C$RR+C$T0,C$MF+C$MU2
L938B:  .byte $00                   ;.CUNTIL 0
L938C:  .word $0000
L938E:  .byte $FC, CS_RR+CS_T0, CS_MU2 ;.CT 80,C$RR+C$T0,C$MU2
L9391:  .byte $FC, CS_RR+CS_T0, CS_MU2 ;.CT 80,C$RR+C$T0,C$MU2
L9394:  .byte $FC, CS_RR+CS_T0, CS_MU2 ;.CT 80,C$RR+C$T0,C$MU2
L9397:  .byte $FC, CS_RR+CS_T0, CS_MU2 ;.CT 80,C$RR+C$T0,C$MU2
L939A:  .byte $00                   ;.CUNTIL C$AS
L939B:  .word CS_AS
L939D:  .byte $44, CS_RL+CS_T0, CS_MU2 ;.CT 20,C$RL+C$T0,C$MU2
L93A0:  .byte $00                   ;.CUNTIL 0
L93A1:  .word $0000
L93A3:  .byte $01                   ;.CGOTO TCH1DZ
L93A4:  .word TCH1DZ

TCH2D2:
L93A6:  .byte $02                   ;.CGOSUB SPLIT
L93A7:  .word SPLIT

TCH1D2:
L93A9:  .byte $00                   ;.CUNTIL C$PN
L93AA:  .word CS_PN
L93AC:  .byte $FC, CS_RR+CS_T0, CS_MF+CS_MU2 ;.CT 80,C$RR+C$T0,C$MF+C$MU2
L93AF:  .byte $00                   ;.CUNTIL 0
L93B0:  .word $0000
L93B2:  .byte $84, CS_RL+CS_T0, CS_MU2 ;.CT 40,C$RL+C$T0,C$MU2
L93B5:  .byte $80                   ;.CIF C$R1
L93B6:  .word CS_R1
L93B8:  .byte $44, CS_RR+CS_T0, CS_MU2 ;.CT 20,C$RR+C$T0,C$MU2
L93BB:  .byte $80                   ;.CIF 0
L93BC:  .word $0000
L93BE:  .byte $84, CS_RL+CS_T0, CS_MU2 ;.CT 40,C$RL+C$T0,C$MU2
L93C1:  .byte $80                   ;.CIF C$R1
L93C2:  .word CS_R1
L93C4:  .byte $44, CS_RL+CS_T0, CS_MU2 ;.CT 20,C$RL+C$T0,C$MU2
L93C7:  .byte $80                   ;.CIF 0
L93C8:  .word $0000
L93CA:  .byte $84, CS_RL+CS_T0, CS_MU2 ;.CT 40,C$RL+C$T0,C$MU2
L93CD:  .byte $00                   ;.CUNTIL C$AS
L93CE:  .word CS_AS
L93D0:  .byte $44, CS_RR+CS_T0, CS_MU2 ;.CT 20,C$RR+C$T0,C$MU2
L93D3:  .byte $00                   ;.CUNTIL 0
L93D4:  .word $0000
L93D6:  .byte $01                   ;.CGOTO TCH1DZ
L93D7:  .word TCH1DZ

TCH2D3:
L93D9:  .byte $02                   ;.CGOSUB SPLIT
L93DA:  .word SPLIT

TCH1D3:
L93DC:  .byte $00                   ;.CUNTIL C$PN
L93DD:  .word CS_PN
L93DF:  .byte $14, CS_T0, CS_MF+CS_MU2 ;.CT 02,C$T0,C$MF+C$MU2
L93E2:  .byte $14, CS_T0, CS_MF+CS_MD2 ;.CT 02,C$T0,C$MF+C$MD2
L93E5:  .byte $14, CS_T0, CS_MF+CS_MU2 ;.CT 02,C$T0,C$MF+C$MU2
L93E8:  .byte $14, CS_T0, CS_MF+CS_MD2 ;.CT 02,C$T0,C$MF+C$MD2
L93EB:  .byte $14, CS_T0, CS_MF+CS_MU2 ;.CT 02,C$T0,C$MF+C$MU2
L93EE:  .byte $14, CS_T0, CS_MF+CS_MD2 ;.CT 02,C$T0,C$MF+C$MD2
L93F1:  .byte $14, CS_T0, CS_MF+CS_MU2 ;.CT 02,C$T0,C$MF+C$MU2
L93F4:  .byte $14, CS_T0, CS_MF+CS_MD2 ;.CT 02,C$T0,C$MF+C$MD2
L93F7:  .byte $00                   ;.CUNTIL 0
L93F8:  .word $0000
L93FA:  .byte $00                   ;.CUNTIL C$AH
L93FB:  .word CS_AH
L93FD:  .byte $44, CS_T0+CS_YL+CS_YR, CS_MU2 ;.CT 20,C$T0+C$YL+C$YR,C$MU2
L9400:  .byte $44, CS_T0+CS_PU+CS_PD, CS_MU2 ;.CT 20,C$T0+C$PU+C$PD,C$MU2
L9403:  .byte $44, CS_T0+CS_YL+CS_YR, CS_MD2 ;.CT 20,C$T0+C$YL+C$YR,C$MD2
L9406:  .byte $44, CS_T0+CS_PU+CS_PD, CS_MD2 ;.CT 20,C$T0+C$PU+C$PD,C$MD2
L9409:  .byte $44, CS_T0+CS_YL+CS_YR, CS_MU2 ;.CT 20,C$T0+C$YL+C$YR,C$MU2
L940C:  .byte $44, CS_T0+CS_PU+CS_PD, CS_MU2 ;.CT 20,C$T0+C$PU+C$PD,C$MU2
L940F:  .byte $44, CS_T0+CS_YL+CS_YR, CS_MD2 ;.CT 20,C$T0+C$YL+C$YR,C$MD2
L9412:  .byte $44, CS_T0+CS_PU+CS_PD, CS_MD2 ;.CT 20,C$T0+C$PU+C$PD,C$MD2
L9415:  .byte $00                   ;.CUNTIL C$AS
L9416:  .word CS_AS
L9418:  .byte $44, CS_RL+CS_T0, CS_MF ;.CT 20,C$RL+C$T0,C$MF
L941B:  .byte $00                   ;.CUNTIL 0
L941C:  .word $0000
L941E:  .byte $01                   ;.CGOTO TCH1DZ
L941F:  .word TCH1DZ

SPLIT:
L9421:  .byte $0C, CS_T0, CS_MF     ;.CT 01,C$T0,C$MF  ALLOW RANDOM TO GET SET
L9424:  .byte $80                   ;.CIF C$R1
L9425:  .word CS_R1
L9427:  .byte $01                   ;.CGOTO 20$
L9428:  .word SPLIT_20
L942A:  .byte $80                   ;.CIF C$R2
L942B:  .word CS_R2
L942D:  .byte $44, CS_T0, CS_MF3+CS_MU3 ;.CT 20,C$T0,C$MF3+C$MU3
L9430:  .byte $01                   ;.CGOTO 40$
L9431:  .word SPLIT_40
L9433:  .byte $80                   ;.CIF 0
L9434:  .word $0000
L9436:  .byte $44, CS_T0, CS_MF3+CS_MD3 ;.CT 20,C$T0,C$MF3+C$MD3
L9439:  .byte $01                   ;.CGOTO 40$
L943A:  .word SPLIT_40

SPLIT_20:
L943C:  .byte $80                   ;.CIF C$R2
L943D:  .word CS_R2
L943F:  .byte $44, CS_T0+CS_RR, CS_MF3+CS_MU3 ;.CT 20,C$T0+C$RR,C$MF3+C$MU3
L9442:  .byte $01                   ;.CGOTO 40$
L9443:  .word SPLIT_40
L9445:  .byte $80                   ;.CIF 0
L9446:  .word $0000
L9448:  .byte $44, CS_T0+CS_RR, CS_MF3+CS_MD3 ;.CT 20,C$T0+C$RR,C$MF3+C$MD3
L944B:  .byte $01                   ;.CGOTO 40$
L944C:  .word SPLIT_40

SPLIT_40:
L944E:  .byte $80                   ;.CIF C$R2
L944F:  .word CS_R2
L9451:  .byte $44, CS_T9+CS_RL, CS_MF2 ;.CT 20,C$T9+C$RL,C$MF2
L9454:  .byte $80                   ;.CIF 0
L9455:  .word $0000
L9457:  .byte $03                   ;.CRETURN
L9458:  .word $0000

TCH1DZ:          ;BE MEAN TO PLAYER
TCH1DZ_10:
L945A:  .byte $24, $00, CS_MU2      ;.CT 10,0,C$MU2
L945D:  .byte $00                   ;.CUNTIL C$PN
L945E:  .word CS_PN
L9460:  .byte $84, CS_RL+CS_T0, CS_MF2 ;.CT 40,C$RL+C$T0,C$MF2
L9463:  .byte $00                   ;.CUNTIL C$AS+C$AG
L9464:  .word CS_AS+CS_AG
L9466:  .byte $44, CS_RR+CS_T0, CS_MF2 ;.CT 20,C$RR+C$T0,C$MF2
L9469:  .byte $00                   ;.CUNTIL C$AG
L946A:  .word CS_AG
L946C:  .byte $44, CS_RL, CS_MF     ;.CT 20,C$RL,C$MF
L946F:  .byte $00                   ;.CUNTIL 0
L9470:  .word $0000
;;; .CGOTO 10$
L9472:  .byte $00                   ;.CUNTIL C$PN+C$PS
L9473:  .word CS_PN+CS_PS
L9475:  .byte $84, CS_RL+CS_T0, CS_MF2 ;.CT 40,C$RL+C$T0,C$MF2
L9478:  .byte $00                   ;.CUNTIL C$AS+C$AG+C$PS
L9479:  .word CS_AS+CS_AG+CS_PS
L947B:  .byte $44, CS_RR+CS_T0, CS_MF2 ;.CT 20,C$RR+C$T0,C$MF2
L947E:  .byte $00                   ;.CUNTIL C$AG+C$PS
L947F:  .word CS_AG+CS_PS
L9481:  .byte $44, CS_RL, CS_MF     ;.CT 20,C$RL,C$MF
L9484:  .byte $00                   ;.CUNTIL 0
L9485:  .word $0000
L9487:  .byte $80                   ;.CIF C$PS
L9488:  .word CS_PS
L948A:  .byte $01                   ;.CGOTO 20$
L948B:  .word TCH1DZ_20
L948D:  .byte $80                   ;.CIF 0
L948E:  .word $0000
L9490:  .byte $01                   ;.CGOTO 10$
L9491:  .word TCH1DZ

TCH1DZ_20:
L9493:  .byte $80                   ;.CIF C$R1
L9494:  .word CS_R1
L9496:  .byte $44, CS_RR, CS_MU2    ;.CT 20,C$RR,C$MU2
L9499:  .byte $01                   ;.CGOTO 10$
L949A:  .word TCH1DZ
L949C:  .byte $80                   ;.CIF 0
L949D:  .word $0000
L949F:  .byte $44, CS_RL, CS_MF2    ;.CT 20,C$RL,C$MF2
L94A2:  .byte $01                   ;.CGOTO 10$
L94A3:  .word TCH1DZ

;==============================================================================
; MODULE WSFIL1   WSFIL1.MAC
;==============================================================================

;.SBTTL STAR WARS FILLER FOR ROM 1
L94A5:  .byte $B8, $5D, $78, $28, $40, $EC, $D4, $B7 ;.IRPC .A,<EARL VICKERS DID AUDIO>
L94AD:  .byte $2A, $89, $60, $C6, $20, $84, $3D, $70
L94B5:  .byte $00, $78, $ED, $B0, $68, $EF

CHKSM1:
L94BB:  .word PCKS1

FILL1:
L94BD:  .byte $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF ;.REPT 106.  FILL WITH FF'S
L94C5:  .byte $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
L94CD:  .byte $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
L94D5:  .byte $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
L94DD:  .byte $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
L94E5:  .byte $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
L94ED:  .byte $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
L94F5:  .byte $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
L94FD:  .byte $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
L9505:  .byte $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
L950D:  .byte $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
L9515:  .byte $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
L951D:  .byte $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
L9525:  .byte $FF, $FF

CPYRT1:
L9527:  .byte $43, $4F, $50, $59, $52, $49, $47, $48 ;.ASCII /COPYRIGHT 1983 ATARI/
L952F:  .byte $54, $20, $31, $39, $38, $33, $20, $41
L9537:  .byte $54, $41, $52, $49

;==============================================================================
; MODULE WSGAS   WSGAS.MAC
;   GAS AND SCORE
;==============================================================================

;------------------------------------------------------------------------------
; ADCGAS - GAS--DO1GAS,VWGAS,ADCGAS
;   ADD CANNED GAS
;------------------------------------------------------------------------------
ADCGAS:
L953B:  LDA  OPTS1                  ;HIGH NIBBLE OF OPTION BANK 2
L953E:  ANDA #$03                   ;HOW MUCH BONUS ENERGY?
L9540:  BEQ  L9557                  ;IFNE  MORE THAN NOTHING
L9542:  ADDA S_GAS                  ;ADD IT IN
L9544:  STA  S_GAS
L9546:  LDA  OPTS1+1                ;LOW NIBBLE OF OPTION BANK 2
L9549:  ANDA #$03                   ;MAX ALLOWABLE GAS IS STARTING AMOUNT
L954B:  ADDA #$06
L954D:  CMPA S_GAS
L954F:  BHS  L9553                  ;IFLO  OVER THE MAX LIMIT
L9551:  STA  S_GAS                  ;SO SET IT TO THE LIMIT
L9553:  LDA  #$14                   ;SHOW GAS REFUEL FOR A SECOND
L9555:  STA  S_CAN
L9557:  RTS

;------------------------------------------------------------------------------
; DO1GAS - WE MIGHT INC GAS  (comment at the call)
;------------------------------------------------------------------------------
DO1GAS:
L9558:  LDA  GS_GLW                 ;WHAT CAN WE LOSE?
L955A:  BLE  L95A0                  ;IFGT  ?SHIELDS HIT?
L955C:  LDA  GS_HIT
L955E:  BGT  L95A0                  ;IFLE  ?AND DONE WITH PREVIOUS GAS CHANGE?
L9560:  LDA  #$01
L9562:  STA  GS_HIT                 ;GAS NOW HANDLING BEING HIT
L9564:  LDA  S_GAS
L9566:  STA  GS_OLD                 ;SAVE OLD AMOUNT FOR FLICKER
L9568:  LDA  #$F6                   ;START DISPLAY ANIMATION FROM SCRATCH
L956A:  ADDA S_GAS
L956C:  STA  GS_LEN
L956E:  DEC  S_GAS                  ;THEN DECREASE OUR FUEL
L9570:  BGE  L9578                  ;IFLT  ?OUT OF FUEL?
L9572:  LDA  #$FF
L9574:  STA  S_GAS                  ;SET TO DEAD
L9576:  CLR  GS_HIT                 ;NO ANIMATION CUZ FINAL MESSAGE ALREADY ON
L9578:  LDA  S_GAS
L957A:  CMPA #$00
L957C:  BNE  L9586                  ;IFEQ
L957E:  JSR  SPKLOS                 ;I'VE LOST R2
L9581:  JSR  AUDDR                  ;DEAD R2, SWAN SONG
L9584:  BRA  L9599                  ;ELSE
L9586:  CMPA #$01
L9588:  BNE  L958F                  ;IFEQ
L958A:  JSR  AUDRC                  ;GAS AT 1 COOKS R2
L958D:  BRA  L9599                  ;ELSE
L958F:  CMPA #$02
L9591:  BNE  L9599                  ;IFEQ
L9593:  JSR  SPKR2T                 ;R2 TRY AND INCREASE THE POWER
L9596:  JSR  AUDRD                  ;R2 DONE
L9599:  CLRB
L959A:  STB  GS_VTP                 ;NO VIEW TOP OF GAUGE
L959C:  STB  GS_VUP                 ;NO VIEW UP PART OF GAUGE
L959E:  STB  GS_VBS                 ;NOT EVEN BASE OF GAUGE YET
L95A0:  LDA  S_CAN                  ;DEC CAN ( FLAG FOR BRIGHT ) UNTIL 00
L95A2:  BEQ  L95A6                  ;IFNE
L95A4:  DEC  S_CAN
L95A6:  RTS

;------------------------------------------------------------------------------
; VWGAS - [note] View the gas gauge: VWGONE if S_GAS is gone and no hit is being handled; else color from TGCLR, title
;   VJFUEL, the gauge (GSVNEW while GS_HIT animates, else GSVALL) and the S_GAS numeral. Y-->VG list
;------------------------------------------------------------------------------
VWGAS:
L95A7:  LDA  GS_HIT
L95A9:  BNE  L95B2                  ;IFEQ  ?FINISHED HANDLING HIT?
L95AB:  LDA  S_GAS
L95AD:  BGT  L95B2                  ;IFLE  ?AND NO GAS LEFT?
L95AF:  JMP  VWGONE                 ;J JUST VIEW GAS GONE MESSAGE
L95B2:  LDB  S_GAS
L95B4:  LSLB
L95B5:  LDX  #TGCLR                 ;SELECT CURRENT COLOR
L95B8:  LDU  B,X
L95BA:  STU  ,Y++
L95BC:  LDD  #VJFUEL                ;SHOW TITLE OF GAS GAUGE
L95BF:  STD  ,Y++
L95C1:  LDD  #VGRW0&$1FFF           ;GOTO BASE OF GAUGE
L95C4:  STD  ,Y++
L95C6:  LDD  #$0000
L95C9:  STD  ,Y++
L95CB:  LDA  GS_HIT
L95CD:  BEQ  L95D4                  ;IFNE  ?ARE WE ANIMATING A HIT?
L95CF:  JSR  GSVNEW                 ;THEN VIEW OUR NEW DISPLAY
L95D2:  BRA  L95D7                  ;ELSE  ELSE LOOK AT OLD ONE
L95D4:  JSR  GSVALL
L95D7:  LDD  #(-4*VGS_C/2)&$1FFF    ;DOWN 4/2 OF NUMERAL
L95DA:  STD  ,Y++
L95DC:  LDD  #(-1*VGS_CW/2)&$1FFF   ;LEFT ONE HALF NUMERAL
L95DF:  STD  ,Y++
L95E1:  LDA  GS_HIT
L95E3:  BLE  L95EA                  ;IFGT  ?CURRENTLY REDRAWING?
L95E5:  LDU  #VJFLS                 ;THEN FLASH NEW NUMBER
L95E8:  BRA  L95F2                  ;ELSE
L95EA:  LDB  S_GAS
L95EC:  LSLB
L95ED:  LDX  #TGCLR                 ;SELECT CURRENT COLOR
L95F0:  LDU  B,X
L95F2:  STU  ,Y++
L95F4:  CLR  BT_SUP                 ;DONT SUPPRESS ANY NUMERALS
L95F6:  LDA  S_GAS
L95F8:  BGE  L95FB                  ;IFLT
L95FA:  CLRA                        ;LIMIT TO ZERO
L95FB:  JSR  VWBYT1                 ;JUST VIEW ONE NUMERAL OF BYTE
L95FE:  LDD  #VGCNTR
L9601:  STD  ,Y++
L9603:  RTS

;------------------------------------------------------------------------------
; VWGONE - J JUST VIEW GAS GONE MESSAGE  (comment at the call)
;------------------------------------------------------------------------------
VWGONE:
L9604:  LDD  #VGSCAL-$100           ;DOUBLE SIZE
L9607:  STD  ,Y++
L9609:  LDB  #MS_SHG                ;SHIELDS GONE WARNING
L960B:  JSR  DOMESS
L960E:  RTS

;------------------------------------------------------------------------------
; GSVALL - VIEW ALL OF GAS GAUGE
;------------------------------------------------------------------------------
GSVALL:
L960F:  LDB  S_GAS
L9611:  LSLB
L9612:  LDX  #TGCLR
L9615:  LDD  B,X                    ;GET CORRECT COLOR
L9617:  TST  S_CAN                  ;TEST BRIGHT FLAG
L9619:  BEQ  L961D                  ;IFNE  FLAG ON
L961B:  ORB  #$FF                   ;MAKE VERY BRIGHT
L961D:  STD  ,Y++
L961F:  LDB  S_GAS
L9621:  LSLB
L9622:  LDX  #TGALL                 ;DRAW ALL OF THE GAUGE
L9625:  LDU  B,X
L9627:  STU  ,Y++
L9629:  RTS

;------------------------------------------------------------------------------
; GSVNEW - ANIMATE OUR NEW GAS GAUGE
;------------------------------------------------------------------------------
GSVNEW:
L962A:  LDA  GS_VTP
L962C:  BNE  L964B                  ;IFEQ  ?WORKING ON SMOOTH TOP LINE?
L962E:  LDU  #VJFLS                 ;FLASH THE OLD VALUE
L9631:  STU  ,Y++
L9633:  LDB  GS_OLD
L9635:  LSLB
L9636:  LDX  #TGALL                 ;COVER UP ALL OF THE GAUGE
L9639:  LDU  B,X
L963B:  STU  ,Y++
L963D:  LDA  FRAMEL
L963F:  ANDA #$00
L9641:  BNE  L9649                  ;IFEQ  ?AND TIME INTERVAL HAS PASSED?
L9643:  INC  GS_LEN
L9645:  BLT  L9649                  ;IFGE  ?FINISHED WITH SHIELD FLASH OF GAS GAUGE?
L9647:  INC  GS_VTP                 ;THEN START REDRAW OF GAUGE, BEGIN WITH TOP
L9649:  BRA  L96A0                  ;ELSE  ELSE DO ANIMATION OF REDRAW NEW GAUGE
L964B:  JSR  GSVHIT                 ;DRAW THE HIT ON THE WHOLE NEW GAUGE
L964E:  LDU  #VJFLS                 ;COVER PART OF NEW WITH FLASH THE OLD VALUE
L9651:  STU  ,Y++
L9653:  LDA  GS_VUP
L9655:  BNE  L9674                  ;IFEQ  ?PREPARE FOR UPSTROKE?
L9657:  LDB  GS_OLD
L9659:  LSLB
L965A:  LDX  #TGUP                  ;COVER UP THE UPSTROKE ET AL.
L965D:  LDU  B,X
L965F:  STU  ,Y++
L9661:  LDA  FRAMEL
L9663:  ANDA #$00
L9665:  BNE  L9672                  ;IFEQ  ?TIME INTERVAL?
L9667:  INC  GS_VUP                 ;SET TO VIEW NORMAL UPSTROKE
L9669:  LDB  S_GAS                  ;FIND WHERE TO UNDO FLASHING OLD GAUGE
L966B:  LDX  #TGDLM                 ;WHERE TO START UNCOVERING NEW GAUGE
L966E:  LDA  B,X
L9670:  STA  GS_LEN
L9672:  BRA  L96A0                  ;ELSE  ELSE NEW UPSTROKE REVEALED, WORK ON BASE
L9674:  LDA  GS_VBS
L9676:  BNE  L9690                  ;IFEQ  ?STILL WORKING ON REVEALING BASE?
L9678:  LDB  GS_LEN
L967A:  LSLB
L967B:  LDX  #TGDRW                 ;DRAW ANIMATION
L967E:  LDU  B,X
L9680:  STU  ,Y++
L9682:  LDA  FRAMEL
L9684:  ANDA #$00
L9686:  BNE  L968E                  ;IFEQ  ?TIME INTERVAL?
L9688:  DEC  GS_LEN                 ;FLASHY COVERING GETS SHORTER AND SHORTER
L968A:  BGT  L968E                  ;IFLE  ?ALL DONE UNCOVERING BASE?
L968C:  INC  GS_VBS                 ;THEN SAY SO
L968E:  BRA  L96A0                  ;ELSE  ELSE NEW BASE FULLY VISIBLE, NEW GAUGE DONE
L9690:  LDA  FRAMEL
L9692:  ANDA #$00
L9694:  BNE  L96A0                  ;IFEQ  ?AND TIME INTERVAL HAS PASSED?
L9696:  LDA  #$00
L9698:  STA  GS_HIT                 ;THEN STOP ANIMATING THE HIT
L969A:  STA  GS_GLW                 ;AND TELL REST OF WORLD WE ARE READY FOR MORE
L969C:  LDA  S_GAS
L969E:  STA  GS_OLD                 ;CURRENT IS NOW OLD, STABILIZE TO CORRECT VALUE
L96A0:  RTS

;------------------------------------------------------------------------------
; GSVHIT - VIEW A DAMAGED FUEL GAUGE
;------------------------------------------------------------------------------
GSVHIT:
L96A1:  LDB  S_GAS                  ;VIEW NEW CURRENT GAS VALUE
L96A3:  LSLB
L96A4:  LDX  #TGCLR
L96A7:  LDD  B,X                    ;GET CORRECT COLOR
L96A9:  STD  ,Y++
L96AB:  LDB  S_GAS                  ;VIEW NEW CURRENT GAS VALUE
L96AD:  LSLB
L96AE:  LDX  #TGALL                 ;DRAW ALL OF THE GAUGE
L96B1:  LDU  B,X
L96B3:  STU  ,Y++
L96B5:  RTS

TGCLR:           ;COLOR BY S.GAS
L96B6:  .word (VGCOFF*$100)+VGCOPC  ;0
L96B8:  .word (VGCRED*$100)+VGCOPC  ;1
L96BA:  .word (VGCRED*$100)+VGCOPC  ;2
L96BC:  .word (VGCYLW*$100)+VGCOPC  ;3
L96BE:  .word (VGCYLW*$100)+VGCOPC  ;4
L96C0:  .word (VGCGRN*$100)+VGCOPC  ;5
L96C2:  .word (VGCGRN*$100)+VGCOPC  ;6
L96C4:  .word (VGCGRN*$100)+VGCOPC  ;7
L96C6:  .word (VGCGRN*$100)+VGCOPC  ;8
L96C8:  .word (VGCGRN*$100)+VGCOPC  ;9

TGALL:           ;DRAW WHOLE PIC, TOP,UPSTROKE,BASELINE
L96CA:  .word VJGA0                 ;.IRP .A,<0,1,2,3,4,5,6,7,8,9>
L96CC:  .word VJGA1
L96CE:  .word VJGA2
L96D0:  .word VJGA3
L96D2:  .word VJGA4
L96D4:  .word VJGA5
L96D6:  .word VJGA6
L96D8:  .word VJGA7
L96DA:  .word VJGA8
L96DC:  .word VJGA9

TGUP:            ;DRAW UPSTROKE FOLLOWED BY BASE LINE
L96DE:  .word VJGU0                 ;.IRP .A,<0,1,2,3,4,5,6,7,8,9>
L96E0:  .word VJGU1
L96E2:  .word VJGU2
L96E4:  .word VJGU3
L96E6:  .word VJGU4
L96E8:  .word VJGU5
L96EA:  .word VJGU6
L96EC:  .word VJGU7
L96EE:  .word VJGU8
L96F0:  .word VJGU9

TGDRW:           ;ANIMATE BY GOING THRU THESE BASE LINES
L96F2:  .word VJG0                  ;.IRP .A,<0,1A,1,2A,2,3A,3,4A,4,5A,5,6A,6,7A,7,8A,8,9A,9>
L96F4:  .word VJG1A
L96F6:  .word VJG1
L96F8:  .word VJG2A
L96FA:  .word VJG2
L96FC:  .word VJG3A
L96FE:  .word VJG3
L9700:  .word VJG4A
L9702:  .word VJG4
L9704:  .word VJG5A
L9706:  .word VJG5
L9708:  .word VJG6A
L970A:  .word VJG6
L970C:  .word VJG7A
L970E:  .word VJG7
L9710:  .word VJG8A
L9712:  .word VJG8
L9714:  .word VJG9A
L9716:  .word VJG9

TGDLM:           ;WHERE TO START UNDOING OLD OVERLAY ON GAUGE
L9718:  .byte $00, $02, $04, $06, $08, $0A, $0C, $0E ;.IRP .A,<0,2,4,6,8,10.,12.,14.,16.,18.>
L9720:  .byte $10, $12

;------------------------------------------------------------------------------
; SCRWAV - SCORE ROUTINES
;   ADD WAVE BONUS TO THE SCORE
;------------------------------------------------------------------------------
SCRWAV:
L9722:  LDA  SC_FWV                 ;FIRST WAVE?
L9725:  BNE  L9739                  ;IFEQ  YES, THEN GIVE THE PLAYER HIS/HER JUST DESSERTS
L9727:  LDB  GM_WAV                 ;JUST FINISHED THIS LEVEL
L972A:  BEQ  L9739                  ;IFNE  WAVE 0 GETS NO BONUS
L972C:  ASLB                        ;*3
L972D:  ADDB GM_WAV
L9730:  LDX  #TSCBN1-3              ;POINTS TO TABLE BUT IGNORING LEVEL 0
L9733:  ABX
L9734:  TFR  X,U
L9736:  JSR  ADUSCR                 ;ADD IT IN
L9739:  RTS

;------------------------------------------------------------------------------
; SCRTWR - SCORE FOR HITTING A TOWER BUNKER  (comment at the call)
;------------------------------------------------------------------------------
SCRTWR:
L973A:  LDU  #TWRMUL                ;INCREMENTAL SCORE FOR TOWERS
L973D:  JSR  ADUSCR                 ;ADD IT IN
L9740:  LDX  #TSCTWR
;ADD TO MULTIPLE SCORE
L9743:  LDA  TWRMUL+2               ;LSD FIRST
L9746:  ADDA 2,X
L9748:  DAA
L9749:  STA  TWRMUL+2
L974C:  LDA  TWRMUL+1
L974F:  ADCA 1,X
L9751:  DAA
L9752:  STA  TWRMUL+1
L9755:  LDA  TWRMUL+0               ;MSD
L9758:  ADCA ,X
L975A:  DAA
L975B:  STA  TWRMUL+0
L975E:  LDA  GD_TWL                 ;HANDLE NUMBER OF TOWERS LEFT
L9761:  BEQ  L9774                  ;IFNE  ?ANY LEFT?
L9763:  ADDA #$99                   ;DECIMAL DEC
L9765:  DAA
L9766:  STA  GD_TWL
L9769:  BNE  L9774                  ;IFEQ  ?DONE ALL TOWERS?
L976B:  LDU  #TSCATP                ;THEN GIVE BIG BONUS
L976E:  JSR  ADUSCR
L9771:  INC  Q_ATP                  ;YEP, ALL TOPS GOT HIT
L9774:  RTS

;------------------------------------------------------------------------------
; SCRSHLD - GIVE POINTS FOR SHIELD ENERGY REMAINING
;------------------------------------------------------------------------------
SCRSHLD:
L9775:  LDB  S_GAS                  ;SET COUNT
L9777:  BEQ  L97AB                  ;IFNE  PROBLEM IF ZERO
L9779:  LDU  #TSCSHL                ;SCORE PER REMAINING SHIELD ENERGY
L977C:  LDA  #$00                   ;START WITH 000000
L977E:  STA  SC_ADD
L9781:  STA  SC_ADD+1
L9784:  STA  SC_ADD+2
L9787:  LDA  2,U
L9789:  ADDA SC_ADD+2
L978C:  DAA
L978D:  STA  SC_ADD+2
L9790:  LDA  1,U
L9792:  ADCA SC_ADD+1
L9795:  DAA
L9796:  STA  SC_ADD+1
L9799:  LDA  ,U
L979B:  ADCA SC_ADD+0
L979E:  DAA
L979F:  STA  SC_ADD+0
L97A2:  DECB                        ;DEC COUNT
L97A3:  BNE  L9787                  ;EQEND
L97A5:  LDU  #SC_ADD                ;POINT TO SCORE WE JUST BUILT
L97A8:  JSR  ADUSCR
L97AB:  RTS

;------------------------------------------------------------------------------
; GETFRP - GET POINTER TO THIS WAVES POINTS
;------------------------------------------------------------------------------
GETFRP:
L97AC:  LDB  GM_WAV
L97AF:  CMPB #(TSCFRZ-TSCFRC)/3
L97B1:  BLO  L97B8                  ;IFHS
L97B3:  LDU  #TSCFRZ-3              ;HIGHER LEVELS USE MAX SCORE
L97B6:  BRA  L97C1                  ;ELSE
L97B8:  LSLB
L97B9:  ADDB GM_WAV                 ;*3
L97BC:  LDU  #TSCFRC
L97BF:  LEAU B,U
L97C1:  RTS

;------------------------------------------------------------------------------
; VWFRC - VIEW THE SUCCESSFUL FORCE SCORE
;------------------------------------------------------------------------------
VWFRC:
L97C2:  LDD  #VJMFL                 ;COLOR
L97C5:  STD  ,Y++
L97C7:  LDD  #VGRW7&$1FFF           ;Y DISTANCE UP
L97CA:  STD  ,Y++
L97CC:  LDD  #$1EC0                 ;X POSITION ON LEFT SCREEN
L97CF:  STD  ,Y++
L97D1:  LDA  #$04                   ;SUPPRESS UP TO 4 LEADING ZEROS
L97D3:  STA  BT_SUP
L97D5:  JSR  GETFRP                 ;U-->6 DIGIT SCORE TO USE
L97D8:  LEAX -$1,U                  ;POINT X-->8 DIGIT FIELD
L97DA:  JSR  VW6DIG                 ;BUT DISPLAY LO 6 DIGITS ONLY
L97DD:  LDB  #MS_USE+1              ;FOLLOW WITH TEXT, FOR USING THE FORCE
L97DF:  JSR  DOMESS                 ;AUTO DOES SCALE AND CENTER RESET
L97E2:  RTS

;------------------------------------------------------------------------------
; SCRFRC - PLAYER USED THE FORCE IN THE TRENCH
;------------------------------------------------------------------------------
SCRFRC:
L97E3:  JSR  GETFRP                 ;U-->LEVEL SCORE
L97E6:  BRA  ADUSCR

;------------------------------------------------------------------------------
; SCRTIES - KILL A REGULAR TIE FIGHTER
;------------------------------------------------------------------------------
SCRTIES:
L97E8:  LDU  #TSCA1D
L97EB:  BRA  ADUSCR

;------------------------------------------------------------------------------
; SCRDARTH - GOT DARTH
;------------------------------------------------------------------------------
SCRDARTH:
L97ED:  LDU  #TSCA2D
L97F0:  BRA  ADUSCR

;------------------------------------------------------------------------------
; SCRPNL - DECORATIVE PANEL
;------------------------------------------------------------------------------
SCRPNL:
L97F2:  LDU  #TSCPNL
L97F5:  BRA  ADUSCR

;------------------------------------------------------------------------------
; SCRBNK - LASER BUNKERS
;------------------------------------------------------------------------------
SCRBNK:
L97F7:  LDU  #TSCBNK
L97FA:  BRA  ADUSCR

;------------------------------------------------------------------------------
; SCRTRT - TRENCH GUN TURRET
;------------------------------------------------------------------------------
SCRTRT:
L97FC:  LDU  #TSCTRT
L97FF:  BRA  ADUSCR

;------------------------------------------------------------------------------
; SCRSHT - HIT FIREBALL
;------------------------------------------------------------------------------
SCRSHT:
L9801:  LDU  #TSCSHT
L9804:  BRA  ADUSCR

;------------------------------------------------------------------------------
; SCRPORT - HIT EXHAUST PORT ( KILLED DEATH STAR )
;------------------------------------------------------------------------------
SCRPORT:
L9806:  LDU  #TSCPRT
L9809:  BRA  ADUSCR

;------------------------------------------------------------------------------
; SCRALL - GOT ALL TOWER TOPS OR BUNKERS IN A WAVE
;------------------------------------------------------------------------------
SCRALL:
L980B:  LDU  #TSCATP
L980E:  BRA  ADUSCR

;------------------------------------------------------------------------------
; ADUSCR - ADD FROM U PTR TO SCORE, USES A REGISTER
;------------------------------------------------------------------------------
ADUSCR:
L9810:  LDA  2,U
L9812:  STA  SC_ADD+2               ;DISPLAY OUR NEW ADDITION
L9815:  ADDA S_SC21
L9817:  DAA
L9818:  STA  S_SC21
L981A:  LDA  1,U
L981C:  STA  SC_ADD+1
L981F:  ADCA S_SC43
L9821:  DAA
L9822:  STA  S_SC43
L9824:  LDA  ,U
L9826:  STA  SC_ADD+0
L9829:  ADCA S_SC65
L982B:  DAA
L982C:  STA  S_SC65
L982E:  LDA  S_SC87
L9830:  ADCA #$00
L9832:  DAA
L9833:  STA  S_SC87
L9835:  LDA  #$FF
L9837:  STA  SC_ADT                 ;NEW TIMER FOR NEW ADDITION
L983A:  RTS

TSCFRC:
L983B:  .byte $00, $50, $00         ;USE THE FORCE IN THE TRENCH
L983E:  .byte $01, $00, $00
L9841:  .byte $02, $50, $00
L9844:  .byte $05, $00, $00
L9847:  .byte $10, $00, $00         ;LEVEL 5 AND ABOVE

TSCFRZ:
TSCA1D:
L984A:  .byte $00, $10, $00         ;TIE FIGHTER SHOT

TSCA2D:
L984D:  .byte $00, $20, $00         ;CHASED DARTH OFF

TSCPNL:
L9850:  .byte $00, $00, $50         ;DECORATIVE PANEL HIT

TSCTRT:
L9853:  .byte $00, $01, $00         ;TRENCH TURRET

TSCTWR:
L9856:  .byte $00, $02, $00         ;TOWER TOP

TSCBNK:
L9859:  .byte $00, $02, $00         ;LASER BUNKER

TSCSHT:
L985C:  .byte $00, $00, $33         ;HIT FIREBALL

TSCPRT:
L985F:  .byte $02, $50, $00         ;EXHAUST PORT

TSCATP:
L9862:  .byte $05, $00, $00         ;ELIMINATED ALL TOWER TOPS AND/OR BUNKERS

TSCSHL:
L9865:  .byte $00, $50, $00         ;SHIELD SCORE FOR REMAINING ENERGY UNITS

TSCBN1:
;NO BONUS FOR CHOOSING DETH STAR 0
L9868:  .byte $20, $00, $00         ;BONUS FOR CHOOSING DETH STAR 1

TSCBN2:
L986B:  .byte $40, $00, $00         ;BONUS FOR CHOOSING DETH STAR 2

TSCBN3:
L986E:  .byte $60, $00, $00         ;BONUS FOR CHOOSING DETH STAR 3

TSCBN4:
L9871:  .byte $80, $00, $00         ;BONUS FOR CHOOSING DETH STAR 4

;==============================================================================
; MODULE WSGLOW   WSGLOW.MAC
;   GLOW AND SHIELDS
;==============================================================================

;------------------------------------------------------------------------------
; BG1GLW - GLOW--DO1GLW,VWGLW
;   BEGIN GLOWING
;------------------------------------------------------------------------------
BG1GLW:
L9874:  LDA  GS_GLW
L9876:  BNE  L987E                  ;IFEQ  ?READY FOR ANOTHER HIT?
L9878:  LDA  #$10                   ;FOR THIS LONG
L987A:  STA  S_GLW
L987C:  INC  GS_GLW                 ;TELL GAS THAT WE HAVE GLOWED ONCE MORE
L987E:  RTS

;------------------------------------------------------------------------------
; KPGLOW - KEEP ON GLOWING, DONT TIME OUT OR STICK
;------------------------------------------------------------------------------
KPGLOW:
L987F:  LDA  FRAMEL
L9881:  ANDA #$03
L9883:  STA  S_GLW
L9885:  RTS

;------------------------------------------------------------------------------
; DO1QGLW - CUT GLOW DOWN TO SIZE
;------------------------------------------------------------------------------
DO1QGLW:
L9886:  LDB  S_GLW
L9888:  CMPB #$08                   ;NEED QUICK GLOW FOR TRENCH SEQUENCES
L988A:  BLS  DO1GLW                 ;IFHI
L988C:  LDB  #$08                   ;INSTEAD OF 10 FROM BG1GLW
L988E:  STB  S_GLW

;------------------------------------------------------------------------------
; DO1GLW - [note] Count S_GLW (glowing from hit) down by one until it reaches zero; DO1QGLW falls into this
;------------------------------------------------------------------------------
DO1GLW:
L9890:  LDB  S_GLW
L9892:  BEQ  L9897                  ;IFNE  NOT FINISHED YET
L9894:  DECB
L9895:  STB  S_GLW
L9897:  RTS

;------------------------------------------------------------------------------
; DONGLW - GLOW THE ALIENS
;------------------------------------------------------------------------------
DONGLW:
L9898:  LDA  FRAMEL
L989A:  ANDA #$00
L989C:  BNE  DONGLW_90
L989E:  LDX  #ALIEN

DONGLW_10:
L98A1:  DEC  AS_GLW,X
L98A3:  BPL  DONGLW_30
L98A5:  CLR  AS_GLW,X               ;FORCE TO ZERO

DONGLW_30:
L98A7:  LEAX AS_IZE,X
L98AA:  CMPX #ALIENZ
L98AD:  BLO  DONGLW_10

DONGLW_90:
L98AF:  RTS

;------------------------------------------------------------------------------
; VWGLW - VIEW GLOW IF WE ARE HIT
;------------------------------------------------------------------------------
VWGLW:
L98B0:  LDB  S_GLW
L98B2:  ANDB #$03                   ;MAKE IT FLASH
L98B4:  BEQ  L98CA                  ;IFNE
L98B6:  LDD  #VGSCAL-$100           ;SUPER LARGE TO BACKLIGHT SCREEN
L98B9:  STD  ,Y++
L98BB:  LDD  #(VGCOLR+(VGCWHT*$100))|$FF ;MAX WHITE
L98BE:  STD  ,Y++
L98C0:  LDD  #VJFCWN                ;BOX
L98C3:  STD  ,Y++
L98C5:  LDD  #VGSCAL                ;RESET SCALE
L98C8:  STD  ,Y++
L98CA:  RTS

;==============================================================================
; MODULE WSGRND   WSGRND.MAC
;   GROUND OBJECT STUFF
;==============================================================================

;.SBTTL TOWER MAZES

TTWRS:           ;TABLE OF NUMBER OF TOWERS IN GROUND MAZE
;WAVE 1 HAS NO GROUND PHASE
L98CB:  .byte YBUNK                 ;TMAP BUNK  00 TOWERS, 7-0, 7-1, 7-2, 7-3 WAVE 02
L98CC:  .byte YSQUARE               ;TMAP SQUARE  16 TOWERS, 8-0, 12-1, 6-2, 2-3 WAVE 03
L98CD:  .byte YCLUSTR               ;TMAP CLUSTR  16 TOWERS, 8-0, 6-1, 7-2, 7-3 WAVE 04
L98CE:  .byte YTURNON               ;TMAP TURNON  20 TOWERS, 12-0, 11-1, 5-2, 0-3 WAVE 05
L98CF:  .byte YWEDGE                ;TMAP WEDGE  20 TOWERS, 8-0, 8-1, 4-2, 8-3 WAVE 06
L98D0:  .byte YDIFF                 ;TMAP DIFF  20 TOWERS, 7-0, 9-1, 7-2, 5-3 WAVE 07
L98D1:  .byte YTRAP                 ;TMAP TRAP  21 TOWERS, 11-0, 8-1, 7-2, 2-3 WAVE 08
L98D2:  .byte YSYMTRC               ;TMAP SYMTRC  21 TOWERS, 9-0, 5-1, 7-2, 7-3 WAVE 09
L98D3:  .byte YVALLEY               ;TMAP VALLEY  27 TOWERS, 10-0, 7-1, 5-2, 6-3 WAVE 10
L98D4:  .byte YTWRCTY               ;TMAP TWRCTY  28 TOWERS, 8-0, 8-1, 7-2, 5-3 WAVE 11
L98D5:  .byte Y3SQUARE              ;TMAP 3SQUARE  20 TOWERS, 8-0, 12-1, 6-2, 6-3 WAVE 12
L98D6:  .byte Y3CLUSTR              ;TMAP 3CLUSTR  20 TOWERS, 8-0, 6-1, 9-2, 9-3 WAVE 13
L98D7:  .byte Y3TURNON              ;TMAP 3TURNON  24 TOWERS, 12-0, 11-1, 9-2, 0-3 WAVE 14
L98D8:  .byte Y3WEDGE               ;TMAP 3WEDGE  24 TOWERS, 8-0, 8-1, 8-2, 8-3 WAVE 15
L98D9:  .byte Y3DIFF                ;TMAP 3DIFF  24 TOWERS, 9-0, 9-1, 8-2, 6-3 WAVE 16
L98DA:  .byte Y3TRAP                ;TMAP 3TRAP  25 TOWERS, 11-0, 8-1, 7-2, 6-3 WAVE 17
L98DB:  .byte Y3SYMTRC              ;TMAP 3SYMTRC  25 TOWERS, 11-0, 7-1, 7-2, 7-3 WAVE 18
L98DC:  .byte Y3VALLEY              ;TMAP 3VALLEY  31 TOWERS, 10-0, 7-1, 7-2, 8-3 WAVE 19
L98DD:  .byte Y3TWRCTY              ;TMAP 3TWRCTY  32 TOWERS, 8-0, 8-1, 9-2, 7-3 WAVE 20

T3DIFF:          ;24 TOWERS, 9-0, 9-1, 8-2, 6-3 WAVE 16
TDIFF:           ;20 TOWERS, 7-0, 9-1, 7-2, 5-3 WAVE 07
TTWRSZ:
;TOP VIEW, X +RIGHT, -LEFT
;Y FORWARD
L98DE:  .word $1000, $B000          ;BUNKER -5000,1000 1  A
L98E2:  .byte $03, $01, $00
L98E5:  .word $1000, $E000          ;BUNKER -2000,1000 1
L98E9:  .byte $03, $01, $01
L98EC:  .word $1000, $2000          ;BUNKER 2000,1000 1
L98F0:  .byte $03, $01, $02
L98F3:  .word $1000, $5000          ;BUNKER 5000,1000 1
L98F7:  .byte $03, $01, $03
L98FA:  .word $1800, $A000          ;TOWER -6000,1800 3  B
L98FE:  .byte $01, $03, $04
L9901:  .word $1800, $6000          ;TOWER 6000,1800 2
L9905:  .byte $01, $02, $05
L9908:  .word $2000, $B800          ;TOWER -4800,2000 2  C
L990C:  .byte $01, $02, $06
L990F:  .word $2000, $4800          ;TOWER 4800,2000 2
L9913:  .byte $01, $02, $07
L9916:  .word $3000, $C000          ;BUNKER -4000,3000 2  D
L991A:  .byte $03, $02, $08
L991D:  .word $3000, $0000          ;TOWER 0,3000 0
L9921:  .byte $01, $00, $09
L9924:  .word $3000, $4000          ;BUNKER 4000,3000 2
L9928:  .byte $03, $02, $0A
L992B:  .word $3800, $9800          ;TOWER -6800,3800 3  E
L992F:  .byte $01, $03, $0B
L9932:  .word $3800, $F000          ;TOWER -1000,3800 0
L9936:  .byte $01, $00, $0C
L9939:  .word $3800, $1000          ;TOWER 1000,3800 0
L993D:  .byte $01, $00, $0D
L9940:  .word $3800, $6800          ;TOWER 6800,3800 3
L9944:  .byte $01, $03, $0E
L9947:  .word $4000, $9000          ;BUNKER -7000,4000 3  F
L994B:  .byte $03, $03, $0F
L994E:  .word $4000, $7000          ;BUNKER 7000,4000 3
L9952:  .byte $03, $03, $10
L9955:  .word $5000, $9000          ;TOWER -7000,5000 1  G
L9959:  .byte $01, $01, $11
L995C:  .word $5000, $0000          ;BISHOP 0,5000 1
L9960:  .byte $02, $01, $12
L9963:  .word $5000, $7000          ;TOWER 7000,5000 1
L9967:  .byte $01, $01, $13
L996A:  .word $5400, $E400          ;TOWER -1C00,5400 1  H
L996E:  .byte $01, $01, $14
L9971:  .word $5400, $1C00          ;TOWER 1C00,5400 1
L9975:  .byte $01, $01, $15
L9978:  .word $5800, $C000          ;TOWER -4000,5800 0  I
L997C:  .byte $01, $00, $16
L997F:  .word $5800, $4000          ;TOWER 4000,5800 0
L9983:  .byte $01, $00, $17
L9986:  .word $6800, $D800          ;TOWER -2800,6800 0  J
L998A:  .byte $01, $00, $18
L998D:  .word $6800, $2800          ;TOWER 2800,6800 0
L9991:  .byte $01, $00, $19
L9994:  .word $7000, $F000          ;BISHOP -1000,7000 2  K
L9998:  .byte $02, $02, $1A
L999B:  .word $7000, $1000          ;BISHOP 1000,7000 2
L999F:  .byte $02, $02, $1B

ZDIFF:
L99A2:  .word $8000, $9000          ;TOWER -7000,8000 3  L
L99A6:  .byte $01, $03, $1C
L99A9:  .word $8000, $D800          ;TOWER -2800,8000 0
L99AD:  .byte $01, $00, $1D
L99B0:  .word $8000, $2800          ;TOWER 2800,8000 0
L99B4:  .byte $01, $00, $1E
L99B7:  .word $8000, $7000          ;TOWER 7000,8000 2
L99BB:  .byte $01, $02, $1F

Z3DIFF:
T3CLUSTR:        ;20 TOWERS, 8-0, 6-1, 9-2, 9-3 WAVE 13
TCLUSTR:         ;16 TOWERS, 8-0, 6-1, 7-2, 7-3 WAVE 04
;CLUSTER'S LAST STAND
;A
L99BE:  .word $3000, $8800          ;TOWER -7800,3000 2
L99C2:  .byte $01, $02, $00
L99C5:  .word $3000, $9800          ;BUNKER -6800,3000 2
L99C9:  .byte $03, $02, $01
L99CC:  .word $3000, $A800          ;BUNKER -5800,3000 2
L99D0:  .byte $03, $02, $02
L99D3:  .word $3000, $B800          ;TOWER -4800,3000 2
L99D7:  .byte $01, $02, $03
L99DA:  .word $3000, $E800          ;TOWER -1800,3000 0
L99DE:  .byte $01, $00, $04
L99E1:  .word $3000, $F800          ;BUNKER -0800,3000 0
L99E5:  .byte $03, $00, $05
L99E8:  .word $3000, $0800          ;BUNKER 0800,3000 0
L99EC:  .byte $03, $00, $06
L99EF:  .word $3000, $1800          ;TOWER 1800,3000 0
L99F3:  .byte $01, $00, $07
L99F6:  .word $3000, $4800          ;TOWER 4800,3000 3
L99FA:  .byte $01, $03, $08
L99FD:  .word $3000, $5800          ;BUNKER 5800,3000 3
L9A01:  .byte $03, $03, $09
L9A04:  .word $3000, $6800          ;BUNKER 6800,3000 3
L9A08:  .byte $03, $03, $0A
L9A0B:  .word $3000, $7800          ;TOWER 7800,3000 3
L9A0F:  .byte $01, $03, $0B
;B
L9A12:  .word $4000, $9000          ;TOWER -7000,4000 2
L9A16:  .byte $01, $02, $0C
L9A19:  .word $4000, $A000          ;BUNKER -6000,4000 2
L9A1D:  .byte $03, $02, $0D
L9A20:  .word $4000, $B000          ;TOWER -5000,4000 2
L9A24:  .byte $01, $02, $0E
L9A27:  .word $4000, $F000          ;TOWER -1000,4000 0
L9A2B:  .byte $01, $00, $0F
L9A2E:  .word $4000, $1000          ;TOWER 1000,4000 0
L9A32:  .byte $01, $00, $10
L9A35:  .word $4000, $5000          ;TOWER 5000,4000 3
L9A39:  .byte $01, $03, $11
L9A3C:  .word $4000, $6000          ;BUNKER 6000,4000 3
L9A40:  .byte $03, $03, $12
L9A43:  .word $4000, $7000          ;TOWER 7000,4000 3
L9A47:  .byte $01, $03, $13
;C
L9A4A:  .word $5400, $CC00          ;BUNKER -3400,5400 1
L9A4E:  .byte $03, $01, $14
L9A51:  .word $5400, $3400          ;BUNKER 3400,5400 1
L9A55:  .byte $03, $01, $15
;D
L9A58:  .word $6000, $A000          ;TOWER -6000,6000 1
L9A5C:  .byte $01, $01, $16
L9A5F:  .word $6000, $E000          ;BUNKER -2000,6000 0
L9A63:  .byte $03, $00, $17
L9A66:  .word $6000, $2000          ;BUNKER 2000,6000 0
L9A6A:  .byte $03, $00, $18
L9A6D:  .word $6000, $6000          ;TOWER 6000,6000 1
L9A71:  .byte $01, $01, $19
;E
L9A74:  .word $7400, $E000          ;TOWER -2000,7400 1
L9A78:  .byte $01, $01, $1A
L9A7B:  .word $7400, $2000          ;TOWER 2000,7400 1
L9A7F:  .byte $01, $01, $1B

ZCLUSTR:
L9A82:  .word $8000, $9800          ;TOWER -6800,8000 2  F
L9A86:  .byte $01, $02, $1C
L9A89:  .word $8000, $B800          ;TOWER -4800,8000 2
L9A8D:  .byte $01, $02, $1D
L9A90:  .word $8000, $4800          ;TOWER 4800,8000 3
L9A94:  .byte $01, $03, $1E
L9A97:  .word $8000, $6800          ;TOWER 6800,8000 3
L9A9B:  .byte $01, $03, $1F

Z3CLUSTR:
TBUNK:           ;0 TOWERS, 7-0, 7-1, 7-2, 7-3 WAVE 2 ONLY
;BUNKER WAVE
L9A9E:  .word $0400, $3000          ;BUNKER 3000,0400 1  A
L9AA2:  .byte $03, $01, $00
L9AA5:  .word $0C00, $2000          ;BUNKER 2000,0C00 0  B
L9AA9:  .byte $03, $00, $01
L9AAC:  .word $1000, $9800          ;BUNKER -6800,1000 1  C
L9AB0:  .byte $03, $01, $02
L9AB3:  .word $1400, $4800          ;BUNKER 4800,1400 1  D
L9AB7:  .byte $03, $01, $03
L9ABA:  .word $1800, $B000          ;BUNKER -5000,1800 3  E
L9ABE:  .byte $03, $03, $04
L9AC1:  .word $1800, $D000          ;BUNKER -3000,1800 0
L9AC5:  .byte $03, $00, $05
L9AC8:  .word $2000, $C000          ;BUNKER -4000,2000 1  F
L9ACC:  .byte $03, $01, $06
L9ACF:  .word $2400, $3800          ;BUNKER 3800,2400 2  G
L9AD3:  .byte $03, $02, $07
L9AD6:  .word $2400, $7000          ;BUNKER 7000,2400 2
L9ADA:  .byte $03, $02, $08
L9ADD:  .word $2800, $0000          ;BUNKER 0000,2800 0  H
L9AE1:  .byte $03, $00, $09
L9AE4:  .word $3000, $8800          ;BUNKER -7800,3000 1  I
L9AE8:  .byte $03, $01, $0A
L9AEB:  .word $4000, $8000          ;BUNKER 8000,4000 1  J
L9AEF:  .byte $03, $01, $0B
L9AF2:  .word $4400, $6000          ;BUNKER 6000,4400 2  K
L9AF6:  .byte $03, $02, $0C
L9AF9:  .word $4800, $9000          ;BUNKER -7000,4800 1  L
L9AFD:  .byte $03, $01, $0D
L9B00:  .word $4800, $A800          ;BUNKER -5800,4800 3
L9B04:  .byte $03, $03, $0E
L9B07:  .word $4C00, $5000          ;BUNKER 5000,4C00 2  M
L9B0B:  .byte $03, $02, $0F
L9B0E:  .word $5000, $E000          ;BUNKER -2000,5000 3  N
L9B12:  .byte $03, $03, $10
L9B15:  .word $5000, $0000          ;BUNKER 0000,5000 2
L9B19:  .byte $03, $02, $11
L9B1C:  .word $5000, $2800          ;BUNKER 2800,5000 0
L9B20:  .byte $03, $00, $12
L9B23:  .word $6800, $B800          ;BUNKER -4800,6800 3  O
L9B27:  .byte $03, $03, $13
L9B2A:  .word $6800, $D800          ;BUNKER -2800,6800 0
L9B2E:  .byte $03, $00, $14
L9B31:  .word $7000, $A000          ;BUNKER -6000,7000 3  P
L9B35:  .byte $03, $03, $15
L9B38:  .word $7000, $E800          ;BUNKER -1800,7000 0
L9B3C:  .byte $03, $00, $16
L9B3F:  .word $7000, $1800          ;BUNKER 1800,7000 3
L9B43:  .byte $03, $03, $17
L9B46:  .word $7000, $5800          ;BUNKER 5800,7000 3
L9B4A:  .byte $03, $03, $18
L9B4D:  .word $7800, $F800          ;BUNKER -0800,7800 0  Q
L9B51:  .byte $03, $00, $19
L9B54:  .word $7800, $4000          ;BUNKER 4000,7800 2
L9B58:  .byte $03, $02, $1A
L9B5B:  .word $7800, $6800          ;BUNKER 6800,7800 2
L9B5F:  .byte $03, $02, $1B

ZBUNK:
T3TWRCTY:        ;32 TOWERS, 8-0, 8-1, 9-2, 7-3 WAVE 20
TTWRCTY:         ;28 TOWERS, 8-0, 8-1, 7-2, 5-3 WAVE 11
;TOWER CITY
;A
L9B62:  .word $0000, $9000          ;TOWER -7000,0000 0
L9B66:  .byte $01, $00, $00
L9B69:  .word $0000, $B000          ;TOWER -5000,0000 0
L9B6D:  .byte $01, $00, $01
L9B70:  .word $0000, $D000          ;TOWER -3000,0000 0
L9B74:  .byte $01, $00, $02
L9B77:  .word $0000, $F000          ;TOWER -1000,0000 0
L9B7B:  .byte $01, $00, $03
L9B7E:  .word $0000, $1000          ;TOWER 1000,0000 0
L9B82:  .byte $01, $00, $04
L9B85:  .word $0000, $3000          ;TOWER 3000,0000 0
L9B89:  .byte $01, $00, $05
L9B8C:  .word $0000, $5000          ;TOWER 5000,0000 0
L9B90:  .byte $01, $00, $06
L9B93:  .word $0000, $7000          ;TOWER 7000,0000 0
L9B97:  .byte $01, $00, $07
;B
L9B9A:  .word $1000, $C800          ;TOWER -3800,1000 2
L9B9E:  .byte $01, $02, $08
;C
L9BA1:  .word $2800, $C000          ;TOWER -4000,2800 2
L9BA5:  .byte $01, $02, $09
;D
L9BA8:  .word $3000, $8800          ;TOWER -7800,3000 2
L9BAC:  .byte $01, $02, $0A
L9BAF:  .word $3000, $A800          ;TOWER -5800,3000 2
L9BB3:  .byte $01, $02, $0B
L9BB6:  .word $3000, $4800          ;TOWER 4800,3000 2
L9BBA:  .byte $01, $02, $0C
L9BBD:  .word $3000, $6800          ;TOWER 6800,3000 2
L9BC1:  .byte $01, $02, $0D
;E
L9BC4:  .word $4000, $A000          ;TOWER -6000,4000 3
L9BC8:  .byte $01, $03, $0E
L9BCB:  .word $4000, $4000          ;TOWER 4000,4000 2
L9BCF:  .byte $01, $02, $0F
L9BD2:  .word $4000, $6000          ;TOWER 6000,4000 3
L9BD6:  .byte $01, $03, $10
L9BD9:  .word $4000, $8000          ;TOWER 8000,4000 3
L9BDD:  .byte $01, $03, $11
;F
L9BE0:  .word $6000, $0000          ;TOWER 0000,6000 3
L9BE4:  .byte $01, $03, $12
;G
L9BE7:  .word $6800, $8400          ;TOWER -7C00,6800 3
L9BEB:  .byte $01, $03, $13
;H
L9BEE:  .word $7000, $9800          ;TOWER -6800,7000 1
L9BF2:  .byte $01, $01, $14
L9BF5:  .word $7000, $B800          ;TOWER -4800,7000 1
L9BF9:  .byte $01, $01, $15
L9BFC:  .word $7000, $D800          ;TOWER -2800,7000 1
L9C00:  .byte $01, $01, $16
L9C03:  .word $7000, $F800          ;TOWER -0800,7000 1
L9C07:  .byte $01, $01, $17
L9C0A:  .word $7000, $1800          ;TOWER 1800,7000 1
L9C0E:  .byte $01, $01, $18
L9C11:  .word $7000, $3800          ;TOWER 3800,7000 1
L9C15:  .byte $01, $01, $19
L9C18:  .word $7000, $5800          ;TOWER 5800,7000 1
L9C1C:  .byte $01, $01, $1A
L9C1F:  .word $7000, $7800          ;TOWER 7800,7000 1
L9C23:  .byte $01, $01, $1B

ZTWRCTY:
L9C26:  .word $3000, $E800          ;TOWER -1800,3000 2  D
L9C2A:  .byte $01, $02, $1C
L9C2D:  .word $3000, $0800          ;TOWER 800,3000 2
L9C31:  .byte $01, $02, $1D
L9C34:  .word $4000, $F800          ;TOWER -800,4000 3  E
L9C38:  .byte $01, $03, $1E
L9C3B:  .word $4000, $1800          ;TOWER 1800,4000 3
L9C3F:  .byte $01, $03, $1F

Z3TWRCTY:
T3SYMTRC:        ;25 TOWERS, 11-0, 7-1, 7-2, 7-3 WAVE 18
TSYMTRC:         ;21 TOWERS, 9-0, 5-1, 7-2, 7-3 WAVE 09
;SYMMETRIC
;A
L9C42:  .word $0800, $A800          ;BUNKER -5800,0800 2
L9C46:  .byte $03, $02, $00
L9C49:  .word $0800, $5800          ;BUNKER 5800,0800 2
L9C4D:  .byte $03, $02, $01
;B
L9C50:  .word $0C00, $E800          ;TOWER -1800,0C00 0
L9C54:  .byte $01, $00, $02
L9C57:  .word $0C00, $1800          ;TOWER 1800,0C00 0
L9C5B:  .byte $01, $00, $03
;C
L9C5E:  .word $1400, $C400          ;TOWER -3C00,1400 0
L9C62:  .byte $01, $00, $04
L9C65:  .word $1400, $3C00          ;TOWER 3C00,1400 0
L9C69:  .byte $01, $00, $05
;D
L9C6C:  .word $2800, $A800          ;TOWER -5800,2800 2
L9C70:  .byte $01, $02, $06
L9C73:  .word $2800, $5800          ;TOWER 5800,2800 2
L9C77:  .byte $01, $02, $07
;E
L9C7A:  .word $3000, $0000          ;BUNKER 0000,3000 0
L9C7E:  .byte $03, $00, $08
;F
L9C81:  .word $3800, $E000          ;TOWER -2000,3800 0
L9C85:  .byte $01, $00, $09
L9C88:  .word $3800, $2000          ;TOWER 2000,3800 0
L9C8C:  .byte $01, $00, $0A
;G
L9C8F:  .word $4800, $C000          ;TOWER -4000,4800 3
L9C93:  .byte $01, $03, $0B
L9C96:  .word $4800, $4000          ;TOWER 4000,4800 3
L9C9A:  .byte $01, $03, $0C
;H
L9C9D:  .word $5000, $9000          ;TOWER -7000,5000 3
L9CA1:  .byte $01, $03, $0D
L9CA4:  .word $5000, $D800          ;BUNKER -2800,5000 1
L9CA8:  .byte $03, $01, $0E
L9CAB:  .word $5000, $2800          ;BUNKER 2800,5000 1
L9CAF:  .byte $03, $01, $0F
L9CB2:  .word $5000, $7000          ;TOWER 7000,5000 2
L9CB6:  .byte $01, $02, $10
;I
L9CB9:  .word $5800, $F000          ;BUNKER -1000,5800 2
L9CBD:  .byte $03, $02, $11
L9CC0:  .word $5800, $1000          ;BUNKER 1000,5800 2
L9CC4:  .byte $03, $02, $12
;J
L9CC7:  .word $6800, $B800          ;TOWER -4800,6800 0
L9CCB:  .byte $01, $00, $13
L9CCE:  .word $6800, $4800          ;TOWER 4800,6800 0
L9CD2:  .byte $01, $00, $14
;K
L9CD5:  .word $7000, $8800          ;TOWER -7800,7000 3
L9CD9:  .byte $01, $03, $15
L9CDC:  .word $7000, $A000          ;TOWER -6000,7000 1
L9CE0:  .byte $01, $01, $16
L9CE3:  .word $7000, $D000          ;TOWER -3000,7000 3
L9CE7:  .byte $01, $03, $17
L9CEA:  .word $7000, $0000          ;TOWER 0000,7000 1
L9CEE:  .byte $01, $01, $18
L9CF1:  .word $7000, $3000          ;TOWER 3000,7000 3
L9CF5:  .byte $01, $03, $19
L9CF8:  .word $7000, $6000          ;TOWER 6000,7000 1
L9CFC:  .byte $01, $01, $1A
L9CFF:  .word $7000, $7800          ;TOWER 7800,7000 3
L9D03:  .byte $01, $03, $1B

ZSYMTRC:
L9D06:  .word $8000, $B000          ;TOWER -5000,8000 0  L
L9D0A:  .byte $01, $00, $1C
L9D0D:  .word $8000, $E800          ;TOWER -1800,8000 1
L9D11:  .byte $01, $01, $1D
L9D14:  .word $8000, $1800          ;TOWER 1800,8000 1
L9D18:  .byte $01, $01, $1E
L9D1B:  .word $8000, $5000          ;TOWER 5000,8000 0
L9D1F:  .byte $01, $00, $1F

Z3SYMTRC:
T3TRAP:          ;25 TOWERS, 11-0, 8-1, 7-2, 6-3 WAVE 17
TTRAP:           ;21 TOWERS, 11-0, 8-1, 7-2, 2-3 WAVE 08
;TRAP
;A
L9D22:  .word $6000, $9800          ;TOWER -6800,6000 2
L9D26:  .byte $01, $02, $00
L9D29:  .word $1000, $6800          ;TOWER 6800,1000 2
L9D2D:  .byte $01, $02, $01
;B
L9D30:  .word $2000, $D000          ;BUNKER -3000,2000 1
L9D34:  .byte $03, $01, $02
;C
L9D37:  .word $3000, $9000          ;BUNKER -7000,3000 2
L9D3B:  .byte $03, $02, $03
L9D3E:  .word $3000, $E000          ;TOWER -2000,3000 0
L9D42:  .byte $01, $00, $04
L9D45:  .word $3000, $2000          ;TOWER 2000,3000 0
L9D49:  .byte $01, $00, $05
L9D4C:  .word $3000, $7000          ;BUNKER 7000,3000 2
L9D50:  .byte $03, $02, $06
;D
L9D53:  .word $3800, $B800          ;TOWER -4800,3800 1
L9D57:  .byte $01, $01, $07
L9D5A:  .word $3800, $4800          ;TOWER 4800,3800 1
L9D5E:  .byte $01, $01, $08
;E
L9D61:  .word $4000, $9000          ;TOWER -7000,4000 3
L9D65:  .byte $01, $03, $09
L9D68:  .word $4000, $E800          ;BUNKER -1800,4000 0
L9D6C:  .byte $03, $00, $0A
L9D6F:  .word $4000, $1800          ;BUNKER 1800,4000 0
L9D73:  .byte $03, $00, $0B
L9D76:  .word $4000, $4800          ;TOWER 4800,4000 1
L9D7A:  .byte $01, $01, $0C
;F
L9D7D:  .word $5000, $E000          ;BUNKER -2000,5000 0
L9D81:  .byte $03, $00, $0D
L9D84:  .word $5000, $F000          ;TOWER -1000,5000 0
L9D88:  .byte $01, $00, $0E
L9D8B:  .word $5000, $1000          ;TOWER 1000,5000 0
L9D8F:  .byte $01, $00, $0F
L9D92:  .word $5000, $2000          ;BUNKER 2000,5000 0
L9D96:  .byte $03, $00, $10
;G
L9D99:  .word $6000, $8800          ;TOWER -7800,6000 3
L9D9D:  .byte $01, $03, $11
L9DA0:  .word $6000, $A000          ;TOWER -6000,6000 2
L9DA4:  .byte $01, $02, $12
L9DA7:  .word $6000, $C000          ;TOWER -4000,6000 1
L9DAB:  .byte $01, $01, $13
L9DAE:  .word $6000, $D000          ;TOWER -3000,6000 1
L9DB2:  .byte $01, $01, $14
L9DB5:  .word $6000, $F800          ;TOWER -0800,6000 0
L9DB9:  .byte $01, $00, $15
L9DBC:  .word $6000, $0800          ;TOWER 0800,6000 0
L9DC0:  .byte $01, $00, $16
L9DC3:  .word $6000, $3000          ;TOWER 3000,6000 1
L9DC7:  .byte $01, $01, $17
L9DCA:  .word $6000, $4000          ;TOWER 4000,6000 1
L9DCE:  .byte $01, $01, $18
L9DD1:  .word $6000, $6000          ;TOWER 6000,6000 2
L9DD5:  .byte $01, $02, $19
L9DD8:  .word $6000, $8000          ;TOWER 8000,6000 2
L9DDC:  .byte $01, $02, $1A
;H
L9DDF:  .word $7000, $0000          ;TOWER 0000,7000 0
L9DE3:  .byte $01, $00, $1B

ZTRAP:
L9DE6:  .word $8000, $A800          ;TOWER -5800,8000 3  I
L9DEA:  .byte $01, $03, $1C
L9DED:  .word $8000, $E000          ;TOWER -2000,8000 3
L9DF1:  .byte $01, $03, $1D
L9DF4:  .word $8000, $2000          ;TOWER 2000,8000 3
L9DF8:  .byte $01, $03, $1E
L9DFB:  .word $8000, $5800          ;TOWER 5800,8000 3
L9DFF:  .byte $01, $03, $1F

Z3TRAP:
T3WEDGE:         ;24 TOWERS, 8-0, 8-1, 8-2, 8-3 WAVE 15
TWEDGE:          ;20 TOWERS, 8-0, 8-1, 4-2, 8-3 WAVE 06
;WEDGE
;A
L9E02:  .word $0000, $B800          ;TOWER -4800,0000 2
L9E06:  .byte $01, $02, $00
L9E09:  .word $0000, $4800          ;TOWER 4800,0000 2
L9E0D:  .byte $01, $02, $01
;B
L9E10:  .word $1000, $A000          ;TOWER -6000,1000 3
L9E14:  .byte $01, $03, $02
L9E17:  .word $1000, $E000          ;TOWER -2000,1000 1
L9E1B:  .byte $01, $01, $03
L9E1E:  .word $1000, $F800          ;TOWER -0800,1000 0
L9E22:  .byte $01, $00, $04
L9E25:  .word $1000, $0800          ;TOWER 0800,1000 0
L9E29:  .byte $01, $00, $05
L9E2C:  .word $1000, $2000          ;TOWER 2000,1000 1
L9E30:  .byte $01, $01, $06
;C
L9E33:  .word $2000, $C800          ;TOWER -3800,2000 1
L9E37:  .byte $01, $01, $07
L9E3A:  .word $2000, $3800          ;TOWER 3800,2000 1
L9E3E:  .byte $01, $01, $08
;D
L9E41:  .word $2C00, $E400          ;TOWER -1C00,2C00 0
L9E45:  .byte $01, $00, $09
L9E48:  .word $2C00, $1C00          ;TOWER 1C00,2C00 0
L9E4C:  .byte $01, $00, $0A
;E
L9E4F:  .word $3000, $9000          ;TOWER -7000,3000 3
L9E53:  .byte $01, $03, $0B
;F
L9E56:  .word $4000, $0000          ;BUNKER 0000,4000 1
L9E5A:  .byte $03, $01, $0C
;G
L9E5D:  .word $5000, $0000          ;TOWER 0000,5000 1
L9E61:  .byte $01, $01, $0D
L9E64:  .word $5000, $8000          ;BUNKER 8000,5000 3
L9E68:  .byte $03, $03, $0E
;H
L9E6B:  .word $6000, $E800          ;BUNKER -1800,6000 1
L9E6F:  .byte $03, $01, $0F
L9E72:  .word $6000, $1800          ;BUNKER 1800,6000 1
L9E76:  .byte $03, $01, $10
L9E79:  .word $6000, $8000          ;TOWER 8000,6000 3
L9E7D:  .byte $01, $03, $11
;I
L9E80:  .word $7000, $8800          ;BUNKER -7800,7000 2
L9E84:  .byte $03, $02, $12
L9E87:  .word $7000, $A000          ;TOWER -6000,7000 0
L9E8B:  .byte $01, $00, $13
L9E8E:  .word $7000, $B000          ;TOWER -5000,7000 0
L9E92:  .byte $01, $00, $14
L9E95:  .word $7000, $F000          ;TOWER -1000,7000 3
L9E99:  .byte $01, $03, $15
L9E9C:  .word $7000, $1000          ;TOWER 1000,7000 3
L9EA0:  .byte $01, $03, $16
L9EA3:  .word $7000, $5000          ;TOWER 5000,7000 0
L9EA7:  .byte $01, $00, $17
L9EAA:  .word $7000, $6000          ;TOWER 6000,7000 0
L9EAE:  .byte $01, $00, $18
L9EB1:  .word $7000, $7800          ;BUNKER 7800,7000 2
L9EB5:  .byte $03, $02, $19
;J
L9EB8:  .word $7800, $E000          ;BUNKER -2000,7800 3
L9EBC:  .byte $03, $03, $1A
L9EBF:  .word $7800, $2000          ;BUNKER 2000,7800 3
L9EC3:  .byte $03, $03, $1B

ZWEDGE:
L9EC6:  .word $4000, $B000          ;TOWER -5000,4000 2  F
L9ECA:  .byte $01, $02, $1C
L9ECD:  .word $4000, $C000          ;TOWER -4000,4000 2
L9ED1:  .byte $01, $02, $1D
L9ED4:  .word $4000, $3000          ;TOWER 3000,4000 2
L9ED8:  .byte $01, $02, $1E
L9EDB:  .word $4000, $4000          ;TOWER 4000,4000 2
L9EDF:  .byte $01, $02, $1F

Z3WEDGE:
T3SQUARE:        ;20 TOWERS, 8-0, 12-1, 6-2, 6-3 WAVE 12
TSQUARE:         ;16 TOWERS, 8-0, 12-1, 6-2, 2-3 WAVE 03
;SQUARE
;A
L9EE2:  .word $2000, $8000          ;BUNKER -8000,2000 2
L9EE6:  .byte $03, $02, $00
L9EE9:  .word $2000, $A000          ;BUNKER -6000,2000 1
L9EED:  .byte $03, $01, $01
L9EF0:  .word $2000, $B000          ;BUNKER -5000,2000 1
L9EF4:  .byte $03, $01, $02
L9EF7:  .word $2000, $5000          ;BUNKER 5000,2000 1
L9EFB:  .byte $03, $01, $03
L9EFE:  .word $2000, $6000          ;BUNKER 6000,2000 1
L9F02:  .byte $03, $01, $04
;B
L9F05:  .word $3000, $8000          ;TOWER -8000,3000 2
L9F09:  .byte $01, $02, $05
L9F0C:  .word $3000, $A000          ;TOWER -6000,3000 1
L9F10:  .byte $01, $01, $06
L9F13:  .word $3000, $B000          ;TOWER -5000,3000 1
L9F17:  .byte $01, $01, $07
L9F1A:  .word $3000, $D000          ;BUNKER -3000,3000 1
L9F1E:  .byte $03, $01, $08
L9F21:  .word $3000, $E000          ;BUNKER -2000,3000 0
L9F25:  .byte $03, $00, $09
L9F28:  .word $3000, $0000          ;BUNKER 0000,3000 0
L9F2C:  .byte $03, $00, $0A
L9F2F:  .word $3000, $2000          ;BUNKER 2000,3000 0
L9F33:  .byte $03, $00, $0B
L9F36:  .word $3000, $3000          ;BUNKER 3000,3000 1
L9F3A:  .byte $03, $01, $0C
L9F3D:  .word $3000, $5000          ;TOWER 5000,3000 1
L9F41:  .byte $01, $01, $0D
L9F44:  .word $3000, $6000          ;TOWER 6000,3000 1
L9F48:  .byte $01, $01, $0E
;C
L9F4B:  .word $4000, $D000          ;TOWER -3000,4000 2
L9F4F:  .byte $01, $02, $0F
L9F52:  .word $4000, $E000          ;TOWER -2000,4000 0
L9F56:  .byte $01, $00, $10
L9F59:  .word $4000, $0000          ;TOWER 0000,4000 0
L9F5D:  .byte $01, $00, $11
L9F60:  .word $4000, $2000          ;TOWER 2000,4000 0
L9F64:  .byte $01, $00, $12
L9F67:  .word $4000, $3000          ;TOWER 3000,4000 2
L9F6B:  .byte $01, $02, $13
;D
L9F6E:  .word $4800, $5800          ;BUNKER 5800,4800 2
L9F72:  .byte $03, $02, $14
;E
L9F75:  .word $5400, $7000          ;BUNKER 7000,5400 2
L9F79:  .byte $03, $02, $15
;F
L9F7C:  .word $6000, $9000          ;TOWER -7000,6000 3
L9F80:  .byte $01, $03, $16
L9F83:  .word $6000, $7000          ;TOWER 7000,6000 3
L9F87:  .byte $01, $03, $17
;G
L9F8A:  .word $6800, $F000          ;TOWER -1000,6800 0
L9F8E:  .byte $01, $00, $18
L9F91:  .word $6800, $1000          ;TOWER 1000,6800 0
L9F95:  .byte $01, $00, $19
;H
L9F98:  .word $7000, $C000          ;TOWER -4000,7000 1
L9F9C:  .byte $01, $01, $1A
L9F9F:  .word $7000, $4000          ;TOWER 4000,7000 1
L9FA3:  .byte $01, $01, $1B

ZSQUARE:
L9FA6:  .word $8000, $A000          ;TOWER -6000,8000 3  I
L9FAA:  .byte $01, $03, $1C
L9FAD:  .word $8000, $E000          ;TOWER -2000,8000 3
L9FB1:  .byte $01, $03, $1D
L9FB4:  .word $8000, $2000          ;TOWER 2000,8000 3
L9FB8:  .byte $01, $03, $1E
L9FBB:  .word $8000, $6000          ;TOWER 6000,8000 3
L9FBF:  .byte $01, $03, $1F

Z3SQUARE:
T3VALLEY:        ;31 TOWERS, 10-0, 7-1, 7-2, 8-3 WAVE 19
TVALLEY:         ;27 TOWERS, 10-0, 7-1, 5-2, 6-3 WAVE 10
;VALLEY
;A
L9FC2:  .word $0000, $0000          ;TOWER 0000,0000 1
L9FC6:  .byte $01, $01, $00
;B
L9FC9:  .word $1800, $8000          ;TOWER -8000,1800 3
L9FCD:  .byte $01, $03, $01
;C
L9FD0:  .word $2000, $D800          ;TOWER -2800,2000 1
L9FD4:  .byte $01, $01, $02
L9FD7:  .word $2000, $2800          ;TOWER 2800,2000 1
L9FDB:  .byte $01, $01, $03
;D
L9FDE:  .word $3000, $9000          ;TOWER -7000,3000 2
L9FE2:  .byte $01, $02, $04
L9FE5:  .word $3000, $6000          ;BUNKER 6000,3000 2
L9FE9:  .byte $03, $02, $05
L9FEC:  .word $3000, $7000          ;TOWER 7000,3000 2
L9FF0:  .byte $01, $02, $06
;E
L9FF3:  .word $3800, $B000          ;TOWER -5000,3800 3
L9FF7:  .byte $01, $03, $07
L9FFA:  .word $3800, $E000          ;TOWER -2000,3800 0
L9FFE:  .byte $01, $00, $08
LA001:  .word $3800, $2000          ;TOWER 2000,3800 0
LA005:  .byte $01, $00, $09
LA008:  .word $3800, $5000          ;TOWER 5000,3800 3
LA00C:  .byte $01, $03, $0A
;F
LA00F:  .word $4800, $E800          ;TOWER -1800,4800 0
LA013:  .byte $01, $00, $0B
LA016:  .word $4800, $1800          ;TOWER 1800,4800 0
LA01A:  .byte $01, $00, $0C
;G
LA01D:  .word $5000, $8800          ;TOWER -7800,5000 2
LA021:  .byte $01, $02, $0D
LA024:  .word $5000, $A000          ;TOWER -6000,5000 3
LA028:  .byte $01, $03, $0E
LA02B:  .word $5000, $C000          ;TOWER -4000,5000 1
LA02F:  .byte $01, $01, $0F
LA032:  .word $5000, $4000          ;TOWER 4000,5000 1
LA036:  .byte $01, $01, $10
LA039:  .word $5000, $6000          ;TOWER 6000,5000 3
LA03D:  .byte $01, $03, $11
LA040:  .word $5000, $7800          ;TOWER 7800,5000 2
LA044:  .byte $01, $02, $12
;H
LA047:  .word $5C00, $E400          ;TOWER -1C00,5C00 0
LA04B:  .byte $01, $00, $13
LA04E:  .word $5C00, $1C00          ;TOWER 1C00,5C00 0
LA052:  .byte $01, $00, $14
;I
LA055:  .word $6000, $F000          ;TOWER -1000,6000 0
LA059:  .byte $01, $00, $15
LA05C:  .word $6000, $1000          ;TOWER 1000,6000 0
LA060:  .byte $01, $00, $16
LA063:  .word $6000, $7C00          ;TOWER 7C00,6000 3
LA067:  .byte $01, $03, $17
;J
LA06A:  .word $7000, $C800          ;TOWER -3800,7000 1
LA06E:  .byte $01, $01, $18
LA071:  .word $7000, $F800          ;TOWER -0800,7000 0
LA075:  .byte $01, $00, $19
LA078:  .word $7000, $0800          ;TOWER 0800,7000 0
LA07C:  .byte $01, $00, $1A
LA07F:  .word $7000, $3800          ;TOWER 3800,7000 1
LA083:  .byte $01, $01, $1B

ZVALLEY:
LA086:  .word $0000, $A000          ;TOWER -6000,0000 3  A
LA08A:  .byte $01, $03, $1C
LA08D:  .word $0000, $C000          ;TOWER -4000,0000 2
LA091:  .byte $01, $02, $1D
LA094:  .word $0000, $4000          ;TOWER 4000,0000 2
LA098:  .byte $01, $02, $1E
LA09B:  .word $0000, $6000          ;TOWER 6000,0000 3
LA09F:  .byte $01, $03, $1F

Z3VALLEY:
T3TURNON:        ;24 TOWERS, 12-0, 11-1, 9-2, 0-3 WAVE 14
TTURNON:         ;20 TOWERS, 12-0, 11-1, 5-2, 0-3 WAVE 05
;QUICK TURNON
;A
LA0A2:  .word $1000, $E000          ;TOWER -2000,1000 1
LA0A6:  .byte $01, $01, $00
LA0A9:  .word $1000, $2000          ;TOWER 2000,1000 1
LA0AD:  .byte $01, $01, $01
;B
LA0B0:  .word $2000, $C000          ;BUNKER -4000,2000 1
LA0B4:  .byte $03, $01, $02
LA0B7:  .word $2000, $4000          ;BUNKER 4000,2000 1
LA0BB:  .byte $03, $01, $03
;C
LA0BE:  .word $2800, $E000          ;TOWER -2000,2800 0
LA0C2:  .byte $01, $00, $04
LA0C5:  .word $2800, $2000          ;TOWER 2000,2800 0
LA0C9:  .byte $01, $00, $05
;D
LA0CC:  .word $3000, $9000          ;BUNKER -7000,3000 2
LA0D0:  .byte $03, $02, $06
LA0D3:  .word $3000, $A000          ;BUNKER -6000,3000 2
LA0D7:  .byte $03, $02, $07
LA0DA:  .word $3000, $6000          ;BUNKER 6000,3000 2
LA0DE:  .byte $03, $02, $08
;E
LA0E1:  .word $3800, $B000          ;TOWER -5000,3800 1
LA0E5:  .byte $01, $01, $09
LA0E8:  .word $3800, $5000          ;TOWER 5000,3800 1
LA0EC:  .byte $01, $01, $0A
;F
LA0EF:  .word $4000, $D000          ;BUNKER -3000,4000 0
LA0F3:  .byte $03, $00, $0B
LA0F6:  .word $4000, $0000          ;BUNKER 0000,4000 0
LA0FA:  .byte $03, $00, $0C
LA0FD:  .word $4000, $3000          ;BUNKER 3000,4000 0
LA101:  .byte $03, $00, $0D
LA104:  .word $4000, $8000          ;TOWER 8000,4000 1
LA108:  .byte $01, $01, $0E
;G
LA10B:  .word $5000, $8800          ;TOWER -7800,5000 2
LA10F:  .byte $01, $02, $0F
LA112:  .word $5000, $0000          ;TOWER 0000,5000 0
LA116:  .byte $01, $00, $10
LA119:  .word $5000, $7800          ;TOWER 7800,5000 2
LA11D:  .byte $01, $02, $11
;H
LA120:  .word $6000, $C000          ;TOWER -4000,6000 0
LA124:  .byte $01, $00, $12
LA127:  .word $6000, $4000          ;TOWER 4000,6000 0
LA12B:  .byte $01, $00, $13
;I
LA12E:  .word $6800, $D000          ;TOWER -3000,6800 0
LA132:  .byte $01, $00, $14
LA135:  .word $6800, $3000          ;TOWER 3000,6800 0
LA139:  .byte $01, $00, $15
;J
LA13C:  .word $7000, $9000          ;TOWER -7000,7000 1
LA140:  .byte $01, $01, $16
LA143:  .word $7000, $A000          ;TOWER -6000,7000 1
LA147:  .byte $01, $01, $17
LA14A:  .word $7000, $F000          ;TOWER -1000,7000 0
LA14E:  .byte $01, $00, $18
LA151:  .word $7000, $1000          ;TOWER 1000,7000 0
LA155:  .byte $01, $00, $19
LA158:  .word $7000, $6000          ;TOWER 6000,7000 1
LA15C:  .byte $01, $01, $1A
LA15F:  .word $7000, $7000          ;TOWER 7000,7000 1
LA163:  .byte $01, $01, $1B

ZTURNON:
LA166:  .word $1000, $B800          ;TOWER -4800,1000 2  A
LA16A:  .byte $01, $02, $1C
LA16D:  .word $1000, $5800          ;TOWER 5800,1000 2
LA171:  .byte $01, $02, $1D
LA174:  .word $2000, $9800          ;TOWER -6800,2000 2  B
LA178:  .byte $01, $02, $1E
LA17B:  .word $2000, $7000          ;TOWER 7000,2000 2
LA17F:  .byte $01, $02, $1F

Z3TURNON:
TGDPTR:
LA182:  .word TBUNK                 ;TMAP BUNK  00 TOWERS, 7-0, 7-1, 7-2, 7-3 WAVE 02
LA184:  .word ZBUNK
LA186:  .word TSQUARE               ;TMAP SQUARE  16 TOWERS, 8-0, 12-1, 6-2, 2-3 WAVE 03
LA188:  .word ZSQUARE
LA18A:  .word TCLUSTR               ;TMAP CLUSTR  16 TOWERS, 8-0, 6-1, 7-2, 7-3 WAVE 04
LA18C:  .word ZCLUSTR
LA18E:  .word TTURNON               ;TMAP TURNON  20 TOWERS, 12-0, 11-1, 5-2, 0-3 WAVE 05
LA190:  .word ZTURNON
LA192:  .word TWEDGE                ;TMAP WEDGE  20 TOWERS, 8-0, 8-1, 4-2, 8-3 WAVE 06
LA194:  .word ZWEDGE
LA196:  .word TDIFF                 ;TMAP DIFF  20 TOWERS, 7-0, 9-1, 7-2, 5-3 WAVE 07
LA198:  .word ZDIFF
LA19A:  .word TTRAP                 ;TMAP TRAP  21 TOWERS, 11-0, 8-1, 7-2, 2-3 WAVE 08
LA19C:  .word ZTRAP
LA19E:  .word TSYMTRC               ;TMAP SYMTRC  21 TOWERS, 9-0, 5-1, 7-2, 7-3 WAVE 09
LA1A0:  .word ZSYMTRC
LA1A2:  .word TVALLEY               ;TMAP VALLEY  27 TOWERS, 10-0, 7-1, 5-2, 6-3 WAVE 10
LA1A4:  .word ZVALLEY
LA1A6:  .word TTWRCTY               ;TMAP TWRCTY  28 TOWERS, 8-0, 8-1, 7-2, 5-3 WAVE 11
LA1A8:  .word ZTWRCTY
LA1AA:  .word T3SQUARE              ;TMAP 3SQUARE  20 TOWERS, 8-0, 12-1, 6-2, 6-3 WAVE 12
LA1AC:  .word Z3SQUARE
LA1AE:  .word T3CLUSTR              ;TMAP 3CLUSTR  20 TOWERS, 8-0, 6-1, 9-2, 9-3 WAVE 13
LA1B0:  .word Z3CLUSTR
LA1B2:  .word T3TURNON              ;TMAP 3TURNON  24 TOWERS, 12-0, 11-1, 9-2, 0-3 WAVE 14
LA1B4:  .word Z3TURNON
LA1B6:  .word T3WEDGE               ;TMAP 3WEDGE  24 TOWERS, 8-0, 8-1, 8-2, 8-3 WAVE 15
LA1B8:  .word Z3WEDGE
LA1BA:  .word T3DIFF                ;TMAP 3DIFF  24 TOWERS, 9-0, 9-1, 8-2, 6-3 WAVE 16
LA1BC:  .word Z3DIFF
LA1BE:  .word T3TRAP                ;TMAP 3TRAP  25 TOWERS, 11-0, 8-1, 7-2, 6-3 WAVE 17
LA1C0:  .word Z3TRAP
LA1C2:  .word T3SYMTRC              ;TMAP 3SYMTRC  25 TOWERS, 11-0, 7-1, 7-2, 7-3 WAVE 18
LA1C4:  .word Z3SYMTRC
LA1C6:  .word T3VALLEY              ;TMAP 3VALLEY  31 TOWERS, 10-0, 7-1, 7-2, 8-3 WAVE 19
LA1C8:  .word Z3VALLEY
LA1CA:  .word T3TWRCTY              ;TMAP 3TWRCTY  32 TOWERS, 8-0, 8-1, 9-2, 7-3 WAVE 20
LA1CC:  .word Z3TWRCTY

;------------------------------------------------------------------------------
; IGRND - GROUND ROUTINES
;   INIT FOR SEEING GROUND
;   >= WAVE 21: CHOOSE RANDOMLY(?) FROM ABOVE 6 MAPS
;   (also: ZGDPTR)
;------------------------------------------------------------------------------
IGRND:
ZGDPTR:
LA1CE:  LDU  #GDRAM
LA1D1:  LDA  #$00
LA1D3:  STA  GDS_TYP,U              ;CLEAR OUT TYP -- NOT YET IN SEQUENCE
LA1D5:  LEAU GDS_IZ,U
LA1D7:  CMPU #GDRAMZ
LA1DB:  BLO  LA1D1                  ;HSEND
LA1DD:  LDA  GD_WAV                 ;LIMIT WAVE #
LA1E0:  CMPA #MAPS_EQ
LA1E2:  BLO  LA1EF                  ;IFHS  ?REQUESTED WAVE TOO HI?
LA1E4:  LDB  #MAPS_EQ-MAPS_RPT      ;# OF REPEAT MAPS TO CHOOSE FROM
LA1E6:  LDA  P_RND1
LA1E9:  MUL
LA1EA:  ADDA #MAPS_RPT              ;ADDED TO BASE REPEAT MAP
LA1EC:  STA  GD_WAV                 ;GIVES RANDOM SELECTION FROM TOP MAPS
LA1EF:  LDB  GD_WAV                 ;SETUP NUMBER OF TOWERS FOR THIS WAVE
LA1F2:  LDX  #TTWRS
LA1F5:  ABX
LA1F6:  CMPX #TTWRSZ
LA1F9:  BLO  LA1FE                  ;IFHS  PAST END OF TABLE
LA1FB:  LDX  #TTWRSZ-1
LA1FE:  LDA  ,X
LA200:  STA  GD_TWL                 ;# OF TOWERS LEFT, BCD
LA203:  LDD  TSCTWR                 ;SETUP PROGRESSIVE SCORE TO FIRST VALUE
LA206:  STD  TWRMUL                 ;PROGRESSIVE SCORE FOR TOWER, BCD
LA209:  LDA  TSCTWR+2
LA20C:  STA  TWRMUL+2
LA20F:  LDA  #$00
LA211:  STA  GD_SEQ                 ;SEQUENCE TO START WITH
LA213:  RTS

;------------------------------------------------------------------------------
; VWGRND - [note] View the ground: BJGROT the TDS_GND shape, GRLZIN, then for each entry of the GD_WAV maze (TGDPTR)
;   allowed by GD_SEQ: if in range and in view, GDVIEW and GDGUN; else set up its GDRAM type backstage
;------------------------------------------------------------------------------
VWGRND:
LA214:  LDB  #TDS_GND               ;THE GROUND SHAPE
LA216:  STB  BJ_ID                  ;INTO OBJECT INDENTIFIER
LA218:  JSR  BJGROT                 ;ROTATE THE GROUND OBJECT POINTS AND SAVE STARTING AT M.GD
LA21B:  LDD  #$0000
LA21E:  STD  MS_TX+M_U1             ;SET S1 CENTER TO 0,0,0
LA221:  STD  MS_TY+M_U1
LA224:  STD  MS_TZ+M_U1
LA227:  JSR  GRLZIN                 ;INIT LAZAR COLLISION PARMS
LA22A:  LDD  MS_TX+M_S1             ;RESTORE PLAYER'S POSITION
LA22D:  STD  MS_TX+M_U1
LA230:  LDD  MS_TY+M_S1
LA233:  STD  MS_TY+M_U1
LA236:  LDD  MS_TZ+M_S1
LA239:  STD  MS_TZ+M_U1
LA23C:  LDB  GD_WAV                 ;WAVE NUMBER FOR GROUND SEQUENCE
LA23F:  LSLB                        ;*4 TO INDEX INTO TABLE
LA240:  LSLB
LA241:  LDX  #TGDPTR                ;TABLE OF POINTERS TO GROUND MAZES
LA244:  ABX                         ;POINTS INTO TABLE
LA245:  CMPX #ZGDPTR
LA248:  BLO  LA24D                  ;IFHS  PAST THE TABLE'S END
LA24A:  LDX  #ZGDPTR-4              ;USE LAST ENTRY IF OUT OF RANGE
LA24D:  LDX  ,X                     ;START OF MAZE
LA24F:  STX  S2_PRM
LA251:  LDA  GD_SEQ                 ;CURRENT SEQUENCE NUMBER
LA253:  CMPA TGDS_SQ,X
LA255:  LBLT VWGRND_90              ;?ALLOWED IN THIS SEQUENCE?
LA259:  LDD  TGDS_X,X
LA25B:  STD  M_GD                   ;MAP IS IN TOP VIEW, X LEFT/RIGHT(MBOX Y)
LA25E:  LDD  TGDS_Y,X
LA260:  STD  M_GD+2
LA263:  LDD  #GDS_MDT*2             ;AROUND CENTER OF TOWER(PSUB2 DOES DIV OF 2)
LA266:  STD  M_GD+4
LA269:  LDD  #MS_GDBC               ;SETUP BIC FOR MATH BOX
LA26C:  STD  M_BIC
LA26F:  LDA  #MS_PSB2               ;OBJECT WITHIN RANGE?
LA271:  JSR  MGOWT
LA274:  LDD  M_XP
;*** IF X SIGN CHANGES, RESTART NEW BUILDING
LA277:  BPL  LA27E                  ;IFMI  ?FLIP X OVER FOR TIGHTER PACKING?
LA279:  ANDA #$3F                   ;FLIP IT BACK IN FRONT(PSB2 DIVIDES BY 2)
LA27B:  STD  M_XP
LA27E:  STD  4+M_X0                 ;SAVE NEW DISTANCE FOR COLLISION
LA281:  CMPD #$0100
LA285:  BLT  VWGRND_80              ;IFGE  NOT TOO CLOSE
LA287:  CMPD #$3C00
LA28B:  BHS  VWGRND_80              ;IFLO  NOT TOO FAR ==> WITIN RANGE
;CHECK FOR 45 DEGREES
LA28D:  LDD  M_YP                   ;YP
LA290:  BPL  LA296                  ;IFMI
LA292:  COMA                        ;NEGD
LA293:  NEGB
LA294:  SBCA #$FF
LA296:  SUBD M_XP
LA299:  BHS  VWGRND_80              ;IFLO  ?OBJECT NOW DEFINATELY VISIBLE?
LA29B:  LDU  #GDRAM
LA29E:  LDB  TGDS_RM,X
LA2A0:  LEAU B,U
LA2A2:  LDA  GDS_TYP,U
LA2A4:  BITA #TYPS_VW
LA2A6:  BEQ  LA2AE                  ;IFNE  ?ALREADY FULLY SETUP TO VIEW NOW?
LA2A8:  JSR  GDVIEW                 ;THEN VIEW THE BUILDING
LA2AB:  JSR  GDGUN                  ;ALLOW BUILDINGS TO FIRE GUNS
LA2AE:  BRA  VWGRND_90

VWGRND_80:
;NOT CURRENTLY VISIBLE, BUT SEQUENCE OK
LA2B0:  LDX  S2_PRM                 ;MAKE IT VIEWABLE WHILE BACKSTAGE
LA2B2:  LDU  #GDRAM
LA2B5:  LDB  TGDS_RM,X
LA2B7:  LEAU B,U                    ;POINTING TO RAM ENTRY
LA2B9:  LDA  Q_KTW                  ;?TRANSIT GROM GROUND TO BASE?
LA2BC:  BEQ  LA2C2                  ;IFNE  YES
LA2BE:  CLR  GDS_TYP,U              ;KILL ALL GUNS
LA2C0:  BRA  VWGRND_90              ;ELSE
LA2C2:  LDA  #TYPS_LV+TYPS_AM+TYPS_VW ;WHEN BACKSTAGE, MAKE IT ALIVE, READY TO SHOOT
LA2C4:  LDB  GDS_TYP,U
LA2C6:  BITB #TYPS_DM
LA2C8:  BEQ  LA2D6                  ;IFNE  ?PREVIOUSLY DAMAGED?
LA2CA:  ORA  #TYPS_DM               ;THEN REMAIN DAMAGED
LA2CC:  LDB  TGDS_PC,X
LA2CE:  CMPB #PCS_BNK
LA2D0:  BNE  LA2D4                  ;IFEQ  ?DAMAGED BUILDING A BUNKER?
LA2D2:  ANDA #-1-TYPS_VW            ;THEN NO VIEW THIS PREVIOUSLY DAMAGED BUNKER
LA2D4:  BRA  LA2D8                  ;ELSE
LA2D6:  ORA  #TYPS_BK               ;ELSE NOT DAMAGED, SO TURN ON BUNKER PART
LA2D8:  STA  GDS_TYP,U

VWGRND_90:
;NOT IN THIS SEQUENCE
LA2DA:  LDB  GD_WAV                 ;WAVE NUMBER FOR GROUND SEQUENCE
LA2DD:  LSLB                        ;*4 TO INDEX INTO TABLE
LA2DE:  LSLB
LA2DF:  LDX  #TGDPTR                ;TABLE OF POINTERS TO GROUND MAZES
LA2E2:  ABX                         ;POINTS INTO TABLE
LA2E3:  CMPX #ZGDPTR
LA2E6:  BLO  LA2EB                  ;IFHS  PAST THE TABLE'S END
LA2E8:  LDX  #ZGDPTR-4              ;USE LAST ENTRY IF OUT OF RANGE
LA2EB:  TFR  X,U                    ;POINTS INTO TABLE OF POINTERS
LA2ED:  LDX  S2_PRM
LA2EF:  LEAX TGDS_IZ,X
LA2F1:  CMPX 2,U                    ;CMPARE TO END OF CURRENT MAZE
LA2F3:  LBLO LA24F                  ;HSEND
LA2F7:  RTS

;------------------------------------------------------------------------------
; GDVIEW - THEN VIEW THE BUILDING  (comment at the call)
;------------------------------------------------------------------------------
GDVIEW:
LA2F8:  LDX  S2_PRM
LA2FA:  LDB  TGDS_PC,X
LA2FC:  CMPB #PCS_BNK
LA2FE:  BNE  LA304                  ;IFEQ  ? A BUNKER PICTURE?
LA300:  LDB  #TDS_BNK
LA302:  BRA  LA306                  ;ELSE  ELSE A TOWER PIC
LA304:  LDB  #TDS_TWR
LA306:  STB  BJ_ID                  ;UPDATE OBJECT ROUTINES ABOUT IT
LA308:  LDD  #(VGCYLW*$100)+VGCOPC  ;THEN ASSUME VISIBLE NORMALLY
LA30B:  STD  M_GDCB                 ;BASE COLOR, INTO MBOX FOR LATER D-PAGE USE
LA30E:  LDU  #GDRAM
LA311:  LDB  TGDS_RM,X
LA313:  LEAU B,U
LA315:  LDA  GDS_TYP,U
LA317:  LDB  TGDS_PC,X
LA319:  CMPB #PCS_BNK
LA31B:  BEQ  LA333                  ;IFNE  ?NOT A LONE BUNKER?
LA31D:  BITA #TYPS_DM               ;THEN MUST BE A TOWER OR BISHOP
LA31F:  BNE  GDVIEW_20              ;?DAMAGED?
LA321:  BITA #TYPS_BK
LA323:  BNE  LA32E                  ;IFEQ  ?OR WITH A GONE BUNKER ON TOP?

GDVIEW_20:
LA325:  LDB  #TDS_STB               ;THEN DRAW JUST THE STUB
LA327:  STB  BJ_ID
LA329:  LDD  #(VGCOFF*$100)+VGCOPC  ;NO HAT DRAWN ON TOP
LA32C:  BRA  LA331                  ;ELSE  ELSE TOWER HAS A HAT
LA32E:  LDD  #(VGCWHT*$100)+VGCOPC  ;SO DRAW IT SPECIAL WHITE
LA331:  BRA  LA33F                  ;ELSE  ELSE IS LONE BUNKER
LA333:  BITA #TYPS_DM
LA335:  BNE  LA33C                  ;IFEQ  ?NOT DAMAGED?
LA337:  LDD  #(VGCRED*$100)+VGCOPC-$20
LA33A:  BRA  LA33F                  ;ELSE  ELSE DAMAGED
LA33C:  LDD  #(VGCOFF*$100)+VGCOPC  ;SHOW IT
LA33F:  STD  M_GDCT                 ;TOP COLOR OF LASAR TOWERS, BUNKER COLOR
LA342:  LDA  #$72                   ;LIN SCALE TO REDUCE SIZE OF FAR OBJECTS
LA344:  STA  M_GDSC                 ;SAVE THE SCALE
LA347:  LDA  M_XP                   ;3F MAX
LA34A:  LSLA
LA34B:  LSLA                        ;BUMP UP TO UNSIGNED FF
;;; LDB #0FF ;MULT FOR SMALLEST SIZE
;;; MUL
LA34C:  STA  M_GDSC+1
LA34F:  LDB  #$40                   ;RANGE OF BRITENESS
LA351:  COMA                        ;FLIP FOR BRITENESS
LA352:  MUL
LA353:  ADDA #$40                   ;DIMMEST BRITENESS
LA355:  STA  M_GDCB+1               ;PUT INTO COLOR INSTRUCTIONS
LA358:  LDD  (MS_VX+M_S1)&$FFFF     ;GET PLAYER SPEED
LA35B:  LSLB                        ;LSLD
LA35C:  ROLA
LA35D:  ADDD #$0400                 ;PLUS OFFSET
LA360:  SUBD M_XP
;;; IFHS ;?GETTING CLOSE TO TOWER?
LA363:  LBLT GDVIEW_91
LA367:  LDA  TGDS_PC,X
LA369:  CMPA #PCS_BNK
LA36B:  BEQ  LA3A7                  ;IFNE  ?A TOWER?
LA36D:  LDA  S_GAS
LA36F:  BLT  LA374                  ;IFGE  ?STILL IN NORMAL GAMEPLAY?
LA371:  JSR  AUDPF                  ;TOWER PFFFTS
LA374:  LDD  M_XP
LA377:  SUBD #$0200
LA37A:  SUBD (MS_VX+M_S1)&$FFFF
LA37D:  BGT  LA3A5                  ;IFLE  ?CLOSE ENUF FOR COLLISION?
LA37F:  LDD  #VJFLS                 ;VERY BRITE HIT
LA382:  STD  M_GDCB                 ;BASE COLOR, INTO MBOX FOR LATER D-PAGE USE
LA385:  LDD  #(VGCOFF*$100)+VGCOPC
LA388:  STD  M_GDCT                 ;TOP COLOR OF LASAR TOWERS
LA38B:  LDA  S_GAS
LA38D:  BLT  LA395                  ;IFGE  ?STILL IN REGULAR GAMEPLAY?
LA38F:  JSR  BG1GLW                 ;START GLOWING SHIELDS
LA392:  JSR  AUDCR                  ;AND CRASH INTO TOWER
LA395:  LDA  S_ROL
LA397:  BNE  LA39D                  ;IFEQ  ?ANY PREVIOUS DIRECTION PREFERRED?
LA399:  LDA  M_YP                   ;IF NOT, THEN SELECT ONE
LA39C:  NEGA
LA39D:  LDB  #$20                   ;AMOUNT TO ROLL
LA39F:  TSTA
LA3A0:  BPL  LA3A3                  ;IFMI  ?WHICH DIRECTION TO CHOOSE?
LA3A2:  NEGB
LA3A3:  STB  S_ROL
LA3A5:  BRA  GDVIEW_91              ;ELSE  ELSE IS BUNKER
LA3A7:  LDD  MS_TZ+M_U1
LA3AA:  SUBD #$07A0                 ;HITE*SCALE*PSUB2+SCREEN HITE FOR CLOSE HIT
LA3AD:  BGT  GDVIEW_91              ;IFLE  ?CLOSE OVER TOP OF BUNKER?
LA3AF:  JSR  AUDPF                  ;BUNKER PFFFTS
LA3B2:  LDX  S2_PRM
LA3B4:  LDU  #GDRAM
LA3B7:  LDB  TGDS_RM,X
LA3B9:  LEAU B,U
LA3BB:  LDA  GDS_TYP,U
LA3BD:  BITA #TYPS_DM
LA3BF:  BNE  GDVIEW_91              ;IFEQ  ?CHECK COLLISION SINCE BLOWN AWAY?
LA3C1:  LDD  MS_TZ+M_U1
LA3C4:  SUBD #$05A0                 ;HITE*SCALE*PSUB2
LA3C7:  BGE  GDVIEW_91              ;IFLT  ?TOO CLOSE OVER TOP OF BUNKER?
LA3C9:  LDD  M_XP
LA3CC:  SUBD #$0400
LA3CF:  SUBD (MS_VX+M_S1)&$FFFF
LA3D2:  BGT  GDVIEW_91              ;IFLE  ?CLOSE ENUF FOR COLLISION?
LA3D4:  LDD  #VJFLS                 ;VERY BRITE HIT
LA3D7:  STD  M_GDCT                 ;TOP COLOR FOR BUNKER, INTO MBOX FOR LATER D-PAGE USE
LA3DA:  LDA  S_GAS
LA3DC:  BLT  LA3E4                  ;IFGE  ?STILL IN NORMAL GAME?
LA3DE:  JSR  BG1GLW                 ;BEGIN GLOWING SHIELDS
LA3E1:  JSR  AUDCR                  ;AND CRASH INTO BUNKER
LA3E4:  LDA  S_ROL
LA3E6:  BNE  GDVIEW_91              ;IFEQ  ?READY FOR ANOTHER HIT? (BE POLITE)
LA3E8:  LDA  #$13                   ;ROLLING COUNT FOR PARTIAL ROLL
LA3EA:  LDB  M_YP
LA3ED:  BMI  LA3F0                  ;IFPL  ?WHICH DIRECTION TO ROLL?
LA3EF:  NEGA                        ;HIT RIGHT SHOULDER ROLLS US LEFT
LA3F0:  ADDA S_ROL                  ;ROLLS ACCUMULATE -- LOSE CONTROL
LA3F2:  STA  S_ROL

GDVIEW_91:
;;; ENDIF
LA3F4:  LDA  M_XP
LA3F7:  SUBA #$08                   ;FIRST 1000 AWAY
LA3F9:  BGT  LA400                  ;IFLE  ?TOO CLOSE FOR DISPLAY COMFORT?
LA3FB:  JSR  BJGCLP                 ;CLIP CLOSE OBJECTS
LA3FE:  BRA  LA403                  ;ELSE
LA400:  JSR  BJGPNT                 ;TRANSLATE AND PROJECT GROUND OBJECT'S POINTS
LA403:  JSR  BJGDRW                 ;DRAW THE OBJECT, NEEDS ORIGINAL M.XP,YP,ZP
LA406:  JSR  GRLZCL                 ;PROCESS LAZAR COLLISION
LA409:  RTS

;------------------------------------------------------------------------------
; GRLZIN - LAZAR COLLISIONS
;   INIT VALS FOR LATER COLLISION
;   TRANSPOSE U1 TO GET UNROTATED LAZAR VIDEO LOC
;------------------------------------------------------------------------------
GRLZIN:
LA40A:  JSR  TRANU1
LA40D:  LDD  #$0000
LA410:  STD  0+M_X0
LA413:  LDD  LZ_CX
LA415:  STD  2+M_X0                 ;LEFT/RIGHT VID X IS MATH Y
LA418:  LDD  LZ_CY
LA41A:  STD  4+M_X0                 ;UP/DOWN VID Y IS MATH Z
LA41D:  LDD  #MS_X0BC
LA420:  STD  M_BIC
LA423:  LDA  #MS_PSUB
LA425:  JSR  MGOWT
LA428:  LDD  M_YP
LA42B:  STD  0+M_X0                 ;FOR LATER SAFEKEEPING
LA42E:  LDD  M_ZP
LA431:  STD  2+M_X0                 ;LAZAR VIDEO LOC IF SHIP NOT ROTATED
LA434:  BPL  LA455                  ;IFMI  ?LOWER THAN CENTER OF SCREEN?
LA436:  LDA  LZ_ON
LA438:  BEQ  LA455                  ;IFNE
LA43A:  LDA  #$FF
LA43C:  STA  LZ_HIT                 ;THEN AM SWEEPING DIRT GROUND -- SHOW SPLASH
LA43E:  LDA  #BT0+BT1               ;UPPER HALF
LA440:  STA  SP_TYP
LA443:  LDD  #(VGCGRN*$100)+VGCOPC
LA446:  STD  SP_COL
LA449:  LDD  M_ZP                   ;HITE BENEATH HORIZON IN VID UNITS
LA44C:  LSRA                        ;LSRD  -256.
LA44D:  RORB
LA44E:  LSRA                        ;LSRD  -128. ( 80 )
LA44F:  RORB
;BUT ROTATION MAY MAKE IT 1.4 TIMES BIGGER
LA450:  ADDB #$C0                   ;HORIZON IS FAR AWAY, BOTTOM OF SCREEN IS CLOSE
LA452:  STB  SP_LOC
LA455:  JSR  TRANU1                 ;UN-TRANSPOSE MATRIX BACK TO NORMAL
LA458:  RTS

;------------------------------------------------------------------------------
; GRLZCL - CHECK FOR ACTUAL COLLISION
;   CALC 1/X WITH LIN SCALE INCLUDED
;------------------------------------------------------------------------------
GRLZCL:
LA459:  LDX  S2_PRM
LA45B:  LDD  4+M_X0                 ;PULL VIEWED OBJECT DISTANCE
LA45E:  LSLB                        ;LSLD  PSUB2 DOES DIV BY 2
LA45F:  ROLA
LA460:  STD  M_DVD                  ;GEN 1/X
LA463:  LDD  2,X                    ;OBJECT Y
LA465:  SUBD MS_TY+M_U1             ;TRANSLATE WITHOUT ROTATION
LA468:  STD  M_YP                   ;PREPARE FOR MULTIPLY
LA46B:  LDD  #$0000                 ;Z, BOTTOM OF BUNKERS,TOWERS
LA46E:  SUBD MS_TZ+M_U1
LA471:  STD  M_ZP
LA474:  LDD  M_QUO
LA477:  STD  M_XP                   ;GET X FOR PROPER SCREEN CONVERSION
LA47A:  LDA  #MS_PERS
LA47C:  JSR  MGOWT
LA47F:  LDD  M_YP
LA482:  STD  M_YT                   ;FOR SAVETY
LA485:  LDD  M_ZP
LA488:  STD  M_ZT                   ;Y,Z CONVERTED TO SCREEN COORDS
LA48B:  LDA  TGDS_PC,X              ;DIFFERENT HITES FOR DIFFERENT TOWERS
LA48D:  CMPA #PCS_BNK
LA48F:  BEQ  LA49F                  ;IFNE  ?TOWER?
LA491:  LDD  #$03C0                 ;DOUBLE RADIUS OF OBJECT
LA494:  STD  M_YP
LA497:  LDD  #$5280                 ;DOUBLE HITE
LA49A:  STD  M_ZP                   ;Z HITE(MAX)
LA49D:  BRA  LA4BA                  ;ELSE
LA49F:  LDU  #GDRAM                 ;FIRST FIND IF BUNKER IS STILL ALIVE
LA4A2:  LDB  TGDS_RM,X
LA4A4:  LEAU B,U
LA4A6:  LDA  GDS_TYP,U
LA4A8:  BITA #TYPS_DM
LA4AA:  LBNE GRLZCL_92              ;B EXIT SINCE BUNKER ALREADY DAMAGED
LA4AE:  LDD  #$0690                 ;DOUBLE BUNKER HITE
LA4B1:  STD  M_YP
LA4B4:  LDD  #$05A0                 ;DOUBLE BUNKER HITE
LA4B7:  STD  M_ZP
LA4BA:  LDD  M_XP                   ;GET 1/X
LA4BD:  SUBD #$0100                 ;ADJUST FOR LINEAR SCALE EFFECT
LA4C0:  BPL  LA4C5                  ;IFMI
LA4C2:  LDD  #$0000                 ;BUT DONT GO OVERBOARD
LA4C5:  STD  M_XP
LA4C8:  LDA  #MS_PERS
LA4CA:  JSR  MGOWT                  ;DO THE MULTIPLYS
LA4CD:  LDD  M_YT                   ;NOW TEST UNROTATED VIDEO LOC
LA4D0:  ADDD M_YP                   ;MISNAMED, IS RADIUS OF COLLISION
LA4D3:  ADDD #$000A                 ;SITE RADIUS FOR FUDGE
LA4D6:  SUBD 0+M_X0                 ;UNROTATED LAZAR SITE LOCATION
;IFGE ;1?TO ONE SIDE OF TOWER?
LA4D9:  LBLT GRLZCL_92
LA4DD:  ASRA                        ;ASRD  THEN CHANGE DELTA DIAMETER TO RADIUS
LA4DE:  RORB
LA4DF:  SUBD #$000A                 ;SITE DIAMETER/2 FOR FUDGE
LA4E2:  SUBD M_YP                   ;AND COMPARE WITH COLLISION RADIUS WIDTH
;IFLE ;2?WITHIN BOTH BOUNDS? THEN A LEFT/RIGHT HIT!
LA4E5:  LBGT GRLZCL_92
;NOW CHECK Z
LA4E9:  LDD  2+M_X0
LA4EC:  SUBD M_ZT                   ;COMPARE WITH UNROTATED LAZAR SCREEN
LA4EF:  BMI  GRLZCL_92              ;IFPL  3?SHOOTING ABOVE GROUND LEVEL?
LA4F1:  SUBD M_ZP                   ;MISNOMER -- TEST AGAINST HITE DIAMETER
LA4F4:  BGT  GRLZCL_92              ;IFLE  4?WITHIN LIMITS?
LA4F6:  LDA  TGDS_PC,X
LA4F8:  CMPA #PCS_BNK
LA4FA:  BNE  LA50A                  ;IFEQ  5?BUNKER?
LA4FC:  LDD  4+M_X0
LA4FF:  CMPD CL_BDS
LA502:  BHS  LA508                  ;IFLO  ?CLOSEST SO FAR?
LA504:  STD  CL_BDS
LA506:  STX  CL_BP                  ;AND SAVE POINTER FOR LATER
LA508:  BRA  GRLZCL_92              ;ELSE  ELSE IS TOWER
LA50A:  LDD  #$4CE0                 ;HITE TO BUNKER ON TOP
LA50D:  STD  M_YP
LA510:  LDA  #MS_PERS               ;BLITZES ZP
LA512:  JSR  MGOWT
LA515:  LDD  2+M_X0                 ;LAZAR HITE
LA518:  ADDD #$000A                 ;SITE RADIUS FOR FUDGE
LA51B:  SUBD M_ZT
LA51E:  SUBD M_YP
LA521:  BLT  LA53E                  ;IFGE  6?WITHIN BUNKER ON TOP?
LA523:  LDU  #GDRAM                 ;FIRST FIND IF BUNKER IS STILL ALIVE
LA526:  LDB  TGDS_RM,X
LA528:  LEAU B,U
LA52A:  LDA  GDS_TYP,U
LA52C:  BITA #TYPS_DM
LA52E:  BNE  GRLZCL_92              ;B EXIT SINCE BUNKER ALREADY DAMAGED
LA530:  LDD  4+M_X0
LA533:  CMPD CL_BDS
LA536:  BHS  LA53C                  ;IFLO  ?CLOSEST SO FAR?
LA538:  STD  CL_BDS
LA53A:  STX  CL_BP                  ;AND SAVE POINTER FOR LATER
LA53C:  BRA  GRLZCL_92              ;ELSE  ELSE SPLASHED TOWER
LA53E:  LDD  4+M_X0
LA541:  CMPD CL_TDS
LA544:  BHS  GRLZCL_92              ;IFLO  ?CLOSEST SO FAR?
LA546:  STD  CL_TDS
LA548:  STX  CL_TP                  ;AND SAVE POINTER FOR LATER

GRLZCL_92:
GRLZCL_91:
GRLZCL_90:
;ENDIF
;ENDIF
LA54A:  RTS

;------------------------------------------------------------------------------
; GDHTGB - GROUND BUNKER HIT BY LAZARS
;------------------------------------------------------------------------------
GDHTGB:
LA54B:  LDX  CL_BP                  ;GET THE POINTER
LA54D:  LDD  TGDS_X,X
LA54F:  SUBD MS_TX+M_S1             ;PLACE IN FRONT OF PLAYER(MAP WRAPS EVERY 8000)
LA552:  ANDA #$7F                   ;KEEP IN VIEW
LA554:  ADDD MS_TX+M_S1
LA557:  STD  M_XT
LA55A:  LDD  TGDS_Y,X
LA55C:  STD  M_YT
LA55F:  LDU  #GDRAM
LA562:  LDB  TGDS_RM,X              ;AND OFFSET INTO RAM
LA564:  LEAU B,U
LA566:  LDA  GDS_TYP,U
LA568:  ORA  #TYPS_DM               ;SET DAMAGED BIT
LA56A:  STA  GDS_TYP,U
LA56C:  LDA  TGDS_PC,X
LA56E:  CMPA #PCS_BNK               ;GROUND LASER BUNKER?
LA570:  BNE  LA580                  ;IFEQ  YES
LA572:  LDD  #$02D0
LA575:  STD  M_ZT
LA578:  JSR  BGBKXP
LA57B:  JSR  SCRBNK                 ;SCORE FOR HITTING A BUNKER
LA57E:  BRA  LA58C                  ;ELSE  MUST BE TOWER TOP
LA580:  LDD  #$5460                 ;55 IS MID HITE OF TOP, 5 IS FUDGE TO LOOK GOOD
LA583:  STD  M_ZT
LA586:  JSR  BGTWXP
LA589:  JSR  SCRTWR                 ;SCORE FOR HITTING A TOWER BUNKER
LA58C:  JSR  AUDSX                  ;SMALL EXPLOSION FOR HITTING BUNKER
LA58F:  RTS

;------------------------------------------------------------------------------
; GDHTGT - GROUND TOWER HIT BY LAZARS
;------------------------------------------------------------------------------
GDHTGT:
LA590:  RTS

;------------------------------------------------------------------------------
; GDGUN - SHOOT GUNS
;   ATTEMPT TO FIRE GUNS FROM LAZAR BUILDINGS
;------------------------------------------------------------------------------
GDGUN:
LA591:  LDA  S_GAS
LA593:  BLT  LA5B2                  ;IFGE  ?NOT YET IN DEATH SCENE?
LA595:  LDX  S2_PRM
LA597:  LDU  #GDRAM
LA59A:  LDB  TGDS_RM,X
LA59C:  LEAU B,U
LA59E:  LDA  GDS_TYP,U
LA5A0:  BITA #TYPS_DM
LA5A2:  BNE  LA5B2                  ;IFEQ  ?GUNS NOT DAMAGED YET?
LA5A4:  LDA  TGDS_PC,X              ;GET BUILDING TYPE
LA5A6:  CMPA #PCS_BSH
LA5A8:  LBEQ GDBSHGN                ;2==>BISHOP GUN
LA5AC:  LBHI GDBNKGN                ;>2==>BUNKER GUN
LA5B0:  BRA  GDTWRGN                ;<2==>TOWER GUN
LA5B2:  RTS

;------------------------------------------------------------------------------
; GDTWRGN - TOWER GUN
;------------------------------------------------------------------------------
GDTWRGN:
LA5B3:  LDD  #$4000
LA5B6:  SUBD 4+M_X0                 ;4000-DISTANCE TO TOWER
LA5B9:  LSLB                        ;LSLD  /4000 IS UNITY, THEN *2 FOR PRESUB2 EFFECT
LA5BA:  ROLA
LA5BB:  STD  M_XP                   ;GET LINEAR SCALED FRACTIONS OF ORIGINAL HITE
LA5BE:  LDD  #$2940                 ;VERY TOP OF BUNKER
LA5C1:  STD  M_ZP
LA5C4:  LDD  #$02D0
LA5C7:  STD  M_YP                   ;HITE OF BUNKER PORTION
LA5CA:  LDA  #MS_PERS               ;MULT THE LIN SCALE BY TOWER SIZE
LA5CC:  JSR  MGOWT
LA5CF:  LDD  M_ZP
LA5D2:  SUBD MS_TZ+M_U1             ;COMPARE AGAINST PLAYERS HITE
LA5D5:  BGE  LA5DE                  ;IFLT  ?STILL BENEATH HORIZON?
LA5D7:  LDA  GDS_TYP,U
LA5D9:  ORA  #TYPS_AM
LA5DB:  STA  GDS_TYP,U              ;WE HAVE PROPER AIM WHENEVER WE POKE ABOVE HORIZON
LA5DD:  RTS
LA5DE:  SUBD M_YP                   ;CHECK AGAINST MAX SIZE OF BUNKER ITSELF
LA5E1:  BLE  GDTWRG_30              ;B SHOOT IF WE STRADDLE HORIZON
LA5E3:  LDA  GDS_TYP,U              ;ELSE TEST IF WE USED TO BE UNDER HORIZON
LA5E5:  BITA #TYPS_AM
LA5E7:  BEQ  LA607                  ;IFNE  ?JUMPED PAST HORIZON? THEN SHOOT ANYWAY

GDTWRG_30:
LA5E9:  LDA  GDS_TYP,U              ;SINCE HAVE PASSED HORIZON, CLEAR OUT AIM
LA5EB:  ANDA #-1-TYPS_AM
LA5ED:  STA  GDS_TYP,U
LA5EF:  LDA  P_RND1
LA5F2:  BPL  LA5F7                  ;IFMI  ?50 PERCENT CHANCE OF FIRING?
LA5F4:  JSR  FRWFGN                 ;J THEN SHOOT A FORWARD GUN
LA5F7:  LDA  P_RND1
LA5FA:  BPL  LA5FF                  ;IFMI  ?SHOOT ONE WAY DIAG OR THE OTHER?
LA5FC:  JSR  FRWRGN                 ;J SHOOT TO RIGHT DIAGONALLY
LA5FF:  LDA  P_RND1
LA602:  BPL  LA607                  ;IFMI  ?SHOOT ONE WAY DIAG OR THE OTHER?
LA604:  JSR  FRWLGN                 ;J ELSE SHOOT LEFT DIAGONALLY
LA607:  RTS

;------------------------------------------------------------------------------
; GDBSHGN - BISHOP GUN
;------------------------------------------------------------------------------
GDBSHGN:
LA608:  LDD  #$4000
LA60B:  SUBD 4+M_X0                 ;4000-DISTANCE TO TOWER
LA60E:  LSLB                        ;LSLD  (4000-DIST)/4000(UNITY)*2(PRESUB2 EFFECT)
LA60F:  ROLA
LA610:  STD  M_XP                   ;GET LINEAR SCALED FRACTIONS OF ORIGINAL HITE
LA613:  LDD  #$2940                 ;VERY TOP OF BUNKER
LA616:  STD  M_ZP
LA619:  LDD  #$02D0
LA61C:  STD  M_YP                   ;HITE OF BUNKER PORTION
LA61F:  LDA  #MS_PERS               ;MULT THE LIN SCALE BY TOWER SIZE
LA621:  JSR  MGOWT
LA624:  LDD  M_ZP
LA627:  SUBD MS_TZ+M_U1             ;COMPARE AGAINST PLAYERS HITE
LA62A:  BGE  LA633                  ;IFLT  ?STILL BENEATH HORIZON?
LA62C:  LDA  GDS_TYP,U
LA62E:  ORA  #TYPS_AM
LA630:  STA  GDS_TYP,U              ;WE HAVE PROPER AIM WHENEVER WE POKE ABOVE HORIZON
LA632:  RTS
LA633:  SUBD M_YP                   ;CHECK AGAINST MAX SIZE OF BUNKER ITSELF
LA636:  BLE  GDBSHG_30              ;B SHOOT IF WE STRADDLE HORIZON
LA638:  LDA  GDS_TYP,U              ;ELSE TEST IF WE USED TO BE UNDER HORIZON
LA63A:  BITA #TYPS_AM
LA63C:  BEQ  LA654                  ;IFNE  ?JUMPED PAST HORIZON? THEN SHOOT ANYWAY

GDBSHG_30:
LA63E:  LDA  GDS_TYP,U              ;SINCE HAVE PASSED HORIZON, CLEAR OUT AIM
LA640:  ANDA #-1-TYPS_AM
LA642:  STA  GDS_TYP,U
LA644:  LDA  P_RND1
LA647:  BPL  LA64C                  ;IFMI  ?50 PERCENT CHANCE OF FIRING?
LA649:  JSR  FRWRGN                 ;J SHOOT TO RIGHT DIAGONALLY
LA64C:  LDA  P_RND1
LA64F:  BPL  LA654                  ;IFMI  ?50 PERCENT CHANCE OF FIRING?
LA651:  JSR  FRWLGN                 ;J ELSE SHOOT LEFT DIAGONALLY
LA654:  RTS

;------------------------------------------------------------------------------
; GDBNKGN - BUNKER GUN
;------------------------------------------------------------------------------
GDBNKGN:
LA655:  LDA  #$40                   ;CLOSE WILL BE 40, FAR IS 0
LA657:  SUBA 4+M_X0                 ;REVERSED DISTANCE TO BUNKER,0 TO 3F
LA65A:  CMPA P_RND1
LA65D:  BLO  LA674                  ;IFHS  ?LESS CHANCE WHEN FAR AWAY?
LA65F:  LDA  P_RND1
LA662:  CMPA #$50
LA664:  BHS  LA669                  ;IFLO  ?SHOOT STRAIGHT AHEAD?
LA666:  JMP  FRBFGN                 ;J THEN SHOOT A BUNKER FORWARD GUN
LA669:  LDA  P_RND1
LA66C:  BPL  LA671                  ;IFMI  ?SHOOT ONE WAY DIAG OR THE OTHER?
LA66E:  JMP  FRBRGN                 ;J SHOOT TO BUNKER RIGHT DIAGONALLY
LA671:  JMP  FRBLGN                 ;J ELSE SHOOT BUNKER LEFT DIAGONALLY
LA674:  RTS

;==============================================================================
; MODULE WSGUNS   WSGUNS.MAC
;   GUNS AS SHOOTING OBJECTSWSMAIN GAME PLAY
;==============================================================================

;.SBTTL GUN EQUATES, OFFSETS

TMOVE:           ;MOVE ROUTINES
LA675:  .word MOVST                 ;.IRP .A,<ST,AM,LV,WF,WL,WR,BF,BL,BR,PL,PR>
LA677:  .word MOVAM
LA679:  .word MOVLV
LA67B:  .word MOVWF
LA67D:  .word MOVWL
LA67F:  .word MOVWR
LA681:  .word MOVBF
LA683:  .word MOVBL
LA685:  .word MOVBR
LA687:  .word MOVPL
LA689:  .word MOVPR

;------------------------------------------------------------------------------
; FRAGUN - FIRE GUNS
;   FIRE ALIENS GUN
;   X-->ALIEN PARM
;   U-->GUN PARM
;   (also: ZMOVE)
;------------------------------------------------------------------------------
FRAGUN:
ZMOVE:
LA68B:  STU  GN_PTR
LA68D:  LDB  #$40
LA68F:  STB  GS_TMR,U
LA691:  LDB  #TYPS_LV
LA693:  STB  GS_TYP,U
LA695:  LDB  #MOVS_AM
LA697:  STB  GS_MOV,U
LA699:  LDA  Q_SHK
LA69C:  BLE  LA6AB                  ;IFGT  ?STILL WAITING FOR 'CANT SHAKE HIM'?
LA69E:  CMPX AM_PTR
LA6A1:  BNE  LA6AB                  ;IFEQ  ?IS THIS THE ONE WE ARE POINTING AT?
LA6A3:  DEC  Q_SHK                  ;COUNT DOWN ONE LESS SHOT
LA6A6:  BNE  LA6AB                  ;IFEQ
LA6A8:  JSR  SPKSHK                 ;I CANT SHAKE HIM
LA6AB:  LDU  GS_UVP,U               ;U-->GUN UVP
LA6AD:  LDX  AS_UVP,X               ;X-->ALIEN UVP
LA6AF:  LDD  MS_TX,X
LA6B1:  SUBD MS_TX+M_S1
LA6B4:  STD  ,U                     ;POSITION SHOT RELATIVE TO PLAYER
LA6B6:  LDD  MS_TY,X
LA6B8:  SUBD MS_TY+M_S1
LA6BB:  STD  2,U                    ;Y POS
LA6BD:  LDD  MS_TZ,X
LA6BF:  SUBD MS_TZ+M_S1
LA6C2:  STD  4,U                    ;Z POS
LA6C4:  JSR  AUDTC                  ;TIE FIGHTER CANNONS
LA6C7:  RTS

TGNGD:           ;GROUND BUNKERS
LA6C8:  .word GUNZ-(1*GS_IZE)
LA6CA:  .word GUNZ-(1*GS_IZE)       ;1 MODERATE
LA6CC:  .word GUNZ-(2*GS_IZE)
LA6CE:  .word GUNZ-(2*GS_IZE)       ;3 MODERATE
LA6D0:  .word GUNZ-(3*GS_IZE)
LA6D2:  .word GUNZ-(3*GS_IZE)       ;5 MODERATE
LA6D4:  .word GUNZ-(4*GS_IZE)
LA6D6:  .word GUNZ-(4*GS_IZE)
LA6D8:  .word GUNZ-(5*GS_IZE)
LA6DA:  .word GUNZ-(5*GS_IZE)
LA6DC:  .word GUNZ-(6*GS_IZE)
LA6DE:  .word GUNZ-(6*GS_IZE)

;------------------------------------------------------------------------------
; ZGNGD - # OF GROUND GUNS
;   (also: GNGDAVAIL)
;------------------------------------------------------------------------------
ZGNGD:
GNGDAVAIL:
LA6E0:  LDB  WV_HRD
LA6E3:  CMPB #(ZGNGD-TGNGD)/2
LA6E5:  BLO  LA6EC                  ;IFHS  LIMIT TO TABLE SIZE
LA6E7:  LDX  #ZGNGD-2
LA6EA:  BRA  LA6F2                  ;ELSE
LA6EC:  LSLB                        ;WORD ENTRIES
LA6ED:  LDX  #TGNGD
LA6F0:  LDX  B,X
LA6F2:  BRA  TSTAVAIL

;------------------------------------------------------------------------------
; GNBSAVAIL - ONLY ALLOW BASE GUNS
;------------------------------------------------------------------------------
GNBSAVAIL:
LA6F4:  LDB  WV_HRD
LA6F7:  CMPB #$07
LA6F9:  BLS  LA6FD                  ;IFHI  LIMIT TO TABLE SIZE
LA6FB:  LDB  #$07
LA6FD:  LSLB                        ;WORD ENTRIES
LA6FE:  LDX  #TGNBS
LA701:  LDX  B,X
LA703:  BRA  TSTAVAIL

;------------------------------------------------------------------------------
; GNAVAIL - FIND AN AVAILABLE GUN, PUT INTO GN.PTR AND X
;   ELSE POP TO PREVIOUS CALLER
;------------------------------------------------------------------------------
GNAVAIL:
LA705:  LDX  #GUN

TSTAVAIL:
LA708:  STX  GN_PTR
LA70A:  LDA  GS_TYP,X
LA70C:  BEQ  TSTAVA_90              ;B IF FOUND A GOOD GUN
LA70E:  LEAX GS_IZE,X
LA710:  CMPX #GUNZ
LA713:  BLO  TSTAVAIL               ;HSEND
LA715:  LEAS 2,S                    ;POP UP ONE MORE LEVEL IF NO GUNS FOUND

TSTAVA_90:
LA717:  RTS

TGNBS:           ;BASE
LA718:  .word GUNZ-(1*GS_IZE)
LA71A:  .word GUNZ-(1*GS_IZE)       ;1 MODERATE
LA71C:  .word GUNZ-(2*GS_IZE)
LA71E:  .word GUNZ-(2*GS_IZE)       ;3 MODERATE
LA720:  .word GUNZ-(3*GS_IZE)
LA722:  .word GUNZ-(3*GS_IZE)       ;5 MODERATE
LA724:  .word GUNZ-(3*GS_IZE)
LA726:  .word GUNZ-(4*GS_IZE)

;------------------------------------------------------------------------------
; FRBFGN - BUNKER FIRES A FORWARD GUN
;   BUNKER FIRES A LEFT DIAG GUN
;   BUNKER FIRES A RIGHT GUN
;   (also: FRBLGN, FRBRGN)
;------------------------------------------------------------------------------
FRBFGN:
FRBLGN:
FRBRGN:
LA728:  JSR  GNGDAVAIL
LA72B:  LDA  #$70
LA72D:  STA  GS_TMR,X
LA72F:  LDA  #TYPS_LV+TYPS_UN
LA731:  STA  GS_TYP,X
LA733:  LDU  S2_PRM
LA735:  STX  TMPGRM
LA737:  LDD  2,U
LA739:  SUBD MS_TY+M_S1
LA73C:  BMI  LA742                  ;IFPL  ?BUNKER TO RIGHT OF PLAYER?
LA73E:  LDA  #MOVS_BR               ;THIS IS A RIGHT HAND BUNKER
LA740:  BRA  LA744                  ;ELSE
LA742:  LDA  #MOVS_BL               ;ELSE LEFT GUN
LA744:  STA  GS_MOV,X
LA746:  LDX  GS_UVP,X
LA748:  LDA  ,U                     ;FORCE GROUND SHOTS ALWAYS TO FRONT
LA74A:  SUBA MS_TX+M_S1             ;SHOT-ME, IF MINUS THEN FLIP ACTUAL LOC
LA74D:  ANDA #$80                   ;JUST PLAY WITH SIGN BIT TO FLIP
LA74F:  EORA ,U
LA751:  LDB  1,U
LA753:  STD  ,X
LA755:  LDD  2,U
LA757:  STD  2,X
LA759:  LDD  #GDS_MNT               ;START AT MINIMUM PLAYER HITE
LA75C:  STD  4,X
LA75E:  LDD  2,X                    ;Y RELATIVE POSITION OF SHOT
LA760:  SUBD MS_TY+M_S1
LA763:  STA  6,X                    ;TEMP, +==>BUNKER TO RIGHT OF PLAYER
LA765:  BPL  LA76B                  ;IFMI
LA767:  COMA                        ;NEGD  ABSD
LA768:  NEGB
LA769:  SBCA #$FF
LA76B:  STD  M_DVN                  ;***NUMERATOR
LA76E:  LDD  ,X
LA770:  SUBD MS_TX+M_S1             ;X RELATIVE DISTANCE TO TRAVEL
LA773:  STD  M_DVD                  ;START DIVIDER
LA776:  LDD  #$0200                 ;RESTORE DIVIDER
LA779:  STD  M_DVN
LA77C:  LDA  M_QUO
LA77F:  LSLA                        ;MOVE 4000(3FFF) AS ONE TO FFFF AS ONE
LA780:  LSLA
LA781:  BCC  LA784                  ;IFCS
LA783:  CLRA                        ;NO ANGLE IF BAD DATA
LA784:  STA  7,X                    ;ANGLE TO PLAYER
LA786:  LDA  SI_RSX                 ;DETERMINE DIRECTION BASED ON PLAYERS MOTION
LA788:  EORA 6,X                    ;DIRECTION BUNKER LIES, + TO RIGHT
LA78A:  BPL  LA790                  ;IFMI  ?MOVING OPPOSITE OF BUNKER?
LA78C:  CLR  6,X                    ;THEN NORMAL ATTACK
LA78E:  BRA  LA7B2                  ;ELSE  ELSE CHECK SOME MORE
LA790:  LDA  SI_RSX
LA792:  BPL  LA795                  ;IFMI
LA794:  NEGA
LA795:  LSLA                        ;CONVERT TO ANGLE
LA796:  CMPA 7,X
LA798:  BHI  LA79E                  ;IFLS  ?SITE IS ON NEGATIVE SIDE OF BUNKER?
LA79A:  CLR  6,X                    ;THEN NORMAL ALSO
LA79C:  BRA  LA7B2                  ;ELSE
LA79E:  LDA  #$FF                   ;ELSE REVERSE ATTACK PREFERENCE
LA7A0:  STA  6,X
LA7A2:  LDX  TMPGRM
LA7A4:  LDA  GS_MOV,X               ;REVERSE MOVEMENT ALSO
LA7A6:  CMPA #MOVS_BR
LA7A8:  BNE  LA7AE                  ;IFEQ  BUNKER ON RIGHT
LA7AA:  LDA  #MOVS_BL               ;REPLACE WITH LEFT
LA7AC:  BRA  LA7B0                  ;ELSE
LA7AE:  LDA  #MOVS_BR               ;VICE-VERSA
LA7B0:  STA  GS_MOV,X
LA7B2:  JSR  AUDTL                  ;TOWER LAZARS
LA7B5:  RTS

;------------------------------------------------------------------------------
; FRWFGN - TOWER FIRES A FORWARD GUN
;------------------------------------------------------------------------------
FRWFGN:
LA7B6:  JSR  GNAVAIL
LA7B9:  LDA  #MOVS_WF
LA7BB:  STA  GS_MOV,X
LA7BD:  BRA  TOWRIN

;------------------------------------------------------------------------------
; FRWLGN - TOWER FIRES A LEFT GUN
;------------------------------------------------------------------------------
FRWLGN:
LA7BF:  JSR  GNAVAIL
LA7C2:  LDA  #MOVS_WL
LA7C4:  STA  GS_MOV,X
LA7C6:  BRA  TOWRIN

;------------------------------------------------------------------------------
; FRWRGN - TOWER FIRES A RIGHT GUN
;------------------------------------------------------------------------------
FRWRGN:
LA7C8:  JSR  GNAVAIL
LA7CB:  LDA  #MOVS_WR
LA7CD:  STA  GS_MOV,X
LA7CF:  BRA  TOWRIN

;------------------------------------------------------------------------------
; TOWRIN - INIT REST OF TOWER GUN
;------------------------------------------------------------------------------
TOWRIN:
LA7D1:  LDA  #$70
LA7D3:  STA  GS_TMR,X
LA7D5:  LDA  #TYPS_LV+TYPS_UN
LA7D7:  STA  GS_TYP,X
LA7D9:  LDU  S2_PRM
LA7DB:  LDX  GS_UVP,X
LA7DD:  LDA  ,U                     ;FORCE GROUND SHOTS ALWAYS TO FRONT
LA7DF:  SUBA MS_TX+M_S1             ;SHOT-ME, IF MINUS THEN FLIP ACTUAL LOC
LA7E2:  ANDA #$80                   ;JUST PLAY WITH SIGN BIT TO FLIP
LA7E4:  EORA ,U
LA7E6:  LDB  1,U
LA7E8:  STD  ,X
LA7EA:  LDD  2,U
LA7EC:  STD  2,X
LA7EE:  LDD  MS_TZ+M_U1             ;SHOOT IT ON LEVEL WITH PLAYER
LA7F1:  STD  4,X
LA7F3:  JSR  AUDTL                  ;TOWER LAZARS
LA7F6:  RTS

;------------------------------------------------------------------------------
; FRPLGN - LEFT PANEL FIRES A GUN
;------------------------------------------------------------------------------
FRPLGN:
LA7F7:  LDA  BS_PFL
LA7F9:  BEQ  LA800                  ;IFNE  ?EXHAUST PORT IN VIEW?
LA7FB:  JSR  GNAVAIL                ;THEN FIRE EVERYTHING
LA7FE:  BRA  LA803                  ;ELSE
LA800:  JSR  GNBSAVAIL              ;ELSE 3 GUNS MAX
LA803:  LDA  #MOVS_PL
LA805:  STA  GS_MOV,X
LA807:  LDU  GS_UVP,X
LA809:  BRA  PANLIN

;------------------------------------------------------------------------------
; FRPRGN - RIGHT PANEL FIRES A GUN
;------------------------------------------------------------------------------
FRPRGN:
LA80B:  LDA  BS_PFL
LA80D:  BEQ  LA814                  ;IFNE  ?EXHAUST PORT IN VIEW?
LA80F:  JSR  GNAVAIL                ;THEN FIRE EVERYTHING
LA812:  BRA  LA817                  ;ELSE
LA814:  JSR  GNBSAVAIL              ;ELSE 3 GUNS MAX
LA817:  LDA  #MOVS_PR
LA819:  STA  GS_MOV,X
LA81B:  LDU  GS_UVP,X
LA81D:  BRA  PANLIN

;------------------------------------------------------------------------------
; PANLIN - INIT REST OF PANEL GUN
;------------------------------------------------------------------------------
PANLIN:
LA81F:  LDD  M_X0
LA822:  STD  ,U                     ;X POSITION
LA824:  LDD  M_Y0
LA827:  STD  2,U                    ;Y POSITION
LA829:  LDD  M_Z0
LA82C:  STD  4,U                    ;Z POSITION
LA82E:  LDA  #$40
LA830:  STA  GS_TMR,X
LA832:  LDA  #TYPS_LV+TYPS_UN       ;ALIVE WITH UNIVERSE COORDS
LA834:  STA  GS_TYP,X
LA836:  LDA  P_RND1
LA839:  LSRA                        ;45 DEGREES
LA83A:  LDB  M_Z0
LA83D:  CMPB #$FC
LA83F:  BLT  LA843                  ;IFGE  ?TOP PANEL?
LA841:  LDA  #$00                   ;THEN JUST GO LEVEL
LA843:  STA  6,U                    ;Z ANGLE
LA845:  JSR  AUDTL                  ;USE TOWER LAZARS FOR NOW
LA848:  RTS

;------------------------------------------------------------------------------
; MVGUN - MOVE GUNS
;   MOVE THE GUNS, SHELLS, ETC.
;------------------------------------------------------------------------------
MVGUN:
LA849:  LDX  #GUN                   ;X--> GUN PACKETS
LA84C:  STX  GN_PTR                 ;---LOOP FOR EACH GUN
;X--> GUN PACKET
LA84E:  LDA  GS_TYP,X
LA850:  BEQ  LA861                  ;IFNE
LA852:  LDB  GS_MOV,X
LA854:  LSLB                        ;SAFELY FORM WORD POINTER
LA855:  CMPB #ZMOVE-TMOVE
LA857:  BHS  LA860                  ;IFLO
LA859:  LDU  #TMOVE
LA85C:  JSR  [B,U]                  ;DO THE APPROPRIATE MOVE ROUTINE
LA85E:  BRA  LA861                  ;ELSE  ELSE IS ERROR
LA860:  SWI                         ;TELL THE PROGRAMMER
LA861:  LDX  GN_PTR
LA863:  LEAX GS_IZE,X
LA865:  CMPX #GUNZ
LA868:  BLO  LA84C                  ;HSEND
LA86A:  RTS

;------------------------------------------------------------------------------
; MOVST - STAY IN PLACE
;------------------------------------------------------------------------------
MOVST:
LA86B:  DEC  GS_TMR,X
LA86D:  BGT  LA874                  ;IFLE
LA86F:  CLRB
LA870:  STB  GS_TYP,X
LA872:  STB  GS_TMR,X
LA874:  RTS

;------------------------------------------------------------------------------
; MOVAM - AIM AT PLAYER
;------------------------------------------------------------------------------
MOVAM:
LA875:  DEC  GS_TMR,X
LA877:  BGT  LA880                  ;IFLE
LA879:  CLRB
LA87A:  STB  GS_TYP,X
LA87C:  STB  GS_TMR,X
LA87E:  BRA  LA8A6                  ;ELSE
LA880:  LDU  GS_UVP,X               ;POINT TO MATH INFO
LA882:  LDD  #$0000                 ;CLRD
LA885:  SUBD ,U                     ;POS-(POS/4) TO HAVE IT BASHFUL TOWARDS PLAYER
LA887:  JSR  ASRD3
LA88A:  ADDD ,U                     ;X
LA88C:  STD  ,U
LA88E:  LDD  #$0000                 ;CLRD
LA891:  SUBD 2,U                    ;POS-(POS/4) TO HAVE IT BASHFUL TOWARDS PLAYER
LA893:  JSR  ASRD3
LA896:  ADDD 2,U                    ;Y
LA898:  STD  2,U
LA89A:  LDD  #$0000                 ;CLRD
LA89D:  SUBD 4,U                    ;POS-(POS/4) TO HAVE IT BASHFUL TOWARDS PLAYER
LA89F:  JSR  ASRD3
LA8A2:  ADDD 4,U                    ;Z
LA8A4:  STD  4,U
LA8A6:  RTS

;------------------------------------------------------------------------------
; MOVLV - LEAVE THE PLAYER
;------------------------------------------------------------------------------
MOVLV:
LA8A7:  DEC  GS_TMR,X
LA8A9:  BGT  LA8B2                  ;IFLE
LA8AB:  CLRB
LA8AC:  STB  GS_TYP,X
LA8AE:  STB  GS_TMR,X
LA8B0:  BRA  LA8D5                  ;ELSE
LA8B2:  LDU  GS_UVP,X               ;POINT TO MATH INFO
LA8B4:  LDD  ,U
LA8B6:  JSR  ASRD3
LA8B9:  ADDD ,U                     ;X
LA8BB:  BVS  MOVLV_80
LA8BD:  STD  ,U
LA8BF:  LDD  2,U
LA8C1:  JSR  ASRD3
LA8C4:  ADDD 2,U                    ;Y
LA8C6:  BVS  MOVLV_80
LA8C8:  STD  2,U
LA8CA:  LDD  4,U
LA8CC:  JSR  ASRD3
LA8CF:  ADDD 4,U                    ;Z
LA8D1:  BVS  MOVLV_80
LA8D3:  STD  4,U
LA8D5:  RTS

MOVLV_80:        ;WENT OUT OF VIEW
LA8D6:  CLRB
LA8D7:  STB  GS_TYP,X
LA8D9:  RTS

;------------------------------------------------------------------------------
; MOVWF - [note] Move routine MOVS_WF (tower forward gun), X-->gun packet: shot X - $100 (goto player), then TOWRMV
;------------------------------------------------------------------------------
MOVWF:
LA8DA:  LDU  GS_UVP,X
LA8DC:  LDD  #$FF00                 ;GOTO PLAYER
LA8DF:  ADDD ,U
LA8E1:  STD  ,U
LA8E3:  JMP  TOWRMV

;------------------------------------------------------------------------------
; MOVWL - [note] Move routine MOVS_WL (tower left gun), X-->gun packet: shot X - $100 and Y - $100, then TOWRMV
;------------------------------------------------------------------------------
MOVWL:
LA8E6:  LDU  GS_UVP,X
LA8E8:  LDD  #$FF00                 ;GOTO PLAYER
LA8EB:  ADDD ,U
LA8ED:  STD  ,U
LA8EF:  LDD  #$FF00
LA8F2:  ADDD 2,U
LA8F4:  STD  2,U
LA8F6:  JMP  TOWRMV

;------------------------------------------------------------------------------
; MOVWR - [note] Move routine MOVS_WR (tower right gun), X-->gun packet: shot X - $100 and Y + $100, then TOWRMV
;------------------------------------------------------------------------------
MOVWR:
LA8F9:  LDU  GS_UVP,X
LA8FB:  LDD  #$FF00                 ;GOTO PLAYER
LA8FE:  ADDD ,U
LA900:  STD  ,U
LA902:  LDD  #$0100
LA905:  ADDD 2,U
LA907:  STD  2,U
LA909:  JMP  TOWRMV

;------------------------------------------------------------------------------
; SLEWX - [note] Slew shot X, U-->shot position: B = high byte of shot X minus high byte of MS_TX+M_S1; if plus,
;   subtract 4*B from shot X
;------------------------------------------------------------------------------
SLEWX:
LA90C:  LDB  ,U
LA90E:  SUBB MS_TX+M_S1
LA911:  BMI  LA91F                  ;IFPL  MAKE SURE ITS OK
LA913:  CLRA
LA914:  JSR  LSLD2
LA917:  COMA                        ;NEGD
LA918:  NEGB
LA919:  SBCA #$FF
LA91B:  ADDD ,U
LA91D:  STD  ,U
LA91F:  RTS

;------------------------------------------------------------------------------
; SLWYL - SLEW Y SHOTS TO THE LEFT WITH PLAYER
;------------------------------------------------------------------------------
SLWYL:
LA920:  LDD  #$0000                 ;MATCH Y VELOCITY ALSO
LA923:  SUBD (MS_VY+M_S1)&$FFFF
LA926:  JSR  ASRD3
LA929:  ADDD (MS_VY+M_S1)&$FFFF
LA92C:  BPL  LA932                  ;IFMI  RIGHT BUNKER MOVES LEFT ONLY
LA92E:  ADDD 2,U
LA930:  STD  2,U
LA932:  RTS

;------------------------------------------------------------------------------
; SLWYR - SLEW Y SHOTS TO THE RIGHT WITH PLAYER
;------------------------------------------------------------------------------
SLWYR:
LA933:  LDD  #$0000                 ;MATCH Y VELOCITY ALSO
LA936:  SUBD (MS_VY+M_S1)&$FFFF
LA939:  JSR  ASRD3
LA93C:  ADDD (MS_VY+M_S1)&$FFFF
LA93F:  BMI  LA945                  ;IFPL  LEFT BUNKER SHOOTS TOWARDS RIGHT
LA941:  ADDD 2,U
LA943:  STD  2,U
LA945:  RTS

;------------------------------------------------------------------------------
; MOVBL - [note] Move routine MOVS_BL (left bunker gun), X-->gun packet: SLWYR and SLEWX, then slew shot Y toward a
;   point right of the player (fast to the right, slowly to the left) and move shot Z up toward the player
;------------------------------------------------------------------------------
MOVBL:
LA946:  LDU  GS_UVP,X
LA948:  JSR  SLWYR                  ;NORMAL LEFT BUNKER SLEWS RIGHT
LA94B:  JSR  SLEWX
LA94E:  LDD  ,U
LA950:  SUBD MS_TX+M_S1             ;DISTANCE FORWARDS
LA953:  LDB  7,U                    ;FRACTION FOR DIRECTION
LA955:  MUL
LA956:  TST  6,U
LA958:  BNE  LA95E                  ;IFEQ  NORMAL IS TO THE LEFT
LA95A:  COMA                        ;NEGD  TO PLAYERS LEFT
LA95B:  NEGB
LA95C:  SBCA #$FF
LA95E:  ADDD MS_TY+M_S1
LA961:  SUBD 2,U
LA963:  ADDD #$0100                 ;LEFT BUNKER SHOOTS FOR PLAYERS RIGHT
LA966:  BMI  LA978                  ;IFPL  ?AIMING RIGHT?
LA968:  JSR  ASRD3                  ;THIS IS LEFT BUNKERS PREFFERED DIRECTION
LA96B:  CMPD #$0180
LA96F:  BLE  LA974                  ;IFGT
LA971:  LDD  #$0180
LA974:  ADDD 2,U
LA976:  BRA  LA986                  ;ELSE  ELSE AIMING LEFT
LA978:  JSR  ASRD5                  ;GO SLOWLY
LA97B:  CMPD #$FE80
LA97F:  BGE  LA984                  ;IFLT
LA981:  LDD  #$FE80
LA984:  ADDD 2,U
LA986:  STD  2,U
LA988:  LDD  MS_TZ+M_S1
LA98B:  ADDD #$0100
LA98E:  SUBD 4,U
LA990:  BMI  LA9A2                  ;IFPL  ?AIMING UPWARD?
LA992:  JSR  ASRD3
LA995:  CMPD #$0200
LA999:  BLE  LA99E                  ;IFGT
LA99B:  LDD  #$0200
LA99E:  ADDD 4,U
LA9A0:  STD  4,U                    ;THEN MOVE THE GUN UP
LA9A2:  RTS

;------------------------------------------------------------------------------
; MOVBR - [note] Move routine MOVS_BR (right bunker gun), X-->gun packet: SLWYL and SLEWX, then slew shot Y toward a
;   point left of the player (fast to the left, slowly to the right) and move shot Z up toward the player
;------------------------------------------------------------------------------
MOVBR:
LA9A3:  LDU  GS_UVP,X
LA9A5:  JSR  SLWYL
LA9A8:  JSR  SLEWX
LA9AB:  LDD  ,U
LA9AD:  SUBD MS_TX+M_S1             ;DISTANCE FORWARDS
LA9B0:  LDB  7,U                    ;FRACTION FOR DIRECTION
LA9B2:  MUL
LA9B3:  TST  6,U
LA9B5:  BEQ  LA9BB                  ;IFNE  NORMAL IS RIGHT, REVERSED IS TO LEFT
LA9B7:  COMA                        ;NEGD
LA9B8:  NEGB
LA9B9:  SBCA #$FF
LA9BB:  ADDD MS_TY+M_S1             ;TO PLAYERS RIGHT
LA9BE:  ADDD #$FF00                 ;RIGHT BUNKER AIMS FOR PLAYERS LEFT
LA9C1:  SUBD 2,U
LA9C3:  BMI  LA9D5                  ;IFPL
LA9C5:  JSR  ASRD5                  ;THEN GO SLOW
LA9C8:  CMPD #$0180
LA9CC:  BLE  LA9D1                  ;IFGT
LA9CE:  LDD  #$0180
LA9D1:  ADDD 2,U
LA9D3:  BRA  LA9E3                  ;ELSE
LA9D5:  JSR  ASRD3                  ;SLEW FAST IN PREFERRED DIRECTION
LA9D8:  CMPD #$FE80
LA9DC:  BGE  LA9E1                  ;IFLT
LA9DE:  LDD  #$FE80
LA9E1:  ADDD 2,U
LA9E3:  STD  2,U
LA9E5:  LDD  MS_TZ+M_S1
LA9E8:  ADDD #$0100
LA9EB:  SUBD 4,U
LA9ED:  BMI  LA9FF                  ;IFPL  ?AIMING UPWARD?
LA9EF:  JSR  ASRD3
LA9F2:  CMPD #$0200
LA9F6:  BLE  LA9FB                  ;IFGT
LA9F8:  LDD  #$0200
LA9FB:  ADDD 4,U
LA9FD:  STD  4,U                    ;THEN MOVE THE GUN UP
LA9FF:  RTS

;------------------------------------------------------------------------------
; MOVBF - [note] Move routine, TMOVE entry BF, X-->gun packet: shot X - $100 (goto player), move shot Z up toward the
;   player (at most $180), then BNKRMV
;------------------------------------------------------------------------------
MOVBF:
LAA00:  LDU  GS_UVP,X
LAA02:  LDD  #$FF00                 ;GOTO PLAYER
LAA05:  ADDD ,U
LAA07:  STD  ,U
LAA09:  LDD  MS_TZ+M_S1
LAA0C:  ADDD #$0080
LAA0F:  SUBD 4,U
LAA11:  BMI  LAA23                  ;IFPL  ?AIMING UPWARD?
LAA13:  JSR  ASRD3
LAA16:  CMPD #$0180
LAA1A:  BLE  LAA1F                  ;IFGT
LAA1C:  LDD  #$0180
LAA1F:  ADDD 4,U
LAA21:  STD  4,U                    ;THEN MOVE THE GUN UP
LAA23:  BRA  PANLMV

;------------------------------------------------------------------------------
; MOVBLC - [note] As MOVBF but shot Y - $100 as well; nothing in the listing refers to this routine
;------------------------------------------------------------------------------
MOVBLC:
LAA25:  LDU  GS_UVP,X
LAA27:  LDD  #$FF00                 ;GOTO PLAYER
LAA2A:  ADDD ,U
LAA2C:  STD  ,U
LAA2E:  LDD  #$FF00
LAA31:  ADDD 2,U
LAA33:  STD  2,U
LAA35:  LDD  MS_TZ+M_S1
LAA38:  ADDD #$0080
LAA3B:  SUBD 4,U
LAA3D:  BMI  LAA4F                  ;IFPL  ?AIMING UPWARD?
LAA3F:  JSR  ASRD3
LAA42:  CMPD #$0180
LAA46:  BLE  LAA4B                  ;IFGT
LAA48:  LDD  #$0180
LAA4B:  ADDD 4,U
LAA4D:  STD  4,U                    ;THEN MOVE THE GUN UP
LAA4F:  BRA  PANLMV

;------------------------------------------------------------------------------
; MOVBRC - [note] As MOVBF but shot Y + $100 as well; nothing in the listing refers to this routine
;------------------------------------------------------------------------------
MOVBRC:
LAA51:  LDU  GS_UVP,X
LAA53:  LDD  #$FF00                 ;GOTO PLAYER
LAA56:  ADDD ,U
LAA58:  STD  ,U
LAA5A:  LDD  #$0100
LAA5D:  ADDD 2,U
LAA5F:  STD  2,U
LAA61:  LDD  MS_TZ+M_S1
LAA64:  ADDD #$0080
LAA67:  SUBD 4,U
LAA69:  BMI  LAA7B                  ;IFPL  ?AIMING UPWARD?
LAA6B:  JSR  ASRD3
LAA6E:  CMPD #$0180
LAA72:  BLE  LAA77                  ;IFGT
LAA74:  LDD  #$0180
LAA77:  ADDD 4,U
LAA79:  STD  4,U                    ;THEN MOVE THE GUN UP
LAA7B:  BRA  PANLMV

;------------------------------------------------------------------------------
; PANLMV - MOVE PANEL GUN
;   MOVE TOWER GUN
;   MOVE BUNKER GUN
;   (also: TOWRMV, BNKRMV)
;------------------------------------------------------------------------------
PANLMV:
TOWRMV:
BNKRMV:
LAA7D:  LDA  GS_TYP,X
LAA7F:  BITA #TYPS_PR               ;?IS THE SHOT ONLY PRETTY?(NO COLLISION CUZ PASSED PLAYER)
LAA81:  BEQ  LAA85                  ;IFNE
LAA83:  CLR  GS_TYP,X               ;THEN KILL IT
LAA85:  RTS

;------------------------------------------------------------------------------
; MOVPL - MOVE LEFT PANEL GUN
;------------------------------------------------------------------------------
MOVPL:
LAA86:  LDU  GS_UVP,X
LAA88:  JSR  SLEWX
LAA8B:  LDD  MS_TZ+M_S1
LAA8E:  SUBD 4,U
LAA90:  BMI  LAA99                  ;IFPL  ?NEED TO GO UP TO PLAYER?
LAA92:  JSR  ASRD4                  ;DO IT SLOWLY
LAA95:  ADDD 4,U
LAA97:  STD  4,U
LAA99:  LDA  WV_HRD
LAA9C:  CMPA #$01
LAA9E:  BLO  LAAA5                  ;IFHS  ?ON OR ABOVE THE FIRST WAVE?
LAAA0:  LDD  MS_TY+M_S1             ;THEN HEAT SEEK THE PLAYER
LAAA3:  BRA  LAAA8                  ;ELSE  ELSE
LAAA5:  LDD  #$FE80                 ;MOVE TO INSIDE OF SIDELINE
LAAA8:  SUBD 2,U                    ;GUN Y LOC
LAAAA:  BMI  LAAB3                  ;IFPL  LEFT GUNS ONLY MOVE TO RIGHT
LAAAC:  JSR  ASRD4                  ;REDUCE DOWN TO SMALL FRACTION OF DISTANCE
LAAAF:  ADDD 2,U
LAAB1:  STD  2,U
LAAB3:  BRA  PANLMV

;------------------------------------------------------------------------------
; MOVPR - MOVE RIGHT PANEL GUN
;------------------------------------------------------------------------------
MOVPR:
LAAB5:  LDU  GS_UVP,X
LAAB7:  JSR  SLEWX
LAABA:  LDD  MS_TZ+M_S1
LAABD:  SUBD 4,U
LAABF:  BMI  LAAC8                  ;IFPL  ?NEED TO GO UP TO PLAYER?
LAAC1:  JSR  ASRD4                  ;DO IT SLOWLY
LAAC4:  ADDD 4,U
LAAC6:  STD  4,U
LAAC8:  LDA  WV_HRD
LAACB:  CMPA #$01
LAACD:  BLO  LAAD4                  ;IFHS  ?ON OR ABOVE THE FIRST WAVE?
LAACF:  LDD  MS_TY+M_S1             ;THEN HEAT SEEK THE PLAYER
LAAD2:  BRA  LAAD7                  ;ELSE  ELSE
LAAD4:  LDD  #$0180                 ;MOVE TO INSIDE OF SIDELINE
LAAD7:  SUBD 2,U                    ;GUN Y LOC
LAAD9:  BPL  LAAE2                  ;IFMI  RIGHT GUNS ONLY MOVE TO LEFT
LAADB:  JSR  ASRD4                  ;REDUCE DOWN TO SMALL FRACTION OF DISTANCE
LAADE:  ADDD 2,U
LAAE0:  STD  2,U
LAAE2:  BRA  PANLMV

;------------------------------------------------------------------------------
; VWGUN - VIEW GUNS
;------------------------------------------------------------------------------
VWGUN:
LAAE4:  LDX  #GUN                   ;X--> GUN PACKETS

VWGUN_10:
LAAE7:  STX  GN_PTR
LAAE9:  LDA  GS_TYP,X
LAAEB:  LBEQ VWGUN_95               ;?GUN BEING USED?
LAAEF:  BITA #TYPS_GL               ;?GLOWING AGAINST OUR SHIELDS?
LAAF1:  BEQ  LAAF9                  ;IFNE
LAAF3:  JSR  GLOWVW                 ;THEN SHOW GUN AGAINST OUR SCREENS
LAAF6:  JMP  VWGUN_95               ;J
LAAF9:  BITA #TYPS_UN               ;?VIEW RELATIVE TO UNIVERSE?
LAAFB:  BEQ  LAB11                  ;IFNE
LAAFD:  LDD  MS_TX+M_S1             ;RESTORE DOWNLOADED UNIT VECTOR
LAB00:  STD  MS_TX+M_U1
LAB03:  LDD  MS_TY+M_S1
LAB06:  STD  MS_TY+M_U1
LAB09:  LDD  MS_TZ+M_S1
LAB0C:  STD  MS_TZ+M_U1
LAB0F:  BRA  LAB1D                  ;ELSE  ELSE RELATIVE TO PLAYER
LAB11:  LDD  #$0000                 ;CLRD
LAB14:  STD  MS_TX+M_U1             ;GUNS ARE RELATIVE TO PLAYER
LAB17:  STD  MS_TY+M_U1
LAB1A:  STD  MS_TZ+M_U1
LAB1D:  CLRA
LAB1E:  LDB  GS_BIC,X
LAB20:  STD  M_BIC
LAB23:  LDA  #MS_PSB2
LAB25:  JSR  MGOWT
LAB28:  LDD  M_XP                   ;X
LAB2B:  CMPD #$0001
LAB2F:  LBLE VWGUN_90
LAB33:  CMPD #$7F00
LAB37:  LBHI VWGUN_90
LAB3B:  STD  M_DVD
LAB3E:  STD  M_XT
LAB41:  LDD  M_YP
LAB44:  STD  M_YT
LAB47:  BPL  LAB4D                  ;IFMI
LAB49:  COMA                        ;NEGD
LAB4A:  NEGB
LAB4B:  SBCA #$FF
LAB4D:  SUBD M_XP
LAB50:  LBHS VWGUN_90
LAB54:  LDD  M_ZP
LAB57:  STD  M_ZT
LAB5A:  BPL  LAB60                  ;IFMI
LAB5C:  COMA                        ;NEGD
LAB5D:  NEGB
LAB5E:  SBCA #$FF
LAB60:  SUBD M_XP
LAB63:  LBHS VWGUN_90
;GUN SHOT IS VISIBLE
LAB67:  JSR  OBJCEN                 ;PROCESS CENTER OF GUNSHOT
LAB6A:  LDX  GN_PTR
LAB6C:  LDA  GS_TYP,X
LAB6E:  BITA #TYPS_LV+TYPS_PR       ;CAN ONLY HIT LIVE OR PRETTY SHOTS
LAB70:  BEQ  LABC0                  ;IFNE  ?ALLOWED TO HIT THIS SHOT?
LAB72:  LDD  #$0080                 ;FAT CHANCE OF COMPUTING THIS, TURNOFF GAS AND TEST IT
LAB75:  STD  M_YP
LAB78:  LDA  #MS_PERS
LAB7A:  JSR  MGOWT
LAB7D:  LDD  M_YP
LAB80:  ADDD #$000A                 ;SIZE OF CURSOR
LAB83:  STD  TMPSIZ
LAB85:  LDD  BJ_CX                  ;OBJECT CENTER
LAB87:  SUBD LZ_CX                  ;LAZAR CENTER
LAB89:  BPL  LAB8F                  ;IFMI
LAB8B:  COMA                        ;NEGD  ABSD
LAB8C:  NEGB
LAB8D:  SBCA #$FF
LAB8F:  STD  TMPOCT                 ;PREPARE FOR OCTAGON COLLISION DETECT
LAB91:  SUBD TMPSIZ
LAB93:  BGT  LABC0                  ;IFLE  LE FOR LIBERALITY
LAB95:  LDD  BJ_CY
LAB97:  SUBD LZ_CY                  ;NOW CHECKING Y COORDS
LAB99:  BPL  LAB9F                  ;IFMI
LAB9B:  COMA                        ;NEGD
LAB9C:  NEGB
LAB9D:  SBCA #$FF
LAB9F:  CMPD TMPSIZ
LABA2:  BGT  LABC0                  ;IFLE  ?WITHIN Y ALSO?
LABA4:  ADDD TMPOCT                 ;THEN ADD TO OCTAGON TEST
LABA6:  STD  TMPOCT
LABA8:  LDD  TMPSIZ
LABAA:  LSRA                        ;LSRD
LABAB:  RORB
LABAC:  ADDD TMPSIZ                 ;MAKE 1.5 FOR OCTAGON
LABAE:  SUBD TMPOCT
LABB0:  BLT  LABC0                  ;IFGE  ?ALSO WITHIN OCTAGON?
LABB2:  LDD  M_XT                   ;THEN SEE IF WE ARE THE CLOSEST ALIEN
LABB5:  CMPD CL_GDS                 ;GUN DISTANCE
LABB8:  BHS  LABC0                  ;IFLO  ?ALSO THE NEAREST GUN SO FAR?
LABBA:  STD  CL_GDS
LABBC:  LDX  GN_PTR                 ;THEN WE GOT A HIT
LABBE:  STX  CL_GP                  ;RECORD WHO WE ARE
LABC0:  LDA  GS_TYP,X
LABC2:  BITA #TYPS_LV
LABC4:  BEQ  VWGUN_50               ;IFNE  ?LIVE SHELL HAS COLLISIONS ALLOWED?
LABC6:  LDD  M_XT
LABC9:  LSLB                        ;LSLD  SCALE BACK UP TO REGULAR COORDS
LABCA:  ROLA
LABCB:  BMI  VWGUN_50
LABCD:  LDU  (MS_VX+M_S1)&$FFFF
LABD0:  CMPU #$0200
LABD4:  BLT  LABDB                  ;IFGE  ?PLAYER SHIP FAST ENUF?
LABD6:  SUBD (MS_VX+M_S1)&$FFFF     ;THEN USE ITS SPEED
LABD9:  BRA  LABDE                  ;ELSE  ELSE
LABDB:  SUBD #$0200                 ;MIN DISTANCE LEST SHOTS ARE TOO LARGE
LABDE:  BLE  VWGUN_40               ;B COLLISION IF WITHIN FORWARD MOVEMENT
LABE0:  SUBD #$0110                 ;MAX GUN SPEED PLUS FUDGE
LABE3:  BGT  VWGUN_50               ;IFLE  ?COLLISION DUE TO PLAYER SPEED OR GUN SPEED?

VWGUN_40:
LABE5:  LDD  BJ_CX                  ;CENTER OF GUNSHOT ON SCREEN
LABE7:  BMI  LABF0                  ;IFPL  ?RIGHT HALF OF SCREEN?
LABE9:  SUBD #VGCURR*4              ;+-128*4==>=-512 SCREEN COORDS
LABEC:  BGE  VWGUN_50               ;B EXIT IF NO CHANCE OF CURSOR HITTING IT
LABEE:  BRA  LABF5                  ;ELSE  ELSE CHECK LEFT SITE LIMIT
LABF0:  SUBD #VGCURL*4
LABF3:  BLE  VWGUN_50
LABF5:  LDD  BJ_CY                  ;CHECK UP/DOWN LIMITS
LABF7:  BMI  LAC00                  ;IFPL
LABF9:  SUBD #VGCURT*4              ;TOP LIMIT
LABFC:  BGE  VWGUN_50               ;B EXIT IF TOO HI TO HIT
LABFE:  BRA  LAC05                  ;ELSE  ELSE ON BOTTOM HALF OF SCREEN
LAC00:  SUBD #VGCURB*4
LAC03:  BLE  VWGUN_50               ;B NO COLLISION IF OUT OF SITE REACH
LAC05:  CMPX CL_GP                  ;?CAN WE HIT THIS GUN?
LAC07:  BNE  LAC14                  ;IFEQ
LAC09:  LDA  LZ_ON                  ;?AND LAZARS ARE ON?
LAC0B:  BEQ  LAC14                  ;IFNE
LAC0D:  JSR  GNHTSG                 ;THEN KILL THIS GUN NOW
LAC10:  LDX  GN_PTR                 ;SAFE RESTORE
LAC12:  BRA  VWGUN_50               ;AND NO MORE COLLIDE WITH SHIELDS
;ELSE IT SURELY HIT US
LAC14:  JSR  GNAHIT                 ;RECORD GUNS HIT ON OUR SHIELDS
LAC17:  LDD  #VGCNTR                ;CANCEL OUT THE OBJCENT ABOVE
LAC1A:  STD  ,Y++
LAC1C:  JSR  GLOWVW                 ;AND GLOW THE SHELL
LAC1F:  JMP  VWGUN_95               ;J DO NEXT SHELL

VWGUN_50:
LAC22:  JSR  GN1DRW                 ;DRAW GUN TYPE 2
LAC25:  BRA  VWGUN_95

VWGUN_90:        ;SHOT NOT VISIBLE
LAC27:  LDA  GS_TYP,X
LAC29:  BITA #TYPS_LV
LAC2B:  BEQ  LAC31                  ;IFNE
;;; LDA #TYP$PR ;REPLACE LIVE SHOT WITH PRETTY ONE(BUT A DUD)
LAC2D:  LDA  #$00                   ;KILL IT OFF FOR NOW
LAC2F:  BRA  LAC32                  ;ELSE
LAC31:  CLRA                        ;ELSE TURN SHOT OFF
LAC32:  STA  GS_TYP,X

VWGUN_95:        ;NEXT GUN SHOT
LAC34:  LDX  GN_PTR
LAC36:  LEAX GS_IZE,X
LAC38:  CMPX #GUNZ
LAC3B:  LBLO VWGUN_10
LAC3F:  LDD  MS_TX+M_S1             ;RESTORE DOWNLOADED UNIT VECTOR
LAC42:  STD  MS_TX+M_U1
LAC45:  LDD  MS_TY+M_S1
LAC48:  STD  MS_TY+M_U1
LAC4B:  LDD  MS_TZ+M_S1
LAC4E:  STD  MS_TZ+M_U1
LAC51:  RTS

;------------------------------------------------------------------------------
; GN1DRW - DRAW NORMAL GUN
;------------------------------------------------------------------------------
GN1DRW:
LAC52:  LDX  GN_PTR
;---DETERMINE SCALE
LAC54:  LDA  #$08                   ;MAX FOR BINARY SCALE
;CLOSEST IS 100,
LAC56:  STA  TMPBIN
LAC58:  LDD  M_XT

GN1DRW_10:       ;---LOOP FOR BINARY SCALE
LAC5B:  DEC  TMPBIN
LAC5D:  BEQ  GN1DRW_20
LAC5F:  LSLB
LAC60:  ROLA
LAC61:  BPL  GN1DRW_10
LAC63:  ANDA #$7F                   ;MAX FOR LINEAR SCALE

GN1DRW_20:
LAC65:  STA  TMPLIN
;DO THE FIREBALL
LAC67:  LDA  GS_TYP,X
LAC69:  ANDA #TYPS_HR               ;SHELL HURT?
LAC6B:  BNE  LAC7C                  ;IFEQ  NO, DO NORMAL SHELL
LAC6D:  LDA  TMPBIN                 ;USE CALCULATED SCALE FOR NORMAL SHELLS
LAC6F:  ORA  #(VGSCAL&$F000)/$100
LAC71:  LDB  TMPLIN
LAC73:  STD  ,Y++
LAC75:  LDD  #VJGNB                 ;JSR TO THE SPARKLER
LAC78:  STD  ,Y++
LAC7A:  BRA  LACA6                  ;ELSE  YES, SHELL HURT
;LIMIT SCALE FOR HURT SHOTS
LAC7C:  LDB  TMPLIN
LAC7E:  LDA  TMPBIN
LAC80:  INCA                        ;2 * SMALLER ( USING LARGER STAMPS )
LAC81:  CMPA #$03                   ;DON'T LET IT GET TOO LARGE
LAC83:  BHS  LAC8A                  ;IFLO  LIMIT IT
LAC85:  LDA  #$03                   ;BINARY OF THREE
LAC87:  CLRB                        ;LINEAR OF 0
LAC88:  BRA  LAC91                  ;ELSE
LAC8A:  CMPA #$06                   ;BUT MAKE SURE ITS VISIBLE FAR AWAY
LAC8C:  BLO  LAC91                  ;IFHS  LIMIT IT TO A MINIMUM SIZE
LAC8E:  LDA  #$06                   ;BINARY OF 6
LAC90:  CLRB                        ;LINEAR OF 0
LAC91:  ORA  #(VGSCAL&$F000)/$100
LAC93:  STD  ,Y++
LAC95:  LDB  GS_TMR,X               ;FADE USING TIMER
LAC97:  ASLB                        ;*16 FOR Z
LAC98:  ASLB
LAC99:  ASLB
LAC9A:  ASLB
LAC9B:  ORB  #$0F                   ;A LITTLE BRIGHTER
LAC9D:  LDA  #(VGCOLR/$100)+VGCPRP  ;MAKE IT PURPLE
LAC9F:  STD  ,Y++
LACA1:  LDD  #VJGNX                 ;EXPLOSION SPARKLER
LACA4:  STD  ,Y++
LACA6:  LDD  #VGSCAL
LACA9:  STD  ,Y++                   ;RESTORE SCALE
LACAB:  LDD  #VGCNTR                ;CENTER
LACAE:  STD  ,Y++

GN1DRW_90:
LACB0:  RTS

;------------------------------------------------------------------------------
; GLOWVW - THEN SHOW GUN AGAINST OUR SCREENS  (comment at the call)
;   AND GLOW THE SHELL  (another call)
;------------------------------------------------------------------------------
GLOWVW:
LACB1:  LDX  GN_PTR
LACB3:  LDU  GS_UVP,X               ;GET VECTOR TO FACEPLATE POSITION
LACB5:  LDD  ,U
LACB7:  STD  ,Y++
LACB9:  LDD  2,U
LACBB:  STD  ,Y++
LACBD:  LDA  GS_TMR,X               ;USE TIMER TO SETUP SIZE, USE 70C0 TO 7000
LACBF:  LDB  #$10                   ;MAX SCALE(SMALLEST SIZE)/TIMER
LACC1:  MUL
LACC2:  LDA  #(VGSCAL&$F000)/$100   ;MAKES IT A SCALE INSTRUCTION
LACC4:  STD  ,Y++
LACC6:  LDB  GS_TMR,X               ;NOW SET UP THE COLOR
LACC8:  ASLB                        ;BRIGHTNESS DEPENDS ON TIME
LACC9:  ASLB
LACCA:  ASLB
LACCB:  ASLB
LACCC:  LDA  #(VGCOLR/$100)+VGCWHT  ;ALWAYS WHITE
LACCE:  STD  ,Y++
LACD0:  LDD  #VJGNX                 ;JSR TO THE SPARKLER WITHOUT CENTER LINES
LACD3:  STD  ,Y++
LACD5:  LDD  #VGSCAL
LACD8:  STD  ,Y++                   ;RESTORE SCALE
LACDA:  LDD  #VGCNTR                ;CENTER
LACDD:  STD  ,Y++

GLOWVW_90:
LACDF:  RTS

;------------------------------------------------------------------------------
; GNAHIT - ALIEN GUN HIT PLAYER
;   X-->GUN BLOCK
;------------------------------------------------------------------------------
GNAHIT:
LACE0:  LDU  GS_UVP,X               ;* * * MUST FOLLOW OBJCENT * * *
;USES PREVIOUS VG INSTRUCTION
LACE2:  LDD  -$4,Y                  ;GET VECTOR TO FACEPLATE POSITION
LACE4:  STD  ,U
LACE6:  LDD  -$2,Y
LACE8:  STD  2,U
LACEA:  LDA  #TYPS_GL
LACEC:  STA  GS_TYP,X
LACEE:  LDA  #$0F
LACF0:  STA  GS_TMR,X               ;SHOW SHELL DISSOLVING
LACF2:  LDA  #MOVS_ST               ;SHELL STAYS IN PLACE
LACF4:  STA  GS_MOV,X
LACF6:  JSR  BG1GLW
LACF9:  LDA  S_ROL
LACFB:  BNE  LAD00                  ;IFEQ  ?NO CURRENT DIRECTION?
LACFD:  LDA  P_RND1                 ;THEN CHOOSE WHICH WAY
LAD00:  LDB  #$20                   ;AMOUNT TO ROLL
LAD02:  TSTA                        ;CHECK CURRENT DIRECTION
LAD03:  BPL  LAD06                  ;IFMI
LAD05:  NEGB
LAD06:  STB  S_ROL                  ;ROLL US IN RESPONSE
LAD08:  JSR  AUDSH                  ;SOUND OUR BEING HIT BY A GUN
LAD0B:  LDA  Q_GHIT                 ;GUN HIT FIRST TIME
LAD0E:  BNE  LAD1F                  ;IFEQ  ?FIRST TIME?
LAD10:  INC  Q_GHIT
LAD13:  LDA  S_GAS
LAD15:  CMPA #$03
LAD17:  BLS  LAD1F                  ;IFHI  ONLY IF GAS WILL BE 3 OR 4 ON UP
LAD19:  JSR  SPKHIT                 ;IM HIT BUT NOT BAD, R2 SEE WHAT YOU CAN DO
LAD1C:  JSR  AUDRS                  ;R2 SHAVE
LAD1F:  RTS

;------------------------------------------------------------------------------
; GNHTSG - SPACE LAZAR HIT ALIEN GUN
;   PROTON HIT BASE GUN
;   CL.GP-->GUN BLOCK
;   (also: PTHTBG)
;------------------------------------------------------------------------------
GNHTSG:
PTHTBG:
LAD20:  LDU  CL_GP                  ;U-->ALIEN GUN
LAD22:  LDA  GS_TYP,U
LAD24:  BEQ  LAD3D                  ;IFNE  ?SHOT ALIVE?
LAD26:  ANDA #TYPS_UN               ;KEEP IT ON UNIVERSAL COORDS
LAD28:  ORA  #TYPS_HR               ;MAKE IT HURT
LAD2A:  STA  GS_TYP,U
LAD2C:  LDA  #$0F                   ;FADE TIMER
LAD2E:  STA  GS_TMR,U
LAD30:  LDA  #MOVS_ST               ;MAKE SHELL 'STAY' IN PLACE
LAD32:  STA  GS_MOV,U
LAD34:  JSR  AUDTCZ                 ;TIE FIGHTER CANNON STOPPED
LAD37:  JSR  SCRSHT                 ;SCORE OUR SHOT
LAD3A:  JSR  AUDSS                  ;HIT ALIEN SHOT
LAD3D:  RTS

;------------------------------------------------------------------------------
; FRPTGN - PTGUN - PLAYERS PROTON TORPEDO GUN
;------------------------------------------------------------------------------
FRPTGN:
LAD3E:  LDA  #$01
LAD40:  STA  PT_LIV                 ;PT IS ALIVE
LAD42:  LDD  MS_TX+M_S1
LAD45:  ADDD #$0100                 ;JUST A BIT IN FRONT
LAD48:  STD  PT_X
LAD4A:  LDD  MS_TY+M_S1
LAD4D:  STD  PT_Y
LAD4F:  LDD  MS_TZ+M_S1
LAD52:  STD  PT_Z
LAD54:  LDX  #GUN
LAD57:  STX  CL_GP                  ;GUN POINTER
LAD59:  JSR  PTHTBG                 ;PROTON HITS BASE GUN
LAD5C:  LDX  CL_GP
LAD5E:  LEAX GS_IZE,X
LAD60:  CMPX #GUNZ                  ;DONE?
LAD63:  BLO  LAD57                  ;HSEND
LAD65:  JSR  PMSF2                  ;SOUND THE DEATH KNELL
LAD68:  JSR  AUDPH                  ;OTHER POKEY ASSIST TO PROTONING PORTHOLE
LAD6B:  RTS

;------------------------------------------------------------------------------
; MVPTGN - PLAYERS PROTON TORP GUN  (comment at the call)
;------------------------------------------------------------------------------
MVPTGN:
LAD6C:  LDA  PT_LIV
LAD6E:  BEQ  LADAE                  ;IFNE  ?PT ALIVE?
LAD70:  LDD  PT_X
LAD72:  ADDD #$0300                 ;MOVE FORWARD AHEAD OF SHIP
LAD75:  ADDD (MS_VX+M_S1)&$FFFF
LAD78:  CMPD BS_PLC
LAD7B:  BMI  LAD7F                  ;IFPL  ?BEYOND PORTHOLE LOCATION?(NOTE WRAPAROUND)
LAD7D:  LDD  BS_PLC                 ;THEN STOP ABOVE PORTHOLE
LAD7F:  STD  PT_X
LAD81:  LDD  BS_PLC
LAD83:  SUBD PT_X                   ;FORWARD DISTANCE TO HOLE
LAD85:  SUBD #$1000                 ;GET UPWARD DISTANCE FROM BOTTOM HOLE
LAD88:  CMPD PT_Z
LAD8B:  BGE  LAD8F                  ;IFLT
LAD8D:  STD  PT_Z                   ;WHEN PROTON TORP IS CLOSE, ANGLE INTO HOLE
LAD8F:  LDD  BS_PLC
LAD91:  SUBD PT_X                   ;FORWARD DISTANCE TO HOLE
LAD93:  JSR  ASRD4                  ;(BUT ALWAYS A POSITIVE RESULT)
LAD96:  TST  PT_Y
LAD98:  BMI  LADA3                  ;IFPL  ?Y TO RIGHT OF MIDLINE?
LAD9A:  CMPD PT_Y
LAD9D:  BGE  LADA1                  ;IFLT  ?DOES GLIDE SLOPE SAY GET CLOSER?
LAD9F:  STD  PT_Y
LADA1:  BRA  LADAE                  ;ELSE  ELSE Y TO LEFT OF MIDLINE
LADA3:  COMA                        ;NEGD
LADA4:  NEGB
LADA5:  SBCA #$FF
LADA7:  CMPD PT_Y
LADAA:  BLE  LADAE                  ;IFGT  ?IS GLIDE SLOPE CLOSER TO MIDLINE?
LADAC:  STD  PT_Y                   ;THEN PUT SHOTS THERE
LADAE:  RTS

;------------------------------------------------------------------------------
; VWPTGN - VIEW PLAYERS PROTON TORPEDO
;------------------------------------------------------------------------------
VWPTGN:
LADAF:  LDA  PT_LIV
LADB1:  BEQ  LADD3                  ;IFNE  ?PLAYER TORP ALIVE?
LADB3:  LDD  PT_X                   ;THEN SETUP COORDS
LADB5:  STD  M_X0
LADB8:  LDD  PT_Y
LADBA:  ADDD #$0080
LADBD:  STD  M_Y0
LADC0:  LDD  PT_Z
LADC2:  STD  M_Z0
LADC5:  JSR  PTVW
LADC8:  LDD  PT_Y
LADCA:  SUBD #$0080                 ;DO LEFT PROTON TORP NOW
LADCD:  STD  M_Y0
LADD0:  JSR  PTVW
LADD3:  RTS

;------------------------------------------------------------------------------
; PTVW - VIEW A SINGLE TORP IN M.X0
;------------------------------------------------------------------------------
PTVW:
LADD4:  LDD  #MS_X0BC               ;TRANSFORM CENTER POINT
LADD7:  STD  M_BIC
LADDA:  LDA  #MS_PSB2
LADDC:  JSR  MGOWT
LADDF:  LDD  M_XP                   ;CHECK TO SEE IF HOLE HAS BEEN PASSED
LADE2:  SUBD #$E000                 ;CHECK FOR WELL PAST HOLE(AND OUT IN SPACE USUALLY)
LADE5:  BGT  LADEB                  ;IFLE  ?PLAYER PAST HOLE?
LADE7:  LDA  #$00
LADE9:  STA  PT_LIV                 ;THEN TURN OFF PROTON TORPS
LADEB:  LDD  M_XP
LADEE:  CMPD #$0001
LADF2:  BLT  LAE5F                  ;IFGE  ?FAR ENUF IN FRONT?
LADF4:  STD  M_DVD
LADF7:  STD  M_XT
LADFA:  LDD  M_YP
LADFD:  BPL  LAE03                  ;IFMI
LADFF:  COMA                        ;NEGD  ABSOLUTE VALUE
LAE00:  NEGB
LAE01:  SBCA #$FF
LAE03:  SUBD M_XP
LAE06:  BGE  LAE5F                  ;IFLT  ?Y IN FRONT VIEW?
LAE08:  LDD  M_ZP
LAE0B:  BPL  LAE11                  ;IFMI
LAE0D:  COMA                        ;NEGD  ABSOLUTE VALUE
LAE0E:  NEGB
LAE0F:  SBCA #$FF
LAE11:  SUBD M_XP
LAE14:  BGE  LAE5F                  ;IFLT  ?Z IN FRONT VIEW?
LAE16:  LDD  M_QUO
LAE19:  STD  M_XP
LAE1C:  LDA  #MS_PERS               ;PERSPECTIVE MULTIPLY
LAE1E:  JSR  MGOWT
LAE21:  LDD  M_ZP                   ;GET TO PROPER PLACE ON SCREEN
LAE24:  ADDD #VGOFFY
LAE27:  ANDA #$1F
LAE29:  STD  ,Y++
LAE2B:  LDD  M_YP
LAE2E:  ANDA #$1F
LAE30:  STD  ,Y++
LAE32:  LDD  #((VGCTRQ*$100)+VGCOPC)|$FF ;BRITE TURQOISE SHOTS
LAE35:  STD  ,Y++
;---DETERMINE SCALE
LAE37:  LDA  #$06                   ;MAX FOR BINARY SCALE
;MAX 0 IS AT 200
LAE39:  STA  TMPBIN
LAE3B:  LDD  M_XT

PTVW_10:         ;---LOOP FOR BINARY SCALE
LAE3E:  DEC  TMPBIN
LAE40:  BEQ  PTVW_20
LAE42:  LSLB
LAE43:  ROLA
LAE44:  BPL  PTVW_10
LAE46:  ANDA #$7F                   ;MAX FOR LINEAR SCALE

PTVW_20:
LAE48:  LDB  TMPBIN
LAE4A:  ORB  #$70                   ;SCALE INSTRUCTION
LAE4C:  STB  ,Y+
LAE4E:  STA  ,Y+
LAE50:  LDD  #VJGNT
LAE53:  STD  ,Y++
LAE55:  LDD  #VGSCAL
LAE58:  STD  ,Y++
LAE5A:  LDD  #VGCNTR
LAE5D:  STD  ,Y++
LAE5F:  RTS

;==============================================================================
; MODULE WSLAZR   WSLAZR.MAC
;   LAZARS
;==============================================================================

;------------------------------------------------------------------------------
; TSTLAZ - LASAR -- S1LAZ,MVLAZ,VWLAZ,CL1LAZ
;   TEST IF LAZARS SHOULD BE ON IN MAINLINE
;   >0 ==> STICK LASAR ONTO HIT FOR A WHILE
;   <0 ==> GLANCED OFF, NOT STUCK
;------------------------------------------------------------------------------
TSTLAZ:
LAE60:  LDA  LZ_HIT                 ;CHECK IF A HIT HAS OCCURRED LAST FRAME
LAE62:  BLE  LAE6E                  ;IFGT
LAE64:  DEC  LZ_HIT                 ;TIME IT OUT
LAE66:  LDA  #$00
LAE68:  STA  LZ_EDG                 ;LAZAR FREEZES IN POSITION
LAE6A:  STA  LZ_ON                  ;AND NO SHOW REGULAR LAZARS
LAE6C:  BRA  LAE72                  ;ELSE
LAE6E:  LDA  #$00
LAE70:  STA  LZ_HIT
LAE72:  LDA  #$00
LAE74:  STA  LZ_ON                  ;AND STOP ALL LAZARS
LAE76:  ORCC #$10                   ;SEI  ***PREVENT POSSIBLE IRQ/MAINLINE INTERACTIONS
LAE78:  LDA  VG_LON                 ;GET ON SWITCH FROM IRQ
LAE7A:  BEQ  LAE87                  ;IFNE
LAE7C:  INC  LZ_ALT                 ;EDGED ALTERNATION
LAE7F:  CLR  LZ_HIT                 ;STOP THE HIT PICTURE, ALLOW SWEEPING LAZARS
LAE81:  LDB  #$08
LAE83:  STB  LZ_EDG
LAE85:  CLR  VG_LON                 ;PREPARE IRQ FOR NEXT MAINLINE
LAE87:  LDA  LZ_EDG
LAE89:  BLE  LAE9F                  ;IFGT  ?HAVE AN EDG TO DETECT?
LAE8B:  DEC  LZ_EDG
LAE8D:  STA  LZ_ON                  ;TURN ON LAZARS TOO
LAE8F:  LDD  VG_RSX                 ;16 BIT REAL SITE VALUE, FOR LAZAR
LAE91:  STD  LZ_RSX
LAE93:  LDD  VG_RSY
LAE95:  STD  LZ_RSY
LAE97:  LDD  VG_CX                  ;10 BIT CURRENT SITE VALUE, FOR LAZAR
LAE99:  STD  LZ_CX
LAE9B:  LDD  VG_CY
LAE9D:  STD  LZ_CY
LAE9F:  ANDCC #$EF                  ;CLI  ***REALLOW INTERFERENCE
LAEA1:  LDA  LZ_EDG
LAEA3:  CMPA #$07                   ;CHEAP DETECT OF EVERY EDGE
LAEA5:  BNE  LAEB2                  ;IFEQ
LAEA7:  LDA  Q_FRC
LAEAA:  BNE  LAEAF                  ;IFEQ  ?WAS TRYING TO USE THE FORCE?
LAEAC:  DEC  Q_FRC                  ;THEN NO MORE USING THE FORCE
LAEAF:  JSR  AUDXL                  ;START XWING LASAR
LAEB2:  LDA  #$FF                   ;SETUP FOR COLLISION, NONE YET
LAEB4:  STA  CL_ADS                 ;ALIEN DISTANCE NEGATIVE (NONE YET)
LAEB6:  STA  CL_BDS                 ;BUNKER
LAEB8:  STA  CL_GDS                 ;GUN
LAEBA:  STA  CL_TDS                 ;TOWER
LAEBC:  RTS

;------------------------------------------------------------------------------
; VWLAZ - VWLAZ:: VIEW LAZARS
;   VIEW ANY LASARS
;------------------------------------------------------------------------------
VWLAZ:
LAEBD:  LDA  LZ_ON
LAEBF:  ORA  LZ_HIT                 ;?OR HIT IN PROGRESS?
LAEC1:  BNE  VWLAZ_5                ;B ?LAZARS OFF?
LAEC3:  RTS

VWLAZ_5:         ;---ELSE DO THEM
LAEC4:  LDA  LZ_ALT
LAEC7:  ANDA #$01                   ;FIRE SWITCH EDGE?
LAEC9:  BEQ  LAF25                  ;IFNE  YES, FIRE LEFT LAZARS
;VIEW UPPER LEFT LAZAR
LAECB:  LDD  #VGOFFY+0              ;Y COORD FOR START UPPER LAZAR
LAECE:  ADDD LZ_GY                  ;GUNS SHIFT AROUND
LAED1:  ANDA #$1F                   ;OPCODE
LAED3:  STD  ,Y++
LAED5:  LDD  LZ_CY
LAED7:  SUBD #$0000
LAEDA:  SUBD LZ_GY
LAEDD:  STD  TMPDY                  ;DELTA LEFT TO DRAW
LAEDF:  LDD  #VGLIML+90             ;X COORD FOR START LEFT LAZAR
LAEE2:  ADDD LZ_GX
LAEE5:  ANDA #$1F                   ;NO BRITE
LAEE7:  STD  ,Y++
LAEE9:  LDD  LZ_CX                  ;VG, 10BIT CURRENT SITE POSITION
LAEEB:  SUBD #VGLIML+90
LAEEE:  SUBD LZ_GX
LAEF1:  STD  TMPDX                  ;DELTA LEFT TO DRAW
LAEF3:  LDB  #$00                   ;OFFSET INTO COLORS(POM-POM GUN)
LAEF5:  JSR  LAZVW
;VIEW LOWER LEFT LAZAR
LAEF8:  LDD  #VGLIMB+35             ;Y COORD FOR START LOWER LAZAR
LAEFB:  ADDD LZ_GY                  ;GUNS SHIFT AROUND
LAEFE:  ANDA #$1F                   ;OPCODE
LAF00:  STD  ,Y++
LAF02:  LDD  LZ_CY
LAF04:  SUBD #(VGLIMB-VGOFFY)+35
LAF07:  SUBD LZ_GY
LAF0A:  STD  TMPDY                  ;DELTA LEFT TO DRAW
LAF0C:  LDD  #VGLIML+85             ;X COORD FOR START LEFT LAZAR
LAF0F:  ADDD LZ_GX
LAF12:  ANDA #$1F                   ;NO BRITE
LAF14:  STD  ,Y++
LAF16:  LDD  LZ_CX                  ;VG, 10BIT CURRENT SITE POSITION
LAF18:  SUBD #VGLIML+85
LAF1B:  SUBD LZ_GX
LAF1E:  STD  TMPDX                  ;DELTA LEFT TO DRAW
LAF20:  LDB  #$08                   ;OFFSET INTO COLORS(POM-POM GUN)
LAF22:  JSR  LAZVW
LAF25:  LDA  LZ_ALT
LAF28:  ANDA #$01                   ;FIRE SWITCH EDGE?
LAF2A:  BNE  LAF86                  ;IFEQ  YES, SHOOT THEM WITH THE RIGHT SIDE
;VIEW LOWER RIGHT LAZAR
LAF2C:  LDD  #VGLIMB+35             ;Y COORD FOR START LOWER LAZAR
LAF2F:  ADDD LZ_GY                  ;GUNS SHIFT AROUND
LAF32:  ANDA #$1F                   ;OPCODE
LAF34:  STD  ,Y++
LAF36:  LDD  LZ_CY
LAF38:  SUBD #(VGLIMB-VGOFFY)+35
LAF3B:  SUBD LZ_GY
LAF3E:  STD  TMPDY                  ;DELTA LEFT TO DRAW
LAF40:  LDD  #VGLIMR-85             ;X COORD FOR START RIGHT LAZAR
LAF43:  ADDD LZ_GX
LAF46:  ANDA #$1F                   ;NO BRITE
LAF48:  STD  ,Y++
LAF4A:  LDD  LZ_CX                  ;VG, 10BIT CURRENT SITE POSITION
LAF4C:  SUBD #VGLIMR-85
LAF4F:  SUBD LZ_GX
LAF52:  STD  TMPDX                  ;DELTA LEFT TO DRAW
LAF54:  LDB  #$00                   ;OFFSET INTO COLORS(POM-POM GUN)
LAF56:  JSR  LAZVW
;VIEW UPPER RIGHT LAZAR
LAF59:  LDD  #VGOFFY+0              ;Y COORD FOR START UPPER LAZAR
LAF5C:  ADDD LZ_GY                  ;GUNS SHIFT AROUND
LAF5F:  ANDA #$1F                   ;OPCODE
LAF61:  STD  ,Y++
LAF63:  LDD  LZ_CY
LAF65:  SUBD #$0000
LAF68:  SUBD LZ_GY
LAF6B:  STD  TMPDY                  ;DELTA LEFT TO DRAW
LAF6D:  LDD  #VGLIMR-90             ;X COORD FOR START RIGHT LAZAR
LAF70:  ADDD LZ_GX
LAF73:  ANDA #$1F                   ;NO BRITE
LAF75:  STD  ,Y++
LAF77:  LDD  LZ_CX                  ;VG, 10BIT CURRENT SITE POSITION
LAF79:  SUBD #VGLIMR-90
LAF7C:  SUBD LZ_GX
LAF7F:  STD  TMPDX                  ;DELTA LEFT TO DRAW
LAF81:  LDB  #$08                   ;OFFSET INTO COLORS(POM-POM GUN)
LAF83:  JSR  LAZVW
LAF86:  RTS

;------------------------------------------------------------------------------
; LAZVW - ---VECTOR TO LAZAR SITE AND DISPLAY
;------------------------------------------------------------------------------
LAZVW:
LAF87:  LDU  #TLZFR                 ;FULL FIRE COLORS
LAF8A:  LEAU B,U                    ;ADD OFFSET TO COLORS
LAF8C:  LDA  LZ_HIT
LAF8E:  BLE  LAF9A                  ;IFGT  ?HIT SOMETHING IMPORTANT?
LAF90:  LDB  #$3F                   ;SPREAD OUT HIT COUNT INTO FULL BRITE
LAF92:  MUL                         ;RESULT BRITE IN B
LAF93:  LDA  #((VGCTRQ*$100)+VGCOPC)/$100 ;USED LAZAR GOES BRITE TO DIM
LAF95:  STD  ,Y++
LAF97:  JMP  LAZVW_88
LAF9A:  LDX  #LZPNT                 ;FIRST ENTRY

LAZVW_20:
LAF9D:  LDD  ,U++                   ;PULL THE APPROPRIATE COLOR
LAF9F:  STD  ,Y++
LAFA1:  LDD  TMPDY                  ;CURRENT DELTA TO SITE
LAFA3:  BMI  LAZVW_22
LAFA5:  ADDD #$0001                 ;ROUND POSITIVE UP

LAZVW_22:
LAFA8:  ASRA
LAFA9:  RORB                        ;DIVIDE BY 2
LAFAA:  STD  ,Y                     ;TEMP SAVE
LAFAC:  COMA                        ;NEGD
LAFAD:  NEGB
LAFAE:  SBCA #$FF
LAFB0:  ADDD TMPDY                  ;REDUCE ORIGINAL APPROPRIATE AMOUNT
LAFB2:  STD  TMPDY
LAFB4:  LDD  ,Y                     ;GET Y PORTION AGAIN
LAFB6:  ANDA #$1F
LAFB8:  STD  ,Y++                   ;AND VECTORIZE Y
LAFBA:  LDD  TMPDX                  ;CURRENT DELTA TO SITE
LAFBC:  BMI  LAZVW_26
LAFBE:  ADDD #$0001                 ;ROUND POSITIVE UP

LAZVW_26:
LAFC1:  ASRA
LAFC2:  RORB                        ;DIVIDE BY 2
LAFC3:  STD  ,Y                     ;TEMP SAVE
LAFC5:  COMA                        ;NEGD
LAFC6:  NEGB
LAFC7:  SBCA #$FF
LAFC9:  ADDD TMPDX                  ;REDUCE ORIGINAL APPROPRIATE AMOUNT
LAFCB:  STD  TMPDX
LAFCD:  LDD  ,Y                     ;GET X PORTION AGAIN
LAFCF:  ORA  #$E0                   ;DEFAULT BRITE
LAFD1:  STD  ,Y++                   ;AND VECTORIZE X
LAFD3:  LDD  TMPDX                  ;KEEP GOING TILL WE ARRIVE AT SITE
LAFD5:  ADDD #$0008
LAFD8:  BLT  LAZVW_20               ;RELOOP IF <-8
LAFDA:  SUBD #$0010
LAFDD:  BGT  LAZVW_20               ;RELOOP IF DX>8
LAFDF:  LDD  TMPDY
LAFE1:  ADDD #$0008
LAFE4:  BLT  LAZVW_20               ;RELOOP IF <-8
LAFE6:  SUBD #$0010
LAFE9:  BGT  LAZVW_20               ;RELOOP IF DY>8
LAFEB:  LDD  ,U++
LAFED:  STD  ,Y++                   ;SETUP APPROPRIATE COLOR

LAZVW_88:        ;---DISPLAY REST OF LAZAR LINE
LAFEF:  LDD  TMPDY
LAFF1:  ANDA #$1F
LAFF3:  STD  ,Y++
LAFF5:  LDD  TMPDX
LAFF7:  ORA  #$E0                   ;BRITE
LAFF9:  STD  ,Y++
LAFFB:  LDA  LZ_HIT
LAFFD:  BLE  LB006                  ;IFGT  ?HIT SOMETHING?
LAFFF:  LDD  #VJLZS                 ;SHOW LAZAR SPLASH
LB002:  STD  ,Y++
LB004:  BRA  LB044                  ;ELSE
LB006:  BGE  LB044                  ;IFLT  ?OR SPLASHING AGAINST SOMETHING?
LB008:  LDB  SP_LOC                 ;X DISTANCE, USE TO SCALE
LB00B:  LDA  #((VGSCAL-$100)&$FF00)/$100 ;MAKE IT A SCALE INSTRUCTION
;LARGER PLEASE
LB00D:  STD  ,Y++
LB00F:  LDD  SP_COL                 ;COLOR, DEPENDS ON WHAT WAS HIT
LB012:  STD  ,Y++
LB014:  LDA  SP_TYP                 ;QUADRANT DATA
LB017:  ANDA #$01                   ;UP-RIGHT?
LB019:  BEQ  LB020                  ;IFNE  YES
LB01B:  LDD  #VJSPUR
LB01E:  STD  ,Y++
LB020:  LDA  SP_TYP
LB023:  ANDA #$02                   ;UP-LEFT?
LB025:  BEQ  LB02C                  ;IFNE  YES
LB027:  LDD  #VJSPUL
LB02A:  STD  ,Y++
LB02C:  LDA  SP_TYP
LB02F:  ANDA #$04                   ;DOWN-LEFT?
LB031:  BEQ  LB038                  ;IFNE  YES
LB033:  LDD  #VJSPDL
LB036:  STD  ,Y++
LB038:  LDA  SP_TYP
LB03B:  ANDA #$08                   ;DOWN-RIGHT?
LB03D:  BEQ  LB044                  ;IFNE  YES
LB03F:  LDD  #VJSPDR
LB042:  STD  ,Y++
LB044:  LDD  #VGSCAL                ;RESTORE SCALE
LB047:  STD  ,Y++
LB049:  LDD  #VGCNTR                ;CENTER
LB04C:  STD  ,Y++
LB04E:  RTS

TLZFR:           ;COLORS FOR LAZAR FIRE
LB04F:  .word VJLZF0                ;.IRP .A,<0,1,2,3,4,5,6,7,8,9,A,B,C,D,E,F>
LB051:  .word VJLZF1
LB053:  .word VJLZF2
LB055:  .word VJLZF3
LB057:  .word VJLZF4
LB059:  .word VJLZF5
LB05B:  .word VJLZF6
LB05D:  .word VJLZF7
LB05F:  .word VJLZF8
LB061:  .word VJLZF9
LB063:  .word VJLZFA
LB065:  .word VJLZFB
LB067:  .word VJLZFC
LB069:  .word VJLZFD
LB06B:  .word VJLZFE
LB06D:  .word VJLZFF
LB06F:  .word VJLZF0                ;.IRP .A,<0>  A BIT EXTRA FOR SAFETY(MAX LENGTH SHOULD BE 8+8)

;------------------------------------------------------------------------------
; CLBLZ - CLBLZ -- COLLIDE WITH BASE LAZAR
;   COLLIDE WITH LAZAR, BASE STAR TRENCH
;------------------------------------------------------------------------------
CLBLZ:
LB071:  LDA  LZ_ON
LB073:  BEQ  LB094                  ;IFNE  ?LAZARS ON?
LB075:  JSR  CLBLZ_10
LB078:  LDD  #$0200                 ;AND IN TYPICAL NON-STRUCTURED MANNER,
LB07B:  STD  M_DVN                  ;RESTORE DIVIDER
LB07E:  LDD  CL_GDS                 ;CHECK THE GUNS ALSO
LB080:  BMI  LB089                  ;IFPL  ?GOT A GUN?
LB082:  LDA  #$04
LB084:  STA  LZ_HIT
LB086:  JSR  GNHTSG                 ;ALWAYS HIT A GUN SINCE NO DISTANCE CLUE
LB089:  LDA  PT_LZF                 ;PROTON TORP LAZAR FLAG
LB08B:  BLE  LB094                  ;IFGT  ?LAZAR GOT CLOSE ENUF TO FIRE PROTON TORPS?
LB08D:  LDA  #$FF
LB08F:  STA  PT_LZF                 ;MARK THAT PROTON TORP HAS FIRED
LB091:  JSR  FRPTGN                 ;THEN LAUNCH DIRECT HIT PROTON TORPS
LB094:  RTS                         ;EXIT

CLBLZ_10:
LB095:  LDD  #$7000                 ;FARTHEST FORWARD POINT
LB098:  ADDD MS_TX+M_U1
LB09B:  STD  TMPTX
LB09D:  LDD  #$0000
LB0A0:  SUBD LZ_RSX                 ;LEFT/RIGHT
LB0A2:  JSR  ASRD3
LB0A5:  ADDD LZ_RSX                 ;(8X-1X) FOR 7000 MAX
LB0A7:  ADDD MS_TY+M_U1
LB0AA:  STD  TMPTY                  ;LEFT/RIGHT
LB0AC:  LDD  #$0000
LB0AF:  SUBD LZ_RSY                 ;UP/DOWN
LB0B1:  JSR  ASRD3
LB0B4:  ADDD LZ_RSY                 ;(8Y-1Y) FOR 7000 MAX VALUE
LB0B6:  ADDD MS_TZ+M_U1
LB0B9:  STD  TMPTZ
;*** BE SURE TO RESTORE DIVIDER UPON EXIT
LB0BB:  LDD  #$F000                 ;?PASSED BOTTOM OF TRENCH?
LB0BE:  SUBD TMPTZ                  ;KEEP RESULT POSITIVE
LB0C0:  LBLT CLBLZ_50
LB0C4:  STD  M_DVN                  ;% OF LINE BENEATH BOTTOM
LB0C7:  LDD  MS_TZ+M_U1             ;OLD TZ
LB0CA:  SUBD TMPTZ                  ;LENGTH OF LINE
LB0CC:  STD  M_DVD                  ;UNSIGNED DIVIDE ONLY
LB0CF:  LDD  TMPTY
LB0D1:  SUBD MS_TY+M_U1             ;POTENTIAL Y VALUES
LB0D4:  STD  M_YP
LB0D7:  LDD  TMPTX                  ;NEW-OLD:MAX RANGE
LB0D9:  SUBD MS_TX+M_U1             ;POTENTIAL X VALUES
LB0DC:  STD  M_ZP                   ;MISNAMED--DELTA X
LB0DF:  LDD  M_QUO                  ;GET THE FRACTION OF LINE
LB0E2:  STD  M_XP                   ;GEN %*DY,%*DX
LB0E5:  LDA  #MS_PERS
LB0E7:  JSR  MGOWT
LB0EA:  LDD  TMPTY                  ;FARTHEST POSSIBLE NEW Y
LB0EC:  SUBD M_YP                   ;INTERSECTED NOT QUITE THAT FAR
LB0EF:  BMI  CLBLZ_44
LB0F1:  CMPD #$0400                 ;?WITHIN RIGHT SIDE?
LB0F5:  BGT  CLBLZ_50               ;B IF OUTSIDE THEN TRY SIDES
LB0F7:  BRA  CLBLZ_46               ;THEN GOT A COLLISION

CLBLZ_44:
LB0F9:  CMPD #$FC00                 ;?WITHIN LEFT SIDE?
LB0FD:  BLT  CLBLZ_50               ;B IF OUTSIDE THEN TRY SIDES

CLBLZ_46:
LB0FF:  STD  TMPTY                  ;Y: ACTUAL END OF LAZAR ON BOTTOM
LB101:  LDD  TMPTX                  ;NEW-%(NEW-OLD)
LB103:  SUBD M_ZP                   ;MISNAMED: X OFFSET
LB106:  STD  TMPTX                  ;COLLIDED X POSITION
LB108:  STD  LZ_PNX                 ;X DEPTH
LB10A:  LDD  #$F000                 ;BOTTOM OF TRENCH
LB10D:  STD  TMPTZ
LB10F:  LDA  #$FF                   ;AT LEAST HIT THE BOTTOM
LB111:  STA  LZ_HIT
LB113:  LDA  #BT0+BT1               ;UPPER HALF
LB115:  STA  SP_TYP
LB118:  LDA  TMPTX                  ;RELATIVE DISTANCE AWAY
LB11A:  SUBA MS_TX+M_U1
LB11D:  LDB  #$03
LB11F:  MUL
LB120:  CMPD #$00E0
LB124:  BLO  LB128                  ;IFHS  LIMIT THE SCALE
LB126:  LDB  #$E0
LB128:  STB  SP_LOC
LB12B:  LDD  #(VGCGRN*$100)+VGCOPC
LB12E:  STD  SP_COL
LB131:  LDA  BS_PFL
LB133:  BEQ  LB157                  ;IFNE  ?EXHAUST PORT ON?
LB135:  LDA  PT_LZF
LB137:  BNE  LB157                  ;IFEQ  ?PROTON TORP STILL PRIMED?
LB139:  LDD  TMPTY
LB13B:  ADDD #$0200
LB13E:  BLT  LB157                  ;IFGE  ?WITHIN LEFT EDGE?
LB140:  SUBD #$0400
LB143:  BGT  LB157                  ;IFLE  ?WITHIN RIGHT EDGE?
LB145:  LDD  TMPTX
LB147:  SUBD BS_PLC                 ;GET DELTA FROM PORTHOLE LOC
LB149:  ADDD #$0200
LB14C:  BLT  LB157                  ;IFGE  ?ABOVE BOTTOM EDGE?
LB14E:  SUBD #$0400
LB151:  BGT  LB157                  ;IFLE  ?BELOW TOP EDGE?
LB153:  LDA  #$01
LB155:  STA  PT_LZF                 ;SET LAZAR FIRE FLAG
LB157:  RTS                         ;EXIT DONE WITH BOTTOM

CLBLZ_50:        ;---SIDE CHECK
LB158:  LDD  TMPTY
LB15A:  LBPL CLBLZ_70               ;B RIGHT SIDE

CLBLZ_60:        ;---CHECK LEFT SIDE COLLISION
LB15E:  LDD  #$FC00                 ;?PASSED LEFT SIDE OF TRENCH?
LB161:  SUBD TMPTY                  ;KEEP RESULT POSITIVE
LB163:  LBLT CLBLZ_80               ;B NOT YET PASSED SIDE
LB167:  STD  M_DVN                  ;% OF LINE BENEATH SIDE
LB16A:  LDD  MS_TY+M_U1             ;ABS(NEW-OLD:TOTAL RANGE)
LB16D:  SUBD TMPTY                  ;LENGTH OF LINE
LB16F:  STD  M_DVD                  ;UNSIGNED DIVIDE ONLY
LB172:  LDD  TMPTZ
LB174:  SUBD MS_TZ+M_U1             ;POTENTIAL Z VALUES
LB177:  STD  M_ZP
LB17A:  LDD  TMPTX                  ;NEW-OLD:TOTAL RANGE
LB17C:  SUBD MS_TX+M_U1             ;POTENTIAL X VALUES
LB17F:  STD  M_YP                   ;MISNAMED--DELTA X
LB182:  LDD  M_QUO                  ;GET THE FRACTION OF LINE
LB185:  STD  M_XP                   ;GEN %*DZ,%*DX
LB188:  LDA  #MS_PERS
LB18A:  JSR  MGOWT
LB18D:  LDD  TMPTZ                  ;FARTHEST POSSIBLE Z
LB18F:  SUBD M_ZP                   ;INTERSECTED NOT QUITE THAT FAR
LB192:  BMI  CLBLZ_66
LB194:  CMPD #$0000                 ;?BENEATH TOP?
LB198:  LBGT CLBLZ_80               ;B IF OUTSIDE THEN STOP TRYING
LB19C:  BRA  CLBLZ_68               ;THEN GOT A COLLISION

CLBLZ_66:
LB19E:  CMPD #$F000                 ;?ABOVE BOTTOM?
LB1A2:  LBLT CLBLZ_80               ;B IF OUTSIDE THEN STOP TRYING

CLBLZ_68:
LB1A6:  STD  TMPTZ                  ;Z: ACTUAL END OF LAZAR ON SIDE
LB1A8:  ADDD #$1000                 ;BASE IT AT ZERO
LB1AB:  STD  LZ_PNW                 ;WIDTH
LB1AD:  LDD  TMPTX
LB1AF:  SUBD M_YP                   ;MISNAMED: X OFFSET
LB1B2:  STD  TMPTX                  ;COLLIDED X POSITION
LB1B4:  STD  LZ_PNX
LB1B6:  LDD  #$FC00                 ;LEFT SIDE OF TRENCH
LB1B9:  STD  TMPTY                  ;Y POSITION
LB1BB:  LDA  #$FF                   ;AT LEAST HIT THE SIDES
LB1BD:  STA  LZ_HIT
LB1BF:  LDA  #BT0+BT3               ;RIGHT HALF
LB1C1:  STA  SP_TYP
LB1C4:  LDA  TMPTX                  ;RELATIVE DISTANCE AWAY
LB1C6:  SUBA MS_TX+M_U1
LB1C9:  LDB  #$03
LB1CB:  MUL
LB1CC:  CMPD #$00E0
LB1D0:  BLO  LB1D4                  ;IFHS  LIMIT THE SCALE
LB1D2:  LDB  #$E0
LB1D4:  STB  SP_LOC
LB1D7:  LDD  #(VGCGRN*$100)+VGCOPC
LB1DA:  STD  SP_COL
LB1DD:  LDX  #PNLW                  ;LEFT WALL PANELS
LB1E0:  JMP  LZCPNW                 ;?COLLIDE WITH PANELS?

CLBLZ_70:        ;---CHECK RIGHT SIDE COLLISION
LB1E3:  SUBD #$0400                 ;?PASSED RIGHT SIDE OF TRENCH?
LB1E6:  BLT  CLBLZ_80               ;B NOT YET PASSED SIDE
LB1E8:  STD  M_DVN                  ;% OF LINE BENEATH SIDE
LB1EB:  LDD  TMPTY                  ;LENGTH OF LINE
LB1ED:  SUBD MS_TY+M_U1             ;OLD TY
LB1F0:  STD  M_DVD                  ;UNSIGNED DIVIDE ONLY
LB1F3:  LDD  TMPTZ
LB1F5:  SUBD MS_TZ+M_U1             ;POTENTIAL Z VALUES
LB1F8:  STD  M_ZP
LB1FB:  LDD  TMPTX                  ;NEW-OLD:TOTAL RANGE
LB1FD:  SUBD MS_TX+M_U1             ;POTENTIAL X VALUES
LB200:  STD  M_YP                   ;MISNAMED--DELTA X
LB203:  LDD  M_QUO                  ;GET THE FRACTION OF LINE
LB206:  STD  M_XP                   ;GEN %*DZ,%*DX
LB209:  LDA  #MS_PERS
LB20B:  JSR  MGOWT
LB20E:  LDD  TMPTZ                  ;FARTHEST POSSIBLE Z
LB210:  SUBD M_ZP                   ;INTERSECTED NOT QUITE THAT FAR
LB213:  BMI  CLBLZ_76
LB215:  CMPD #$0000                 ;?BENEATH TOP?
LB219:  BGT  CLBLZ_80               ;B IF OUTSIDE THEN STOP TRYING
LB21B:  BRA  CLBLZ_78               ;THEN GOT A COLLISION

CLBLZ_76:
LB21D:  CMPD #$F000                 ;?ABOVE BOTTOM?
LB221:  BLT  CLBLZ_80               ;B IF OUTSIDE THEN STOP TRYING

CLBLZ_78:
LB223:  STD  TMPTZ                  ;Z: ACTUAL END OF LAZAR ON SIDE
LB225:  ADDD #$1000                 ;BASE IT AT ZERO
LB228:  STD  LZ_PNW                 ;WIDTH
LB22A:  LDD  TMPTX
LB22C:  SUBD M_YP                   ;MISNAMED: X OFFSET
LB22F:  STD  TMPTX                  ;COLLIDED X POSITION
LB231:  STD  LZ_PNX                 ;X DEPTH
LB233:  LDD  #$0400                 ;RIGHT SIDE OF TRENCH
LB236:  STD  TMPTY
LB238:  LDA  #$FF
LB23A:  STA  LZ_HIT                 ;AT LEAST HIT THE SIDES
LB23C:  LDA  #BT1+BT2               ;LEFT HALF
LB23E:  STA  SP_TYP
LB241:  LDA  TMPTX                  ;RELATIVE DISTANCE AWAY
LB243:  SUBA MS_TX+M_U1
LB246:  LDB  #$03
LB248:  MUL
LB249:  CMPD #$00E0
LB24D:  BLO  LB251                  ;IFHS  LIMIT THE SCALE
LB24F:  LDB  #$E0
LB251:  STB  SP_LOC
LB254:  LDD  #(VGCGRN*$100)+VGCOPC
LB257:  STD  SP_COL
LB25A:  LDX  #PNRW                  ;RIGHT WALL
LB25D:  JMP  LZCPNW                 ;EXIT: CHECK PANEL COLLISION

CLBLZ_80:        ;---POTENTIAL WALL COLLISION FAILED
CLBLZ_90:
LB260:  RTS

;------------------------------------------------------------------------------
; LZCPNW - CHECK COLLIDE WITH WIDE WALL PANELS
;------------------------------------------------------------------------------
LZCPNW:
LB261:  LDA  LZ_ON
LB263:  BNE  LZCPNW_10
LB265:  RTS                         ;EXIT IF LAZARS NOT ON

LZCPNW_10:
LB266:  LDB  LZ_PNX
LB268:  LSRB
LB269:  LSRB
LB26A:  LSRB
LB26B:  ANDB #$0F                   ;PANEL EVERY 800(16 PANELS DEEP)
LB26D:  ABX                         ;POINT INTO PANEL FLAG RAM
LB26E:  LDD  LZ_PNX
LB270:  ANDA #$07
LB272:  SUBD #$200-LZR
LB275:  BLT  LZCPNW_70              ;B TOO SHORT ON X
LB277:  SUBD #$400+LZD
LB27A:  BGT  LZCPNW_70              ;B TOO LONG ON X
LB27C:  LDA  #$03                   ;SET UP MASK
LB27E:  STA  TMPMSK
LB280:  LDD  LZ_PNW                 ;CHECK FOR PROPER WIDTH
LB282:  SUBD #$80-LZR               ;LEAST EDGE OF FIRST PANEL

LZCPNW_20:
LB285:  SUBD #$300+LZD              ;GREATER EDGE OF PANEL
LB288:  BGT  LZCPNW_60
LB28A:  SUBD #0-($300+LZD)          ;SIZE OF PANEL
LB28D:  BLT  LZCPNW_70              ;B MISSED
LB28F:  JMP  LZHPN                  ;J HIT A PANEL

LZCPNW_60:
LB292:  SUBD #$100-LZD              ;ADVANCE TO NEXT PANEL
LB295:  LSL  TMPMSK
LB297:  LSL  TMPMSK                 ;SLIDE MASK FOR NEXT PANEL
LB299:  BNE  LZCPNW_20              ;LOOP TILL NO LIVE PANELS

LZCPNW_70:
LB29B:  RTS

;------------------------------------------------------------------------------
; LZHPN - HIT A PANEL
;------------------------------------------------------------------------------
LZHPN:
LB29C:  LDA  TMPMSK
LB29E:  ANDA ,X                     ;CHECK FOR TYPE OF PANEL
LB2A0:  BEQ  LB2D1                  ;IFNE  ?ALIVE?
LB2A2:  STA  TMPFLG                 ;SAVEIT, IS 1,2,3 IN THE SLOT
LB2A4:  LDA  TMPMSK
LB2A6:  LSLA
LB2A7:  ANDA TMPMSK                 ;GEN A TYPE 2 IN CORRECT SLOT
LB2A9:  CMPA TMPFLG                 ;CHECK AGAINST MASKED PANEL TYPE
LB2AB:  BEQ  LB2D1                  ;IFNE  ?NOT A FORCE FIELD?
LB2AD:  BLS  LB2C1                  ;IFHI  MUST HAVE BEEN A 1, I.E. A DECORATIVE PANEL
LB2AF:  LDA  #$04                   ;STICK HERE AND SHOW A HIT
LB2B1:  STA  LZ_HIT
LB2B3:  LDA  ,X
LB2B5:  EORA TMPFLG                 ;GET RID OF PANEL
LB2B7:  STA  ,X                     ;STORED BACK
LB2B9:  JSR  SCRPNL                 ;SCORE FOR A PANEL
LB2BC:  JSR  AUDSX
LB2BF:  BRA  LB2D1                  ;ELSE  MUST BE A TURRET
LB2C1:  LDA  #$04                   ;STICK HERE AND SHOW A HIT
LB2C3:  STA  LZ_HIT
LB2C5:  LDA  ,X
LB2C7:  EORA TMPFLG                 ;GET RID OF PANEL
LB2C9:  STA  ,X                     ;STORED BACK
LB2CB:  JSR  SCRTRT                 ;KILLED A TURRET
LB2CE:  JSR  AUDSX
LB2D1:  RTS

;------------------------------------------------------------------------------
; CLGLZ - CLGLZ -- COLLIDE WITH GROUND LAZAR
;------------------------------------------------------------------------------
CLGLZ:
LB2D2:  LDA  LZ_ON
LB2D4:  BEQ  LB2E3                  ;IFNE  ?ARE LAZARS ON?
LB2D6:  LDD  CL_GDS                 ;CHECK THE GUNS FIRST
LB2D8:  BMI  LB2E1                  ;IFPL  ?GOT A GUN?
LB2DA:  LDA  #$04
LB2DC:  STA  LZ_HIT
LB2DE:  JSR  GNHTSG                 ;ALWAYS HIT A GUN SINCE NO DISTANCE QUEUE
LB2E1:  BRA  CLGA                   ;THEN CHECK FOR ALIENS NEXT
LB2E3:  RTS

;------------------------------------------------------------------------------
; CLGA - [note] Alien test (after the guns in CLGLZ): if CL_ADS is valid and no farther than CL_BDS and CL_TDS, set
;   LZ_HIT = 4 and jump to CPHTSA; else go on to CLGB or CLGT
;------------------------------------------------------------------------------
CLGA:
LB2E4:  LDD  CL_ADS
LB2E6:  BMI  CLGB
LB2E8:  CMPD CL_BDS
LB2EB:  BHI  CLGB
LB2ED:  SUBD CL_TDS
LB2EF:  BHI  CLGT
LB2F1:  LDA  #$04
LB2F3:  STA  LZ_HIT
LB2F5:  JMP  CPHTSA

;------------------------------------------------------------------------------
; CLGB - BUNKER TEST
;------------------------------------------------------------------------------
CLGB:
LB2F8:  LDD  CL_BDS
LB2FA:  BMI  CLGT
LB2FC:  SUBD CL_TDS
LB2FE:  BHI  CLGT
LB300:  LDA  #$04
LB302:  STA  LZ_HIT
LB304:  JMP  GDHTGB

;------------------------------------------------------------------------------
; CLGT - [note] Tower test: if CL_TDS is valid, LZ_HIT = $FF (no hit, but splash against wall), SP_TYP = full
;   surface, SP_LOC = 3 * high byte of CL_TDS (limit $E0), SP_COL = yellow
;------------------------------------------------------------------------------
CLGT:
LB307:  LDD  CL_TDS
LB309:  BMI  LB32A                  ;IFPL  ?VALID TOWER?
LB30B:  LDA  #$FF                   ;NO HIT, BUT SPLASH AGAINST WALL
LB30D:  STA  LZ_HIT
LB30F:  LDA  #BT0+BT1+BT2+BT3       ;FULL SURFACE
LB311:  STA  SP_TYP
LB314:  LDA  CL_TDS                 ;RELATIVE DISTANCE AWAY
LB316:  LDB  #$03                   ;2 FOR PRE SUB2 AND 1 FOR SMALL LINEAR TOWERS
LB318:  MUL
LB319:  CMPD #$00E0
LB31D:  BLO  LB321                  ;IFHS  LIMIT THE SCALE
LB31F:  LDB  #$E0
LB321:  STB  SP_LOC
LB324:  LDD  #(VGCYLW*$100)+VGCOPC
LB327:  STD  SP_COL
LB32A:  RTS

;------------------------------------------------------------------------------
; CLSLZ - CLSLZ -- COLLIDE WITH SPACE LASAR
;------------------------------------------------------------------------------
CLSLZ:
LB32B:  LDA  LZ_ON
LB32D:  BEQ  LB33D                  ;IFNE  ?ARE LAZARS ON?
LB32F:  LDD  CL_GDS                 ;CHECK ALIEN GUNS FIRST
LB331:  BMI  LB339                  ;IFPL  ?VALID GUN POSSIBILITY?
LB333:  SUBD CL_ADS                 ;CHECK AGAINST ALIEN DISTANCE
LB335:  BLO  HTSG                   ;B IF CLOSER, THEN HIT THE GUN
LB337:  BRA  HTSA                   ;J ELSE VALID ALIEN IS CLOSER
LB339:  LDA  CL_ADS                 ;IF NO GUN, CHECK ALIEN
LB33B:  BGE  HTSA                   ;B IF ALIEN VALID, HIT HIM
LB33D:  RTS

;------------------------------------------------------------------------------
; HTSG - SPACE LAZAR HIT ALIEN GUN
;------------------------------------------------------------------------------
HTSG:
LB33E:  LDA  #$04
LB340:  STA  LZ_HIT                 ;DISPLAY HIT FOR A WHILE
LB342:  JMP  GNHTSG                 ;GUNS, HIT SPACE GUN

;------------------------------------------------------------------------------
; HTSA - SPACE LAZAR HIT ALIEN SHIP
;------------------------------------------------------------------------------
HTSA:
LB345:  LDA  #$04
LB347:  STA  LZ_HIT                 ;DISPLAY HIT FOR A WHILE
LB349:  JMP  CPHTSA                 ;CPU, HIT SPACE ALIEN

;==============================================================================
; MODULE WSFIL2   WSFIL2.MAC
;==============================================================================

;.SBTTL STAR WARS FILLER FOR ROM 2

CHKSM2:
LB34C:  .word PCKS2

FILL2:
LB34E:  .byte $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF ;.REPT 100.  FILL WITH FF'S
LB356:  .byte $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
LB35E:  .byte $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
LB366:  .byte $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
LB36E:  .byte $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
LB376:  .byte $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
LB37E:  .byte $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
LB386:  .byte $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
LB38E:  .byte $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
LB396:  .byte $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
LB39E:  .byte $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
LB3A6:  .byte $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
LB3AE:  .byte $FF, $FF, $FF, $FF

CPYRT2:
LB3B2:  .byte $43, $4F, $50, $59, $52, $49, $47, $48 ;.ASCII /COPYRIGHT 1983 ATARI/
LB3BA:  .byte $54, $20, $31, $39, $38, $33, $20, $41
LB3C2:  .byte $54, $41, $52, $49
LB3C6:  .byte $04, $BC, $96, $FA, $5B, $28, $41, $4C ;.IRPC .A,<MIKE HALLY WAS THE WHIPCRACKER>
LB3CE:  .byte $4C, $59, $20, $57, $41, $53, $20, $54
LB3D6:  .byte $48, $45, $20, $57, $48, $49, $50, $43
LB3DE:  .byte $52, $41, $43, $4B, $45, $52

;==============================================================================
; MODULE WSPANL   WSPANL.MAC
;   PANEL ON WALLS OF TRENCH OF BASE STAR
;==============================================================================

;------------------------------------------------------------------------------
; VWPANEL - BASESTAR PANELS -- VWPANEL,PNVLW
;   VIEW THE PANELS
;------------------------------------------------------------------------------
VWPANEL:
LB3E4:  LDA  WG_FCU                 ;VERIFY CORRECT FORCE FIELD CUE VALUE
LB3E7:  CMPA #(ZFFCUE-TFFCUE)/2
LB3E9:  BLO  LB3F0                  ;IFHS  ?WRAPPED OVER TOP?
LB3EB:  LDA  #$00                   ;THEN START FRESH
LB3ED:  STA  WG_FCU
LB3F0:  LDA  #$01
LB3F2:  STA  PN_DES                 ;DESIRED TYPE OF PANEL TO SEE
LB3F4:  LDA  #TDS_WPN               ;DECORATIVE WALL PANEL
LB3F6:  STA  BJ_ID
LB3F8:  STA  PN_ID
LB3FA:  JSR  BJGROT                 ;PRE-ROTATE ITS POINTS
LB3FD:  JSR  PNVLW                  ;VIEW LEFT WALL PANELS
LB400:  LDA  PN_ID
LB402:  STA  BJ_ID
LB404:  JSR  BJFROT                 ;FLIPPED PRE-ROTATE
LB407:  JSR  PNVRW                  ;VIEW RIGHT WALL PANELS
LB40A:  LDA  #$02
LB40C:  STA  PN_DES                 ;DESIRED TYPE OF PANEL TO SEE
LB40E:  LDA  #TDS_WFF               ;WALL FORCE FIELD
LB410:  STA  BJ_ID
LB412:  STA  PN_ID
LB414:  JSR  BJGROT                 ;PRE-ROTATE ITS POINTS
LB417:  JSR  PNVLW                  ;VIEW LEFT WALL PANELS
LB41A:  LDA  PN_ID
LB41C:  STA  BJ_ID
LB41E:  JSR  BJFROT                 ;FLIPPED PRE-ROTATE
LB421:  JSR  PNVRW                  ;VIEW RIGHT WALL PANELS
LB424:  LDA  #$03
LB426:  STA  PN_DES                 ;DESIRED TYPE OF PANEL TO SEE
LB428:  LDA  #TDS_WGA               ;WALL GUN TYPE A
LB42A:  STA  BJ_ID
LB42C:  STA  PN_ID
LB42E:  JSR  BJGROT                 ;PRE-ROTATE ITS POINTS
LB431:  JSR  PNVLW                  ;VIEW LEFT WALL PANELS
LB434:  LDA  PN_ID
LB436:  STA  BJ_ID
LB438:  JSR  BJFROT                 ;FLIPPED PRE-ROTATE
LB43B:  JSR  PNVRW                  ;VIEW RIGHT BOTTOM PANELS
LB43E:  RTS

;------------------------------------------------------------------------------
; PNVLW - VIEW THE LEFT PANELS
;------------------------------------------------------------------------------
PNVLW:
LB43F:  LDA  #$00
LB441:  STA  WG_FCB                 ;NO BUMP TO NEXT FORCE FIELD CUE YET
LB444:  LDA  WG_FCU                 ;INIT CURRENT CUE COLOR
LB447:  STA  WG_FCC
LB44A:  LDA  #$88                   ;REGULAR MAX PLUS DELTA
LB44C:  STA  WG_FCZ                 ;BRITENESS OF CLOSEST FORCE-FIELD
LB44F:  LDB  MS_TX+M_U1             ;SETUP POINTER TO PANEL FLAGS
LB452:  LSRB
LB453:  LSRB
LB454:  LSRB
LB455:  ANDB #$0F
LB457:  LDX  #PNLW                  ;FLAG ARRAY
LB45A:  ABX
LB45B:  STX  S2_PRM
LB45D:  LDA  MS_TX+M_U1             ;CURRENT SHIP POSITION
LB460:  ANDA #$F8
LB462:  ADDA #$04                   ;THEN GET INTO MIDDLE OF PANEL
LB464:  LDB  #$00
LB466:  STD  M_X0
LB469:  LDD  #$FC00
LB46C:  STD  M_Y0
LB46F:  LDD  #$F200                 ;BASE START(MID OF LOWEST SEGMENT)
LB472:  STD  M_Z0
LB475:  LDX  S2_PRM
LB477:  CMPX #PNLWZ
LB47A:  BLO  LB47F                  ;IFHS  ?WRAPAROUND?
LB47C:  LEAX <-PNLWS_IZ,X           ;MOVE BACK MOD(WHOLE TABLE)
LB47F:  LDA  ,X+                    ;GET FLAGS
LB481:  STX  S2_PRM
;;; TSTA ;STX TO KEEP LATEST POINTER, TSTA TO GET VAL
LB483:  STA  PN_FLG                 ;WORKING FLAG BITS
LB485:  ANDA #$03
LB487:  CMPA PN_DES                 ;CHECK AGAINST DESIRED PANEL TYPE
LB489:  LBNE PNVLW_50               ;?CORRECT TYPE?
LB48D:  LDA  PN_ID
LB48F:  STA  BJ_ID                  ;PREPARE CORRECT OBJECT IDENTIFICATION
LB491:  LDD  #MS_X0BC
LB494:  STD  M_BIC
LB497:  LDA  #MS_PSB2
LB499:  JSR  MGOWT                  ;GET PANELS CENTER POINT OUT THERE
LB49C:  LDA  PN_DES
LB49E:  CMPA #$02
LB4A0:  BNE  LB4B5                  ;IFEQ  ?GOT A FORCE FIELD TO COLOR CUE?
LB4A2:  INC  WG_FCB                 ;BUMP OUR COLOR CUE FOR LATER PANEL
LB4A5:  LDB  WG_FCC
LB4A8:  LSLB
LB4A9:  LDX  #TFFCUE                ;COLOR CUE THE WEDGES FOR DEPTH VISION
LB4AC:  LDD  B,X
LB4AE:  STD  ,Y++
LB4B0:  LDA  WG_FCZ                 ;Z-BRITENESS TO USE
LB4B3:  STA  -$1,Y                  ;OVERLAY PREVIOUS BRIGHTNESS
LB4B5:  LDD  M_X0
LB4B8:  SUBD MS_TX+M_U1             ;GET RELATIVE DISP TO PANEL CENTER
LB4BB:  CMPD #$1000
LB4BF:  BGT  LB510                  ;IFLE
LB4C1:  LDA  PN_ID
LB4C3:  CMPA #TDS_WFF
LB4C5:  BNE  LB50B                  ;IFEQ  ?DOING A FORCE FIELD?
LB4C7:  LDD  M_XP                   ;?FRONT PART VISIBLE?
LB4CA:  SUBD #$0000
LB4CD:  BLT  PNVLW_50               ;B EXIT IF NOT REALLY VISIBLE
LB4CF:  LDD  MS_TY+M_U1             ;THEN CHECK LEFT/RIGHT
LB4D2:  BGT  LB50B                  ;IFLE  ?ON LEFT SIDE?
LB4D4:  LDD  M_Z0
LB4D7:  ADDD #$0200                 ;TOP OF FORCE FIELD
LB4DA:  SUBD MS_TZ+M_U1
LB4DD:  BLT  LB50B                  ;IFGE  ?FORCE FIELD ABOVE PLAYER?
LB4DF:  SUBD #$0400
LB4E2:  BGT  LB50B                  ;IFLE  ?BUT NOT TOO FAR?
LB4E4:  LDD  M_X0
LB4E7:  SUBD MS_TX+M_U1
LB4EA:  SUBD #$0400                 ;HALF OF FF DEPTH, MORE THAN MAX SPEED
LB4ED:  BHI  LB50B                  ;IFLS  ?WITHIN FIRST HALF OF FORCE FIELD?
LB4EF:  LDA  #TDS_WFG               ;THEN A HIT, CHANGE THE PICTURE TO BRITE
LB4F1:  STA  BJ_ID
LB4F3:  LDA  S_GAS
LB4F5:  BLT  LB4FD                  ;IFGE  ?STILL IN NORMAL GAMEPLAY?
LB4F7:  JSR  BG1GLW                 ;BEGIN GLOWING PLAYERS SHIP
LB4FA:  JSR  AUDCR                  ;CRASH INTO FORCE FIELD
LB4FD:  LDA  S_ROL
LB4FF:  BNE  LB50B                  ;IFEQ  ?FINISHED WITH PRIOR COLLIDE?
LB501:  LDA  #$4E
LB503:  LDB  P_RND1
LB506:  BPL  LB509                  ;IFMI
LB508:  NEGA                        ;FLIP OTHER DIRECTION FOR VARIETY
LB509:  STA  S_ROL
LB50B:  JSR  BJBCLP                 ;ALL CLOSE PANELS GET POINTS CLIPPED
LB50E:  BRA  LB513                  ;ELSE  ELSE
LB510:  JSR  BJGPNT                 ;DO POINTS SPEEDILY
LB513:  JSR  BJGDRW

PNVLW_50:
LB516:  LDD  M_Z0
LB519:  ADDD #$0400                 ;MOVE UP TO NEXT PANEL
LB51C:  STD  M_Z0
LB51F:  LDA  PN_FLG
LB521:  LSRA
LB522:  LSRA
LB523:  LBNE LB483                  ;EQEND  LOOP TO NEXT PANEL UP
LB527:  LDA  PN_DES
LB529:  CMPA #$02
LB52B:  BNE  LB565                  ;IFEQ
LB52D:  LDX  S2_PRM                 ;ONE PAST CURRENT PANNEL
LB52F:  LDA  >PNRW-PNLW-1,X         ;POINT TO OTHER PANNEL SET
LB533:  LSLA
LB534:  BCC  LB53D                  ;IFCS  2 OR 3?
LB536:  BMI  LB53D                  ;IFPL  MUST BE A 2 ( FORCE FIELD )
LB538:  INC  WG_FCB                 ;BUMP OUR COLOR CUE
LB53B:  BRA  PNVLW_60
LB53D:  LSLA
LB53E:  BNE  LB533                  ;EQEND

PNVLW_60:
LB540:  LDA  WG_FCB
LB543:  BEQ  LB565                  ;IFNE  ?HAVE AT LEAST ONE FORCE FIELD IN THIS PANEL?
LB545:  LDA  WG_FCC
LB548:  INCA
LB549:  CMPA #(ZFFCUE-TFFCUE)/2
LB54B:  BLO  LB54F                  ;IFHS  ?OVERFLOW TABLE SIZE?
LB54D:  LDA  #$00
LB54F:  STA  WG_FCC                 ;CURRENT COLOR CUE INDEX
LB552:  LDA  WG_FCZ                 ;CURRENT BRITENESS
LB555:  SUBA #$08                   ;FURTHER PANELS ARE DIMMER
LB557:  CMPA #$40                   ;LOWER LIMIT
LB559:  BHS  LB55D                  ;IFLO  ?TOO DIM? OR WRAPPED?
LB55B:  LDA  #$40
LB55D:  STA  WG_FCZ                 ;SAVE NEXT BRITENESS
LB560:  LDA  #$00
LB562:  STA  WG_FCB
LB565:  LDD  M_X0
LB568:  ADDD #$0800                 ;GET NEXT SEGMENT
LB56B:  STD  M_X0
LB56E:  SUBD MS_TX+M_U1             ;GET RELATIVE DISPLACEMENT
LB571:  SUBD #$7000                 ;?WITHIN VIEW?
LB574:  LBLO LB46F                  ;HSEND  ---LOOP NEXT SEGMENT
LB578:  RTS

;------------------------------------------------------------------------------
; PNVRW - VIEW THE LEFT PANELS
;------------------------------------------------------------------------------
PNVRW:
LB579:  LDA  #$00
LB57B:  STA  WG_FCB                 ;NO BUMP TO NEXT FORCE FIELD CUE YET
LB57E:  LDA  WG_FCU                 ;INIT CURRENT CUE COLOR
LB581:  STA  WG_FCC
LB584:  LDA  #$88                   ;MAX BRITE PLUS DELTA
LB586:  STA  WG_FCZ                 ;STARTING BRITENESS FOR NEAREST FORCE FIELD
LB589:  LDB  MS_TX+M_U1             ;SETUP POINTER TO PANEL FLAGS
LB58C:  LSRB
LB58D:  LSRB
LB58E:  LSRB
LB58F:  ANDB #$0F
LB591:  LDX  #PNRW                  ;FLAG ARRAY
LB594:  ABX
LB595:  STX  S2_PRM
LB597:  LDA  MS_TX+M_U1             ;CURRENT SHIP POSITION
LB59A:  ANDA #$F8
LB59C:  ADDA #$04                   ;THEN GET INTO MIDDLE OF PANEL
LB59E:  LDB  #$00
LB5A0:  STD  M_X0
LB5A3:  LDD  #$0400
LB5A6:  STD  M_Y0
LB5A9:  LDD  #$F200                 ;BASE START(MID OF LOWEST SEGMENT)
LB5AC:  STD  M_Z0
LB5AF:  LDX  S2_PRM
LB5B1:  CMPX #PNRWZ
LB5B4:  BLO  LB5B9                  ;IFHS  ?WRAPAROUND?
LB5B6:  LEAX <-PNRWS_IZ,X           ;MOVE BACK MOD(WHOLE TABLE)
LB5B9:  LDA  ,X+                    ;GET FLAGS
LB5BB:  STX  S2_PRM
;;; TSTA ;STX TO KEEP LATEST POINTER, TSTA TO GET VAL
LB5BD:  STA  PN_FLG                 ;WORKING FLAG BITS
LB5BF:  ANDA #$03
LB5C1:  CMPA PN_DES                 ;CHECK AGAINST DESIRED PANEL TYPE
LB5C3:  LBNE PNVRW_50               ;?CORRECT TYPE?
LB5C7:  LDA  PN_ID
LB5C9:  STA  BJ_ID                  ;SETUP CORRECT OBJECT ID
LB5CB:  LDD  #MS_X0BC
LB5CE:  STD  M_BIC
LB5D1:  LDA  #MS_PSB2
LB5D3:  JSR  MGOWT                  ;GET PANELS CENTER POINT OUT THERE
LB5D6:  LDA  PN_DES
LB5D8:  CMPA #$02
LB5DA:  BNE  LB5EF                  ;IFEQ  ?GOT A FORCE FIELD TO COLOR CUE?
LB5DC:  INC  WG_FCB                 ;BUMP OUR COLOR CUE FOR LATER PANEL
LB5DF:  LDB  WG_FCC
LB5E2:  LSLB
LB5E3:  LDX  #TFFCUE                ;COLOR CUE THE WEDGES FOR DEPTH VISION
LB5E6:  LDD  B,X
LB5E8:  STD  ,Y++
LB5EA:  LDA  WG_FCZ
LB5ED:  STA  -$1,Y                  ;OVERLAY PREVIOUS BRIGHTNESS
LB5EF:  LDD  M_X0
LB5F2:  SUBD MS_TX+M_U1             ;GET RELATIVE DISP TO PANEL CENTER
LB5F5:  CMPD #$1000
LB5F9:  BGT  LB64A                  ;IFLE
LB5FB:  LDA  PN_ID
LB5FD:  CMPA #TDS_WFF
LB5FF:  BNE  LB645                  ;IFEQ  ?DOING A FORCE FIELD?
LB601:  LDD  M_XP                   ;TEST FOR REALLY IN VIEW
LB604:  SUBD #$0000
LB607:  BLT  PNVRW_50               ;B EXIT IF PAST FRONT HALF
LB609:  LDD  MS_TY+M_U1             ;THEN CHECK LEFT/RIGHT
LB60C:  BLT  LB645                  ;IFGE  ?ON RIGHT SIDE?
LB60E:  LDD  M_Z0
LB611:  ADDD #$0200                 ;BOTTOM OF FORCE FIELD
LB614:  SUBD MS_TZ+M_U1
LB617:  BLT  LB645                  ;IFGE  ?BENEATH TOP OF FORCE FIELD?
LB619:  SUBD #$0400
LB61C:  BGT  LB645                  ;IFLE  ?AND ABOVE BOTTOM?
LB61E:  LDD  M_X0
LB621:  SUBD MS_TX+M_U1
LB624:  SUBD #$0400                 ;HALF OF FF DEPTH, MORE THAN MAX SPEED
LB627:  BHI  LB645                  ;IFLS  ?WITHIN FIRST HALF OF FORCE FIELD?
LB629:  LDA  #TDS_WFG               ;THEN A HIT, CHANGE THE PICTURE TO BRITE
LB62B:  STA  BJ_ID
LB62D:  LDA  S_GAS                  ;?STILL IN NORMAL GAMEPLAY?
LB62F:  BLT  LB637                  ;IFGE
LB631:  JSR  BG1GLW                 ;BEGIN GLOWING SHIP SHIELDS
LB634:  JSR  AUDCR                  ;CRASH INTO FORCE FIELD
LB637:  LDA  S_ROL
LB639:  BNE  LB645                  ;IFEQ  JUST ONE HIT PER COLLISION PLEASE
LB63B:  LDA  #$4E
LB63D:  LDB  P_RND1
LB640:  BPL  LB643                  ;IFMI
LB642:  NEGA                        ;FLIP OTHER DIRECTION TO EVEN US OUT
LB643:  STA  S_ROL
LB645:  JSR  BJBCLP                 ;ALL CLOSE PANELS GET POINTS CLIPPED
LB648:  BRA  LB64D                  ;ELSE  ELSE
LB64A:  JSR  BJGPNT                 ;DO POINTS SPEEDILY
LB64D:  JSR  BJGDRW

PNVRW_50:
LB650:  LDD  M_Z0
LB653:  ADDD #$0400                 ;MOVE UP TO NEXT PANEL
LB656:  STD  M_Z0
LB659:  LDA  PN_FLG
LB65B:  LSRA
LB65C:  LSRA
LB65D:  LBNE LB5BD                  ;EQEND  LOOP TO NEXT PANEL UP
LB661:  LDA  PN_DES
LB663:  CMPA #$02
LB665:  BNE  LB69F                  ;IFEQ
LB667:  LDX  S2_PRM                 ;ONE PAST CURRENT PANNEL
LB669:  LDA  >PNLW-PNRW-1,X         ;POINT TO OTHER PANNEL SET
LB66D:  LSLA
LB66E:  BCC  LB677                  ;IFCS  2 OR 3?
LB670:  BMI  LB677                  ;IFPL  MUST BE A 2 ( FORCE FIELD )
LB672:  INC  WG_FCB                 ;BUMP OUR COLOR CUE
LB675:  BRA  PNVRW_60
LB677:  LSLA
LB678:  BNE  LB66D                  ;EQEND

PNVRW_60:
LB67A:  LDA  WG_FCB
LB67D:  BEQ  LB69F                  ;IFNE  ?HAVE AT LEAST ONE FORCE FIELD IN THIS PANEL?
LB67F:  LDA  WG_FCC
LB682:  INCA
LB683:  CMPA #(ZFFCUE-TFFCUE)/2
LB685:  BLO  LB689                  ;IFHS  ?OVERFLOW TABLE SIZE?
LB687:  LDA  #$00
LB689:  STA  WG_FCC                 ;CURRENT COLOR CUE INDEX
LB68C:  LDA  WG_FCZ                 ;CURRENT BRITENESS
LB68F:  SUBA #$08                   ;FURTHER PANELS ARE DIMMER
LB691:  CMPA #$40                   ;LOWER LIMIT
LB693:  BHS  LB697                  ;IFLO  ?TOO DIM? OR WRAPPED?
LB695:  LDA  #$40
LB697:  STA  WG_FCZ                 ;SAVE NEXT BRITENESS
LB69A:  LDA  #$00
LB69C:  STA  WG_FCB
LB69F:  LDD  M_X0
LB6A2:  ADDD #$0800                 ;GET NEXT SEGMENT
LB6A5:  STD  M_X0
LB6A8:  SUBD MS_TX+M_U1             ;GET RELATIVE DISPLACEMENT
LB6AB:  SUBD #$7000                 ;?WITHIN VIEW?
LB6AE:  LBLO LB5A9                  ;HSEND  ---LOOP NEXT SEGMENT
LB6B2:  RTS

TFFCUE:
LB6B3:  .word (VGCYLW*$100)+VGCOPC
LB6B5:  .word (VGCTRQ*$100)+VGCOPC
LB6B7:  .word (VGCPRP*$100)+VGCOPC

;==============================================================================
; MODULE WSSITE   WSSITE.MAC
;   I HANDLE SITE
;==============================================================================

;------------------------------------------------------------------------------
; VWSITE - SITE
;   VIEW ALL SITE STUFF WITH NORMAL COLORS
;   (also: ZFFCUE)
;------------------------------------------------------------------------------
VWSITE:
ZFFCUE:
LB6B9:  JSR  VWCURS                 ;CURSOR WITH NORMAL COLORS
LB6BC:  JSR  VWPLAN                 ;X-WING PARTS
LB6BF:  RTS

;------------------------------------------------------------------------------
; VWSITC - VIEW SITE STUFF WITH OWN CURSOR COLOR
;------------------------------------------------------------------------------
VWSITC:
LB6C0:  JSR  VWCURC                 ;CURSOR WITHOUT COLOR COMMAND
LB6C3:  JSR  VWPLAN                 ;X-WING PARTS
LB6C6:  RTS

;------------------------------------------------------------------------------
; VWCURS - ---VIEW CURSOR WITH ITS NORMAL COLOR
;------------------------------------------------------------------------------
VWCURS:
LB6C7:  LDD  #(VGCTRQ*$100)+VGCOPC  ;SITE COLOR
LB6CA:  STD  ,Y++                   ;COLOR BRITE

;------------------------------------------------------------------------------
; VWCURC - VIEW CURSOR WITH YOUR OWN COLOR
;------------------------------------------------------------------------------
VWCURC:
LB6CC:  LDD  #VJSITE                ;JOY MOVES CURSOR
LB6CF:  STD  ,Y++
LB6D1:  LDD  VGSITE
LB6D4:  STD  ,Y++
LB6D6:  RTS

;------------------------------------------------------------------------------
; VWPLAN - VIEW PARTS OF X-WING VISIBLE TO PLAYER
;------------------------------------------------------------------------------
VWPLAN:
LB6D7:  LDA  SI_RSX                 ;SHIFT PLAYERS HOOD VIA CONTROLS
LB6D9:  BPL  LB6DC                  ;IFMI
LB6DB:  NEGA                        ;ABSOLUTE VALUE
LB6DC:  LDB  #$6E                   ;ALLOW +-5.5 GRIDS MOVEMENT, *2 COMPENSATES FOR MUL
LB6DE:  MUL
LB6DF:  LDB  SI_RSX
LB6E1:  BPL  LB6E4                  ;IFMI
LB6E3:  NEGA                        ;RESTORE SIGN
LB6E4:  TFR  A,B
LB6E6:  SEX
LB6E7:  STD  LZ_GX                  ;X DISTANCE OF SITE
LB6EA:  ANDA #$1F                   ;NO BRITE
LB6EC:  STD  2,Y                    ;X VECTOR OFFSET
LB6EE:  STD  8,Y
LB6F0:  STD  $E,Y
LB6F2:  STD  $14,Y
LB6F5:  STD  $1A,Y
LB6F8:  LDA  SI_RSY                 ;NOW HANDLE UP/DOWN SHIFTING
LB6FA:  BPL  LB6FD                  ;IFMI
LB6FC:  NEGA                        ;ABSOLUTE VALUE
LB6FD:  LDB  #$50                   ;ALLOW +-4 GRIDS MOVEMENT, *2 COMPENSATES FOR MUL
LB6FF:  MUL
LB700:  LDB  SI_RSY
LB702:  BPL  LB705                  ;IFMI
LB704:  NEGA                        ;RESTORE SIGN
LB705:  TFR  A,B
LB707:  SEX
LB708:  STD  LZ_GY                  ;Y DISTANCE OF SITE
LB70B:  ANDA #$1F                   ;VECTOR OPCODE
LB70D:  STD  ,Y                     ;UP/DOWN Y VECTOR
LB70F:  STD  6,Y
LB711:  STD  $C,Y
LB713:  STD  $12,Y
LB716:  STD  $18,Y
LB719:  LDD  #VJSTBM                ;PLAYERS HOOD, BOTTOM MIDDLE
LB71C:  STD  4,Y
LB71E:  LDD  #VJSTTR                ;PLAYERS GUN,TOP LEFT
LB721:  STD  $A,Y
LB723:  LDD  #VJSTBL                ;PLAYERS GUN,BOTTOM LEFT
LB726:  STD  $10,Y
LB729:  LDD  #VJSTTL                ;PLAYERS GUN, TOP RIGHT
LB72C:  STD  $16,Y
LB72F:  LDD  #VJSTBR                ;PLAYERS GUN,BOTTOM RIGHT
LB732:  STD  $1C,Y
LB735:  LEAY $1E,Y                  ;BUMP PAST PREVIOUS CLUMP

VWPLAN_70:
LB738:  RTS

;==============================================================================
; MODULE WSXPLD   WSXPLD.MAC
;   EXPLODE
;==============================================================================

;------------------------------------------------------------------------------
; BGAXPLD - EXPLODE -- IVXPLD,DOXPLD,VWXPLD
;------------------------------------------------------------------------------
BGAXPLD:
LB739:  LDA  #$00                   ;THE ALIEN IS NOW DEAD
LB73B:  STA  AS_TYP,X
LB73D:  JSR  CPUGON
LB740:  PSHS X,U
LB742:  JSR  BGAXP
LB745:  PULS X,U
LB747:  RTS

;.SBTTL MUNGE, FANCY EXPLOSION OF OTHERS

TMV:
LB748:  .word MVBK1                 ;.IRP .A,<BK1,BK2,BK3,TW1,TW2,TW3,TI1,TI2,TI3>
LB74A:  .word MVBK2
LB74C:  .word MVBK3
LB74E:  .word MVTW1
LB750:  .word MVTW2
LB752:  .word MVTW3
LB754:  .word MVTI1
LB756:  .word MVTI2
LB758:  .word MVTI3

ZMV:
TVW:
LB75A:  .word VWBK1                 ;.IRP .A,<BK1,BK2,BK3,TW1,TW2,TW3,TI1,TI2,TI3>
LB75C:  .word VWBK2
LB75E:  .word VWBK3
LB760:  .word VWTW1
LB762:  .word VWTW2
LB764:  .word VWTW3
LB766:  .word VWTI1
LB768:  .word VWTI2
LB76A:  .word VWTI3

;------------------------------------------------------------------------------
; BGAXP - BEGIN ALIEN EXPLOSION
;   X-->ALIEN PARMS
;   (also: ZVW)
;------------------------------------------------------------------------------
BGAXP:
ZVW:
LB76C:  LDU  AS_UVP,X               ;U-->ALIEN VECTORS
LB76E:  JSR  NXTFRE
;X-->EXPLOSION PARMS
LB771:  LDA  #TPS_TI1               ;TYPE 1, TIE FIGHTER
LB773:  STA  XPS_TYP,X
LB775:  LDA  #$18
LB777:  STA  XPS_TMR,X
LB779:  LDD  #$0000
LB77C:  SUBD MS_AY,U                ;OFFSET TO CENTER OF LEFT WING
LB77E:  JSR  ASRD6
LB781:  STD  XPS_MX,X               ;INIT MUNGE VALUE
LB783:  ADDD MS_TX,U
LB785:  STD  XPS_CX,X
LB787:  LDD  #$0000
LB78A:  SUBD MS_BY,U                ;OFFSET TO CENTER OF LEFT WING
LB78C:  JSR  ASRD6
LB78F:  STD  XPS_MY,X               ;INIT MUNGE VELOCITY
LB791:  ADDD MS_TY,U
LB793:  STD  XPS_CY,X
LB795:  LDD  #$0000
LB798:  SUBD MS_CY,U                ;OFFSET TO CENTER OF LEFT WING
LB79A:  JSR  ASRD6
LB79D:  STD  XPS_MZ,X               ;INIT Z MUNGE
LB79F:  ADDD MS_TZ,U
LB7A1:  STD  XPS_CZ,X
LB7A3:  JSR  BGAM
LB7A6:  JSR  NXTFRE
;X-->EXPLOSION PARMS
LB7A9:  LDA  #TPS_TI2               ;TYPE 2, TIE FIGHTER RIGHT WING
LB7AB:  STA  XPS_TYP,X
LB7AD:  LDA  #$18
LB7AF:  STA  XPS_TMR,X
LB7B1:  LDD  MS_AY,U                ;OFFSET TO CENTER OF RIGHT WING
LB7B3:  JSR  ASRD6
LB7B6:  STD  XPS_MX,X               ;INIT MUNGE X
LB7B8:  ADDD MS_TX,U
LB7BA:  STD  XPS_CX,X
LB7BC:  LDD  MS_BY,U                ;OFFSET TO CENTER OF RIGHT WING
LB7BE:  JSR  ASRD6
LB7C1:  STD  XPS_MY,X               ;INIT Y MUNGE
LB7C3:  ADDD MS_TY,U
LB7C5:  STD  XPS_CY,X
LB7C7:  LDD  MS_CY,U                ;OFFSET TO CENTER OF RIGHT WING
LB7C9:  JSR  ASRD6
LB7CC:  STD  XPS_MZ,X               ;INIT Z MUNGE
LB7CE:  ADDD MS_TZ,U
LB7D0:  STD  XPS_CZ,X
LB7D2:  JSR  BGAM
LB7D5:  JSR  NXTFRE
;X-->EXPLOSION PARMS
LB7D8:  LDA  #TPS_TI3               ;TYPE 3, TIE FIGHTER CENTER GLOBE
LB7DA:  STA  XPS_TYP,X
LB7DC:  LDA  #$10
LB7DE:  STA  XPS_TMR,X
LB7E0:  LDD  MS_TX,U
LB7E2:  STD  XPS_CX,X
LB7E4:  STD  XPS_MX,X
LB7E6:  LDD  MS_TY,U
LB7E8:  STD  XPS_CY,X
LB7EA:  STD  XPS_MY,X
LB7EC:  LDD  MS_TZ,U
LB7EE:  STD  XPS_CZ,X
LB7F0:  STD  XPS_MZ,X
LB7F2:  LDA  XPS_MX,X               ;D:=X POSITION
LB7F4:  LDB  #$80                   ;LIMIT THE VECTORIZING
LB7F6:  LSLB
LB7F7:  ROLA
LB7F8:  BVC  LB7FE                  ;IFVS  ?OVER-NORMALIZED?
LB7FA:  RORA
LB7FB:  RORB
LB7FC:  BRA  BGAXP_40
LB7FE:  LSL  XPS_MY+1,X
LB800:  ROL  XPS_MY,X
LB802:  BVC  LB80C                  ;IFVS  ?Y IS OVER?
LB804:  ROR  XPS_MY,X
LB806:  ROR  XPS_MY+1,X             ;Y IS CORRECTED
LB808:  ASRA
LB809:  RORB                        ;UNDO X
LB80A:  BRA  BGAXP_40
LB80C:  LSL  XPS_MZ+1,X
LB80E:  ROL  XPS_MZ,X
LB810:  BVC  LB7F6                  ;VSEND  ALSO END WHEN Z TOO LARGE
LB812:  ROR  XPS_MZ,X
LB814:  ROR  XPS_MZ+1,X             ;Z IS CORRECTED
LB816:  ASR  XPS_MY,X
LB818:  ASR  XPS_MY+1,X             ;UNDO ONE Y
LB81A:  ASRA
LB81B:  RORB                        ;UNDO X ALSO

BGAXP_40:
LB81C:  SUBD XPS_CX,X               ;GET DISTANCE FROM CURRENT TO FRONTIER
LB81E:  JSR  ASRD4                  ;GO ALL THE WAY TO EDGE IN 16.
LB821:  LDB  P_RND1
LB824:  STD  XPS_MX,X
LB826:  LDD  XPS_MY,X
LB828:  SUBD XPS_CY,X
LB82A:  JSR  ASRD4
LB82D:  LDB  P_RND1
LB830:  STD  XPS_MY,X
LB832:  LDD  XPS_MZ,X
LB834:  SUBD XPS_CZ,X
LB836:  JSR  ASRD4
LB839:  LDB  P_RND1
LB83C:  STD  XPS_MZ,X
LB83E:  RTS

;------------------------------------------------------------------------------
; BGAM - HANDLE XP$M*
;------------------------------------------------------------------------------
BGAM:
LB83F:  LDD  MS_VX,U
LB841:  ADDD XPS_MX,X
LB843:  STD  XPS_MX,X
LB845:  LDD  MS_VY,U
LB847:  ADDD XPS_MY,X
LB849:  STD  XPS_MY,X
LB84B:  LDD  MS_VZ,U
LB84D:  ADDD XPS_MZ,X
LB84F:  STD  XPS_MZ,X
LB851:  RTS

;------------------------------------------------------------------------------
; BGWGXP - BEGIN WALL GUN EXPLOSION
;   BEGIN BUNKER EXPLOSION
;   (also: BGBKXP)
;------------------------------------------------------------------------------
BGWGXP:
BGBKXP:
LB852:  LDD  #(TPS_BK1*$100)+TPS_BK2 ;TYPE 1 BUNKER, TYPE 2 BUNKER
LB855:  STD  TMPTP1
LB857:  LDD  #(TPS_BK3*$100)+3      ;TYPE 3 BUNKER, Z VELOCITY OF 0C00(4*300)
LB85A:  STD  TMPTP3
LB85C:  BRA  BGBKN

;------------------------------------------------------------------------------
; BGTWXP - [note] Begin tower top explosion: TMPTP1..3 = tower piece types TPS_TW1..3 and TMPVZ = 2, then falls into
;   BGBKN, which queues the three pieces around center M_XT,YT,ZT
;------------------------------------------------------------------------------
BGTWXP:
LB85E:  LDD  #(TPS_TW1*$100)+TPS_TW2 ;TYPE 1 TOWER,TYPE 2 TOWER
LB861:  STD  TMPTP1
LB863:  LDD  #(TPS_TW3*$100)+2      ;TYPE 3 TOWER, Z VELOCITY OF 800(4*200)
LB866:  STD  TMPTP3

BGBKN:
;M.XT,YT,ZT HAVE CENTER
LB868:  JSR  NXTFRE                 ;X-->EXPLOSION QUEUE ENTRY
LB86B:  LDA  TMPTP1                 ;BUNKER PIECE 1
LB86D:  STA  XPS_TYP,X
LB86F:  LDA  #$20
LB871:  STA  XPS_TMR,X              ;LIFE TIMER
LB873:  LDD  M_XT                   ;CENTER OF EXPLOSION
LB876:  STD  XPS_CX,X
LB878:  LDD  M_YT
LB87B:  ADDA #$FE
LB87D:  STD  XPS_CY,X
LB87F:  LDD  M_ZT
LB882:  STD  XPS_CZ,X
LB884:  LDD  MS_TX+M_S1
LB887:  ADDA #$7F
LB889:  SUBD M_XT
LB88C:  JSR  ASRD5
LB88F:  LDB  P_RND1
LB892:  STD  XPS_MX,X               ;SPEED TO DESTINATION
LB894:  LDD  MS_TY+M_S1
LB897:  ADDA #$C1                   ;GO LEFT
LB899:  SUBD M_YT
LB89C:  JSR  ASRD5
LB89F:  LDB  P_RND1
LB8A2:  STD  XPS_MY,X               ;LEFT/RIGHT SPEED TO DESTINATION
LB8A4:  LDA  TMPVZ                  ;728. TO 1024., VARY AROUND 54.*120.*2/16=810.
LB8A6:  LDB  P_RND1
LB8A9:  JSR  LSLD2                  ;*4
LB8AC:  STD  XPS_MZ,X               ;VERTICAL VELOCITY
;CENTER PIECE
LB8AE:  JSR  NXTFRE                 ;X-->EXPLOSION QUEUE ENTRY
LB8B1:  LDA  TMPTP2                 ;BUNKER PIECE 2
LB8B3:  STA  XPS_TYP,X
LB8B5:  LDA  #$20
LB8B7:  STA  XPS_TMR,X              ;LIFE TIMER
LB8B9:  LDD  M_XT                   ;CENTER OF EXPLOSION
LB8BC:  ADDA #$02
LB8BE:  STD  XPS_CX,X
LB8C0:  LDD  M_YT
LB8C3:  STD  XPS_CY,X
LB8C5:  LDD  M_ZT
LB8C8:  STD  XPS_CZ,X
LB8CA:  LDD  MS_TX+M_S1
LB8CD:  ADDA #$7F
LB8CF:  SUBD M_XT
LB8D2:  JSR  ASRD5
LB8D5:  LDB  P_RND1
LB8D8:  STD  XPS_MX,X               ;SPEED TO DESTINATION
LB8DA:  LDD  MS_TY+M_S1
LB8DD:  SUBD M_YT
LB8E0:  JSR  ASRD5
LB8E3:  LDB  P_RND1
LB8E6:  STD  XPS_MY,X               ;LEFT/RIGHT SPEED TO DESTINATION
LB8E8:  LDA  TMPVZ                  ;728. TO 1024., VARY AROUND 54.*120.*2/16=810.
LB8EA:  LDB  P_RND1
LB8ED:  JSR  LSLD2                  ;*4
LB8F0:  STD  XPS_MZ,X               ;VERTICAL VELOCITY
;RIGHT PIECE
LB8F2:  JSR  NXTFRE                 ;X-->EXPLOSION QUEUE ENTRY
LB8F5:  LDA  TMPTP3                 ;BUNKER PIECE 3
LB8F7:  STA  XPS_TYP,X
LB8F9:  LDA  #$20
LB8FB:  STA  XPS_TMR,X              ;LIFE TIMER
LB8FD:  LDD  M_XT                   ;CENTER OF EXPLOSION
LB900:  STD  XPS_CX,X
LB902:  LDD  M_YT
LB905:  ADDA #$02
LB907:  STD  XPS_CY,X
LB909:  LDD  M_ZT
LB90C:  STD  XPS_CZ,X
LB90E:  LDD  MS_TX+M_S1
LB911:  ADDA #$7F
LB913:  SUBD M_XT
LB916:  JSR  ASRD5
LB919:  LDB  P_RND1
LB91C:  STD  XPS_MX,X               ;SPEED TO DESTINATION
LB91E:  LDD  MS_TY+M_S1
LB921:  ADDA #$3F                   ;GO RIGHT
LB923:  SUBD M_YT
LB926:  JSR  ASRD5
LB929:  LDB  P_RND1
LB92C:  STD  XPS_MY,X               ;LEFT/RIGHT SPEED TO DESTINATION
LB92E:  LDA  TMPVZ                  ;728. TO 1024., VARY AROUND 54.*120.*2/16=810.
LB930:  LDB  P_RND1
LB933:  JSR  LSLD2                  ;*4
LB936:  STD  XPS_MZ,X               ;VERTICAL VELOCITY
LB938:  RTS

;------------------------------------------------------------------------------
; IXPLD - ONCE PER PHASE TO CLEAR THINGS UP
;------------------------------------------------------------------------------
IXPLD:
LB939:  LDX  #XPQUE
LB93C:  LDA  #$00
LB93E:  STA  XPS_TMR,X
LB940:  LEAX XPS_IZE,X
LB942:  CMPX #XPQUEZ
LB945:  BLO  LB93C                  ;HSEND
LB947:  RTS

;------------------------------------------------------------------------------
; NXTFRE - GET NEXT FREE EXPLOSION SLOT
;------------------------------------------------------------------------------
NXTFRE:
LB948:  LDB  XP_HDQ
LB94A:  INCB                        ;BUMP TO NEXT SLOT
LB94B:  CMPB #XPS_EQ
LB94D:  BLO  LB951                  ;IFHS  ?WRAPPED?
LB94F:  LDB  #$00                   ;THEN START AT FRONT OF CIRCULAR QUEUE AGAIN
LB951:  STB  XP_HDQ
LB953:  LDA  #XPS_IZE
LB955:  MUL
LB956:  LDX  #XPQUE
LB959:  LEAX D,X                    ;X-->QUEUE ENTRY
LB95B:  RTS

;------------------------------------------------------------------------------
; MUNGE - CONTORT THE EXPLOSION MATRIX FOR VIEWING
;------------------------------------------------------------------------------
MUNGE:
LB95C:  LDD  #$14BD                 ;19.04 DEGREES ROLL
LB95F:  STD  M_SIN
LB962:  LDD  #$3C8C
LB965:  STD  M_COS
LB968:  LDD  #MS_MUNBC
LB96B:  STD  M_BIC
LB96E:  LDA  #MS_ROLL
LB970:  JSR  MGOWT
LB973:  LDD  #$0590                 ;4.99 DEGREES PITCH
LB976:  STD  M_SIN
LB979:  LDD  #$3FC2
LB97C:  STD  M_COS
LB97F:  LDD  #MS_MUNBC
LB982:  STD  M_BIC
LB985:  LDA  #MS_PTCH
LB987:  JSR  MGOWT
LB98A:  RTS

;------------------------------------------------------------------------------
; DOXPLD - PROCESS EXPLOSIONS IN PROGRESS
;------------------------------------------------------------------------------
DOXPLD:
LB98B:  LDX  #XPQUE
LB98E:  LDA  XPS_TMR,X
LB990:  BEQ  LB9A1                  ;IFNE
LB992:  DEC  XPS_TMR,X              ;COUNT DOWN TO ZERO
LB994:  LDB  XPS_TYP,X
LB996:  CMPB #(ZMV-TMV)/2
LB998:  BLO  LB99B                  ;IFHS
LB99A:  SWI                         ;REPLACE WITH LOWEST ONE (OR SET TMR TO ZERO)
LB99B:  LDU  #TMV
LB99E:  LSLB                        ;WORD POINTER
LB99F:  JSR  [B,U]
LB9A1:  LEAX XPS_IZE,X
LB9A3:  CMPX #XPQUEZ
LB9A6:  BLO  LB98E                  ;HSEND
LB9A8:  LDX  #XPQUE
LB9AB:  LDA  XPS_TMR,X
LB9AD:  BEQ  LB9B2                  ;IFNE
LB9AF:  JMP  MUNGE                  ;J A LIVE EXPLOSION KEEPS THE MATRIX ROLLING
LB9B2:  LEAX XPS_IZE,X
LB9B4:  CMPX #XPQUEZ
LB9B7:  BLO  LB9AB                  ;HSEND
;?NONE ARE ACTIVE?
LB9B9:  LDU  #M_MUN                 ;THEN RESTART THE UNIT VECTORS
LB9BC:  JSR  UNITV
LB9BF:  RTS

;------------------------------------------------------------------------------
; MVBK1 - [note] Move a bunker or tower explosion piece, X-->explosion queue entry: add XPS_MX,MY to center with
;   friction losses (velocity less 1/32), add XPS_MZ to Z (stops at ground level 0), gravity $C8 off XPS_MZ
;   (also: MVBK2, MVBK3, MVTW1, MVTW2, MVTW3)
;------------------------------------------------------------------------------
MVBK1:
MVBK2:
MVBK3:
MVTW1:
MVTW2:
MVTW3:
LB9C0:  LDD  XPS_MX,X
LB9C2:  ADDD XPS_CX,X               ;MOVE CENTER OF EXPLOSION PIECE
LB9C4:  STD  XPS_CX,X
LB9C6:  LDD  #$0000
LB9C9:  SUBD XPS_MX,X
LB9CB:  JSR  ASRD5
LB9CE:  ADDD XPS_MX,X
LB9D0:  STD  XPS_MX,X               ;FRICTION LOSSES
LB9D2:  LDD  XPS_MY,X
LB9D4:  ADDD XPS_CY,X               ;MOVE CENTER OF EXPLOSION
LB9D6:  STD  XPS_CY,X
LB9D8:  LDD  #$0000
LB9DB:  SUBD XPS_MY,X
LB9DD:  JSR  ASRD5
LB9E0:  ADDD XPS_MY,X
LB9E2:  STD  XPS_MY,X               ;FRICTION LOSSES
LB9E4:  LDD  XPS_CZ,X
LB9E6:  ADDD XPS_MZ,X
LB9E8:  BVS  LB9F1                  ;IFVC  ?VALID RESULTS?
LB9EA:  BGE  LB9EF                  ;IFLT  ?RAMMING INTO GROUND?
LB9EC:  LDD  #$0000                 ;THEN FREEZE IT AT GROUND LEVEL
LB9EF:  STD  XPS_CZ,X               ;UPDATE VERTICAL POSITION
LB9F1:  LDD  XPS_MZ,X
LB9F3:  SUBD #$00C8                 ;FORCE OF GRAVITY <54.*120.*2>/16.SQUARED FRAME
LB9F6:  STD  XPS_MZ,X
LB9F8:  RTS

;------------------------------------------------------------------------------
; MVTI1 - LEFT WING KEEP ORIGINAL VELOCITY
;   RIGHT WING KEEP ORIGINAL VELOCITY
;   CENTER GLOBE MOVE AWAY FROM LAZAR BLAST
;   (also: MVTI2, MVTI3)
;------------------------------------------------------------------------------
MVTI1:
MVTI2:
MVTI3:
LB9F9:  LDD  XPS_MX,X
LB9FB:  ADDD XPS_CX,X
LB9FD:  BVS  LBA01                  ;IFVC
LB9FF:  STD  XPS_CX,X
LBA01:  LDD  XPS_MY,X
LBA03:  ADDD XPS_CY,X
LBA05:  BVS  LBA09                  ;IFVC
LBA07:  STD  XPS_CY,X
LBA09:  LDD  XPS_MZ,X
LBA0B:  ADDD XPS_CZ,X
LBA0D:  BVS  LBA11                  ;IFVC
LBA0F:  STD  XPS_CZ,X
LBA11:  RTS

;------------------------------------------------------------------------------
; VWXPLD - VIEW OTHERS EXPLODING
;------------------------------------------------------------------------------
VWXPLD:
LBA12:  LDA  #MS_MUNBC
LBA14:  JSR  IS2UV                  ;DOWNLOAD DESTINATION MATRIX
LBA17:  LDA  #MS_CNCT
LBA19:  JSR  MGOWT                  ;CONCATENATE WITH VIEWERS MATRIX
LBA1C:  LDX  #XPQUE
LBA1F:  STX  S2_PRM
LBA21:  LDA  XPS_TMR,X
LBA23:  BEQ  LBA28                  ;IFNE  ?GOT A LIVE EXPLOSION?
LBA25:  JSR  VWXPL2
LBA28:  LDX  S2_PRM
LBA2A:  LEAX XPS_IZE,X
LBA2C:  CMPX #XPQUEZ
LBA2F:  BLO  LBA1F                  ;HSEND
LBA31:  RTS

;------------------------------------------------------------------------------
; VWXPL2 - [note] View one explosion piece, X-->explosion queue entry: PSB2 its center; if in view call its TVW
;   routine (XPS_TYP), then ADOBJ, OBJPNT, OBJDRW; if not visible clear XPS_TMR to turn it off
;------------------------------------------------------------------------------
VWXPL2:
LBA32:  LDD  XPS_CX,X
LBA34:  STD  M_X0                   ;CENTER OF THIS PIECE
LBA37:  LDD  XPS_CY,X
LBA39:  STD  M_Y0
LBA3C:  LDD  XPS_CZ,X
LBA3E:  STD  M_Z0
LBA41:  LDD  #MS_X0BC
LBA44:  STD  M_BIC
LBA47:  LDA  #MS_PSB2
LBA49:  JSR  MGOWT
LBA4C:  LDD  M_XP
LBA4F:  BMI  VWXPL2_92              ;B SPECIAL IF NOT VISIBLE
LBA51:  STD  M_XT
LBA54:  STD  M_DVD
LBA57:  LDD  M_YP
LBA5A:  STD  M_YT
LBA5D:  BPL  LBA63                  ;IFMI
LBA5F:  COMA                        ;NEGD
LBA60:  NEGB
LBA61:  SBCA #$FF
LBA63:  SUBD M_XT
LBA66:  BGE  VWXPL2_92              ;B SPECIAL IF NOT VISIBLE
LBA68:  LDD  M_ZP
LBA6B:  STD  M_ZT
LBA6E:  BPL  LBA74                  ;IFMI
LBA70:  COMA                        ;NEGD
LBA71:  NEGB
LBA72:  SBCA #$FF
LBA74:  LSRA                        ;LSRD  ALLOW Z TO BE TWICE AS HI FOR LAZAR TOWERS
LBA75:  RORB
LBA76:  SUBD M_XT
LBA79:  BGE  VWXPL2_92              ;B SPECIAL IF NOT VISIBLE
LBA7B:  LDB  XPS_TYP,X
LBA7D:  CMPB #(ZVW-TVW)/2
LBA7F:  BLO  LBA82                  ;IFHS  ?OUT OF RANGE TYP?
LBA81:  SWI                         ;REPLACE WITH TYPE 1
LBA82:  LDU  #TVW
LBA85:  LSLB                        ;WORD POINTER
LBA86:  JSR  [B,U]
LBA88:  JSR  ADOBJ                  ;MAKE SURE WE CAN USE IT
LBA8B:  JSR  OBJPNT                 ;THEN GET THE POINTS
LBA8E:  JSR  OBJDRW                 ;AND DRAW IT
LBA91:  LDD  #VGSCAL
LBA94:  STD  ,Y++
LBA96:  LDD  #VGCNTR
LBA99:  STD  ,Y++
LBA9B:  BRA  VWXPL2_98

VWXPL2_92:
LBA9D:  CLR  XPS_TMR,X              ;IF PIECE NOT VISIBLE, THEN TURN IT OFF

VWXPL2_98:
LBA9F:  RTS

;------------------------------------------------------------------------------
; VWBK1 - [note] View bunker explosion piece 1: A = TDS_BK1, branch to VWBKN
;------------------------------------------------------------------------------
VWBK1:
LBAA0:  LDA  #TDS_BK1
LBAA2:  BRA  VWBKN

;------------------------------------------------------------------------------
; VWBK2 - [note] View bunker explosion piece 2: A = TDS_BK2, branch to VWBKN
;------------------------------------------------------------------------------
VWBK2:
LBAA4:  LDA  #TDS_BK2
LBAA6:  BRA  VWBKN

;------------------------------------------------------------------------------
; VWBK3 - [note] View bunker explosion piece 3: A = TDS_BK3, branch to VWBKN
;------------------------------------------------------------------------------
VWBK3:
LBAA8:  LDA  #TDS_BK3
LBAAA:  BRA  VWBKN

;------------------------------------------------------------------------------
; VWTW1 - [note] View tower explosion piece 1: A = TDS_TW1, branch to VWTWN
;------------------------------------------------------------------------------
VWTW1:
LBAAC:  LDA  #TDS_TW1
LBAAE:  BRA  VWTWN

;------------------------------------------------------------------------------
; VWTW2 - [note] View tower explosion piece 2: A = TDS_TW2, branch to VWTWN
;------------------------------------------------------------------------------
VWTW2:
LBAB0:  LDA  #TDS_TW2
LBAB2:  BRA  VWTWN

;------------------------------------------------------------------------------
; VWTW3 - [note] View tower explosion piece 3: A = TDS_TW3, branch to VWTWN
;------------------------------------------------------------------------------
VWTW3:
LBAB4:  LDA  #TDS_TW3
LBAB6:  BRA  VWTWN

;------------------------------------------------------------------------------
; VWTWN - [note] Common part for tower pieces: BJ_ID = A, color white, then join VWBKN at VWTWN2
;------------------------------------------------------------------------------
VWTWN:
LBAB8:  STA  BJ_ID
LBABA:  LDA  #((VGCOLR&$FF00)/$100)+VGCWHT
LBABC:  BRA  VWTWN2

;------------------------------------------------------------------------------
; VWBKN - [note] Common part for bunker pieces: BJ_ID = A, color red. VWTWN2: output color (fades when XPS_TMR <= 7),
;   PSB2 the piece's shadow point (center X,Y on the ground), OBJCEN, then a scale from M_XT. X-->piece
;------------------------------------------------------------------------------
VWBKN:
LBABE:  STA  BJ_ID
LBAC0:  LDA  #((VGCOLR&$FF00)/$100)+VGCRED

VWTWN2:
LBAC2:  LDB  XPS_TMR,X              ;A:=COLOR SELECT AND OPCODE
LBAC4:  CMPB #$07
LBAC6:  BHI  LBACE                  ;IFLS  ?FADE WHEN DONE?
LBAC8:  LSLB
LBAC9:  LSLB
LBACA:  LSLB
LBACB:  LSLB                        ;UP TO 0-70
LBACC:  BRA  LBAD0                  ;ELSE
LBACE:  LDB  #$80
LBAD0:  STD  ,Y++                   ;COLOR SELECT
LBAD2:  LDD  XPS_CX,X               ;GET SHADOW IN CORRECT POSITION
LBAD4:  STD  M_X0
LBAD7:  LDD  XPS_CY,X
LBAD9:  STD  M_Y0
LBADC:  LDD  #$0000                 ;POSITION ON GROUND
LBADF:  STD  M_Z0
LBAE2:  LDD  #MS_X0BC
LBAE5:  STD  M_BIC
;***DO YOU BELIEVE THIS SIDE EFFECT?
LBAE8:  LDD  M_ZT
LBAEB:  PSHS A,B,X,U
LBAED:  LDU  M_YT
LBAF0:  LDX  M_XT
LBAF3:  LDA  #MS_PSB2
LBAF5:  JSR  MGOWT
;***HERE WE GO BACK AGAIN
LBAF8:  STX  M_XT
LBAFB:  STU  M_YT
LBAFE:  PULS A,B,X,U
LBB00:  STD  M_ZT
LBB03:  LDD  M_XP
LBB06:  STD  M_DVD
LBB09:  JSR  OBJCEN                 ;POSITION THE SHADOW FIRST, THEN SCALE ALL ELSE
LBB0C:  LDA  #$72                   ;SCALE DOWN TO MATCH GRND
LBB0E:  LDB  M_XT
LBB11:  LSLB
LBB12:  LSLB
LBB13:  STD  ,Y++
LBB15:  RTS

;------------------------------------------------------------------------------
; VWTI3 - VIEW TIE CENTER
;------------------------------------------------------------------------------
VWTI3:
LBB16:  LDB  #TDS_TI3
LBB18:  BRA  VWTIN

;------------------------------------------------------------------------------
; VWTI1 - LEFT TIE WING
;------------------------------------------------------------------------------
VWTI1:
LBB1A:  LDB  #TDS_TI1
LBB1C:  BRA  VWTIN

;------------------------------------------------------------------------------
; VWTI2 - RIGHT TIE WING
;------------------------------------------------------------------------------
VWTI2:
LBB1E:  LDB  #TDS_TI2
LBB20:  BRA  VWTIN

;------------------------------------------------------------------------------
; VWTIN - [note] Common part for TIE pieces: BJ_ID = B, color from TVWCLE indexed by XPS_TMR (VJFLS flash when beyond
;   the table), then OBJCEN. X-->explosion queue entry
;------------------------------------------------------------------------------
VWTIN:
LBB22:  STB  BJ_ID
LBB24:  LDB  XPS_TMR,X              ;SELECT A COLOR
LBB26:  CMPB #$1F
LBB28:  BLS  LBB2F                  ;IFHI  ?BEYOND THE TABLE?
LBB2A:  LDD  #VJFLS                 ;THEN REALLY FLASH
LBB2D:  BRA  LBB35                  ;ELSE
LBB2F:  LDU  #TVWCLE                ;ELSE SHOW US BEATING IT
LBB32:  LSLB
LBB33:  LDD  B,U
LBB35:  STD  ,Y++
LBB37:  JSR  OBJCEN
LBB3A:  RTS

TVWCLE:          ;VIEW EXPLODE
LBB3B:  .word (VGCOLR&$F000)+(($32&$F)*$100)+($32&$F0) ;TVWBYT 32,32,42,42,52,52,62,62
LBB3D:  .word (VGCOLR&$F000)+(($32&$F)*$100)+($32&$F0)
LBB3F:  .word (VGCOLR&$F000)+(($42&$F)*$100)+($42&$F0)
LBB41:  .word (VGCOLR&$F000)+(($42&$F)*$100)+($42&$F0)
LBB43:  .word (VGCOLR&$F000)+(($52&$F)*$100)+($52&$F0)
LBB45:  .word (VGCOLR&$F000)+(($52&$F)*$100)+($52&$F0)
LBB47:  .word (VGCOLR&$F000)+(($62&$F)*$100)+($62&$F0)
LBB49:  .word (VGCOLR&$F000)+(($62&$F)*$100)+($62&$F0)
LBB4B:  .word (VGCOLR&$F000)+(($72&$F)*$100)+($72&$F0) ;TVWBYT 72,72,82,82,92,92,0A2,0A2
LBB4D:  .word (VGCOLR&$F000)+(($72&$F)*$100)+($72&$F0)
LBB4F:  .word (VGCOLR&$F000)+(($82&$F)*$100)+($82&$F0)
LBB51:  .word (VGCOLR&$F000)+(($82&$F)*$100)+($82&$F0)
LBB53:  .word (VGCOLR&$F000)+(($92&$F)*$100)+($92&$F0)
LBB55:  .word (VGCOLR&$F000)+(($92&$F)*$100)+($92&$F0)
LBB57:  .word (VGCOLR&$F000)+(($A2&$F)*$100)+($A2&$F0)
LBB59:  .word (VGCOLR&$F000)+(($A2&$F)*$100)+($A2&$F0)
LBB5B:  .word (VGCOLR&$F000)+(($87&$F)*$100)+($87&$F0) ;TVWBYT 87,0A2,97,0A2,0A7,0A2,0C7,0A2
LBB5D:  .word (VGCOLR&$F000)+(($A2&$F)*$100)+($A2&$F0)
LBB5F:  .word (VGCOLR&$F000)+(($97&$F)*$100)+($97&$F0)
LBB61:  .word (VGCOLR&$F000)+(($A2&$F)*$100)+($A2&$F0)
LBB63:  .word (VGCOLR&$F000)+(($A7&$F)*$100)+($A7&$F0)
LBB65:  .word (VGCOLR&$F000)+(($A2&$F)*$100)+($A2&$F0)
LBB67:  .word (VGCOLR&$F000)+(($C7&$F)*$100)+($C7&$F0)
LBB69:  .word (VGCOLR&$F000)+(($A2&$F)*$100)+($A2&$F0)
LBB6B:  .word (VGCOLR&$F000)+(($A6&$F)*$100)+($A6&$F0) ;TVWBYT 0A6,0A6,0A6,0A6,0A6,0A6,0A6,0A6
LBB6D:  .word (VGCOLR&$F000)+(($A6&$F)*$100)+($A6&$F0)
LBB6F:  .word (VGCOLR&$F000)+(($A6&$F)*$100)+($A6&$F0)
LBB71:  .word (VGCOLR&$F000)+(($A6&$F)*$100)+($A6&$F0)
LBB73:  .word (VGCOLR&$F000)+(($A6&$F)*$100)+($A6&$F0)
LBB75:  .word (VGCOLR&$F000)+(($A6&$F)*$100)+($A6&$F0)
LBB77:  .word (VGCOLR&$F000)+(($A6&$F)*$100)+($A6&$F0)
LBB79:  .word (VGCOLR&$F000)+(($A6&$F)*$100)+($A6&$F0)

;------------------------------------------------------------------------------
; BGXPLN - DETH STAR VISUALS
;   TEMPORARILY START AT LAST SEQUENCE
;------------------------------------------------------------------------------
BGXPLN:
LBB7B:  LDA  #$01                   ;STARTING PHASE, 00 IS FLAG MEANING END
LBB7D:  STA  XP_PHS
LBB7F:  LDD  #$0001                 ;STARTING COUNT
LBB82:  STD  XP_CNT
LBB84:  RTS

;------------------------------------------------------------------------------
; VWXPLN - DETH STAR PRETTY STARTING  (comment at the call)
;------------------------------------------------------------------------------
VWXPLN:
LBB85:  LDA  XP_PHS
LBB87:  ASLA
LBB88:  LDX  #TXPPHS
LBB8B:  JSR  [A,X]

;------------------------------------------------------------------------------
; XP_NUL - [note] Phase 0 of TXPPHS (XP_PHS = 0 is the flag meaning end): do nothing, RTS. VWXPLN also returns through here
;------------------------------------------------------------------------------
XP_NUL:
LBB8D:  RTS

TXPPHS:
LBB8E:  .word XP_NUL, XP_PH0, XP_PH1, XP_PH2
LBB96:  .word XP_PH3

;------------------------------------------------------------------------------
; XP_PH0 - FROM DIM TO BRIGHT
;------------------------------------------------------------------------------
XP_PH0:
LBB98:  LDD  #VGCOLR+(VGCRED*$100)  ;COLOR COMMAND
LBB9B:  LDU  #VGSCAL+$400+$F0       ;STARTING SCALE COMMAND
LBB9E:  LDX  XP_CNT                 ;NUMBER OF CIRCLES
LBBA0:  JSR  DCIRCL                 ;DRAW CIRCLES
LBBA3:  LDD  XP_CNT
LBBA5:  ADDD #$0002
LBBA8:  STD  XP_CNT
LBBAA:  CMPD #$003F
LBBAE:  BHS  LBBBA                  ;IFLO  KEEP GOING
LBBB0:  LDD  #$0001
LBBB3:  STD  XP_CNT
LBBB5:  INC  XP_PHS
LBBB7:  JSR  AUDDF                  ;FINAL DETH STAR EXPLOSION
LBBBA:  RTS

;------------------------------------------------------------------------------
; XP_PH1 - BRIGHT BLUE FROM CENTER,RED EXPANSION
;------------------------------------------------------------------------------
XP_PH1:
LBBBB:  LDX  XP_CNT                 ;DRAW BLUE CIRCLES
LBBBD:  LDD  #(VGCOLR+(VGCBLU*$100))|$FF
LBBC0:  LDU  #VGSCAL+$400+$F0
LBBC3:  JSR  DCIRCL
LBBC6:  LDD  XP_CNT
LBBC8:  ADDD #$0002
LBBCB:  STD  XP_CNT
LBBCD:  CMPD #$003F
LBBD1:  BHS  LBC0B                  ;IFLO  DRAW SOME RED
LBBD3:  LDB  #$3F
LBBD5:  SUBB XP_CNT+1
LBBD7:  CLRA
LBBD8:  TFR  D,X
LBBDA:  LDD  #(VGCOLR+(VGCRED*$100))|$FF
LBBDD:  JSR  DCIRCL
LBBE0:  LDD  XP_CNT                 ;RED EXPANSION RINGS
LBBE2:  ASLB                        ;ASLD
LBBE3:  ROLA
LBBE4:  ASLB                        ;ASLD
LBBE5:  ROLA
LBBE6:  ASLB                        ;ASLD
LBBE7:  ROLA
LBBE8:  COMA
LBBE9:  COMB
LBBEA:  BMI  LBBEF                  ;IFPL
LBBEC:  DECA
LBBED:  ORB  #$80
LBBEF:  ADDD #VGSCAL+$400+$70
LBBF2:  TSTB
LBBF3:  BMI  LBBF8                  ;IFPL
LBBF5:  DECA
LBBF6:  ANDB #$7F
LBBF8:  TFR  D,U
LBBFA:  LDD  XP_CNT
LBBFC:  LSRB
LBBFD:  LSRB
LBBFE:  ANDB #$07
LBC00:  EORB #$07
LBC02:  INCB
LBC03:  TFR  D,X
LBC05:  LDD  #(VGCOLR+(VGCRED*$100))|$FF
LBC08:  JSR  DRING                  ;DRAW RINGS
LBC0B:  LDD  XP_CNT
LBC0D:  CMPD #$003F
LBC11:  BLO  LBC1D                  ;IFHS  SETUP FOR NEXT PHASE
LBC13:  LDD  #$0001
LBC16:  STD  XP_CNT
LBC18:  INC  XP_PHS
LBC1A:  JSR  AUDDF
LBC1D:  RTS

;------------------------------------------------------------------------------
; XP_PH2 - BRIGHT WHITE FROM CENTER,BLUE EXPANSION
;------------------------------------------------------------------------------
XP_PH2:
LBC1E:  LDX  XP_CNT                 ;DRAW WHITE CIRCLES
LBC20:  LDD  #(VGCOLR+(VGCWHT*$100))|$FF
LBC23:  LDU  #VGSCAL+$400+$70
LBC26:  JSR  DCIRCL
LBC29:  LDD  XP_CNT
LBC2B:  ADDD #$0003
LBC2E:  STD  XP_CNT
LBC30:  CMPD #$003F
LBC34:  BHS  LBC43                  ;IFLO  DRAW SOME BLUE
LBC36:  LDB  #$3F
LBC38:  SUBB XP_CNT+1
LBC3A:  CLRA
LBC3B:  TFR  D,X
LBC3D:  LDD  #(VGCOLR+(VGCBLU*$100))|$FF
LBC40:  JSR  DCIRCL
LBC43:  LDD  XP_CNT                 ;BLUE EXPANSION RINGS
LBC45:  CMPD #$003F
LBC49:  BHS  LBC72                  ;IFLO  DRAW EM
LBC4B:  ASLB                        ;ASLD
LBC4C:  ROLA
LBC4D:  ASLB                        ;ASLD
LBC4E:  ROLA
LBC4F:  ASLB                        ;ASLD
LBC50:  ROLA
LBC51:  COMA
LBC52:  COMB
LBC53:  BMI  LBC58                  ;IFPL
LBC55:  DECA
LBC56:  ORB  #$80
LBC58:  ADDD #VGSCAL+$400+$70
LBC5B:  TSTB
LBC5C:  BMI  LBC61                  ;IFPL
LBC5E:  DECA
LBC5F:  ANDB #$7F
LBC61:  TFR  D,U
LBC63:  LDD  XP_CNT
LBC65:  ANDB #$0F
LBC67:  EORB #$0F
LBC69:  INCB
LBC6A:  TFR  D,X
LBC6C:  LDD  #(VGCOLR+(VGCBLU*$100))|$FF
LBC6F:  JSR  DRING                  ;DRAW RINGS
LBC72:  LDD  XP_CNT
LBC74:  CMPD #$0050
LBC78:  BLO  LBC84                  ;IFHS  SETUP FOR NEXT PHASE
LBC7A:  LDD  #$0080
LBC7D:  STD  XP_CNT
LBC7F:  INC  XP_PHS
LBC81:  JSR  AUDDF
LBC84:  RTS

;------------------------------------------------------------------------------
; XP_PH3 - CONTINUALLY EXPANDING WHITE RINGS
;------------------------------------------------------------------------------
XP_PH3:
LBC85:  LDD  XP_CNT
LBC87:  SUBD #$0004
LBC8A:  STD  XP_CNT
LBC8C:  CMPD #$0008
LBC90:  BLO  LBCA9                  ;IFHS  CONTINUE THIS EXPLOSION PHASE
LBC92:  ADDD #VGSCAL+$300
LBC95:  TFR  D,U
LBC97:  LDD  XP_CNT
LBC99:  LSRA                        ;LSRD
LBC9A:  RORB
LBC9B:  ANDB #$3F
LBC9D:  EORB #$3F
LBC9F:  TFR  D,X
;FINAL EXPLOSION
LBCA1:  LDD  #(VGCOLR+(VGCWHT*$100))|$FF
LBCA4:  JSR  DRING
LBCA7:  BRA  LBCAD                  ;ELSE
LBCA9:  LDA  #$00                   ;NULL PHASE, ALL DONE
LBCAB:  STA  XP_PHS
LBCAD:  RTS

;------------------------------------------------------------------------------
; DCIRCL - DCIRCL
;------------------------------------------------------------------------------
DCIRCL:
LBCAE:  STD  ,Y++
LBCB0:  LDD  #VGOFFY&$1FFF          ;Y OFFSET FOR GAME'S SCREEN CENTER
LBCB3:  STD  ,Y++
LBCB5:  LDD  #$0000                 ;NO OFFSET FOR X
LBCB8:  STD  ,Y++
LBCBA:  STU  ,Y++                   ;SCALE
LBCBC:  LDD  #VJBCR2                ;BASE CIRCLE WITHOUT COLOR
LBCBF:  STD  ,Y++
LBCC1:  LEAU -$2,U
LBCC3:  LEAX -$1,X
LBCC5:  BNE  LBCB0                  ;EQEND
LBCC7:  RTS

;------------------------------------------------------------------------------
; DRING - DRING
;------------------------------------------------------------------------------
DRING:
LBCC8:  STD  ,Y++
LBCCA:  LDD  #VGOFFY&$1FFF          ;Y OFFSET FOR GAME'S SCREEN CENTER
LBCCD:  STD  ,Y++
LBCCF:  LDD  #$0000                 ;NO OFFSET FOR X
LBCD2:  STD  ,Y++
LBCD4:  STU  ,Y++
LBCD6:  LDD  #VJBCR2                ;BASE STAR CIRCLE WITHOUT COLOR COMMAND
LBCD9:  STD  ,Y++
LBCDB:  TFR  U,D
LBCDD:  SUBD #$0004
LBCE0:  ANDB #$7F
LBCE2:  TFR  D,U
LBCE4:  LEAX -$1,X
LBCE6:  BNE  LBCCA                  ;EQEND
LBCE8:  RTS

;==============================================================================
; MODULE WSXMT   WSXMT.MAC
;   XMIT WITH SOUND BOARD
;==============================================================================

;------------------------------------------------------------------------------
; DOXMT - DOXMT - XMT TO SOUND BOARD
;   A := ID OF REQUESTED SOUND
;   ALL INDEX REGS MUST BE SAVED
;   ABOUT 50 CYCLE LATENCY FOR SOUND BOARD
;   USE SAFETY FACTOR OF 4 FOR 200 CYCLES
;   15 CYCLES PER FOLLOWING LOOP*14. IS 210.
;------------------------------------------------------------------------------
DOXMT:
LBCE9:  LDB  #$0E                   ;TIME OUT THE SOUND BOARD
LBCEB:  TST  R_STAS                 ;D7 HI SAYS PREVIOUS XMT STILL THERE
LBCEE:  BPL  DOXMT_30               ;SKIP OUT WHEN ROOM FOR MORE DATA
LBCF0:  DECB
LBCF1:  BNE  LBCEB                  ;EQEND
LBCF3:  LDA  #$00                   ;TOOK TOO LONG TO PROCESS,

DOXMT_30:
;SO SOFTWARE RESET SOUND BOARD
LBCF5:  STA  W_XMTS                 ;SHIP IT OUT
LBCF8:  RTS

;------------------------------------------------------------------------------
; AUDTST - SNDPBX - XMT,RCV ROUTINE TAGS
;   USE POKEY AND SPEECH RIGHT AWAY FOR IMPATIENT TECHS
;------------------------------------------------------------------------------
AUDTST:
LBCF9:  LDA  #IDATST                ;AUD TST  SOUND EFFECT POKEY TEST TONES
LBCFB:  JMP  DOXMT

;------------------------------------------------------------------------------
; PMTST - [note] Request music channel POKEY test tones: A = IDPTST, jump to DOXMT
;------------------------------------------------------------------------------
PMTST:
LBCFE:  LDA  #IDPTST                ;PM TST  MUSIC CHANNEL POKEY TEST TONES
LBD00:  JMP  DOXMT

;------------------------------------------------------------------------------
; SPKALW - REST OF VOICE
;------------------------------------------------------------------------------
SPKALW:
LBD03:  LDA  #IDSALW                ;SPK ALW  ALWAYS
LBD05:  JMP  DOXMT

;------------------------------------------------------------------------------
; SPKELE - SPK BRE ;BREATH OF VADER
;------------------------------------------------------------------------------
SPKELE:
LBD08:  LDA  #IDSELE                ;SPK ELE  ELEPHANT PASS-BY SOUND
LBD0A:  JMP  DOXMT

;------------------------------------------------------------------------------
; SPKFOA - SAY FORCE WILL BE WITH YOU ALWAYS  (comment at the call)
;------------------------------------------------------------------------------
SPKFOA:
LBD0D:  LDA  #IDSFOA                ;SPK FOA  THE FORCE WILL BE WITH YOU / ALWAYS
LBD0F:  JMP  DOXMT

;------------------------------------------------------------------------------
; SPKFOR - 'THE FORCE WILL BE WITH YOU'  (comment at the call)
;------------------------------------------------------------------------------
SPKFOR:
LBD12:  LDA  #IDSFOR                ;SPK FOR  THE FORCE WILL BE WITH YOU
LBD14:  JMP  DOXMT

;------------------------------------------------------------------------------
; SPKGRE - SPK GET ;GET SET UP FOR YOUR ATTACK RUN
;------------------------------------------------------------------------------
SPKGRE:
LBD17:  LDA  #IDSGRE                ;SPK GRE  GREAT SHOT KID, THAT WAS 1 IN A MILLION
LBD19:  JMP  DOXMT

;------------------------------------------------------------------------------
; SPKHAV - I HAVE YOU NOW  (comment at the call)
;------------------------------------------------------------------------------
SPKHAV:
LBD1C:  LDA  #IDSHAV                ;SPK HAV  BREATH / I HAVE YOU KNOW / BREATH
LBD1E:  JMP  DOXMT

;------------------------------------------------------------------------------
; SPKHIT - IM HIT BUT NOT BAD, R2 SEE WHAT YOU CAN DO  (comment at the call)
;------------------------------------------------------------------------------
SPKHIT:
LBD21:  LDA  #IDSHIT                ;SPK HIT  I'M HIT BUT NOT BAD, R2 SEE WHAT YOU CAN DO WITH IT
LBD23:  JMP  DOXMT

;------------------------------------------------------------------------------
; SPKI - [note] Request init of speech chip: A = IDSI, jump to DOXMT
;------------------------------------------------------------------------------
SPKI:
LBD26:  LDA  #IDSI                  ;SPK I  INIT SPEECH CHIP
LBD28:  JMP  DOXMT

;------------------------------------------------------------------------------
; SPKIMO - I'M ON THE LEADER  (comment at the call)
;------------------------------------------------------------------------------
SPKIMO:
LBD2B:  LDA  #IDSIMO                ;SPK IMO  BREATH / I'M ON THE LEADER / BREATH
LBD2D:  JMP  DOXMT

;------------------------------------------------------------------------------
; SPKLET - LET GO LUKE  (comment at the call)
;------------------------------------------------------------------------------
SPKLET:
LBD30:  LDA  #IDSLET                ;SPK LET  LET GO LUKE
LBD32:  JMP  DOXMT

;------------------------------------------------------------------------------
; SPKLOS - I'VE LOST R2  (comment at the call)
;------------------------------------------------------------------------------
SPKLOS:
LBD35:  LDA  #IDSLOS                ;SPK LOS  I'VE LOST R2
LBD37:  JMP  DOXMT

;------------------------------------------------------------------------------
; SPKR2N - R2 SWEARS AT PLAYER FOR MISSING EXHAUST PORT  (comment at the call)
;------------------------------------------------------------------------------
SPKR2N:
LBD3A:  LDA  #IDSR2N                ;SPK R2N  R2 NO
LBD3C:  JMP  DOXMT

;------------------------------------------------------------------------------
; SPKR2T - R2 TRY AND INCREASE THE POWER  (comment at the call)
;------------------------------------------------------------------------------
SPKR2T:
LBD3F:  LDA  #IDSR2T                ;SPK R2T  R2, TRY AND INCREASE THE POWER
LBD41:  JMP  DOXMT

;------------------------------------------------------------------------------
; SPKRED - SPK REB ;REBEL BASE, 1 MINUTE AND CLOSING
;------------------------------------------------------------------------------
SPKRED:
LBD44:  LDA  #IDSRED                ;SPK RED  RED FIVE STANDING BY
LBD46:  JMP  DOXMT

;------------------------------------------------------------------------------
; SPKREM - SAY "REMEMBER..."  (comment at the call)
;------------------------------------------------------------------------------
SPKREM:
LBD49:  LDA  #IDSREM                ;SPK REM  REMEMBER
LBD4B:  JMP  DOXMT

;------------------------------------------------------------------------------
; SPKSHK - SPK SCP ;MY SCOPE'S NEGATIVE, I DON'T SEE ANYTHING
;------------------------------------------------------------------------------
SPKSHK:
LBD4E:  LDA  #IDSSHK                ;SPK SHK  I CAN'T SHAKE HIM
LBD50:  JMP  DOXMT

;------------------------------------------------------------------------------
; SPKSIZ - /LOOK AT THE SIZE OF THAT THING/  (comment at the call)
;------------------------------------------------------------------------------
SPKSIZ:
LBD53:  LDA  #IDSSIZ                ;SPK SIZ  LOOK AT THE SIZE OF THAT THING
LBD55:  JMP  DOXMT

;------------------------------------------------------------------------------
; SPKSKP - SKIP ANY WAITING VOICES  (comment at the calls)
;   SKIP ANY OTHER VOICES  (another call)
;------------------------------------------------------------------------------
SPKSKP:
LBD58:  LDA  #IDSSKP                ;SPK SKP  SKIP OVER ANY WAITING SPEECH
LBD5A:  JMP  DOXMT

;------------------------------------------------------------------------------
; SPKSTA - STAY IN ATTACK FORMATION  (comment at the call)
;------------------------------------------------------------------------------
SPKSTA:
LBD5D:  LDA  #IDSSTA                ;SPK STA  BREATH / STAY IN ATTACK FORMATION / BREATH
LBD5F:  JMP  DOXMT

;------------------------------------------------------------------------------
; SPKSTR - THE FORCE IS STRONG WITH THIS ONE  (comment at the call)
;------------------------------------------------------------------------------
SPKSTR:
LBD62:  LDA  #IDSSTR                ;SPK STR  BREATH / THE FORCE IS STRONG WITH THIS ONE / BREATH
LBD64:  JMP  DOXMT

;------------------------------------------------------------------------------
; SPKTHI - SPK SWI ;SWITCH YOUR DEFLECTORS ON, DOUBLE FRONT
;------------------------------------------------------------------------------
SPKTHI:
LBD67:  LDA  #IDSTHI                ;SPK THI  THIS IS RED FIVE, I'M GOING IN
LBD69:  JMP  DOXMT

;------------------------------------------------------------------------------
; SPKTRU - LUKE, TRUST ME  (comment at the call)
;------------------------------------------------------------------------------
SPKTRU:
LBD6C:  LDA  #IDSTRU                ;SPK TRU  LUKE TRUST ME
LBD6E:  JMP  DOXMT

;------------------------------------------------------------------------------
; SPKUSE - USE THE FORCE LUKE  (comment at the call)
;------------------------------------------------------------------------------
SPKUSE:
LBD71:  LDA  #IDSUSE                ;SPK USE  USE THE FORCE, LUKE
LBD73:  JMP  DOXMT

;------------------------------------------------------------------------------
; SPKYAU - SPK YAH ;YAHOO
;------------------------------------------------------------------------------
SPKYAU:
LBD76:  LDA  #IDSYAU                ;SPK YAU  YAHOO / YOU'RE ALL CLEAR KID
LBD78:  JMP  DOXMT

;------------------------------------------------------------------------------
; PMBEN - SPK YOU ;YOU'RE ALL CLEAR KID
;   MUSIC
;------------------------------------------------------------------------------
PMBEN:
LBD7B:  LDA  #IDPBEN                ;PM BEN  BEN THEME:START TOWER
LBD7D:  JMP  DOXMT

;------------------------------------------------------------------------------
; PMCNT - CANTINA MUSIC  (comment at the call)
;------------------------------------------------------------------------------
PMCNT:
LBD80:  LDA  #IDPCNT                ;PM CNT  CANTENA: HIGH SCORE
LBD82:  JMP  DOXMT

;------------------------------------------------------------------------------
; PMDAR - THEN DO DARTH THEME  (comment at the call)
;------------------------------------------------------------------------------
PMDAR:
LBD85:  LDA  #IDPDAR                ;PM DAR  LORD VADER'S THEME
LBD87:  JMP  DOXMT

;------------------------------------------------------------------------------
; PMDES - [note] Request descent into Deth Star music: A = IDPDES, jump to DOXMT
;------------------------------------------------------------------------------
PMDES:
LBD8A:  LDA  #IDPDES                ;PM DES  DESCENT INTO DETH STAR
LBD8C:  JMP  DOXMT

;------------------------------------------------------------------------------
; PMEND - START END OF DETH STAR MUSIC  (comment at the call)
;------------------------------------------------------------------------------
PMEND:
LBD8F:  LDA  #IDPEND                ;PM END  AFTER DEATH STAR EXPLOSION
LBD91:  JMP  DOXMT

;------------------------------------------------------------------------------
; PM4TH - BATTLE MUSIC IN FOURTHS  (comment at the call)
;------------------------------------------------------------------------------
PM4TH:
LBD94:  LDA  #IDP4TH                ;PM 4TH  BATTLE MUSIC IN FOURTHS: GROUND TOWERS
LBD96:  JMP  DOXMT

;------------------------------------------------------------------------------
; PMREB - FINISH GROUND WITH REBEL  (comment at the call)
;------------------------------------------------------------------------------
PMREB:
LBD99:  LDA  #IDPREB                ;PM REB  REBEL SHIP THEME: TRANSITION INTO TRENCH
LBD9B:  JMP  DOXMT

;------------------------------------------------------------------------------
; PMRRP - THEN DO REBEL REPEAT THEME  (comment at the call)
;------------------------------------------------------------------------------
PMRRP:
LBD9E:  LDA  #IDPRRP                ;PM RRP  REBEL THEME WITH FAST REPEATS: TRANSIT INTO TRENCH
LBDA0:  JMP  DOXMT

;------------------------------------------------------------------------------
; PMSF2 - SOUND THE DEATH KNELL  (comment at the call)
;------------------------------------------------------------------------------
PMSF2:
LBDA3:  LDA  #IDPSF2                ;PM SF2  SPECIAL EFFECT 2: FIRING INTO EXHAUST PORT
LBDA5:  JMP  DOXMT

;------------------------------------------------------------------------------
; PMTH5 - THEME MUSIC  (comment at the call)
;------------------------------------------------------------------------------
PMTH5:
LBDA8:  LDA  #IDPTH5                ;PM TH5  MAIN THEME,START OF GAME
LBDAA:  JMP  DOXMT

;------------------------------------------------------------------------------
; PMTHB - THEME B FOLLOWS MAIN THEME  (comment at the call)
;------------------------------------------------------------------------------
PMTHB:
LBDAD:  LDA  #IDPTHB                ;PM THB  THEME, TYPE B: SPACE WAVE
LBDAF:  JMP  DOXMT

;------------------------------------------------------------------------------
; AUDCR - AUDIO SPECIAL EFFECTS
;------------------------------------------------------------------------------
AUDCR:
LBDB2:  LDA  #IDACR                 ;AUD CR  CRASH INTO BRIDGE OR TOWER
LBDB4:  JMP  DOXMT

;------------------------------------------------------------------------------
; AUDDF - FINAL DETH STAR EXPLOSION  (comment at the call)
;------------------------------------------------------------------------------
AUDDF:
LBDB7:  LDA  #IDADF                 ;AUD DF  DETH STAR FINAL EXPLOSION
LBDB9:  JMP  DOXMT

;------------------------------------------------------------------------------
; AUDDR - AUD DP ;DETH STAR PRELIM EXPLODE
;------------------------------------------------------------------------------
AUDDR:
LBDBC:  LDA  #IDADR                 ;AUD DR  R2 DEAD
LBDBE:  JMP  DOXMT

;------------------------------------------------------------------------------
; AUDNAY - [note] Request nay (test fail) sound: A = IDANAY, jump to DOXMT
;------------------------------------------------------------------------------
AUDNAY:
LBDC1:  LDA  #IDANAY                ;AUD NAY  NAY - TEST FAIL
LBDC3:  JMP  DOXMT

;------------------------------------------------------------------------------
; AUDPB - APPROACH OF PASSBY SOUND  (comment at the call)
;------------------------------------------------------------------------------
AUDPB:
LBDC6:  LDA  #IDAPB                 ;AUD PB  PASS BY
LBDC8:  JMP  DOXMT

;------------------------------------------------------------------------------
; AUDPBZ - THEN KILL ANY PASSBY SOUND  (comment at the call)
;------------------------------------------------------------------------------
AUDPBZ:
LBDCB:  LDA  #IDAPBZ                ;AUD PBZ  STOP PASSBY SOUND
LBDCD:  JMP  DOXMT

;------------------------------------------------------------------------------
; AUDPF - TOWER PFFFTS  (comment at the call)
;   BUNKER PFFFTS  (another call)
;------------------------------------------------------------------------------
AUDPF:
LBDD0:  LDA  #IDAPF                 ;AUD PF  TOWER PFFFT
LBDD2:  JMP  DOXMT

;------------------------------------------------------------------------------
; AUDPH - OTHER POKEY ASSIST TO PROTONING PORTHOLE  (comment at the call)
;   PORTHOLE SHOT WHEN ENDING INITIALS  (another call)
;------------------------------------------------------------------------------
AUDPH:
LBDD5:  LDA  #IDAPH                 ;AUD PH  PORTHOLE (ASSISTS PMSF2)
LBDD7:  JMP  DOXMT

;------------------------------------------------------------------------------
; AUDPS - AUD PM ;PASS BY MEDIUM ;NOT NO MORE
;------------------------------------------------------------------------------
AUDPS:
LBDDA:  LDA  #IDAPS                 ;AUD PS  PASS BY SHORT
LBDDC:  JMP  DOXMT

;------------------------------------------------------------------------------
; AUDRC - GAS AT 1 COOKS R2  (comment at the call)
;------------------------------------------------------------------------------
AUDRC:
LBDDF:  LDA  #IDARC                 ;AUD RC  R2 COOKED
LBDE1:  JMP  DOXMT

;------------------------------------------------------------------------------
; AUDRD - R2 DONE  (comment at the call)
;------------------------------------------------------------------------------
AUDRD:
LBDE4:  LDA  #IDARD                 ;AUD RD  R2 DONE
LBDE6:  JMP  DOXMT

;------------------------------------------------------------------------------
; AUDRS - R2 SHAVE  (comment at the call)
;------------------------------------------------------------------------------
AUDRS:
LBDE9:  LDA  #IDARS                 ;AUD RS  R2 SHAVE, YES SOUND
LBDEB:  JMP  DOXMT

;------------------------------------------------------------------------------
; AUDRY - [note] Request R2 yes sound: A = IDARY, jump to DOXMT
;------------------------------------------------------------------------------
AUDRY:
LBDEE:  LDA  #IDARY                 ;AUD RY  R2 YES SOUND
LBDF0:  JMP  DOXMT

;------------------------------------------------------------------------------
; AUDSH - SOUND OUR BEING HIT BY A GUN  (comment at the call)
;------------------------------------------------------------------------------
AUDSH:
LBDF3:  LDA  #IDASH                 ;AUD SH  SHIELDS
LBDF5:  JMP  DOXMT

;------------------------------------------------------------------------------
; AUDSS - HIT ALIEN SHOT  (comment at the call)
;   SHOOTING ENEMY SHOT SOUND, RUBBING IT OUT  (another call)
;------------------------------------------------------------------------------
AUDSS:
LBDF8:  LDA  #IDASS                 ;AUD SS  PLAYER SHOT ALIEN SHOTS
LBDFA:  JMP  DOXMT

;------------------------------------------------------------------------------
; AUDSX - SMALL EXPLOSION  (comment at the call)
;   SMALL EXPLOSION FOR HITTING BUNKER  (another call)
;------------------------------------------------------------------------------
AUDSX:
LBDFD:  LDA  #IDASX                 ;AUD SX  ALIEN SHIP EXPLODE
LBDFF:  JMP  DOXMT

;------------------------------------------------------------------------------
; AUDTC - TIE FIGHTER CANNONS  (comment at the call)
;------------------------------------------------------------------------------
AUDTC:
LBE02:  LDA  #IDATC                 ;AUD TC  TIE FIGHTER CANNON
LBE04:  JMP  DOXMT

;------------------------------------------------------------------------------
; AUDTCZ - TIE FIGHTER CANNON STOPPED  (comment at the call)
;------------------------------------------------------------------------------
AUDTCZ:
LBE07:  LDA  #IDATCZ                ;AUD TCZ  TIE FIGHTER CANNON END SOUND
LBE09:  JMP  DOXMT

;------------------------------------------------------------------------------
; AUDTH - THRUST TOWARDS DETH STAR  (comment at the call)
;------------------------------------------------------------------------------
AUDTH:
LBE0C:  LDA  #IDATH                 ;AUD TH  THRUST TO DETH STAR
LBE0E:  JMP  DOXMT

;------------------------------------------------------------------------------
; AUDTL - TOWER LAZARS  (comment at the calls)
;   USE TOWER LAZARS FOR NOW  (another call)
;------------------------------------------------------------------------------
AUDTL:
LBE11:  LDA  #IDATL                 ;AUD TL  TOWER LAZARS
LBE13:  JMP  DOXMT

;------------------------------------------------------------------------------
; AUDXL - START XWING LASAR  (comment at the call)
;   LAZAR SOUND WHEN SHOOTING INITIALS  (another call)
;------------------------------------------------------------------------------
AUDXL:
LBE16:  LDA  #IDAXL                 ;AUD XL  X-WING LAZARS
LBE18:  JMP  DOXMT

;------------------------------------------------------------------------------
; AUDYEA - AUD XLZ ;END OF X-WING LAZARS
;------------------------------------------------------------------------------
AUDYEA:
LBE1B:  LDA  #IDAYEA                ;AUD YEA  YAY - TEST PASS
LBE1D:  JMP  DOXMT

;==============================================================================
; MODULE TCEROM   TCEROM.MAC
;==============================================================================

;------------------------------------------------------------------------------
; EEACC - DISPLAY ACCOUNTING INFO
;------------------------------------------------------------------------------
EEACC:
LBE20:  LDA  #MS_ACC
LBE22:  JSR  MESSON
LBE25:  INCA
LBE26:  CMPA #MS_OPT
LBE28:  BLO  LBE22                  ;HSEND
LBE2A:  LDA  #MS_XIT                ;EXIT MESSAGE
LBE2C:  JSR  MESSON
LBE2F:  LDD  #VGCOLR+(VGCRED*$100)  ;SETUP COLOR FOR DATA MESSAGES
LBE32:  STD  ,Y++
LBE34:  LDX  #AMECH                 ;START WITH AUX COIN DATA
LBE37:  LDU  #T_ACCP                ;TABLE OF POSITIONS
LBE3A:  LDD  ,U++                   ;SET POSITION
LBE3C:  STD  ,Y++
LBE3E:  LDD  #$0030
LBE41:  STD  ,Y++
LBE43:  STU  TEMP                   ;SAVE U--- VWNIBL ALTERS U
LBE46:  LDB  #$05
LBE48:  STB  BT_SUP
LBE4A:  LDB  #$05                   ;VIEW 6 NIBBLES
LBE4C:  LDA  ,X+
LBE4E:  JSR  VWNIBL
LBE51:  DECB
LBE52:  BPL  LBE4C                  ;MIEND
LBE54:  LDD  #VGCNTR
LBE57:  STD  ,Y++
LBE59:  LDU  TEMP                   ;GET POINTER TO POS TABLE BACK
LBE5C:  CMPX #TTIME
LBE5F:  BLO  LBE3A                  ;HSEND
;DISPLAY HIGHEST LEVEL ATTAINED
LBE61:  LDD  T_ACCP+6
LBE64:  STD  ,Y++
LBE66:  LDD  #$013C
LBE69:  STD  ,Y++
LBE6B:  LDA  #$01
LBE6D:  STA  BT_SUP                 ;SUPRESS 1 DIGIT
LBE6F:  LDA  ENDGAM                 ;BCD VALUE OF HIGHEST WAVE ATTAINED ( HI NIBL )
LBE72:  JSR  VWNIBL
LBE75:  LDA  ENDGAM+1               ;LO NIBL
LBE78:  JSR  VWNIBL
LBE7B:  LDD  #VGCNTR
LBE7E:  STD  ,Y++
;GET TOTAL COINS PAID
LBE80:  LDX  #RMECH                 ;GET RIGHT MECH DATA INTO TEMP
LBE83:  JSR  EETEMP
LBE86:  LDU  #TEMP2                 ;GET LEFT MECH DATA INTO TEMP2
LBE89:  LDX  #LMECH
LBE8C:  JSR  EETMP2
LBE8F:  LDA  TEMP+2                 ;3 BYTE ADD, RESULT IN TEMP
LBE92:  ADDA TEMP2+2
LBE95:  DAA
LBE96:  STA  TEMP+2
LBE99:  LDA  TEMP+1
LBE9C:  ADCA TEMP2+1
LBE9F:  DAA
LBEA0:  STA  TEMP+1
LBEA3:  LDA  TEMP                   ;NOW THE MSB
LBEA6:  ADCA TEMP2
LBEA9:  DAA
LBEAA:  STA  TEMP
;DISPLAY TOTAL COINS
LBEAD:  LDD  T_ACCP+8               ;POSITION
LBEB0:  STD  ,Y++
LBEB2:  LDD  #$0030
LBEB5:  STD  ,Y++
LBEB7:  LDB  #$05
LBEB9:  STB  BT_SUP
LBEBB:  LDA  TEMP                   ;DATA
LBEBE:  JSR  VWBYTE
LBEC1:  LDA  TEMP+1
LBEC4:  JSR  VWBYTE
LBEC7:  LDA  TEMP+2
LBECA:  JSR  VWBYTE
LBECD:  LDD  #VGCNTR                ;CENTER
LBED0:  STD  ,Y++
LBED2:  LDX  #TTIME                 ;DISPLAY TOTAL GAME TIME
LBED5:  JSR  EETEMP                 ;MOVE IT TO TEMP
LBED8:  JSR  TMPMUL                 ;GOT TO MULTIPLY BY 4 FOR SECONDS
LBEDB:  LDD  T_ACCP+14              ;POSITION IT
LBEDE:  STD  ,Y++
LBEE0:  LDD  #$0030
LBEE3:  STD  ,Y++
LBEE5:  LDB  #$07
LBEE7:  STB  BT_SUP
LBEE9:  LDA  TEMP
LBEEC:  JSR  VWBYTE
LBEEF:  LDA  TEMP+1
LBEF2:  JSR  VWBYTE
LBEF5:  LDA  TEMP+2
LBEF8:  JSR  VWBYTE
LBEFB:  LDA  TEMP+3
LBEFE:  JSR  VWBYTE
LBF01:  LDD  #VGCNTR
LBF04:  STD  ,Y++
LBF06:  LDX  #TIMEON                ;DISPLAY TOTAL TIME ON
LBF09:  JSR  EETEMP                 ;MOVE IT TO TEMP
LBF0C:  JSR  TMPMUL                 ;GOT TO MULTIPLY BY 4 FOR SECONDS
LBF0F:  LDD  T_ACCP+16              ;POSITION IT
LBF12:  STD  ,Y++
LBF14:  LDD  #$0030
LBF17:  STD  ,Y++
LBF19:  LDB  #$07
LBF1B:  STB  BT_SUP
LBF1D:  LDA  TEMP
LBF20:  JSR  VWBYTE
LBF23:  LDA  TEMP+1
LBF26:  JSR  VWBYTE
LBF29:  LDA  TEMP+2
LBF2C:  JSR  VWBYTE
LBF2F:  LDA  TEMP+3
LBF32:  JSR  VWBYTE
LBF35:  LDD  #VGCNTR
LBF38:  STD  ,Y++
;CALCULATE AND SHOW AVERAGE GAME TIME
LBF3A:  LDX  #GAMES-2               ;MOVE NUMBER OF GAMES PLAYED TO TEMP+1
LBF3D:  JSR  EETEMP
LBF40:  CLR  TEMP                   ;LEADING 0
LBF43:  LDA  TEMP+1                 ;NUMBER OF GAMES = 00?
LBF46:  ORA  TEMP+2
LBF49:  ORA  TEMP+3
LBF4C:  BEQ  LBF7C                  ;IFNE  NO, THEN I GUESS I WON'T DIVIDE BY 0
LBF4E:  LDX  #TTIME                 ;GET TOTAL GAME TIME TO TEMP2
LBF51:  LDU  #TEMP2
LBF54:  JSR  EETMP2
LBF57:  JSR  DIVIDE                 ;TEMP2/TEMP RESULT IN TEMP ( GAME TIME/# OF GAMES)
;ADJUST ANSWER FOR M:S FORMAT
LBF5A:  LDA  TEMP
LBF5D:  ANDA #$0F
LBF5F:  CMPA #$0F                   ;E MEANS 56 SECONDS ( 14*4) F IS 60 SECONDS
LBF61:  LDA  TEMP
LBF64:  BLO  LBF69                  ;IFHS  60 SECONDS GETS ADDED IN AS A MINUTE (HI NIBBLE)
LBF66:  INC  TEMP
LBF69:  LSRA                        ;HI NIBBLE REALLY 64 SECONDS NOT 60 SECONDS
LBF6A:  LSRA                        ;SO ADD 64 SECOND NIBBLE TO 4 SECOND NIBBLE
LBF6B:  LSRA
LBF6C:  LSRA
LBF6D:  ADDA TEMP
LBF70:  STA  TEMP                   ;ADJUSTED MINUTES+SECONDS/4 IE. M:S
LBF73:  ANDA #$0F
LBF75:  CMPA #$0F
LBF77:  BLO  LBF7C                  ;IFHS  IF 60 SECONDS ADD 1 TO MINUTES
LBF79:  INC  TEMP                   ;0F+1=10
LBF7C:  LDD  T_ACCP+10              ;SHOW IT
LBF7F:  STD  ,Y++
LBF81:  LDD  #$0030
LBF84:  STD  ,Y++
LBF86:  LDA  TEMP
LBF89:  JSR  TIME
LBF8C:  LDD  #VGCNTR
LBF8F:  STD  ,Y++
;CALCULATE AND SHOW PERCENTAGE OF PLAY/TIMEON
LBF91:  LDX  #TIMEON                ;GET TOTAL TIME ON TO TEMP
LBF94:  JSR  EETEMP
LBF97:  LDA  TEMP                   ;NO PLAY TIME?
LBF9A:  ORA  TEMP+1
LBF9D:  ORA  TEMP+2
LBFA0:  ORA  TEMP+3
LBFA3:  BEQ  LBFB4                  ;IFNE  WON'T DIVIDE BY ZERO
LBFA5:  LDX  #TTIME+2               ;GET PLAY TIME ON TO TEMP2 ( 2 LSD IGNORED )
LBFA8:  LDU  #TEMP2
LBFAB:  JSR  EETMP2
LBFAE:  CLR  TEMP2+3                ;* 100.
LBFB1:  JSR  DIVIDE
LBFB4:  LDD  T_ACCP+12              ;SHOW IT
LBFB7:  STD  ,Y++
LBFB9:  LDD  #$0030
LBFBC:  STD  ,Y++
LBFBE:  CLRA                        ;CONVERT FROM HEX
LBFBF:  LDB  TEMP
LBFC2:  LDX  #$0010
LBFC5:  JSR  BINBCD
LBFC8:  LDB  #$01
LBFCA:  STB  BT_SUP
LBFCC:  LDA  BCD+2
LBFCF:  JSR  VWBYTE
LBFD2:  LDD  #VGCNTR
LBFD5:  STD  ,Y++
;DISPLAY HISTOGRAM OF GAME TIMES
LBFD7:  LDB  #(ZHISTOG-HISTOG-2)/2  ;START AT LARGEST TIME ( 6:00 )
LBFD9:  STB  TEMP
LBFDC:  LDU  #T_HISP
LBFDF:  STU  TEMP+2
LBFE2:  LDU  TEMP+2
LBFE5:  LDD  ,U++                   ;Y POSITION
LBFE7:  STD  ,Y++
LBFE9:  CMPU #T_HISP+20             ;PAST HALF WAY POINT + 2 ( U++ ABOVE )
LBFED:  BLO  LBFF4                  ;IFHS  YES, PUT DATA ON LEFT HALF OF SCREEN
LBFEF:  LDD  #$1ED4
LBFF2:  BRA  LBFF7                  ;ELSE  RIGHT SIDE OF SCREEN
LBFF4:  LDD  #$0064
LBFF7:  STD  ,Y++
LBFF9:  STU  TEMP+2
LBFFC:  LDX  #T_HIST-1              ;TIME SLOT TIME
LBFFF:  LDB  TEMP
LC002:  LDA  B,X
LC004:  JSR  TIME                   ;DISPLAY TIME IN M:S FORMAT
LC007:  LDD  VGMSGA                 ;2 BLANKS
LC00A:  STD  ,Y++
LC00C:  STD  ,Y++
LC00E:  LDB  #$00
LC010:  STB  BT_SUP
LC012:  LDX  #HISTOG                ;HISTOGRAM DATA
LC015:  LDB  TEMP
LC018:  ASLB
LC019:  LDA  B,X                    ;HIGH NIBBLE
LC01B:  JSR  VWNIBL                 ;SHOW IT
LC01E:  INCB
LC01F:  LDA  B,X
LC021:  JSR  VWNIBL
LC024:  LDD  #VGCNTR                ;CENTER INSTRUCTION
LC027:  STD  ,Y++
LC029:  DEC  TEMP
LC02C:  BPL  LBFE2                  ;MIEND
LC02E:  RTS

;------------------------------------------------------------------------------
; DIVIDE - DIVIDE
;------------------------------------------------------------------------------
DIVIDE:
LC02F:  LDX  #TEMP+4                ;PERFORM DECIMAL NEGATE OF DENOMINATOR
LC032:  LDA  #$01
LC034:  STA  TMPCNT                 ;SETUP FOR NEGATE
LC037:  LDB  #$03                   ;4 BYTES WORTH
LC039:  LDA  #$99
LC03B:  SUBA ,-X
LC03D:  ADDA TMPCNT
LC040:  DAA
LC041:  STA  ,X
LC043:  BCS  LC04A                  ;IFCC  PROPAGATE THE CARRY
LC045:  CLR  TMPCNT
LC048:  BRA  LC04F                  ;ELSE
LC04A:  LDA  #$01
LC04C:  STA  TMPCNT
LC04F:  DECB
LC050:  BPL  LC039                  ;MIEND
LC052:  LDB  #$FF
LC054:  INCB
LC055:  CMPB #$EF
LC057:  BEQ  DIVIDE_40              ;OVERFLOW---LEAVE AT MAX
LC059:  LDA  TEMP2+3                ;START WITH LSB
LC05C:  ADDA TEMP+3                 ;SUBTRACT DENOMINATOR ( ADD NEGATIVE IN DECIMAL)
LC05F:  DAA
LC060:  STA  TEMP2+3
LC063:  LDA  TEMP2+2
LC066:  ADCA TEMP+2
LC069:  DAA
LC06A:  STA  TEMP2+2
LC06D:  LDA  TEMP2+1
LC070:  ADCA TEMP+1
LC073:  DAA
LC074:  STA  TEMP2+1
LC077:  LDA  TEMP2+0
LC07A:  ADCA TEMP+0
LC07D:  DAA
LC07E:  STA  TEMP2+0
LC081:  BCS  LC054                  ;CCEND  DONE WHEN STAYS NEGATIVE ( DECIMAL ) NO CARRY

DIVIDE_40:
LC083:  STB  TEMP
LC086:  RTS

;------------------------------------------------------------------------------
; TMPMUL - TMPMUL
;------------------------------------------------------------------------------
TMPMUL:
LC087:  BSR  TMPML2                 ;DO IT TWICE

;------------------------------------------------------------------------------
; TMPML2 - ADD TEMP TO TEMP IN DECIMAL
;------------------------------------------------------------------------------
TMPML2:
LC089:  ANDCC #$FE                  ;CLC  START WITH CARRY CLEAR
LC08B:  LDB  #$03                   ;4 BYTES WORTH
LC08D:  LDX  #TEMP+3                ;START WITH LSD
LC090:  LDA  ,X
LC092:  ADCA ,X
LC094:  DAA
LC095:  STA  ,X
LC097:  LEAX -$1,X
LC099:  DECB
LC09A:  BPL  LC090                  ;MIEND
LC09C:  RTS

;------------------------------------------------------------------------------
; EEACCU - COIN ACOUNTING UPDATE
;------------------------------------------------------------------------------
EEACCU:
LC09D:  LDA  #$02                   ;VERIFY AREA 2
LC09F:  JSR  SUMMIT                 ;CALCULATES CHECKSUM WITHOUT STORING
LC0A2:  BNE  LC0FE                  ;IFEQ  CHECKSUM OK, THEN CONTINUE-- ELSE BAD DATA
LC0A4:  CLRA                        ;START WITH 0
LC0A5:  LDB  >S_CCTIM               ;GET COIN COUNTER DATA-ALL 3
LC0A8:  ASLB                        ;ASLD  GET COUNTER DATA INTO A
LC0A9:  ROLA
LC0AA:  LDB  >S_CCTIM+1
LC0AD:  ASLB                        ;ASLD
LC0AE:  ROLA
LC0AF:  LDB  >S_CCTIM+2
LC0B2:  ASLB                        ;ASLD
LC0B3:  ROLA
LC0B4:  TFR  A,B                    ;NEW DATA IN B
LC0B6:  EORB EECOIN                 ;1=CHANGE IN STATE
LC0B9:  ANDB EECOIN                 ;1=COIN COUNTER JUST TURNED ON
LC0BC:  STA  EECOIN                 ;NEW STATE
LC0BF:  LDX  #RMECH
LC0C2:  LSRB
LC0C3:  BCC  LC0F7                  ;IFCS
LC0C5:  LDU  #ITEMP
LC0C8:  JSR  EETMP2                 ;MOVE EE TO TEMP
LC0CB:  LDA  ITEMP+2                ;LSB
LC0CE:  ADDA #$01
LC0D0:  DAA
LC0D1:  STA  ITEMP+2
LC0D4:  LDA  ITEMP+1
LC0D7:  ADCA #$00
LC0D9:  DAA
LC0DA:  STA  ITEMP+1
LC0DD:  LDA  ITEMP+0
LC0E0:  ADCA #$00
LC0E2:  DAA
LC0E3:  STA  ITEMP+0
LC0E6:  LDU  #ITEMP
LC0E9:  JSR  TMPEE2                 ;PUT BACK IN EE ROM
LC0EC:  LDA  #$02                   ;CALCULATE CHECKSUM FOR AREA 2
LC0EE:  STB  ITEMP+3                ;SAVE IT
LC0F1:  JSR  EECKSM
LC0F4:  LDB  ITEMP+3                ;GET B BACK
LC0F7:  LEAX -$6,X                  ;NEXT MECH
LC0F9:  CMPX #AMECH                 ;DONE?
LC0FC:  BHS  LC0C2                  ;LOEND
LC0FE:  RTS

;------------------------------------------------------------------------------
; EEACCT - UPDATE TOTAL GAME TIME
;------------------------------------------------------------------------------
EEACCT:
LC0FF:  LDA  #$02
LC101:  JSR  CHKEE                  ;MAKE SURE AREA 2 IS VALID
LC104:  LDX  #TTIME                 ;TOTAL GAME TIMES
LC107:  JSR  EETEMP                 ;GET TOTALS INTO TEMPS
LC10A:  LDA  TEMP+3                 ;ADD GAME TIME TO TOTAL
LC10D:  ADDA >GTIME+1
LC110:  DAA
LC111:  STA  TEMP+3
LC114:  LDA  TEMP+2
LC117:  ADCA >GTIME+0
LC11A:  DAA
LC11B:  STA  TEMP+2
LC11E:  LDA  TEMP+1
LC121:  ADCA #$00
LC123:  DAA
LC124:  STA  TEMP+1
LC127:  LDA  TEMP+0
LC12A:  ADCA #$00
LC12C:  DAA
LC12D:  BCS  LC132                  ;IFCC  DO NOT OVERFLOW THE MSB
LC12F:  STA  TEMP+0
LC132:  LDA  #$03                   ;DO FOUR BYTES
LC134:  STB  TMPCNT
LC137:  LDU  #TEMP
LC13A:  JSR  TMPEE3                 ;PUT DATA BACK TO EEROM
;UPDATE NUMBER OF GAMES PLAYED
LC13D:  LDX  #GAMES                 ;NUMBER OF GAMES
LC140:  JSR  EETEMP                 ;PUT IT IN TEMPS
LC143:  LDA  TEMP+2
LC146:  ADDA #$01
LC148:  DAA
LC149:  STA  TEMP+2
LC14C:  LDA  TEMP+1
LC14F:  ADCA #$00
LC151:  DAA
LC152:  STA  TEMP+1
LC155:  LDA  TEMP+0
LC158:  ADCA #$00
LC15A:  DAA
LC15B:  STA  TEMP+0
LC15E:  JSR  TEMPEE                 ;PUT IT BACK IN EEROM
;RECORD HIGHEST LEVEL EVER ATTAINED
LC161:  LDX  #ENDGAM
LC164:  JSR  EETEMP                 ;GET CURRENT HIGHEST TO TEMP
LC167:  LDA  GM_DWAV                ;END OF GAME LEVEL ( IN BCD OR DECIMAL )
LC16A:  CMPA TEMP                   ;COMPARE TO RECORDED LEVEL
LC16D:  BLS  LC17B                  ;IFHI  THIS ONE IS HIGHER, USE IT INSTEAD
LC16F:  STA  TEMP
LC172:  CLR  TEMP+1                 ;CLEAR UNUSED NIBBLES
LC175:  CLR  TEMP+2
LC178:  JSR  TEMPEE                 ;PUT IT BACK INTO EEROM
;UPDATE HISTOGRAM INFO
LC17B:  LDX  #ZHISTOG-2             ;LAST ENTRY POINTER
LC17E:  LDA  >GTIME                 ;MSB-IF NOT 0 THEN OVER 6:00, SO PUT IN LAST ENTRY
LC181:  BNE  EEACCT_20              ;IFEQ  FIND OUT WHERE TO PUT DATA
LC183:  LDA  >GTIME+1
LC186:  LDX  #HISTOG                ;BEGINNING OF HISTOGRAM DATA
LC189:  LDB  #$9A                   ;GET NEGATIVE OF T.HIST ( THIS WON'T WORK FOR ALL)
LC18B:  SUBB T_HIST
LC18E:  STB  TEMP
LC191:  ADDA TEMP
LC194:  DAA
LC195:  BCC  EEACCT_20              ;FOUND ITS NICHE
LC197:  LEAX 2,X
LC199:  CMPX #ZHISTOG-2
LC19C:  BLO  LC191                  ;HSEND  IF NOT FOUND, PUT IN LAST ONE ANYWAY

EEACCT_20:
LC19E:  LDA  1,X                    ;ADD 1
LC1A0:  ANDA #$0F
LC1A2:  ADDA #$01
LC1A4:  DAA
LC1A5:  STA  1,X
LC1A7:  ANDA #$F0
LC1A9:  BEQ  LC1E9                  ;IFNE  UPDATE HI NIBBLE
LC1AB:  LDA  ,X
LC1AD:  ANDA #$0F
LC1AF:  ADDA #$01
LC1B1:  DAA
LC1B2:  STA  ,X
LC1B4:  ANDA #$F0
LC1B6:  BEQ  LC1E9                  ;IFNE  OVERFLOW-BAD NEWS DIVIDE ALL HISTOGRAM VALUES BY 2
LC1B8:  LDX  #HISTOG
LC1BB:  LDA  ,X
LC1BD:  ASLA
LC1BE:  ASLA
LC1BF:  ASLA
LC1C0:  ASLA
LC1C1:  STA  TEMP
LC1C4:  LDA  1,X
LC1C6:  ANDA #$0F
LC1C8:  ADDA TEMP
LC1CB:  BITA #$10                   ;WILL DIVIDE BY 2 WORK?
LC1CD:  BEQ  LC1D1                  ;IFNE  NO
LC1CF:  SUBA #$06                   ;THIS CORRECTS IT
LC1D1:  LSRA
LC1D2:  STA  1,X
LC1D4:  LSRA
LC1D5:  LSRA
LC1D6:  LSRA
LC1D7:  LSRA
LC1D8:  STA  ,X
LC1DA:  LEAX 2,X
LC1DC:  CMPX #ZHISTOG
LC1DF:  BLO  LC1BB                  ;HSEND
LC1E1:  LDA  #$05                   ;1/2 OF 100 IS 50
LC1E3:  STA  ,U
LC1E5:  LDA  #$00
LC1E7:  STA  1,U
;SAVE POT VALUES
LC1E9:  LDA  >RHEOP+RHS_LO
LC1EC:  STA  TEMP
LC1EF:  LDA  >RHEOP+RHS_SP
LC1F2:  STA  TEMP+1
LC1F5:  LDA  >RHEOY+RHS_LO
LC1F8:  STA  TEMP+2
LC1FB:  LDA  >RHEOY+RHS_SP
LC1FE:  STA  TEMP+3
LC201:  LDX  #POTSAV                ;MOVE THEM FROM TEMP TO POTSAV IN EEROM
LC204:  LDU  #TEMP
LC207:  LDA  #$03                   ;4 BYTES WORTH
LC209:  JSR  TMPEE3

;------------------------------------------------------------------------------
; EEUTIM - UPDATE TOTAL TIME ON
;------------------------------------------------------------------------------
EEUTIM:
LC20C:  LDX  #TIMEON                ;MOVE TIMEON FROM EEROM
LC20F:  JSR  EETEMP
LC212:  ORCC #$10                   ;SEI  STOPS INTERRUPT INTERACTION
LC214:  LDU  TIMER+2                ;RAM BASED TIME
LC217:  LDD  TIMER
LC21A:  ANDCC #$EF                  ;CLI
LC21C:  CMPD TEMP                   ;NEW TIME SHOULD BE LARGER THAN OLD
LC220:  BHI  EEUTIM_40              ;OK USE THIS AS NEW TIME
LC222:  BLO  EEUTIM_50              ;LESS, DON'T USE IT AND SET IT TO OLD
LC224:  CMPU TEMP+2                 ;CHECK THE LOWER BYTES
LC228:  BLS  EEUTIM_50

EEUTIM_40:
LC22A:  STD  TEMP                   ;SAVE NEW TIME
LC22D:  STU  TEMP+2
LC230:  LDX  #TIMEON
LC233:  LDU  #TEMP
LC236:  LDA  #$03
LC238:  JSR  TMPEE3                 ;PUT IT BACK INTO EEROM
LC23B:  BRA  EEUTIM_60

EEUTIM_50:
LC23D:  LDD  TEMP                   ;RESTORE TIME FROM TIMEON
LC240:  STD  TIMER
LC243:  LDD  TEMP+2
LC246:  STD  TIMER+2

EEUTIM_60:
LC249:  LDA  #$02                   ;SET NEW CHECKSUM
LC24B:  JMP  EECKSM                 ;AND RETURN

;------------------------------------------------------------------------------
; EECPY - SET EEROM AREA TO DEFAULT VALUES
;------------------------------------------------------------------------------
EECPY:
LC24E:  CMPA #NAREA                 ;LEGAL?
LC250:  BHS  EECKSM                 ;IFLO  YES, GO AHEAD PLEASE
LC252:  CMPA #$02                   ;AREAS 0 AND 1 GET DEFAULTS DIFFERENTLY
LC254:  BLO  LC27F                  ;IFHS  GET DEFAULTS FROM T.DFLT
LC256:  LDX  #T_AREA+1              ;GET END OF AREA
LC259:  LDB  A,X                    ;POINTS TO SOMEWHERE IN EEROM PAGE
LC25B:  SUBB #$02                   ;LIMIT IS FIRST NIBBLE OF CHECKSUM
LC25D:  STB  TEMP+1
LC260:  LDB  #EEROM/$100            ;WHAT PAGE IS NON-VOLATILE RAM
LC262:  STB  TEMP                   ;(TEMP,TEMP+1) IS LIMIT
LC265:  LDX  #T_AREA
LC268:  LDB  A,X                    ;GET START OF AREA
LC26A:  LDX  #T_DFLT-(EECK1-EEROM+2) ;DEFAULT TABLE STARTS WITH AREA 2
LC26D:  ABX
LC26E:  TFR  X,U
LC270:  LDX  #EEROM
LC273:  ABX
LC274:  LDB  ,U+
LC276:  STB  ,X+
LC278:  CMPX TEMP
LC27B:  BLO  LC274                  ;HSEND
LC27D:  BRA  EECKSM                 ;ELSE  ELSE GET DEFAULTS FROM ELSEWHERE
LC27F:  TFR  A,B                    ;SAVE IT
LC281:  TSTA
LC282:  BNE  LC29B                  ;IFEQ  OPTION SWITCHES----USE PHYSICAL SWITCHES FOR DEFAULT
LC284:  LDA  R_OPT1                 ;COINS
LC286:  STA  TEMP
LC289:  LDA  R_OPT2                 ;STARTING LIVES,DIFFICULTY,BONUS SHIELDS,ATTRACTIVE MUSIC
LC28B:  STA  TEMP+1
LC28E:  LDA  #$00                   ;SET FOR MISC. OPTIONS
LC290:  STA  TEMP+2
LC293:  LDX  #DUPOPT                ;START OF AREA 0
LC296:  JSR  TEMPEE
LC299:  BRA  LC2B1                  ;ELSE  MUST BE HIGH SCORE INIT
LC29B:  LDX  #SAVSCR                ;DO SCORES FIRST
LC29E:  LDU  #INTSCR                ;INITIAL SCORE TABLE (SEE TCHSCR)
LC2A1:  LDA  #$0B
LC2A3:  JSR  TMPEE3
LC2A6:  LDX  #SAVINT                ;NOW FOR THE INITIALS
LC2A9:  LDU  #INTINT                ;INITIAL INITIALS TABLE (SEE TCHSCR)
LC2AC:  LDA  #$08
LC2AE:  JSR  TMPEE3
LC2B1:  TFR  B,A                    ;GET AREA NUMBER BACK INTO A

;------------------------------------------------------------------------------
; EECKSM - CHECKSUM EEROM AREA
;------------------------------------------------------------------------------
EECKSM:
LC2B3:  JSR  SUMMIT                 ;GET CHECKSUM, Z=1 IF CHECKSUM SAME, SUM IN B
LC2B6:  BEQ  LC2C2                  ;IFNE  STORE IT
LC2B8:  STB  1,X                    ;LO NIBBLE
LC2BA:  LSRB
LC2BB:  LSRB
LC2BC:  LSRB
LC2BD:  LSRB
LC2BE:  STB  ,X                     ;HI NIBBLE
LC2C0:  LDB  #$FF                   ;CLEAR ZERO FLAG
LC2C2:  RTS

;------------------------------------------------------------------------------
; SUMMIT - CHECK FOR PROPER CHECKSUM  (comment at the call)
;   CALCULATES CHECKSUM WITHOUT STORING  (another call)
;   GET CHECKSUM, Z=1 IF CHECKSUM SAME, SUM IN B  (another call)
;------------------------------------------------------------------------------
SUMMIT:
LC2C3:  LEAS -$3,S                  ;ALLOCATE 3 BYTES
LC2C5:  LDX  #T_AREA+1              ;GET LENGHT OF AREA
LC2C8:  LDB  A,X
LC2CA:  LDX  #T_AREA
LC2CD:  SUBB A,X
LC2CF:  SUBB #$02                   ;DON'T CHECKSUM THE CHECKSUM
LC2D1:  STB  CNT,S
LC2D3:  LDB  A,X                    ;GET START OF AREA
LC2D5:  LDX  #EEROM
LC2D8:  ABX                         ;POINTS TO START OF AREA TO CHECKSUM
LC2D9:  LDB  #$00                   ;SEED
LC2DB:  STB  NEWSUM,S
LC2DD:  ORCC #$01                   ;SEC  PREVENT A ZERO CHECKSUM
LC2DF:  LDB  ,X+                    ;GET DATA
LC2E1:  ANDB #$0F                   ;ONLY LOWER NIBBLE IS DATA
LC2E3:  ADCB NEWSUM,S               ;SUM
LC2E5:  STB  NEWSUM,S
LC2E7:  DEC  CNT,S
LC2E9:  BNE  LC2DF                  ;EQEND
LC2EB:  ADCB #$00                   ;GET ALL THE CARRIES IN
LC2ED:  STB  NEWSUM,S
;COMPARE WITH OLD CHECKSUM
LC2EF:  LDB  ,X                     ;HI NIBBLE
LC2F1:  ASLB
LC2F2:  ASLB
LC2F3:  ASLB
LC2F4:  ASLB
LC2F5:  STB  OLDSUM,S
LC2F7:  LDB  1,X                    ;LO NIBBLE
LC2F9:  ANDB #$0F
LC2FB:  ADDB OLDSUM,S               ;OLD CHECKSUM
LC2FD:  STB  OLDSUM,S
LC2FF:  LDB  NEWSUM,S
LC301:  CMPB OLDSUM,S               ;SET CONDITION CODE
LC303:  LEAS 3,S                    ;RESTORE STACK POINTER
LC305:  RTS

;------------------------------------------------------------------------------
; EEINIT - TEST/REINIT EEROM
;------------------------------------------------------------------------------
EEINIT:
LC306:  LDX  #EEROM                 ;COPY EEROM TO BUFFER
LC309:  LDU  #EEBUF
LC30C:  LDD  ,X++
LC30E:  STD  ,U++
LC310:  CMPX #EEROMZ
LC313:  BLO  LC30C                  ;HSEND
LC315:  LDA  #$FF                   ;PERFORM A RECALL OF THE NON-VOLATILE MEMORY
LC317:  STA  NVRRCL
LC31A:  LDX  #$0100                 ;WAIT FOR THE CAP TO DISCHARGE
LC31D:  STA  WTCHDG
LC320:  LEAX -$1,X
LC322:  BNE  LC31D                  ;EQEND
LC324:  LDA  #$00                   ;TURN OFF RECALL LINE
LC326:  STA  NVRRCL
LC329:  LDX  #$A000                 ;NOW WAIT FOR THE CAP TO CHARGE BACK UP
LC32C:  STA  WTCHDG
LC32F:  LEAX -$1,X
LC331:  BNE  LC32C                  ;EQEND
LC333:  LDX  #EEROM                 ;SWAP EEROM AND BUFFER
LC336:  LDY  #EEBUF
LC33A:  LDU  ,X
LC33C:  LDD  ,Y
LC33E:  STU  ,Y++
LC340:  STD  ,X++
LC342:  CMPX #EEROMZ
LC345:  BLO  LC33A                  ;HSEND  EEBUF HAS RECALLED DATA AND EEROM HAS ITS ORIGINAL
;START CHECKING VALIDITY
LC347:  LDA  #NAREA                 ;OPTION SWITCH AREA IS SPECIAL, 2 AREAS
LC349:  JSR  SUMMIT
LC34C:  BEQ  EEINIT_20              ;PRIMARY OK, MAKE SURE BACKUP IS OK
LC34E:  LDA  #$00                   ;PRIMARY WAS BAD, CHECK BACKUP AREA
LC350:  JSR  SUMMIT
LC353:  BEQ  EEINIT_15              ;BACKUP OK, GO REWRITE MAIN AREA FROM BACKUP
;BOTH RAM AREAS BAD, CHECK RECALLED DATA
LC355:  JSR  EEINI2                 ;RESTORE PRIMARY AND BACKUP FROM EEBUFF COPY
LC358:  LDA  #NAREA
LC35A:  JSR  EEINI2
LC35D:  JSR  SUMMIT                 ;CHECKSUM RECALLED PRIMARY
LC360:  BEQ  EEINIT_20              ;'TWAS OK, CHECK NEW BACKUP
LC362:  LDA  #$00                   ;NEW PRIMARY BAD, CHECK NEW BACKUP
LC364:  JSR  SUMMIT
LC367:  BEQ  EEINIT_15

;------------------------------------------------------------------------------
; EEINI0 - THEN RE-INIT IT  (comment at the call)
;------------------------------------------------------------------------------
EEINI0:
LC369:  JSR  EECPY                  ;RESTORE FROM ROM TABLE

EEINIT_15:       ;PRIMARY BAD, BUT BACKUP OK
LC36C:  LDX  #T_AREA                ;MOVE BACKUP TO PRIMARY
LC36F:  LDB  >NAREA,X
LC373:  LDX  #EEROM
LC376:  ABX                         ;POINTER TO BAD AREA
LC377:  LDU  #EEROM                 ;POINTER TO GOOD AREA (BACKUP)
LC37A:  BRA  EEINIT_40              ;FIX IT FROM BACKUP

EEINIT_20:       ;PRIMARY GOOD
LC37C:  LDA  #$00                   ;CHECK THE BACKUP AREA
LC37E:  JSR  SUMMIT
LC381:  BNE  EEINI1                 ;FIX IT FROM PRIMARY
;BOTH AREAS HAVE GOOD CHECKSUMS, MAKE AREAS THE SAME
LC383:  LDA  EECK3                  ;PRIMARY OPTION SWITCH CHECKSUM
LC386:  ANDA #$0F
LC388:  STA  TEMP
LC38B:  LDA  EECK0                  ;BACKUP
LC38E:  ANDA #$0F
LC390:  CMPA TEMP
LC393:  BNE  LC3A5                  ;IFEQ
LC395:  LDA  EECK3+1
LC398:  ANDA #$0F
LC39A:  STA  TEMP
LC39D:  LDA  EECK0+1
LC3A0:  ANDA #$0F
LC3A2:  CMPA TEMP
LC3A5:  BEQ  EEINIT_55              ;OPTION SWITCH CHECKSUM ARE THE SAME, CHECK OTHER AREAS

;------------------------------------------------------------------------------
; EEINI1 - SETUP BACKUP AND CHECK OTHER AREAS  (comment at the call)
;------------------------------------------------------------------------------
EEINI1:
LC3A7:  LDX  #T_AREA                ;REPLACE BACKUP AREA WITH PRIMARY
LC3AA:  LDB  >NAREA,X
LC3AE:  LDX  #EEROM
LC3B1:  ABX
LC3B2:  TFR  X,U                    ;POINTS TO PRIMARY OPTION SWITCH AREA
LC3B4:  LDX  #EEROM                 ;POINTS TO BACKUP OPTION SWITCH AREA

EEINIT_40:
LC3B7:  LDB  T_AREA+1               ;LENGTH OF OPTION SWITCH AREAS
LC3BA:  STB  TMPCNT
LC3BD:  LDB  ,U+                    ;TRANSFER GOOD TO BAD
LC3BF:  STB  ,X+
LC3C1:  DEC  TMPCNT
LC3C4:  BNE  LC3BD                  ;EQEND

EEINIT_55:
LC3C6:  LDA  #NAREA-1               ;NEXT AREA
LC3C8:  JSR  SUMMIT
LC3CB:  BEQ  LC3D8                  ;IFNE  NO GOOD
LC3CD:  JSR  EEINI2                 ;REPLACE FROM BUFFER
LC3D0:  JSR  SUMMIT
LC3D3:  BEQ  LC3D8                  ;IFNE  REALLY BAD, USE DEFAULTS
LC3D5:  JSR  EECPY
LC3D8:  DECA
LC3D9:  BNE  LC3C8                  ;EQEND
LC3DB:  LDX  #TIMEON                ;SETUP RAM BASED TIME ON
LC3DE:  JSR  EETEMP
LC3E1:  LDD  TEMP
LC3E4:  STD  TIMER
LC3E7:  LDD  TEMP+2
LC3EA:  STD  TIMER+2
LC3ED:  RTS

;------------------------------------------------------------------------------
; EEINI2 - MOVE AREA A FROM EEBUF TO EEROM
;------------------------------------------------------------------------------
EEINI2:
LC3EE:  LDX  #T_AREA+1
LC3F1:  LDB  A,X
LC3F3:  LDX  #EEROM
LC3F6:  ABX
LC3F7:  STX  TEMP                   ;START OF NEXT AREA
LC3FA:  LDX  #T_AREA
LC3FD:  LDB  A,X
LC3FF:  LDX  #EEBUF
LC402:  ABX
LC403:  TFR  X,U                    ;START OF AREA IN EEBUF
LC405:  LDX  #EEROM
LC408:  ABX                         ;START OF AREA IN EEROM
LC409:  LDB  ,U+
LC40B:  STB  ,X+
LC40D:  CMPX TEMP
LC410:  BLO  LC409                  ;HSEND
LC412:  RTS

;------------------------------------------------------------------------------
; CHKEE - CHECK AND RESTORE IF NECESSARY THE VALIDITY OF AREA (A)
;------------------------------------------------------------------------------
CHKEE:
LC413:  JSR  SUMMIT
LC416:  BEQ  LC44F                  ;IFNE  ERROR
LC418:  STA  TEMP                   ;SAVE AREA NUMBER
LC41B:  LDX  #EEROM                 ;COPY EEROM TO BUFFER
LC41E:  LDU  #EEBUF
LC421:  LDD  ,X++
LC423:  STD  ,U++
LC425:  CMPX #EEROMZ
LC428:  BLO  LC421                  ;HSEND
LC42A:  JSR  NOVRCL                 ;PERFORM A RECALL OF THE NON-VOLATILE RAM
LC42D:  LDX  #EEROM                 ;SWAP EEROM AND BUFFER
LC430:  LDY  #EEBUF
LC434:  LDU  ,X
LC436:  LDD  ,Y
LC438:  STU  ,Y++
LC43A:  STD  ,X++
LC43C:  CMPX #EEROMZ
LC43F:  BLO  LC434                  ;HSEND  EEBUF HAS RECALEED DATA AND EEROM HAS ITS ORIGINAL
LC441:  LDA  TEMP                   ;RESTORE AREA NUMBER
LC444:  JSR  EEINI2
LC447:  JSR  SUMMIT
LC44A:  BEQ  LC44F                  ;IFNE
LC44C:  JSR  EECPY
LC44F:  RTS

;------------------------------------------------------------------------------
; EEOPT - DISPLAY OPTION SWITCHES
;------------------------------------------------------------------------------
EEOPT:
LC450:  LDA  #MS_OPT                ;OPTION SWITCH MESSAGES
LC452:  JSR  MESSON
LC455:  INCA
LC456:  CMPA #MS_VLC
LC458:  BLO  LC452                  ;HSEND
LC45A:  LDA  #MS_TST                ;"AUX FOR SELF TEST" MESSAGE
LC45C:  JSR  MESSON
LC45F:  LDD  #VGCOLR+(VGCGRN*$100)  ;OPTION SWITCH VALUE COLOR
LC462:  STD  ,Y++
LC464:  LDA  #T_OPTZ-T_OPT-1        ;DISPLAY ALL OPTION SWITCH VALUES
LC466:  STA  TEMP2
LC469:  LDA  TEMP2
LC46C:  JSR  EEOPT3
LC46F:  DEC  TEMP2
LC472:  BPL  LC469                  ;MIEND
LC474:  JSR  EETSTR                 ;REPORT RESULTS OF EEROM ( NOVRAM ) TEST
LC477:  LDA  RESETS                 ;CHECK FOR RESETS
LC47A:  ANDA #$0F
LC47C:  BEQ  LC4EA                  ;IFNE  SOMETHING NEEDS TO BE RESET
LC47E:  LDB  #MS_RES                ;"USE RIGHT FIRE BUTTON TO PERFORM ANY RESET"
LC480:  JSR  DOMESS
LC483:  LDA  GN_SWE                 ;CHECK FOR FIRE BUTTON
LC485:  ANDA #RFIRBT                ;RIGHT FIRE
LC487:  BEQ  LC4EA                  ;IFNE  IT WAS PUSHED, RESET INDICATED AREAS
LC489:  LDA  RESETS
LC48C:  ANDA #$08                   ;RESET HIGH SCORES?
LC48E:  BEQ  LC498                  ;IFNE  YES
LC490:  LDA  #$01
LC492:  JSR  EECPY                  ;PERFORM DEFAULT COPY ON AREA 1
LC495:  JSR  SETINT                 ;RESET OTHER INITIALS TOO
LC498:  LDA  RESETS
LC49B:  ANDA #$04                   ;RESET ACCOUNTING INFO?
LC49D:  BEQ  LC4B1                  ;IFNE  YES
LC49F:  LDX  #GAMES                 ;CLEAR AREA 2 STARTING AT GAMES ( LEAVE COINS ALONE )
LC4A2:  LDD  #$0000
LC4A5:  STD  ,X++                   ;WORD STORE FOR 2 NIBBLES
LC4A7:  CMPX #EECK2
LC4AA:  BLO  LC4A5                  ;HSEND
LC4AC:  LDA  #$02                   ;CHECKSUM AREA 2
LC4AE:  JSR  EECKSM
LC4B1:  LDA  RESETS
LC4B4:  ANDA #$02                   ;RESET OPTIONS TO DEFAULT?
LC4B6:  BEQ  LC4DA                  ;IFNE  YES
LC4B8:  LDA  #$00                   ;SET AREA 0 TO DEFAULT
LC4BA:  JSR  EECPY
LC4BD:  LDX  #T_AREA                ;COPY BACKUP AREA TO PRIMARY AREA
LC4C0:  LDB  >NAREA,X
LC4C4:  LDX  #EEROM
LC4C7:  ABX
LC4C8:  LDU  #EEROM
LC4CB:  LDB  T_AREA+1
LC4CE:  STB  TMPCNT
LC4D1:  LDB  ,U+
LC4D3:  STB  ,X+
LC4D5:  DEC  TMPCNT
LC4D8:  BNE  LC4D1                  ;EQEND
LC4DA:  LDA  RESETS
LC4DD:  ANDA #$01                   ;TEST NOVRAM?
LC4DF:  BEQ  LC4E4                  ;IFNE  YES
LC4E1:  JSR  EETST                  ;TEST STORE-ABILITY OF NOVRAM
LC4E4:  LDD  #$0000                 ;CLEAR RESET BYTE
LC4E7:  STD  RESETS
LC4EA:  RTS

;------------------------------------------------------------------------------
; EEOPT1 - SELECT NEW OPTIONS
;------------------------------------------------------------------------------
EEOPT1:
LC4EB:  LDB  FRAME+1
LC4ED:  ANDB #$0F                   ;NOT TOO QUICK
LC4EF:  BNE  LC519                  ;IFEQ
LC4F1:  LDB  >SI_RSY                ;UP/DOWN
LC4F4:  CMPB #$D0
LC4F6:  BHS  LC519                  ;IFLO  MAY BE NEGATIVE ENOUGH
LC4F8:  CMPB #$30
LC4FA:  BLS  LC519                  ;IFHI  LARGE ENOUGH TO CHANGE
LC4FC:  TSTB
LC4FD:  BMI  LC50C                  ;IFPL  BACK AN OPTION
LC4FF:  LDB  EEINDX
LC502:  DECB
LC503:  BPL  LC507                  ;IFMI  WRAP WHEN BELOW 0
LC505:  LDB  #T_OPTZ-T_OPT-1
LC507:  STB  EEINDX
LC50A:  BRA  LC519                  ;ELSE  FORWARD AN OPTION
LC50C:  LDB  EEINDX
LC50F:  INCB
LC510:  CMPB #T_OPTZ-T_OPT-1
LC512:  BLS  LC516                  ;IFHI  WRAP
LC514:  LDB  #$00
LC516:  STB  EEINDX
LC519:  LDX  #T_OPT                 ;GET OPTION DESCRIPTOR
LC51C:  LDA  EEINDX
LC51F:  LDB  A,X
LC521:  STB  TEMP+2
LC524:  LSRB
LC525:  LSRB
LC526:  LSRB
LC527:  ANDB #$03                   ;FIELD SIZE
LC529:  LDX  #EEMASK
LC52C:  LDA  B,X                    ;MASK FOR THIS FIELD SIZE
LC52E:  STA  TEMP                   ;ALSO MAX VALUE FOR CURRENT OPTION
;LEFT FIRE BUTTON CHANGES THE OPTION
LC531:  LDB  GN_SWE                 ;LOOK FOR EDGE OF LEFT FIRE BUTTON
LC533:  ANDB #LFIRBT
LC535:  BEQ  LC5A3                  ;IFNE  FOUND AN EDGE
LC537:  LDB  EEVAL                  ;CURRENT VALUE
LC53A:  INCB                        ;NEXT VALUE, MAYBE
LC53B:  CMPB TEMP                   ;PAST MAX?
LC53E:  BLS  LC542                  ;IFHI  YES, WRAP BACK TO LOWEST VALUE
LC540:  LDB  #$00
LC542:  STA  EEVAL
LC545:  LDA  TEMP+2                 ;OPTION DESCRIPTOR
LC548:  ROLA                        ;GET BIT POSITION
LC549:  ROLA
LC54A:  ROLA
LC54B:  ROLA
LC54C:  ANDA #$07
LC54E:  DECA
LC54F:  BMI  EEOPT1_20
LC551:  ASLB                        ;SHIFT DATA
LC552:  ASL  TEMP                   ;SHIFT MASK
LC555:  BRA  LC54E                  ;LOOP

EEOPT1_20:
LC557:  LDA  TEMP+2                 ;OPTION DESCRIPTOR
LC55A:  ANDA #$07                   ;INDEX INTO OPTION SWITCH AREA
LC55C:  ASLA                        ;NIBBLES, NIBBLES, NIBBLES. I'VE GOT TO REMEMBER NIBBLES
LC55D:  LDX  #OPTS0
LC560:  LEAX A,X                    ;POINTER TO OPTION SWITCH DATA
LC562:  LDA  ,X                     ;GET THE DATA INTO TEMP STORAGE
LC564:  ASLA                        ;HIGH NIBBLE
LC565:  ASLA
LC566:  ASLA
LC567:  ASLA
LC568:  STA  TEMP+1
LC56B:  LDA  1,X                    ;LO NIBBLE
LC56D:  ANDA #$0F
LC56F:  ADDA TEMP+1
LC572:  STA  TEMP+1
LC575:  EORB TEMP+1                 ;PUT NEW DATA INTO TEMP
LC578:  ANDB TEMP
LC57B:  EORB TEMP+1
LC57E:  STB  1,X                    ;PUT IT BACK INTO EEROM
LC580:  LSRB
LC581:  LSRB
LC582:  LSRB
LC583:  LSRB
LC584:  STB  ,X
LC586:  LDA  #NAREA                 ;SET CHECKSUM
LC588:  JSR  EECKSM
LC58B:  LDX  #EEROM                 ;MOV EEROM TO EEBUF TO PREPARE FOR "EEINI1"
LC58E:  LDU  #EEBUF
LC591:  LDD  ,X++
LC593:  STD  ,U++
LC595:  CMPX #EEROM+$FF
LC598:  BLO  LC591                  ;HSEND
LC59A:  JSR  EEINI1                 ;SETUP BACKUP AND CHECK OTHER AREAS
LC59D:  LDA  EEINDX                 ;DISPLAY THE NEW VALUE
LC5A0:  JSR  EEOPT3
LC5A3:  RTS

;------------------------------------------------------------------------------
; EEOPT3 - DISPLAY OPTION VALUE
;------------------------------------------------------------------------------
EEOPT3:
LC5A4:  LDX  #T_OPT
LC5A7:  LDB  A,X                    ;OPTION SWITCH DESCRIPTOR
LC5A9:  STB  TEMP                   ;SAVE IT
LC5AC:  ANDB #$07                   ;WHICH WORD?
LC5AE:  LDX  #OPTS0
LC5B1:  ASLB                        ;NIBBLES REMEMBER
LC5B2:  ABX                         ;POINTER TO OPTION SWITCHES
LC5B3:  LDB  TEMP                   ;SWITCH DESCRIPTOR
LC5B6:  LSRB
LC5B7:  LSRB
LC5B8:  LSRB
LC5B9:  STB  TEMP                   ;SAVE IT
LC5BC:  ANDB #$03                   ;WHAT IS THE FIELD SIZE?
LC5BE:  LDU  #EEMASK
LC5C1:  LEAU B,U                    ;ADD B TO U, POINTS TO FIELD MASK
LC5C3:  LDB  TEMP
LC5C6:  LSRB
LC5C7:  LSRB
LC5C8:  STB  TEMP                   ;BIT POSITION OF FIELD
LC5CB:  LDB  ,X                     ;GET OPTION SWITCH DATA (BOTH NIBBLES)
LC5CD:  ASLB
LC5CE:  ASLB
LC5CF:  ASLB
LC5D0:  ASLB
LC5D1:  STB  TEMP+1
LC5D4:  LDB  1,X
LC5D6:  ANDB #$0F
LC5D8:  ADDB TEMP+1
LC5DB:  DEC  TEMP
LC5DE:  BMI  EEOPT3_20
LC5E0:  LSRB
LC5E1:  BRA  LC5DB                  ;LOOP

EEOPT3_20:
LC5E3:  ANDB ,U                     ;MASK FOR FIELD
LC5E5:  STB  EEVAL
LC5E8:  LDX  #T_MOPV                ;OPTION SWITCH VALUE MESSAGE TABLE
LC5EB:  LEAX A,X                    ;INDEX INTO TABLE--BASE MESSAGE #
LC5ED:  ADDB ,X                     ;MESSAGE NUMBER OF THIS VALUE
LC5EF:  JMP  DOMES2                 ;COLOR MUST BE ALREADY SET UP

;------------------------------------------------------------------------------
; EETST - TEST EEROM STORE
;   TEST STORE-ABILITY OF EEROM (NOVRAM)
;------------------------------------------------------------------------------
EETST:
LC5F2:  LDX  #EEROM                 ;COPY CURRENT DATA TO BUFFER
LC5F5:  LDU  #EEBUF
LC5F8:  LDD  ,X++
LC5FA:  STD  ,U++
LC5FC:  CMPX #EEROMZ
LC5FF:  BLO  LC5F8                  ;HSEND
LC601:  LDX  #EEROM                 ;COMPLIMENT THE DATA PRIOR TO STORE
LC604:  LDA  ,X
LC606:  COMA
LC607:  STA  ,X+
LC609:  CMPX #EEROMZ
LC60C:  BLO  LC604                  ;HSEND
LC60E:  STA  NSTORE                 ;STORE IT OUT TO ROM PORTION OF EEROM
LC611:  JSR  EEWAIT                 ;WAIT 10 MS FOR THE STORE
LC614:  JSR  EECLR                  ;CLEAR IT OUT TO TEST THE RECALL
LC617:  JSR  NOVRCL                 ;RECALL THE DATA
;DATA IN RAM SHOULD BE COMPLIMENT OF BUFFER DATA
LC61A:  LDX  #EEROM                 ;COMPLIMENT IT AGAIN
LC61D:  LDA  ,X
LC61F:  COMA
LC620:  STA  ,X+
LC622:  CMPX #EEROMZ
LC625:  BLO  LC61D                  ;HSEND
;SHOULD BE THE ORIGINAL DATA AGAIN
LC627:  STA  NSTORE                 ;STORE IT OUT AGAIN
LC62A:  JSR  EEWAIT                 ;WAIT 10 MS FOR STORE
LC62D:  JSR  EECMP                  ;COMPARE DATA TO BUFFER
LC630:  BNE  RESTOR                 ;BAD DATA--SET FLAG AND RESTORE WITH BUFFER DATA
;TWICE COMPLIMENTED DATA LOOKS OK, TRY RECALLING THE DATA AGAIN
LC632:  JSR  EECLR                  ;CLEAR IT TO TEST RECALL
LC635:  JSR  NOVRCL                 ;RECALL THE DATA AGAIN
LC638:  JSR  EECMP                  ;ONE LAST COMPARE
LC63B:  BEQ  LC640                  ;IFNE
LC63D:  JMP  RESTOR                 ;PUT THE RAM PORTION BACK IF POSSIBLE
LC640:  RTS

;------------------------------------------------------------------------------
; EECMP - COMPARE EEROM DATA TO BUFFER DATA
;------------------------------------------------------------------------------
EECMP:
LC641:  LDX  #EEROM
LC644:  LDU  #EEBUF
LC647:  LDA  ,X+
LC649:  EORA ,U+
LC64B:  ANDA #$0F                   ;LOW NIBBLE ONLY
LC64D:  BNE  EECMP_10
LC64F:  CMPX #EEROMZ
LC652:  BLO  LC647                  ;HSEND
LC654:  LDA  #$01                   ;SET FLAG TO SAY NOVRAM OK
LC656:  STA  NVTSTR
LC659:  CLRA                        ;SET CONDTION CODE FOR NO ERROR ( Z=1 )

EECMP_10:
LC65A:  RTS

;------------------------------------------------------------------------------
; RESTOR - ERROR IN NOVRAM, SET FLAGS AND REWRITE DATA WITH BUFFER
;------------------------------------------------------------------------------
RESTOR:
LC65B:  LEAX -$1,X                  ;DID POST ADD ABOVE
LC65D:  TFR  X,D                    ;ADDRESS OF ERROR
LC65F:  STD  NVADDR                 ;FOR REPORTING ERROR
LC662:  LDA  #$FF                   ;FLAG SAYING NOVRAM BAD
LC664:  STA  NVTSTR                 ;TEST RESULTS
LC667:  LDX  #EEROM                 ;COPY BUFFER TO EEROM RAM
LC66A:  LDU  #EEBUF
LC66D:  LDD  ,U++
LC66F:  STD  ,X++
LC671:  CMPX #EEROMZ
LC674:  BLO  LC66D                  ;HSEND
LC676:  TST  NVTSTR                 ;SET CONDITION CODES
LC679:  RTS

;------------------------------------------------------------------------------
; EECLR - CLEAR RAM PORTION OF EEROM ( NOVRAM )
;------------------------------------------------------------------------------
EECLR:
LC67A:  LDX  #EEROM
LC67D:  LDD  #$0000
LC680:  STD  ,X++
LC682:  CMPX #EEROMZ
LC685:  BLO  LC680                  ;HSEND
LC687:  RTS

;------------------------------------------------------------------------------
; EEWAIT - WAIT AT LEAST 10 MS FOR NOVRAM STORE CYCLE
;------------------------------------------------------------------------------
EEWAIT:
LC688:  LDX  #$07D0                 ;10. MS = 15000. CYCLES/8 CYCLES = 1875.
LC68B:  LEAX -$1,X                  ;DEX
LC68D:  BNE  LC68B                  ;EQEND
LC68F:  RTS

;------------------------------------------------------------------------------
; EETSTR - REPORT EETST RESULTS
;------------------------------------------------------------------------------
EETSTR:
LC690:  LDA  NVTSTR                 ;RESULTS OF NOVRAM ( EEROM ) TEST
;0 MEANS NO TEST PERFORMED
;1 MEANS NO ERRORS DETECTED
;ANYTHING ELSE MEANS ERRORS DETECTED
LC693:  BEQ  LC6B7                  ;IFNE  TEST WAS PERFORMED - TELL RESULTS
LC695:  CMPA #$01
LC697:  BNE  LC69D                  ;IFEQ  NO ERRORS -- GOOD EEROM
LC699:  LDB  #MS_GNV                ;"NO ERRORS" ( GOOD NOVRAM )
LC69B:  BRA  LC6B4                  ;ELSE  THERE WERE ERRORS
LC69D:  LDD  #$1F6A
LC6A0:  STD  ,Y++
LC6A2:  LDD  #$01A4
LC6A5:  STD  ,Y++
LC6A7:  LDA  NVADDR+1               ;LOW BYTE OF ADDRESS OF ERROR
LC6AA:  JSR  VWBYTE
LC6AD:  LDD  #VGCNTR
LC6B0:  STD  ,Y++
LC6B2:  LDB  #MS_BNV                ;"ERROR AT" ( BAD NOVRAM )
LC6B4:  JSR  DOMESS
LC6B7:  RTS

;------------------------------------------------------------------------------
; NOVRCL - RECALL NON-VOLATILE MEMORY
;------------------------------------------------------------------------------
NOVRCL:
LC6B8:  LDA  #$FF                   ;D7 = 1 PUTS NOVRAM IN RECALL MODE
LC6BA:  STA  NVRRCL
LC6BD:  JSR  WAITFRAME              ;WAIT A WHILE, THERE'S A LARGE CAP ON THE LINE
LC6C0:  LDA  #$00                   ;D7 = 0 BRINGS US OUT OF RECALL MODE
LC6C2:  STA  NVRRCL
LC6C5:  LDU  #$0000
LC6C8:  JSR  WAITFRAME
LC6CB:  LEAU 1,U
LC6CD:  CMPU #$0020
LC6D1:  BLO  LC6C8                  ;HSEND  NOW THE NOVRAM SHOULD BE USABLE
LC6D3:  RTS

;------------------------------------------------------------------------------
; EETEMP - MOVE EEROM TO TEMP
;   MOVE 8 NIBBLES IN EEROM TO 4 BYTES OF RAM
;------------------------------------------------------------------------------
EETEMP:
LC6D4:  LDU  #TEMP

;------------------------------------------------------------------------------
; EETMP2 - MOVE EE TO TEMP  (comment at the call)
;------------------------------------------------------------------------------
EETMP2:
LC6D7:  LDA  #$03

;------------------------------------------------------------------------------
; EETMP3 - [note] Move EEROM nibbles at (X) to bytes at (U): A = number of bytes less one, two nibbles (upper, lower)
;   per byte; uses TMPCNT; ends with LEAX -8,X (restores X only for the 8-nibble EETEMP case)
;------------------------------------------------------------------------------
EETMP3:
LC6D9:  STA  TMPCNT
LC6DC:  LDA  ,X+                    ;UPPER NIBBLE
LC6DE:  ASLA
LC6DF:  ASLA
LC6E0:  ASLA
LC6E1:  ASLA
LC6E2:  STA  ,U
LC6E4:  LDA  ,X+                    ;LOWER NIBBLE
LC6E6:  ANDA #$0F
LC6E8:  ADDA ,U
LC6EA:  STA  ,U+
LC6EC:  DEC  TMPCNT
LC6EF:  BPL  LC6DC                  ;MIEND
LC6F1:  LEAX -$8,X                  ;RESTORE X
LC6F3:  RTS

;------------------------------------------------------------------------------
; TEMPEE - MOVE TEMP TO EEROM
;------------------------------------------------------------------------------
TEMPEE:
LC6F4:  LDU  #TEMP

;------------------------------------------------------------------------------
; TMPEE2 - PUT BACK IN EE ROM  (comment at the call)
;------------------------------------------------------------------------------
TMPEE2:
LC6F7:  LDA  #$02

;------------------------------------------------------------------------------
; TMPEE3 - PUT DATA BACK TO EEROM  (comment at the call)
;   PUT IT BACK INTO EEROM  (another call)
;------------------------------------------------------------------------------
TMPEE3:
LC6F9:  STA  TMPCNT                 ;NUMBER OF BYTES TO MOVE
LC6FC:  LDA  ,U+                    ;GET DATA
LC6FE:  STA  1,X                    ;STORE LOWER NIBBLE FIRST
LC700:  LSRA                        ;GET UPPER NIBBLE TO LOWER
LC701:  LSRA
LC702:  LSRA
LC703:  LSRA
LC704:  STA  ,X++                   ;STORE UPPER, UPDATE X
LC706:  DEC  TMPCNT
LC709:  BPL  LC6FC                  ;MIEND
LC70B:  LEAX -$6,X
LC70D:  RTS

;------------------------------------------------------------------------------
; TIME - TIME
;------------------------------------------------------------------------------
TIME:
LC70E:  LDB  #$00
LC710:  STB  BT_SUP
LC712:  TFR  A,B
LC714:  LSRA
LC715:  LSRA
LC716:  LSRA
LC717:  LSRA
LC718:  CMPA #$0A
LC71A:  BLO  LC71E                  ;IFHS  MAX OF 9
LC71C:  LDA  #$09
LC71E:  JSR  VWNIBL                 ;MINUTES
LC721:  LDA  #(VJCOLN&$FF00)/$100   ;CHANGE TO COLON IF WE MAKE ONE
LC723:  STA  ,Y+
LC725:  LDA  #VJCOLN&$FF
LC727:  STA  ,Y+
LC729:  CLRA
LC72A:  ANDB #$0F                   ;SECONDS
LC72C:  BEQ  LC734                  ;IFNE
LC72E:  ADDA #$04
LC730:  DAA
LC731:  DECB
LC732:  BNE  LC72E                  ;EQEND
LC734:  JMP  VWBYTE                 ;AND RETURN

;.SBTTL TABLES

EEMASK:
LC737:  .byte $01, $03, $07, $0F

T_DFLT:
LC73B:  .word $0800, $0800, $0800, $0800 ;POT SAVE
LC743:  .word $0000, $0000, $0000   ;AUX COINS
LC749:  .word $0000, $0000, $0000   ;LEFT MECH COINS
LC74F:  .word $0000, $0000, $0000   ;RIGHT MECH COINS
LC755:  .word $0000, $0000, $0000   ;NUMBER OF GAMES PLAYED
LC75B:  .word $0000, $0000, $0000, $0000 ;TOTAL ON TIME
LC763:  .word $0000, $0000, $0000, $0000 ;TOTAL GAME TIME
LC76B:  .word $0000, $0000, $0000   ;HISTOGRAM OF GAME TIMES
LC771:  .word $0000, $0000, $0000
LC777:  .word $0000, $0000, $0000
LC77D:  .word $0000, $0000, $0000
LC783:  .word $0000, $0000, $0000
LC789:  .word $0000, $0000, $0000
LC78F:  .word $0000, $0000, $0000   ;HIGHEST WAVE LEVEL ATTAINED
LC795:  .word $0000                 ;CHECKSUM FOR AREA 2

T_OPT:           ;OPTION DESCRIPTOR TABLE
LC797:  .byte $08                   ;SPEC 0,2,0  COIN VALUE
LC798:  .byte $80                   ;SPEC 0,1,4  LEFT MECH MULT
LC799:  .byte $48                   ;SPEC 0,2,2  RIGHT MECH MULT
LC79A:  .byte $B0                   ;SPEC 0,3,5  BONUS ADDER
LC79B:  .byte $09                   ;SPEC 1,2,0  STARTING LIVES ( 6 TO 9 )
LC79C:  .byte $49                   ;SPEC 1,2,2  PLAY DIFFICULTY
LC79D:  .byte $89                   ;SPEC 1,2,4  BONUS ENERGY AT WAVE END
LC79E:  .byte $C1                   ;SPEC 1,1,6  MUSIC IN ATTRACT
;SPEC 1,1,7 ;FREEZE MODE, NOT USABLE HERE
LC79F:  .byte $E4                   ;SPEC 4,1,7  RESET HIGH SCORES
LC7A0:  .byte $C4                   ;SPEC 4,1,6  RESET ACCOUNTING TIMING INFO
LC7A1:  .byte $A4                   ;SPEC 4,1,5  RESET COIN OPTIONS TO DEFAULT
LC7A2:  .byte $84                   ;SPEC 4,1,4  TEST NOVRAM

T_OPTZ:
LC7A3:  .byte $00                   ;HISTORY OF GAME TIMES DATA

T_HIST:
LC7A4:  .byte $05, $0A, $10
LC7A7:  .byte $15, $1A, $20
LC7AA:  .byte $25, $2A, $30
LC7AD:  .byte $35, $3A, $40
LC7B0:  .byte $45, $4A, $50
LC7B3:  .byte $55, $5A, $60

T_AREA:          ;STARTING ADDRESS FOR EACH AREA
LC7B6:  .byte $00
LC7B7:  .byte EECK0-EEROM+2
LC7B8:  .byte EECK1-EEROM+2
LC7B9:  .byte EECK2-EEROM+2
LC7BA:  .byte EECK3-EEROM+2

T_ACCP:          ;Y POSITIONS FOR ACCOUNTING INFO
LC7BB:  .word $01B8                 ;.POS 440.  AUX COINS
LC7BD:  .word $0190                 ;.POS 400.  LEFT COINS
LC7BF:  .word $0168                 ;.POS 360.  RIGHT COINS
LC7C1:  .word $0118                 ;.POS 280.  TOTAL GAMES PLAYED -/- HIGHEST LEVEL ATTAINED
LC7C3:  .word $0140                 ;.POS 320.  TOTAL COINS PAID
LC7C5:  .word $00B4                 ;.POS 180.  AVERAGE GAME TIME
LC7C7:  .word $0050                 ;.POS 080.  PERCENTAGE OF GAME PLAYED
LC7C9:  .word $00DC                 ;.POS 220.  TOTAL GAME TIME
LC7CB:  .word $0078                 ;.POS 120.  TIME ON

T_HISP:          ;Y POSITIONS FOR HISTOGRAM
LC7CD:  .word $1E6B                 ;.POS -405.
LC7CF:  .word $1E98                 ;.POS -360.
LC7D1:  .word $1EC5                 ;.POS -315.
LC7D3:  .word $1EF2                 ;.POS -270.
LC7D5:  .word $1F1F                 ;.POS -225.
LC7D7:  .word $1F4C                 ;.POS -180.
LC7D9:  .word $1F79                 ;.POS -135.
LC7DB:  .word $1FA6                 ;.POS -090.
LC7DD:  .word $1FD3                 ;.POS -045.
LC7DF:  .word $1E6B                 ;.POS -405.
LC7E1:  .word $1E98                 ;.POS -360.
LC7E3:  .word $1EC5                 ;.POS -315.
LC7E5:  .word $1EF2                 ;.POS -270.
LC7E7:  .word $1F1F                 ;.POS -225.
LC7E9:  .word $1F4C                 ;.POS -180.
LC7EB:  .word $1F79                 ;.POS -135.
LC7ED:  .word $1FA6                 ;.POS -090.
LC7EF:  .word $1FD3                 ;.POS -045.

T_MOPV:          ;TABLE OF MESSAGE #'S FOR OPTION SWITCH VALUES
LC7F1:  .byte MS_VLC                ;VALUE OF COIN (FREE,1C/2P,1C/1P,2C/1P)
LC7F2:  .byte MS_LMV                ;LEFT MECH VALUE (1,2)
LC7F3:  .byte MS_RMV                ;RIGHT MECH VALUE (1,4,5,6)
LC7F4:  .byte MS_BAV                ;BONUS ADDER VALUE (0,2-1,4-1,4-2,5-1,3-1,0,0)
LC7F5:  .byte MS_SLV                ;STARTING LIVES (6,7,8,9)
LC7F6:  .byte MS_DIF                ;DIFFICULTY (EASY,MODERATE,HARD,HARDEST)
LC7F7:  .byte MS_BSV                ;BONUS SHIELD VALUE ( 0,1,2,3 )
LC7F8:  .byte MS_MUV                ;MUSIC IN ATTRACT ( N/Y )
LC7F9:  .byte MS_RHS                ;RESET HIGH SCORES ( Y/N )
LC7FA:  .byte MS_RAC                ;RESET ACCOUNTING INFO ( Y/N )
LC7FB:  .byte MS_ROP                ;RESET OPTIONS TO DEFAULTS ( Y/N )
LC7FC:  .byte MS_TER                ;TEST EEROM ( Y/N )

;==============================================================================
; MODULE TCHSCR   TCHSCR.MAC
;   TOMCAT HI SCORE
;==============================================================================

;------------------------------------------------------------------------------
; VWHSCR - VWHSCR
;------------------------------------------------------------------------------
VWHSCR:
LC7FD:  TST  UPDFLG                 ;ENTERING INITIALS?
LC800:  BMI  LC811                  ;IFPL  YES
LC802:  LDA  #MS_RF1                ;"REBEL FORCE" MIDDLE OF SCREEN
LC804:  JSR  MESSON
LC807:  LDD  #VGSCAL
LC80A:  STD  ,Y++
LC80C:  LDD  #THSY1                 ;TABLE OF HI SCORE Y POSITIONS FOR HALF SCREEN
LC80F:  BRA  LC81E                  ;ELSE
LC811:  LDA  #MS_RF2                ;"REBEL FORCE" TOP OF SCREEN
LC813:  JSR  MESSON
LC816:  LDD  #VGSCAL-$100+$40       ;MAKE LIST LARGER,BUT NOT TOO LARGE
LC819:  STD  ,Y++
LC81B:  LDD  #THSY2                 ;TABLE OF HI SCORE Y POSITIONS FOR WHOLE SCREEN
LC81E:  STD  HSYPOS
LC821:  LDA  #$00                   ;START AT THE FIRST ONE
LC823:  STA  HSCNT
LC826:  LDU  HSYPOS                 ;DO THE INITIALS FIRST
LC829:  LDD  ,U                     ;GET Y POS
LC82B:  STD  ,Y++
LC82D:  LDD  #$1F80                 ;X POS
LC830:  STD  ,Y++
LC832:  LDB  HSCNT
LC835:  ASLB                        ;*3
LC836:  ADDB HSCNT
LC839:  LDX  #INITLS
LC83C:  ABX                         ;POINT TO THIS SET OF INITIALS
LC83D:  CMPX UPDFLG                 ;PLAYER'S INITIALS? ( ONLY FOR ENTERING INITIALS )
LC840:  BNE  LC847                  ;IFEQ  YES
LC842:  LDD  #VGCOLR+(VGCWHT*$100)  ;MAKE THEM STAND OUT
LC845:  BRA  LC84A                  ;ELSE
LC847:  LDD  PH_COL                 ;COLOR DEPENDING ON THE PHASE
LC84A:  STD  ,Y++
LC84C:  STD  TMPCOL                 ;USED FOR FLASHING INITIAL IN ENTERING STATE
LC84E:  LDU  #VGMSGA+$14            ;POINTS TO LETTER "A"
;1ST INITIAL
LC851:  TST  UPDFLG                 ;ENTERING INITIALS?
LC854:  BMI  LC871                  ;IFPL  YES, HAVE TO FLASH CURRENT INITIAL
LC856:  LDA  UPDINT
LC859:  CMPA #$00                   ;THIS INITIAL??
LC85B:  BNE  LC86D                  ;IFEQ  YES, THEN MAKE IT FLASH
LC85D:  LDA  >FRAME+1               ;LSD OF FRAME
LC860:  ANDA #$01                   ;ON OR OFF
LC862:  BNE  LC869                  ;IFEQ  OFF THIS FRAME
LC864:  LDD  PH_COL                 ;USE NORMAL COLOR FOR OFF
LC867:  BRA  LC86B                  ;ELSE  ON AS PER THIS LINES COLOR
LC869:  LDD  TMPCOL                 ;WILL BE WHITE IF CURRENT INITIAL BEING ENTERED
LC86B:  BRA  LC86F                  ;ELSE  NOT THIS INITIAL, MAKE SURE IT IS THIS LINES COLOR
LC86D:  LDD  TMPCOL
LC86F:  STD  ,Y++
LC871:  LDA  ,X+
LC873:  BNE  LC884                  ;IFEQ  BLANK
LC875:  TST  UPDFLG
LC878:  BMI  LC87F                  ;IFPL  ENTERING INITIALS, SHOW UNDERLINE INSTEAD OF BLANK
LC87A:  LDD  VGMSGA+82
LC87D:  BRA  LC882                  ;ELSE  NOT ENTERING INITIALS, SHOW A BLANK
LC87F:  LDD  VGMSGA
LC882:  BRA  LC887                  ;ELSE  THEN A-Z
LC884:  ASLA                        ;WORD TABLE
LC885:  LDD  A,U                    ;JSRL TO LETTER
LC887:  STD  ,Y++
;2ND INITIAL
LC889:  TST  UPDFLG                 ;ENTERING INITIALS?
LC88C:  BMI  LC8A9                  ;IFPL  YES, HAVE TO FLASH CURRENT INITIAL
LC88E:  LDA  UPDINT
LC891:  CMPA #$01                   ;THIS INITIAL??
LC893:  BNE  LC8A5                  ;IFEQ  YES, THEN MAKE IT FLASH
LC895:  LDA  >FRAME+1               ;LSD OF FRAME
LC898:  ANDA #$01                   ;ON OR OFF
LC89A:  BNE  LC8A1                  ;IFEQ  OFF THIS FRAME
LC89C:  LDD  PH_COL                 ;USE NORMAL COLOR FOR OFF
LC89F:  BRA  LC8A3                  ;ELSE  ON AS PER THIS LINES COLOR
LC8A1:  LDD  TMPCOL                 ;WILL BE WHITE IF CURRENT INITIAL BEING ENTERED
LC8A3:  BRA  LC8A7                  ;ELSE  NOT THIS INITIAL, MAKE SURE IT IS THIS LINES COLOR
LC8A5:  LDD  TMPCOL
LC8A7:  STD  ,Y++
LC8A9:  LDA  ,X+
LC8AB:  BNE  LC8BC                  ;IFEQ  BLANK
LC8AD:  TST  UPDFLG
LC8B0:  BMI  LC8B7                  ;IFPL  ENTERING INITIALS, SHOW UNDERLINE INSTEAD OF BLANK
LC8B2:  LDD  VGMSGA+82
LC8B5:  BRA  LC8BA                  ;ELSE  NOT ENTERING INITIALS, SHOW A BLANK
LC8B7:  LDD  VGMSGA
LC8BA:  BRA  LC8BF                  ;ELSE  THEN A-Z
LC8BC:  ASLA                        ;WORD TABLE
LC8BD:  LDD  A,U                    ;JSRL TO LETTER
LC8BF:  STD  ,Y++
;3RD INITIAL
LC8C1:  TST  UPDFLG                 ;ENTERING INITIALS?
LC8C4:  BMI  LC8E1                  ;IFPL  YES, HAVE TO FLASH CURRENT INITIAL
LC8C6:  LDA  UPDINT
LC8C9:  CMPA #$02                   ;THIS INITIAL??
LC8CB:  BNE  LC8DD                  ;IFEQ  YES, THEN MAKE IT FLASH
LC8CD:  LDA  >FRAME+1               ;LSD OF FRAME
LC8D0:  ANDA #$01                   ;ON OR OFF
LC8D2:  BNE  LC8D9                  ;IFEQ  OFF THIS FRAME
LC8D4:  LDD  PH_COL                 ;USE NORMAL COLOR FOR OFF
LC8D7:  BRA  LC8DB                  ;ELSE  ON AS PER THIS LINES COLOR
LC8D9:  LDD  TMPCOL                 ;WILL BE WHITE IF CURRENT INITIAL BEING ENTERED
LC8DB:  BRA  LC8DF                  ;ELSE  NOT THIS INITIAL, MAKE SURE IT IS THIS LINES COLOR
LC8DD:  LDD  TMPCOL
LC8DF:  STD  ,Y++
LC8E1:  LDA  ,X+
LC8E3:  BNE  LC8F4                  ;IFEQ  BLANK
LC8E5:  TST  UPDFLG
LC8E8:  BMI  LC8EF                  ;IFPL  ENTERING INITIALS, SHOW UNDERLINE INSTEAD OF BLANK
LC8EA:  LDD  VGMSGA+82
LC8ED:  BRA  LC8F2                  ;ELSE  NOT ENTERING INITIALS, SHOW A BLANK
LC8EF:  LDD  VGMSGA
LC8F2:  BRA  LC8F7                  ;ELSE  THEN A-Z
LC8F4:  ASLA                        ;WORD TABLE
LC8F5:  LDD  A,U                    ;JSRL TO LETTER
LC8F7:  STD  ,Y++
LC8F9:  LDD  TMPCOL                 ;RESTORE COLOR TO THIS LINE'S COLOR
LC8FB:  STD  ,Y++
LC8FD:  LDD  #VGCNTR
LC900:  STD  ,Y++
;NOW THE NUMBER
LC902:  LDU  HSYPOS
LC905:  LDD  ,U                     ;Y POS
LC907:  STD  ,Y++
LC909:  LDD  #$1F38                 ;X POS
LC90C:  STD  ,Y++
LC90E:  LDA  HSCNT
LC911:  INCA
LC912:  CMPA #$0A                   ;MAKE IT 10
LC914:  BLO  LC918                  ;IFHS
LC916:  LDA  #$10
LC918:  LDB  #$01                   ;SUPPRESS THIS MANY ZEROS
LC91A:  STB  BT_SUP
LC91C:  JSR  VWBYTE                 ;THE NUMBER
LC91F:  LDD  #VJPERD                ;PERIOD
LC922:  STD  ,Y++
LC924:  LDD  #VGCNTR
LC927:  STD  ,Y++
;NOW FOR THE SCORE
LC929:  LDB  HSCNT
LC92C:  ASLB
LC92D:  ASLB
LC92E:  LDX  #HSCORS
LC931:  ABX                         ;POINT AT APPROPRIATE HIGH SCORE
LC932:  LDU  HSYPOS
LC935:  LDD  ,U++                   ;Y POS
LC937:  STD  ,Y++
LC939:  LDD  #$1FF0                 ;X POS
LC93C:  STD  ,Y++
LC93E:  STU  HSYPOS
LC941:  LDB  #$06                   ;SUPPRESS THIS MANY LEADING ZEROS
LC943:  STB  BT_SUP
;X-->8 BCD FIELD
LC945:  JSR  VW8DIG                 ;VIEW 8 DIGITS WITH COMMAS
LC948:  LEAX 4,X                    ;BUMP X BY 8 BCD
LC94A:  LDD  #VGCNTR
LC94D:  STD  ,Y++
LC94F:  INC  HSCNT
LC952:  LDA  HSCNT
LC955:  CMPA #$0A                   ;DONE?
LC957:  LBLO LC826                  ;HSEND
LC95B:  LDD  #VGSCAL                ;RESTORE SCALE TO NORMAL
LC95E:  STD  ,Y++
LC960:  LDD  UPDFLG                 ;ENTERING INITIALS?
LC963:  BPL  LC966                  ;IFMI  NOPE, THEN LEAVE
LC965:  RTS
LC966:  LDD  #VGCOLR+(VGCRED*$100)
LC969:  STD  ,Y++
LC96B:  LDX  #TINTXY+4              ;TABLE OF XY POSITIONS FOR ALPHABET
LC96E:  LDU  #VGMSGA+22             ;START WITH "A"
LC971:  LDD  2,X                    ;Y POS
LC973:  ANDA #$1F
LC975:  STD  ,Y++
LC977:  LDD  ,X                     ;X POS
LC979:  ANDA #$1F
LC97B:  STD  ,Y++
LC97D:  LDD  ,U++                   ;JSRL TO LETTER
LC97F:  STD  ,Y++
LC981:  LDD  #VGCNTR
LC984:  STD  ,Y++
LC986:  LEAX 4,X
LC988:  CMPX #TINTXY+(27*4)         ;STOP AFTER "Z"
LC98B:  BLO  LC971                  ;HSEND
;THE UNDERLINE
LC98D:  LDD  TINTXY+2               ;Y POS
LC990:  ANDA #$1F
LC992:  STD  ,Y++
LC994:  LDD  TINTXY+0               ;X POS
LC997:  ANDA #$1F
LC999:  STD  ,Y++
LC99B:  LDD  VGMSGA+82              ;"_" OR UNDERLINE
LC99E:  STD  ,Y++
LC9A0:  LDD  #VGSCAL                ;RESTORE NORMAL SCALE
LC9A3:  STD  ,Y++
LC9A5:  LDD  #VGCNTR
LC9A8:  STD  ,Y++
;NEXT COMES "RUB"
LC9AA:  LDB  INITL
LC9AD:  CMPB #$1B                   ;"RUB"???
LC9AF:  BNE  LC9B6                  ;IFEQ  YES, THEN HIGHLIGHT IT
LC9B1:  LDD  #VGCOLR+(VGCWHT*$100)-$30
LC9B4:  BRA  LC9B9                  ;ELSE  NORMAL COLOR
LC9B6:  LDD  #VGCOLR+(VGCRED*$100)-$30
LC9B9:  STD  ,Y++
LC9BB:  LDD  2,X
LC9BD:  ANDA #$1F
LC9BF:  STD  ,Y++
LC9C1:  LDD  ,X
LC9C3:  SUBD #$0008
LC9C6:  ANDA #$1F
LC9C8:  STD  ,Y++
LC9CA:  LDD  #VGSCAL-$40            ;MAKE LETTERS SMALLER
LC9CD:  STD  ,Y++
LC9CF:  LDD  VGMSGA+56              ;"R"
LC9D2:  STD  ,Y++
LC9D4:  LDD  VGMSGA+62              ;"U"
LC9D7:  STD  ,Y++
LC9D9:  LDD  VGMSGA+24              ;"B"
LC9DC:  STD  ,Y++
LC9DE:  LDD  #VGSCAL                ;RESTORE NORMAL SCALE
LC9E1:  STD  ,Y++
LC9E3:  LDD  #VGCNTR
LC9E6:  STD  ,Y++
;NOW THE WORD "END"
LC9E8:  LDB  INITL
LC9EB:  CMPB #$1C                   ;"END"???
LC9ED:  BNE  LC9F4                  ;IFEQ  YES, THEN HIGHLIGHT IT
LC9EF:  LDD  #VGCOLR+(VGCWHT*$100)-$30
LC9F2:  BRA  LC9F7                  ;ELSE  NORMAL COLOR
LC9F4:  LDD  #VGCOLR+(VGCRED*$100)-$30
LC9F7:  STD  ,Y++
LC9F9:  LDD  6,X
LC9FB:  ANDA #$1F
LC9FD:  STD  ,Y++
LC9FF:  LDD  4,X
LCA01:  SUBD #$0008
LCA04:  ANDA #$1F
LCA06:  STD  ,Y++
LCA08:  LDD  #VGSCAL-$40            ;MAKE LETTERS SMALLER
LCA0B:  STD  ,Y++
LCA0D:  LDD  VGMSGA+30              ;"E"
LCA10:  STD  ,Y++
LCA12:  LDD  VGMSGA+48              ;"N"
LCA15:  STD  ,Y++
LCA17:  LDD  VGMSGA+28              ;"D"
LCA1A:  STD  ,Y++
LCA1C:  LDD  #VGSCAL                ;RESTORE NORMAL SCALE
LCA1F:  STD  ,Y++
LCA21:  LDD  #VGCNTR
LCA24:  STD  ,Y++
;HILITE SELECTED LETTER
LCA26:  LDD  #VGCOLR+(VGCWHT*$100)
LCA29:  STD  ,Y++
LCA2B:  LDB  INITL                  ;CURRENT LETTER
LCA2E:  CMPB #$1B                   ;NORMAL ALPHAS
LCA30:  BHS  LCA5B                  ;IFLO  YES, THEN HIGHLIGHT ( END, RUB DONE ELSEWHERE )
LCA32:  ASLB
LCA33:  ASLB
LCA34:  LDX  #TINTXY
LCA37:  ABX                         ;POINTS TO POSITION
LCA38:  LDD  2,X                    ;Y POS
LCA3A:  ANDA #$1F
LCA3C:  STD  ,Y++
LCA3E:  LDD  ,X                     ;X POS
LCA40:  ANDA #$1F
LCA42:  STD  ,Y++
LCA44:  LDB  INITL
LCA47:  BNE  LCA4E                  ;IFEQ  BLANK?? USE UNDERLINE INSTEAD
LCA49:  LDD  VGMSGA+82
LCA4C:  BRA  LCA54                  ;ELSE
LCA4E:  ASLB
LCA4F:  LDX  #VGMSGA+20             ;"A"
LCA52:  LDD  B,X
LCA54:  STD  ,Y++
LCA56:  LDD  #VGCNTR
LCA59:  STD  ,Y++
LCA5B:  LDD  #VGCOLR+(VGCYLW*$100)  ;YELLOW FOR THE SITE
LCA5E:  STD  ,Y++
LCA60:  JSR  VWCURC                 ;DISPLAY THE CURSOR
LCA63:  RTS

THSY1:           ;LOW ON SCREEN POSITIONS
LCA64:  .word $1FB8                 ;.POS -72.,-108.,-142.,-190.
LCA66:  .word $1F94
LCA68:  .word $1F72
LCA6A:  .word $1F42
LCA6C:  .word $1F1E                 ;.POS -226.,-260.,-296.,-330.
LCA6E:  .word $1EFC
LCA70:  .word $1ED8
LCA72:  .word $1EB6
LCA74:  .word $1E92                 ;.POS -366.,-402.
LCA76:  .word $1E6E

THSY2:           ;WHOLE SCREEN
LCA78:  .word $008C                 ;.POS 140.,100.,60.,20.
LCA7A:  .word $0064
LCA7C:  .word $003C
LCA7E:  .word $0014
LCA80:  .word $1FEC                 ;.POS -20.,-60.,-100.,-140.
LCA82:  .word $1FC4
LCA84:  .word $1F9C
LCA86:  .word $1F74
LCA88:  .word $1F4C                 ;.POS -180.,-220.
LCA8A:  .word $1F24

;------------------------------------------------------------------------------
; UPDATE - UPDATE CHECK FOR HIGH SCORE
;------------------------------------------------------------------------------
UPDATE:
LCA8C:  LDX  #HSCORS
LCA8F:  LDD  S_SC87                 ;4 MSDs
LCA91:  SUBD ,X
LCA93:  BHI  UPDAT2                 ;MSD'S TELL US IT IS A HIGH SCORE
;ELSE CHECK FURTHER
LCA95:  BNE  LCA9D                  ;IFEQ  MSDs ARE EQUAL---STILL HAS A CHANCE
LCA97:  LDD  S_SC43                 ;4 LSDs
LCA99:  SUBD 2,X
LCA9B:  BHS  UPDAT2                 ;THIS IS A HIGH SCORE
LCA9D:  LEAX 4,X                    ;NEXT HI SCORE
LCA9F:  CMPX #HSCORS+(4*NHSCRS)
LCAA2:  BLO  LCA8F                  ;HSEND
LCAA4:  RTS

;------------------------------------------------------------------------------
; UPDAT2 - [note] Score is a high score (from UPDATE), X-->table entry beaten: PUTHI to make room, clear UPDINT and
;   INITL for the first initial, and return X = end of HSCORS so UPDATE's loop leaves
;------------------------------------------------------------------------------
UPDAT2:
LCAA5:  JSR  PUTHI                  ;MAKE ROOM
LCAA8:  LDA  #$00                   ;WORK ON FIRST INITIAL
LCAAA:  STA  UPDINT
LCAAD:  LDD  #$0000                 ;BLANK
LCAB0:  STD  INITL                  ;CURRENT VALUE OF INITIAL BEING WORKED ON
LCAB3:  LDX  #HSCORS+(4*NHSCRS)     ;LEAVE
LCAB6:  RTS

;------------------------------------------------------------------------------
; PUTHI - PUTHI
;------------------------------------------------------------------------------
PUTHI:
LCAB7:  STX  UPDFLG                 ;HERE'S WHERE TO STOP
LCABA:  LDU  #INITLS+(3*NHSCRS)-3   ;END OF INITIALS
LCABD:  LDX  #HSCORS+(4*NHSCRS)-4   ;END OF HIGH SCORE TABLE
LCAC0:  CMPX UPDFLG                 ;REPLACING LAST ENTRY??
LCAC3:  BEQ  LCADE                  ;IFNE  NO, OK SHIFT TABLE APPROPRIATELY
LCAC5:  LDD  -$4,X                  ;MOVE 4 BYTES OF SCORE DOWN
LCAC7:  STD  ,X
LCAC9:  LDD  -$2,X
LCACB:  STD  2,X
LCACD:  LDD  -$3,U                  ;MOVE 3 BYTES OF INITIALS
LCACF:  STD  ,U
LCAD1:  LDA  -$1,U
LCAD3:  STA  2,U
LCAD5:  LEAU -$3,U
LCAD7:  LEAX -$4,X
LCAD9:  CMPX UPDFLG
LCADC:  BHI  LCAC5                  ;LSEND
LCADE:  STU  UPDFLG                 ;U POINTS TO THE INITIALS
LCAE1:  LDA  #$00                   ;SETUP 1ST INITIAL AS A BLANK
LCAE3:  STA  ,U
LCAE5:  LDD  #$0000                 ;BLANKS FOR 2ND, AND 3RD
LCAE8:  STD  1,U
LCAEA:  LDD  S_SC87                 ;MOVE PLAYER'S SCORE INTO TABLE
LCAEC:  STD  ,X
LCAEE:  LDD  S_SC43
LCAF0:  STD  2,X
LCAF2:  RTS

;------------------------------------------------------------------------------
; GETINT - GETINT
;------------------------------------------------------------------------------
GETINT:
LCAF3:  LDX  UPDFLG                 ;INDEX INTO TABLE
LCAF6:  LDB  UPDINT                 ;WHICH INITIAL ARE WE GETTING
LCAF9:  ABX
LCAFA:  TFR  X,U                    ;GET IT OUT OF THE WAY
LCAFC:  LDA  UPDINT
LCAFF:  CMPA #$03                   ;DONE WITH APLHA'S ??
LCB01:  BLO  LCB08                  ;IFHS  YES, THEN ONLY CHECK FOR RUB OR END
LCB03:  LDX  #TINTXY+(4*27)
LCB06:  BRA  LCB0B                  ;ELSE  CHECK FOR ALL CHARACTERS
LCB08:  LDX  #TINTXY                ;TABLE OF POSITIONS FOR INITIALS ( CENTER OF LETTER )
LCB0B:  LDD  >SI_CX                 ;CHECK X POS OF CURSOR
LCB0E:  SUBD #$0008
LCB11:  SUBD ,X
LCB13:  TSTA                        ;ABSD
LCB14:  BPL  LCB1A
LCB16:  COMA
LCB17:  NEGB
LCB18:  SBCA #$FF
LCB1A:  STD  TMPABS
LCB1C:  CMPD #$0018
LCB20:  BHS  LCB49                  ;IFLO  WITHIN X LIMIT
LCB22:  LDD  >SI_CY                 ;CHECK Y POS
LCB25:  ADDD #VGOFFY-12             ;ADD IN SCREEN OFFSET
LCB28:  SUBD 2,X
LCB2A:  TSTA                        ;ABSD
LCB2B:  BPL  LCB31
LCB2D:  COMA
LCB2E:  NEGB
LCB2F:  SBCA #$FF
LCB31:  CMPD #$0018
LCB35:  BHS  LCB49                  ;IFLO  ALSO WITHIN Y LIMIT
LCB37:  ADDD TMPABS                 ;OCTAGON CHECK
LCB39:  CMPD #$0020
LCB3D:  BHS  LCB49                  ;IFLO  HIT
LCB3F:  TFR  X,D                    ;MAKE INDEXED NUMBER USEFUL
LCB41:  SUBD #TINTXY
LCB44:  LSRB                        ;/4
LCB45:  LSRB
LCB46:  STB  INITL                  ;CURRENT VALUE OF INITIAL
LCB49:  LEAX 4,X                    ;NEXT TABLE ENTRY
LCB4B:  CMPX #TINTZ                 ;DONE?
LCB4E:  BLO  LCB0B                  ;HSEND
LCB50:  LDA  INITL                  ;PUT IT IN TABLE
LCB53:  CMPA #$1B                   ;NORMAL ALPHA?
LCB55:  BHS  LCB59                  ;IFLO  YES, THEN INSERT IT INTO TABLE
LCB57:  STA  ,U
LCB59:  LDA  GN_SWE                 ;FALLING EDGE OF FIRE BUTTON ( SEE IFRAME IN MAIN )
LCB5B:  ANDA #FIREBT|THMBT
LCB5D:  BEQ  LCBA3                  ;IFNE  TRANSITION FROM OFF TO ON
LCB5F:  LDA  INITL
LCB62:  CMPA #$1B                   ;"RUB"?
LCB64:  BNE  LCB82                  ;IFEQ  BACK UP ONE INITIAL
LCB66:  LDA  UPDINT
LCB69:  CMPA #$02                   ;ON AN INITIAL?
LCB6B:  BHI  LCB71                  ;IFLS  YES, RUB IT OUT
LCB6D:  LDA  #$00                   ;MAKE IT A BLANK ( UNDERLINE IN THIS MODE )
LCB6F:  STA  ,U
LCB71:  LDA  UPDINT                 ;MOVE POINTER BACK ONE
LCB74:  BEQ  LCB7D                  ;IFNE  DON'T WRAP
LCB76:  DEC  UPDINT
LCB79:  LDA  #$00                   ;BLANK FOR THE INITIAL WE JUST MOVED BACK TO
LCB7B:  STA  -$1,U
LCB7D:  JSR  AUDSS                  ;SHOOTING ENEMY SHOT SOUND, RUBBING IT OUT
LCB80:  BRA  LCBA3                  ;ELSE  NOT "RUB"
LCB82:  CMPA #$1C                   ;"END"?
LCB84:  BNE  LCB91                  ;IFEQ  ALL DONE, LEAVE
LCB86:  LDD  #$FFFF                 ;NO MORE HI SCORE
LCB89:  STD  UPDFLG
LCB8C:  JSR  AUDPH                  ;PORTHOLE SHOT WHEN ENDING INITIALS
LCB8F:  BRA  LCBA3                  ;ELSE  NORMAL ALPHA CHARACTER
LCB91:  INC  UPDINT                 ;NEXT INITIAL
LCB94:  LDA  UPDINT
LCB97:  CMPA #$03                   ;ALL INITIALS SELECTED?
LCB99:  BLO  LCBA0                  ;IFHS  YES
LCB9B:  LDA  #$1C                   ;INITL TO "END"
LCB9D:  STA  INITL
LCBA0:  JSR  AUDXL                  ;LAZAR SOUND WHEN SHOOTING INITIALS
LCBA3:  RTS

TINTXY:          ;TABLE OF XY POSITIONS FOR INITIALS
LCBA4:  .word $011C, $FF44          ;UNDERLINE
LCBA8:  .word $FEDC, $FFA4          ;A
LCBAC:  .word $FEDC, $FF74          ;B
LCBB0:  .word $FEDC, $FF44          ;C
LCBB4:  .word $FEDC, $FF14          ;D
LCBB8:  .word $FEDC, $FEE4          ;E
LCBBC:  .word $FEDC, $FEB4          ;F
LCBC0:  .word $FEDC, $FE84          ;G
LCBC4:  .word $FEDC, $FE54          ;H
LCBC8:  .word $FEDC, $FE24          ;I
LCBCC:  .word $FF0C, $FE24          ;J
LCBD0:  .word $FF3C, $FE24          ;K
LCBD4:  .word $FF6C, $FE24          ;L
LCBD8:  .word $FF9C, $FE24          ;M
LCBDC:  .word $FFCC, $FE24          ;N
LCBE0:  .word $FFFC, $FE24          ;O
LCBE4:  .word $002C, $FE24          ;P
LCBE8:  .word $005C, $FE24          ;Q
LCBEC:  .word $008C, $FE24          ;R
LCBF0:  .word $00BC, $FE24          ;S
LCBF4:  .word $00EC, $FE24          ;T
LCBF8:  .word $011C, $FE24          ;U
LCBFC:  .word $011C, $FE54          ;V
LCC00:  .word $011C, $FE84          ;W
LCC04:  .word $011C, $FEB4          ;X
LCC08:  .word $011C, $FEE4          ;Y
LCC0C:  .word $011C, $FF14          ;Z
LCC10:  .word $011C, $FF74          ;RUB
LCC14:  .word $011C, $FFA4          ;END

;------------------------------------------------------------------------------
; SETINT - SETINT
;   END OF TABLE
;   (also: TINTZ)
;------------------------------------------------------------------------------
SETINT:
TINTZ:
LCC18:  JSR  DOINTS                 ;COPY DEFAULTS TO HIGH SCORE TABLE
LCC1B:  LDA  #$01                   ;CHECK EEROM HIGH SCORE TABLE
LCC1D:  JSR  SUMMIT                 ;RETURNS EQ IF CHECSUM OK
LCC20:  BNE  CHKHIS                 ;IFEQ  GOOD, USE EEROM FOR THE TOP 3 SCORES
LCC22:  LDU  #INITLS                ;DO INITIALS FIRST
LCC25:  LDX  #SAVINT
LCC28:  LDA  #$08
LCC2A:  JSR  EETMP3
LCC2D:  LDU  #HSCORS                ;NOW DO THE SCORES
LCC30:  LDX  #SAVSCR
LCC33:  LDA  #$0B
LCC35:  JSR  EETMP3

;------------------------------------------------------------------------------
; CHKHIS - MAKE SURE EACH ENTRY IS IN VALID RANGE
;------------------------------------------------------------------------------
CHKHIS:
LCC38:  LDX  #INITLS                ;INITIALS CAN RANGE FROM 0 TO 26.
LCC3B:  LDA  ,X+
LCC3D:  CMPA #$1B                   ;BLANK TO Z
LCC3F:  BHS  DOINTS                 ;ERROR SOMEWHERE, PUT IN DEFAULTS ( SUPPOSED TO BE OK )
LCC41:  CMPX #INITLS+30
LCC44:  BLO  LCC3B                  ;HSEND
LCC46:  LDX  #HSCORS                ;MAKE SURE EACH NUMBER IS DECIMAL ( BCD )
LCC49:  LDA  ,X+
LCC4B:  CMPA #$A0                   ;HIGH NIBBLE <= 9 ?
LCC4D:  BHS  DOINTS                 ;NO, ERROR -- PUT IN DEFAULTS
LCC4F:  ANDA #$0F
LCC51:  CMPA #$0A                   ;LO NIBBLE <= 9 ?
LCC53:  BHS  DOINTS                 ;NOPE, ERROR -- USE DEFAULTS
LCC55:  CMPX #HSCORS+40
LCC58:  BLO  LCC49                  ;HSEND
LCC5A:  RTS

;------------------------------------------------------------------------------
; DOINTS - COPY DEFAULTS TO HIGH SCORE TABLE  (comment at the call)
;------------------------------------------------------------------------------
DOINTS:
LCC5B:  LDX  #INITLS
LCC5E:  LDU  #INTINT                ;INITIAL INITIALS
LCC61:  LDD  ,U++
LCC63:  STD  ,X++
LCC65:  CMPX #INITLS+30
LCC68:  BLO  LCC61                  ;HSEND
LCC6A:  LDX  #HSCORS
LCC6D:  LDU  #INTSCR                ;INITIAL HIGH SCORES
LCC70:  LDD  ,U++
LCC72:  STD  ,X++
LCC74:  CMPX #HSCORS+40
LCC77:  BLO  LCC70                  ;HSEND
LCC79:  RTS

INTINT:
LCC7A:  .byte $0F, $02, $09         ;OBI
LCC7D:  .byte $17, $01, $0E         ;WAN
LCC80:  .byte $08, $01, $0E         ;HAN
LCC83:  .byte $07, $0A, $12         ;GJR
LCC86:  .byte $0D, $0C, $08         ;MLH
LCC89:  .byte $0A, $05, $04         ;JED
LCC8C:  .byte $0E, $0C, $01         ;NLA
LCC8F:  .byte $05, $0A, $04         ;EJD
LCC92:  .byte $05, $01, $12         ;EAR
LCC95:  .byte $12, $0C, $0D         ;RLM

INTSCR:
LCC98:  .word $0128, $5353
LCC9C:  .word $0111, $0936
LCCA0:  .word $0102, $4650
LCCA4:  .word $0087, $2551
LCCA8:  .word $0081, $3553
LCCAC:  .word $0070, $4899
LCCB0:  .word $0051, $8000
LCCB4:  .word $0049, $2159
LCCB8:  .word $0038, $4766
LCCBC:  .word $0038, $0655

;==============================================================================
; MODULE WSROOT   WSROOT.MAC
;   ROOT VERSION OF BANK SWITCHING VECTOR TABLE
;==============================================================================

;------------------------------------------------------------------------------
; INOBJ - WSVCTR - VECTOR ROUTINES FOR BANK SWITCHING
;   WSOBJ
;------------------------------------------------------------------------------
INOBJ:
LCCC0:  ORCC #$01                   ;OVLY INOBJ
LCCC2:  ROR  W_BANK
LCCC5:  JSR  JINOBJ
LCCC8:  CLR  W_BANK
LCCCB:  RTS

;------------------------------------------------------------------------------
; ADBOBJ - [note] Bank-switch vector to overlay JADBOBJ (add object points to mbox, B = object #); restores root bank
;------------------------------------------------------------------------------
ADBOBJ:
LCCCC:  ORCC #$01                   ;OVLY ADBOBJ
LCCCE:  ROR  W_BANK
LCCD1:  JSR  JADBOBJ
LCCD4:  CLR  W_BANK
LCCD7:  RTS

;------------------------------------------------------------------------------
; ADOBJ - MAKE SURE WE CAN USE IT  (comment at the call)
;------------------------------------------------------------------------------
ADOBJ:
LCCD8:  ORCC #$01                   ;OVLY ADOBJ
LCCDA:  ROR  W_BANK
LCCDD:  JSR  JADOBJ
LCCE0:  CLR  W_BANK
LCCE3:  RTS

;------------------------------------------------------------------------------
; BJCNTR - START FROM CENTER SCREEN  (comment at the calls)
;------------------------------------------------------------------------------
BJCNTR:
LCCE4:  ORCC #$01                   ;OVLY BJCNTR
LCCE6:  ROR  W_BANK
LCCE9:  JSR  JBJCNTR
LCCEC:  CLR  W_BANK
LCCEF:  RTS

;------------------------------------------------------------------------------
; OBJCEN - THEN PROCESS THE CENTER POINT  (comment at the calls)
;   PROCESS CENTER OF SHIP  (another call)
;   PROCESS CENTER OF GUNSHOT  (another call)
;------------------------------------------------------------------------------
OBJCEN:
LCCF0:  ORCC #$01                   ;OVLY OBJCEN
LCCF2:  ROR  W_BANK
LCCF5:  JSR  JOBJCEN
LCCF8:  CLR  W_BANK
LCCFB:  RTS

;------------------------------------------------------------------------------
; BJLNV - DRAW VISIBLE LINE  (comment at the calls)
;------------------------------------------------------------------------------
BJLNV:
LCCFC:  ORCC #$01                   ;OVLY BJLNV
LCCFE:  ROR  W_BANK
LCD01:  JSR  JBJLNV
LCD04:  CLR  W_BANK
LCD07:  RTS

;------------------------------------------------------------------------------
; BJLNB - START FROM CENTER SCREEN  (comment at the call)
;------------------------------------------------------------------------------
BJLNB:
LCD08:  ORCC #$01                   ;OVLY BJLNB
LCD0A:  ROR  W_BANK
LCD0D:  JSR  JBJLNB
LCD10:  CLR  W_BANK
LCD13:  RTS

;------------------------------------------------------------------------------
; OBJBPNT - PROCESS OBJECT POINTS  (comment at the call)
;------------------------------------------------------------------------------
OBJBPNT:
LCD14:  ORCC #$01                   ;OVLY OBJBPNT
LCD16:  ROR  W_BANK
LCD19:  JSR  JOBJBPNT
LCD1C:  CLR  W_BANK
LCD1F:  RTS

;------------------------------------------------------------------------------
; OBJPNT - THEN GET THE POINTS  (comment at the call)
;------------------------------------------------------------------------------
OBJPNT:
LCD20:  ORCC #$01                   ;OVLY OBJPNT
LCD22:  ROR  W_BANK
LCD25:  JSR  JOBJPNT
LCD28:  CLR  W_BANK
LCD2B:  RTS

;------------------------------------------------------------------------------
; OBJDRW - DRAW THE OBJECT LINES  (comment at the call)
;   AND DRAW IT  (another call)
;------------------------------------------------------------------------------
OBJDRW:
LCD2C:  ORCC #$01                   ;OVLY OBJDRW
LCD2E:  ROR  W_BANK
LCD31:  JSR  JOBJDRW
LCD34:  CLR  W_BANK
LCD37:  RTS

;------------------------------------------------------------------------------
; BJGROT - PRE-ROTATE ITS POINTS  (comment at the calls)
;   ROTATE IT IN FRONT OF US  (another call)
;   ROTATE THE GROUND OBJECT POINTS AND SAVE STARTING AT M.GD  (another call)
;------------------------------------------------------------------------------
BJGROT:
LCD38:  ORCC #$01                   ;OVLY BJGROT
LCD3A:  ROR  W_BANK
LCD3D:  JSR  JBJGROT
LCD40:  CLR  W_BANK
LCD43:  RTS

;------------------------------------------------------------------------------
; BJFROT - FLIPPED PRE-ROTATE  (comment at the calls)
;------------------------------------------------------------------------------
BJFROT:
LCD44:  ORCC #$01                   ;OVLY BJFROT
LCD46:  ROR  W_BANK
LCD49:  JSR  JBJFROT
LCD4C:  CLR  W_BANK
LCD4F:  RTS

;------------------------------------------------------------------------------
; BJGPNT - DO POINTS SPEEDILY  (comment at the calls)
;   ELSE USE REGULAR  (another call)
;   TRANSLATE AND PROJECT GROUND OBJECT'S POINTS  (another call)
;------------------------------------------------------------------------------
BJGPNT:
LCD50:  ORCC #$01                   ;OVLY BJGPNT
LCD52:  ROR  W_BANK
LCD55:  JSR  JBJGPNT
LCD58:  CLR  W_BANK
LCD5B:  RTS

;------------------------------------------------------------------------------
; BJBCLP - ALL CLOSE PANELS GET POINTS CLIPPED  (comment at the calls)
;   THEN PROCESS POINTS WITH CLIPPING  (another call)
;------------------------------------------------------------------------------
BJBCLP:
LCD5C:  ORCC #$01                   ;OVLY BJBCLP
LCD5E:  ROR  W_BANK
LCD61:  JSR  JBJBCLP
LCD64:  CLR  W_BANK
LCD67:  RTS

;------------------------------------------------------------------------------
; BJGCLP - CLIP CLOSE OBJECTS  (comment at the call)
;------------------------------------------------------------------------------
BJGCLP:
LCD68:  ORCC #$01                   ;OVLY BJGCLP
LCD6A:  ROR  W_BANK
LCD6D:  JSR  JBJGCLP
LCD70:  CLR  W_BANK
LCD73:  RTS

;------------------------------------------------------------------------------
; BJGDRW - DRAW THE LINES  (comment at the call)
;   DRAW THE OBJECT, NEEDS ORIGINAL M.XP,YP,ZP  (another call)
;------------------------------------------------------------------------------
BJGDRW:
LCD74:  ORCC #$01                   ;OVLY BJGDRW
LCD76:  ROR  W_BANK
LCD79:  JSR  JBJGDRW
LCD7C:  CLR  W_BANK
LCD7F:  RTS

;------------------------------------------------------------------------------
; VWSTAR - WSSTAR
;------------------------------------------------------------------------------
VWSTAR:
LCD80:  ORCC #$01                   ;OVLY VWSTAR
LCD82:  ROR  W_BANK
LCD85:  JSR  JVWSTAR
LCD88:  CLR  W_BANK
LCD8B:  RTS

;------------------------------------------------------------------------------
; VWSTRG - VIEW GROUND STARS  (comment at the calls)
;------------------------------------------------------------------------------
VWSTRG:
LCD8C:  ORCC #$01                   ;OVLY VWSTRG
LCD8E:  ROR  W_BANK
LCD91:  JSR  JVWSTRG
LCD94:  CLR  W_BANK
LCD97:  RTS

;==============================================================================
; MODULE WSMATH   WSMATH.MAC
;   MATH AND COMMON ROUTINES FOR ROOT AND OVERLAY
;==============================================================================

;------------------------------------------------------------------------------
; ASRD8 - SHIFT ROUTINES
;------------------------------------------------------------------------------
ASRD8:
LCD98:  ASRA                        ;.IRP .A <8,7,6,5,4,3,2,1>
LCD99:  RORB

ASRD7:
LCD9A:  ASRA
LCD9B:  RORB

;------------------------------------------------------------------------------
; ASRD6 - [note] Entry point: arithmetic shift D right 6 bits (falls through ASRD5..ASRD1 to the RTS at ASRD0)
;------------------------------------------------------------------------------
ASRD6:
LCD9C:  ASRA
LCD9D:  RORB

;------------------------------------------------------------------------------
; ASRD5 - [note] Entry point: arithmetic shift D right 5 bits (falls through ASRD4..ASRD1 to the RTS at ASRD0)
;------------------------------------------------------------------------------
ASRD5:
LCD9E:  ASRA
LCD9F:  RORB

;------------------------------------------------------------------------------
; ASRD4 - [note] Entry point: arithmetic shift D right 4 bits (falls through ASRD3..ASRD1 to the RTS at ASRD0)
;------------------------------------------------------------------------------
ASRD4:
LCDA0:  ASRA
LCDA1:  RORB

;------------------------------------------------------------------------------
; ASRD3 - [note] Entry point: arithmetic shift D right 3 bits (falls through ASRD2, ASRD1 to the RTS at ASRD0)
;------------------------------------------------------------------------------
ASRD3:
LCDA2:  ASRA
LCDA3:  RORB

ASRD2:
LCDA4:  ASRA
LCDA5:  RORB

ASRD1:
LCDA6:  ASRA
LCDA7:  RORB

ASRD0:
LCDA8:  RTS

;------------------------------------------------------------------------------
; LSLD8 - [note] Entry point: shift D left 8 bits (falls through LSLD7..LSLD1 to the RTS at LSLD0)
;------------------------------------------------------------------------------
LSLD8:
LCDA9:  LSLB                        ;.IRP .A <8,7,6,5,4,3,2,1>
LCDAA:  ROLA

;------------------------------------------------------------------------------
; LSLD7 - [note] Entry point: shift D left 7 bits (falls through LSLD6..LSLD1 to the RTS at LSLD0)
;------------------------------------------------------------------------------
LSLD7:
LCDAB:  LSLB
LCDAC:  ROLA

LSLD6:
LCDAD:  LSLB
LCDAE:  ROLA

LSLD5:
LCDAF:  LSLB
LCDB0:  ROLA

;------------------------------------------------------------------------------
; LSLD4 - [note] Entry point: shift D left 4 bits (falls through LSLD3..LSLD1 to the RTS at LSLD0)
;------------------------------------------------------------------------------
LSLD4:
LCDB1:  LSLB
LCDB2:  ROLA

LSLD3:
LCDB3:  LSLB
LCDB4:  ROLA

;------------------------------------------------------------------------------
; LSLD2 - [note] Entry point: shift D left 2 bits (falls through LSLD1 to the RTS at LSLD0)
;------------------------------------------------------------------------------
LSLD2:
LCDB5:  LSLB
LCDB6:  ROLA

LSLD1:
LCDB7:  LSLB
LCDB8:  ROLA

LSLD0:
LCDB9:  RTS

;------------------------------------------------------------------------------
; MGOWT - MATH SUBROUTINES
;   START THE MATH BOX, AND WAIT
;------------------------------------------------------------------------------
MGOWT:
LCDBA:  STA  M_PCGO

MWAIT:
MWAIT_10:
LCDBD:  TST  M_BUSY                 ;SLOW BUT SAFE
LCDC0:  BMI  MWAIT
LCDC2:  RTS

;------------------------------------------------------------------------------
; UNITV - SETUP UNIT VECTORS
;------------------------------------------------------------------------------
UNITV:
LCDC3:  LDD  #$0000
LCDC6:  STD  MS_VX,U                ;VELOCITY VECTORS
LCDC8:  STD  MS_VY,U
LCDCA:  STD  MS_VZ,U
LCDCC:  STD  MS_TX,U                ;TRANSLATION COORDS
LCDCE:  STD  MS_TY,U
LCDD0:  STD  MS_TZ,U
;STD M$AX(U) ;IDENTITY MATRIX
LCDD2:  STD  MS_AY,U
LCDD4:  STD  MS_AZ,U
LCDD6:  STD  MS_BX,U
;STD M$BY(U)
LCDD8:  STD  MS_BZ,U
LCDDA:  STD  MS_CX,U
LCDDC:  STD  MS_CY,U
;STD M$CZ(U)
LCDDE:  LDA  #$40                   ;IDENTITY VALUE FOR 1.
LCDE0:  STD  MS_AX,U
LCDE2:  STD  MS_BY,U
LCDE4:  STD  MS_CZ,U
LCDE6:  RTS

;------------------------------------------------------------------------------
; TRANU1 - TRANSPOSE U1 UNIT VECTORS
;------------------------------------------------------------------------------
TRANU1:
LCDE7:  LDD  (MS_AY+M_U1)&$FFFF
LCDEA:  LDU  (MS_BX+M_U1)&$FFFF
LCDED:  STD  (MS_BX+M_U1)&$FFFF
LCDF0:  STU  (MS_AY+M_U1)&$FFFF
LCDF3:  LDD  (MS_AZ+M_U1)&$FFFF
LCDF6:  LDU  MS_CX+M_U1
LCDF9:  STD  MS_CX+M_U1
LCDFC:  STU  (MS_AZ+M_U1)&$FFFF
LCDFF:  LDD  (MS_BZ+M_U1)&$FFFF
LCE02:  LDU  MS_CY+M_U1
LCE05:  STD  MS_CY+M_U1
LCE08:  STU  (MS_BZ+M_U1)&$FFFF
LCE0B:  RTS

;------------------------------------------------------------------------------
; IS1UV - MATH BOX, PRIMARY INIT  (comment at the calls)
;   DOWNLOAD LATEST UNIT VECTOR  (another call)
;   DOWNLOAD VECTORS  (another call)
;------------------------------------------------------------------------------
IS1UV:
LCE0C:  STA  M_BICL
LCE0F:  CLR  M_BICH
LCE12:  LDA  #MS_DLD1
LCE14:  JSR  MGOWT
LCE17:  RTS

;------------------------------------------------------------------------------
; IS2UV - DOWNLOAD SHIP 2 UNIT VECTORS  (comment at the call)
;   DOWNLOAD DESTINATION MATRIX  (another call)
;------------------------------------------------------------------------------
IS2UV:
LCE18:  STA  M_BICL
LCE1B:  CLR  M_BICH
LCE1E:  LDA  #MS_DLD2
LCE20:  JSR  MGOWT
LCE23:  RTS

;------------------------------------------------------------------------------
; S1RL - ROLL PLAYER SHIP
;------------------------------------------------------------------------------
S1RL:
LCE24:  LDD  #MS_S1BC
LCE27:  STD  M_BIC
LCE2A:  LDA  #MS_ROLL
LCE2C:  JMP  MGOWT                  ;RTS

;------------------------------------------------------------------------------
; S1PT - PITCH PLAYER SHIP
;------------------------------------------------------------------------------
S1PT:
LCE2F:  LDD  #MS_S1BC
LCE32:  STD  M_BIC
LCE35:  LDA  #MS_PTCH
LCE37:  JMP  MGOWT                  ;RTS

;------------------------------------------------------------------------------
; S1YW - YAW PLAYER SHIP
;------------------------------------------------------------------------------
S1YW:
LCE3A:  LDD  #MS_S1BC
LCE3D:  STD  M_BIC
LCE40:  LDA  #MS_YAW
LCE42:  JMP  MGOWT                  ;RTS

;------------------------------------------------------------------------------
; RND8 - RANDOM NUMBER SET
;   GEN NON-VOLATILE SETS OF RANDOM NUMBERS
;------------------------------------------------------------------------------
RND8:
LCE45:  LDD  RND_S1
LCE47:  STD  RND_S2                 ;MOVE RND1,2 TO RND2,3
LCE49:  LDA  P_RND1                 ;GET NEW RANDOM BYTE
LCE4C:  STA  RND_S1
LCE4E:  RTS

;==============================================================================
; MODULE WSFIL3   WSFIL3.MAC
;==============================================================================

;.SBTTL STAR WARS FILLER FOR ROM 3
LCE4F:  .byte $13, $D8, $35, $8F, $04, $C4, $55, $52 ;.IRPC .A,<ERIC DURFEY GOT WIRED>
LCE57:  .byte $46, $45, $59, $20, $47, $4F, $54, $20
LCE5F:  .byte $57, $49, $52, $45, $44

CHKSM3:
LCE64:  .word PCKS3

FILL3:
LCE66:  .byte $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF ;.REPT 100.  FILL WITH FF'S
LCE6E:  .byte $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
LCE76:  .byte $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
LCE7E:  .byte $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
LCE86:  .byte $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
LCE8E:  .byte $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
LCE96:  .byte $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
LCE9E:  .byte $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
LCEA6:  .byte $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
LCEAE:  .byte $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
LCEB6:  .byte $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
LCEBE:  .byte $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
LCEC6:  .byte $FF, $FF, $FF, $FF

CPYRT3:
LCECA:  .byte $43, $4F, $50, $59, $52, $49, $47, $48 ;.ASCII /COPYRIGHT 1983 ATARI/
LCED2:  .byte $54, $20, $31, $39, $38, $33, $20, $41
LCEDA:  .byte $54, $41, $52, $49

;==============================================================================
; MODULE WSVROM   WSVROM.MAC
;==============================================================================

;.SBTTL STAR WARS BANNER

FAKEVG:
LCEDE:  .word $1AF6, $1DA8          ;VOFFM -60.,-129.
LCEE2:  .word $0000, $E208          ;AON 112,46
LCEE6:  .word $1F7E, $E000          ;AON 112,33
LCEEA:  .word $0000, $FF74          ;AON 98,33
LCEEE:  .word (((DROP55-VGBASE)/2)&$1FFF)+$A000 ;DROP 5,5
LCEF0:  .word $1EC0, $FFCE          ;AON 93,1
LCEF4:  .word (((DROP35-VGBASE)/2)&$1FFF)+$A000 ;DROP 3,5
LCEF6:  .word $0000, $FF4C          ;AON 75,1
LCEFA:  .word (((DROP55-VGBASE)/2)&$1FFF)+$A000 ;DROP 5,5
LCEFC:  .word $0140, $E050          ;AON 83,33
LCF00:  .word $0000, $FF4C          ;AON 65,33
LCF04:  .word $51FB                 ;AON 64,30
LCF06:  .word $1FEC, $E032          ;AON 69,28
LCF0A:  .word $1FA6, $E032          ;AON 74,19
LCF0E:  .word (((DROP55-VGBASE)/2)&$1FFF)+$A000 ;DROP 5,5
LCF10:  .word $1FB0, $FFEC          ;AON 72,11
LCF14:  .word (((DROP55-VGBASE)/2)&$1FFF)+$A000 ;DROP 5,5
LCF16:  .word $1F9C, $FF88          ;AON 60,1
LCF1A:  .word (((DROP35-VGBASE)/2)&$1FFF)+$A000 ;DROP 3,5
LCF1C:  .word $0000, $FE0C          ;AON 10,1
LCF20:  .word (((DROP35-VGBASE)/2)&$1FFF)+$A000 ;DROP 3,5
LCF22:  .word $008C, $E05A          ;AON 19,15
LCF26:  .word $0000, $E140          ;AON 51,15
LCF2A:  .word $4AE5                 ;AON 52,17
LCF2C:  .word $0014, $FFD8          ;AON 48,19
LCF30:  .word (((DROP15-VGBASE)/2)&$1FFF)+$A000 ;DROP 1,5
LCF32:  .word $005A, $FFCE          ;AON 43,28
LCF36:  .word (((DROP35-VGBASE)/2)&$1FFF)+$A000 ;DROP 3,5
LCF38:  .word $0050, $E028          ;AON 47,36
LCF3C:  .word $0064, $E082          ;AON 60,46
LCF40:  .word VGSCAL                ;SCAL
LCF42:  .word VGCNTR                ;CNTR
LCF44:  .word $C000                 ;RTSL
LCF46:  .word $1AF6, $00B4          ;VOFFM 18.,-129.
LCF4A:  .word $1E3E, $E0B4          ;AON 56,1
LCF4E:  .word (((DROP35-VGBASE)/2)&$1FFF)+$A000 ;DROP 3,5
LCF50:  .word $0000, $FF60          ;AON 40,1
LCF54:  .word (((DROP35-VGBASE)/2)&$1FFF)+$A000 ;DROP 3,5
LCF56:  .word $0046, $FFE2          ;AON 37,8
LCF5A:  .word (((DROP45-VGBASE)/2)&$1FFF)+$A000 ;DROP 4,5
LCF5C:  .word $0000, $FF56          ;AON 20,8
LCF60:  .word (((DROP55-VGBASE)/2)&$1FFF)+$A000 ;DROP 5,5
LCF62:  .word $1FBA, $FFF6          ;AON 19,1
LCF66:  .word (((DROP55-VGBASE)/2)&$1FFF)+$A000 ;DROP 5,5
LCF68:  .word $0000, $FF60          ;AON 3,1
LCF6C:  .word (((DROP35-VGBASE)/2)&$1FFF)+$A000 ;DROP 3,5
LCF6E:  .word $01C2, $E078          ;AON 15,46
LCF72:  .word $0000, $E0E6          ;AON 38,46
LCF76:  .word $1F88, $1F92          ;AOFF 27,34
LCF7A:  .word (((DROP35-VGBASE)/2)&$1FFF)+$A000 ;DROP 3,5
LCF7C:  .word $1F74, $E046          ;AON 34,20
LCF80:  .word $0000, $FF92          ;AON 23,20
LCF84:  .word $008C, $E028          ;AON 27,34
LCF88:  .word VGSCAL                ;SCAL
LCF8A:  .word VGCNTR                ;CNTR
LCF8C:  .word $C000                 ;RTSL
LCF8E:  .word $1AF6, $0226          ;VOFFM 55.,-129.
LCF92:  .word $0000, $FEE8          ;AON -13,46
LCF96:  .word (((DROP55-VGBASE)/2)&$1FFF)+$A000 ;DROP 5,5
LCF98:  .word $1E3E, $E05A          ;AON -4,1
LCF9C:  .word $0000, $E0AA          ;AON 13,1
LCFA0:  .word (((DROP45-VGBASE)/2)&$1FFF)+$A000 ;DROP 4,5
LCFA2:  .word $008C, $FFD8          ;AON 9,15
LCFA6:  .word $1F74, $E122          ;AON 38,1
LCFAA:  .word (((DROP35-VGBASE)/2)&$1FFF)+$A000 ;DROP 3,5
LCFAC:  .word $0000, $E154          ;AON 72,1
LCFB0:  .word (((DROP35-VGBASE)/2)&$1FFF)+$A000 ;DROP 3,5
LCFB2:  .word $008C, $FFA6          ;AON 63,15
LCFB6:  .word $0000, $FEF2          ;AON 36,15
LCFBA:  .word $0014, $FFD8          ;AON 32,17
LCFBE:  .word $003C, $E03C          ;AON 38,23
LCFC2:  .word (((DROP25-VGBASE)/2)&$1FFF)+$A000 ;DROP 2,5
LCFC4:  .word $006E, $FFCE          ;AON 33,34
LCFC8:  .word $0078, $FF4C          ;AON 15,46
LCFCC:  .word $1F88, $000A          ;AOFF 16,34
LCFD0:  .word (((DROP25-VGBASE)/2)&$1FFF)+$A000 ;DROP 2,5
LCFD2:  .word $1FD8, $E03C          ;AON 22,30
LCFD6:  .word $56E5                 ;AON 23,28
LCFD8:  .word $1FCE, $FFD8          ;AON 19,23
LCFDC:  .word $0000, $FF7E          ;AON 6,23
LCFE0:  .word $006E, $FFD8          ;AON 2,34
LCFE4:  .word $0000, $E08C          ;AON 16,34
LCFE8:  .word VGSCAL                ;SCAL
LCFEA:  .word VGCNTR                ;CNTR
LCFEC:  .word $C000                 ;RTSL
LCFEE:  .word $18BC, $1C4A          ;VOFFM -95.,-186.
LCFF2:  .word (((DROP36-VGBASE)/2)&$1FFF)+$A000 ;DROP 3,6
LCFF4:  .word $1F24, $FFBA          ;AON 38,32
LCFF8:  .word $00DC, $E0A0          ;AON 54,54
LCFFC:  .word $0000, $E08C          ;AON 68,54
LD000:  .word (((DROP36-VGBASE)/2)&$1FFF)+$A000 ;DROP 3,6
LD002:  .word $1F24, $FFBA          ;AON 61,32
LD006:  .word $00DC, $E0AA          ;AON 78,54
LD00A:  .word $0000, $E08C          ;AON 92,54
LD00E:  .word (((DROP46-VGBASE)/2)&$1FFF)+$A000 ;DROP 4,6
LD010:  .word $1DE4, $FEE8          ;AON 64,00
LD014:  .word (((DROP66-VGBASE)/2)&$1FFF)+$A000 ;DROP 6,6
LD016:  .word $0000, $FF10          ;AON 40,0
LD01A:  .word (((DROP66-VGBASE)/2)&$1FFF)+$A000 ;DROP 6,6
LD01C:  .word $0096, $E032          ;AON 45,15
LD020:  .word $1F6A, $FF7E          ;AON 32,0
LD024:  .word (((DROP66-VGBASE)/2)&$1FFF)+$A000 ;DROP 6,6
LD026:  .word $0000, $FF10          ;AON 8,0
LD02A:  .word (((DROP66-VGBASE)/2)&$1FFF)+$A000 ;DROP 6,6
LD02C:  .word $021C, $E0B4          ;AON 26,54
LD030:  .word $0000, $E0BE          ;AON 45,54
LD034:  .word VGSCAL                ;SCAL
LD036:  .word VGCNTR                ;CNTR
LD038:  .word $C000                 ;RTSL
LD03A:  .word $18BC, $1FB0          ;VOFFM -8.,-186.
LD03E:  .word $1DE4, $E082          ;AON 64,0
LD042:  .word (((DROP66-VGBASE)/2)&$1FFF)+$A000 ;DROP 6,6
LD044:  .word $0000, $FF38          ;AON 44,0
LD048:  .word (((DROP66-VGBASE)/2)&$1FFF)+$A000 ;DROP 6,6
LD04A:  .word $0050, $FFE2          ;AON 41,8
LD04E:  .word (((DROP66-VGBASE)/2)&$1FFF)+$A000 ;DROP 6,6
LD050:  .word $0000, $FF2E          ;AON 20,8
LD054:  .word (((DROP66-VGBASE)/2)&$1FFF)+$A000 ;DROP 6,6
LD056:  .word $1FB0, $FFC4          ;AON 14,0
LD05A:  .word (((DROP66-VGBASE)/2)&$1FFF)+$A000 ;DROP 6,6
LD05C:  .word $0000, $FF24          ;AON -8,0
LD060:  .word (((DROP66-VGBASE)/2)&$1FFF)+$A000 ;DROP 6,6
LD062:  .word $021C, $E118          ;AON 20,54
LD066:  .word $0000, $E136          ;AON 51,54
LD06A:  .word $1F88, $1F56          ;AOFF 34,42
LD06E:  .word (((DROP56-VGBASE)/2)&$1FFF)+$A000 ;DROP 5,6
LD070:  .word $1F2E, $E03C          ;AON 40,21
LD074:  .word $0000, $FF56          ;AON 23,21
LD078:  .word $00D2, $E06E          ;AON 34,42
LD07C:  .word VGSCAL                ;SCAL
LD07E:  .word VGCNTR                ;CNTR
LD080:  .word $C000                 ;RTSL
LD082:  .word $18BC, $019A          ;VOFFM 41.,-186.
LD086:  .word $0000, $FE84          ;AON 3,54
LD08A:  .word $1DE4, $E00A          ;AON 4,0
LD08E:  .word $0000, $E0C8          ;AON 24,0
LD092:  .word (((DROP66-VGBASE)/2)&$1FFF)+$A000 ;DROP 6,6
LD094:  .word $00B4, $FFEC          ;AON 22,18
LD098:  .word $1F4C, $E154          ;AON 56,0
LD09C:  .word (((DROP66-VGBASE)/2)&$1FFF)+$A000 ;DROP 6,6
LD09E:  .word $0000, $E258          ;AON 116,0
LD0A2:  .word (((DROP66-VGBASE)/2)&$1FFF)+$A000 ;DROP 6,6
LD0A4:  .word $0078, $E078          ;AON 128,12
LD0A8:  .word (((DROP66-VGBASE)/2)&$1FFF)+$A000 ;DROP 6,6
LD0AA:  .word $006E, $FFC4          ;AON 122,23
LD0AE:  .word $0078, $FF1A          ;AON 99,35
LD0B2:  .word $0014, $FFA6          ;AON 90,37
LD0B6:  .word $0028, $FFEC          ;AON 88,41
LD0BA:  .word $0000, $E168          ;AON 124,41
LD0BE:  .word (((DROP46-VGBASE)/2)&$1FFF)+$A000 ;DROP 4,6
LD0C0:  .word $0082, $FFB0          ;AON 116,54
LD0C4:  .word $0000, $FE70          ;AON 76,54
LD0C8:  .word $1F9C, $FF9C          ;AON 66,44
LD0CC:  .word (((DROP36-VGBASE)/2)&$1FFF)+$A000 ;DROP 3,6
LD0CE:  .word $1F9C, $E028          ;AON 70,34
LD0D2:  .word (((DROP46-VGBASE)/2)&$1FFF)+$A000 ;DROP 4,6
LD0D4:  .word $1F92, $E0BE          ;AON 89,23
LD0D8:  .word (((DROP16-VGBASE)/2)&$1FFF)+$A000 ;DROP 1,6
LD0DA:  .word $1FEC, $E050          ;AON 97,21
LD0DE:  .word $51E5                 ;AON 98,18
LD0E0:  .word $0000, $FEE8          ;AON 70,18
LD0E4:  .word $001E, $FF42          ;AON 51,21
LD0E8:  .word $0050, $E08C          ;AON 65,29
LD0EC:  .word (((DROP26-VGBASE)/2)&$1FFF)+$A000 ;DROP 2,6
LD0EE:  .word $0082, $FFD8          ;AON 61,42
LD0F2:  .word $0078, $FF38          ;AON 41,54
LD0F6:  .word $1F88, $1FCE          ;AOFF 36,42  HOLE IN 'R'
LD0FA:  .word (((DROP36-VGBASE)/2)&$1FFF)+$A000 ;DROP 3,6
LD0FC:  .word $1FC4, $E064          ;AON 46,36
LD100:  .word $1FD8, $E00A          ;AON 47,32
LD104:  .word $1FE2, $FFB0          ;AON 39,29
LD108:  .word $0000, $FF2E          ;AON 18,29
LD10C:  .word $0082, $FFF6          ;AON 17,42
LD110:  .word $0000, $E0BE          ;AON 36,42
LD114:  .word VGSCAL                ;SCAL
LD116:  .word VGCNTR                ;CNTR
LD118:  .word $C000                 ;RTSL

;.SBTTL GUNSHOT PICTURES
LD11A:  .word $64FF                 ;COLOR VGCRED,0FF
LD11C:  .word $0078, $E00A          ;AON 2,16
LD120:  .word $1FD3, $001E          ;AOFF 8,10
LD124:  .word $1FB5, $FFD8          ;AON 0,0
LD128:  .word $003C, $E04B          ;AON 15,8
LD12C:  .word (((VRFLS-VGBASE)/2)&$1FFF)+$A000 ;FUSE
LD12E:  .word (((VRGNT-VGBASE)/2)&$1FFF)+$A000
LD130:  .word $64FF
LD132:  .word $1FD3, $1FFB          ;AOFF 14,2
LD136:  .word $1FF1, $FFBA          ;AON 0,0
LD13A:  .word $1FD3, $E050          ;AON 16,-6
LD13E:  .word (((VRFLS-VGBASE)/2)&$1FFF)+$A000 ;FUSE
LD140:  .word (((VRGNT-VGBASE)/2)&$1FFF)+$A000
LD142:  .word $64FF
LD144:  .word $1FD3, $1FEC          ;AOFF 12,-12
LD148:  .word $005A, $FFC4          ;AON 0,0
LD14C:  .word $1FB5, $E01E          ;AON 6,-10
LD150:  .word $5116                 ;AOFF 2,-14
LD152:  .word $0069, $FFF6          ;AON 0,0
LD156:  .word $1F88, $FFE2          ;AON -6,-16
LD15A:  .word (((VRFLS-VGBASE)/2)&$1FFF)+$A000 ;FUSE
LD15C:  .word (((VRGNT-VGBASE)/2)&$1FFF)+$A000
LD15E:  .word $64FF
LD160:  .word $002D, $1FF6          ;AOFF -8,-10
LD164:  .word $004B, $E028          ;AON 0,0
LD168:  .word $1FC4, $FFC4          ;AON -12,-8
LD16C:  .word $002D, $000A          ;AOFF -10,-2
LD170:  .word $000F, $E032          ;AON 0,0
LD174:  .word $000F, $FFB0          ;AON -16,2
LD178:  .word (((VRFLS-VGBASE)/2)&$1FFF)+$A000 ;FUSE
LD17A:  .word (((VRGNT-VGBASE)/2)&$1FFF)+$A000
LD17C:  .word $64FF
LD17E:  .word $002D, $0000          ;AOFF -16,8
LD182:  .word $1FC4, $E050          ;AON 0,0
LD186:  .word $003C, $FFE2          ;AON -6,8
LD18A:  .word $003C, $0000          ;AOFF -6,16
LD18E:  .word (((VRFLS-VGBASE)/2)&$1FFF)+$A000 ;FUSE
LD190:  .word (((VRGNT-VGBASE)/2)&$1FFF)+$A000
LD192:  .word $64FF
LD194:  .word $1F88, $E01E          ;AON 0,0
LD198:  .word (((VRFLS-VGBASE)/2)&$1FFF)+$A000 ;FUSE
LD19A:  .word (((VRGNT-VGBASE)/2)&$1FFF)+$A000
LD19C:  .word $64FF
LD19E:  .word $C000                 ;RTSL
LD1A0:  .word $64FF                 ;COLOR VGCRED,0FF
LD1A2:  .word $005A, $E00F          ;AON 3,12
LD1A6:  .word $1FF1, $000F          ;AOFF 6,10
LD1AA:  .word $1FB5, $FFE2          ;AON 0,0
LD1AE:  .word $002D, $E050          ;AON 16,6
LD1B2:  .word (((VRFLS-VGBASE)/2)&$1FFF)+$A000 ;FUSE
LD1B4:  .word (((VRGNT-VGBASE)/2)&$1FFF)+$A000
LD1B6:  .word $64FF
LD1B8:  .word $1FCC, $0005          ;AOFF 17,-1
LD1BC:  .word $0007, $FFAB          ;AON 0,0
LD1C0:  .word $1FB5, $E046          ;AON 14,-10
LD1C4:  .word (((VRFLS-VGBASE)/2)&$1FFF)+$A000 ;FUSE
LD1C6:  .word (((VRGNT-VGBASE)/2)&$1FFF)+$A000
LD1C8:  .word $64FF
LD1CA:  .word $1FF1, $1FCE          ;AOFF 4,-12
LD1CE:  .word $005A, $FFEC          ;AON 0,0
LD1D2:  .word $1F88, $E000          ;AON 0,-16
LD1D6:  .word $4F16                 ;AOFF -4,-12
LD1D8:  .word $005A, $E014          ;AON 0,0
LD1DC:  .word $1F90, $FFCE          ;AON -10,-15
LD1E0:  .word (((VRFLS-VGBASE)/2)&$1FFF)+$A000 ;FUSE
LD1E2:  .word (((VRGNT-VGBASE)/2)&$1FFF)+$A000
LD1E4:  .word $64FF
LD1E6:  .word $003C, $1FF1          ;AOFF -13,-7
LD1EA:  .word $0034, $E041          ;AON 0,0
LD1EE:  .word $1FE2, $FFB0          ;AON -16,-4
LD1F2:  .word $002D, $0014          ;AOFF -12,2
LD1F6:  .word $1FF1, $E03C          ;AON 0,0
LD1FA:  .word $002D, $FFB0          ;AON -16,6
LD1FE:  .word (((VRFLS-VGBASE)/2)&$1FFF)+$A000 ;FUSE
LD200:  .word (((VRGNT-VGBASE)/2)&$1FFF)+$A000
LD202:  .word $64FF
LD204:  .word $4F05                 ;AOFF -14,10
LD206:  .word $1FB5, $E046          ;AON 0,0
LD20A:  .word $005A, $FFE2          ;AON -6,12
LD20E:  .word $0025, $001E          ;AOFF 0,17
LD212:  .word (((VRFLS-VGBASE)/2)&$1FFF)+$A000 ;FUSE
LD214:  .word (((VRGNT-VGBASE)/2)&$1FFF)+$A000
LD216:  .word $64FF
LD218:  .word $1F81, $E000          ;AON 0,0
LD21C:  .word (((VRFLS-VGBASE)/2)&$1FFF)+$A000 ;FUSE
LD21E:  .word (((VRGNT-VGBASE)/2)&$1FFF)+$A000
LD220:  .word $64FF
LD222:  .word $C000                 ;RTSL
LD224:  .word $64FF                 ;COLOR VGCRED,0FF
LD226:  .word $005A, $E00A          ;AON 2,12
LD22A:  .word $4B0F                 ;AOFF 8,15
LD22C:  .word (((VRFLS-VGBASE)/2)&$1FFF)+$A000 ;FUSE
LD22E:  .word (((VRGNT-VGBASE)/2)&$1FFF)+$A000
LD230:  .word $64FF
LD232:  .word $1F90, $FFD8          ;AON 0,0
LD236:  .word $004B, $E03C          ;AON 12,10
LD23A:  .word $1FD3, $1FF6          ;AOFF 10,4
LD23E:  .word $1FE2, $FFCE          ;AON 0,0
LD242:  .word $000F, $E055          ;AON 17,2
LD246:  .word (((VRFLS-VGBASE)/2)&$1FFF)+$A000 ;FUSE
LD248:  .word (((VRGNT-VGBASE)/2)&$1FFF)+$A000
LD24A:  .word $64FF
LD24C:  .word $1FE2, $1FF1          ;AOFF 14,-2
LD250:  .word $000F, $FFBA          ;AON 0,0
LD254:  .word $1FC4, $E046          ;AON 14,-8
LD258:  .word $1FD3, $1FEC          ;AOFF 10,-14
LD25C:  .word (((VRFLS-VGBASE)/2)&$1FFF)+$A000 ;FUSE
LD25E:  .word (((VRGNT-VGBASE)/2)&$1FFF)+$A000
LD260:  .word $64FF
LD262:  .word $0069, $FFCE          ;AON 0,0
LD266:  .word $1F97, $FFF6          ;AON -2,-14
LD26A:  .word $4F16                 ;AOFF -6,-10
LD26C:  .word $004B, $E01E          ;AON 0,0
LD270:  .word $1FA6, $FFBA          ;AON -14,-12
LD274:  .word $0026, $1FF6          ;AOFF -16,-7
LD278:  .word (((VRFLS-VGBASE)/2)&$1FFF)+$A000 ;FUSE
LD27A:  .word (((VRGNT-VGBASE)/2)&$1FFF)+$A000
LD27C:  .word $64FF
LD27E:  .word $0034, $E050          ;AON 0,0
LD282:  .word $1FF1, $FFA6          ;AON -18,-2
LD286:  .word $002D, $0028          ;AOFF -10,4
LD28A:  .word $1FE2, $E032          ;AON 0,0
LD28E:  .word $005A, $FFC4          ;AON -12,12
LD292:  .word (((VRFLS-VGBASE)/2)&$1FFF)+$A000 ;FUSE
LD294:  .word (((VRGNT-VGBASE)/2)&$1FFF)+$A000
LD296:  .word $64FF
LD298:  .word $002D, $0032          ;AOFF -2,18
LD29C:  .word $1F79, $E00A          ;AON 0,0
LD2A0:  .word (((VRFLS-VGBASE)/2)&$1FFF)+$A000 ;FUSE
LD2A2:  .word (((VRGNT-VGBASE)/2)&$1FFF)+$A000
LD2A4:  .word $64FF
LD2A6:  .word $C000                 ;RTSL
LD2A8:  .word $64FF                 ;COLOR VGCRED,0FF
LD2AA:  .word $1F81, $E00F          ;AON 3,-17
LD2AE:  .word (((VRFLS-VGBASE)/2)&$1FFF)+$A000 ;FUSE
LD2B0:  .word (((VRGNT-VGBASE)/2)&$1FFF)+$A000
LD2B2:  .word $64FF
LD2B4:  .word $0034, $0019          ;AOFF 8,-10
LD2B8:  .word $004B, $FFD8          ;AON 0,0
LD2BC:  .word $1FB5, $E03C          ;AON 12,-10
LD2C0:  .word $0035, $0005          ;AOFF 13,-3
LD2C4:  .word $0016, $FFBF          ;AON 0,0
LD2C8:  .word $1FF1, $E055          ;AON 17,-2
LD2CC:  .word (((VRFLS-VGBASE)/2)&$1FFF)+$A000 ;FUSE
LD2CE:  .word (((VRGNT-VGBASE)/2)&$1FFF)+$A000
LD2D0:  .word $64FF
LD2D2:  .word $002D, $1FF1          ;AOFF 14,4
LD2D6:  .word $1FE2, $FFBA          ;AON 0,0
LD2DA:  .word $004B, $E046          ;AON 14,10
LD2DE:  .word $0016, $1FF1          ;AOFF 11,13
LD2E2:  .word (((VRFLS-VGBASE)/2)&$1FFF)+$A000 ;FUSE
LD2E4:  .word (((VRGNT-VGBASE)/2)&$1FFF)+$A000
LD2E6:  .word $64FF
LD2E8:  .word $1F9F, $FFC9          ;AON 0,0
LD2EC:  .word $0069, $FFF1          ;AON -3,14
LD2F0:  .word $4011                 ;AOFF -9,14
LD2F2:  .word (((VRFLS-VGBASE)/2)&$1FFF)+$A000 ;FUSE
LD2F4:  .word (((VRGNT-VGBASE)/2)&$1FFF)+$A000
LD2F6:  .word $64FF
LD2F8:  .word $1F97, $E02D          ;AON 0,0
LD2FC:  .word $004B, $FFBA          ;AON -14,10
LD300:  .word $1FDA, $1FF6          ;AOFF -16,5
LD304:  .word $1FDB, $E050          ;AON 0,0
LD308:  .word $0000, $FFAB          ;AON -17,0
LD30C:  .word (((VRFLS-VGBASE)/2)&$1FFF)+$A000 ;FUSE
LD30E:  .word (((VRGNT-VGBASE)/2)&$1FFF)+$A000
LD310:  .word $64FF
LD312:  .word $1FE2, $0023          ;AOFF -10,-4
LD316:  .word $001E, $E032          ;AON 0,0
LD31A:  .word $1FA6, $FFC4          ;AON -12,-12
LD31E:  .word $1FE2, $0028          ;AOFF -4,-16
LD322:  .word $0078, $E014          ;AON 0,0
LD326:  .word (((VRFLS-VGBASE)/2)&$1FFF)+$A000 ;FUSE
LD328:  .word (((VRGNT-VGBASE)/2)&$1FFF)+$A000
LD32A:  .word $64FF
LD32C:  .word $C000                 ;RTSL
LD32E:  .word $4FE0                 ;AON 0,2
LD330:  .word $0000, $003C          ;AOFF 6,2
LD334:  .word $1FE2, $FFC4          ;AON 0,0
LD338:  .word $1FE2, $E028          ;AON 4,-2
LD33C:  .word $1FE2, $1FD8          ;AOFF 0,-4
LD340:  .word $003C, $E000          ;AON 0,0
LD344:  .word $1FE2, $FFD8          ;AON -4,-2
LD348:  .word $005A, $0000          ;AOFF -4,4
LD34C:  .word $1FC4, $E028          ;AON 0,0
LD350:  .word $C000                 ;RTSL
LD352:  .word $40F6                 ;AON -2,0
LD354:  .word $005A, $0000          ;AOFF -2,6
LD358:  .word $1FA6, $E014          ;AON 0,0
LD35C:  .word $003C, $E014          ;AON 2,4
LD360:  .word $1FC4, $0014          ;AOFF 4,0
LD364:  .word $0000, $FFD8          ;AON 0,0
LD368:  .word $1FC4, $E014          ;AON 2,-4
LD36C:  .word $0000, $1FC4          ;AOFF -4,-4
LD370:  .word $003C, $E028          ;AON 0,0
LD374:  .word $C000                 ;RTSL
LD376:  .word $51E0                 ;AON 0,-2
LD378:  .word $0000, $1FC4          ;AOFF -6,-2
LD37C:  .word $001E, $E03C          ;AON 0,0
LD380:  .word $001E, $FFD8          ;AON -4,2
LD384:  .word $001E, $0028          ;AOFF 0,4
LD388:  .word $1FC4, $E000          ;AON 0,0
LD38C:  .word $001E, $E028          ;AON 4,2
LD390:  .word $1FA6, $0000          ;AOFF 4,-4
LD394:  .word $003C, $FFD8          ;AON 0,0
LD398:  .word $C000                 ;RTSL
LD39A:  .word $40EA                 ;AON 2,0
LD39C:  .word $1FA6, $0000          ;AOFF 2,-6
LD3A0:  .word $005A, $FFEC          ;AON 0,0
LD3A4:  .word $1FC4, $FFEC          ;AON -2,-4
LD3A8:  .word $003C, $1FEC          ;AOFF -4,0
LD3AC:  .word $0000, $E028          ;AON 0,0
LD3B0:  .word $003C, $FFEC          ;AON -2,4
LD3B4:  .word $0000, $003C          ;AOFF 4,4
LD3B8:  .word $1FC4, $FFD8          ;AON 0,0
LD3BC:  .word $C000                 ;RTSL

;.SBTTL DETH STAR LIGHTS ON THE DARK SIDE
LD3BE:  .word $441A                 ;MVCTR -6,4,OFF
LD3C0:  .word (((VGSTAR+2-VGBASE)/2)&$1FFF)+$A000 ;DOT
LD3C2:  .word $5622                 ;MVCTR 2,-10,ON
LD3C4:  .word (((VGSTAR+2-VGBASE)/2)&$1FFF)+$A000 ;DOT
LD3C6:  .word $422A                 ;MVCTR 10,2,ON
LD3C8:  .word (((VGSTAR+2-VGBASE)/2)&$1FFF)+$A000 ;DOT
LD3CA:  .word $4604                 ;MVCTR 4,6,OFF
LD3CC:  .word $C000                 ;RTSL
LD3CE:  .word $4604                 ;MVCTR 4,6,OFF
LD3D0:  .word (((VGSTAR+2-VGBASE)/2)&$1FFF)+$A000 ;DOT
LD3D2:  .word $5E36                 ;MVCTR -10,-2,ON
LD3D4:  .word (((B_L2-VGBASE)/2)&$1FFF)+$E000 ;JMPL B.L2
LD3D6:  .word $5C06                 ;MVCTR 6,-4,OFF
LD3D8:  .word $4A3E                 ;MVCTR -2,10,ON
LD3DA:  .word (((B_C2-VGBASE)/2)&$1FFF)+$E000 ;JMPL B.C2
LD3DC:  .word $4105                 ;MVCTR 5,1,OFF
LD3DE:  .word (((VGSTAR+2-VGBASE)/2)&$1FFF)+$A000 ;DOT
LD3E0:  .word $5F3B                 ;MVCTR -5,-1,ON
LD3E2:  .word (((VGSTAR+2-VGBASE)/2)&$1FFF)+$A000 ;DOT
LD3E4:  .word (((B_O-VGBASE)/2)&$1FFF)+$E000 ;JMPL B.O
LD3E6:  .word $5C06                 ;MVCTR 6,-4,OFF
LD3E8:  .word $453F                 ;MVCTR -1,5,ON
LD3EA:  .word (((VGSTAR+2-VGBASE)/2)&$1FFF)+$A000 ;DOT
LD3EC:  .word $5F3B                 ;MVCTR -5,-1,ON
LD3EE:  .word (((VGSTAR+2-VGBASE)/2)&$1FFF)+$A000 ;DOT
LD3F0:  .word (((B_C-VGBASE)/2)&$1FFF)+$E000 ;JMPL B.C
LD3F2:  .word $5C06                 ;MVCTR 6,-4,OFF
LD3F4:  .word $4A3E                 ;MVCTR -2,10,ON
LD3F6:  .word (((VGSTAR+2-VGBASE)/2)&$1FFF)+$A000 ;DOT
LD3F8:  .word $5E16                 ;MVCTR -10,-2,OFF
LD3FA:  .word (((B_L2-VGBASE)/2)&$1FFF)+$E000 ;JMPL B.L2
LD3FC:  .word (((VGSTAR+2-VGBASE)/2)&$1FFF)+$A000 ;DOT
LD3FE:  .word $5B01                 ;MVCTR 1,-5,OFF
LD400:  .word (((VGSTAR+2-VGBASE)/2)&$1FFF)+$A000 ;DOT
LD402:  .word $4A3E                 ;MVCTR -2,10,ON
LD404:  .word (((VGSTAR+2-VGBASE)/2)&$1FFF)+$A000 ;DOT
LD406:  .word $5F1B                 ;MVCTR -5,-1,OFF
LD408:  .word (((VGSTAR+2-VGBASE)/2)&$1FFF)+$A000 ;DOT
LD40A:  .word $422A                 ;MVCTR 10,2,ON
LD40C:  .word (((VGSTAR+2-VGBASE)/2)&$1FFF)+$A000 ;DOT
LD40E:  .word $5C06                 ;MVCTR 6,-4,OFF
LD410:  .word $C000                 ;RTSL
LD412:  .word (((VGSTAR+2-VGBASE)/2)&$1FFF)+$A000 ;DOT
LD414:  .word $5A1C                 ;MVCTR -4,-6,OFF
LD416:  .word (((VGSTAR+2-VGBASE)/2)&$1FFF)+$A000 ;DOT
LD418:  .word $422A                 ;MVCTR 10,2,ON
LD41A:  .word (((VGSTAR+2-VGBASE)/2)&$1FFF)+$A000 ;DOT
LD41C:  .word $5F1B                 ;MVCTR -5,-1,OFF
LD41E:  .word (((B_T2-VGBASE)/2)&$1FFF)+$E000 ;JMPL B.T2
LD420:  .word $5A1C                 ;MVCTR -4,-6,OFF
LD422:  .word (((VGSTAR+2-VGBASE)/2)&$1FFF)+$A000 ;DOT
LD424:  .word $4A3E                 ;MVCTR -2,10,ON
LD426:  .word (((VGSTAR+2-VGBASE)/2)&$1FFF)+$A000 ;DOT
LD428:  .word $422A                 ;MVCTR 10,2,ON
LD42A:  .word (((VGSTAR+2-VGBASE)/2)&$1FFF)+$A000 ;DOT
LD42C:  .word $5917                 ;MVCTR -9,-7,OFF
LD42E:  .word (((VGSTAR+2-VGBASE)/2)&$1FFF)+$A000 ;DOT
LD430:  .word $4125                 ;MVCTR 5,1,ON
LD432:  .word (((VGSTAR+2-VGBASE)/2)&$1FFF)+$A000 ;DOT
LD434:  .word $420A                 ;MVCTR 10,2,OFF
LD436:  .word $C000                 ;RTSL
LD438:  .word $5C06                 ;MVCTR 6,-4,OFF
LD43A:  .word (((VGSTAR+2-VGBASE)/2)&$1FFF)+$A000 ;DOT
LD43C:  .word $5E36                 ;MVCTR -10,-2,ON
LD43E:  .word (((B_F2-VGBASE)/2)&$1FFF)+$E000 ;JMPL B.F2
LD440:  .word $5F1B                 ;MVCTR -5,-1,OFF
LD442:  .word $4729                 ;MVCTR 9,7,ON
LD444:  .word (((VGSTAR+2-VGBASE)/2)&$1FFF)+$A000 ;DOT
LD446:  .word $5E16                 ;MVCTR -10,-2,OFF
LD448:  .word (((VGSTAR+2-VGBASE)/2)&$1FFF)+$A000 ;DOT
LD44A:  .word $5622                 ;MVCTR 2,-10,ON
LD44C:  .word (((VGSTAR+2-VGBASE)/2)&$1FFF)+$A000 ;DOT
LD44E:  .word $420A                 ;MVCTR 10,2,OFF
LD450:  .word (((VGSTAR+2-VGBASE)/2)&$1FFF)+$A000 ;DOT
LD452:  .word $4335                 ;MVCTR -11,3,ON
LD454:  .word (((VGSTAR+2-VGBASE)/2)&$1FFF)+$A000 ;DOT
LD456:  .word (((B_A2-VGBASE)/2)&$1FFF)+$E000 ;JMPL B.A2
LD458:  .word (((VGSTAR+2-VGBASE)/2)&$1FFF)+$A000 ;DOT
LD45A:  .word $5F1B                 ;MVCTR -5,-1,OFF
LD45C:  .word $422A                 ;MVCTR 10,2,ON
LD45E:  .word (((VGSTAR+2-VGBASE)/2)&$1FFF)+$A000 ;DOT
LD460:  .word $453F                 ;MVCTR -1,5,ON
LD462:  .word (((VGSTAR+2-VGBASE)/2)&$1FFF)+$A000 ;DOT
LD464:  .word $5E36                 ;MVCTR -10,-2,ON
LD466:  .word (((B_K2-VGBASE)/2)&$1FFF)+$E000 ;JMPL B.K2
LD468:  .word (((VGSTAR+2-VGBASE)/2)&$1FFF)+$A000 ;DOT
LD46A:  .word $5A1C                 ;MVCTR -4,-6,OFF
LD46C:  .word (((VGSTAR+2-VGBASE)/2)&$1FFF)+$A000 ;DOT
LD46E:  .word $453F                 ;MVCTR -1,5,ON
LD470:  .word (((VGSTAR+2-VGBASE)/2)&$1FFF)+$A000 ;DOT
LD472:  .word $4624                 ;MVCTR 4,6,ON
LD474:  .word (((VGSTAR+2-VGBASE)/2)&$1FFF)+$A000 ;DOT
LD476:  .word $5C26                 ;MVCTR 6,-4,ON
LD478:  .word (((VGSTAR+2-VGBASE)/2)&$1FFF)+$A000 ;DOT
LD47A:  .word $5B21                 ;MVCTR 1,-5,ON
LD47C:  .word (((VGSTAR+2-VGBASE)/2)&$1FFF)+$A000 ;DOT
LD47E:  .word $451F                 ;MVCTR -1,5,OFF
LD480:  .word $5E36                 ;MVCTR -10,-2,ON
LD482:  .word $430F                 ;MVCTR 15,3,OFF
LD484:  .word $C000                 ;RTSL
LD486:  .word $5A1C                 ;MVCTR -4,-6,OFF
LD488:  .word (((VGSTAR+2-VGBASE)/2)&$1FFF)+$A000 ;DOT
LD48A:  .word $4A3E                 ;MVCTR -2,10,ON
LD48C:  .word (((VGSTAR+2-VGBASE)/2)&$1FFF)+$A000 ;DOT
LD48E:  .word $4125                 ;MVCTR 5,1,ON
LD490:  .word (((VGSTAR+2-VGBASE)/2)&$1FFF)+$A000 ;DOT
LD492:  .word $5C26                 ;MVCTR 6,-4,ON
LD494:  .word (((VGSTAR+2-VGBASE)/2)&$1FFF)+$A000 ;DOT
LD496:  .word $5A3C                 ;MVCTR -4,-6,ON
LD498:  .word (((VGSTAR+2-VGBASE)/2)&$1FFF)+$A000 ;DOT
LD49A:  .word $5F3B                 ;MVCTR -5,-1,ON
LD49C:  .word $480E                 ;MVCTR 14,8,OFF
LD49E:  .word $C000                 ;RTSL
LD4A0:  .word $5A1C                 ;MVCTR -4,-6,OFF
LD4A2:  .word (((VGSTAR+2-VGBASE)/2)&$1FFF)+$A000 ;DOT
LD4A4:  .word $4A3E                 ;MVCTR -2,10,ON
LD4A6:  .word (((VGSTAR+2-VGBASE)/2)&$1FFF)+$A000 ;DOT
LD4A8:  .word $582C                 ;MVCTR 12,-8,ON
LD4AA:  .word (((B_W2-VGBASE)/2)&$1FFF)+$E000 ;JMPL B.W2
LD4AC:  .word (((VGSTAR+2-VGBASE)/2)&$1FFF)+$A000 ;DOT
LD4AE:  .word $5A1C                 ;MVCTR -4,-6,OFF
LD4B0:  .word (((VGSTAR+2-VGBASE)/2)&$1FFF)+$A000 ;DOT
LD4B2:  .word $4A3E                 ;MVCTR -2,10,ON
LD4B4:  .word (((VGSTAR+2-VGBASE)/2)&$1FFF)+$A000 ;DOT
LD4B6:  .word $5B01                 ;MVCTR 1,-5,OFF
LD4B8:  .word (((VGSTAR+2-VGBASE)/2)&$1FFF)+$A000 ;DOT
LD4BA:  .word $422A                 ;MVCTR 10,2,ON
LD4BC:  .word (((VGSTAR+2-VGBASE)/2)&$1FFF)+$A000 ;DOT
LD4BE:  .word $451F                 ;MVCTR -1,5,OFF
LD4C0:  .word (((B_M2-VGBASE)/2)&$1FFF)+$E000 ;JMPL B.M2
LD4C2:  .word $5A1C                 ;MVCTR -4,-6,OFF
LD4C4:  .word (((VGSTAR+2-VGBASE)/2)&$1FFF)+$A000 ;DOT
LD4C6:  .word $4A3E                 ;MVCTR -2,10,ON
LD4C8:  .word (((VGSTAR+2-VGBASE)/2)&$1FFF)+$A000 ;DOT
LD4CA:  .word $5C26                 ;MVCTR 6,-4,ON
LD4CC:  .word (((VGSTAR+2-VGBASE)/2)&$1FFF)+$A000 ;DOT
LD4CE:  .word $4624                 ;MVCTR 4,6,ON
LD4D0:  .word (((VGSTAR+2-VGBASE)/2)&$1FFF)+$A000 ;DOT
LD4D2:  .word $5622                 ;MVCTR 2,-10,ON
LD4D4:  .word (((B_L3-VGBASE)/2)&$1FFF)+$E000 ;JMPL B.L3
LD4D6:  .word (((VGSTAR+2-VGBASE)/2)&$1FFF)+$A000 ;DOT
LD4D8:  .word $5A1C                 ;MVCTR -4,-6,OFF
LD4DA:  .word (((VGSTAR+2-VGBASE)/2)&$1FFF)+$A000 ;DOT
LD4DC:  .word $422A                 ;MVCTR 10,2,ON
LD4DE:  .word (((VGSTAR+2-VGBASE)/2)&$1FFF)+$A000 ;DOT
LD4E0:  .word $453F                 ;MVCTR -1,5,ON
LD4E2:  .word (((VGSTAR+2-VGBASE)/2)&$1FFF)+$A000 ;DOT
LD4E4:  .word $5E36                 ;MVCTR -10,-2,ON
LD4E6:  .word (((VGSTAR+2-VGBASE)/2)&$1FFF)+$A000 ;DOT
LD4E8:  .word $453F                 ;MVCTR -1,5,ON
LD4EA:  .word (((VGSTAR+2-VGBASE)/2)&$1FFF)+$A000 ;DOT
LD4EC:  .word $422A                 ;MVCTR 10,2,ON
LD4EE:  .word (((B_Y2-VGBASE)/2)&$1FFF)+$E000 ;JMPL B.Y2
LD4F0:  .word $441A                 ;MVCTR -6,4,OFF
LD4F2:  .word (((VGSTAR+2-VGBASE)/2)&$1FFF)+$A000 ;DOT
LD4F4:  .word $5B21                 ;MVCTR 1,-5,ON
LD4F6:  .word (((VGSTAR+2-VGBASE)/2)&$1FFF)+$A000 ;DOT
LD4F8:  .word $5C26                 ;MVCTR 6,-4,ON
LD4FA:  .word (((VGSTAR+2-VGBASE)/2)&$1FFF)+$A000 ;DOT
LD4FC:  .word $4624                 ;MVCTR 4,6,ON
LD4FE:  .word (((VGSTAR+2-VGBASE)/2)&$1FFF)+$A000 ;DOT
LD500:  .word $453F                 ;MVCTR -1,5,ON
LD502:  .word (((B_Y2-VGBASE)/2)&$1FFF)+$E000 ;JMPL B.Y2
LD504:  .word $441A                 ;MVCTR -6,4,OFF
LD506:  .word (((VGSTAR+2-VGBASE)/2)&$1FFF)+$A000 ;DOT
LD508:  .word $5622                 ;MVCTR 2,-10,ON
LD50A:  .word (((VGSTAR+2-VGBASE)/2)&$1FFF)+$A000 ;DOT
LD50C:  .word $4624                 ;MVCTR 4,6,ON
LD50E:  .word (((VGSTAR+2-VGBASE)/2)&$1FFF)+$A000 ;DOT
LD510:  .word $5C26                 ;MVCTR 6,-4,ON
LD512:  .word (((VGSTAR+2-VGBASE)/2)&$1FFF)+$A000 ;DOT
LD514:  .word $4A3E                 ;MVCTR -2,10,ON
LD516:  .word (((B_Y2-VGBASE)/2)&$1FFF)+$E000 ;JMPL B.Y2
LD518:  .word $5B01                 ;MVCTR 1,-5,OFF
LD51A:  .word (((VGSTAR+2-VGBASE)/2)&$1FFF)+$A000 ;DOT
LD51C:  .word $453F                 ;MVCTR -1,5,ON
LD51E:  .word (((VGSTAR+2-VGBASE)/2)&$1FFF)+$A000 ;DOT
LD520:  .word $443A                 ;MVCTR -6,4,ON
LD522:  .word (((VGSTAR+2-VGBASE)/2)&$1FFF)+$A000 ;DOT
LD524:  .word $5C06                 ;MVCTR 6,-4,OFF
LD526:  .word $4624                 ;MVCTR 4,6,ON
LD528:  .word (((VGSTAR+2-VGBASE)/2)&$1FFF)+$A000 ;DOT
LD52A:  .word $5C06                 ;MVCTR 6,-4,OFF
LD52C:  .word $C000                 ;RTSL
;BASE CITY LIGHTS
LD52E:  .word $0096, $1F9C          ;AOFF -25,25
LD532:  .word (((B_M-VGBASE)/2)&$1FFF)+$A000 ;JSRL B.M
LD534:  .word (((B_A-VGBASE)/2)&$1FFF)+$A000 ;JSRL B.A
LD536:  .word (((B_Y-VGBASE)/2)&$1FFF)+$A000 ;JSRL B.Y
LD538:  .word $1FBE, $1FD8          ;AOFF -20,16
LD53C:  .word (((B_T-VGBASE)/2)&$1FFF)+$A000 ;JSRL B.T
LD53E:  .word (((B_H-VGBASE)/2)&$1FFF)+$A000 ;JSRL B.H
LD540:  .word (((B_E-VGBASE)/2)&$1FFF)+$A000 ;JSRL B.E
LD542:  .word $1FA6, $1FB0          ;AOFF -25,03
LD546:  .word (((B_F-VGBASE)/2)&$1FFF)+$A000 ;JSRL B.F
LD548:  .word (((B_O-VGBASE)/2)&$1FFF)+$A000 ;JSRL B.O
LD54A:  .word (((B_R-VGBASE)/2)&$1FFF)+$A000 ;JSRL B.R
LD54C:  .word (((B_C-VGBASE)/2)&$1FFF)+$A000 ;JSRL B.C
LD54E:  .word (((B_E-VGBASE)/2)&$1FFF)+$A000 ;JSRL B.E
LD550:  .word VGSCAL                ;SCAL
LD552:  .word VGCNTR                ;CNTR
LD554:  .word $C000                 ;RTSL
LD556:  .word $001E, $1F9C          ;AOFF -25,05
LD55A:  .word (((B_M-VGBASE)/2)&$1FFF)+$A000 ;JSRL B.M
LD55C:  .word (((B_A-VGBASE)/2)&$1FFF)+$A000 ;JSRL B.A
LD55E:  .word (((B_R-VGBASE)/2)&$1FFF)+$A000 ;JSRL B.R
LD560:  .word (((B_G-VGBASE)/2)&$1FFF)+$A000 ;JSRL B.G
LD562:  .word (((B_O-VGBASE)/2)&$1FFF)+$A000 ;JSRL B.O
LD564:  .word (((B_L-VGBASE)/2)&$1FFF)+$A000 ;JSRL B.L
LD566:  .word (((B_I-VGBASE)/2)&$1FFF)+$A000 ;JSRL B.I
LD568:  .word (((B_N-VGBASE)/2)&$1FFF)+$A000 ;JSRL B.N
LD56A:  .word VGSCAL                ;SCAL
LD56C:  .word VGCNTR                ;CNTR
LD56E:  .word $C000                 ;RTSL
LD570:  .word $005A, $1FB0          ;AOFF -20,15
LD574:  .word (((B_R-VGBASE)/2)&$1FFF)+$A000 ;JSRL B.R
LD576:  .word (((B_I-VGBASE)/2)&$1FFF)+$A000 ;JSRL B.I
LD578:  .word (((B_V-VGBASE)/2)&$1FFF)+$A000 ;JSRL B.V
LD57A:  .word (((B_E-VGBASE)/2)&$1FFF)+$A000 ;JSRL B.E
LD57C:  .word (((B_R-VGBASE)/2)&$1FFF)+$A000 ;JSRL B.R
LD57E:  .word (((B_A-VGBASE)/2)&$1FFF)+$A000 ;JSRL B.A
LD580:  .word VGSCAL                ;SCAL
LD582:  .word VGCNTR                ;CNTR
LD584:  .word $C000                 ;RTSL
LD586:  .word $0096, $1FC4          ;AOFF -15,25
LD58A:  .word (((B_H-VGBASE)/2)&$1FFF)+$A000 ;JSRL B.H
LD58C:  .word (((B_A-VGBASE)/2)&$1FFF)+$A000 ;JSRL B.A
LD58E:  .word (((B_L-VGBASE)/2)&$1FFF)+$A000 ;JSRL B.L
LD590:  .word (((B_L-VGBASE)/2)&$1FFF)+$A000 ;JSRL B.L
LD592:  .word (((B_Y-VGBASE)/2)&$1FFF)+$A000 ;JSRL B.Y
LD594:  .word VGSCAL                ;SCAL
LD596:  .word VGCNTR                ;CNTR
LD598:  .word $C000                 ;RTSL
LD59A:  .word $1FA0, $1FB0          ;AOFF -20,-16
LD59E:  .word (((B_B-VGBASE)/2)&$1FFF)+$A000 ;JSRL B.B
LD5A0:  .word (((B_E-VGBASE)/2)&$1FFF)+$A000 ;JSRL B.E
LD5A2:  .word $1FDA, $0014          ;AOFF -05,-21
LD5A6:  .word (((B_W-VGBASE)/2)&$1FFF)+$A000 ;JSRL B.W
LD5A8:  .word (((B_I-VGBASE)/2)&$1FFF)+$A000 ;JSRL B.I
LD5AA:  .word (((B_T-VGBASE)/2)&$1FFF)+$A000 ;JSRL B.T
LD5AC:  .word (((B_H-VGBASE)/2)&$1FFF)+$A000 ;JSRL B.H
LD5AE:  .word $1FAE, $1F9C          ;AOFF -10,-32
LD5B2:  .word (((B_Y-VGBASE)/2)&$1FFF)+$A000 ;JSRL B.Y
LD5B4:  .word (((B_O-VGBASE)/2)&$1FFF)+$A000 ;JSRL B.O
LD5B6:  .word (((B_U-VGBASE)/2)&$1FFF)+$A000 ;JSRL B.U
LD5B8:  .word VGSCAL                ;SCAL
LD5BA:  .word VGCNTR                ;CNTR
LD5BC:  .word $C000                 ;RTSL
LD5BE:  .word $1F88, $1FB0          ;AOFF -20,-20
LD5C2:  .word (((B_A-VGBASE)/2)&$1FFF)+$A000 ;JSRL B.A
LD5C4:  .word (((B_V-VGBASE)/2)&$1FFF)+$A000 ;JSRL B.V
LD5C6:  .word (((B_E-VGBASE)/2)&$1FFF)+$A000 ;JSRL B.E
LD5C8:  .word (((B_L-VGBASE)/2)&$1FFF)+$A000 ;JSRL B.L
LD5CA:  .word (((B_L-VGBASE)/2)&$1FFF)+$A000 ;JSRL B.L
LD5CC:  .word (((B_A-VGBASE)/2)&$1FFF)+$A000 ;JSRL B.A
LD5CE:  .word (((B_R-VGBASE)/2)&$1FFF)+$A000 ;JSRL B.R
LD5D0:  .word VGSCAL                ;SCAL
LD5D2:  .word VGCNTR                ;CNTR
LD5D4:  .word $C000                 ;RTSL
LD5D6:  .word $1F5E, $1FC4          ;AOFF -15,-27
LD5DA:  .word (((B_V-VGBASE)/2)&$1FFF)+$A000 ;JSRL B.V
LD5DC:  .word (((B_I-VGBASE)/2)&$1FFF)+$A000 ;JSRL B.I
LD5DE:  .word (((B_C-VGBASE)/2)&$1FFF)+$A000 ;JSRL B.C
LD5E0:  .word (((B_K-VGBASE)/2)&$1FFF)+$A000 ;JSRL B.K
LD5E2:  .word (((B_E-VGBASE)/2)&$1FFF)+$A000 ;JSRL B.E
LD5E4:  .word (((B_R-VGBASE)/2)&$1FFF)+$A000 ;JSRL B.R
LD5E6:  .word (((B_S-VGBASE)/2)&$1FFF)+$A000 ;JSRL B.S
LD5E8:  .word VGSCAL                ;SCAL
LD5EA:  .word VGCNTR                ;CNTR
LD5EC:  .word $C000                 ;RTSL
LD5EE:  .word $1F2E, $1FD8          ;AOFF -10,-35
LD5F2:  .word (((B_D-VGBASE)/2)&$1FFF)+$A000 ;JSRL B.D
LD5F4:  .word (((B_U-VGBASE)/2)&$1FFF)+$A000 ;JSRL B.U
LD5F6:  .word (((B_R-VGBASE)/2)&$1FFF)+$A000 ;JSRL B.R
LD5F8:  .word (((B_F-VGBASE)/2)&$1FFF)+$A000 ;JSRL B.F
LD5FA:  .word (((B_E-VGBASE)/2)&$1FFF)+$A000 ;JSRL B.E
LD5FC:  .word (((B_Y-VGBASE)/2)&$1FFF)+$A000 ;JSRL B.Y
LD5FE:  .word VGSCAL                ;SCAL
LD600:  .word VGCNTR                ;CNTR
LD602:  .word $C000                 ;RTSL

;.SBTTL VG TABLES

ZFAKEVG:
VTFLS:           ;FLASH COLOR TABLE
;USES MAX BRIGHTNESS
LD604:  .word $61FF                 ;COLOR 1,0FF
LD606:  .word $62FF                 ;COLOR 2,0FF
LD608:  .word $63FF                 ;COLOR 3,0FF
LD60A:  .word $64FF                 ;COLOR 4,0FF
LD60C:  .word $65FF                 ;COLOR 5,0FF
LD60E:  .word $66FF                 ;COLOR 6,0FF
LD610:  .word $67FF                 ;COLOR 7,0FF

VTFLSZ:
VTMFL:           ;MEDIUM ( MESSAGE ) FLASH COLOR TABLE
;USES DEFAULT BRIGHTNESS
LD612:  .word $6180                 ;COLOR 1
LD614:  .word $6280                 ;COLOR 2
LD616:  .word $6380                 ;COLOR 3
LD618:  .word $6480                 ;COLOR 4
LD61A:  .word $6580                 ;COLOR 5
LD61C:  .word $6680                 ;COLOR 6
LD61E:  .word $6780                 ;COLOR 7

VTMFLZ:
VTLZF:           ;TABLE OF LAZAR FIRE JMPL'S
LD620:  .word ((LZF0-VGBASE)/2)+$E000 ;.IRP .A,<0,1,2,3,4,5,6,7,8,9,A,B,C,D,E,F>
LD622:  .word ((LZF1-VGBASE)/2)+$E000
LD624:  .word ((LZF2-VGBASE)/2)+$E000
LD626:  .word ((LZF3-VGBASE)/2)+$E000
LD628:  .word ((LZF4-VGBASE)/2)+$E000
LD62A:  .word ((LZF5-VGBASE)/2)+$E000
LD62C:  .word ((LZF6-VGBASE)/2)+$E000
LD62E:  .word ((LZF7-VGBASE)/2)+$E000
LD630:  .word ((LZF8-VGBASE)/2)+$E000
LD632:  .word ((LZF9-VGBASE)/2)+$E000
LD634:  .word ((LZFA-VGBASE)/2)+$E000
LD636:  .word ((LZFB-VGBASE)/2)+$E000
LD638:  .word ((LZFC-VGBASE)/2)+$E000
LD63A:  .word ((LZFD-VGBASE)/2)+$E000
LD63C:  .word ((LZFE-VGBASE)/2)+$E000
LD63E:  .word ((LZFF-VGBASE)/2)+$E000

VTLZFZ:
VTLZS:           ;TABLE FOR LAZAR SPLASHES
LD640:  .word ((LZS0-VGBASE)/2)+$E000 ;.IRP .A,<0,1,2,3>
LD642:  .word ((LZS1-VGBASE)/2)+$E000
LD644:  .word ((LZS2-VGBASE)/2)+$E000
LD646:  .word ((LZS3-VGBASE)/2)+$E000

VTLZSZ:
VTGNB:           ;ALIEN GUN SHOT, BASE
LD648:  .word ((GNB0-VGBASE)/2)+$E000 ;.IRP .A,<0,1,2,3>
LD64A:  .word ((GNB1-VGBASE)/2)+$E000
LD64C:  .word ((GNB2-VGBASE)/2)+$E000
LD64E:  .word ((GNB3-VGBASE)/2)+$E000

VTGNBZ:
VTGNX:           ;ALIEN GUN SHOT EXPLODING, BASE
LD650:  .word ((GNX0-VGBASE)/2)+$E000 ;.IRP .A,<0,1,2,3>
LD652:  .word ((GNX1-VGBASE)/2)+$E000
LD654:  .word ((GNX2-VGBASE)/2)+$E000
LD656:  .word ((GNX3-VGBASE)/2)+$E000

VTGNXZ:
VTGNT:           ;ALIEN GUN SHOT, TIP
LD658:  .word ((GNT0-VGBASE)/2)+$E000 ;.IRP .A,<0,1,2,3>
LD65A:  .word ((GNT1-VGBASE)/2)+$E000
LD65C:  .word ((GNT2-VGBASE)/2)+$E000
LD65E:  .word ((GNT3-VGBASE)/2)+$E000

;==============================================================================
; MODULE TCSPLS   TCSPLS.MAC
;   SPLASH ROUTINES FOR LASER SHOTS
;==============================================================================

;------------------------------------------------------------------------------
; SPLASH - SPLASH
;   (also: VTGNTZ)
;------------------------------------------------------------------------------
SPLASH:
VTGNTZ:
LD660:  JSR  URQUAD
LD663:  JSR  URQ2
LD666:  LDD  #VGRTSL
LD669:  STD  ,U++
LD66B:  JSR  ULQUAD
LD66E:  JSR  ULQ2
LD671:  LDD  #VGRTSL
LD674:  STD  ,U++
LD676:  JSR  DLQUAD
LD679:  JSR  DLQ2
LD67C:  LDD  #VGRTSL
LD67F:  STD  ,U++
LD681:  JSR  DRQUAD
LD684:  JSR  DRQ2
LD687:  LDD  #VGRTSL
LD68A:  STD  ,U++
LD68C:  RTS

;------------------------------------------------------------------------------
; URQUAD - UP-RIGHT QUADRANT ( +Y AND +X )
;------------------------------------------------------------------------------
URQUAD:
LD68D:  LDU  #VRSPUR

;------------------------------------------------------------------------------
; URQ2 - [note] Up-right quadrant, entry with U already set: copy 3 vector words from the RNDVEC list to (U)+ as is
;------------------------------------------------------------------------------
URQ2:
LD690:  JSR  RNDVEC                 ;RETURNS WITH X POINTING TO A LIST OF VECTORS
LD693:  LDD  ,X++
LD695:  STD  ,U++
LD697:  LDD  ,X++
LD699:  STD  ,U++
LD69B:  LDD  ,X
LD69D:  STD  ,U++
LD69F:  RTS

;------------------------------------------------------------------------------
; ULQUAD - UP-LEFT QUADRANT ( +Y AND -X )
;------------------------------------------------------------------------------
ULQUAD:
LD6A0:  LDU  #VRSPUL

;------------------------------------------------------------------------------
; ULQ2 - [note] Up-left quadrant, entry with U already set: copy 3 vector words from the RNDVEC list to (U)+ with X
;   negated; Z off on the first and third, Z = 7 on the second
;------------------------------------------------------------------------------
ULQ2:
LD6A3:  JSR  RNDVEC                 ;RETURNS WITH X POINTING TO A LIST OF VECTORS
LD6A6:  LDD  ,X++
LD6A8:  NEGB                        ;NEGATIVE X
LD6A9:  ANDB #$1F                   ;Z OFF
LD6AB:  STD  ,U++
LD6AD:  LDD  ,X++
LD6AF:  NEGB                        ;NEGATIVE X ( THERE ARE NO 0 X'S )
LD6B0:  ORB  #$E0                   ;AND SET Z TO 7
LD6B2:  STD  ,U++
LD6B4:  LDD  ,X
LD6B6:  NEGB                        ;NEGATIVE X
LD6B7:  ANDB #$1F                   ;Z OFF
LD6B9:  STD  ,U++
LD6BB:  RTS

;------------------------------------------------------------------------------
; DLQUAD - DOWN-LEFT QUADRANT ( -Y AND -X )
;------------------------------------------------------------------------------
DLQUAD:
LD6BC:  LDU  #VRSPDL

;------------------------------------------------------------------------------
; DLQ2 - [note] Down-left quadrant, entry with U already set: copy 3 vector words from the RNDVEC list to (U)+ with Y
;   and X negated (remade as SVCTR instructions); Z off on the first and third, Z = 7 on the second
;------------------------------------------------------------------------------
DLQ2:
LD6BF:  JSR  RNDVEC                 ;RETURNS WITH X POINTING TO A LIST OF VECTORS
LD6C2:  LDD  ,X++
LD6C4:  NEGA                        ;NEGATIVE Y
LD6C5:  ANDA #$1F                   ;LIMIT IT
LD6C7:  ORA  #$40                   ;MAKE IT A SVCTR INSTRUCTION AGAIN
LD6C9:  NEGB                        ;NEGATIVE X
LD6CA:  ANDB #$1F                   ;Z OFF
LD6CC:  STD  ,U++
LD6CE:  LDD  ,X++
LD6D0:  NEGA
LD6D1:  ANDA #$1F
LD6D3:  ORA  #$40
LD6D5:  NEGB                        ;NEGATIVE X
LD6D6:  ORB  #$E0                   ;Z=7
LD6D8:  STD  ,U++
LD6DA:  LDD  ,X
LD6DC:  NEGA
LD6DD:  ANDA #$1F
LD6DF:  ORA  #$40
LD6E1:  NEGB
LD6E2:  ANDB #$1F
LD6E4:  STD  ,U++
LD6E6:  RTS

;------------------------------------------------------------------------------
; DRQUAD - DOWN-RIGHT QUAD ( -Y AND +X )
;------------------------------------------------------------------------------
DRQUAD:
LD6E7:  LDU  #VRSPDR

;------------------------------------------------------------------------------
; DRQ2 - [note] Down-right quadrant, entry with U already set: copy 3 vector words from the RNDVEC list to (U)+ with Y
;   negated (remade as SVCTR instructions)
;------------------------------------------------------------------------------
DRQ2:
LD6EA:  JSR  RNDVEC                 ;RETURNS WITH X POINTING TO A LIST OF VECTORS
LD6ED:  LDD  ,X++
LD6EF:  NEGA
LD6F0:  ANDA #$1F
LD6F2:  ORA  #$40
LD6F4:  STD  ,U++
LD6F6:  LDD  ,X++
LD6F8:  NEGA
LD6F9:  ANDA #$1F
LD6FB:  ORA  #$40
LD6FD:  STD  ,U++
LD6FF:  LDD  ,X
LD701:  NEGA
LD702:  ANDA #$1F
LD704:  ORA  #$40
LD706:  STD  ,U++
LD708:  RTS

;------------------------------------------------------------------------------
; RNDVEC - RETURNS WITH X POINTING TO A LIST OF VECTORS  (comment at the calls)
;------------------------------------------------------------------------------
RNDVEC:
LD709:  LDA  P_RND                  ;RANDOM NUMBER
LD70C:  ANDA #$0F                   ;0 TO 15.
LD70E:  LDB  #$06                   ;6 BYTE ENTRIES IN TABLE
LD710:  MUL
LD711:  LDX  #TSPLSH                ;TABLE OF SPLASH VECTORS
LD714:  ABX
LD715:  RTS

;.SBTTL SPLASH VECTORS

TSPLSH:          ;TABLE OF SPLASH VECTORS
LD716:  .byte $42, $00, $4D, $E1, $51, $1F ;.SPLSH 00.,04.,02.,30.
LD71C:  .byte $46, $01, $46, $E1, $54, $1E ;.SPLSH 02.,12.,04.,24.
LD722:  .byte $49, $02, $43, $E1, $54, $1D ;.SPLSH 04.,18.,06.,24.
LD728:  .byte $43, $01, $4C, $E3, $51, $1C ;.SPLSH 02.,06.,08.,30.
LD72E:  .byte $42, $01, $48, $E4, $56, $1B ;.SPLSH 02.,04.,10.,20.
LD734:  .byte $43, $02, $48, $E6, $55, $18 ;.SPLSH 04.,06.,16.,22.
LD73A:  .byte $45, $04, $43, $E2, $58, $1A ;.SPLSH 08.,10.,12.,16.
LD740:  .byte $46, $05, $45, $E4, $55, $17 ;.SPLSH 10.,12.,18.,22.
LD746:  .byte $42, $02, $46, $E6, $58, $18 ;.SPLSH 04.,04.,16.,16.
LD74C:  .byte $44, $05, $44, $E5, $58, $16 ;.SPLSH 10.,08.,20.,16.
LD752:  .byte $42, $03, $48, $EC, $56, $11 ;.SPLSH 06.,04.,30.,20.
LD758:  .byte $41, $02, $45, $EA, $5A, $14 ;.SPLSH 04.,02.,24.,12.
LD75E:  .byte $41, $03, $42, $E6, $5D, $17 ;.SPLSH 06.,02.,18.,06.
LD764:  .byte $42, $08, $41, $E4, $5D, $14 ;.SPLSH 16.,04.,24.,06.
LD76A:  .byte $41, $06, $41, $E6, $5E, $14 ;.SPLSH 12.,02.,24.,04.
LD770:  .byte $40, $02, $41, $ED, $5F, $11 ;.SPLSH 04.,00.,30.,02.

;==============================================================================
; MODULE WSCOIN   WSCOIN.MAC
;   COIN HANDLING
;==============================================================================

;------------------------------------------------------------------------------
; COINS - ACTIVITY CHECK
;   ONLY CALL MOOLAH IF IT IS NEEDED.
;   CHECK COIN RELATED SWITCHES OR E.M. COUNTERS FOR ACTIVITY,
;   WHEN ACTIVE SET A COUNTER TO CALL MOOLAH.
;   TIMER SHOULD BE SET TO A VALUE LARGE ENOUGH TO
;   ALLOW ELECTRO-MECHANICAL COUNTERS TO CYCLE.
;------------------------------------------------------------------------------
COINS:
LD776:  LDA  S_COINA                ;CHECK SWITCHES
LD779:  ANDA #$0F                   ;RIGHT,LEFT,AUX COIN AND SLAM SWITCHES
LD77B:  CMPA #$0F
LD77D:  BEQ  LD783                  ;IFNE  SWITCH ACTIVITY
LD77F:  LDA  #$FF                   ;GIVE 'EM A COUPLE OF SECONDS
LD781:  STA  MOOTIM                 ;DECREMENTED EVERY 16 MS IN IRQ
LD783:  LDA  MOOTIM                 ;SHALL I CALL MOOLAH
LD785:  BNE  LD788                  ;IFEQ  TIMER RAN OUT, DON'T DO MOOLAH
LD787:  RTS                         ;RETURN FROM WHENCE YOU CAME
;ELSE
LD788:  DEC  MOOTIM                 ;DEC TIMER
LD78A:  LDA  #MAXCRD                ;VERIFY PROPER CREDIT RANGE
LD78C:  CMPA S_S_CRDT
LD78E:  BHS  LD792                  ;IFLO  TOO MANY CREDITS
LD790:  STA  S_S_CRDT
LD792:  LDA  S_CCTIM+2              ;CHECK ELECTRO-MECHANICAL COUNTER TIMERS
LD794:  STA  EMCNT0                 ;ACTIVATE EM-COUNTERS ( RIGHT )
LD797:  LDB  S_CCTIM+1
LD799:  STB  EMCNT1                 ;( LEFT )
LD79C:  ORA  S_CCTIM+1
LD79E:  ORA  S_CCTIM                ;AUX DOESN'T HIT EM-COUNTER
LD7A0:  BEQ  LD7A6                  ;IFNE  MECH ACTIVITY
LD7A2:  LDA  #$FF
LD7A4:  STA  MOOTIM
LD7A6:  LDA  TESTSW                 ;SELF TEST SWITCH?
LD7A9:  ANDA #TESTBT
LD7AB:  BNE  LD7B0                  ;IFEQ  YES, IT IS ON
LD7AD:  JMP  S_EXT                  ;NO COINS, BUT CONTINUE EM COUNTER TIMING
LD7B0:  LDA  OPTS0                  ;SETUP $CMODE FROM EEROM OPTIONS
LD7B3:  ASLA                        ;HIGH NIBBLE
LD7B4:  ASLA
LD7B5:  ASLA
LD7B6:  ASLA
LD7B7:  STA  S_CMODE
LD7B9:  LDA  OPTS0+1                ;LO NIBBLE
LD7BC:  ANDA #$0F
LD7BE:  ORA  S_CMODE
LD7C0:  STA  S_CMODE
LD7C2:  LDA  S_INTCT
LD7C4:  ANDA #$03
LD7C6:  BNE  MOOLAH                 ;IFEQ  16 MS
LD7C8:  JSR  EEACCU                 ;UPDATE COIN ACCOUNTING INFO IN EEROM

;.SBTTL DETECT COIN

MOOLAH:
LD7CB:  LDX  #$480E                 ;(src: LDX #$BASE+OFFSET+OFFSET)  X IS USED TO INDEX FROM RIGHT TO LEFT COIN MECH

S_DETCT:
LD7CE:  LDA  S_COINA                ;GET COIN SWITCHES
LD7D1:  CMPX #$480D                 ;(src: CMPX #$BASE+OFFSET)  WHICH MECH ARE WE DOING
LD7D4:  BEQ  S_DETCT_11             ;MIDDLE ($BASE+OFFSET) SHIFT TWICE
LD7D6:  BHS  S_DETCT_12             ;RIGHT ($BASE+2*OFFSET) SHIFT ONCE
LD7D8:  LSRA                        ;ELSE RIGHT, SHIFT THRICE

S_DETCT_11:
LD7D9:  LSRA

S_DETCT_12:
LD7DA:  LSRA
LD7DB:  LDA  ,X                     ;(src: LDA $CNSTT-$BASE(X))
LD7DD:  ANDA #$1F                   ;SHARED INST. SEE BELOW IN BRACKETS []
LD7DF:  BCS  S_DETCT_50             ;BRANCH IF INPUT HIGH (COIN ABSENT)
;[ANDA #31.] ;ISOLATE COIN-ON DOWN-COUNTER, RESET COIN-OFF UP-CTR.
LD7E1:  BEQ  S_DETCT_1              ;STICK AT 0 (TERMINAL COUNT)
LD7E3:  CMPA #$1B                   ;IN FIRST FIVE SAMPLES?
LD7E5:  BHS  S_DETCT_10             ;YES, RUN FAST
LD7E7:  LDB  S_INTCT                ;CHECK INTERUPT CTR
LD7E9:  ANDB #$01                   ;COUNTDOWN SLOWLY
LD7EB:  BNE  S_DETCT_1              ;SKIP IF NOT 0 (MOD 2) INTERRUPT

S_DETCT_10:
LD7ED:  SUBA #$01                   ;COUNTDOWN EVERY 8 MILS

S_DETCT_1:
LD7EF:  STA  ,X                     ;(src: STA $CNSTT-$BASE(X))  SAVE UPDATED STATUS
LD7F1:  LDA  S_LAM                  ;CHECK SLAM SWITCH
LD7F4:  ANDA #S_LMBIT
LD7F6:  BNE  S_DETCT_20             ;BRANCH IF BIT HI (SWITCH OFF)
LD7F8:  LDA  #PRST*8                ;ELSE SET PRE-COIN SLAM TIMER
LD7FA:  STA  S_LMTIM                ;DECR. 8 TIMES/FRAME=PRST FRAMES

S_DETCT_20:
LD7FC:  LDA  S_LMTIM                ;CHECK PRE-COIN SLAM TIMER
LD7FE:  BEQ  S_DETCT_30             ;O.K.
LD800:  DEC  S_LMTIM                ;ELSE RUN TIMER
LD802:  LDA  #$00
LD804:  STA  ,X                     ;(src: STA $CNSTT-$BASE(X))  CLEAR COIN STATUS
LD806:  STA  3,X                    ;(src: STA $PSTSL-$BASE(X))  CLEAR POST-COIN SLAM-TIMER

S_DETCT_30:
LD808:  LDA  3,X                    ;(src: LDA $PSTSL-$BASE(X))  CHECK POST-COIN SLAM-TIMER
LD80A:  BEQ  S_DETNXT               ;EMPTY, PROCEED WITH NEXT MECH
LD80C:  DEC  3,X                    ;(src: DEC $PSTSL-$BASE(X))  RUN TIMER
LD80E:  BEQ  S_MULT                 ;WHEN IT BECOMES ZERO INDICATE A COIN
LD810:  BRA  S_DETNXT               ;ELSE NOT DONE, PROCEED WITH NEXT MECH

S_DETCT_50:
;COIN SW IS OFF
;[ANDA #31.] ;GET COIN-ON DOWN-CTR (ACTUALLY DONE BEFORE)
LD812:  CMPA #$1B                   ;IS COIN VALID YET (ON FOR >4 SAMPLES)
LD814:  BHS  S_DETCT_60             ;NO, RESET IT
LD816:  LDA  ,X                     ;(src: LDA $CNSTT-$BASE(X))  GET STATUS AGAIN
LD818:  ADDA #$20                   ;BUMP COIN-OFF UP-CTR.
LD81A:  BCC  S_DETCT_1              ;IF IT DIDN'T WRAP, JUST STORE STATUS
LD81C:  BNE  S_DETCT_70             ;IT WRAPPED BUT COIN WAS ON TOO LONG, JUST RESET

S_DETCT_60:
;COIN TOO LONG OR TOO SHORT
LD81E:  LDA  #$1F                   ;RESET DOWN-COUNTER
LD820:  BRA  S_DETCT_1              ;AND PROCESS TIMERS

S_DETCT_70:
;COIN SW OK, WAIT FOR POST SLAM
LD822:  LDA  #$1F                   ;SETUP DOWN-COUNTER FOR NEXT COIN
LD824:  STA  ,X                     ;(src: STA $CNSTT-$BASE(X))  SAVE RESET STATUS
LD826:  LDB  3,X                    ;(src: LDB $PSTSL-$BASE(X))  CHECK IF PREVIOUS COIN STILL WAITING
LD828:  LDA  #POST*4                ;/(4 COUNTS/FRAME)="POST" FRAMES
LD82A:  STA  3,X                    ;(src: STA $PSTSL-$BASE(X))  DELAY ACCEPTANCE FOR POST/60 SEC.
LD82C:  TSTB                        ;?ONLY ONE COIN WAITING?
LD82D:  BEQ  S_DETNXT               ;THEN WAIT FOR POST SLAM

;.SBTTL MECH-MULTIPLIERS

S_MULT:
LD82F:  CLRA                        ;START WITH 0 (TO ADD 1)
LD830:  CMPX #$480D                 ;(src: CMPX #$BASE+OFFSET)  CHECK WHICH MECH
LD833:  BLO  S_MUL85                ;IF LEFT, ALWAYS ADD 1
LD835:  BEQ  S_MUL83                ;IF CENTER, CHECK HALF-MUL
LD837:  LDA  S_CMODE                ;GDM  ELSE GET DOLLAR MUL
LD839:  ANDA #$0C
LD83B:  LSRA
LD83C:  LSRA
LD83D:  BEQ  S_MUL85                ;00-ADD 1
LD83F:  ADDA #$02                   ;ELSE MAP 1,2,3 TO 3,4,5
LD841:  BRA  S_MUL85                ;(ALWAYS)

S_MODLO:         ;TWICE THE UNIT-COINS REQUIRED TO RECEIVE BONUS
;NOTE: BRANCH AROUND THIS TABLE
LD843:  .byte $FF, $04, $08, $08, $0A, $FF, $FF, $FF ;-,2,4,4,5,-,-,-UNIT COINS

;------------------------------------------------------------------------------
; S_MUL83 - [note] Center mech: check half-mul - A = 1 if S_CMODE bit $10 is set, else 0; falls into S_MUL85, which
;   adds A+1 unit coins to S_BCCNT and S_CNCT
;------------------------------------------------------------------------------
S_MUL83:
LD84B:  LDA  S_CMODE                ;GHM
LD84D:  ANDA #$10
LD84F:  BEQ  S_MUL85
LD851:  LDA  #$01

S_MUL85:
LD853:  INCA                        ;ADD MIN OF ONE COIN
LD854:  TFR  A,B                    ;SAVE NEW COINS INCREMENT
LD856:  ADDB S_BCCNT                ;UPDATE BONUS-ADDER COUNTER
LD858:  STB  S_BCCNT
LD85A:  ADDA S_CNCT
LD85C:  STA  S_CNCT
LD85E:  INC  9,X                    ;(src: INC $CCTIM-$BASE(X))  "QUEUE" PULSE FOR E.M. COUNTER

S_DETNXT:
LD860:  LEAX -OFFSET,X
LD862:  CMPX #$480C                 ;(src: CMPX #$BASE)
LD865:  LBGE S_DETCT

;.SBTTL BONUS-ADDER

S_BONUS:
LD869:  LDA  S_CMODE                ;GBAM  GET BONUS ADDER MODE
LD86B:  LSRA
LD86C:  LSRA
LD86D:  LSRA
LD86E:  LSRA
LD86F:  LSRA
LD870:  LDB  S_BCCNT
LD872:  LSLB                        ;B:= ORIGINAL UNIT COINS*2
LD873:  LDX  #S_MODLO
LD876:  SUBB A,X                    ;SEE IF ENOUGH UNIT-COINS HAVE ACCUMULATED
LD878:  BLO  S_EXTB                 ;BRANCH IF NOT
LD87A:  LSL  S_BCCNT                ;PULL IN HALF-CREDIT MARKER
LD87C:  RORB
LD87D:  CMPA #$03                   ;MODE 3 YIELDS 2 BONUS COINS FOR 4 INSERTED
LD87F:  BEQ  S_BONUS_20             ;NOTE: MODE 3 ==> NO ODD BONUS COINS
LD881:  ADDB #$80                   ;OTHER MODES: ADD ODD BONUS
LD883:  BCC  S_BONUS_40             ;? 2 ODDS MAKE A PAIR OF BONUS COINS?

S_BONUS_20:
LD885:  INC  S_CNCT                 ;ADD TWO BONUS COINS
LD887:  INC  S_CNCT

S_BONUS_40:
LD889:  STB  S_BCCNT                ;UPDATE BOTH ODD BONUS COIN

;.SBTTL COINS TO CREDITS

S_EXTB:
S_CNVRT:
LD88B:  LDA  S_CMODE                ;GCM  GET COIN MODE IN ACC 0,1
LD88D:  ANDA #$03
LD88F:  BEQ  S_CNVRT_50             ;IF FREE PLAY, KEEP COIN COUNT CLEAR, LEAVE CREDIT
LD891:  TFR  A,B                    ;SAVE $CMODE
LD893:  NEGA                        ;CONVERT MODE 0,1,2,3 TO -,-1,-1,-2 UNIT COIN PRICING
LD894:  ASRA
LD895:  ADDA S_CNCT                 ;A:=$CNCT-PRICE
LD897:  BPL  S_CNVRT_40             ;?NOT ENOUGH UNIT COINS?
LD899:  TST  S_BCCNT                ;TEST FOR EXTRA ODD BONUS COIN
LD89B:  BPL  S_EXT                  ;?EXTRA ODD BONUS COIN PRESENT?
LD89D:  INCA                        ;INCLUDE IT IN
LD89E:  BMI  S_EXT                  ;?ENOUGH COINS NOW?
LD8A0:  LSL  S_BCCNT                ;GREAT--CLEAR ODD COIN FLAG
LD8A2:  LSR  S_BCCNT

S_CNVRT_40:
LD8A4:  CMPB #$01                   ;ENUF COINS ==> INCREASE CREDITS
LD8A6:  BNE  S_CNVRT_45             ;?MODE 1?
LD8A8:  INC  S_S_CRDT               ;THEN ADD SECOND CREDIT

S_CNVRT_45:
LD8AA:  INC  S_S_CRDT               ;ALWAYS ADD FIRST CREDIT

S_CNVRT_50:
LD8AC:  STA  S_CNCT                 ;SAVE NEW REDUCED COIN COUNT

;.SBTTL ELECTRO-MECH. CTRS

S_EXT:
;SINCE COUNTERS MAY BE WIRE-ORED TOGETHER, ONE FULL
;ON/OFF CYCLE MUST OCCURR FOR EACH POTENTIAL COUNT.
;NO OVERLAPPING ALLOWED!
;ALSO NOTE: WITH MAX OF 1 COUNTER ON,POWER NEEDS ARE LESS
LD8AE:  LDB  S_INTCT                ;SPEC 171005 DRAFT 3, 2/23/82
LD8B0:  ANDB #$0F                   ;MIN ON TIME = 50 MSECS, MIN OFF = 50 MSECS
LD8B2:  BNE  S_EXT_99               ;SO USE 16 INTS ==> 64 MSEC ON, 64 MSECS OFF
LD8B4:  LDX  #S_BASE+OFFSET+OFFSET

S_EXT_10:
LD8B7:  LDA  S_CCTIM-S_BASE,X       ;CHECK TIMER(X)
LD8B9:  BPL  S_EXT_30               ;B NOT CURRENTLY ACTIVE ON
LD8BB:  ANDA #$7F                   ;WAS ACTIVE ON, SO CYCLE TO ACTIVE OFF
LD8BD:  INCB                        ;FLAGIT: FOUND AN ACTIVE COUNTER

S_EXT_20:
LD8BE:  STA  S_CCTIM-S_BASE,X       ;SAVE DECREMENTED TIMER

S_EXT_30:
LD8C0:  LEAX -OFFSET,X
LD8C2:  CMPX #S_BASE
LD8C5:  BGE  S_EXT_10
LD8C7:  TSTB                        ;CHECK "IN USE" FLAG
LD8C8:  BNE  S_EXT_99               ;SKIP IF ANY IN USE
;IF NONE OF THE COUNTERS ARE CURRENTLY IN USE, WE CHECK TO SEE IF ANY CAN BE
;STARTED.
LD8CA:  LDX  #S_BASE+OFFSET+OFFSET

S_EXT_40:
LD8CD:  LDA  S_CCTIM-S_BASE,X       ;NEED WE START THIS ONE
LD8CF:  BEQ  S_EXT_50               ;NO, NO COUNTS PENDING
LD8D1:  ADDA #$7F                   ;SET 1 MSB, DEC 7 LSB
LD8D3:  STA  S_CCTIM-S_BASE,X       ;START TIMER, ACTIVE ON
LD8D5:  BRA  S_EXT_99               ;EXIT, SO WE DON'T START MORE

S_EXT_50:
LD8D7:  LEAX -OFFSET,X
LD8D9:  CMPX #S_BASE
LD8DC:  BGE  S_EXT_40

S_EXT_99:
LD8DE:  RTS

;==============================================================================
; MODULE TCMES   TCMES.MAC
;   MESSAGE GENERATOR
;==============================================================================

;------------------------------------------------------------------------------
; MESSON - MESSON,MESSOFF
;------------------------------------------------------------------------------
MESSON:
LD8DF:  LDX  #MESBLK
LD8E2:  CMPX MESLST
LD8E5:  BHS  LD8F1                  ;IFLO  LIST NOT EMPTY, SEARCH IT
LD8E7:  CMPA ,X+
LD8E9:  BNE  LD8EC                  ;IFEQ  ALREADY HERE
LD8EB:  RTS                         ;LEAVE
LD8EC:  CMPX MESLST                 ;END OF LIST?
LD8EF:  BLO  LD8E7                  ;HSEND
;X POINTS TO NEXT AVAILABLE SLOT IN MESSAGE LIST
LD8F1:  STA  ,X+                    ;STORE MESSAGE NUMBER
LD8F3:  STX  MESLST                 ;UPDATE POINTER
LD8F6:  RTS

;------------------------------------------------------------------------------
; MESSOFF - [note] Turn message A off: search the list MESBLK..MESLST for message number A and delete it by moving the
;   last entry into its slot and backing MESLST up one
;------------------------------------------------------------------------------
MESSOFF:
LD8F7:  LDX  #MESBLK                ;SEARCH MESSAGE LIST FOR MESSAGE NUMBER
LD8FA:  CMPA ,X
LD8FC:  BNE  LD912                  ;IFEQ  FOUND IT, DELETE IT
LD8FE:  LDU  MESLST                 ;AVAILABLE POINTER
LD901:  CMPU #MESBLK                ;COMPARE WITH FIRST ENTRY SLOT
LD905:  BLS  LD912                  ;IFHI  LIST WASN'T EMPTY, OK TO DELETE IT
LD907:  LEAU -$1,U                  ;DECU  POINTS TO LAST ENTRY NOW
LD909:  LDA  ,U                     ;WAS LAST ENTRY
LD90B:  STA  ,X                     ;INSERT AT ENTRY TO BE DELETED
LD90D:  STU  MESLST                 ;SAVE UPDATE POINTER
LD910:  LEAX ,U                     ;TUX  TRANSFER U->X, LEAVE LOOP
LD912:  LEAX 1,X                    ;NEXT ENTRY
LD914:  CMPX MESLST
LD917:  BLO  LD8FA                  ;HSEND
LD919:  RTS

;------------------------------------------------------------------------------
; ALLOFF - TURN OFF ALL MESSAGES  (comment at the calls)
;   TURN ALL MESSAGES OFF  (another call)
;------------------------------------------------------------------------------
ALLOFF:
LD91A:  LDX  #MESBLK                ;SET POINTER TO START OF LIST
LD91D:  CLR  ,X
LD91F:  STX  MESLST
LD922:  RTS

;------------------------------------------------------------------------------
; VWMESS - VWMESS
;------------------------------------------------------------------------------
VWMESS:
LD923:  LDU  #MESBLK                ;START AT THE BEGINNING
LD926:  CMPU MESLST                 ;ARE WE DONE BEFORE WE START?
LD92A:  BHS  LD941                  ;IFLO  NO, GO ON
LD92C:  LDB  ,U+
LD92E:  CMPB #MESSZ                 ;IS IT A VALID MESSAGE NUMBER?
LD930:  BHS  LD93B                  ;IFLO  YES, DO IT
LD932:  STB  >MESNUM                ;SAVE IT FOR LATER--->MESOUT
LD935:  JSR  MCOLR                  ;COLOR
LD938:  JSR  MOUT2                  ;OUTPUT CHARACTERS
LD93B:  CMPU MESLST                 ;DONE? (U UPDATED AT BEGINNING OF LOOP)
LD93F:  BLO  LD92C                  ;HSEND
LD941:  RTS

;------------------------------------------------------------------------------
; VWMES2 - VWMES2 NEVER DOES A COLOR COMMAND
;------------------------------------------------------------------------------
VWMES2:
LD942:  LDU  #MESBLK                ;START AT THE BEGINNING
LD945:  CMPU MESLST                 ;ARE WE DONE BEFORE WE START?
LD949:  BHS  LD95D                  ;IFLO  NO, GO ON
LD94B:  LDB  ,U+
LD94D:  CMPB #MESSZ                 ;IS IT A VALID MESSAGE NUMBER?
LD94F:  BHS  LD957                  ;IFLO  YES, DO IT
LD951:  STB  >MESNUM                ;SAVE IT FOR LATER--->MESOUT
LD954:  JSR  MOUT2                  ;OUTPUT CHARACTERS
LD957:  CMPU MESLST                 ;DONE? (U UPDATED AT BEGINNING OF LOOP)
LD95B:  BLO  LD94B                  ;HSEND
LD95D:  RTS

;------------------------------------------------------------------------------
; SPMON - SPMON,SPMOFF --SPECIAL MESSAGE ON,OFF
;------------------------------------------------------------------------------
SPMON:
LD95E:  LDU  SPMLST                 ;POINTS TO NEXT AVAILABLE SLOT IN SPECIAL MESSAGE LIST
LD961:  STA  ,U+                    ;PUT IT IN LIST
LD963:  LDD  #$0000                 ;SIZE ALWAYS STARTS AT LINEAR SCALE OF 0
LD966:  STD  ,U++
LD968:  LDD  #$0100                 ;START MOVING SLOW
LD96B:  STD  ,U++
LD96D:  STU  SPMLST                 ;SAVE UPDATED POINTER
LD970:  RTS

;------------------------------------------------------------------------------
; SPMOFF - GET RID OF IT  (comment at the call)
;------------------------------------------------------------------------------
SPMOFF:
LD971:  LDU  #SPMBLK                ;START AT THE BEGINNING
LD974:  CMPA ,U                     ;IS THIS IT
LD976:  BNE  LD97C                  ;IFEQ  YES, FOUND IT
LD978:  LDA  #$00
LD97A:  STD  ,U
LD97C:  LEAU 5,U                    ;NEXT ENTRY
LD97E:  CMPU SPMLST                 ;DONE?
LD982:  BLO  LD974                  ;HSEND
LD984:  RTS

;------------------------------------------------------------------------------
; VWSPMS - VWSPMS --- VIEW SPECIAL MESSAGES
;------------------------------------------------------------------------------
VWSPMS:
LD985:  LDU  #SPMBLK                ;SPECIAL MESSAGE RAM BLOCK
LD988:  CMPU SPMLST                 ;DONE BEFORE WE START?
LD98C:  BHS  LD9DB                  ;IFLO  LIST NOT EMPTY, GO ON
LD98E:  LDD  #VGSCAL                ;SET UP SCALE
LD991:  STD  ,Y++
LD993:  LDA  ,U+                    ;GET MESSAGE #
LD995:  BEQ  LD9D3                  ;IFNE  VALID MESSAGE
LD997:  STA  >MESNUM                ;SAVE IT FOR LATER
LD99A:  LDD  #VGLIMT&$1FFF          ;VECTOR FROM CENTER TO VANISHING POINT
LD99D:  STD  ,Y++
LD99F:  LDD  #$0000
LD9A2:  STD  ,Y++
LD9A4:  LDB  ,U                     ;SIZE FROM LIST
LD9A6:  LDA  #((VGSCAL/$100)&$F0)+1 ;MAKES THIS A SCAL INSTRUCTION
LD9A8:  STD  ,Y++
LD9AA:  COMB                        ;BRIGHTNESS RELATIVE TO INVERSE OF SCALE
LD9AB:  ADDB #$10                   ;PLUS AN OFFSET
LD9AD:  LDA  #(VGCOLR/$100)+VGCGRN  ;COLOR
LD9AF:  STD  ,Y++
LD9B1:  LDX  #TSPMX-(SPMS1*2)       ;TABLE OF SPECIAL MESS. X POSITIONS
LD9B4:  LDB  >MESNUM
LD9B7:  ABX
LD9B8:  ABX
LD9B9:  LDD  #$1DD0                 ;DELTA Y (FROM VANISHING POINT)
LD9BC:  STD  ,Y++
LD9BE:  LDD  ,X                     ;DELTA X FOR MESSAGE
LD9C0:  ANDA #$1F
LD9C2:  ORA  #$00
LD9C4:  STD  ,Y++
LD9C6:  JSR  MESOUT                 ;OUTPUT REST OF MESSAGE
LD9C9:  LDD  #VGSCAL                ;RESET THE SCALE TO NORMAL
LD9CC:  STD  ,Y++
LD9CE:  LDD  #VGCNTR                ;CENTER AFTER MESSAGE
LD9D1:  STD  ,Y++
LD9D3:  LEAU 4,U
LD9D5:  CMPU SPMLST                 ;DONE?
LD9D9:  BLO  LD993                  ;HSEND
LD9DB:  RTS

;------------------------------------------------------------------------------
; BGBNNR - BEGIN BANNER
;------------------------------------------------------------------------------
BGBNNR:
LD9DC:  LDD  #$0000
LD9DF:  STD  BN_CNT
LD9E2:  LDD  #(VGCOLR&$F000)+$18    ;START WITH DIM Z
LD9E5:  STD  BN_COL
LD9E8:  LDD  #SPMBLK                ;SETUP POINTER
LD9EB:  STD  SPMLST
LD9EE:  LDD  TSPMAL                 ;SETUP ALARM FOR 1ST MESSAGE
LD9F1:  STD  SPMALM
LD9F4:  LDA  #SPMS1
LD9F6:  STA  SPMNXT
LD9F9:  RTS

;------------------------------------------------------------------------------
; VWBNNR - VIEW BANNER, STAR WARS TITLE
;------------------------------------------------------------------------------
VWBNNR:
LD9FA:  LDD  BN_CNT
LD9FD:  ADDD #$0001
LDA00:  STD  BN_CNT
LDA03:  CMPD #$00F8                 ;MAX OF LINEAR SCALE
LDA07:  LBHS SPMESS                 ;TOO SMALL, GOTO END
;ELSE
;PUT OUT "STAR WARS"
LDA0B:  CMPD #$0040
LDA0F:  BHS  LDA1E                  ;IFLO  BRIGHTENING, NOT MOVING
LDA11:  LDD  BN_COL
LDA14:  ADDB #$03
LDA16:  STD  BN_COL
LDA19:  LDD  #$0040                 ;ASSUME A SIZE
LDA1C:  BRA  LDA2A                  ;ELSE  NOW MOVE AND DIM BRIGHTNESS RELATIVE TO SCALE
LDA1E:  LDD  BN_CNT
LDA21:  COMB
LDA22:  ADDB #$18                   ;ADD AN OFFSET SO BRIGHT LONGER
LDA24:  STD  BN_COL
LDA27:  LDD  BN_CNT
LDA2A:  ORA  #(VGSCAL/$100)+1
LDA2C:  STD  BN_SCL
LDA2F:  LDD  BN_COL                 ;SETUP COLOR JUST ONCE
LDA32:  ORA  #((VGCOLR&$F000)/$100)+VGCBLU
LDA34:  STD  ,Y++
LDA36:  LDD  #VGLIMT&$1FFF          ;HORIZON POINT FOR BANNERS
LDA39:  STD  ,Y
LDA3B:  STD  8,Y
LDA3D:  STD  $10,Y
LDA40:  STD  $18,Y
LDA43:  STD  $20,Y
LDA46:  STD  $28,Y
LDA49:  LDD  #$0000
LDA4C:  STD  2,Y
LDA4E:  STD  $A,Y
LDA50:  STD  $12,Y
LDA53:  STD  $1A,Y
LDA56:  STD  $22,Y
LDA59:  STD  $2A,Y
LDA5C:  LDD  BN_SCL
LDA5F:  STD  4,Y
LDA61:  STD  $C,Y
LDA63:  STD  $14,Y
LDA66:  STD  $1C,Y
LDA69:  STD  $24,Y
LDA6C:  STD  $2C,Y
LDA6F:  LDD  #VJSWST                ;'ST'
LDA72:  STD  6,Y
LDA74:  LDD  #VJSWSA                ;'A'
LDA77:  STD  $E,Y
LDA79:  LDD  #VJSWSR                ;'R'
LDA7C:  STD  $16,Y
LDA7F:  LDD  #VJSWWW                ;'W'
LDA82:  STD  $1E,Y
LDA85:  LDD  #VJSWWA                ;'A'
LDA88:  STD  $26,Y
LDA8B:  LDD  #VJSWRS                ;'RS'
LDA8E:  STD  $2E,Y
LDA91:  LEAY $30,Y

;.SBTTL SPMESS

SPMESS:
VWBNNR_80:
LDA94:  LDX  #SPMBLK                ;UPDATE MOVING MESSAGE SIZES
LDA97:  CMPX SPMLST
LDA9A:  BHS  LDAF5                  ;IFLO  THERE IS A MESSAGE TO PROCESS
LDA9C:  LDD  BN_CNT
LDA9F:  CMPD #$00E0
LDAA3:  BHS  LDAB3                  ;IFLO
LDAA5:  CMPD #$0040
LDAA9:  BLO  LDAB1                  ;IFHS
LDAAB:  LDD  1,X
LDAAD:  ADDD 3,X
LDAAF:  STD  1,X
LDAB1:  BRA  LDAEE                  ;ELSE
LDAB3:  CMPD #$0160
LDAB7:  BHS  LDAC1                  ;IFLO
LDAB9:  LDD  #$0400                 ;SPEED IT UP
LDABC:  STD  SPMBLK+3
LDABF:  BRA  LDAEE                  ;ELSE
LDAC1:  LDD  1,X                    ;UPDATE SCALE
LDAC3:  ADDD 3,X
LDAC5:  STD  1,X
LDAC7:  CMPD #$F000                 ;MAKE NEXT ONE FAST
LDACB:  BLO  LDAEE                  ;IFHS
LDACD:  LDA  ,X                     ;MESSAGE #
LDACF:  INCA                        ;NEXT MESSAGE
LDAD0:  LDU  #SPMBLK
LDAD3:  CMPA ,U
LDAD5:  BNE  LDADF                  ;IFEQ  FOUND NEXT HIGHER MESSAGE
LDAD7:  LDD  #$0400                 ;SPEED IT UP
LDADA:  STD  3,U
LDADC:  LDU  SPMLST                 ;LEAVE LOOP
LDADF:  LEAU 5,U                    ;NEXT IN LIST
LDAE1:  CMPU SPMLST                 ;DONE?
LDAE5:  BLO  LDAD3                  ;HSEND
LDAE7:  LDA  ,X
LDAE9:  JSR  SPMOFF                 ;GET RID OF IT
LDAEC:  LEAX -$5,X                  ;MAKE SURE WE DO THE ONE THAT REPLACED IT
LDAEE:  LEAX 5,X
LDAF0:  CMPX SPMLST                 ;DONE?
LDAF3:  BLO  LDA9C                  ;HSEND
LDAF5:  LDD  BN_CNT                 ;INC TIMER
LDAF8:  CMPD #$0200
LDAFC:  BLO  LDB03                  ;IFHS  DONE, GO BACK TO INSTRUCTION PHASE
LDAFE:  LDA  #PHS_INS
LDB00:  STA  >PHASE
LDB03:  CMPD SPMALM                 ;ALARM? ( NEXT LINE ?)
LDB07:  BLO  LDB2E                  ;IFHS  YES, START IT AND RESET FOR NEXT LINE
LDB09:  LDA  SPMNXT
LDB0C:  JSR  SPMON
LDB0F:  LDA  SPMNXT
LDB12:  INCA
LDB13:  CMPA #SPMSZ
LDB15:  BLO  LDB1F                  ;IFHS  NO MORE MESSAGES
LDB17:  LDD  #$FFFF                 ;DISABLE ALARM
LDB1A:  STD  SPMALM                 ;TIMER WILL NEVER GET THIS FAR
LDB1D:  BRA  LDB2E                  ;ELSE
LDB1F:  STA  SPMNXT                 ;NEXT MESSAGE TO GO OUT
LDB22:  LDX  #TSPMAL-(SPMS1*2)      ;GET ALARM TIME
LDB25:  TFR  A,B
LDB27:  ABX                         ;WORD TABLE
LDB28:  ABX
LDB29:  LDD  ,X
LDB2B:  STD  SPMALM                 ;NEW ALARM
LDB2E:  RTS

TSPMAL:          ;ALARM TIMES FOR SPECIAL MESSAGES
LDB2F:  .word $0041
LDB31:  .word $0050
LDB33:  .word $0060
LDB35:  .word $0070
LDB37:  .word $0080
LDB39:  .word $0090
LDB3B:  .word $00A0
LDB3D:  .word $00B8

;.SBTTL MESSAGES

MES0:
LDB3F:  .byte $53, $54, $41, $52, $20, $57, $41, $52 ;.MESS -104.,-420.,GRN,<STAR WARS>,CPY
LDB47:  .byte $D3

MES1:
LDB48:  .byte $40, $20, $31, $39, $38, $33, $20, $4C ;.MESS -404.,-456.,GRN,<@ 1983 LUCASFILM LTD. AND ATARI,INC.>
LDB50:  .byte $55, $43, $41, $53, $46, $49, $4C, $4D
LDB58:  .byte $20, $4C, $54, $44, $2E, $20, $41, $4E
LDB60:  .byte $44, $20, $41, $54, $41, $52, $49, $2C
LDB68:  .byte $49, $4E, $43, $AE

MES2:
LDB6C:  .byte $41, $4C, $4C, $20, $52, $49, $47, $48 ;.MESS -224.,-492.,GRN,<ALL RIGHTS RESERVED.>
LDB74:  .byte $54, $53, $20, $52, $45, $53, $45, $52
LDB7C:  .byte $56, $45, $44, $AE

MES3:
LDB80:  .byte $4C, $55, $43, $41, $53, $46, $49, $4C ;.MESS -464.,-528.,GRN,<LUCASFILM TRADEMARKS USED UNDER LICENSE.>,CPZ
LDB88:  .byte $4D, $20, $54, $52, $41, $44, $45, $4D
LDB90:  .byte $41, $52, $4B, $53, $20, $55, $53, $45
LDB98:  .byte $44, $20, $55, $4E, $44, $45, $52, $20
LDBA0:  .byte $4C, $49, $43, $45, $4E, $53, $45, $AE

MES4:
MES5:
LDBA8:  .byte $47, $41, $4D, $45, $20, $4F, $56, $45 ;.MESS -104.,0480.,TRQ,<GAME OVER>,GVR
LDBB0:  .byte $D2

MES6:
LDBB1:  .byte $49, $4E, $53, $45, $52, $54, $20, $43 ;.MESS -140.,0480.,BLU,<INSERT COINS>,INS
LDBB9:  .byte $4F, $49, $4E, $D3

MES7:
LDBBD:  .byte $46, $52, $45, $45, $20, $50, $4C, $41 ;.MESS -104.,0432.,YLW,<FREE PLAY>,FRE
LDBC5:  .byte $D9

MES8:
LDBC6:  .byte $32, $20, $50, $4C, $41, $59, $53, $20 ;.MESS -164.,0432.,YLW,<2 PLAYS 1 COIN>,2PC
LDBCE:  .byte $31, $20, $43, $4F, $49, $CE

MES9:
LDBD4:  .byte $31, $20, $43, $4F, $49, $4E, $20, $31 ;.MESS -152.,0432.,YLW,<1 COIN 1 PLAY>,1CP
LDBDC:  .byte $20, $50, $4C, $41, $D9

MES10:
LDBE1:  .byte $32, $20, $43, $4F, $49, $4E, $53, $20 ;.MESS -164.,0432.,YLW,<2 COINS 1 PLAY>,2CP
LDBE9:  .byte $31, $20, $50, $4C, $41, $D9

MES11:
LDBEF:  .byte $50, $55, $4C, $4C, $20, $54, $52, $49 ;.MESS -248.,0480.,VJMFL,<PULL TRIGGER TO START>,STR
LDBF7:  .byte $47, $47, $45, $52, $20, $54, $4F, $20
LDBFF:  .byte $53, $54, $41, $52, $D4

MES12:
LDC04:  .byte $43, $52, $45, $44, $49, $54, $D3 ;.MESS -060.,0432.,WHT,<CREDITS>,CRD

MES13:
LDC0B:  .byte $43, $52, $45, $44, $49, $D4 ;.MESS -060.,0432.,WHT,<CREDIT>

MES14:
LDC11:  .byte $53, $48, $49, $45, $4C, $44, $20, $47 ;.MESS -116.,460./2,VJMFL,<SHIELD GONE>,SHG
LDC19:  .byte $4F, $4E, $C5

MES15:
LDC1C:  .byte $46, $4C, $49, $47, $48, $54, $20, $49 ;.MESS -396.,0288.,RED,<FLIGHT INSTRUCTIONS TO RED FIVE>,FLI
LDC24:  .byte $4E, $53, $54, $52, $55, $43, $54, $49
LDC2C:  .byte $4F, $4E, $53, $20, $54, $4F, $20, $52
LDC34:  .byte $45, $44, $20, $46, $49, $56, $C5

MES16:
LDC3B:  .byte $31, $2E, $20, $20, $59, $4F, $55, $52 ;.MESS -444.,0216.,RED,<1. YOUR X-WING IS EQUIPPED WITH AN>
LDC43:  .byte $20, $58, $2D, $57, $49, $4E, $47, $20
LDC4B:  .byte $49, $53, $20, $45, $51, $55, $49, $50
LDC53:  .byte $50, $45, $44, $20, $57, $49, $54, $48
LDC5B:  .byte $20, $41, $CE

MES17:
LDC5E:  .byte $49, $4E, $56, $49, $53, $49, $42, $4C ;.MESS -420.,0180.,RED,<INVISIBLE DEFLECTOR SHIELD THAT>
LDC66:  .byte $45, $20, $44, $45, $46, $4C, $45, $43
LDC6E:  .byte $54, $4F, $52, $20, $53, $48, $49, $45
LDC76:  .byte $4C, $44, $20, $54, $48, $41, $D4

MES18:
LDC7D:  .byte $57, $49, $4C, $4C, $20, $50, $52, $4F ;.MESS -420.,0144.,RED,<WILL PROTECT YOU FOR COLLISIONS.>
LDC85:  .byte $54, $45, $43, $54, $20, $59, $4F, $55
LDC8D:  .byte $20, $46, $4F, $52, $20, $20, $20, $43
LDC95:  .byte $4F, $4C, $4C, $49, $53, $49, $4F, $4E
LDC9D:  .byte $53, $AE

MES19:
LDC9F:  .byte $32, $2E, $20, $20, $44, $45, $46, $4C ;.MESS -444.,0072.,RED,<2. DEFLECTOR STRENGTH IS LOST WHEN>
LDCA7:  .byte $45, $43, $54, $4F, $52, $20, $53, $54
LDCAF:  .byte $52, $45, $4E, $47, $54, $48, $20, $49
LDCB7:  .byte $53, $20, $4C, $4F, $53, $54, $20, $57
LDCBF:  .byte $48, $45, $CE

MES20:
LDCC2:  .byte $41, $20, $46, $49, $52, $45, $42, $41 ;.MESS -420.,0036.,RED,<A FIREBALL IMPACTS YOUR SHIELD OR>
LDCCA:  .byte $4C, $4C, $20, $49, $4D, $50, $41, $43
LDCD2:  .byte $54, $53, $20, $59, $4F, $55, $52, $20
LDCDA:  .byte $53, $48, $49, $45, $4C, $44, $20, $4F
LDCE2:  .byte $D2

MES21:
LDCE3:  .byte $57, $48, $45, $4E, $20, $59, $4F, $55 ;.MESS -420.,0000.,RED,<WHEN YOU STRIKE A LASER TOWER OR>
LDCEB:  .byte $20, $53, $54, $52, $49, $4B, $45, $20
LDCF3:  .byte $41, $20, $4C, $41, $53, $45, $52, $20
LDCFB:  .byte $54, $4F, $57, $45, $52, $20, $4F, $D2

MES22:
LDD03:  .byte $54, $52, $45, $4E, $43, $48, $20, $43 ;.MESS -420.,-036.,RED,<TRENCH CATWALK.>
LDD0B:  .byte $41, $54, $57, $41, $4C, $4B, $AE

MES23:
LDD12:  .byte $33, $2E, $20, $20, $41, $49, $4D, $20 ;.MESS -444.,-108.,RED,<3. AIM YOUR LASERS WITH CURSOR TO>
LDD1A:  .byte $59, $4F, $55, $52, $20, $4C, $41, $53
LDD22:  .byte $45, $52, $53, $20, $57, $49, $54, $48
LDD2A:  .byte $20, $43, $55, $52, $53, $4F, $52, $20
LDD32:  .byte $54, $CF

MES24:
LDD34:  .byte $45, $58, $50, $4C, $4F, $44, $45, $20 ;.MESS -420.,-144.,RED,<EXPLODE EMPIRE TIE FIGHTERS, LASER>
LDD3C:  .byte $45, $4D, $50, $49, $52, $45, $20, $54
LDD44:  .byte $49, $45, $20, $46, $49, $47, $48, $54
LDD4C:  .byte $45, $52, $53, $2C, $20, $4C, $41, $53
LDD54:  .byte $45, $D2

MES25:
LDD56:  .byte $54, $4F, $57, $45, $52, $20, $54, $4F ;.MESS -420.,-180.,RED,<TOWER TOPS AND TRENCH TURRETS.>
LDD5E:  .byte $50, $53, $20, $41, $4E, $44, $20, $54
LDD66:  .byte $52, $45, $4E, $43, $48, $20, $54, $55
LDD6E:  .byte $52, $52, $45, $54, $53, $AE

MES26:
LDD74:  .byte $34, $2E, $20, $20, $53, $48, $4F, $4F ;.MESS -444.,-252.,RED,<4. SHOOT FIREBALLS BEFORE THEY>
LDD7C:  .byte $54, $20, $46, $49, $52, $45, $42, $41
LDD84:  .byte $4C, $4C, $53, $20, $42, $45, $46, $4F
LDD8C:  .byte $52, $45, $20, $54, $48, $45, $D9

MES27:
LDD93:  .byte $49, $4D, $50, $41, $43, $54, $20, $59 ;.MESS -420.,-288.,RED,<IMPACT YOUR SHIELD.>
LDD9B:  .byte $4F, $55, $52, $20, $53, $48, $49, $45
LDDA3:  .byte $4C, $44, $AE

MES28:
LDDA6:  .byte $35, $2E, $20, $20, $54, $48, $45, $20 ;.MESS -444.,-360.,RED,<5. THE REBEL FORCE IS DEPENDING ON>
LDDAE:  .byte $52, $45, $42, $45, $4C, $20, $46, $4F
LDDB6:  .byte $52, $43, $45, $20, $49, $53, $20, $44
LDDBE:  .byte $45, $50, $45, $4E, $44, $49, $4E, $47
LDDC6:  .byte $20, $4F, $CE

MES29:
LDDC9:  .byte $59, $4F, $55, $20, $54, $4F, $20, $53 ;.MESS -420.,-396.,RED,<YOU TO STOP THE EMPIRE BY BLOWING>
LDDD1:  .byte $54, $4F, $50, $20, $54, $48, $45, $20
LDDD9:  .byte $45, $4D, $50, $49, $52, $45, $20, $42
LDDE1:  .byte $59, $20, $42, $4C, $4F, $57, $49, $4E
LDDE9:  .byte $C7

MES30:
LDDEA:  .byte $55, $50, $20, $54, $48, $45, $20, $44 ;.MESS -420.,-432.,RED,<UP THE DEATH STAR.>,FLZ
LDDF2:  .byte $45, $41, $54, $48, $20, $53, $54, $41
LDDFA:  .byte $52, $AE

MES31:
LDDFC:  .byte $B6                   ;.MESS 0084.,0144.,RED,<6>

MES32:
LDDFD:  .byte $B7                   ;.MESS 0084.,0144.,RED,<7>

MES33:
LDDFE:  .byte $B8                   ;.MESS 0084.,0144.,RED,<8>

MES34:
LDDFF:  .byte $B9                   ;.MESS 0084.,0144.,RED,<9>

MES35:
LDE00:  .byte $53, $43, $4F, $52, $49, $4E, $C7 ;.MESS -060.,0280.,PRP,<SCORING>,SCR

MES36:
LDE07:  .byte $54, $49, $45, $20, $46, $49, $47, $48 ;.MESS -372.,0180.,PRP,<TIE FIGHTERS 1,000>,SC1
LDE0F:  .byte $54, $45, $52, $53, $20, $20, $20, $20
LDE17:  .byte $20, $20, $20, $20, $20, $20, $20, $20
LDE1F:  .byte $20, $20, $20, $20, $20, $31, $2C, $30
LDE27:  .byte $30, $B0

MES37:
LDE29:  .byte $44, $41, $52, $54, $48, $20, $56, $41 ;.MESS -372.,0120.,PRP,<DARTH VADER'S SHIP 2,000>
LDE31:  .byte $44, $45, $52, $27, $53, $20, $53, $48
LDE39:  .byte $49, $50, $20, $20, $20, $20, $20, $20
LDE41:  .byte $20, $20, $20, $20, $20, $32, $2C, $30
LDE49:  .byte $30, $B0

MES38:
LDE4B:  .byte $4C, $41, $53, $45, $52, $20, $42, $55 ;.MESS -372.,0060.,PRP,<LASER BUNKERS 200>
LDE53:  .byte $4E, $4B, $45, $52, $53, $20, $20, $20
LDE5B:  .byte $20, $20, $20, $20, $20, $20, $20, $20
LDE63:  .byte $20, $20, $20, $20, $20, $20, $20, $32
LDE6B:  .byte $30, $B0

MES39:
LDE6D:  .byte $4C, $41, $53, $45, $52, $20, $54, $4F ;.MESS -372.,0000.,PRP,<LASER TOWERS 200>
LDE75:  .byte $57, $45, $52, $53, $20, $20, $20, $20
LDE7D:  .byte $20, $20, $20, $20, $20, $20, $20, $20
LDE85:  .byte $20, $20, $20, $20, $20, $20, $20, $32
LDE8D:  .byte $30, $B0

MES40:
LDE8F:  .byte $54, $52, $45, $4E, $43, $48, $20, $54 ;.MESS -372.,-060.,PRP,<TRENCH TURRETS 100>
LDE97:  .byte $55, $52, $52, $45, $54, $53, $20, $20
LDE9F:  .byte $20, $20, $20, $20, $20, $20, $20, $20
LDEA7:  .byte $20, $20, $20, $20, $20, $20, $20, $31
LDEAF:  .byte $30, $B0

MES41:
LDEB1:  .byte $46, $49, $52, $45, $42, $41, $4C, $4C ;.MESS -372.,-120.,PRP,<FIREBALLS 33>
LDEB9:  .byte $53, $20, $20, $20, $20, $20, $20, $20
LDEC1:  .byte $20, $20, $20, $20, $20, $20, $20, $20
LDEC9:  .byte $20, $20, $20, $20, $20, $20, $20, $20
LDED1:  .byte $33, $B3

MES42:
LDED3:  .byte $45, $58, $48, $41, $55, $53, $54, $20 ;.MESS -372.,-280.,PRP,<EXHAUST PORT 25,000>
LDEDB:  .byte $50, $4F, $52, $54, $20, $20, $20, $20
LDEE3:  .byte $20, $20, $20, $20, $20, $20, $20, $20
LDEEB:  .byte $20, $20, $20, $20, $32, $35, $2C, $30
LDEF3:  .byte $30, $B0

MES43:
LDEF5:  .byte $44, $45, $53, $54, $52, $4F, $59, $49 ;.MESS -372.,-350.,PRP,<DESTROYING ALL TOWER TOPS 50,000>,SCZ
LDEFD:  .byte $4E, $47, $20, $41, $4C, $4C, $20, $54
LDF05:  .byte $4F, $57, $45, $52, $20, $54, $4F, $50
LDF0D:  .byte $53, $20, $20, $20, $35, $30, $2C, $30
LDF15:  .byte $30, $B0

MES44:
LDF17:  .byte $53, $45, $4C, $45, $43, $54, $20, $41 ;.MESS -224.,0340.,PRP,<SELECT A DEATH STAR>,DS1
LDF1F:  .byte $20, $44, $45, $41, $54, $48, $20, $53
LDF27:  .byte $54, $41, $D2

MES45:
LDF2A:  .byte $46, $49, $52, $45, $20, $4C, $41, $53 ;.MESS -380.,0300.,PRP,<FIRE LASER AT DESIRED DEATH STAR>
LDF32:  .byte $45, $52, $20, $41, $54, $20, $44, $45
LDF3A:  .byte $53, $49, $52, $45, $44, $20, $44, $45
LDF42:  .byte $41, $54, $48, $20, $53, $54, $41, $D2

MES46:
LDF4A:  .byte $43, $4F, $55, $4E, $54, $44, $4F, $57 ;.MESS -104.,0260.,VJMFL,<COUNTDOWN>
LDF52:  .byte $CE

MES47:
LDF53:  .byte $45, $41, $53, $D9    ;.MESS -300.,0032.,GRN,<EASY>

MES48:
LDF57:  .byte $4D, $45, $44, $49, $55, $CD ;.MESS -068.,-200.,GRN,<MEDIUM>

MES49:
LDF5D:  .byte $48, $41, $52, $C4    ;.MESS 0224.,0032.,GRN,<HARD>

MES50:
LDF61:  .byte $57, $41, $56, $45, $20, $B1 ;.MESS -468.,0200.,RED,<WAVE 1>

MES51:
LDF67:  .byte $57, $41, $56, $45, $20, $B3 ;.MESS -068.,-160.,RED,<WAVE 3>

MES52:
LDF6D:  .byte $57, $41, $56, $45, $20, $B5 ;.MESS 0332.,0200.,RED,<WAVE 5>

MES53:
MES54:
LDF73:  .byte $42, $4F, $4E, $55, $D3 ;.MESS 0344.,0000.,BLU,<BONUS>

MES55:
LDF78:  .byte $4E, $4F, $20, $42, $4F, $4E, $55, $D3 ;.MESS -492.,0000.,BLU,<NO BONUS>

MES56:
LDF80:  .byte $34, $30, $30, $2C, $30, $30, $B0 ;.MESS -080.,-440.,RED,<400,000>

MES57:
LDF87:  .byte $38, $30, $30, $2C, $30, $30, $B0 ;.MESS 0320.,-040.,RED,<800,000>,DSZ

MES58:
LDF8E:  .byte $4D, $45, $53, $53, $41, $47, $45, $20 ;.MESS -368.,0340.,YLW,<MESSAGE FROM REBEL COMMAND POST>,HS1
LDF96:  .byte $46, $52, $4F, $4D, $20, $52, $45, $42
LDF9E:  .byte $45, $4C, $20, $43, $4F, $4D, $4D, $41
LDFA6:  .byte $4E, $44, $20, $50, $4F, $53, $D4

MES59:
LDFAD:  .byte $59, $4F, $55, $20, $41, $52, $45, $20 ;.MESS -308.,0280.,PRP,<YOU ARE A TRUE REBEL PILOT>
LDFB5:  .byte $41, $20, $54, $52, $55, $45, $20, $52
LDFBD:  .byte $45, $42, $45, $4C, $20, $50, $49, $4C
LDFC5:  .byte $4F, $D4

MES60:
LDFC7:  .byte $54, $48, $45, $20, $46, $4F, $52, $43 ;.MESS -248.,0220.,VJMFL,<THE FORCE IS WITH YOU>
LDFCF:  .byte $45, $20, $49, $53, $20, $57, $49, $54
LDFD7:  .byte $48, $20, $59, $4F, $D5

MES61:
LDFDC:  .byte $53, $48, $4F, $4F, $54, $20, $59, $4F ;.MESS -224.,0120.,BLU,<SHOOT YOUR INITIALS>,HSZ
LDFE4:  .byte $55, $52, $20, $49, $4E, $49, $54, $49
LDFEC:  .byte $41, $4C, $D3

MES62:
MES63:
LDFEF:  .byte $50, $52, $49, $4E, $43, $45, $53, $53 ;.MESS -320.,0316.,RED,<PRINCESS LEIA'S REBEL FORCE>,RF2
LDFF7:  .byte $20, $4C, $45, $49, $41, $27, $53, $20
LDFFF:  .byte $52, $45, $42, $45, $4C, $20, $46, $4F
LE007:  .byte $52, $43, $C5

MES64:
LE00A:  .byte $50, $4F, $49, $4E, $54, $53, $20, $4E ;.MESS -128.,VGRW7,RED,<POINTS NEXT TOWER>,NXT
LE012:  .byte $45, $58, $54, $20, $54, $4F, $57, $45
LE01A:  .byte $D2

MES65:
LE01B:  .byte $54, $4F, $57, $45, $52, $D3 ;.MESS 0314.,0444.,RED,<TOWERS>,TWR

MES66:
LE021:  .byte $43, $4C, $45, $41, $52, $45, $44, $20 ;.MESS -284.,VGRW7,VJMFL,<CLEARED ALL LASER TOWERS>,ATP
LE029:  .byte $41, $4C, $4C, $20, $4C, $41, $53, $45
LE031:  .byte $52, $20, $54, $4F, $57, $45, $52, $D3

MES67:
LE039:  .byte $35, $30, $2C, $30, $30, $30, $20, $46 ;.MESS -356.,VGRW7,RED,<50,000 FOR SHOOTING ALL TOWERS>,RWD
LE041:  .byte $4F, $52, $20, $53, $48, $4F, $4F, $54
LE049:  .byte $49, $4E, $47, $20, $41, $4C, $4C, $20
LE051:  .byte $54, $4F, $57, $45, $52, $D3

MES68:
LE057:  .byte $45, $58, $48, $41, $55, $53, $54, $20 ;.MESS -212.,VGRW9/2-12.,VJMFL,<EXHAUST PORT AHEAD>,EXH
LE05F:  .byte $50, $4F, $52, $54, $20, $41, $48, $45
LE067:  .byte $41, $C4

MES69:
LE069:  .byte $44, $45, $41, $54, $48, $20, $53, $54 ;.MESS -236.,0312.,VJMFL,<DEATH STAR DESTROYED>,DSD
LE071:  .byte $41, $52, $20, $44, $45, $53, $54, $52
LE079:  .byte $4F, $59, $45, $C4

MES70:
LE07D:  .byte $45, $58, $48, $41, $55, $53, $54, $20 ;.MESS -224.,VGRW9/2-12.,VJMFL,<EXHAUST PORT MISSED>,MSD
LE085:  .byte $50, $4F, $52, $54, $20, $4D, $49, $53
LE08D:  .byte $53, $45, $C4

MES71:
LE090:  .byte $42, $4F, $4E, $55, $53, $20, $46, $4F ;.MESS -308.,0192.,VJMFL,<BONUS FOR REMAINING ENERGY>,BRE
LE098:  .byte $52, $20, $52, $45, $4D, $41, $49, $4E
LE0A0:  .byte $49, $4E, $47, $20, $45, $4E, $45, $52
LE0A8:  .byte $47, $D9

MES72:
LE0AA:  .byte $35, $2C, $30, $30, $30, $20, $20, $D8 ;.MESS -128.,0144.,VJMFL,<5,000 X>

MES73:
LE0B2:  .byte $41, $44, $44, $45, $44, $20, $54, $4F ;.MESS -272.,0072.,VJMFL,<ADDED TO DEFLECTOR SHIELD>,BSE
LE0BA:  .byte $20, $44, $45, $46, $4C, $45, $43, $54
LE0C2:  .byte $4F, $52, $20, $53, $48, $49, $45, $4C
LE0CA:  .byte $C4

MES74:
LE0CB:  .byte $53, $48, $49, $45, $4C, $44, $20, $41 ;.MESS -272.,0072.,VJMFL,<SHIELD AT FULL STRENGTH>
LE0D3:  .byte $54, $20, $46, $55, $4C, $4C, $20, $53
LE0DB:  .byte $54, $52, $45, $4E, $47, $54, $C8

MES75:
LE0E2:  .byte $53, $54, $41, $52, $54, $49, $4E, $47 ;.MESS -224.,-048.,VJMFL,<STARTING WAVE BONUS>,BON
LE0EA:  .byte $20, $57, $41, $56, $45, $20, $42, $4F
LE0F2:  .byte $4E, $55, $D3

MES76:
LE0F5:  .byte $53, $48, $4F, $4F, $54, $20, $46, $49 ;.MESS -176.,VGRW7,WHT,<SHOOT FIREBALLS>,SFB
LE0FD:  .byte $52, $45, $42, $41, $4C, $4C, $D3

MES77:
LE104:  .byte $53, $48, $4F, $4F, $54, $20, $54, $49 ;.MESS -212.,VGRW7,RED,<SHOOT TIE FIGHTERS>,STF
LE10C:  .byte $45, $20, $46, $49, $47, $48, $54, $45
LE114:  .byte $52, $D3

MES78:
LE116:  .byte $41, $56, $4F, $49, $44, $20, $43, $41 ;.MESS -164.,VGRW7,RED,<AVOID CATWALKS>,ACW
LE11E:  .byte $54, $57, $41, $4C, $4B, $D3

MES79:
LE124:  .byte $55, $53, $45, $20, $54, $48, $45, $20 ;.MESS -152.,VGRW9,VJMFL,<USE THE FORCE>,USE
LE12C:  .byte $46, $4F, $52, $43, $C5

MES80:
LE131:  .byte $20, $46, $4F, $52, $20, $55, $53, $49 ;.MESS 0000.,0000.,VJMFL,< FOR USING THE FORCE>
LE139:  .byte $4E, $47, $20, $54, $48, $45, $20, $46
LE141:  .byte $4F, $52, $43, $C5

MES81:
LE145:  .byte $4F, $42, $49, $2D, $57, $41, $4E, $20 ;.SPMESS <OBI-WAN KENOBI IS GONE BUT HIS>
LE14D:  .byte $4B, $45, $4E, $4F, $42, $49, $20, $49
LE155:  .byte $53, $20, $47, $4F, $4E, $45, $20, $42
LE15D:  .byte $55, $54, $20, $48, $49, $D3

MES82:
LE163:  .byte $50, $52, $45, $53, $45, $4E, $43, $45 ;.SPMESS <PRESENCE IS FELT WITHIN THE FORCE.>
LE16B:  .byte $20, $49, $53, $20, $46, $45, $4C, $54
LE173:  .byte $20, $57, $49, $54, $48, $49, $4E, $20
LE17B:  .byte $54, $48, $45, $20, $46, $4F, $52, $43
LE183:  .byte $45, $AE

MES83:
LE185:  .byte $54, $48, $45, $20, $45, $4D, $50, $49 ;.SPMESS <THE EMPIRE'S DEATH STAR, UNDER THE>
LE18D:  .byte $52, $45, $27, $53, $20, $44, $45, $41
LE195:  .byte $54, $48, $20, $53, $54, $41, $52, $2C
LE19D:  .byte $20, $55, $4E, $44, $45, $52, $20, $54
LE1A5:  .byte $48, $C5

MES84:
LE1A7:  .byte $43, $4F, $4D, $4D, $41, $4E, $44, $20 ;.SPMESS <COMMAND OF DARTH VADER, NEARS THE>
LE1AF:  .byte $4F, $46, $20, $44, $41, $52, $54, $48
LE1B7:  .byte $20, $56, $41, $44, $45, $52, $2C, $20
LE1BF:  .byte $4E, $45, $41, $52, $53, $20, $54, $48
LE1C7:  .byte $C5

MES85:
LE1C8:  .byte $52, $45, $42, $45, $4C, $20, $50, $4C ;.SPMESS <REBEL PLANET. YOU MUST JOIN THE>
LE1D0:  .byte $41, $4E, $45, $54, $2E, $20, $20, $59
LE1D8:  .byte $4F, $55, $20, $4D, $55, $53, $54, $20
LE1E0:  .byte $4A, $4F, $49, $4E, $20, $54, $48, $C5

MES86:
LE1E8:  .byte $52, $45, $42, $45, $4C, $4C, $49, $4F ;.SPMESS <REBELLION TO STOP THE EMPIRE.>
LE1F0:  .byte $4E, $20, $54, $4F, $20, $53, $54, $4F
LE1F8:  .byte $50, $20, $54, $48, $45, $20, $45, $4D
LE200:  .byte $50, $49, $52, $45, $AE

MES87:
LE205:  .byte $54, $48, $45, $20, $46, $4F, $52, $43 ;.SPMESS <THE FORCE WILL BE WITH YOU.>
LE20D:  .byte $45, $20, $57, $49, $4C, $4C, $20, $42
LE215:  .byte $45, $20, $57, $49, $54, $48, $20, $59
LE21D:  .byte $4F, $55, $AE

MES88:
LE220:  .byte $41, $4C, $57, $41, $59, $D3 ;.SPMESS <ALWAYS>

MES89:
LE226:  .byte $41, $43, $43, $4F, $55, $4E, $54, $49 ;.MESS -260.,480.,WHT,<ACCOUNTING INFORMATION>,ACC
LE22E:  .byte $4E, $47, $20, $49, $4E, $46, $4F, $52
LE236:  .byte $4D, $41, $54, $49, $4F, $CE

MES90:
LE23C:  .byte $41, $55, $58, $20, $43, $4F, $49, $4E ;.MESS -216.,440.,GRN,<AUX COINS>
LE244:  .byte $D3

MES91:
LE245:  .byte $4C, $45, $46, $54, $20, $4D, $45, $43 ;.MESS -360.,400.,GRN,<LEFT MECH COINS>
LE24D:  .byte $48, $20, $43, $4F, $49, $4E, $D3

MES92:
LE254:  .byte $52, $49, $47, $48, $54, $20, $4D, $45 ;.MESS -384.,360.,GRN,<RIGHT MECH COINS>
LE25C:  .byte $43, $48, $20, $43, $4F, $49, $4E, $D3

MES93:
LE264:  .byte $54, $4F, $54, $41, $4C, $20, $43, $4F ;.MESS -384.,320.,GRN,<TOTAL COINS PAID>
LE26C:  .byte $49, $4E, $53, $20, $50, $41, $49, $C4

MES94:
LE274:  .byte $47, $41, $4D, $45, $53, $20, $50, $4C ;.MESS -288.,280.,GRN,<GAMES PLAYED>
LE27C:  .byte $41, $59, $45, $C4

MES95:
LE280:  .byte $48, $49, $47, $48, $20, $57, $41, $56 ;.MESS 0250.,320.,GRN,<HIGH WAVE>
LE288:  .byte $C5

MES96:
LE289:  .byte $54, $4F, $54, $41, $4C, $20, $47, $41 ;.MESS -360.,220.,GRN,<TOTAL GAME TIME SECONDS>
LE291:  .byte $4D, $45, $20, $54, $49, $4D, $45, $20
LE299:  .byte $20, $20, $20, $20, $20, $20, $20, $20
LE2A1:  .byte $20, $20, $53, $45, $43, $4F, $4E, $44
LE2A9:  .byte $D3

MES97:
LE2AA:  .byte $41, $56, $45, $52, $41, $47, $45, $20 ;.MESS -408.,180.,GRN,<AVERAGE GAME TIME>
LE2B2:  .byte $47, $41, $4D, $45, $20, $54, $49, $4D
LE2BA:  .byte $C5

MES98:
LE2BB:  .byte $54, $4F, $54, $41, $4C, $20, $54, $49 ;.MESS -312.,120.,GRN,<TOTAL TIME ON SECONDS>
LE2C3:  .byte $4D, $45, $20, $4F, $4E, $20, $20, $20
LE2CB:  .byte $20, $20, $20, $20, $20, $20, $20, $20
LE2D3:  .byte $53, $45, $43, $4F, $4E, $44, $D3

MES99:
LE2DA:  .byte $50, $45, $52, $43, $45, $4E, $54, $41 ;.MESS -432.,080.,GRN,<PERCENTAGE OF PLAY PERCENT>
LE2E2:  .byte $47, $45, $20, $4F, $46, $20, $50, $4C
LE2EA:  .byte $41, $59, $20, $20, $20, $20, $20, $50
LE2F2:  .byte $45, $52, $43, $45, $4E, $D4

MES100:
LE2F8:  .byte $48, $49, $53, $54, $4F, $52, $59, $20 ;.MESS -248.,000.,WHT,<HISTORY OF GAME TIMES>
LE300:  .byte $4F, $46, $20, $47, $41, $4D, $45, $20
LE308:  .byte $54, $49, $4D, $45, $D3

MES101:
LE30D:  .byte $47, $41, $4D, $45, $20, $4F, $50, $54 ;.MESS -140.,500.,WHT,<GAME OPTIONS>,OPT
LE315:  .byte $49, $4F, $4E, $D3

MES102:
LE319:  .byte $56, $41, $4C, $55, $45, $20, $4F, $46 ;.MESS -360.,450.,GRN,<VALUE OF A COIN>
LE321:  .byte $20, $41, $20, $43, $4F, $49, $CE

MES103:
LE328:  .byte $4C, $45, $46, $54, $20, $4D, $45, $43 ;.MESS -360.,400.,GRN,<LEFT MECH VALUE>
LE330:  .byte $48, $20, $56, $41, $4C, $55, $C5

MES104:
LE337:  .byte $52, $49, $47, $48, $54, $20, $4D, $45 ;.MESS -384.,350.,GRN,<RIGHT MECH VALUE>
LE33F:  .byte $43, $48, $20, $56, $41, $4C, $55, $C5

MES105:
LE347:  .byte $42, $4F, $4E, $55, $53, $20, $41, $44 ;.MESS -264.,300.,GRN,<BONUS ADDER>
LE34F:  .byte $44, $45, $D2

MES106:
LE352:  .byte $53, $54, $41, $52, $54, $49, $4E, $47 ;.MESS -360.,250.,GRN,<STARTING SHIELD>
LE35A:  .byte $20, $53, $48, $49, $45, $4C, $C4

MES107:
LE361:  .byte $50, $4C, $41, $59, $20, $44, $49, $46 ;.MESS -360.,200.,GRN,<PLAY DIFFICULTY>
LE369:  .byte $46, $49, $43, $55, $4C, $54, $D9

MES108:
LE370:  .byte $42, $4F, $4E, $55, $53, $20, $53, $48 ;.MESS -288.,150.,GRN,<BONUS SHIELD>
LE378:  .byte $49, $45, $4C, $C4

MES109:
LE37C:  .byte $4D, $55, $53, $49, $43, $20, $49, $4E ;.MESS -384.,100.,GRN,<MUSIC IN ATTRACT>
LE384:  .byte $20, $41, $54, $54, $52, $41, $43, $D4

MES110:
LE38C:  .byte $52, $45, $53, $45, $54, $20, $48, $49 ;.MESS -408.,000.,GRN,<RESET HIGH SCORES>
LE394:  .byte $47, $48, $20, $53, $43, $4F, $52, $45
LE39C:  .byte $D3

MES111:
LE39D:  .byte $52, $45, $53, $45, $54, $20, $54, $49 ;.MESS -408.,-050.,GRN,<RESET TIMING INFO>
LE3A5:  .byte $4D, $49, $4E, $47, $20, $49, $4E, $46
LE3AD:  .byte $CF

MES112:
LE3AE:  .byte $52, $45, $53, $45, $54, $20, $4F, $50 ;.MESS -312.,-100.,GRN,<RESET OPTIONS>
LE3B6:  .byte $54, $49, $4F, $4E, $D3

MES113:
LE3BB:  .byte $54, $45, $53, $54, $20, $4E, $4F, $56 ;.MESS -264.,-150.,GRN,<TEST NOVRAM>
LE3C3:  .byte $52, $41, $CD

MES114:
LE3C6:  .byte $55, $50, $2C, $44, $4F, $57, $4E, $20 ;.MESS -260.,-300.,GRN,<UP,DOWN TO SELECT ITEM>
LE3CE:  .byte $54, $4F, $20, $53, $45, $4C, $45, $43
LE3D6:  .byte $54, $20, $49, $54, $45, $CD

MES115:
LE3DC:  .byte $50, $55, $4C, $4C, $20, $4C, $45, $46 ;.MESS -368.,-350.,GRN,<PULL LEFT FIRE TO CHANGE SETTING>
LE3E4:  .byte $54, $20, $46, $49, $52, $45, $20, $54
LE3EC:  .byte $4F, $20, $43, $48, $41, $4E, $47, $45
LE3F4:  .byte $20, $53, $45, $54, $54, $49, $4E, $C7

MES116:
LE3FC:  .byte $46, $52, $45, $45, $20, $50, $4C, $41 ;.MESS 072.,450.,GRN,<FREE PLAY>,VLC
LE404:  .byte $D9

MES117:
LE405:  .byte $32, $20, $43, $52, $45, $44, $49, $54 ;.MESS 072.,450.,GRN,<2 CREDITS>
LE40D:  .byte $D3

MES118:
LE40E:  .byte $31, $20, $43, $52, $45, $44, $49, $D4 ;.MESS 072.,450.,GRN,<1 CREDIT>

MES119:
LE416:  .byte $25, $20, $43, $52, $45, $44, $49, $D4 ;.MESS 072.,450.,GRN,<% CREDIT>

MES120:
LE41E:  .byte $B1                   ;.MESS 072.,400.,GRN,<1>,LMV

MES121:
LE41F:  .byte $B2                   ;.MESS 072.,400.,GRN,<2>

MES122:
LE420:  .byte $B1                   ;.MESS 072.,350.,GRN,<1>,RMV

MES123:
LE421:  .byte $B4                   ;.MESS 072.,350.,GRN,<4>

MES124:
LE422:  .byte $B5                   ;.MESS 072.,350.,GRN,<5>

MES125:
LE423:  .byte $B6                   ;.MESS 072.,350.,GRN,<6>

MES126:
LE424:  .byte $4E, $4F, $4E, $C5    ;.MESS 072.,300.,GRN,<NONE>,BAV

MES127:
LE428:  .byte $32, $20, $47, $49, $56, $45, $53, $20 ;.MESS 072.,300.,GRN,<2 GIVES 1>
LE430:  .byte $B1

MES128:
LE431:  .byte $34, $20, $47, $49, $56, $45, $53, $20 ;.MESS 072.,300.,GRN,<4 GIVES 1>
LE439:  .byte $B1

MES129:
LE43A:  .byte $34, $20, $47, $49, $56, $45, $53, $20 ;.MESS 072.,300.,GRN,<4 GIVES 2>
LE442:  .byte $B2

MES130:
LE443:  .byte $35, $20, $47, $49, $56, $45, $53, $20 ;.MESS 072.,300.,GRN,<5 GIVES 1>
LE44B:  .byte $B1

MES131:
LE44C:  .byte $33, $20, $47, $49, $56, $45, $53, $20 ;.MESS 072.,300.,GRN,<3 GIVES 1>
LE454:  .byte $B1

MES132:
MES133:
LE455:  .byte $4E, $4F, $4E, $C5    ;.MESS 072.,300.,GRN,<NONE>

MES134:
LE459:  .byte $B6                   ;.MESS 072.,250.,GRN,<6>,SLV

MES135:
LE45A:  .byte $B7                   ;.MESS 072.,250.,GRN,<7>

MES136:
LE45B:  .byte $B8                   ;.MESS 072.,250.,GRN,<8>

MES137:
LE45C:  .byte $B9                   ;.MESS 072.,250.,GRN,<9>

MES138:
LE45D:  .byte $45, $41, $53, $D9    ;.MESS 072.,200.,GRN,<EASY>,DIF

MES139:
LE461:  .byte $4D, $4F, $44, $45, $52, $41, $54, $C5 ;.MESS 072.,200.,GRN,<MODERATE>

MES140:
LE469:  .byte $48, $41, $52, $C4    ;.MESS 072.,200.,GRN,<HARD>

MES141:
LE46D:  .byte $48, $41, $52, $44, $45, $53, $D4 ;.MESS 072.,200.,GRN,<HARDEST>

MES142:
LE474:  .byte $B0                   ;.MESS 072.,150.,GRN,<0>,BSV

MES143:
LE475:  .byte $B1                   ;.MESS 072.,150.,GRN,<1>

MES144:
LE476:  .byte $B2                   ;.MESS 072.,150.,GRN,<2>

MES145:
LE477:  .byte $B3                   ;.MESS 072.,150.,GRN,<3>

MES146:
LE478:  .byte $59, $45, $D3         ;.MESS 072.,100.,GRN,<YES>,MUV

MES147:
LE47B:  .byte $4E, $CF              ;.MESS 072.,100.,GRN,<NO>

MES148:
LE47D:  .byte $4E, $CF              ;.MESS 072.,000.,GRN,<NO>,RHS

MES149:
LE47F:  .byte $59, $45, $D3         ;.MESS 072.,000.,GRN,<YES>

MES150:
LE482:  .byte $4E, $CF              ;.MESS 072.,-050.,GRN,<NO>,RAC

MES151:
LE484:  .byte $59, $45, $D3         ;.MESS 072.,-050.,GRN,<YES>

MES152:
LE487:  .byte $4E, $CF              ;.MESS 072.,-100.,GRN,<NO>,ROP

MES153:
LE489:  .byte $59, $45, $D3         ;.MESS 072.,-100.,GRN,<YES>

MES154:
LE48C:  .byte $4E, $CF              ;.MESS 072.,-150.,GRN,<NO>,TER

MES155:
LE48E:  .byte $59, $45, $D3         ;.MESS 072.,-150.,GRN,<YES>

MES156:
LE491:  .byte $4E, $4F, $20, $45, $52, $52, $4F, $52 ;.MESS 178.,-150.,RED,<NO ERRORS>,GNV
LE499:  .byte $D3

MES157:
LE49A:  .byte $45, $52, $52, $4F, $52, $20, $41, $D4 ;.MESS 178.,-150.,RED,<ERROR AT>,BNV

MES158:
LE4A2:  .byte $53, $57, $49, $54, $43, $48, $20, $54 ;.MESS -128.,400.,WHT,<SWITCH TEST>,SWT
LE4AA:  .byte $45, $53, $D4

MES159:
LE4AD:  .byte $4C, $45, $46, $54, $20, $46, $49, $52 ;.MESS -300.,300.,GRN,<LEFT FIRE>
LE4B5:  .byte $C5

MES160:
LE4B6:  .byte $52, $49, $47, $48, $54, $20, $46, $49 ;.MESS 100.,300.,GRN,<RIGHT FIRE>
LE4BE:  .byte $52, $C5

MES161:
LE4C0:  .byte $53, $50, $41, $52, $45, $20, $B1 ;.MESS -080.,-150.,GRN,<SPARE 1>

MES162:
LE4C7:  .byte $53, $45, $4C, $46, $20, $54, $45, $53 ;.MESS -104.,200.,GRN,<SELF TEST>
LE4CF:  .byte $D4

MES163:
LE4D0:  .byte $53, $4C, $41, $CD    ;.MESS -044.,150.,GRN,<SLAM>

MES164:
LE4D4:  .byte $41, $55, $58, $20, $43, $4F, $49, $CE ;.MESS -092.,100.,GRN,<AUX COIN>

MES165:
LE4DC:  .byte $4C, $45, $46, $54, $20, $43, $4F, $49 ;.MESS -104.,050.,GRN,<LEFT COIN>
LE4E4:  .byte $CE

MES166:
LE4E5:  .byte $52, $49, $47, $48, $54, $20, $43, $4F ;.MESS -116.,-000.,GRN,<RIGHT COIN>
LE4ED:  .byte $49, $CE

MES167:
MES168:
LE4EF:  .byte $A0                   ;.MESS -104.,-100.,GRN,< >

MES169:
LE4F0:  .byte $4C, $45, $46, $54, $20, $54, $48, $55 ;.MESS -324.,250.,GRN,<LEFT THUMB>
LE4F8:  .byte $4D, $C2

MES170:
LE4FA:  .byte $52, $49, $47, $48, $54, $20, $54, $48 ;.MESS 100.,250.,GRN,<RIGHT THUMB>
LE502:  .byte $55, $4D, $C2

MES171:
LE505:  .byte $53, $50, $41, $52, $45, $20, $B2 ;.MESS -080.,-200.,GRN,<SPARE 2>

MES172:
MES173:
MES174:
LE50C:  .byte $A0                   ;.MESS -068.,-300.,GRN,< >

MES175:
LE50D:  .byte $50, $4F, $54, $20, $54, $45, $53, $D4 ;.MESS 228.,210.,WHT,<POT TEST>,POT

MES176:
LE515:  .byte $48, $41, $52, $44, $57, $41, $52, $45 ;.MESS -176.,450.,WHT,<HARDWARE ERRORS>,RAM
LE51D:  .byte $20, $45, $52, $52, $4F, $52, $D3

MES177:
LE524:  .byte $4E, $4F, $20, $45, $52, $52, $4F, $52 ;.MESS -212.,000.,WHT,<NO ERRORS DETECTED>
LE52C:  .byte $53, $20, $44, $45, $54, $45, $43, $54
LE534:  .byte $45, $C4

MES178:
LE536:  .byte $50, $52, $4F, $47, $52, $41, $4D, $20 ;.MESS -200.,400.,GRN,<PROGRAM RAM AT 2FH>
LE53E:  .byte $52, $41, $4D, $20, $41, $54, $20, $32
LE546:  .byte $46, $C8

MES179:
LE548:  .byte $4D, $41, $54, $48, $20, $52, $41, $4D ;.MESS -164.,350.,GRN,<MATH RAM AT 5F>
LE550:  .byte $20, $41, $54, $20, $35, $C6

MES180:
LE556:  .byte $4D, $41, $54, $48, $20, $52, $41, $4D ;.MESS -164.,300.,GRN,<MATH RAM AT 5H>
LE55E:  .byte $20, $41, $54, $20, $35, $C8

MES181:
LE564:  .byte $56, $47, $20, $52, $41, $4D, $30, $20 ;.MESS -140.,250.,GRN,<VG RAM0 AT 3L>
LE56C:  .byte $41, $54, $20, $33, $CC

MES182:
LE571:  .byte $56, $47, $20, $52, $41, $4D, $31, $20 ;.MESS -140.,200.,GRN,<VG RAM1 AT 3M>
LE579:  .byte $41, $54, $20, $33, $CD

MES183:
LE57E:  .byte $56, $47, $20, $52, $41, $4D, $32, $20 ;.MESS -140.,150.,GRN,<VG RAM2 AT 3P>
LE586:  .byte $41, $54, $20, $33, $D0

MES184:
LE58B:  .byte $56, $47, $20, $52, $41, $4D, $33, $20 ;.MESS -140.,100.,GRN,<VG RAM3 AT 4L>
LE593:  .byte $41, $54, $20, $34, $CC

MES185:
LE598:  .byte $56, $47, $20, $52, $41, $4D, $34, $20 ;.MESS -140.,050.,GRN,<VG RAM4 AT 4M>
LE5A0:  .byte $41, $54, $20, $34, $CD

MES186:
LE5A5:  .byte $56, $47, $20, $52, $41, $4D, $35, $20 ;.MESS -140.,000.,GRN,<VG RAM5 AT 4P>
LE5AD:  .byte $41, $54, $20, $34, $D0

MES187:
LE5B2:  .byte $4E, $4F, $4E, $20, $56, $4F, $4C, $41 ;.MESS -260.,-050.,GRN,<NON VOLATILE RAM AT 1E>
LE5BA:  .byte $54, $49, $4C, $45, $20, $52, $41, $4D
LE5C2:  .byte $20, $41, $54, $20, $31, $C5

MES188:
LE5C8:  .byte $50, $52, $4F, $47, $52, $41, $4D, $20 ;.MESS -200.,-200.,GRN,<PROGRAM ROM0 AT 1F>
LE5D0:  .byte $52, $4F, $4D, $30, $20, $41, $54, $20
LE5D8:  .byte $31, $C6

MES189:
LE5DA:  .byte $50, $52, $4F, $47, $52, $41, $4D, $20 ;.MESS -200.,-250.,GRN,<PROGRAM ROM1 AT 1HJ>
LE5E2:  .byte $52, $4F, $4D, $31, $20, $41, $54, $20
LE5EA:  .byte $31, $48, $CA

MES190:
LE5ED:  .byte $50, $52, $4F, $47, $52, $41, $4D, $20 ;.MESS -200.,-300.,GRN,<PROGRAM ROM2 AT 1JK>
LE5F5:  .byte $52, $4F, $4D, $32, $20, $41, $54, $20
LE5FD:  .byte $31, $4A, $CB

MES191:
LE600:  .byte $50, $52, $4F, $47, $52, $41, $4D, $20 ;.MESS -200.,-350.,GRN,<PROGRAM ROM3 AT 1KL>
LE608:  .byte $52, $4F, $4D, $33, $20, $41, $54, $20
LE610:  .byte $31, $4B, $CC

MES192:
LE613:  .byte $50, $52, $4F, $47, $52, $41, $4D, $20 ;.MESS -200.,-400.,GRN,<PROGRAM ROM4 AT 1M>
LE61B:  .byte $52, $4F, $4D, $34, $20, $41, $54, $20
LE623:  .byte $31, $CD

MES193:
LE625:  .byte $56, $47, $20, $52, $4F, $4D, $20, $41 ;.MESS -140.,-150.,GRN,<VG ROM AT 1L>
LE62D:  .byte $54, $20, $31, $CC

MES194:
LE631:  .byte $4D, $41, $54, $48, $42, $4F, $58, $20 ;.MESS -152.,400.,WHT,<MATHBOX TESTS>,MBT
LE639:  .byte $54, $45, $53, $54, $D3

MES195:
LE63E:  .byte $42, $41, $44, $20, $4D, $41, $54, $48 ;.MESS -260.,200.,WHT,<BAD MATHBOX READY LINE>,MBN
LE646:  .byte $42, $4F, $58, $20, $52, $45, $41, $44
LE64E:  .byte $59, $20, $4C, $49, $4E, $C5

MES196:
LE654:  .byte $44, $49, $56, $49, $44, $45, $52, $20 ;.MESS -164.,350.,WHT,<DIVIDER ERRORS>,DIV
LE65C:  .byte $45, $52, $52, $4F, $52, $D3

MES197:
LE662:  .byte $4E, $4F, $20, $44, $49, $56, $49, $44 ;.MESS -200.,200.,WHT,<NO DIVIDER ERRORS>
LE66A:  .byte $45, $52, $20, $45, $52, $52, $4F, $52
LE672:  .byte $D3

MES198:
LE673:  .byte $4F, $50, $54, $20, $53, $57, $20, $20 ;.MESS -360.,275.,WHT,<OPT SW NUM DIV DEN IS ERROR>
LE67B:  .byte $20, $20, $4E, $55, $4D, $20, $44, $49
LE683:  .byte $56, $20, $44, $45, $4E, $20, $49, $53
LE68B:  .byte $20, $45, $52, $52, $4F, $D2

MES199:
LE691:  .byte $4D, $41, $54, $52, $49, $58, $20, $45 ;.MESS -152.,-100.,WHT,<MATRIX ERRORS>,MTX
LE699:  .byte $52, $52, $4F, $52, $D3

MES200:
LE69E:  .byte $4E, $4F, $20, $4D, $41, $54, $52, $49 ;.MESS -188.,-300.,WHT,<NO MATRIX ERRORS>
LE6A6:  .byte $58, $20, $45, $52, $52, $4F, $52, $D3

MES201:
LE6AE:  .byte $42, $49, $50, $20, $54, $45, $53, $D4 ;.MESS -092.,100.,WHT,<BIP TEST>,BIP

MES202:
LE6B6:  .byte $41, $4C, $49, $47, $4E, $20, $54, $48 ;.MESS -176.,-100.,WHT,<ALIGN THE BOXES>
LE6BE:  .byte $45, $20, $42, $4F, $58, $45, $D3

MES203:
LE6C5:  .byte $53, $43, $41, $4C, $45, $20, $54, $45 ;.MESS -116.,250.,WHT,<SCALE TEST>,SCL
LE6CD:  .byte $53, $D4

MES204:
LE6CF:  .byte $4C, $49, $4E, $45, $41, $D2 ;.MESS -068.,190.,WHT,<LINEAR>

MES205:
LE6D5:  .byte $4C, $49, $4E, $45, $41, $52, $20, $41 ;.MESS -200.,190.,WHT,<LINEAR AND BINARY>
LE6DD:  .byte $4E, $44, $20, $42, $49, $4E, $41, $52
LE6E5:  .byte $D9

MES206:
LE6E6:  .byte $30, $2E, $20, $4F, $46, $C6 ;.MESS -100.,-200.,<WHT&0FF00!00>,<0. OFF>,INT

MES207:
LE6EC:  .byte $31, $2E, $20, $44, $49, $CD ;.MESS -100.,-250.,<WHT&0FF00!10>,<1. DIM>

MES208:
LE6F2:  .byte $32, $2E, $20, $4C, $4F, $D7 ;.MESS -100.,-300.,<WHT&0FF00!20>,<2. LOW>

MES209:
LE6F8:  .byte $33, $2E, $20, $48, $49, $47, $C8 ;.MESS -100.,-350.,<WHT&0FF00!80>,<3. HIGH>

MES210:
LE6FF:  .byte $49, $4E, $54, $45, $4E, $53, $49, $54 ;.MESS -164.,300.,WHT,<INTENSITY TEST>
LE707:  .byte $59, $20, $54, $45, $53, $D4

MES211:
LE70D:  .byte $50, $52, $45, $53, $53, $20, $41, $55 ;.MESS -308.,-450.,WHT,<PRESS AUX COIN TO CONTINUE>,XIT
LE715:  .byte $58, $20, $43, $4F, $49, $4E, $20, $54
LE71D:  .byte $4F, $20, $43, $4F, $4E, $54, $49, $4E
LE725:  .byte $55, $C5

MES212:
LE727:  .byte $50, $52, $45, $53, $53, $20, $41, $55 ;.MESS -332.,-450.,WHT,<PRESS AUX COIN FOR SELF TEST>,TST
LE72F:  .byte $58, $20, $43, $4F, $49, $4E, $20, $46
LE737:  .byte $4F, $52, $20, $53, $45, $4C, $46, $20
LE73F:  .byte $54, $45, $53, $D4

HERE:
MES213:
LE743:  .byte $50, $55, $4C, $4C, $20, $52, $49, $47 ;.MESS -392.,-250.,VJMFL,<PULL RIGHT FIRE TO PERFORM RESETS>,RES
LE74B:  .byte $48, $54, $20, $46, $49, $52, $45, $20
LE753:  .byte $54, $4F, $20, $50, $45, $52, $46, $4F
LE75B:  .byte $52, $4D, $20, $52, $45, $53, $45, $54
LE763:  .byte $D3

;------------------------------------------------------------------------------
; VW8DIG - VW8DIG,VW6DIG,VWBYTE,VWNIBL
;   VIEW 87,654,321
;   (also: MES214)
;------------------------------------------------------------------------------
VW8DIG:
MES214:
LE764:  LDA  ,X                     ;GET 8 AND 7
LE766:  JSR  VWBYTE
LE769:  LDA  BT_SUP
LE76B:  BGT  VW6DIG                 ;IFLE  ?ENCOUNTERED A DIGIT?
LE76D:  LDD  #VJNUMS                ;THEN SEPARATE NUMERALS WITH COMMAS
LE770:  STD  ,Y++

;------------------------------------------------------------------------------
; VW6DIG - VIEW 654,321
;   FALL THRU TO DO OTHER 6 DIGITS
;------------------------------------------------------------------------------
VW6DIG:
LE772:  LDA  1,X                    ;SHOW 65
LE774:  JSR  VWBYTE
LE777:  LDA  2,X                    ;SHOW 4,
LE779:  LSRA
LE77A:  LSRA
LE77B:  LSRA
LE77C:  LSRA
LE77D:  JSR  VWNIBL
LE780:  LDA  BT_SUP
LE782:  BGT  LE789                  ;IFLE  ?HAVE SOME DIGITS TO SEPARATE?
LE784:  LDD  #VJNUMS
LE787:  STD  ,Y++
LE789:  LDA  2,X                    ;VIEW 3
LE78B:  JSR  VWNIBL
LE78E:  LDA  3,X                    ;VIEW 21

;------------------------------------------------------------------------------
; VWBYTE - VIEW BOTH NUMERALS IN BYTE
;   FALL THRU TO VWBYTE
;------------------------------------------------------------------------------
VWBYTE:
LE790:  TFR  A,B
LE792:  LSRB                        ;DO HI BYTE
LE793:  LSRB
LE794:  LSRB
LE795:  ANDB #$1E
LE797:  BNE  LE7A2                  ;IFEQ  ?IS IT A ZERO?
LE799:  TST  BT_SUP
LE79B:  BLE  LE7A2                  ;IFGT  ?AND SUPPRESSION STILL ON?
LE79D:  LDU  VGMSGA                 ;THEN GET A BLANK
LE7A0:  BRA  VWBYTE_20
LE7A2:  CLR  BT_SUP                 ;ELSE IS SIGNIFICANT DIGIT--STOP ZERO SUPPRESSION
LE7A4:  LDU  #VGMSGA+2
LE7A7:  LDU  B,U

VWBYTE_20:       ;---OUTPUT SELECTED NUMERAL
LE7A9:  DEC  BT_SUP                 ;DECREASE NUMBER OF SUPPRESSED DIGITS
LE7AB:  STU  ,Y++

;------------------------------------------------------------------------------
; VWNIBL - TOMCAT NAME
;   VIEW ONLY LO NUMERAL
;   (also: VWBYT1)
;------------------------------------------------------------------------------
VWNIBL:
VWBYT1:
LE7AD:  LSLA
LE7AE:  ANDA #$1E
LE7B0:  BNE  LE7BB                  ;IFEQ  ?IS IT A ZERO?
LE7B2:  TST  BT_SUP
LE7B4:  BLE  LE7BB                  ;IFGT  ?AND SUPPRESSION STILL ON?
LE7B6:  LDU  VGMSGA                 ;THEN GET A BLANK
LE7B9:  BRA  VWBYT1_40
LE7BB:  CLR  BT_SUP                 ;ELSE IS SIGNIFICANT DIGIT--STOP ZERO SUPPRESSION
LE7BD:  LDU  #VGMSGA+2
LE7C0:  LDU  A,U

VWBYT1_40:       ;---DISPLAY OUR NUMBER
LE7C2:  DEC  BT_SUP                 ;DECREASE NUMBER OF SIGNIFICANT DIGITS
LE7C4:  STU  ,Y++
LE7C6:  RTS

;------------------------------------------------------------------------------
; DOMESS - DOMESS
;------------------------------------------------------------------------------
DOMESS:
LE7C7:  CMPB #MESSZ                 ;LEGAL MESSAGE NUMBER?
LE7C9:  BHS  LE7D2                  ;IFLO  YES, THEN SHOW IT
LE7CB:  STB  >MESNUM                ;PUT IT HERE FOR THE OTHER ROUTINES
LE7CE:  BSR  MCOLR                  ;LOOKUP AND OUTPUT COLOR INSTRUCTION TO VG
LE7D0:  BSR  MOUT                   ;POSITION AND OUTPUT CHARACTERS
LE7D2:  RTS

;------------------------------------------------------------------------------
; DOMES2 - OUTPUT OPTION MESSAGE IN HILITE  (comment at the call)
;   COLOR MUST BE ALREADY SET UP  (another call)
;------------------------------------------------------------------------------
DOMES2:
LE7D3:  CMPB #MESSZ                 ;LEGAL MESSAGE NUMBER?
LE7D5:  BHS  LE7DC                  ;IFLO  YES, THEN SHOW IT
LE7D7:  STB  >MESNUM                ;PUT IT HERE FOR THE OTHER ROUTINES
LE7DA:  BSR  MOUT                   ;POSITION AND OUTPUT CHARACTERS
LE7DC:  RTS

;------------------------------------------------------------------------------
; MCOLR - MESS PARTS
;------------------------------------------------------------------------------
MCOLR:
LE7DD:  LDB  >MESNUM
LE7E0:  LDX  #TMESCL                ;TABLE OF MESSAGE COLORS
LE7E3:  ABX                         ;INDEX INTO WORD TABLE
LE7E4:  ABX
LE7E5:  LDD  ,X                     ;GET THE COLOR COMMAND
LE7E7:  STD  ,Y++                   ;PUT IT IN VG RAM
LE7E9:  RTS

;------------------------------------------------------------------------------
; MOUT - POSITION AND OUTPUT CHARACTERS  (comment at the calls)
;------------------------------------------------------------------------------
MOUT:
LE7EA:  LDB  >MESNUM
LE7ED:  LDX  #TMESXY                ;MESSAGE POSITION TABLE
LE7F0:  ABX                         ;*4 FOR 2-WORD ENTRIES
LE7F1:  ABX
LE7F2:  ABX
LE7F3:  ABX
LE7F4:  LDD  2,X                    ;DELTA Y FROM CENTER
LE7F6:  STD  ,Y++
LE7F8:  LDD  ,X                     ;DELTA X FROM CENTER
LE7FA:  BRA  MOUTXT                 ;GO TO MOUT EXIT

;------------------------------------------------------------------------------
; MOUT2 - USES Y OFFSET FOR SCROLLING
;------------------------------------------------------------------------------
MOUT2:
LE7FC:  LDB  >MESNUM
LE7FF:  LDX  #TMESXY                ;MESSAGE POSITION TABLE
LE802:  ABX                         ;*4 FOR 2-WORD ENTRIES
LE803:  ABX
LE804:  ABX
LE805:  ABX
LE806:  LDD  2,X                    ;DELTA Y FROM CENTER
LE808:  SUBD >MSYOFF                ;SUBTRACT OFFSET FOR SCROLLING
LE80B:  ANDA #$1F
LE80D:  STD  ,Y++
LE80F:  LDD  ,X                     ;DELTA X FROM CENTER

MOUTXT:
LE811:  STD  ,Y++
LE813:  JSR  MESOUT                 ;NOW PUT OUT THE CHARACTERS
LE816:  LDD  #VGSCAL                ;SET TO NORMAL SCALE
LE819:  STD  ,Y++
LE81B:  LDD  #VGCNTR                ;CENTER AFTER MESSAGE
LE81E:  STD  ,Y++
LE820:  RTS

;------------------------------------------------------------------------------
; MESOUT - MESOUT
;------------------------------------------------------------------------------
MESOUT:
LE821:  LDX  #TMESS                 ;MESSAGE ADDRESS TABLE
LE824:  LDB  >MESNUM                ;MESSAGE NUMBER
LE827:  ABX                         ;INDEX INTO WORD TABLE
LE828:  ABX                         ;UNSIGNED ADD
LE829:  LDX  ,X                     ;X NOW POINTS TO FIRST CHARACTER IN MESSAGE
LE82B:  LDB  ,X+                    ;GET CHARACTER
LE82D:  STX  >MESPNT                ;SAVE UPDATED POINTER
LE830:  ASLB                        ;*2 BECAUSE VGMSGA IS WORD TABLE
LE831:  CMPB #$82                   ;ASCII 'A' *2
LE833:  BLO  LE83C                  ;IFHS  ALPHA
LE835:  LDX  #VGMSGA+$16-2
LE838:  ANDB #$7F
LE83A:  BRA  LE888                  ;ELSE  NOT ALPHA
;CHECK FOR THOSE CHARACTERS BELOW ALPHA AND ABOVE NUMERIC
LE83C:  CMPB #$74
LE83E:  BNE  LE845                  ;IFEQ  ":"
LE840:  LDX  #VGMSGA+$50-$74
LE843:  BRA  LE888                  ;ELSE
LE845:  CMPB #$80
LE847:  BNE  LE84F                  ;IFEQ  "@" FOR CIRCLE C
LE849:  LDX  #VGMSGA+$56
LE84C:  CLRB
LE84D:  BRA  LE888                  ;ELSE
LE84F:  CMPB #$60                   ;ASCII '0' *2
LE851:  BLO  LE858                  ;IFHS  MUST BE NUMERIC
LE853:  LDX  #VGMSGA+2-$60
LE856:  BRA  LE888                  ;ELSE  CHECK FOR CHARACTERS BELOW NUMERIC
LE858:  CMPB #$40
LE85A:  BNE  LE861                  ;IFEQ  SPACE
LE85C:  LDX  #VGMSGA-$40
LE85F:  BRA  LE888                  ;ELSE
LE861:  CMPB #$4E
LE863:  BNE  LE86A                  ;IFEQ  APOSTROPHE
LE865:  LDX  #VGMSGA+$4A-$4E
LE868:  BRA  LE888                  ;ELSE
;CMPB #50
;IFEQ ;LEFT PAREN
;LDX #VGMSGA+58-50
;ELSE
;CMPB #52
;IFEQ ;RIGHT PAREN
;LDX #VGMSGA+5A-52
;ELSE
LE86A:  CMPB #$58
LE86C:  BNE  LE873                  ;IFEQ  COMMA
LE86E:  LDX  #VGMSGA+$4C-$58
LE871:  BRA  LE888                  ;ELSE
LE873:  CMPB #$5A
LE875:  BNE  LE87C                  ;IFEQ  HYPHEN
LE877:  LDX  #VGMSGA+$58-$5A
LE87A:  BRA  LE888                  ;ELSE
LE87C:  CMPB #$4A                   ;"%" FOR 1/2
LE87E:  BNE  LE885                  ;IFEQ
LE880:  LDX  #VGMSGA+$54-$4A
LE883:  BRA  LE888                  ;ELSE  MUST BE PERIOD
LE885:  LDX  #VGMSGA+$4E-$5C
LE888:  LDD  B,X                    ;SHOULD BE JSRL TO APROPRIATE LETTER ROUTINE
LE88A:  STD  ,Y++
LE88C:  LDX  >MESPNT                ;RESTORE X
LE88F:  TST  -$1,X                  ;DONE
LE891:  BPL  LE82B                  ;MIEND
LE893:  RTS

TMESS:           ;REGULAR GAME PLAY MESSAGES POINTERS
LE894:  .word MES0                  ;.REPT MESSZ
LE896:  .word MES1
LE898:  .word MES2
LE89A:  .word MES3
LE89C:  .word MES4
LE89E:  .word MES5
LE8A0:  .word MES6
LE8A2:  .word MES7
LE8A4:  .word MES8
LE8A6:  .word MES9
LE8A8:  .word MES10
LE8AA:  .word MES11
LE8AC:  .word MES12
LE8AE:  .word MES13
LE8B0:  .word MES14
LE8B2:  .word MES15
LE8B4:  .word MES16
LE8B6:  .word MES17
LE8B8:  .word MES18
LE8BA:  .word MES19
LE8BC:  .word MES20
LE8BE:  .word MES21
LE8C0:  .word MES22
LE8C2:  .word MES23
LE8C4:  .word MES24
LE8C6:  .word MES25
LE8C8:  .word MES26
LE8CA:  .word MES27
LE8CC:  .word MES28
LE8CE:  .word MES29
LE8D0:  .word MES30
LE8D2:  .word MES31
LE8D4:  .word MES32
LE8D6:  .word MES33
LE8D8:  .word MES34
LE8DA:  .word MES35
LE8DC:  .word MES36
LE8DE:  .word MES37
LE8E0:  .word MES38
LE8E2:  .word MES39
LE8E4:  .word MES40
LE8E6:  .word MES41
LE8E8:  .word MES42
LE8EA:  .word MES43
LE8EC:  .word MES44
LE8EE:  .word MES45
LE8F0:  .word MES46
LE8F2:  .word MES47
LE8F4:  .word MES48
LE8F6:  .word MES49
LE8F8:  .word MES50
LE8FA:  .word MES51
LE8FC:  .word MES52
LE8FE:  .word MES53
LE900:  .word MES54
LE902:  .word MES55
LE904:  .word MES56
LE906:  .word MES57
LE908:  .word MES58
LE90A:  .word MES59
LE90C:  .word MES60
LE90E:  .word MES61
LE910:  .word MES62
LE912:  .word MES63
LE914:  .word MES64
LE916:  .word MES65
LE918:  .word MES66
LE91A:  .word MES67
LE91C:  .word MES68
LE91E:  .word MES69
LE920:  .word MES70
LE922:  .word MES71
LE924:  .word MES72
LE926:  .word MES73
LE928:  .word MES74
LE92A:  .word MES75
LE92C:  .word MES76
LE92E:  .word MES77
LE930:  .word MES78
LE932:  .word MES79
LE934:  .word MES80
LE936:  .word MES81
LE938:  .word MES82
LE93A:  .word MES83
LE93C:  .word MES84
LE93E:  .word MES85
LE940:  .word MES86
LE942:  .word MES87
LE944:  .word MES88
LE946:  .word MES89
LE948:  .word MES90
LE94A:  .word MES91
LE94C:  .word MES92
LE94E:  .word MES93
LE950:  .word MES94
LE952:  .word MES95
LE954:  .word MES96
LE956:  .word MES97
LE958:  .word MES98
LE95A:  .word MES99
LE95C:  .word MES100
LE95E:  .word MES101
LE960:  .word MES102
LE962:  .word MES103
LE964:  .word MES104
LE966:  .word MES105
LE968:  .word MES106
LE96A:  .word MES107
LE96C:  .word MES108
LE96E:  .word MES109
LE970:  .word MES110
LE972:  .word MES111
LE974:  .word MES112
LE976:  .word MES113
LE978:  .word MES114
LE97A:  .word MES115
LE97C:  .word MES116
LE97E:  .word MES117
LE980:  .word MES118
LE982:  .word MES119
LE984:  .word MES120
LE986:  .word MES121
LE988:  .word MES122
LE98A:  .word MES123
LE98C:  .word MES124
LE98E:  .word MES125
LE990:  .word MES126
LE992:  .word MES127
LE994:  .word MES128
LE996:  .word MES129
LE998:  .word MES130
LE99A:  .word MES131
LE99C:  .word MES132
LE99E:  .word MES133
LE9A0:  .word MES134
LE9A2:  .word MES135
LE9A4:  .word MES136
LE9A6:  .word MES137
LE9A8:  .word MES138
LE9AA:  .word MES139
LE9AC:  .word MES140
LE9AE:  .word MES141
LE9B0:  .word MES142
LE9B2:  .word MES143
LE9B4:  .word MES144
LE9B6:  .word MES145
LE9B8:  .word MES146
LE9BA:  .word MES147
LE9BC:  .word MES148
LE9BE:  .word MES149
LE9C0:  .word MES150
LE9C2:  .word MES151
LE9C4:  .word MES152
LE9C6:  .word MES153
LE9C8:  .word MES154
LE9CA:  .word MES155
LE9CC:  .word MES156
LE9CE:  .word MES157
LE9D0:  .word MES158
LE9D2:  .word MES159
LE9D4:  .word MES160
LE9D6:  .word MES161
LE9D8:  .word MES162
LE9DA:  .word MES163
LE9DC:  .word MES164
LE9DE:  .word MES165
LE9E0:  .word MES166
LE9E2:  .word MES167
LE9E4:  .word MES168
LE9E6:  .word MES169
LE9E8:  .word MES170
LE9EA:  .word MES171
LE9EC:  .word MES172
LE9EE:  .word MES173
LE9F0:  .word MES174
LE9F2:  .word MES175
LE9F4:  .word MES176
LE9F6:  .word MES177
LE9F8:  .word MES178
LE9FA:  .word MES179
LE9FC:  .word MES180
LE9FE:  .word MES181
LEA00:  .word MES182
LEA02:  .word MES183
LEA04:  .word MES184
LEA06:  .word MES185
LEA08:  .word MES186
LEA0A:  .word MES187
LEA0C:  .word MES188
LEA0E:  .word MES189
LEA10:  .word MES190
LEA12:  .word MES191
LEA14:  .word MES192
LEA16:  .word MES193
LEA18:  .word MES194
LEA1A:  .word MES195
LEA1C:  .word MES196
LEA1E:  .word MES197
LEA20:  .word MES198
LEA22:  .word MES199
LEA24:  .word MES200
LEA26:  .word MES201
LEA28:  .word MES202
LEA2A:  .word MES203
LEA2C:  .word MES204
LEA2E:  .word MES205
LEA30:  .word MES206
LEA32:  .word MES207
LEA34:  .word MES208
LEA36:  .word MES209
LEA38:  .word MES210
LEA3A:  .word MES211
LEA3C:  .word MES212
LEA3E:  .word MES213

TSPMX:           ;SPECIAL MESSAGE POINTERS
LEA40:  .word (-(MES82-MES81)*12)+4 ;.REPT SPMSZ-SPMS1
LEA42:  .word (-(MES83-MES82)*12)+4
LEA44:  .word (-(MES84-MES83)*12)+4
LEA46:  .word (-(MES85-MES84)*12)+4
LEA48:  .word (-(MES86-MES85)*12)+4
LEA4A:  .word (-(MES87-MES86)*12)+4
LEA4C:  .word (-(MES88-MES87)*12)+4
LEA4E:  .word (-(MES89-MES88)*12)+4

;.SBTTL MESSAGES

TMESXY:          ;X,Y POSITIONS FOR MESSAGES
LEA50:  .word $1F98, $1E5C          ;.MESS -104.,-420.,GRN,<STAR WARS>,CPY
LEA54:  .word $1E6C, $1E38          ;.MESS -404.,-456.,GRN,<@ 1983 LUCASFILM LTD. AND ATARI,INC.>
LEA58:  .word $1F20, $1E14          ;.MESS -224.,-492.,GRN,<ALL RIGHTS RESERVED.>
LEA5C:  .word $1E30, $1DF0          ;.MESS -464.,-528.,GRN,<LUCASFILM TRADEMARKS USED UNDER LICENSE.>,CPZ
LEA60:  .word $1F98, $0000          ;.NEXTMESS -104.,000.,RED!0FF,GO1
LEA64:  .word $1F98, $01E0          ;.MESS -104.,0480.,TRQ,<GAME OVER>,GVR
LEA68:  .word $1F74, $01E0          ;.MESS -140.,0480.,BLU,<INSERT COINS>,INS
LEA6C:  .word $1F98, $01B0          ;.MESS -104.,0432.,YLW,<FREE PLAY>,FRE
LEA70:  .word $1F5C, $01B0          ;.MESS -164.,0432.,YLW,<2 PLAYS 1 COIN>,2PC
LEA74:  .word $1F68, $01B0          ;.MESS -152.,0432.,YLW,<1 COIN 1 PLAY>,1CP
LEA78:  .word $1F5C, $01B0          ;.MESS -164.,0432.,YLW,<2 COINS 1 PLAY>,2CP
;.MESS -164.,0400.,YLW,<2 COIN MINIMUM>,2CM
LEA7C:  .word $1F08, $01E0          ;.MESS -248.,0480.,VJMFL,<PULL TRIGGER TO START>,STR
LEA80:  .word $1FC4, $01B0          ;.MESS -060.,0432.,WHT,<CREDITS>,CRD
LEA84:  .word $1FC4, $01B0          ;.MESS -060.,0432.,WHT,<CREDIT>
LEA88:  .word $1F8C, $00E6          ;.MESS -116.,460./2,VJMFL,<SHIELD GONE>,SHG
LEA8C:  .word $1E74, $0120          ;.MESS -396.,0288.,RED,<FLIGHT INSTRUCTIONS TO RED FIVE>,FLI
LEA90:  .word $1E44, $00D8          ;.MESS -444.,0216.,RED,<1. YOUR X-WING IS EQUIPPED WITH AN>
LEA94:  .word $1E5C, $00B4          ;.MESS -420.,0180.,RED,<INVISIBLE DEFLECTOR SHIELD THAT>
LEA98:  .word $1E5C, $0090          ;.MESS -420.,0144.,RED,<WILL PROTECT YOU FOR COLLISIONS.>
LEA9C:  .word $1E44, $0048          ;.MESS -444.,0072.,RED,<2. DEFLECTOR STRENGTH IS LOST WHEN>
LEAA0:  .word $1E5C, $0024          ;.MESS -420.,0036.,RED,<A FIREBALL IMPACTS YOUR SHIELD OR>
LEAA4:  .word $1E5C, $0000          ;.MESS -420.,0000.,RED,<WHEN YOU STRIKE A LASER TOWER OR>
LEAA8:  .word $1E5C, $1FDC          ;.MESS -420.,-036.,RED,<TRENCH CATWALK.>
LEAAC:  .word $1E44, $1F94          ;.MESS -444.,-108.,RED,<3. AIM YOUR LASERS WITH CURSOR TO>
LEAB0:  .word $1E5C, $1F70          ;.MESS -420.,-144.,RED,<EXPLODE EMPIRE TIE FIGHTERS, LASER>
LEAB4:  .word $1E5C, $1F4C          ;.MESS -420.,-180.,RED,<TOWER TOPS AND TRENCH TURRETS.>
LEAB8:  .word $1E44, $1F04          ;.MESS -444.,-252.,RED,<4. SHOOT FIREBALLS BEFORE THEY>
LEABC:  .word $1E5C, $1EE0          ;.MESS -420.,-288.,RED,<IMPACT YOUR SHIELD.>
LEAC0:  .word $1E44, $1E98          ;.MESS -444.,-360.,RED,<5. THE REBEL FORCE IS DEPENDING ON>
LEAC4:  .word $1E5C, $1E74          ;.MESS -420.,-396.,RED,<YOU TO STOP THE EMPIRE BY BLOWING>
LEAC8:  .word $1E5C, $1E50          ;.MESS -420.,-432.,RED,<UP THE DEATH STAR.>,FLZ
LEACC:  .word $0054, $0090          ;.MESS 0084.,0144.,RED,<6>
LEAD0:  .word $0054, $0090          ;.MESS 0084.,0144.,RED,<7>
LEAD4:  .word $0054, $0090          ;.MESS 0084.,0144.,RED,<8>
LEAD8:  .word $0054, $0090          ;.MESS 0084.,0144.,RED,<9>
LEADC:  .word $1FC4, $0118          ;.MESS -060.,0280.,PRP,<SCORING>,SCR
LEAE0:  .word $1E8C, $00B4          ;.MESS -372.,0180.,PRP,<TIE FIGHTERS 1,000>,SC1
LEAE4:  .word $1E8C, $0078          ;.MESS -372.,0120.,PRP,<DARTH VADER'S SHIP 2,000>
LEAE8:  .word $1E8C, $003C          ;.MESS -372.,0060.,PRP,<LASER BUNKERS 200>
LEAEC:  .word $1E8C, $0000          ;.MESS -372.,0000.,PRP,<LASER TOWERS 200>
LEAF0:  .word $1E8C, $1FC4          ;.MESS -372.,-060.,PRP,<TRENCH TURRETS 100>
LEAF4:  .word $1E8C, $1F88          ;.MESS -372.,-120.,PRP,<FIREBALLS 33>
LEAF8:  .word $1E8C, $1EE8          ;.MESS -372.,-280.,PRP,<EXHAUST PORT 25,000>
LEAFC:  .word $1E8C, $1EA2          ;.MESS -372.,-350.,PRP,<DESTROYING ALL TOWER TOPS 50,000>,SCZ
LEB00:  .word $1F20, $0154          ;.MESS -224.,0340.,PRP,<SELECT A DEATH STAR>,DS1
LEB04:  .word $1E84, $012C          ;.MESS -380.,0300.,PRP,<FIRE LASER AT DESIRED DEATH STAR>
LEB08:  .word $1F98, $0104          ;.MESS -104.,0260.,VJMFL,<COUNTDOWN>
LEB0C:  .word $1ED4, $0020          ;.MESS -300.,0032.,GRN,<EASY>
LEB10:  .word $1FBC, $1F38          ;.MESS -068.,-200.,GRN,<MEDIUM>
LEB14:  .word $00E0, $0020          ;.MESS 0224.,0032.,GRN,<HARD>
LEB18:  .word $1E2C, $00C8          ;.MESS -468.,0200.,RED,<WAVE 1>
LEB1C:  .word $1FBC, $1F60          ;.MESS -068.,-160.,RED,<WAVE 3>
LEB20:  .word $014C, $00C8          ;.MESS 0332.,0200.,RED,<WAVE 5>
;.NEXTMESS -256.,-200.,BLU
LEB24:  .word $1FC8, $1E70          ;.NEXTMESS -056.,-400.,BLU
;.NEXTMESS 0144.,-200.,BLU
LEB28:  .word $0158, $0000          ;.MESS 0344.,0000.,BLU,<BONUS>
LEB2C:  .word $1E14, $0000          ;.MESS -492.,0000.,BLU,<NO BONUS>
;.MESS -280.,-240.,RED,<200,000>
LEB30:  .word $1FB0, $1E48          ;.MESS -080.,-440.,RED,<400,000>
;.MESS 0120.,-240.,RED,<600,000>
LEB34:  .word $0140, $1FD8          ;.MESS 0320.,-040.,RED,<800,000>,DSZ
LEB38:  .word $1E90, $0154          ;.MESS -368.,0340.,YLW,<MESSAGE FROM REBEL COMMAND POST>,HS1
LEB3C:  .word $1ECC, $0118          ;.MESS -308.,0280.,PRP,<YOU ARE A TRUE REBEL PILOT>
LEB40:  .word $1F08, $00DC          ;.MESS -248.,0220.,VJMFL,<THE FORCE IS WITH YOU>
LEB44:  .word $1F20, $0078          ;.MESS -224.,0120.,BLU,<SHOOT YOUR INITIALS>,HSZ
LEB48:  .word $1EC0, $0000          ;.NEXTMESS -320.,000.,VJMFL,RF1
LEB4C:  .word $1EC0, $013C          ;.MESS -320.,0316.,RED,<PRINCESS LEIA'S REBEL FORCE>,RF2
LEB50:  .word $1F80, VGRW7&$1FFF    ;.MESS -128.,VGRW7,RED,<POINTS NEXT TOWER>,NXT
LEB54:  .word $013A, $01BC          ;.MESS 0314.,0444.,RED,<TOWERS>,TWR
LEB58:  .word $1EE4, VGRW7&$1FFF    ;.MESS -284.,VGRW7,VJMFL,<CLEARED ALL LASER TOWERS>,ATP
LEB5C:  .word $1E9C, VGRW7&$1FFF    ;.MESS -356.,VGRW7,RED,<50,000 FOR SHOOTING ALL TOWERS>,RWD
LEB60:  .word $1F2C, ((VGRW9/2)-12)&$1FFF ;.MESS -212.,VGRW9/2-12.,VJMFL,<EXHAUST PORT AHEAD>,EXH
LEB64:  .word $1F14, $0138          ;.MESS -236.,0312.,VJMFL,<DEATH STAR DESTROYED>,DSD
LEB68:  .word $1F20, ((VGRW9/2)-12)&$1FFF ;.MESS -224.,VGRW9/2-12.,VJMFL,<EXHAUST PORT MISSED>,MSD
LEB6C:  .word $1ECC, $00C0          ;.MESS -308.,0192.,VJMFL,<BONUS FOR REMAINING ENERGY>,BRE
LEB70:  .word $1F80, $0090          ;.MESS -128.,0144.,VJMFL,<5,000 X>
LEB74:  .word $1EF0, $0048          ;.MESS -272.,0072.,VJMFL,<ADDED TO DEFLECTOR SHIELD>,BSE
LEB78:  .word $1EF0, $0048          ;.MESS -272.,0072.,VJMFL,<SHIELD AT FULL STRENGTH>
LEB7C:  .word $1F20, $1FD0          ;.MESS -224.,-048.,VJMFL,<STARTING WAVE BONUS>,BON
LEB80:  .word $1F50, VGRW7&$1FFF    ;.MESS -176.,VGRW7,WHT,<SHOOT FIREBALLS>,SFB
LEB84:  .word $1F2C, VGRW7&$1FFF    ;.MESS -212.,VGRW7,RED,<SHOOT TIE FIGHTERS>,STF
LEB88:  .word $1F5C, VGRW7&$1FFF    ;.MESS -164.,VGRW7,RED,<AVOID CATWALKS>,ACW
LEB8C:  .word $1F68, VGRW9&$1FFF    ;.MESS -152.,VGRW9,VJMFL,<USE THE FORCE>,USE
LEB90:  .word $0000, $0000          ;.MESS 0000.,0000.,VJMFL,< FOR USING THE FORCE>
LEB94:  .byte $00, $00, $00, $00, $00, $00, $00, $00 ;not assembled by any source statement (ROM fill)
LEB9C:  .byte $00, $00, $00, $00, $00, $00, $00, $00 ;not assembled by any source statement (ROM fill)
LEBA4:  .byte $00, $00, $00, $00, $00, $00, $00, $00 ;not assembled by any source statement (ROM fill)
LEBAC:  .byte $00, $00, $00, $00, $00, $00, $00, $00 ;not assembled by any source statement (ROM fill)
LEBB4:  .word $1EFC, $01E0          ;.MESS -260.,480.,WHT,<ACCOUNTING INFORMATION>,ACC
LEBB8:  .word $1F28, $01B8          ;.MESS -216.,440.,GRN,<AUX COINS>
LEBBC:  .word $1E98, $0190          ;.MESS -360.,400.,GRN,<LEFT MECH COINS>
LEBC0:  .word $1E80, $0168          ;.MESS -384.,360.,GRN,<RIGHT MECH COINS>
LEBC4:  .word $1E80, $0140          ;.MESS -384.,320.,GRN,<TOTAL COINS PAID>
LEBC8:  .word $1EE0, $0118          ;.MESS -288.,280.,GRN,<GAMES PLAYED>
LEBCC:  .word $00FA, $0140          ;.MESS 0250.,320.,GRN,<HIGH WAVE>
LEBD0:  .word $1E98, $00DC          ;.MESS -360.,220.,GRN,<TOTAL GAME TIME SECONDS>
LEBD4:  .word $1E68, $00B4          ;.MESS -408.,180.,GRN,<AVERAGE GAME TIME>
LEBD8:  .word $1EC8, $0078          ;.MESS -312.,120.,GRN,<TOTAL TIME ON SECONDS>
LEBDC:  .word $1E50, $0050          ;.MESS -432.,080.,GRN,<PERCENTAGE OF PLAY PERCENT>
LEBE0:  .word $1F08, $0000          ;.MESS -248.,000.,WHT,<HISTORY OF GAME TIMES>
LEBE4:  .word $1F74, $01F4          ;.MESS -140.,500.,WHT,<GAME OPTIONS>,OPT
LEBE8:  .word $1E98, $01C2          ;.MESS -360.,450.,GRN,<VALUE OF A COIN>
LEBEC:  .word $1E98, $0190          ;.MESS -360.,400.,GRN,<LEFT MECH VALUE>
LEBF0:  .word $1E80, $015E          ;.MESS -384.,350.,GRN,<RIGHT MECH VALUE>
LEBF4:  .word $1EF8, $012C          ;.MESS -264.,300.,GRN,<BONUS ADDER>
LEBF8:  .word $1E98, $00FA          ;.MESS -360.,250.,GRN,<STARTING SHIELD>
LEBFC:  .word $1E98, $00C8          ;.MESS -360.,200.,GRN,<PLAY DIFFICULTY>
LEC00:  .word $1EE0, $0096          ;.MESS -288.,150.,GRN,<BONUS SHIELD>
LEC04:  .word $1E80, $0064          ;.MESS -384.,100.,GRN,<MUSIC IN ATTRACT>
LEC08:  .word $1E68, $0000          ;.MESS -408.,000.,GRN,<RESET HIGH SCORES>
LEC0C:  .word $1E68, $1FCE          ;.MESS -408.,-050.,GRN,<RESET TIMING INFO>
LEC10:  .word $1EC8, $1F9C          ;.MESS -312.,-100.,GRN,<RESET OPTIONS>
LEC14:  .word $1EF8, $1F6A          ;.MESS -264.,-150.,GRN,<TEST NOVRAM>
LEC18:  .word $1EFC, $1ED4          ;.MESS -260.,-300.,GRN,<UP,DOWN TO SELECT ITEM>
LEC1C:  .word $1E90, $1EA2          ;.MESS -368.,-350.,GRN,<PULL LEFT FIRE TO CHANGE SETTING>
LEC20:  .word $0048, $01C2          ;.MESS 072.,450.,GRN,<FREE PLAY>,VLC
LEC24:  .word $0048, $01C2          ;.MESS 072.,450.,GRN,<2 CREDITS>
LEC28:  .word $0048, $01C2          ;.MESS 072.,450.,GRN,<1 CREDIT>
LEC2C:  .word $0048, $01C2          ;.MESS 072.,450.,GRN,<% CREDIT>
LEC30:  .word $0048, $0190          ;.MESS 072.,400.,GRN,<1>,LMV
LEC34:  .word $0048, $0190          ;.MESS 072.,400.,GRN,<2>
LEC38:  .word $0048, $015E          ;.MESS 072.,350.,GRN,<1>,RMV
LEC3C:  .word $0048, $015E          ;.MESS 072.,350.,GRN,<4>
LEC40:  .word $0048, $015E          ;.MESS 072.,350.,GRN,<5>
LEC44:  .word $0048, $015E          ;.MESS 072.,350.,GRN,<6>
LEC48:  .word $0048, $012C          ;.MESS 072.,300.,GRN,<NONE>,BAV
LEC4C:  .word $0048, $012C          ;.MESS 072.,300.,GRN,<2 GIVES 1>
LEC50:  .word $0048, $012C          ;.MESS 072.,300.,GRN,<4 GIVES 1>
LEC54:  .word $0048, $012C          ;.MESS 072.,300.,GRN,<4 GIVES 2>
LEC58:  .word $0048, $012C          ;.MESS 072.,300.,GRN,<5 GIVES 1>
LEC5C:  .word $0048, $012C          ;.MESS 072.,300.,GRN,<3 GIVES 1>
LEC60:  .word $0048, $012C          ;.NEXTMES 072.,300.,GRN
LEC64:  .word $0048, $012C          ;.MESS 072.,300.,GRN,<NONE>
LEC68:  .word $0048, $00FA          ;.MESS 072.,250.,GRN,<6>,SLV
LEC6C:  .word $0048, $00FA          ;.MESS 072.,250.,GRN,<7>
LEC70:  .word $0048, $00FA          ;.MESS 072.,250.,GRN,<8>
LEC74:  .word $0048, $00FA          ;.MESS 072.,250.,GRN,<9>
LEC78:  .word $0048, $00C8          ;.MESS 072.,200.,GRN,<EASY>,DIF
LEC7C:  .word $0048, $00C8          ;.MESS 072.,200.,GRN,<MODERATE>
LEC80:  .word $0048, $00C8          ;.MESS 072.,200.,GRN,<HARD>
LEC84:  .word $0048, $00C8          ;.MESS 072.,200.,GRN,<HARDEST>
LEC88:  .word $0048, $0096          ;.MESS 072.,150.,GRN,<0>,BSV
LEC8C:  .word $0048, $0096          ;.MESS 072.,150.,GRN,<1>
LEC90:  .word $0048, $0096          ;.MESS 072.,150.,GRN,<2>
LEC94:  .word $0048, $0096          ;.MESS 072.,150.,GRN,<3>
LEC98:  .word $0048, $0064          ;.MESS 072.,100.,GRN,<YES>,MUV
LEC9C:  .word $0048, $0064          ;.MESS 072.,100.,GRN,<NO>
LECA0:  .word $0048, $0000          ;.MESS 072.,000.,GRN,<NO>,RHS
LECA4:  .word $0048, $0000          ;.MESS 072.,000.,GRN,<YES>
LECA8:  .word $0048, $1FCE          ;.MESS 072.,-050.,GRN,<NO>,RAC
LECAC:  .word $0048, $1FCE          ;.MESS 072.,-050.,GRN,<YES>
LECB0:  .word $0048, $1F9C          ;.MESS 072.,-100.,GRN,<NO>,ROP
LECB4:  .word $0048, $1F9C          ;.MESS 072.,-100.,GRN,<YES>
LECB8:  .word $0048, $1F6A          ;.MESS 072.,-150.,GRN,<NO>,TER
LECBC:  .word $0048, $1F6A          ;.MESS 072.,-150.,GRN,<YES>
LECC0:  .word $00B2, $1F6A          ;.MESS 178.,-150.,RED,<NO ERRORS>,GNV
LECC4:  .word $00B2, $1F6A          ;.MESS 178.,-150.,RED,<ERROR AT>,BNV
LECC8:  .word $1F80, $0190          ;.MESS -128.,400.,WHT,<SWITCH TEST>,SWT
LECCC:  .word $1ED4, $012C          ;.MESS -300.,300.,GRN,<LEFT FIRE>
LECD0:  .word $0064, $012C          ;.MESS 100.,300.,GRN,<RIGHT FIRE>
LECD4:  .word $1FB0, $1F6A          ;.MESS -080.,-150.,GRN,<SPARE 1>
LECD8:  .word $1F98, $00C8          ;.MESS -104.,200.,GRN,<SELF TEST>
LECDC:  .word $1FD4, $0096          ;.MESS -044.,150.,GRN,<SLAM>
LECE0:  .word $1FA4, $0064          ;.MESS -092.,100.,GRN,<AUX COIN>
LECE4:  .word $1F98, $0032          ;.MESS -104.,050.,GRN,<LEFT COIN>
LECE8:  .word $1F8C, $0000          ;.MESS -116.,-000.,GRN,<RIGHT COIN>
LECEC:  .word $1F68, $1FCE          ;.NEXTMESS -152.,-050.,GRN
LECF0:  .word $1F98, $1F9C          ;.MESS -104.,-100.,GRN,< >
LECF4:  .word $1EBC, $00FA          ;.MESS -324.,250.,GRN,<LEFT THUMB>
LECF8:  .word $0064, $00FA          ;.MESS 100.,250.,GRN,<RIGHT THUMB>
LECFC:  .word $1FB0, $1F38          ;.MESS -080.,-200.,GRN,<SPARE 2>
LED00:  .word $1F8C, $1F06          ;.NEXTMESS -116.,-250.,GRN
LED04:  .word $1FB0, $1ED4          ;.NEXTMESS -080.,-300.,GRN
LED08:  .word $1FBC, $1ED4          ;.MESS -068.,-300.,GRN,< >
LED0C:  .word $00E4, $00D2          ;.MESS 228.,210.,WHT,<POT TEST>,POT
LED10:  .word $1F50, $01C2          ;.MESS -176.,450.,WHT,<HARDWARE ERRORS>,RAM
LED14:  .word $1F2C, $0000          ;.MESS -212.,000.,WHT,<NO ERRORS DETECTED>
LED18:  .word $1F38, $0190          ;.MESS -200.,400.,GRN,<PROGRAM RAM AT 2FH>
LED1C:  .word $1F5C, $015E          ;.MESS -164.,350.,GRN,<MATH RAM AT 5F>
LED20:  .word $1F5C, $012C          ;.MESS -164.,300.,GRN,<MATH RAM AT 5H>
LED24:  .word $1F74, $00FA          ;.MESS -140.,250.,GRN,<VG RAM0 AT 3L>
LED28:  .word $1F74, $00C8          ;.MESS -140.,200.,GRN,<VG RAM1 AT 3M>
LED2C:  .word $1F74, $0096          ;.MESS -140.,150.,GRN,<VG RAM2 AT 3P>
LED30:  .word $1F74, $0064          ;.MESS -140.,100.,GRN,<VG RAM3 AT 4L>
LED34:  .word $1F74, $0032          ;.MESS -140.,050.,GRN,<VG RAM4 AT 4M>
LED38:  .word $1F74, $0000          ;.MESS -140.,000.,GRN,<VG RAM5 AT 4P>
LED3C:  .word $1EFC, $1FCE          ;.MESS -260.,-050.,GRN,<NON VOLATILE RAM AT 1E>
LED40:  .word $1F38, $1F38          ;.MESS -200.,-200.,GRN,<PROGRAM ROM0 AT 1F>
LED44:  .word $1F38, $1F06          ;.MESS -200.,-250.,GRN,<PROGRAM ROM1 AT 1HJ>
LED48:  .word $1F38, $1ED4          ;.MESS -200.,-300.,GRN,<PROGRAM ROM2 AT 1JK>
LED4C:  .word $1F38, $1EA2          ;.MESS -200.,-350.,GRN,<PROGRAM ROM3 AT 1KL>
LED50:  .word $1F38, $1E70          ;.MESS -200.,-400.,GRN,<PROGRAM ROM4 AT 1M>
LED54:  .word $1F74, $1F6A          ;.MESS -140.,-150.,GRN,<VG ROM AT 1L>
LED58:  .word $1F68, $0190          ;.MESS -152.,400.,WHT,<MATHBOX TESTS>,MBT
LED5C:  .word $1EFC, $00C8          ;.MESS -260.,200.,WHT,<BAD MATHBOX READY LINE>,MBN
LED60:  .word $1F5C, $015E          ;.MESS -164.,350.,WHT,<DIVIDER ERRORS>,DIV
LED64:  .word $1F38, $00C8          ;.MESS -200.,200.,WHT,<NO DIVIDER ERRORS>
LED68:  .word $1E98, $0113          ;.MESS -360.,275.,WHT,<OPT SW NUM DIV DEN IS ERROR>
LED6C:  .word $1F68, $1F9C          ;.MESS -152.,-100.,WHT,<MATRIX ERRORS>,MTX
LED70:  .word $1F44, $1ED4          ;.MESS -188.,-300.,WHT,<NO MATRIX ERRORS>
LED74:  .word $1FA4, $0064          ;.MESS -092.,100.,WHT,<BIP TEST>,BIP
LED78:  .word $1F50, $1F9C          ;.MESS -176.,-100.,WHT,<ALIGN THE BOXES>
LED7C:  .word $1F8C, $00FA          ;.MESS -116.,250.,WHT,<SCALE TEST>,SCL
LED80:  .word $1FBC, $00BE          ;.MESS -068.,190.,WHT,<LINEAR>
LED84:  .word $1F38, $00BE          ;.MESS -200.,190.,WHT,<LINEAR AND BINARY>
LED88:  .word $1F9C, $1F38          ;.MESS -100.,-200.,<WHT&0FF00!00>,<0. OFF>,INT
LED8C:  .word $1F9C, $1F06          ;.MESS -100.,-250.,<WHT&0FF00!10>,<1. DIM>
LED90:  .word $1F9C, $1ED4          ;.MESS -100.,-300.,<WHT&0FF00!20>,<2. LOW>
LED94:  .word $1F9C, $1EA2          ;.MESS -100.,-350.,<WHT&0FF00!80>,<3. HIGH>
LED98:  .word $1F5C, $012C          ;.MESS -164.,300.,WHT,<INTENSITY TEST>
LED9C:  .word $1ECC, $1E3E          ;.MESS -308.,-450.,WHT,<PRESS AUX COIN TO CONTINUE>,XIT
LEDA0:  .word $1EB4, $1E3E          ;.MESS -332.,-450.,WHT,<PRESS AUX COIN FOR SELF TEST>,TST
LEDA4:  .word $1E78, $1F06          ;.MESS -392.,-250.,VJMFL,<PULL RIGHT FIRE TO PERFORM RESETS>,RES

TZ:
TMESCL:          ;COLOR COMMANDS FOR MESSAGES
LEDA8:  .word GRN                   ;.MESS -104.,-420.,GRN,<STAR WARS>,CPY
LEDAA:  .word GRN                   ;.MESS -404.,-456.,GRN,<@ 1983 LUCASFILM LTD. AND ATARI,INC.>
LEDAC:  .word GRN                   ;.MESS -224.,-492.,GRN,<ALL RIGHTS RESERVED.>
LEDAE:  .word GRN                   ;.MESS -464.,-528.,GRN,<LUCASFILM TRADEMARKS USED UNDER LICENSE.>,CPZ
LEDB0:  .word RED|$FF               ;.NEXTMESS -104.,000.,RED!0FF,GO1
LEDB2:  .word TRQ                   ;.MESS -104.,0480.,TRQ,<GAME OVER>,GVR
LEDB4:  .word BLU                   ;.MESS -140.,0480.,BLU,<INSERT COINS>,INS
LEDB6:  .word YLW                   ;.MESS -104.,0432.,YLW,<FREE PLAY>,FRE
LEDB8:  .word YLW                   ;.MESS -164.,0432.,YLW,<2 PLAYS 1 COIN>,2PC
LEDBA:  .word YLW                   ;.MESS -152.,0432.,YLW,<1 COIN 1 PLAY>,1CP
LEDBC:  .word YLW                   ;.MESS -164.,0432.,YLW,<2 COINS 1 PLAY>,2CP
LEDBE:  .word VJMFL                 ;.MESS -248.,0480.,VJMFL,<PULL TRIGGER TO START>,STR
LEDC0:  .word WHT                   ;.MESS -060.,0432.,WHT,<CREDITS>,CRD
LEDC2:  .word WHT                   ;.MESS -060.,0432.,WHT,<CREDIT>
LEDC4:  .word VJMFL                 ;.MESS -116.,460./2,VJMFL,<SHIELD GONE>,SHG
LEDC6:  .word RED                   ;.MESS -396.,0288.,RED,<FLIGHT INSTRUCTIONS TO RED FIVE>,FLI
LEDC8:  .word RED                   ;.MESS -444.,0216.,RED,<1. YOUR X-WING IS EQUIPPED WITH AN>
LEDCA:  .word RED                   ;.MESS -420.,0180.,RED,<INVISIBLE DEFLECTOR SHIELD THAT>
LEDCC:  .word RED                   ;.MESS -420.,0144.,RED,<WILL PROTECT YOU FOR COLLISIONS.>
LEDCE:  .word RED                   ;.MESS -444.,0072.,RED,<2. DEFLECTOR STRENGTH IS LOST WHEN>
LEDD0:  .word RED                   ;.MESS -420.,0036.,RED,<A FIREBALL IMPACTS YOUR SHIELD OR>
LEDD2:  .word RED                   ;.MESS -420.,0000.,RED,<WHEN YOU STRIKE A LASER TOWER OR>
LEDD4:  .word RED                   ;.MESS -420.,-036.,RED,<TRENCH CATWALK.>
LEDD6:  .word RED                   ;.MESS -444.,-108.,RED,<3. AIM YOUR LASERS WITH CURSOR TO>
LEDD8:  .word RED                   ;.MESS -420.,-144.,RED,<EXPLODE EMPIRE TIE FIGHTERS, LASER>
LEDDA:  .word RED                   ;.MESS -420.,-180.,RED,<TOWER TOPS AND TRENCH TURRETS.>
LEDDC:  .word RED                   ;.MESS -444.,-252.,RED,<4. SHOOT FIREBALLS BEFORE THEY>
LEDDE:  .word RED                   ;.MESS -420.,-288.,RED,<IMPACT YOUR SHIELD.>
LEDE0:  .word RED                   ;.MESS -444.,-360.,RED,<5. THE REBEL FORCE IS DEPENDING ON>
LEDE2:  .word RED                   ;.MESS -420.,-396.,RED,<YOU TO STOP THE EMPIRE BY BLOWING>
LEDE4:  .word RED                   ;.MESS -420.,-432.,RED,<UP THE DEATH STAR.>,FLZ
LEDE6:  .word RED                   ;.MESS 0084.,0144.,RED,<6>
LEDE8:  .word RED                   ;.MESS 0084.,0144.,RED,<7>
LEDEA:  .word RED                   ;.MESS 0084.,0144.,RED,<8>
LEDEC:  .word RED                   ;.MESS 0084.,0144.,RED,<9>
LEDEE:  .word PRP                   ;.MESS -060.,0280.,PRP,<SCORING>,SCR
LEDF0:  .word PRP                   ;.MESS -372.,0180.,PRP,<TIE FIGHTERS 1,000>,SC1
LEDF2:  .word PRP                   ;.MESS -372.,0120.,PRP,<DARTH VADER'S SHIP 2,000>
LEDF4:  .word PRP                   ;.MESS -372.,0060.,PRP,<LASER BUNKERS 200>
LEDF6:  .word PRP                   ;.MESS -372.,0000.,PRP,<LASER TOWERS 200>
LEDF8:  .word PRP                   ;.MESS -372.,-060.,PRP,<TRENCH TURRETS 100>
LEDFA:  .word PRP                   ;.MESS -372.,-120.,PRP,<FIREBALLS 33>
LEDFC:  .word PRP                   ;.MESS -372.,-280.,PRP,<EXHAUST PORT 25,000>
LEDFE:  .word PRP                   ;.MESS -372.,-350.,PRP,<DESTROYING ALL TOWER TOPS 50,000>,SCZ
LEE00:  .word PRP                   ;.MESS -224.,0340.,PRP,<SELECT A DEATH STAR>,DS1
LEE02:  .word PRP                   ;.MESS -380.,0300.,PRP,<FIRE LASER AT DESIRED DEATH STAR>
LEE04:  .word VJMFL                 ;.MESS -104.,0260.,VJMFL,<COUNTDOWN>
LEE06:  .word GRN                   ;.MESS -300.,0032.,GRN,<EASY>
LEE08:  .word GRN                   ;.MESS -068.,-200.,GRN,<MEDIUM>
LEE0A:  .word GRN                   ;.MESS 0224.,0032.,GRN,<HARD>
LEE0C:  .word RED                   ;.MESS -468.,0200.,RED,<WAVE 1>
LEE0E:  .word RED                   ;.MESS -068.,-160.,RED,<WAVE 3>
LEE10:  .word RED                   ;.MESS 0332.,0200.,RED,<WAVE 5>
LEE12:  .word BLU                   ;.NEXTMESS -056.,-400.,BLU
LEE14:  .word BLU                   ;.MESS 0344.,0000.,BLU,<BONUS>
LEE16:  .word BLU                   ;.MESS -492.,0000.,BLU,<NO BONUS>
LEE18:  .word RED                   ;.MESS -080.,-440.,RED,<400,000>
LEE1A:  .word RED                   ;.MESS 0320.,-040.,RED,<800,000>,DSZ
LEE1C:  .word YLW                   ;.MESS -368.,0340.,YLW,<MESSAGE FROM REBEL COMMAND POST>,HS1
LEE1E:  .word PRP                   ;.MESS -308.,0280.,PRP,<YOU ARE A TRUE REBEL PILOT>
LEE20:  .word VJMFL                 ;.MESS -248.,0220.,VJMFL,<THE FORCE IS WITH YOU>
LEE22:  .word BLU                   ;.MESS -224.,0120.,BLU,<SHOOT YOUR INITIALS>,HSZ
LEE24:  .word VJMFL                 ;.NEXTMESS -320.,000.,VJMFL,RF1
LEE26:  .word RED                   ;.MESS -320.,0316.,RED,<PRINCESS LEIA'S REBEL FORCE>,RF2
LEE28:  .word RED                   ;.MESS -128.,VGRW7,RED,<POINTS NEXT TOWER>,NXT
LEE2A:  .word RED                   ;.MESS 0314.,0444.,RED,<TOWERS>,TWR
LEE2C:  .word VJMFL                 ;.MESS -284.,VGRW7,VJMFL,<CLEARED ALL LASER TOWERS>,ATP
LEE2E:  .word RED                   ;.MESS -356.,VGRW7,RED,<50,000 FOR SHOOTING ALL TOWERS>,RWD
LEE30:  .word VJMFL                 ;.MESS -212.,VGRW9/2-12.,VJMFL,<EXHAUST PORT AHEAD>,EXH
LEE32:  .word VJMFL                 ;.MESS -236.,0312.,VJMFL,<DEATH STAR DESTROYED>,DSD
LEE34:  .word VJMFL                 ;.MESS -224.,VGRW9/2-12.,VJMFL,<EXHAUST PORT MISSED>,MSD
LEE36:  .word VJMFL                 ;.MESS -308.,0192.,VJMFL,<BONUS FOR REMAINING ENERGY>,BRE
LEE38:  .word VJMFL                 ;.MESS -128.,0144.,VJMFL,<5,000 X>
LEE3A:  .word VJMFL                 ;.MESS -272.,0072.,VJMFL,<ADDED TO DEFLECTOR SHIELD>,BSE
LEE3C:  .word VJMFL                 ;.MESS -272.,0072.,VJMFL,<SHIELD AT FULL STRENGTH>
LEE3E:  .word VJMFL                 ;.MESS -224.,-048.,VJMFL,<STARTING WAVE BONUS>,BON
LEE40:  .word WHT                   ;.MESS -176.,VGRW7,WHT,<SHOOT FIREBALLS>,SFB
LEE42:  .word RED                   ;.MESS -212.,VGRW7,RED,<SHOOT TIE FIGHTERS>,STF
LEE44:  .word RED                   ;.MESS -164.,VGRW7,RED,<AVOID CATWALKS>,ACW
LEE46:  .word VJMFL                 ;.MESS -152.,VGRW9,VJMFL,<USE THE FORCE>,USE
LEE48:  .word VJMFL                 ;.MESS 0000.,0000.,VJMFL,< FOR USING THE FORCE>
LEE4A:  .byte $00, $00, $00, $00, $00, $00, $00, $00 ;not assembled by any source statement (ROM fill)
LEE52:  .byte $00, $00, $00, $00, $00, $00, $00, $00 ;not assembled by any source statement (ROM fill)
LEE5A:  .word WHT                   ;.MESS -260.,480.,WHT,<ACCOUNTING INFORMATION>,ACC
LEE5C:  .word GRN                   ;.MESS -216.,440.,GRN,<AUX COINS>
LEE5E:  .word GRN                   ;.MESS -360.,400.,GRN,<LEFT MECH COINS>
LEE60:  .word GRN                   ;.MESS -384.,360.,GRN,<RIGHT MECH COINS>
LEE62:  .word GRN                   ;.MESS -384.,320.,GRN,<TOTAL COINS PAID>
LEE64:  .word GRN                   ;.MESS -288.,280.,GRN,<GAMES PLAYED>
LEE66:  .word GRN                   ;.MESS 0250.,320.,GRN,<HIGH WAVE>
LEE68:  .word GRN                   ;.MESS -360.,220.,GRN,<TOTAL GAME TIME SECONDS>
LEE6A:  .word GRN                   ;.MESS -408.,180.,GRN,<AVERAGE GAME TIME>
LEE6C:  .word GRN                   ;.MESS -312.,120.,GRN,<TOTAL TIME ON SECONDS>
LEE6E:  .word GRN                   ;.MESS -432.,080.,GRN,<PERCENTAGE OF PLAY PERCENT>
LEE70:  .word WHT                   ;.MESS -248.,000.,WHT,<HISTORY OF GAME TIMES>
LEE72:  .word WHT                   ;.MESS -140.,500.,WHT,<GAME OPTIONS>,OPT
LEE74:  .word GRN                   ;.MESS -360.,450.,GRN,<VALUE OF A COIN>
LEE76:  .word GRN                   ;.MESS -360.,400.,GRN,<LEFT MECH VALUE>
LEE78:  .word GRN                   ;.MESS -384.,350.,GRN,<RIGHT MECH VALUE>
LEE7A:  .word GRN                   ;.MESS -264.,300.,GRN,<BONUS ADDER>
LEE7C:  .word GRN                   ;.MESS -360.,250.,GRN,<STARTING SHIELD>
LEE7E:  .word GRN                   ;.MESS -360.,200.,GRN,<PLAY DIFFICULTY>
LEE80:  .word GRN                   ;.MESS -288.,150.,GRN,<BONUS SHIELD>
LEE82:  .word GRN                   ;.MESS -384.,100.,GRN,<MUSIC IN ATTRACT>
LEE84:  .word GRN                   ;.MESS -408.,000.,GRN,<RESET HIGH SCORES>
LEE86:  .word GRN                   ;.MESS -408.,-050.,GRN,<RESET TIMING INFO>
LEE88:  .word GRN                   ;.MESS -312.,-100.,GRN,<RESET OPTIONS>
LEE8A:  .word GRN                   ;.MESS -264.,-150.,GRN,<TEST NOVRAM>
LEE8C:  .word GRN                   ;.MESS -260.,-300.,GRN,<UP,DOWN TO SELECT ITEM>
LEE8E:  .word GRN                   ;.MESS -368.,-350.,GRN,<PULL LEFT FIRE TO CHANGE SETTING>
LEE90:  .word GRN                   ;.MESS 072.,450.,GRN,<FREE PLAY>,VLC
LEE92:  .word GRN                   ;.MESS 072.,450.,GRN,<2 CREDITS>
LEE94:  .word GRN                   ;.MESS 072.,450.,GRN,<1 CREDIT>
LEE96:  .word GRN                   ;.MESS 072.,450.,GRN,<% CREDIT>
LEE98:  .word GRN                   ;.MESS 072.,400.,GRN,<1>,LMV
LEE9A:  .word GRN                   ;.MESS 072.,400.,GRN,<2>
LEE9C:  .word GRN                   ;.MESS 072.,350.,GRN,<1>,RMV
LEE9E:  .word GRN                   ;.MESS 072.,350.,GRN,<4>
LEEA0:  .word GRN                   ;.MESS 072.,350.,GRN,<5>
LEEA2:  .word GRN                   ;.MESS 072.,350.,GRN,<6>
LEEA4:  .word GRN                   ;.MESS 072.,300.,GRN,<NONE>,BAV
LEEA6:  .word GRN                   ;.MESS 072.,300.,GRN,<2 GIVES 1>
LEEA8:  .word GRN                   ;.MESS 072.,300.,GRN,<4 GIVES 1>
LEEAA:  .word GRN                   ;.MESS 072.,300.,GRN,<4 GIVES 2>
LEEAC:  .word GRN                   ;.MESS 072.,300.,GRN,<5 GIVES 1>
LEEAE:  .word GRN                   ;.MESS 072.,300.,GRN,<3 GIVES 1>
LEEB0:  .word GRN                   ;.NEXTMES 072.,300.,GRN
LEEB2:  .word GRN                   ;.MESS 072.,300.,GRN,<NONE>
LEEB4:  .word GRN                   ;.MESS 072.,250.,GRN,<6>,SLV
LEEB6:  .word GRN                   ;.MESS 072.,250.,GRN,<7>
LEEB8:  .word GRN                   ;.MESS 072.,250.,GRN,<8>
LEEBA:  .word GRN                   ;.MESS 072.,250.,GRN,<9>
LEEBC:  .word GRN                   ;.MESS 072.,200.,GRN,<EASY>,DIF
LEEBE:  .word GRN                   ;.MESS 072.,200.,GRN,<MODERATE>
LEEC0:  .word GRN                   ;.MESS 072.,200.,GRN,<HARD>
LEEC2:  .word GRN                   ;.MESS 072.,200.,GRN,<HARDEST>
LEEC4:  .word GRN                   ;.MESS 072.,150.,GRN,<0>,BSV
LEEC6:  .word GRN                   ;.MESS 072.,150.,GRN,<1>
LEEC8:  .word GRN                   ;.MESS 072.,150.,GRN,<2>
LEECA:  .word GRN                   ;.MESS 072.,150.,GRN,<3>
LEECC:  .word GRN                   ;.MESS 072.,100.,GRN,<YES>,MUV
LEECE:  .word GRN                   ;.MESS 072.,100.,GRN,<NO>
LEED0:  .word GRN                   ;.MESS 072.,000.,GRN,<NO>,RHS
LEED2:  .word GRN                   ;.MESS 072.,000.,GRN,<YES>
LEED4:  .word GRN                   ;.MESS 072.,-050.,GRN,<NO>,RAC
LEED6:  .word GRN                   ;.MESS 072.,-050.,GRN,<YES>
LEED8:  .word GRN                   ;.MESS 072.,-100.,GRN,<NO>,ROP
LEEDA:  .word GRN                   ;.MESS 072.,-100.,GRN,<YES>
LEEDC:  .word GRN                   ;.MESS 072.,-150.,GRN,<NO>,TER
LEEDE:  .word GRN                   ;.MESS 072.,-150.,GRN,<YES>
LEEE0:  .word RED                   ;.MESS 178.,-150.,RED,<NO ERRORS>,GNV
LEEE2:  .word RED                   ;.MESS 178.,-150.,RED,<ERROR AT>,BNV
LEEE4:  .word WHT                   ;.MESS -128.,400.,WHT,<SWITCH TEST>,SWT
LEEE6:  .word GRN                   ;.MESS -300.,300.,GRN,<LEFT FIRE>
LEEE8:  .word GRN                   ;.MESS 100.,300.,GRN,<RIGHT FIRE>
LEEEA:  .word GRN                   ;.MESS -080.,-150.,GRN,<SPARE 1>
LEEEC:  .word GRN                   ;.MESS -104.,200.,GRN,<SELF TEST>
LEEEE:  .word GRN                   ;.MESS -044.,150.,GRN,<SLAM>
LEEF0:  .word GRN                   ;.MESS -092.,100.,GRN,<AUX COIN>
LEEF2:  .word GRN                   ;.MESS -104.,050.,GRN,<LEFT COIN>
LEEF4:  .word GRN                   ;.MESS -116.,-000.,GRN,<RIGHT COIN>
LEEF6:  .word GRN                   ;.NEXTMESS -152.,-050.,GRN
LEEF8:  .word GRN                   ;.MESS -104.,-100.,GRN,< >
LEEFA:  .word GRN                   ;.MESS -324.,250.,GRN,<LEFT THUMB>
LEEFC:  .word GRN                   ;.MESS 100.,250.,GRN,<RIGHT THUMB>
LEEFE:  .word GRN                   ;.MESS -080.,-200.,GRN,<SPARE 2>
LEF00:  .word GRN                   ;.NEXTMESS -116.,-250.,GRN
LEF02:  .word GRN                   ;.NEXTMESS -080.,-300.,GRN
LEF04:  .word GRN                   ;.MESS -068.,-300.,GRN,< >
LEF06:  .word WHT                   ;.MESS 228.,210.,WHT,<POT TEST>,POT
LEF08:  .word WHT                   ;.MESS -176.,450.,WHT,<HARDWARE ERRORS>,RAM
LEF0A:  .word WHT                   ;.MESS -212.,000.,WHT,<NO ERRORS DETECTED>
LEF0C:  .word GRN                   ;.MESS -200.,400.,GRN,<PROGRAM RAM AT 2FH>
LEF0E:  .word GRN                   ;.MESS -164.,350.,GRN,<MATH RAM AT 5F>
LEF10:  .word GRN                   ;.MESS -164.,300.,GRN,<MATH RAM AT 5H>
LEF12:  .word GRN                   ;.MESS -140.,250.,GRN,<VG RAM0 AT 3L>
LEF14:  .word GRN                   ;.MESS -140.,200.,GRN,<VG RAM1 AT 3M>
LEF16:  .word GRN                   ;.MESS -140.,150.,GRN,<VG RAM2 AT 3P>
LEF18:  .word GRN                   ;.MESS -140.,100.,GRN,<VG RAM3 AT 4L>
LEF1A:  .word GRN                   ;.MESS -140.,050.,GRN,<VG RAM4 AT 4M>
LEF1C:  .word GRN                   ;.MESS -140.,000.,GRN,<VG RAM5 AT 4P>
LEF1E:  .word GRN                   ;.MESS -260.,-050.,GRN,<NON VOLATILE RAM AT 1E>
LEF20:  .word GRN                   ;.MESS -200.,-200.,GRN,<PROGRAM ROM0 AT 1F>
LEF22:  .word GRN                   ;.MESS -200.,-250.,GRN,<PROGRAM ROM1 AT 1HJ>
LEF24:  .word GRN                   ;.MESS -200.,-300.,GRN,<PROGRAM ROM2 AT 1JK>
LEF26:  .word GRN                   ;.MESS -200.,-350.,GRN,<PROGRAM ROM3 AT 1KL>
LEF28:  .word GRN                   ;.MESS -200.,-400.,GRN,<PROGRAM ROM4 AT 1M>
LEF2A:  .word GRN                   ;.MESS -140.,-150.,GRN,<VG ROM AT 1L>
LEF2C:  .word WHT                   ;.MESS -152.,400.,WHT,<MATHBOX TESTS>,MBT
LEF2E:  .word WHT                   ;.MESS -260.,200.,WHT,<BAD MATHBOX READY LINE>,MBN
LEF30:  .word WHT                   ;.MESS -164.,350.,WHT,<DIVIDER ERRORS>,DIV
LEF32:  .word WHT                   ;.MESS -200.,200.,WHT,<NO DIVIDER ERRORS>
LEF34:  .word WHT                   ;.MESS -360.,275.,WHT,<OPT SW NUM DIV DEN IS ERROR>
LEF36:  .word WHT                   ;.MESS -152.,-100.,WHT,<MATRIX ERRORS>,MTX
LEF38:  .word WHT                   ;.MESS -188.,-300.,WHT,<NO MATRIX ERRORS>
LEF3A:  .word WHT                   ;.MESS -092.,100.,WHT,<BIP TEST>,BIP
LEF3C:  .word WHT                   ;.MESS -176.,-100.,WHT,<ALIGN THE BOXES>
LEF3E:  .word WHT                   ;.MESS -116.,250.,WHT,<SCALE TEST>,SCL
LEF40:  .word WHT                   ;.MESS -068.,190.,WHT,<LINEAR>
LEF42:  .word WHT                   ;.MESS -200.,190.,WHT,<LINEAR AND BINARY>
LEF44:  .word (WHT&$FF00)|0         ;.MESS -100.,-200.,<WHT&0FF00!00>,<0. OFF>,INT
LEF46:  .word (WHT&$FF00)|$10       ;.MESS -100.,-250.,<WHT&0FF00!10>,<1. DIM>
LEF48:  .word (WHT&$FF00)|$20       ;.MESS -100.,-300.,<WHT&0FF00!20>,<2. LOW>
LEF4A:  .word (WHT&$FF00)|$80       ;.MESS -100.,-350.,<WHT&0FF00!80>,<3. HIGH>
LEF4C:  .word WHT                   ;.MESS -164.,300.,WHT,<INTENSITY TEST>
LEF4E:  .word WHT                   ;.MESS -308.,-450.,WHT,<PRESS AUX COIN TO CONTINUE>,XIT
LEF50:  .word WHT                   ;.MESS -332.,-450.,WHT,<PRESS AUX COIN FOR SELF TEST>,TST
LEF52:  .word VJMFL                 ;.MESS -392.,-250.,VJMFL,<PULL RIGHT FIRE TO PERFORM RESETS>,RES

;==============================================================================
; MODULE WSINT   WSINT.MAC
;   HARDWARE INTERRUPTS
;==============================================================================

;------------------------------------------------------------------------------
; INTDIS - INVALID INTERRUPTS
;   ALL INTS DISABLED FROM HERE ON
;   FORCE WATCHDOG RESET
;   (also: SWI3, SWI2, FIRQ, NMI, ASWI, TMESCZ, ASWI_10)
;------------------------------------------------------------------------------
INTDIS:
SWI3:
SWI2:
FIRQ:
NMI:
ASWI:
TMESCZ:
ASWI_10:
LEF54:  BRA  INTDIS                 ;ANYTHING OTHER THAN IRQ OR RESET HANGS IN

;------------------------------------------------------------------------------
; IRQ - IRQ
;------------------------------------------------------------------------------
IRQ:
LEF56:  LDX  $A,S                   ;VALIDATE PC
LEF58:  CMPX #PROG
LEF5B:  BHS  LEF5E                  ;IFLO
LEF5D:  SWI
LEF5E:  CMPX #INTDIS
LEF61:  BLO  LEF64                  ;IFHS  SHOULDN'T BE UP THIS HIGH
LEF63:  SWI                         ;BREAK FOR OUT OF RANGE IRQ
LEF64:  LDA  #DPRAM/$100            ;SETUP NORMAL DIRECT PAGE
LEF66:  TFR  A,DP
LEF68:  STA  WTCHDG                 ;KEEP WATCHDOG QUIET HERE SINCE IT IS TOO FAST
;FOR MAINLINE
LEF6B:  LDA  S_GARBG                ;VALIDATE RAM TRAP
LEF6D:  CMPA #$3F
LEF6F:  BEQ  LEF72                  ;IFNE
LEF71:  SWI
LEF72:  DEC  GMTIMR                 ;?TIME FOR NEXT GAME FRAME UPDATE?
LEF74:  BPL  LEF7F                  ;IFMI  YES
LEF76:  LDA  #$0B                   ;12.*4.2MS==>50. MS, 20 PER SECOND
LEF78:  STA  GMTIMR
LEF7A:  INC  GMSYNC
LEF7C:  BVC  LEF7F                  ;IFVS  ?MAINLINE CAUGHT UP IN ITSELF?
LEF7E:  SWI
LEF7F:  INC  S_INTCT                ;INCREMENT THE INTERRUPT COUNTER
LEF81:  JSR  COINS
LEF84:  LDA  S_S_CRDT
LEF86:  CMPA #BADCRD
LEF88:  BLO  LEF8B                  ;IFHS  ?TOO MUCH OF A GOOD THING?
LEF8A:  SWI                         ;GAMING IS ILLEGAL, BREAK IT UP
;SWITCHES
LEF8B:  LDX  #IN_NW0
LEF8E:  LDA  R_BYT0
LEF91:  JSR  DEBNCE
LEF94:  LDA  R_BYT1
LEF97:  JSR  DEBNCE
LEF9A:  LDA  R_BYT2
LEF9D:  JSR  DEBNCE
LEFA0:  LDA  R_BYT3
LEFA3:  JSR  DEBNCE
LEFA6:  LDA  VG_LSN                 ;PREVIOUS NEW VALUE
LEFA8:  STA  VG_LSO                 ;IS CURRENT OLD VALUE
LEFAA:  LDA  >R_THMB                ;THUMB VALUES
LEFAD:  ANDA #THMBT                 ;ISOLATE THUMB VALUES
LEFAF:  STA  -$1,S                  ;ITEMP THUMB VALUE
LEFB1:  LDA  >R_FIRE                ;GET THIS NEWEST VALUE
LEFB4:  ANDA #-1-THMBT              ;CLEAR ROOM FOR CHANGING THUMB VALUE
LEFB6:  ORA  -$1,S                  ;MIX IN THUMB VALUE
LEFB8:  STA  VG_LSN                 ;AND SAY SO
LEFBA:  EORA VG_LSO                 ;CATCH ANY CHANGES
LEFBC:  ANDA VG_LSO                 ;FROM AN OLD '1'
LEFBE:  STA  VG_LSE                 ;1==>FALLING EDGE (WENT ON)
LEFC0:  LDA  VG_LSE                 ;SEE IF PLAYER HAS PRESSED FIRE
LEFC2:  ANDA #FIREBT|THMBT
LEFC4:  BEQ  LEFCA                  ;IFNE  ?SWITCH EDGE?
LEFC6:  ORA  VG_LON
LEFC8:  STA  VG_LON                 ;THEN TURN ON LAZARS
LEFCA:  JSR  DOPOTS
LEFCD:  LDA  S_INTCT
LEFCF:  BNE  LEFE6                  ;IFEQ  ONCE A SECOND
;BRIEF ASIDE: CHECK ON SOUND BOARD EVERY SO OFTEN
LEFD1:  LDA  R_STAS
LEFD4:  LSLA
LEFD5:  BPL  IRQ_112                ;B RESET SOUND PCB IF IT HASN'T HIT WATCHDOG
LEFD7:  LDA  R_RCVS                 ;ELSE SOUND PCB HIT WATCHDOG, VERIFY VALUE
LEFDA:  CMPA #PBXS_OK               ;CHECK VALUE FINDS 'CATCH FIRE AND BURN' MODE
LEFDC:  BEQ  LEFE6                  ;IFNE  ?OOPS, WRONG VALUE, SOUND PCB IN TROUBLE

IRQ_112:
LEFDE:  STA  W_RSTS                 ;FORCE A RESET TO SOUND BOARD
LEFE1:  LDA  #$00                   ;RESET VIA SOFTWARE ALSO
LEFE3:  STA  W_XMTS                 ;ATTEMPT TO RESET SOUND BOARD
LEFE6:  LDA  S_INTCT
LEFE8:  ANDA #$03                   ;EVERY 16 MILS
LEFEA:  BNE  DOVG                   ;IFEQ
;INC TIMERS
LEFEC:  LDA  >GTIME+2               ;CURRENT GAME TIMER - SET TO 0 AT START OF GAME
LEFEF:  ADDA #$01
LEFF1:  CMPA #$FA                   ;4 SECONDS? ( 250. * 16 ms = 4 SECONDS )
LEFF3:  BLO  LEFF7                  ;IFHS  YES
LEFF5:  LDA  #$00                   ;START BACK AT 00
LEFF7:  STA  >GTIME+2
LEFFA:  BNE  DOVG                   ;IFEQ  4 SECONDS, DO OTHER TIMERS
LEFFC:  LDA  >GTIME+1
LEFFF:  ADDA #$01
LF001:  DAA
LF002:  STA  >GTIME+1
LF005:  LDA  >GTIME
LF008:  ADCA #$00
LF00A:  DAA                         ;9999 * 16 ms = 666.6 MINS = 11.11 HOURS
LF00B:  BCS  LF010                  ;IFCC  DON'T OVERFLOW TIME, MORE THAN 11 HOURS !!WOW!!
LF00D:  STA  >GTIME
;INC TOTAL TIME ON COUNT
LF010:  LDA  TIMER+3
LF013:  ADDA #$01
LF015:  DAA
LF016:  STA  TIMER+3
LF019:  LDA  TIMER+2
LF01C:  ADCA #$00
LF01E:  DAA
LF01F:  STA  TIMER+2
LF022:  LDA  TIMER+1
LF025:  ADCA #$00
LF027:  DAA
LF028:  STA  TIMER+1
LF02B:  LDA  TIMER
LF02E:  ADCA #$00
LF030:  DAA
LF031:  STA  TIMER

DOVG:            ;HANDLE VG STUFF
LF034:  DEC  VGTIMR
LF036:  BVC  LF041                  ;IFVS  ?VGEN TIMED OUT?
LF038:  STA  VGSTOP                 ;THEN KILL IT
LF03B:  JSR  DOWNVG                 ;RELOAD PSUEDO ROM ( IE PROGRAM ROM TO VG RAM )
LF03E:  JMP  DOVG_90
LF041:  LBPL DOVG_90                ;?START NEXT VGEN FIELD?
LF045:  LDA  VGHALT
LF048:  LSLA
LF049:  LBPL DOVG_90                ;?VGEN HALTED (READY TO START)?
LF04D:  LDA  VGSYNC                 ;?SWITCH FRAME BUFFERS?
LF04F:  BPL  LF06A                  ;IFMI  NON-NEGATIVE VALUE INDICATES BUFFER READY
LF051:  LDA  VGRAM
LF054:  ANDA #VGBFSZ/$200           ;HIGH BYTE IN VG WORDS
LF056:  BEQ  LF05A                  ;IFNE  BEWARE BAD VGRAM AND GLITCHES
LF058:  LDA  #VGBFSZ/$100           ;HIGH BYTE ADDRESS IN BYTES
LF05A:  ORA  #(VGRAM/$100)&$FF
LF05C:  STA  VGSYNC
LF05E:  LDB  #VGVARB/2
LF060:  LSRA                        ;ALSO SWITCH FIELD BUFFERS
LF061:  ANDA #VGBFSZ/$200           ;PROG USED BYTES, VG USES WORDS
LF063:  EORA #VGBFSZ/$200           ;HI BYTE IN VG WORDS
LF065:  ORA  #$E0                   ;INCLUDE THE JMP
LF067:  STD  VGRAM
LF06A:  DEC  PT_DLY                 ;ON STARTUP, DONT USE UNSEASONED POT FILTER
LF06C:  BPL  LF073                  ;IFMI
LF06E:  CLR  PT_DLY
LF070:  JSR  RHCTRL                 ;DO CONTROLS AT IRQ VG TIME
LF073:  JSR  GNSITE                 ;AND DISPLAY ITS COORDS
;---LAZAR FIRE
LF076:  LDB  VG_LZF
LF078:  ADDB #$02
LF07A:  CMPB #VRLZFZ-VRLZF
LF07C:  BLO  LF07F                  ;IFHS  WRAPPED THE TABLE
LF07E:  CLRB
LF07F:  STB  VG_LZF
LF081:  LDX  #VRLZF+2               ;ALLOW FOR PREDEC
LF084:  ABX                         ;NEXT START OF RAM
LF085:  LDU  #VTLZF                 ;SOURCE ROM
LF088:  LDD  ,U++
LF08A:  STD  ,--X
LF08C:  CMPX #VRLZF
LF08F:  BGT  LF088                  ;LEEND
LF091:  LDX  #VRLZFZ                ;END OF RAM
LF094:  CMPU #VTLZFZ
LF098:  BHS  DOVG_48                ;DONE LEAVE
LF09A:  LDD  ,U++                   ;ROM HAS HEAD FIRST, TO TAIL
LF09C:  STD  ,--X                   ;VIEW RAM HAS HEAD FAR AWAY, TAIL NEAR
LF09E:  BRA  LF094                  ;LOOP

DOVG_48:
;===LAZAR SPLASH
LF0A0:  LDB  VG_LZS
LF0A2:  ADDB #$02
LF0A4:  CMPB #VTLZSZ-VTLZS
LF0A6:  BLO  LF0A9                  ;IFHS
LF0A8:  CLRB
LF0A9:  STB  VG_LZS
LF0AB:  LDU  #VTLZS
LF0AE:  LDD  B,U
LF0B0:  STD  VRLZS                  ;ONE PICTURE ONLY
;ALIEN GUN SHOT, BASE SPARKLE
LF0B3:  DEC  VF_GNB
LF0B5:  BGT  LF0D8                  ;IFLE
LF0B7:  LDB  #$04                   ;EVERY FOURTH SCREEN, CHANGE PICTURE TYPE
LF0B9:  STB  VF_GNB
LF0BB:  LDB  VG_GNB
LF0BD:  ADDB #$02
LF0BF:  CMPB #VTGNBZ-VTGNB
LF0C1:  BLO  LF0C4                  ;IFHS
LF0C3:  CLRB
LF0C4:  STB  VG_GNB
LF0C6:  LDU  #VTGNB
LF0C9:  LDD  B,U
LF0CB:  STD  VRGNB                  ;ONE PICTURE ONLY
LF0CE:  LDB  VG_GNB                 ;ALSO HANDLE GUN EXPLODE SAME TIME
LF0D0:  LDU  #VTGNX
LF0D3:  LDD  B,U
LF0D5:  STD  VRGNX
;ALIEN GUN SHOT, TIP FUSE
LF0D8:  DEC  VF_GNT
LF0DA:  BGT  LF0F3                  ;IFLE
LF0DC:  LDB  #$01                   ;EVERY SCREEN, CHANGE PICTURE TYPE
LF0DE:  STB  VF_GNT
LF0E0:  LDB  VG_GNT
LF0E2:  ADDB #$02
LF0E4:  CMPB #VTGNTZ-VTGNT
LF0E6:  BLO  LF0E9                  ;IFHS
LF0E8:  CLRB
LF0E9:  STB  VG_GNT
LF0EB:  LDU  #VTGNT
LF0EE:  LDD  B,U
LF0F0:  STD  VRGNT                  ;ONE PICTURE ONLY
LF0F3:  LDB  VG_FLS                 ;BRITE FLASH
LF0F5:  ADDB #$02
LF0F7:  CMPB #VTFLSZ-VTFLS
LF0F9:  BLO  LF0FC                  ;IFHS  ?OVERFLOWED?
LF0FB:  CLRB
LF0FC:  STB  VG_FLS
LF0FE:  LDU  #VTFLS
LF101:  LDD  B,U
LF103:  STD  VRFLS                  ;ONE PICTURE ONLY
LF106:  LDD  #VGRTSL
LF109:  STD  VRFLS+2                ;AND RETURN VG
LF10C:  LDB  VG_MFL                 ;MEDIUM FLASH
LF10E:  ADDB #$02
LF110:  CMPB #VTMFLZ-VTMFL
LF112:  BLO  LF115                  ;IFHS  ?OVERFLOWED TABLE?
LF114:  CLRB                        ;THEN START AT BEGINNING
LF115:  STB  VG_MFL
LF117:  LDU  #VTMFL
LF11A:  LDD  B,U
LF11C:  STD  VRMFL                  ;ONE PICTURE ONLY
LF11F:  LDD  #VGRTSL
LF122:  STD  VRMFL+2                ;AND RETURN VG
LF125:  JSR  SPLASH                 ;OSCILLATE LAZAR SPLASH PICS
LF128:  STA  VGGO                   ;START VGEN AGAIN
LF12B:  LDA  #$05
LF12D:  STA  VGTIMR

DOVG_90:
LF12F:  STA  IRCLR                  ;ALLOW NEXT IRQ
LF132:  RTI

;------------------------------------------------------------------------------
; DEBNCE - A=NEW VAL
;   X-->RAM AREA
;------------------------------------------------------------------------------
DEBNCE:
LF133:  LDB  ,X                     ;NW: PREVIOUS NEW
LF135:  STB  1,X                    ;OL: -->OLD
LF137:  STA  ,X                     ;NW: SAVE NEWEST
LF139:  ANDA 1,X                    ;OL: SAME BITS ON
LF13B:  ORA  2,X                    ;SW:
LF13D:  STA  2,X                    ;SW: SAVE DEBOUNCED ON BITS
LF13F:  ORB  ,X++                   ;NW: SAME BITS OFF
LF141:  ANDB ,X                     ;SW:
LF143:  STB  ,X+                    ;SW: SAVE DEBOUNCED OFF BITS,
;(X)+: PREPARE FOR NEXT SWITCH SET
LF145:  RTS

;------------------------------------------------------------------------------
; DOPOTS - HANDLE READING POT VALUES
;------------------------------------------------------------------------------
DOPOTS:
LF146:  LDA  S_INTCT
LF148:  LSRA                        ;?WHICH POT?
LF149:  LDY  #PT_VL                 ;ASSUME POT 1
LF14D:  BCS  LF153                  ;IFCC  NOPE, IT'S THE OTHER ONE
LF14F:  LDY  #PT_VL+PTS_IZ          ;POT 2
;POKEY FILTER
;REQUIRE 2 SAMPLES ALL HIGHER (OR LOWER)
;THAN CURRENT SAVED VALUE.
;THEN UPDATE TO CLOSEST HI (LO) VALUE
LF153:  LDB  1,Y                    ;B:=VNEW PREVIOUS NEW BECOMES CURRENT OLD
LF155:  LDA  R_CHN
LF158:  STA  1,Y                    ;A:=VNEW UPDATE CURRENT NEW
LF15A:  CMPA ,Y                     ;VL
LF15C:  BLO  LF16C                  ;IFHS  ?NEW VALUE HIGHER THAN STANDARD VALUE?
LF15E:  CMPB ,Y                     ;VL
LF160:  BLS  LF16A                  ;IFHI  ?AND OLD VALUE HIGHER ALSO?
LF162:  CMPB 1,Y                    ;VNEW
LF164:  BLS  LF168                  ;IFHI  ?VNEW IS CLOSER?
LF166:  LDB  1,Y                    ;VNEW
LF168:  STB  ,Y                     ;VL SAVE CLOSEST OF HIGHER VALUES
LF16A:  BRA  LF178                  ;ELSE  ELSE NEW VALUE IS LOWER THAN STANDARD VALUE
LF16C:  CMPB ,Y                     ;VL
LF16E:  BHS  LF178                  ;IFLO  ?OLD VALUE ALSO LOWER?
LF170:  CMPB 1,Y                    ;VNEW
LF172:  BHS  LF176                  ;IFLO  ?VNEW IS CLOSER?
LF174:  LDB  1,Y                    ;VNEW
LF176:  STB  ,Y                     ;VL SAVE CLOSEST OF LOWER VALUES
LF178:  CMPY #PT_VL                 ;START NEXT A-D CONVERSION
LF17C:  BNE  LF186                  ;IFEQ
LF17E:  STA  W_CHN0                 ;SELECT CHANNEL 0
LF181:  STA  W_CHN0                 ;START GOOD CONVERSION
LF184:  BRA  LF18C                  ;ELSE
LF186:  STA  W_CHN1                 ;SELECT CHANNEL 1
LF189:  STA  W_CHN1                 ;AND START IT CLEANLY
LF18C:  RTS

;------------------------------------------------------------------------------
; RHCTRL - IRQ VG HANDLES CONTROLS
;------------------------------------------------------------------------------
RHCTRL:
LF18D:  LDX  #RHEOP                 ;DO PITCH POT
LF190:  LDA  PT_VL2                 ;UP/DOWN VG Y
LF192:  NOP
LF193:  JSR  RHLIM                  ;LIMIT AND SCALE RHESTAT
LF196:  LDA  RHS_NML,X              ;NOW LIMIT THE POT BY THE VG SCREEN
LF198:  CMPA #VGCURT                ;HI LIMIT - CURSOR SIZE, SCALED TO +-128
LF19A:  BLE  LF19E                  ;IFGT
LF19C:  LDA  #VGCURT
LF19E:  CMPA #VGCURB&$FF            ;TOP CURSOR POSITION, SCALED DOWN +-512 TO +-128
LF1A0:  BGE  LF1A4                  ;IFLT
LF1A2:  LDA  #VGCURB&$FF
LF1A4:  STA  RHS_NML,X
LF1A6:  JSR  RHPOS
LF1A9:  LDX  #RHEOY                 ;DO YAW POT
LF1AC:  LDA  PT_VL1                 ;LEFT/RIGHT VG X
LF1AE:  NOP
LF1AF:  JSR  RHLIM                  ;LIMIT AND SCALE RHESTAT
LF1B2:  LDA  RHS_NML,X              ;NOW LIMIT TO CURSOR SCREEN SIZE
LF1B4:  CMPA #VGCURR
LF1B6:  BLE  LF1BA                  ;IFGT
LF1B8:  LDA  #VGCURR
LF1BA:  CMPA #VGCURL&$FF
LF1BC:  BGE  LF1C0                  ;IFLT
LF1BE:  LDA  #VGCURL&$FF
LF1C0:  STA  RHS_NML,X
LF1C2:  JSR  RHPOS
LF1C5:  RTS

;------------------------------------------------------------------------------
; RHLIM - ---LIMIT AND SCALE
;------------------------------------------------------------------------------
RHLIM:
LF1C6:  CMPA RHS_LO,X               ;A=RHEOSTAT VALUE
;X==>RAM BLOCK
;Y==>DATA TABLE
LF1C8:  BHS  LF1D0                  ;IFLO  ?LESS THAN LO?
LF1CA:  CMPA RHS_LT,X
LF1CC:  BLO  LF1D0                  ;IFHS  ?HIGHER THAN TRIAL LO?
LF1CE:  DEC  RHS_LO,X               ;APPROACH NEW DEGLITCHED LO
LF1D0:  STA  RHS_LT,X               ;SAVE OUR NEW TRIAL LO
LF1D2:  CMPA RHS_LO,X               ;?LESS THAN LOWER LIMIT?
LF1D4:  BHS  LF1D8                  ;IFLO
LF1D6:  LDA  RHS_LO,X               ;THEN REPLACE WITH LOWER LIMIT
LF1D8:  SUBA RHS_LO,X               ;BASE AT ZERO
LF1DA:  STA  RH_DIR                 ;TEMP STORAGE OF POT BASED VALUE
LF1DC:  LDB  RHS_SP,X               ;SPREAD THE VALUES-SCAL
LF1DE:  MUL
LF1DF:  ADDA RH_DIR                 ;MULTS BY 1XX SO VALUE GOES ABOVE 7F
LF1E1:  BNE  LF1E5                  ;IFEQ  ?UNDERFLOW?
LF1E3:  LDA  #$01                   ;RANGE IS -7F TO 7F (ALLOWS PROPER NEGATE)
LF1E5:  BCS  LF1EB                  ;IFCC  ?OVERFLOW?
LF1E7:  CLR  RHS_ST,X               ;PREPARE TIMER FOR NEXT TOO-HIGH POT VALUE
LF1E9:  BRA  LF1F7                  ;ELSE
LF1EB:  LDA  #$FF                   ;THEN LIMIT VALUE
LF1ED:  INC  RHS_ST,X               ;TIME THESE EXCESSES
LF1EF:  LDB  RHS_ST,X
LF1F1:  CMPB #$02
LF1F3:  BLO  LF1F7                  ;IFHS  ?TOO LARGE FOR TOO LONG?
LF1F5:  DEC  RHS_SP,X               ;THEN DECREASE SPREAD
LF1F7:  CLRB
LF1F8:  SUBA #$80                   ;CHANGE TO SIGNED VALUE
LF1FA:  STA  RHS_NML,X
LF1FC:  RTS

;------------------------------------------------------------------------------
; RHPOS - CONVERT NML VALUE TO SCREEN POSITION
;   SLEWED POSITIONAL
;------------------------------------------------------------------------------
RHPOS:
LF1FD:  CLR  RH_DIR                 ;START WITH POSITIVE DIRECTION TO TRAVEL
LF1FF:  LDA  RHS_NML,X              ;CURRENT -7F TO 7F POT
LF201:  LDB  #$80                   ;HALF WAY INTO POTS STAMP
LF203:  SUBD RHS_POS,X              ;CURRENT SCREEN POSITION
LF205:  BGE  LF20A                  ;IFLT  ?WANT TO GO IN NEGATIVE DIRECTION?
LF207:  NEGA                        ;THEN CHANGE DELTA TO POSITIVE 8-BIT
LF208:  DEC  RH_DIR                 ;AND SAVE NEGATIVE INDICATOR
LF20A:  BLE  LF20F                  ;IFGT  ?SLIGHTLY POSITIVE?
LF20C:  ADDD #$00FF                 ;TRUNCATE UPWARD -- ALWAYS SLEW SOME
LF20F:  CMPA #$F8
LF211:  BLS  LF215                  ;IFHI
LF213:  LDA  #$F8                   ;PREVENT OVERFLOWS DURING LATER TRUNCATIONS
LF215:  LDB  #$60                   ;HOW QUICKLY TO SKEW TO DESIRED LOCATION
LF217:  CMPA #$40                   ;ONE-QUARTER SCREEN
LF219:  BHS  LF21D                  ;IFLO  ?CLOSE ENUF?
LF21B:  LDB  #$30                   ;SLOWER WHEN CLOSER
LF21D:  MUL
LF21E:  TST  RH_DIR                 ;RESTORE ORIGINAL DIRECTION
LF220:  BPL  LF226                  ;IFMI
LF222:  COMA                        ;NEGD
LF223:  NEGB
LF224:  SBCA #$FF
LF226:  ADDD RHS_POS,X              ;NOW UPDATE OUR CURSOR POSITION
LF228:  STD  RHS_POS,X              ;RH$POS IS EQUATED TO VG.RSX,VG.RSY
LF22A:  RTS

;------------------------------------------------------------------------------
; GNSITE - IRQ,VG GENERATE SITE COORDS ON SCREEN
;------------------------------------------------------------------------------
GNSITE:
LF22B:  LDB  VG_RSY
LF22D:  LDA  VG_RSY+1               ;REVERSE LDD
LF22F:  ANDA #$C0                   ;ONLY NEED TOP TWO BITS
LF231:  LSLA                        ;SHIFT UP LO VALUES
LF232:  ROLB                        ;FROM +-128 TO +-256
LF233:  BCC  LF237                  ;IFCS  ?NEGATIVE?
LF235:  ORA  #$3F                   ;AFTER TWO SHIFTS IS SEX'D
LF237:  ROLA
LF238:  ROLB                        ;UP TO +-512
LF239:  ROLA                        ;NOW OF FORM 1FFF, VECTOR OPCODE
LF23A:  STD  VG_CY                  ;CURRENT SITE Y POS
LF23C:  ADDD #VGOFFY                ;OFFSET TO CENTER
LF23F:  ANDA #$1F                   ;VECTOR OPCODE
LF241:  STD  VRSITE+0
;---YAW CURSOR IN X POSITION
LF244:  LDB  VG_RSX
LF246:  LDA  VG_RSX+1               ;REVERSE LDD
LF248:  ANDA #$C0                   ;ONLY SHIFT IN TOP TWO BITS
LF24A:  LSLA                        ;SHIFT UP LO VALUES
LF24B:  ROLB                        ;FROM +-128 TO +-256
LF24C:  BCC  LF250                  ;IFCS  ?NEGATIVE?
LF24E:  ORA  #$3F                   ;BECOMES SEX'D AFTER TWO SHIFTS
LF250:  ROLA
LF251:  ROLB                        ;UP TO +-512
LF252:  ROLA
LF253:  STD  VG_CX                  ;CURRENT SITE LEFT/RIGHT
LF255:  ANDA #$1F                   ;KEEP BRITENESS ZERO
LF257:  STD  VRSITE+2
LF25A:  LDD  #$C000                 ;RTSL
LF25D:  STD  VRSITE+4
LF260:  RTS

;------------------------------------------------------------------------------
; RESET - RESET
;------------------------------------------------------------------------------
RESET:
LF261:  ORCC #$10                   ;SEI  DISABLE INTERRUPTS UNTIL MAINLINE INIT
LF263:  CLR  W_BANK                 ;SELECT NORMAL ROOT ROM
LF266:  LDA  #$00                   ;TURN ON DIAG LEDS FOR TESTING
LF268:  STA  W_LED1
LF26B:  STA  W_LED2
LF26E:  STA  W_LED3
LF271:  LDA  #$00
LF273:  STA  P_IRND                 ;INIT RANDOM # SEQUENCE
LF276:  LDA  #$80                   ;GET IT GOING BEFORE TEST/DIAGNOSTICS
LF278:  STA  P_IRND                 ;THEN START UP THE RANDOM # GENERATOR
LF27B:  STA  VGSTOP                 ;GATE ARRAY ONLY LISTENS TO STOP, NOT RESET LINE
LF27E:  LDU  #$0000                 ;JUST SIT HERE AND SPIN FOR AWHILE TO LET THE NOVRAM COME TO LIFE
LF281:  STA  WTCHDG                 ;GOT TO KEEP IT HAPPY
LF284:  LEAU -$1,U
LF286:  CMPU #$0000                 ;NOT NEEDED BUT IT MAKES THE LOOP A LITTLE LONGER
LF28A:  BNE  LF281                  ;EQEND
LF28C:  LDS  #STACK                 ;SYSTEM STACK
LF290:  LDA  #DPRAM/$100            ;INIT DPAGE POINTER
LF292:  TFR  A,DP
LF294:  STA  W_RSTS                 ;HARDWARE RESET SOUND BOARD
LF297:  LDA  #$00
LF299:  STA  W_XMTS                 ;ALSO TRY SOFTWARE RESET
LF29C:  LDX  #RAM                   ;CLEAR RAM
LF29F:  LDD  #$0000
LF2A2:  STD  ,X++
LF2A4:  CMPX #RAMZ
LF2A7:  BLO  LF2A2                  ;HSEND
;---AFTER 2K FAST LOOP
LF2A9:  STA  WTCHDG
LF2AC:  LDX  #M_BASE                ;CLEAR MATH RAM
LF2AF:  LDD  #$0000
LF2B2:  STD  ,X++
LF2B4:  STA  WTCHDG                 ;KEEP THE DOG HAPPY
LF2B7:  CMPX #M_FIN
LF2BA:  BLO  LF2B2                  ;HSEND
LF2BC:  LDX  #VGRAM                 ;CLEAR VECTOR RAM
LF2BF:  LDD  #$0000
LF2C2:  STD  ,X++
;---MORE THAN 2K, SO DO ALL THE TIME
LF2C4:  STA  WTCHDG                 ;KEEP THE DOG HAPPY
;;; .IF NE,DEVSYS
;;; CMPX #VGROM ;DON'T DESTROY DOWNLOADED VG PSUEDO ROM STUFF
;;; .IFF
LF2C7:  CMPX #VGRROM                ;CLEAR ALL THE WAY TO REAL ROM
;;; .ENDC
LF2CA:  BLO  LF2C2                  ;HSEND
;WITH ALL OF MEMORY EMPTY, PREPARED FOR TEST
LF2CC:  LDA  TESTSW
LF2CF:  ANDA #TESTBT                ;SELF-TEST?
LF2D1:  BNE  LF2D6                  ;IFEQ  YES
LF2D3:  JMP  TEST
;NOT SELF TEST ******************************************************************
;SETUP FOR THE FIRST DEBOUNCE OF THE OPTION SWITCHES
LF2D6:  LDA  R_BYT2                 ;GET FIRST SET OF DATA
LF2D9:  LDB  R_BYT3
LF2DC:  STA  R_OPT2                 ;SAVE THE DATA
LF2DE:  STB  R_OPT1
LF2E0:  LDX  #$0800                 ;WAIT A WHILE
LF2E3:  LEAX -$1,X
LF2E5:  BNE  LF2E3                  ;EQEND
LF2E7:  LDA  R_BYT2                 ;SECOND READING FOR DEBOUNCING THE OPTION SWITCHES
LF2EA:  LDB  R_BYT3
LF2ED:  CMPA R_OPT2
LF2EF:  BNE  LF2DC                  ;EQEND  NOT THE SAME, GO BACK AND TRY AGAIN
LF2F1:  CMPB R_OPT1
LF2F3:  BNE  LF2DC                  ;EQEND  NOT THE SAME, TRY AGAIN
;SETUP VG WITH ALL HALT INSTRUCTIONS ( JUST IN CASE ... )
LF2F5:  LDD  #$2020                 ;HALT VG
LF2F8:  LDX  #VGRAM
LF2FB:  STD  ,X++
;---MORE THAN 2K FAST LOOP, SO DO ALL THE TIME
LF2FD:  STA  WTCHDG                 ;KEEP THE DOG HAPPY
LF300:  CMPX #VGROM
LF303:  BLO  LF2FB                  ;HSEND
LF305:  LDD  #(VGVARB/2)+$E000      ;JUMP TO DOUBLE BUFFER
LF308:  STD  VGRAM
LF30B:  LDA  #$FF                   ;SWITCH BUFFERS IMMEDIATELY
LF30D:  STA  VGSYNC
LF30F:  LDA  #$3F                   ;TRAP OUT FIRST BYTE RAM
LF311:  STA  S_GARBG
LF313:  LDA  #$40                   ;POSITIVE VALUE FOR DELAY
LF315:  STA  PT_DLY                 ;DELAY RHEOSTATS UNTIL FILTER IS STABLE
LF317:  JSR  EEINIT                 ;INIT EEROM ( VERIFY/SET NOVRAM AREAS TO VALID STATES )
LF31A:  STA  WTCHDG                 ;FINAL SHADDUP
LF31D:  LDA  #$FF                   ;TURN OFF DIAG LEDS FOR MAINLINE
LF31F:  STA  W_LED1
LF322:  STA  W_LED2
LF325:  STA  W_LED3
LF328:  STA  IRCLR                  ;ENABLE HARDWARE INTS (BUT STILL DISABLED BY SOFTWARE)
LF32B:  JMP  MAIN                   ;START THE MAINLINE

;==============================================================================
; MODULE TCTEST   TCTEST.MAC
;   TOMCAT TEST
;==============================================================================

;.SBTTL TEST ROUTINES

TRAMP:           ;TABLE OF POINTERS FOR RAM TEST (ERROR BIT PATTERN)
LF32E:  .word RAM                   ;PROCESSOR RAM 0001

MRAM0:
LF330:  .word MBRAM+0               ;MATH BOX RAM (EVEN ADDRESSES) 0002

MRAM1:
LF332:  .word MBRAM+1               ;MATH BOX RAM ( ODD ADDRESSES) 0004
LF334:  .word VGRAM+0               ;VECTOR GENERATOR RAM 0008
LF336:  .word VGRAM+$800            ;" " " 0010
LF338:  .word VGRAM+$1000           ;" " " 0020
LF33A:  .word VGRAM+$1800           ;" " " 0040
LF33C:  .word VGRAM+$2000           ;" " " 0080
LF33E:  .word VGRAM+$2800           ;" " " 0100

TRAMPZ:
LF340:  .word NVRAM+0               ;NON-VOLATILE RAM 0200

TROMP:           ;TABLE OF POINTERS FOR ROM TEST
LF342:  .word PROG+0                ;PROGRAM ROMS 0400
LF344:  .word PROG+$2000            ;" " 0800
LF346:  .word PROG+$4000            ;" " 1000
LF348:  .word PROG+$6000            ;" " 2000
LF34A:  .word PROG+$8000            ;" " 4000

TROMPZ:
LF34C:  .word VGROM+0               ;VECTOR GENERATOR ROM 8000

BITS:
LF34E:  .word $0001, $0002, $0004, $0008 ;BIT PATTERNS
LF356:  .word $0010, $0020, $0040, $0080
LF35E:  .word $0100, $0200, $0400, $0800
LF366:  .word $1000, $2000, $4000, $8000

;------------------------------------------------------------------------------
; TEST - TEST
;------------------------------------------------------------------------------
TEST:
LF36E:  LDA  DIAGSW
LF371:  ANDA #DIAGBT                ;DIAGNOSTIC SWITCH?
LF373:  BNE  RAMTST                 ;IFEQ  YES, ITS ON
LF375:  LDA  R_BYT2                 ;CHECK FOR DIAGNOSTIC 1 OR 2
LF378:  COMA
LF379:  ANDA #$7F                   ;DIAG 1 = 00; DIAG 2 = 80
LF37B:  BEQ  RAMTST                 ;IFNE  NOT DIAG 1 OR 2, THEN SKIP RAM/ROM TEST
LF37D:  JMP  DIAGLP                 ;GO EXECUTE DIAGNOSTICS, NOW WITHOUT DELAY

;------------------------------------------------------------------------------
; RAMTST - ELSE PERFORM RAM/ROM TEST FOR SELF-TEST AND/OR DIAGNOSTICS 1&2
;   PERFORM A RUNNING 1 AND 0 TEST ON ALL RAMS. THE MAJORITY OF RAMS ARE OF TYPE 4016 ( 2K*8 )
;   EXCEPT FOR THE NON-VOLATILE RAM WHICH IS 100*4.
;   THIS TEST ASSUMES THAT ALL RAM HAS BEEN CLEARED BEFORE GETTING HERE.
;------------------------------------------------------------------------------
RAMTST:
LF380:  LDS  #$0000                 ;USE S TO FLAG ERRORS
LF384:  LDU  #TRAMP                 ;TABLE OF RAM POINTERS
LF387:  LDX  ,U++                   ;BLOCK POINTER
LF389:  LDY  #$0800                 ;BLOCK SIZE ( 2K*8 )
LF38D:  LDA  ,X                     ;START WITH NEXT BYTE
LF38F:  BEQ  LF39D                  ;IFNE  ERROR---SHOULD BE ZERO
LF391:  TFR  S,D                    ;ERR
LF393:  ORA  BITS-TRAMP-2,U
LF396:  ORB  BITS-TRAMP-1,U
LF399:  TFR  D,S
LF39B:  BRA  RAMTST_100
LF39D:  LDA  #$80                   ;FLOATING ONE TEST
LF39F:  LSLA                        ;SETUP CARRY TOO(1,000)

RAMTST_30:
LF3A0:  ROLA                        ;FORM NEXT TEST
LF3A1:  STA  ,X
LF3A3:  TFR  A,B
LF3A5:  EORB ,X
LF3A7:  BEQ  LF3B5                  ;IFNE  ERROR---SHOULD HAVE MATCHED
LF3A9:  TFR  S,D                    ;ERR
LF3AB:  ORA  BITS-TRAMP-2,U
LF3AE:  ORB  BITS-TRAMP-1,U
LF3B1:  TFR  D,S
LF3B3:  BRA  RAMTST_100
LF3B5:  BCC  RAMTST_50              ;?END OF FLOATING ONE?(=1,000)
LF3B7:  TSTA
LF3B8:  BNE  RAMTST_30              ;B NOPE, WAS FLOATING ZERO
LF3BA:  ADDA #$FF                   ;YEP, PREPARE FOR FLOATING ZERO
LF3BC:  BRA  RAMTST_30              ;J (1,000),ADDA#0FF,(0,0FF),ROLA,(1,0FE)

RAMTST_50:
LF3BE:  TFR  A,B
LF3C0:  INCB                        ;?END OF FLOATING ZERO?(=0,0FF)
LF3C1:  BNE  RAMTST_30              ;B NOT YET
LF3C3:  STA  WTCHDG                 ;KEEP THE DOG QUIET
;INCREMENT X TO NEXT BYTE
LF3C6:  CMPU #MRAM0+2               ;MATH RAM?? ( SPECIAL CASE FOR MATH RAM )
LF3CA:  BEQ  RAMTST_80
LF3CC:  CMPU #MRAM1+2
LF3D0:  BNE  LF3D6                  ;IFEQ  YES, MATH RAM

RAMTST_80:
LF3D2:  LEAX 2,X                    ;THEN DO EVERY OTHER BYTE
LF3D4:  BRA  LF3D8                  ;ELSE
LF3D6:  LEAX 1,X                    ;DO EVERY BYTE
LF3D8:  LEAY -$1,Y                  ;DECREMENT BLOCK LENGTH COUNT, DONE?
LF3DA:  BNE  LF38D                  ;EQEND

RAMTST_100:
LF3DC:  CMPU #TRAMPZ                ;END OF TABLE?
LF3E0:  BLO  LF387                  ;HSEND

FINCLR:          ;PERFORM A FINAL CLEAR OF ALL RAMS
;PREVIOUS TESTING LEFT ALL DATA AT 0FF
LF3E2:  LDU  #TRAMP
LF3E5:  LDX  ,U++
LF3E7:  LDY  #$0800                 ;BLOCK SIZE COUNTER
LF3EB:  INC  ,X                     ;SHOULD INC FROM 0FF TO 00
LF3ED:  BEQ  LF3FB                  ;IFNE  WASN'T 0FF --- ERROR
LF3EF:  TFR  S,D                    ;ERR
LF3F1:  ORA  BITS-TRAMP-2,U
LF3F4:  ORB  BITS-TRAMP-1,U
LF3F7:  TFR  D,S
LF3F9:  BRA  FINCLR_100
LF3FB:  LDA  ,X                     ;INC SHOULD HAVE LEFT A 00
LF3FD:  BEQ  LF40B                  ;IFNE  WASN'T 00 --- ERROR
LF3FF:  TFR  S,D                    ;ERR
LF401:  ORA  BITS-TRAMP-2,U
LF404:  ORB  BITS-TRAMP-1,U
LF407:  TFR  D,S
LF409:  BRA  FINCLR_100
LF40B:  STA  WTCHDG                 ;MUZZLE THE DOG
;INCREMENT X TO NEXT BYTE
LF40E:  CMPU #MRAM0+2               ;MATH RAM?? ( SPECIAL CASE FOR MATH RAM )
LF412:  BEQ  FINCLR_80
LF414:  CMPU #MRAM1+2
LF418:  BNE  LF41E                  ;IFEQ  YES, MATH RAM

FINCLR_80:
LF41A:  LEAX 2,X                    ;THEN DO EVERY OTHER BYTE
LF41C:  BRA  LF420                  ;ELSE
LF41E:  LEAX 1,X                    ;DO EVERY BYTE
LF420:  LEAY -$1,Y                  ;DECREMENT BLOCK LENGTH COUNT, DONE?
LF422:  BNE  LF3EB                  ;EQEND

FINCLR_100:
LF424:  CMPU #TRAMPZ                ;END OF TABLE?
LF428:  BLO  LF3E5                  ;HSEND
;NON-VOLATILE RAM TEST
LF42A:  TFR  S,D                    ;IS PROGRAM RAM OK?
LF42C:  ANDB #$01
LF42E:  BNE  LF43F                  ;IFEQ  YES, USE IT FOR EEBUFF
LF430:  LDX  #NVRAM
LF433:  LDU  #EEBUF
LF436:  LDD  ,X++
LF438:  STD  ,U++
LF43A:  CMPX #NVRAMZ
LF43D:  BLO  LF436                  ;HSEND
LF43F:  LDU  #TRAMPZ+2              ;POINTER FOR ERROR BITS

NVRTST:
LF442:  LDX  #NVRAM                 ;CLEAR IT FIRST
LF445:  LDD  #$0000
LF448:  STD  ,X++
LF44A:  CMPX #NVRAMZ
LF44D:  BLO  LF448                  ;HSEND
LF44F:  LDX  #NVRAM
LF452:  LDA  ,X
LF454:  ANDA #$0F                   ;LOW NIBBLE ONLY
LF456:  BEQ  LF464                  ;IFNE
LF458:  TFR  S,D                    ;ERR
LF45A:  ORA  BITS-TRAMP-2,U
LF45D:  ORB  BITS-TRAMP-1,U
LF460:  TFR  D,S
LF462:  BRA  NVRTST_100
LF464:  LDA  #$80
LF466:  LSLA                        ;SET PATTERN (1,00)
LF467:  LDY  #$0004                 ;SET COUNT

NVRTST_30:
LF46B:  ROLA
LF46C:  STA  ,X
LF46E:  TFR  A,B
LF470:  EORB ,X
LF472:  ANDB #$0F
LF474:  BEQ  LF482                  ;IFNE  SHOULD HAVE MATCHED
LF476:  TFR  S,D                    ;ERR
LF478:  ORA  BITS-TRAMP-2,U
LF47B:  ORB  BITS-TRAMP-1,U
LF47E:  TFR  D,S
LF480:  BRA  NVRTST_100
LF482:  LEAY -$1,Y                  ;DONE WITH THIS PASS?
LF484:  BNE  NVRTST_30              ;NO, CONTINUE
LF486:  TSTA                        ;YES, WHAT PHASE
LF487:  BMI  LF491                  ;IFPL  WAS RUNNING 1, MAKE IT RUNNING 0
LF489:  LDA  #$FF                   ;C SHOULD BE CLEAR STILL
LF48B:  LDY  #$0005                 ;COUNT OF 5 WILL LEAVE NIBBLE AS F
LF48F:  BRA  NVRTST_30
LF491:  STA  WTCHDG
LF494:  LEAX 1,X                    ;NEXT BYTE
LF496:  CMPX #NVRAMZ                ;DONE?
LF499:  BLO  LF452                  ;HSEND
;OK CHECK USING A FINAL CLEAR
LF49B:  LDX  #NVRAM
LF49E:  INC  ,X                     ;WAS LEFT AS xF, NOW SHOULD BE x0
LF4A0:  LDA  ,X+
LF4A2:  ANDA #$0F                   ;LOW NIBBLE ONLY
LF4A4:  BEQ  LF4B2                  ;IFNE  WRONG
LF4A6:  TFR  S,D                    ;ERR
LF4A8:  ORA  BITS-TRAMP-2,U
LF4AB:  ORB  BITS-TRAMP-1,U
LF4AE:  TFR  D,S
LF4B0:  BRA  NVRTST_100
LF4B2:  CMPX #NVRAMZ                ;DONE?
LF4B5:  BLO  LF49E                  ;HSEND

NVRTST_100:
LF4B7:  TFR  S,D
LF4B9:  ANDB #$01
LF4BB:  BNE  LF4CE                  ;IFEQ  PROGRAM RAM ( EEBUF ) OK
LF4BD:  LDX  #EEBUF                 ;COPY DATA BACK TO NVRAM
LF4C0:  LDU  #NVRAM
LF4C3:  LDD  ,X++
LF4C5:  STD  ,U++
LF4C7:  CMPX #EEBUF+$100
LF4CA:  BLO  LF4C3                  ;HSEND
LF4CC:  BRA  LF4EC                  ;ELSE  NO EEBUF
LF4CE:  LDA  #$FF                   ;PERFORM A RECALL OF THE NON-VOLATILE MEMORY
LF4D0:  STA  NVRRCL
LF4D3:  LDX  #$0100                 ;WAIT FOR THE CAP TO DISCHARGE
LF4D6:  STA  WTCHDG
LF4D9:  LEAX -$1,X
LF4DB:  BNE  LF4D6                  ;EQEND
LF4DD:  LDA  #$00                   ;TURN OFF RECALL LINE
LF4DF:  STA  NVRRCL
LF4E2:  LDX  #$A000                 ;NOW WAIT FOR THE CAP TO CHARGE BACK UP
LF4E5:  STA  WTCHDG
LF4E8:  LEAX -$1,X
LF4EA:  BNE  LF4E5                  ;EQEND
LF4EC:  STA  WTCHDG                 ;KEEP THE DOG HAPPY

ROMTST:
;SPECIAL DEAL FOR FIRST ROM, BANK SELECTED HALVES OF A 27128
LF4EF:  LDA  #$00                   ;SWITCH TO FIRST HALF
LF4F1:  STA  W_BANK
LF4F4:  LDX  TROMP                  ;GET POINTER FOR FIRST ROM
LF4F7:  LDY  #$2000                 ;EACH HALF OF THE 27128 IS 8K LONG
LF4FB:  TFR  X,D                    ;USE ADDRESS AS SEED
LF4FD:  ADCB 1,X
LF4FF:  ADCA ,X++
LF501:  STA  WTCHDG                 ;SHUT THE DOG UP
LF504:  LEAY -$2,Y
LF506:  BNE  LF4FD                  ;EQEND  END OF FIRST HALF
LF508:  TFR  D,X                    ;SAVE CURRENT CHECKSUM
LF50A:  LDA  #$FF
LF50C:  STA  W_BANK                 ;SWITCH BANKS
LF50F:  LDU  #TROMP+2               ;SETUP U CORRECTLY FOR ERROR AND LATER TESTS
LF512:  TFR  X,D                    ;GET CHECKSUM BACK
LF514:  LDY  #$2000                 ;OTHER HALF IS 8K ALSO
LF518:  LDX  TROMP                  ;STARTING ADDRESS
LF51B:  BRA  ROMTST_30              ;CONTINUE WITH THE CHECKSUMMING
LF51D:  LDU  #TROMP+2               ;TABLE OF ROM POINTERS, SECOND ROM
LF520:  LDX  ,U++                   ;GET POINTER
LF522:  LDY  #$2000                 ;2764s ARE 8K LONG

ROMTST_20:
LF526:  TFR  X,D                    ;USE ADDRESS AS SEED

ROMTST_30:
LF528:  ADCB 1,X
LF52A:  ADCA ,X++
LF52C:  STA  WTCHDG                 ;SHUT THE DOG UP
LF52F:  LEAY -$2,Y
LF531:  BNE  ROMTST_30              ;EQEND
LF533:  STD  CHKSUM-TROMP-2,U
LF537:  BEQ  LF543                  ;IFNE  ERROR
LF539:  TFR  S,D
LF53B:  ORA  BITS-TRAMP-2,U
LF53E:  ORB  BITS-TRAMP-1,U
LF541:  TFR  D,S
LF543:  CMPU #TROMPZ
LF547:  BLO  LF520                  ;HSEND
LF549:  CMPU #TROMPZ+2
LF54D:  BHS  LF557                  ;IFLO
LF54F:  LDX  ,U++
LF551:  LDY  #$1000
LF555:  BRA  ROMTST_20
LF557:  LDA  #$FF                   ;TURN OFF THE LEDS
LF559:  STA  W_LED1
LF55C:  STA  W_LED2
LF55F:  STA  W_LED3
LF562:  CLR  SIGFLG
LF564:  LDA  DIAGSW                 ;CHECK FOR DIAGNOSTIC SWITCH
LF567:  ANDA #DIAGBT
LF569:  BNE  LF56E                  ;IFEQ  ITS ON, DO DIAGNOSTICS
LF56B:  JMP  DIAGLP
LF56E:  STA  WTCHDG                 ;HIT THE DOG

;.SBTTL DISPLAY THE RESULTS

TSTOUT:
LF571:  STS  ERRORS                 ;SAVE ERRORS FOR LATER
LF574:  TFR  S,D
LF576:  ANDB #$01                   ;PROGRAM RAM OK? ( VARIABLES AND STACK )
LF578:  BNE  LF5ED                  ;IFEQ  NO, SPECIAL FAILURE MODE
;YES, THEN ATTEMP TO USE VG FOR ERROR DISPLAY
;SETUP FOR DISPLAY
LF57A:  LDY  #VGRAM                 ;VG POINTER
LF57E:  LDD  #VGCOLR&$FF00          ;COLOR OFF
LF581:  STD  ,Y++
LF583:  LDD  #VJBONDRY              ;DRAW A BOX TO FOOL THE BEAM KILLER
LF586:  STD  ,Y++
LF588:  LDD  #VGCNTR
LF58B:  STD  ,Y++
LF58D:  LDA  #$48                   ;SET DPAGE REGISTER
LF58F:  TFR  A,DP
LF591:  STS  TTEMP                  ;SAVE ERRORS IN RAM
LF594:  LDS  #STACK                 ;SET STACK
LF598:  LDB  #MS_XIT                ;"PRESS AUX SWITCH TO CONTINUE"
LF59A:  JSR  DOMESS
LF59D:  LDB  #MS_RAM                ;"HARDWARE ERRORS"
LF59F:  JSR  DOMESS
LF5A2:  LDB  #MS_RAM+2              ;START WITH ERROR MESSAGES
LF5A4:  STB  TTEMP2
LF5A6:  LDD  TTEMP                  ;ERRORS?
LF5A8:  BNE  LF5B1                  ;IFEQ  NO ERRORS
LF5AA:  LDB  #MS_RAM+1              ;"NO ERRORS DETECTED"
LF5AC:  JSR  DOMESS
LF5AF:  BRA  LF5EB                  ;ELSE  YES, THERE ARE ERRORS
LF5B1:  LSRA                        ;LSRD  SHIFT IT
LF5B2:  RORB
LF5B3:  STD  TTEMP                  ;STORE IT BACK
LF5B5:  BCC  LF5E5                  ;IFCS  HAD AN ERROR THERE
LF5B7:  LDB  TTEMP2                 ;MESSAGE NUMBER FOR THIS ERROR
LF5B9:  JSR  DOMESS                 ;SAY IT
LF5BC:  LDB  TTEMP2
LF5BE:  SUBB #MS_RAM+12             ;ROM ERROR MESSAGES?
LF5C0:  BLO  LF5E5                  ;IFHS  YES, THEN OUTPUT THE CHECKSUM
LF5C2:  ASLB
LF5C3:  LDX  #TSUMY                 ;POSITION TO THE RIGHT OF THE MESSAGE
LF5C6:  ABX
LF5C7:  LDU  ,X
LF5C9:  STU  ,Y++
LF5CB:  LDU  #$0120
LF5CE:  STU  ,Y++
LF5D0:  LDX  #CHKSUM                ;GET THE DATA
LF5D3:  ABX
LF5D4:  LDA  ,X+
LF5D6:  COMA
LF5D7:  JSR  VWBYTE
LF5DA:  LDA  ,X
LF5DC:  COMA
LF5DD:  JSR  VWBYTE
LF5E0:  LDD  #VGCNTR
LF5E3:  STD  ,Y++
LF5E5:  INC  TTEMP2                 ;NEXT MESSAGE NUMBER
LF5E7:  LDD  TTEMP                  ;DONE WHEN NO ERRORS LEFT TO DISPLAY
LF5E9:  BNE  LF5B1                  ;EQEND
LF5EB:  BRA  TSTOUT_100             ;LEAVE
;NOTHING WORKS, TRY TO MAKE ERROR TONES
LF5ED:  LDX  #$0008
LF5F0:  TFR  S,D
LF5F2:  LSRB
LF5F3:  BCC  LF5F9                  ;IFCS  ERROR ON
LF5F5:  LDA  #IDANAY                ;ERROR SOUND
LF5F7:  BRA  LF5FB                  ;ELSE
LF5F9:  LDA  #IDAYEA                ;NON-ERROR SOUND
LF5FB:  STA  W_XMTS
LF5FE:  LDU  #$0000                 ;1/2 SECOND DELAY
LF601:  STB  WTCHDG
LF604:  LEAU 1,U
LF606:  CMPU #$A000
LF60A:  BLO  LF601                  ;HSEND
LF60C:  LEAX -$1,X
LF60E:  BNE  LF5F2                  ;EQEND
;NOW THE OTHER HALF OF THE ERRORS
LF610:  LDX  #$0008
LF613:  TFR  S,D
LF615:  LSRA
LF616:  BCC  LF61C                  ;IFCS  ERROR ON
LF618:  LDB  #IDANAY                ;ERROR SOUND
LF61A:  BRA  LF61E                  ;ELSE
LF61C:  LDB  #IDAYEA                ;NON-ERROR SOUND
LF61E:  STB  W_XMTS
LF621:  LDU  #$0000                 ;1/2 SECOND DELAY
LF624:  STA  WTCHDG
LF627:  LEAU 1,U
LF629:  CMPU #$A000
LF62D:  BLO  LF624                  ;HSEND
LF62F:  LEAX -$1,X
LF631:  BNE  LF615                  ;EQEND
;DELAY, THEN REPEAT
LF633:  LDU  #$0000
LF636:  STA  WTCHDG
LF639:  LEAU 1,U
LF63B:  CMPU #$FF00
LF63F:  BLO  LF636                  ;HSEND
LF641:  BRA  LF5ED                  ;LOOP

TSTOUT_100:
LF643:  LDD  #$2020                 ;HALT
LF646:  STD  ,Y++

;.SBTTL TEST MAINLINE
LF648:  LDU  #TSTATE                ;SET UP FIRST TEST STATE
LF64B:  CLR  COLOR                  ;START WITH THE FIRST COLOR IN TABLE
LF64D:  LDA  #$03                   ;INIT SWITCH DEBOUNCERS
LF64F:  STA  DBNC
LF651:  STA  DBNC2
LF653:  STA  DBNC3
LF655:  STA  ERRCNT                 ;START NOISES QUICKLY
LF657:  LDX  #BITS                  ;SET UP FOR HARDWARE ERROR DISPLAY ( FIRST STATE )
LF65A:  STX  ERRPNT

TSTLP:
LF65C:  LDD  #$0001
LF65F:  LDX  #$0000
LF662:  STA  WTCHDG                 ;5 CYCLES ---- SHUT THE DOG UP
LF665:  LEAX D,X                    ;8 CYCLES
LF667:  CMPX #$0708                 ;4 CYCLES
LF66A:  BLO  LF662                  ;HSEND  3 CYCLES = 20 CYCLES * 1800. /1.5MHz = 24ms
LF66C:  STA  VGSTOP                 ;STOP THE VECTOR GENERATOR, SHOULD HAVE PREVIOUSLY HALTED
LF66F:  LDA  DIAGSW                 ;CHECK FOR DIAGNOSTIC SWITCH
LF672:  ANDA #DIAGBT
LF674:  BNE  LF679                  ;IFEQ  IT IS ON
LF676:  JMP  HANG                   ;GO DO THEM BUT RESET FIRST
;DEBOUNCE SWITCHES AND SET PARAMS
LF679:  LDA  AUXSW                  ;CHECK AUX SWITCH
LF67C:  ANDA #AUXBIT
LF67E:  BNE  LF69F                  ;IFEQ  SWITCH WAS THERE
LF680:  LDA  DBNC
LF682:  BEQ  LF69D                  ;IFNE
LF684:  DECA
LF685:  BNE  LF69D                  ;IFEQ
LF687:  LEAU 2,U                    ;INC STATE
LF689:  CMPU #TSTATZ                ;END OF STATE TABLE?
LF68D:  BLO  LF692                  ;IFHS
LF68F:  LDU  #TSTATE+2
LF692:  LDD  #$0000
LF695:  STD  SCALE                  ;ALWAYS START THE SCALE TEST WITH LARGEST SCALE
LF697:  STA  SCLTYP                 ;ALWAYS START THE SCALE TEST WITH LINEAR TEST
LF699:  STA  COLOR                  ;ALWAYS START AT FIRST COLOR IN TABLE ( RED )
LF69B:  LDA  #$80                   ;AUTO REPEAT TIMER
LF69D:  BRA  LF6A1                  ;ELSE  NO SWITCHES ON
LF69F:  LDA  #$03                   ;WANT TO SEE IT THIS MANY TIMES FOR A DEBOUNCE
LF6A1:  STA  DBNC
LF6A3:  LDA  IN0                    ;DEBOUNCE FIRE SWITCH FOR COLOR CHANGES
LF6A6:  COMA                        ;CHECK FOR EITHER FIRE SWITCH
LF6A7:  ANDA #FIREBT
LF6A9:  BEQ  LF6C7                  ;IFNE
LF6AB:  LDA  DBNC2
LF6AD:  BEQ  LF6C5                  ;IFNE
LF6AF:  DECA
LF6B0:  BNE  LF6C5                  ;IFEQ  INC COLOR FROM TABLE
LF6B2:  LDB  COLOR
LF6B4:  ADDB #$02
LF6B6:  CMPB #TCOLRZ-TCOLR
LF6B8:  BLO  LF6BB                  ;IFHS  END OF TABLE, START OVER
LF6BA:  CLRB
LF6BB:  STB  COLOR
LF6BD:  CMPB #(TCOLRW-TCOLR)/2      ;WHITE?
LF6BF:  BNE  LF6C3                  ;IFEQ  YES, ALWAYS MAKE A NEW WHITE BRIGHT
LF6C1:  CLR  BRITE
LF6C3:  LDA  #$80                   ;AUTO REPEAT TIMER
LF6C5:  BRA  LF6C9                  ;ELSE  NO SWITCHES ON
LF6C7:  LDA  #$03                   ;WANT TO SEE IT THIS MANY TIMES TO DEBOUNCE
LF6C9:  STA  DBNC2
LF6CB:  CMPU #TSTATZ-2              ;RASTER TEST?
LF6CF:  BNE  LF6F0                  ;IFEQ  YES, THEN CHECK FOR BRIGHTNESS CHANGE
LF6D1:  LDA  IN1                    ;USE THUMB BUTTONS FOR CHANGE
LF6D4:  COMA
LF6D5:  ANDA #THMBT
LF6D7:  BEQ  LF6EA                  ;IFNE  SWITCH IS ON
LF6D9:  LDA  DBNC3
LF6DB:  BEQ  LF6E8                  ;IFNE
LF6DD:  DECA
LF6DE:  BNE  LF6E8                  ;IFEQ  TIME TO CHANGE
LF6E0:  LDB  BRITE
LF6E2:  EORB #$01
LF6E4:  STB  BRITE
LF6E6:  LDA  #$80                   ;AUTO REPEAT TIMER
LF6E8:  BRA  LF6EC                  ;ELSE  SWITCHES NOT ON
LF6EA:  LDA  #$03                   ;NORMAL DEBOUNCE COUNT
LF6EC:  STA  DBNC3
LF6EE:  BRA  LF6F2                  ;ELSE  NOPE, NOT THE RASTER TEST
LF6F0:  CLR  BRITE                  ;THEN MAKE SURE FLAG NOT SET
LF6F2:  LDY  #VGRAM                 ;SETUP POINTER
LF6F6:  LDB  COLOR                  ;OUTPUT COLOR COMMAND
LF6F8:  LDX  #TCOLR
LF6FB:  LDD  B,X
LF6FD:  CMPD #VGCOLR+(VGCWHT*$100)  ;WHITE?
LF701:  BNE  LF709                  ;IFEQ
LF703:  TST  BRITE
LF705:  BEQ  LF709                  ;IFNE  WANTS THE DIMMER WHITE FOR COLOR TRACKING
LF707:  LDB  #$20                   ;INSTEAD OF THE NORMAL 80
LF709:  STD  ,Y++
LF70B:  JMP  [,U]                   ;EXECUTE THAT STATE

;------------------------------------------------------------------------------
; GETBAK - GO BACK TO MAIN TEST LOOP  (comment at the call)
;   GO BACK TO THE MAINLINE  (another call)
;------------------------------------------------------------------------------
GETBAK:
LF70D:  LDD  #$2020                 ;PUT A COUPLE OF HALTS AT END
LF710:  STD  ,Y++
LF712:  STD  ,Y++

GETBK2:
LF714:  STA  VGGO                   ;START THE VECTOR GENERATOR
LF717:  LDA  TESTSW                 ;CHECK FOR TEST SWITCH
LF71A:  ANDA #TESTBT
LF71C:  LBEQ TSTLP                  ;NEEND  FALL THROUGH IF NO TEST SWITCH

HANG:
LF720:  JMP  HANG                   ;WAIT FOR WATCHDOG

TSTATE:
LF723:  .word SDISP                 ;DISPLAY RAM-ROM ERRORS

TSTAT3:
LF725:  .word SSWTCH                ;SWITCH TEST

TSTAT1:
LF727:  .word SDIV                  ;MATHBOX TESTS -- DIVIDER AND MATRIX PROC.
LF729:  .word SHATCH                ;CROSSHATCH PATTERN
LF72B:  .word SCHKR                 ;CHECKER BOARD PATTERN
LF72D:  .word SINTEN                ;COLOR INTENSITY PATTERN
LF72F:  .word SBIP                  ;BIP PATTERN
LF731:  .word SSCAL                 ;SCALE PATTERN
LF733:  .word SRASTR                ;RASTER PATTERN

TSTATZ:
TCOLR:
LF735:  .word VGCOLR+(VGCRED*$100)  ;COLORS FOR PATTERN TESTS
LF737:  .word VGCOLR+(VGCGRN*$100)
LF739:  .word VGCOLR+(VGCBLU*$100)
LF73B:  .word VGCOLR+(VGCPRP*$100)

TCOLRW:
LF73D:  .word VGCOLR+(VGCWHT*$100)
LF73F:  .word VGCOLR+(VGCYLW*$100)
LF741:  .word VGCOLR+(VGCTRQ*$100)

TCOLRZ:
TSUMY:
LF743:  .word $1F38
LF745:  .word $1F06
LF747:  .word $1ED4
LF749:  .word $1EA2
LF74B:  .word $1E70
LF74D:  .word $1F6A

;------------------------------------------------------------------------------
; TSUMYZ - SWITCH AND POT TEST
;   (also: SDISP)
;------------------------------------------------------------------------------
TSUMYZ:
SDISP:
LF74F:  DEC  ERRCNT                 ;TIME?
LF751:  BPL  LF77C                  ;IFMI  YES, TIME TO SOUND OFF
LF753:  LDA  #$10                   ;RESET TIMER FOR THE NEXT BIT
LF755:  STA  ERRCNT
LF757:  LDX  ERRPNT                 ;INDEXES INTO BIT TABLE
LF759:  LDD  ERRORS                 ;CHECK IT OUT
LF75B:  ANDA ,X
LF75D:  BNE  SDISP_30               ;ERROR DETECTED, GO SAY NAY
LF75F:  ANDB 1,X                    ;A WAS CLEAN, HOW ABOUT B?
LF761:  BNE  SDISP_30               ;IFEQ  B CLEAN TOO, SAY YEA
LF763:  LDA  #IDAYEA
LF765:  BRA  LF769                  ;ELSE  MAKE ERROR SOUND ( NAY )

SDISP_30:
LF767:  LDA  #IDANAY
LF769:  STA  W_XMTS                 ;SHOVE IT OUT TO THE SOUND BOARD
LF76C:  LEAX 2,X
LF76E:  CMPX #BITS+$20              ;END OF BIT TABLE?
LF771:  BLO  LF77A                  ;IFHS  YES
LF773:  LDA  #$20                   ;DELAY LONGER BEFORE STARTING OVER
LF775:  STA  ERRCNT
LF777:  LDX  #BITS
LF77A:  STX  ERRPNT
LF77C:  JMP  GETBK2                 ;DO NOTHING

;------------------------------------------------------------------------------
; SSWTCH - SWITCH TEST  (comment at its table entry)
;------------------------------------------------------------------------------
SSWTCH:
LF77F:  STA  W_CHN0                 ;START POT 0 READING FOR LATER
LF782:  STA  W_CHN0                 ;MAKES IT A GOOD START
LF785:  LDD  #VJBONDRY              ;DRAW THE BORDER
LF788:  STD  ,Y++
LF78A:  LDD  #VGCNTR
LF78D:  STD  ,Y++
LF78F:  LDS  #STACK                 ;SET STACK
LF793:  LDB  #MS_SWT                ;"SWITCH TEST"
LF795:  JSR  DOMESS
LF798:  LDB  #MS_XIT                ;"PRESS AUX COIN TO CONTINUE"
LF79A:  JSR  DOMESS
LF79D:  LDB  #MS_SWT+1              ;MESSAGES FOR SWITCHES
LF79F:  STB  TTEMP2
LF7A1:  LDA  R_BYT0                 ;GET SWITCH DATA
LF7A4:  LDB  R_BYT1
LF7A7:  ORB  #$C7                   ;DISALLOW NON-SWITCHES (IE MATHBOX READY,VG HALTED,ETC.)
LF7A9:  STD  TTEMP
LF7AB:  ASLB                        ;ASLD  SHIFT BIT TO CARRY
LF7AC:  ROLA
LF7AD:  STD  TTEMP                  ;SAVE FOR NEXT SWITCH
LF7AF:  BCS  LF7B6                  ;IFCC  SWITCH WAS ON
LF7B1:  LDB  TTEMP2                 ;DISLAY MESSAGE
LF7B3:  JSR  DOMESS
LF7B6:  INC  TTEMP2                 ;NEXT POSSIBLE MESSAGE
LF7B8:  LDD  TTEMP                  ;SWITCH DATA
LF7BA:  BNE  LF7AB                  ;EQEND
;FIND SWITCH EDGES AND MAKE SOUND
LF7BC:  LDD  SWNEW                  ;PUT LAST TIMES NEW INTO THIS TIMES OLD
LF7BE:  STD  SWOLD
LF7C0:  LDA  R_BYT0                 ;READ IN SWITCHES IN QUESTION
LF7C3:  ANDA #$CF
LF7C5:  LDB  R_BYT1
LF7C8:  ANDB #$3A
LF7CA:  STD  SWNEW                  ;SAVE AS NEW
LF7CC:  EORA SWOLD                  ;CATCH OFF TO ON EDGES
LF7CE:  ANDA SWOLD
LF7D0:  EORB SWOLD+1
LF7D2:  ANDB SWOLD+1
LF7D4:  CMPD #$0000
LF7D8:  BEQ  LF7DF                  ;IFNE  CAUGHT AN EDGE, MAKE A SOUND
LF7DA:  LDA  #IDAYEA
LF7DC:  STA  W_XMTS
;OPTION SWITCHES
LF7DF:  LDD  #$1EA2                 ;POSITION FOR OPTION SWITCH DISPLAY
LF7E2:  STD  ,Y++
LF7E4:  LDD  #$1F74
LF7E7:  STD  ,Y++
LF7E9:  LDA  #$10                   ;SHOW OPTION SWITCH BANK LOCATION ( 10D )
LF7EB:  JSR  VWBYTE
LF7EE:  LDD  VGMSGA+28
LF7F1:  STD  ,Y++
LF7F3:  LDD  VGMSGA
LF7F6:  STD  ,Y++
LF7F8:  LDA  R_BYT2                 ;1ST BANK OF OPTION SWITCHES
LF7FB:  JSR  SWDISP                 ;SHOW 'EM
LF7FE:  LDD  #$1E70
LF801:  STD  ,Y++
LF803:  LDD  #$1F5C
LF806:  STD  ,Y++
LF808:  LDA  #$10                   ;SHOW OPTION SWITCH BANK LOCATION ( 10EF )
LF80A:  JSR  VWBYTE
LF80D:  LDD  VGMSGA+30
LF810:  STD  ,Y++
LF812:  LDD  VGMSGA+32
LF815:  STD  ,Y++
LF817:  LDD  VGMSGA
LF81A:  STD  ,Y++
LF81C:  LDA  R_BYT3                 ;2ND BANK OF OPTION SWITCHES
LF81F:  JSR  SWDISP                 ;SHOW 'EM
;POT TEST
LF822:  LDB  #MS_POT                ;"POT TEST"
LF824:  JSR  DOMESS
LF827:  LDD  #VJPOTP                ;SHOW PATTERN AROUND POT TEST LINE
LF82A:  STD  ,Y++
LF82C:  LDD  #$0000                 ;POSITION TO THE RIGHT
LF82F:  STD  ,Y++
LF831:  LDD  #$0140
LF834:  STD  ,Y++
LF836:  LDB  R_CHN                  ;READ Y POT
LF839:  SUBB #$80                   ;MAKE READING RELATIVE TO CENTER
LF83B:  SEX
LF83C:  TFR  D,U                    ;COMPENSATE FOR 1.5/1 ASPECT RATIO
LF83E:  ASRA                        ;ASRD  1/2
LF83F:  RORB
LF840:  LEAU D,U                    ;GENERATED 1.5 FOR THE Y POT
LF842:  TFR  U,D                    ;GET IT BACK
LF844:  ANDA #$1F
LF846:  STD  ,Y++
LF848:  STA  W_CHN1                 ;START X POT
LF84B:  STA  W_CHN1                 ;MAKE SURE IT STARTS CORRECTLY
LF84E:  LDX  #$0014
LF851:  LEAX -$1,X
LF853:  BNE  LF851                  ;EQEND
LF855:  LDB  R_CHN
LF858:  SUBB #$80
LF85A:  SEX
LF85B:  ANDA #$1F
LF85D:  ORA  #$E0                   ;TURN THIS LINE ON
LF85F:  STD  ,Y++
LF861:  LDD  #VGCNTR
LF864:  STD  ,Y++
LF866:  LDU  #TSTAT3                ;DESTROYED U, SET BACK TO SWITCH TEST STATE
LF869:  JMP  GETBAK                 ;GO BACK TO MAIN TEST LOOP

;------------------------------------------------------------------------------
; SWDISP - DISPLAY 8 SWITCHES IN "0" OR "1" FORM
;------------------------------------------------------------------------------
SWDISP:
LF86C:  LDB  #$07                   ;COUNT
LF86E:  LSRA                        ;SHIFT SWITCH INTO CARRY
LF86F:  BCC  LF876                  ;IFCS  NOT ON
LF871:  LDX  VGMSGA+32              ;"F" FOR OFF
LF874:  BRA  LF879                  ;ELSE  WAS ON
LF876:  LDX  VGMSGA+48              ;"N" FOR ON
LF879:  STX  ,Y++
LF87B:  DECB
LF87C:  BPL  LF86E                  ;MIEND
LF87E:  LDD  #VGCNTR
LF881:  STD  ,Y++
LF883:  RTS

;------------------------------------------------------------------------------
; SCHKR - SCREEN TEST PATTERNS
;------------------------------------------------------------------------------
SCHKR:
LF884:  LDD  #VJCHKR                ;CHECKER PATTERN
LF887:  STD  ,Y++
LF889:  JMP  GETBAK

;------------------------------------------------------------------------------
; SHATCH - CROSSHATCH PATTERN  (comment at its table entry)
;------------------------------------------------------------------------------
SHATCH:
LF88C:  LDD  #VJHTCH                ;CROSS HATCH PATTERN
LF88F:  STD  ,Y++
LF891:  JMP  GETBAK

;------------------------------------------------------------------------------
; SINTEN - COLOR INTENSITY PATTERN  (comment at its table entry)
;------------------------------------------------------------------------------
SINTEN:
LF894:  LDD  #VJINTN                ;COLOR BAR PATTERN
LF897:  STD  ,Y++
LF899:  LDB  #MS_INT                ;OUTPUT THE INTENSITY TEST MESSAGES
LF89B:  STB  TTEMP2
LF89D:  JSR  DOMESS
LF8A0:  LDB  TTEMP2
LF8A2:  INCB
LF8A3:  CMPB #MS_INT+5
LF8A5:  BLO  LF89B                  ;HSEND
LF8A7:  JMP  GETBAK

;------------------------------------------------------------------------------
; SBIP - BIP PATTERN  (comment at its table entry)
;------------------------------------------------------------------------------
SBIP:
LF8AA:  LDD  #VJBIP                 ;BIP PATTERN
LF8AD:  STD  ,Y++
LF8AF:  LDD  #VJBIP2                ;BOX WITHOUT CENTERS
LF8B2:  STD  ,Y++
LF8B4:  STD  ,Y++
LF8B6:  STD  ,Y++
LF8B8:  STD  ,Y++
LF8BA:  LDD  #VGCNTR
LF8BD:  STD  ,Y++
LF8BF:  LDB  #MS_BIP                ;"BIP TEST"
LF8C1:  JSR  DOMESS
LF8C4:  LDB  #MS_BIP+1              ;"ALIGN THE BOXES"
LF8C6:  JSR  DOMESS
LF8C9:  JMP  GETBAK

;------------------------------------------------------------------------------
; SSCAL - SCALE PATTERN  (comment at its table entry)
;------------------------------------------------------------------------------
SSCAL:
LF8CC:  LDA  DBNC2                  ;CHECK FOR TRIGGER SWITCH
LF8CE:  CMPA #$01
LF8D0:  BHI  LF8D9                  ;IFLS
LF8D2:  LDD  #$0000                 ;RESET TO LARGEST LINEAR SCALE TEST
LF8D5:  STD  SCALE
LF8D7:  STA  SCLTYP
LF8D9:  LDD  #VGCOLR&$F000          ;NO COLOR FOR THE BOX
LF8DC:  STD  ,Y++
LF8DE:  LDD  #VJBOX                 ;DRAW A BOX
LF8E1:  STD  ,Y++
LF8E3:  LDD  #VGCNTR
LF8E6:  STD  ,Y++
LF8E8:  LDD  SCALE                  ;UPDATE SCALE
LF8EA:  ADDD #$0001
LF8ED:  TST  SCLTYP                 ;WHICH TEST ARE WE DOING?
LF8EF:  BNE  LF900                  ;IFEQ  LINEAR SCALE TEST
LF8F1:  CMPB #$FC                   ;DONE YET?
LF8F3:  BLO  LF8FC                  ;IFHS  YEP, ALL DONE
LF8F5:  LDA  #$01
LF8F7:  STA  SCLTYP                 ;NON-ZERO MEANS GO TO COMBINED SCALE TEST
LF8F9:  LDD  #$0000                 ;START FROM 0000
LF8FC:  STD  SCALE
LF8FE:  BRA  LF917                  ;ELSE  COMBINATION SCALE TEST
LF900:  CMPB #$B0                   ;CAUSE A DELAY
LF902:  BLO  LF906                  ;IFHS  DELAY WHILE LINEAR IS 80 TO 0B0
LF904:  CLRB
LF905:  INCA
LF906:  CMPA #$08                   ;BINARY SCALE WRAP?
LF908:  BLO  LF90F                  ;IFHS  YES
LF90A:  CLR  SCLTYP                 ;THEN START LINEAR SCALE TEST AGAIN
LF90C:  LDD  #$0000
LF90F:  STD  SCALE
LF911:  CMPB #$7F                   ;IF LINEAR SCALE IS GREATER THAN 7F MAKE IT 7F
LF913:  BLO  LF917                  ;IFHS  THIS HOLDS THE SIZE OF THE SQUARE WHILE DELAYING
LF915:  LDB  #$7F
LF917:  ORA  #(VGSCAL&$F000)/$100   ;MAKE THIS A SCALE INSTRUCTION
LF919:  STD  ,Y++
LF91B:  LDD  #VGCOLR+(VGCGRN*$100)  ;GIVE IT SOME COLOR
LF91E:  STD  ,Y++
LF920:  LDD  #VJSQR                 ;USE SQAURE FOR SCALE TEST
LF923:  STD  ,Y++
LF925:  LDD  #VGSCAL
LF928:  STD  ,Y++
LF92A:  LDB  SCLTYP
LF92C:  BNE  LF932                  ;IFEQ  LINEAR SCALE TEST
LF92E:  LDB  #MS_SCL+1              ;"LINEAR"
LF930:  BRA  LF934                  ;ELSE
LF932:  LDB  #MS_SCL+2              ;"LINEAR AND BINARY"
LF934:  JSR  DOMESS
LF937:  LDB  #MS_SCL                ;"SCALE TEST"
LF939:  JSR  DOMESS
LF93C:  JMP  GETBAK

;------------------------------------------------------------------------------
; SRASTR - RASTER PATTERN  (comment at its table entry)
;------------------------------------------------------------------------------
SRASTR:
LF93F:  LDD  #VJRSTR                ;START OF PATTERN
LF942:  STD  ,Y++
LF944:  LDX  #$0038                 ;# OF LINES
LF947:  LDD  #VJRST2                ;EACH LINE
LF94A:  STD  ,Y++
LF94C:  LEAX -$1,X
LF94E:  BNE  LF94A                  ;EQEND
LF950:  LDD  #VGCNTR                ;CENTER
LF953:  STD  ,Y++
LF955:  JMP  GETBAK

;------------------------------------------------------------------------------
; SDIV - MATHBOX TEST --- DIVIDER
;------------------------------------------------------------------------------
SDIV:
LF958:  LDD  #VJBONDRY              ;PUT THE BOX OUT THERE
LF95B:  STD  ,Y++
LF95D:  LDD  #VGCNTR
LF960:  STD  ,Y++
LF962:  LDD  #VGSCAL
LF965:  STD  ,Y++
LF967:  LDS  #STACK                 ;SETUP THE STACK
LF96B:  LDB  #MS_MBT                ;"MATHBOX TESTS"
LF96D:  JSR  DOMESS
LF970:  LDA  #$5D                   ;DO A QUICKIE TEST FOR THE MATHBOX READY LINE
LF972:  STA  M_PCGO
LF975:  TST  M_BUSY                 ;IF READY ALREADY, ITS AN ERROR
LF978:  BPL  SDIV_10                ;ERROR
LF97A:  TST  M_BUSY                 ;IF READY NOW, GOOD. ELSE ERROR
LF97D:  BPL  SDIV_20

SDIV_10:
LF97F:  LDB  #MS_MBN                ;"BAD MATHBOX READY LINE" (MATH BOX NO)
LF981:  JSR  DOMESS
LF984:  LDU  #TSTAT1                ;STAY IN THIS TEST
LF987:  JMP  GETBAK                 ;GO BACK TO THE MAINLINE

SDIV_20:
;CONTINUE WITH MATHBOX TESTS
LF98A:  LDD  #VGCOLR+(VGCGRN*$100)  ;SHOW ERRORS IN GREEN
LF98D:  STD  ,Y++
LF98F:  CLR  TTEMP                  ;CLEAR ERROR FLAG
LF991:  LDX  #TDIV                  ;BEGINNING OF TABLE
LF994:  LDS  #SDIVRT                ;SET RETURN ADDRESS
LF998:  JMP  DIVTST                 ;GO DO CURRENT DIVIDER TEST INDICATED BY X

;------------------------------------------------------------------------------
; SDIVRT - RETURN FROM DIVIDER TEST
;   COMPARE TO CORRECT ANSWER WAS LAST THING DONE
;------------------------------------------------------------------------------
SDIVRT:
LF99B:  BEQ  LFA19                  ;IFNE  ERROR--THEN DISPLAY ERROR
LF99D:  STD  ERRORS                 ;ANSWER FROM DIVIDER
LF99F:  INC  TTEMP                  ;FLAG AN ERROR ( WON'T WRAP )
;SHOW OPTION SWITCH SETTING FOR DIAGNOSTIC
LF9A1:  LDS  #STACK                 ;SET STACK
LF9A5:  LDD  6,X                    ;Y POSITION ON SCREEN
LF9A7:  STD  ,Y++
LF9A9:  LDD  #$1E98                 ;X POS
LF9AC:  STD  ,Y++
LF9AE:  LDD  VGMSGA+48              ;"NNNN" FOR ON INDICATES DIVIDER TEST
LF9B1:  STD  ,Y++
LF9B3:  STD  ,Y++
LF9B5:  STD  ,Y++
LF9B7:  STD  ,Y++
LF9B9:  LDD  VGMSGA                 ;" "
LF9BC:  STD  ,Y++
LF9BE:  TFR  X,D                    ;WHICH TEST OF 16.
LF9C0:  SUBD #TDIV
LF9C3:  ASLB                        ;DISPLAY D6-D3
LF9C4:  LDA  #$03
LF9C6:  ASLB
LF9C7:  BCS  LF9CE                  ;IFCC
LF9C9:  LDU  VGMSGA+32              ;"F" FOR OFF
LF9CC:  BRA  LF9D1                  ;ELSE
LF9CE:  LDU  VGMSGA+48              ;"N" FOR ON
LF9D1:  STU  ,Y++
LF9D3:  DECA
LF9D4:  BPL  LF9C6                  ;MIEND
LF9D6:  LDD  VGMSGA                 ;COUPLE OF SPACES
LF9D9:  STD  ,Y++
LF9DB:  STD  ,Y++
LF9DD:  LDA  ,X                     ;NUMERATOR
LF9DF:  JSR  VWBYTE
LF9E2:  LDA  1,X
LF9E4:  JSR  VWBYTE
LF9E7:  LDD  VGMSGA
LF9EA:  STD  ,Y++
LF9EC:  LDA  2,X                    ;DENOMINATOR
LF9EE:  JSR  VWBYTE
LF9F1:  LDA  3,X
LF9F3:  JSR  VWBYTE
LF9F6:  LDD  VGMSGA
LF9F9:  STD  ,Y++
LF9FB:  LDA  4,X                    ;CORRECT ANSWER
LF9FD:  JSR  VWBYTE
LFA00:  LDA  5,X
LFA02:  JSR  VWBYTE
LFA05:  LDD  VGMSGA
LFA08:  STD  ,Y++
LFA0A:  LDA  ERRORS                 ;INCORRECT ANSWER
LFA0C:  JSR  VWBYTE
LFA0F:  LDA  ERRORS+1
LFA11:  JSR  VWBYTE
LFA14:  LDD  #VGCNTR
LFA17:  STD  ,Y++
LFA19:  LEAX 8,X
LFA1B:  CMPX #TDIVZ
LFA1E:  LBLO LF994                  ;HSEND
LFA22:  LDS  #STACK                 ;SET STACK FOR MESSAGES
LFA26:  TST  TTEMP                  ;ERRORS?
LFA28:  BNE  LFA2E                  ;IFEQ  NO
LFA2A:  LDB  #MS_DIV+1              ;"NO DIVIDER ERRORS"
LFA2C:  BRA  LFA35                  ;ELSE
LFA2E:  LDB  #MS_DIV                ;"DIVIDER ERRORS"
LFA30:  JSR  DOMESS
LFA33:  LDB  #MS_DIV+2              ;DIVIDER ERROR HEADING
LFA35:  JSR  DOMESS

;.SBTTL MATHBOX TEST --- MATRIX

SMUL:
LFA38:  LDX  #TMULT
LFA3B:  CLR  TTEMP                  ;CLEAR ERROR FLAG
LFA3D:  LDD  #VGCOLR+(VGCRED*$100)  ;SHOW MATRIX ERRORS IN RED
LFA40:  STD  ,Y++
LFA42:  TFR  X,D                    ;GET TEST #
LFA44:  SUBD #TMULT1                ;MINUS TABLE OFFSET
LFA47:  LSRB                        ;/2 ==> 0,2,4,6 FOR MTST12
LFA48:  LDS  #SMULRT
LFA4C:  JMP  [,X]

;------------------------------------------------------------------------------
; SMULRT - COMPARE TO CORRECT ANSWER WAS LAST THING DONE
;------------------------------------------------------------------------------
SMULRT:
LFA4E:  BEQ  LFAC1                  ;IFNE  ERROR--THEN DISPLAY ERROR
LFA50:  STD  ERRORS                 ;ANSWER FROM DIVIDER
LFA52:  INC  TTEMP                  ;FLAG AN ERROR
LFA54:  CMPX #TMULT2                ;SOME TESTS DON'T HAVE DIAGNOSTICS
LFA57:  BHS  LFA92                  ;IFLO  THESE DO
;SHOW OPTION SWITCH SETTING FOR DIAGNOSTIC
LFA59:  LDD  2,X                    ;Y POSITION ON SCREEN
LFA5B:  STD  ,Y++
LFA5D:  LDD  #$1EA2                 ;X POS
LFA60:  STD  ,Y++
LFA62:  LDD  VGMSGA+48              ;"NNNF" FOR ON INDICATES MULTIPLIER RATHER THAN DIVIDER TEST
LFA65:  STD  ,Y++
LFA67:  STD  ,Y++
LFA69:  STD  ,Y++
LFA6B:  LDD  VGMSGA+32              ;"F"
LFA6E:  STD  ,Y++
LFA70:  LDD  VGMSGA                 ;" "
LFA73:  STD  ,Y++
LFA75:  TFR  X,D                    ;WHICH TEST OF 6
LFA77:  SUBD #TMULT
LFA7A:  ASLB                        ;DISPLAY D5-D2
LFA7B:  ASLB
LFA7C:  ADDB #$50                   ;THESE TESTS START WITH DIAG 5
LFA7E:  LDA  #$03
LFA80:  ASLB
LFA81:  BCS  LFA88                  ;IFCC
LFA83:  LDU  VGMSGA+32              ;"F" FOR OFF
LFA86:  BRA  LFA8B                  ;ELSE
LFA88:  LDU  VGMSGA+48              ;"N" FOR ON
LFA8B:  STU  ,Y++
LFA8D:  DECA
LFA8E:  BPL  LFA80                  ;MIEND
LFA90:  BRA  LFAA9                  ;ELSE  NON DIAGNOSTIC TESTS GIVE CODE LETTERS
LFA92:  LDD  2,X
LFA94:  STD  ,Y++
LFA96:  LDD  #$0096
LFA99:  STD  ,Y++
LFA9B:  TFR  X,D
LFA9D:  SUBD #TMULT2
LFAA0:  LSRB
LFAA1:  LDS  #VGMSGA+22
LFAA5:  LDD  B,S
LFAA7:  STD  ,Y++
LFAA9:  LDD  VGMSGA
LFAAC:  STD  ,Y++
LFAAE:  LDS  #STACK                 ;SET STACK
LFAB2:  LDA  ERRORS                 ;DIPLAY ERRONEOUS DATA
LFAB4:  JSR  VWBYTE
LFAB7:  LDA  ERRORS+1
LFAB9:  JSR  VWBYTE
LFABC:  LDD  #VGCNTR
LFABF:  STD  ,Y++
LFAC1:  LEAX 4,X
LFAC3:  CMPX #TMULTZ
LFAC6:  LBLO LFA42                  ;HSEND
LFACA:  LDS  #STACK                 ;SET THE STACK FOR THE MESSAGE ROUTINE
LFACE:  TST  TTEMP                  ;ERRORS?
LFAD0:  BNE  LFAD6                  ;IFEQ  NO
LFAD2:  LDB  #MS_MTX+1              ;"NO MATRIX ERRORS"
LFAD4:  BRA  LFAD8                  ;ELSE
LFAD6:  LDB  #MS_MTX                ;"MATRIX ERRORS"
LFAD8:  JSR  DOMESS
LFADB:  LDU  #TSTAT1                ;RESET U FOR MATHBOX TESTS
LFADE:  JMP  GETBAK

TMULT:
LFAE1:  .word MTST6, $1F6A
LFAE5:  .word MTST7, $1F38

TMULT1:
LFAE9:  .word MTST12, $1F06
LFAED:  .word MTST12, $1ED4
LFAF1:  .word MTST12, $1EA2
LFAF5:  .word MTST12, $1E70

TMULT2:
LFAF9:  .word MULT9, $1F6A
LFAFD:  .word MTST10, $1F38
LFB01:  .word MTST11, $1F06
LFB05:  .word MTST8, $1ED4

;------------------------------------------------------------------------------
; TMULTZ - [note] End of the TMULT table. MULT9 (its TMULT2 entry): matrix test 9 - set S as return pointer to MT9RT1
;   and jump to MTST9
;   (also: MULT9)
;------------------------------------------------------------------------------
TMULTZ:
MULT9:
LFB09:  LDS  #MT9RT1
LFB0D:  JMP  MTST9                  ;CLEARS ACCUMULATOR AND STARTS ACCUMULATING

;------------------------------------------------------------------------------
; MT9RT1 - [note] Return from MTST9: D (M_XP) must be $0001, else to SMULRT with the error; then U = 2, return pointer
;   S = MT9RT2, and jump to MTST92 to add the accumulator to itself
;------------------------------------------------------------------------------
MT9RT1:
LFB10:  CMPD #$0001
LFB14:  BEQ  LFB19                  ;IFNE
LFB16:  JMP  SMULRT
LFB19:  LDU  #$0002
LFB1C:  LDS  #MT9RT2
LFB20:  JMP  MTST92                 ;ADD ACCUMULATOR TO ITSELF

;------------------------------------------------------------------------------
; MT9RT2 - [note] Return from MTST92: D must equal the BITS entry at U, else to SMULRT with the error; U + 2 and repeat
;   MTST92 until U = $20, then to SMULRT with the last compare equal
;------------------------------------------------------------------------------
MT9RT2:
LFB23:  CMPD BITS,U
LFB28:  BEQ  LFB2D                  ;IFNE
LFB2A:  JMP  SMULRT
LFB2D:  LEAU 2,U
LFB2F:  CMPU #$0020
LFB33:  BLO  LFB1C                  ;HSEND
LFB35:  JMP  SMULRT

;------------------------------------------------------------------------------
; DIVTST - DIVIDER TESTS
;   PROGRAMMER: JED MARGOLIN MODIFIED BY NORM AVELLAR
;   DATE 12/10/82 5/18/83
;   2/21/83
;   3/14/83
;   4/4/83
;   HARDWARE: STAR WARS,REV A
;   The STAR WARS Divider is an unsigned 15 bit fractional divider which assumes
;   that the dividend (the numerator) is less than twice the Divisor (the
;   denominator).
;   The hardware consists of a Dividend Latch, a Dividend Shift Register, an
;   inverting Divisor Latch, an Adder, a Difference Latch, a Quotient Shift
;   Register with tri-state Buffer, and a Control Unit which includes the
;   Divide Cycle Counter.
;   The Dividend Latch is written into by the 6809 and has two parts: Dividend
;   Latch High Byte (DVDDH) and Dividend Latch Low Byte (DVDDL) The Dividend
;   Latch is not altered by the operation of the divider so it may be left at
;   its previous value if desired.
;   The Divisor Latch is also written into by the 6809 and has two parts:
;   Divisor High Byte (DVSRH) and Divisor Low Byte (DVSRL). DVSRH loads
;   the Divisor High Byte, clears the Quotient Shift Register, and loads the
;   Dividend Shift Register from the Dividend Latch. DVSRL loads the Divisor Low
;   Byte and starts the Divider.
;   Divider Operation: Subtract the Divisor from the Dividend in the Dividend
;   Shift Register and put the result in the Difference Latch.
;   If the result of this subtraction is positive, the Carry (C16*) will
;   be a '1'. Shift a '1' into the Quotient Shift Register and store the
;   value from the Difference Latch into the Dividend Shift Register.
;   (In a conventional divider algorithm the dividend shift register would
;   then be shifted left, but here the output of the Adder is wired
;   to the Difference Latch already shifted over by one)
;   If the result of the subtraction is negative, the Carry (C16*) will
;   be a '0'. Shift a '0' into the Quotient Shift Register and shift the
;   Dividend Shift Register left once. The value in the Difference Latch
;   is otherwise ignored.
;   Do it 15 times. With a 3 Mhz clock it will take 5.0 uS.
;   The Quotient Shift Register is read by the 6809 as QUOH and QUOL.
;------------------------------------------------------------------------------
DIVTST:
LFB38:  LDD  ,X                     ;GET NUMERATOR
LFB3A:  STD  M_DVN
LFB3D:  LDD  2,X                    ;GET DENOMINATOR
LFB3F:  STD  M_DVD                  ;STORE DENOMINATOR AND START DIVIDER
LFB42:  MUL                         ;CONVENIENT WAY TO WAIT
LFB43:  LDD  M_QUO                  ;GET ANSWER
LFB46:  CMPD 4,X                    ;IS IT RIGHT?
LFB49:  JMP  ,S                     ;RETURN VIA PREVIOUSLY SET POINTER

TDIV:            ;TABLE OF VALUES FOR DIVIDER TESTS
;NUMERATOR,DENOMINATOR,QUOTIENT,Y POS ON SCREEN
LFB4B:  .word $4000, $4000, $4000, $00C8
LFB53:  .word $5555, $4000, $5555, $0096
LFB5B:  .word $2AAA, $4000, $2AAA, $0064
LFB63:  .word $2AAA, $2AAA, $4000, $0032
LFB6B:  .word $5555, $5555, $4000, $0000

;------------------------------------------------------------------------------
; TDIVZ - MULTIPLIER TEST
;   (also: MULRET)
;------------------------------------------------------------------------------
TDIVZ:
MULRET:
LFB73:  JMP  ,S                     ;RETURN VIA PREVIOUSLY SET POINTER

;------------------------------------------------------------------------------
; MTST1 - TEST 1 LOOP - LDA ZERO,HALT
;------------------------------------------------------------------------------
MTST1:
LFB75:  LDD  #$5555
LFB78:  STD  M_ZRO
LFB7B:  LDA  #$57
LFB7D:  STA  M_PCGO
LFB80:  BRA  TDIVZ

;------------------------------------------------------------------------------
; MTST2 - TEST 2 LOOP - LDB ZERO,HALT
;------------------------------------------------------------------------------
MTST2:
LFB82:  LDD  #$AAAA
LFB85:  STD  M_ZRO
LFB88:  LDA  #$58
LFB8A:  STA  M_PCGO
LFB8D:  BRA  TDIVZ

;------------------------------------------------------------------------------
; MTST3 - TEST 3 LOOP - LDC ZERO,MAC,HALT
;------------------------------------------------------------------------------
MTST3:
LFB8F:  LDD  #$5555
LFB92:  STD  M_ZRO
LFB95:  LDA  #$59
LFB97:  STA  M_PCGO
LFB9A:  BRA  TDIVZ

;------------------------------------------------------------------------------
; MTST4 - TEST 4 LOOP - CLA,HALT
;------------------------------------------------------------------------------
MTST4:
LFB9C:  LDA  #$5A
LFB9E:  STA  M_PCGO
LFBA1:  BRA  TDIVZ

;------------------------------------------------------------------------------
; MTST5 - TEST 5 LOOP - IBC,HALT
;------------------------------------------------------------------------------
MTST5:
LFBA3:  LDA  #$5B
LFBA5:  STA  M_PCGO
LFBA8:  BRA  TDIVZ

;------------------------------------------------------------------------------
; MTST6 - TEST 6 LOOP - LAC XP
;   SAC YP,HALT
;------------------------------------------------------------------------------
MTST6:
LFBAA:  LDD  #$5555
LFBAD:  STD  M_XP
LFBB0:  LDA  #$5C
LFBB2:  STA  M_PCGO
LFBB5:  NOP
LFBB6:  LDD  M_YP                   ;FOR ANALYZER TRIGGERING
LFBB9:  CMPD #$5555
LFBBD:  BRA  TDIVZ

;------------------------------------------------------------------------------
; MTST7 - TEST 7 LOOP - LAC XP
;   SAC YP,HALT
;------------------------------------------------------------------------------
MTST7:
LFBBF:  LDD  #$AAAA
LFBC2:  STD  M_XP
LFBC5:  LDA  #$5C
LFBC7:  STA  M_PCGO
LFBCA:  NOP
LFBCB:  LDD  M_YP                   ;FOR ANALYZER TRIGGERING
LFBCE:  CMPD #$AAAA
LFBD2:  BRA  TDIVZ

;------------------------------------------------------------------------------
; MTST8 - TEST 8 LOOP TESTS SUBTRACT
;   LDA XT,CLA
;   LDB YT
;   LDC ZT,MAC
;   SAC XP,HALT
;------------------------------------------------------------------------------
MTST8:
LFBD4:  LDD  #$2696
LFBD7:  STD  M_XT
LFBDA:  LDD  #$1B2C
LFBDD:  STD  M_YT
LFBE0:  LDD  #$4000
LFBE3:  STD  M_ZT
LFBE6:  LDA  #$5D
LFBE8:  STA  M_PCGO
LFBEB:  MUL
LFBEC:  LDD  M_XP
LFBEF:  CMPD #$0B6A
LFBF3:  JMP  MULRET

;------------------------------------------------------------------------------
; MTST9 - TEST 9 TESTS ACCUMULATOR
;   LDA XT
;   LDB YT
;   LDC ZT,MAC
;   SAC XP,HALT
;------------------------------------------------------------------------------
MTST9:
LFBF6:  LDA  #$5A                   ;FIRST CLEAR ACCUMULATOR
LFBF8:  STA  M_PCGO
LFBFB:  LDD  #$0000
LFBFE:  STD  M_YT
LFC01:  LDD  #$4000
LFC04:  STD  M_ZT
LFC07:  LDD  #$0001                 ;EVERY TIME THIS PART IS RUN
LFC0A:  STD  M_XT                   ;THE PRODUCT SHOULD ACCUMULATE

MTST92:
LFC0D:  STD  M_XT                   ;ADD RESULT BACK TO ACCUMULATOR
LFC10:  LDA  #$5E
LFC12:  STA  M_PCGO
LFC15:  MUL
LFC16:  LDD  M_XP                   ;PUT RESULT IN D
LFC19:  JMP  MULRET

;------------------------------------------------------------------------------
; MTST10 - TEST 10 - TEST BLOCK INDEX COUNTER
;   LDA X,IND,CLA
;   LDB ZERO
;   LDC ONE,MAC
;   SAC XP,HALT
;------------------------------------------------------------------------------
MTST10:
LFC1C:  LDU  #MBRAM+$28             ;SETUP THE MATH RAM
LFC1F:  LDD  #$0005                 ;START AT BIC #4
LFC22:  STD  ,U
LFC24:  ADDD #$0001
LFC27:  LEAU 8,U
LFC29:  CMPU #MBRAMZ
LFC2D:  BLO  LFC22                  ;HSEND
LFC2F:  LDD  #$0000
LFC32:  STD  M_ZRO
LFC35:  LDD  #$4000
LFC38:  STD  M_ONE
LFC3B:  LDD  #$0004
LFC3E:  STD  M_BIC
LFC41:  LDU  #$0008                 ;START AT 8TH BIC
LFC44:  STA  WTCHDG
LFC47:  TFR  U,D                    ;INCREMENT THE BIC
LFC49:  LSRA                        ;LSRD  ADD HALF THE CURRENT VALUE OF U
LFC4A:  RORB
LFC4B:  LDA  #$5B                   ;INC BIC
LFC4D:  STA  M_PCGO
LFC50:  DECB
LFC51:  BNE  LFC4B                  ;EQEND
LFC53:  LDA  #$5F                   ;GO GET THE DATA
LFC55:  STA  M_PCGO
LFC58:  MUL
LFC59:  CMPU M_XP                   ;SHOULD BE THE SAME
LFC5D:  BEQ  LFC62                  ;IFNE  ERROR
LFC5F:  JMP  MULRET
LFC62:  TFR  U,D                    ;ADD U TO ITSELF
LFC64:  LEAU D,U
LFC66:  CMPU #$0200
LFC6A:  BLO  LFC44                  ;HSEND
LFC6C:  LDD  #$0000                 ;NO ERRORS
LFC6F:  JMP  MULRET

;------------------------------------------------------------------------------
; MTST11 - TEST 11 QUICK ACCUMULATOR TEST
;------------------------------------------------------------------------------
MTST11:
LFC72:  LDD  #$1B2C
LFC75:  STD  M_XT
LFC78:  LDD  #$0000
LFC7B:  STD  M_YT
LFC7E:  LDD  #$4000
LFC81:  STD  M_ZT
LFC84:  LDA  #$5D                   ;CLEARS ACCUM. AND PUTS 1B2C IN ACCUM
LFC86:  STA  M_PCGO
LFC89:  MUL
LFC8A:  LDD  #$196A
LFC8D:  STD  M_XT
LFC90:  LDD  #$0000
LFC93:  STD  M_YT
LFC96:  LDD  #$4000
LFC99:  STD  M_ZT
LFC9C:  LDA  #$5E                   ;ADDS 196A TO ACCUM.
LFC9E:  STA  M_PCGO
LFCA1:  MUL
LFCA2:  LDD  M_XP
LFCA5:  CMPD #$3496
LFCA9:  JMP  MULRET

;------------------------------------------------------------------------------
; MTST12 - TEST 12 LOOP -- TESTS SUBTRACT
;   LDA XT,CLA
;   LDB YT
;   LDC ZT,MAC
;   SAC XP,HALT
;   B MUST BE SET TO 0,2,4 OR 6 BEFORE GETTING HERE
;------------------------------------------------------------------------------
MTST12:
LFCAC:  ASLB
LFCAD:  ASLB
LFCAE:  LDU  #TMTRX                 ;TABLE OF VALUES FOR TEST 12
LFCB1:  LEAU B,U
LFCB3:  LDD  ,U
LFCB5:  STD  M_XT
LFCB8:  LDD  2,U
LFCBA:  STD  M_YT
LFCBD:  LDD  4,U
LFCBF:  STD  M_ZT
LFCC2:  LDA  #$5D
LFCC4:  STA  M_PCGO
LFCC7:  MUL                         ;DELAY
LFCC8:  LDD  M_XP
LFCCB:  CMPD 6,U
LFCCE:  JMP  MULRET

TMTRX:
LFCD1:  .word $5555, $0000, $4000, $5555
LFCD9:  .word $0000, $5555, $C000, $5555
LFCE1:  .word $2AAA, $0000, $4000, $2AAA
LFCE9:  .word $0000, $2AAA, $C000, $2AAA

TMUL:            ;TABLE OF MULTIPLIER TEST ROUTINES
LFCF1:  .word MTST1
LFCF3:  .word MTST2
LFCF5:  .word MTST3
LFCF7:  .word MTST4
LFCF9:  .word MTST5
LFCFB:  .word MTST6
LFCFD:  .word MTST7

TMUL1:
LFCFF:  .word MTST12
LFD01:  .word MTST12
LFD03:  .word MTST12
LFD05:  .word MTST12

;------------------------------------------------------------------------------
; TMULZ - DIAGNOSTICS
;   (also: DLOOP, DIAGLP)
;------------------------------------------------------------------------------
TMULZ:
DLOOP:
DIAGLP:
LFD07:  LDA  TESTSW                 ;BOTH TEST AND DIAG SWITCHES ON?
LFD0A:  ANDA #TESTBT
LFD0C:  LDB  DIAGSW
LFD0F:  ANDB #DIAGBT
LFD11:  CMPD #$0000                 ;SHOULD BE 0000 IF BOTH ON
LFD15:  BEQ  LFD1A                  ;IFNE
LFD17:  JMP  HANG                   ;WAIT FOR WATCH DOG
LFD1A:  STA  WTCHDG                 ;KEEP THE DOG QUIET
LFD1D:  LDA  #$FF                   ;TURN OFF ALL LEDS
LFD1F:  STA  W_LED1
LFD22:  STA  W_LED2
LFD25:  STA  W_LED3
LFD28:  LDB  R_BYT2
LFD2B:  COMB
LFD2C:  LDU  #TDNUM                 ;TABLE OF DIAG NUM TO BCD CONVERSIONS
LFD2F:  CMPB ,U+                    ;IS THIS THE SWITCH CONFIGURATION?
LFD31:  BNE  LFD5A                  ;IFEQ  YES, THEN SHOW THE TEST NUMBER
LFD33:  STA  VGSTOP                 ;MAKE SURE VG HAS STOPPED
LFD36:  LDY  #VGRAM                 ;SET UP POINTER
LFD3A:  LDD  #VJBONDRY              ;DRAW A BOX
LFD3D:  STD  ,Y++
LFD3F:  LDD  #VGCNTR
LFD42:  STD  ,Y++
LFD44:  LDA  ,U                     ;GET BCD FOR DIAG NUMBER
LFD46:  LDS  #STACK
LFD4A:  JSR  VWBYTE
LFD4D:  LDD  #$2020                 ;PUT A HALT IN AT END OF LIST
LFD50:  STD  ,Y++
LFD52:  STD  ,Y++
LFD54:  STA  VGGO                   ;START THE VG
LFD57:  LDU  #TDNUMZ                ;LEAVE THE LOOP
LFD5A:  LEAU 1,U                    ;NEXT ENTRY
LFD5C:  CMPU #TDNUMZ
LFD60:  BLO  LFD2F                  ;HSEND
LFD62:  LDB  R_BYT2                 ;READ OPTION SWITCH TO FIND DIAGNOSTIC TEST #
LFD65:  COMB                        ;OFF-->0, ON-->1
LFD66:  TFR  B,A
LFD68:  ANDB #$0F                   ;TO BE USED BY CERTAIN TESTS INTERNALLY
LFD6A:  ANDA #$F8                   ;TOP 5 BITS INDICATE TEST TYPE
LFD6C:  CMPA #$C0                   ;AVG INSTRUCTIONS?
LFD6E:  BEQ  LFD72                  ;IFNE  NO
LFD70:  CLR  SIGFLG                 ;MAKE SURE SIGNATURE ANALYSIS GETS INITIATED CORRECTLY
LFD72:  LDX  #TDIAG
LFD75:  CMPA ,X+
LFD77:  BNE  LFD7B                  ;IFEQ
LFD79:  JMP  [,X]
LFD7B:  LEAX 2,X
LFD7D:  CMPX #TDIAGZ                ;PAST END OF TABLE?
LFD80:  BLO  LFD75                  ;HSEND  IF NOT KEEP LOOKING
LFD82:  JMP  DIAGERR                ;ELSE FLASH ALL 3 LEDS TO INDICATE ERROR

TDIAG:
LFD85:  .byte $00                   ;LOOKUP 000,D.KERN  KERNAL TEST
LFD86:  .word D_KERN
LFD88:  .byte $80                   ;LOOKUP 080,D.AVGR  AVG RAM AND ROM TEST
LFD89:  .word D_AVGR
LFD8B:  .byte $C0                   ;LOOKUP 0C0,D.AVGI  AVG INSTRUCTIONS
LFD8C:  .word D_AVGI
LFD8E:  .byte $E0                   ;LOOKUP 0E0,D.MTRX  MATRIX PROCESSOR INSTRUCTIONS
LFD8F:  .word D_MTRX
LFD91:  .byte $E8                   ;LOOKUP 0E8,D.MTRX  "
LFD92:  .word D_MTRX
LFD94:  .byte $F0                   ;LOOKUP 0F0,D.DVDR  DIVIDER TESTS
LFD95:  .word D_DVDR
LFD97:  .byte $F8                   ;LOOKUP 0F8,D.SND  SOUND BOARD COMMUNICATIONS
LFD98:  .word D_SND

TDIAGZ:
TDNUM:           ;SWITCH TO TEST NUMBER CONVERSION TABLE
LFD9A:  .byte $E0, $10
LFD9C:  .byte $E1, $11
LFD9E:  .byte $E2, $12
LFDA0:  .byte $E3, $13
LFDA2:  .byte $E4, $14
LFDA4:  .byte $E5, $15
LFDA6:  .byte $E6, $16
LFDA8:  .byte $E7, $17
LFDAA:  .byte $E8, $18
LFDAC:  .byte $E9, $19
LFDAE:  .byte $EA, $20
LFDB0:  .byte $F0, $21
LFDB2:  .byte $F1, $22
LFDB4:  .byte $F2, $23
LFDB6:  .byte $F3, $24
LFDB8:  .byte $F4, $25
LFDBA:  .byte $F8, $26

;------------------------------------------------------------------------------
; TDNUMZ - KERNAL TEST
;   (also: D_KERN)
;------------------------------------------------------------------------------
TDNUMZ:
D_KERN:
LFDBC:  TSTB                        ;SHOULD BE 00
LFDBD:  BEQ  LFDC2                  ;IFNE  ERROR
LFDBF:  JMP  DIAGERR
LFDC2:  TFR  S,D                    ;GET TEST RESULTS
LFDC4:  ANDA #$40                   ;ROM 4 OK?
LFDC6:  ANDB #$01                   ;RAM OK?
LFDC8:  CMPD #$0000
LFDCC:  BNE  LFDD4                  ;IFEQ  YES, ROM AND RAM OK
LFDCE:  LDU  #W_LED1                ;THEN FLASH LED 1
LFDD1:  JMP  LEDFLSH                ;AND RETURN TO DIAGLP
LFDD4:  JMP  DIAGLP

;------------------------------------------------------------------------------
; D_AVGR - AVG ROM/RAM TEST
;------------------------------------------------------------------------------
D_AVGR:
LFDD7:  TSTB                        ;SHOULD BE 00
LFDD8:  BEQ  LFDDD                  ;IFNE  ERROR
LFDDA:  JMP  DIAGERR
LFDDD:  TFR  S,D
LFDDF:  ANDA #$81
LFDE1:  ANDB #$F8
LFDE3:  CMPD #$0000
LFDE7:  BNE  LFDEF                  ;IFEQ  AVG RAM AND ROM ARE OK
LFDE9:  LDU  #W_LED2                ;THEN FLASH LED 2
LFDEC:  JMP  LEDFLSH                ;AND RETURN TO DIAGLP
LFDEF:  JMP  DIAGLP

;------------------------------------------------------------------------------
; D_AVGI - AVG INSTRUCTION DIAGNOSTICS
;------------------------------------------------------------------------------
D_AVGI:
LFDF2:  CMPB #$06                   ;SIGNATURE ANALYSIS?
LFDF4:  BNE  LFE0E                  ;IFEQ  YEP
LFDF6:  TST  SIGFLG                 ;BEEN THROUGH HERE ALREADY?
LFDF8:  BNE  LFE0C                  ;IFEQ  NOPE, THEN SET UP RAM, AND SET FLAG
LFDFA:  LDX  #VGRAM+$800            ;VGRAM1
LFDFD:  LDA  #$00
LFDFF:  STA  ,X+
LFE01:  ADDA #$05
LFE03:  CMPX #VGRAM+$1000           ;FILLED VGRAM1 WITH APPROPRIATE DATA?
LFE06:  BLO  LFDFF                  ;HSEND
LFE08:  LDA  #$FF
LFE0A:  STA  SIGFLG                 ;FLAG SO WON'T DO IT AGAIN
LFE0C:  BRA  LFE34                  ;ELSE  NORMAL AVG INSTRUCTIONS
LFE0E:  CLR  SIGFLG
LFE10:  STA  VGSTOP
LFE13:  LDX  #TAVGI
LFE16:  ASLB                        ;2-WORD ENTRIES
LFE17:  ASLB
LFE18:  ABX
LFE19:  CMPX #TAVGIZ
LFE1C:  BLO  LFE21                  ;IFHS
LFE1E:  JMP  DIAGERR                ;FLASH LEDS
LFE21:  LDD  ,X                     ;SET UP INSTRUCTIONS FROM THE TABLE
LFE23:  STD  VGRAM+0
LFE26:  LDD  2,X
LFE28:  STD  VGRAM+2
LFE2B:  LDD  #$2020                 ;MAKE SURE IT STOPS
LFE2E:  STD  VGRAM+4
LFE31:  STA  VGGO                   ;START THE VG
LFE34:  JMP  DIAGLP                 ;GO BACK TO THE DIAGNOSTIC MAIN LOOP

TAVGI:
LFE37:  .word $2020, $2020          ;HALT;HALT
LFE3B:  .word $0100, $0100          ;VCTR 100,100
LFE3F:  .word $5010, $2020          ;SVCTR 20,20;HALT
LFE43:  .word $8040, $2020          ;CNTR;HALT
LFE47:  .word $7240, $2020          ;SCAL 2,40;HALT
LFE4B:  .word $6780, $2020          ;COLOR WHT,80;HALT

;------------------------------------------------------------------------------
; TAVGIZ - MATHBOX DIAGS
;   MATRIX PROCESSOR DIAGS
;   (also: D_MTRX)
;------------------------------------------------------------------------------
TAVGIZ:
D_MTRX:
LFE4F:  LDX  #TMUL                  ;MATRIX MULTIPLIER TEST TABLE
LFE52:  ASLB
LFE53:  ABX
LFE54:  LDY  #$0000                 ;SETUP REPEAT COUNT

D_MTRX_30:       ;REPEATER RETURN POINT ( FOR FASTER TESTS )
LFE58:  CMPX #TMULZ                 ;PAST END OF TABLE?
LFE5B:  BLO  LFE60                  ;IFHS  YES
LFE5D:  JMP  DIAGERR                ;THEN INDICATE AN ERROR
LFE60:  STA  WTCHDG                 ;DOING MULTIPLE TESTS, SO KEEP THE DOG QUIET
LFE63:  LEAY 1,Y                    ;INC REPEAT COUNT
LFE65:  CMPY #$0200
LFE69:  BLO  LFE71                  ;IFHS  CHECK FOR NEW TEST, RESTART VG, ETC.
LFE6B:  LDS  #DLOOP                 ;RETURN TO THE DIAGNOSTIC MAIN LOOP DELAY
LFE6F:  BRA  LFE75                  ;ELSE  JUST KEEP DOING OLD TEST
LFE71:  LDS  #D_MTRX_30             ;RETURN TO ABOVE
LFE75:  TFR  X,D                    ;SETUP FOR MTST12
LFE77:  SUBD #TMUL1                 ;GIVES 0,2,4 OR 6
LFE7A:  JMP  [,X]                   ;DO IT AND RETURN VIA S

;------------------------------------------------------------------------------
; D_DVDR - DIVIDER DIAGS
;------------------------------------------------------------------------------
D_DVDR:
LFE7C:  LDX  #TDIV                  ;DIVIDER TEST TABLE
LFE7F:  ASLB                        ;8 BYTES PER ENTRY
LFE80:  ASLB
LFE81:  ASLB
LFE82:  ABX
LFE83:  LDY  #$0000                 ;SETUP REPEAT COUNT

D_DVDR_30:       ;REPEATER RETURN POINT ( FOR FASTER TESTS )
LFE87:  CMPX #TDIVZ                 ;PAST END OF TABLE?
LFE8A:  BLO  LFE8F                  ;IFHS  YES
LFE8C:  JMP  DIAGERR                ;THEN INDICATE AN ERROR
LFE8F:  STA  WTCHDG                 ;DOING MULTIPLE TESTS, SO KEEP THE DOG QUIET
LFE92:  LEAY 1,Y                    ;INC REPEAT COUNT
LFE94:  CMPY #$0200
LFE98:  BLO  LFEA0                  ;IFHS  CHECK FOR NEW TEST, RESTART VG, ETC.
LFE9A:  LDS  #DLOOP                 ;RETURN TO THE DIAGNOSTIC MAIN LOOP DELAY
LFE9E:  BRA  LFEA4                  ;ELSE  JUST KEEP DOING OLD TEST
LFEA0:  LDS  #D_DVDR_30             ;RETURN TO ABOVE
LFEA4:  JMP  DIVTST                 ;GO DO IT AND RETURN VIA S

;------------------------------------------------------------------------------
; D_SND - SOUND BOARD COMMUNICATIONS
;------------------------------------------------------------------------------
D_SND:
LFEA7:  ANDB #$07
LFEA9:  BEQ  LFEAE                  ;IFNE
LFEAB:  JMP  DIAGERR
LFEAE:  LDA  #$01                   ;STARTING PATTERN
LFEB0:  STB  W_RSTS                 ;RESET THE SOUND BOARD (INITIATE PORT TEST)
LFEB3:  TFR  X,U                    ;SHORT PAUSE
LFEB5:  LDB  R_RCVS                 ;READ PORT FROM SOUND BOARD, SHOULD CLEAR RECIEVED FLAG
LFEB8:  LDB  R_STAS                 ;CHECK RECEIVE STATUS, SHOULD BE LOW SINCE I JUST READ IT
LFEBB:  ANDB #$40
LFEBD:  BNE  WAIT1                  ;WASN'T CORRECT POLARITY
;CHECK TO SEE IF XMIT READY
LFEBF:  LDB  #$80                   ;ALLOW A DELAY
LFEC1:  DECB
LFEC2:  BMI  WAIT1                  ;DELAYED TOO LONG, WAIT A WHILE AND TRY AGAIN
LFEC4:  STA  WTCHDG                 ;KEEP THE POOCH QUIET
LFEC7:  TST  R_STAS                 ;CHECK XMIT STATUS
LFECA:  BMI  LFEC1                  ;PLEND  XMIT IS NOW READY
LFECC:  STA  W_XMTS                 ;GIVE THE SOUND BOARD THE DATA PATTERN
LFECF:  LDB  R_STAS                 ;CHECK XMIT STATUS, SHOULD BE HI SINCE I JUST SENT DATA
LFED2:  BPL  WAIT1                  ;WRONG, DELAY AND TRY AGAIN LATER
;WAIT FOR SOUND BOARD TO TALK TO US
LFED4:  LDX  #$0100                 ;ALLOW A DELAY
LFED7:  LEAX -$1,X
LFED9:  BEQ  WAIT1                  ;DELAYED TOO LONG, TRY AGAIN LATER
LFEDB:  STA  WTCHDG
LFEDE:  LDB  R_STAS                 ;GET STATUS
LFEE1:  ANDB #$40                   ;HI IF SOUND BOARD TALKED TO US
LFEE3:  BEQ  LFED7                  ;NEEND  IT SPOKE!
;THE XMIT LINE SHOULD BE READY AGAIN SINCE IT READ BEFORE IT SPOKE
LFEE5:  TST  R_STAS
LFEE8:  BMI  WAIT1                  ;WRONG! DELAY AND TRY AGAIN
LFEEA:  CMPA R_RCVS                 ;COMPARE DATA RCVD FROM SOUND BOARD TO DATA XMITD
LFEED:  BNE  WAIT1                  ;ERROR, GO AWAY AGAIN
;CHECK RECEIVE STATUS AGAIN
LFEEF:  LDB  R_STAS
LFEF2:  ANDB #$40
LFEF4:  BMI  WAIT1                  ;WRONGO
LFEF6:  ASLA                        ;NEW PATTERN
LFEF7:  BCC  LFEB0                  ;CSEND  WHEN BIT SHIFTS TO CARRY, ALL DONE
LFEF9:  LDU  #W_LED3                ;ELSE ALL OK, FLASH LED #3
LFEFC:  JMP  LEDFLSH

;------------------------------------------------------------------------------
; LEDFLSH - DIAGNOSTIC LED FLASHERS
;   FLASH LED POINTED AT BY U
;------------------------------------------------------------------------------
LEDFLSH:
LFEFF:  LDA  #$00                   ;TURN LED ON
LFF01:  STA  ,U

WAIT1:           ;THIS ENTRY POINT WAITS 1 SECOND
LFF03:  LDX  #$0000                 ;WAIT ABOUT HALF A SECOND
LFF06:  STA  WTCHDG
LFF09:  LEAX 1,X
LFF0B:  CMPX #$AC55
LFF0E:  BLO  LFF06                  ;HSEND
LFF10:  LDA  #$FF                   ;TURN LED OFF
LFF12:  STA  ,U
LFF14:  LDX  #$0000                 ;WAIT ANOTHER HALF A SECOND
LFF17:  STA  WTCHDG
LFF1A:  LEAX 1,X
LFF1C:  CMPX #$AC55
LFF1F:  BLO  LFF17                  ;HSEND
LFF21:  JMP  DIAGLP                 ;GO BACK TO BEGINNING OF DIAGNOSTICS

;------------------------------------------------------------------------------
; DIAGERR - DIAGNOSTIC ERROR INDICATOR--FLASH ALL LEDS
;------------------------------------------------------------------------------
DIAGERR:
LFF24:  LDA  #$00                   ;TURN ALL LEDS ON
LFF26:  STA  W_LED1
LFF29:  STA  W_LED2
LFF2C:  STA  W_LED3
LFF2F:  LDX  #$0000                 ;WAIT ABOUT 1/4 SECOND
LFF32:  STA  WTCHDG
LFF35:  LEAX 1,X
LFF37:  CMPX #$5600
LFF3A:  BLO  LFF32                  ;HSEND
LFF3C:  LDA  #$FF                   ;TURN ALL LEDS OFF
LFF3E:  STA  W_LED1
LFF41:  STA  W_LED2
LFF44:  STA  W_LED3
LFF47:  LDX  #$0000                 ;WAITR ANOTHER 1/4 SECOND
LFF4A:  STA  WTCHDG
LFF4D:  LEAX 1,X
LFF4F:  CMPX #$5600
LFF52:  BLO  LFF4A                  ;HSEND
LFF54:  JMP  DIAGLP                 ;GO BACK TO DIAGNOSTIC LOOP

;==============================================================================
; MODULE WSFIL4   WSFIL4.MAC
;==============================================================================

;.SBTTL STAR WARS FILLER FOR ROM 4
LFF57:  .byte $A6, $BF, $C8, $40, $96, $1F, $64, $10 ;.IRPC .A,<JED MARGOLIN -- ENGINEER EMERITUS>
LFF5F:  .byte $59, $A0, $74, $A6, $20, $7B, $6E, $E0
LFF67:  .byte $7D, $E8, $AE, $CD, $78, $92, $07, $F4
LFF6F:  .byte $00, $18, $E9, $40, $9A, $F5, $B0, $38
LFF77:  .byte $07

FILL4:
LFF78:  .byte $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF ;.REPT 064  FILL WITH FF'S
LFF80:  .byte $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
LFF88:  .byte $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
LFF90:  .byte $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
LFF98:  .byte $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
LFFA0:  .byte $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
LFFA8:  .byte $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
LFFB0:  .byte $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
LFFB8:  .byte $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
LFFC0:  .byte $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
LFFC8:  .byte $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
LFFD0:  .byte $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
LFFD8:  .byte $FF, $FF, $FF, $FF

CPYRT4:
LFFDC:  .byte $43, $4F, $50, $59, $52, $49, $47, $48 ;.ASCII /COPYRIGHT 1983 ATARI/
LFFE4:  .byte $54, $20, $31, $39, $38, $33, $20, $41
LFFEC:  .byte $54, $41, $52, $49

CHKSM4:
LFFF0:  .word PCKS4

;==============================================================================
; MODULE WSINT (continued)   WSINT.MAC
;   HARDWARE INTERRUPTS
;==============================================================================

;.SBTTL RESET
LFFF2:  .word SWI3, SWI2, FIRQ, IRQ
LFFFA:  .word ASWI                  ;ACTUAL SOFTWARE BRK ADDRESS
LFFFC:  .word NMI
LFFFE:  .word RESET

;==============================================================================
; The 6809 vectors are the .VCTRS words at $FFF2-$FFFF above (SWI3, SWI2, FIRQ,
; IRQ, SWI, NMI, RESET).  $6000-$7FFF is banked: this file holds bank 0, and
; starwars_overlay_rom.asm holds bank 1.
;==============================================================================
