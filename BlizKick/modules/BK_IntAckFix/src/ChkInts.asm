;*---------------------------------------------------------------------------
;  :Program.	ChkInts.asm
;  :Contents.	check interrupts for intreq not set
;  :Author.	Bert Jahn
;  :EMail.	wepl@whdload.de
;  :Version.	$Id: ChkInts.asm 1.2 2007/12/03 11:17:20 wepl Exp wepl $
;  :History.	02.12.07 created
;  :Requires.	OS V37+
;  :Copyright.	Public Domain
;  :Language.	68000 Assembler
;  :Translator.	Barfly V2.16
;---------------------------------------------------------------------------*
;##########################################################################

	INCDIR	Includes:
	INCLUDE	lvo/exec.i
	INCLUDE	exec/execbase.i
	INCLUDE	exec/memory.i
	INCLUDE	lvo/dos.i
	INCLUDE	dos/dos.i
	INCLUDE	hardware/custom.i
	INCLUDE	hardware/intbits.i
	INCLUDE	lvo/utility.i

	INCLUDE	macros/ntypes.i

_custom = $dff000

;++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

GL	EQUR	A4		;a4 ptr to Globals
LOC	EQUR	A5		;a5 for local vars

	STRUCTURE	ReadArgsArray,0
		LONG	rda_delay
		LABEL	rda_SIZEOF

	NSTRUCTURE	Globals,0
		NAPTR	gl_execbase
		NAPTR	gl_dosbase
		NAPTR	gl_utilbase
		NULONG	gl_intfcnt
		NULONG	gl_intcnt
		NULONG	gl_intftmp
		NULONG	gl_inttmp
		NLONG	gl_int68
		NAPTR	gl_rdargs
		NSTRUCT	gl_rdarray,rda_SIZEOF
		NALIGNLONG
		NLABEL	gl_SIZEOF

;##########################################################################

	SECTION	"",CODE
	OUTPUT	C:ChkInts
	BOPT	O+				;enable optimizing
	BOPT	OG+				;enable optimizing
	BOPT	ODd-				;disable mul optimizing
	BOPT	ODe-				;disable mul optimizing
	BOPT	sa+				;create symbol hunk

VER	MACRO
		dc.b	"ChkInts 1.0 "
	DOSCMD	"WDate >t:date"
	INCBIN	"t:date"
		dc.b	" by Bert Jahn"
	ENDM

		bra	.start
		dc.b	"$VER: "
		VER
		dc.b	" V37+"
	CNOP 0,2
.start

;##########################################################################

		link	GL,#gl_SIZEOF		;GL = PubMem
		moveq	#(-gl_SIZEOF)/4-1,d0
		move.l	GL,a0
.clr		clr.l	-(a0)
		dbf	d0,.clr
		lea	(_gl),a0
		move.l	GL,(a0)
		move.l	(4),(gl_execbase,GL)

		move.l	#37,d0
		lea	(_dosname),a1
		move.l	(gl_execbase,GL),a6
		jsr	_LVOOpenLibrary(a6)
		move.l	d0,(gl_dosbase,GL)
		beq	.nodoslib

		move.l	#37,d0
		lea	(_utilname),a1
		jsr	_LVOOpenLibrary(a6)
		move.l	d0,(gl_utilbase,GL)
		beq	.noutillib

		lea	(_ver),a0
		bsr	_Print

		lea	(_template),a0
		move.l	a0,d1
		lea	(gl_rdarray,GL),a0
		move.l	a0,d2
		moveq	#0,d3
		move.l	(gl_dosbase,GL),a6
		jsr	(_LVOReadArgs,a6)
		move.l	d0,(gl_rdargs,GL)
		bne	.argsok
		lea	(_readargs),a0
		bsr	_PrintErrorDOS
		bra	.noargs
.argsok
		moveq	#10,d0
		move.l	(gl_rdarray+rda_delay,GL),d1
		beq	.dset
		move.l	d1,a0
		move.l	(a0),d0
