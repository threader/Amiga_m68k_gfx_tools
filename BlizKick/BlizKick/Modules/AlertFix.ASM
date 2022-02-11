; FILE: Source:modules/AlertFix.ASM          REV: 5 --- cool Alert fix for 040/060

;
; AlertFix patch for BlizKick ("patch" Module)
; ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
;
; This patch fixes the problems with pending alerts & 680x0.library
; being resident in blizzppc flash. Also fixes two bugs in exec/Alert().
; If NewAlert module is installed make the exec/Alert() call it too
; (meaning that AlertFix should come after NewAlert if both are used).
;
;
; V1.1 - 2nd Feb 2000
; Fixed major bug from the code, it broke regular Alert() calls. Huh.
;
; V1.2 - 5th Feb 2000
; Made it possible to plant AlertFix inside ROM.
;
; V1.3 - 11th Sep 2000
; Now really properly disable MMU instead of 'moves' -hack. Should
; work with 68040 now, I hope. Added internal support for NewAlert
; module. Added fix for two exec/Alert() bugs. Now also patches
; '$104 = ThisTask' -write, was missing before, oops. No longer calls
; Supervisor thru execbase vector, but with direct jsr, should make
; the patch work better during serious error conditions. Now works
; with 68020 and 68030 too.
;
;
; Written by Harry "Piru" Sintonen.
; This source code is Public Domain.

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

	cmp.w	#37,($C,a0)		;requires V37+ rom image
	blo	.exit

	lea	(regs,pc),a5
	movem.l	d0/a0-a4,(a5)

	lea	(.no020p,pc),a1
	btst	#1,($128+1,a6)		AFB_68020 AttnFlags
	beq	.err

	lea	(.resname,pc),a1
	movem.l	(regs,pc),d0/a0
	move.l	(findresident,pc),a2
	jsr	(a2)
	lea	(.nores,pc),a1
	tst.l	d0
	beq	.err

	move.l	d0,a4
	moveq	#4,d2
	move.l	(RT_INIT,a4),a2
	add.l	a2,d2
	move.l	d2,_newalert_addr
	move.l	d2,_backfromh1

	;test if inside rom bounds?
	move.l	(rom_log,pc),d0
	cmp.l	d0,a2
	blo.b	.nofix
	add.l	(rom_size,pc),d0
	cmp.l	d0,a2
	bhs.b	.nofix
	; inside rom, so generate ram buffer address
	sub.l	(rom_log,pc),a2		-$f80000
	add.l	(rom_phys,pc),a2	+buffer
.nofix
	moveq	#0,d3
	cmp.l	#'NewA',(-4,a2)		is it our NewAlert patch?
	beq.b	.na_cont		yep, special handling then

	; check validity of the alert.hook tag
	lea	(.badres,pc),a1
	cmp.l	#$42B80000,(a2)
	bne	.err
	cmp.w	#$48E7,(4,a2)
	bne	.err
	cmp.w	#$242E,(8,a2)
	bne	.err

	; find 'clr.l (0).w' in alert.hook end
	move.w	#1024/2,d0
.find	subq.w	#1,d0
	beq	.err
	addq.l	#2,a2
	cmp.l	#$42B80000,(a2)		'clr.l (0).w'
	bne.b	.find
	cmp.w	#$70FF,(4,a2)		'moveq #-1,d0'
	bne.b	.find
	move.l	a2,d3
.na_cont

	; find $0 and $100 accesses in Alert()
	lea	(.badrom1,pc),a1
	move.l	(rom_phys,pc),a2
	move.w	#16384/2,d0
	lea	($2000,a2),a2
.find2	subq.w	#1,d0
	beq	.err
	addq.l	#2,a2
	cmp.l	#$203C<<16|'HE',(a2)
	bne.b	.find2
	cmp.l	#'LP'<<16|$B0B8,(4,a2)
	bne.b	.find2
	cmp.l	#$21C00000,(12,a2)
	bne.b	.find2
	cmp.l	#$41F80100,(16,a2)
	bne.b	.find2

	; find Alert() DisplayAlert bsr
	lea	(20,a2),a0
	moveq	#64,d0
.find3	subq.l	#1,d0
	beq	.err
	addq.l	#2,a0
	cmp.w	#$6100,(a0)		'bsr.w x'
	bne.b	.find3
	cmp.l	#$4AAE0126,(4,a0)	check for both bugged &
	beq.b	.found3			bugfree 'tst.x IDNestCnt(a6)'
	cmp.l	#$4A2E0126,(4,a0)
	bne.b	.find3
.found3	move.l	a0,d4


	; find VBR bug in Alert()
	moveq	#64,d0
