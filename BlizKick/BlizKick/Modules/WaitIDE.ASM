; FILE: Source:modules/WaitIDE.ASM          REV: 9 --- Fix KS to wait all IDE devices.

;
; Fix scsi.device to wait all IDE devices
; ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
; 1.1: Added support for 43.17 scsi.device although it doesn't work. :)
;      Maybe 43.18 will work then.
; 1.2: Fixed error reporting when the module is loaded to EXTRESBUF and
;      the patching fail.
;
; Note: Until someone show me good reason why he need this module applied
; to AmigaOS 3.5 or AmigaOS 3.9 scsi.device, the module will fail.
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

	cmp.w	#39,($C,a0)		; V37 support _could_ be added...
	bhs.b	.cont
	moveq	#0,d0
	rts

.cont	movem.l	d0/a0-a1,-(sp)

	lea	(scsiname,pc),a1
	jsr	(a2)
	tst.l	d0
	beq	.fail
	move.l	d0,a5

	move.l	a5,a0			; a0=beg of search
	lea	(16384,a0),a1		; a1=end of search

	move.l	#$FFC0FFFF,d1
	move.l	#$70001E80,d2		; moveq #x,d0 / move.b  d0,(sp)
	move.l	#$196F0003,d3		; move.b  $03(sp),x(a4)
	move.l	#$0000122C,d4		; move.b  x(a4),d1
	move.l	#$0000102C,d5		; move.b  x(a4),d0

.find	addq.l	#2,a0
	cmp.l	a1,a0
	bhs.b	.try_new
	move.l	(a0),d0
	and.l	d1,d0
	cmp.l	d2,d0
	bne.b	.find
	cmp.l	(4,a0),d3
	bne.b	.find
	move.l	(8,a0),d0
	and.l	d1,d0
	cmp.l	d4,d0
	bne.b	.find
	move.l	(12,a0),d0
	and.l	d1,d0
	cmp.l	d5,d0
	bne.b	.find

	tst.b	(1,a0)
	beq.b	.is_only2nd

.doit	move.b	#$7F,(1,a0)
	moveq	#1,d0
	bra.b	.noerr

.is_only2nd	lea	(-10,a0),a0
	cmp.b	#$70,(a0)
	bne.b	.not_found
	tst.b	(1,a0)
	bne.b	.doit
	bra	.not_found


	; Scan for new: (43.17 at least)

.try_new	move.l	a5,a0			; a0=beg of search
	lea	(16384,a0),a1		; a1=end of search

	IFGT	0

	move.l	#$B23C<<16!13,d1
	move.l	#$FFFFFC00,d2
	move.l	#$66000000,d3
	move.l	#$FFC0FFFF,d4
	move.l	#$7000082F,d5

.nfind	addq.l	#2,a0
	cmp.l	a1,a0
	bhs.b	.not_found
	cmp.l	(a0),d1
	bne.b	.nfind
	move.l	(4,a0),d0
	and.l	d2,d0
	cmp.l	d3,d0
	bne.b	.nfind
	move.l	(8,a0),d0
	and.l	d4,d0
	cmp.l	d5,d0
	bne.b	.nfind

	addq.l	#8,a0
	bra.b	.doit

	ELSE

	move.l	#$FFFFFFC0,d1
	move.l	#$1EBC0000,d2		; move.b  #x,(sp)
	move.l	#$FFFFFFC0,d3
	move.l	#$102C0000,d4		; move.b  x(a4),d0

.nfind	addq.l	#2,a0
	cmp.l	a1,a0
	bhs.b	.not_found
	move.l	(a0),d0
	and.l	d1,d0
	cmp.l	d2,d0
	bne.b	.nfind
	move.l	(4,a0),d0
	and.l	d3,d0
	cmp.l	d4,d0
	bne.b	.nfind

	addq.l	#2,a0
	bra.b	.doit

	ENDC

.not_found
	movem.l	(1*4,sp),d0/d1		;[a0] rom_phys, [a1] rom_log
	move.l	(RT_IDSTRING,a5),a0

	cmp.l	d1,a0
	blo.b	.nofix
	add.l	(sp),d1			;[d0] rom_size
	cmp.l	d1,a0
	bhs.b	.nofix
	sub.l	d1,a0			;[a1] (rom_log)
	add.l	d0,a0			;[a0] (rom_phys)
.nofix
	move.l	a0,-(sp)
	move.l	sp,a1
	lea	(fmt1,pc),a0
	jsr	(a4)
	addq.l	#4,sp

.fail	moveq	#0,d0
.noerr	lea	(3*4,sp),sp
	rts


scsiname	dc.b	'scsi.device',0
fmt1	dc.b	'Couldn''t patch %s',0


	SECTION	VERSION,DATA

	dc.b	'$VER: WaitIDE_PATCH 1.2 (26.3.02)',0

