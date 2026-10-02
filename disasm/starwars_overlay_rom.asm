;Star Wars (Atari, 1983) - annotated disassembly of bank 1 of the main program
;ROM: the second half of 136021-214.1f, mapped at $6000-$7FFF when the bank
;latch selects it (Atari's 'overlay': the object tables and vector draw
;routines, and the star generators).  Address labels here are Kxxxx, so a
;bank-1 address is never mistaken for the bank-0 address Lxxxx of
;starwars_program_rom.asm.
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
K6000:  JMP  RESET                  ;HELP DEVELOPMENT SYSTEM WORK
K6003:  .word IRQ

;==============================================================================
; MODULE WSOBJ   WSOBJ.MAC
;   OBJECT TABLES AND VECTOR DRAW ROUTINES
;==============================================================================

TPNT:
TD0PC:
K6005:  .word $0000, $0000, $0000   ;.P 0,0,0
K600B:  .word $FF7E, $FF30, $00EA   ;.P -10,-16,18  LEFT OUTER FIN
K6011:  .word $0068, $FF30, $00EA   ;.P 8,-16,18
K6017:  .word $00B6, $FF30, $0000   ;.P 14,-16,0
K601D:  .word $0068, $FF30, $FF16   ;.P 8,-16,-18
K6023:  .word $FF7E, $FF30, $FF16   ;.P -10,-16,-18
K6029:  .word $FF30, $FF30, $0000   ;.P -16,-16,0
K602F:  .word $FFE6, $FF30, $001A   ;.P -2,-16,2  SMALL CIRCLE ON LEFT FIN
K6035:  .word $0000, $FF30, $001A   ;.P 0,-16,2
K603B:  .word $000D, $FF30, $0000   ;.P 1,-16,0
K6041:  .word $0000, $FF30, $FFE6   ;.P 0,-16,-2
K6047:  .word $FFE6, $FF30, $FFE6   ;.P -2,-16,-2
K604D:  .word $FFD9, $FF30, $0000   ;.P -3,-16,0
K6053:  .word $FF7E, $00D0, $00EA   ;.P -10,16,18  RIGHT FIN
K6059:  .word $0068, $00D0, $00EA   ;.P 8,16,18
K605F:  .word $00B6, $00D0, $0000   ;.P 14,16,0
K6065:  .word $0068, $00D0, $FF16   ;.P 8,16,-18
K606B:  .word $FF7E, $00D0, $FF16   ;.P -10,16,-18
K6071:  .word $FF30, $00D0, $0000   ;.P -16,16,0
K6077:  .word $FFE6, $00D0, $001A   ;.P -2,16,2  SMALL CIRCLE ON RIGHT FIN
K607D:  .word $0000, $00D0, $001A   ;.P 0,16,2
K6083:  .word $000D, $00D0, $0000   ;.P 1,16,0
K6089:  .word $0000, $00D0, $FFE6   ;.P 0,16,-2
K608F:  .word $FFE6, $00D0, $FFE6   ;.P -2,16,-2
K6095:  .word $FFD9, $00D0, $0000   ;.P -3,16,0
K609B:  .word $FFE6, $FFB2, $001A   ;.P -2,-6,2  INNER CIRCLE LEFT STRUT
K60A1:  .word $0000, $FFB2, $001A   ;.P 0,-6,2
K60A7:  .word $000D, $FFB2, $0000   ;.P 1,-6,0
K60AD:  .word $0000, $FFB2, $FFE6   ;.P 0,-6,-2
K60B3:  .word $FFE6, $FFB2, $FFE6   ;.P -2,-6,-2
K60B9:  .word $FFD9, $FFB2, $0000   ;.P -3,-6,0
K60BF:  .word $FFE6, $004E, $001A   ;.P -2,6,2  INNER CIRCLE RIGHT STRUT
K60C5:  .word $0000, $004E, $001A   ;.P 0,6,2
K60CB:  .word $000D, $004E, $0000   ;.P 1,6,0
K60D1:  .word $0000, $004E, $FFE6   ;.P 0,6,-2
K60D7:  .word $FFE6, $004E, $FFE6   ;.P -2,6,-2
K60DD:  .word $FFD9, $004E, $0000   ;.P -3,6,0
K60E3:  .word $FFCC, $FFE6, $004E   ;.P -4,-2,6  LARGE CIRCLE LEFT BODY
K60E9:  .word $001A, $FFE6, $004E   ;.P 2,-2,6
K60EF:  .word $004E, $FFE6, $0027   ;.P 6,-2,3
K60F5:  .word $004E, $FFCC, $0000   ;.P 6,-4,0
K60FB:  .word $004E, $FFE6, $FFD9   ;.P 6,-2,-3
K6101:  .word $001A, $FFE6, $FFB2   ;.P 2,-2,-6
K6107:  .word $FFCC, $FFE6, $FFB2   ;.P -4,-2,-6
K610D:  .word $FF98, $FFE6, $0000   ;.P -8,-2,0
K6113:  .word $FFCC, $001A, $004E   ;.P -4,2,6  LARGE CIRCLE RIGHT BODY
K6119:  .word $001A, $001A, $004E   ;.P 2,2,6
K611F:  .word $004E, $001A, $0027   ;.P 6,2,3
K6125:  .word $004E, $0034, $0000   ;.P 6,4,0
K612B:  .word $004E, $001A, $FFD9   ;.P 6,2,-3
K6131:  .word $001A, $001A, $FFB2   ;.P 2,2,-6
K6137:  .word $FFCC, $001A, $FFB2   ;.P -4,2,-6
K613D:  .word $FF98, $001A, $0000   ;.P -8,2,0

TD1PC:
K6143:  .word $0000, $0000, $0000   ;.P 0,0,0
K6149:  .word $FF7E, $FFE6, $00EA   ;.P -10,-2,18  LEFT OUTER FIN
K614F:  .word $0068, $FFE6, $00EA   ;.P 8,-2,18
K6155:  .word $00B6, $FFE6, $0000   ;.P 14,-2,0
K615B:  .word $0068, $FFE6, $FF16   ;.P 8,-2,-18
K6161:  .word $FF7E, $FFE6, $FF16   ;.P -10,-2,-18
K6167:  .word $FF30, $FFE6, $0000   ;.P -16,-2,0
K616D:  .word $FFE6, $FFE6, $001A   ;.P -2,-2,2  SMALL CIRCLE ON LEFT FIN
K6173:  .word $0000, $FFE6, $001A   ;.P 0,-2,2
K6179:  .word $000D, $FFE6, $0000   ;.P 1,-2,0
K617F:  .word $0000, $FFE6, $FFE6   ;.P 0,-2,-2
K6185:  .word $FFE6, $FFE6, $FFE6   ;.P -2,-2,-2
K618B:  .word $FFD9, $FFE6, $0000   ;.P -3,-2,0
K6191:  .word $FFE6, $0082, $001A   ;.P -2,10,2  INNER CIRCLE LEFT STRUT
K6197:  .word $0000, $0082, $001A   ;.P 0,10,2
K619D:  .word $000D, $0082, $0000   ;.P 1,10,0
K61A3:  .word $0000, $0082, $FFE6   ;.P 0,10,-2
K61A9:  .word $FFE6, $0082, $FFE6   ;.P -2,10,-2
K61AF:  .word $FFD9, $0082, $0000   ;.P -3,10,0

TD2PC:
K61B5:  .word $0000, $0000, $0000   ;.P 0,0,0
K61BB:  .word $FF7E, $00EA, $001A   ;.P -10,18,2  RIGHT OUTER FIN
K61C1:  .word $0068, $00EA, $001A   ;.P 8,18,2
K61C7:  .word $00B6, $0000, $001A   ;.P 14,0,2
K61CD:  .word $0068, $FF16, $001A   ;.P 8,-18,2
K61D3:  .word $FF7E, $FF16, $001A   ;.P -10,-18,2
K61D9:  .word $FF30, $0000, $001A   ;.P -16,0,2
K61DF:  .word $FFE6, $001A, $001A   ;.P -2,2,2  SMALL CIRCLE ON RIGHT FIN
K61E5:  .word $0000, $001A, $001A   ;.P 0,2,2
K61EB:  .word $000D, $0000, $001A   ;.P 1,0,2
K61F1:  .word $0000, $FFE6, $001A   ;.P 0,-2,2
K61F7:  .word $FFE6, $FFE6, $001A   ;.P -2,-2,2
K61FD:  .word $FFD9, $0000, $001A   ;.P -3,0,2
K6203:  .word $FFE6, $001A, $FF7E   ;.P -2,2,-10  INNER CIRCLE RIGHT STRUT
K6209:  .word $0000, $001A, $FF7E   ;.P 0,2,-10
K620F:  .word $000D, $0000, $FF7E   ;.P 1,0,-10
K6215:  .word $0000, $FFE6, $FF7E   ;.P 0,-2,-10
K621B:  .word $FFE6, $FFE6, $FF7E   ;.P -2,-2,-10
K6221:  .word $FFD9, $0000, $FF7E   ;.P -3,0,-10

TD3PC:
K6227:  .word $0000, $0000, $0000   ;.P 0,0,0
K622D:  .word $FFE6, $FFB2, $001A   ;.P -2,-6,2  INNER CIRCLE LEFT STRUT
K6233:  .word $0000, $FFB2, $001A   ;.P 0,-6,2
K6239:  .word $000D, $FFB2, $0000   ;.P 1,-6,0
K623F:  .word $0000, $FFB2, $FFE6   ;.P 0,-6,-2
K6245:  .word $FFE6, $FFB2, $FFE6   ;.P -2,-6,-2
K624B:  .word $FFD9, $FFB2, $0000   ;.P -3,-6,0
K6251:  .word $FFE6, $004E, $001A   ;.P -2,6,2  INNER CIRCLE RIGHT STRUT
K6257:  .word $0000, $004E, $001A   ;.P 0,6,2
K625D:  .word $000D, $004E, $0000   ;.P 1,6,0
K6263:  .word $0000, $004E, $FFE6   ;.P 0,6,-2
K6269:  .word $FFE6, $004E, $FFE6   ;.P -2,6,-2
K626F:  .word $FFD9, $004E, $0000   ;.P -3,6,0
K6275:  .word $FFCC, $FFE6, $004E   ;.P -4,-2,6  LARGE CIRCLE LEFT BODY
K627B:  .word $001A, $FFE6, $004E   ;.P 2,-2,6
K6281:  .word $004E, $FFE6, $0027   ;.P 6,-2,3
K6287:  .word $004E, $FFCC, $0000   ;.P 6,-4,0
K628D:  .word $004E, $FFE6, $FFD9   ;.P 6,-2,-3
K6293:  .word $001A, $FFE6, $FFB2   ;.P 2,-2,-6
K6299:  .word $FFCC, $FFE6, $FFB2   ;.P -4,-2,-6
K629F:  .word $FF98, $FFE6, $0000   ;.P -8,-2,0
K62A5:  .word $FFCC, $001A, $004E   ;.P -4,2,6  LARGE CIRCLE RIGHT BODY
K62AB:  .word $001A, $001A, $004E   ;.P 2,2,6
K62B1:  .word $004E, $001A, $0027   ;.P 6,2,3
K62B7:  .word $004E, $0034, $0000   ;.P 6,4,0
K62BD:  .word $004E, $001A, $FFD9   ;.P 6,2,-3
K62C3:  .word $001A, $001A, $FFB2   ;.P 2,2,-6
K62C9:  .word $FFCC, $001A, $FFB2   ;.P -4,2,-6
K62CF:  .word $FF98, $001A, $0000   ;.P -8,2,0

TD4PC:
K62D5:  .word $0000, $0000, $0000   ;.P 0,0,0
K62DB:  .word $FF4C, $FF4C, $0082   ;.P -18,-18,13  1-8 RIGHT OUTER WING
K62E1:  .word $00B4, $FF4C, $0082   ;.P 18,-18,13
K62E7:  .word $00B4, $FEF2, $0032   ;.P 18,-27,5
K62ED:  .word $00B4, $FEF2, $FFCE   ;.P 18,-27,-5
K62F3:  .word $00B4, $FF4C, $FF7E   ;.P 18,-18,-13
K62F9:  .word $FF4C, $FF4C, $FF7E   ;.P -18,-18,-13
K62FF:  .word $FF4C, $FEF2, $FFCE   ;.P -18,-27,-5
K6305:  .word $FF4C, $FEF2, $0032   ;.P -18,-27,5
K630B:  .word $FFEC, $FEF2, $001E   ;.P -2,-27,3  9-12 RIGHT INNER WING
K6311:  .word $0014, $FEF2, $001E   ;.P 2,-27,3
K6317:  .word $0014, $FEF2, $FFE2   ;.P 2,-27,-3
K631D:  .word $FFEC, $FEF2, $FFE2   ;.P -2,-27,-3
K6323:  .word $FF4C, $00B4, $0082   ;.P -18,18,13  13-20 LEFT OUTER WING
K6329:  .word $00B4, $00B4, $0082   ;.P 18,18,13
K632F:  .word $00B4, $010E, $0032   ;.P 18,27,5
K6335:  .word $00B4, $010E, $FFCE   ;.P 18,27,-5
K633B:  .word $00B4, $00B4, $FF7E   ;.P 18,18,-13
K6341:  .word $FF4C, $00B4, $FF7E   ;.P -18,18,-13
K6347:  .word $FF4C, $010E, $FFCE   ;.P -18,27,-5
K634D:  .word $FF4C, $010E, $0032   ;.P -18,27,5
K6353:  .word $FFEC, $010E, $001E   ;.P -2,27,3  21-24 LEFT INNER WING
K6359:  .word $0014, $010E, $001E   ;.P 2,27,3
K635F:  .word $0014, $010E, $FFE2   ;.P 2,27,-3
K6365:  .word $FFEC, $010E, $FFE2   ;.P -2,27,-3
K636B:  .word $FFC4, $FFC4, $0032   ;.P -6,-6,5  25-28 RIGHT BODY STRUT
K6371:  .word $003C, $FFC4, $0032   ;.P 6,-6,5
K6377:  .word $003C, $FFC4, $FFCE   ;.P 6,-6,-5
K637D:  .word $FFC4, $FFC4, $FFCE   ;.P -6,-6,-5
K6383:  .word $FFC4, $003C, $0032   ;.P -6,6,5  29-32 LEFT BODY STRUT
K6389:  .word $003C, $003C, $0032   ;.P 6,6,5
K638F:  .word $003C, $003C, $FFCE   ;.P 6,6,-5
K6395:  .word $FFC4, $003C, $FFCE   ;.P -6,6,-5
K639B:  .word $FFE2, $FFE2, $0050   ;.P -3,-3,8  33-40 RIGHT BODY FACE
K63A1:  .word $001E, $FFE2, $0050   ;.P 3,-3,8
K63A7:  .word $0050, $FFB0, $001E   ;.P 8,-8,3
K63AD:  .word $0050, $FFB0, $FFE2   ;.P 8,-8,-3
K63B3:  .word $001E, $FFE2, $FFB0   ;.P 3,-3,-8
K63B9:  .word $FFE2, $FFE2, $FFB0   ;.P -3,-3,-8
K63BF:  .word $FFB0, $FFB0, $FFE2   ;.P -8,-8,-3
K63C5:  .word $FFB0, $FFB0, $001E   ;.P -8,-8,3
K63CB:  .word $FFE2, $001E, $0050   ;.P -3,3,8  41-48 LEFT BODY FACE
K63D1:  .word $001E, $001E, $0050   ;.P 3,3,8
K63D7:  .word $0050, $0050, $001E   ;.P 8,8,3
K63DD:  .word $0050, $0050, $FFE2   ;.P 8,8,-3
K63E3:  .word $001E, $001E, $FFB0   ;.P 3,3,-8
K63E9:  .word $FFE2, $001E, $FFB0   ;.P -3,3,-8
K63EF:  .word $FFB0, $0050, $FFE2   ;.P -8,8,-3
K63F5:  .word $FFB0, $0050, $001E   ;.P -8,8,3
K63FB:  .word $0032, $FFEC, $003C   ;.P 5,-2,6  49-56 FRONT OUTER WINDOW
K6401:  .word $0032, $0014, $003C   ;.P 5,2,6
K6407:  .word $0050, $003C, $0014   ;.P 8,6,2
K640D:  .word $0050, $003C, $FFEC   ;.P 8,6,-2
K6413:  .word $0032, $0014, $FFC4   ;.P 5,2,-6
K6419:  .word $0032, $FFEC, $FFC4   ;.P 5,-2,-6
K641F:  .word $0050, $FFC4, $FFEC   ;.P 8,-6,-2
K6425:  .word $0050, $FFC4, $0014   ;.P 8,-6,2

TD5PC:
K642B:  .word $0000, $0000, $0000   ;.P 0,0,0

TD6PC:
K6431:  .word $0000, $0000, $0000   ;.P 0,0,0

