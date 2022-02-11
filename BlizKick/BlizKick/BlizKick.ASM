; FILE: Source:BlizKick.ASM          REV: 510 --- BlizKick - the ultimate maprom tool
; History
;  1      Running OK!
;  15     Now BlizKick should work with all Blizzard turbos.
;  19     Now BlizKick should even support KS 1.0... (?)
;  25     Added LOCALFAST feature.
;  31     Added QUICKBOOT feature.
;  33     Added better Printf.
;  48     Added Better ROM identification code (checksum).
;  65     Added "real" cache clear routine.
;  69     Fixed _seek bug.
;  71     Fixed KS 1.3 SPEEDROM bug.
;  81     Replaced "execinit" patch with resident tag.
;  107    Fix for Blizzard 1260! 1230-IV too!!
;  111    Added original Kickstart restoration.
;  114    Implemented KS1.x KS restoration.
;  115    Improved error messages.
;  116    Improved MAPROM test and CacheClear routine.
;  125    Added HOGWAITBLIT feature.
;  129    Added SetPatch (680x0.library) check.
;  175    Added MODULE feature.
;  186    Added EXTRESBUF feature.
;  210    Added External patches and BKMF_ExtResBuf flag, fixed 1.x ROMTag support.
;  215    Fixed LOCALFAST feature not to force MEMF_LOCAL or MEMF_KICK!
;  220    Fixed KS 1.x ROMTag support.
;  225    Added special handling for 1230-IV and 1260. Fixed FORCE.
;  240    Removed need to be run before SetPatch on 1260 systems.
;  248    Can be used with Enforcer, CPU FASTROM, VMM etc.
;  257    Improved 040/060 cache flushing code. BlizKick release 1.6.
;  266    Fixed bug in 040/060 MMU test code.
;  276    Added XPK support.
;  277    Modified to work better with PowerPC... :)
;  279    Added better (Old)OpenLibrary code. Removed FindName() things.
;  289    Fixed XPK support.
;  293    Now will set memory node name if null.
;  300    Fixed EXTRESBUF.
;  302    Fixed negative return code bug.
;  307    Added ROM address validity test.
;  311    Fixed BLIZZARD 2060 code.
;  313    Fixed one terrible bug from B2060 code.
;  328    Fixing EXTRESBUF...
;  332    Finished! Now it should work with 1260, 2040 and 2060.
;  338    DOES work on 1260. Fixed one minor bug. SoftSCSI module doesn't work.
;  340    Added memheader move code to LOCALFAST. -> Speed AllocMem()
;  343    Fixed reset code!
;  344    Allowed BlizKick to kick same kickfile and rom chip version.
;  348    Fixed .testblizppcrunnommu. Added pseudofile (*) feature.
;  353    Added LastPatches (fix for MEMF_REVERSE svstack, etc.)
;  361    Fixed svstack trash, disabled SVSTACKTRASH.
;  377    Added QUIET switch, fixed LastPatches, KS 33.180 works now!
;  388    Got KS 33.180 finally work 100%.
;  389    Added handling for BKMODPATH env variable.
;  399    Improved HOGWAITBLIT.
;  400    Found out that 2040 and 2060 boards are almost identical.
;  403    Fixed reset code to *disable* caches.
;  404    1.11ß1: Trying to get EXTRESBUF into fastmem.
;  412    Did it. Seems to work 100%.
;  415    Fixed MAPROM test. Now should detect if MAPROM not set.
;  416    Disabled SUPERVISOR_NOREVERSE from LastPatches.
;  421    Added support for (A4000?) CPU Cards.
;  425    Now KS 1.x are only patched if they're original versions. This should
;         prevent problems with some patches 1.x ROM images.
;  426    Fixed bug in ROM image validation test.
;  427    9th Dec 1997: ARGH! Wrote nice CPUCard support but forgot to enable
;         it!!! ;-)
;  429    Added support for Cyberstorm PPC and MKIII. Now should work at least
;         with CBM CPU Cards, Cyberstorm MKI, MKIII and PPC.
;  439    Separated A1200 and other model's check routines. Hopefully fixed CS
;         MKIII/PPC support. Added CS MKII support. Now CPUCARD is only meant to
;         be used with CS MKI & compatible.
;  442    Fixed few typos etc.
;  443    Fixed stupid BUG from CS support... THANKS DUKEN!! =)
;  444    Had mixed 20x0 and CS MK II product IDs... doh! Thanks shido at #amiga!
;  445    Fixed some Lock bugs.
;  446    13th May 1998 Made the source public in hope someone would continue the
;         development.
;  450    6th July 1998 Added Blizzard PPC support.
;  458    8th July 1998 Fixed Blizzard PPC and CS MKII support (I hope).
;  459    17th July 1998 Fixed stupid bug from CS MKII support.
;  461    4th October 1998 Finally fixed the blizz ppc bug. hehe.
;  462    6th October 1998 Fixed support for old KS.
;  463    9th October 1998 Fixed MK2 bug. Ta ChaoZer.
;  464    13th October 1998 Another MK2 fix <sigh>. Ta ChaoZer.
;  467    3rd November 1998 Disabled rom checksum disable in SPEEDROM.
;  468    24th January 1999 Fixed stupid blizzppc (and probably CSPPC too)
;         bug, blizzppc/csppc kernel overwrote EXTRES buffer. Now allocates
;         1mb extra memory. froze 1.18.
;  469    7th November 1999 Made BlizKick use fastmem hunks again. Finally
;         made it possible to `FORCE-after-maprom-is-already-active' and remove
;         maprom for Blizzard PPC.
;  470    Implemented new straightforward method to solve BKMODPATH variable
;         in DoPlanting routine.
;  471    Doesn't Delay(25) if QUIET is specified.
;  472    Added 040/060 move16 optimized copymem256.
;  473    Sped up FindResident and resident module reconnect. froze 1.19.
;  474    7th Jan 2000: Bumped revision strings to 1.20.
;  475    8th Jan 2000: Fixed major memory loss on extresbuf Deallocate on error
;         condition. Also that Deallocate() call wasn't called in Forbid state.
;  476    9th Jan 2000: New feature: you can give *any* loadsegable executable
;         as module. Resident modules inside will be initialized. Cool. Renders
;         SCSIDEV43 module obsolete, just give devs:scsi43.device as one module!
;         You can also give l:fastfilesystem etc! wooow, this is WAY too cool. :)
;         This required a change in the internal way of handling EXTRES buffer
;         + some new InternalLoadSeg code.
;  477    Now uses move.l an,an as nop when possible. FindResident bugged, it
;         scanned ROM first, then EXTRES buffer. Fixed to be opposite.
;  478    Added mmu.library support to getmmu and runnommu routine. This is a
;         "good thing"(TM).
;  479    14th Jan 2000: LOCALFAST and QUICKBOOT are now finally gone. Arguments
;         are there, but do nothing. Now the good news: Finally cleaned up the
;         code, and changed EXTRES buffer attaching to ROM such way it finally
;         works everytime on blizzppc. Yes! Added new argument SANITY/K/N to
;         specify sanity added to EXTRES buffer allocation in kbytes. PoolMem
;         could have fucked BlizKick in several ways, it changes MemHeaders on
;         the fly... Fixed. froze 1.20.
;  480    17th Jan 2000: *MAJOR BUG*: move16 could have easily got source
;         aligned by only 8 causing copy source shifted by 8 bytes -> non
;         working rom image. *THIS* has caused all these weird crashed with
;         different EXTRESBUF sizes. Me & my ultrafast copyloop. Duh! :(
;         Now uses *only* movem copy.
;  481    Wrote separate LocalFast module so removed ARG_LOCALFAST completely.
;         exe module support didn't set error code properly when out of EXTRES
;         buffer memory. Accidently called dos.library/Open for _gettc when
;         exec.library/Supervisor should have been called. Fun thing is that
;         this had so side effects. :) froze 1.21.
;  482    29th Jan: Fixed some nastiness from Blizzard 1230 maprom .testcode,
;         dunno if this fixes anything, but anyway it was bugged. mmu.library
;         getmmu was bugged: it always thought machine had 030 compatible MMU,
;         this didn't cause any problems though, but was wrong. Oops, stupid
;         bug in MK2 support, blo instead of bhi. Also 20x0 support could have
;         been affected. froze 1.22beta1.
;  483    31th Jan: removed CPU Card test code, I think it prevented it from
;         working, I hope. froze 1.22beta2.
;  484    3rd Feb: CS MK II works now, but BlizKick didn't recognize if it was
;         run before. Tweaked check code to run MMU disabled, see _checkactive.
;         froze 1.22beta3.
;  485    24th Feb: Disabled memory header name checks, should now work better
;         if memory node name is fucked. Fixed LocalFast module, it was kindof
;         broken. froze 1.22beta4.
;  486    my BK_MOD macro was fucked in previous release. damn! :(
;         froze 1.22beta5.
;  487    6th Mar: InstallModule BKMB_SingleMode misbehaved if module was
;         already installed. fixed. Forgot to remove LOCALFAST commandline
;         argument when I wrote LocalFast module. fixed. froze 1.22beta7.
;  488    7th Mar: Removed _regtemp stuff as mmu.library WithoutMMU passes
;         registers around. Rewrote runnommu, adding transparent translation
;         disable for 68030/68040/68060 and proper ATC cache flushing for
;         68030. Now BlizKick checks for activity first MMU enabled then MMU
;         disabled. Added elfloadseg-patch ioerr bug workaround, now you get
;         proper error message when module is not found. Added 256k ROM
;         support for CPU Cards. froze 1.22beta8.
;  489    27th Mar: oops, the new 030 runnommu accidently did rts instead of
;         rte. Definetely broke BlizKick on 030 machines. froze 1.22beta10.
;  490    28th Apr: No longer tries to open mmu.library if run before
;         SetPatch. froze 1.22beta11.
;  491    1st Aug: Bugfix: the 040+ cacheclear routine didn't invalidate the
;         data and inst cache after flush. froze 1.22beta12.
;  492    4th Aug: Bugfix: Terrible horrible stupid "nggh ngggh!" -level bug
;         fixed from 020/030 MMU test code, it fucked up VBR completely! Many
;         thanks go to "John Stunner" who found this and reported it at
;         ru.amiga 2nd Aug. Also special thanks to Useless who redirected this
;         message to me 3rd Aug. This bug was very evil as it fucked up ALL
;         exception vectors in VBR, every time BlizKick was run. So it made
;         030 systems very unstable... oh my god! ;) froze 1.22beta13.
;  493    6th Aug: Fixes to DisableCacheS: now invalidate cache on 040/060.
;         Made disable 060 superscalar dispatch. froze 1.22beta14.
;  494    7th Aug: Finally found the reason for CS MK II
;         'Kickstart wasn't kicked using BlizKick!' -error. When _restore check
;         failed it fell thru to this error message. Now has special error
;         message 'Kickstart restoring not supported!' for this case. Should
;         finally work fine on CS MK II. Now will quit quietly (RC = WARN) if
;         MorphOS is running. froze 1.22beta15.
;  495    10th Aug: PutResident RTF_AUTOINIT support was a bit broken. Never
;         really used, so was harmless. 15th Aug: Improved 030 runnommu not to
;         mess with mmu registers if mmu seems to be disabled already.
;  496    2nd Sep: froze 1.22.
;  497    4th Sep: Fixed silly bug from 030 MMU code, wrong stack offset was
;         used for restoring TC in runnommu (Remco Komduur). froze 1.23.
;  498    11th Sep: Total rewrote of the 040/060 cache & MMU code. Much cleaner
;         implementation now. Bugs fixed: runnommu didn't turn off 68060
;         StoreBuffer, could have caused malfunction with specific buggy CPU
;         Cards. runnommu didn't disable the 68060 Branch Cache, if 'Branch
;         Prediction Error' took place the code might have screwed up. The
;         CSPPC/CSMKIII/BPPC maprom trigger code restored only partial MMU
;         setup, and without clearning the ATC cache, if the MMU setup wasn't
;         standard the code probably screwed up. Maprom trigger code turned
;         off the 68060 StoreLoadBypass feature, now it isn't touched. Now
;         mmu.library/WithoutMMU() is only used for pre-68040 CPUs. froze
;         1.24beta1.
; 499     12th Oct: fixed small bug in SPEEDROM: the RT_END of the last ROMTag
;         was made to point to $fffffe. Due some funny side effect ($1000000 -
;         $fffffe) / 2 - 1 = 0) it caused the ROM's ROMTag scanner access
;         longword at $fffffe, thus accessing non-existent memory. (maybe this
;         was it Gunther... :-) froze 1.24beta2.
; 500     3rd Nov 2000: I broke CPUCARD support when I added 256K rom support
;         in 1.22beta8. Oh my, oh my, now I feel very stupid.:-).
; 501     6th Nov 2000: Now this one was funny: I had some really weird & crap
;         problems with TC_EXCEPTCODE with another project. Turned out that
;         that BlizKick's final Forbid() was the cause for ALL those problems.
;         Now that I think of it, it makes NO sense to call Forbid() before
;         final 'rts' in a CLI program, it is only valid in WB programs. This
;         bugfix probably solves lots of those weird problems there has been
;         with BlizKick. froze 1.24beta3.
; 502     24th Jan 2001: Copyright update recompile. froze 1.24beta5.
; 503     1st Feb 2001: (Hopefully) added EXTRESBUF support for CPUCARDs
;         (^Berserk^). Now default to BKMODPATH of "DEVS:Modules/" if the
;         env variable is not found (Lizard). Added IGNPATH option for
;         completeness. Reworked B20x0 code, hopefully fixed some problems.
;         Reworked KickSys to use set of subroutines for different cards,
;         much cleaner now. froze 1.24beta6.
; 504     24th Oct 2001: Minor code cleanups. Fixed 12th Oct 2001 flashrom
;         problem (In the new flashrom the blizzard memory node attributes
;         was added MEMF_LOCAL flag, which prevented BlizKick from locating
;         the memory node. Generally this is good thing (TM), since this
;         finally officially documents the feature that blizzppc memory
;         doesn't go away at reset. However, I was unable to predict this
;         change, and while I want BlizKick to be 100% bulletproof when
;         probing for the memory node, this change broke it). froze 1.24beta7.
; 505     25th Oct 2001: Fixed massive bug in mmu.library logic. Now it
;         really should work as expected. If maprom was available but failed
;         to initialize BlizKick crashed horribly. Fixed. I think these bugs
;         were added in 1.24beta6. Found a very long standing bug from PUP-
;         cards reboot code: due to some card reset hardware magic, ExecBase
;         was never trashed like with other cards. This caused all reset
;         proof applications to stay in memory, which definetely is not what
;         should happen. Fixed to behave like other cards. Added commandline
;         option to disable trashing of ExecBase (KEEPEXEC), however its'
;         use is not recommended and it can cause some weird problems. Fixed
;         *very* long standing problem with some PowerUP systems where
;         rebooting the system gave red screen (ie. ROM checksum wrong).
;         New commandline option NOPUPREBOOT fixes this behaviour on these
;         systems. froze 1.24beta8.
; 506     10th Mar 2002: Fixed to set dfc to 1 for pflusha on 68040/68060.
;         froze 1.24rc1.
; 507     22nd Mar 2002: Fixed exec 45.x of AmigaOS 3.9 BoingBag2.
; 508     4th Jun 2002: Added HAVE_ERB_MMUALIGN. 
; 509     11th Jan 2003: Copyright update.
; 510     14th Oct 2003: Fixed a bug in Cyberstorm memlist scanner. Added UAE
;         support.
;

;DEBUGMODE	EQU	1		;don't clone code

;
; I seriously doubt if this source code is useful for anything else.
; Hairy code everywhere, this one is really a bitch to maintain...
;

; TODO (err, not never, maybe, huh)
; o total rewrite in C (btw is still currently in progress ;-)
; o unused romtag zapper & support for this extra space to FindSpace.
;   also add this functionality to applypatch
; o BootControl module. Maybe. Requested by several users.
; o ROM checksum (restore orig rom if bad ROM checksum)
; o possibility to get commandline arguments from a file
;   (can be emulated with `BlizKick ? <cmd_file')
;

USE_STD_INCLUDES	SET	1
	IFNE	USE_STD_INCLUDES
	MACHINE	MC68040
	include	"exec/types.i"
	include	"exec/nodes.i"
	include	"exec/libraries.i"
	include	"exec/memory.i"
	include	"exec/execbase.i"
	include	"exec/resident.i"
	include	"exec/alerts.i"
	include	"exec/semaphores.i"
	include	"dos/dos.i"
	include	"exec/exec_lib.i"
	include	"dos/dos_lib.i"
	include	"graphics/gfxbase.i"
	include	"graphics/graphics_lib.i"
call	MACRO
	jsr	(_LVO\1,a6)
	ENDM
	ELSE
	include	"Devpac:Gen.gs"
	ENDC
	include	"dos/dosextens.i"
	include	"libraries/configvars.i"
	include	"libraries/expansion_lib.i"
	include	"hardware/dmabits.i"
	include	"hardware/custom.i"

	include	"libraries/xpk.i"	; from xpk_dev

	include	"blizkickmodule.i"


UAEPROD	EQU	2011

; mmu.library LVOs
	IFND	_LVOGetMMUType
_LVOGetMMUType	EQU	-$36
_LVOWithoutMMU	EQU	-$10E
	ENDC

	IFND	MUTYPE_NONE
MUTYPE_NONE     equ     0
MUTYPE_68851    equ     '2'
MUTYPE_68030    equ     '3'
MUTYPE_68040    equ     '4'
MUTYPE_68060    equ     '6'
	ENDC

; PoolMem uses this to indicate small pool MemHeader.
; We don't want to get EXTRES buffer memory from such mem...
	BITDEF	MEM,POOLMEM,4


; 68040 / 68060 CACR bits
	BITDEF	CACR,HalfICache,13		;060
	BITDEF	CACR,NoAllocateI,14		;040/060
	BITDEF	CACR,EnableICache,15		;040/060
	BITDEF	CACR,ClearUserBCache,21		;060
	BITDEF	CACR,ClearAllBCache,22		;060
	BITDEF	CACR,EnableBCache,23		;060
	BITDEF	CACR,HalfDCache,27		;060
	BITDEF	CACR,DisableCPUSHInv,28		;060?
	BITDEF	CACR,EnableStoreBuffer,29	;060
	BITDEF	CACR,NoAllocateD,30		;040/060
	BITDEF	CACR,EnableDCache,31		;040/060

