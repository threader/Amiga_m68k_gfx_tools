; FILE: Source:modules/RebootFix.ASM          REV: 9 --- Fix problem with multisync reboot

;
; RebootFix module for BlizKick
; ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
;
; V1.3 - 5th Aug 2000
; Fucked up if the module patch was installed inside ROM. Fixed.
;
; V1.4 - 31st Jan 2001
; Added support for exec44 coldstart.
;
; Written by Harry Sintonen.
; This source code is Public Domain.
;
;

	incdir	"include:"
	include	"blizkickmodule.i"


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

	cmp.w	#37,($C,a0)		;requires V37+ rom image
	bhs.b	.cont
	moveq	#0,d0
	rts

.cont	moveq	#0,d7

	move.l	a0,a5
	move.l	#$397C0200,d1	;$0100  move.w #$200,($0100,a4)
	move.l	#$317C0200,d2	;$0064  move.w #$200,($0064,a0)
	move.w	#512-1,d3
.findl	subq.w	#1,d3
	beq.b	.badrom
	addq.l	#2,a5
	cmp.l	(a5),d1
	bne.b	.not1
	cmp.w	#$0100,(4,a5)
	beq.b	.found
.not1
	cmp.l	(a5),d2
	bne.b	.findl
	cmp.w	#$0064,(4,a5)
	bne.b	.findl

.found
	move.w	#$4EB9,(a5)+		;create jsr

	; a0 = ptr to ROM
	; d0 = rom len
	; d6 = dosbase
	move.l	d0,d5
	lea	(_rebootfix_module,pc),a1
	jsr	(a3)			;call _InstallModule
	move.l	d0,d1
	move.l	d5,d0
	tst.l	d1
	beq.b	.nomod

	lea	(_name,pc),a1
	jsr	(a2)			;call _FindResident
	tst.l	d0
	beq.b	.nomod

	move.l	d0,a0
	moveq	#_earlycode-_init,d0
	add.l	(RT_INIT,a0),d0
	move.l	d0,(a5)		; jsr destination


	moveq	#1,d7
.nomod
.badrom
	move.l	d7,d0
	rts

	CNOP	0,4
_rebootfix_module
 BK_MOD BKMF_SingleMode,_end,(0)<<24+37<<16+NT_UNKNOWN<<8+(256-128),_name,_idstr,_init

; Singlemode on,
; NEVER INIT module, requires KS V37.x or better, module type NT_UNKNOWN, priority -128.

_init	rts

_earlycode	movem.l	d0/a0,-(sp)
	lea	$dff000+$100,a0
	move.w	#$0200,(a0)		; Colour burst on!
	moveq	#3,d0
	swap	d0			; some delay
.loop	move.w	#$0020,($1DC-$100,a0)	; set PAL
	subq.l	#1,d0
	bne.b	.loop
	movem.l	(sp)+,d0/a0
	rts

_name
_idstr	dc.b	'RebootFix patch',0
	CNOP	0,2
_end

	SECTION	VERSION,DATA

	dc.b	'$VER: RebootFix_PATCH 1.4 (31.1.01)',0

