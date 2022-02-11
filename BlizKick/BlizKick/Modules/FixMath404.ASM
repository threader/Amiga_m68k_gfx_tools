; FILE: Source:modules/FixMath404.ASM          REV: 14 --- Fix V40.4 math library

;
; Fix mathieeesingbas 40.4 -Module
; ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
; This patch module will fix mathieeesingbas.library V40.4 bug in functions
; IEEESPMul() and IEEESPDiv() [this bug occurs if you don't have 68881 or
; 68882 FPU].
;
; V1.1 - 13th Dec 2000
; Made it possible to patch mathieeesingbas.library that is fully or
; partially inside extresbuf. Added a check for 40.70 A3000 rom that
; doesn't have this bug, since it is guaranteed to have FPU.
;
; Written by Harry Sintonen.
; This source code is Public Domain.
;

	incdir	"include:"
	include	"blizkickmodule.i"	; Some required...


	SECTION	PATCH,CODE
_DUMMY_LABEL
	BK_PTC

; Code is run with following incoming parameters:
;
; a0=ptr to ROM start (buffer)	eg. $1DE087B8
; a1=ptr to ROM start (ROM)	eg. $00F80000 (do *not* access!)
; d0=ROM lenght in bytes	eg. $00080000
; a2=ptr to _FindResident routine (will search ROM buffer for resident tag):
;    CALL: jsr (a2)
;      IN: a0=ptr to ROM, d0=rom len, a1=ptr to resident name
;     OUT: d0=ptr to resident (buf) or NULL
; a3=ptr to _InstallModule routine (can be used to plant a "module"):
;    CALL: jsr (a3)
;      IN: a0=ptr to ROM, d0=rom len, a1=ptr to module, d6=dosbase
;     OUT: d0=success
; a4=ptr to _Printf routine (will dump some silly things (errormsg?) to stdout ;-)
;    CALL: jsr (a4)
;      IN: a0=FmtString, a1=Array (may be 0), d6=dosbase
;     OUT: -
; d6=dosbase, a6=execbase
;
; Code should return:
;
; d0=true if succeeded, false if failed.
; d1-d7/a0-a6 can be trashed. a7 *must* be preserved! ;-)

	moveq	#0,d7

	cmp.w	#40,($C,a0)		; Requires KS V40+
	blo	.exit

	lea	(regs,pc),a5
	movem.l	d0/a0-a1,(a5)

	lea	(_mname,pc),a1		; _FindResident
	jsr	(a2)
	tst.l	d0
	beq.b	.exit
	move.l	d0,a2			; a2=mathlib resident

	cmp.b	#40,(RT_VERSION,a2)	; V40
	bne.b	.exit
	cmp.b	#RTF_COLDSTART,(RT_FLAGS,a2) ; Coldstart
	bne.b	.exit
	move.l	(RT_IDSTRING,a2),d0
	beq.b	.exit
	bsr.b	buffer
	move.l	d0,a5			; a5=ptr in buffer

.find	cmp.b	#'0',(a5)+		; 40.4
	bne.b	.find
	addq.l	#1,a5
	cmp.b	#'4',(a5)+
	bne.b	.exit
	cmp.b	#' ',(a5)
	bne.b	.exit

	move.l	(RT_INIT,a2),d0		; Test RT_INIT
	beq.b	.exit
	bsr.b	buffer
	move.l	d0,a2			; a2=ptr in buffer


	moveq	#32/2,d1
	move.w	#$41F9,d0		; Find first "lea ABS,a0"
.find2	subq.l	#1,d1
	beq.b	.exit
	cmp.w	(a2)+,d0
	bne.b	.find2

.find3	subq.l	#1,d1			; Find second "lea ABS,a0"
	beq.b	.nobug
	cmp.w	(a2)+,d0
	bne.b	.find3

	move.l	(a2),d0			; lea abs address...
	bsr.b	buffer
	move.l	d0,a2			; ...in buffer address

	move.w	(a2)+,d0		; Test for $FFFF
	addq.w	#1,d0
	bne.b	.exit

	lea	(12*2,a2),a2		; 13th & 14th function
	cmp.l	#$001A001C,(a2)		; Check for invalid
	bne.b	.aok			; Already ok!
	move.l	#$063606A0,(a2)		; Stuff correct!
	moveq	#1,d7

.exit	move.l	d7,d0			; Valid counter?
	bne.b	.xit
	lea	(_error1,pc),a0		; a0=fmt
	pea	(_mname,pc)
	move.l	sp,a1			; a1=array
	jsr	(a4)			; Call _Printf
	addq.l	#4,sp
	moveq	#0,d0			; Return fail
.xit	rts

.aok	lea	(_error2,pc),a0
.print	jsr	(a4)			; Call _Printf
	moveq	#1,d0
	rts

.nobug	lea	(_nobug,pc),a0
	bra.b	.print


buffer	;test if inside rom bounds?
	move.l	(rom_log,pc),d1
	cmp.l	d1,d0
	blo.b	.nofix
	add.l	(rom_size,pc),d1
	cmp.l	d1,d0
	bhs.b	.nofix
	; inside rom, so generate ram buffer address
	sub.l	(rom_log,pc),d0		-$f80000
	add.l	(rom_phys,pc),d0	+buffer
.nofix	rts



_mname	dc.b	'mathieeesingbas.library',0

_error1	dc.b	'FixMath404: This patch requires V40 ROM with %s V40.4!',10,0
_error2	dc.b	'FixMath404: Already OK!',10,0
_nobug	dc.b	'FixMath404: This ROM doesn''t have the bug',10,0


	CNOP	0,2
regs
rom_size	ds.l	1
rom_phys	ds.l	1
rom_log	ds.l	1

	SECTION	VERSION,DATA

	dc.b	'$VER: FixMath404_PATCH 1.1 (13.12.00)',0
