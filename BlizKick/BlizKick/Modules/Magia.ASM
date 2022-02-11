; FILE: Source:modules/Magia.ASM          REV: 7 --- Haha!

;
; Example BlizKick Module
; ~~~~~~~~~~~~~~~~~~~~~~~
; This code shows how to create simple BlizKick "patch" Module.
; Should be quite self-explonary...
;
; !PATCHING CODE NEED NOT BE FULLY PC-RELATIVE!
;
; !PATCH CODE ITSELF NEED TO BE FULLY PC-RELATIVE!
;  (as ROM is...)
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

	lea	(a0,d0.l),a1		; a1=rom end (buf)
	moveq	#'A',d1
	moveq	#'%',d2
	moveq	#0,d0
.find	cmp.l	a1,a0
	bhs.b	.exit
	move.b	(a0)+,d0
	cmp.b	d2,d0
	beq.b	.try_prompt
	cmp.b	d0,d1
	bne.b	.find
	lsl.l	#8,d0
	move.b	(a0)+,d0
	lsl.l	#8,d0
	move.b	(a0)+,d0
	lsl.l	#8,d0
	move.b	(a0),d0
	cmp.l	#'Amig',d0
	bne.b	.find

	subq.l	#3,a0
	move.b	#'M',(a0)+
	move.b	#'a',(a0)+
	move.b	#'g',(a0)+
	move.b	#'i',(a0)
	bra.b	.find

.exit	moveq	#1,d0
	rts

.try_prompt	cmp.b	#'N',(a0)
	bne.b	.find
	cmp.b	#4,(-2,a0)
	bne.b	.try_2
	cmp.b	#'>',(1,a0)
	bne.b	.find
	move.b	#' ',(a0)
	move.b	#'#',-(a0)
	move.b	#2,-(a0)
	bra.b	.find
.try_2	cmp.b	#'.',(1,a0)
	bne.b	.find
	cmp.b	#'%',(2,a0)
	bne.b	.find
	cmp.b	#'S',(3,a0)
	bne.b	.find
	cmp.b	#'>',(4,a0)
	bne.b	.find
	move.b	#'#',(-1,a0)
	move.b	#' ',(a0)+
	clr.b	(a0)
	bra	.find


	; And this is supposed to be a nice joke!!? ;-))

	SECTION	VERSION,DATA

	dc.b	'$VER: Magia_PATCH 1.1 (11.9.96)',0

