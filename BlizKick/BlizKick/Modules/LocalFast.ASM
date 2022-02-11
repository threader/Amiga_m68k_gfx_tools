; FILE: Source:modules/LocalFast.ASM          REV: 4 --- LocalFast module

;
; LocalFast module for BlizKick 1.20+
; ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
; Written by Harry "Piru" Sintonen.
; This source code is Public Domain.
;
; As I decided to drop LOCALFAST feature from BlizKick 1.20
; and after getting some requests about getting this feature
; back (hi Hexaae;), I decided to code it as a external
; module.
;
; Imlementation note: this module WILL be confused by PoolMem.
; Doesn't crash, but will refuse to install.
;
; V1.2 - 24th Feb 2000
; Fixed stupid bug: it didn't sub 512k from memory size even when
; it was needed. This kindof made this module unusable until now.
; sorry :)
;
; V1.3 - 5th Aug 2000
; Fixed really stupid bug: the memory node name was referencing
; wrong memory (the mem used when loading the module!). Fixed with
; simple memname pc-relativity inside the module patch code.
; Special thanks to Hexaae, now the bug is finally fixed.. :-)
; LocalFast also fucked up if the LocalFast patch was installed
; inside ROM. Fixed that too.
;
;    - Piru
;

	incdir	"include:"
	include	"exec/types.i"
	include	"exec/memory.i"
	include	"exec/execbase.i"

	include	"blizkickmodule.i"

; PoolMem uses this to indicate small pool MemHeader.
	BITDEF	MEM,POOLMEM,4


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

	; find the blizzard memory header

	jsr	(-$84,a6)		; Forbid
	lea	(MemList,a6),a5
	lea	(LH_TAIL,a5),a4		; end marker
.scanloop	move.l	(a5),a5
	cmp.l	a5,a4			; list end reached?
	beq	.nomem

	move.w	(MH_ATTRIBUTES,a5),d0

	; this is a 1st PoolMem check...
	btst	#MEMB_POOLMEM,d0
	bne	.poolmem

	; Find public fast, that has no MEMF_POOLMEM, MEMF_CHIP,
	; MEMF_KICK or MEMF_LOCAL set:
	and.w	#MEMF_POOLMEM!MEMF_CHIP!MEMF_FAST!MEMF_PUBLIC!MEMF_KICK!MEMF_LOCAL,d0
	cmp.w	#MEMF_FAST!MEMF_PUBLIC,d0
	bne.b	.scanloop

	cmp.l	#$01000000,(MH_LOWER,a5) ; must be 32bit mem
	blo.b	.scanloop

;;	move.l	(LN_NAME,a5),d0		; some logic to check node name
;;	beq.b	.found
;;	move.l	d0,a2
;;	move.l	(a2),d0
;;	or.l	#$20202020,d0		; To lowercase
;;	cmp.l	#'bliz',d0
;;	beq.b	.found
;;	tst.b	(a2)			; null name -> buggy AllocMem result test!
;;	bne.b	.scanloop
;;.found
	move.l	(MH_UPPER,a5),d1

	move.l	#$07FFFF,d0		; this is a 2nd PoolMem check...
	and.l	d1,d0
	bne	.poolmem

	move.l	#$80000,d0		; is upper at 512k boundary?
	and.l	d1,d0
	bne.b	.is_ok			; yup! it's already ok then!
	sub.l	#$80000,d1		; nope. snip off last 512k!
.is_ok

	move.l	(MH_LOWER,a5),d0
	clr.w	d0			; mask out MH stuff
	lea	(aml_regs,pc),a0
	sub.l	d0,d1			; d1=mem size

	move.l	d1,(a0)+		; size

	move.w	(MH_ATTRIBUTES,a5),d1
	and.l	#MEMF_PUBLIC!MEMF_FAST!MEMF_LOCAL!MEMF_24BITDMA,d1
	move.l	d1,(a0)+		; attrs

	move.b	(LN_PRI,a5),d1
	extb.l	d1			; sign extend b -> l
	move.l	d1,(a0)+		; pri

	move.l	d0,(a0)+		; base

	move.l	(LN_NAME,a5),d0
	beq.b	.lmpfixname
	move.l	d0,a1
	tst.b	(a1)
	bne.b	.lmphasname