TD7PC:
TD8PC:
TD9PC:
TD10PC:
K6437:  .word $0000, $0000, $F100   ;.PGND 0,0,0  CENTER ON GROUND
K643D:  .word $FC40, $0000, $F100   ;.PGND -8,0,0  FRONT
K6443:  .word $0000, $03C0, $F100   ;.PGND 0,8,0  LEFT
K6449:  .word $0000, $FC40, $F100   ;.PGND 0,-8,0  RIGHT
K644F:  .word $FE20, $0000, $1A40   ;.PGND -4,0,58  TOP OF TOWER, TOP OF CANNON
K6455:  .word $0000, $01E0, $1A40   ;.PGND 0,4,58
K645B:  .word $0000, $FE20, $1A40   ;.PGND 0,-4,58
K6461:  .word $FE20, $0000, $1770   ;.PGND -4,0,52  BOTTOM OF CANNON
K6467:  .word $0000, $01E0, $1770   ;.PGND 0,4,52
K646D:  .word $0000, $FE20, $1770   ;.PGND 0,-4,52
K6473:  .word $FDA8, $0000, $FA60   ;.PGND -5,0,14  MIDLINE
K6479:  .word $0000, $0258, $FA60   ;.PGND 0,5,14
K647F:  .word $0000, $FDA8, $FA60   ;.PGND 0,-5,14
K6485:  .word $FD30, $0000, $F3D0   ;.PGND -6,0,6  NEAR BOTTOM
K648B:  .word $0000, $02D0, $F3D0   ;.PGND 0,6,6
K6491:  .word $0000, $FD30, $F3D0   ;.PGND 0,-6,6

TD11PC:
K6497:  .word $FF00, $0000, $FF40   ;.PH -20,0,-18  0-3 OUTER RECTANGLE
K649D:  .word $FF00, $0000, $00C0   ;.PH -20,0,18
K64A3:  .word $0100, $0000, $00C0   ;.PH 20,0,18
K64A9:  .word $0100, $0000, $FF40   ;.PH 20,0,-18
K64AF:  .word $FF80, $0000, $FFC0   ;.PH -10,0,-8  4-7 INNER RECTANGLE
K64B5:  .word $FF80, $0000, $0040   ;.PH -10,0,8
K64BB:  .word $0080, $0000, $0040   ;.PH 10,0,8
K64C1:  .word $0080, $0000, $FFC0   ;.PH 10,0,-8

TD12PC:
TD13PC:
K64C7:  .word $0000, $0000, $0000   ;.P 0,0,0
K64CD:  .word $FF00, $0000, $00C0   ;.P -32,0,24  0-4 WALL BASE
K64D3:  .word $0100, $0000, $00C0   ;.P 32,0,24
K64D9:  .word $0100, $0000, $FF40   ;.P 32,0,-24
K64DF:  .word $FF00, $0000, $FF40   ;.P -32,0,-24
K64E5:  .word $FFA0, $0060, $0040   ;.P -12,12,8  5-10 GUN BODY
K64EB:  .word $0060, $0020, $0040   ;.P 12,4,8
K64F1:  .word $0060, $0020, $FFC0   ;.P 12,4,-8
K64F7:  .word $FFA0, $0060, $FFC0   ;.P -12,12,-8
K64FD:  .word $FFA0, $0020, $FFC0   ;.P -12,4,-8
K6503:  .word $FFA0, $0020, $0040   ;.P -12,4,8
K6509:  .word $FFA0, $0048, $0020   ;.P -12,9,4  11-14 GUN NOZZLE
K650F:  .word $FFA0, $0038, $0020   ;.P -12,7,4
K6515:  .word $FFA0, $0048, $FFE0   ;.P -12,9,-4
K651B:  .word $FFA0, $0038, $FFE0   ;.P -12,7,-4

TD14PC:
TD15PC:
K6521:  .word $FF00, $0000, $0000   ;.PH -20,0,0  0-1 FRONT MIDLINE
K6527:  .word $FF00, $0200, $0000   ;.PH -20,40,0
K652D:  .word $0000, $0000, $FF00   ;.PH 0,0,-20  2-3 BOTTOM MIDLINE
K6533:  .word $0000, $0200, $FF00   ;.PH 0,40,-20
K6539:  .word $0000, $0000, $0100   ;.PH 0,0,20  4-5 TOP MIDLINE
K653F:  .word $0000, $0200, $0100   ;.PH 0,40,20

TD16PC:
K6545:  .word $0060, $0060, $0000   ;.PH 0C,0C,0  0-3 INNER CIRCLE
K654B:  .word $0060, $FFA0, $0000   ;.PH 0C,-0C,0
K6551:  .word $FFA0, $0060, $0000   ;.PH -0C,0C,0
K6557:  .word $FFA0, $FFA0, $0000   ;.PH -0C,-0C,0
K655D:  .word $00A0, $00A0, $0000   ;.PH 14,14,0  4-7 SUPPORT BERM
K6563:  .word $00A0, $FF60, $0000   ;.PH 14,-14,0
K6569:  .word $FF60, $00A0, $0000   ;.PH -14,14,0
K656F:  .word $FF60, $FF60, $0000   ;.PH -14,-14,0
K6575:  .word $0100, $0100, $0000   ;.PH 20,20,0  8-15 BASE
K657B:  .word $0100, $FF00, $0000   ;.PH 20,-20,0
K6581:  .word $FF00, $0100, $0000   ;.PH -20,20,0
K6587:  .word $FF00, $FF00, $0000   ;.PH -20,-20,0

TD17PC:
K658D:  .word $0000, $0000, $0000   ;.P 0,0,0
K6593:  .word $003C, $FF10, $0168   ;.P 5,-20,30
K6599:  .word $012C, $0000, $0168   ;.P 25,0,30
K659F:  .word $FE5C, $00F0, $0168   ;.P -35,20,30
K65A5:  .word $003C, $FF10, $FE98   ;.P 5,-20,-30
K65AB:  .word $012C, $0000, $FE98   ;.P 25,0,-30
K65B1:  .word $FE5C, $00F0, $FE98   ;.P -35,20,-30

TD18PC:
K65B7:  .word $0000, $0000, $0000   ;.P 0,0,0
K65BD:  .word $0078, $FF10, $0168   ;.P 10,-20,30
K65C3:  .word $0168, $0000, $0168   ;.P 30,0,30
K65C9:  .word $0078, $00F0, $0168   ;.P 10,20,30
K65CF:  .word $FDA8, $0000, $0168   ;.P -50,0,30
K65D5:  .word $0078, $FF10, $FE98   ;.P 10,-20,-30
K65DB:  .word $0168, $0000, $FE98   ;.P 30,0,-30
K65E1:  .word $0078, $00F0, $FE98   ;.P 10,20,-30
K65E7:  .word $FDA8, $0000, $FE98   ;.P -50,0,-30

TD19PC:
K65ED:  .word $0000, $0000, $0000   ;.P 0,0,0
K65F3:  .word $003C, $00F0, $0168   ;.P 5,20,30
K65F9:  .word $012C, $0000, $0168   ;.P 25,0,30
K65FF:  .word $FE5C, $FF10, $0168   ;.P -35,-20,30
K6605:  .word $003C, $00F0, $FE98   ;.P 5,20,-30
K660B:  .word $012C, $0000, $FE98   ;.P 25,0,-30
K6611:  .word $FE5C, $FF10, $FE98   ;.P -35,-20,-30

TD20PC:
K6617:  .word $0000, $0000, $0000   ;.P 0,0,0
K661D:  .word $0108, $FDE4, $0168   ;.P 22,-45,30
K6623:  .word $0108, $003C, $0168   ;.P 22,5,30
K6629:  .word $FD48, $01A4, $0168   ;.P -58,35,30
K662F:  .word $0108, $FDE4, $FE98   ;.P 22,-45,-30
K6635:  .word $0108, $003C, $FE98   ;.P 22,5,-30
K663B:  .word $FD48, $01A4, $FE98   ;.P -58,35,-30

TD21PC:
K6641:  .word $0000, $0000, $0000   ;.P 0,0,0
K6647:  .word $0150, $FE98, $0168   ;.P 28,-30,30
K664D:  .word $0150, $0168, $0168   ;.P 28,30,30
K6653:  .word $FD90, $0000, $0168   ;.P -52,0,30
K6659:  .word $0150, $FE98, $FE98   ;.P 28,-30,-30
K665F:  .word $0150, $0168, $FE98   ;.P 28,30,-30
K6665:  .word $FD90, $0000, $FE98   ;.P -52,0,-30

TD22PC:
K666B:  .word $0000, $0000, $0000   ;.P 0,0,0
K6671:  .word $0108, $021C, $0168   ;.P 22,45,30
K6677:  .word $0108, $FFC4, $0168   ;.P 22,-5,30
K667D:  .word $FD48, $FE5C, $0168   ;.P -58,-35,30
K6683:  .word $0108, $021C, $FE98   ;.P 22,45,-30
K6689:  .word $0108, $FFC4, $FE98   ;.P 22,-5,-30
K668F:  .word $FD48, $FE5C, $FE98   ;.P -58,-35,-30

TD23PC:
K6695:  .word $0000, $0000, $0000   ;.P 0,0,0
K669B:  .word $FFDD, $FFDD, $FFCE   ;.P -35,-35,-50
K66A1:  .word $002D, $FFDD, $FFCE   ;.P 45,-35,-50
K66A7:  .word $FFDD, $FFDD, $006E   ;.P -35,-35,110
K66AD:  .word $FFDD, $002D, $FFCE   ;.P -35,45,-50
K66B3:  .word $002D, $0014, $FFCE   ;.P 45,20,-50
K66B9:  .word $FFDD, $002D, $006E   ;.P -35,45,110

TD24PC:
K66BF:  .word $0000, $0000, $0000   ;.P 0,0,0
K66C5:  .word $FFA6, $FFEC, $FF9C   ;.P -90,-20,-100
K66CB:  .word $FFA6, $FFEC, $003C   ;.P -90,-20,60
K66D1:  .word $FFA6, $003C, $003C   ;.P -90,60,60
K66D7:  .word $FFF6, $0023, $FF9C   ;.P -10,35,-100
K66DD:  .word $0046, $FFEC, $FF9C   ;.P 70,-20,-100
K66E3:  .word $0046, $0005, $FF9C   ;.P 70,5,-100
K66E9:  .word $0096, $FFEC, $003C   ;.P 150,-20,60

TD25PC:
K66EF:  .word $0000, $0000, $0000   ;.P 0,0,0
K66F5:  .word $FFE7, $FFF6, $FF9C   ;.P -25,-10,-100
K66FB:  .word $FFE7, $000F, $FF9C   ;.P -25,15,-100
K6701:  .word $0037, $FFF6, $FF9C   ;.P 55,-10,-100
K6707:  .word $0037, $FFF6, $003C   ;.P 55,-10,60

;------------------------------------------------------------------------------
; JINOBJ - [note] Initialize objects: clear the BIC list BJBIC..BJBICZ, BJ_BIC = MS_BJBC/2 (starting BIC value, pairs of
;   points), BJ_RAM = M_OBJ (starting RAM address)
;   (also: TPNTZ, INOBJ_670D)
;------------------------------------------------------------------------------
JINOBJ:
TPNTZ:
INOBJ_670D:
K670D:  LDX  #BJBIC
K6710:  LDA  #$00

JINOBJ_10:
K6712:  STA  ,X+                    ;CLEAR OUT BIC LIST
K6714:  CMPX #BJBICZ
K6717:  BLO  JINOBJ_10
K6719:  LDA  #MS_BJBC
K671B:  LSRA                        ;PAIRS OF POINTS
K671C:  STA  BJ_BIC                 ;STARTING BIC VALUE
K671E:  LDD  #M_OBJ
K6721:  STD  BJ_RAM                 ;STARTING RAM ADDRESS
K6723:  RTS

;------------------------------------------------------------------------------
; JADBOBJ - ADD OBJECT POINTS TO MBOX
;   (also: ADBOBJ_6724)
;------------------------------------------------------------------------------
JADBOBJ:
ADBOBJ_6724:
K6724:  STB  BJ_ID                  ;B:=OBJECT #

JADOBJ:
ADOBJ_6726:
K6726:  LDB  BJ_ID
K6728:  LDX  #BJBIC
K672B:  LDA  B,X                    ;?MISSING FROM MBOX?
K672D:  BNE  JADOBJ_90              ;B IF ALREADY PRESENT IN MBOX
K672F:  LDA  BJ_BIC                 ;THEN START THE TRANSFER
K6731:  STA  B,X                    ;SAVE BIC ADDRESS
K6733:  LDX  #TDRWNM
K6736:  LDA  B,X                    ;# OF POINTS TO XFER
K6738:  STA  TMPCNT_4801
K673A:  LSRA                        ;PAIRS OF POINTS
K673B:  ADDA BJ_BIC                 ;UPDATE BIC
K673D:  BCC  JADOBJ_25              ;?TOO MANY POINTS?
K673F:  SWI                         ;***TEST***

JADOBJ_25:
;FOR PROD, REPOINT FOR PSUEDO-GOOD POINTS BJBIC TO M$BJBC
K6740:  STA  BJ_BIC
K6742:  LDX  #TDRWPC                ;POINTER TO 6 BYTE ROM POINTS
K6745:  LSLB                        ;ACCESSED BY WORDS
K6746:  LDX  B,X                    ;X-->6 BYTE ROM
K6748:  LDU  BJ_RAM                 ;U-->8 BYTE MRAM

JADOBJ_30:
K674A:  LDD  ,X                     ;X
K674C:  STD  ,U
K674E:  LDD  2,X                    ;Y
K6750:  STD  2,U
K6752:  LDD  4,X                    ;Z
K6754:  STD  4,U
K6756:  LEAX 6,X                    ;6 BYTE ROM
K6758:  LEAU 8,U                    ;8 BYTE MRAM
K675A:  DEC  TMPCNT_4801            ;ONE LESS POINT
K675C:  BGT  JADOBJ_30              ;LOOP THRU THEM ALL
K675E:  STU  BJ_RAM                 ;RECORD LATEST MRAM USAGE

JADOBJ_90:
K6760:  RTS

;------------------------------------------------------------------------------
; JBJCNTR - OBJECT DRAW -- BJCNTR,OBJCEN,OBJPNT,OBJDRW,BJLNV/B
;   EXPECTS VG AT CENTER, INFO AT QUO, YP, XP
;   (also: JOBJCEN, BJCNTR_6761, OBJCEN_6761)
;------------------------------------------------------------------------------
JBJCNTR:
JOBJCEN:
BJCNTR_6761:
OBJCEN_6761:
K6761:  LDD  M_QUO                  ;AT LEAST 7.5 CYCLES AFTER M.DVD
K6764:  STD  M_XP
K6767:  LDA  #MS_PERS
K6769:  JSR  MGOWT
K676C:  LDD  M_ZP
K676F:  STD  BJ_CY                  ;NEW CUNENT Y
K6771:  ADDD #VGOFFY                ;VIDEO CENTER OFFSET
K6774:  ANDA #$1F
K6776:  STD  ,Y++                   ;Y LONG VECTOR
K6778:  LDD  M_YP
K677B:  STD  BJ_CX
K677D:  ANDA #$1F
K677F:  STD  ,Y++                   ;X LONG VECTOR
K6781:  RTS

;------------------------------------------------------------------------------
; JBJLNV - [note] Draw visible line: M_QUO to M_XP and MS_PERS, then output a vector (Z bits $E0) from current
;   BJ_CX,BJ_CY to the new point M_YP (left/right), M_ZP (up/down) and make it current. Y-->VG list
;   (also: BJLNV_6782)
;------------------------------------------------------------------------------
JBJLNV:
BJLNV_6782:
K6782:  LDD  M_QUO                  ;AT LEAST 7.5 CYCLES AFTER M.DVD
K6785:  STD  M_XP
K6788:  LDA  #MS_PERS
K678A:  JSR  MGOWT
K678D:  LDD  M_ZP
K6790:  SUBD BJ_CY                  ;CURRENT UP/DOWN POSITION
K6792:  ANDA #$1F
K6794:  STD  ,Y++
K6796:  LDD  M_ZP
K6799:  STD  BJ_CY
K679B:  LDD  M_YP                   ;LEFT/RIGHT
K679E:  SUBD BJ_CX
K67A0:  ORA  #$E0
K67A2:  STD  ,Y++
K67A4:  LDD  M_YP
K67A7:  STD  BJ_CX
K67A9:  RTS

;------------------------------------------------------------------------------
; JBJLNB - [note] Draw blank line: as JBJLNV but the vector is output blank (Z bits off); updates BJ_CX,BJ_CY
;   (also: BJLNB_67AA)
;------------------------------------------------------------------------------
JBJLNB:
BJLNB_67AA:
K67AA:  LDD  M_QUO                  ;AT LEAST 7.5 CYCLES AFTER M.DVD
K67AD:  STD  M_XP
K67B0:  LDA  #MS_PERS
K67B2:  JSR  MGOWT
K67B5:  LDD  M_ZP
K67B8:  SUBD BJ_CY                  ;CURRENT UP/DOWN POSITION
K67BA:  ANDA #$1F
K67BC:  STD  ,Y++
K67BE:  LDD  M_ZP
K67C1:  STD  BJ_CY
K67C3:  LDD  M_YP                   ;LEFT/RIGHT
K67C6:  SUBD BJ_CX
K67C8:  ANDA #$1F                   ;BLANK
K67CA:  STD  ,Y++
K67CC:  LDD  M_YP
K67CF:  STD  BJ_CX
K67D1:  RTS

;------------------------------------------------------------------------------
; JOBJBPNT - [note] Process object points, B = object #: BJ_ID = B, then JOBJPNT - for each point of the object (count
;   from TDRWNM, BIC from BJBIC) do MS_PAD, 1/X and MS_PERS, saving M_YP,M_ZP in BJ_PNT (4 bytes each)
;   (also: OBJBPNT_67D2)
;------------------------------------------------------------------------------
JOBJBPNT:
OBJBPNT_67D2:
K67D2:  STB  BJ_ID