.find4	subq.l	#1,d0
	beq	.err
	addq.l	#2,a0
	cmp.l	#$21FC00F8,(a0)
	bne.b	.find4
	cmp.l	#$002046FC,(6,a0)
	bne.b	.find4
	addq.l	#8,a0
	; inside ram buffer, so generate rom address
	sub.l	(rom_phys,pc),a0	-buffer
	add.l	(rom_log,pc),a0		+$f80000
	move.l	a0,_privi_addr2

	; find Privilege violation exception code
	lea	(.badrom2,pc),a1
	move.l	(rom_phys,pc),a3
	move.w	#8192/2,d0
.find5	subq.w	#1,d0
	beq	.err
	addq.l	#2,a3
	cmp.l	#$0CAF00F8,(a3)
	bne.b	.find5
	cmp.l	#$0002660C,(6,a3)
	bne.b	.find5
	cmp.l	#$2F7C00F8,(10,a3)
	bne.b	.find5
	cmp.l	#$00024ED5,(16,a3)
	bne.b	.find5
	move.l	a3,d5

	; find Supervisor 010+ code
	move.l	(rom_phys,pc),a3
	move.w	#8192/2,d0
.find6	subq.w	#1,d0
	beq	.err
	addq.l	#2,a3
	cmp.l	#$007C2000,(a3)
	bne.b	.find6
	cmp.l	#$518F40D7,(4,a3)
	bne.b	.find6
	cmp.l	#$2F7C00F8,(8,a3)
	bne.b	.find6
	cmp.l	#$00023F7C,(14,a3)
	bne.b	.find6
	; inside ram buffer, so generate rom address
	sub.l	(rom_phys,pc),a3	-buffer
	add.l	(rom_log,pc),a3		+$f80000
	move.l	a3,_svptr1
	move.l	a3,_svptr2


	; finally ready for patching,
	; install the patch code

	movem.l	(regs,pc),d0/a0
	lea	(_AlertFix_module,pc),a1
	move.l	(installmodule,pc),a3
	jsr	(a3)

	; find ourself

	movem.l	(regs,pc),d0/a0
	lea	(_name,pc),a1
	move.l	(findresident,pc),a3
	jsr	(a3)

	lea	(.plantfail,pc),a1
	tst.l	d0
	beq	.err

	move.l	d0,a5
	; (RT_INIT,a5) gives us pointer to RT_INIT as logical address,
	; a5 + RT_SIZE is pointer to data after RT structure (usually
                ; RT_INIT pos) in physical memory.
	move.l	(RT_INIT,a5),a3
	lea	(RT_SIZE,a5),a5

	tst.l	d3
	beq.b	.skip_newalert

	btst	#3,($128+1,a6)		AFB_68040 AttnFlags
	beq.b	.no040p_a

	;lea	(_ahook1-_init,a3),a1
	;move.l	a1,(RT_INIT,a4)
	move.l	a3,(RT_INIT,a4)

	lea	(_ahook2-_init,a3),a1
	move.l	d3,a0
	move.w	#$4EB9,(a0)+
	move.l	a1,(a0)+
.no040p_a
	bra.b	.no_newalert
.skip_newalert
	; okay, we got NewAlert, patch the exception
	; handler to jump it directly.
	lea	(_newalert-_init,a3),a1
	move.l	d4,a0
	move.w	#$4EB9,(a0)+
	move.l	a1,(a0)+
.no_newalert

	btst	#3,($128+1,a6)		AFB_68040 AttnFlags
	beq.b	.no040p_b

	lea	(_alert1-_init,a3),a1
	move.w	#$4EB9,(a2)+
	move.l	a1,(a2)+

	lea	(_alert2-_init,a3),a1
	addq.l	#6,a2
	move.w	#$4EB9,(a2)+
	move.l	a1,(a2)+

	; find the '$104=ThisTask' write
	lea	(.badrom1,pc),a1
	moveq	#32,d0
.find7	subq.l	#1,d0
	beq.b	.err
	addq.l	#2,a2
	cmp.l	#$2A6E0114,(a2)			'move.l $114(a6),a5'
	bne.b	.find7
	lea	(_alert3-_init,a3),a1
	move.w	#$4EB9,(a2)+
	move.l	a1,(a2)+
.no040p_b

	move.l	d5,a0
	lea	(_privi-_init,a3),a1
	move.l	(2,a0),(_privi_addr1-_init,a5)
	move.w	#$4EB9,(a0)+
	move.l	a1,(a0)+

	moveq	#1,d7

.err	tst.l	d7
	bne.b	.exit
	lea	(.errh,pc),a0
	move.l	a1,-(sp)
	move.l	sp,a1
	move.l	(printf,pc),a2
	jsr	(a2)
	addq.l	#4,sp
.exit	move.l	d7,d0
	rts


.resname	dc.b	'alert.hook',13,10,0

.errh	dc.b	'AlertFix: couldn''t %s!',10,0

