;Star Wars (Atari, 1983) - annotated disassembly of the vector ROM $3000-$3FFF
;(136021-105.1l): AVG display-list subroutines - characters, pictures, tests.
;AVG words are big-endian here, as the 6809 stores them:
;  $0yyy $zxxx  VCTR  draw to dx,dy (13-bit signed), intensity z (0-7)
;  $4...        short VCTR: dy in bits 12-8, z in bits 7-5, dx in bits 4-0 (x2)
;  $2000 HALT   $6ccc STAT/COLOR (colour in bits 10-8, brightness in bits 7-0)
;  $7sll SCAL   $8040 CNTR   $Annn JSRL   $C000 RTSL   $Ennn JMPL
;JSRL/JMPL operands are word addresses: (address - VGBASE)/2.
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

.org $3000

.include "starwars_defines.asm"


;==============================================================================
; MODULE WSVROM   WSVROM.MAC
;==============================================================================

;.SBTTL REAL VG ROM
L3000:  .word VGCKS0                ;CHECKSUM FOR THE VG ROM *****************

;.SBTTL CHARACTER TABLE

VGMSGA:
L3002:  .word (((CHAR_-VGBASE)/2)&$1FFF)+$A000 ;JSRL CHAR.  ADDRESS OF LETTER ROUTINES
L3004:  .word (((CHAR_0-VGBASE)/2)&$1FFF)+$A000 ;JSRL CHAR.0
L3006:  .word (((CHAR_1-VGBASE)/2)&$1FFF)+$A000 ;JSRL CHAR.1
L3008:  .word (((CHAR_2-VGBASE)/2)&$1FFF)+$A000 ;JSRL CHAR.2
L300A:  .word (((CHAR_3-VGBASE)/2)&$1FFF)+$A000 ;JSRL CHAR.3
L300C:  .word (((CHAR_4-VGBASE)/2)&$1FFF)+$A000 ;JSRL CHAR.4
L300E:  .word (((CHAR_5-VGBASE)/2)&$1FFF)+$A000 ;JSRL CHAR.5
L3010:  .word (((CHAR_6-VGBASE)/2)&$1FFF)+$A000 ;JSRL CHAR.6
L3012:  .word (((CHAR_7-VGBASE)/2)&$1FFF)+$A000 ;JSRL CHAR.7
L3014:  .word (((CHAR_8-VGBASE)/2)&$1FFF)+$A000 ;JSRL CHAR.8
L3016:  .word (((CHAR_9-VGBASE)/2)&$1FFF)+$A000 ;JSRL CHAR.9
L3018:  .word (((CHAR_A-VGBASE)/2)&$1FFF)+$A000 ;JSRL CHAR.A
L301A:  .word (((CHAR_B-VGBASE)/2)&$1FFF)+$A000 ;JSRL CHAR.B
L301C:  .word (((CHAR_C-VGBASE)/2)&$1FFF)+$A000 ;JSRL CHAR.C
L301E:  .word (((CHAR_D-VGBASE)/2)&$1FFF)+$A000 ;JSRL CHAR.D
L3020:  .word (((CHAR_E-VGBASE)/2)&$1FFF)+$A000 ;JSRL CHAR.E
L3022:  .word (((CHAR_F-VGBASE)/2)&$1FFF)+$A000 ;JSRL CHAR.F
L3024:  .word (((CHAR_G-VGBASE)/2)&$1FFF)+$A000 ;JSRL CHAR.G
L3026:  .word (((CHAR_H-VGBASE)/2)&$1FFF)+$A000 ;JSRL CHAR.H
L3028:  .word (((CHAR_I-VGBASE)/2)&$1FFF)+$A000 ;JSRL CHAR.I
L302A:  .word (((CHAR_J-VGBASE)/2)&$1FFF)+$A000 ;JSRL CHAR.J
L302C:  .word (((CHAR_K-VGBASE)/2)&$1FFF)+$A000 ;JSRL CHAR.K
L302E:  .word (((CHAR_L-VGBASE)/2)&$1FFF)+$A000 ;JSRL CHAR.L
L3030:  .word (((CHAR_M-VGBASE)/2)&$1FFF)+$A000 ;JSRL CHAR.M
L3032:  .word (((CHAR_N-VGBASE)/2)&$1FFF)+$A000 ;JSRL CHAR.N
L3034:  .word (((CHAR_O-VGBASE)/2)&$1FFF)+$A000 ;JSRL CHAR.O
L3036:  .word (((CHAR_P-VGBASE)/2)&$1FFF)+$A000 ;JSRL CHAR.P
L3038:  .word (((CHAR_Q-VGBASE)/2)&$1FFF)+$A000 ;JSRL CHAR.Q
L303A:  .word (((CHAR_R-VGBASE)/2)&$1FFF)+$A000 ;JSRL CHAR.R
L303C:  .word (((CHAR_S-VGBASE)/2)&$1FFF)+$A000 ;JSRL CHAR.S
L303E:  .word (((CHAR_T-VGBASE)/2)&$1FFF)+$A000 ;JSRL CHAR.T
L3040:  .word (((CHAR_U-VGBASE)/2)&$1FFF)+$A000 ;JSRL CHAR.U
L3042:  .word (((CHAR_V-VGBASE)/2)&$1FFF)+$A000 ;JSRL CHAR.V
L3044:  .word (((CHAR_W-VGBASE)/2)&$1FFF)+$A000 ;JSRL CHAR.W
L3046:  .word (((CHAR_X-VGBASE)/2)&$1FFF)+$A000 ;JSRL CHAR.X
L3048:  .word (((CHAR_Y-VGBASE)/2)&$1FFF)+$A000 ;JSRL CHAR.Y
L304A:  .word (((CHAR_Z-VGBASE)/2)&$1FFF)+$A000 ;JSRL CHAR.Z
;EXTENDED CHARS
L304C:  .word (((CH_APO-VGBASE)/2)&$1FFF)+$A000 ;JSRL CH.APO  APOSTROPHE
L304E:  .word (((CH_CMA-VGBASE)/2)&$1FFF)+$A000 ;JSRL CH.CMA  COMMA
L3050:  .word (((CH_PER-VGBASE)/2)&$1FFF)+$A000 ;JSRL CH.PER  PERIOD
L3052:  .word (((CH_CLN-VGBASE)/2)&$1FFF)+$A000 ;JSRL CH.CLN  COLON
L3054:  .word (((UNDERL-VGBASE)/2)&$1FFF)+$A000 ;JSRL UNDERL
L3056:  .word (((CH_HLF-VGBASE)/2)&$1FFF)+$A000 ;JSRL CH.HLF  ONE-HALF
L3058:  .word (((CH_COP-VGBASE)/2)&$1FFF)+$A000 ;JSRL CH.COP
L305A:  .word (((CH_HYP-VGBASE)/2)&$1FFF)+$A000 ;JSRL CH.HYP  HYPHEN
;;; JSRL CH.LPN ;LEFT PAREN
;;; JSRL CH.RPN ;RIGHT PAREN
L305C:  .word $C000                 ;RTSL

;.SBTTL CHARACTER DEFINITIONS

CHAR_A:
L305E:  .word $48E0                 ;VCTR 0,16,.BRITE
L3060:  .word $44E4                 ;VCTR 8,8,.BRITE
L3062:  .word $5CE4                 ;VCTR 8,-8,.BRITE
L3064:  .word $58E0                 ;VCTR 0,-16,.BRITE
L3066:  .word $4518                 ;VCTR -16,10,0
L3068:  .word $40E8                 ;VCTR 16,0,.BRITE
L306A:  .word $5B04                 ;VCTR 8,-10,0
L306C:  .word $C000                 ;RTSL

CHAR_B:
L306E:  .word $4CE0                 ;VCTR 0,24,.BRITE
L3070:  .word $40E5                 ;VCTR 10,0,.BRITE
L3072:  .word $5DE2                 ;VCTR 4,-6,.BRITE
L3074:  .word $5DFE                 ;VCTR -4,-6,.BRITE
L3076:  .word $40FB                 ;VCTR -10,0,.BRITE
L3078:  .word $4006                 ;VCTR 12,0,0
L307A:  .word $5DE2                 ;VCTR 4,-6,.BRITE
L307C:  .word $5DFE                 ;VCTR -4,-6,.BRITE
L307E:  .word $40FA                 ;VCTR -12,0,.BRITE
L3080:  .word (((CHAR_-VGBASE)/2)&$1FFF)+$E000 ;JMPL CHAR.

CHAR_C:
L3082:  .word $4CE0                 ;VCTR 0,24,.BRITE
L3084:  .word $40E8                 ;VCTR 16,0,.BRITE
L3086:  .word $5418                 ;VCTR -16,-24,0
L3088:  .word (((UNDERL-VGBASE)/2)&$1FFF)+$E000 ;JMPL UNDERL

CHAR_D:
L308A:  .word $40E5                 ;VCTR 10,0,.BRITE
L308C:  .word $44E3                 ;VCTR 6,8,.BRITE
L308E:  .word $44E0                 ;VCTR 0,8,.BRITE
L3090:  .word $44FD                 ;VCTR -6,8,.BRITE
L3092:  .word $40FB                 ;VCTR -10,0,.BRITE
L3094:  .word $54E0                 ;VCTR 0,-24,.BRITE
L3096:  .word (((CHAR_-VGBASE)/2)&$1FFF)+$E000 ;JMPL CHAR.

CHAR_E:
L3098:  .word $40E8                 ;VCTR 16,0,.BRITE

CHARE1:
L309A:  .word $4018                 ;VCTR -16,0,0

CHAR_F:
L309C:  .word $4600                 ;VCTR 0,12,0
L309E:  .word $40E6                 ;VCTR 12,0,.BRITE  MIDLINE
L30A0:  .word $5A1A                 ;VCTR -12,-12,0

CHARF1:
L30A2:  .word $4CE0                 ;VCTR 0,24,.BRITE
L30A4:  .word $40E8                 ;VCTR 16,0,.BRITE
L30A6:  .word (((CHARU2-VGBASE)/2)&$1FFF)+$E000 ;JMPL CHARU2
L30A8:  .word $C000                 ;RTSL

CHAR_G:
L30AA:  .word $4504                 ;VCTR 8,10,0
L30AC:  .word $40E4                 ;VCTR 8,0,.BRITE
L30AE:  .word $5BE0                 ;VCTR 0,-10,.BRITE
L30B0:  .word $4018                 ;VCTR -16,0,0
L30B2:  .word (((CHAR_C-VGBASE)/2)&$1FFF)+$E000 ;JMPL CHAR.C

CHAR_H:
L30B4:  .word $4CE0                 ;VCTR 0,24,.BRITE
L30B6:  .word $5A00                 ;VCTR 0,-12,0
L30B8:  .word $40E8                 ;VCTR 16,0,.BRITE
L30BA:  .word $5A00                 ;VCTR 0,-12,0
L30BC:  .word (((CHARU1-VGBASE)/2)&$1FFF)+$E000 ;JMPL CHARU1

CHAR_I:
L30BE:  .word $40E8                 ;VCTR 16,0,.BRITE
L30C0:  .word $4C18                 ;VCTR -16,24,0

CHARI1:
L30C2:  .word $40E8                 ;VCTR 16,0,.BRITE
L30C4:  .word $401C                 ;VCTR -8,0,0
L30C6:  .word (((CHAR11-VGBASE)/2)&$1FFF)+$E000 ;JMPL CHAR11

CHAR_J:
L30C8:  .word $4400                 ;VCTR 0,8,0
L30CA:  .word $5CE4                 ;VCTR 8,-8,.BRITE
L30CC:  .word $40E4                 ;VCTR 8,0,.BRITE
L30CE:  .word (((CHARU1-VGBASE)/2)&$1FFF)+$E000 ;JMPL CHARU1

CHAR_K:
L30D0:  .word $4CE0                 ;VCTR 0,24,.BRITE
L30D2:  .word $5A00                 ;VCTR 0,-12,0
L30D4:  .word $46E8                 ;VCTR 16,12,.BRITE
L30D6:  .word $5A18                 ;VCTR -16,-12,0
L30D8:  .word $5AE8                 ;VCTR 16,-12,.BRITE
L30DA:  .word (((CHAR73-VGBASE)/2)&$1FFF)+$E000 ;JMPL CHAR73

CHAR_L:
L30DC:  .word $4C00                 ;VCTR 0,24,0
L30DE:  .word $54E0                 ;VCTR 0,-24,.BRITE

UNDERL:
L30E0:  .word $40E8                 ;VCTR 16,0,.BRITE
L30E2:  .word (((CHAR73-VGBASE)/2)&$1FFF)+$E000 ;JMPL CHAR73

CHAR_M:
L30E4:  .word $4CE0                 ;VCTR 0,24,.BRITE
L30E6:  .word $5CE4                 ;VCTR 8,-8,.BRITE
L30E8:  .word $44E4                 ;VCTR 8,8,.BRITE
L30EA:  .word (((CHAR72-VGBASE)/2)&$1FFF)+$E000 ;JMPL CHAR72

CHAR_N:
L30EC:  .word $4CE0                 ;VCTR 0,24,.BRITE
L30EE:  .word $54E8                 ;VCTR 16,-24,.BRITE
L30F0:  .word (((CHARU1-VGBASE)/2)&$1FFF)+$E000 ;JMPL CHARU1

CHAR_O:
L30F2:  .word $40E8                 ;VCTR 16,0,.BRITE
L30F4:  .word $4CE0                 ;VCTR 0,24,.BRITE

CHARO2:
L30F6:  .word $5418                 ;VCTR -16,-24,0
L30F8:  .word (((CHARF1-VGBASE)/2)&$1FFF)+$E000 ;JMPL CHARF1

CHAR_:
L30FA:  .word $400C                 ;VCTR 24,0,0  BLANK
L30FC:  .word $C000                 ;RTSL

CHAR_P:
L30FE:  .word $4600                 ;VCTR 0,12,0
L3100:  .word $40E8                 ;VCTR 16,0,.BRITE
L3102:  .word $46E0                 ;VCTR 0,12,.BRITE
L3104:  .word (((CHARO2-VGBASE)/2)&$1FFF)+$E000 ;JMPL CHARO2

CHAR_Q:
L3106:  .word $4404                 ;VCTR 8,8,0
L3108:  .word $5CE4                 ;VCTR 8,-8,.BRITE
L310A:  .word $4018                 ;VCTR -16,0,0
L310C:  .word $40E4                 ;VCTR 8,0,.BRITE
L310E:  .word $44E4                 ;VCTR 8,8,.BRITE
L3110:  .word $48E0                 ;VCTR 0,16,.BRITE
L3112:  .word $5418                 ;VCTR -16,-24,0
L3114:  .word (((CHARF1-VGBASE)/2)&$1FFF)+$E000 ;JMPL CHARF1

CHAR_R:
L3116:  .word $4600                 ;VCTR 0,12,0
L3118:  .word $5AE8                 ;VCTR 16,-12,.BRITE
L311A:  .word $4018                 ;VCTR -16,0,0
L311C:  .word (((CHAR_P-VGBASE)/2)&$1FFF)+$E000 ;JMPL CHAR.P

CHAR_S:
L311E:  .word $4008                 ;VCTR 16,0,0
L3120:  .word $46E0                 ;VCTR 0,12,.BRITE
L3122:  .word $4018                 ;VCTR -16,0,0
L3124:  .word $46E0                 ;VCTR 0,12,.BRITE
L3126:  .word (((CHAR33-VGBASE)/2)&$1FFF)+$E000 ;JMPL CHAR33

CHAR_T:
L3128:  .word $4C00                 ;VCTR 0,24,0
L312A:  .word (((CHARI1-VGBASE)/2)&$1FFF)+$E000 ;JMPL CHARI1

CHAR_U:
L312C:  .word $4C00                 ;VCTR 0,24,0
L312E:  .word $54E0                 ;VCTR 0,-24,.BRITE
L3130:  .word $40E8                 ;VCTR 16,0,.BRITE

CHARU1:
L3132:  .word $4CE0                 ;VCTR 0,24,.BRITE

CHARU2:
L3134:  .word $5404                 ;VCTR 8,-24,0
L3136:  .word $C000                 ;RTSL

CHAR_V:
L3138:  .word $4C00                 ;VCTR 0,24,0
L313A:  .word $54E4                 ;VCTR 8,-24,.BRITE
L313C:  .word $4CE4                 ;VCTR 8,24,.BRITE
L313E:  .word (((CHARU2-VGBASE)/2)&$1FFF)+$E000 ;JMPL CHARU2

CHAR_W:
L3140:  .word $4C00                 ;VCTR 0,24,0
L3142:  .word $54E0                 ;VCTR 0,-24,.BRITE
L3144:  .word $44E4                 ;VCTR 8,8,.BRITE
L3146:  .word $5CE4                 ;VCTR 8,-8,.BRITE
L3148:  .word (((CHARU1-VGBASE)/2)&$1FFF)+$E000 ;JMPL CHARU1

