; FILE: Source:modules/PatchMath020.ASM          REV: 2 --- Patches C-compiler math routines with 020+ code

;
; PatchMath020 module for BlizKick
; ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
; This module replaces C-compiler math routines with 020+
; opcodes. V1.1 enables non-64bit mul/div patches for 060.
; Also sped-up patch scanning a lot.
; V1.2 fix a bug
;
; Written by Harry Sintonen.
; This source code is Public Domain.
;
; NOTE: Optimization routine was sent to me by Dave Jones.
; Thanks a lot Dave!
;
;

	incdir	"include:"
	include	"exec/execbase.i"
	include	"exec/libraries.i"	; Some required...
	include	"exec/exec_lib.i"
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

LTSFVARSTACK	EQU	8
	STRUCTURE KTSTR,0
	APTR	KT_LoadAddr	; scan start
	ULONG	KT_LoadFileSize	; scan lenght
	APTR	KT_CallBack	; null or ptr to printf func
	STRUCT	KT_PrintFVarStack,LTSFVARSTACK
	LABEL	KTSTR_SIZEOF

Push	MACRO
	move.l	\1,-(sp)
	ENDM
Pop	MACRO
	move.l	(sp)+,\1
	ENDM
Pushm	MACRO
	movem.l	\1,-(sp)
	ENDM
Popm	MACRO
	movem.l	(sp)+,\1
	ENDM
Call	MACRO
	jsr	(_LVO\1,a6)
	ENDM

	btst	#AFB_68020,(AttnFlags+1,a6) ; need minimum 020
	bne.b	.cont
.fail	moveq	#0,d0
	rts

.cont
	tst.b	(AttnFlags+1,a6)	; If no 060 enable all patches:
	bpl.b	.noenall
	lea	(C_Opt1,pc),a5
.enableall	tst.l	(a5)
	beq.b	.noenall
	st	(a5)			; opt_enable
	lea	(OptimStructSize,a5),a5
	bra.b	.enableall
.noenall
	move.l	a4,_printf		; Init callback hook
	move.l	d6,_d6reg

	lea	(ktstr,pc),a4		; Build KTSTR structure
	move.l	a0,(KT_LoadAddr,a4)
	move.l	d0,(KT_LoadFileSize,a4)
	lea	(_callback,pc),a0
	move.l	a0,(KT_CallBack,a4)

	; Patch_CompilerRoutines
	;  IN: a1=KTSTR
	; OUT: -
	move.l	a4,a1			; ...and go
	bsr	Patch_CompilerRoutines

	moveq	#1,d0			; Set to 0 for debug
	rts

;  IN: a0=string to print (no linefeed!), a4=KTSTR
; OUT: -
;NOTE: may trash a0-a4/a6 and d0-d1 (at least)
_printf	dc.l	0
_d6reg	dc.l	0
_callback	move.l	d6,-(sp)
	move.l	(_d6reg,pc),d6		; get orig d6 (DosBase)
	lea	(KT_PrintFVarStack,a4),a1
	move.l	(_printf,pc),a2		; get printf
	jsr	(a2)			; print it
	lea	(.lf,pc),a0		; print linefeed
	jsr	(a2)
	move.l	(sp)+,d6
	rts
.lf	dc.b	10,0

	CNOP	0,2
ktstr	ds.b	KTSTR_SIZEOF


	OPT	O-			; Turn off all optimizations

* Dave Jones:
*
* " Finally,  here's  a routine from KickTool (Now inactive) that you
*   may  like  to  add  to  BlizKick.   It  replaces  C compiler Math
*   routines  with  68020  opcodes.   It  probably will need a little
*   hacking  to  get it to work with BlizKick, but I'm sure your more
*   than capable of doing this..
*
*   Note also, that this is a generic routine I wrote for all-purpose
*   exe files, but not all these compiler routines are in kickstarts,
*   so  you  may remove some of them.  I guess you've got quite a few
*   kicks that you can test on, to decide which ones need to remain. "


*#############################################################################
*#######
*####### ROUTINES BY DAVE JONES, MODIFIED BY HS
*#######
*####### Note that it would be nice to ask Dave Jones for the permission and
*####### the original routines if you intend to use these. This mostly because
*####### I can't be sure if I haven't messed up things again... ;)
*#######

