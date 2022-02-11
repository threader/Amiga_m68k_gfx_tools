; FILE: Source:modules/NoClick.ASM          REV: 6 --- NoClick patch

;
; Drive NoClick -Module
; ~~~~~~~~~~~~~~~~~~~~~
; This patch module will turn off drive clicking at very early time...
; Actually my floppy drive manages to click only once upon reset... :)
;
; 1.0: Initial release
; 1.1: Added support for hackdisk.device. You must specify NoClick
;      module *AFTER* hackdisk module if you want it function!
; 1.2: Made it possible to patch trackdisk.device that is fully or
;      partially inside extresbuf. Changed the way the patch is
;      applied to avoid problems with specific ROM version (40.70
;      A3000 and A4000 had problems, however 40.70 A4000T worked).
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

	moveq	#0,d7

	cmp.w	#37,($C,a0)		; Requires KS V37+
	blo	.exit

	lea	(regs,pc),a5
	movem.l	d0/a0-a1,(a5)

	lea	(_tdname,pc),a1		; _FindResident
	jsr	(a2)
	tst.l	d0
	beq.b	.exit
	move.l	d0,a2			; a2=trackdisk resident

	cmp.b	#37,(RT_VERSION,a2)	; V37+
	blo.b	.exit
	btst	#RTB_COLDSTART,(RT_FLAGS,a2) ; Coldstart
	beq.b	.exit
	move.l	(RT_IDSTRING,a2),d0
	beq.b	.exit
	bsr	buffer
	move.l	d0,a5			; a5=RT_IDSTRING in buffer

	cmp.b	#'H',(a5)+		; Hackdisk.device?
	bne.b	.nhackd
	cmp.b	#'a',(a5)
	beq.b	.ishackd
.nhackd
	move.l	a2,a5			; a5=ptr in buffer
	move.l	(RT_ENDSKIP,a2),d0
	bsr	buffer
	sub.l	a2,d0
	lsr.l	#1,d0
	subq.l	#8,d0			; max num of words to search
	ble.b	.perr

.find	addq.l	#2,a5			; Magic Begins Here:
	subq.l	#1,d0
	beq.b	.exit
	cmp.l	#$FFFFFFFF,(a5)		; tdu_Comp10Track = -1, tdu_Comp11Track = -1
	bne.b	.find
	tst.w	(4,a5)			; (tdu_tdu_StepDelay & 0xffff0000) == 0
	bne.b	.find
	cmp.l	#15000,(8,a5)		; tdu_SettleDelay = 15000
	bne.b	.find
	cmp.l	#(10<<24)|(0<<16)|$ffff,(12,a5)	;tdu_RetryCnt = 10, tdu_PubFlags = 0, tdu_CurrTrk = -1
	bne.b	.find
	or.b	#1,(12+1,a5)		; tdu_PubFlags = TDPF_NOCLICK
	moveq	#1,d7
	bra.b	.find

.exit	move.l	d7,d0			; Valid counter?
	bne.b	.xit
	lea	(_error1,pc),a0		; a0=fmt
	pea	(_tdname,pc)
	move.l	sp,a1			; a1=array
	jsr	(a4)			; Call _Printf
	addq.l	#4,sp
.fail	moveq	#0,d0			; Return fail
.xit	rts

.perr	lea	(_error2,pc),a0
	jsr	(a4)			; Call _Printf
	bra.b	.fail	


	; Handle hackdisk.device
.ishackd
	bclr	#0,d0			; Align word
	move.l	d0,a5			; a5=ptr in buffer

	move.l	#8192/2,d0		; Max Num of words to seach
.hfind	addq.l	#2,a5			; MoreMagic Begins Here:
	subq.l	#1,d0
	beq.b	.perr
	cmp.l	#$08EC0001,(a5)
	bne.b	.hfind
	cmp.w	#53,(4,a5)		; TDU_PUBFLAGS
	bne.b	.hfind

	move.l	#$197C0003,(a5)		; Change!
	moveq	#1,d7
	bra.b	.exit



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



_tdname	dc.b	'trackdisk.device',0

_error1	dc.b	'NoClick: This patch requires %s V37+!',10,0
_error2	dc.b	'NoClick: Couldn''t patch!',10,0

	CNOP	0,2
regs
rom_size	ds.l	1
rom_phys	ds.l	1
rom_log	ds.l	1

	SECTION	VERSION,DATA

	dc.b	'$VER: NoClick_PATCH 1.2 (13.12.00)',0
