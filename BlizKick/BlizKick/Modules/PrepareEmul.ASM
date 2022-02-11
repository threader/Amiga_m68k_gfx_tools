; FILE: Source:modules/PrepareEmul.ASM          REV: 18 --- PrepareEmul for BlizKick

;
; PrepareEmul patch for BlizKick ("patch" Module)
; ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
; Written by Harry Sintonen.
; This source code is Public Domain.
;
; Original PrepareEmul belongs to The ShapeShifter package
; © Copyright 1993-1997 Christian Bauer. This patch doesn't really
; base on PrepareEmul program, but ShapeShifter's documentation...
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

NEWSTART	EQU	$2000

	moveq	#0,d7
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
	IFEQ	NEWSTART-$3000
	beq.b	.skip
	ELSE
	beq.b	.is
	ENDC
	cmp.w	#$0400,(a0)
	beq.b	.is
	cmp.w	#$1000,(a0)
	bne.b	.find
.is	move.w	#NEWSTART,(a0)
.skip	addq.l	#1,d7
	bra.b	.find

.done	move.l	d7,d0
	bne.b	.exitok
	lea	(.errmsg,pc),a0
	jsr	(a4)
	moveq	#0,d0
.exitok	rts


.errmsg	dc.b	'This ROM isn''t compatible with PrepareEmul patch!',10,0


	SECTION	VERSION,DATA

	dc.b	'$VER: PrepareEmul_PATCH 1.4 (30.5.97)',0

