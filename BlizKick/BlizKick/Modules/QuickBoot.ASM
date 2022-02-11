; FILE: Source:modules/QuickBoot.ASM          REV: 3 --- QuickBoot module

;
; QuickBoot module for BlizKick 1.20+
; ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
; Written by Harry "Piru" Sintonen.
; This source code is Public Domain.
;
; As I decided to drop QUICKBOOT feature from BlizKick 1.20
; and after getting some requests about getting this feature
; back, I decided to code it as a external module.
;
; Implementation note: Currently supports Blizzard 1230-II,
; -III, and -IV / Blizzard 1240 / Blizzard 1260. No guaratees
; that every card supports this though.
;
; V1.2 - 5th Aug 2000
; Fucked up if the module patch was installed inside ROM. Fixed.
;
;    - Piru
;

	incdir	"include:"
	include	"exec/types.i"
	include	"exec/memory.i"
	include	"exec/execbase.i"

	include	"blizkickmodule.i"


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

	cmp.w	#37,($C,a0)		;requires V37+ rom image
	blo	.exit

	lea	(regs,pc),a5
	movem.l	d0/a0-a4,(a5)

	; find the blizzard card

	lea	(expname,pc),a1
	moveq	#37,d0
	jsr	(-$228,a6)		; OpenLibrary
	move.l	d0,d5
	beq	.exit

	lea	(table,pc),a2
.loop	move.w	(a2)+,d0
	bmi.b	.done
	move.w	(a2)+,d1
	sub.l	a0,a0
	exg	d5,a6
	jsr	(-$48,a6)		; FindCondigDev
	exg	d5,a6
	tst.l	d0
	beq.b	.loop

	move.w	-(a2),_BoardNum
.done
	move.l	d5,a1
	jsr	(-$19e,a6)		; CloseLibrary

	move.w	(_BoardNum,pc),d0
	beq	.nocard



	; find exec.library resident tag

	move.l	(LN_NAME,a6),a1
	movem.l	(regs,pc),d0/a0
	move.l	(findresident,pc),a2
	jsr	(a2)
	tst.l	d0
	beq	.exit

	move.l	d0,a3
	move.l	(RT_INIT,a3),d1

	; d1 = RT_INIT address
	; fix our code to jump here when done

	lea	(jumpaddr,pc),a1
	move.l	d1,(a1)

	; install patch module

	lea	(_quickboot_module,pc),a1
	movem.l	(regs,pc),d0/a0
	move.l	(installmodule,pc),a2
	jsr	(a2)
	tst.l	d0
	beq.b	.exit

	; find ourself

	lea	(_name,pc),a1
	movem.l	(regs,pc),d0/a0
	move.l	(findresident,pc),a2
	jsr	(a2)
	tst.l	d0
	beq.b	.exit

	; fix RT_INIT to jump our patch code

	move.l	d0,a0
	; (RT_INIT,a0) gives us pointer to RT_INIT as logical address
	moveq	#_earlycode-_init,d0
	add.l	(RT_INIT,a0),d0
	move.l	d0,(RT_INIT,a3)

	; all done, return success

	moveq	#1,d7
.exit
	move.l	d7,d0
	rts

.nocard	lea	(.nocards,pc),a0

.perr	move.l	(printf,pc),a2
	jsr	(a2)
	bra.b	.exit


.nocards	dc.b	'QuickBoot: no Blizzard 12x0 found!',10,0


	CNOP	0,2
_quickboot_module
 BK_MOD BKMF_SingleMode,_end,(0)<<24+37<<16+NT_UNKNOWN<<8+(256-128),_name,_idstr,_init

; Singlemode on,
; NEVER INIT module, requires KS V37.x or better, module type NT_UNKNOWN, priority -128.

_init	rts

_earlycode	; a6=execbase
	movem.l	d0-d1/d7/a0-a1,-(sp)

	lea	(LibList,a6),a0
	lea	(expname,pc),a1
	jsr	(-$84,a6)		; Forbid
	jsr	(-$114,a6)		; FindName
	jsr	(-$8a,a6)		; Permit
	move.l	d0,d7
	beq.b	.noexp

	sub.l	a0,a0
	move.w	#$2140,d0
	move.w	(_BoardNum,pc),d1
	exg	d7,a6
	jsr	(-$48,a6)		; FindCondigDev
	exg	d7,a6
	tst.l	d0
	beq.b	.noexp

	move.l	d0,a0
	;bclr	#ERTB_DIAGVALID,(cd_Rom+er_Type,a0)	; Don't run init code!
	bclr	#4,(16+0,a0)		; Don't run init code!
.noexp
	movem.l	(sp)+,d0-d1/d7/a0-a1
	dc.w	$4ef9
jumpaddr	dc.l	$badc0de

_BoardNum	dc.w	0

expname	dc.b	'expansion.library',0

_name
_idstr	dc.b	'QuickBoot.patch',0
	CNOP	0,2
_end


	CNOP	0,2
table	dc.w	$2140,$11	; 1230-IV/1240/1260
	dc.w	$2140,$0D	; 1230-III
	dc.w	$2140,$0B	; 1230-II
	dc.w	-1

regs
rom_size	ds.l	1
rom_phys	ds.l	1
rom_log	ds.l	1
findresident	ds.l	1
installmodule	ds.l	1
printf	ds.l	1



	SECTION	VERSION,DATA

	dc.b	'$VER: QuickBoot_PATCH 1.2 (5.8.00)',0

