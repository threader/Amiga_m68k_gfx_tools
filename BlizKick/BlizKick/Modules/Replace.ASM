; FILE: Source:modules/Replace.ASM          REV: 12 --- Replacing Module for BlizKick

;
; Example BlizKick Module
; ~~~~~~~~~~~~~~~~~~~~~~~
; This code shows how to create replacing BlizKick "Module".
; Should be quite self-explonary... (?)
;
; !CODE MUST BE FULLY PC-RELATIVE!
;
; Written by Harry Sintonen.
; This source code is Public Domain.
;

	incdir	"include:"
	include	"exec/execbase.i"
	include	"blizkickmodule.i"	; Some required...

_LVORawDoFmt		EQU	-$20A
_LVOOpenLibraryTagged	EQU	-$32A
_LVOTimedDisplayAlert	EQU	-$336
_LVOCloseLibrary	EQU	-$19E


	SECTION	MODULE,CODE
_DUMMY_LABEL
 BK_MOD BKMF_ReplaceMode!BKMF_ExtResBuf,_end,(RTF_COLDSTART)<<24+39<<16+NT_UNKNOWN<<8+$C9,_name,_name,_init

; Replace mode on, requires EXTRESBUF buffer, COLDSTART module, requires KS V39.x or better,
; module type NT_UNKNOWN, priority -55.

STACKBUF	EQU	200

_init	clr.l	(0).W
	movem.l	d2/d7/a2/a3/a6,-(sp)
	move.l	(LastAlert,a6),d2
	moveq	#-1,d0			; Display no alert?
	cmp.l	d0,d2
	beq.b	.exit

	lea	(-STACKBUF,sp),sp
	move.l	sp,a3
	lea	(SoftFail,pc),a0
	move.l	d2,d0
	swap	d0
	cmp.b	#1,d0
	bne.b	.skip0
	lea	(NoMem,pc),a0
	bra.b	.skip1

.skip0	btst	#$1F,d2
	bne.b	.skip1
	tst.w	d0
	beq.b	.skip1
	lea	(Recoverable,pc),a0
.skip1	bsr.b	.dostr
	lea	(PressLeftie,pc),a0
	bsr.b	.dostr
	clr.b	(a3)+

	lea	(ErrorFmt,pc),a0
	lea	(LastAlert,a6),a1
	lea	(.PutChar,pc),a2
	jsr	(_LVORawDoFmt,a6)

.try	moveq	#3,d0			; 3=intuition.library
	jsr	(_LVOOpenLibraryTagged,a6)
	tst.l	d0
	beq.b	.try			; crash!
	move.l	(LastAlert+3*4,a6),a1
	move.l	a6,a3
	move.l	d0,a6
	move.l	d2,d0
	move.l	sp,a0
	moveq	#40,d1
	jsr	(_LVOTimedDisplayAlert,a6)
	move.l	d0,a2
	move.l	a6,a1
	move.l	a3,a6
	jsr	(_LVOCloseLibrary,a6)

	lea	(STACKBUF,sp),sp
	clr.l	(0).W
	moveq	#-1,d0			; No alert on next round, please!
	move.l	d0,(LastAlert,a6)
.exit	move.l	a2,d0
	movem.l	(sp)+,d2/d7/a2/a3/a6
	rts

.dostr	clr.b	(a3)+
.copy	move.b	(a0)+,(a3)+
	bne.b	.copy
	st	(a3)+
	rts

.PutChar	move.b	d0,(a3)+
	clr.b	(a3)
	rts

_name	dc.b	'alert.hook',13,10,0

NoMem	dc.b	38,15
	dc.b	'Not enough memory. ',0
SoftFail	dc.b	38,15
	dc.b	'Software Failure. ',0
Recoverable	dc.b	38,15
	dc.b	'Recoverable Alert. ',0
PressLeftie	dc.b	234,15
	dc.b	'Press left mouse button to continue.',0
ErrorFmt	dc.b	142,30
	dc.b	'Error:  %04x %04x   Task:  %08lx',0

	CNOP	0,2
_end


	SECTION	VERSION,DATA

	dc.b	'$VER: alert.hook_MODULE 1.1 (11.9.96)',0