*#############################################################################

*HS:
* Made this thing run faster.

 STRUCTURE optim,0
   UWORD opt_enable
   UWORD opt_offset
   UWORD opt_size
   UWORD opt_repsize
   UWORD opt_repoffset
   UWORD opt_txtoffset
   LABEL OptimStructSize

Patch_CompilerRoutines
	Pushm	d0-d2/a0-a5
	Move.l	a1,a4
	Move.l	KT_LoadAddr(a4),a0

	move.l	KT_LoadFileSize(a4),d2
	add.l	a0,d2

;******************************************************************

	lea	C_Opt1(PC),a2
.SpotOptimisation
	tst.w	(a2)			;opt_enable
	beq.b	.not_enabled

	move.w	opt_offset(a2),a1	; Get ptr to original C to find
	add.l	a2,a1
.HuntLoop
	move.l	a1,a5
	; Find
	move.w	opt_size(a2),d1		; size of original C
	move.l	a0,a3
	subq	#1,d1			; Correct for the dbcc
.seek	cmpm.w	(a5)+,(a3)+
	dbne	d1,.seek
	bne.b	.NotFound

	bsr.b	.FoundOptim

.NotFound	addq.l	#2,a0

	cmp.l	a0,d2
	bgt.b	.HuntLoop		; Go back

;******************************************************************
; If we get here, then we've scanned to EOF for the current
; optimisation, so move back to beginning of file, and
; try a different optimisation.

	Move.l	KT_LoadAddr(a4),a0	; restore a0

.not_enabled	Lea	OptimStructSize(a2),a2
	Tst.l	(a2)			; get next optimisation
	Bne.b	.SpotOptimisation

.NoMorePatches	Popm	d0-d2/a0-a5
	Rts

;-------------------------------------------------------------------

	CNOP	0,4
.FoundOptim	Tst.l	KT_CallBack(a4)
	Beq.b	.QuietMode

	Moveq.l	#0,d1
	Move.w	opt_txtoffset(a2),d1
	Add.l	a2,d1
	Move.l	d1,KT_PrintFVarStack(a4) ; Name

	Pushm	a0-a4/a6
	Sub.l	KT_LoadAddr(a4),a0
	Move.l	a0,KT_PrintFVarStack+4(a4)

	Lea	FoundTxt(pc),a0		; body
	Move.l	KT_CallBack(a4),a2
	Jsr	(a2)
	Popm	a0-a4/a6

.QuietMode
	Move.w	opt_repsize(a2),d0	; size of my version
	Subq.l	#1,d0			; correct for dbf

	Move.l	a1,-(sp)

	Move.w	opt_repoffset(a2),a1	; addr of rep code
	Add.l	a2,a1
.CopyPatch	Move.w	(a1)+,(a0)+
	dbf	d0,.CopyPatch

	Move.l	(sp)+,a1

	Move.w	opt_size(a2),d0		; original C size in words
	Sub.w	opt_repsize(a2),d0	; Mycode size in words
	Subq.l	#1,d0

.ClrLoop	Clr.w	(a0)+
	dbf	d0,.ClrLoop
	Rts

FoundTxt	Dc.b	"Patched %s routine at offset $%lx",0
	CNOP	0,2	

;-------------------------------------------------------------------
*HS:
* Added parameter \2 that tells whether this patch should be done on
* 060.

Optim	Macro
.List\1	Dc.w	\2
	Dc.w	\1-.List\1
	Dc.w	\1Size/2
	Dc.w	\1RepSize/2
	Dc.w	\1Rep-.List\1
	Dc.w	\1Txt-.List\1
\1DEF	SET	1
	Endm

*HS:
* Here you can enable different optimizations. Only DiceC Mulu and Divs
* can be found from current ROM images.
*

