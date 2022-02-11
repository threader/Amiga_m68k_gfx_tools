; FILE: Source:modules/BPPCFix.ASM          REV: 2 --- Disable ppc.library of blizzppc

;
; BPPCFix module for BlizKick
; ~~~~~~~~~~~~~~~~~~~~~~~~~~~
; Written by Harry Sintonen.
;
; 1.0: initial release.
; 1.1: fixed priority to -1. with priority 0 and installed to ROM
;      area, this module was initialized before `Blizzard PPC Library Init'
;      and thus failed to work.
; 1.2: now disables BlizzardPPCLibInit. 3.31 seconds faster booting on my
;      68060 @ 50MHz system. As a side effect Rafal Mania's InitPPCLib
;      doesn't work anymore. Use BPPCFixFix and patch regular ppc.library
;      *or* use loadppclib if you need to reload ppc.library.
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
 BK_MOD BKMF_SingleMode,_end,(RTF_COLDSTART)<<24+37<<16+NT_UNKNOWN<<8+(1),_name,_idstr,_init

; Singlemode on,
; COLDSTART module, requires KS V37.x or better, module type NT_UNKNOWN, priority 1.

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
1$:	move.l	d0,a2

; compare module name with "BlizzardPPCLibInit"
	move.l	(RT_NAME,a2),a2		; name of current module
	lea	(ppclibinit_name,pc),a3
	moveq	#19-1,d0
2$:	cmpm.b	(a2)+,(a3)+
	dbne	d0,2$
	bne.b	loop_end
	subq.l	#4,a1			; BlizzardPPCLibInit found - remove module

loop_end:
	move.l	(a0)+,d0
	bne.b	loop

	clr.l	(a1)			; end list

	jsr	(-$27c,a6)		; CacheClearU()

	jsr	(-$8a,a6)		; Permit()

exit	movem.l	(sp)+,d0-a6
	rts

ppclibinit_name
	dc.b	'BlizzardPPCLibInit',0

_name	dc.b	'BPPCFix',0
_idstr	dc.b	'BPPCFix 1.2 (2.9.00)',0
	CNOP	0,2
_end

	SECTION	VERSION,DATA

	dc.b	'$VER: BPPCFix_MODULE 1.2 (2.9.00)',0

