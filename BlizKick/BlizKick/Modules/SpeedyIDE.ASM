; FILE: Source:modules/SpeedyIDE.ASM          REV: 3 --- Speed up scsi.device access

;
; Speed up scsi.device IDE disk access
; ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
; 1.1: Fixed read patch for AmigaOS 3.9 BoingBag2 scsi.device 43.43.
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
.fail	rts

.cont	lea	(scsiname,pc),a1
	jsr	(a2)
	tst.l	d0
	beq.b	.fail

	move.l	d0,a0			; a0=beg of search
	lea	(16384,a0),a1		; a1=end of search

	move.l	#$700F32D0,d1		; moveq #16-1,d0 / move.w  (a0),(a1)+
	move.l	#$32D032D0,d2		; move.w  (a0),(a1)+ / move.w  (a0),(a1)+
	bsr.b	.find
	bne.b	.found_read

	; try locating scsi.device 43.43 read loop
	move.l	#$701F3210,d1		; moveq #32-1,d0 / move.w  (a0),d1
	move.l	#$48413210,d2		; swap  d1 / move.w  (a0),d1
	move.l	#$22C13210,d3		; move.l  d1,(a1)+ / move.w  (a0),d1
	bsr.b	.find2
	beq.b	.not_read
.found_read
	move.l	a0,-(sp)
	move.l	d0,a0
	move.l	#$700722D0,d1		; moveq #8-1,d0 / move.l  (a0),(a1)+
	bsr	.set16
	move.l	(sp)+,a0
.not_read

	move.l	#$700F3099,d1		; moveq #16-1,d0 / move.w  (a1)+,(a0)
	move.l	#$30993099,d2		; move.w  (a1)+,(a0) / move.w  (a1)+,(a0)
	bsr.b	.find
	beq.b	.not_write

	move.l	d0,a0
	move.l	#$70072099,d1		; moveq #8-1,d0 / move.l  (a1)+,(a0)
	bsr.b	.set16
.not_write

	moveq	#1,d0
	rts

;;.not_found	moveq	#0,d0
;;	rts

.find	move.l	a0,-(sp)
.findl	addq.l	#2,a0
	cmp.l	a1,a0
	bhs.b	.fnot_found
	cmp.l	(a0),d1
	bne.b	.findl
	cmp.l	(4,a0),d2
	bne.b	.findl
	cmp.l	(8,a0),d2
	bne.b	.findl
	cmp.l	(12,a0),d2
	bne.b	.findl
	cmp.l	(16,a0),d2
	bne.b	.findl
	move.l	a0,d0
.fexit	move.l	(sp)+,a0
	rts
.fnot_found	moveq	#0,d0
	bra.b	.fexit

.find2	move.l	a0,-(sp)
.find2l	addq.l	#2,a0
	cmp.l	a1,a0
	bhs.b	.f2not_found
	cmp.l	(a0),d1
	bne.b	.find2l
	cmp.l	(4,a0),d2
	bne.b	.find2l
	cmp.l	(8,a0),d3
	bne.b	.find2l
	cmp.l	(12,a0),d2
	bne.b	.find2l
	cmp.l	(16,a0),d3
	bne.b	.find2l
	cmp.l	(20,a0),d2
	bne.b	.find2l
	cmp.l	(24,a0),d3
	bne.b	.find2l
	cmp.l	(28,a0),d2
	bne.b	.find2l
	move.l	a0,d0
.f2exit	move.l	(sp)+,a0
	rts
.f2not_found	moveq	#0,d0
	bra.b	.f2exit

.set16	moveq	#16-1-1,d0
	move.l	d1,(a0)+
.setl	move.w	d1,(a0)+
	dbf	d0,.setl
	rts


scsiname	dc.b	'scsi.device',0


	SECTION	VERSION,DATA

	dc.b	'$VER: SpeedyIDE_PATCH 1.1 (26.3.02)',0