JOBJPNT:
OBJPNT_67D4:
K67D4:  LDB  BJ_ID                  ;SAVE OBJECT IDENTIFICATION
K67D6:  LDX  #TDRWNM
K67D9:  LDA  B,X                    ;# OF POINTS
K67DB:  STA  TMPCNT_4801
K67DD:  LDX  #BJBIC
K67E0:  LDA  B,X
K67E2:  BNE  JOBJPN_5
K67E4:  SWI                         ;***TEST***

JOBJPN_5:
;SET TO M$BJBC IF FAIL
K67E5:  LSLA                        ;ALWAYS IN PAIRS, SHIFT UP TO 9 BITS
K67E6:  STA  M_BICL
K67E9:  ROLA
K67EA:  STA  M_BICH
K67ED:  LDX  #BJ_PNT

JOBJPN_10:
K67F0:  LDA  #MS_PAD
K67F2:  JSR  MGOWT
K67F5:  LDD  M_XP                   ;X
K67F8:  STD  M_DVD
K67FB:  ORCC #$00                   ;TOTAL OF 7.5 CYCLE DELAY BEFORE READ
K67FD:  LDD  M_QUO                  ;GET 1/X, RECIPROCAL
K6800:  STD  M_XP
K6803:  LDA  #MS_PERS               ;1/X (*Y,*Z)
K6805:  JSR  MGOWT
K6808:  LDD  M_YP
K680B:  STD  ,X
K680D:  LDD  M_ZP
K6810:  STD  2,X
K6812:  LEAX 4,X
K6814:  DEC  TMPCNT_4801
K6816:  BGT  JOBJPN_10
K6818:  RTS

;------------------------------------------------------------------------------
; JOBJDRW - [note] Draw the object lines: interpret object BJ_ID's line list (TDRWLN, first byte must be 0), drawing
;   bright or blank vectors between BJ_PNT points until $FF or a damage code not above BJ_DMC
;   (also: OBJDRW_6819)
;------------------------------------------------------------------------------
JOBJDRW:
OBJDRW_6819:
K6819:  LDX  #TDRWLN
K681C:  LDB  BJ_ID                  ;PULL IN OBJECTS IDENTIFICATION
K681E:  LSLB
K681F:  LDU  B,X
K6821:  LDB  ,U+
K6823:  BEQ  JOBJDR_10              ;IFNE
K6825:  SWI                         ;OOPS, NOT AN INTERPRETABLE OBJECT

JOBJDR_10:
K6826:  LDB  ,U+
K6828:  BITB #$02
K682A:  BEQ  JOBJDR_18
K682C:  CMPB #$FF
K682E:  BEQ  JOBJDR_90
K6830:  LSRB
K6831:  LSRB
K6832:  CMPB BJ_DMC
K6834:  BHI  JOBJDR_10              ;CONTINUE IF BACK DAMAGE
K6836:  BRA  JOBJDR_90

JOBJDR_18:
K6838:  CLRA
K6839:  BITB #$03
K683B:  BNE  JOBJDR_20
K683D:  LDA  #$E0                   ;0 CODE HAS BRITNESS

JOBJDR_20:
K683F:  STA  BJ_BRT                 ;PRE FORMATTED BRITNESS
K6841:  ANDB #$FC                   ;PREPARE OFFSET
K6843:  LDX  #BJ_PNT                ;AND BASE POINT TABLE
K6846:  ABX                         ;ADD OFFSET TO POINT TABLE
K6847:  LDD  2,X                    ;Y
K6849:  SUBD BJ_CY
K684B:  ANDA #$1F
K684D:  STD  ,Y++
K684F:  LDD  ,X                     ;X
K6851:  SUBD BJ_CX
K6853:  ANDA #$1F
K6855:  ORA  BJ_BRT
K6857:  STD  ,Y++
K6859:  LDD  ,X
K685B:  STD  BJ_CX
K685D:  LDD  2,X
K685F:  STD  BJ_CY
K6861:  BRA  JOBJDR_10

JOBJDR_90:
K6863:  RTS

;------------------------------------------------------------------------------
; JBJGROT - [note] Pre-rotate object BJ_ID's ROM points (TDRWPC) with center at zero: MS_PSUB each point through M_GD
;   and save the result in 16-byte blocks from M_GDFE (MS_GDXR,YR,ZR); restores MS_TX,TY,TZ+M_U1
;   (also: BJGROT_6864)
;------------------------------------------------------------------------------
JBJGROT:
BJGROT_6864:
K6864:  LDD  #$0000                 ;CENTER OF OBJECT IS AT ZERO
K6867:  STD  MS_TX+M_U1
K686A:  STD  MS_TY+M_U1
K686D:  STD  MS_TZ+M_U1
K6870:  LDX  #TDRWNM                ;GET # OF POINTS
K6873:  LDB  BJ_ID
K6875:  LDA  B,X
K6877:  STA  TMPCNT_4801
K6879:  LDX  #TDRWPC
K687C:  LSLB
K687D:  LDU  B,X                    ;U-->ROM POINTS FOR OBJECT
K687F:  LDX  #M_GDFE                ;FRONT END FOR LATER FAST TRANSFORM
K6882:  LDD  ,U++
K6884:  STD  0+M_GD                 ;X
K6887:  LDD  ,U++
K6889:  STD  2+M_GD                 ;Y
K688C:  LDD  ,U++
K688E:  STD  4+M_GD                 ;Z
K6891:  LDD  #MS_GDBC               ;POINT TO TRANSFORM BLOCK
K6894:  STD  M_BIC
K6897:  LDA  #MS_PSUB               ;STANDARD PRESUBTRACT
K6899:  JSR  MGOWT
K689C:  LDD  M_XP
K689F:  STD  MS_GDXR,X
K68A1:  LDD  M_YP
K68A4:  STD  MS_GDYR,X
K68A7:  LDD  M_ZP
K68AA:  STD  MS_GDZR,X
K68AD:  LEAX $10,X
K68B0:  DEC  TMPCNT_4801
K68B2:  BGT  K6882                  ;LEEND
K68B4:  LDD  MS_TX+M_S1             ;RESTORE ORIGINAL VALS
K68B7:  STD  MS_TX+M_U1
K68BA:  LDD  MS_TY+M_S1
K68BD:  STD  MS_TY+M_U1
K68C0:  LDD  MS_TZ+M_S1
K68C3:  STD  MS_TZ+M_U1
K68C6:  RTS

;------------------------------------------------------------------------------
; JBJFROT - [note] Flipped pre-rotate: as JBJGROT but each point's Y is negated (flip Y direction) before MS_PSUB
;   (also: BJFROT_68C7)
;------------------------------------------------------------------------------
JBJFROT:
BJFROT_68C7:
K68C7:  LDD  #$0000                 ;CENTER OF OBJECT IS AT ZERO
K68CA:  STD  MS_TX+M_U1
K68CD:  STD  MS_TY+M_U1
K68D0:  STD  MS_TZ+M_U1
K68D3:  LDX  #TDRWNM                ;GET # OF POINTS
K68D6:  LDB  BJ_ID
K68D8:  LDA  B,X
K68DA:  STA  TMPCNT_4801
K68DC:  LDX  #TDRWPC
K68DF:  LSLB
K68E0:  LDU  B,X                    ;U-->ROM POINTS FOR OBJECT
K68E2:  LDX  #M_GDFE                ;FRONT END FOR LATER FAST TRANSFORM
K68E5:  LDD  ,U++
K68E7:  STD  0+M_GD                 ;X
K68EA:  LDD  #$0000
K68ED:  SUBD ,U++                   ;FLIP Y DIRECTION
K68EF:  STD  2+M_GD                 ;Y
K68F2:  LDD  ,U++
K68F4:  STD  4+M_GD                 ;Z
K68F7:  LDD  #MS_GDBC               ;POINT TO TRANSFORM BLOCK
K68FA:  STD  M_BIC
K68FD:  LDA  #MS_PSUB               ;STANDARD PRESUBTRACT
K68FF:  JSR  MGOWT
K6902:  LDD  M_XP
K6905:  STD  MS_GDXR,X
K6907:  LDD  M_YP
K690A:  STD  MS_GDYR,X
K690D:  LDD  M_ZP
K6910:  STD  MS_GDZR,X
K6913:  LEAX $10,X
K6916:  DEC  TMPCNT_4801
K6918:  BGT  K68E5                  ;LEEND
K691A:  LDD  MS_TX+M_S1             ;RESTORE ORIGINAL VALS
K691D:  STD  MS_TX+M_U1
K6920:  LDD  MS_TY+M_S1
K6923:  STD  MS_TY+M_U1
K6926:  LDD  MS_TZ+M_S1
K6929:  STD  MS_TZ+M_U1
K692C:  RTS

;------------------------------------------------------------------------------
; JBJGPNT - [note] Translate and project ground object's points: negate M_XP,YP,ZP, MS_PR2I, then for each point of
;   object BJ_ID feed 1/X (M_QUO) to M_YT and run MS_PRS2, starting the next divide from M_XT; no clipping
;   (also: BJGPNT_692D)
;------------------------------------------------------------------------------
JBJGPNT:
BJGPNT_692D:
K692D:  LDD  #$0000                 ;NEGATE XP,YP,ZP
K6930:  SUBD M_XP
K6933:  STD  M_XP
K6936:  LDD  #$0000
K6939:  SUBD M_YP
K693C:  STD  M_YP
K693F:  LDD  #$0000
K6942:  SUBD M_ZP
K6945:  STD  M_ZP
K6948:  LDD  #MS_GDBC               ;SET BIC TO Xr+1
K694B:  STD  M_BIC
K694E:  LDD  MS_GDXR+M_GDFE         ;USING FRONT END INITIALIZOR, TRANSLATE Xr
K6951:  SUBD M_XP                   ;Xr-(-Xp)=Xr+Xp
K6954:  STD  M_DVD                  ;START THE DIVIDER
K6957:  LDA  #MS_PR2I               ;PERSPECTIVE MULT 2 INIT
K6959:  STA  M_PCGO                 ;DOIT
K695C:  LDX  #TDRWNM
K695F:  LDB  BJ_ID                  ;SAVE OBJECT IDENTIFICATION
K6961:  LDA  B,X                    ;# OF POINTS
K6963:  LDB  #MS_PRS2               ;SPECIAL PERSPECTIVE MULT 2
K6965:  LDU  M_QUO                  ;1/X
K6968:  LDX  M_XT                   ;X FOR THE NEXT LOOP
K696B:  STU  M_YT                   ;SPECIAL PERS USES YT FOR MULT
K696E:  STB  M_PCGO                 ;DO SPECIAL PERS
K6971:  STX  M_DVD                  ;START NEXT 1/X
K6974:  DECA
K6975:  BGT  K6965                  ;LEEND
K6977:  RTS

;------------------------------------------------------------------------------
; JBJBCLP - WITH TIGHT CLIPPING
;   (also: BJBCLP_6978)
;------------------------------------------------------------------------------
JBJBCLP:
BJBCLP_6978:
K6978:  LDD  #$0000                 ;NEGATE XP,YP,ZP
K697B:  SUBD M_XP
K697E:  STD  M_XP
K6981:  LDD  #$0000
K6984:  SUBD M_YP
K6987:  STD  M_YP
K698A:  LDD  #$0000
K698D:  SUBD M_ZP
K6990:  STD  M_ZP
K6993:  LDD  #MS_GDBC               ;SET BIC TO Xr+1
K6996:  STD  M_BIC
K6999:  LDD  MS_GDXR+M_GDFE         ;USING FRONT END INITIALIZOR, TRANSLATE Xr
K699C:  SUBD M_XP                   ;Xr-(-Xp)=Xr+Xp
K699F:  STD  M_DVD                  ;START THE DIVIDER
K69A2:  LDA  #MS_PR2I               ;PERSPECTIVE MULT 2 INIT
K69A4:  STA  M_PCGO                 ;DOIT
K69A7:  LDX  #TDRWNM
K69AA:  LDB  BJ_ID                  ;SAVE OBJECT IDENTIFICATION
K69AC:  LDA  B,X                    ;# OF POINTS
K69AE:  LDB  #MS_PRS2               ;SPECIAL PERSPECTIVE MULT 2
K69B0:  LDU  M_QUO                  ;1/X
K69B3:  CMPU #$0100                 ;AFTER UNSIGNED DIVIDE,
;X TOO CLOSE(LE 100) GIVES NEGATIVE QUOTIENT
;X BEHIND(HS 8000) GIVES LO QUOTIENT(LS 100)
K69B7:  BGT  K69BC                  ;IFLE  SIGNED LE 100 CATCHES BOTH
K69B9:  LDU  #$7FFF
K69BC:  LDX  M_XT                   ;X FOR THE NEXT LOOP
K69BF:  STU  M_YT                   ;SPECIAL PERS USES YT FOR MULT
K69C2:  STB  M_PCGO                 ;DO SPECIAL PERS
K69C5:  STX  M_DVD                  ;START NEXT 1/X
K69C8:  DECA
K69C9:  BGT  K69B0                  ;LEEND
K69CB:  LDX  #TDRWNM                ;NOW SET SCREEN VALS TO REASONABLE VG NUMBERS
K69CE:  LDB  BJ_ID                  ;SAVE OBJECT IDENTIFICATION
K69D0:  LDA  B,X                    ;# OF POINTS
K69D2:  LDU  #M_GD+$C               ;U-->OUTPUT BLOCKS
K69D5:  LDX  ,U                     ;VG X
K69D7:  CMPX #VGEDGR+24
K69DA:  BLE  K69E3                  ;IFGT
K69DC:  LDX  #VGEDGR+24
K69DF:  STX  ,U
K69E1:  BRA  K69ED                  ;ELSE
K69E3:  CMPX #VGEDGL-24
K69E6:  BGE  K69ED                  ;IFLT
K69E8:  LDX  #VGEDGL-24
K69EB:  STX  ,U
K69ED:  LDX  2,U                    ;VG Y
K69EF:  CMPX #(VGEDGT-VGOFFY+24)&$FFFF
K69F2:  BLE  K69FB                  ;IFGT
K69F4:  LDX  #(VGEDGT-VGOFFY+24)&$FFFF
K69F7:  STX  2,U
K69F9:  BRA  K6A05                  ;ELSE
K69FB:  CMPX #VGEDGB-VGOFFY-24
K69FE:  BGE  K6A05                  ;IFLT
K6A00:  LDX  #VGEDGB-VGOFFY-24
K6A03:  STX  2,U
K6A05:  LEAU $10,U                  ;NEXT OUTPUT BLOCK
K6A08:  DECA
K6A09:  BGT  K69D5                  ;LEEND
K6A0B:  RTS

;------------------------------------------------------------------------------
; JBJGCLP - WITH GENEROUS CLIPPING
;   (also: BJGCLP_6A0C)
;------------------------------------------------------------------------------
JBJGCLP:
BJGCLP_6A0C:
K6A0C:  LDD  #$0000                 ;NEGATE XP,YP,ZP
K6A0F:  SUBD M_XP
K6A12:  STD  M_XP
K6A15:  LDD  #$0000
K6A18:  SUBD M_YP
K6A1B:  STD  M_YP
K6A1E:  LDD  #$0000
K6A21:  SUBD M_ZP
K6A24:  STD  M_ZP
K6A27:  LDD  #MS_GDBC               ;SET BIC TO Xr+1
K6A2A:  STD  M_BIC
K6A2D:  LDD  MS_GDXR+M_GDFE         ;USING FRONT END INITIALIZOR, TRANSLATE Xr
K6A30:  SUBD M_XP                   ;Xr-(-Xp)=Xr+Xp
K6A33:  STD  M_DVD                  ;START THE DIVIDER
K6A36:  LDA  #MS_PR2I               ;PERSPECTIVE MULT 2 INIT
K6A38:  STA  M_PCGO                 ;DOIT
K6A3B:  LDX  #TDRWNM
K6A3E:  LDB  BJ_ID                  ;SAVE OBJECT IDENTIFICATION
K6A40:  LDA  B,X                    ;# OF POINTS
K6A42:  LDB  #MS_PRS2               ;SPECIAL PERSPECTIVE MULT 2
K6A44:  LDU  M_QUO                  ;1/X
K6A47:  CMPU #$0100                 ;AFTER UNSIGNED DIVIDE,
;X TOO CLOSE(LE 100) GIVES NEGATIVE QUOTIENT
;X BEHIND(HS 8000) GIVES LO QUOTIENT(LS 100)
K6A4B:  BGT  K6A50                  ;IFLE  SIGNED LE 100 CATCHES BOTH
K6A4D:  LDU  #$7FFF
K6A50:  LDX  M_XT                   ;X FOR THE NEXT LOOP
K6A53:  STU  M_YT                   ;SPECIAL PERS USES YT FOR MULT
K6A56:  STB  M_PCGO                 ;DO SPECIAL PERS
K6A59:  STX  M_DVD                  ;START NEXT 1/X
K6A5C:  DECA
K6A5D:  BGT  K6A44                  ;LEEND
K6A5F:  LDX  #TDRWNM                ;NOW SET SCREEN VALS TO REASONABLE VG NUMBERS
K6A62:  LDB  BJ_ID                  ;SAVE OBJECT IDENTIFICATION
K6A64:  LDA  B,X                    ;# OF POINTS
K6A66:  LDU  #M_GD+$C               ;U-->OUTPUT BLOCKS
K6A69:  LDX  ,U                     ;VG X
K6A6B:  CMPX #VGEDGR+512
K6A6E:  BLE  K6A77                  ;IFGT
K6A70:  LDX  #VGEDGR+512
K6A73:  STX  ,U
K6A75:  BRA  K6A81                  ;ELSE
K6A77:  CMPX #VGEDGL-512
K6A7A:  BGE  K6A81                  ;IFLT
K6A7C:  LDX  #VGEDGL-512
K6A7F:  STX  ,U
K6A81:  LDX  2,U                    ;VG Y
K6A83:  CMPX #(VGEDGT-VGOFFY+512)&$FFFF
K6A86:  BLE  K6A8F                  ;IFGT
K6A88:  LDX  #(VGEDGT-VGOFFY+512)&$FFFF
K6A8B:  STX  2,U
K6A8D:  BRA  K6A99                  ;ELSE
K6A8F:  CMPX #VGEDGB-VGOFFY-512
K6A92:  BGE  K6A99                  ;IFLT
K6A94:  LDX  #VGEDGB-VGOFFY-512
K6A97:  STX  2,U
K6A99:  LEAU $10,U                  ;NEXT OUTPUT BLOCK
K6A9C:  DECA
K6A9D:  BGT  K6A69                  ;LEEND
K6A9F:  RTS

