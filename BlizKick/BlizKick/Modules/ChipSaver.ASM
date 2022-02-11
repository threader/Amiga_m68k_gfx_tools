; FILE: Source:modules/ChipSaver.ASM          REV: 52 --- Copies chipmem to fast

;
; ChipSaver patch for BlizKick
; ~~~~~~~~~~~~~~~~~~~~~~~~~~~~
; This module copies chip memory to fast memory if  if RMB is pressed during
; reboot. Creates ExoticRipper compatible image ($100 -image).
;
; Suggested by Max Romanoff.
;
; V1.1 - 5th Aug 2000
; Fucked up if the module patch was installed inside ROM. Fixed.
;
; Written by Harry Sintonen.
; This source code is Public Domain.
;

;FASTBUFHEAD_LEN EQU	256*1024		;skip first 256K (prevent trashing)
CHIPBEGSAVE_LEN	EQU	64*1024			;save lenght (must be multiple of 64)

	incdir	"include:"
	include	"exec/types.i"
	include	"exec/libraries.i"
	include	"exec/memory.i"

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

	cmp.w	#37,($C,a0)		;requires V37+ rom image
	bhs.b	.cont
	moveq	#0,d0
	rts

.cont	moveq	#0,d7

	move.l	d0,-(sp)
	bsr	FindBlizMemMid
	move.l	d0,d1
	move.l	(sp)+,d0
	tst.l	d1
	beq.b	.noblizmem
;	add.l	#FASTBUFHEAD_LEN,d1
	lea	(_absdstp_1,pc),a5	;fix chipbegsave buffer adr
	move.l	d1,(a5)
	lea	(_absdstp_2,pc),a5
	move.l	d1,(a5)

	move.l	a0,a5
	move.l	#$13FC0003,d1
	move.w	#512-1,d2
.findl	subq.w	#1,d2
	beq.b	.badrom
	addq.l	#2,a5
	cmp.l	(a5),d1
	bne.b	.findl

	move.l	a5,d1			;d1=jump pos (buf)
	moveq	#8,d3
	add.l	d1,d3
	sub.l	a0,d3
	add.l	a1,d3			;d3=return jump pos (rom)

	move.l	a0,-(sp)
	move.l	d1,a0			;copy original code
	lea	(_instpos,pc),a5
	move.l	(a0)+,(a5)+
	move.l	(a0)+,(a5)+

	lea	(_jmpromp,pc),a0	;fix returning jmp
	move.l	d3,(a0)

	move.l	d1,a5			;create jmp
	move.w	#$4EF9,(a5)+
	move.l	(sp)+,a0

	move.l	d0,d5
	lea	(_copier_module,pc),a1
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
	move.l	#_earlycode-_init,d0
	add.l	(RT_INIT,a0),d0
	move.l	d0,(a5)

	moveq	#1,d7
.nomod
.badrom
.noblizmem	move.l	d7,d0
	rts


FindBlizMemMid	movem.l	d1-a6,-(sp)
	moveq	#0,d1
	jsr	(-$84,a6)		;Forbid
	lea	(MemList,a6),a5
	lea	(4,a5),a4
.scanloop	move.l	(a5),a5
	cmp.l	a5,a4
	beq.b	.notfound
	move.w	(MH_ATTRIBUTES,a5),d0
	and.w	#MEMF_CHIP!MEMF_FAST!MEMF_PUBLIC,d0	;Public fast?
	cmp.w	#MEMF_FAST!MEMF_PUBLIC,d0
	bne.b	.scanloop
	cmp.l	#$01000000,(MH_LOWER,a5)	;32bit?
	blo.b	.scanloop
	move.l	(LN_NAME,a5),d0
	beq.b	.found
	move.l	d0,a2
	move.l	(a2),d0
	or.l	#$20202020,d0		;To lowercase
	cmp.l	#'bliz',d0
	beq.b	.found
	tst.b	(a2)			;null name -> buggy AllocMem result test!
	bne.b	.scanloop
