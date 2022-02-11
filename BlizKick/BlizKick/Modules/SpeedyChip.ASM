; FILE: Source:modules/SpeedyChip.ASM          REV: 2 --- Patch 060 MMU list for faster chipmem write

;
; SpeedyChip module for BlizKick
; ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
; SpeedyChip module patches 060 MMU list speeding up chip memory
; writes.
;
; This module does the same thing as speedychip
; (Aminet: util/boot/speedychip.lha) by Harry Sintonen (that's me!-)
;
; NOTE: If you have V42+ 68060.library you don't need this module.
;
; Written by Harry Sintonen.
; This source code is Public Domain.
;
;

	incdir	"include:"
	include	"exec/libraries.i"	; Some required...
	include	"exec/memory.i"
	include	"exec/execbase.i"
	include	"exec/exec_lib.i"
	include	"blizkickmodule.i"

	SECTION	MODULE,CODE
_DUMMY_LABEL
 BK_MOD BKMF_SingleMode,_end,(RTF_AFTERDOS)<<24!37<<16!NT_UNKNOWN<<8!(256-110),_name,_idstr,_init

; Singlemode on,
; AFTERDOS module, requires KS V37.x or better, module type NT_UNKNOWN, priority -110.
; -> after ramlib (ramlib patches OpenLibrary).

_init	movem.l	d0-d1/a0-a2/a6,-(sp)
	move.l	(4).w,a6
	btst	#AFB_68040,(AttnFlags+1,a6) ; Test for 040+
	beq.b	.exit

	move.l	#PATCH_LEN+4,d0		; get memory for patch
	moveq	#MEMF_PUBLIC,d1
	jsr	(_LVOAllocMem,a6)
	tst.l	d0
	beq	.exit
	move.l	d0,a2

	lea	(Patch,pc),a0		; copy patch code
	lea	(4,a2),a1
	move.l	#PATCH_LEN,d0
	jsr	(_LVOCopyMem,a6)

	jsr	(_LVOForbid,a6)		; install patch
	move.l	a2,d0
	addq.l	#4,d0
	move.w	#_LVOOpenLibrary,a0
	move.l	a6,a1
	jsr	(_LVOSetFunction,a6)
	move.l	d0,(a2)
	jsr	(_LVOCacheClearU,a6)
	jsr	(_LVOPermit,a6)

.exit	movem.l	(sp)+,d0-d1/a0-a2/a6
	rts

Patch
.origol	EQU	*-4
	move.l	(.origol,pc),a0
	cmp.l	#'6804',(a1)		; match for '68040.library'
	bne.b	.orig
	cmp.l	#'0.li',(4,a1)
	bne.b	.orig
	cmp.l	#'brar',(8,a1)
	bne.b	.orig
	cmp.w	#'y'<<8,(12,a1)
	bne.b	.orig

	jsr	(a0)			; try opening it
	move.l	d0,-(sp)		; if opened 060 flag & MMU
	beq.b	.exit			; should be initialized ok.

	tst.b	(AttnFlags+1,a6)	; test for 060
	bmi.b	.has_060

.exit	move.l	(sp)+,d0
	rts
.orig	jmp	(a0)

.has_060	move.l	a5,a0			; get MMU control register
	lea	(.gettcr,pc),a5
	jsr	(_LVOSupervisor,a6)
	tst.w	d0			; test bit 15  E - Enable
	bpl.b	.exit
	btst	#14,d0			; P - Page Size
	bne.b	.exit			; Must have 4k page size

	movem.l	d2-d3/a4-a5,-(sp)	; store some regs
	jsr	(_LVODisable,a6)	; no others messing around, please...

	lea	(Patch,pc),a5		; remove (or disable) patch:
	move.w	#_LVOOpenLibrary,a0
	cmp.l	2(a6,a0.w),a5
	bne.b	.cant_rem
	move.l	-(a5),d0
	move.l	a6,a1
	jsr	(_LVOSetFunction,a6)
	bra.b	.was_remd
.cant_rem	move.w	#$4ED0,(4,a5)		; disable patch
	jsr	(_LVOCacheClearU,a6)
.was_remd
	lea	(.geturp,pc),a5		; get MMU list root table
	jsr	(_LVOSupervisor,a6)
	move.l	d0,a0			; a0=array of 128 root-level table descriptors, 32mb each

	move.l	(a0),d0			; get first pointer table
	and.w	#$FE00,d0
	move.l	d0,a4			; a4=array of 128 pointer table descriptors, 256k each

	moveq	#8-1,d3			; Patch all page desciptors of first 8 table
.mloop	move.l	(a4)+,d0		; descriptors (8*256k=2mb=size of chipmem)
	and.w	#$FE00,d0
	move.l	d0,a0			; a0=array of 64 page descriptors
	moveq	#64-1,d1
.ploop	move.l	(a0),d2
	move.l	d2,d0
	and.b	#%11,d0			; get PDT
	beq.b	.next			; 00=invalid
	cmp.b	#%10,d0			; 10=indirect
	beq.b	.next

	; ok this is really it:
	or.b	#%1100000,d2		; set cm (bits 5&6) to 11 (Cache-Inhibited, Imprecise exception model)
	move.l	d2,(a0)

.next	addq.l	#4,a0
	dbf	d1,.ploop
	dbf	d3,.mloop

	lea	(.flush,pc),a5		; flush ATC & caches
	jsr	(_LVOSupervisor,a6)
	jsr	(_LVOCacheClearU,a6)	; flush caches with OS too (just to be sure:)
	jsr	(_LVOEnable,a6)		; and back...
	movem.l	(sp)+,d2-d3/a4-a5	; pop registers
	move.l	(sp)+,d0		; pop OpenLibrary() result.
	rts

.gettcr	move.l	a0,a5
	dc.l	$4E7A0003		;movec	tc,d0
	nop
	rte

.geturp	dc.l	$4E7A0806		;movec	urp,d0
	nop
	rte

.flush	dc.w	$F518	; PFLUSHA	flush the address translation cache
	dc.w	$F4F8	; CPUSHA BC	flush the caches into memory
	dc.w	$F4D8	; INVA  BC	invalidate the data and inst caches
 	nop
	rte


PATCH_LEN	EQU	*-Patch

_name	dc.b	'SpeedyChip',0
_idstr	dc.b	'SpeedyChip 1.1 (3.12.97)',0
	CNOP	0,2
_end

	SECTION	VERSION,DATA

	dc.b	'$VER: SpeedyChip_MODULE 1.1 (3.12.97)',0