; 68040 / 68060 CACR bitmasks
CACRF_CachesOr040	EQU	CACRF_EnableDCache|CACRF_EnableICache
CACRF_CachesAnd040	EQU	CACRF_NoAllocateI|CACRF_NoAllocateD
CACRF_CachesOr060	EQU	CACRF_CachesOr040|CACRF_EnableStoreBuffer|CACRF_EnableBCache
CACRF_CachesAnd060	EQU	CACRF_CachesAnd040|CACRF_DisableCPUSHInv|CACRF_HalfICache|CACRF_HalfDCache

; 68060 PCR bits
	BITDEF	PCR,EnableDebugFeatures,7	;060
	BITDEF	PCR,StoreLoadBypass,5		;060
	BITDEF	PCR,DisableFPU,1		;060
	BITDEF	PCR,EnableSuperScalar,0		;060


ARG_KICKFILE	EQU	0
ARG_MODULE	EQU	4
ARG_EXTRESBUF	EQU	8
ARG_SANITY	EQU	12
ARG_FORCE	EQU	16
ARG_SPEEDROM	EQU	20
ARG_HOGWAITBLIT	EQU	24
ARG_CPUCARD	EQU	28
ARG_IGNPATH	EQU	32
ARG_NOPUPREBOOT	EQU	36
ARG_KEEPEXEC	EQU	40
ARG_QUIET	EQU	44

BLIZPROD	EQU	$2140
ROMSUMOFFS	EQU	-$18
ROMSIZEOFFS	EQU	-$14
IDOFFS	EQU	-$10
BLIZKICK_ID	EQU	'BlzK'
DEF_SANITY	EQU	32		;default allocation sanity buffer, 32k

HAVE_SPEEDROMCHECKSUM	EQU	0	;1 = disable rom checksum on SPEEDROM
HAVE_NEW_ENV_METHOD	EQU	1	;1 = use new BKMODPATH solve routine
HAVE_DEFBKMODPATH	EQU	1	;1 = if no BKMODPATH var is found use "DEVS:Modules/"
HAVE_CPUCARDPOKING	EQU	0	;0 = don't unnecaccarily mess with the CPU Card
HAVE_ERB_MMUALIGN	EQU	1	;1 = align EXTRESBUF by MAXMMUPAGESIZE
MAXMMUPAGESIZE		EQU	8192

	SECTION	CODE,CODE

Main	move.l	a0,a2
	move.l	d0,d2
	move.l	(4).w,a6

	lea	(.morphosname,pc),a1
	call	Forbid
	call	FindResident
	move.l	d0,d3
	lea	(_enforcer,pc),a1
	call	FindPort
	lea	(_EnforcerFlag,pc),a0
	move.l	d0,(a0)
	; Figure out if it is ok to try using mmu.library. requrements:
	; 1. SetPatch is run
	; 2. mmu.library is in memory
	lea	(.setpatchname,pc),a1
	call	FindSemaphore
	tst.l	d0
	beq.b	.no_setpatch
	lea	(LibList,a6),a0
	lea	(.mmuname,pc),a1
	call	FindName
.no_setpatch
	; d0 = nonzero if it's ok to use mmu library
	call	Permit
	tst.l	d3
	beq.b	.no_morphos
	; quit silently if MorphOS...
	moveq	#RETURN_WARN,d0
	rts
.no_morphos
	; NOTE: must use d0 for this coz else .dont_try craps!
	tst.l	d0
	beq.b	.dont_try
	lea	(.mmuname,pc),a1
	moveq	#41,d0
	bsr	OpenLib
.dont_try	lea	(_mmubase,pc),a0
	move.l	d0,(a0)

	lea	(_ExecBase,pc),a0
	move.l	a6,(a0)
	lea	(_AttnFlags,pc),a0
	move.w	(AttnFlags,a6),(a0)

	IFGT	0
	btst	#AFB_68040,(_AttnFlags+1,pc)
	bne.b	.has_040
	lea	(copymem256,pc),a0
	move.w	#$6000|(copymem256_000-copymem256-2),(a0)
.has_040
	ENDC

	moveq	#RETURN_FAIL,d7

	IFD	DEBUGMODE

	bsr	CacheClearOS
	bsr	Copy
	move.l	d0,d7			; save return code

	ELSE

	move.l	#COPYCODE_SIZEOF,d0
	move.l	#MEMF_PUBLIC,d1
	call	AllocMem
	tst.l	d0
	beq.b	.exit

	move.l	d0,-(sp)		; store the pointer to stack
	move.l	d0,a1
	lea	(Copy,pc),a0
	move.l	#COPYCODE_SIZEOF,d0
	call	CopyMemQuick		; copy the code to the MEMF_PUBLIC buffer
	bsr	CacheClearOS
	move.l	(sp),a0			; restore the buffer ptr
	jsr	(a0)			; call the code in the buffer
	move.l	d0,d7			; save return code
	move.l	(sp)+,a1
	move.l	#COPYCODE_SIZEOF,d0	; free the MEMF_PUBLIC buffer
	call	FreeMem

	ENDC
.exit
	; a6 = execbase
	move.l	(_mmubase,pc),d0
	beq.b	.nommulib
	move.l	d0,a1
	call	CloseLibrary
.nommulib	move.l	d7,d0			; set return code
	rts				; *poof*

.morphosname	dc.b	'MorphOS',0
.setpatchname	dc.b	'« SetPatch »',0
.mmuname	dc.b	'mmu.library',0


	CNOP	0,4
Copy
	lea	(DosName,pc),a1
	moveq	#33,d0
	bsr	OpenLib
	move.l	d0,d6
	beq	.exit
	move.l	d0,a6

	moveq	#0,d4			Set default!!

	cmp.w	#37,(LIB_VERSION,a6)
	shs	d5

	; get mmu type
	bsr	getmmu
	lea	(_mmuflag,pc),a0
	move.b	d0,(a0)

	lea	(_Array,pc),a3
	tst.b	d5
	bne.b	.ks20
	clr.l	-1(a2,d2.l)
	subq.l	#1,d2
	beq.b	.do			RESTORE!
	move.l	a2,(a3)
	lea	(_13Help,pc),a0
	cmp.b	#'?',(a2)
	bne.b	.do
	subq.l	#1,d2
	beq	.printmsgexit
	bra.b	.do
.ks20	lea	(_Template,pc),a0
	move.l	a0,d1
	move.l	a3,d2
	moveq	#0,d3
	call	ReadArgs
	move.l	d0,d4
	beq	.badargs

.do
	lea	(_Quiet,pc),a0
	move.l	(ARG_QUIET,a3),(a0)

	tst.l	(ARG_CPUCARD,a3)
	beq.b	.no_cpucard
	bsr	TestCPUCard
	lea	(_CPUCard,pc),a0
	move.b	d0,(a0)
	bne.b	.has_cpucard
	lea	(NoCPUCard,pc),a0
	bra.b	.printmsgexit
.no_cpucard

	bsr	TestHardware
	lea	(NoHardware,pc),a0
	lea	(_BlizROM,pc),a1
	move.l	d0,(a1)
	beq.b	.printmsgexit
.has_cpucard

	movem.l	d4-d6/a6,-(sp)
	moveq	#RETURN_ERROR,d7
	lea	(Messu,pc),a0
	bsr	_PrintHeaderf
	bsr	_HeadMain
	movem.l	(sp)+,d4-d6/a6

.freeargs	tst.b	d5
	beq.b	.closedos
	move.l	d4,d1
	call	FreeArgs
.closedos	move.l	d6,a1
	move.l	(_ExecBase,pc),a6
	call	CloseLibrary
.exit
	move.l	d7,d0
	rts

.printmsgexit	bsr	_PrintHeaderf
	bra.b	.freeargs

.badargs	bsr.b	_PrintFault		IN: d5=kickflag, d6=dosbase
	bra.b	.closedos


;  IN: d5=kickflag, d6=dosbase
; OUT: Fault printed
_PrintFault	movem.l	d0-d2/a0-a1/a6,-(sp)
	move.l	(_Quiet,pc),d0
	bne.b	.exit
	move.l	d6,a6
	call	IoErr
	tst.b	d5
	beq.b	.oldie
	move.l	d0,d1
	moveq	#0,d2
	call	PrintFault
.exit	movem.l	(sp)+,d0-d2/a0-a1/a6
	rts

.oldie	move.l	d0,-(sp)
	beq.b	.noerr
	lea	(_ks13error,pc),a0
	move.l	sp,a1
	bsr	_Printf
.noerr	addq.l	#4,sp
	bra.b	.exit


;  IN: A0=FmtString, A1=Array, a2=Buffer
; OUT: Formatted text
_Sprintf	movem.l	d0-d1/a0-a3/a6,-(sp)
	move.l	a2,a3
	lea	(.putchar,pc),a2
	move.l	(_ExecBase,pc),a6
	call	RawDoFmt
	movem.l	(sp)+,d0-d1/a0-a3/a6
	rts
.putchar	move.b	d0,(a3)+
	rts


;  IN: A0=FmtString, A1=Array, d6=dosbase
; OUT: Printed text, including program info header
_PrintHeaderf	movem.l	d0-d1/a0-a2/a6,-(sp)
	move.l	(_ExecBase,pc),a6
	move.l	#$10000,d0		; Allocate 64k buffer
	moveq	#MEMF_ANY,d1
	call	AllocMem
	move.l	d0,-(sp)
	beq.b	.nomem
	movem.l	(3*4,sp),a0-a1
	move.l	(sp),a2
	bsr.b	_Sprintf
	pea	(_Copyright,pc)
	pea	(_Version,pc)
	lea	(.header,pc),a0
	move.l	sp,a1
	bsr.b	_Printf
	addq.l	#8,sp
.nomem	move.l	(sp)+,d0
	beq.b	.exit
	move.l	d0,a1
	move.l	#$10000,d0
	call	FreeMem
.exit	movem.l	(sp)+,d0-d1/a0-a2/a6
	rts
.header	dc.b	$9B,'1;32m%s',$9B,'31m %s.',$9B,'0m',10
	dc.b	'%s',0
	CNOP	0,2


	STRUCTURE pf_data,0
	APTR	pfd_DosBase
	APTR	pfd_Count
	STRUCT	pfd_Buffer,256
	LABEL	pf_data_SIZEOF

	CNOP	0,4
;;_OutputFH	dc.l	0
;  IN: A0=FmtString, A1=Array (may be 0), d6=dosbase
; OUT: Printed text
_Printf
Printf	movem.l	a0-a3/a6/d0-d3,-(sp)
	move.l	(_Quiet,pc),d0
	bne.b	.exit
	lea	(-pf_data_SIZEOF,sp),sp
	move.l	sp,a3
	move.l	d6,(a3)+
	clr.l	(a3)+
	lea	(.newchar,pc),a2
	move.l	(_ExecBase,pc),a6
	call	RawDoFmt
	move.l	d6,a6
	IFD	_OutputFH
	move.l	_OutputFH,d1
	ELSE
	call	Output
	move.l	d0,d1
	ENDC
	move.l	a3,d2
	move.l	(-4,a3),d3
	call	Write
	lea	(pf_data_SIZEOF,sp),sp
.exit	movem.l	(sp)+,a0-a3/a6/d0-d3
	rts
.newchar	movem.l	d0-d3/a0-a1/a3/a6,-(sp)
	move.l	a3,d2				for Write()
	move.l	-(a3),d1
	move.b	d0,4(a3,d1.l)
	addq.b	#1,d1
	move.l	d1,(a3)
	bne.b	.dont_print
	move.l	-(a3),a6
	IFD	_OutputFH
	move.l	_OutputFH,d1
	ELSE
	call	Output
	move.l	d0,d1
	ENDC
	move.l	#256,d3
	call	Write
.dont_print	movem.l	(sp)+,d0-d3/a0-a1/a3/a6
	rts


;  IN: d6=dosbase, *must* remain if you're going to call internal _xxx functions
;      a3=paramarray, is zero if null template, scratch
;      a6=dosbase, scratch
; OUT: d7=return code
_HeadMain
	bsr	_checkactive
	move.b	d0,d2
	beq.b	.isactive
	lea	(_checkactive,pc),a0
	bsr	runnommu
	move.b	d0,d2			keep this flag for a while
.isactive

	tst.l	(a3)			(ARG_KICKFILE,a3)
	bne.b	.norestore

	tst.b	d2
	bne.b	.notactive
	lea	(_restore,pc),a0
	bsr	runnommu
	tst.l	d0
	beq.b	.norestore2

	; a4 & d3 are set
	bsr	KickSys
.norestore2
	lea	(NoRestore,pc),a0
	bra	_Printf
.notactive
	lea	(NoRem,pc),a0
	bra	_Printf
.norestore

	moveq	#0,d1			!!
	bsr	SetIoErr

	tst.l	(ARG_FORCE,a3)
	bne.b	.force1

	moveq	#RETURN_WARN,d7
	tst.b	d2
	beq	.exit			Already kicked!

	moveq	#RETURN_ERROR,d7

.force1	move.l	(a3),a0			(ARG_KICKFILE,a3),a0
	cmp.b	#'*',(a0)
	bne.b	.not_pseudofile
	tst.b	(1,a0)
	bne.b	.not_pseudofile

	; Handle "*" -file:
	tst.b	d2			Test for kicked ROM.
	beq	.exit			Already kicked!
	lea	$01000000+IDOFFS,a4	Will fail if kicked previously!
	move.l	-(a4),d3		a4=$01000000+ROMSIZEOFFS
	move.l	d3,d0
	moveq	#MEMF_PUBLIC,d1
	move.l	(_ExecBase,pc),a6
	call	AllocMem
	tst.l	d0
	beq	.exit
	move.l	a4,a0
	sub.l	d3,a0
	add.w	#-ROMSIZEOFFS,a0
	move.l	d0,a4
	move.l	a4,a1
	move.l	d3,d0
	call	CopyMemQuick
	move.l	d3,d1
	move.l	d3,d4
	bra.b	.cont_pseudo

.not_pseudofile
	bsr	XPKLoad
	beq	.exit
	move.l	a1,a4
	move.l	d1,d3
	move.l	d0,d4

.cont_pseudo	and.l	#$FFF3FFFF,d1		256K or 512K ROM
	bne	.free
	cmp.l	#$00080000,d3
	bhi	.free
	lea	ROMSUMOFFS(a4,d3.l),a5
	cmp.l	(4,a5),d3		Compare to romsize
	bne	.free

	move.l	(a4),d2
	and.l	#$FFF8FFFF,d2
	cmp.l	#$11104EF9,d2
	bne	.free
	move.l	(4,a4),d2		Test for relocated ROM
	add.l	d3,d2
	swap	d2
	cmp.w	#$0100,d2
	bne	.free

	move.l	a4,a0			Get original ROM checksum
	move.l	d3,d0
	bsr	ROMReSum
	lea	(_OrigSum,pc),a0
	move.l	d0,(a0)

	movem.l	($C,a4),d0/d1		Fix for old KS
	addq.l	#1,d0
	bne.b	.nofix
	move.l	d1,($C,a4)
.nofix
	tst.l	(ARG_FORCE,a3)
	bne.b	.force2

	moveq	#RETURN_WARN,d7
	lea	$01000000,a1
	move.l	a1,a0
	sub.l	(ROMSIZEOFFS,a0),a0
	move.l	($C,a0),d0		Test for different version.
	cmp.l	($C,a4),d0
	bne.b	.kick

	cmp.l	#BLIZKICK_ID,(8,a5)	Test for kicked file.
	beq.b	.free

.kick	moveq	#RETURN_ERROR,d7
.force2
	move.l	(_Quiet,pc),d0
	bne.b	.no_output
	lea	(Messu2,pc),a0
	lea	($C,a4),a1
	bsr	_Printf
	move.l	d6,a6
	moveq	#25,d1
	call	Delay
.no_output
	bsr.b	GoForIt

.free	move.l	(_ExecBase,pc),a6
	move.l	a4,a1
	move.l	d4,d0
	call	FreeMem

.exit	tst.l	d7
	bmi.b	.nexitok
	beq.b	.exitok
	bsr	_PrintFault		IN: d5=kickflag, d6=dosbase
	lea	(Already,pc),a0
	cmp.w	#RETURN_WARN,d7
	beq.b	.thiserr
	lea	(CouldNotKick,pc),a0
.thiserr	move.l	a3,a1
	bra	_Printf
.nexitok	neg.l	d7			result IN d7!!
.exitok	rts



GoForIt	;illegal

	neg.l	d7
	move.l	(_ExecBase,pc),a6

	move.l	(ARG_EXTRESBUF,a3),d0
	beq.b	.no_extbuf
	move.l	d0,a0
	move.l	(a0),d1

	move.l	#DEF_SANITY,d2
	move.l	(ARG_SANITY,a3),d0
	beq.b	.nosanity
	move.l	d0,a0
	move.l	(a0),d2
.nosanity	lsl.l	#8,d2
	lsl.l	#2,d2			*1024

	move.l	a4,a0
	move.l	d3,d0
	bsr	ExtResBuf
	bne.b	.got_extbuf
	bsr	_PrintFault		IN: d5=kickflag, d6=dosbase
	bra.b	.fail
.got_extbuf
.no_extbuf
	tst.l	(ARG_HOGWAITBLIT,a3)
	beq.b	.no_agawblit
	move.l	a4,a0
	move.l	d3,d0
	bsr	PutHogWaitBlit
.no_agawblit
	move.l	a4,a0
	move.l	d3,d0
	bsr	DoPlanting
	beq.b	.fail

	tst.l	(ARG_SPEEDROM,a3)
	beq.b	.no_patch2
	move.l	a4,a0
	move.l	d3,d0
	bsr	SpeedROM
.no_patch2

	move.l	a4,a0
	move.l	d3,d0
	bsr	LastPatches


	move.l	a4,a0
	move.l	d3,d0
	bsr	HackExec45


	move.l	#BLIZKICK_ID,IDOFFS(a4,d3.l)
	move.l	a4,a0
	move.l	d3,d0
	bsr.b	ROMReSum
	move.l	d0,ROMSUMOFFS(a4,d3.l)
	bsr	CacheClearOS

	bsr	KickSys
