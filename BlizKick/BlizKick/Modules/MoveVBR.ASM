; FILE: Source:modules/MoveVBR.ASM          REV: 6 --- Moves VBR to fastmem

;
; MoveVBR module for BlizKick
; ~~~~~~~~~~~~~~~~~~~~~~~~~~~
; Written by Harry Sintonen.
; This source code is Public Domain.
;
;

	incdir	"include:"
	include	"exec/types.i"
	include	"exec/libraries.i"

	include	"exec/execbase.i"

	include	"blizkickmodule.i"	; Some required...

	SECTION	MODULE,CODE
_DUMMY_LABEL
 BK_MOD BKMF_SingleMode,_end,(RTF_COLDSTART)<<24+37<<16+NT_UNKNOWN<<8+104,_name,_idstr,_init
;BK_MOD BKMF_SingleMode,_end,(RTF_COLDSTART)<<24+37<<16+NT_UNKNOWN<<8+$FF,_name,_idstr,_init

; Singlemode on,
; COLDSTART module, requires KS V37.x or better, module type NT_UNKNOWN, priority 104.

_init	movem.l	d0-a6,-(sp)
	move.l	(4).w,a6
	btst	#AFB_68010,(AttnFlags+1,a6)
	beq.b	.exit2
	jsr	(-$78,a6)		;call	Disable

	lea	(.getvbr,pc),a5
	jsr	(-$1E,a6)		;call Supervisor
	tst.l	d0
	bne.b	.exit

	move.l	#$400,d0
	moveq	#4,d1			;MEMF_FAST,d1
	jsr	(-$2AC,a6)		;call	AllocVec
	tst.l	d0
	beq.b	.exit
	move.l	d0,a2

	sub.l	a0,a0
	move.l	a2,a1
	move.l	#$400,d0
	jsr	(-$276,a6)		;call	CopyMemQuick
	jsr	(-$27C,a6)		;call	CacheClearU

	lea	(.setvbr,pc),a5
	jsr	(-$1E,a6)		;call Supervisor

.exit	jsr	(-$7E,a6)		;call	Enable
.exit2	movem.l	(sp)+,d0-a6
	rts

.getvbr	movec	vbr,d0
	rte
.setvbr	movec	a2,vbr
	rte

_name	dc.b	'MoveVBR',0
_idstr	dc.b	'MoveVBR 1.2 (11.9.96)',0
	CNOP	0,2
_end

	SECTION	VERSION,DATA

	dc.b	'$VER: MoveVBR_MODULE 1.2 (11.9.96)',0