.dset		lea	(gl_rdarray+rda_delay,GL),a1
		move.l	d0,(a1)
		lea	_msg_interval,a0
		bsr	_PrintArgs

		bsr	_Main
.opend
		move.l	(gl_rdargs,GL),d1
		move.l	(gl_dosbase,GL),a6
		jsr	(_LVOFreeArgs,a6)
.noargs
		move.l	(gl_utilbase,GL),a1
		move.l	(gl_execbase,GL),a6
		jsr	(_LVOCloseLibrary,a6)
.noutillib
		move.l	(gl_dosbase,GL),a1
		move.l	(gl_execbase,GL),a6
		jsr	(_LVOCloseLibrary,a6)
.nodoslib
		unlk	GL
		moveq	#0,d0
		rts

;##########################################################################

_Main		move.l	(gl_execbase,GL),a6
		btst	#AFB_68010,(AttnFlags+1,a6)
		beq	.quit

		lea	_install,a5
		jsr	(_LVOSupervisor,a6)
.loop
		lea	_msg,a0
		move.l	(gl_intcnt,GL),d2
		beq	.noprint		;avoid division by zero
		move.l	(gl_intfcnt,GL),d3
		move.l	(gl_inttmp,GL),d4
		move.l	(gl_intftmp,GL),d5
		move.l	d2,(gl_inttmp,GL)
		move.l	d3,(gl_intftmp,GL)
		neg.l	d4
		neg.l	d5
		add.l	d2,d4
		beq	.noprint		;avoid division by zero
		add.l	d3,d5
		move.l	(gl_utilbase,GL),a6
		moveq	#100,d0
		move.l	d5,d1
		jsr	(_LVOUMult32,a6)
		move.l	d4,d1
		jsr	(_LVOUDivMod32,a6)
		move.l	d0,-(a7)
		moveq	#100,d0
		move.l	d3,d1
		jsr	(_LVOUMult32,a6)
		move.l	d2,d1
		jsr	(_LVOUDivMod32,a6)
		movem.l	d0/d4-d5,-(a7)
		movem.l	d2-d3,-(a7)
		move.l	a7,a1
		bsr	_PrintArgs
		add.w	#6*4,a7
.noprint
		move.l	(gl_rdarray+rda_delay,GL),d1
		move.l	(gl_dosbase,GL),a6
		jsr	(_LVODelay,a6)

		bsr	_CheckBreak
		tst.l	d0
		beq	.loop

		lea	_remove,a5
		move.l	(gl_execbase,GL),a6
		jsr	(_LVOSupervisor,a6)

.quit		rts

	SUPER
	MC68010
_install	movec	vbr,a0
		move.l	($68,a0),(gl_int68,GL)
		lea	_int68,a1
		move.l	a1,($68,a0)
		rte
_remove		movec	vbr,a0
		move.l	(gl_int68,GL),($68,a0)
		rte
	MC68000

_int68		subq.l	#4,a7
		movem.l	GL,-(a7)
		move.l	(_gl),GL
		move.l	(gl_int68,GL),(_MOVEMBYTES,a7)
		addq.l	#1,(gl_intcnt,GL)
		btst	#INTB_PORTS,(_custom+intreqr+1)
		bne	.1
		addq.l	#1,(gl_intfcnt,GL)
.1		movem.l	(a7)+,_MOVEMREGS
		rts

;##########################################################################

	INCDIR	Sources:
	INCLUDE	dosio.i
		Print
		PrintArgs
		CheckBreak
	INCLUDE	error.i
		PrintErrorDOS

;##########################################################################

_gl		dc.l	0

_msg_interval	dc.b	"interval time is %ld ticks",10,0
_msg		dc.b	"sum: %3ld/%3ld=%2ld%% interval: %3ld/%3ld=%2ld%%",10,0
_readargs	dc.b	"read arguments",0
_dosname	dc.b	"dos.library",0
_utilname	dc.b	"utility.library",0
_template	dc.b	"Interval/N"		;delay in ticks between output
		dc.b	0

_ver		VER
		dc.b	10,"press Ctrl-C to end",10,0

;##########################################################################

	END