.fail

;;	bra	FreeExtResBuf

;  IN: a6=execbase
; OUT: d0/d1/a0/a1 trashed
FreeExtResBuf
	move.l	(_erh_freeaddr,pc),d0
	beq.b	.xit
	move.l	d0,a1
	move.b	(_MemHeaderFlag,pc),d1
	beq.b	.xit
	call	Forbid
	lea	(_memhead,pc),a0
	bsr	FindMemHeader
	beq.b	.cantfind
	move.l	(_erh_alloclen,pc),d0
	call	Deallocate
.cantfind	call	Permit
	lea	(_erh_freeaddr,pc),a0
	clr.l	(a0)
.xit	rts


ROMReSum	move.l	d0,d1
	lsr.l	#2,d1
	move.l	ROMSUMOFFS(a0,d0.l),d0
	not.l	d0
.loop	add.l	(a0)+,d0
	bcc.b	.skip
	addq.l	#1,d0
.skip	subq.l	#1,d1
	bne.b	.loop
	not.l	d0
	rts



	; Test for kicked ROM:
_checkactive	cmp.l	#BLIZKICK_ID,$01000000+IDOFFS
	sne	d0
	rts


_restore	lea	$0B80000,a4		Magic address!
	move.l	(ROMSIZEOFFS,a4),d3
	move.l	d3,d0
	and.l	#$FFF3FFFF,d0		256K or 512K ROM
	bne.b	.exitrts
	cmp.l	#$00080000,d3
	bhi.b	.exitrts
	sub.l	d3,a4

	; sanity check...
	move.l	(a4),d0
	and.l	#$FFF8FFFF,d0
	cmp.l	#$11104EF9,d0
	bne.b	.exitrts

	moveq	#1,d0
	rts
.exitrts	moveq	#0,d0
	rts


;  IN: -
; OUT: d0=0 if no mmu, -1 if 040/060 mmu, 1 if 030/851 MMU.
getmmu	movem.l	d1-a6,-(sp)
	moveq	#0,d7

	move.l	(_mmubase,pc),d0
	bne.b	.use_mmulib

	move.l	(_ExecBase,pc),a6
	move.w	(AttnFlags,a6),d0
	btst	#AFB_68020,d0
	beq.b	.exit
	cmp.w	#37,(LIB_VERSION,a6)
	blo.b	.oldtest

	moveq	#-1,d7
	lea	(.test040plus,pc),a5
	btst	#AFB_68040,d0
	bne.b	.test
.oldtest	moveq	#1,d7
	lea	(.test020plus,pc),a5

.test	call	Disable
	call	Supervisor
	call	Enable

.exit	move.l	d7,d0
	movem.l	(sp)+,d1-a6
	rts


.use_mmulib	move.l	d0,a6	
	call	GetMMUType
	move.b	d0,d7
	beq.b	.exit

	moveq	#-1,d7
	cmp.b	#MUTYPE_68040,d0	040 MMU
	beq.b	.exit
	cmp.b	#MUTYPE_68060,d0	060 MMU
	beq.b	.exit

	moveq	#1,d7			851/030 MMU
	bra.b	.exit


.test040plus	or.w	#$700,sr		Disable interrupts.
	movec	vbr,a0			Get VBR
	move.l	($10,a0),-(sp)		Save Illegal Instruction vector
	move.l	a0,-(sp)		Save VBR
	lea	(.illegal040,pc),a1
	move.l	a1,($10,a0)
	cpusha	bc
	cinva	bc

	movec	tc,d0			$4e7a0003	Test some "common" MMU regs:
	movec	urp,d1			$4e7a1806	Test 040/060 MMU only reg!!
	movec	srp,d1			$4e7a1807	Test 040/060 MMU only reg!!
	nop
.exit040
	move.l	(sp)+,a0
	move.l	(sp)+,($10,a0)		Restore Illegal Instruction vector
	cpusha	bc
	cinva	bc
	nop
	rte


	CNOP	0,4
.illegal040	moveq	#0,d7
	lea	(.exit040,pc),a0
	move.l	a0,(2,sp)
	cpusha	bc
	cinva	bc
	nop
	rte


.test020plus	or.w	#$700,sr		Disable interrupts.

	;···

	movec	vbr,a0			Get VBR
	move.l	($10,a0),-(sp)		Save Illegal Instruction vector
	move.l	($2C,a0),-(sp)		Save F-Line Emul vector
	move.l	($E0,a0),-(sp)		Save MMU Config Error vector
	move.l	($E4,a0),-(sp)		Save MMU Illegal Operation Error vector
	move.l	($E8,a0),-(sp)		Save MMU Access Level Violation Error vector
	move.l	a0,-(sp)		Save VBR

	subq.l	#4,sp			Bug: This was at ··· before ("John Stunner" & Useless)

	lea	(.mmuinstfailure,pc),a1
	move.l	a1,($10,a0)
	move.l	a1,($2C,a0)
	move.l	a1,($E0,a0)
	move.l	a1,($E4,a0)
	move.l	a1,($E8,a0)

	bsr	_flush020

	; Try to get TC
	dc.w	$F000,$2400		pflusha
	dc.w	$F017,$4200		pmove.l tc,(sp)
	dc.w	$F000,$2400		pflusha
.exitsuper
	addq.l	#4,sp
	move.l	(sp)+,a0		Restore VBR
	move.l	(sp)+,($E8,a0)		Restore MMU Access Level Violation Error vector
	move.l	(sp)+,($E4,a0)		Restore MMU Illegal Operation vector
	move.l	(sp)+,($E0,a0)		Restore MMU Config Error vector
	move.l	(sp)+,($2C,a0)		Restore F-Line Emul vector
	move.l	(sp)+,($10,a0)		Restore Illegal...
.exitall	bsr.b	_flush020
	nop
	rte

.mmuinstfailure	moveq	#0,d7
	lea	(.exitsuper,pc),a0	Invalid mmu instruction!
	move.l	a0,(2,sp)
	bsr.b	_flush020
	nop
	rte


_flush020	move.l	d0,-(sp)
	movec	cacr,d0
	or.w	#CACRF_ClearI!CACRF_ClearD,d0
	movec	d0,cacr
	move.l	(sp)+,d0
	rts


; runnommu -- run routine with mmu disabled
;
;  IN: a0=code to run in supervisor, mmu off. *MUST* return with rts!!
; OUT: d0=whatever values routine leaves to d0. cc's set accordingly.
;NOTE: registers d0-d7/a0-a4 are passed to routine as is. Also routine
;      can return these registers.
;
runnommu	movem.l	a5/a6,-(sp)
	move.l	(_mmubase,pc),-(sp)
	bne	.use_mmulib
.dont_use	move.l	(_ExecBase,pc),a6
	move.b	(_mmuflag,pc),(sp)
	lea	(.discodenommu,pc),a5
	addq.l	#4,sp
	beq.b	.doit
	lea	(.discode020,pc),a5
	bpl.b	.doit
	lea	(.discode040,pc),a5
.doit	call	Disable
	call	Supervisor
	call	Enable
.exit	movem.l	(sp)+,a5/a6
	tst.l	d0
	rts

.use_mmulib	; only use mmu.library WithoutMMU() for 68020/68030
	btst	#AFB_68040,(_AttnFlags+1,pc)
	bne.b	.dont_use

	move.l	(sp)+,a6
	move.l	a0,a5
	call	WithoutMMU
	bsr	CacheClearOS
	bra.b	.exit


.discodenommu	or.w	#$700,sr
	jsr	(a0)
	bsr	CacheClrS
	nop
	rte

.discode020	or.w	#$700,sr
	subq.l	#4,sp
	dc.w	$F017,$4200		pmove.l tc,(sp)
	subq.l	#4,sp
	dc.w	$F017,$0E00		pmove.l tt1,(sp)
	subq.l	#4,sp
	dc.w	$F017,$0A00		pmove.l tt0,(sp)
	clr.l	-(sp)
	dc.w	$F000,$2400		pflusha
	tst.w	(1*4+2,sp)
	bpl.b	.dontdis1
	dc.w	$F017,$0800		pmove.l (sp),tt0
.dontdis1	tst.w	(2*4+2,sp)
	bpl.b	.dontdis2
	dc.w	$F017,$0C00		pmove.l (sp),tt1
.dontdis2	tst.l	(3*4,sp)
	bpl.b	.dontdis3
	dc.w	$F000,$2400		pflusha
	dc.w	$F017,$4000		pmove.l	(sp),tc
.dontdis3	dc.w	$F000,$2400		pflusha
	addq.l	#4,sp
	bsr	_flush020
	jsr	(a0)
	bsr	_flush020
	dc.w	$F000,$2400		pflusha
	tst.w	(2,sp)
	bpl.b	.dontrest1
	dc.w	$F017,$0800		pmove.l (sp),tt0
.dontrest1	addq.l	#4,sp
	tst.w	(2,sp)
	bpl.b	.dontrest2
	dc.w	$F017,$0C00		pmove.l (sp),tt1
.dontrest2	addq.l	#4,sp
	tst.l	(sp)			NOTE: can't use (sp)+ !
	bpl.b	.dontrest3
	dc.w	$F000,$2400		pflusha
	dc.w	$F017,$4000		pmove.l	(sp),tc
.dontrest3	addq.l	#4,sp
	dc.w	$F000,$2400		pflusha
	bsr	_flush020
	nop
	rte


.discode040	or.w	#$700,sr
	movem.l	d0/a0,-(sp)
	lea	(_mmuregs,pc),a0
	movec	itt0,d0
	move.l	d0,(a0)+
	movec	itt1,d0
	move.l	d0,(a0)+
	movec	dtt0,d0
	move.l	d0,(a0)+
	movec	dtt1,d0
	move.l	d0,(a0)+
	movec	cacr,d0
	move.l	d0,(a0)+
	movec	tc,d0
	move.l	d0,(a0)+
	movec	dfc,d0
	move.l	d0,(a0)+
	cpusha	bc			make sure the above are stored
	cinva	bc
	; LAmask=$ff E=%1 S=%10 (Ignore FC2 when matching), CM=%00 (Cacheable, Writethrough), W=%0 (R/W)
	move.l	#$00FFC000,d0
	movec	d0,itt0
	movec	d0,itt1
	movec	d0,dtt1
	; LAmask=$00 E=%1 S=%10 (Ignore FC2 when matching) CM=%10 (Cache-Inhibited, Precise Exception Model), W=%0 (R/W)
	move.l	#$0000C040,d0
	movec	d0,dtt0
	; NAD = 0, ESB = 0, DPI = 0, FOC = 0, EBC = 0, NAI = 0, FIC = 0
	; EDC = 1, EIC = 1
	move.l	#CACRF_EnableDCache|CACRF_EnableICache,d0
	movec	d0,cacr
	; E = 0, P = 0, NAD = 0, NAI = 0, FOTC = 0, FITC = 0, DCO = 00
	; DUO = 00, DWO = 0, DCI = 00, DUI = 00,
	moveq	#1,d0
	movec	d0,dfc
	moveq	#0,d0
	pflusha
	movec	d0,tc
	movem.l	(sp)+,d0/a0
	jsr	(a0)
	cpusha	bc
	cinva	bc
	movem.l	d0/a0,-(sp)
	lea	(_mmuregs,pc),a0
	move.l	(a0)+,d0
	movec	d0,itt0
	move.l	(a0)+,d0
	movec	d0,itt1
	move.l	(a0)+,d0
	movec	d0,dtt0
	move.l	(a0)+,d0
	movec	d0,dtt1
	move.l	(a0)+,d0
	movec	d0,cacr
	moveq	#1,d0
	movec	d0,dfc
	move.l	(a0)+,d0
	pflusha
	movec	d0,tc
	move.l	(a0)+,d0
	cpusha	bc
	cinva	bc
	movec	d0,dfc
	movem.l	(sp)+,d0/a0
	nop
	rte


; runwithmmu040 -- run routine with original mmu setup, 040/060
;
;  IN: a0=code to run with origiginal mmu state. *MUST* return with rts!!
; OUT: d0=whatever values routine leaves to d0. cc's set accordingly.
;NOTE: registers d0-d7/a0-a6 are passed to routine as is. Also routine
;      can return these registers.
;
; WARNING! ONLY CALL THIS ROUTINE WITHIN runnommu code!
;
runwithmmu040	move.l	d0,-(sp)
	move.b	(_mmuflag,pc),d0
	bmi.b	.got

	move.l	(sp)+,d0
	bsr	CacheClrS
	jsr	(a0)
	bra	CacheClrS
.got
	movec	dfc,d0
	move.l	d0,-(sp)
	movec	tc,d0
	move.l	d0,-(sp)
	movec	cacr,d0
	move.l	d0,-(sp)
	movec	dtt1,d0
	move.l	d0,-(sp)
	movec	dtt0,d0
	move.l	d0,-(sp)
	movec	itt1,d0
	move.l	d0,-(sp)
	movec	itt0,d0
	move.l	d0,-(sp)
	cpusha	bc			make sure the above are stored
	cinva	bc
	move.l	(_itt0,pc),d0
	movec	d0,itt0
	move.l	(_itt1,pc),d0
	movec	d0,itt1
	move.l	(_dtt0,pc),d0
	movec	d0,dtt0
	move.l	(_dtt1,pc),d0
	movec	d0,dtt1
	move.l	(_cacr,pc),d0
	movec	d0,cacr
	
	moveq	#1,d0
	movec	d0,dfc
	move.l	(_tc,pc),d0
	pflusha
	movec	d0,tc
	move.l	(_dfc,pc),d0
	cpusha	bc
	cinva	bc
	movec	d0,dfc
	move.l	(7*4,sp),d0
	jsr	(a0)
	cpusha	bc
	cinva	bc
	move.l	d0,(6*4,sp)
	move.l	(sp)+,d0
	movec	d0,itt0
	move.l	(sp)+,d0
	movec	d0,itt1
	move.l	(sp)+,d0
	movec	d0,dtt0
	move.l	(sp)+,d0
	movec	d0,dtt1
	move.l	(sp)+,d0
	movec	d0,cacr
	moveq	#1,d0
	movec	d0,dfc
	move.l	(sp)+,d0
	pflusha
	movec	d0,tc
	move.l	(sp)+,d0
	cpusha	bc
	cinva	bc
	movec	d0,dfc
	move.l	(sp)+,d0
	rts


;  IN: a5 = memheader
;      a6 = execbase
FoundMem	move.l	a5,a0			for Allocate_REVERSE
	lea	(_memhead,pc),a1
	moveq	#MH_FIRST,d0
	call	CopyMem
	lea	(_MemHeaderFlag,pc),a0
	st	(a0)
	rts



; TestHardware - test & query remap hardware
TestHardware	movem.l	d1-a6,-(sp)
	moveq	#0,d7			default: no supported hardware found
	move.l	(_ExecBase,pc),a6

	bsr	.testblizzppc
	bne	.exit_np

	lea	(.ExpName,pc),a1
	moveq	#33,d0
	bsr	OpenLib
	beq	.exit_np
	move.l	d0,a6

	lea	(.boards,pc),a2
	moveq	#0,d2
	moveq	#0,d6			clear maprom address lower...
.bfloop	moveq	#0,d0
	moveq	#0,d1
	move.w	(a2)+,d0		manufacturer
	bmi.b	.bfnomatch
	move.w	(a2)+,d1		product
	move.w	(a2)+,d6		maprom address, upper word
	move.l	(a2)+,d3		lower <<16 | upper ram area or -1
	sub.l	a0,a0
	call	FindConfigDev
	move.l	d0,d2
	beq.b	.bfloop
.bfnomatch	move.l	a6,a1
	move.l	(_ExecBase,pc),a6
	call	CloseLibrary
	tst.l	d2
	beq.b	.exit_np
	swap	d6			maprom address in d6
	move.l	d2,a0

	moveq	#0,d0
	move.b	(cd_Rom+er_Product,a0),d0

	cmp.w	#BLIZPROD,(cd_Rom+er_Manufacturer,a0)
	bne.b	.notbliz

	lea	(_MK2,pc),a0
	cmp.w	#$19,d0
	seq	(a0)
	lea	(_B20x0,pc),a0
	cmp.w	#$18,d0
	seq	(a0)
	lea	(_CSPPC_MK3,pc),a0
	cmp.w	#$64,d0
	seq	(a0)
.notbliz
	cmp.w	#UAEPROD,(cd_Rom+er_Manufacturer,a0)
	bne.b	.notuae
	lea	(_UAE_Z3,pc),a0
	cmp.w	#3,d0
	seq	(a0)
.notuae

	move.l	d3,d0			lower & upper ram area for .csfindmemscan
	lea	(.blizfindmem,pc),a0
	addq.l	#1,d0
	beq.b	.skip			-1 it's blizzard!
	lea	(.csfindmem,pc),a0
.skip	call	Forbid
	lea	(MemList,a6),a5
	lea	(LH_TAIL,a5),a4
	jmp	(a0)

.exitsp
	move.l	d7,d0
.exit_known	call	Permit
.exit_np	tst.l	d0
	bne.b	.foundvalid
	lea	(_MemHeaderFlag,pc),a0
	clr.b	(a0)
.foundvalid	movem.l	(sp)+,d1-a6
	rts



;  IN: a6 = execbase
; OUT: d0 = status
.testblizzppc	btst	#AFB_68040,(_AttnFlags+1,pc)	; blizzppc card has at least 040 CPU
	beq	.pexit2

	lea	(.pidtag,pc),a1			; try to find the resident romtag
	call	FindResident
	tst.l	d0				; if we found it, be happy
	bne.b	.foundit

	lea	(.nastyfind,pc),a0		; if not, try find it the hw banging
	bsr	runnommu			; way...
	beq	.pexit2

.foundit	call	Forbid

	lea	(MemList,a6),a5			; find the blizzppc memory node
	lea	(LH_TAIL,a5),a4
.pscanloop	move.l	(a5),a5
	cmp.l	a5,a4
	beq	.pexit
;;flashfix	move.w	#MEMF_POOLMEM!MEMF_PUBLIC!MEMF_CHIP!MEMF_FAST!MEMF_LOCAL!MEMF_24BITDMA,d0
	move.w	#MEMF_POOLMEM!MEMF_PUBLIC!MEMF_CHIP!MEMF_FAST!MEMF_24BITDMA,d0
	and.w	(MH_ATTRIBUTES,a5),d0
	cmp.w	#MEMF_FAST!MEMF_PUBLIC,d0
	bne.b	.pscanloop
