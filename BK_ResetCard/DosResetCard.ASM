; DosResetCard.ASM VER: 1.0 (8.12.2001)

; DosResetCard module for BlizKick V1.20+.
; Written by ArtPo.
; This code is Public Domain.

	INCDIR	"Include:"
	INCLUDE	"blizkickmodule.i"	; .mod\@ requires ASM-One Rev. 465+

_LVOOpenLibrary		EQU	-552
_LVOCloseLibrary	EQU	-414
_LVODelay		EQU	-198

	SECTION	MODULE,CODE

_DUMMY_LABEL

	BK_MOD	BKMF_SingleMode,_end,(RTF_AFTERDOS)<<24+36<<16+NT_UNKNOWN<<8+(256-100),_name,_idstr,_init

_init	lea	.dosn(pc),a1
	moveq	#36,d0
	jsr	_LVOOpenLibrary(a6)
	tst.l	d0
	beq.s	.end
	move.l	a5,-(a7)
	movea.l	d0,a5

	exg	a5,a6
	moveq	#15,d1
	move.b	#$FF,$DA9000		; PCMCIA Reset Enable
	jsr	_LVODelay(a6)
	move.b	#$FC,$DA9000		; PCMCIA Reset Disable
	exg	a5,a6

	movea.l	a5,a1
	jsr	_LVOCloseLibrary(a6)
	move.l	(a7)+,a5
.end	moveq	#0,d0
	rts

.dosn	dc.b	"dos.library",0
	EVEN

_name	dc.b	"DosResetCard",0
	EVEN
_idstr	dc.b	"DosResetCard 1.0 (8.12.01)",0
	EVEN
_end

	SECTION	VERSION,DATA

	dc.b	"$VER: DosResetCard_MODULE 1.0 (8.12.2001)",0