CHAR_X:
L314A:  .word $4CE8                 ;VCTR 16,24,.BRITE
L314C:  .word $4018                 ;VCTR -16,0,0
L314E:  .word $54E8                 ;VCTR 16,-24,.BRITE
L3150:  .word (((CHAR73-VGBASE)/2)&$1FFF)+$E000 ;JMPL CHAR73

CHAR_Y:
L3152:  .word $4004                 ;VCTR 8,0,0
L3154:  .word $48E0                 ;VCTR 0,16,.BRITE
L3156:  .word $44FC                 ;VCTR -8,8,.BRITE
L3158:  .word $5C04                 ;VCTR 8,-8,0
L315A:  .word $44E4                 ;VCTR 8,8,.BRITE
L315C:  .word (((CHARU2-VGBASE)/2)&$1FFF)+$E000 ;JMPL CHARU2

CHAR_Z:
L315E:  .word $4C00                 ;VCTR 0,24,0
L3160:  .word $40E8                 ;VCTR 16,0,.BRITE
L3162:  .word $54F8                 ;VCTR -16,-24,.BRITE
L3164:  .word (((UNDERL-VGBASE)/2)&$1FFF)+$E000 ;JMPL UNDERL

CHAR_1:
L3166:  .word $40E8                 ;VCTR 16,0,.BRITE
L3168:  .word $4A1A                 ;VCTR -12,20,0
L316A:  .word $42E2                 ;VCTR 4,4,.BRITE

CHAR11:
L316C:  .word $54E0                 ;VCTR 0,-24,.BRITE

CHAR12:
L316E:  .word $4008                 ;VCTR 16,0,0
L3170:  .word $C000                 ;RTSL

CHAR_2:
L3172:  .word $46E0                 ;VCTR 0,12,.BRITE
L3174:  .word $4008                 ;VCTR 16,0,0
L3176:  .word $46E0                 ;VCTR 0,12,.BRITE
L3178:  .word (((CHAR32-VGBASE)/2)&$1FFF)+$E000 ;JMPL CHAR32

CHAR_3:
L317A:  .word $4008                 ;VCTR 16,0,0

CHAR31:
L317C:  .word $4CE0                 ;VCTR 0,24,.BRITE

CHAR32:
L317E:  .word $4018                 ;VCTR -16,0,0

CHAR33:
L3180:  .word $40E8                 ;VCTR 16,0,.BRITE
L3182:  .word $5A18                 ;VCTR -16,-12,0
L3184:  .word $40E8                 ;VCTR 16,0,.BRITE
L3186:  .word $5A18                 ;VCTR -16,-12,0
L3188:  .word (((UNDERL-VGBASE)/2)&$1FFF)+$E000 ;JMPL UNDERL

CHAR_4:
L318A:  .word $4C00                 ;VCTR 0,24,0
L318C:  .word $5AE0                 ;VCTR 0,-12,.BRITE
L318E:  .word $40E8                 ;VCTR 16,0,.BRITE
L3190:  .word $4600                 ;VCTR 0,12,0
L3192:  .word (((CHAR72-VGBASE)/2)&$1FFF)+$E000 ;JMPL CHAR72

CHAR_6:
L3194:  .word $4600                 ;VCTR 0,12,0
L3196:  .word $40E8                 ;VCTR 16,0,.BRITE
L3198:  .word $5AE0                 ;VCTR 0,-12,.BRITE
L319A:  .word $4018                 ;VCTR -16,0,0
L319C:  .word (((CHAR_L-VGBASE)/2)&$1FFF)+$E000 ;JMPL CHAR.L

CHAR_7:
L319E:  .word $4C00                 ;VCTR 0,24,0

CHAR71:
L31A0:  .word $40E8                 ;VCTR 16,0,.BRITE

CHAR72:
L31A2:  .word $54E0                 ;VCTR 0,-24,.BRITE

CHAR73:
L31A4:  .word $4004                 ;VCTR 8,0,0
L31A6:  .word $C000                 ;RTSL

CHAR_8:
L31A8:  .word $4CE0                 ;VCTR 0,24,.BRITE
L31AA:  .word $5408                 ;VCTR 16,-24,0
L31AC:  .word (((CHAR31-VGBASE)/2)&$1FFF)+$E000 ;JMPL CHAR31

CHAR_9:
L31AE:  .word $4C00                 ;VCTR 0,24,0
L31B0:  .word $5AE0                 ;VCTR 0,-12,.BRITE
L31B2:  .word $40E8                 ;VCTR 16,0,.BRITE
L31B4:  .word $4618                 ;VCTR -16,12,0
L31B6:  .word (((CHAR71-VGBASE)/2)&$1FFF)+$E000 ;JMPL CHAR71

CH_PER:
L31B8:  .word $0000, (ON*$2000)+(0&$1FFF) ;VCTR 0,0,ON  PERIOD
L31BC:  .word (((CHAR_-VGBASE)/2)&$1FFF)+$E000 ;JMPL CHAR.

CH_CLN:
L31BE:  .word $4000+(OFF*$20)+((8/2)&$1F)+((10*$80)&$1F00) ;VCTR 8,10,OFF
L31C0:  .word $0000, (ON*$2000)+(0&$1FFF) ;VCTR 0,0,ON
L31C4:  .word $4000+(OFF*$20)+((0/2)&$1F)+((-10*$80)&$1F00) ;VCTR 0,-10,OFF
L31C6:  .word $0000, (ON*$2000)+(0&$1FFF) ;VCTR 0,0,ON
L31CA:  .word (((CHAR12-VGBASE)/2)&$1FFF)+$E000 ;JMPL CHAR12

CH_APO:
L31CC:  .word $4000+(OFF*$20)+((10/2)&$1F)+((24*$80)&$1F00) ;VCTR 10,24,OFF  APOSTROPHE
L31CE:  .word (((CH_TIC-VGBASE)/2)&$1FFF)+$A000 ;JSRL CH.TIC
L31D0:  .word $4000+(OFF*$20)+((14/2)&$1F)+((-24*$80)&$1F00) ;VCTR 14,-24,OFF
L31D2:  .word $C000                 ;RTSL

CH_CMA:
L31D4:  .word $4000+(OFF*$20)+((4/2)&$1F)+((0*$80)&$1F00) ;VCTR 4,0,OFF
L31D6:  .word (((CH_TIC-VGBASE)/2)&$1FFF)+$A000 ;JSRL CH.TIC  COMMA
L31D8:  .word $4000+(OFF*$20)+((20/2)&$1F)+((0*$80)&$1F00) ;VCTR 20,0,OFF
L31DA:  .word $C000                 ;RTSL

CH_TIC:
L31DC:  .word $4000+(ON*$20)+((-4/2)&$1F)+((-10*$80)&$1F00) ;VCTR -4,-10,ON
L31DE:  .word $4000+(ON*$20)+((6/2)&$1F)+((10*$80)&$1F00) ;VCTR 6,10,ON
L31E0:  .word $0000, (ON*$2000)+(-2&$1FFF) ;VCTR -2,0,ON
L31E4:  .word $C000                 ;RTSL

CH_HLF:
L31E6:  .word $4000+(OFF*$20)+((4/2)&$1F)+((16*$80)&$1F00) ;VCTR 4,16,OFF  ONE
L31E8:  .word $4000+(ON*$20)+((0/2)&$1F)+((8*$80)&$1F00) ;VCTR 0,8,ON
L31EA:  .word $4000+(OFF*$20)+((-4/2)&$1F)+((-24*$80)&$1F00) ;VCTR -4,-24,OFF
L31EC:  .word $4000+(ON*$20)+((12/2)&$1F)+((24*$80)&$1F00) ;VCTR 12,24,ON  SLASH
L31EE:  .word $4000+(OFF*$20)+((-4/2)&$1F)+((-12*$80)&$1F00) ;VCTR -4,-12,OFF
L31F0:  .word $4000+(ON*$20)+((8/2)&$1F)+((0*$80)&$1F00) ;VCTR 8,0,ON  TWO ON BOTTOM
L31F2:  .word $4000+(ON*$20)+((0/2)&$1F)+((-6*$80)&$1F00) ;VCTR 0,-6,ON
L31F4:  .word $4000+(ON*$20)+((-10/2)&$1F)+((0*$80)&$1F00) ;VCTR -10,0,ON
L31F6:  .word $4000+(ON*$20)+((0/2)&$1F)+((-6*$80)&$1F00) ;VCTR 0,-6,ON
L31F8:  .word $4000+(ON*$20)+((10/2)&$1F)+((0*$80)&$1F00) ;VCTR 10,0,ON
L31FA:  .word $4000+(OFF*$20)+((8/2)&$1F)+((0*$80)&$1F00) ;VCTR 8,0,OFF
L31FC:  .word $C000                 ;RTSL

CH_COP:          ;COPYRIGHT CIRCLE C
L31FE:  .word $4000+(OFF*$20)+((8/2)&$1F)+((-6*$80)&$1F00) ;VCTR 8,-6,OFF
L3200:  .word $4000+(ON*$20)+((-8/2)&$1F)+((10*$80)&$1F00) ;VCTR -8,10,ON
L3202:  .word $4000+(ON*$20)+((0/2)&$1F)+((16*$80)&$1F00) ;VCTR 0,16,ON
L3204:  .word $4000+(ON*$20)+((8/2)&$1F)+((10*$80)&$1F00) ;VCTR 8,10,ON
L3206:  .word $4000+(ON*$20)+((16/2)&$1F)+((0*$80)&$1F00) ;VCTR 16,0,ON
;START OF C
L3208:  .word $4000+(OFF*$20)+((-2/2)&$1F)+((-10*$80)&$1F00) ;VCTR -2,-10,OFF
L320A:  .word $4000+(ON*$20)+((-10/2)&$1F)+((0*$80)&$1F00) ;VCTR -10,0,ON
L320C:  .word $4000+(ON*$20)+((0/2)&$1F)+((-18*$80)&$1F00) ;VCTR 0,-18,ON
L320E:  .word $4000+(ON*$20)+((10/2)&$1F)+((0*$80)&$1F00) ;VCTR 10,0,ON
;END OF C
L3210:  .word $4000+(OFF*$20)+((-14/2)&$1F)+((-8*$80)&$1F00) ;VCTR -14,-8,OFF
L3212:  .word $4000+(ON*$20)+((16/2)&$1F)+((0*$80)&$1F00) ;VCTR 16,0,ON
L3214:  .word $4000+(ON*$20)+((8/2)&$1F)+((10*$80)&$1F00) ;VCTR 8,10,ON
L3216:  .word $4000+(ON*$20)+((0/2)&$1F)+((16*$80)&$1F00) ;VCTR 0,16,ON
L3218:  .word $4000+(ON*$20)+((-8/2)&$1F)+((10*$80)&$1F00) ;VCTR -8,10,ON
L321A:  .word $4000+(OFF*$20)+((0/2)&$1F)+((-30*$80)&$1F00) ;VCTR 0,-30,OFF
L321C:  .word $C000                 ;RTSL

CH_HYP:
L321E:  .word $4000+(OFF*$20)+((2/2)&$1F)+((12*$80)&$1F00) ;VCTR 2,12,OFF
L3220:  .word $4000+(ON*$20)+((12/2)&$1F)+((0*$80)&$1F00) ;VCTR 12,0,ON
L3222:  .word $4000+(OFF*$20)+((10/2)&$1F)+((-12*$80)&$1F00) ;VCTR 10,-12,OFF
L3224:  .word $C000                 ;RTSL

;.SBTTL REAL VG ROM
L3226:  .word $4000+(OFF*$20)+((-4/2)&$1F)+((-6*$80)&$1F00) ;VOFF -4,-6
L3228:  .word $45E1                 ;VON 2,10
L322A:  .word $4000+(OFF*$20)+((6/2)&$1F)+((-4*$80)&$1F00) ;VOFF 6,-4
L322C:  .word $C000                 ;RTSL

;.SBTTL LAZAR FIRE COLORS

LZF0:
;LAZAR FIRE
L322E:  .word $63FF                 ;COLOR VGCTRQ,0FF
L3230:  .word $C000                 ;RTSL

LZF1:
L3232:  .word $61FF                 ;COLOR VGCBLU,0FF
L3234:  .word $C000                 ;RTSL

LZF2:
L3236:  .word $61CC                 ;COLOR VGCBLU,0CC
L3238:  .word $C000                 ;RTSL

LZF3:
L323A:  .word $6180                 ;COLOR VGCBLU,080
L323C:  .word $C000                 ;RTSL

LZF4:
L323E:  .word $6140                 ;COLOR VGCBLU,40
L3240:  .word $C000                 ;RTSL

LZF5:
L3242:  .word $6100                 ;COLOR VGCBLU,00
L3244:  .word $C000                 ;RTSL

LZF6:
L3246:  .word $6100                 ;COLOR VGCBLU,00
L3248:  .word $C000                 ;RTSL

LZF7:
L324A:  .word $6100                 ;COLOR VGCBLU,00
L324C:  .word $C000                 ;RTSL

LZF8:
L324E:  .word $63FF                 ;COLOR VGCTRQ,0FF
L3250:  .word $C000                 ;RTSL

LZF9:
L3252:  .word $61FF                 ;COLOR VGCBLU,0FF
L3254:  .word $C000                 ;RTSL

LZFA:
L3256:  .word $61CC                 ;COLOR VGCBLU,0CC
L3258:  .word $C000                 ;RTSL

LZFB:
L325A:  .word $6180                 ;COLOR VGCBLU,080
L325C:  .word $C000                 ;RTSL

LZFC:
L325E:  .word $6140                 ;COLOR VGCBLU,40
L3260:  .word $C000                 ;RTSL

LZFD:
L3262:  .word $6100                 ;COLOR VGCBLU,00
L3264:  .word $C000                 ;RTSL

LZFE:
L3266:  .word $6100                 ;COLOR VGCBLU,00
L3268:  .word $C000                 ;RTSL

LZFF:
L326A:  .word $6100                 ;COLOR VGCBLU,00
L326C:  .word $C000                 ;RTSL

LZS0:
;LAZAR SPLASH
L326E:  .word $67FF                 ;COLOR VGCWHT,0FF
L3270:  .word (((VGLZS0-VGBASE)/2)&$1FFF)+$E000 ;JMPL VGLZS0

LZS1:
L3272:  .word $67FF                 ;COLOR VGCWHT,0FF
L3274:  .word (((VGLZS1-VGBASE)/2)&$1FFF)+$E000 ;JMPL VGLZS1

LZS2:
L3276:  .word $66FF                 ;COLOR VGCYLW,0FF
L3278:  .word (((VGLZS2-VGBASE)/2)&$1FFF)+$E000 ;JMPL VGLZS2

LZS3:
L327A:  .word $66FF                 ;COLOR VGCYLW,0FF
L327C:  .word (((VGLZS3-VGBASE)/2)&$1FFF)+$E000 ;JMPL VGLZS3

;.SBTTL GUN SHOT DISIPATION BASE STAMPS
L327E:  .word $00B4, $00E1          ;AOFF 15,8
L3282:  .word (((VRGNT-VGBASE)/2)&$1FFF)+$A000 ;FUSEX
L3284:  .word $1EC5, $000F          ;AOFF 16,-6
L3288:  .word (((VRGNT-VGBASE)/2)&$1FFF)+$A000 ;FUSEX
L328A:  .word $1F1F, $1EB6          ;AOFF -6,-16
L328E:  .word (((VRGNT-VGBASE)/2)&$1FFF)+$A000 ;FUSEX
L3290:  .word $0195, $1F6A          ;AOFF -16,2
L3294:  .word (((VRGNT-VGBASE)/2)&$1FFF)+$A000 ;FUSEX
L3296:  .word $013B, $0096          ;AOFF -6,16
L329A:  .word (((VRGNT-VGBASE)/2)&$1FFF)+$A000 ;FUSEX
L329C:  .word $C000                 ;RTSL
L329E:  .word $0087, $00F0          ;AOFF 16,6
L32A2:  .word (((VRGNT-VGBASE)/2)&$1FFF)+$A000 ;FUSEX
L32A4:  .word $1E98, $1FE2          ;AOFF 14,-10
L32A8:  .word (((VRGNT-VGBASE)/2)&$1FFF)+$A000 ;FUSEX
L32AA:  .word $1F90, $1E98          ;AOFF -10,-15
L32AE:  .word (((VRGNT-VGBASE)/2)&$1FFF)+$A000 ;FUSEX
L32B0:  .word $01D8, $1FA6          ;AOFF -16,6
L32B4:  .word (((VRGNT-VGBASE)/2)&$1FFF)+$A000 ;FUSEX
L32B6:  .word $00F7, $00F0          ;AOFF 0,17
L32BA:  .word (((VRGNT-VGBASE)/2)&$1FFF)+$A000 ;FUSEX
L32BC:  .word $C000                 ;RTSL
L32BE:  .word $0151, $0078          ;AOFF 8,15
L32C2:  .word (((VRGNT-VGBASE)/2)&$1FFF)+$A000 ;FUSEX
L32C4:  .word $1EDC, $0087          ;AOFF 17,2
L32C8:  .word (((VRGNT-VGBASE)/2)&$1FFF)+$A000 ;FUSEX
L32CA:  .word $1E98, $1F97          ;AOFF 10,-14
L32CE:  .word (((VRGNT-VGBASE)/2)&$1FFF)+$A000 ;FUSEX
L32D0:  .word $009E, $1E7A          ;AOFF -16,-7
L32D4:  .word (((VRGNT-VGBASE)/2)&$1FFF)+$A000 ;FUSEX
L32D6:  .word $01AB, $003C          ;AOFF -12,12
L32DA:  .word (((VRGNT-VGBASE)/2)&$1FFF)+$A000 ;FUSEX
L32DC:  .word $C000                 ;RTSL
L32DE:  .word $1E82, $002D          ;AOFF 3,-17
L32E2:  .word (((VRGNT-VGBASE)/2)&$1FFF)+$A000 ;FUSEX
L32E4:  .word $0151, $00D2          ;AOFF 17,-2
L32E8:  .word (((VRGNT-VGBASE)/2)&$1FFF)+$A000 ;FUSEX
L32EA:  .word $0151, $1FA6          ;AOFF 11,13
L32EE:  .word (((VRGNT-VGBASE)/2)&$1FFF)+$A000 ;FUSEX
L32F0:  .word $0017, $1ED4          ;AOFF -9,14
L32F4:  .word (((VRGNT-VGBASE)/2)&$1FFF)+$A000 ;FUSEX
L32F6:  .word $1EC5, $1F88          ;AOFF -17,0
L32FA:  .word (((VRGNT-VGBASE)/2)&$1FFF)+$A000 ;FUSEX
L32FC:  .word $C000                 ;RTSL