;------------------------------------------------------------------------------
; JBJGDRW - [note] Draw ground type object BJ_ID: its TDRWLN entry must begin with type byte 1 (else SWI); jumps to the
;   code that follows that byte (direct executing)
;   (also: BJGDRW_6AA0)
;------------------------------------------------------------------------------
JBJGDRW:
BJGDRW_6AA0:
K6AA0:  LDX  #TDRWLN
K6AA3:  LDB  BJ_ID                  ;PULL IN OBJECTS IDENTIFICATION
K6AA5:  LSLB
K6AA6:  LDU  B,X
K6AA8:  LDB  ,U+
K6AAA:  CMPB #$01
K6AAC:  BEQ  K6AAF                  ;IFNE  ?GROUND TYPE OBJECT?
K6AAE:  SWI                         ;OOPS, NOT CORRECT TYPE
K6AAF:  JMP  ,U                     ;GO DO IT

TD0LN:
;GROUND TYPE, DIRECT EXECUTING
K6AB1:  .byte $00                   ;.WL TIE  TIE FIGHTER
K6AB2:  .byte $05, $08, $0C, $10, $14, $18, $04 ;.BD 1,2,3,4,5,6,1
K6AB9:  .byte $1C, $20, $24, $28, $2C, $30, $1C ;.LD 7,8,9,10,11,12,7
K6AC0:  .byte $64, $68, $6C, $70, $74, $64 ;.LD 25,26,27,28,29,25
K6AC6:  .byte $94, $98, $9C, $BC    ;.LD 37,38,39,47
K6ACA:  .byte $9D, $A0, $A4, $C4    ;.BD 39,40,41,49
K6ACE:  .byte $A5, $A8, $AC, $B0, $94 ;.BD 41,42,43,44,37
K6AD3:  .byte $B4, $B8, $BC, $C0, $C4, $C8, $CC, $D0 ;.LD 45,46,47,48,49,50,51,52,45
K6ADB:  .byte $B4
K6ADC:  .byte $7C, $80, $84, $88, $8C, $90, $7C ;.LD 31,32,33,34,35,36,31
K6AE3:  .byte $4C, $50, $54, $58, $5C, $60, $4C ;.LD 19,20,21,22,23,24,19
K6AEA:  .byte $34, $38, $3C, $40, $44, $48, $34 ;.LD 13,14,15,16,17,18,13
K6AF1:  .byte $39, $50, $80, $B8, $98, $68, $20, $08 ;.BD 14,20,32,46,38,26,8,2
K6AF9:  .byte $0D, $24, $6C, $A0    ;.BD 3,9,27,40
K6AFD:  .byte $C1, $84, $54, $3C    ;.BD 48,33,21,15
K6B01:  .byte $41, $58, $88, $C8, $A8, $70, $28, $10 ;.BD 16,22,34,50,42,28,10,4
K6B09:  .byte $15, $2C, $74, $AC, $CC, $8C, $5C, $44 ;.BD 5,11,29,43,51,35,23,17
K6B11:  .byte $49, $60, $90, $D0, $B0, $78, $30, $18 ;.BD 18,24,36,52,44,30,12,6
K6B19:  .byte $FF                   ;.LEND

TD1LN:
TD2LN:
;TIE FIGHTER, EXPLODED PIECES
K6B1A:  .byte $00                   ;.WL TI1  LEFT WING AND STRUT
K6B1B:  .byte $1D, $20, $24, $28, $2C, $30, $1C ;.BD 7,8,9,10,11,12,7  INNER CIRCLE OF LEFT FIN
K6B22:  .byte $34, $38, $3C, $40, $44, $48, $34 ;.LD 13,14,15,16,17,18,13  STRUT CIRCLE ON BODY
K6B29:  .byte $1D, $04, $08, $0C, $10, $14, $18, $04 ;.BD 7,1,2,3,4,5,6,1  OUTER CIRCLE OF LEFT FIN
K6B31:  .byte $09, $20, $38         ;.BD 2,8,14  SPIDER LINES
K6B34:  .byte $3D, $24, $0C         ;.BD 15,9,3
K6B37:  .byte $11, $28, $40         ;.BD 4,10,16
K6B3A:  .byte $45, $2C, $14         ;.BD 17,11,5
K6B3D:  .byte $19, $30, $48         ;.BD 6,12,18
K6B40:  .byte $FF                   ;.LEND

TD3LN:
K6B41:  .byte $00                   ;.WL TI3  CENTER TIE CABIN
;.LD 25,26,27,28,29,25
K6B42:  .byte $05, $08, $0C, $10, $14, $04 ;.BD 1,2,3,4,5,1
;.LD 37,38,39,47
K6B48:  .byte $34, $38, $3C, $5C    ;.LD 13,14,15,23
;.BD 39,40,41,49
K6B4C:  .byte $3D, $40, $44, $64    ;.BD 15,16,17,25
;.BD 41,42,43,44,37
K6B50:  .byte $45, $48, $4C, $50, $34 ;.BD 17,18,19,20,13
;.LD 45,46,47,48,49,50,51,52,45
K6B55:  .byte $54, $58, $5C, $60, $64, $68, $6C, $70 ;.LD 21,22,23,24,25,26,27,28,21
K6B5D:  .byte $54
;.LD 31,32,33,34,35,36,31
K6B5E:  .byte $1C, $20, $24, $28, $2C, $30, $1C ;.LD 7,8,9,10,11,12,7
;.BD 32,46,38,26
K6B65:  .byte $21, $58, $38, $08    ;.BD 8,22,14,2
;.BD 27,40
K6B69:  .byte $0D, $40              ;.BD 3,16
;.BD 48,33
K6B6B:  .byte $61, $24              ;.BD 24,9
;.BD 34,50,42,28
K6B6D:  .byte $29, $68, $48, $10    ;.BD 10,26,18,4
;.BD 29,43,51,35
K6B71:  .byte $15, $4C, $6C, $2C    ;.BD 5,19,27,11
;.BD 36,52,44,30
K6B75:  .byte $31, $70, $50, $18    ;.BD 12,28,20,6
K6B79:  .byte $FF                   ;.LEND

TD4LN:
K6B7A:  .byte $00                   ;.WL RTH  DARTH VADER TIE FIGHTER
;RIGHT WING
K6B7B:  .byte $21, $04, $08, $0C, $20, $1C, $10, $0C ;.BD 8,1,2,3,8,7,4,3
K6B83:  .byte $11, $14, $18, $1C    ;.BD 4,5,6,7
;RIGHT STRUT
K6B87:  .byte $31, $2C, $28, $24, $30, $70 ;.BD 12,11,10,9,12,28
K6B8D:  .byte $6D, $2C              ;.BD 27,11
K6B8F:  .byte $29, $68              ;.BD 10,26
K6B91:  .byte $65, $24              ;.BD 25,9
;.BD 13,12,11,10,9,14,13,33
;.BD 32,12
;.BD 11,31
;.BD 30,10
;.BD 9,29
;.BD 34,14
;BODY
K6B93:  .byte $95, $90, $8C, $88, $A8, $AC, $B0, $B4 ;.BD 37,36,35,34,42,43,44,45,37
K6B9B:  .byte $94
K6B9C:  .byte $98, $B8, $BC, $C0, $A4, $84, $A0, $9C ;.LD 38,46,47,48,41,33,40,39,38
K6BA4:  .byte $98
;.BD 45,44,43,42,50,51,52,53,45
;.LD 46,54,55,56,49,41,48,47,46
K6BA5:  .byte $9D, $90              ;.BD 39,36
K6BA7:  .byte $8D, $A0              ;.BD 35,40
K6BA9:  .byte $85, $88              ;.BD 33,34
K6BAB:  .byte $A9, $A4              ;.BD 42,41
K6BAD:  .byte $C1, $AC              ;.BD 48,43
K6BAF:  .byte $B1, $BC              ;.BD 44,47
K6BB1:  .byte $B9, $B4              ;.BD 46,45
;.BD 47,44
;.BD 43,48
;.BD 41,42
;.BD 50,49
;.BD 56,51
;.BD 52,55
;.BD 54,53
;LEFT STRUT
K6BB3:  .byte $7D, $5C, $58, $54, $54, $60, $5C ;.BD 31,23,22,21,21,24,23
K6BBA:  .byte $59, $78              ;.BD 22,30
K6BBC:  .byte $75, $54              ;.BD 29,21
K6BBE:  .byte $61, $80              ;.BD 24,32
;.BD 38,26,25,24,23,28,27,26
;.BD 25,37
;.BD 36,24
;.BD 23,35
;.BD 40,28
;.BD 27,39
;LEFT WING
K6BC0:  .byte $4D, $48, $44, $40, $4C, $50, $3C, $40 ;.BD 19,18,17,16,19,20,15,16
K6BC8:  .byte $3D, $38, $34, $50    ;.BD 15,14,13,20
;.BD 21,20,19,18,21,22,17,18
;.BD 17,16,15,22
;FRONT WINDOW
K6BCC:  .byte $C5, $C8, $CC, $D0, $D4, $D8, $DC, $E0 ;.BD 49,50,51,52,53,54,55,56,49,53
K6BD4:  .byte $C4, $D4
K6BD6:  .byte $D9, $C8              ;.BD 54,50
K6BD8:  .byte $CD, $DC              ;.BD 51,55
K6BDA:  .byte $E1, $D0              ;.BD 56,52
K6BDC:  .byte $FF                   ;.LEND

TD5LN:
K6BDD:  .byte $00                   ;.WL XW  X WING
K6BDE:  .byte $FF                   ;.LEND

TD6LN:
K6BDF:  .byte $00                   ;.WL YW  Y WING
K6BE0:  .byte $FF                   ;.LEND

TD17LN:
TD19LN:
TD20LN:
TD21LN:
TD22LN:
TD23LN:
;OTHER EXPLOSION PICS
K6BE1:  .byte $00                   ;.WL TW1  TOWER TOP
K6BE2:  .byte $05, $08, $0C, $04, $10, $14, $08 ;.BD 1,2,3,1,4,5,2
K6BE9:  .byte $15, $18, $0C         ;.BD 5,6,3
K6BEC:  .byte $19, $10              ;.BD 6,4
K6BEE:  .byte $FF                   ;.LEND

TD18LN:
K6BEF:  .byte $00                   ;.WL TW2  TOWER TOP
K6BF0:  .byte $05, $08, $0C, $10, $04, $14, $18, $08 ;.BD 1,2,3,4,1,5,6,2
K6BF8:  .byte $19, $1C, $0C         ;.BD 6,7,3
K6BFB:  .byte $1D, $20, $10         ;.BD 7,8,4
K6BFE:  .byte $21, $14              ;.BD 8,5
K6C00:  .byte $FF                   ;.LEND

TD24LN:
K6C01:  .byte $00                   ;.WL WG2  TRENCH WALL GUN TURRET
K6C02:  .byte $05, $08, $0C, $10, $04, $14, $1C, $08 ;.BD 1,2,3,4,1,5,7,2
K6C0A:  .byte $0D, $1C, $18, $14    ;.BD 3,7,6,5
K6C0E:  .byte $19, $10              ;.BD 6,4
K6C10:  .byte $FF                   ;.LEND

TD25LN:
K6C11:  .byte $00                   ;.WL WG3  TRENCH WALL GUN TURRET
K6C12:  .byte $05, $08, $0C, $04, $10, $08 ;.BD 1,2,3,1,4,2
K6C18:  .byte $0D, $10              ;.BD 3,4
K6C1A:  .byte $FF                   ;.LEND

TD9LN:
K6C1B:  .byte $01                   ;.WGD BNK  BUNKER
K6C1C:  LDA  #M_GD/$100             ;PLOT 0  ASSUMES STARTING FROM CENTER
K6C1E:  TFR  A,DP
.dpage $5E
K6C20:  LDD  $5E0E
K6C22:  ADDD #VGOFFY
K6C25:  ANDA #$1F
K6C27:  STD  ,Y
K6C29:  LDD  $5E0C
K6C2B:  ANDA #$1F
K6C2D:  STD  2,Y
K6C2F:  LDD  M_GDSC                 ;MOVD M.GDSC
K6C31:  STD  4,Y
K6C33:  LDD  M_GDCT                 ;MOVD M.GDCT  DRAW TOP OF BUNKER
K6C35:  STD  6,Y
K6C37:  LDD  $5E1E                  ;BDRAWTO 1,2,14,13,1,3,15,13
K6C39:  SUBD $5E0E
K6C3B:  ANDA #$1F
K6C3D:  STD  8,Y
K6C3F:  LDD  $5E1C
K6C41:  SUBD $5E0C
K6C43:  ANDA #$1F
K6C45:  STD  $A,Y
K6C47:  LDD  $5E2E
K6C49:  SUBD $5E1E
K6C4B:  ANDA #$1F
K6C4D:  STD  $C,Y
K6C4F:  LDD  $5E2C
K6C51:  SUBD $5E1C
K6C53:  ORA  #$E0
K6C55:  STD  $E,Y
K6C57:  LDD  $5EEE
K6C59:  SUBD $5E2E
K6C5B:  ANDA #$1F
K6C5D:  STD  $10,Y
K6C60:  LDD  $5EEC
K6C62:  SUBD $5E2C
K6C64:  ORA  #$E0
K6C66:  STD  $12,Y
K6C69:  LDD  $5EDE
K6C6B:  SUBD $5EEE
K6C6D:  ANDA #$1F
K6C6F:  STD  $14,Y
K6C72:  LDD  $5EDC
K6C74:  SUBD $5EEC
K6C76:  ORA  #$E0
K6C78:  STD  $16,Y
K6C7B:  LDD  $5E1E
K6C7D:  SUBD $5EDE
K6C7F:  ANDA #$1F
K6C81:  STD  $18,Y
K6C84:  LDD  $5E1C
K6C86:  SUBD $5EDC
K6C88:  ORA  #$E0
K6C8A:  STD  $1A,Y
K6C8D:  LDD  $5E3E
K6C8F:  SUBD $5E1E
K6C91:  ANDA #$1F
K6C93:  STD  $1C,Y
K6C96:  LDD  $5E3C
K6C98:  SUBD $5E1C
K6C9A:  ORA  #$E0
K6C9C:  STD  $1E,Y
K6C9F:  LDD  $5EFE
K6CA1:  SUBD $5E3E
K6CA3:  ANDA #$1F
K6CA5:  STD  $20,Y
K6CA8:  LDD  $5EFC
K6CAA:  SUBD $5E3C
K6CAC:  ORA  #$E0
K6CAE:  STD  $22,Y
K6CB1:  LDD  $5EDE
K6CB3:  SUBD $5EFE
K6CB5:  ANDA #$1F
K6CB7:  STD  $24,Y
K6CBA:  LDD  $5EDC
K6CBC:  SUBD $5EFC
K6CBE:  ORA  #$E0
K6CC0:  STD  $26,Y
K6CC3:  LDD  $5EEE                  ;BDRAWTO 14,15
K6CC5:  SUBD $5EDE
K6CC7:  ANDA #$1F
K6CC9:  STD  $28,Y
K6CCC:  LDD  $5EEC
K6CCE:  SUBD $5EDC
K6CD0:  ANDA #$1F
K6CD2:  STD  $2A,Y
K6CD5:  LDD  $5EFE
K6CD7:  SUBD $5EEE
K6CD9:  ANDA #$1F
K6CDB:  STD  $2C,Y
K6CDE:  LDD  $5EFC
K6CE0:  SUBD $5EEC
K6CE2:  ORA  #$E0
K6CE4:  STD  $2E,Y
K6CE7:  LDD  #VGSCAL                ;ENDPLOT  CENTER AND BUMP Y
K6CEA:  STD  $30,Y
K6CED:  LDD  #VGCNTR
K6CF0:  STD  $32,Y
K6CF3:  LEAY $34,Y
K6CF6:  LDA  #DPRAM/$100
K6CF8:  TFR  A,DP
.dpage $48
K6CFA:  RTS