.no020p	dc.b	'find 68020 or better CPU',0
.nores	dc.b	'find alert.hook',0
.badres	dc.b	'patch alert.hook',0
.badrom1	dc.b	'patch Alert()',0
.badrom2	dc.b	'patch Supervisor()',0
.plantfail	dc.b	'InstallModule(), add some EXTRESBUF',0

	CNOP	0,2
_AlertFix_module
 BK_MOD BKMF_SingleMode,_end,(0)<<24+37<<16+NT_UNKNOWN<<8+(256-54),_name,_idstr,_init

; Singlemode on,
; never init this module, requires KS V37.x or better, module type NT_UNKNOWN, priority -54.

_init	; this code will never be called directly!
_ahook1	moveq	#0,d0
	sub.l	a0,a0
	bsr.b	_write
_backfromh1	EQU	*+2
	jmp	$badc0de

_ahook2	moveq	#0,d0
	sub.l	a0,a0
	bsr.b	_write
	moveq	#-1,d0
	rts

_alert1	addq.l	#4,(sp)
	sub.l	a0,a0
	bsr.b	_read
	cmp.l	#'HELP',d0
	beq.b	.need_help
	cmp.l	#'HELP',(0).w
.need_help	rts

_alert3	move.l	($114,a6),a5
	bra.b	_alert3b

_alert2	addq.l	#6,(sp)
	sub.l	a0,a0
	move.l	#'HELP',d0
	bsr.b	_write

	lea	($100).w,a0
	move.l	d7,d0
	bsr.b	_write
	addq.l	#4,a0
_alert3b	move.l	a5,d0
	;bra.b	_write			fall thru to _write!

;  IN: a0.l = address
;      d0.l = data
; OUT: a0.l = address
_write	movem.l	d1/a1/a5,-(sp)
	lea	(.write,pc),a1
	lea	(runnommu_s,pc),a5
_svptr1	EQU	*+2
	jsr	$badc0de
	movem.l	(sp)+,d1/a1/a5
.write	move.l	d0,(a0)
	rts

;  IN: a0.l = address
; OUT: a0.l = address
;      d0.l = data
_read	movem.l	d1/a1/a5,-(sp)
	lea	(.read,pc),a1
	lea	(runnommu_s,pc),a5
_svptr2	EQU	*+2
	jsr	$badc0de
	movem.l	(sp)+,d1/a1/a5
	rts
.read	move.l	(a0),d0
	rts

_privi	addq.l	#2,(sp)
_privi_addr1	EQU	*+2
	cmp.l	#$badda7a,(4+2,sp)
	beq.b	.ok
_privi_addr2	EQU	*+2
	cmp.l	#$badda7a,(4+2,sp)
	bne.b	.ok
	move.l	(4+2,sp),(sp)
.ok	rts

_newalert	addq.l	#2,(sp)
_newalert_addr	EQU	*+2
	jsr	$badc0de
	tst.b	($126,a6)
	rts


;  IN: a1 = routine to run in supervisor, mmu disabled, end with rts
;      d0/d2-d7/a0/a2-a4 = whatever you like
;      a6 = execbase
; OUT: d1 = scratched
;      d0/d2-d7/a0/a2-a4 = whatever you like
;
runnommu_s
	ori.w	#$700,sr

	movec	tc,d1
	move.l	d1,-(sp)
	movec	cacr,d1
	move.l	d1,-(sp)
	movec	dtt1,d1
	move.l	d1,-(sp)
	movec	dtt0,d1
	move.l	d1,-(sp)
	movec	itt1,d1
	move.l	d1,-(sp)
	movec	itt0,d1
	move.l	d1,-(sp)
	cpusha	bc			make sure the above is written
	cinva	bc

	move.l	#$00FFC000,d1		mark 32-bit: Cacheable, Writethrough
	movec	d1,itt0	
	movec	d1,itt1
	movec	d1,dtt1
	move.l	#$0000C040,d1		mark 24-bit-DMA: Cache-Inhibited, Precise Exception Model
	movec	d1,dtt0
	move.l	#$80008000,d1		instcache + datacache
	movec	d1,cacr
	moveq	#0,d1			turn off possible MMU mapping
	pflusha
	movec	d1,tc
	cpusha	bc
	cinva	bc

	jsr	(a1)

	cpusha	bc
	move.l	(sp)+,d1
	movec	d1,itt0
	move.l	(sp)+,d1
	movec	d1,itt1
	move.l	(sp)+,d1
	movec	d1,dtt0
	move.l	(sp)+,d1
	movec	d1,dtt1
	move.l	(sp)+,d1
	movec	d1,cacr
	move.l	(sp)+,d1
	pflusha
	movec	d1,tc
	cpusha	bc
	cinva	bc
	nop
	rte

_name
_idstr	dc.b	'AlertFix.patchcode',0

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

	dc.b	'$VER: AlertFix_PATCH 1.3 (11.9.00)',0

