; FILE: Source:modules/SoftSCSI.ASM          REV: 20 --- Softkick SCSI ROM

;
; SoftSCSI -Module
; ~~~~~~~~~~~~~~~~
; This module will replace the SCSI (ep)rom (27C256) found from BLIZZARD
; turbo boards via software. Should work with 1230-IV, 1240-T/ERC and 1260.
;
; +--------------+------------------------
; |  1230-IV     |
; |  1240-T/ERC  |     A1234.ROM
; |  1260        |
; +--------------+------------------------
;
; The ROM file *must* be "DEVS:Modules/A1234.ROM".
; Note that this module requires lots of rom space (~20K), so you should
; use EXTRESBUF feature of BlizKick.
;
; Beta ROM file can be obtained from phase5's ftp server ftp.phase5.de,
; directory /pub/phase5/BETA/SCSI/.
;
; This module does the same thing as SoftSCSI
; (Aminet: util/boot/SoftSCSI.lha) by Gideon Zenz.
;
; Written by Harry Sintonen.
; This source code is Public Domain.
;

	incdir	"include:"		; Some required...
	include	"exec/types.i"
	include	"exec/libraries.i"
	include	"libraries/configvars.i"
	include	"blizkickmodule.i"

_LVOOpenLibrary		EQU	-$228
_LVOCloseLibrary	EQU	-$19E

_LVOOpen		EQU	-$1E
_LVOClose		EQU	-$24
_LVORead		EQU	-$2A

_LVOFindConfigDev	EQU	-$48

MODE_OLDFILE		EQU	1005
OFFSET_BEGINNING	EQU	-1
OFFSET_CURRENT		EQU	0
OFFSET_END		EQU	1

call	MACRO
	jsr	(_LVO\1,a6)
	ENDM


BLIZPROD	EQU	$2140
XROM_BUFSIZE	EQU	32768


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

	cmp.w	#37,($C,a0)		; Requires KS ROM V2.04+
	bhs.b	.go
	moveq	#0,d0
	rts

.go	movem.l	d0/a0-a1,-(sp)
	moveq	#0,d7

	lea	(_sscsi_name,pc),a1	; _FindResident
	jsr	(a2)
	tst.l	d0
	bne	.xit			; Already installed!

	lea	(_ExpName,pc),a1
	moveq	#37,d0
	call	OpenLibrary
	move.l	d0,d5
	beq	.xit

	sub.l	a0,a0			; BUG: was missing!
	move.l	#BLIZPROD,d0		; Requires 1230-IV, 1240 or 1260!
	moveq	#$11,d1
	exg	d5,a6
	call	FindConfigDev
	exg	d5,a6
	move.l	d0,d2
	move.l	d5,a1
	call	CloseLibrary
	tst.l	d2
	beq	.berr			; Need board!

	exg	d6,a6
	lea	(_1200name,pc),a0
	move.l	a0,d1
	move.l	#MODE_OLDFILE,d2
	call	Open
	move.l	d0,d5
	beq.b	.exitd			; No file!

	lea	(_ROMImage,pc),a5	
	move.l	d5,d1
	move.l	a5,d2
	moveq	#4,d3
	call	Read
	cmp.l	d0,d3
	bne.b	.readerr		; bad romfile!
	cmp.l	#'XROM',(a5)
	bne.b	.readerr		; bad romfile!

	move.l	d5,d1
	move.l	#XROM_BUFSIZE,d3	; Read it!
	call	Read
	tst.l	d0
	bmi.b	.readerr		; bad romfile!
	add.l	d0,_softscsi_module+bkm_ResTag+RT_ENDSKIP  ; magic... :)

	movem.l	(sp),d0/a0
	lea	(_softscsi_module,pc),a1
	exg	d6,a6			; d6=dosbase !!
	jsr	(a3)			; _InstallModule
	exg	d6,a6
	tst.l	d0
	beq.b	.installerr		; Failed!

	moveq	#1,d7			; All ok!

.readerr	move.l	d5,d1
	call	Close

.exitd	exg	d6,a6
.exit	move.l	d7,d0			; Valid counter?
	bne.b	.xit
	lea	(_error1,pc),a0		; a0=fmt
.fail	pea	(_1200name,pc)
	pea	(_header,pc)
	move.l	sp,a1			; a1=array
	jsr	(a4)			; Call _Printf
	addq.l	#8,sp
	moveq	#0,d0			; Return fail
.xit	lea	(3*4,sp),sp
	rts

.berr	lea	(_error2,pc),a0
	bra.b	.fail	


.installerr	move.l	d5,d1
	call	Close
	exg	d6,a6
	lea	(_error3,pc),a0		; a0=fmt
	bra.b	.fail	


_1200name	dc.b	'DEVS:Modules/A1234.ROM',0

_header	dc.b	'SoftSCSI: ',0
_error1	dc.b	'%sCouldn''t load "%s"!',10,0
_error2	dc.b	'%sRequires BLIZZARD 1230-IV, 1240-T/ERC or 1260 turbo board.',10,0
_error3	dc.b	'%sCouldn''t plant module! (increase EXTRESBUF)',10,0

	CNOP	0,4
_softscsi_module
 BK_MOD BKMF_SingleMode,_patch_end,(RTF_COLDSTART)<<24!37<<16!NT_UNKNOWN<<8!104,_sscsi_name,_sscsi_name,.SoftSCSI

;  IN: d0=0, a0=0?, a6=execbase
.SoftSCSI	movem.l	d0-a6,-(sp)
	lea	(_ExpName,pc),a1
	moveq	#37,d0
	call	OpenLibrary
	move.l	d0,d6
	beq.b	.exit

	sub.l	a0,a0
	move.l	#$2140,d0
	moveq	#$11,d1
	exg	d6,a6
	call	FindConfigDev
	exg	d6,a6
	tst.l	d0
	beq.b	.close

	move.l	d0,a0
	move.l	(cd_Rom+er_Reserved0c,a0),a0	; a0=DiagArea
	lea	(14,a0),a1
	move.l	(26,a1),a0
	move.l	(30,a1),a3
	lea	(34,a1),a4		; a6=execbase
	movem.l	d6/a6,-(sp)
	bsr.b	_Code
	movem.l	(sp)+,d6/a6

.close	move.l	d6,a1
	call	CloseLibrary

.exit	movem.l	(sp)+,d0-a6
	rts

_ExpName	dc.b	'expansion.library',0
_sscsi_name	dc.b	'SoftSCSI',0
	CNOP	0,8
_ROMImage
_Code
_patch_end					; MUST be here!
	ds.b	XROM_BUFSIZE


	SECTION	VERSION,DATA

	dc.b	'$VER: SoftSCSI_MODULE 1.2 (10.3.97)',0
