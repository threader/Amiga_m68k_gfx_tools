;*---------------------------------------------------------------------------
;  :Program.	IntAckFix.asm
;  :Contents.	BlizKick module to fix the interrupt acknowledge bug on 68040/60 systems
;		to my knowledge this bug is in all kickstarts including exec44
;  :Author.	Wepl
;  :Version.	$Id: IntAckFix.asm 1.1 2007/12/02 20:17:37 wepl Exp wepl $
;  :History.	02.12.07 created
;  :Requires.	-
;  :Copyright.	Public Domain
;  :Language.	68000 Assembler
;  :Translator.	Barfly V2.16
;  :To Do.
;---------------------------------------------------------------------------*

	INCDIR	Includes:
	INCLUDE	hardware/custom.i
	INCLUDE	blizkickmodule.i

_custom = $dff000

	OUTPUT	Devs:Kickstarts/Remus/BK_mods/IntAckFix
	BOPT	O+				;enable optimizing
	BOPT	OG+				;enable optimizing
	BOPT	ODd-				;disable mul optimizing
	BOPT	ODe-				;disable mul optimizing
	SUPER

	IFND	.passchk
	DOSCMD	"WDate  >T:date"
.passchk
	ENDC

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

		move.l	d0,d2			;D2 = ROM length
		move.l	a0,d3			;D3 = ROM buffer
		move.l	a1,d4			;D4 = ROM address

	;search exec.ExitIntr

		lea	_execname,a1
		jsr	(a2)			;_FindResident
		tst.l	d0
		beq	.noexec
		
		move.l	d0,a0
		move.l	(RT_ENDSKIP,a0),a1
		sub.l	(RT_MATCHTAG,a0),a1
		add.l	a0,a1
		sub.l	a5,a5

.search		cmp.l	a0,a1
		blo	.searchend

		cmp.w	#$4cdf,(a0)+
		bne	.search
		cmp.w	#$6303,(a0)+
		bne	.search
		cmp.w	#$4e73,(a0)+
		bne	.search
		cmp.w	#$46fc,(a0)+
		bne	.search
		cmp.w	#$2000,(a0)+
		bne	.search
		move.l	a5,d0
		bne	.multfound
		lea	(-10,a0),a5		;A5 = patch address
		
.searchend	move.l	a5,d0
		beq	.notfound
		
	; install patch code...

		move.l	d2,d0			;ROM length
		move.l	d3,a0			;ROM buffer
		lea	_module,a1
		jsr	(a3)			;_InstallModule
		tst.l	d0
		beq	.modfail

	; find patch code...

		move.l	d2,d0			;ROM length
		move.l	d3,a0			;ROM buffer
		lea	_rtname,a1
		jsr	(a2)			;_FindResident
		tst.l	d0
		beq	.findfail

	; patch

		move.w	#$4ef9,(a5)+		;jmp x.l
		move.l	d0,a0
		move.l	(RT_INIT,a0),a0
		addq.l	#2,a0			;skip the rts
		move.l	a0,(a5)

	; success
		lea	_success,a0
		sub.l	d3,d0
		move.l	d0,-(a7)
		pea	(-2,a5)
		sub.l	d3,(a7)
		move.l	a7,a1
		jsr	(a4)
		addq.l	#8,a7

		moveq	#1,d0
		rts

.noexec		lea	_noexec,a0
		bra	.fail

.notfound	lea	_notfound,a0
		bra	.fail

.multfound	lea	_multfound,a0
		bra	.fail

.modfail	lea	_modfail,a0
		bra	.fail

.findfail	lea	_findfail,a0
		bra	.fail

.fail		jsr	(a4)
		moveq	#0,d0
		rts

_module

 BK_MOD BKMF_SingleMode,_rtend,(0)<<24+37<<16+NT_UNKNOWN<<8+(256-128),_rtname,_rtid,_rtinit

; Singlemode on,
; NEVER INIT module, requires KS V37.x or better, module type NT_UNKNOWN, priority -128.

_rtinit		rts

_patch		tst.w	(_custom+intreqr)
		movem.l	(a7)+,d0-d1/a0-a1/a5-a6
		rte

_rtname		dc.b	"IntAckFix",0
_rtid		dc.b	"IntAckFix 0.1 "
	INCBIN	"T:date"
		dc.b	0
	EVEN
_rtend

_execname	dc.b	"exec.library",0
_noexec		dc.b	"exec.library not found",0
_notfound	dc.b	"code to patch could not be found",0
_multfound	dc.b	"multiple code matches found",0
_modfail	dc.b	"install module failed",0
_findfail	dc.b	"installed module not found",0
_success	dc.b	"successful patched (patch=$%lx module=$%lx)",0

	SECTION	VERSION,DATA

	dc.b	'$VER: IntAckFix_PATCH 0.1 '
	INCBIN	"T:date"
		dc.b	0