C_Opt1	Optim	DiceC_Mulu,1
	Optim	DiceC_Divs,0
	;Optim	DiceC_MovMem,1
	;Optim	DiceC_StackLongMuls,1
	;Optim	Manx_Divs,1
	;Optim	Manx_Mulu,1
	;Optim	Manx_Mods,0
	;Optim	Manx_DivuModu,0
	;Optim	Manx_DivuModu2,0
	;Optim	SASMuls,1
	;Optim	SASMulu,1
	;Optim	SASDivsMods,0
	;Optim	SASDivuModu,0
	;Optim	SASDivsL,0
	;Optim	GenericMul1,0
	dc.l	0			** END MARKER!

***************************************************
	IFD	SASMulsDEF
SASMuls
__H0_end	movem.l	D1-D4,-(SP)
	move.l	D0,D4
	eor.l	D1,D4
	tst.l	D0
	beq.b	lbC001C9C

	bpl.b	lbC001C70

	neg.l	D0
lbC001C70	move.l	D0,D2
	tst.l	D1
	bne.b	lbC001C7A

	clr.l	D0
	bra.b	lbC001C9C

lbC001C7A	bpl.b	lbC001C7E

	neg.l	D1
lbC001C7E	move.l	D0,D3
	mulu	D1,D3
	swap	D2
	mulu	D1,D2
	swap	D2
	clr.w	D2
	add.l	D2,D3
	swap	D1
	mulu	D1,D0
	swap	D0
	clr.w	D0
	add.l	D3,D0
	tst.l	D4
	bpl.b	lbC001C9C

	neg.l	D0
lbC001C9C	movem.l	(SP)+,D1-D4
	rts
SASMulsSize	= *-SASMuls

;==================================================
SASMulsRep
_rep0	muls.l	D1,D0
	rts
SASMulsRepSize	= *-SASMulsRep
SASMulsTxt		Dc.b	"SAS C Muls",0
	CNOP	0,2
	ENDC
***************************************************
	IFD	SASMuluDEF
SASMulu
_seq1	movem.l	D1-D3,-(SP)
	move.l	D0,D2
	beq.b	lbC001CD0

	tst.l	D1
	bne.b	lbC001CB8

	clr.l	D0
	bra.b	lbC001CD0

lbC001CB8	move.l	D0,D3
	mulu	D1,D3
	swap	D2
	mulu	D1,D2
	swap	D2
	clr.w	D2
	add.l	D2,D3
	swap	D1
	mulu	D1,D0
	swap	D0
	clr.w	D0
	add.l	D3,D0
lbC001CD0	movem.l	(SP)+,D1-D3
	rts
SASMuluSize	= *-SASMulu

;==================================================
SASMuluRep
_rep1	mulu.l	D1,D0
	rts
SASMuluRepSize	= *-SASMuluRep
SASMuluTxt		Dc.b	"SAS C Mulu.l",0
	CNOP	0,2
	ENDC
***************************************************
	IFD	SASDivsModsDEF
SASDivsMods

_seq2	movem.l	D2-D5,-(SP)
	move.l	D1,D5
	beq.b	lbC001D16

	bpl.b	lbC001CE8

	neg.l	D1
lbC001CE8	move.l	D0,D4
	beq.b	lbC001D14

	bpl.b	lbC001CF0

	neg.l	D0
lbC001CF0	clr.l	D2
	moveq	#$1F,D3
lbC001CF4	asl.l	#1,D0
	roxl.l	#1,D2
	cmp.l	D1,D2
	bcs.b	lbC001D00

	sub.l	D1,D2
	addq.l	#1,D0
lbC001D00	dbra	D3,lbC001CF4

	move.l	D2,D1
	eor.l	D4,D5
	bpl.b	lbC001D0C

	neg.l	D0
lbC001D0C	eor.l	D1,D4
	bpl.b	lbC001D18

	neg.l	D1
	bra.b	lbC001D18

lbC001D14	clr.l	D1
lbC001D16	clr.l	D0
lbC001D18	movem.l	(SP)+,D2-D5
	rts
SASDivsModsSize	= *-SASDivsMods

;==================================================
SASDivsModsRep
_rep2	divsl.l	D1,D1:D0
	rts
SASDivsModsRepSize =*-SASDivsModsRep
SASDivsModsTxt		Dc.b	"SAS C Divsmods",0
	CNOP	0,2
	ENDC
