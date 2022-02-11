; FILE: Source:modules/Colour.ASM          REV: 10 --- Colour-bars on boot

;
; Example BlizKick Module
; ~~~~~~~~~~~~~~~~~~~~~~~
; This code shows how to create simple BlizKick "Module".
; Should be quite self-explonary...
;
; !CODE MUST BE FULLY PC-RELATIVE!
;
; Written by Harry Sintonen.
; This source code is Public Domain.
;

; Version 1.0 was buggy!! It wasn't PC-relative... ;-(((
;

	incdir	"include:"
	include	"blizkickmodule.i"	; Some required...


TIME	EQU	1*50			; Display 1 second (PAL)
;DEBUG	EQU	1			; Enable if you want to test from CLI


	IFD	DEBUG
	SECTION	DEBUG,CODE
	jsr	_init
	moveq	#0,d0
	rts
	ENDC


	SECTION	MODULE,CODE
_DUMMY_LABEL
 BK_MOD 0,_end,(RTF_COLDSTART)<<24+30<<16+NT_UNKNOWN<<8+126,_name,_idstr,_init

; COLDSTART module, requires KS V30.x or better, module type NT_UNKNOWN, priority 126.

_init	movem.l	d0-a6,-(sp)
	lea	$DFF000,a6

	move.w	($1C,a6),d0		; Save DMA & ints state:
	swap	d0
	move.w	($02,a6),d0
	or.l	#$80008000,d0
	move.l	d0,-(sp)

	move.w	#$7FFF,($9A,a6)		; All ints off!
	move.w	#$01FF,($96,a6)		; All DMA off!
	move.w	#$0200,($100,a6)	; Colour burst on!

	lea	(_colours,pc),a4	; Do the trick:
	moveq	#numcolours,d7
	move.l	#(TIME*312/2)-1,d5
	moveq	#1,d6

.mloop	move.l	($04,a6),d0
	lsr.l	#8,d0
	andi.w	#$3FF,d0
	beq.b	.dors
	subq.l	#1,d6
	bne.b	.nors
.dors	move.l	d7,d6
	move.l	a4,a0
.nors	move.w	(a0)+,($180,a6)
	move.b	($06,a6),d0		; Wait for one raster line:
.wait	cmp.b	($06,a6),d0
	beq.b	.wait
	dbf	d5,.mloop

	move.l	(sp)+,d0		; Restore DMA & ints:
	move.w	d0,($96,a6)
	swap	d0
	move.w	d0,($9A,a6)

	movem.l	(sp)+,d0-a6
	rts

_colours
	dc.w	$101,$101,$202,$303,$404,$505,$606,$707
	dc.w	$808,$909,$A0A,$B0B,$C0C,$D0D,$E0E,$F0F
	dc.w	$F0F,$F0F
	dc.w	$F0F,$E0E,$D0D,$C0C,$B0B,$A0A,$909,$808
	dc.w	$707,$606,$505,$404,$303,$202,$101,$101,$000

numcolours	EQU	(*-_colours)/2


_name	dc.b	'Colour',0
_idstr	dc.b	'Colour 1.3 (11.9.96)',0
	CNOP	0,2
_end

	SECTION	VERSION,DATA

	dc.b	'$VER: Colour_MODULE 1.3 (11.9.96)',0