TD8LN:
TD7LN:
K6CFB:  .byte $01                   ;.WGD TWR
K6CFC:  LDA  #M_GD/$100             ;PLOT 0  ASSUMES STARTING FROM CENTER
K6CFE:  TFR  A,DP
.dpage $5E
K6D00:  LDD  $5E0E
K6D02:  ADDD #VGOFFY
K6D05:  ANDA #$1F
K6D07:  STD  ,Y
K6D09:  LDD  $5E0C
K6D0B:  ANDA #$1F
K6D0D:  STD  2,Y
K6D0F:  LDD  M_GDSC                 ;MOVD M.GDSC
K6D11:  STD  4,Y
K6D13:  LDD  M_GDCB                 ;MOVD M.GDCB  COLOR THE BASE
K6D15:  STD  6,Y
K6D17:  LDD  $5E1E                  ;BDRAWTO 1,3,15,12,9
K6D19:  SUBD $5E0E
K6D1B:  ANDA #$1F
K6D1D:  STD  8,Y
K6D1F:  LDD  $5E1C
K6D21:  SUBD $5E0C
K6D23:  ANDA #$1F
K6D25:  STD  $A,Y
K6D27:  LDD  $5E3E
K6D29:  SUBD $5E1E
K6D2B:  ANDA #$1F
K6D2D:  STD  $C,Y
K6D2F:  LDD  $5E3C
K6D31:  SUBD $5E1C
K6D33:  ORA  #$E0
K6D35:  STD  $E,Y
K6D37:  LDD  $5EFE
K6D39:  SUBD $5E3E
K6D3B:  ANDA #$1F
K6D3D:  STD  $10,Y
K6D40:  LDD  $5EFC
K6D42:  SUBD $5E3C
K6D44:  ORA  #$E0
K6D46:  STD  $12,Y
K6D49:  LDD  $5ECE
K6D4B:  SUBD $5EFE
K6D4D:  ANDA #$1F
K6D4F:  STD  $14,Y
K6D52:  LDD  $5ECC
K6D54:  SUBD $5EFC
K6D56:  ORA  #$E0
K6D58:  STD  $16,Y
K6D5B:  LDD  $5E9E
K6D5D:  SUBD $5ECE
K6D5F:  ANDA #$1F
K6D61:  STD  $18,Y
K6D64:  LDD  $5E9C
K6D66:  SUBD $5ECC
K6D68:  ORA  #$E0
K6D6A:  STD  $1A,Y
K6D6D:  LDD  M_GDCT                 ;MOVD M.GDCT  UP THE TOP
K6D6F:  STD  $1C,Y
K6D72:  LDD  $5E6E                  ;DRAWTO 6,4,7  AND DOWN THE MIDDLE
K6D74:  SUBD $5E9E
K6D76:  ANDA #$1F
K6D78:  STD  $1E,Y
K6D7B:  LDD  $5E6C
K6D7D:  SUBD $5E9C
K6D7F:  ORA  #$E0
K6D81:  STD  $20,Y
K6D84:  LDD  $5E4E
K6D86:  SUBD $5E6E
K6D88:  ANDA #$1F
K6D8A:  STD  $22,Y
K6D8D:  LDD  $5E4C
K6D8F:  SUBD $5E6C
K6D91:  ORA  #$E0
K6D93:  STD  $24,Y
K6D96:  LDD  $5E7E
K6D98:  SUBD $5E4E
K6D9A:  ANDA #$1F
K6D9C:  STD  $26,Y
K6D9F:  LDD  $5E7C
K6DA1:  SUBD $5E4C
K6DA3:  ORA  #$E0
K6DA5:  STD  $28,Y
K6DA8:  LDD  M_GDCB                 ;MOVD M.GDCB
K6DAA:  STD  $2A,Y
K6DAD:  LDD  $5EAE                  ;DRAWTO 10,13,1,2,14,11,8  UP LEFT SIDE
K6DAF:  SUBD $5E7E
K6DB1:  ANDA #$1F
K6DB3:  STD  $2C,Y
K6DB6:  LDD  $5EAC
K6DB8:  SUBD $5E7C
K6DBA:  ORA  #$E0
K6DBC:  STD  $2E,Y
K6DBF:  LDD  $5EDE
K6DC1:  SUBD $5EAE
K6DC3:  ANDA #$1F
K6DC5:  STD  $30,Y
K6DC8:  LDD  $5EDC
K6DCA:  SUBD $5EAC
K6DCC:  ORA  #$E0
K6DCE:  STD  $32,Y
K6DD1:  LDD  $5E1E
K6DD3:  SUBD $5EDE
K6DD5:  ANDA #$1F
K6DD7:  STD  $34,Y
K6DDA:  LDD  $5E1C
K6DDC:  SUBD $5EDC
K6DDE:  ORA  #$E0
K6DE0:  STD  $36,Y
K6DE3:  LDD  $5E2E
K6DE5:  SUBD $5E1E
K6DE7:  ANDA #$1F
K6DE9:  STD  $38,Y
K6DEC:  LDD  $5E2C
K6DEE:  SUBD $5E1C
K6DF0:  ORA  #$E0
K6DF2:  STD  $3A,Y
K6DF5:  LDD  $5EEE
K6DF7:  SUBD $5E2E
K6DF9:  ANDA #$1F
K6DFB:  STD  $3C,Y
K6DFE:  LDD  $5EEC
K6E00:  SUBD $5E2C
K6E02:  ORA  #$E0
K6E04:  STD  $3E,Y
K6E07:  LDD  $5EBE
K6E09:  SUBD $5EEE
K6E0B:  ANDA #$1F
K6E0D:  STD  $40,Y
K6E10:  LDD  $5EBC
K6E12:  SUBD $5EEC
K6E14:  ORA  #$E0
K6E16:  STD  $42,Y
K6E19:  LDD  $5E8E
K6E1B:  SUBD $5EBE
K6E1D:  ANDA #$1F
K6E1F:  STD  $44,Y
K6E22:  LDD  $5E8C
K6E24:  SUBD $5EBC
K6E26:  ORA  #$E0
K6E28:  STD  $46,Y
K6E2B:  LDD  M_GDCT                 ;MOVD M.GDCT  AND NOW THE TOP
K6E2D:  STD  $48,Y
K6E30:  LDD  $5E5E                  ;DRAWTO 5,4
K6E32:  SUBD $5E8E
K6E34:  ANDA #$1F
K6E36:  STD  $4A,Y
K6E39:  LDD  $5E5C
K6E3B:  SUBD $5E8C
K6E3D:  ORA  #$E0
K6E3F:  STD  $4C,Y
K6E42:  LDD  $5E4E
K6E44:  SUBD $5E5E
K6E46:  ANDA #$1F
K6E48:  STD  $4E,Y
K6E4B:  LDD  $5E4C
K6E4D:  SUBD $5E5C
K6E4F:  ORA  #$E0
K6E51:  STD  $50,Y
K6E54:  LDD  $5E7E                  ;BDRAWTO 7,9  BOTTOM OF CANNON
K6E56:  SUBD $5E4E
K6E58:  ANDA #$1F
K6E5A:  STD  $52,Y
K6E5D:  LDD  $5E7C
K6E5F:  SUBD $5E4C
K6E61:  ANDA #$1F
K6E63:  STD  $54,Y
K6E66:  LDD  $5E9E
K6E68:  SUBD $5E7E
K6E6A:  ANDA #$1F
K6E6C:  STD  $56,Y
K6E6F:  LDD  $5E9C
K6E71:  SUBD $5E7C
K6E73:  ORA  #$E0
K6E75:  STD  $58,Y
K6E78:  LDD  $5E7E                  ;BDRAWTO 7,8  OTHER SIDE OF BOTTOM OF CANNON
K6E7A:  SUBD $5E9E
K6E7C:  ANDA #$1F
K6E7E:  STD  $5A,Y
K6E81:  LDD  $5E7C
K6E83:  SUBD $5E9C
K6E85:  ANDA #$1F
K6E87:  STD  $5C,Y
K6E8A:  LDD  $5E8E
K6E8C:  SUBD $5E7E
K6E8E:  ANDA #$1F
K6E90:  STD  $5E,Y
K6E93:  LDD  $5E8C
K6E95:  SUBD $5E7C
K6E97:  ORA  #$E0
K6E99:  STD  $60,Y
K6E9C:  LDD  #VGSCAL                ;ENDPLOT  CENTER AND BUMP Y
K6E9F:  STD  $62,Y
K6EA2:  LDD  #VGCNTR
K6EA5:  STD  $64,Y
K6EA8:  LEAY $66,Y
K6EAB:  LDA  #DPRAM/$100
K6EAD:  TFR  A,DP
.dpage $48
K6EAF:  RTS

TD10LN:
K6EB0:  .byte $01                   ;.WGD STB  STUB OF TOWER WITHOUT BUNKER HAT ON TOP
K6EB1:  LDA  #M_GD/$100             ;PLOT 0  ASSUMES STARTING FROM CENTER
K6EB3:  TFR  A,DP
.dpage $5E
K6EB5:  LDD  $5E0E
K6EB7:  ADDD #VGOFFY
K6EBA:  ANDA #$1F
K6EBC:  STD  ,Y
K6EBE:  LDD  $5E0C
K6EC0:  ANDA #$1F
K6EC2:  STD  2,Y
K6EC4:  LDD  M_GDSC                 ;MOVD M.GDSC
K6EC6:  STD  4,Y
K6EC8:  LDD  M_GDCB                 ;MOVD M.GDCB  COLOR THE BASE
K6ECA:  STD  6,Y
K6ECC:  LDD  $5E1E                  ;BDRAWTO 1,3,15,12,9  UP RIGHT SIDE
K6ECE:  SUBD $5E0E
K6ED0:  ANDA #$1F
K6ED2:  STD  8,Y
K6ED4:  LDD  $5E1C
K6ED6:  SUBD $5E0C
K6ED8:  ANDA #$1F
K6EDA:  STD  $A,Y
K6EDC:  LDD  $5E3E
K6EDE:  SUBD $5E1E
K6EE0:  ANDA #$1F
K6EE2:  STD  $C,Y
K6EE4:  LDD  $5E3C
K6EE6:  SUBD $5E1C
K6EE8:  ORA  #$E0
K6EEA:  STD  $E,Y
K6EEC:  LDD  $5EFE
K6EEE:  SUBD $5E3E
K6EF0:  ANDA #$1F
K6EF2:  STD  $10,Y
K6EF5:  LDD  $5EFC
K6EF7:  SUBD $5E3C
K6EF9:  ORA  #$E0
K6EFB:  STD  $12,Y
K6EFE:  LDD  $5ECE
K6F00:  SUBD $5EFE
K6F02:  ANDA #$1F
K6F04:  STD  $14,Y
K6F07:  LDD  $5ECC
K6F09:  SUBD $5EFC
K6F0B:  ORA  #$E0
K6F0D:  STD  $16,Y
K6F10:  LDD  $5E9E
K6F12:  SUBD $5ECE
K6F14:  ANDA #$1F
K6F16:  STD  $18,Y
K6F19:  LDD  $5E9C
K6F1B:  SUBD $5ECC
K6F1D:  ORA  #$E0
K6F1F:  STD  $1A,Y
K6F22:  LDD  $5E7E                  ;DRAWTO 7,10,13,1  DOWN CENTER
K6F24:  SUBD $5E9E
K6F26:  ANDA #$1F
K6F28:  STD  $1C,Y
K6F2B:  LDD  $5E7C
K6F2D:  SUBD $5E9C
K6F2F:  ORA  #$E0
K6F31:  STD  $1E,Y
K6F34:  LDD  $5EAE
K6F36:  SUBD $5E7E
K6F38:  ANDA #$1F
K6F3A:  STD  $20,Y
K6F3D:  LDD  $5EAC
K6F3F:  SUBD $5E7C
K6F41:  ORA  #$E0
K6F43:  STD  $22,Y
K6F46:  LDD  $5EDE
K6F48:  SUBD $5EAE
K6F4A:  ANDA #$1F
K6F4C:  STD  $24,Y
K6F4F:  LDD  $5EDC
K6F51:  SUBD $5EAC
K6F53:  ORA  #$E0
K6F55:  STD  $26,Y
K6F58:  LDD  $5E1E
K6F5A:  SUBD $5EDE
K6F5C:  ANDA #$1F
K6F5E:  STD  $28,Y
K6F61:  LDD  $5E1C
K6F63:  SUBD $5EDC
K6F65:  ORA  #$E0
K6F67:  STD  $2A,Y
K6F6A:  LDD  $5E2E                  ;DRAWTO 2,14,11,8,7  UP LEFT SIDE
K6F6C:  SUBD $5E1E
K6F6E:  ANDA #$1F
K6F70:  STD  $2C,Y
K6F73:  LDD  $5E2C
K6F75:  SUBD $5E1C
K6F77:  ORA  #$E0
K6F79:  STD  $2E,Y
K6F7C:  LDD  $5EEE
K6F7E:  SUBD $5E2E
K6F80:  ANDA #$1F
K6F82:  STD  $30,Y
K6F85:  LDD  $5EEC
K6F87:  SUBD $5E2C
K6F89:  ORA  #$E0
K6F8B:  STD  $32,Y
K6F8E:  LDD  $5EBE
K6F90:  SUBD $5EEE
K6F92:  ANDA #$1F
K6F94:  STD  $34,Y
K6F97:  LDD  $5EBC
K6F99:  SUBD $5EEC
K6F9B:  ORA  #$E0
K6F9D:  STD  $36,Y
K6FA0:  LDD  $5E8E
K6FA2:  SUBD $5EBE
K6FA4:  ANDA #$1F
K6FA6:  STD  $38,Y
K6FA9:  LDD  $5E8C
K6FAB:  SUBD $5EBC
K6FAD:  ORA  #$E0
K6FAF:  STD  $3A,Y
K6FB2:  LDD  $5E7E
K6FB4:  SUBD $5E8E
K6FB6:  ANDA #$1F
K6FB8:  STD  $3C,Y
K6FBB:  LDD  $5E7C
K6FBD:  SUBD $5E8C
K6FBF:  ORA  #$E0
K6FC1:  STD  $3E,Y
K6FC4:  LDD  #VGSCAL                ;ENDPLOT  CENTER AND BUMP Y
K6FC7:  STD  $40,Y
K6FCA:  LDD  #VGCNTR
K6FCD:  STD  $42,Y
K6FD0:  LEAY $44,Y
K6FD3:  LDA  #DPRAM/$100
K6FD5:  TFR  A,DP
.dpage $48
K6FD7:  RTS

