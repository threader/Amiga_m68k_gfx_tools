; FILE: Source:modules/FusionReserve.ASM          REV: 9 --- Do same as RsrvCold

;
; FusionReserve for BlizKick
; ~~~~~~~~~~~~~~~~~~~~~~~~~~
; This module substitutes RsrvCold tool of FUSION MAC Emulator (Copyright
; © 1997 Jim Drew & Microcode Solutions). It should also work with
; Mac1200 (Copyright © 1992-1996 Jim Drew & Utilities Unlimited
; International, Inc.).
;
; Written by Harry Sintonen.
; This source code is Public Domain.
;
;

	incdir	"include:"
	include	"exec/execbase.i"
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

NEWSTART	EQU	$4000

	moveq	#0,d7
	move.l	a0,a5
	move.l	d0,d5

	lsr.l	#1+5,d0			; d0=1st 1/32th of the rom (words)
	move.w	#$41F8,d2		; cmp preload
	move.l	#$210843F8,d3		; -""-
.find	subq.l	#1,d0
	beq.b	.done
	move.l	(a0),d1
	addq.l	#2,a0
	cmp.w	d1,d2
	beq.b	.lea_a0
	cmp.l	d1,d3
	bne.b	.find
.lea_a0	addq.l	#2,a0
	cmp.w	#$3000,(a0)		; A1200 rom!
	beq.b	.is
	cmp.w	#$0400,(a0)
	beq.b	.is
	cmp.w	#$1000,(a0)
	beq.b	.is
	cmp.w	#$2000,(a0)
	bne.b	.find
.is	move.w	#NEWSTART,(a0)
.skip	addq.l	#1,d7
	bra.b	.find

.done	move.l	d7,d0
	beq.b	.failed

	move.l	a5,a0
	move.l	d5,d0
	lea	(_FusionReserveVBR,pc),a1
	jsr	(a3)
	bra.b	.exitok

.failed	lea	(.errmsg,pc),a0
	jsr	(a4)
	moveq	#0,d0
.exitok	rts

.errmsg	dc.b	'This ROM isn''t compatible with FusionReserve patch!',10,0
	CNOP	0,2

_FusionReserveVBR
 BK_MOD BKMF_SingleMode,_end,(RTF_COLDSTART)<<24+37<<16+NT_UNKNOWN<<8+104,_name,_idstr,_init

; Singlemode on,
; COLDSTART module, requires KS V37.x or better, module type NT_UNKNOWN, priority 104.

_init	movem.l	d0-a6,-(sp)
	move.l	(4).w,a6		; Really need 010+ =)
	btst	#AFB_68010,(AttnFlags+1,a6)
	beq.b	.exit2
	jsr	(-$78,a6)		;call	Disable

	lea	(MemList,a6),a0		; Is chipmem start moved?
	lea	(.chipname,pc),a1
	jsr	(-$114,a6)		;call	FindName
	cmp.l	#$200000,d0
	blo.b	.in_chip
	move.l	d0,a0			; node in fastmem so get
	move.l	(20,a0),d0		; MH_LOWER and compare that.
.in_chip	cmp.l	#NEWSTART,d0
	blo.b	.exit			; not moved, so quit!

	lea	(.getvbr,pc),a5
	jsr	(-$1E,a6)		;call Supervisor
	tst.l	d0
	bne.b	.doclear		; was .exit ! Stupid me !-(

	move.l	#$400,d0
	moveq	#1,d1			;MEMF_PUBLIC,d1
	jsr	(-$2AC,a6)		;call	AllocVec
	move.l	d0,d2
	beq.b	.exit

	sub.l	a0,a0
	move.l	d2,a1
	move.l	#$400,d0
	jsr	(-$276,a6)		;call	CopyMemQuick
	jsr	(-$27C,a6)		;call	CacheClearU

	lea	(.setvbr,pc),a5
	jsr	(-$1E,a6)		;call Supervisor

.doclear
;	lea	($100).w,a0
;	move.w	#(NEWSTART-$100)/8-1,d0
;.clear	clr.l	(a0)+
;	clr.l	(a0)+
;	dbf	d0,.clear

	clr.b	($3E85).w
	clr.b	($3E48).w
	move.l	#'RSRV',($2118).w

	jsr	(-$27C,a6)		;call	CacheClearU
.exit	jsr	(-$7E,a6)		;call	Enable
.exit2	movem.l	(sp)+,d0-a6
	rts

.getvbr	movec	vbr,d0
	rte
.setvbr	movec	d2,vbr
	rte

.chipname	dc.b	'chip memory',0
_name
_idstr	dc.b	'FusionReserveVBR',0
	CNOP	0,2
_end


	SECTION	VERSION,DATA

	dc.b	'$VER: FusionReserve_PATCH 1.2 (25.11.97)',0