.lmpfixname
	lea	(.fixedname,pc),a1
.lmphasname
	moveq	#32-2,d0
.lmpcopy	move.b	(a1)+,(a0)+
	dbeq	d0,.lmpcopy
	beq.b	.lmpnoname
	clr.b	(a0)+
.lmpnoname
	jsr	(-$8a,a6)		; Permit

	; find exec.library resident tag

	lea	(.execname,pc),a1
	movem.l	(regs,pc),d0/a0
	move.l	(findresident,pc),a2
	jsr	(a2)
	tst.l	d0
	beq	.exit

	move.l	d0,a3
	move.l	(RT_INIT,a3),d1

	;test if inside rom bounds?
	move.l	(rom_log,pc),d0
	cmp.l	d0,d1
	blo.b	.nofix
	add.l	(rom_size,pc),d0
	cmp.l	d0,d1
	bhs.b	.nofix
	; inside rom, so generate ram buffer address
	sub.l	(rom_log,pc),d1		; -$f80000
	add.l	(rom_phys,pc),d1	; +buffer
.nofix
	; d1 = RT_INIT address
	; fix our code to jump here when done

	lea	(jumpaddr,pc),a1
	move.l	d1,(a1)

	; install patch code...

	lea	(_localfast_module,pc),a1
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

	; fix the exec RT_INIT pointer to jump
	; our patch code...

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

.nomem	lea	(.nomemerr,pc),a0

.perr	jsr	(-$8a,a6)		; Permit
	move.l	(printf,pc),a2
	jsr	(a2)
	bra.b	.exit

.poolmem	lea	(.poolmemerr,pc),a0
	bra.b	.perr

.execname	dc.b	'exec.library',0
.nomemerr	dc.b	'LocalFast: suitable memory header not found!',10,0
.poolmemerr	dc.b	'LocalFast: PoolMem has messed up Memory headers!',10,0
.fixedname	dc.b	'Blizzard_Mem',0


	CNOP	0,2
_localfast_module
 BK_MOD BKMF_SingleMode,_end,(0)<<24+37<<16+NT_UNKNOWN<<8+(256-128),_name,_idstr,_init

; Singlemode on,
; NEVER INIT module, requires KS V37.x or better, module type NT_UNKNOWN, priority -128.

_init	rts

_earlycode	; a6=execbase
	movem.l	d0-d2/a0-a1,-(sp)

	; is this memory already present?
	move.l	(aml_base,pc),a1
	lea	(256,a1),a1		; skip possible MH
	jsr	(-$216,a6)		; TypeOfMem
	tst.l	d0
	bne.b	.already		; it is, skip!

	; add the memory!
	movem.l	(aml_regs,pc),d0-d2/a0
	lea	(memname,pc),a1
	jsr	(-$26a,a6)		; AddMemList
.already
	movem.l	(sp)+,d0-d2/a0-a1
	dc.w	$4ef9
jumpaddr	dc.l	$badc0de

aml_regs	dc.l	0			; d0 size
	dc.l	0			; d1 attrs
	dc.l	0			; d2 pri
aml_base	dc.l	0			; a0 base
memname	ds.b	32			; space for memory name

_name
_idstr	dc.b	'LocalFast.patch',0
	CNOP	0,2
_end


	CNOP	0,2
regs
rom_size	ds.l	1
rom_phys	ds.l	1
rom_log	ds.l	1
findresident	ds.l	1
installmodule	ds.l	1
printf	ds.l	1



	SECTION	VERSION,DATA

	dc.b	'$VER: LocalFast_PATCH 1.3 (5.8.00)',0