;;	tst.l	(LN_NAME,a5)
;;	bne.b	.pscanloop
	cmp.l	#$40000000,(MH_LOWER,a5)
	blo.b	.pscanloop
	move.l	(MH_UPPER,a5),d0
	cmp.l	#$80000000,d0
	bhs.b	.pscanloop
	and.l	#$0007FFFF,d0
	beq.b	.pfoundit

.pexit	call	Permit
.pexit2	moveq	#0,d0
	rts

.pfoundit	bsr	FoundMem

	call	Permit

	lea	(_BlizPPC,pc),a0
	st	(a0)

	move.l	#$FFF00000,d0
	rts


.nastyfind	lea	$F00020,a0		BlizzPPC flash is located here...
	move.l	#4000,d0		Must use .l!
	movem.l	(.pidtag,pc),d1-d4

.nf_find	cmp.l	(a0),d1
	bne.b	.nf_more
	cmp.l	(4,a0),d2
	bne.b	.nf_more
	cmp.l	(8,a0),d3
	bne.b	.nf_more
	cmp.l	(12,a0),d4
	bne.b	.nf_more

	moveq	#1,d0
	rts

.nf_more	addq.l	#1,a0
	subq.l	#1,d0
	bne.b	.nf_find
	rts

.pidtag	dc.b	'BlizzardPPC.IDTag',0
	CNOP	0,2



.blizfindmem
.trymore	sub.l	a3,a3
.scanloop	move.l	(a5),a5
	cmp.l	a5,a4
	beq	.exitsp
	moveq	#MEMF_POOLMEM!MEMF_CHIP!MEMF_FAST!MEMF_PUBLIC,d0	Public fast?
	and.w	(MH_ATTRIBUTES,a5),d0
	cmp.w	#MEMF_FAST!MEMF_PUBLIC,d0
	bne.b	.scanloop
	cmp.l	#$01000000,(MH_LOWER,a5)	32bit?
	blo.b	.scanloop
;;	move.l	(LN_NAME,a5),d0
;;	beq.b	.found
;;	move.l	d0,a2
;;	move.l	(a2),d0
;;	or.l	#$20202020,d0		To lowercase
;;	cmp.l	#'bliz',d0
;;	beq.b	.found
;;	tst.b	(a2)			null name -> buggy AllocMem result test!
;;	bne.b	.scanloop
;;.found
	bsr	FoundMem

	move.l	(MH_UPPER,a5),a3

	move.l	a3,d0			Test for MapROM:
	beq.b	.exit
	and.l	#$0007FFFF,d0
	bne.b	.exit
	move.l	a3,d0
	and.l	#$00080000,d0
	beq.b	.exit

	move.l	d6,d0			"known"?
	bne	.exit_known

	move.l	a3,a2
	add.l	#$80000-4,a2
	lea	$00F80000+$80000-4,a1

	lea	(.testcode,pc),a0
	bsr	runnommu
	beq.b	.exit
	move.l	a3,d7
.exit	tst.l	d7
	beq	.trymore
	bra	.exitsp


.is_mk2	move.l	#$08000000,d1
	move.l	#$10000000,d2
.mk2scanloop	move.l	(a5),a5
	cmp.l	a5,a4
	beq	.exitsp
	moveq	#MEMF_POOLMEM!MEMF_CHIP!MEMF_FAST!MEMF_PUBLIC,d0	Public fast?
	and.w	(MH_ATTRIBUTES,a5),d0
	cmp.w	#MEMF_FAST!MEMF_PUBLIC,d0
	bne.b	.mk2scanloop
	cmp.l	(MH_LOWER,a5),d1
	bhi.b	.mk2scanloop		bug: was blo!
	cmp.l	(MH_UPPER,a5),d2
	blo.b	.mk2scanloop

	bsr	FoundMem

	move.l	(MH_UPPER,a5),d0
	move.l	#$80000,d1
	move.l	d0,d2
	and.l	d1,d2
	bne.b	.mk2skip
	sub.l	d1,d0
.mk2skip	move.l	d0,d7
	bra	.exitsp


.is_UAE
	sub.l	a3,a3
.uaescanloop	move.l	(a5),a5
	cmp.l	a5,a4
	beq	.exitsp
	moveq	#MEMF_POOLMEM!MEMF_CHIP!MEMF_FAST!MEMF_PUBLIC,d0	Public fast?
	and.w	(MH_ATTRIBUTES,a5),d0
	cmp.w	#MEMF_FAST!MEMF_PUBLIC,d0
	bne.b	.uaescanloop
	move.l	d3,d0
	swap	d0			; get lower limit
	cmp.w	(MH_LOWER,a5),d0
	bhi.b	.uaescanloop
	cmp.w	(MH_UPPER,a5),d3	; compare upper limit
	blo.b	.uaescanloop

	bsr	FoundMem

	tst.l	$f0ff60			; sanity
	beq	.exitsp

	pea	(80).w			; call uaelib func 80
	jsr	$f0ff60
	addq.l	#4,sp
	tst.l	d0
	beq	.exitsp			; old uae, func 80 not supported
	addq.l	#1,d0
	beq	.exitsp			; -1 -> maprom not enabled

	subq.l	#1,d0			; restore maprom addr

	; see if mapping is working

	lea	$f80000,a1
	move.l	d0,a0

	call	Disable

	move.l	(a1),d1
	cmp.l	(a0),d1
	sne	d2
	not.l	d1
	move.l	d1,(a0)
	cmp.l	(a1),d1
	sne	d3
	not.l	d1
	move.l	d1,(a0)

	call	Enable

	tst.b	d2
	bne	.exitsp
	tst.b	d3
	bne	.exitsp

	; mapping works!

	move.l	d0,d7			; d7 = maprom address
	bra	.exitsp


.csfindmem	move.b	(_UAE_Z3,pc),d0
	bne	.is_UAE

	move.b	(_MK2,pc),d0
	bne	.is_mk2

.cstrymore	sub.l	a3,a3
.csscanloop	move.l	(a5),a5
	cmp.l	a5,a4
	beq	.exitsp
	moveq	#MEMF_POOLMEM!MEMF_CHIP!MEMF_FAST!MEMF_PUBLIC,d0	Public fast?
	and.w	(MH_ATTRIBUTES,a5),d0
	cmp.w	#MEMF_FAST!MEMF_PUBLIC,d0
	bne.b	.csscanloop
	move.l	d3,d0
	swap	d0			; get lower limit
	cmp.w	(MH_LOWER,a5),d0
	bhi.b	.csscanloop
	cmp.w	(MH_UPPER,a5),d3	; compare upper limit
	blo.b	.csscanloop

	bsr	FoundMem

	move.l	(MH_UPPER,a5),a3

	move.l	a3,d0			Test for MapROM:
	beq.b	.csexit
	and.l	#$0007FFFF,d0
	bne.b	.csexit

	move.l	d6,d0			"known"?
	bne	.exit_known

	move.b	(_B20x0,pc),d0
	beq.b	.no20x0a
	cmp.w	#$0800,(MH_LOWER,a5)	Test for $08000000 mem.
	bne.b	.csexit
.no20x0a
	move.l	a3,d7

.csexit	tst.l	d7
	beq	.cstrymore
	bra	.exitsp


; a1=ROM, a2=RAM
.testcode	or.w	#$700,sr		Disable interrupts

	move.l	(a2),d1
	cmp.l	(a1),d1
	bne.b	.exite
	not.l	d1
	move.l	d1,(a2)
	bsr	CacheClrS
	cmp.l	(a1),d1
	sne	d0
	not.l	d1			Restore before testing!
	move.l	d1,(a2)			(this was bugged)
	bsr	CacheClrS
	tst.b	d0
	bne.b	.exite
	cmp.l	(a1),d1
	bne.b	.exite
	moveq	#1,d0
	rts
.exite	moveq	#0,d0
	rts





BITEM	MACRO
	dc.w	\2,\3,\1
	dc.l	\4
	ENDM

.boards	BITEM $0000,UAEPROD,$03,$10005000	   UAE Z3 fastram, upto 1GB
	BITEM $0000,BLIZPROD,$18,$08001000	18 2040-ERC/2060
	;BITEM $0000,BLIZPROD,$0C,$08002000	0C Cyberstorm MKI
	BITEM $0000,BLIZPROD,$19,0		19 Cyberstorm MKII
	BITEM $FFF0,BLIZPROD,$64,$08002000	64 Cyberstorm MKIII / PPC
	BITEM $4FF8,BLIZPROD,$11,-1		11 1230-IV / 1260 / 1240-T/ERC
	BITEM $1EF8,BLIZPROD,$0D,-1		0D 1230-III
	BITEM $0FF8,BLIZPROD,$0B,-1		0B 1230-II
;;	BITEM $????,BLIZPROD,$??,-1		0? 1230-I
	dc.w	-1


.ExpName	dc.b	'expansion.library',0
	CNOP	0,2



; FindMemHeader - find memheader even if it has moved by PoolMem
; MUST call this in Forbid()! Use returned memheader before Permit()!
;
;  IN: a0=clone of MH (up to MH_FIRST) to find
;      a6=execbase
; OUT: a0=memheader or NULL, Z flag set
;
FindMemHeader	movem.l	d0-d3/a1,-(sp)
	moveq	#0,d0

	move.w	(MH_ATTRIBUTES,a0),d1
	move.w	(LN_TYPE,a0),d2
	move.l	(LN_NAME,a0),d3

	lea	(MemList,a6),a0
	lea	(LH_TAIL,a0),a1
.find	move.l	(a0),a0
	cmp.l	a0,a1
	beq.b	.fail
	cmp.w	(MH_ATTRIBUTES,a0),d1
	bne.b	.find
	cmp.w	(LN_TYPE,a0),d2		type & pri
	bne.b	.find
	cmp.l	(LN_NAME,a0),d3
	bne.b	.find

.exit	move.l	a0,d0
	movem.l	(sp)+,d0-d3/a1
	rts

.fail	sub.l	a0,a0
	bra.b	.exit



;  IN: a0=rom, d0=rom len
; OUT: d0=success, fail if no AGA or WaitBlit func couln't be found
PutHogWaitBlit	movem.l	d1-a6,-(sp)
	moveq	#0,d7

	cmp.w	#39,($C,a0)		Requires rom 39+
	blo.b	.exit

	lea	-4(a0,d0.l),a1

	move.w	$DFF004,d0		Test AGA:
	and.w	#$7F00,d0
	lsr.w	#8,d0
	bclr	#4,d0
	cmp.b	#$22,d0
	beq.b	.aga
	cmp.b	#$23,d0
	bne.b	.exit
.aga
	move.l	#$08390006,d0
.find	addq.l	#2,a0
	cmp.l	a1,a0
	beq.b	.exit
	cmp.l	(a0),d0
	bne.b	.find
	cmp.l	#$00DFF002,(4,a0)
	bne.b	.find
	cmp.l	#$66024E75,(8,a0)
	bne.b	.find

	cmp.l	#$08390006,(-8,a0)	No KS 1.x!
	beq.b	.exit
	cmp.l	#$4A3900DF,(-6,a0)	KS 2.x/3.x:
	bne.b	.exit
	subq.l	#6,a0
	lea	(.waitblit,pc),a1
	moveq	#(.waitblitend-.waitblit)/2,d0
.copy	move.w	(a1)+,(a0)+
	subq.l	#1,d0
	bne.b	.copy
	moveq	#1,d7

.exit	move.l	d7,d0
	movem.l	(sp)+,d1-a6
	rts

	; 1.x  36 bytes
	; 2.05 40 bytes
	; 3.0  48 bytes
	; 3.1  48 bytes
.waitblit	btst	#DMAB_BLTDONE-8,$DFF000+dmaconr			8
	bne.b	.gowait						2
	rts							2
.gowait	move.l	a0,-(sp)					2
	lea	($DFF000+dmaconr),a0				6
	move.w	#DMAF_SETCLR!DMAF_BLITHOG,(dmacon-dmaconr,a0)	6
.wait	btst	#DMAB_BLTDONE-8,(a0)				4
	bne.b	.wait						2
	move.w	#DMAF_BLITHOG,(dmacon-dmaconr,a0)		6
	move.l	(sp)+,a0					2
	rts							2 =42
	IFGT	0
.gowait	move.w	#DMAF_SETCLR!DMAF_BLITHOG,$DFF000+dmacon	8
.wait	btst	#DMAB_BLTDONE-8,$DFF000+dmaconr	8
	bne.b	.wait				2
	move.w	#DMAF_BLITHOG,$DFF000+dmacon	8
	rts					2 =40
	ENDC
.waitblitend
	IFGT	(.waitblitend-.waitblit)-42
	FAIL	!! WAITBLIT routine too long !!
	ENDC



;  IN: a0=rom start (buf)
;      d0=rom len
;      a1=name
; OUT: d0=ptr to resident (buf) or NULL
FindResident	movem.l	d1-a6,-(sp)
	move.l	a1,a3

	move.l	d0,d4
	move.l	a0,a4

	moveq	#1,d6
	lea	(_erh_arealen,pc),a0
	move.l	(a0)+,d0
	beq.b	.try_rom

	move.l	(a0),a0
	sub.l	a5,a5			Difference=0

.findres	moveq	#RT_SIZE-2,d1
	sub.l	d1,d0
	move.w	#RTC_MATCHWORD,d1
.find	subq.l	#2,d0
	bls.b	.try_rom
	cmp.w	(a0)+,d1
	bne.b	.find
	moveq	#2,d2
	add.l	(a0),d2			(RT_MATCHTAG-2,a0),d2
	add.l	a5,d2
	cmp.l	a0,d2
	bne.b	.find
	move.l	(RT_NAME-2,a0),a1
	add.l	a5,a1
	move.l	a3,a2
.compare	cmpm.b	(a2)+,(a1)+
	bne.b	.find
	tst.b	(-1,a2)
	bne.b	.compare

	move.l	a0,d0
	subq.l	#2,d0

.exit	movem.l	(sp)+,d1-a6
	rts

.exit_nf	moveq	#0,d0
	bra.b	.exit

.try_rom	tst.l	d6
	beq.b	.exit_nf

	move.l	d4,d0
	move.l	a4,a0

	move.l	#$01000000,d1
	sub.l	d0,d1			d2=rom start (rom)
	move.l	a0,a5
	sub.l	d1,a5			a5=difference

	moveq	#0,d6
	bra.b	.findres


PATHBUF_SIZE	EQU	256

;  IN: a0=ptr to rom (buf), d0=rom len, a3=array  (d6=dosbase)
; OUT: d0=success, will print doserror if failed
DoPlanting	movem.l	d1-a6,-(sp)
	lea	(-PATHBUF_SIZE,sp),sp
	move.l	sp,a5
	move.l	d6,a6

	move.l	d0,d1
	move.l	(ARG_MODULE,a3),d0
	beq	.exit			OK! ;-)
	move.l	d0,a2

	IFND	HAVE_NEW_ENV_METHOD
	moveq	#0,d3
	ENDC
	moveq	#0,d4			null!
	cmp.w	#37,(LIB_VERSION,a6)
	blo	.not20

	tst.l	(ARG_IGNPATH,a3)
	bne	.ignorepath

	IFD	HAVE_NEW_ENV_METHOD

	movem.l	d1-d3/a0,-(sp)
	sub.l	a1,a1
	move.l	(_ExecBase,pc),a6
	call	FindTask
	move.l	d6,a6
	move.l	d0,a0
	lea	(pr_WindowPtr,a0),a0
	move.l	(a0),-(sp)
	move.l	a0,-(sp)
	moveq	#-1,d0
	move.l	d0,(a0)

	lea	(_VarName,pc),a0
	move.l	a0,d1
	move.l	a5,d2
	move.l	#PATHBUF_SIZE,d3	d4=0
	call	GetVar
	addq.l	#1,d0
	bne.b	.gotvar
	lea	(_VarEnvArcName,pc),a0
	move.l	a0,d1
	call	GetVar
	addq.l	#1,d0
	bne.b	.gotvar

	lea	(_VarEnvArcName,pc),a0
	move.l	a0,d1
	move.l	#MODE_OLDFILE,d2
	call	Open
	move.l	d0,d4			d4=0 if failed, no dirlock
	beq.b	.novar
	move.l	d4,d1
	move.l	a5,d2
	subq.l	#1,d3			#PATHBUF_SIZE-1
	call	Read
	move.l	d0,d2
	move.l	d4,d1
	call	Close
	tst.l	d2
	bmi.b	.novar
	clr.b	0(a5,d2.l)		null terminate
	move.l	a5,a0			strip linefeeds
.filt_loop	move.b	(a0)+,d0
	beq.b	.filt_end
	cmp.b	#10,d0
	bne.b	.filt_loop
	clr.b	-(a0)
.filt_end
	IFNE	HAVE_DEFBKMODPATH
	bra.b	.gotvar
.novar	lea	(_DefaultBKMODPATH,pc),a0
	move.l	a5,a1
.def_cpy	move.b	(a0)+,(a1)+
	bne.b	.def_cpy
	ENDC
.gotvar

	move.l	a5,d1
	bsr	_lockread
	beq.b	.nolock
	move.l	d1,d4
	call	CurrentDir
	move.l	d0,d7			oldlock
.nolock
	IFEQ	HAVE_DEFBKMODPATH
.novar
	ENDC

	move.l	(sp)+,a0
	move.l	(sp)+,(a0)

	movem.l	(sp)+,d1-d3/a0
.ignorepath
.not20

	ELSE

	movem.l	d1-d2/a0,-(sp)
	sub.l	a1,a1
	move.l	(_ExecBase,pc),a6
	call	FindTask
	move.l	d6,a6
	move.l	d0,a0
	lea	(pr_WindowPtr,a0),a0
	move.l	(a0),-(sp)
	move.l	a0,-(sp)
	moveq	#-1,d0
	move.l	d0,(a0)

	lea	(_EnvName,pc),a0
	move.b	#':',(3,a0)
	move.l	a0,d1
	bsr	_lockread
	move.l	d0,d2
	call	UnLock
	move.l	(sp)+,a0
	move.l	(sp)+,(a0)
	tst.l	d2
	bne.b	.has_env

	lea	(_EnvArcName,pc),a0
	move.l	a0,d1
	bsr	_lockread
	beq.b	.no_envarclock
	move.l	d0,d2
	lea	(_EnvName,pc),a0
	clr.b	(3,a0)
	move.l	a0,d1
	call	AssignLock
	move.l	d0,d3			d3=assignstate
	bne.b	.got_assign
	move.l	d2,d1
	call	UnLock
