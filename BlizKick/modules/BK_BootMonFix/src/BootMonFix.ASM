; FILE: Source:modules/BootMonFix.ASM          REV: 1 --- Disable BootVGA.Monitor of blizzppc and csppc

;
; BootMonFix module for G-Rex/CVPPC/BlizzardVision
; ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
; by Dale Whinham, completely based on BPPCFix040 by Harry Sintonen
;
; This module disables the BlizzardPPC/CSPPC "BootVGA.Monitor" resident,
; which is located in the accelerator's flash ROM and loaded during
; startup.
;
; The BootVGA resident is responsible for the "31KHz boot monitor" 
; feature of CyberStorm and Blizzard boards with CyberVisionPPC, BVision
; and G-Rex graphics cards. It also does some patching to copy Intuition
; screens into the gfxcard framebuffer UNTIL CyberGraphX is loaded.
; 
; This could be undesirable if you have a second monitor, monitor switch
; or flickerfixer as it will hugely slow down non-CGX Intuition screens
; until CGX has loaded. It gets annoying if you boot from floppy as much
; as I do. :)
;
; This module simply disables it in the same way as Harry's BPPCFix040
; module does. Tested with AlgorKick on an Algor PRO with Voodoo3/G-Rex,
; Amiga 4000D.
;
; Thanks to Piru (Harry) for giving me the OK on releasing this! :);
;
; 1.0: initial release.
;
; based on;
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
	bpl.w	loop1
	bclr	#31,d0
	move.l	d0,a0
	move.l	d0,a1
	bra.b	loop_end
loop1:	move.l	d0,a4

	lea	(bootmon_name,pc),a3
	bsr.b	killtag
	beq.w	loop_end

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
killtag1:
	addq.l	#1,d0
	tst.b	(a2)+
	bne.b	killtag1
	move.l	(RT_NAME,a4),a2		; name of current module
killtag2:
	cmpm.b	(a2)+,(a3)+
	dbne	d0,killtag2
	bne.b	killtag3
	subq.l	#4,a1			; module name matched - kill it!
killtag3:
	rts

bootmon_name
	dc.b	'BootVGA.Monitor',0

_name	dc.b	'BootMonFix',0

_idstr	dc.b	'BootMonFix 1.0 (15.5.12)',0
	CNOP	0,2
_end

	SECTION	VERSION,DATA

	dc.b	'$VER: BootMonFix_MODULE 1.0 (24.5.12)',0

