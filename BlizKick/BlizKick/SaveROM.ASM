; FILE: Source:SaveROM.ASM          REV: 4 --- Kickstart ROM saver.
; History
;  3      Now requires only KS 1.0.
;  4      Made to allocate 1/4 ROM size buffer and copy + write the ROM in
;         4 chunks. Fixes problems with bad device drivers & MMU mapped rom.
;

	include	"exec/types.i"
	include	"exec/memory.i"
	include	"dos/dos.i"

	include	"exec/exec_lib.i"
	include	"dos/dos_lib.i"

Main	move.l	(4).w,a6
	clr.l	-1(a0,d0.l)
	lea	$01000000,a3
	move.l	a0,a5
	move.l	(-$14,a3),d3
	moveq	#RETURN_FAIL,d7
	sub.l	d3,a3
	lsr.l	#2,d3
	beq.b	.exit
	tst.w	d3
	bne.b	.exit
	move.l	d3,d0
	moveq	#MEMF_PUBLIC,d1
	jsr	(_LVOAllocMem,a6)
	tst.l	d0
	beq.b	.exit
	move.l	d0,a4

	lea	(.dosname,pc),a1
	jsr	(_LVOOldOpenLibrary,a6)
	tst.l	d0
	beq.b	.freemem
	move.l	d0,a6
	moveq	#RETURN_ERROR,d7
	move.l	a5,d1
	move.l	#MODE_NEWFILE,d2
	jsr	(_LVOOpen,a6)
	move.l	d0,d6
	beq.b	.closedos

	moveq	#4,d5
.copyloop
	move.l	a4,a0
	move.l	d3,d0
.copy	move.l	(a3)+,(a0)+
	move.l	(a3)+,(a0)+
	subq.l	#8,d0
	bne.b	.copy

	move.l	d6,d1
	move.l	a4,d2
	; d3 = size
	jsr	(_LVOWrite,a6)
	cmp.l	d0,d3
	bne.b	.error
	subq.l	#1,d5
	bne.b	.copyloop

	moveq	#RETURN_OK,d7

.error	move.l	d6,d1
	jsr	(_LVOClose,a6)
	tst.l	d7
	beq.b	.closedos
	move.l	a5,d1
	jsr	(_LVODeleteFile,a6)
.closedos
	move.l	a6,a1
	move.l	(4).w,a6
	jsr	(_LVOCloseLibrary,a6)
.freemem
	move.l	a4,a1
	move.l	d3,d0
	jsr	(_LVOFreeMem,a6)
.exit	move.l	d7,d0
	rts

.dosname	dc.b	'dos.library',0