***************************************************
	IFD	SASDivuModuDEF
SASDivuModu
_seq3	move.l	D2,-(SP)
	move.l	D3,-(SP)
	tst.l	D1
	beq.b	lbC001D4E

	tst.l	D0
	beq.b	lbC001D4C

	clr.l	D2
	moveq	#$1F,D3
lbC001D34	asl.l	#1,D0
	roxl.l	#1,D2
	cmp.l	D1,D2
	bcs.b	lbC001D44

	sub.l	D1,D2
	Dc.w	$D0BC,0,1		; Add.l #1,d0
lbC001D44	dbra	D3,lbC001D34

	move.l	D2,D1
	bra.b	lbC001D50

lbC001D4C	clr.l	D1
lbC001D4E	clr.l	D0
lbC001D50	move.l	(SP)+,D3
	move.l	(SP)+,D2
	rts
SASDivuModuSize = *-SASDivuModu

;==================================================
SASDivuModuRep
_rep3	divul.l	D1,D1:D0
	rts
SASDivuModuRepSize = *-SASDivuModuRep
SASDivuModuTxt		Dc.b	"SAS C Divumodu",0
	CNOP	0,2
	ENDC
***************************************************
	IFD	SASDivsLDEF
SASDivsL
	dc.l	$4A806A00,$001E4480,$4A816A00,$000C4481,$61000020
	dc.l	$44814E75,$61000018,$44804481,$4E754A81,$6A00000C
	dc.l	$44816100,$00064480,$4E752F02,$48413401,$66000022
	dc.l	$48404841,$48423400,$67000006,$84C13002,$48403400
	dc.l	$84C13002,$48423202,$241F4E75,$2F037610,$0C410080
	dc.l	$64000006,$E1995143,$0C410800,$64000006,$E9995943
	dc.l	$0C412000,$64000006,$E5995543,$4A416B00,$0006E399
	dc.l	$53433400,$E6A84842,$4242E6AA,$484380C1,$36003002
	dc.l	$34034841,$C4C19082,$64000006,$5343D081,$72003203
	dc.l	$4843E7B8,$4840C141,$261F241F
	dc.w	$4E75
SASDivsLSize = *-SASDivsL
;==================================================
SASDivsLRep	divsl.l	d1,d1:d0
	rts
SASDivsLRepSize = *-SASDivsLRep
SASDivsLTxt		Dc.b	"SAS C Signed Div",0
	CNOP	0,2
	ENDC
***************************************************
	IFD	Manx_MuluDEF
Manx_Mulu
; D0 = D0 * D1
_mulu0	movem.l	D1-D3,-(SP)
	move.w	D1,D2
	mulu	D0,D2
	move.l	D1,D3
	swap	D3
	mulu	D0,D3
	swap	D3
	clr.w	D3
	add.l	D3,D2
	swap	D0
	mulu	D1,D0
	swap	D0
	clr.w	D0
	add.l	D2,D0
	movem.l	(SP)+,D1-D3
	rts
Manx_MuluSize	= *-Manx_Mulu

;==================================================
Manx_MuluRep
_rep4	mulu.l	D1,D0
	rts
Manx_MuluRepSize = *-Manx_MuluRep
Manx_MuluTxt		Dc.b	"ManxC Mulu",0
	CNOP	0,2
	ENDC
***************************************************
	IFD	Manx_DivsDEF
Manx_Divs
_seq5	dc.l	$48E74800,$42844A80,$6A044480,$52444A81
	dc.l	$6A064481,$0A440001,$613E4A44,$67024480
	dc.l	$4CDF0012,$4A804E75

Manx_DivsSize	= *-Manx_Divs
;==================================================
Manx_DivsRep
_rep5	divs.l	D1,D0
	rts
Manx_DivsRepSize = *-Manx_DivsRep
Manx_DivsTxt		Dc.b	"ManxC Divs",0
	CNOP	0,2
	ENDC
***************************************************
	IFD	Manx_DivuModuDEF