;.SBTTL PLAYER'S GUN SITE

VGSITE:
L32FE:  .word (((VGSITE+2-VGBASE)/2)&$1FFF)+$A000 ;JSRL VGSITE+2
;TOP RIGHT QUAD
L3300:  .word $4505                 ;AOFF 1,1
L3302:  .word $4AE5                 ;AON 2,3
L3304:  .word $5BE0                 ;AON 2,2
L3306:  .word $40E5                 ;AON 3,2
L3308:  .word $5BF6                 ;AON 1,1
L330A:  .word $5B1B                 ;AOFF 0,0
;BOTTOM RIGHT QUAD
L330C:  .word $5B05                 ;AOFF 1,-1
L330E:  .word $56E5                 ;AON 2,-3
L3310:  .word $45E0                 ;AON 2,-2
L3312:  .word $40E5                 ;AON 3,-2
L3314:  .word $45F6                 ;AON 1,-1
L3316:  .word $451B                 ;AOFF 0,0
;BOTTOM LEFT QUAD
L3318:  .word $5B1B                 ;AOFF -1,-1
L331A:  .word $56FB                 ;AON -2,-3
L331C:  .word $45E0                 ;AON -2,-2
L331E:  .word $40FB                 ;AON -3,-2
L3320:  .word $45EA                 ;AON -1,-1
L3322:  .word $4505                 ;AOFF 0,0
;TOP LEFT QUAD
L3324:  .word $451B                 ;AOFF -1,1
L3326:  .word $4AFB                 ;AON -2,3
L3328:  .word $5BE0                 ;AON -2,2
L332A:  .word $40FB                 ;AON -3,2
L332C:  .word $5BEA                 ;AON -1,1
L332E:  .word $5B05                 ;AOFF 0,0
L3330:  .word VGCNTR                ;CNTR
L3332:  .word $C000                 ;RTSL

VGLZD:           ;LAZAR DOT, END OF TRACER
L3334:  .word $6180                 ;COLOR VGCBLU
L3336:  .word $0000, $E000          ;VON 0,0
L333A:  .word $C000                 ;RTSL

VGINIT:
L333C:  .word VGCNTR                ;CNTR
L333E:  .word VGSCAL                ;SCAL
L3340:  .word $6180                 ;COLOR VGCBLU
L3342:  .word VGRW0&$1FFF, (OFF*$2000)+(VGLIMR&$1FFF) ;VOFF VGLIMR,VGRW0
L3346:  .word $0000, $E000          ;VON 0,0  DO A DOT
L334A:  .word (VGLIMB-VGRW0)&$1FFF, (OFF*$2000)+(0&$1FFF) ;VOFF 0,VGLIMB-VGRW0
L334E:  .word $0000, $E000          ;VON 0,0
L3352:  .word $0000, (OFF*$2000)+((VGLIML-VGLIMR)&$1FFF) ;VOFF VGLIML-VGLIMR,0
L3356:  .word $0000, $E000          ;VON 0,0
L335A:  .word (VGRW0-VGLIMB)&$1FFF, (OFF*$2000)+(0&$1FFF) ;VOFF 0,VGRW0-VGLIMB
L335E:  .word $0000, $E000          ;VON 0,0
L3362:  .word VGCNTR                ;CNTR
L3364:  .word $C000                 ;RTSL

VGFCWN:
L3366:  .word VGRW0&$1FFF, (OFF*$2000)+(VGLIMR&$1FFF) ;VOFF VGLIMR,VGRW0
L336A:  .word (VGLIMB-VGRW0)&$1FFF, $E000 ;VON 0,VGLIMB-VGRW0
L336E:  .word $0000, $FC40          ;VON VGLIML-VGLIMR,0
L3372:  .word (VGRW0-VGLIMB)&$1FFF, $E000 ;VON 0,VGRW0-VGLIMB
L3376:  .word VGRW0&$1FFF, $E3C0    ;VON VGLIMR-VGLIML,VGRW0
L337A:  .word VGCNTR                ;CNTR
L337C:  .word $C000                 ;RTSL

VGLZS0:          ;LINE LEFT TO RIGHT
L337E:  .word $0000, (OFF*$2000)+(-7&$1FFF) ;VOFF -7.,0  LEFT MID
L3382:  .word $40E7                 ;VON 14.,0  RIGHT, MID
L3384:  .word $0000, (OFF*$2000)+(-7&$1FFF) ;VOFF -7.,0  CENTRAL
L3388:  .word $C000                 ;RTSL

VGLZS1:          ;PLUS SIGN
L338A:  .word $0000, (OFF*$2000)+(-7&$1FFF) ;VOFF -7.,0  LEFT
L338E:  .word $40E7                 ;VON 14.,0  RIGHT
L3390:  .word $0007, (OFF*$2000)+(-7&$1FFF) ;VOFF -7.,7.  TOP
L3394:  .word $59E0                 ;VON 0,-14.  BOTTOM
L3396:  .word $0007, (OFF*$2000)+(0&$1FFF) ;VOFF 0,7.  CENTRAL
L339A:  .word $C000                 ;RTSL

VGLZS2:          ;SMALL CIRCLE
L339C:  .word $0000, (OFF*$2000)+(-7&$1FFF) ;VOFF -7.,0  LEFT
L33A0:  .word $0005, $E002          ;VON 2,5  UP LEFT
L33A4:  .word $0002, $E005          ;VON 5,2  UP
L33A8:  .word $1FFE, $E005          ;VON 5,-2  UP RIGHT
L33AC:  .word $1FFB, $E002          ;VON 2,-5  RIGHT
L33B0:  .word $1FFB, $FFFE          ;VON -2,-5  DN RIGHT
L33B4:  .word $1FFE, $FFFB          ;VON -5,-2  DN
L33B8:  .word $0002, $FFFB          ;VON -5,2  DN LEFT
L33BC:  .word $0005, $FFFE          ;VON -2,5  LEFT
L33C0:  .word $0000, (OFF*$2000)+(7&$1FFF) ;VOFF 7,0  CENTRAL
L33C4:  .word $C000                 ;RTSL

VGLZS3:          ;LARGER LAZAR SPLASH CIRCLE
L33C6:  .word $4019                 ;VOFFM -7.,0  LEFT
L33C8:  .word $45E2                 ;VONM 2,5  UP LEFT
L33CA:  .word $42E5                 ;VONM 5,2  UP
L33CC:  .word $5EE5                 ;VONM 5,-2  UP RIGHT
L33CE:  .word $5BE2                 ;VONM 2,-5  RIGHT
L33D0:  .word $5BFE                 ;VONM -2,-5  DN RIGHT
L33D2:  .word $5EFB                 ;VONM -5,-2  DN
L33D4:  .word $42FB                 ;VONM -5,2  DN LEFT
L33D6:  .word $45FE                 ;VONM -2,5  LEFT
L33D8:  .word $4007                 ;VOFFM 7,0  CENTRAL
L33DA:  .word $C000                 ;RTSL

VGSTAR:
L33DC:  .word $B9EF                 ;JSRL .+2  STAR
L33DE:  .word $0000, $E000          ;VON 0,0
L33E2:  .word $C000                 ;RTSL

VGTITL:
L33E4:  .word $6480                 ;COLOR VGCRED
L33E6:  .word VGRW1&$1FFF, (OFF*$2000)+((VGLIML+(3*VGS_CW))&$1FFF) ;VOFF VGLIML+<3*VG$CW>,VGRW1
L33EA:  .word (((CHAR_S-VGBASE)/2)&$1FFF)+$A000 ;ALPHA <SCORE>
L33EC:  .word (((CHAR_C-VGBASE)/2)&$1FFF)+$A000
L33EE:  .word (((CHAR_O-VGBASE)/2)&$1FFF)+$A000
L33F0:  .word (((CHAR_R-VGBASE)/2)&$1FFF)+$A000
L33F2:  .word (((CHAR_E-VGBASE)/2)&$1FFF)+$A000
L33F4:  .word VGCNTR                ;CNTR
L33F6:  .word VGRW1&$1FFF, (OFF*$2000)+((VGLIMR-((4+0)*VGS_CW))&$1FFF) ;VOFF VGLIMR-<<4+0>*VG$CW>,VGRW1  4 CHAR TITLE, 0 CHAR FROM EDGE
L33FA:  .word (((CHAR_W-VGBASE)/2)&$1FFF)+$A000 ;ALPHA <WAVE>
L33FC:  .word (((CHAR_A-VGBASE)/2)&$1FFF)+$A000
L33FE:  .word (((CHAR_V-VGBASE)/2)&$1FFF)+$A000
L3400:  .word (((CHAR_E-VGBASE)/2)&$1FFF)+$A000
L3402:  .word VGCNTR                ;CNTR
L3404:  .word $C000                 ;RTSL

VGFUEL:
L3406:  .word VGRW4&$1FFF, (OFF*$2000)+((-3*VGS_CW)&$1FFF) ;VOFF <-3*VG$CW>,VGRW4
L340A:  .word (((CHAR_S-VGBASE)/2)&$1FFF)+$A000 ;ALPHA <SHIELD>
L340C:  .word (((CHAR_H-VGBASE)/2)&$1FFF)+$A000
L340E:  .word (((CHAR_I-VGBASE)/2)&$1FFF)+$A000
L3410:  .word (((CHAR_E-VGBASE)/2)&$1FFF)+$A000
L3412:  .word (((CHAR_L-VGBASE)/2)&$1FFF)+$A000
L3414:  .word (((CHAR_D-VGBASE)/2)&$1FFF)+$A000
L3416:  .word VGCNTR                ;CNTR
L3418:  .word $C000                 ;RTSL

VGSTTR:
L341A:  .word VGOFFY&$1FFF, (OFF*$2000)+(VGLIMR&$1FFF) ;VOFF VGLIMR,VGOFFY
;GUN SHAFT
L341E:  .word $6180                 ;COLOR VGCBLU
L3420:  .word $001E, $0064          ;AOFF 0,3
L3424:  .word $0000, $FFBA          ;AON -7,3
L3428:  .word $56F6                 ;AON -9,1
L342A:  .word $0000, $E05A          ;AON 0,1
L342E:  .word $0000, $1FA6          ;AOFF -9,1
L3432:  .word $56E0                 ;AON -9,-1
L3434:  .word $0000, $E05A          ;AON 0,-1
L3438:  .word $0000, $1FA6          ;AOFF -9,-1
L343C:  .word $56EA                 ;AON -7,-3
L343E:  .word $0000, $E046          ;AON 0,-3
;GUN COLLAR
L3442:  .word $6480                 ;COLOR VGCRED
L3444:  .word $000A, $1FB0          ;AOFF -8,-2
L3448:  .word $40F6                 ;AON -10,-2
L344A:  .word $45FB                 ;AON -11,-1
L344C:  .word $40EA                 ;AON -9,-1
L344E:  .word $4016                 ;AOFF -11,-1
L3450:  .word $4AE0                 ;AON -11,1
L3452:  .word $40EA                 ;AON -9,1
L3454:  .word $4016                 ;AOFF -11,1
L3456:  .word $45E5                 ;AON -10,2
L3458:  .word $40EA                 ;AON -8,2
;GUN DISH
;COLOR VGCRED ;SAME COLOR AS COLLAR
L345A:  .word $450A                 ;AOFF -6,3
L345C:  .word $4AFB                 ;AON -7,5
L345E:  .word $4AF1                 ;AON -10,7
L3460:  .word $0000, $FFC4          ;AON -16,7
L3464:  .word $5BE0                 ;AON -16,6
L3466:  .word $5BEA                 ;AON -14,5
L3468:  .word $56E5                 ;AON -13,3
L346A:  .word $1FC4, $E000          ;AON -13,-3
L346E:  .word $56FB                 ;AON -14,-5
L3470:  .word $5BF6                 ;AON -16,-6
L3472:  .word $5BE0                 ;AON -16,-7
L3474:  .word $0000, $E03C          ;AON -10,-7
L3478:  .word $4AEF                 ;AON -7,-5
L347A:  .word $4AE5                 ;AON -6,-3
L347C:  .word $561B                 ;AOFF -7,-5
L347E:  .word $0000, $FFC4          ;AON -13,-5
L3482:  .word $56F1                 ;AON -16,-7
L3484:  .word $4A0F                 ;AOFF -13,-5
L3486:  .word $4AE5                 ;AON -12,-3
L3488:  .word $003C, $E000          ;AON -12,3
L348C:  .word $4AFB                 ;AON -13,5
L348E:  .word $0000, $E03C          ;AON -7,5
L3492:  .word $0000, $1FC4          ;AOFF -13,5
L3496:  .word $4AF1                 ;AON -16,7
;GUN TIP
L3498:  .word $6180                 ;COLOR VGCBLU
L349A:  .word $1FC4, $001E          ;AOFF -13,1
L349E:  .word $0000, $FFCE          ;AON -18,1
L34A2:  .word $5BFB                 ;AON -19,0
L34A4:  .word $5BE5                 ;AON -18,-1
L34A6:  .word $0000, $E032          ;AON -13,-1
L34AA:  .word $4500                 ;AOFF -13,0
L34AC:  .word $0000, $FFC4          ;AON -19,0
L34B0:  .word VGCNTR                ;CNTR
L34B2:  .word $C000                 ;RTSL

VGSTBR:
L34B4:  .word VGLIMB&$1FFF, (OFF*$2000)+(VGLIMR&$1FFF) ;VOFF VGLIMR,VGLIMB
;GUN SHAFT
L34B8:  .word $6180                 ;COLOR VGCBLU
L34BA:  .word $1FEC, $0064          ;AOFF 0,1
L34BE:  .word $001E, $FFCE          ;AON -5,4
L34C2:  .word $40F6                 ;AON -7,4
L34C4:  .word $56F6                 ;AON -9,2
L34C6:  .word $56E0                 ;AON -9,0
L34C8:  .word $56EA                 ;AON -7,-2
L34CA:  .word $1FD8, $E046          ;AON 0,-6
L34CE:  .word $4500                 ;AOFF 0,-5
L34D0:  .word $0032, $FFA6          ;AON -9,0
L34D4:  .word $4A00                 ;AOFF -9,2
L34D6:  .word $1FCE, $E05A          ;AON 0,-3
L34DA:  .word $4F00                 ;AOFF 0,0
L34DC:  .word $0028, $FFBA          ;AON -7,4
;GUN COLLAR
L34E0:  .word $6480                 ;COLOR VGCRED
L34E2:  .word $40F1                 ;AON -10,4
L34E4:  .word $5BFB                 ;AON -11,3
L34E6:  .word $56E0                 ;AON -11,1
L34E8:  .word $5BE5                 ;AON -10,0
L34EA:  .word $5BEA                 ;AON -8,-1
L34EC:  .word $451B                 ;AOFF -9,0
L34EE:  .word $45F6                 ;AON -11,1
L34F0:  .word $4A00                 ;AOFF -11,3
L34F2:  .word $5BEA                 ;AON -9,2
L34F4:  .word $4505                 ;AOFF -8,3
L34F6:  .word $45F6                 ;AON -10,4
;GUN DISH
;COLOR VGCRED ;SAME COLOR AS COLLAR
L34F8:  .word $0000, $0028          ;AOFF -6,4
L34FC:  .word $4AE0                 ;AON -6,6
L34FE:  .word $4AFB                 ;AON -7,8
L3500:  .word $4AF1                 ;AON -10,10
L3502:  .word $0000, $FFC4          ;AON -16,10
L3506:  .word $5BE0                 ;AON -16,9
L3508:  .word $5BEA                 ;AON -14,8
L350A:  .word $56E5                 ;AON -13,6
L350C:  .word $1FC4, $E000          ;AON -13,0
L3510:  .word $56FB                 ;AON -14,-2
L3512:  .word $5BF6                 ;AON -16,-3
L3514:  .word $5BE0                 ;AON -16,-4
L3516:  .word $0000, $E03C          ;AON -10,-4
L351A:  .word $4AEF                 ;AON -7,-2
L351C:  .word $0000, $FFC4          ;AON -13,-2
L3520:  .word $56F1                 ;AON -16,-4
L3522:  .word $4A0F                 ;AOFF -13,-2
L3524:  .word $4AE5                 ;AON -12,0
L3526:  .word $003C, $E000          ;AON -12,6
L352A:  .word $4AFB                 ;AON -13,8
L352C:  .word $4AF1                 ;AON -16,10
L352E:  .word $560F                 ;AOFF -13,8
L3530:  .word $0000, $E03C          ;AON -7,8
;GUN TIP
L3534:  .word $6180                 ;COLOR VGCBLU
L3536:  .word $1FE2, $1FC4          ;AOFF -13,5
L353A:  .word $0014, $FFD8          ;AON -17,7
L353E:  .word $40F6                 ;AON -19,7
L3540:  .word $5BE0                 ;AON -19,6
L3542:  .word $5BE5                 ;AON -18,5
L3544:  .word $1FE2, $E032          ;AON -13,2
L3548:  .word $4500                 ;AOFF -13,3
L354A:  .word $001E, $FFC4          ;AON -19,6
L354E:  .word $4505                 ;AOFF -18,7
L3550:  .word $1FE2, $E032          ;AON -13,4
L3554:  .word VGCNTR                ;CNTR
L3556:  .word $C000                 ;RTSL

