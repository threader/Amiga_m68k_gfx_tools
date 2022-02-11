; FILE: Source:modules/RemCards.ASM          REV: 3 --- Removes carddisk stuff

;
; RemCards patch for BlizKick
; ~~~~~~~~~~~~~~~~~~~~~~~~~~~
; This module removes all carddisk stuff from system thus saving some
; memory/resources.
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

	cmp.w	#37,($C,a0)		;requires V37+ rom image
	bhs.b	.cont
	moveq	#0,d0
	rts

.cont	lea	(.resname,pc),a1
	jsr	(a2)
	tst.l	d0
	beq.b	.nores

	move.l	d0,a0
	;move.b	#RTW_NEVER,(RT_FLAGS,a0)
	clr.b	(RT_FLAGS,a0)
	moveq	#1,d0
	rts

.nores	pea	(.resname,pc)
	move.l	sp,a1
	lea	(.mes1,pc),a0
	jsr	(a4)
	addq.l	#4,sp
	moveq	#0,d0
	rts

.resname	dc.b	'card.resource',0
.mes1	dc.b	'RemCards: %s not found!',10,0


	SECTION	VERSION,DATA

	dc.b	'$VER: RemCards_PATCH 1.0 (24.5.97)',0