Manx_DivuModu
_seq6	movem.l	D2/D3,-(SP)
	swap	D1
	tst.w	D1
	bne.b	_rep6

	swap	D1
	move.w	D1,D3
	move.w	D0,D2
	clr.w	D0
	swap	D0
	divu	D3,D0
	move.l	D0,D1
	swap	D0
	move.w	D2,D1
	divu	D3,D1
	move.w	D1,D0
	clr.w	D1
lbC001DD6	swap	D1
	movem.l	(SP)+,D2/D3
	rts
Manx_DivuModuSize = *-Manx_DivuModu

;==================================================
Manx_DivuModuRep
_rep6	divul.l	D1,D1:D0
	rts
Manx_DivuModuRepSize = *-Manx_DivuModuRep
Manx_DivuModuTxt	Dc.b	"ManxC DivuModu",0
	CNOP	0,2
	ENDC
***************************************************
	IFD	Manx_ModsDEF
Manx_Mods	Dc.l	$48E74800,$42844A80,$6A044480,$52444A81
	Dc.l	$6A024481,$611A2001,$60D82F01,$61122001
	Dc.l	$221F4A80,$4E752F01,$6106221F,$4A804E75
Manx_ModsSize	= *-Manx_Mods

;==================================================

Manx_ModsRep
_rep7	move.l	D1,-(SP)
	divsl.l	D1,D1:D0
	exg	D0,D1
	move.l	(SP)+,D1
lbC001E14	tst.l	D0
	rts
Manx_ModsRepSize = *-Manx_ModsRep
Manx_DivuModu2Txt	Dc.b	"ManxC DivuModu2",0
	CNOP	0,2
	ENDC

***************************************************
	IFD	Manx_DivuModu2DEF
Manx_DivuModu2
_seq8	movem.l	D2/D3,-(SP)
	swap	D1
	tst.w	D1
	bne.b	_rep8

	swap	D1
	clr.w	D3
	divu	D1,D0
	bvc.b	lbC001E38

	move.w	D0,D2
	clr.w	D0
	swap	D0
	divu	D1,D0
	move.w	D0,D3
	move.w	D2,D0
	divu	D1,D0
lbC001E38	move.l	D0,D1
	swap	D0
	move.w	D3,D0
	swap	D0
	clr.w	D1
	swap	D1
	movem.l	(SP)+,D2/D3
	rts
Manx_DivuModu2Size = *-Manx_DivuModu2

;==================================================
Manx_DivuModu2Rep
_rep8	divul.l	D1,D1:D0
	rts
Manx_DivuModu2RepSize = *-Manx_DivuModu2Rep
Manx_ModsTxt		Dc.b	"ManxC Mods",0
	CNOP	0,2
	ENDC
***************************************************
	IFD	DiceC_MuluDEF
DiceC_Mulu
__CXM33	Pushm	D2/D3
	move.l	D0,D2
	move.l	D1,D3
	swap	D2
	swap	D3
	mulu	D1,D2
	mulu	D0,D3
	mulu	D1,D0
	add.w	D3,D2
	swap	D2
	clr.w	D2
	add.l	D2,D0
	Popm	D2/D3
	rts
DiceC_MuluSize	= *-DiceC_Mulu
;==================================================
DiceC_MuluRep	Mulu.l	D1,D0
	Rts
DiceC_MuluRepSize = *-DiceC_MuluRep
DiceC_MuluTxt		Dc.b	"DiceC Mulu",0
	CNOP	0,2
	ENDC
***************************************************
	IFD	DiceC_DivsDEF
DiceC_Divs	dc.l	$2F024841,$34016600,$00224840,$48414842
	dc.l	$34006700,$000684C1,$30024840,$340084C1
	dc.l	$30024842,$3202241F,$4E752F03,$76100C41
	dc.l	$00806400,$0006E199,$51430C41,$08006400
	dc.l	$0006E999,$59430C41,$20006400,$0006E599
	dc.l	$55434A41,$6B000006,$E3995343,$3400E6A8
	dc.l	$48424242,$E6AA4843,$80C13600,$30023403
	dc.l	$4841C4C1,$90826400,$00085343,$D08164FE
	dc.l	$72003203,$4843E7B8,$4840C141,$261F241F
	dc.w	$4E75

DiceC_DivsSize	= *-DiceC_Divs