VGSTBM:
L3558:  .word VGLIMB&$1FFF, (OFF*$2000)+(0&$1FFF) ;VOFF 0,VGLIMB
L355C:  .word $6180                 ;COLOR VGCBLU
L355E:  .word $1F9C, $1F88          ;AOFF -12,-3
L3562:  .word $003C, $E014          ;AON -10,3
L3566:  .word $4AEA                 ;AON -8,5
L3568:  .word $4AEF                 ;AON -5,7
L356A:  .word $4AEA                 ;AON -3,9
L356C:  .word $0000, $E03C          ;AON 3,9
L3570:  .word $56EA                 ;AON 5,7
L3572:  .word $56EF                 ;AON 8,5
L3574:  .word $56EA                 ;AON 10,3
L3576:  .word $1FC4, $E014          ;AON 12,-3
L357A:  .word $4011                 ;AOFF 9,-3
L357C:  .word $003C, $FFEC          ;AON 7,3
L3580:  .word $0028, $FFD8          ;AON 3,7
L3584:  .word $0000, $FFC4          ;AON -3,7
L3588:  .word $1FD8, $FFD8          ;AON -7,3
L358C:  .word $1FC4, $FFEC          ;AON -9,-3
L3590:  .word $400A                 ;AOFF -7,-3
L3592:  .word $6480                 ;COLOR VGCRED
L3594:  .word $005A, $E01E          ;AON -4,6
L3598:  .word $000A, $0050          ;AOFF 4,7
L359C:  .word $1F9C, $E01E          ;AON 7,-3
L35A0:  .word $0046, $0014          ;AOFF 9,4
L35A4:  .word $4FF6                 ;AON 7,7
L35A6:  .word $0028, $FFE2          ;AON 4,11
L35AA:  .word $4AF6                 ;AON 2,13
L35AC:  .word $1FD8, $E00A          ;AON 3,9
L35B0:  .word $0028, $1FF6          ;AOFF 2,13
L35B4:  .word $0000, $FFD8          ;AON -2,13
L35B8:  .word $1FD8, $FFF6          ;AON -3,9
L35BC:  .word $0028, $000A          ;AOFF -2,13
L35C0:  .word $56F6                 ;AON -4,11
L35C2:  .word $1FD8, $FFE2          ;AON -7,7
L35C6:  .word $51F6                 ;AON -9,4
L35C8:  .word VGCNTR                ;CNTR
L35CA:  .word $C000                 ;RTSL

VGSTTL:
L35CC:  .word VGOFFY&$1FFF, (OFF*$2000)+(VGLIML&$1FFF) ;VOFF VGLIML,VGOFFY
;GUN SHAFT
L35D0:  .word $6180                 ;COLOR VGCBLU
L35D2:  .word $001E, $1F9C          ;AOFF 0,3
L35D6:  .word $0000, $E046          ;AON 7,3
L35DA:  .word $56EA                 ;AON 9,1
L35DC:  .word $0000, $FFA6          ;AON 0,1
L35E0:  .word $0000, $005A          ;AOFF 9,1
L35E4:  .word $56E0                 ;AON 9,-1
L35E6:  .word $0000, $FFA6          ;AON 0,-1
L35EA:  .word $0000, $005A          ;AOFF 9,-1
L35EE:  .word $56F6                 ;AON 7,-3
L35F0:  .word $0000, $FFBA          ;AON 0,-3
;GUN COLLAR
L35F4:  .word $6480                 ;COLOR VGCRED
L35F6:  .word $000A, $0050          ;AOFF 8,-2
L35FA:  .word $40EA                 ;AON 10,-2
L35FC:  .word $45E5                 ;AON 11,-1
L35FE:  .word $40F6                 ;AON 9,-1
L3600:  .word $400A                 ;AOFF 11,-1
L3602:  .word $4AE0                 ;AON 11,1
L3604:  .word $40F6                 ;AON 9,1
L3606:  .word $400A                 ;AOFF 11,1
L3608:  .word $45FB                 ;AON 10,2
L360A:  .word $40F6                 ;AON 8,2
;GUN DISH
;COLOR VGCRED ;SAME COLOR AS COLLAR
L360C:  .word $4516                 ;AOFF 6,3
L360E:  .word $4AE5                 ;AON 7,5
L3610:  .word $4AEF                 ;AON 10,7
L3612:  .word $0000, $E03C          ;AON 16,7
L3616:  .word $5BE0                 ;AON 16,6
L3618:  .word $5BF6                 ;AON 14,5
L361A:  .word $56FB                 ;AON 13,3
L361C:  .word $1FC4, $E000          ;AON 13,-3
L3620:  .word $56E5                 ;AON 14,-5
L3622:  .word $5BEA                 ;AON 16,-6
L3624:  .word $5BE0                 ;AON 16,-7
L3626:  .word $0000, $FFC4          ;AON 10,-7
L362A:  .word $4AF1                 ;AON 7,-5
L362C:  .word $4AFB                 ;AON 6,-3
L362E:  .word $5605                 ;AOFF 7,-5
L3630:  .word $0000, $E03C          ;AON 13,-5
L3634:  .word $56EF                 ;AON 16,-7
L3636:  .word $4A11                 ;AOFF 13,-5
L3638:  .word $4AFB                 ;AON 12,-3
L363A:  .word $003C, $E000          ;AON 12,3
L363E:  .word $4AE5                 ;AON 13,5
L3640:  .word $0000, $FFC4          ;AON 7,5
L3644:  .word $0000, $003C          ;AOFF 13,5
L3648:  .word $4AEF                 ;AON 16,7
;GUN TIP
L364A:  .word $6180                 ;COLOR VGCBLU
L364C:  .word $1FC4, $1FE2          ;AOFF 13,1
L3650:  .word $0000, $E032          ;AON 18,1
L3654:  .word $5BE5                 ;AON 19,0
L3656:  .word $5BFB                 ;AON 18,-1
L3658:  .word $0000, $FFCE          ;AON 13,-1
L365C:  .word $4500                 ;AOFF 13,0
L365E:  .word $0000, $E03C          ;AON 19,0
L3662:  .word VGCNTR                ;CNTR
L3664:  .word $C000                 ;RTSL

VGSTBL:
L3666:  .word VGLIMB&$1FFF, (OFF*$2000)+(VGLIML&$1FFF) ;VOFF VGLIML,VGLIMB
;GUN SHAFT
L366A:  .word $6180                 ;COLOR VGCBLU
L366C:  .word $1FEC, $1F9C          ;AOFF 0,1
L3670:  .word $001E, $E032          ;AON 5,4
L3674:  .word $40EA                 ;AON 7,4
L3676:  .word $56EA                 ;AON 9,2
L3678:  .word $56E0                 ;AON 9,0
L367A:  .word $56F6                 ;AON 7,-2
L367C:  .word $1FD8, $FFBA          ;AON 0,-6
L3680:  .word $4500                 ;AOFF 0,-5
L3682:  .word $0032, $E05A          ;AON 9,0
L3686:  .word $4A00                 ;AOFF 9,2
L3688:  .word $1FCE, $FFA6          ;AON 0,-3
L368C:  .word $4F00                 ;AOFF 0,0
L368E:  .word $0028, $E046          ;AON 7,4
;GUN COLLAR
L3692:  .word $6480                 ;COLOR VGCRED
L3694:  .word $40EF                 ;AON 10,4
L3696:  .word $5BE5                 ;AON 11,3
L3698:  .word $56E0                 ;AON 11,1
L369A:  .word $5BFB                 ;AON 10,0
L369C:  .word $5BF6                 ;AON 8,-1
L369E:  .word $4505                 ;AOFF 9,0
L36A0:  .word $45EA                 ;AON 11,1
L36A2:  .word $4A00                 ;AOFF 11,3
L36A4:  .word $5BF6                 ;AON 9,2
L36A6:  .word $451B                 ;AOFF 8,3
L36A8:  .word $45EA                 ;AON 10,4
;GUN DISH
;COLOR VGCRED ;SAME COLOR AS COLLAR
L36AA:  .word $0000, $1FD8          ;AOFF 6,4
L36AE:  .word $4AE0                 ;AON 6,6
L36B0:  .word $4AE5                 ;AON 7,8
L36B2:  .word $4AEF                 ;AON 10,10
L36B4:  .word $0000, $E03C          ;AON 16,10
L36B8:  .word $5BE0                 ;AON 16,9
L36BA:  .word $5BF6                 ;AON 14,8
L36BC:  .word $56FB                 ;AON 13,6
L36BE:  .word $1FC4, $E000          ;AON 13,0
L36C2:  .word $56E5                 ;AON 14,-2
L36C4:  .word $5BEA                 ;AON 16,-3
L36C6:  .word $5BE0                 ;AON 16,-4
L36C8:  .word $0000, $FFC4          ;AON 10,-4
L36CC:  .word $4AF1                 ;AON 7,-2
L36CE:  .word $0000, $E03C          ;AON 13,-2
L36D2:  .word $56EF                 ;AON 16,-4
L36D4:  .word $4A11                 ;AOFF 13,-2
L36D6:  .word $4AFB                 ;AON 12,0
L36D8:  .word $003C, $E000          ;AON 12,6
L36DC:  .word $4AE5                 ;AON 13,8
L36DE:  .word $4AEF                 ;AON 16,10
L36E0:  .word $5611                 ;AOFF 13,8
L36E2:  .word $0000, $FFC4          ;AON 7,8
;GUN TIP
L36E6:  .word $6180                 ;COLOR VGCBLU
L36E8:  .word $1FE2, $003C          ;AOFF 13,5
L36EC:  .word $0014, $E028          ;AON 17,7
L36F0:  .word $40EA                 ;AON 19,7
L36F2:  .word $5BE0                 ;AON 19,6
L36F4:  .word $5BFB                 ;AON 18,5
L36F6:  .word $1FE2, $FFCE          ;AON 13,2
L36FA:  .word $4500                 ;AOFF 13,3
L36FC:  .word $001E, $E03C          ;AON 19,6
L3700:  .word $451B                 ;AOFF 18,7
L3702:  .word $1FE2, $FFCE          ;AON 13,4
L3706:  .word VGCNTR                ;CNTR
L3708:  .word $C000                 ;RTSL

;.SBTTL DROPLINES FOR TITLE

DROP15:          ;DROP 1 SEGMENTS OF TOTAL LENGTH OF 5
L370A:  .word $1FD8, (OFF*$2000)+((0*M_/D_)&$1FFF) ;VOFFM 0,-1.
L370E:  .word (((RISE15-VGBASE)/2)&$1FFF)+$E000 ;JMPL RISE15  DISPLAY GOING BACK UP

DROP25:          ;DROP 2 SEGMENTS OF TOTAL LENGTH OF 5
L3710:  .word $1FB0, (OFF*$2000)+((0*M_/D_)&$1FFF) ;VOFFM 0,-2.
L3714:  .word (((RISE25-VGBASE)/2)&$1FFF)+$E000 ;JMPL RISE25  DISPLAY GOING BACK UP

DROP35:          ;DROP 3 SEGMENTS OF TOTAL LENGTH OF 5
L3716:  .word $1F88, (OFF*$2000)+((0*M_/D_)&$1FFF) ;VOFFM 0,-3.
L371A:  .word (((RISE35-VGBASE)/2)&$1FFF)+$E000 ;JMPL RISE35  DISPLAY GOING BACK UP

DROP45:          ;DROP 4 SEGMENTS OF TOTAL LENGTH OF 5
L371C:  .word $1F60, (OFF*$2000)+((0*M_/D_)&$1FFF) ;VOFFM 0,-4.
L3720:  .word (((RISE45-VGBASE)/2)&$1FFF)+$E000 ;JMPL RISE45  DISPLAY GOING BACK UP

DROP55:          ;DROP 5 SEGMENTS OF TOTAL LENGTH OF 5
L3722:  .word $1F38, (OFF*$2000)+((0*M_/D_)&$1FFF) ;VOFFM 0,-5.
L3726:  .word (((RISE55-VGBASE)/2)&$1FFF)+$E000 ;JMPL RISE55  DISPLAY GOING BACK UP

DROP16:          ;DROP 1 SEGMENTS OF TOTAL LENGTH OF 6
L3728:  .word $1FD8, (OFF*$2000)+((0*M_/D_)&$1FFF) ;VOFFM 0,-1.
L372C:  .word (((RISE16-VGBASE)/2)&$1FFF)+$E000 ;JMPL RISE16  DISPLAY GOING BACK UP

DROP26:          ;DROP 2 SEGMENTS OF TOTAL LENGTH OF 6
L372E:  .word $1FB0, (OFF*$2000)+((0*M_/D_)&$1FFF) ;VOFFM 0,-2.
L3732:  .word (((RISE26-VGBASE)/2)&$1FFF)+$E000 ;JMPL RISE26  DISPLAY GOING BACK UP

DROP36:          ;DROP 3 SEGMENTS OF TOTAL LENGTH OF 6
L3734:  .word $1F88, (OFF*$2000)+((0*M_/D_)&$1FFF) ;VOFFM 0,-3.
L3738:  .word (((RISE36-VGBASE)/2)&$1FFF)+$E000 ;JMPL RISE36  DISPLAY GOING BACK UP

DROP46:          ;DROP 4 SEGMENTS OF TOTAL LENGTH OF 6
L373A:  .word $1F60, (OFF*$2000)+((0*M_/D_)&$1FFF) ;VOFFM 0,-4.
L373E:  .word (((RISE46-VGBASE)/2)&$1FFF)+$E000 ;JMPL RISE46  DISPLAY GOING BACK UP

DROP56:          ;DROP 5 SEGMENTS OF TOTAL LENGTH OF 6
L3740:  .word $1F38, (OFF*$2000)+((0*M_/D_)&$1FFF) ;VOFFM 0,-5.
L3744:  .word (((RISE56-VGBASE)/2)&$1FFF)+$E000 ;JMPL RISE56  DISPLAY GOING BACK UP

DROP66:          ;DROP 6 SEGMENTS OF TOTAL LENGTH OF 6
L3746:  .word $1F10, (OFF*$2000)+((0*M_/D_)&$1FFF) ;VOFFM 0,-6.
L374A:  .word (((RISE66-VGBASE)/2)&$1FFF)+$E000 ;JMPL RISE66  DISPLAY GOING BACK UP

RISE55:          ;RISE FROM BOTTOM BACK TO TOP
L374C:  .word $0028, $2000          ;VONM 0,1.,1

RISE45:
L3750:  .word $0028, $4000          ;VONM 0,1.,2

RISE35:
L3754:  .word $0028, $6000          ;VONM 0,1.,3

RISE25:
L3758:  .word $0028, $8000          ;VONM 0,1.,4

RISE15:
L375C:  .word $0028, $A000          ;VONM 0,1.,5
L3760:  .word $C000                 ;RTSL

RISE66:          ;DRAW UPWARDS, BRITER ON TOP
L3762:  .word $0028, $2000          ;VONM 0,1.,1

RISE56:
L3766:  .word $0028, $4000          ;VONM 0,1.,2

