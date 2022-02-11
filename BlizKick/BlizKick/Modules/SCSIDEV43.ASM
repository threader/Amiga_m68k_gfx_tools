; FILE: Source:modules/SCSIDEV43.ASM          REV: 7 --- Install V43 scsi.device

;
; Plant V43 scsi.device -Module
; ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
; This patch module will install V43 scsi.device replacing one inside
; kickstart. It will also disable beta message of the scsi.device :)
;
; Device will be loaded from file "devs:scsi43.device".
;
; This module can't install A4000T_scsidisk 43.34 because it uses
; several hunks. Use V44 SetPatch + AmigaOS ROM Update to load it
; instead.
;
; This module has been tested with following scsi.device (a300.ld.strip)
;  versions:
;
;    43.11 (3.9.96)	Works fine for me.
;    43.17 (12.5.97)	Works, but doesn't recognize my drives! :(
;    43.18 (15.6.97)    Works fine.
;    43.23 (7.11.97)    Works fine.
;    43.24 (9.11.98)    Works fine.
;    43.34 (21.12.99)   Works fine.
;
; Written by Harry Sintonen.
; This source code is Public Domain.
;

	incdir	"include:"		; Some required...
	include	"exec/types.i"
	include	"exec/libraries.i"
	include	"blizkickmodule.i"

SCSI_MAXSIZE	EQU	17352+4096

_LVOCopyMem	EQU	-$270

_LVOIoErr	EQU	-$84
_LVOLoadSeg	EQU	-$96
_LVOUnLoadSeg	EQU	-$9C
_LVOSetIoErr	EQU	-$1CE

call	MACRO
	jsr	(_LVO\1,a6)
	ENDM

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


; NOTE: Kickstart *is* 2.0+

	cmp.w	#39,($C,a0)		; Requires KS ROM V3.1+
	bhs.b	.go
	moveq	#0,d0
	rts

.go	movem.l	d0/a0-a1,-(sp)
	moveq	#0,d7

	lea	(_scsiname,pc),a1	; _FindResident
	jsr	(a2)
	tst.l	d0
	beq	.xit
	move.l	d0,a5			; a5=scsi.device resident

	moveq	#1,d7
	move.l	(RT_IDSTRING,a5),a0
	sub.l	(2*4,sp),a0		;[a1]
	add.l	(1*4,sp),a0		;[a0]
	lea	(_hdiname,pc),a1
	moveq	#12-1,d1		; 'IDE_scsidisk'
.cmp	move.b	(a0)+,d0
	cmp.b	(a1)+,d0
	dbne	d1,.cmp
	tst.w	d1			; Test if already installed
	bmi	.xit

	moveq	#0,d7
	moveq	#-1,d4			; IoErr=-1 (default)
	exg	d6,a6
	lea	(_hddname,pc),a0
	move.l	a0,d1
	call	LoadSeg
	move.l	d0,d5
	beq	.exit

	move.l	d5,a2
	add.l	a2,a2
	add.l	a2,a2
	tst.l	(a2)+			; Requires single hunk exe!
	bne	.baddie			; a2=hunk start

	moveq	#127,d0			; Find resident:
	move.w	#$4AFC,d1
	move.l	a2,a0
.findrt	cmp.w	(a0)+,d1
	dbeq	d0,.findrt
	tst.w	d0
	bmi	.baddie
	subq.l	#2,a0
	cmp.l	(RT_MATCHTAG,a0),a0
	bne.b	.findrt

	tst.b	(RT_FLAGS,a0)		; Allow no RTF_AUTOINIT
	bmi	.baddie

	; a0=residenttag (loadsed), a2=1st seg start
	bsr	makepcrel

	; a0=residenttag (loadsed), a2=1st seg start
	bsr	disablebeta

	lea	(_buf,pc),a1
	move.l	#BKMODULE_ID,(a1)+	; bkm_ID
	move.l	#(0)<<16!RTC_MATCHWORD,(a1)+ ; bkm_Flags RT_MATCHWORD
	clr.l	(a1)+			; RT_MATCHTAG
	moveq	#RT_SIZE,d0
	add.l	(RT_ENDSKIP,a0),d0
	sub.l	a2,d0
	cmp.l	#SCSI_MAXSIZE,d0	; Too big?
	bhi.b	.baddie			; It is quit!

	move.l	d0,(a1)+		; RT_ENDSKIP
	move.l	(RT_FLAGS,a0),(a1)+	; RT_FLAGS,RT_VERSION,RT_TYPE,RT_PRI
	moveq	#RT_SIZE,d0
	add.l	(RT_NAME,a0),d0
	sub.l	a2,d0
	move.l	d0,(a1)+		; RT_NAME
	moveq	#RT_SIZE,d0
	add.l	(RT_IDSTRING,a0),d0
	sub.l	a2,d0
	move.l	d0,(a1)+		; RT_IDSTRING
	moveq	#RT_SIZE,d0
	add.l	(RT_INIT,a0),d0
	sub.l	a2,d0
	move.l	d0,(a1)+		; RT_INIT

	clr.w	(a0)			; Kill old RT_MATCHWORD

	movem.l	a0-a1,-(sp)
	move.l	(RT_ENDSKIP,a0),d0
	sub.l	a2,d0
	move.l	a2,a0
	exg	d6,a6			;ex6--
	call	CopyMem
	movem.l	(sp)+,a0-a1

