; FILE: Source:modules/hackdisk.ASM          REV: 26 --- Install hackdisk.device

;
; Plant hackdisk.device -Module
; ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
; This patch module will plant hackdisk.device into current ROM image, so
; replacing trackdisk.device.
;
; Device will be loaded from file "devs:hackdisk.device".
;
; hackdisk.device is copyright © 1992,93 by Dan Babcock.
; Version 2.04 is copyright © 1996-1997 by Harry Sintonen. =o)
;
; Actually, version 2.04 of hackdisk.device was "made" (haha!) by me
; to be compatible with BlizKick. Version 2.02 had a bug which caused
; it to fail when used with this module (it tried to open
; intuition.library before it was even initialized. I had to modify it,
; because changing trackdisk.device's residenttag priority would have
; been too hackish. Trackdisk (and hackdisk!) has priority 20 and
; intuition has 10).
;
; This module has been tested with version 2.04.
;
; 1.2: Made it possible to patch trackdisk.device that is inside
;      extresbuf.
;
; Written by Harry Sintonen.
; This source code is Public Domain.
;

	incdir	"include:"		; Some required...
	include	"exec/types.i"
	include	"exec/libraries.i"
	include	"blizkickmodule.i"

_LVOAllocMem	EQU	-$C6
_LVOFreeMem	EQU	-$CC
_LVOCopyMem	EQU	-$270

_LVOOpen	EQU	-$1E
_LVOClose	EQU	-$24
_LVORead	EQU	-$2A
_LVOSeek	EQU	-$42
_LVOInternalLoadSeg	EQU	-$2F4		; 2.0+
_LVOInternalUnLoadSeg	EQU	-$2FA

MODE_OLDFILE	EQU	1005
OFFSET_CURRENT	EQU	0
HUNK_RELOC32	EQU	1004

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

	cmp.w	#33,($C,a0)		; Requires KS ROM V1.2+
	bhs.b	.go
	moveq	#0,d0
	rts

.go
	lea	(regs,pc),a5
	movem.l	d0/a0-a1,(a5)

	moveq	#0,d7

	lea	(_tdname,pc),a1		; _FindResident
	jsr	(a2)
	tst.l	d0
	beq	.xit
	move.l	d0,a5			; a5=trackdisk resident

	moveq	#1,d7
	move.l	(RT_IDSTRING,a5),d0
	beq	.xit
	bsr	buffer
	move.l	d0,a0
	lea	(_hdiname,pc),a1	; NOTE: lowercase!
	moveq	#8-1,d1			; 'hackdisk'
.cmp	move.b	(a0)+,d0
	or.b	#32,d0			; lowercase
	cmp.b	(a1)+,d0
	dbne	d1,.cmp
	tst.w	d1			; Test if already installed
	bmi	.xit

	moveq	#0,d7
	exg	d6,a6
	lea	(_hddname,pc),a0
	move.l	a0,d1
	move.l	#MODE_OLDFILE,d2
	call	Open
	move.l	d0,d4
	beq	.exit

	; d0 = fh
	sub.l	a0,a0
	lea	(funcs,pc),a1
	subq.l	#4,sp
	move.l	sp,a2
	call	InternalLoadSeg
	addq.l	#4,sp
	move.l	d0,d5
	beq	.close
	bmi	.baddie

	move.l	d5,a2
	add.l	a2,a2
	add.l	a2,a2			; aptr 1st hunk
	tst.l	(a2)+			; Requires single hunk exe!
	bne	.baddie			; a2=hunk start

	move.l	(RT_ENDSKIP,a5),d0
	bsr	buffer
	move.l	d0,d2			; d2 = rt_endskip in buffer
	move.l	(RT_ENDSKIP,a2),d1
	sub.l	a2,d1			; d1=hd res size
	sub.l	a5,d2			; d2=td res size
	cmp.l	d2,d1
	bhi	.baddie			; if hd>td fail!

BUFSIZE	EQU	512
	lea	(-BUFSIZE,sp),sp
