; FILE: Source:modules/ramlibstack.ASM          REV: 2 --- make ramlib stack 8k

;
; Make ramlib stack 8k
; ~~~~~~~~~~~~~~~~~~~~
; This module hacks ramlib initialization so that it will allocate
; 8k stack instead of original 2k. Substitutes MCPRamlibPatch.
;
; Written by Harry Sintonen.
; This source code is Public Domain.
;

	incdir	"include:"
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

	cmp.w	#37,($C,a0)
	bhs.b	.cont
	moveq	#0,d0
	rts

.cont	movem.l	d0/a0-a1,-(sp)

	lea	(ramlibname,pc),a1
	jsr	(a2)
	tst.l	d0
	beq	.fail
	move.l	d0,a5

	move.l	a5,a0			; a0=beg of search
	lea	(2048,a0),a1		; a1=end of search

	move.l	#$2608E48B,d1
	move.l	#$7808E19C,d2
	move.l	#$4EAEFF76,d3

.find	addq.l	#2,a0
	cmp.l	a1,a0
	bhs.b	.not_found
	cmp.l	(a0),d1
	bne.b	.find
	cmp.l	(4,a0),d2
	bne.b	.find
	cmp.l	(8,a0),d3
	bne.b	.find

	move.w	#$7820,(4,a0)
	moveq	#1,d0
	bra.b	.noerr

.not_found	move.l	(RT_IDSTRING,a5),a0
	sub.l	(2*4,sp),a0		;[a1]
	add.l	(1*4,sp),a0		;[a0]
	move.l	a0,-(sp)
	move.l	sp,a1
	lea	(fmt1,pc),a0
	jsr	(a4)
	addq.l	#4,sp

.fail	moveq	#0,d0
.noerr	lea	(3*4,sp),sp
	rts


ramlibname	dc.b	'ramlib',0
fmt1	dc.b	'Couldn''t patch %s',0


	SECTION	VERSION,DATA

	dc.b	'$VER: ramlibstack_PATCH 1.0 (19.10.98)',0

