; FILE: Source:modules/BPPCFix040.ASM          REV: 1 --- Disable 680x0 libraries of blizzppc

;
; BPPCFix 040 module for BlizKick
; ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
; Written by Harry Sintonen.
;
; This module disables BlizzPPC flashrom 68040.library
; (and 68060.library if available).
;
; 1.0: initial release.
; 1.1: fixed to require EXTRESBUF. this prevents possible priority
;      problems.
;
; based on:
;
;** BPPCFix_kickcode.asm
;**
;** Disables ppc.library resident modules on Amigas with BPPC
;** Written in 1998 by Frank Wille <frank@phoenix.owl.de>
;**
;** V1.0  26-Dec-98
;**       created
;
;
;

	incdir	"include:"
	include	"exec/types.i"
	include	"exec/libraries.i"

	include	"exec/execbase.i"

	include	"blizkickmodule.i"	; Some required...

	SECTION	MODULE,CODE
_DUMMY_LABEL
 BK_MOD BKMF_ExtResBuf|BKMF_SingleMode,_end,(RTF_COLDSTART)<<24+37<<16+NT_UNKNOWN<<8+100,_name,_idstr,_init

; Require EXTRESBUF for this module, Singlemode on,
; COLDSTART module, requires KS V37.x or better, module type NT_UNKNOWN, priority 100.

_init	movem.l	d0-a6,-(sp)
	move.l	(4).w,a6

	jsr	(-$84,a6)		; Forbid()

	move.l	(ResModules,a6),a0
	move.l	a0,a1
	bra.b	loop_end
loop:
	move.l	d0,(a1)+
	bpl.b	1$
	bclr	#31,d0
	move.l	d0,a0
	move.l	d0,a1
	bra.b	loop_end
1$:	move.l	d0,a4

	lea	(da040_name,pc),a3
	bsr.b	killtag
	beq.b	loop_end

	lea	(da060_name,pc),a3
	bsr.b	killtag

loop_end:
	move.l	(a0)+,d0
	bne.b	loop

	clr.l	(a1)			; end list

	jsr	(-$27c,a6)		; CacheClearU()

	jsr	(-$8a,a6)		; Permit()

exit	movem.l	(sp)+,d0-a6
	rts


killtag	moveq	#-1,d0
	move.l	a3,a2
1$:	addq.l	#1,d0
	tst.b	(a2)+
	bne.b	1$
	move.l	(RT_NAME,a4),a2		; name of current module
2$:	cmpm.b	(a2)+,(a3)+
	dbne	d0,2$
	bne.b	3$
	subq.l	#4,a1			; module name matched - kill it!
3$:	rts

da040_name
	dc.b	'68040.library',0

da060_name
	dc.b	'68060.library',0


_name	dc.b	'BPPCFix040',0

_idstr	dc.b	'BPPCFix040 1.1 (7.3.00)',0
	CNOP	0,2
_end

	SECTION	VERSION,DATA

	dc.b	'$VER: BPPCFix040_MODULE 1.1 (7.3.00)',0

