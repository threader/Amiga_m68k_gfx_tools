; ColdResetCard.ASM VER: 1.0 (8.12.2001)

; ColdResetCard module for BlizKick V1.20+.
; Written by ArtPo.
; This code is Public Domain.

	INCDIR	"Include:"
	INCLUDE	"blizkickmodule.i"	; .mod\@ requires ASM-One Rev. 465+

_LVOForbid	EQU	-132
_LVOPermit	EQU	-138

	SECTION	MODULE,CODE

_DUMMY_LABEL

	BK_MOD	BKMF_SingleMode,_end,(RTF_COLDSTART)<<24+36<<16+NT_UNKNOWN<<8+47,_name,_idstr,_init

_init	jsr	_LVOForbid(a6)
	move.w	$DFF01C,d1
	andi.w	#$0008,d1
	move.w	d1,$DFF09A

	move.b	#$FF,$DA9000		; PCMCIA Reset Enable
	move.l	#$20000,d0
.timer	tst.b	$BFE001			; timer.device?
	subq.l	#1,d0
	bne.s	.timer
	move.b	#$FC,$DA9000		; PCMCIA Reset Disable

	bset.l	#15,d1
	move.w	d1,$DFF09A
	jsr	_LVOPermit(a6)
	rts

_name	dc.b	"ColdResetCard",0
	EVEN
_idstr	dc.b	"ColdResetCard 1.0 (8.12.01)",0
	EVEN
_end

	SECTION	VERSION,DATA

	dc.b	"$VER: ColdResetCard_MODULE 1.0 (8.12.2001)",0