RISE46:
L376A:  .word $0028, $6000          ;VONM 0,1.,3

RISE36:
L376E:  .word $0028, $8000          ;VONM 0,1.,4

RISE26:
L3772:  .word $0028, $A000          ;VONM 0,1.,5

RISE16:
L3776:  .word $0028, $C000          ;VONM 0,1.,6
L377A:  .word $C000                 ;RTSL

;.SBTTL GAS GAUGE
L377C:  .word (((VLG0R-VGBASE)/2)&$1FFF)+$A000 ;.IRP .A,<G0,G1A,G1,G2A,G2,G3A,G3,G4A,G4,G5A,G5,G6A,G6,G7A,G7,G8A,G8,G9A,G9>
L377E:  .word (((VLG0L-VGBASE)/2)&$1FFF)+$E000
L3780:  .word (((VLG1AR-VGBASE)/2)&$1FFF)+$A000
L3782:  .word (((VLG1AL-VGBASE)/2)&$1FFF)+$E000
L3784:  .word (((VLG1R-VGBASE)/2)&$1FFF)+$A000
L3786:  .word (((VLG1L-VGBASE)/2)&$1FFF)+$E000
L3788:  .word (((VLG2AR-VGBASE)/2)&$1FFF)+$A000
L378A:  .word (((VLG2AL-VGBASE)/2)&$1FFF)+$E000
L378C:  .word (((VLG2R-VGBASE)/2)&$1FFF)+$A000
L378E:  .word (((VLG2L-VGBASE)/2)&$1FFF)+$E000
L3790:  .word (((VLG3AR-VGBASE)/2)&$1FFF)+$A000
L3792:  .word (((VLG3AL-VGBASE)/2)&$1FFF)+$E000
L3794:  .word (((VLG3R-VGBASE)/2)&$1FFF)+$A000
L3796:  .word (((VLG3L-VGBASE)/2)&$1FFF)+$E000
L3798:  .word (((VLG4AR-VGBASE)/2)&$1FFF)+$A000
L379A:  .word (((VLG4AL-VGBASE)/2)&$1FFF)+$E000
L379C:  .word (((VLG4R-VGBASE)/2)&$1FFF)+$A000
L379E:  .word (((VLG4L-VGBASE)/2)&$1FFF)+$E000
L37A0:  .word (((VLG5AR-VGBASE)/2)&$1FFF)+$A000
L37A2:  .word (((VLG5AL-VGBASE)/2)&$1FFF)+$E000
L37A4:  .word (((VLG5R-VGBASE)/2)&$1FFF)+$A000
L37A6:  .word (((VLG5L-VGBASE)/2)&$1FFF)+$E000
L37A8:  .word (((VLG6AR-VGBASE)/2)&$1FFF)+$A000
L37AA:  .word (((VLG6AL-VGBASE)/2)&$1FFF)+$E000
L37AC:  .word (((VLG6R-VGBASE)/2)&$1FFF)+$A000
L37AE:  .word (((VLG6L-VGBASE)/2)&$1FFF)+$E000
L37B0:  .word (((VLG7AR-VGBASE)/2)&$1FFF)+$A000
L37B2:  .word (((VLG7AL-VGBASE)/2)&$1FFF)+$E000
L37B4:  .word (((VLG7R-VGBASE)/2)&$1FFF)+$A000
L37B6:  .word (((VLG7L-VGBASE)/2)&$1FFF)+$E000
L37B8:  .word (((VLG8AR-VGBASE)/2)&$1FFF)+$A000
L37BA:  .word (((VLG8AL-VGBASE)/2)&$1FFF)+$E000
L37BC:  .word (((VLG8R-VGBASE)/2)&$1FFF)+$A000
L37BE:  .word (((VLG8L-VGBASE)/2)&$1FFF)+$E000
L37C0:  .word (((VLG9AR-VGBASE)/2)&$1FFF)+$A000
L37C2:  .word (((VLG9AL-VGBASE)/2)&$1FFF)+$E000
L37C4:  .word (((VLG9R-VGBASE)/2)&$1FFF)+$A000
L37C6:  .word (((VLG9L-VGBASE)/2)&$1FFF)+$E000
L37C8:  .word (((VLGA0R-VGBASE)/2)&$1FFF)+$A000 ;.IRP .A,<0,1,2,3,4,5,6,7,8,9>
L37CA:  .word (((VLGA0L-VGBASE)/2)&$1FFF)+$E000
L37CC:  .word (((VLGA0R-VGBASE)/2)&$1FFF)+$A000
L37CE:  .word (((VLGA0L-VGBASE)/2)&$1FFF)+$E000
L37D0:  .word (((VLGA1R-VGBASE)/2)&$1FFF)+$A000
L37D2:  .word (((VLGA1L-VGBASE)/2)&$1FFF)+$E000
L37D4:  .word (((VLGA1R-VGBASE)/2)&$1FFF)+$A000
L37D6:  .word (((VLGA1L-VGBASE)/2)&$1FFF)+$E000
L37D8:  .word (((VLGA2R-VGBASE)/2)&$1FFF)+$A000
L37DA:  .word (((VLGA2L-VGBASE)/2)&$1FFF)+$E000
L37DC:  .word (((VLGA2R-VGBASE)/2)&$1FFF)+$A000
L37DE:  .word (((VLGA2L-VGBASE)/2)&$1FFF)+$E000
L37E0:  .word (((VLGA3R-VGBASE)/2)&$1FFF)+$A000
L37E2:  .word (((VLGA3L-VGBASE)/2)&$1FFF)+$E000
L37E4:  .word (((VLGA3R-VGBASE)/2)&$1FFF)+$A000
L37E6:  .word (((VLGA3L-VGBASE)/2)&$1FFF)+$E000
L37E8:  .word (((VLGA4R-VGBASE)/2)&$1FFF)+$A000
L37EA:  .word (((VLGA4L-VGBASE)/2)&$1FFF)+$E000
L37EC:  .word (((VLGA4R-VGBASE)/2)&$1FFF)+$A000
L37EE:  .word (((VLGA4L-VGBASE)/2)&$1FFF)+$E000
L37F0:  .word (((VLGA5R-VGBASE)/2)&$1FFF)+$A000
L37F2:  .word (((VLGA5L-VGBASE)/2)&$1FFF)+$E000
L37F4:  .word (((VLGA5R-VGBASE)/2)&$1FFF)+$A000
L37F6:  .word (((VLGA5L-VGBASE)/2)&$1FFF)+$E000
L37F8:  .word (((VLGA6R-VGBASE)/2)&$1FFF)+$A000
L37FA:  .word (((VLGA6L-VGBASE)/2)&$1FFF)+$E000
L37FC:  .word (((VLGA6R-VGBASE)/2)&$1FFF)+$A000
L37FE:  .word (((VLGA6L-VGBASE)/2)&$1FFF)+$E000
L3800:  .word (((VLGA7R-VGBASE)/2)&$1FFF)+$A000
L3802:  .word (((VLGA7L-VGBASE)/2)&$1FFF)+$E000
L3804:  .word (((VLGA7R-VGBASE)/2)&$1FFF)+$A000
L3806:  .word (((VLGA7L-VGBASE)/2)&$1FFF)+$E000
L3808:  .word (((VLGA8R-VGBASE)/2)&$1FFF)+$A000
L380A:  .word (((VLGA8L-VGBASE)/2)&$1FFF)+$E000
L380C:  .word (((VLGA8R-VGBASE)/2)&$1FFF)+$A000
L380E:  .word (((VLGA8L-VGBASE)/2)&$1FFF)+$E000
L3810:  .word (((VLGA9R-VGBASE)/2)&$1FFF)+$A000
L3812:  .word (((VLGA9L-VGBASE)/2)&$1FFF)+$E000
L3814:  .word (((VLGA9R-VGBASE)/2)&$1FFF)+$A000
L3816:  .word (((VLGA9L-VGBASE)/2)&$1FFF)+$E000

VLG0R:
;RIGHT SIDE
;DO JUST THE BASE LINE
;#A IS LESS DRAW (DOES # WITHOUT THE TIC)
L3818:  .word $C000                 ;RTSL

VLG1AR:
L381A:  .word $400F                 ;VOFFM 3,0
L381C:  .word (((GSB1AR-VGBASE)/2)&$1FFF)+$E000 ;JMPL GSB1AR

VLG1R:
L381E:  .word $400F                 ;VOFFM 3,0
L3820:  .word (((GSB1R-VGBASE)/2)&$1FFF)+$E000 ;JMPL GSB1R

VLG2AR:
L3822:  .word (0*M_*MASP/DASP/D_)&$1FFF, $003C ;VOFFM 6,0
L3826:  .word (((GSB2AR-VGBASE)/2)&$1FFF)+$E000 ;JMPL GSB2AR

VLG2R:
L3828:  .word (0*M_*MASP/DASP/D_)&$1FFF, $003C ;VOFFM 6,0
L382C:  .word (((GSB2R-VGBASE)/2)&$1FFF)+$E000 ;JMPL GSB2R

VLG3AR:
L382E:  .word (0*M_*MASP/DASP/D_)&$1FFF, $005A ;VOFFM 9,0
L3832:  .word (((GSB3AR-VGBASE)/2)&$1FFF)+$E000 ;JMPL GSB3AR

VLG3R:
L3834:  .word (0*M_*MASP/DASP/D_)&$1FFF, $005A ;VOFFM 9,0
L3838:  .word (((GSB3R-VGBASE)/2)&$1FFF)+$E000 ;JMPL GSB3R

VLG4AR:
L383A:  .word (0*M_*MASP/DASP/D_)&$1FFF, $0078 ;VOFFM 12.,0
L383E:  .word (((GSB4AR-VGBASE)/2)&$1FFF)+$E000 ;JMPL GSB4AR

VLG4R:
L3840:  .word (0*M_*MASP/DASP/D_)&$1FFF, $0078 ;VOFFM 12.,0
L3844:  .word (((GSB4R-VGBASE)/2)&$1FFF)+$E000 ;JMPL GSB4R

VLG5AR:
L3846:  .word (0*M_*MASP/DASP/D_)&$1FFF, $0096 ;VOFFM 15.,0
L384A:  .word (((GSB5AR-VGBASE)/2)&$1FFF)+$E000 ;JMPL GSB5AR

VLG5R:
L384C:  .word (0*M_*MASP/DASP/D_)&$1FFF, $0096 ;VOFFM 15.,0
L3850:  .word (((GSB5R-VGBASE)/2)&$1FFF)+$E000 ;JMPL GSB5R

VLG6AR:
L3852:  .word (0*M_*MASP/DASP/D_)&$1FFF, $00B4 ;VOFFM 18.,0
L3856:  .word (((GSB6AR-VGBASE)/2)&$1FFF)+$E000 ;JMPL GSB6AR

VLG6R:
L3858:  .word (0*M_*MASP/DASP/D_)&$1FFF, $00B4 ;VOFFM 18.,0
L385C:  .word (((GSB6R-VGBASE)/2)&$1FFF)+$E000 ;JMPL GSB6R

VLG7AR:
L385E:  .word (0*M_*MASP/DASP/D_)&$1FFF, $00D2 ;VOFFM 21.,0
L3862:  .word (((GSB7AR-VGBASE)/2)&$1FFF)+$E000 ;JMPL GSB7AR

VLG7R:
L3864:  .word (0*M_*MASP/DASP/D_)&$1FFF, $00D2 ;VOFFM 21.,0
L3868:  .word (((GSB7R-VGBASE)/2)&$1FFF)+$E000 ;JMPL GSB7R

VLG8AR:
L386A:  .word (0*M_*MASP/DASP/D_)&$1FFF, $00F0 ;VOFFM 24.,0
L386E:  .word (((GSB8AR-VGBASE)/2)&$1FFF)+$E000 ;JMPL GSB8AR

VLG8R:
L3870:  .word (0*M_*MASP/DASP/D_)&$1FFF, $00F0 ;VOFFM 24.,0
L3874:  .word (((GSB8R-VGBASE)/2)&$1FFF)+$E000 ;JMPL GSB8R

VLG9AR:
L3876:  .word (0*M_*MASP/DASP/D_)&$1FFF, $00F0 ;VOFFM 24.,0
L387A:  .word (((GSB9AR-VGBASE)/2)&$1FFF)+$E000 ;JMPL GSB9AR

VLG9R:
L387C:  .word (0*M_*MASP/DASP/D_)&$1FFF, $00F0 ;VOFFM 24.,0
L3880:  .word (((GSB9R-VGBASE)/2)&$1FFF)+$E000 ;JMPL GSB9R

VLGA0R:
;DO ALL OF DISPLAY, BRITE OUT TO EDGE UP
L3882:  .word $C000                 ;RTSL

VLGA1R:
L3884:  .word $1FF1, $E01E          ;VONM 3,-1
L3888:  .word (((GSU1R-VGBASE)/2)&$1FFF)+$E000 ;JMPL GSU1R

VLGA2R:
L388A:  .word $1FE2, $E03C          ;VONM 6,-2
L388E:  .word (((GSU2R-VGBASE)/2)&$1FFF)+$E000 ;JMPL GSU2R

VLGA3R:
L3890:  .word $1FD3, $E05A          ;VONM 9,-3
L3894:  .word (((GSU3R-VGBASE)/2)&$1FFF)+$E000 ;JMPL GSU3R

VLGA4R:
L3896:  .word $1FC4, $E078          ;VONM 12.,-4
L389A:  .word (((GSU4R-VGBASE)/2)&$1FFF)+$E000 ;JMPL GSU4R

VLGA5R:
L389C:  .word $1FB5, $E096          ;VONM 15.,-5
L38A0:  .word (((GSU5R-VGBASE)/2)&$1FFF)+$E000 ;JMPL GSU5R

VLGA6R:
L38A2:  .word $1FA6, $E0B4          ;VONM 18.,-6
L38A6:  .word (((GSU6R-VGBASE)/2)&$1FFF)+$E000 ;JMPL GSU6R

VLGA7R:
L38A8:  .word $1F97, $E0D2          ;VONM 21.,-7
L38AC:  .word (((GSU7R-VGBASE)/2)&$1FFF)+$E000 ;JMPL GSU7R

VLGA8R:
L38AE:  .word $1F88, $E0F0          ;VONM 24.,-8
L38B2:  .word (((GSU8R-VGBASE)/2)&$1FFF)+$E000 ;JMPL GSU8R

VLGA9R:
L38B4:  .word $1F79, $E10E          ;VONM 27.,-9
L38B8:  .word (((GSU9R-VGBASE)/2)&$1FFF)+$E000 ;JMPL GSU9R

VLGU0R:
;UPSTROKE, BLANK DOWN TOP THEN DO FULL EDGE UP
;GSU* DOES ASSUMES IN CORRECT POSITION FOR UPSTROKE
L38BA:  .word $C000                 ;RTSL

VLGU1R:
L38BC:  .word $1FF1, $001E          ;VOFFM 3,-1

GSU1R:
L38C0:  .word $000F, $E000          ;VONM 0,1
L38C4:  .word (((GSB1AR-VGBASE)/2)&$1FFF)+$E000 ;JMPL GSB1AR

VLGU2R:
L38C6:  .word $1FE2, $003C          ;VOFFM 6,-2

GSU2R:
L38CA:  .word $4FE0                 ;VONM 0,2
L38CC:  .word (((GSB2AR-VGBASE)/2)&$1FFF)+$E000 ;JMPL GSB2AR

VLGU3R:
L38CE:  .word $1FD3, $005A          ;VOFFM 9,-3

GSU3R:
L38D2:  .word $002D, $E000          ;VONM 0,3
L38D6:  .word (((GSB3AR-VGBASE)/2)&$1FFF)+$E000 ;JMPL GSB3AR

VLGU4R:
L38D8:  .word $1FC4, $0078          ;VOFFM 12.,-4

GSU4R:
L38DC:  .word $003C, $E000          ;VONM 0,4
L38E0:  .word (((GSB4AR-VGBASE)/2)&$1FFF)+$E000 ;JMPL GSB4AR

VLGU5R:
L38E2:  .word $1FB5, $0096          ;VOFFM 15.,-5

GSU5R:
L38E6:  .word $004B, $E000          ;VONM 0,5
L38EA:  .word (((GSB5AR-VGBASE)/2)&$1FFF)+$E000 ;JMPL GSB5AR

VLGU6R:
L38EC:  .word $1FA6, $00B4          ;VOFFM 18.,-6

GSU6R:
L38F0:  .word $005A, $E000          ;VONM 0,6
L38F4:  .word (((GSB6AR-VGBASE)/2)&$1FFF)+$E000 ;JMPL GSB6AR

VLGU7R:
L38F6:  .word $1F97, $00D2          ;VOFFM 21.,-7

GSU7R:
L38FA:  .word $0069, $E000          ;VONM 0,7
L38FE:  .word (((GSB7AR-VGBASE)/2)&$1FFF)+$E000 ;JMPL GSB7AR

