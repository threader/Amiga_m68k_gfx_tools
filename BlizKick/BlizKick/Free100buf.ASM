; FILE: Source:Free100buf.ASM          REV: 17 --- Free std $100-buf

	include	"Devpac:Gen.gs"


Main	move.l	(4).w,a6		; Get execbase
	sub.l	a1,a1			; Find our task
	jsr	-$126(a6)		;FindTask
	move.l	d0,a3

	tst.l	$AC(a3)			; pr_CLI
	bne.s	_main			; Hey we're CLI!

	lea	$5C(a3),a0		; pr_MsgPort
	jsr	-$180(a6)		;WaitPort
	lea	$5C(a3),a0		; pr_MsgPort
	jsr	-$174(a6)		;GetMsg
	move.l	d0,-(sp)

	bsr.s	_main
	move.l	d0,d2			; Store return code

	move.l	4.w,a6
	move.l	(sp)+,a1
	jsr	-$84(a6)		;Forbid
	jsr	-$17A(a6)		;ReplyMsg

	move.l	d2,d0			; WOW! Return code is set.
	rts


_main	moveq	#RETURN_WARN,d7

	call	Forbid
	move.l	($100).w,a2

	move.l	a2,a1
	bsr.b	.testmem
	beq.b	.nomem

	move.l	a2,a1
	add.l	(4,a2),a1
	subq.l	#1,a1
	bsr.b	.testmem
	beq.b	.nomem

	cmp.l	#$DEADBEEF,(a2)
	bne.b	.nomem
	cmp.l	#$200000*4,(4,a2)
	bhi.b	.nomem

	move.l	a2,a1
	move.l	(4,a2),d0
	bsr	FreeMemSafely

	tst.l	_ErrFlag
	bne.b	.nomem

	clr.l	($100).w
;;	clr.l	(a2)			DON'T -- Will corrupt MH_FREELIST -> $8100000C
;;	clr.l	(4,a2)			No need MH_FREELIST will kill it... :)

	moveq	#RETURN_OK,d7

.nomem	call	Permit
	move.l	d7,d0
	rts

.testmem	move.l	a1,-(sp)
	call	TypeOfMem
	move.l	(sp)+,a0
	tst.l	d0
	beq.b	.tmnomem

	bsr.b	MemoryInfo
	move.l	d0,d1
	addq.l	#1,d1
	beq.b	.tmnomem
	btst	#MEMB_LARGEST,d0	Allocated?
.tmnomem	rts


	CNOP	0,4
; Code taken from mon and modified a bit by me.
;  IN: a0=memaddr
; OUT: d0=-1 if not in memlist, d0=attributes+bit MEMB_LARGEST set if allocated
MemoryInfo	movem.l	d1-d2/d5/a0-a1/a5-a6,-(sp)
	move.l	a0,d5
	move.l	(4).w,a6
	call	Forbid
	move.l	(MemList,a6),a5
.loop	tst.l	(a5)
	beq.b	.not_found
	cmp.l	(MH_LOWER,a5),d5
	bcs.b	.next
	cmp.l	(MH_UPPER,a5),d5
	bcc.b	.next
	move.l	(MH_FIRST,a5),d2
.scanfreemem	beq.b	.validmem
	move.l	d2,a1
	cmp.l	a1,d5
	blo.b	.notthis
	move.l	(4,a1),d0
	lea	(a1,d0.l),a0
	cmp.l	a0,d5
	blo.b	.validmem
.notthis	move.l	(a1),d2
	bra.b	.scanfreemem
.next	move.l	(a5),a5
	bra.b	.loop

.not_found	sub.l	a5,a5
.validmem
	moveq	#-1,d0
	move.l	a5,d1
	beq.b	.not_valid_mem

	moveq	#0,d0
	move.w	(MH_ATTRIBUTES,a5),d0
	
	tst.l	d2			d2=0 -> memory allocated
	bne.b	.is_free
	bset	#MEMB_LARGEST,d0
.is_free
.not_valid_mem	call	Permit
	movem.l	(sp)+,d1-d2/d5/a0-a1/a5-a6
	rts


	CNOP	0,4
_ErrFlag	dc.l	0
FreeMemSafely	movem.l	d0/a1,-(sp)
	clr.l	_ErrFlag
;;	sub.l	a1,a1
;;	call	FindTask
;;	move.l	d0,.ThisTask
	move.l	a3,.ThisTask
	lea	(.Alertp,pc),a0
	move.l	a0,d0
	move.w	#_LVOAlert,a0
	move.l	a6,a1
	call	Forbid
	call	SetFunction
	move.l	d0,.OldAlert
	call	Permit
	movem.l	(sp)+,d0/a1
	call	FreeMem
	move.l	(.OldAlert,pc),d0
	move.w	#_LVOAlert,a0
	move.l	a6,a1
	call	Forbid
	call	SetFunction
	call	Permit
	rts

	CNOP	0,4
.OldAlert	dc.l	0
.ThisTask	dc.l	0
.Alertp	move.l	d0,-(sp)
	move.l	(ThisTask,a6),d0
	cmp.l	(.ThisTask,pc),d0
	bne.b	.alert
	st	_ErrFlag
	move.l	(sp)+,d0
	rts

.alert	move.l	(sp)+,d0
	move.l	(.OldAlert,pc),-(sp)
	rts


	dc.b	'$VER: Free100buf 1.0 (21.5.97)',0
	dc.b	'$COPYRIGHT: Copyright © 1997 Harry Sintonen',0