.got_assign
.no_envarclock
.has_env
	lea	(_VarName,pc),a0
	move.l	a0,d1
	move.l	a5,d2
	move.l	d3,-(sp)
	move.l	#PATHBUF_SIZE,d3	d4=0
	call	GetVar
	move.l	(sp)+,d3
	addq.l	#1,d0
	beq.b	.novar
	move.l	a5,d1
	bsr	_lockread
	beq.b	.nolock
	move.l	d0,d4
	move.l	d4,d1
	call	CurrentDir
	move.l	d0,d7			oldlock
.nolock
.novar	movem.l	(sp)+,d1-d2/a0
.not20
	ENDC

.loop	move.l	(a2)+,d0
	beq.b	.exit2
	move.l	d0,a1
	move.l	d1,d0
	bsr.b	FilePlant
	bne.b	.loop
	bsr	_PrintFault		IN: d5=kickflag, d6=dosbase
	lea	(PlantError,pc),a0
	move.l	a2,a1
	subq.l	#4,a1
	bsr	_Printf
	moveq	#-1,d0

.exit2	tst.l	d4
	beq.b	.nodirlock
	move.l	d0,-(sp)
	move.l	d7,d1
	call	CurrentDir
	move.l	d4,d1
	call	UnLock
	move.l	(sp)+,d0
.nodirlock
	IFND	HAVE_NEW_ENV_METHOD

	tst.l	d3
	beq.b	.noassign
	move.l	d0,d7
	lea	(_EnvName,pc),a0
	clr.b	(3,a0)
	move.l	a0,d1
	moveq	#0,d2
	call	AssignLock
	move.l	d7,d0
.noassign
	ENDC

.exit	not.l	d0
	lea	(PATHBUF_SIZE,sp),sp
	movem.l	(sp)+,d1-a6
	rts

_lockread	moveq	#ACCESS_READ,d2
	call	Lock
	move.l	d0,d1
	rts

;  IN: a1=ptr to filename, a0=ptr to rom (buf), d0=rom len  (d6=dosbase)
; OUT: d0=success
FilePlant	movem.l	d1-a6,-(sp)
	move.l	d6,a6
	moveq	#0,d7

	move.l	d0,d4
	move.l	a0,a4

	; this is a elfloadseg-patch ioerr bug
	; workaround:

	move.l	a1,a2
	move.l	a1,d1
	moveq	#ACCESS_READ,d2
	call	Lock
	move.l	d0,d1
	beq	.exit
	call	UnLock

	move.l	a2,d1
	call	LoadSeg
	move.l	d0,d5
	beq	.exit

	move.l	d5,a1
	add.l	a1,a1
	addq.l	#2,a1			;-)
	add.l	a1,a1
	move.l	d4,d0
	move.l	a4,a0
	bsr	InstallModule
	move.l	d0,d7
	bne.b	.was_module

	; try direct executable planting

	cmp.l	#BKMODULE_ID,(a1)	was it a module that failed?
	beq.b	.was_module		yes, quit!

	; the test above is really needed or else horrors
	; would happen. namely installing non-functional
	; resident tag that would crash system.

	move.l	(8*4,sp),d1		filename from stack
	move.l	#MODE_OLDFILE,d2
	call	Open
	move.l	d0,d4
	beq.b	.exit

	lea	(.af_dosbase,pc),a0
	move.l	a6,(a0)

	pea	(.freefunc,pc)
	pea	(.allocfunc,pc)
	pea	(.readfunc,pc)
	move.l	sp,a1
	clr.l	-(sp)
	move.l	sp,a2
	sub.l	a0,a0
	;move.l	d4,d0			d0=filehandle!!
	call	InternalLoadSeg
	lea	(4*4,sp),sp
	move.l	d0,d7

	move.l	d4,d1
	call	Close

	; If we could load seglist, check for coldstart magic
	move.l	d7,d0
	beq.b	.nohack45
	lsl.l	#2,d0
	addq.l	#4,d0
	move.l	d0,a0
	cmp.l	#$11144EF9,(a0)		coldstart magic?
	bne.b	.nohack45
	cmp.l	#$0000FFFF,(8,a0)
	bne.b	.nohack45

	; Update ptr to coldstart magic
	lea	(_coldstart,pc),a1
	move.l	a0,(a1)
.nohack45

.was_module	move.l	d5,d1
	beq.b	.exit
	call	UnLoadSeg

.exit	move.l	d7,d0
	movem.l	(sp)+,d1-a6
	rts



;  IN: d0=size, d1=flags
; OUT: d0=memory
.allocfunc	tst.l	d0
	bne.b	.af_do

.af_fail	move.l	a6,-(sp)
	move.l	(.af_dosbase,pc),a6
	moveq	#ERROR_NO_FREE_STORE,d1
	call	SetIoErr
	move.l	(sp)+,a6
	moveq	#0,d0
	rts

.af_do	btst	#MEMB_CHIP,d1		don't allow chipmem
	bne.b	.af_fail

	movem.l	d0/d1,-(sp)
	move.l	(_erh_memheader,pc),d0
	beq.b	.af_exit
	move.l	d0,a0
	move.l	(sp),d0
	call	Allocate
	tst.l	d0
	beq.b	.af_nomem
	; d0=return val

	; should clear allocated area?
	btst	#MEMB_CLEAR-16,(1,sp)
	beq.b	.af_exit

	; get original alloc req and align it
	move.l	(sp),d1
	addq.l	#MEM_BLOCKMASK,d1
	and.w	#-MEM_BLOCKSIZE,d1

	move.l	d0,a0
.af_clear	clr.l	(a0)+
	clr.l	(a0)+
	subq.l	#8,d1
	bne.b	.af_clear

.af_exit	addq.l	#8,sp
	rts

.af_nomem	addq.l	#8,sp
	bra.b	.af_fail

.af_dosbase	ds.l	1


;  IN: a1=memory d0=size
; OUT: -
.freefunc	tst.l	d0
	bne.b	.ff_do
.ff_no	rts
.ff_do	move.l	a1,d1
	beq.b	.ff_no

	move.l	(_erh_memheader,pc),d1
	beq.b	.ff_no

	movem.l	d0/a1,-(sp)
	move.l	a1,d1
	and.w	#-MEM_BLOCKSIZE,d1
	exg	d1,a1
	addq.l	#MEM_BLOCKMASK,d0
	sub.l	a1,d1
	add.l	d1,d0
	moveq	#-1,d1
	and.l	#-MEM_BLOCKSIZE,d0	note: .l!!
	beq.b	.ff_nofill
.ff_fill	move.l	d1,(a1)+
	move.l	d1,(a1)+
	subq.l	#8,d0
	bne.b	.ff_fill
.ff_nofill	movem.l	(sp)+,d0/a1

	move.l	(_erh_memheader,pc),a0
	jmp	(_LVODeallocate,a6)

;  IN: d1=fh, d2=buffer, d3=len
; OUT: d0=actual
.readfunc	jmp	(_LVORead,a6)



;  IN: d1.l=error (d6=dosbase)
SetIoErr	movem.l	d0-d1/a0-a1/a6,-(sp)
	move.l	d6,a6
	cmp.w	#36,(LIB_VERSION,a6)
	blo.b	.old
	call	SetIoErr
	bra.b	.exit
.old	move.l	(_ExecBase,pc),a6
	sub.l	a1,a1
	call	FindTask
	move.l	d0,a0
	move.l	(4,sp),(pr_Result2,a0)
.exit	movem.l	(sp)+,d0-d1/a0-a1/a6
	rts


;  IN: a1=ptr to module, a0=ptr to rom (buf), d0=rom len  (d6=dosbase)
; OUT: d0=success, d1/a0/a1 preserved
InstallModule	movem.l	d1-a6,-(sp)
	moveq	#0,d7
	move.l	#ERROR_OBJECT_WRONG_TYPE,d1
	bsr.b	SetIoErr

	move.l	#$01000000,d2
	sub.l	d0,d2
	move.l	a0,a5
	sub.l	d2,a5			a5=difference

	cmp.l	#BKMODULE_ID,(a1)+	(bkm_ID)
	bne.b	.exit
	move.w	(a1)+,d4		d4=bkm_Flags, a1=bkm_ResTag
	move.w	d4,d1
	and.w	#~BKMF_ALL,d1		Test validity:
	bne.b	.exit
	cmp.w	#BKEP_ID,(a1)		Test for patch module:
	beq	.is_epatch
	cmp.l	#RTC_MATCHWORD<<16,(a1)
	bne.b	.exit

	move.l	#ERROR_OBJECT_TOO_LARGE,d1
	bsr.b	SetIoErr

	lea	(.replace_test,pc),a3
	lsr.w	#1,d4			btst	#BKMB_ReplaceMode,d4
	bcs.b	.replace
	lea	(.single_test,pc),a3
	lsr.w	#1,d4			btst	#BKMB_SingleMode,d4
	bcc.b	.no_findresident
.replace	movem.l	d0/a1,-(sp)
	add.l	(RT_NAME,a1),a1
	bsr	FindResident
	move.l	d0,a2
	movem.l	(sp)+,d0/a1
	jmp	(a3)
.no_findresident
.is_single
.is_erbf	move.l	(RT_ENDSKIP,a1),d1
	lsr.w	#1,d4			btst	#BKMB_ExtResBuf,d4
	bcc.b	.no_extresbuf1
	neg.l	d1
.no_extresbuf1	bsr	FindSpace
	beq.b	.exit

.go_replace	move.l	d0,a3			a3=ptr to func (buf)
	move.l	d1,a2			a2=ptr to func (ROM)

	move.w	($C,a0),d1		d1=rom version
	move.l	a1,a0
	lea	(RT_VERSION,a0),a4
	cmp.b	(a4),d1			Test version!
	blo.b	.nofail
	move.b	d1,(a4)			Force current version!
	cmp.w	#36,d1
	shs	d1
	move.l	a3,a1			a2=ptr to func (ROM)
	bsr	PutResident

.nofail	moveq	#1,d7
.exit	move.l	d7,d0
.exit2	bsr	CacheClearOS		Clear caches.
	movem.l	(sp)+,d1-a6
	rts


.replace_test	beq.b	.exit			If no match exit!
	move.b	(RT_PRI,a2),d1
	cmp.b	(RT_PRI,a1),d1
	bne.b	.exit			If no match exit!

	lsr.w	#1,d4
	btst	#0,d4			btst BKMB_ExtResBuf,d4
	bne.b	.is_erbf

	move.l	(RT_ENDSKIP,a2),d1	d1=ptr to ENDSKIP (ROM)
	add.l	a5,d1			d1=ptr to ENDSKIP (buf)
	sub.l	a2,d1
	cmp.l	(RT_ENDSKIP,a1),d1
	ble.b	.exit
	move.l	a2,d0
	move.l	d0,d1
	sub.l	a5,d1
	bra.b	.go_replace


.single_test	beq.b	.is_single		SINGLE: If no match continue!
	move.b	(RT_PRI,a2),d1
	cmp.b	(RT_PRI,a1),d1
	bne.b	.is_single		SINGLE: If no match continue!
	move.l	#ERROR_TOO_MANY_ARGS,d1
	bsr	SetIoErr
	bra.b	.exit

; a0=ptr to rom start (buf), a1=ptr to epatch, d0=rom len, d2=ptr to rom start (ROM)
.is_epatch	lea	(2,a1),a5
	move.l	d2,a1
	lea	(FindResident,pc),a2
	lea	(InstallModule,pc),a3
	lea	(_Printf,pc),a4
	move.l	(_ExecBase,pc),a6
	jsr	(a5)
	bra.b	.exit2


;  IN: a0=rom (buf), d0=rom len, d1=required space (negate if ExtResBuf required)
; OUT: d0=ptr to area (buf) or NULL, d1=ptr to area (rom)
;NOTE: condition codes set on return!
FindSpace	movem.l	d2-d3/d6-d7/a0-a2,-(sp)
	moveq	#0,d7

	move.l	#$01000000,d2
	sub.l	d0,d2
	move.l	a0,d6
	sub.l	d2,d6			d6=difference (buf-rom)

	tst.l	d1
	bmi.b	.required_extres

	lea	ROMSUMOFFS(a0,d0.l),a1
	bsr.b	.find
	bhs.b	.found			Big enough 'empty' space.

	move.l	#$00040000,d2
	cmp.l	d2,d0			Test for >$40000 ROM
	bls.b	.try_extres

	lea	(a0,d0.l),a1
	sub.l	d2,a1			a1=$FC0000
	move.l	(a1),d2
	and.l	#$FFF8FFFF,d2
	cmp.l	#$11104EF9,d2
	bne.b	.try_extres
	bsr.b	.find
	blo.b	.try_extres

.found	move.l	a1,d7
	addq.l	#1+3,d7
	and.w	#-4,d7

.exit	move.l	d7,d1
	sub.l	d6,d1
	move.l	d7,d0
	movem.l	(sp)+,d2-d3/d6-d7/a0-a2
	rts

.find	moveq	#-1,d2
.null	move.b	-(a1),d3
	addq.l	#1,d2
	not.b	d3
	beq.b	.null
	cmp.l	d1,d2
	rts

.required_extres
	neg.l	d1
.try_extres	move.l	(_erh_memheader,pc),d0
	beq.b	.exit
	move.l	d0,a0
	move.l	d1,d0
	move.l	a6,-(sp)
	move.l	(_ExecBase,pc),a6
	call	Allocate
	move.l	(sp)+,a6
	move.l	d0,d7
	moveq	#0,d6			NULL difference!
	bra.b	.exit


;  IN: a0=resident
;      a1=adr to "free" buf
;      a2=adr to "free" buf (rom)
;      d1.b=zero if <V36 ROM
PutResident	;bsr	CacheClearOS		336r: Added coz bad move16 optimized copymem patches?
	movem.l	d0-a6,-(sp)
	move.l	(_ExecBase,pc),a6
	lea	(RT_MATCHTAG,a1),a3
	lea	(4,a1),a4
	move.l	(RT_ENDSKIP,a0),d0
	call	CopyMem
	;bsr	CacheClearOS		336r: Added coz bad move16 optimized copymem patches?
	move.l	a2,d0
	move.l	d0,(a3)+		RT_MATCHTAG
	add.l	d0,(a3)+		RT_ENDSKIP
	tst.b	(4+3,sp)		V36+ ?
	bne.b	.no_incomp
	move.b	(a3),d1
	and.b	#~(RTF_AUTOINIT!RTW_COLDSTART),d1
	beq.b	.no_incomp
	and.b	#RTF_AUTOINIT!RTW_COLDSTART,(a3) Mask out incompatible bits
	or.b	#RTW_COLDSTART,(a3)
.no_incomp	move.b	(a3),d1
	addq.l	#RT_NAME-RT_FLAGS,a3
	add.l	d0,(a3)+		RT_NAME
	add.l	d0,(a3)+		RT_IDSTRING
	and.b	#RTF_AUTOINIT,d1
	beq.b	.noauto
	add.l	(a3),a4
	tst.l	(a4)+
	beq.b	.nop1
	add.l	d0,(-4,a4)
.nop1
	tst.l	(a4)+
	beq.b	.nop2
	add.l	d0,(-4,a4)
.nop2
	tst.l	(a4)+
	beq.b	.nop3
	add.l	d0,(-4,a4)
.nop3
.noauto	add.l	d0,(a3)+		RT_INIT
	movem.l	(sp)+,d0-a6
	rts


;  IN: a0=rom (buf), d0=rom len, d1=required buffer len, d2=sanity size
;      a6=execbase, d6=dosbase
; OUT: d0=ptr to extres buffer or NULL
ExtResBuf	movem.l	d0-a6,-(sp)
	moveq	#0,d7

	move.l	d0,d5			d5=rom len
	move.l	a0,a5			a0=buf strt

	move.l	#ERROR_OBJECT_WRONG_TYPE,d1
	bsr	SetIoErr

	cmp.w	#37,($C,a5)		need 37+
	blo	.exit

	move.b	(_MemHeaderFlag,pc),d0
	beq	.exit

	; find exec.library resident tag

	move.l	a5,a0
	move.l	d5,d0
	lea	(ExecName,pc),a1
	bsr	FindResident
	tst.l	d0
	beq	.exit

	move.l	d0,a3
	move.l	(RT_INIT,a3),d1

	;test if inside rom bounds?
	cmp.l	#$0f80000,d1
	blo	.exit
	cmp.l	#$1000000,d1
	bhs	.exit

	; generate ram buffer address
	sub.l	#$f80000,d1		-$f80000
	add.l	a5,d1			+buffer
	move.l	d1,a0

	moveq	#12,d4			skip 12 bytes
	cmp.l	#$41F900DF,(a0)		37.x
	beq.b	.use12
	moveq	#4,d4			skip 4 bytes
	cmp.w	#$41FA,(a0)		39.x/40.x [lea (x,pc),a0]
	bne	.exit