VLGU8R:
L3900:  .word $1F88, $00F0          ;VOFFM 24.,-8

GSU8R:
L3904:  .word $0078, $E000          ;VONM 0,8
L3908:  .word (((GSB8AR-VGBASE)/2)&$1FFF)+$E000 ;JMPL GSB8AR

VLGU9R:
L390A:  .word $1F79, $010E          ;VOFFM 27.,-9

GSU9R:
L390E:  .word $0087, $E000          ;VONM 0,9
L3912:  .word (((GSB9AR-VGBASE)/2)&$1FFF)+$E000 ;JMPL GSB9AR

GSB9R:
;GSB* DOES BASE LINE FROM OUTWARD ON BACK
;# ==> PARTIAL UPSTROKE FOLLOWED BY BASELINE
;#A ==> NO UPSTROKE, JUST BASELINE
L3914:  .word $1F79, (OFF*$2000)+((0*M_/D_)&$1FFF) ;VOFFM 0,-9
L3918:  .word $0087, $E000          ;VONM 0,9

GSB9AR:
L391C:  .word $40F1                 ;VONM -3,0

GSB8R:
L391E:  .word $1FF1, (OFF*$2000)+((0*M_/D_)&$1FFF) ;VOFFM 0,-1
L3922:  .word $000F, $E000          ;VONM 0,1

GSB8AR:
L3926:  .word $40F1                 ;VONM -3,0

GSB7R:
L3928:  .word $1FF1, (OFF*$2000)+((0*M_/D_)&$1FFF) ;VOFFM 0,-1
L392C:  .word $000F, $E000          ;VONM 0,1

GSB7AR:
L3930:  .word $40F1                 ;VONM -3,0

GSB6R:
L3932:  .word $1FA6, (OFF*$2000)+((0*M_/D_)&$1FFF) ;VOFFM 0,-6
L3936:  .word $005A, $E000          ;VONM 0,6

GSB6AR:
L393A:  .word $40F1                 ;VONM -3,0

GSB5R:
L393C:  .word $1FF1, (OFF*$2000)+((0*M_/D_)&$1FFF) ;VOFFM 0,-1
L3940:  .word $000F, $E000          ;VONM 0,1

GSB5AR:
L3944:  .word $40F1                 ;VONM -3,0

GSB4R:
L3946:  .word $1FF1, (OFF*$2000)+((0*M_/D_)&$1FFF) ;VOFFM 0,-1
L394A:  .word $000F, $E000          ;VONM 0,1

GSB4AR:
L394E:  .word $40F1                 ;VONM -3,0

GSB3R:
L3950:  .word $1FD3, (OFF*$2000)+((0*M_/D_)&$1FFF) ;VOFFM 0,-3
L3954:  .word $002D, $E000          ;VONM 0,3

GSB3AR:
L3958:  .word $40F1                 ;VONM -3,0

GSB2R:
L395A:  .word $1FF1, (OFF*$2000)+((0*M_/D_)&$1FFF) ;VOFFM 0,-1
L395E:  .word $000F, $E000          ;VONM 0,1

GSB2AR:
L3962:  .word $40F1                 ;VONM -3,0

GSB1R:
L3964:  .word $1FF1, (OFF*$2000)+((0*M_/D_)&$1FFF) ;VOFFM 0,-1
L3968:  .word $000F, $E000          ;VONM 0,1

GSB1AR:
L396C:  .word $40F1                 ;VONM -3,0
L396E:  .word $C000                 ;RTSL

VLG0L:
;LEFT SIDE
;DO JUST THE BASE LINE
;#A IS LESS DRAW (DOES # WITHOUT THE TIC)
L3970:  .word $C000                 ;RTSL

VLG1AL:
L3972:  .word $4011                 ;VOFFM -3,0
L3974:  .word (((GSB1AL-VGBASE)/2)&$1FFF)+$E000 ;JMPL GSB1AL

VLG1L:
L3976:  .word $4011                 ;VOFFM -3,0
L3978:  .word (((GSB1L-VGBASE)/2)&$1FFF)+$E000 ;JMPL GSB1L

VLG2AL:
L397A:  .word (0*M_*MASP/DASP/D_)&$1FFF, $1FC4 ;VOFFM -6,0
L397E:  .word (((GSB2AL-VGBASE)/2)&$1FFF)+$E000 ;JMPL GSB2AL

VLG2L:
L3980:  .word (0*M_*MASP/DASP/D_)&$1FFF, $1FC4 ;VOFFM -6,0
L3984:  .word (((GSB2L-VGBASE)/2)&$1FFF)+$E000 ;JMPL GSB2L

VLG3AL:
L3986:  .word (0*M_*MASP/DASP/D_)&$1FFF, $1FA6 ;VOFFM -9,0
L398A:  .word (((GSB3AL-VGBASE)/2)&$1FFF)+$E000 ;JMPL GSB3AL

VLG3L:
L398C:  .word (0*M_*MASP/DASP/D_)&$1FFF, $1FA6 ;VOFFM -9,0
L3990:  .word (((GSB3L-VGBASE)/2)&$1FFF)+$E000 ;JMPL GSB3L

VLG4AL:
L3992:  .word (0*M_*MASP/DASP/D_)&$1FFF, $1F88 ;VOFFM -12.,0
L3996:  .word (((GSB4AL-VGBASE)/2)&$1FFF)+$E000 ;JMPL GSB4AL

VLG4L:
L3998:  .word (0*M_*MASP/DASP/D_)&$1FFF, $1F88 ;VOFFM -12.,0
L399C:  .word (((GSB4L-VGBASE)/2)&$1FFF)+$E000 ;JMPL GSB4L

VLG5AL:
L399E:  .word (0*M_*MASP/DASP/D_)&$1FFF, $1F6A ;VOFFM -15.,0
L39A2:  .word (((GSB5AL-VGBASE)/2)&$1FFF)+$E000 ;JMPL GSB5AL

VLG5L:
L39A4:  .word (0*M_*MASP/DASP/D_)&$1FFF, $1F6A ;VOFFM -15.,0
L39A8:  .word (((GSB5L-VGBASE)/2)&$1FFF)+$E000 ;JMPL GSB5L

VLG6AL:
L39AA:  .word (0*M_*MASP/DASP/D_)&$1FFF, $1F4C ;VOFFM -18.,0
L39AE:  .word (((GSB6AL-VGBASE)/2)&$1FFF)+$E000 ;JMPL GSB6AL

VLG6L:
L39B0:  .word (0*M_*MASP/DASP/D_)&$1FFF, $1F4C ;VOFFM -18.,0
L39B4:  .word (((GSB6L-VGBASE)/2)&$1FFF)+$E000 ;JMPL GSB6L

VLG7AL:
L39B6:  .word (0*M_*MASP/DASP/D_)&$1FFF, $1F2E ;VOFFM -21.,0
L39BA:  .word (((GSB7AL-VGBASE)/2)&$1FFF)+$E000 ;JMPL GSB7AL

VLG7L:
L39BC:  .word (0*M_*MASP/DASP/D_)&$1FFF, $1F2E ;VOFFM -21.,0
L39C0:  .word (((GSB7L-VGBASE)/2)&$1FFF)+$E000 ;JMPL GSB7L

VLG8AL:
L39C2:  .word (0*M_*MASP/DASP/D_)&$1FFF, $1F10 ;VOFFM -24.,0
L39C6:  .word (((GSB8AL-VGBASE)/2)&$1FFF)+$E000 ;JMPL GSB8AL

VLG8L:
L39C8:  .word (0*M_*MASP/DASP/D_)&$1FFF, $1F10 ;VOFFM -24.,0
L39CC:  .word (((GSB8L-VGBASE)/2)&$1FFF)+$E000 ;JMPL GSB8L

VLG9AL:
L39CE:  .word (0*M_*MASP/DASP/D_)&$1FFF, $1F10 ;VOFFM -24.,0
L39D2:  .word (((GSB9AL-VGBASE)/2)&$1FFF)+$E000 ;JMPL GSB9AL

VLG9L:
L39D4:  .word (0*M_*MASP/DASP/D_)&$1FFF, $1F10 ;VOFFM -24.,0
L39D8:  .word (((GSB9L-VGBASE)/2)&$1FFF)+$E000 ;JMPL GSB9L

VLGA0L:
;DO ALL OF DISPLAY, BRITE OUT TO EDGE UP
L39DA:  .word $C000                 ;RTSL

VLGA1L:
L39DC:  .word $1FF1, $FFE2          ;VONM -3,-1
L39E0:  .word (((GSU1L-VGBASE)/2)&$1FFF)+$E000 ;JMPL GSU1L

VLGA2L:
L39E2:  .word $1FE2, $FFC4          ;VONM -6,-2
L39E6:  .word (((GSU2L-VGBASE)/2)&$1FFF)+$E000 ;JMPL GSU2L

VLGA3L:
L39E8:  .word $1FD3, $FFA6          ;VONM -9,-3
L39EC:  .word (((GSU3L-VGBASE)/2)&$1FFF)+$E000 ;JMPL GSU3L

VLGA4L:
L39EE:  .word $1FC4, $FF88          ;VONM -12.,-4
L39F2:  .word (((GSU4L-VGBASE)/2)&$1FFF)+$E000 ;JMPL GSU4L

VLGA5L:
L39F4:  .word $1FB5, $FF6A          ;VONM -15.,-5
L39F8:  .word (((GSU5L-VGBASE)/2)&$1FFF)+$E000 ;JMPL GSU5L

VLGA6L:
L39FA:  .word $1FA6, $FF4C          ;VONM -18.,-6
L39FE:  .word (((GSU6L-VGBASE)/2)&$1FFF)+$E000 ;JMPL GSU6L

VLGA7L:
L3A00:  .word $1F97, $FF2E          ;VONM -21.,-7
L3A04:  .word (((GSU7L-VGBASE)/2)&$1FFF)+$E000 ;JMPL GSU7L

VLGA8L:
L3A06:  .word $1F88, $FF10          ;VONM -24.,-8
L3A0A:  .word (((GSU8L-VGBASE)/2)&$1FFF)+$E000 ;JMPL GSU8L

VLGA9L:
L3A0C:  .word $1F79, $FEF2          ;VONM -27.,-9
L3A10:  .word (((GSU9L-VGBASE)/2)&$1FFF)+$E000 ;JMPL GSU9L

VLGU0L:
;UPSTROKE, BLANK DOWN TOP THEN DO FULL EDGE UP
;GSU* DOES ASSUMES IN CORRECT POSITION FOR UPSTROKE
L3A12:  .word $C000                 ;RTSL

VLGU1L:
L3A14:  .word $1FF1, $1FE2          ;VOFFM -3,-1

GSU1L:
L3A18:  .word $000F, $E000          ;VONM 0,1
L3A1C:  .word (((GSB1AL-VGBASE)/2)&$1FFF)+$E000 ;JMPL GSB1AL

VLGU2L:
L3A1E:  .word $1FE2, $1FC4          ;VOFFM -6,-2

GSU2L:
L3A22:  .word $4FE0                 ;VONM 0,2
L3A24:  .word (((GSB2AL-VGBASE)/2)&$1FFF)+$E000 ;JMPL GSB2AL

VLGU3L:
L3A26:  .word $1FD3, $1FA6          ;VOFFM -9,-3

GSU3L:
L3A2A:  .word $002D, $E000          ;VONM 0,3
L3A2E:  .word (((GSB3AL-VGBASE)/2)&$1FFF)+$E000 ;JMPL GSB3AL

VLGU4L:
L3A30:  .word $1FC4, $1F88          ;VOFFM -12.,-4

GSU4L:
L3A34:  .word $003C, $E000          ;VONM 0,4
L3A38:  .word (((GSB4AL-VGBASE)/2)&$1FFF)+$E000 ;JMPL GSB4AL

VLGU5L:
L3A3A:  .word $1FB5, $1F6A          ;VOFFM -15.,-5

GSU5L:
L3A3E:  .word $004B, $E000          ;VONM 0,5
L3A42:  .word (((GSB5AL-VGBASE)/2)&$1FFF)+$E000 ;JMPL GSB5AL

VLGU6L:
L3A44:  .word $1FA6, $1F4C          ;VOFFM -18.,-6

GSU6L:
L3A48:  .word $005A, $E000          ;VONM 0,6
L3A4C:  .word (((GSB6AL-VGBASE)/2)&$1FFF)+$E000 ;JMPL GSB6AL

VLGU7L:
L3A4E:  .word $1F97, $1F2E          ;VOFFM -21.,-7

GSU7L:
L3A52:  .word $0069, $E000          ;VONM 0,7
L3A56:  .word (((GSB7AL-VGBASE)/2)&$1FFF)+$E000 ;JMPL GSB7AL

VLGU8L:
L3A58:  .word $1F88, $1F10          ;VOFFM -24.,-8

GSU8L:
L3A5C:  .word $0078, $E000          ;VONM 0,8
L3A60:  .word (((GSB8AL-VGBASE)/2)&$1FFF)+$E000 ;JMPL GSB8AL

VLGU9L:
L3A62:  .word $1F79, $1EF2          ;VOFFM -27.,-9

GSU9L:
L3A66:  .word $0087, $E000          ;VONM 0,9
L3A6A:  .word (((GSB9AL-VGBASE)/2)&$1FFF)+$E000 ;JMPL GSB9AL

GSB9L:
;GSB* DOES BASE LINE FROM OUTWARD ON BACK
;# ==> PARTIAL UPSTROKE FOLLOWED BY BASELINE
;#A ==> NO UPSTROKE, JUST BASELINE
L3A6C:  .word $1F79, (OFF*$2000)+((0*M_/D_)&$1FFF) ;VOFFM 0,-9
L3A70:  .word $0087, $E000          ;VONM 0,9

GSB9AL:
L3A74:  .word $40EF                 ;VONM 3,0

GSB8L:
L3A76:  .word $1FF1, (OFF*$2000)+((0*M_/D_)&$1FFF) ;VOFFM 0,-1
L3A7A:  .word $000F, $E000          ;VONM 0,1

GSB8AL:
L3A7E:  .word $40EF                 ;VONM 3,0

GSB7L:
L3A80:  .word $1FF1, (OFF*$2000)+((0*M_/D_)&$1FFF) ;VOFFM 0,-1
L3A84:  .word $000F, $E000          ;VONM 0,1

GSB7AL:
L3A88:  .word $40EF                 ;VONM 3,0

GSB6L:
L3A8A:  .word $1FA6, (OFF*$2000)+((0*M_/D_)&$1FFF) ;VOFFM 0,-6
L3A8E:  .word $005A, $E000          ;VONM 0,6

GSB6AL:
L3A92:  .word $40EF                 ;VONM 3,0

GSB5L:
L3A94:  .word $1FF1, (OFF*$2000)+((0*M_/D_)&$1FFF) ;VOFFM 0,-1
L3A98:  .word $000F, $E000          ;VONM 0,1

GSB5AL:
L3A9C:  .word $40EF                 ;VONM 3,0

GSB4L:
L3A9E:  .word $1FF1, (OFF*$2000)+((0*M_/D_)&$1FFF) ;VOFFM 0,-1
L3AA2:  .word $000F, $E000          ;VONM 0,1

GSB4AL:
L3AA6:  .word $40EF                 ;VONM 3,0

GSB3L:
L3AA8:  .word $1FD3, (OFF*$2000)+((0*M_/D_)&$1FFF) ;VOFFM 0,-3
L3AAC:  .word $002D, $E000          ;VONM 0,3

GSB3AL:
L3AB0:  .word $40EF                 ;VONM 3,0

GSB2L:
L3AB2:  .word $1FF1, (OFF*$2000)+((0*M_/D_)&$1FFF) ;VOFFM 0,-1
L3AB6:  .word $000F, $E000          ;VONM 0,1

GSB2AL:
L3ABA:  .word $40EF                 ;VONM 3,0

GSB1L:
L3ABC:  .word $1FF1, (OFF*$2000)+((0*M_/D_)&$1FFF) ;VOFFM 0,-1
L3AC0:  .word $000F, $E000          ;VONM 0,1

GSB1AL:
L3AC4:  .word $40EF                 ;VONM 3,0
L3AC6:  .word $C000                 ;RTSL

;.SBTTL DEATH STAR PICS ( DETAILED AND MINIATURE )

BSHEM:
L3AC8:  .word $6280                 ;COLOR VGCGRN
L3ACA:  .word $1E20, $0620          ;AOFF 49,-10  DO PREVIOUS POINT
L3ACE:  .word (((BSHEM2-VGBASE)/2)&$1FFF)+$E000 ;JMPL BSHEM2  THEN DO THE REST