TD12LN:
TD13LN:
K6FD8:  .byte $01                   ;.WGD WGA  WALL GUN, TYPE A
K6FD9:  LDA  #M_GD/$100             ;PLOT 4
K6FDB:  TFR  A,DP
.dpage $5E
K6FDD:  LDD  $5E4E
K6FDF:  ADDD #VGOFFY
K6FE2:  ANDA #$1F
K6FE4:  STD  ,Y
K6FE6:  LDD  $5E4C
K6FE8:  ANDA #$1F
K6FEA:  STD  2,Y
K6FEC:  LDD  #(VGCRED*$100)+VGCOPC  ;MOVD #VGCRED*100+VGCOPC
K6FEF:  STD  4,Y
K6FF1:  LDD  $5E3E                  ;DRAWTO 3,2,1,4,9,10,1
K6FF3:  SUBD $5E4E
K6FF5:  ANDA #$1F
K6FF7:  STD  6,Y
K6FF9:  LDD  $5E3C
K6FFB:  SUBD $5E4C
K6FFD:  ORA  #$E0
K6FFF:  STD  8,Y
K7001:  LDD  $5E2E
K7003:  SUBD $5E3E
K7005:  ANDA #$1F
K7007:  STD  $A,Y
K7009:  LDD  $5E2C
K700B:  SUBD $5E3C
K700D:  ORA  #$E0
K700F:  STD  $C,Y
K7011:  LDD  $5E1E
K7013:  SUBD $5E2E
K7015:  ANDA #$1F
K7017:  STD  $E,Y
K7019:  LDD  $5E1C
K701B:  SUBD $5E2C
K701D:  ORA  #$E0
K701F:  STD  $10,Y
K7022:  LDD  $5E4E
K7024:  SUBD $5E1E
K7026:  ANDA #$1F
K7028:  STD  $12,Y
K702B:  LDD  $5E4C
K702D:  SUBD $5E1C
K702F:  ORA  #$E0
K7031:  STD  $14,Y
K7034:  LDD  $5E9E
K7036:  SUBD $5E4E
K7038:  ANDA #$1F
K703A:  STD  $16,Y
K703D:  LDD  $5E9C
K703F:  SUBD $5E4C
K7041:  ORA  #$E0
K7043:  STD  $18,Y
K7046:  LDD  $5EAE
K7048:  SUBD $5E9E
K704A:  ANDA #$1F
K704C:  STD  $1A,Y
K704F:  LDD  $5EAC
K7051:  SUBD $5E9C
K7053:  ORA  #$E0
K7055:  STD  $1C,Y
K7058:  LDD  $5E1E
K705A:  SUBD $5EAE
K705C:  ANDA #$1F
K705E:  STD  $1E,Y
K7061:  LDD  $5E1C
K7063:  SUBD $5EAC
K7065:  ORA  #$E0
K7067:  STD  $20,Y
K706A:  LDD  $5EAE                  ;BDRAWTO 10,6,2
K706C:  SUBD $5E1E
K706E:  ANDA #$1F
K7070:  STD  $22,Y
K7073:  LDD  $5EAC
K7075:  SUBD $5E1C
K7077:  ANDA #$1F
K7079:  STD  $24,Y
K707C:  LDD  $5E6E
K707E:  SUBD $5EAE
K7080:  ANDA #$1F
K7082:  STD  $26,Y
K7085:  LDD  $5E6C
K7087:  SUBD $5EAC
K7089:  ORA  #$E0
K708B:  STD  $28,Y
K708E:  LDD  $5E2E
K7090:  SUBD $5E6E
K7092:  ANDA #$1F
K7094:  STD  $2A,Y
K7097:  LDD  $5E2C
K7099:  SUBD $5E6C
K709B:  ORA  #$E0
K709D:  STD  $2C,Y
K70A0:  LDD  $5E3E                  ;BDRAWTO 3,7,6,5,8,7,9,8
K70A2:  SUBD $5E2E
K70A4:  ANDA #$1F
K70A6:  STD  $2E,Y
K70A9:  LDD  $5E3C
K70AB:  SUBD $5E2C
K70AD:  ANDA #$1F
K70AF:  STD  $30,Y
K70B2:  LDD  $5E7E
K70B4:  SUBD $5E3E
K70B6:  ANDA #$1F
K70B8:  STD  $32,Y
K70BB:  LDD  $5E7C
K70BD:  SUBD $5E3C
K70BF:  ORA  #$E0
K70C1:  STD  $34,Y
K70C4:  LDD  $5E6E
K70C6:  SUBD $5E7E
K70C8:  ANDA #$1F
K70CA:  STD  $36,Y
K70CD:  LDD  $5E6C
K70CF:  SUBD $5E7C
K70D1:  ORA  #$E0
K70D3:  STD  $38,Y
K70D6:  LDD  $5E5E
K70D8:  SUBD $5E6E
K70DA:  ANDA #$1F
K70DC:  STD  $3A,Y
K70DF:  LDD  $5E5C
K70E1:  SUBD $5E6C
K70E3:  ORA  #$E0
K70E5:  STD  $3C,Y
K70E8:  LDD  $5E8E
K70EA:  SUBD $5E5E
K70EC:  ANDA #$1F
K70EE:  STD  $3E,Y
K70F1:  LDD  $5E8C
K70F3:  SUBD $5E5C
K70F5:  ORA  #$E0
K70F7:  STD  $40,Y
K70FA:  LDD  $5E7E
K70FC:  SUBD $5E8E
K70FE:  ANDA #$1F
K7100:  STD  $42,Y
K7103:  LDD  $5E7C
K7105:  SUBD $5E8C
K7107:  ORA  #$E0
K7109:  STD  $44,Y
K710C:  LDD  $5E9E
K710E:  SUBD $5E7E
K7110:  ANDA #$1F
K7112:  STD  $46,Y
K7115:  LDD  $5E9C
K7117:  SUBD $5E7C
K7119:  ORA  #$E0
K711B:  STD  $48,Y
K711E:  LDD  $5E8E
K7120:  SUBD $5E9E
K7122:  ANDA #$1F
K7124:  STD  $4A,Y
K7127:  LDD  $5E8C
K7129:  SUBD $5E9C
K712B:  ORA  #$E0
K712D:  STD  $4C,Y
K7130:  LDD  $5EDE                  ;DRAWTO 13,14,9
K7132:  SUBD $5E8E
K7134:  ANDA #$1F
K7136:  STD  $4E,Y
K7139:  LDD  $5EDC
K713B:  SUBD $5E8C
K713D:  ORA  #$E0
K713F:  STD  $50,Y
K7142:  LDD  $5EEE
K7144:  SUBD $5EDE
K7146:  ANDA #$1F
K7148:  STD  $52,Y
K714B:  LDD  $5EEC
K714D:  SUBD $5EDC
K714F:  ORA  #$E0
K7151:  STD  $54,Y
K7154:  LDD  $5E9E
K7156:  SUBD $5EEE
K7158:  ANDA #$1F
K715A:  STD  $56,Y
K715D:  LDD  $5E9C
K715F:  SUBD $5EEC
K7161:  ORA  #$E0
K7163:  STD  $58,Y
K7166:  LDD  $5EEE                  ;BDRAWTO 14,12,10,5,11,12
K7168:  SUBD $5E9E
K716A:  ANDA #$1F
K716C:  STD  $5A,Y
K716F:  LDD  $5EEC
K7171:  SUBD $5E9C
K7173:  ANDA #$1F
K7175:  STD  $5C,Y
K7178:  LDD  $5ECE
K717A:  SUBD $5EEE
K717C:  ANDA #$1F
K717E:  STD  $5E,Y
K7181:  LDD  $5ECC
K7183:  SUBD $5EEC
K7185:  ORA  #$E0
K7187:  STD  $60,Y
K718A:  LDD  $5EAE
K718C:  SUBD $5ECE
K718E:  ANDA #$1F
K7190:  STD  $62,Y
K7193:  LDD  $5EAC
K7195:  SUBD $5ECC
K7197:  ORA  #$E0
K7199:  STD  $64,Y
K719C:  LDD  $5E5E
K719E:  SUBD $5EAE
K71A0:  ANDA #$1F
K71A2:  STD  $66,Y
K71A5:  LDD  $5E5C
K71A7:  SUBD $5EAC
K71A9:  ORA  #$E0
K71AB:  STD  $68,Y
K71AE:  LDD  $5EBE
K71B0:  SUBD $5E5E
K71B2:  ANDA #$1F
K71B4:  STD  $6A,Y
K71B7:  LDD  $5EBC
K71B9:  SUBD $5E5C
K71BB:  ORA  #$E0
K71BD:  STD  $6C,Y
K71C0:  LDD  $5ECE
K71C2:  SUBD $5EBE
K71C4:  ANDA #$1F
K71C6:  STD  $6E,Y
K71C9:  LDD  $5ECC
K71CB:  SUBD $5EBC
K71CD:  ORA  #$E0
K71CF:  STD  $70,Y
K71D2:  LDD  $5EBE                  ;BDRAWTO 11,13
K71D4:  SUBD $5ECE
K71D6:  ANDA #$1F
K71D8:  STD  $72,Y
K71DB:  LDD  $5EBC
K71DD:  SUBD $5ECC
K71DF:  ANDA #$1F
K71E1:  STD  $74,Y
K71E4:  LDD  $5EDE
K71E6:  SUBD $5EBE
K71E8:  ANDA #$1F
K71EA:  STD  $76,Y
K71ED:  LDD  $5EDC
K71EF:  SUBD $5EBC
K71F1:  ORA  #$E0
K71F3:  STD  $78,Y
K71F6:  LDD  #VGSCAL                ;ENDPLOT  CENTER AND BUMP Y
K71F9:  STD  $7A,Y
K71FC:  LDD  #VGCNTR
K71FF:  STD  $7C,Y
K7202:  LEAY $7E,Y
K7205:  LDA  #DPRAM/$100
K7207:  TFR  A,DP
.dpage $48
K7209:  RTS

TD11LN:
K720A:  .byte $01                   ;.WGD WPN  WALL PANEL
K720B:  LDA  #M_GD/$100             ;PLOT 0  ASSUMES STARTING FROM CENTER
K720D:  TFR  A,DP
.dpage $5E
K720F:  LDD  $5E0E
K7211:  ADDD #VGOFFY
K7214:  ANDA #$1F
K7216:  STD  ,Y
K7218:  LDD  $5E0C
K721A:  ANDA #$1F
K721C:  STD  2,Y
K721E:  LDD  #(VGCGRN*$100)+VGCOPC  ;MOVD #VGCGRN*100+VGCOPC
K7221:  STD  4,Y
K7223:  LDD  $5E1E                  ;DRAWTO 1,2,3,0
K7225:  SUBD $5E0E
K7227:  ANDA #$1F
K7229:  STD  6,Y
K722B:  LDD  $5E1C
K722D:  SUBD $5E0C
K722F:  ORA  #$E0
K7231:  STD  8,Y
K7233:  LDD  $5E2E
K7235:  SUBD $5E1E
K7237:  ANDA #$1F
K7239:  STD  $A,Y
K723B:  LDD  $5E2C
K723D:  SUBD $5E1C
K723F:  ORA  #$E0
K7241:  STD  $C,Y
K7243:  LDD  $5E3E
K7245:  SUBD $5E2E
K7247:  ANDA #$1F
K7249:  STD  $E,Y
K724B:  LDD  $5E3C
K724D:  SUBD $5E2C
K724F:  ORA  #$E0
K7251:  STD  $10,Y
K7254:  LDD  $5E0E
K7256:  SUBD $5E3E
K7258:  ANDA #$1F
K725A:  STD  $12,Y
K725D:  LDD  $5E0C
K725F:  SUBD $5E3C
K7261:  ORA  #$E0
K7263:  STD  $14,Y
K7266:  LDD  $5E4E                  ;BDRAWTO 4,5,6,7,4
K7268:  SUBD $5E0E
K726A:  ANDA #$1F
K726C:  STD  $16,Y
K726F:  LDD  $5E4C
K7271:  SUBD $5E0C
K7273:  ANDA #$1F
K7275:  STD  $18,Y
K7278:  LDD  $5E5E
K727A:  SUBD $5E4E
K727C:  ANDA #$1F
K727E:  STD  $1A,Y
K7281:  LDD  $5E5C
K7283:  SUBD $5E4C
K7285:  ORA  #$E0
K7287:  STD  $1C,Y
K728A:  LDD  $5E6E
K728C:  SUBD $5E5E
K728E:  ANDA #$1F
K7290:  STD  $1E,Y
K7293:  LDD  $5E6C
K7295:  SUBD $5E5C
K7297:  ORA  #$E0
K7299:  STD  $20,Y
K729C:  LDD  $5E7E
K729E:  SUBD $5E6E
K72A0:  ANDA #$1F
K72A2:  STD  $22,Y
K72A5:  LDD  $5E7C
K72A7:  SUBD $5E6C
K72A9:  ORA  #$E0
K72AB:  STD  $24,Y
K72AE:  LDD  $5E4E
K72B0:  SUBD $5E7E
K72B2:  ANDA #$1F
K72B4:  STD  $26,Y
K72B7:  LDD  $5E4C
K72B9:  SUBD $5E7C
K72BB:  ORA  #$E0
K72BD:  STD  $28,Y
K72C0:  LDD  #VGSCAL                ;ENDPLOT  CENTER AND BUMP Y
K72C3:  STD  $2A,Y
K72C6:  LDD  #VGCNTR
K72C9:  STD  $2C,Y
K72CC:  LEAY $2E,Y
K72CF:  LDA  #DPRAM/$100
K72D1:  TFR  A,DP
.dpage $48
K72D3:  RTS

TD14LN:
K72D4:  .byte $01                   ;.WGD WFF  WALL FORCE FIELD
;COLOR SET BY CALLER
K72D5:  LDA  #M_GD/$100             ;PLOT 1
K72D7:  TFR  A,DP
.dpage $5E
K72D9:  LDD  $5E1E
K72DB:  ADDD #VGOFFY
K72DE:  ANDA #$1F
K72E0:  STD  ,Y
K72E2:  LDD  $5E1C
K72E4:  ANDA #$1F
K72E6:  STD  2,Y
K72E8:  LDD  $5E0E                  ;DRAWTO 0,2,3,1,5,4,0
K72EA:  SUBD $5E1E
K72EC:  ANDA #$1F
K72EE:  STD  4,Y
K72F0:  LDD  $5E0C
K72F2:  SUBD $5E1C
K72F4:  ORA  #$E0
K72F6:  STD  6,Y
K72F8:  LDD  $5E2E
K72FA:  SUBD $5E0E
K72FC:  ANDA #$1F
K72FE:  STD  8,Y
K7300:  LDD  $5E2C
K7302:  SUBD $5E0C
K7304:  ORA  #$E0
K7306:  STD  $A,Y
K7308:  LDD  $5E3E
K730A:  SUBD $5E2E
K730C:  ANDA #$1F
K730E:  STD  $C,Y
K7310:  LDD  $5E3C
K7312:  SUBD $5E2C
K7314:  ORA  #$E0
K7316:  STD  $E,Y
K7318:  LDD  $5E1E
K731A:  SUBD $5E3E
K731C:  ANDA #$1F
K731E:  STD  $10,Y
K7321:  LDD  $5E1C
K7323:  SUBD $5E3C
K7325:  ORA  #$E0
K7327:  STD  $12,Y
K732A:  LDD  $5E5E
K732C:  SUBD $5E1E
K732E:  ANDA #$1F
K7330:  STD  $14,Y
K7333:  LDD  $5E5C
K7335:  SUBD $5E1C
K7337:  ORA  #$E0
K7339:  STD  $16,Y
K733C:  LDD  $5E4E
K733E:  SUBD $5E5E
K7340:  ANDA #$1F
K7342:  STD  $18,Y
K7345:  LDD  $5E4C
K7347:  SUBD $5E5C
K7349:  ORA  #$E0
K734B:  STD  $1A,Y
K734E:  LDD  $5E0E
K7350:  SUBD $5E4E
K7352:  ANDA #$1F
K7354:  STD  $1C,Y
K7357:  LDD  $5E0C
K7359:  SUBD $5E4C
K735B:  ORA  #$E0
K735D:  STD  $1E,Y
K7360:  LDD  #VGSCAL                ;ENDPLOT  CENTER AND BUMP Y
K7363:  STD  $20,Y
K7366:  LDD  #VGCNTR
K7369:  STD  $22,Y
K736C:  LEAY $24,Y
K736F:  LDA  #DPRAM/$100
K7371:  TFR  A,DP
.dpage $48
K7373:  RTS

TD15LN:
K7374:  .byte $01                   ;.WGD WFG  WALL FORCE FIELD, COLLIDED VERSION
K7375:  LDA  #M_GD/$100             ;PLOT 1
K7377:  TFR  A,DP
.dpage $5E
K7379:  LDD  $5E1E
K737B:  ADDD #VGOFFY
K737E:  ANDA #$1F
K7380:  STD  ,Y
K7382:  LDD  $5E1C
K7384:  ANDA #$1F
K7386:  STD  2,Y
K7388:  LDD  #VJFLS                 ;MOVD #VJFLS  CATWALK COLOR WHEN COLLIDED
K738B:  STD  4,Y
K738D:  LDD  $5E0E                  ;DRAWTO 0
K738F:  SUBD $5E1E
K7391:  ANDA #$1F
K7393:  STD  6,Y
K7395:  LDD  $5E0C
K7397:  SUBD $5E1C
K7399:  ORA  #$E0
K739B:  STD  8,Y
K739D:  LDD  $5E2E                  ;DRAWTO 2
K739F:  SUBD $5E0E
K73A1:  ANDA #$1F
K73A3:  STD  $A,Y
K73A5:  LDD  $5E2C
K73A7:  SUBD $5E0C
K73A9:  ORA  #$E0
K73AB:  STD  $C,Y
K73AD:  LDD  $5E3E                  ;DRAWTO 3
K73AF:  SUBD $5E2E
K73B1:  ANDA #$1F
K73B3:  STD  $E,Y
K73B5:  LDD  $5E3C
K73B7:  SUBD $5E2C
K73B9:  ORA  #$E0
K73BB:  STD  $10,Y
K73BE:  LDD  $5E1E                  ;DRAWTO 1,5
K73C0:  SUBD $5E3E
K73C2:  ANDA #$1F
K73C4:  STD  $12,Y
K73C7:  LDD  $5E1C
K73C9:  SUBD $5E3C
K73CB:  ORA  #$E0
K73CD:  STD  $14,Y
K73D0:  LDD  $5E5E
K73D2:  SUBD $5E1E
K73D4:  ANDA #$1F
K73D6:  STD  $16,Y
K73D9:  LDD  $5E5C
K73DB:  SUBD $5E1C
K73DD:  ORA  #$E0
K73DF:  STD  $18,Y
K73E2:  LDD  $5E6E                  ;DRAWTO 6,3
K73E4:  SUBD $5E5E
K73E6:  ANDA #$1F
K73E8:  STD  $1A,Y
K73EB:  LDD  $5E6C
K73ED:  SUBD $5E5C
K73EF:  ORA  #$E0
K73F1:  STD  $1C,Y
K73F4:  LDD  $5E3E
K73F6:  SUBD $5E6E
K73F8:  ANDA #$1F
K73FA:  STD  $1E,Y
K73FD:  LDD  $5E3C
K73FF:  SUBD $5E6C
K7401:  ORA  #$E0
K7403:  STD  $20,Y
K7406:  LDD  $5E5E                  ;BDRAWTO 5,4
K7408:  SUBD $5E3E
K740A:  ANDA #$1F
K740C:  STD  $22,Y
K740F:  LDD  $5E5C
K7411:  SUBD $5E3C
K7413:  ANDA #$1F
K7415:  STD  $24,Y
K7418:  LDD  $5E4E
K741A:  SUBD $5E5E
K741C:  ANDA #$1F
K741E:  STD  $26,Y
K7421:  LDD  $5E4C
K7423:  SUBD $5E5C
K7425:  ORA  #$E0
K7427:  STD  $28,Y
K742A:  LDD  $5E0E                  ;DRAWTO 0
K742C:  SUBD $5E4E
K742E:  ANDA #$1F
K7430:  STD  $2A,Y
K7433:  LDD  $5E0C
K7435:  SUBD $5E4C
K7437:  ORA  #$E0
K7439:  STD  $2C,Y
K743C:  LDD  #VGSCAL                ;ENDPLOT  CENTER AND BUMP Y
K743F:  STD  $2E,Y
K7442:  LDD  #VGCNTR
K7445:  STD  $30,Y
K7448:  LEAY $32,Y
K744B:  LDA  #DPRAM/$100
K744D:  TFR  A,DP
.dpage $48
K744F:  RTS

