; FILE: Source:modules/Test.ASM          REV: 5 --- Complex Module for BlizKick

;
; Example BlizKick Module
; ~~~~~~~~~~~~~~~~~~~~~~~
; This code shows how to create complex BlizKick "Module".
; Should be quite self-explonary... (?)
;
; !CODE MUST BE FULLY PC-RELATIVE!
;
; Written by Harry Sintonen.
; This source code is Public Domain.
;

	incdir	"include:"
	include	"exec/types.i"
	include	"exec/libraries.i"
	include	"exec/initializers.i"

	include	"exec/execbase.i"

	include	"blizkickmodule.i"	; Some required...


MYLIB_VERSION	EQU	1
MYLIB_REVISION	EQU	2


	STRUCTURE mylib,LIB_SIZE
	APTR	ml_ExecBase
	LABEL	mylib_SIZEOF


	SECTION	LIBRARYMODULE,CODE
_DUMMY_LABEL
 BK_MODA BKMF_SingleMode,_end,(RTF_COLDSTART)<<24+30<<16+NT_LIBRARY<<8+11,_name,_idstr,mylib_SIZEOF,_funcs,_is,_init

; SINGLE MODE, COLDSTART module, requires KS V30.x or better,
; module type NT_LIBRARY, priority 11.

	BK_INITFUNCS _funcs
	;------ system interface functions
	BK_FUNC	my_LIB_OPEN
	BK_FUNC	my_LIB_CLOSE
	BK_FUNC	my_LIB_EXPUNGE
	BK_FUNC	my_LIB_NULL
	;------ libraries definitions
	BK_FUNC	my_GetVBR
	BK_FUNC	my_SetVBR
	BK_ENDFUNCS

   ; The data table initializes static data structures.  The format is specified in
   ; exec/InitStruct routine's manual pages.  The INITBYTE/INITWORD/INITLONG routines are
   ; in the file "exec/initializers.i".  The first argument is the offset from the library
   ; base for this byte/word/long.  The second argument is the value to put in that cell.
   ; The table is null terminated.

_is	INITBYTE	LN_TYPE,NT_LIBRARY
;;	INITLONG	LN_NAME,_name				; No relocs!
	INITBYTE	LIB_FLAGS,LIBF_SUMUSED!LIBF_CHANGED
	INITWORD	LIB_VERSION,MYLIB_VERSION
	INITWORD	LIB_REVISION,MYLIB_REVISION
;;	INITLONG	LIB_IDSTRING,_idstr			; - "" -
	dc.l   0

; This routine gets called after the library has been allocated.  The library pointer is
; in D0.  The segment list is in A0.  If it returns non-zero then the library will be
; linked into the library list.
;
_init	movem.l	a5/a6,-(sp)
	move.l	d0,a5
	move.l	a6,(ml_ExecBase,a5)

	lea	(_name,pc),a0
	move.l	a0,(LN_NAME,a5)
	lea	(_idstr,pc),a0
	move.l	a0,(LIB_IDSTRING,a5)

	move.l	a5,d0
	movem.l	(sp)+,a5/a6
	rts

;------------------------------------------------------------------------------------------
; here begins the system interface commands.  When the user calls OpenLibrary/CloseLibrary/
; RemoveLibrary, this eventually gets translated into a call to the following routines
; (Open/Close/Expunge).  Exec has already put our library pointer in A6 for us.  Exec has
; turned off task switching while in these routines (via Forbid/Permit), so we should not
; take too long in them.
;------------------------------------------------------------------------------------------


   ; Open returns the library pointer in d0 if the open was successful.  If the open failed
   ; then null is returned.  It might fail if we allocated memory on each open, or if only
   ; open application could have the library open at a time...

my_LIB_OPEN
	; ( libptr:a6, version:d0 )
	tst.w	(LIB_OPENCNT,a6)
	beq.b	.open
.done	move.l	a6,d0
	rts
.open	addq.w	#1,(LIB_OPENCNT,a6)
	bra.b	.done

   ; There are two different things that might be returned from the Close routine.  If the
   ; library is no longer open and there is a delayed expunge then Close should return the
   ; segment list (as given to Init).  Otherwise close should return NULL.

my_LIB_CLOSE

   ; There are two different things that might be returned from the Expunge routine.  If
   ; the library is no longer open then Expunge should return the segment list (as given
   ; to Init).  Otherwise Expunge should set the delayed expunge flag and return NULL.
   ;
   ; One other important note: because Expunge is called from the memory allocator, it may
   ; NEVER Wait() or otherwise take long time to complete.

my_LIB_EXPUNGE
my_LIB_NULL
	moveq	#0,d0
	rts

   ; Functions:


; OUT: d0=vbr or zero if no vbr
my_GetVBR
	movem.l	a5/a6,-(sp)
	move.l	(ml_ExecBase,a6),a6
	moveq	#0,d0
	btst	#AFB_68010,(AttnFlags+1,a6)
	beq.b	.novbr
	lea	(.getvbr,pc),a5
	jsr	(-$1E,a6)		;call Supervisor
.novbr	tst.l	d0
	movem.l	(sp)+,a5/a6
	rts
.getvbr	movec.l	vbr,d0
	rte


;  IN: a0=new vbr, not set if no vbr
; OUT: d0=old vbr, always zero if no vbr
my_SetVBR
	movem.l	a5/a6,-(sp)
	bsr.b	my_GetVBR
	move.l	(ml_ExecBase,a6),a6
	btst	#AFB_68010,(AttnFlags+1,a6)
	beq.b	.novbr
	lea	(.setvbr,pc),a5
	jsr	(-$1E,a6)		;call Supervisor
.novbr	tst.l	d0
	movem.l	(sp)+,a5/a6
	rts
.setvbr	movec.l	a0,vbr
	rte


_name	dc.b	'testmodule.library',0
_idstr	dc.b	'testmodule.library 1.2 (26.2.97)',0
	CNOP	0,2
_end


	SECTION	VERSION,DATA

	dc.b	'$VER: testmodule.library_MODULE 1.2 (26.2.97)',0