BSCIR:
L3AD0:  .word $6280                 ;COLOR VGCGRN
L3AD2:  .word $1E20, $19E0          ;AOFF -49,-10
L3AD6:  .word $1E20, $A060          ;AON -46,-20,5
L3ADA:  .word $1E20, $A0C0          ;AON -40,-30,5
L3ADE:  .word $1E20, $A140          ;AON -30,-40,5
L3AE2:  .word $1EE0, $A140          ;AON -20,-46,5
L3AE6:  .word $1F70, $A140          ;AON -10,-49,5
L3AEA:  .word $1FD0, $A140          ;AON 0,-50,5
L3AEE:  .word $0030, $A140          ;AON 10,-49,5
L3AF2:  .word $0090, $A140          ;AON 20,-46,5
L3AF6:  .word $0120, $A140          ;AON 30,-40,5
L3AFA:  .word $01E0, $A140          ;AON 40,-30,5
L3AFE:  .word $01E0, $C0C0          ;AON 46,-20,6
L3B02:  .word $01E0, $C060          ;AON 49,-10,6

BSHEM2:
L3B06:  .word $01E0, $E020          ;AON 50,0,7
L3B0A:  .word $01E0, $FFE0          ;AON 49,10,7
L3B0E:  .word $01E0, $FFA0          ;AON 46,20,7
L3B12:  .word $01E0, $FF40          ;AON 40,30,7
L3B16:  .word $01E0, $FEC0          ;AON 30,40,7
L3B1A:  .word $0120, $FEC0          ;AON 20,46,7
L3B1E:  .word $0090, $DEC0          ;AON 10,49,6
L3B22:  .word $0030, $DEC0          ;AON 0,50,6
L3B26:  .word $1FD0, $BEC0          ;AON -10,49,5
L3B2A:  .word $1F70, $BEC0          ;AON -20,46,5
L3B2E:  .word $1EE0, $BEC0          ;AON -30,40,5
L3B32:  .word $1E20, $BEC0          ;AON -40,30,5
L3B36:  .word $1E20, $BF40          ;AON -46,20,5
L3B3A:  .word $1E20, $BFA0          ;AON -49,10,5
L3B3E:  .word $1E20, $BFE0          ;AON -50,0,5
L3B42:  .word $1E20, $A020          ;AON -49,-10,5
L3B46:  .word VGSCAL                ;SCAL
L3B48:  .word VGCNTR                ;CNTR
L3B4A:  .word $C000                 ;RTSL

BSTRN:
;BASE TRENCH
L3B4C:  .word $6780                 ;COLOR VGCWHT
L3B4E:  .word $01E0, $0620          ;AOFF 49,10
L3B52:  .word $1C70, $D3C0          ;AON -49,-9,6
L3B56:  .word $1FD0, $0000          ;AOFF -49,-10
L3B5A:  .word $0390, $CC40          ;AON 49,9,6
L3B5E:  .word VGSCAL                ;SCAL
L3B60:  .word VGCNTR                ;CNTR
L3B62:  .word $C000                 ;RTSL

BSDSH:
;BASE DISH OUTLINE
L3B64:  .word $6480                 ;COLOR VGCRED
L3B66:  .word $0330, $0280          ;AOFF 20,17
L3B6A:  .word $0060, $DF80          ;AON 16,19,6
L3B6E:  .word $0090, $DFA0          ;AON 13,22,6
L3B72:  .word $00C0, $DFC0          ;AON 11,26,6
L3B76:  .word $00C0, $DFE0          ;AON 10,30,6
L3B7A:  .word $00C0, $C020          ;AON 11,34,6
L3B7E:  .word $0090, $C060          ;AON 14,37,6
L3B82:  .word $0030, $C080          ;AON 18,38,6
L3B86:  .word $0000, $C080          ;AON 22,38,6
L3B8A:  .word $1FA0, $C080          ;AON 26,36,6
L3B8E:  .word $1F40, $C080          ;AON 30,32,6
L3B92:  .word $1F40, $C060          ;AON 33,28,6
L3B96:  .word $1F40, $C020          ;AON 34,24,6
L3B9A:  .word $1F40, $DFE0          ;AON 33,20,6
L3B9E:  .word $1F70, $DFA0          ;AON 30,17,6
L3BA2:  .word $1FD0, $DF80          ;AON 26,16,6
L3BA6:  .word $0000, $DFA0          ;AON 23,16,6
L3BAA:  .word $0030, $DFA0          ;AON 20,17,6
L3BAE:  .word VGSCAL                ;SCAL
L3BB0:  .word VGCNTR                ;CNTR
L3BB2:  .word $C000                 ;RTSL

BSNSD:
;BASE INSIDE DISH
L3BB4:  .word $6480                 ;COLOR VGCRED
L3BB6:  .word $0330, $0280          ;AOFF 20,17
L3BBA:  .word $01E0, $A040          ;AON 22,27,5
L3BBE:  .word $1E80, $BF40          ;AON 16,19,5
L3BC2:  .word $0090, $1FA0          ;AOFF 13,22
L3BC6:  .word $00F0, $A120          ;AON 22,27,5
L3BCA:  .word $1FD0, $BEA0          ;AON 11,26,5
L3BCE:  .word $00C0, $1FE0          ;AOFF 10,30
L3BD2:  .word $1F70, $A180          ;AON 22,27,5
L3BD6:  .word $0150, $BEA0          ;AON 11,34,5
L3BDA:  .word $0090, $0060          ;AOFF 14,37
L3BDE:  .word $1E20, $A100          ;AON 22,27,5
L3BE2:  .word $0210, $BF80          ;AON 18,38,5
L3BE6:  .word $0000, $0080          ;AOFF 22,38
L3BEA:  .word $1DF0, $A000          ;AON 22,27,5
L3BEE:  .word $01B0, $A080          ;AON 26,36,5
L3BF2:  .word $1C70, $0080          ;AOFF 30,17
L3BF6:  .word $01E0, $BF00          ;AON 22,27,5
L3BFA:  .word $1DF0, $A080          ;AON 26,16,5
L3BFE:  .word $0000, $1FA0          ;AOFF 23,16
L3C02:  .word $0210, $BFE0          ;AON 22,27,5
L3C06:  .word VGSCAL                ;SCAL
L3C08:  .word VGCNTR                ;CNTR
L3C0A:  .word $C000                 ;RTSL

BSFRM:
;BASE FARMLAND
L3C0C:  .word $6280                 ;COLOR VGCGRN
L3C0E:  .word $08D0, $01E0          ;AOFF 15,47
L3C12:  .word $1F40, $A040          ;AON 17,43,5
L3C16:  .word $0030, $A080          ;AON 21,44,5
L3C1A:  .word $0030, $0000          ;AOFF 21,45
L3C1E:  .word $1EB0, $A060          ;AON 24,38,5
L3C22:  .word $0060, $1FE0          ;AOFF 23,40
L3C26:  .word $0030, $A080          ;AON 27,41,5
L3C2A:  .word $1E80, $A060          ;AON 30,33,5
L3C2E:  .word $00C0, $0040          ;AOFF 32,37
L3C32:  .word $1AF0, $A180          ;AON 44,10,5
L3C36:  .word $0030, $A080          ;AON 48,11,5
L3C3A:  .word $0390, $BEE0          ;AON 39,30,5
L3C3E:  .word $1DF0, $0020          ;AOFF 40,19
L3C42:  .word $1FD0, $BF80          ;AON 36,18,5
L3C46:  .word $00F0, $1FC0          ;AOFF 34,23
L3C4A:  .word $1E20, $A080          ;AON 38,13,5
L3C4E:  .word $1FD0, $BF80          ;AON 34,12,5
L3C52:  .word $00F0, $BFC0          ;AON 32,17,5
L3C56:  .word $1F10, $0040          ;AOFF 34,12
L3C5A:  .word $1FD0, $BF80          ;AON 30,11,5
L3C5E:  .word $00F0, $BFC0          ;AON 28,16,5
L3C62:  .word $1C10, $0140          ;AOFF 38,-5
L3C66:  .word $0150, $BFC0          ;AON 36,2,5
L3C6A:  .word $0030, $A080          ;AON 40,3,5
L3C6E:  .word $0030, $0080          ;AOFF 44,4
L3C72:  .word $0030, $A080          ;AON 48,5,5
L3C76:  .word $1EE0, $A040          ;AON 50,-1,5
L3C7A:  .word $1E20, $1FC0          ;AOFF 48,-11
L3C7E:  .word $0360, $BF60          ;AON 43,7,5
L3C82:  .word $1FD0, $BF80          ;AON 39,6,5
L3C86:  .word $1B80, $A0E0          ;AON 46,-18,5
L3C8A:  .word $00F0, $0040          ;AOFF 48,-13
L3C8E:  .word $1FD0, $BFA0          ;AON 45,-14,5
L3C92:  .word $00F0, $1F60          ;AOFF 40,-9
L3C96:  .word $0030, $A060          ;AON 43,-8,5
L3C9A:  .word VGSCAL                ;SCAL
L3C9C:  .word VGCNTR                ;CNTR
L3C9E:  .word $C000                 ;RTSL

BMIN:
L3CA0:  .word $6780                 ;COLOR VGCWHT
L3CA2:  .word $000F, $0031          ;AOFF 49,10
L3CA6:  .word $1FE2, $DF9E          ;AON -49,-10,6
L3CAA:  .word $6280                 ;COLOR VGCGRN
L3CAC:  .word $1FE2, $A009          ;AON -40,-30,5
L3CB0:  .word $54AA                 ;AON -20,-46,5
L3CB2:  .word $5DAA                 ;AON 0,-50,5
L3CB4:  .word $43AA                 ;AON 20,-46,5
L3CB6:  .word $4CAA                 ;AON 40,-30,5
L3CB8:  .word $001E, $C009          ;AON 49,-10,6
L3CBC:  .word $4FE0                 ;AON 49,10,7
L3CBE:  .word $001E, $FFF7          ;AON 40,30,7
L3CC2:  .word $4CF6                 ;AON 20,46,7
L3CC4:  .word $43D6                 ;AON 0,50,6
L3CC6:  .word $5DB6                 ;AON -20,46,5
L3CC8:  .word $54B6                 ;AON -40,30,5
L3CCA:  .word $1FE2, $BFF7          ;AON -49,10,5
L3CCE:  .word $51A0                 ;AON -49,-10,5
;DISH OUTLINE
L3CD0:  .word $6480                 ;COLOR VGCRED
L3CD2:  .word $002D, $0052          ;AOFF 33,20
L3CD6:  .word $1FFA, $DFF9          ;AON 26,16,6
L3CDA:  .word $0001, $DFFA          ;AON 20,17,6
L3CDE:  .word $0008, $DFF9          ;AON 13,22,6
L3CE2:  .word $000C, $DFFD          ;AON 10,30,6
L3CE6:  .word $45C2                 ;AON 14,37,6
L3CE8:  .word $41C4                 ;AON 22,38,6
L3CEA:  .word $1FF1, $C00B          ;AON 33,28,6
L3CEE:  .word $5AC0                 ;AON 33,20,6
;INSIDE DISH
L3CF0:  .word $6480                 ;COLOR VGCRED
L3CF2:  .word $0015, $BFEA          ;AON 11,34,5
L3CF6:  .word $0006, $000B          ;AOFF 22,38
L3CFA:  .word $50A0                 ;AON 22,17,5
L3CFC:  .word $0008, $1FF7          ;AOFF 13,22
L3D00:  .word $0007, $A009          ;AON 22,27,5
;FARMLAND
L3D04:  .word $6280                 ;COLOR VGCGRN
L3D06:  .word $0018, $1FFB          ;AOFF 17,43
L3D0A:  .word $1FF7, $A00F          ;AON 32,37,5
L3D0E:  .word $1FE5, $A008          ;AON 40,19,5
L3D12:  .word $5ABB                 ;AON 30,11,5
L3D14:  .word $5A05                 ;AOFF 40,3
L3D16:  .word $1FE1, $A006          ;AON 46,-18,5
L3D1A:  .word VGSCAL                ;SCAL
L3D1C:  .word VGCNTR                ;CNTR
L3D1E:  .word $C000                 ;RTSL

;.SBTTL SELFTEST-COLOR BARS
L3D20:  .word $0000, (2*$2000)+(INLEN&$1FFF) ;VCTR INLEN,0,2
L3D24:  .word SEPY&$1FFF, (OFF*$2000)+(-INLEN&$1FFF) ;VCTR -INLEN,SEPY,OFF
L3D28:  .word $0000, (3*$2000)+(INLEN&$1FFF) ;VCTR INLEN,0,3
L3D2C:  .word SEPY&$1FFF, (OFF*$2000)+(-INLEN&$1FFF) ;VCTR -INLEN,SEPY,OFF
L3D30:  .word $0000, (4*$2000)+(INLEN&$1FFF) ;VCTR INLEN,0,4
L3D34:  .word SEPY&$1FFF, (OFF*$2000)+(-INLEN&$1FFF) ;VCTR -INLEN,SEPY,OFF
L3D38:  .word $0000, (5*$2000)+(INLEN&$1FFF) ;VCTR INLEN,0,5
L3D3C:  .word SEPY&$1FFF, (OFF*$2000)+(-INLEN&$1FFF) ;VCTR -INLEN,SEPY,OFF
L3D40:  .word $0000, (6*$2000)+(INLEN&$1FFF) ;VCTR INLEN,0,6
L3D44:  .word SEPY&$1FFF, (OFF*$2000)+(-INLEN&$1FFF) ;VCTR -INLEN,SEPY,OFF
L3D48:  .word $0000, (7*$2000)+(INLEN&$1FFF) ;VCTR INLEN,0,7
L3D4C:  .word $C000                 ;RTSL
;CREATES AN EQUATE EQUIVILENT TO A JSRL .+2
L3D4E:  .word (((BONDRY-VGBASE)/2)&$1FFF)+$A000 ;JSRL BONDRY
L3D50:  .word VGCNTR                ;CNTR
L3D52:  .word (SEPY*4)&$1FFF, (OFF*$2000)+(-(INLEN/2*3)&$1FFF) ;VCTR -<INLEN/2*3>,SEPY*4,OFF
L3D56:  .word $6480                 ;COLOR VGCRED
L3D58:  .word (((SEVEN-VGBASE)/2)&$1FFF)+$A000 ;JSRL SEVEN
L3D5A:  .word VGCNTR                ;CNTR
L3D5C:  .word (SEPY*4)&$1FFF, (OFF*$2000)+(-(INLEN/2)&$1FFF) ;VCTR -<INLEN/2>,SEPY*4,OFF
L3D60:  .word $6180                 ;COLOR VGCBLU
L3D62:  .word (((SEVEN-VGBASE)/2)&$1FFF)+$A000 ;JSRL SEVEN
L3D64:  .word VGCNTR                ;CNTR
L3D66:  .word (SEPY*4)&$1FFF, (OFF*$2000)+((INLEN/2)&$1FFF) ;VCTR <INLEN/2>,SEPY*4,OFF
L3D6A:  .word $6280                 ;COLOR VGCGRN
L3D6C:  .word (((SEVEN-VGBASE)/2)&$1FFF)+$A000 ;JSRL SEVEN
L3D6E:  .word VGCNTR                ;CNTR
L3D70:  .word (-SEPY*10)&$1FFF, (OFF*$2000)+(-(INLEN/2*3)&$1FFF) ;VCTR -<INLEN/2*3>,-SEPY*10.,OFF
L3D74:  .word $6680                 ;COLOR VGCYLW
L3D76:  .word (((SEVEN-VGBASE)/2)&$1FFF)+$A000 ;JSRL SEVEN
L3D78:  .word VGCNTR                ;CNTR
L3D7A:  .word (-SEPY*10)&$1FFF, (OFF*$2000)+(-(INLEN/2)&$1FFF) ;VCTR -<INLEN/2>,-SEPY*10.,OFF
L3D7E:  .word $6380                 ;COLOR VGCTRQ
L3D80:  .word (((SEVEN-VGBASE)/2)&$1FFF)+$A000 ;JSRL SEVEN
L3D82:  .word VGCNTR                ;CNTR
L3D84:  .word (-SEPY*10)&$1FFF, (OFF*$2000)+((INLEN/2)&$1FFF) ;VCTR <INLEN/2>,-SEPY*10.,OFF
L3D88:  .word $6580                 ;COLOR VGCPRP
L3D8A:  .word (((SEVEN-VGBASE)/2)&$1FFF)+$A000 ;JSRL SEVEN
L3D8C:  .word VGCNTR                ;CNTR
L3D8E:  .word (-SEPY*3)&$1FFF, (OFF*$2000)+(-(INLEN/2)&$1FFF) ;VCTR -<INLEN/2>,-SEPY*3,OFF
L3D92:  .word $6780                 ;COLOR VGCWHT
;VCTR INLEN,0,2 ;THIS DRAWS DIMMEST LINE NORMALLY
;VCTR -INLEN-40,SEPY,OFF ;POSITION FOR LONGER LINE OF NEXT BRIGHTNESS
;VCTR INLEN+40,0,3 ;DRAW THE LONGER LINE
;JMPL SEVEN2 ;DO THE REST NORMALLY
L3D94:  .word (((SEVEN-VGBASE)/2)&$1FFF)+$A000 ;JSRL SEVEN  NO LONGER DO A LONGER LINE
L3D96:  .word VGCNTR                ;CNTR
;NOW DO 9 BARS USING COLOR Z= 0 TO 80
L3D98:  .word (-SEPY*12)&$1FFF, (OFF*$2000)+((INLEN/2)&$1FFF) ;VCTR <INLEN/2>,-SEPY*12.,OFF  BELOW AND TO THE RIGHT
L3D9C:  .word $6700                 ;COLOR VGCWHT,00
L3D9E:  .word $0000, (ON*$2000)+(INLEN&$1FFF) ;VCTR INLEN,0,ON
L3DA2:  .word (-SEPY-4)&$1FFF, (OFF*$2000)+(-INLEN&$1FFF) ;VCTR -INLEN,-SEPY-4,OFF
L3DA6:  .word $6710                 ;COLOR VGCWHT,10
L3DA8:  .word $0000, (ON*$2000)+(INLEN&$1FFF) ;VCTR INLEN,0,ON
L3DAC:  .word (-SEPY-4)&$1FFF, (OFF*$2000)+(-INLEN&$1FFF) ;VCTR -INLEN,-SEPY-4,OFF
L3DB0:  .word $6720                 ;COLOR VGCWHT,20
L3DB2:  .word $0000, (ON*$2000)+(INLEN&$1FFF) ;VCTR INLEN,0,ON
L3DB6:  .word (-SEPY-4)&$1FFF, (OFF*$2000)+(-INLEN&$1FFF) ;VCTR -INLEN,-SEPY-4,OFF
L3DBA:  .word $6730                 ;COLOR VGCWHT,30
L3DBC:  .word $0000, (ON*$2000)+(INLEN&$1FFF) ;VCTR INLEN,0,ON
L3DC0:  .word (-SEPY-4)&$1FFF, (OFF*$2000)+(-INLEN&$1FFF) ;VCTR -INLEN,-SEPY-4,OFF
L3DC4:  .word $6740                 ;COLOR VGCWHT,40
L3DC6:  .word $0000, (ON*$2000)+(INLEN&$1FFF) ;VCTR INLEN,0,ON
L3DCA:  .word (-SEPY-4)&$1FFF, (OFF*$2000)+(-INLEN&$1FFF) ;VCTR -INLEN,-SEPY-4,OFF
L3DCE:  .word $6750                 ;COLOR VGCWHT,50
L3DD0:  .word $0000, (ON*$2000)+(INLEN&$1FFF) ;VCTR INLEN,0,ON
L3DD4:  .word (-SEPY-4)&$1FFF, (OFF*$2000)+(-INLEN&$1FFF) ;VCTR -INLEN,-SEPY-4,OFF
L3DD8:  .word $6760                 ;COLOR VGCWHT,60
L3DDA:  .word $0000, (ON*$2000)+(INLEN&$1FFF) ;VCTR INLEN,0,ON
L3DDE:  .word (-SEPY-4)&$1FFF, (OFF*$2000)+(-INLEN&$1FFF) ;VCTR -INLEN,-SEPY-4,OFF
L3DE2:  .word $6770                 ;COLOR VGCWHT,70
L3DE4:  .word $0000, (ON*$2000)+(INLEN&$1FFF) ;VCTR INLEN,0,ON
L3DE8:  .word (-SEPY-4)&$1FFF, (OFF*$2000)+(-INLEN&$1FFF) ;VCTR -INLEN,-SEPY-4,OFF
L3DEC:  .word $6780                 ;COLOR VGCWHT,80
L3DEE:  .word $0000, (ON*$2000)+(INLEN&$1FFF) ;VCTR INLEN,0,ON
L3DF2:  .word (-SEPY-4)&$1FFF, (OFF*$2000)+(-INLEN&$1FFF) ;VCTR -INLEN,-SEPY-4,OFF
L3DF6:  .word VGCNTR                ;CNTR
L3DF8:  .word $C000                 ;RTSL