.found	move.l	(MH_LOWER,a5),d1
.notfound	jsr	(-$8A,a6)		;Permit
	move.l	d1,d0			;must set d0!!
	beq.b	.exit

	move.l	(MH_UPPER,a5),d0
	sub.l	d1,d0
	lsr.l	#2,d0			;add ¼th
	add.l	d1,d0
	and.w	#$FFF0,d0

.exit	movem.l	(sp)+,d1-a6
	rts

	CNOP	0,4
_copier_module
 BK_MOD BKMF_SingleMode,_end,(RTF_COLDSTART)<<24+37<<16+NT_UNKNOWN<<8+104,_name,_idstr,_init

; Singlemode on,
; COLDSTART module, requires KS V37.x or better, module type NT_UNKNOWN, priority 104.
; At priority 104 fastmem should be available.

_init	btst	#6,$BFE001		;test LMB
	beq	.sexit			;if pressed don't copy
	movem.l	d0-a6,-(sp)

	lea	$DFF000,a5
	move.w	#$FFFF,($34,a5)		;pin 9 to write mode! ($0C00)

	moveq	#1-1,d0			; Wait for two vertical blankings
.wait1	btst	#0,($5,a5)		; (Could wait only 300 µs!)
	bne.b	.wait1
.wait2	btst	#0,($5,a5)
	beq.b	.wait2
	dbf	d0,.wait1

	btst	#10-8,($16,a5)		;test RMB
	bne	.exit			;if not pressed don't copy

	move.l	(4).w,a6
	move.l	(MaxLocMem,a6),d2

	move.l	d2,d0
	move.l	#MEMF_FAST!MEMF_PUBLIC!MEMF_REVERSE,d1	; buggy on pre-39
	jsr	(-$C6,a6)		;AllocMem
	tst.l	d0
	beq.b	.exit
	move.l	d0,a2

	move.l	a2,a1

	lea	$0BAD0000,a0
_absdstp_1	EQU	*-4
	move.w	#CHIPBEGSAVE_LEN/8-1,d0
.cscopy	move.l	(a0)+,(a1)+
	move.l	(a0)+,(a1)+
	dbf	d0,.cscopy

	lea	CHIPBEGSAVE_LEN,a0
	move.l	d2,d0
	sub.l	a0,d0

	lsr.l	#6,d0			;/64
	subq.l	#1,d0
	move.l	d2,d7
	moveq	#4*4,d6
.copy	move.w	d0,($180,a5)
	movem.l	(a0)+,d1-d4		;16
	movem.l	d1-d4,(a1)
	add.l	d6,a1
	movem.l	(a0)+,d1-d4		;16
	movem.l	d1-d4,(a1)
	add.l	d6,a1
	movem.l	(a0)+,d1-d4		;16
	movem.l	d1-d4,(a1)
	add.l	d6,a1
	movem.l	(a0)+,d1-d4		;16
	movem.l	d1-d4,(a1)
	add.l	d6,a1
	dbf	d0,.copy
	move.l	d7,d2

	move.l	a2,$100.w
	move.l	#$DEADBEEF,(a2)+
	move.l	d2,(a2)+
	clr.l	(a2)

	move.w	#0,($180,a5)

.exit	movem.l	(sp)+,d0-a6
.sexit	rts

_earlycode	sub.l	a0,a0
	lea	$0BAD0000,a1
_absdstp_2	EQU	*-4
	move.w	#CHIPBEGSAVE_LEN/8-1,d0
.ecopy	move.l	(a0)+,(a1)+
	move.l	(a0)+,(a1)+
	dbf	d0,.ecopy
_instpos	nop
	nop
	nop
	nop
	jmp	$0BAD0000		;jmppos+10
_jmpromp	EQU	*-4

_name
_idstr	dc.b	'ChipSaver',0
	CNOP	0,2
_end

	SECTION	VERSION,DATA

	dc.b	'$VER: ChipSaver_PATCH 1.1 (5.8.00)',0