.scan	move.l	d4,d1			; Scan backwards for HUNK_RELOC32:
	moveq	#-8,d2			; This is *really* heavy magic...
	moveq	#OFFSET_CURRENT,d3
	call	Seek
	tst.l	d0
	bmi.b	.baddie2
	move.l	d4,d1
	move.l	sp,d2
	moveq	#4,d3
	call	Read
	cmp.l	d0,d3
	bne.b	.baddie2
	cmp.l	#HUNK_RELOC32,(sp)
	bne.b	.scan

	move.l	d4,d1			; Read reloc table
	move.l	sp,d2
	move.l	#BUFSIZE,d3
	call	Read
	tst.l	d0
	bmi.b	.baddie2

	move.l	sp,a0
	move.l	(a0)+,d3		; d3=number of relocs
	tst.l	(a0)+			; Must be hunk0 relocs!
	bne.b	.scan
	move.l	d3,d1
	lsl.l	#2,d1
	tst.l	(a0,d1.l)		; Must be only relocs!
	bne.b	.scan

	move.l	(RT_ENDSKIP,a2),d0
	sub.l	a2,d0
	move.l	d0,-(sp)		; (sp)=hd res size

	move.l	a5,d0
	bsr	romaddress
	sub.l	a2,d0

.subl	move.l	(a0)+,d2		; ReRelocate :)
	add.l	d0,(a2,d2.l)
	subq.l	#1,d3
	bne.b	.subl

	move.l	a2,a0			; Copy it!
	move.l	a5,a1
	move.b	(RT_VERSION,a1),(RT_VERSION,a0)
	move.b	(RT_PRI,a1),(RT_PRI,a0)
	move.l	(sp)+,d0		; d0=hd res size
	exg	d6,a6
	call	CopyMem
	exg	d6,a6

; As a side remark: This "loadseg-scanbackforrelocs-rerelocate-copy" 
; -code worked at first try! Honestly I didn't think it would... ;)

	moveq	#1,d7			; Succeed!

.baddie2	lea	(BUFSIZE,sp),sp

.baddie	lea	(freefunc,pc),a1
	move.l	d5,d1
	call	InternalUnLoadSeg

.close	move.l	d4,d1
	call	Close

.exit	exg	d6,a6
	move.l	d7,d0			; Valid counter?
	bne.b	.xit
	lea	(_error1,pc),a0		; a0=fmt
	pea	(_hddname,pc)
.fail	move.l	sp,a1			; a1=array
	jsr	(a4)			; Call _Printf
	addq.l	#4,sp
	moveq	#0,d0			; Return fail
.xit	rts

.perr	lea	(_error2,pc),a0
	pea	(_hdiname,pc)
	bra.b	.fail	


funcs	dc.l	readfunc
	dc.l	allocfunc
	dc.l	freefunc

readfunc	jmp	(_LVORead,a6)
allocfunc	jmp	(_LVOAllocMem,a6)
freefunc	jmp	(_LVOFreeMem,a6)


buffer	;test if inside rom bounds?
	move.l	(rom_log,pc),d1
	cmp.l	d1,d0
	blo.b	.nofix
	add.l	(rom_size,pc),d1
	cmp.l	d1,d0
	bhs.b	.nofix
	; inside rom, so generate ram buffer address
	sub.l	(rom_log,pc),d0		-$f80000
	add.l	(rom_phys,pc),d0	+buffer
.nofix	rts

romaddress	;test if inside rom buffer bounds?
	move.l	(rom_phys,pc),d1
	cmp.l	d1,d0
	blo.b	.nofix
	add.l	(rom_size,pc),d1
	cmp.l	d1,d0
	bhs.b	.nofix
	; inside rom, so generate ram buffer address
	sub.l	(rom_phys,pc),d0	-buffer
	add.l	(rom_log,pc),d0		+$f80000
.nofix	rts

_tdname	dc.b	'trackdisk.device',0
_hdiname	EQU	*+5
_hddname	dc.b	'devs:hackdisk.device',0

_error1	dc.b	'Couldn''t load "%s"!',10,0
_error2	dc.b	'Couldn''t utilize this %s version!',10,0

	CNOP	0,2
regs
rom_size	ds.l	1
rom_phys	ds.l	1
rom_log	ds.l	1

	SECTION	VERSION,DATA

	dc.b	'$VER: hackdisk_PATCH 1.2 (13.12.00)',0