.use12
	add.l	(RT_INIT,a3),d4

	IFNE	HAVE_ERB_MMUALIGN
	move.l	#MAXMMUPAGESIZE+extreshandler_SIZEOF+ERHANDLER_SIZEOF+8+MH_SIZE+7,d0
	ELSE	;HAVE_ERB_MMUALIGN
	move.l	#extreshandler_SIZEOF+ERHANDLER_SIZEOF+8+MH_SIZE+7,d0
	ENDC	;HAVE_ERB_MMUALIGN
	add.l	(1*4,sp),d0		d1 from stack
	and.w	#-8,d0			align by 8

	; use this to set up MH_UPPER, MH_FREE,
	; MC_BYTES, ScanEnd...
	move.l	d0,d2
	IFNE	HAVE_ERB_MMUALIGN
	sub.l	#MAXMMUPAGESIZE+extreshandler_SIZEOF,d2
	ELSE	;HAVE_ERB_MMUALIGN
	sub.l	#extreshandler_SIZEOF,d2
	ENDC	;HAVE_ERB_MMUALIGN

	; len for allocabs
	move.l	d0,d3

	; add sanity just in case (something in boot could alloc
	; MEMF_REVERSE overwriting us...)
	;
	; If user sees 80010000 alert he/she should increase
	; SANITY

	add.l	#$90000,d0		add 576k... (internal sanity)
	add.l	(2*4,sp),d0		d2 from stack

	lea	(_erh_alloclen,pc),a0
	move.l	d0,(a0)

	call	Forbid
	lea	(_memhead,pc),a0
	bsr	FindMemHeader
	beq	.cantfind
	bsr	Allocate_REVERSE
	;call	Allocate
	call	Permit
	lea	(_erh_freeaddr,pc),a0
	move.l	d0,(a0)
	beq	.exit

	IFNE	HAVE_ERB_MMUALIGN
	add.l	#MAXMMUPAGESIZE-1,d0
	and.w	#-MAXMMUPAGESIZE,d0
	ENDC	;HAVE_ERB_MMUALIGN

	move.l	d0,a2
	move.l	d0,a1
	addq.l	#8,a2			jump over two longs

	lea	(extreshandler,pc),a0
	moveq	#extreshandler_SIZEOF,d0
	call	CopyMem

	lea	(extreshandler_SIZEOF-8,a2),a0
	move.l	a0,d0

	lea	(_erh_memheader,pc),a1
	move.l	a0,(a1)
	lea	(MH_SIZE,a0),a1
	clr.l	(a0)+			LN_SUCC
	clr.l	(a0)+			LN_PRED
	move.w	#NT_MEMORY<<8,(a0)+	LN_TYPE, LN_PRI
	clr.l	(a0)+			LN_NAME
	clr.w	(a0)+			MH_ATTRIBUTES
	move.l	a1,(a0)+		MH_FIRST
	move.l	a1,(a0)+		MH_LOWER
	add.l	d2,d0			d0 = a1 - (MH_SIZE+8) + size
	move.l	d0,(a0)+		MH_UPPER
	moveq	#-(MH_SIZE+8),d0
	add.l	d2,d0
	move.l	d0,(a0)+		MH_FREE
	move.l	a0,d7
	clr.l	(a0)+			MC_NEXT
	move.l	d0,(a0)+		MC_BYTES

	subq.l	#8,d0
	moveq	#-1,d1
.fill	move.l	d1,(a0)+
	move.l	d1,(a0)+
	subq.l	#8,d0
	bne.b	.fill


	move.l	a2,d0
	lea	(allocpt+2,pc),a0
	subq.l	#8,d0
	move.l	d0,(a0)
	lea	(alloclen+2,pc),a0
	move.l	d3,(a0)

	move.l	d7,(scanstartoffs-8,a2)
	lea	(_erh_areastart,pc),a0
	move.l	d7,(a0)
	moveq	#-(MH_SIZE+8),d0
	add.l	d2,d0
	lea	(_erh_arealen,pc),a0
	move.l	d0,(a0)
	add.l	d7,d0
	move.l	d0,(scanendoffs-8,a2)
	move.l	d4,(jumpoffs-8,a2)
	move.l	a2,(RT_INIT,a3)


	move.l	a5,a0			a0=ptr to rom (buf)
	move.l	d5,d0			d0=rom len
	lea	(_erhandler_module,pc),a1
	bsr	InstallModule
	tst.l	d0
	bne.b	.exit

	bsr	FreeExtResBuf
	moveq	#0,d7


.exit	move.l	d7,d0
	addq.l	#4,sp
	movem.l	(sp)+,d1-a6
	rts

.cantfind	call	Permit
	bra.b	.exit


	; IN: a6=execbase
extreshandler	dc.l	0,0			don't trust 8 bytes we AllocAbs

	lea	(.areas,pc),a0
	dc.w	$4ef9
jumpoffs	EQU	*-extreshandler
	dc.l	$badc0de


.areas	dc.l	$00F80000
	dc.l	$01000000
	dc.l	$00F00000
	dc.l	$00F80000
scanstartoffs	EQU	*-extreshandler
	dc.l	$15c0ded
scanendoffs	EQU	*-extreshandler
	dc.l	$badd1e
	dc.l	-1

extreshandler_SIZEOF	EQU	(*-extreshandler+7)&-8



;  IN: a0=rom (buf), d0=rom len
;      a1=ptr to rom coldstart header
;      a6=execbase, d6=dosbase
; OUT: d0=success
FixColdstartVer
	movem.l	d0-a6,-(sp)

	move.l	a0,a5
	move.l	d0,d5
	move.l	a1,a4

	movem.l	($C,a4),d0/d1		; d1 = exec ver.rev
	addq.l	#1,d0			; is version 65535.65535 ?
	bne.b	.nofix			; nope, don't fix

	move.l	d1,($C,a4)		; default: use exec ver & rev

	move.l	a5,a0
	move.l	d5,d0
	lea	(.romupdateName,pc),a1
	bsr	FindResident
	tst.l	d0
	beq.b	.noromupdate

	move.l	d0,a0
	move.l	(RT_IDSTRING,a0),a0	; should convert to ram buff address
.findrev	move.b	(a0)+,d0
	beq.b	.noromupdate
	cmp.b	#'.',d0
	bne.b	.findrev
	move.l	a0,d1
	clr.l	-(sp)
	move.l	sp,d2
	exg	d6,a6
	call	StrToLong
	exg	d6,a6
	move.l	(sp)+,d1
	tst.l	d0			; error?
	bmi.b	.noromupdate

	; d1 = revision, set it
	move.w	d1,($E,a4)
.noromupdate
.nofix
	movem.l	(sp)+,d0-a6
	rts

.romupdateName
	dc.b	'AmigaOS ROM Update',0
	CNOP	0,2


;  IN: a0=rom (buf), d0=rom len
;      a6=execbase, d6=dosbase
; OUT: d0=success
HackExec45	movem.l	d1-a6,-(sp)
	moveq	#0,d7

	move.l	d0,d5			d5=rom len
	move.l	a0,a5			a0=buf strt

	move.l	(_coldstart,pc),d0
	beq	.exit			need coldstart module

	move.l	(_erh_arealen,pc),d0
	beq	.exit			need extresbuf

	cmp.w	#37,($C,a5)		need 37+
	blo	.exit

	; find exec.library resident tag

	move.l	a5,a0
	move.l	d5,d0
	lea	(ExecName,pc),a1
	bsr	FindResident
	tst.l	d0
	beq	.exit

	move.l	d0,a3
	cmp.b	#45,(RT_VERSION,a3)	need exec v45
	bne	.exit

	; Ugly hack to find the original exec.library romtag

	addq.w	#1,(a3)			temporarily zap RT_MATCHWORD
	move.l	a5,a0
	move.l	d5,d0
	lea	(ExecName,pc),a1
	bsr	FindResident
	subq.w	#1,(a3)			restore RT_MATCHWORD
	tst.l	d0
	beq	.exit			need original exec romtag

	move.l	d0,a4			save ptr to later zapping

	;illegal

	move.l	(RT_INIT,a3),d1

	;test if inside rom bounds?
	cmp.l	#$0f80000,d1
	blo	.notrom1
	cmp.l	#$1000000,d1
	bhs	.notrom1

	; generate ram buffer address
	sub.l	#$f80000,d1		-$f80000
	add.l	a5,d1			+buffer
.notrom1
	move.l	d1,a0

	cmp.l	#$4E7548E7,(-2,a0)	is it LocalFast module? [rts / movem.l x,-(sp)]
	bne.b	.notlf

	; Okay this is the localfast patch. Locate the JMP (abs).l
	; instruction to find the real initcode start...
.crude_hack	cmp.w	#$4EF9,(a0)+
	bne.b	.crude_hack
	move.l	(a0),a0
.notlf

	cmp.w	#$207A,(a0)+		[movea.l (x,pc),a0]
	bne	.exit

	add.w	(a0),a0			a0 = (x,pc) EA address


	move.l	(a0),d1			; d1 = areas array ptr [ROM]

	;test if inside rom bounds?
	cmp.l	#$0f80000,d1
	blo.b	.notrom2
	cmp.l	#$1000000,d1
	bhs.b	.notrom2
	; generate ram buffer address
	sub.l	#$f80000,d1		-$f80000
	add.l	a5,d1			+buffer
.notrom2
	move.l	d1,a0
	; a0 = areas array ptr [buffer]
	;
	; The first area is the ROM area used by the romtag normally.
	; We replace this with our area map.

	move.l	#$00F80000,(a0)+
	move.l	#$01000000,(a0)+
	move.l	#$00F00000,(a0)+
	move.l	#$00F80000,(a0)+

	move.l	(_erh_areastart,pc),d0
	move.l	d0,(a0)+
	add.l	(_erh_arealen,pc),d0
	move.l	d0,(a0)+
	move.l	#-1,(a0)


	; Do the magic to fix the ROM colstart version & revision

	move.l	a5,a0
	move.l	d5,d0
	move.l	(_coldstart,pc),a1
	bsr	FixColdstartVer


	; Patch the ROM coldstart to jump to new coldstart
	; Also copies some ROM version info for the curious apps

	move.l	(_coldstart,pc),a0
	moveq	#(256>>1)-1,d1
.copy	cmp.w	#RTC_MATCHWORD,(a0)
	beq.b	.done
	move.w	(a0)+,(a5)+
	subq.l	#1,d1
	bpl.b	.copy