;      IN: a0=ptr to ROM, d0=rom len, a1=ptr to module, d6=dosbase
	movem.l	(sp),d0/a0		;[d0][a0]
	lea	(_buf,pc),a1

	move.w	($C,a0),d1		; Kludge fix kick version to scsi version...
	move.b	(bkm_ResTag+RT_VERSION,a1),($C+1,a0)
	jsr	(a3)			; _InstallModule
	move.w	d1,($C,a0)		; Restore kick version
	exg	d6,a6			;--ex6
	move.l	d0,d7			; set success flag

	call	IoErr
	move.l	d0,d4

	lea	(_nullstr,pc),a2
	tst.l	d7
	beq.b	.bskip2

;debug	clr.w	(a5)			; Kill ROM scsi.device ROMTag :)

.baddie	lea	(_error2,pc),a2
.bskip2	move.l	d5,d1
	call	UnLoadSeg
	bra.b	.bskip

.exit	lea	(_error1,pc),a2		; a0=fmt
.bskip
	exg	d6,a6
	move.l	d7,d0			; Valid counter?
	bne.b	.xit
	move.l	a2,a0			; a0=fmt
	pea	(_hddname,pc)
	move.l	sp,a1			; a1=array
	jsr	(a4)			; Call _Printf
	addq.l	#4,sp

	move.l	d4,d1
	addq.l	#1,d4
	beq.b	.skip
	exg	d6,a6
	call	SetIoErr
.skip
	moveq	#0,d0			; Return fail
.xit	lea	(3*4,sp),sp
	rts



; a0=residenttag (loadsed), a2=1st seg start
makepcrel	move.l	a0,-(sp)
	move.l	(RT_ENDSKIP,a0),d3	;d3=max
	move.l	a2,d2			;d2=min
	move.l	a2,a0

.mpcloop	addq.l	#2,a0
	cmp.l	a0,d3
	bls.b	.mpcldone

	move.l	(a0),d0
	cmp.l	d0,d2
	bhi.b	.mpcloop
	cmp.l	d0,d3
	bls.b	.mpcloop

	move.l	(-2,a0),d1

	cmp.l	#$4EB90000,d1		; jsr abs.l -> jsr asb(pc); nop
	bne.b	.mpcs0
	sub.l	a0,d0
	move.w	#$4EBA,(-2,a0)
	move.w	d0,(a0)+
	move.w	#$2048,(a0)		; move.l a0,a0 (nop)
	;bra.b	.mpcloop
.mpcs0
	bra.b	.mpcloop
.mpcldone
	move.l	(sp)+,a0
	rts


; a0=residenttag (loadsed), a2=1st seg start
disablebeta	move.l	a0,-(sp)
	moveq	#-(5*4),d3
	add.l	(RT_ENDSKIP,a0),d3	;d3=max
	move.l	(RT_INIT,a0),d2		;d2=min
	move.l	d2,a0

	move.l	#$48E7C0C0,d1		;preload

.loop	addq.l	#2,a0
	cmp.l	a0,d3
	bls.b	.done

	cmp.l	(a0),d1
	bne.b	.loop
	cmp.w	#$206D,(4,a0)
	bne.b	.loop
	tst.b	(6,a0)
	bne.b	.loop
	move.l	(8,a0),d0
	and.l	#$FFFFFFF0,d0
	cmp.l	#$224E7000,d0
	bne.b	.loop
	cmp.w	#$6100,(12,a0)
	bne.b	.loop
	cmp.l	#$4CDF0303,(16,a0)
	bne.b	.loop

	move.w	#$6012,(a0)		;skip it!
.done
	move.l	(sp)+,a0
	rts


_scsiname	dc.b	'scsi.device',0
_hdiname	dc.b	'IDE_scsidisk',0
_hddname	dc.b	'devs:scsi43.device',0

_error1	dc.b	'Couldn''t load "%s"!',10,0
_error2	dc.b	'Couldn''t utilize this %s version!',10,0
_nullstr	EQU	*-1


	CNOP	0,4
_buf	ds.b	SCSI_MAXSIZE+bkm_ResTag+RT_SIZE


	SECTION	VERSION,DATA

	dc.b	'$VER: SCSIDEV43_PATCH 1.3 (8.1.00)',0
