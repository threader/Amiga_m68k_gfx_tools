; FILE: Source:modules/MuMove4K.ASM          REV: 1 --- MuMove4k BlizKick module

;
; MuMove4K BlizKick module implementation
; ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
;
; This module substitutes MuMove4K program by Thomas Richter.
; Based on reverse-engineered code of the original MuMove4K (Hi Thomas :-).
;
; BlizKick module adaption by Harry "Piru" Sintonen.
;


	incdir	"include:"
	include	"exec/ports.i"		; Some required...
	include	"exec/memory.i"
	include	"exec/resident.i"
	include	"exec/execbase.i"
	include	"blizkickmodule.i"

_LVOForbid	EQU	-$84
_LVOPermit	EQU	-$8A
_LVOAllocMem	EQU	-$C6
_LVOFreeMem	EQU	-$D2
_LVORemove	EQU	-$FC
_LVOEnqueue	EQU	-$10E
_LVOAddPort	EQU	-$162
_LVOTypeOfMem	EQU	-$216


	; private data structure used by
	; MuMove4K & MuFastZero.

	STRUCTURE mumovedata,0
	STRUCT	mmd_pad0,$08		; $00
	STRUCT	mmd_romtag1,RT_SIZE	; $08
	STRUCT	mmd_romtag2,RT_SIZE	; $22
	APTR	mmd_rt1ptr		; $3C
	APTR	mmd_rt2ptr		; $40
	APTR	mmd_tagptr1		; $44
	ULONG	mmd_A1200		; $48
	ULONG	mmd_PREPAREEMUL		; $4C
	APTR	mmd_tagptr2		; $50 (NULL -> MuMove4k can't remove the romtag)
	STRUCT	mmd_pad1,$0A		; $54
	UWORD	mmd_version		; $5E
	APTR	mmd_mmd_ptr		; $60
	ULONG	mmd_allocsize		; $64
	STRUCT	mmd_port,MP_SIZE	; $68 (this must be initialized)
	UWORD	mmd_pad2		; $8A
	APTR	mmd_nextptr		; $8C
	APTR	mmd_realmhptr		; $90
	ULONG	mmd_maxsize		; $94
	APTR	mmd_codestart		; $98
	LABEL	mmd_SIZEOF		; $9C


	SECTION	MODULE,CODE
_DUMMY_LABEL
 BK_MOD 0,_end,(RTF_COLDSTART)<<24+37<<16+NT_UNKNOWN<<8+104,_name,_idstr,_init

; COLDSTART module, requires KS V37.x or better, module type NT_UNKNOWN, priority 104.

_init	movem.l	d2/d3/a2-a4/a6,-(sp)
	move.l	(4).w,a6

	move.l	#mmd_SIZEOF,d0
	moveq	#MEMF_PUBLIC,d1
	jsr	(_LVOAllocMem,a6)
	tst.l	d0
	beq	.exit2

	move.l	d0,a2
	clr.l	(mmd_tagptr2,a2)
	move.w	#1,(mmd_version,a2)
	move.l	a2,(mmd_mmd_ptr,a2)
	clr.l	(mmd_allocsize,a2)

	lea	(_portname,pc),a0
	move.w	#(NT_MSGPORT<<8)|$9C,(mmd_port+LN_TYPE,a2)	; pri = -100
	move.l	a0,(mmd_port+LN_NAME,a2)
	move.w	#(PA_IGNORE<<8),(mmd_port+MP_FLAGS,a2)
	clr.l	(mmd_port+MP_SIGTASK,a2)
	lea	(mmd_port+MP_MSGLIST,a2),a0
	NEWLIST	a0

;lbC00052C	movem.l	d2/d3/a2-a4/a6,-(sp)
;	move.w	#$0333,(_custom+color)
;	lea	(stuff,pc),a1
;	move.l	(4).w,a6
;	move.l	(-4,a1),a2
	jsr	(_LVOForbid,a6)
	clr.l	(mmd_nextptr,a2)
	move.l	#$00008000,d3
	move.l	(LibList,a6),a3
	move.l	d3,d2
	subq.l	#1,d3
	bsr	.processlist
	move.l	(DeviceList,a6),a3
	bsr	.processlist
	move.l	d2,(mmd_maxsize,a2)
	move.l	d2,d3
.loop	move.l	d3,d0
	moveq	#MEMF_CHIP,d1
	jsr	(_LVOAllocMem,a6)
	tst.l	d0
	move.l	d0,a1
	beq.b	.nomem
	lea	(a1,d3.l),a0
	cmp.l	d2,a0
	bhi.b	.free
	move.l	(mmd_nextptr,a2),(MC_NEXT,a1)
	move.l	d3,(MC_BYTES,a1)
	move.l	a1,(mmd_nextptr,a2)
	bra.b	.loop

.free	move.l	d3,d0
	jsr	(_LVOFreeMem,a6)
.nomem	lsr.l	#1,d3
	bne.b	.loop

	moveq	#MH_SIZE,d0
	moveq	#MEMF_PUBLIC|MEMF_CHIP,d1
	jsr	(_LVOAllocMem,a6)
	tst.l	d0
	beq	.exit

	move.l	d0,a4
	move.l	(MemList,a6),a3
.find	tst.l	(a3)
	beq.b	.exit
	cmp.l	(MH_LOWER,a3),a4
	bhi.b	.found
	move.l	(a3),a3
	bra.b	.find

.found	move.l	a3,a1
	jsr	(_LVORemove,a6)

	move.l	a4,a1
	move.l	a3,a0
	moveq	#8-1,d0
.copy	move.l	(a0)+,(a1)+
	dbra	d0,.copy

	moveq	#MH_SIZE,d2
	move.b	#-127,(LN_PRI,a3)
	move.l	(mmd_port+LN_NAME,a2),(LN_NAME,a3)
	move.w	#MEMF_CHIP,(MH_ATTRIBUTES,a3)
	add.l	a4,d2
	clr.l	(MH_FIRST,a3)
	move.l	a4,(MH_UPPER,a3)
	clr.l	(MH_FREE,a3)
	move.l	d2,(MH_LOWER,a4)
	move.l	a3,(mmd_realmhptr,a2)

	lea	(MemList,a6),a0
	move.l	a3,a1
	jsr	(_LVOEnqueue,a6)

	lea	(MemList,a6),a0
	move.l	a4,a1
	jsr	(_LVOEnqueue,a6)

.freeloop	move.l	(mmd_nextptr,a2),d0
	beq.b	.done
	move.l	d0,a1
	move.l	(MC_NEXT,a1),(mmd_nextptr,a2)
	move.l	(MC_BYTES,a1),d0
	jsr	(_LVOFreeMem,a6)
	bra.b	.freeloop
.done
	lea	(mmd_port,a2),a1
	jsr	(_LVOAddPort,a6)
;
;.exit	jsr	(_LVOPermit,a6)
;	movem.l	(sp)+,d2/d3/a2-a4/a6
;.rts	rts

	sub.l	a2,a2
.exit	jsr	(_LVOPermit,a6)

	move.l	a2,d0
	beq.b	.nofree
	move.l	a2,a1
	move.l	#mmd_SIZEOF,d0
	jsr	(_LVOFreeMem,a6)
.nofree
.exit2	movem.l	(sp)+,d2/d3/a2-a4/a6
.rts	rts

.processlist	tst.l	(a3)
	beq.b	.rts
	move.l	a3,a1
	jsr	(_LVOTypeOfMem,a6)
	btst	#MEMB_CHIP,d0
	beq.b	.pl_next
	move.l	a3,d0
	clr.w	d0
	moveq	#0,d1
	tst.l	d0
	bne.b	.pl_next
	move.w	(LIB_POSSIZE,a3),d1
	lea	(a3,d1.l),a0
	cmp.l	d2,a0
	bcs.b	.pl_next
	move.l	d3,d1
	move.l	a0,d2
	not.l	d1
	add.l	d3,d2
	and.l	d1,d2
.pl_next	move.l	(a3),a3
	bra.b	.processlist


_portname
_name	dc.b	'« MuMove4K »',0
_idstr	dc.b	'MuMove4K 40.18 (26.10.01)',0
	CNOP	0,2
_end

	SECTION	VERSION,DATA

	dc.b	'$VER: MuMove4K_MODULE 40.18 (26.10.01)',0