TD16LN:
K7450:  .byte $01                   ;.WGD PORT  THERMAL EXHAUST PORT
K7451:  LDA  #M_GD/$100             ;PLOT 5
K7453:  TFR  A,DP
.dpage $5E
K7455:  LDD  $5E5E
K7457:  ADDD #VGOFFY
K745A:  ANDA #$1F
K745C:  STD  ,Y
K745E:  LDD  $5E5C
K7460:  ANDA #$1F
K7462:  STD  2,Y
K7464:  LDD  #(VGCGRN*$100)+VGCOPC  ;MOVD #VGCGRN*100+VGCOPC  OUTER BASE
K7467:  STD  4,Y
K7469:  LDD  $5E9E                  ;DRAWTO 9,8,4
K746B:  SUBD $5E5E
K746D:  ANDA #$1F
K746F:  STD  6,Y
K7471:  LDD  $5E9C
K7473:  SUBD $5E5C
K7475:  ORA  #$E0
K7477:  STD  8,Y
K7479:  LDD  $5E8E
K747B:  SUBD $5E9E
K747D:  ANDA #$1F
K747F:  STD  $A,Y
K7481:  LDD  $5E8C
K7483:  SUBD $5E9C
K7485:  ORA  #$E0
K7487:  STD  $C,Y
K7489:  LDD  $5E4E
K748B:  SUBD $5E8E
K748D:  ANDA #$1F
K748F:  STD  $E,Y
K7491:  LDD  $5E4C
K7493:  SUBD $5E8C
K7495:  ORA  #$E0
K7497:  STD  $10,Y
K749A:  LDD  $5E6E                  ;BDRAWTO 6,10,11,7
K749C:  SUBD $5E4E
K749E:  ANDA #$1F
K74A0:  STD  $12,Y
K74A3:  LDD  $5E6C
K74A5:  SUBD $5E4C
K74A7:  ANDA #$1F
K74A9:  STD  $14,Y
K74AC:  LDD  $5EAE
K74AE:  SUBD $5E6E
K74B0:  ANDA #$1F
K74B2:  STD  $16,Y
K74B5:  LDD  $5EAC
K74B7:  SUBD $5E6C
K74B9:  ORA  #$E0
K74BB:  STD  $18,Y
K74BE:  LDD  $5EBE
K74C0:  SUBD $5EAE
K74C2:  ANDA #$1F
K74C4:  STD  $1A,Y
K74C7:  LDD  $5EBC
K74C9:  SUBD $5EAC
K74CB:  ORA  #$E0
K74CD:  STD  $1C,Y
K74D0:  LDD  $5E7E
K74D2:  SUBD $5EBE
K74D4:  ANDA #$1F
K74D6:  STD  $1E,Y
K74D9:  LDD  $5E7C
K74DB:  SUBD $5EBC
K74DD:  ORA  #$E0
K74DF:  STD  $20,Y
K74E2:  LDD  #(VGCTRQ*$100)+VGCOPC  ;MOVD #VGCTRQ*100+VGCOPC  INNER BERM
K74E5:  STD  $22,Y
K74E8:  LDD  $5E6E                  ;DRAWTO 6,2
K74EA:  SUBD $5E7E
K74EC:  ANDA #$1F
K74EE:  STD  $24,Y
K74F1:  LDD  $5E6C
K74F3:  SUBD $5E7C
K74F5:  ORA  #$E0
K74F7:  STD  $26,Y
K74FA:  LDD  $5E2E
K74FC:  SUBD $5E6E
K74FE:  ANDA #$1F
K7500:  STD  $28,Y
K7503:  LDD  $5E2C
K7505:  SUBD $5E6C
K7507:  ORA  #$E0
K7509:  STD  $2A,Y
K750C:  LDD  $5E6E                  ;BDRAWTO 6,4,0
K750E:  SUBD $5E2E
K7510:  ANDA #$1F
K7512:  STD  $2C,Y
K7515:  LDD  $5E6C
K7517:  SUBD $5E2C
K7519:  ANDA #$1F
K751B:  STD  $2E,Y
K751E:  LDD  $5E4E
K7520:  SUBD $5E6E
K7522:  ANDA #$1F
K7524:  STD  $30,Y
K7527:  LDD  $5E4C
K7529:  SUBD $5E6C
K752B:  ORA  #$E0
K752D:  STD  $32,Y
K7530:  LDD  $5E0E
K7532:  SUBD $5E4E
K7534:  ANDA #$1F
K7536:  STD  $34,Y
K7539:  LDD  $5E0C
K753B:  SUBD $5E4C
K753D:  ORA  #$E0
K753F:  STD  $36,Y
K7542:  LDD  $5E4E                  ;BDRAWTO 4,5,1
K7544:  SUBD $5E0E
K7546:  ANDA #$1F
K7548:  STD  $38,Y
K754B:  LDD  $5E4C
K754D:  SUBD $5E0C
K754F:  ANDA #$1F
K7551:  STD  $3A,Y
K7554:  LDD  $5E5E
K7556:  SUBD $5E4E
K7558:  ANDA #$1F
K755A:  STD  $3C,Y
K755D:  LDD  $5E5C
K755F:  SUBD $5E4C
K7561:  ORA  #$E0
K7563:  STD  $3E,Y
K7566:  LDD  $5E1E
K7568:  SUBD $5E5E
K756A:  ANDA #$1F
K756C:  STD  $40,Y
K756F:  LDD  $5E1C
K7571:  SUBD $5E5C
K7573:  ORA  #$E0
K7575:  STD  $42,Y
K7578:  LDD  $5E5E                  ;BDRAWTO 5,7,3
K757A:  SUBD $5E1E
K757C:  ANDA #$1F
K757E:  STD  $44,Y
K7581:  LDD  $5E5C
K7583:  SUBD $5E1C
K7585:  ANDA #$1F
K7587:  STD  $46,Y
K758A:  LDD  $5E7E
K758C:  SUBD $5E5E
K758E:  ANDA #$1F
K7590:  STD  $48,Y
K7593:  LDD  $5E7C
K7595:  SUBD $5E5C
K7597:  ORA  #$E0
K7599:  STD  $4A,Y
K759C:  LDD  $5E3E
K759E:  SUBD $5E7E
K75A0:  ANDA #$1F
K75A2:  STD  $4C,Y
K75A5:  LDD  $5E3C
K75A7:  SUBD $5E7C
K75A9:  ORA  #$E0
K75AB:  STD  $4E,Y
K75AE:  LDD  #((VGCRED*$100)+VGCOPC)|$FF ;MOVD #VGCRED*100+VGCOPC!0FF  PORTHOLE
K75B1:  STD  $50,Y
K75B4:  LDD  $5E2E                  ;DRAWTO 2,0,1,3
K75B6:  SUBD $5E3E
K75B8:  ANDA #$1F
K75BA:  STD  $52,Y
K75BD:  LDD  $5E2C
K75BF:  SUBD $5E3C
K75C1:  ORA  #$E0
K75C3:  STD  $54,Y
K75C6:  LDD  $5E0E
K75C8:  SUBD $5E2E
K75CA:  ANDA #$1F
K75CC:  STD  $56,Y
K75CF:  LDD  $5E0C
K75D1:  SUBD $5E2C
K75D3:  ORA  #$E0
K75D5:  STD  $58,Y
K75D8:  LDD  $5E1E
K75DA:  SUBD $5E0E
K75DC:  ANDA #$1F
K75DE:  STD  $5A,Y
K75E1:  LDD  $5E1C
K75E3:  SUBD $5E0C
K75E5:  ORA  #$E0
K75E7:  STD  $5C,Y
K75EA:  LDD  $5E3E
K75EC:  SUBD $5E1E
K75EE:  ANDA #$1F
K75F0:  STD  $5E,Y
K75F3:  LDD  $5E3C
K75F5:  SUBD $5E1C
K75F7:  ORA  #$E0
K75F9:  STD  $60,Y
K75FC:  LDD  #VGSCAL                ;ENDPLOT  CENTER AND BUMP Y
K75FF:  STD  $62,Y
K7602:  LDD  #VGCNTR
K7605:  STD  $64,Y
K7608:  LEAY $66,Y
K760B:  LDA  #DPRAM/$100
K760D:  TFR  A,DP
.dpage $48
K760F:  RTS

TDRWLN:          ;LINE POINTERS, PER OBJECT
K7610:  .word $6AB1                 ;.REPT TD$EQ+1
K7612:  .word $6B1A
K7614:  .word $6B1A
K7616:  .word $6B41
K7618:  .word $6B7A
K761A:  .word $6BDD
K761C:  .word $6BDF
K761E:  .word $6CFB
K7620:  .word $6CFB
K7622:  .word $6C1B
K7624:  .word $6EB0
K7626:  .word $720A
K7628:  .word $6FD8
K762A:  .word $6FD8
K762C:  .word $72D4
K762E:  .word $7374
K7630:  .word $7450
K7632:  .word $6BE1
K7634:  .word $6BEF
K7636:  .word $6BE1
K7638:  .word $6BE1
K763A:  .word $6BE1
K763C:  .word $6BE1
K763E:  .word $6BE1
K7640:  .word $6C01
K7642:  .word $6C11

TDRWNM:          ;# OF POINTS PER OBJECT
K7644:  .byte $36, $14, $14, $1E, $3A, $02, $02, $10 ;.REPT TD$EQ+1
K764C:  .byte $10, $10, $10, $08, $10, $10, $06, $06
K7654:  .byte $0C, $08, $0A, $08, $08, $08, $08, $08
K765C:  .byte $08, $06

TDRWPC:          ;ROM POINTS TABLES, PER OBJECT
K765E:  .word $6005                 ;.REPT TD$EQ+1
K7660:  .word $6143
K7662:  .word $61B5
K7664:  .word $6227
K7666:  .word $62D5
K7668:  .word $642B
K766A:  .word $6431
K766C:  .word $6437
K766E:  .word $6437
K7670:  .word $6437
K7672:  .word $6437
K7674:  .word $6497
K7676:  .word $64C7
K7678:  .word $64C7
K767A:  .word $6521
K767C:  .word $6521
K767E:  .word $6545
K7680:  .word $658D
K7682:  .word $65B7
K7684:  .word $65ED
K7686:  .word $6617
K7688:  .word $6641
K768A:  .word $666B
K768C:  .word $6695
K768E:  .word $66BF
K7690:  .word $66EF

;==============================================================================
; MODULE WSFIL9   WSFIL9.MAC
;==============================================================================

;.SBTTL STAR WARS FILLER FOR ROM 9(OVERLAY SECOND HALF OF 0)
K7692:  .byte $DE, $EF, $7F, $CD, $CF, $4F, $7D, $7D ;.IRPC .A,<NORMAN AVELLAR WAS FIRST>
K769A:  .byte $FE, $55, $5D, $ED, $F1, $72, $A4, $F7
K76A2:  .byte $FB, $7F, $AF, $EF, $FD, $7E, $D3, $F7

FILL9:
K76AA:  .byte $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF ;.REPT 1756.  FILL WITH FF'S
K76B2:  .byte $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
K76BA:  .byte $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
K76C2:  .byte $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
K76CA:  .byte $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
K76D2:  .byte $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
K76DA:  .byte $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
K76E2:  .byte $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
K76EA:  .byte $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
K76F2:  .byte $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
K76FA:  .byte $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
K7702:  .byte $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
K770A:  .byte $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
K7712:  .byte $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
K771A:  .byte $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
K7722:  .byte $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
K772A:  .byte $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
K7732:  .byte $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
K773A:  .byte $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
K7742:  .byte $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
K774A:  .byte $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
K7752:  .byte $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
K775A:  .byte $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
K7762:  .byte $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
K776A:  .byte $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
K7772:  .byte $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
K777A:  .byte $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
K7782:  .byte $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
K778A:  .byte $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
K7792:  .byte $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
K779A:  .byte $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
K77A2:  .byte $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
K77AA:  .byte $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
K77B2:  .byte $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
K77BA:  .byte $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
K77C2:  .byte $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
K77CA:  .byte $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
K77D2:  .byte $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
K77DA:  .byte $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
K77E2:  .byte $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
K77EA:  .byte $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
K77F2:  .byte $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
K77FA:  .byte $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
K7802:  .byte $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
K780A:  .byte $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
K7812:  .byte $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
K781A:  .byte $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
K7822:  .byte $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
K782A:  .byte $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
K7832:  .byte $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
K783A:  .byte $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
K7842:  .byte $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
K784A:  .byte $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
K7852:  .byte $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
K785A:  .byte $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
K7862:  .byte $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
K786A:  .byte $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
K7872:  .byte $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
K787A:  .byte $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
K7882:  .byte $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
K788A:  .byte $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
K7892:  .byte $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
K789A:  .byte $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
K78A2:  .byte $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
K78AA:  .byte $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
K78B2:  .byte $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
K78BA:  .byte $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
K78C2:  .byte $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
K78CA:  .byte $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
K78D2:  .byte $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
K78DA:  .byte $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
K78E2:  .byte $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
K78EA:  .byte $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
K78F2:  .byte $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
K78FA:  .byte $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
K7902:  .byte $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
K790A:  .byte $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
K7912:  .byte $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
K791A:  .byte $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
K7922:  .byte $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
K792A:  .byte $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
K7932:  .byte $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
K793A:  .byte $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
K7942:  .byte $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
K794A:  .byte $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
K7952:  .byte $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
K795A:  .byte $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
K7962:  .byte $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
K796A:  .byte $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
K7972:  .byte $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
K797A:  .byte $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
K7982:  .byte $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
K798A:  .byte $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
K7992:  .byte $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
K799A:  .byte $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
K79A2:  .byte $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
K79AA:  .byte $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
K79B2:  .byte $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
K79BA:  .byte $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
K79C2:  .byte $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
K79CA:  .byte $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
K79D2:  .byte $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
K79DA:  .byte $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
K79E2:  .byte $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
K79EA:  .byte $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
K79F2:  .byte $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
K79FA:  .byte $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
K7A02:  .byte $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
K7A0A:  .byte $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
K7A12:  .byte $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
K7A1A:  .byte $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
K7A22:  .byte $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
K7A2A:  .byte $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
K7A32:  .byte $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
K7A3A:  .byte $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
K7A42:  .byte $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
K7A4A:  .byte $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
K7A52:  .byte $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
K7A5A:  .byte $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
K7A62:  .byte $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
K7A6A:  .byte $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
K7A72:  .byte $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
K7A7A:  .byte $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
K7A82:  .byte $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
K7A8A:  .byte $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
K7A92:  .byte $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
K7A9A:  .byte $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
K7AA2:  .byte $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
K7AAA:  .byte $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
K7AB2:  .byte $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
K7ABA:  .byte $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
K7AC2:  .byte $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
K7ACA:  .byte $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
K7AD2:  .byte $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
K7ADA:  .byte $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
K7AE2:  .byte $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
K7AEA:  .byte $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
K7AF2:  .byte $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
K7AFA:  .byte $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
K7B02:  .byte $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
K7B0A:  .byte $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
K7B12:  .byte $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
K7B1A:  .byte $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
K7B22:  .byte $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
K7B2A:  .byte $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
K7B32:  .byte $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
K7B3A:  .byte $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
K7B42:  .byte $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
K7B4A:  .byte $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
K7B52:  .byte $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
K7B5A:  .byte $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
K7B62:  .byte $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
K7B6A:  .byte $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
K7B72:  .byte $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
K7B7A:  .byte $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
K7B82:  .byte $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
K7B8A:  .byte $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
K7B92:  .byte $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
K7B9A:  .byte $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
K7BA2:  .byte $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
K7BAA:  .byte $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
K7BB2:  .byte $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
K7BBA:  .byte $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
K7BC2:  .byte $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
K7BCA:  .byte $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
K7BD2:  .byte $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
K7BDA:  .byte $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
K7BE2:  .byte $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
K7BEA:  .byte $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
K7BF2:  .byte $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
K7BFA:  .byte $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
K7C02:  .byte $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
K7C0A:  .byte $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
K7C12:  .byte $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
K7C1A:  .byte $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
K7C22:  .byte $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
K7C2A:  .byte $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
K7C32:  .byte $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
K7C3A:  .byte $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
K7C42:  .byte $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
K7C4A:  .byte $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
K7C52:  .byte $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
K7C5A:  .byte $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
K7C62:  .byte $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
K7C6A:  .byte $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
K7C72:  .byte $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
K7C7A:  .byte $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
K7C82:  .byte $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
K7C8A:  .byte $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
K7C92:  .byte $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
K7C9A:  .byte $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
K7CA2:  .byte $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
K7CAA:  .byte $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
K7CB2:  .byte $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
K7CBA:  .byte $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
K7CC2:  .byte $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
K7CCA:  .byte $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
K7CD2:  .byte $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
K7CDA:  .byte $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
K7CE2:  .byte $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
K7CEA:  .byte $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
K7CF2:  .byte $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
K7CFA:  .byte $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
K7D02:  .byte $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
K7D0A:  .byte $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
K7D12:  .byte $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
K7D1A:  .byte $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
K7D22:  .byte $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
K7D2A:  .byte $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
K7D32:  .byte $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
K7D3A:  .byte $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
K7D42:  .byte $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
K7D4A:  .byte $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
K7D52:  .byte $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
K7D5A:  .byte $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
K7D62:  .byte $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
K7D6A:  .byte $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
K7D72:  .byte $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
K7D7A:  .byte $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
K7D82:  .byte $FF, $FF, $FF, $FF

CPYRT9:
K7D86:  .byte $43, $4F, $50, $59, $52, $49, $47, $48 ;.ASCII /COPYRIGHT 1983 ATARI/
K7D8E:  .byte $54, $20, $31, $39, $38, $33, $20, $41
K7D96:  .byte $54, $41, $52, $49

;==============================================================================
; MODULE WSSTAR   WSSTAR.MAC
;   STAR GENERATORS
;==============================================================================

