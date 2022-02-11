; FILE: Source:modules/FixGetMsg.ASM          REV: 2 --- Fix GetMsg() bug

;
; FixGetMsg - Fix 68060 GetMsg() loop hang
; ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
; Written by Harry "Piru" Sintonen.
; This source code is Public Domain.
; Idea stolen from FixGetMsg by Frederick H. G. Wright II <fw@well.com>.
;
; This module fixes the hang if GetMsg() is called in tight loop
; on 68060.
;
; V1.0 - 27th Mar 2000
; Original release.
;
; V1.1 - 31st Jan 2001
; Fixed a serious bug, the new GetMsg() trashed zeropage in some rare
; conditions.
;
;    - Piru
;

	incdir	"include:"
	include	"exec/ports.i"
	include	"exec/execbase.i"

	include	"exec/exec_lib.i"

	include	"blizkickmodule.i"


	SECTION	MODULE,CODE
_DUMMY_LABEL
 BK_MOD BKMF_SingleMode,_end,(RTF_COLDSTART)<<24+37<<16+NT_UNKNOWN<<8+104,_name,_idstr,_init

; Singlemode on,
; COLDSTART module, requires KS V37.x or better, module type NT_UNKNOWN, priority 104.

_init	movem.l	d0-d1/a0-a1/a6,-(sp)
	move.l	(4).w,a6

	lea	(newGetMsg,pc),a0
	move.l	a0,d0
	move.w	#_LVOGetMsg,a0
	move.l	a6,a1
	jsr	(_LVOForbid,a6)
	jsr	(_LVOSetFunction,a6)
	jsr	(_LVOPermit,a6)

	movem.l	(sp)+,d0-d1/a0-a1/a6
	rts

	CNOP	0,8
newGetMsg
	lea	(MP_MSGLIST,a0),a0
	moveq	#0,d0
	cmp.l	(LH_TAIL+LN_PRED,a0),a0
	beq.b	.exit

	move.w	#$4000,$DFF09A
	addq.b	#1,(IDNestCnt,a6)
	move.l	(a0),a1
	move.l	(a1),d0
	beq.b	.exit2
	move.l	d0,(a0)
	exg	d0,a1
	move.l	a0,(LN_PRED,a1)
.exit2	subq.b	#1,(IDNestCnt,a6)
	bge.b	.exit
	move.w	#$C000,$DFF09A
.exit	rts


; here is the original function:

	IFGT	0

_LVOGetMsg
	lea	(MP_MSGLIST,a0),a0
	move.w	#$4000,$DFF09A
	addq.b	#1,(IDNestCnt,a6)
	move.l	(a0),a1
	move.l	(a1),d0
	beq.b	.exit2
	move.l	d0,(a0)
	exg	d0,a1
	move.l	a0,(LN_PRED,a1)
.exit2	subq.b	#1,(IDNestCnt,a6)
	bge.b	.exit
	move.w	#$C000,$DFF09A
.exit	rts

	ENDC

_name	dc.b	'FixGetMsg',0
_idstr	dc.b	'FixGetMsg 1.1 (31.1.01)',0
	CNOP	0,2
_end

	SECTION	VERSION,DATA

	dc.b	'$VER: FixGetMsg_MODULE 1.1 (31.1.01)',0