.done

	; Relocate important kicktag fields
	; (In theory should handle the case exec.library would get rommed,
	; but this can't happen currently)

	move.l	(RT_FLAGS,a3),(RT_FLAGS,a4)	; and RT_VERSION, RT_TYPE and RT_PRI
	move.l	(RT_NAME,a3),(RT_NAME,a4)
	move.l	(RT_IDSTRING,a3),(RT_IDSTRING,a4)
	move.l	(RT_INIT,a3),(RT_INIT,a4)

	; Kill the kicktag of the new exec.library
	move.w	#$4e71,(a3)

	; Success!
	moveq	#1,d7

.exit
	move.l	d7,d0
	movem.l	(sp)+,d1-a6
	rts



;  IN: a0 = memHeader
;      d0 = byteSize
;      a6 = execbase
; OUT: d0 = memoryBlock or null, z set/clr
Allocate_REVERSE
	jsr	(_LVOForbid,a6)
	move.l	(MH_FIRST,a0),d1
	beq.b	.fail

	sub.l	a1,a1			; default

	; find last MH that matches our requirements
.findfree_r	move.l	d1,a0
	cmp.l	(MC_BYTES,a0),d0
	bhi.b	.findskip_r
	move.l	a0,a1
.findskip_r	move.l	(a0),d1			; MC_NEXT
	bne.b	.findfree_r

	; found any?
	move.l	a1,d1
	beq.b	.fail

	; allocate from it!
	move.l	(MC_BYTES,a1),d1
	sub.l	d0,d1
	and.w	#-MEM_BLOCKSIZE,d1
	add.l	d1,a1
	jsr	(_LVOAllocAbs,a6)
	jsr	(_LVOPermit,a6)
	tst.l	d0
	rts

.fail	jsr	(_LVOPermit,a6)
	moveq	#0,d0
	rts



	STRUCTURE BKERHSS,0
	STRUCT	BKERH_ss,SS_SIZE
	ULONG	BKERH_version
	UWORD	BKERH_flags
	APTR	BKERH_memheader
	APTR	BKERH_mmustart
	ULONG	BKERH_mmulen
	LABEL	BKERH_SIZEOF

	BITDEF	BKERH,MMUPAGEALIGNED,0

_erhandler_module
 BK_MOD BKMF_SingleMode|BKMF_ExtResBuf,_erhandler_end,(RTF_COLDSTART)<<24!37<<16!NT_UNKNOWN<<8!104,_erh_name,_erh_name,_ERHandler
;
; IMPORTANT:
; priority is after `diag init' resident that adds memory to system
;

	; d0=0, a0=0, a6=execbase
_ERHandler	; reallocate EXTRESBUF
allocpt	lea	$deadc0de,a1
alloclen	move.l	#$cafecafe,d0
	call	AllocAbs
	tst.l	d0
	bne.b	.got

	; die horribe death
	move.l	#AT_DeadEnd!AG_NoMemory,d7
	call	Alert
.got

	; initialize EXTRES API...

	moveq	#BKERH_SIZEOF,d0
	moveq	#MEMF_ANY,d1
	call	AllocMem
	tst.l	d0
	beq.b	.nomem

	move.l	d0,-(sp)
	move.l	d0,a0
	call	InitSemaphore
	move.l	(sp)+,a1

	IFNE	HAVE_ERB_MMUALIGN

	move.l	#ERH_API_V2,(BKERH_version,a1)
	move.w	#BKERHF_MMUPAGEALIGNED,(BKERH_flags,a1)
	move.l	(allocpt+2,pc),(BKERH_mmustart,a1)
	move.l	(alloclen+2,pc),d0
	and.w	#-MAXMMUPAGESIZE,d0
	move.l	d0,(BKERH_mmulen,a1)

	ELSE	;HAVE_ERB_MMUALIGN

	move.l	#ERH_API_V1,(BKERH_version,a1)
	clr.w	(BKERH_flags,a1)
	clr.l	(BKERH_mmustart,a1)
	clr.l	(BKERH_mmulen,a1)

	ENDC	;HAVE_ERB_MMUALIGN

	; must not optimize this!
_erh_memheader	EQU	*+2
	move.l	#0,(BKERH_memheader,a1)

	lea	(_erh_name,pc),a0
	move.l	a0,(LN_NAME,a1)
	move.b	#-120,(LN_PRI,a1)

	call	AddSemaphore
.nomem
	; fall thru!

	;bsr.b	MoveChipHeader
	;rts

; Routines taken from FastExec 2.5 public domain source code by
; Torbjörn A. Andersson. Modified by Harry Sintonen.
******************************************************************************

MoveChipHeader	movem.l	d2/a2-a3,-(sp)
	call	Forbid

.loop0	move.l	(MemList,a6),d2

.loop1	move.l	d2,a2
	move.l	(a2),d2
	beq.b	.quit

	cmp.l	#$1000000,a2		; address
	bhs.b	.loop1

	moveq	#MH_SIZE,d0
	moveq	#MEMF_PUBLIC!MEMF_FAST,d1
	call	AllocMem
	tst.l	d0
	beq.b	.quit
	move.l	d0,a3

	lea	(LN_TYPE,a2),a0		; source
	lea	(LN_TYPE,a3),a1		; dest
	moveq	#MH_SIZE-LN_TYPE,d0
	call	CopyMem

	lea	(MH_SIZE,a2),a0
	cmp.l	(MH_LOWER,a2),a0
	bne.b	.ok
	move.l	a2,(MH_LOWER,a3)
.ok
	move.l	a2,a1			; node
	call	Remove
	lea	(MemList,a6),a0		; list
	move.l	a3,a1			; node
	call	Enqueue

;	cmp.w	#36,(LIB_VERSION,a6)
;	blo.b	.loop0

	move.l	a2,a1			; memoryBlock
	moveq	#MH_SIZE,d0

	move.l	d0,d1
	add.l	a1,d1
	lea	(MemList,a6),a0
.floop	move.l	(a0),a0
	tst.l	(a0)
	beq.b	.fdone
	cmp.l	(MH_LOWER,a0),a1
	blo.b	.floop
	cmp.l	(MH_UPPER,a0),a1
	bhs.b	.floop
	cmp.l	(MH_UPPER,a0),d1
	bhi.b	.fdone
	call	FreeMem
.fdone	bra.b	.loop0

.quit	call	Permit
	movem.l	(sp)+,d2/a2-a3
	rts

_erh_name	dc.b	'EXTRES Handler',0
	CNOP	0,2
_erhandler_end
ERHANDLER_SIZEOF EQU	(*-_erhandler_module+7)&-8


CacheClearOS	movem.l	d0-d1/a0-a1/a6,-(sp)
	pea	(.cleanexit,pc)
	move.l	(_ExecBase,pc),a6
	cmp.w	#37,(LIB_VERSION,a6)
	blo.b	CacheClear
	jmp	(_LVOCacheClearU,a6)	OK! ;-)
.cleanexit	movem.l	(sp)+,d0-d1/a0-a1/a6
	rts
CacheClear	movem.l	a5/a6,-(sp)
	lea	(.cacheclrsv,pc),a5
	move.l	(_ExecBase,pc),a6
	call	Supervisor
	movem.l	(sp)+,a5/a6
	rts
.cacheclrsv	or.w	#$700,sr		Disable interrupts
	bsr.b	CacheClrS
	nop
	rte
CacheClrS	btst	#AFB_68020,(_AttnFlags+1,pc)
	beq.b	.nocache
	btst	#AFB_68040,(_AttnFlags+1,pc)
	beq.b	.not040
	cpusha	bc
	cinva	bc
	nop
.nocache	rts
.not040	move.l	d0,-(sp)
	movec	cacr,d0
	or.w	#CACRF_ClearI!CACRF_ClearD,d0
	movec	d0,cacr
	move.l	(sp)+,d0
	rts


	IFGT	0
DisableCache	btst	#AFB_68020,(_AttnFlags+1,pc)
	beq.b	.no68020
	movem.l	a5/a6,-(sp)
	lea	(.discachesv,pc),a5
	move.l	(_ExecBase,pc),a6
	call	Supervisor
	movem.l	(sp)+,a5/a6
.no68020	rts
.discachesv	or.w	#$700,sr		Disable interrupts
	bsr.b	DisableCacheS
	nop
	rte
	ENDC

DisableCacheS	move.l	d0,-(sp)
	movec	cacr,d0

	btst	#AFB_68040,(_AttnFlags+1,pc)
	bne.b	.is040

	and.w	#~(CACRF_EnableI!CACRF_IBE!CACRF_EnableD!CACRF_DBE),d0
	or.w	#CACRF_ClearI!CACRF_ClearD,d0
	movec	d0,cacr

	move.l	(sp)+,d0
	rts

.is040
	and.l	#~CACRF_CachesOr060,d0
	or.l	#CACRF_ClearAllBCache,d0
	nop
	cpusha	bc
	nop
	cinva	bc
	nop
	movec	d0,cacr
	nop

	; turn off 060 superscalar dispatch
	tst.b	(_AttnFlags+1,pc)
	bpl.b	.no060
	dc.w	$4E7A,$0808	movec	pcr,d0
	and.l	#PCRF_EnableDebugFeatures|PCRF_StoreLoadBypass|PCRF_DisableFPU,d0
	dc.w	$4E7B,$0808	movec	d0,pcr
.no060
	move.l	(sp)+,d0
	rts


; IN: a1=libname, d0=version, a6=execbase
OpenLib	move.w	#_LVOOldOpenLibrary,d1
	cmp.w	#33,(LIB_VERSION,a6)
	blo.b	.oldol
	move.w	#_LVOOpenLibrary,d1
.oldol	jsr	0(a6,d1.w)
	tst.l	d0
	rts


;  IN: a0=filename (d6=dosbase, _Printf)
; OUT: a1=buffer, d0=buffer len, d1=file len

XPKLoad	movem.l	d2-d7/a2-a6,-(sp)
	move.l	a0,a3
	sub.l	a5,a5
	moveq	#0,d6
	moveq	#0,d7

	move.l	(4*4,sp),a6
	move.l	a3,d1
;;	moveq	#ACCESS_READ,d2
;;	call	Lock
;;	move.l	d0,d1
	bsr	_lockread

	beq	.exit
	move.l	d1,-(sp)
	lea	(-(fib_SIZEOF+4),sp),sp
	move.l	sp,d2
	addq.l	#3,d2
	and.w	#-4,d2
	call	Examine
	move.l	d2,a0
	move.l	(fib_Size,a0),d3
	move.l	d0,d2
	lea	((fib_SIZEOF+4),sp),sp
	move.l	(sp)+,d1
	call	UnLock
	tst.l	d2
	beq.b	.exit

	move.l	a3,d1
	move.l	#MODE_OLDFILE,d2
	call	Open
	move.l	d0,d5
	beq.b	.exit

	move.l	d5,d1
	subq.l	#4,sp
	move.l	sp,d2
	move.l	d3,-(sp)
	moveq	#4,d3
	call	Read
	move.l	(sp)+,d3
	move.l	(sp)+,d4
	subq.l	#4,d0
	bne.b	.exit
	move.l	d5,d1
	moveq	#0,d2
	move.l	d3,-(sp)
	moveq	#OFFSET_BEGINNING,d3
	call	Seek
	move.l	(sp)+,d3
	subq.l	#4,d0
	bne.b	.exit
	cmp.l	#'XPKF',d4
	beq.b	.tryxpk

.noxpk	move.l	(_ExecBase,pc),a6
	move.l	d3,d0
	moveq	#MEMF_PUBLIC,d1
	call	AllocMem
	move.l	(4*4,sp),a6
	move.l	d0,d2
	beq.b	.close

	move.l	d5,d1
	call	Read
	cmp.l	d0,d3
	bne.b	.free

	move.l	d3,d7
	move.l	d3,d6
	move.l	d2,a5
	bra.b	.close

.free	move.l	(_ExecBase,pc),a6
	move.l	d2,a1
	move.l	d3,d0
	call	FreeMem
	move.l	(4*4,sp),a6

.close	move.l	d5,d1
	call	Close

.exit	move.l	a5,a1
	move.l	d6,d0
	move.l	d7,d1
	movem.l	(sp)+,d2-d7/a2-a6
	rts


.tryxpk	move.l	(_ExecBase,pc),a6
	lea	(.xpkname,pc),a1
	moveq	#0,d0
	bsr	OpenLib
	beq	.noxpk
	move.l	d0,d2

	move.l	(4*4,sp),a6
	move.l	d5,d1
	call	Close
	exg	d2,a6

XPKERRSIZE	EQU	((XPKERRMSGSIZE+1+3)&-4)

	lea	(-XPKERRSIZE,sp),sp
	move.l	sp,a4
	clr.l	-(sp)
	move.l	sp,d3
	clr.l	-(sp)
	move.l	sp,d4
	clr.l	-(sp)
	move.l	sp,d5
	clr.l	-(sp)
	moveq	#-1,d0
	move.l	d0,-(sp)
	pea	XPK_PassThru		Allow uncompressed file
	pea	MEMF_PUBLIC
	pea	XPK_OutMemType
	move.l	d5,-(sp)		buflen
	pea	XPK_GetOutBufLen
	move.l	d4,-(sp)		filelen
	pea	XPK_GetOutLen
	move.l	d3,-(sp)		outbuf
	pea	XPK_GetOutBuf
	move.l	a4,-(sp)		errbuf
	pea	XPK_GetError
	move.l	a3,-(sp)
	pea	XPK_InName
	move.l	sp,a0
	call	XpkUnpack
	move.l	d5,sp

	move.l	(sp)+,d6		d6=buflen
	move.l	(sp)+,d7		d7=filelen
	move.l	(sp)+,a5		a5=outbuf

	tst.l	d0
	beq.b	.allok
	; a4=errbuf
	move.l	a4,a0
.finde	tst.b	(a0)+
	bne.b	.finde
	move.b	#10,(-1,a0)
	clr.b	(a0)
	move.l	a4,a0
	exg	d2,d6
	bsr	_Printf
	exg	d2,d6

.allok	lea	(XPKERRSIZE,sp),sp

	move.l	a6,a1
	move.l	(_ExecBase,pc),a6
	call	CloseLibrary
	bra	.exit


.xpkname	dc.b	'xpkmaster.library',0
	CNOP	0,2





;  IN: a0=rom, d0=rom len
; OUT: d0=success (number of patches done, or zero)
LastPatches	movem.l	d1-a6,-(sp)
	moveq	#0,d7
	move.l	a0,a6
	move.l	d0,d6

SUPERVISOR_NOREVERSE	SET	0
	IFNE	SUPERVISOR_NOREVERSE
	move.w	#2048/2-1,d0		during first 2k
	move.l	#$2D40003A,d1
.scan	addq.l	#2,a0
	cmp.l	(a0),d1
	dbeq	d0,.scan
	tst.w	d0
	bmi.b	.not0
	cmp.l	#$6608223C,(4,a0)
	bne.b	.scan
	cmp.l	#MEMF_CLEAR!MEMF_REVERSE,(8,a0)
	bne.b	.scan
	cmp.w	#$60EC,(12,a0)
	bne.b	.scan

	move.w	#MEMF_CLEAR>>16,(8,a0)
	addq.l	#1,d7
.not0
	ENDC

	move.l	(_OrigSum,pc),d5
	cmp.l	ROMSUMOFFS(a6,d6.l),d5
	bne	.not_correct_chksum

	cmp.l	#33<<16!180,($C,a6)
	bne.b	.not_33180
	cmp.l	#$56F2E2A6,d5		Must be original to patch!
	bne.b	.not_33180

	move.w	#$0020,($19C,a6)	2MB chip ram
	move.l	#$FF000001,($3000,a6)	ExecBase address mask

	IFGT	0
	move.l	#$20482249,d0		move.l a0,a0 / move.l a1,a1
	move.l	d0,($4D9A,a6)		expansion.library bug
	move.l	#$4EAEFF3A,($4D9A+4,a6)
	move.l	#$4A80672E,($4D9A+8,a6)
	move.l	#$24002200,($4D9A+12,a6)
	move.l	#$20434280,($4D9A+16,a6)
	move.l	#$302F0002,($4D9A+20,a6)
	move.w	d0,($4D9A+24,a6)
	ENDC

	move.l	#$20482249,d0		move.l a0,a0 / move.l a1,a1
	move.w	d0,($4D9A,a6)		expansion.library bug
	move.l	d0,($4D9A+2,a6)
	move.l	#$4A80672C,($4DA4,a6)
	move.l	#$24002240,($4DA4+4,a6)
	move.l	#$20437000,($4DA4+8,a6)
	move.b	#$30,($4DA4+12,a6)

	; my:
	move.l	#$99CC4ED5,($1E6,a6)	no $C00000 mem, please !!
;;	clr.b	($56D,a6)		disable cache (instruction)

	addq.l	#1,d7
.not_33180

	cmp.l	#34<<16!5,($C,a6)
	bne.b	.not_3405
	cmp.l	#$15267DB3,d5		Must be original to patch!
	bne.b	.not_3405

	move.w	#$0020,($19C,a6)	2MB chip ram
	move.l	#$FF000001,($303C,a6)	ExecBase address mask

	addq.l	#1,d7
.not_3405

.not_correct_chksum

	move.l	d7,d0
	movem.l	(sp)+,d1-a6
	rts


;  IN: a0=rom, d0=rom len
; OUT: d0=success (number of patches done, or zero)
SpeedROM	movem.l	d1-a6,-(sp)

	moveq	#0,d7
	move.l	a0,a2
	move.l	d0,d4
	move.l	#$01000000,d2
	sub.l	d4,d2
	move.l	a2,a5
	sub.l	d2,a5			a5=difference

	move.l	(4,a2),a1
	add.l	a5,a1

	cmp.w	#$203C,(6,a1)		KS 1.x start: (34.5)
	bne.b	.nosp1
	cmp.l	#$53806EFC,(12,a1)
	bne.b	.nosp1
	move.w	#$6008,(6,a1)
	addq.l	#1,d7
.nosp1
	IFNE	HAVE_SPEEDROMCHECKSUM
	cmp.l	#$41F900F8,(4,a1)	KS 3.0 chksum:
	bne.b	.nosp2
	cmp.l	#$72FF7401,(10,a1)
	bne.b	.nosp2
	move.l	#$7AFF6010,(10,a1)
	addq.l	#1,d7
.nosp2
	cmp.l	#$41FAFF28,(4,a1)	KS 3.1 chksum:
	bne.b	.nosp3
	cmp.l	#$72FF7401,(8,a1)
	bne.b	.nosp3
	move.l	#$7AFF6010,(8,a1)
	addq.l	#1,d7
.nosp3
	ENDC

	; Reconnect resident modules:

	moveq	#-(RT_SIZE+2),d1
	move.l	a2,a0
	add.l	d4,d1
	sub.l	a1,a1
.find	subq.l	#2,d1
	bls.b	.done
	cmp.w	#RTC_MATCHWORD,(a0)+
	bne.b	.find
	moveq	#2,d0
	add.l	(a0),d0			(RT_MATCHTAG-2,a0),d0
	add.l	a5,d0
	cmp.l	a0,d0
	bne.b	.find
	subq.l	#2,a0
	move.l	a1,d0
	beq.b	.is_1st
	move.l	a0,d0
	sub.l	a5,d0
	move.l	d0,(RT_ENDSKIP,a1)
.is_1st	move.l	a0,a1
	lea	(RT_SIZE,a0),a0
	bra.b	.find
.done
	move.l	a1,d0
	beq.b	.none
	; make last RT_ENDSKIP point $00FFFFFA
	move.l	#$00FFFFFA,(RT_ENDSKIP,a1)
.none

	; can't really reconnect EXTRES buffer restags
	; ...

	addq.l	#1,d7

	move.l	d7,d0
	movem.l	(sp)+,d1-a6
	rts


	IFGT	0

; *** WARNING: REQUIRES SOURCE AND DESTINATION ADDRESSES ALIGNEG BY 16! ***

;  IN: a0=source ptr
;      a1=dest ptr
;      d0=copy len, aligned by 256
; OUT: a0=source ptr + copy len
;      a1=dest ptr + copy len
;      d0=copy len
copymem256_040	move.l	d0,-(sp)
	lsr.l	#8,d0			/256
.copy	move16	(a0)+,(a1)+		16
	move16	(a0)+,(a1)+		16
	move16	(a0)+,(a1)+		16
	move16	(a0)+,(a1)+		16

	move16	(a0)+,(a1)+		16
	move16	(a0)+,(a1)+		16
	move16	(a0)+,(a1)+		16
	move16	(a0)+,(a1)+		16

	move16	(a0)+,(a1)+		16
	move16	(a0)+,(a1)+		16
	move16	(a0)+,(a1)+		16
	move16	(a0)+,(a1)+		16

	subq.l	#1,d0
	move16	(a0)+,(a1)+		16
	move16	(a0)+,(a1)+		16
	move16	(a0)+,(a1)+		16
	move16	(a0)+,(a1)+		16
	bne.b	.copy
	move.l	(sp)+,d0
	rts

	ENDC


;  IN: a0=source ptr
;      a1=dest ptr
;      d0=copy len, aligned by 256
; OUT: a0=source ptr + copy len
;      a1=dest ptr + copy len
;      d0=copy len
copymem256	movem.l	d0-d7/a2-a6,-(sp)
	lsr.l	#8,d0			/256
.copy	movem.l	(a0)+,d1-d7/a2-a6
	movem.l	d1-d7/a2-a6,(a1)	12*4=48
	movem.l	(a0)+,d1-d7/a2-a6
	movem.l	d1-d7/a2-a6,(1*48,a1)	12*4=48
	movem.l	(a0)+,d1-d7/a2-a6
	movem.l	d1-d7/a2-a6,(2*48,a1)	12*4=48
	movem.l	(a0)+,d1-d7/a2-a6
	movem.l	d1-d7/a2-a6,(3*48,a1)	12*4=48
	movem.l	(a0)+,d1-d7/a2-a6
	movem.l	d1-d7/a2-a6,(4*48,a1)	12*4=48
	movem.l	(a0)+,d1-d4
	movem.l	d1-d4,(5*48,a1)		4*4=16
	subq.l	#1,d0
	lea	(256,a1),a1
	bne.b	.copy
	movem.l	(sp)+,d0-d7/a2-a6
	rts

	;IFGT	(copymem256_000-copymem256)-$7E
	;FAIL	"copymem256 offset out of bra.b!"
	;ENDC




;  IN: a4=rom buffer
;      d3=rom size
KickSys	movem.l	d1-a6,-(sp)
	;illegal

	lea	(default_pre,pc),a2
	lea	(default_post,pc),a3

	move.b	(_B20x0,pc),d0
	beq.b	.not_b20x0
	lea	(b20x0_pre,pc),a2
	lea	(b20x0_post,pc),a3
.not_b20x0

	move.b	(_MK2,pc),d0
	beq.b	.not_csmk2
	; uses default_pre
	lea	(csmk2_post,pc),a3
.not_csmk2

	move.b	(_CSPPC_MK3,pc),d0
	beq.b	.not_scppc_mk3
	lea	(csppcmk3_pre,pc),a2
	lea	(csppcmk3_post,pc),a3
.not_scppc_mk3

	move.b	(_BlizPPC,pc),d0
	beq.b	.not_blizzppc
	lea	(blizzppc_pre,pc),a2
	lea	(blizzppc_post,pc),a3
.not_blizzppc

	move.b	(_CPUCard,pc),d0
	beq.b	.notcpucard
	lea	(cpucard_pre,pc),a2
	lea	(cpucard_post,pc),a3
.notcpucard


	move.l	(_ExecBase,pc),a6
	lea	(GfxName,pc),a1
	moveq	#0,d0
	bsr	OpenLib
	tst.l	d0
	beq.b	.nogfx

	move.l	d0,-(sp)
	move.l	d0,a6
	call	OwnBlitter
	call	WaitBlit
	sub.l	a1,a1
	move.l	(gb_ActiView,a6),-(sp)
	call	LoadView
	call	WaitTOF

	; Reset AGA hardware
	cmp.w	#39,(LIB_VERSION,a6)
	blo.b	.noaga
	btst	#GFXB_AA_ALICE,(gb_ChipRevBits0,a6)
	beq.b	.noaga
	lea	$DFF106,a0
	move.w	#$0C00,(a0)
	move.w	#$0000,($1FC-$106,a0)
.noaga
	call	WaitTOF


	; Call the hw banging routine

	move.l	(_ExecBase,pc),a6
	lea	(.super,pc),a0
	bsr	runnommu
	; We drop in here if something goes terribly wrong.

	; Restore view
	move.l	(sp)+,a1
	move.l	(sp)+,a6
	call	LoadView
	call	WaitTOF
	call	DisownBlitter

	; Close gfxbase
	move.l	a6,a1
	move.l	(_ExecBase,pc),a6
	call	CloseLibrary

	; Whine to user
	lea	(KickSysErr,pc),a0
	bsr	_Printf

.nogfx	movem.l	(sp)+,d1-a6
	rts



.super	ori.w	#$700,sr		Disable all ints!
	bsr	CacheClrS		flush caches


	; Do whatever init the card needs

	movem.l	d3/a4,-(sp)
	jsr	(a2)
	movem.l	(sp)+,d3/a4
	tst.l	d0			Did it fail?
	bne.b	.cont
	; NOTE: MUST USE RTS HERE!
	rts

.cont
	; Copy the ROM to the magic address

	move.l	(_BlizROM,pc),a1

	cmp.l	#$40000,d3		Is it 256K ROM?
	bne.b	.no1st

	move.l	d3,d0			Copy 256k:
	move.l	a4,a0
	bsr	copymem256
.no1st
	move.l	d3,d0			Copy ROM:
	move.l	a4,a0
	bsr	copymem256


	; Flush & Disable caches
	;
	bsr	DisableCacheS		Disable all caches.


	; Do whatever post processing the card needs
	;
	jsr	(a3)


	; Trash execbase pointer (MMU disabled)
	;
	bsr	trashexecbase_sv


	; Reboot the system
	;
	lea	$DFF09A,a0
	move.w	#$4000,(a0)+		All interrupts off
	move.w	#$3FFF,(a0)		All DMA off

	lea	$01000000+4,a0		...and reboot...
	sub.l	(ROMSIZEOFFS-4,a0),a0
	move.l	(a0),a0
	subq.l	#2,a0
	IFGT	(*-Main)&2		Main must be longword aligned!
	move.l	a1,a1
	ENDC
	reset
	jmp	(a0)



; Trash execbase pointer, in both supervisor and user state
;
;  IN: - (supervisor state, interrupts disabled)
; OUT: d0-d1/a0-a1 trashed
trashexecbase_sv
	move.l	(_Array+ARG_KEEPEXEC,pc),d0
	bne.b	.exit

	sub.l	a1,a1
	btst	#AFB_68010,(_AttnFlags+1,pc)
	beq.b	.novbr
	movec	vbr,a1
.novbr
	lea	(8*4,a1),a1		; vector 8 (privilege violation)
	lea	(.privilege_violation,pc),a0
	move.l	(a1),d1			; save old privilege violation vector
	move.l	a0,(a1)			; set new privilege violation vector

	lea	(4).w,a0
	moveq	#-1,d0
	move.l	d0,(a0)			; Trash execbase (supervisor)

	move.l	d0,(4-(8*4),a1)		; Trash execbase (in VBR table)

	and.w	#~$2000,sr		; drop to user state
					; (must not use (sp) here, USP could be inaccessable!)
	move.l	d0,(a0)			; Trash execbase (user)

	ori.w	#$2000,sr		; back to supervisor
	nop

	move.l	d1,(a1)			; restore privilege violation vector

	bsr	CacheClrS
.exit	rts

.privilege_violation
	or.w	#$2000,(sp)		; force supervisor
	nop
	rte				; and re-try



	; Default: Blizzard 12x0
default_pre
	moveq	#1,d0
default_post
	rts


	; Blizzard 2040-ERC / 2060
b20x0_pre
	move.l	(_BlizROM,pc),a0

	moveq	#4-1,d0
.loop	moveq	#0,d1			Turn shadow off
	bsr.b	SetMemShadow

	move.l	(4,a0),-(sp)		Do some poking magic
	move.l	(a0),-(sp)
	move.l	(sp),d2
	move.l	d2,d1
	eor.l	#$BADC0DE5,d2
	move.l	d2,(a0)			Write test long
	nop
	move.l	d1,(4,a0)		Trash bus
	nop
	move.l	(a0),d1			Read test long
	nop
	move.l	(sp)+,(a0)		Restore to original
	move.l	(sp)+,(4,a0)
	nop
	bsr	CacheClrS

	cmp.l	d2,d1			Found mapping?
	beq.b	.found

	moveq	#1,d1			Turn shadow on
	bsr.b	SetMemShadow

	subq.l	#1,d0
	bpl.b	.loop

	; return failure
	moveq	#0,d0

.exit	bra	CacheClrS


.found
	lea	(_B20x0Bank,pc),a0
	move.l	d0,(a0)

	; return success
	; NOTE: The shadow is *left* off intentionally!

	moveq	#1,d0
	bra.b	.exit


b20x0_post
	moveq	#1,d1			Turn shadow on
	; [FALL THRU]
;
; This one is from old CyberMap I think...
; Modified a bit.
;
;*********************************************************
;*       writes memshadowregister of the given rambank
;*       setmemshadow(D0=bank,D1=on/off (bool))
;*********************************************************
;*       $ 8    2    c
;*       %100x yy10 1100 ---- ---- ---- ---- ----Shadow Register Format
;*					x = Set/Clr Flag  0=on 1=off
;*					y = Bank Number
MEMSHWREG	EQU	$82C00000		Shadow Enable Control Register

SetMemShadowN	move.l	(_B20x0Bank,pc),d0
	; [FALL THRU]

; IN: d0=bank, d1=mode
SetMemShadow	movem.l	d0-d1/a6,-(sp)

	ror.l	#6,d0			shift in place
	or.l	#MEMSHWREG,d0		mask in MEMSHWREG adr
	tst.l	(4,sp)			d1 from stack
	bne.b	.sf_skip		=! 0 -> TRUE -> b28=0
	bset	#28,d0			== 0 -> FALSE -> b28=1
.sf_skip	move.l	d0,a6			Write Register

	moveq	#%011,d0
	movec	dfc,d1			store old DFC
	movec	d0,dfc			set DFC to %011
	nop
	moves.l	a6,(a6)
	nop
	movec	d1,dfc			restore old DFC
	movem.l	(sp)+,d0-d1/a6
	rts





	; Cyberstorm MK II
csmk2_post
	bset	#7,$00DE0002		Set Gary Coldstart

	move.b	#$2A,$880000E3		Trigger MKII maprom
	nop
	rts



	; Cyberstorm MK III or PPC

csppcmk3_pre
	bset	#7,$00DE0002		Set Gary Coldstart

	lea	(csppc_mkiii_code1,pc),a0
	bsr	runwithmmu040
	moveq	#1,d0
	rts
csppcmk3_post
	lea	(csppc_mkiii_code2,pc),a0
	bra.b	csppcmk3_comm




	; BlizzardPPC
blizzppc_pre
	lea	(blizppc_code1,pc),a0
	bsr	runwithmmu040
	moveq	#1,d0
	rts
blizzppc_post
	lea	(blizppc_code2,pc),a0
csppcmk3_comm	bsr	runwithmmu040
	;;bra.b	pupcard_reboot

pupcard_reboot
	; Some PowerUP cards somehow screw up when rebooted
	; with the magic below. If NOPUPREBOOT option is set
	; this code is not run, but regular reboot code is
	; executed instead.
	;
	; This *finally* fix the annoying red screen crashes
	; with these systems, I hope.
	;
	move.l	(_Array+ARG_NOPUPREBOOT,pc),d0
	bne.b	.nopupreboot

	; Trash execbase pointer (MMU disabled)
	;
	bsr	trashexecbase_sv

	; trigger the card to reboot the system
	;
	move.b	#$40,$00F60018		; blizzppc/csppc/mkiii
	move.b	#$0C,$00F60000		; majik
	nop
	nop
	;
	; NOTE: We should never get here, the code above trigger
	; hard reset.
	;
	rts

.nopupreboot
	move.b	#$40,$00F60018		; blizzppc/csppc/mkiii majic
	rts



	; Cyberstorm MK I / A3640 / Blizzard A4030
cpucard_pre
	bset	#7,$00DE0002		Set Gary Coldstart

	clr.b	$00DE0000		Gary bootflags=ColdStart
	clr.b	$00DE0001
	nop
	move.l	#1,$80F80000		Trigger maprom
	nop

	moveq	#1,d0
	rts

cpucard_post
	move.b	#$80,$00DE0000		Gary BootFlag=ColdBoot
	move.b	#$80,$00DE0001
	rts



	; Some BlizzardPPC / CS PPC / CS MK III routines

blizppc_code1
	clr.b	$00F60013		Turn off BlizPPC maprom

	; fall thru

csppc_mkiii_code1
	nop
	nop
	move.b	#$10,$00F60000		blizzppc/csppc/mkiii
	nop				majik
	nop
	rts

csppc_mkiii_code2
	lea	$00F60020,a0		Trigger PPC/MKIII maprom
	move.b	#$60,(a0)
	nop
	move.b	#$50,(a0)
	nop
	move.b	#$30,(a0)
	nop
	move.b	#1,(-8,a0)
	nop
	clr.b	(a0)
	nop

	; fall thru

pupcard_common
	; disable interupts

	lea	$DFF09A,a0
	move.w	#$4000,(a0)+		All interrupts off
	move.w	#$3FFF,(a0)		All DMA off

	nop
	nop
	nop
	nop

	; If no Enforcer/CyberGuard/MuForce is running,
	; trash execbase with original MMU tables too.
	; Strictly speaking, this is not needed, but
	; this doesn't hurt either.
	;
	move.l	(_EnforcerFlag,pc),d0
	bne.b	.dontpoke

	; Trash execbase pointer (MMU enabled)
	;
	bsr	trashexecbase_sv
.dontpoke
	rts


blizppc_code2
	clr.b	$00F60012		Trigger BlizPPC maprom
	nop

	bra.b	pupcard_common


TestCPUCard
	movem.l	d1-d7/a0-a6,-(sp)
	moveq	#0,d7
	move.l	(_ExecBase,pc),a6
	call	Forbid

	lea	(MemList,a6),a5
	lea	(LH_TAIL,a5),a4

	move.l	#$07000000,d1
	move.l	#$08000000,d2
.loop	move.l	(a5),a5
	cmp.l	a5,a4
	beq	.nomem
	moveq	#MEMF_POOLMEM!MEMF_CHIP!MEMF_FAST!MEMF_PUBLIC,d0	Public fast?
	and.w	(MH_ATTRIBUTES,a5),d0
	cmp.w	#MEMF_FAST!MEMF_PUBLIC,d0
	bne.b	.loop
	cmp.l	(MH_LOWER,a5),d1
	bhi.b	.loop
	cmp.l	(MH_UPPER,a5),d2
	blo.b	.loop

	bsr	FoundMem

	call	Permit

	IFNE	HAVE_CPUCARDPOKING
	bsr.b	CheckCPUCard
	tst.l	d0
	beq.b	.exit
	ENDC

	; exit ok
	lea	(_BlizROM,pc),a0
	move.l	#$07F80000,(a0)

	moveq	#1,d0
.exit
	movem.l	(sp)+,d1-d7/a0-a6
	rts


.nomem	call	Permit
	moveq	#0,d0
	bra.b	.exit


	IFNE	HAVE_CPUCARDPOKING

;  IN: -
; OUT: d0,cc=nonzero if CPU Card with MAPROM present, else zero
CheckCPUCard	movem.l	d7/a6,-(sp)
	moveq	#0,d7
	move.l	(_ExecBase,pc),a6
	cmp.w	#37,(LIB_VERSION,a6)
	blo.b	.exit
	call	Forbid

	bsr.b	cachecontroli
	move.l	d0,-(sp)

	lea	(.nommu,pc),a0
	bsr	runnommu
	move.l	d0,d7

	move.l	(sp)+,d0
	bsr.b	cachecontrol

	call	Permit
.exit	move.l	d7,d0
	movem.l	(sp)+,d7/a6
	rts

.nommu	ori.w	#$700,sr		Lock All Irqs
	moveq	#0,d2
	clr.b	$DE0000			Gary bootflags=ColdStart
	clr.b	$DE0001
	nop
	move.l	#1,$80F80000		Trigger maprom
	nop
	move.l	$07F80000,d0		Test MAPROM
	cmp.l	$00F80000,d0
	bne.b	.nomap
	move.l	d0,d1			2nd test
	not.l	d1
	move.l	d1,$07F80000
	cmp.l	$F80000,d1
	beq.b	.does_map
.xit	move.l	d0,$07F80000
.nomap	move.b	#$80,$DE0000		Gary bootflags=Warmstart
	move.l	d2,d0
	rts

.does_map	moveq	#1,d2
	bra.b	.xit


cachecontroli	moveq	#CACRF_EnableI!CACRF_IBE,d0
cachecontrol	move.l	#~CACRF_WriteAllocate,d1
	jmp	(_LVOCacheControl,a6)

	ENDC


ExecName	dc.b	'exec.library',0
DosName	dc.b	'dos.library',0
_mmuflag	EQU	*-1
GfxName	dc.b	'graphics.library',0
	dc.b	'$VER: '
_Version	dc.b	'BlizKick 1.24 (26.05.07)',0
	dc.b	'$COPYRIGHT: '
_Copyright	dc.b	'Copyright © 1996-2007 PitPlane Productions',0
_Template	dc.b	'KICKFILE,MODULE/M,EXTRESBUF/N,SANITY/K/N,FORCE/S,'
	dc.b	'SPEEDROM/S,HOGWAITBLIT/S,CPUCARD=CSMKI/S,'
	dc.b	'IGNPATH=IGNOREBKMODPATH/S,NOPUPREBOOT/S,KEEPEXEC/S,'
	dc.b	'QUIET/S',0
_13Help	dc.b	'Usage: BlizKick ',$9b,'1mKICKFILE',$9b,'0m',10
	dc.b	'KICKFILE is full path for the ROM image to kick.',10,0
_ks13error	dc.b	'DOS Error #%ld!',10,0
	IFD	HAVE_NEW_ENV_METHOD
_VarEnvArcName	dc.b	'ENVARC:'
_VarName	dc.b	'BKMODPATH',0
	IFNE	HAVE_DEFBKMODPATH
_DefaultBKMODPATH
	dc.b	'DEVS:Modules/',0
	ENDC
	ELSE
_EnvName	dc.b	'ENVx',0
_EnvArcName	dc.b	'ENVARC:',0
_VarName	dc.b	'BKMODPATH',0
	ENDC

_enforcer	dc.b	'_The Enforcer_',0

NoHardware	dc.b	'BlizKick requires turbo board/CPU-card with MAPROM feature.',10,0
NoCPUCard	dc.b	'Couldn''t find CPU Card (or motherboard memory)!',10,0
PlantError	dc.b	'Couldn''t plant module ''%s''!',10,0
Messu	dc.b	'Phase5 turbo board MapROM tool written by Harry "Piru" Sintonen.',10,0
Messu2	dc.b	'Kicking AMIGA ROM Operating System %d.%d.',10,0
Already	dc.b	'Kickstart is already kicked!',10,0
CouldNotKick	dc.b	'Couldn''t kick file ''%s''!',10,0
NoRem	dc.b	'Kickstart wasn''t kicked using BlizKick!',10,0
NoRestore	dc.b	'Kickstart restoring not supported!',10,0
KickSysErr	dc.b	'Hardware banging failed!',10,0

	CNOP	0,4
_ExecBase	ds.l	1
_EnforcerFlag	ds.l	1
_mmubase	ds.l	1
_Array	ds.l	12
_BlizROM	ds.l	1
_Quiet	ds.l	1
_OrigSum	ds.l	1
_coldstart	ds.l	1
_erh_alloclen	ds.l	1
_erh_freeaddr	ds.l	1
_erh_arealen	ds.l	1
_erh_areastart	ds.l	1
_B20x0Bank	ds.l	1
_mmuregs
_itt0	ds.l	1		}
_itt1	ds.l	1		}
_dtt0	ds.l	1		}
_dtt1	ds.l	1		} fixed order
_cacr	ds.l	1		}
_tc	ds.l	1		}
_dfc	ds.l	1		}
_memhead	ds.b	MH_FIRST
_AttnFlags	ds.w	1
_MemHeaderFlag	ds.b	1
_B20x0	ds.b	1
_CPUCard	ds.b	1
_CSPPC_MK3	ds.b	1
_MK2	ds.b	1
_BlizPPC	ds.b	1
_UAE_Z3	ds.b	1

COPYCODE_SIZEOF	EQU	(*-Copy+7)&-8

	END


; maprom not on:
;
; CS MKI     MH_UPPER & $80000 == 0
; CS MKII    MH_UPPER & $80000 == 0
; CS MKIII   MH_UPPER & $80000 == 0
; CS PPC     MH_UPPER & $80000 != 0
; BLIZZ PPC  MH_UPPER & $F0000 != 0
;


; model     id       mem     start     end        notes  maprom
;turbo mem 2140/?    -        ?       - ?          A500
; 1220     2140/0C   4 meg   $00200000-$00600000  A1200
; 1230-I   2140/0?   ? meg   $????????-$????????  A1200  $????????
; 1230-II  2140/0B   4 meg   $0E000000-$0E400000  A1200  $0FF80000 ! ??
; 1230-II  2140/0B   8 meg   $????????-$????????  A1200  $1EF80000 ! ??
; 1230-III 2140/0D   8 meg   $1DC00000-$1E400000  A1200  $1EF80000
; 1230-III 2140/0D  32 meg   $1D000000-$1EF80000  A1200  $1EF80000
; 1230-IV  2140/11   8 meg   $78000000-$78800000  A1200  $4FF80000
; 1230-IV  2140/11   2 meg   $78000000-$78200000  A1200  $4FF80000?
; 1230-IV  2140/11  16 meg   $68000000-$68F80000  A1200  $4FF80000?
;?1260     2140/11   4 meg   $68000000-$68400000  A1200  $4FF80000 040&060 flag set!
;>1260     2140/11   8 meg   $78000000-$78800000  A1200  $4FF80000 040&060 flag set!
;?1260     2140/11  16 meg   $68000000-$69000000  A1200  $4FF80000 040&060 flag set!
; 1260     2140/11   4 meg   $68000000-$68380000  A1200  $4FF80000? 040&060 flag set!
; 1240-T   2140/11  16 meg   $68000000-$69000000  A1200  $4FF80000? 040 flag set!
; 2040-ERC 2140/18   8 meg   $08000000-$08800000  A2000  $???????? 040 flag set!  'blizzard fastram'
; 2060     2140/18  20 meg   $08000000-$09400000  A2000  $???????? 040&060 flag set!
; 4030     2140/?    -        ?       - ?         A4000

; CSMKI    2140/0C  32 meg   $08000000-$0A000000  A4000  csmagic  040 flag set
; CSMKII   2140/19  80 meg   $08000000-$0D000000  A4000  csmagic
; CS-PPC   2140/64   ? meg    ?       - ?         A4000 
; BLIZPPC  2140/6E  16 meg   $68000000-$68800000  A1200  $FFF00000 040 flag set

 Board (unidentified):   Prod=8512/25($2140/$19) (@$EA0000 128K)
 Board (unidentified):   Prod=2092/18($82C/$12) (@$E90000 64K)
 Board (unidentified):   Prod=2167/201($877/$C9) (@$EC0000 64K)
 Board (unidentified):   Prod=8512/34($2140/$22) (@$40000000, size 64meg, subsize same)

last one is CV 64

 VERS:   Kickstart version 40.70, Exec version 40.10, Disk version 40.42
 RAM:    Node type $A, Attributes $505 (FAST), at $8000000-$CFFFFFF (80.0 meg)


*** CS MK I:

PROCESSOR:	CPU 68040/68882fpu
CUSTOM CHIPS:	AA PAL Alice (id=$0023), AA Lisa (id=$00F8)
VERS:	Kickstart version 39.106, Exec version 39.47, Disk version 39.29
RAM:	Node type $A, Attributes $505 (FAST), at $8000000-$9FFFFFF (32.0 meg)
	Node type $A, Attributes $703 (CHIP), at $2000-$1FFFFF (~2.0 meg)
BOARDS:
=======================================================================
 Board + ROM (HD?) (unidentified):   Prod=8512/12($2140/$C) (@$E90000 64K)
 ConfigDev structure found at location $2840
==== Board ID (ExpansionRom) information:
er_Manufacturer         =8512=$2140=(~$DEBF)
er_Product              =12=$C=(~$F3)
er_Type                 =$D1
  (type 3, size 64K, not for free list, ROM diag vec valid, not chained)
er_Flags                =$0
  (no space preference, can be shut up)
er_InitDiagVec          =$80
DiagCopy at             =$8003320
==== Configuration (ConfigDev) information:
cd_BoardAddr            =$E90000
cd_BoardSize            =$10000 (64K)
cd_Flags                =$0  (CONFIGME bit cleared)