;------------------------------------------------------------------------------
; JVWSTAR - STARS--VWSTAR,STARGN,STARNW
;   (also: VWSTAR_7D9A)
;------------------------------------------------------------------------------
JVWSTAR:
VWSTAR_7D9A:
K7D9A:  LDD  ST_UX                  ;STARS RELATIVE MOVEMENT
K7D9C:  STD  MS_TX+M_U1
K7D9F:  LDD  ST_UY
K7DA2:  STD  MS_TY+M_U1
K7DA5:  LDD  ST_UZ
K7DA8:  STD  MS_TZ+M_U1
K7DAB:  LDX  #ST_QU
K7DAE:  LDD  #$0000

JVWSTA_4:
K7DB1:  STD  ,X++                   ;CLEAR OUT STAR QUE
K7DB3:  CMPX #ST_QUZ
K7DB6:  BLO  JVWSTA_4
K7DB8:  STA  ST_GNB                 ;NO STAR TO GEN YET
K7DBA:  LDA  #(((VGCWHT*$100)+VGCOPC)&$FF00)/$100
K7DBC:  LDB  ST_BRT                 ;INCLUDE OUTSIDE BRITENESS
K7DBE:  STD  ,Y++
K7DC0:  LDD  #MS_STBC
K7DC3:  STD  M_BIC
K7DC6:  STB  ST_BIC
K7DC8:  NEGB
K7DC9:  ADDB #MS_STBZ&$FF           ;ZBIC-START= BIC GIVES COUNT OF STARS
K7DCB:  STB  ST_CNT
K7DCD:  LDU  #ST_PNT                ;BEGIN OF CONVERTED STAR POINTS
K7DD0:  LDX  #M_STAD                ;STAR ADDRESS

JVWSTA_10:
K7DD3:  STX  ST_RAM                 ;MATH RAM POINTER

JVWSTA_14:
K7DD5:  LDA  #MS_PSB2
K7DD7:  JSR  MGOWT
K7DDA:  LDD  M_XP                   ;X
K7DDD:  CMPD #$0100
K7DE1:  LBLE JVWSTA_90              ;B ?TOO CLOSE OR IN BACK? THEN NEW STAR
K7DE5:  CMPD #$0FFF
K7DE9:  LBHI JVWSTA_90              ;B ?TOO FAR IN FRONT OR IN BACK?
K7DED:  STD  M_DVD
K7DF0:  LDD  M_YPS                  ;?WIDTH IN VIEW ?
K7DF3:  SUBD M_XPS                  ;ELSE BEYOND VIEW
K7DF6:  LBHS JVWSTA_90              ;B ?BEYOND NORMAL VIEW ALSO? THEN GEN NEW STAR
K7DFA:  LDD  M_ZPS                  ;?HITE IN VIEW ?
K7DFD:  SUBD M_XPS                  ;ELSE OUT OF VIEW
K7E00:  LBHS JVWSTA_90              ;B IF OUT OF NORMAL VIEW ALSO, GEN NEW STAR
K7E04:  LDD  M_QUO                  ;(PLUS 4.5 CYCLES BEFORE READ)
K7E07:  STD  M_XP
K7E0A:  LDA  #MS_PERS
K7E0C:  JSR  MGOWT
K7E0F:  CLRB                        ;NO SECTOR YET
K7E10:  LDA  M_ZP
K7E13:  LSRA
K7E14:  ROLB                        ;EVERY 256 Y
K7E15:  LSRA
K7E16:  ROLB                        ;SIDE FOR +-512.
K7E17:  LDA  M_YP
K7E1A:  LSRA
K7E1B:  ROLB                        ;EVERY 256 X
K7E1C:  LSRA
K7E1D:  ROLB                        ;SIDE FOR +-512.
K7E1E:  LDA  #STS_IZQ
K7E20:  MUL
K7E21:  LDX  #ST_QU
K7E24:  ABX                         ;X-->QUE BLOCK
K7E25:  LDD  STS_QHD,X
K7E27:  BNE  JVWSTA_72              ;?FIRST IN THIS QU?
K7E29:  STU  STS_QHD,X              ;POINT TO FIRST STAR
K7E2B:  BRA  JVWSTA_73              ;B NO PREVIOUS STAR

JVWSTA_72:
K7E2D:  STU  [STS_QTL,X]            ;INITS FORWARD POINTER IN LAST (OR ONLY) ENTRY

JVWSTA_73:
K7E2F:  STU  STS_QTL,X              ;TAIL POINTS TO LAST (OR ONLY)ENTRY
K7E31:  LDD  #$0000
K7E34:  STD  STS_PP,U               ;LAST ENTRY HAS ZERO POINTER
K7E36:  LDD  M_ZP
K7E39:  SUBD STS_QCY,X              ;GET RELATIVE OFFSET
K7E3B:  ANDA #$1F
K7E3D:  STD  STS_PY,U               ;Y LONG VECTOR
K7E3F:  LDD  M_YP
K7E42:  SUBD STS_QCX,X              ;ANOTHER RELATIVE OFFSET
K7E44:  ANDA #$1F                   ;X LONG VECTOR
K7E46:  CMPU STS_QHD,X              ;?AFTER FIRST STAR PER SECTOR?
K7E49:  BEQ  JVWSTA_74
K7E4B:  ORA  #$00                   ;SHOW INTERCONNECT GRAPH

JVWSTA_74:
K7E4D:  STD  STS_PX,U
K7E4F:  LDD  M_ZP
K7E52:  STD  STS_QCY,X              ;NEW Y ABSOLUTE
K7E54:  LDD  M_YP
K7E57:  STD  STS_QCX,X              ;NEXT X ABSOLUTE
K7E59:  LEAU STS_IZP,U              ;NEXT STAR ENTRY
K7E5B:  BRA  JVWSTA_95

JVWSTA_90:
K7E5D:  LDX  ST_RAM
K7E5F:  JSR  STARNW

JVWSTA_95:
K7E62:  INC  ST_BIC
K7E64:  LDX  ST_RAM
K7E66:  LEAX 8,X
K7E68:  DEC  ST_CNT
K7E6A:  LBNE JVWSTA_10
;DISPLAY QUEUED STARS BY SECTOR LOCATION
K7E6E:  LDX  #ST_QU

JVWSTA_110:      ;LOOP THRU QUEUES
K7E71:  LDU  STS_QHD,X
K7E73:  BEQ  JVWSTA_160             ;?STARS IN THIS SECTOR?
K7E75:  LDD  #VGOFFY&$1FFF
K7E78:  STD  ,Y++
K7E7A:  LDD  #$0000                 ;OFFSET X
K7E7D:  STD  ,Y++

JVWSTA_120:      ;---LOOP THRU STARS
K7E7F:  LDD  STS_PY,U               ;Y PORTION
K7E81:  STD  ,Y++
K7E83:  LDD  STS_PX,U               ;X PORTION
K7E85:  STD  ,Y++
K7E87:  LDD  VGSTAR
K7E8A:  STD  ,Y++                   ;DRAW STAR SHAPE
K7E8C:  LDU  STS_PP,U               ;POINTER TO NEXT STAR
K7E8E:  BNE  JVWSTA_120             ;B LOOP IF MORE STARS
K7E90:  LDD  #VGCNTR
K7E93:  STD  ,Y++                   ;CENTER AFTER SECTOR OF STARS

JVWSTA_160:
K7E95:  LEAX STS_IZQ,X              ;NEXT SECTOR'S QUEUE
K7E97:  CMPX #ST_QUZ
K7E9A:  BLO  JVWSTA_110
K7E9C:  LDD  MS_TX+M_S1
K7E9F:  STD  MS_TX+M_U1             ;RESTORE POSITION
K7EA2:  LDD  MS_TY+M_S1
K7EA5:  STD  MS_TY+M_U1
K7EA8:  LDD  MS_TZ+M_S1
K7EAB:  STD  MS_TZ+M_U1
K7EAE:  RTS

;------------------------------------------------------------------------------
; JVWSTRG - [note] View ground stars: as JVWSTAR but in green, with no far limit and without moving the M_U1 position;
;   stars out of view are regenerated with STRNWG. Stars are queued by screen sector, then drawn
;   (also: VWSTRG_7EAF)
;------------------------------------------------------------------------------
JVWSTRG:
VWSTRG_7EAF:
K7EAF:  LDX  #ST_QU
K7EB2:  LDD  #$0000

JVWSTR_4:
K7EB5:  STD  ,X++                   ;CLEAR OUT STAR QUE
K7EB7:  CMPX #ST_QUZ
K7EBA:  BLO  JVWSTR_4
K7EBC:  STA  ST_GNB                 ;NO STAR TO GEN YET
K7EBE:  LDD  #(VGCGRN*$100)+VGCOPC
K7EC1:  STD  ,Y++
K7EC3:  LDD  #MS_STBC
K7EC6:  STD  M_BIC
K7EC9:  STB  ST_BIC
K7ECB:  NEGB
K7ECC:  ADDB #MS_STBZ&$FF           ;ZBIC-START= BIC GIVES COUNT OF STARS
K7ECE:  STB  ST_CNT
K7ED0:  LDU  #ST_PNT                ;BEGIN OF CONVERTED STAR POINTS
K7ED3:  LDX  #M_STAD                ;STAR ADDRESS

JVWSTR_10:
K7ED6:  STX  ST_RAM                 ;MATH RAM POINTER

JVWSTR_14:
K7ED8:  LDA  #MS_PSB2
K7EDA:  JSR  MGOWT
K7EDD:  LDD  M_XP                   ;X
K7EE0:  CMPD #$0100
K7EE4:  LBLE JVWSTR_90              ;B ?TOO CLOSE OR IN BACK? THEN NEW STAR
K7EE8:  STD  M_DVD
K7EEB:  LDD  M_YPS                  ;?WIDTH IN VIEW ?
K7EEE:  SUBD M_XPS                  ;ELSE BEYOND VIEW
K7EF1:  LBHS JVWSTR_90              ;B ?BEYOND NORMAL VIEW ALSO? THEN GEN NEW STAR
K7EF5:  LDD  M_ZPS                  ;CHECK HITE ALSO
K7EF8:  SUBD M_XPS
K7EFB:  LBHS JVWSTR_90
K7EFF:  LDD  M_QUO                  ;(PLUS 4.5 CYCLES BEFORE READ)
K7F02:  STD  M_XP
K7F05:  LDA  #MS_PERS
K7F07:  JSR  MGOWT
K7F0A:  CLRB                        ;NO SECTOR YET
K7F0B:  LDA  M_ZP
K7F0E:  LSRA
K7F0F:  ROLB                        ;EVERY 256 Y
K7F10:  LSRA
K7F11:  ROLB                        ;SIDE FOR +-512.
K7F12:  LDA  M_YP
K7F15:  LSRA
K7F16:  ROLB                        ;EVERY 256 X
K7F17:  LSRA
K7F18:  ROLB                        ;SIDE FOR +-512.
K7F19:  LDA  #STS_IZQ
K7F1B:  MUL
K7F1C:  LDX  #ST_QU
K7F1F:  ABX                         ;X-->QUE BLOCK
K7F20:  LDD  STS_QHD,X
K7F22:  BNE  JVWSTR_72              ;?FIRST IN THIS QU?
K7F24:  STU  STS_QHD,X              ;POINT TO FIRST STAR
K7F26:  BRA  JVWSTR_73              ;B NO PREVIOUS STAR

JVWSTR_72:
K7F28:  STU  [STS_QTL,X]            ;INITS FORWARD POINTER IN LAST (OR ONLY) ENTRY

JVWSTR_73:
K7F2A:  STU  STS_QTL,X              ;TAIL POINTS TO LAST (OR ONLY)ENTRY
K7F2C:  LDD  #$0000
K7F2F:  STD  STS_PP,U               ;LAST ENTRY HAS ZERO POINTER
K7F31:  LDD  M_ZP
K7F34:  SUBD STS_QCY,X              ;GET RELATIVE OFFSET
K7F36:  ANDA #$1F
K7F38:  STD  STS_PY,U               ;Y LONG VECTOR
K7F3A:  LDD  M_YP
K7F3D:  SUBD STS_QCX,X              ;ANOTHER RELATIVE OFFSET
K7F3F:  ANDA #$1F                   ;X LONG VECTOR
K7F41:  CMPU STS_QHD,X              ;?AFTER FIRST STAR PER SECTOR?
K7F44:  BEQ  JVWSTR_74
K7F46:  ORA  #$00                   ;SHOW INTERCONNECT GRAPH

JVWSTR_74:
K7F48:  STD  STS_PX,U
K7F4A:  LDD  M_ZP
K7F4D:  STD  STS_QCY,X              ;NEW Y ABSOLUTE
K7F4F:  LDD  M_YP
K7F52:  STD  STS_QCX,X              ;NEXT X ABSOLUTE
K7F54:  LEAU STS_IZP,U              ;NEXT STAR ENTRY
K7F56:  BRA  JVWSTR_95

JVWSTR_90:
K7F58:  LDX  ST_RAM
K7F5A:  JSR  STRNWG

JVWSTR_95:
K7F5D:  INC  ST_BIC
K7F5F:  LDX  ST_RAM
K7F61:  LEAX 8,X
K7F63:  DEC  ST_CNT
K7F65:  LBNE JVWSTR_10
;DISPLAY QUEUED STARS BY SECTOR LOCATION
K7F69:  LDX  #ST_QU

JVWSTR_110:      ;LOOP THRU QUEUES
K7F6C:  LDU  STS_QHD,X
K7F6E:  BEQ  JVWSTR_160             ;?STARS IN THIS SECTOR?
K7F70:  LDD  #VGOFFY                ;GROUND HORIZON DROPPED(INCLUDES VGOFFY)
K7F73:  ANDA #$1F
K7F75:  STD  ,Y++
K7F77:  LDD  #$0000                 ;OFFSET X
K7F7A:  STD  ,Y++

JVWSTR_120:      ;---LOOP THRU STARS
K7F7C:  LDD  STS_PY,U               ;Y PORTION
K7F7E:  STD  ,Y++
K7F80:  LDD  STS_PX,U               ;X PORTION
K7F82:  STD  ,Y++
K7F84:  LDD  VGSTAR
K7F87:  STD  ,Y++                   ;DRAW STAR SHAPE
K7F89:  LDU  STS_PP,U               ;POINTER TO NEXT STAR
K7F8B:  BNE  JVWSTR_120             ;B LOOP IF MORE STARS
K7F8D:  LDD  #VGCNTR
K7F90:  STD  ,Y++                   ;CENTER AFTER SECTOR OF STARS

JVWSTR_160:
K7F92:  LEAX STS_IZQ,X              ;NEXT SECTOR'S QUEUE
K7F94:  CMPX #ST_QUZ
K7F97:  BLO  JVWSTR_110
K7F99:  RTS

;------------------------------------------------------------------------------
; STARNW - [note] New star at math RAM X: random visual X,Y,Z (RND8), Y and Z signs opposite of current M_YPH, M_ZPH;
;   MS_S1UN (BIC low = ST_BIC) converts to universe coordinates, stored at 0,2,4(X)
;------------------------------------------------------------------------------
STARNW:
K7F9A:  JSR  RND8                   ;SET UP VISUAL X,Y,Z
K7F9D:  LDA  RND_S1
K7F9F:  ANDA #$1F
K7FA1:  LDB  RND_S2
K7FA3:  STD  ,X
K7FA5:  MUL
K7FA6:  TST  M_YPH                  ;B SELECT SIGN OPPOSITE OF CURRENT
K7FA9:  BMI  STARNW_20
K7FAB:  NEGA

STARNW_20:
K7FAC:  STD  2,X
K7FAE:  LDA  RND_S1
K7FB0:  ANDA #$1F
K7FB2:  LDB  RND_S3
K7FB4:  MUL
K7FB5:  TST  M_ZPH
K7FB8:  BMI  STARNW_30
K7FBA:  NEGA

STARNW_30:
K7FBB:  STD  4,X
K7FBD:  LDA  ST_BIC                 ;REDO CURRENT STAR
K7FBF:  STA  M_BICL
K7FC2:  LDA  #MS_S1UN               ;DO POST ADD
K7FC4:  JSR  MGOWT
K7FC7:  LDD  M_XP                   ;STORE UNIVERSE COORDINATES
K7FCA:  STD  ,X
K7FCC:  LDD  M_YP
K7FCF:  STD  2,X
K7FD1:  LDD  M_ZP
K7FD4:  ANDA #$FF
K7FD6:  ANDB #$FF
K7FD8:  STD  4,X
;RESTORE MATH BOX
;BIC ALREADY UPDATED BY PREVIOUS OP
K7FDA:  RTS

;------------------------------------------------------------------------------
; STRNWG - [note] New ground star at math RAM X: X = random, forced way out there, plus MS_TX+M_U1; Y = random, sign
;   opposite of current M_YPH, plus MS_TY+M_U1; Z = 0 (on the ground). Uses RND8
;------------------------------------------------------------------------------
STRNWG:
K7FDB:  JSR  RND8                   ;SET UP VISUAL X,Y,Z
K7FDE:  LDA  RND_S1
K7FE0:  ANDA #$7F
K7FE2:  ORA  #$70                   ;FORCE IT WAY OUT THERE
K7FE4:  LDB  RND_S2
K7FE6:  ADDD MS_TX+M_U1
K7FE9:  STD  ,X
K7FEB:  LDA  RND_S3
K7FED:  ANDA #$7F
K7FEF:  TST  M_YPH                  ;B SELECT SIGN OPPOSITE OF CURRENT
K7FF2:  BMI  STRNWG_20
K7FF4:  NEGA

STRNWG_20:
K7FF5:  ADDD MS_TY+M_U1
K7FF8:  STD  2,X
K7FFA:  LDD  #$0000                 ;ON THE GROUND
K7FFD:  STD  4,X
K7FFF:  RTS