;==================================================
DiceC_DivsRep	Divsl.l	D1,D1:D0
	Rts
DiceC_DivsRepSize = *-DiceC_DivsRep
DiceC_DivsTxt		Dc.b	"DiceC Divu",0
	CNOP	0,2
	ENDC
***************************************************
	IFD	DiceC_MovMemDEF
DiceC_MovMem	Move.l	4(SP),A0
	move.l	8(SP),A1
	move.l	12(SP),D0
	ble.s	lbC0008AC

	cmp.l	A0,A1
	bcs.s	lbC0008A6

	add.l	D0,A0
	add.l	D0,A1
lbC00089E	move.b	-(A0),-(A1)
	subq.l	#1,D0
	bne.s	lbC00089E
	rts

lbC0008A6	move.b	(A0)+,(A1)+
	subq.l	#1,D0
	bne.s	lbC0008A6
lbC0008AC	rts
DiceC_MovMemSize = *-DiceC_MovMem
;==================================================

DiceC_MovMemRep	Push	a6
	Move.l	4(SP),A0
	Move.l	8(SP),A1
	Move.l	12(SP),D0
	Call	CopyMem
	Pop	a6
	Rts
DiceC_MovMemRepSize = *-DiceC_MovMemRep
DiceC_MovMemTxt		Dc.b	"DiceC _MovMem",0
	CNOP	0,2
	ENDC
***************************************************
	IFD	DiceC_StackLongMulsDEF
DiceC_StackLongMuls
_Dice_Muls:	movem.l	d0/d1,-(sp)
	swap	d0
	mulu	d1,d0
	swap	d1
	mulu	2(sp),d1
	add.l	d1,d0
	swap	d0
	clr.w	d0
	move.w	2(sp),d1
	mulu	6(sp),d1
	add.l	d1,d0
	addq.l	#8,sp
	rts
DiceC_StackLongMulsSize = *-DiceC_StackLongMuls
;==================================================
DiceC_StackLongMulsRep
	muls.l	d0,d1
	move.l	d1,d0
	rts
DiceC_StackLongMulsRepSize = *-DiceC_StackLongMulsRep
DiceC_StackLongMulsTxt	Dc.b	"DiceC Stack Long Muls",0
	CNOP	0,2
	ENDC
***************************************************
	IFD	GenericMul1DEF
GenericMul1	movem.l	d2-d4,-(sp)
	move.l	d0,d2
	move.l	d0,d3
	swap	d3
	move.l	d1,d4
	swap	d4
	mulu	d1,d0
	mulu	d3,d1
	mulu	d4,d2
	mulu	d4,d3
	swap	d0
	add.w	d1,d0
	moveq	#0,d4
	addx.l	d4,d4
	add.w	d2,d0
	addx.l	d4,d3
	swap	d0
	clr.w	d1
	swap	d1
	clr.w	d2
	swap	d2
	add.l	d2,d1
	add.l	d3,d1
	beq.b	lskip
	ori.b	#2,ccr
lskip:	movem.l	(sp)+,d2-d4
	rts
_LongMul2:	movem.l	d2/d3,-(sp)
	move.l	d0,d2
	move.l	d1,d3
	bsr.b	GenericMul1
	tst.l	d2
	bpl.b	lm1
	sub.l	d3,d1
lm1:	tst.l	d3
	bpl.b	lm2
	sub.l	d2,d1
lm2:	tst.l	d0
	bpl.b	lm3
	not.l	d1
lm3:	tst.l	d1
	beq.b	lm4
	ori.b	#2,ccr
lm4:	movem.l	(sp)+,d2/d3
	rts
GenericMul1Size = *-GenericMul1
;==================================================
GenericMul1Rep	muls.l	d1,d1:d0
	rts
GenericMul1RepSize = *-GenericMul1Rep
GenericMul1Txt		Dc.b	"Generic Multiply",0
	CNOP	0,2
	ENDC
***************************************************


*#############################################################################

*#######
*####### END OF
*####### ROUTINES BY DAVE JONES
*#######
*#############################################################################


	SECTION	VERSION,DATA

	dc.b	'$VER: PatchMath020_PATCH 1.2 (11.01.03)',0