;.SBTTL SELFTEST-CROSSHATCH AND ALPHA/NUMERICS
L3DFA:  .word (((BONDRY-VGBASE)/2)&$1FFF)+$A000 ;JSRL BONDRY  EDGE OF SCREEN (END UP IN LOWER LEFT CORNER)
L3DFC:  .word VGCNTR                ;CNTR
L3DFE:  .word $1DD8, $1E20          ;SCVEC -MAX,-MAY,OFF
L3E02:  .word $0450, $E2D0          ;SCVEC MAX/2,MAY,ON
L3E06:  .word $1E90, $E0F0          ;SCVEC MAX,MAY/3,ON
L3E0A:  .word $1D20, $FE20          ;SCVEC 0,-MAY,ON
L3E0E:  .word $02E0, $FE20          ;SCVEC -MAX,MAY/3,ON
L3E12:  .word $0170, $E0F0          ;SCVEC -MAX/2,MAY,ON
L3E16:  .word $1BB0, $E2D0          ;SCVEC MAX,-MAY,ON
L3E1A:  .word $0450, $0000          ;SCVEC MAX,MAY,OFF
L3E1E:  .word $1BB0, $FD30          ;SCVEC -MAX/2,-MAY,ON
L3E22:  .word $0170, $FF10          ;SCVEC -MAX,-MAY/3,ON
L3E26:  .word $02E0, $E1E0          ;SCVEC 0,MAY,ON
L3E2A:  .word $1D20, $E1E0          ;SCVEC MAX,-MAY/3,ON
L3E2E:  .word $1E90, $FF10          ;SCVEC MAX/2,-MAY,ON
L3E32:  .word $0450, $FD30          ;SCVEC -MAX,MAY,ON
L3E36:  .word VGCNTR                ;CNTR
L3E38:  .word $1E9A, (OFF*$2000)+(-480&$1FFF) ;VCTR -480.,-358.,OFF
L3E3C:  .word $7240                 ;SCAL 2,40
L3E3E:  .word (((VGMSGA-VGBASE)/2)&$1FFF)+$E000 ;JMPL VGMSGA  GO DO ALPHABET

;.SBTTL SELFTEST-CHECKERBOARD PIC.
L3E40:  .word VGSCAL                ;SCAL
L3E42:  .word VGCNTR                ;.REPT NLINES
L3E44:  .word $1DF1, (OFF*$2000)+(XSCRN&$1FFF)
L3E48:  .word $0000, (ON*$2000)+((-2*XSCRN)&$1FFF)
L3E4C:  .word VGCNTR
L3E4E:  .word $1E51, (OFF*$2000)+(XSCRN&$1FFF)
L3E52:  .word $0000, (ON*$2000)+((-2*XSCRN)&$1FFF)
L3E56:  .word VGCNTR
L3E58:  .word $1EB1, (OFF*$2000)+(XSCRN&$1FFF)
L3E5C:  .word $0000, (ON*$2000)+((-2*XSCRN)&$1FFF)
L3E60:  .word VGCNTR
L3E62:  .word $1F11, (OFF*$2000)+(XSCRN&$1FFF)
L3E66:  .word $0000, (ON*$2000)+((-2*XSCRN)&$1FFF)
L3E6A:  .word VGCNTR
L3E6C:  .word $1F71, (OFF*$2000)+(XSCRN&$1FFF)
L3E70:  .word $0000, (ON*$2000)+((-2*XSCRN)&$1FFF)
L3E74:  .word VGCNTR
L3E76:  .word $1FD1, (OFF*$2000)+(XSCRN&$1FFF)
L3E7A:  .word $0000, (ON*$2000)+((-2*XSCRN)&$1FFF)
L3E7E:  .word VGCNTR
L3E80:  .word $0031, (OFF*$2000)+(XSCRN&$1FFF)
L3E84:  .word $0000, (ON*$2000)+((-2*XSCRN)&$1FFF)
L3E88:  .word VGCNTR
L3E8A:  .word $0091, (OFF*$2000)+(XSCRN&$1FFF)
L3E8E:  .word $0000, (ON*$2000)+((-2*XSCRN)&$1FFF)
L3E92:  .word VGCNTR
L3E94:  .word $00F1, (OFF*$2000)+(XSCRN&$1FFF)
L3E98:  .word $0000, (ON*$2000)+((-2*XSCRN)&$1FFF)
L3E9C:  .word VGCNTR
L3E9E:  .word $0151, (OFF*$2000)+(XSCRN&$1FFF)
L3EA2:  .word $0000, (ON*$2000)+((-2*XSCRN)&$1FFF)
L3EA6:  .word VGCNTR
L3EA8:  .word $01B1, (OFF*$2000)+(XSCRN&$1FFF)
L3EAC:  .word $0000, (ON*$2000)+((-2*XSCRN)&$1FFF)
L3EB0:  .word VGCNTR
L3EB2:  .word $0211, (OFF*$2000)+(XSCRN&$1FFF)
L3EB6:  .word $0000, (ON*$2000)+((-2*XSCRN)&$1FFF)
L3EBA:  .word VGCNTR                ;.REPT NLINES
L3EBC:  .word YSCRN&$1FFF, $1E21
L3EC0:  .word (-2*YSCRN)&$1FFF, (ON*$2000)+(0&$1FFF)
L3EC4:  .word VGCNTR
L3EC6:  .word YSCRN&$1FFF, $1E61
L3ECA:  .word (-2*YSCRN)&$1FFF, (ON*$2000)+(0&$1FFF)
L3ECE:  .word VGCNTR
L3ED0:  .word YSCRN&$1FFF, $1EA1
L3ED4:  .word (-2*YSCRN)&$1FFF, (ON*$2000)+(0&$1FFF)
L3ED8:  .word VGCNTR
L3EDA:  .word YSCRN&$1FFF, $1EE1
L3EDE:  .word (-2*YSCRN)&$1FFF, (ON*$2000)+(0&$1FFF)
L3EE2:  .word VGCNTR
L3EE4:  .word YSCRN&$1FFF, $1F21
L3EE8:  .word (-2*YSCRN)&$1FFF, (ON*$2000)+(0&$1FFF)
L3EEC:  .word VGCNTR
L3EEE:  .word YSCRN&$1FFF, $1F61
L3EF2:  .word (-2*YSCRN)&$1FFF, (ON*$2000)+(0&$1FFF)
L3EF6:  .word VGCNTR
L3EF8:  .word YSCRN&$1FFF, $1FA1
L3EFC:  .word (-2*YSCRN)&$1FFF, (ON*$2000)+(0&$1FFF)
L3F00:  .word VGCNTR
L3F02:  .word YSCRN&$1FFF, $1FE1
L3F06:  .word (-2*YSCRN)&$1FFF, (ON*$2000)+(0&$1FFF)
L3F0A:  .word VGCNTR
L3F0C:  .word YSCRN&$1FFF, $0021
L3F10:  .word (-2*YSCRN)&$1FFF, (ON*$2000)+(0&$1FFF)
L3F14:  .word VGCNTR
L3F16:  .word YSCRN&$1FFF, $0061
L3F1A:  .word (-2*YSCRN)&$1FFF, (ON*$2000)+(0&$1FFF)
L3F1E:  .word VGCNTR
L3F20:  .word YSCRN&$1FFF, $00A1
L3F24:  .word (-2*YSCRN)&$1FFF, (ON*$2000)+(0&$1FFF)
L3F28:  .word VGCNTR
L3F2A:  .word YSCRN&$1FFF, $00E1
L3F2E:  .word (-2*YSCRN)&$1FFF, (ON*$2000)+(0&$1FFF)
L3F32:  .word VGCNTR
L3F34:  .word YSCRN&$1FFF, $0121
L3F38:  .word (-2*YSCRN)&$1FFF, (ON*$2000)+(0&$1FFF)
L3F3C:  .word VGCNTR
L3F3E:  .word YSCRN&$1FFF, $0161
L3F42:  .word (-2*YSCRN)&$1FFF, (ON*$2000)+(0&$1FFF)
L3F46:  .word VGCNTR
L3F48:  .word YSCRN&$1FFF, $01A1
L3F4C:  .word (-2*YSCRN)&$1FFF, (ON*$2000)+(0&$1FFF)
L3F50:  .word VGCNTR
L3F52:  .word YSCRN&$1FFF, $01E1
L3F56:  .word (-2*YSCRN)&$1FFF, (ON*$2000)+(0&$1FFF)
L3F5A:  .word $C000                 ;RTSL

;.SBTTL SELFTEST-HYSTERESIS PIC
L3F5C:  .word $6250                 ;COLOR VGCGRN,50  SCREEN BOUNDARY
L3F5E:  .word VGSCAL                ;SCAL
L3F60:  .word VGCNTR                ;CNTR
L3F62:  .word -MAY&$1FFF, (OFF*$2000)+(-MAX&$1FFF) ;VCTR -MAX,-MAY,OFF
L3F66:  .word $0000, (ON*$2000)+((2*MAX)&$1FFF) ;VCTR 2*MAX,0,ON
L3F6A:  .word (2*MAY)&$1FFF, (ON*$2000)+(0&$1FFF) ;VCTR 0,2*MAY,ON
L3F6E:  .word $0000, (ON*$2000)+((-2*MAX)&$1FFF) ;VCTR -2*MAX,0,ON
L3F72:  .word (-2*MAY)&$1FFF, (ON*$2000)+(0&$1FFF) ;VCTR 0,-2*MAY,ON
L3F76:  .word $C000                 ;RTSL

;.SBTTL SELFTEST-SCALE PIC
L3F78:  .word $008A, $005C          ;AOFF 92,92  LETS DRAW A SQUARE
L3F7C:  .word $0000, $FF48          ;AON -92,92
L3F80:  .word $1EEC, $E000          ;AON -92,-92
L3F84:  .word $0000, $E0B8          ;AON 92,-92
L3F88:  .word $0114, $E000          ;AON 92,92
L3F8C:  .word VGCNTR                ;CNTR
L3F8E:  .word $C000                 ;RTSL

;.SBTTL SELFTEST-RASTER PICS
L3F90:  .word (((BOX-VGBASE)/2)&$1FFF)+$A000 ;JSRL BOX  DRAW BOX, AND GOTO LEFT SIDE OF SCREEN
L3F92:  .word VGCNTR                ;CNTR
L3F94:  .word $0100, (OFF*$2000)+(-MAX&$1FFF) ;VCTR -MAX,100,OFF
L3F98:  .word $0000, (ON*$2000)+((2*MAX)&$1FFF) ;VCTR 2*MAX,0,ON  DRAW LINE FROM LEFT TO RIGHT SIDE OF SCREEN
L3F9C:  .word $1FFB, (OFF*$2000)+(0&$1FFF) ;VCTR 0,-5,OFF  DOWN
L3FA0:  .word $0000, (ON*$2000)+((-2*MAX)&$1FFF) ;VCTR -2*MAX,0,ON  AND RETURN TO LEFT SIDE
L3FA4:  .word $1FFB, (OFF*$2000)+(0&$1FFF) ;VCTR 0,-5,OFF  DOWN
L3FA8:  .word $C000                 ;RTSL

;.SBTTL SELFTEST-POT TEST PATTERN
L3FAA:  .word $000C, (OFF*$2000)+(((256+64-8)*M_/D_)&$1FFF) ;VOFFM 256.+64.-8,8
L3FAE:  .word $6480                 ;COLOR VGCRED  VERY SMALL BOX, CENTERED CONTROL MUST BE WITHIN
L3FB0:  .word $54E0                 ;AON -8,-8
L3FB2:  .word $40E8                 ;AON 8,-8
L3FB4:  .word $4CE0                 ;AON 8,8
L3FB6:  .word $40F8                 ;AON -8,8
L3FB8:  .word $6280                 ;COLOR VGCGRN  INSIDE SEMI-BOX, MUST REACH PAST HERE
L3FBA:  .word $006C, $1FA8          ;AOFF -96,80
L3FBE:  .word $1F10, $E000          ;AON -96,-80
L3FC2:  .word $5408                 ;AOFF -80,-96
L3FC4:  .word $0000, $E0A0          ;AON 80,-96
L3FC8:  .word $4C08                 ;AOFF 96,-80
L3FCA:  .word $00F0, $E000          ;AON 96,80
L3FCE:  .word $4C18                 ;AOFF 80,96
L3FD0:  .word $0000, $FF60          ;AON -80,96
L3FD4:  .word $6780                 ;COLOR VGCWHT  OUTSIDE BOX, MAXIMUM VALUES
L3FD6:  .word $0030, $1FD0          ;AOFF -128,128
L3FDA:  .word $1E80, $E000          ;AON -128,-128
L3FDE:  .word $0000, $E100          ;AON 128,-128
L3FE2:  .word $0180, $E000          ;AON 128,128
L3FE6:  .word $0000, $FF00          ;AON -128,128
L3FEA:  .word VGCNTR                ;CNTR
L3FEC:  .word $C000                 ;RTSL
L3FEE:  .byte $00, $00, $00, $00, $00, $00, $00, $00 ;not assembled by any source statement (ROM fill)
L3FF6:  .byte $00, $00, $00, $00, $00, $00, $00, $00 ;not assembled by any source statement (ROM fill)
L3FFE:  .byte $00, $00              ;not assembled by any source statement (ROM fill)

