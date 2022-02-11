	IFND	BLIZKICKMODULE_I
BLIZKICKMODULE_I	SET	1
**
**	$VER: blizkickmodule.i 1.6 (25.2.2000)
**	Includes Release 1.6
**
**	Macros and defines for BlizKick's "modules" and "patches".
**
**	(C) Copyright 1996-2000 PitPlane Productions.
**	    All Rights Reserved
**

    IFND EXEC_TYPES_I
    INCLUDE "exec/types.i"
    ENDC ; EXEC_TYPES_I

    IFND EXEC_NODES_I
    INCLUDE "exec/nodes.i"
    ENDC ; EXEC_NODES_I

    IFND EXEC_RESIDENT_I
    INCLUDE "exec/resident.i"
    ENDC ; EXEC_RESIDENT_I


;
;   "Modules" are executable files that are loaded with LoadSeg(). Only the
; first segment can be used and the code *MUST* be PC-relative. Modules contain
; a LONG id and Resident Tag. This resident tag will be added to KS ROM. There
; are two macros defined in this file (BK_MOD and BK_MODA), which can be used
; (=should be used) to create "Modules".
;
;   "Module" can (from BlizKick V1.6 on) also be a patch, in which case macro
; called BK_PTC should be used to create it. See macro definition below for
; detailed information. Note that "patch" needn't be fully PC-relative (the
; patching code can be relocatable, it is loaded with LoadSeg() after all).
;
;
; bkm_Flags
; ~~~~~~~~~
; Normally modules can be installed multiple times, but if bkm_Flags has
; BKMB_SingleMode bit set then this module (RT_NAME and RT_PRI match) can be
; found from ROM only once.
;
; If bkm_Flags has BKMB_ReplaceMode bit set then the ROM is scanned for Resident
; Tag with same name (RT_NAME) and priority (RT_PRI) as in this "module". If
; such resident is found it'll be replaced (overwritten) by module's Resident
; Tag. This feature must be considered as "hackish", because resident tags don't
; always be in ROM as one big chunk, but are split into thousand and one little
; pieces... :-( Additionally there are usually code and data inside Resident Tag
; which has nothing to do with that Tag... :.-((. So, if you'd like like to
; safely(?) replace OS Resident Tags you should use this flag in conjugation
; with BKMB_ExtResBuf.
;
; With this feature you could, for example, replace 'exec.library' resident
; with better one, improve KS3.x 'alert.hook' or improve KS1.3 'bootstrap'...
; It's up to you, Coders...
;
; If you specify BKMB_ExtResBuf flag this module will require it to be installed
; to external Resident Tag buffer created by EXTRESBUF feature of the BlizKick.
; Using this makes only(?) sense with BKMB_ReplaceMode...
;
; It was one shiny day I got up with this *great* idea of "modules". Kickstart
; MapROM tools will never be the same again... ;-)
;



BKMODULE_ID	EQU	$707A4E75	; moveq #'z',d0; rts
BKEP_ID	EQU	$4E71		; nop ;-)

ERH_API_V1	EQU	1
ERH_API_V2	EQU	2

	; bkm_Flags:

	BITDEF	BKM,ReplaceMode,0	; Turn on REPLACE MODE
	BITDEF	BKM,SingleMode,1	; Do *not* allow same "module" multiple times
	BITDEF	BKM,ExtResBuf,2		; Require EXTRESBUF for this module
BKMF_ALL EQU	BKMF_ReplaceMode!BKMF_SingleMode!BKMF_ExtResBuf

	STRUCTURE bkmodule,0
	ULONG	bkm_ID			; Must be BKMODULE_ID
	UWORD	bkm_Flags		; See above
	STRUCT	bkm_ResTag,RT_SIZE	; Resident Tag (not relocated!)
;;	LABEL	bkmodule_SIZEOF		; There's no SIZEOF!


;
; BK_MOD -- Create a simple ResidentTag without AUTOINIT
;
; mflags   - "Module" flags, see above.
; end      - ptr to end of this ResidentTag
; flags    - ResidentTag flags
; reqver   - required KS version for this module. This is *NOT*
;	     the ResidentTag version, but required version to use this
;	     module. ResidentTag version will be forced to current
;	     ROM version.
; type     - type of module (NT_XXXXXX)
; pri      - priority for this ResidentTag
; name     - ptr to name of this ResidentTag
; idstring - ptr to idstring of this ResidentTag
; init     - ptr to init code

; no-autoinit-module:
BK_MOD	MACRO	*mflags,end,flags<<24+reqver<<16+type<<8+pri,name,idstring,init
	IFGT	NARG-6
	FAIL	!!!! TOO MANY ARGUMENTS TO BK_MOD !!!!
	MEXIT
	ELSE
	IFGT	6-NARG
	FAIL	!!!! TOO FEW ARGUMENTS TO BK_MOD !!!!
	MEXIT
	ENDC
	ENDC
	dc.l	BKMODULE_ID
	dc.w	\1
.mod\@	dc.w	RTC_MATCHWORD
	dc.l	0
	dc.l	(\2)-.mod\@
	dc.l	(\3)&~(RTF_AUTOINIT<<24)
	dc.l	(\4)-.mod\@
	dc.l	(\5)-.mod\@
	dc.l	(\6)-.mod\@
	ENDM


;
; BK_MODA -- Create a complex ResidentTag with AUTOINIT (library/device/resource?)
;
; mflags   - "Module" flags, see above.
; end      - ptr to end of this ResidentTag
; flags    - ResidentTag flags
; reqver   - required KS version for this module. This is *NOT*
;	     the ResidentTag version, but required version to use this
;	     module. ResidentTag version will be forced to current
;	     ROM version.
; type     - type of module (NT_XXXXXX)
; pri      - priority for this ResidentTag
; name     - ptr to name of this ResidentTag
; idstring - ptr to idstring of this ResidentTag
; size     - see exec.library/InitResident
; funcs    - see exec.library/InitResident
; initstruct - see exec.library/InitResident
; initfunc - see exec.library/InitResident

; autoinit-module:
BK_MODA	MACRO	*mflags,end,flags<<24+reqver<<16+type<<8+pri,name,idstring,size,funcs,initstruct,initfunc
	IFGT	NARG-9
	FAIL	!!!! TOO MANY ARGUMENTS TO BK_MODA !!!!
	MEXIT
	ELSE
	IFGT	9-NARG
	FAIL	!!!! TOO FEW ARGUMENTS TO BK_MODA !!!!
	MEXIT
	ENDC
	ENDC
	dc.l	BKMODULE_ID
	dc.w	\1
.mod\@	dc.w	RTC_MATCHWORD
	dc.l	0
	dc.l	(\2)-.mod\@
	dc.l	(\3)!(RTF_AUTOINIT<<24)
	dc.l	(\4)-.mod\@
	dc.l	(\5)-.mod\@
	dc.l	.mod2\@-.mod\@
.mod2\@	dc.l	\6
	dc.l	(\7)-.mod\@
	dc.l	(\8)-.mod\@
	dc.l	(\9)-.mod\@
	ENDM


;
; BK_PTC -- Create a header for BlizKick external patch
;
;   Notes
;   ~~~~~
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
;
; Code doesn't need to worry about cache flushing after it has done its
; modifications. If the patch code requires some new KS (3.x) features
; you *must* test for approriate KS version!! If patch code is run you
; can assume that you're running on at least AmigaOS 2.0 (V36). Note the
; difference between os version you're running atm and os version user
; is going to boot.
;
; Please, be as fast as possible because user might want to add *several*
; patches! Also note that _Printf output is supressed if user specifies
; QUIET switch.
;
; The macro is used like this:
;
;	SECTION	PATCH,CODE
;
;_SEGSTART_DUMMY:
;
;	BK_PTC
;
;patchcode:
;	cmp.w	#37,($C,A0)	; This patch requires V37 ROM (KS 2.04) or better...
;	blo.b	.fail
;
;	subq.l	#6,d0		; don't test past end
;	move.l	#$xxxxxxxx,d1	; Search for (xxxxxxxx,yyyyyyyy,zzzzzzzz):
;.find;	addq.l	#2,a0
;	subq.l	#2,d0
;	beq.b	.fail
;	cmp.l	(a0),d1
;	bne.b	.find
;	cmp.l	#$yyyyyyyy,(4,a0)
;	bne.b	.find
;	cmp.l	#$zzzzzzzz,(8,a0)
;	bne.b	.find
;	bra.b	.found
;
;.fail	moveq	#0,d0
;	rts
;
;.found	movem.l	d2-d7/a2-a6,-(sp)
;
;	do the patching...
;	...etc...
;
;	movem.l	(sp)+,d2-d7/a2-a6
;	moveq	#1,d0
;	rts
;

; external patch:
BK_PTC	MACRO
	IFGT	NARG
	FAIL	!!!! BK_PTC DOES NOT TAKE ANY ARGUMENTS !!!!
	MEXIT
	ENDC
	dc.l	BKMODULE_ID
	dc.w	0,BKEP_ID
	ENDM


; Following macros can be used to create function tables for devices, libraries
; and resources:

BK_INITFUNCS	MACRO	*label
	IFGT	NARG-1
	FAIL	!!!! TOO MANY ARGUMENTS TO BK_INITFUNCS !!!!
	MEXIT
	ELSE
	IFGT	1-NARG
	FAIL	!!!! TOO FEW ARGUMENTS TO BK_INITFUNCS !!!!
	MEXIT
	ENDC
	ENDC
	CNOP	0,2
\1
_BKM_FB_GLOBAL\@
	dc.w	-1
.BKM_FUNCBASE	EQU	*-2
	ENDM

BK_FUNC	MACRO	*funclabel
	IFGT	NARG-1
	FAIL	!!!! TOO MANY ARGUMENTS TO BK_FUNC !!!!
	MEXIT
	ELSE
	IFGT	1-NARG
	FAIL	!!!! TOO FEW ARGUMENTS TO BK_FUNC !!!!
	MEXIT
	ENDC
	ENDC
	dc.w	(\1)-.BKM_FUNCBASE
	ENDM

BK_ENDFUNCS	MACRO
	IFGT	NARG
	FAIL	!!!! BK_ENDFUNCS DOES NOT TAKE ANY ARGUMENTS !!!!
	MEXIT
	ENDC
	dc.w	-1
	ENDM

	ENDC	; BLIZKICKMODULE_I
