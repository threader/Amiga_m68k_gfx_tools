; FILE: Source:modules/romfixes.ASM          REV: 15 --- misc rom bugfixes
; History
;  0      Started 10th Dec 1999: got idea from Fixes dir in MMULib.lha
;  1      12th Dec: console device fix accidently bsr'ed two bytes off
;         -> strange console update problems & cyberguard hits, fixed
;  2      Added shell Resident patch. froze 1.19.
;  3      Fixed ramlib stack patch for V37 rom
;  4      Added ramlib msgport sigbit patch
;  5      3rd Jan 2000: Disabled resident patch, it's bugged!
;  6      7th Jan 2000: Bugfixed resident patch. No longer freezes if
;         user says `resident c:program' without `ADD' switch.
;         froze 1.20.
;  7      11th Sep 2000: Added exec/Alert() enable bugfix.
;  8      20th Oct 2000: Added graphics/WriteChunkyPixels(),
;         graphics/WritePixelArray8(), graphics/WritePixelLine8() and
;         exec/FreePooled() bugfixes. These are also fixed by standard
;         SetPatch.
;  9      2nd Nov 2000: No longer fail if exec can't be patched. Don't
;         ask me why. :-)
;  10     9th Dec 2000: Added exec/ReleaseSemaphore bugfix.
;  11     13th Dec 2000: Added 68000/68010 utility/UMult64 bugfix.
;  12     1st Feb 2001: No longer barf on V44+ console.device.
;  13     8th Feb 2001: Added A4000/A4000T IDE scsi.device initroutine
;         bugfix.
;  14     31th Jul 2001: Added graphics/InitArea() bugfix.
;  15     22th Mar 2002: No longer fail whole module if some patch fail.
;         Now it should be possible to use romfixes as the last module.
;

;
; romfixes patch for BlizKick ("patch" Module)
; ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
;
; This patch fixes some bugs in current rom versions (including V40!)
;
; - console.device window resize bug (ever wondered why KingCON shell
;   having review buffer and menus enabled crashes on window resize?-)
;   (idea from Thor's util/boot/ConsoleFix.lha)
; - increase ram disk stack size (idea from Thor's util/boot/PatchRAM.lha)
; - increase ramlib stack size from 2k to 8k
; - make ramlib msgport use sigbit SIGBREAKB_CTRL_E instead of SIGB_SINGLE
;   (idea from Eddy Carroll's SnoopDos source code)
; - shell Resident command bug, see CyberGuard.notes / 1.11beta3
; - fix harmless "bug" from exec/Alert() -call. It does 'tst.l (IDNestCnt,a6)'
;   when it should do 'tst.b (IDNestCnt,a6)'.
; - graphics/WriteChunkyPixels() bugfix, the function trashed a2/a6 with
;   Akiko chip.
; - fix graphics/WritePixelArray8() and graphics/WritePixelLine8() source
;   trashing bug.
; - fix exec/ReleaseSemaphore() problem with simultanous pending Procure()
;   and ObtainSemaphore().
; - fix 68000/68010 utility/UMult64() swapped d0 and d1 result registers.
;   (also fixes utility/SMult64())
; - fix A4000/A4000T IDE scsi.device initroutine peeking random memory.
; - fix graphics/InitArea() bug, AreaEllipse() crashed if buffer wasn't
;   explicitly zeroed & maxvectors was limited to 8191.
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

	cmp.w	#37,($C,a0)		; requires V37+ rom image
	blo	.exit

	lea	(regs,pc),a5
	movem.l	d0/a0-a4,(a5)

	lea	(.conname,pc),a1
	movem.l	(regs,pc),d0/a0
	move.l	(findresident,pc),a2
	jsr	(a2)
	lea	(.nocon,pc),a1
	tst.l	d0
	beq	.err

	move.l	d0,a2
	cmp.b	#44,(RT_VERSION,a2)	; check for OS 3.5+ console.device
	bhs	.noconbug

	IFGT	0
	move.l	(RT_INIT,a2),a2
	;test if inside rom bounds?
	move.l	(rom_log,pc),d0
	cmp.l	d0,a2
	blo.b	.nofix
	add.l	(rom_size,pc),d0
	cmp.l	d0,a2
	bhs.b	.nofix
	; inside rom, so generate ram buffer address
	sub.l	(rom_log,pc),a2		; -$f80000
	add.l	(rom_phys,pc),a2	; +buffer
.nofix
	ENDC

	lea	(.badcon,pc),a1
	lea	(8192,a2),a2
	move.w	#16384/2,d0
.find	addq.l	#2,a2
	subq.w	#1,d0
	beq	.confailed

	cmp.l	#$2C5F45EE,(a2)
	bne.b	.find
	cmp.l	#$0082614C,(4,a2)
	bne.b	.find
	cmp.l	#$24524A92,(8,a2)
	bne.b	.find
	cmp.l	#$66F841EE,(12,a2)
	bne.b	.find
	cmp.l	#$126E2F0E,(16,a2)
	bne.b	.find

	; patch console.device bug!

	lea	(.consoledev,pc),a0
	bsr	.patch
	bra.b	.got_conbug

.confailed	bsr	.print
.got_conbug
.noconbug

	lea	(.dosname,pc),a1
	movem.l	(regs,pc),d0/a0
	move.l	(findresident,pc),a2
	jsr	(a2)
	lea	(.nodos,pc),a1
	tst.l	d0
	beq	.err

	move.l	d0,a2
	lea	(.badram,pc),a1
	lea	(8192,a2),a2
	move.w	#16384/2,d0
.find2	addq.l	#2,a2
	subq.w	#1,d0
	;beq	.err
	beq	.noramdiskstack

	cmp.l	#$4878FFFF,(a2)		; pea	(-1).w
	bne.b	.find2
	cmp.l	#$4878000A,(4,a2)	; pea	(10).w
	bne.b	.find2
	cmp.l	#$487804B0,(8,a2)	; pea	(1200).w
	bne.b	.find2
	cmp.l	#$7000222B,(12,a2)	; moveq #0,d0 / move.l (x,a3),d1
	bne.b	.find2

	; patch ram disk stack size!
	move.w	#2048,(10,a2)
	bra.b	.got_ramdiskstack
.noramdiskstack
	bsr	.print
.got_ramdiskstack

	lea	(.ramlibname,pc),a1
	movem.l	(regs,pc),d0/a0
	move.l	(findresident,pc),a2
	jsr	(a2)
	lea	(.noramlib,pc),a1
	tst.l	d0
	beq	.err

	move.l	d0,a3
	move.l	d0,a2

	lea	(.badramlib,pc),a1
	move.w	#2048/2,d0
.find3	addq.l	#2,a2
	subq.w	#1,d0
	beq.b	.try_37

	cmp.l	#$2608E48B,(a2)
	bne.b	.find3
	cmp.l	#$7808E19C,(4,a2)
	bne.b	.find3
	cmp.l	#$4EAEFF76,(8,a2)
	bne.b	.find3

	; patch ramlib stack size! (v39+)
	move.w	#$7820,(4,a2)
	bra.b	.was_39plus


.try_37	move.l	a3,a2
	move.w	#2048/2,d0
.find3_37	addq.l	#2,a2
	subq.w	#1,d0
	;beq	.err
	beq	.noramlibstack

	cmp.l	#$283C0000,(a2)
	bne.b	.find3_37
	cmp.l	#$08004EAE,(4,a2)
	bne.b	.find3_37
	cmp.l	#$FF762C5F,(8,a2)
	bne.b	.find3_37

	; patch ramlib stack size! (v37)
	move.w	#$2000,(4,a2)
.was_39plus

	lea	(.badramlib_b,pc),a1
	move.w	#4096/2,d0
.find3b	addq.l	#2,a3
	subq.w	#1,d0
	;beq	.err
	beq	.noramlibstack

	cmp.l	#$246E0114,(a3)
	bne.b	.find3b
	cmp.w	#$2B4A,(4,a3)
	bne.b	.find3b
	cmp.l	#$3B7C0004,(8,a3)
	bne.b	.find3b
	cmp.l	#$600841ED,(14,a3)
	bne.b	.find3b

	; patch ramlib msgport sigbit
	move.w	#14,(10,a3)		; SIGBREAKB_CTRL_E


	bra.b	.got_ramlibstack
.noramlibstack
	bsr	.print
.got_ramlibstack


	lea	(.shellname,pc),a1
	movem.l	(regs,pc),d0/a0
	move.l	(findresident,pc),a2
	jsr	(a2)
	lea	(.noshell,pc),a1
	tst.l	d0
	beq	.err

	move.l	d0,a2
	lea	(.badresident,pc),a1
	lea	(8192,a2),a2
	move.w	#12288/2,d0
.find4	addq.l	#2,a2
	subq.w	#1,d0
	;beq	.err
	beq	.noresidentbug

	cmp.l	#$67164AAD,(a2)
	bne.b	.find4
	cmp.l	#$FFD06624,(4,a2)
	bne.b	.find4
	cmp.l	#$202B0004,(8,a2)
	bne.b	.find4
	cmp.l	#$4A806A08,(12,a2)
	bne.b	.find4
	cmp.l	#$0C80FFFF,(16,a2)
	bne.b	.find4
	cmp.l	#$FC196E14,(20,a2)
	bne.b	.find4
	cmp.l	#$4AADFFD4,(24,a2)
	bne.b	.find4
	cmp.l	#$660000B6,(28,a2)
	bne.b	.find4
	cmp.l	#$0CAB0000,(32,a2)
	bne.b	.find4
	cmp.l	#$00010004,(36,a2)
	bne.b	.find4

	; patch shell resident command

	lea	(.shell_resident,pc),a0
	bsr	.patch

	bra.b	.got_residentbug
.noresidentbug
	bsr	.print
.got_residentbug


	lea	(.execname,pc),a1
	movem.l	(regs,pc),d0/a0
	move.l	(findresident,pc),a2
	jsr	(a2)
	lea	(.noexec,pc),a1
	tst.l	d0
	beq	.err

	move.l	d0,a3
	lea	(.noalert,pc),a1
	lea	(8192,a3),a2
	move.w	#8192/2,d0
.find5	subq.w	#1,d0
	beq.b	.isfixed5
	addq.l	#2,a2
	cmp.l	#$4CDF6303,(4,a2)	'movem.l (sp)+,d0/d1/a0/a1/a5/a6'
	bne.b	.find5
	cmp.l	#$6C0833FC,(8,a2)	'bge.b *+$a / move.w #x,abs'
	bne.b	.find5
	cmp.l	#$41EE0202,(-12,a2)	'lea (LastAlert,a6),a0'
	bne.b	.find5
	cmp.l	#$20C720CD,(-8,a2)	'move.l d7,(a0)+ / move.l a5,(a0)+'
	bne.b	.find5
	cmp.w	#$4EB9,(-4,a2)		'jsr (x).l' (already ok!)
	beq.b	.isfixed5
	cmp.l	#$4AAE0126,(a2)		'tst.l IDNestCnt(a6)'
	bne.b	.find5

	; Fix Alert() enable bug (make it tst.b not tst.l)
	move.w	#$4A2E,(a2)

	bra.b	.got_alertbug
.isfixed5
	bsr	.print
.got_alertbug

	cmp.b	#39,(RT_VERSION,a3)	; requires V39+ exec
	blo	.no_v39exec

	lea	(.nofreepooled,pc),a1
	lea	(4096,a3),a2
	move.w	#8192/2,d0
.find6	subq.w	#1,d0
	beq.b	.isfixed6
	;beq	.err
	addq.l	#2,a2
	cmp.l	#$20290020,(a2)
	bne.b	.find6
	cmp.l	#$D0A90014,(4,a2)
	bne.b	.find6
	cmp.l	#$90A90018,(8,a2)
	bne.b	.find6
	cmp.l	#$67064E75,(12,a2)
	bne.b	.find6
	cmp.l	#$59895189,(16,a2)
	bne.b	.find6
	cmp.l	#$20092059,(20,a2)
	bne.b	.find6

	; Fix FreePooled() bug
	move.w	#$001C,(2,a2)

	bra.b	.got_freepooled
.isfixed6
	bsr	.print
.got_freepooled

	lea	(.noreleasesemaphore,pc),a1
	lea	(4096,a3),a2
	move.w	#8192/2,d0
.find9	subq.w	#1,d0
	beq	.isfixed9
	;beq	.err
	addq.l	#2,a2
	cmp.l	#$234A0014,(a2)
	bne.b	.find9
	cmp.l	#$526A000E,(4,a2)
	bne.b	.find9
	cmp.l	#$4EAEFE86,(8,a2)
	bne.b	.find9
	cmp.l	#$222A0028,(12,a2)
	bne.b	.find9
	cmp.l	#$201367DA,(16,a2)
	bne.b	.find9
	cmp.l	#$224B2640,(20,a2)
	bne.b	.find9
	cmp.l	#$20290008,(24,a2)
	bne.b	.find9
	cmp.l	#$6712B280,(28,a2)
	bne.b	.find9
	cmp.l	#$66EE2069,(32,a2)
	bne.b	.find9
	cmp.l	#$0004208B,(36,a2)
	bne.b	.find9
	cmp.l	#$27480004,(40,a2)
	bne.b	.find9
	cmp.l	#$224160B4,(44,a2)
	bne	.find9
	cmp.l	#$B2A90014,(48,a2)
	bne	.find9
	cmp.l	#$66DA2069,(52,a2)
	bne	.find9
	cmp.l	#$0004208B,(56,a2)
	bne	.find9
	cmp.l	#$27480004,(60,a2)
	bne	.find9
	cmp.l	#$526A000E,(64,a2)
	bne	.find9
	cmp.w	#$60BA,(68,a2)
	bne	.find9

	; Fix ReleaseSemaphore() bug
	move.w	#$60BE,(64,a2)

	bra.b	.got_releasesemaphore
.isfixed9
	bsr	.print
.got_releasesemaphore
.no_v39exec

	lea	(.gfxname,pc),a1
	movem.l	(regs,pc),d0/a0
	move.l	(findresident,pc),a2
	jsr	(a2)
	lea	(.nogfx,pc),a1
	tst.l	d0
	beq	.err

	move.l	d0,a3
	cmp.w	#40,(RT_VERSION,a3)	; WriteChunkyPixels is V40 only
	bne	.no_v40

	move.l	(rom_phys,pc),a0
	cmp.l	#(40<<16)|63,($C,a0)	; 40.63 doesn't have this bug since the WCP()
	beq	.no_v40			; function doesn't implement Akiko support.

	lea	(.badwcp,pc),a1
	lea	(2048,a3),a2
	move.w	#8192/2,d0
.find7	addq.l	#2,a2
	subq.w	#1,d0
	beq.b	.nowcp			; ignore possible error

	cmp.l	#$2F0E2F0A,(a2)
	bne.b	.find7
	cmp.l	#$2F082248,(4,a2)
	bne.b	.find7
	cmp.l	#$487A0020,(8,a2)
	bne.b	.find7
	cmp.l	#$4FEFFFF8,(12,a2)
	bne.b	.find7
	cmp.l	#$204F48A7,(16,a2)
	bne.b	.find7
	cmp.l	#$F000244F,(20,a2)
	bne.b	.find7
	cmp.l	#$2F042C6E,(24,a2)
	bne.b	.find7
	cmp.l	#$01C84EAE,(28,a2)
	bne.b	.find7
	cmp.l	#$FF284FEF,(32,a2)
	bne.b	.find7
	cmp.l	#$00242C5F,(36,a2)
	bne.b	.find7
	cmp.w	#$4E75,(40,a2)
	bne.b	.find7

	; patch graphics/WriteChunkyPixels()
	lea	(.writechunkypixels,pc),a0
	bsr	.patch
	bra.b	.no_v40
.nowcp	bsr	.print
.no_v40

	lea	(.badwpa8,pc),a1
	lea	(2048,a3),a2
	move.w	#16384/2,d0
.find8	addq.l	#2,a2
	subq.w	#1,d0
	beq	.nowpa			; ignore possible error

	cmp.l	#$944048C2,(a2)
	bne.b	.find8
	cmp.l	#$52822802,(4,a2)
	bne.b	.find8
	cmp.l	#$6F342E00,(8+8,a2)
	bne.b	.find8
	cmp.l	#$2A019641,(8+12,a2)
	bne.b	.find8
	cmp.l	#$48C35283,(8+16,a2)
	bne.b	.find8
	cmp.l	#$6F282648,(8+20,a2)
	bne.b	.find8
	cmp.l	#$20072205,(8+32,a2)
	bne.b	.find8
	cmp.l	#$224C4EB9,(8+36,a2)
	bne.b	.find8
	cmp.l	#$48E7FFFC,(8+70,a2)
	bne.b	.find8
	cmp.l	#$26690004,(8+74,a2)
	bne.b	.find8
	cmp.l	#$20024E75,(8+304,a2)	; v39/v40
	beq.b	.found8
	cmp.l	#$20024E75,(8+310,a2)	; v37
	bne.b	.find8
.found8
	addq.l	#8,a2
	; patch graphics/WritePixelArray8() & graphics/WritePixelLine8()
	lea	(.writepixelarray8,pc),a0
	bsr	.patch
	bra.b	.got_wpa
.nowpa	bsr	.print
.got_wpa

	lea	(.badinitarea,pc),a1
	lea	(1024,a3),a2
	move.w	#16384/2,d0
.findc	addq.l	#2,a2
	subq.w	#1,d0
	beq.b	.isfixedc

	cmp.l	#$21490004,(a2)
	bne.b	.findc
	moveq	#0,d1			; skip=0
	cmp.l	#$20893140,(4,a2)
	beq.b	.is_v39v40
	cmp.l	#$21490000,(4,a2)	; v37.x
	bne.b	.findc
	cmp.w	#$3140,(8,a2)		; v37.x
	bne.b	.findc
	moveq	#2,d1			; skip=2
.is_v39v40	cmp.l	#$0012E580,8(a2,d1.l)
	bne.b	.findc
	cmp.l	#$D2C02149,12(a2,d1.l)
	bne.b	.findc
	cmp.l	#$000C2149,16(a2,d1.l)
	bne.b	.findc
	cmp.l	#$00084268,20(a2,d1.l)
	bne.b	.findc
	cmp.l	#$00104E75,24(a2,d1.l)
	bne.b	.findc

	; patch graphics/InitArea()
	lea	(.initarea,pc),a0
	bsr	.patch
	bra.b	.got_initarea
.isfixedc	bsr	.print
.got_initarea


	lea	(.utilname,pc),a1
	movem.l	(regs,pc),d0/a0
	move.l	(findresident,pc),a2
	jsr	(a2)
	lea	(.noutil,pc),a1
	tst.l	d0
	beq	.err
	move.l	d0,a2

	cmp.b	#39,(RT_VERSION,a2)	; requires V39+ utility
	blo	.no_v39util

	lea	(.noumult64,pc),a1
	move.w	#8192/2,d0
.finda	subq.w	#1,d0
;	beq	.err
	beq	.isfixeda
	addq.l	#2,a2
	cmp.l	#$48E73800,(a2)
	bne.b	.finda
	cmp.l	#$2601C6C0,(4,a2)
	bne.b	.finda
	cmp.l	#$24014842,(8,a2)
	bne.b	.finda
	cmp.l	#$4840C4C0,(12,a2)
	bne.b	.finda
	cmp.l	#$48432801,(16,a2)
	bne.b	.finda
	cmp.l	#$C8C0D644,(20,a2)
	bne.b	.finda
	cmp.l	#$42444844,(24,a2)
	bne.b	.finda
	cmp.l	#$D5844840,(28,a2)
	bne.b	.finda
	cmp.l	#$48412801,(32,a2)
	bne.b	.finda
	cmp.l	#$C8C0D644,(36,a2)
	bne.b	.finda
	cmp.l	#$42444844,(40,a2)
	bne.b	.finda
	cmp.l	#$D5844843,(44,a2)
	bne.b	.finda
	cmp.l	#$20022203,(48,a2)
	bne	.finda
	cmp.l	#$4CDF001C,(52,a2)
	bne	.finda
	cmp.w	#$4E75,(56,a2)
	bne	.finda

	; Fix 68000/68010 UMult64() bug
	move.l	#$22022003,(48,a2)

	bra.b	.got_umult64
.isfixeda
	bsr	.print
.got_umult64
.no_v39util


	move.l	(rom_phys,pc),a0
	cmp.l	#(37<<16)|299,($C,a0)	; pre-37.299 doesn't have scsi.device, and thus no bug
	blo	.no_v37scsi

	lea	(.scsiname,pc),a1
	movem.l	(regs,pc),d0/a0
	move.l	(findresident,pc),a2
	jsr	(a2)
	lea	(.noscsi,pc),a1
	tst.l	d0
	beq	.err
	move.l	d0,a3

	cmp.b	#37,(RT_VERSION,a3)	; scsidisk 37+
	blo	.no_v37scsi

	lea	(.noscsiinit,pc),a1
	move.l	a3,a2
	moveq	#254/2,d0
.findb1	subq.w	#1,d0
;debug!	beq	.err
	beq	.isfixedb
	addq.l	#2,a2
	cmp.l	#$48E73F3C,(a2)
	bne.b	.findb1
	cmp.l	#$93C94EAE,(4,a2)
	bne.b	.findb1
	cmp.l	#$FEDA2A00,(8,a2)
	bne.b	.findb1
	cmp.l	#$70064EAE,(12,a2)
	bne.b	.findb1
	cmp.l	#$FCD64A80,(16,a2)
	bne.b	.findb1
	cmp.l	#$660E2E3C,(20,a2)
	bne.b	.findb1
	cmp.l	#$14030000,(24,a2)
	bne.b	.findb1
	cmp.l	#$4EAEFF94,(28,a2)
	bne.b	.findb1
	cmp.w	#$6000,(32,a2)
	bne.b	.findb1
	cmp.l	#$7C0049F9,(36,a2)
	bne.b	.findb1
	cmp.l	#$00DD2020,(40,a2)
	bne.b	.findb1
	cmp.l	#$2F007000,(44,a2)
	bne.b	.findb1
	cmp.w	#$6100,(48,a2)
	bne	.findb1
	cmp.l	#$2200201F,(52,a2)
	bne	.findb1
	cmp.l	#$4A816700,(56,a2)
	bne	.findb1
	cmp.w	#$2C40,(62,a2)
	bne	.findb1

	; find 'battmem.resource' string
	move.w	#10240/2,d0
	moveq	#2,d2
.findb2	subq.w	#1,d0
;debug!	beq	.err
	beq	.isfixedb
	addq.l	#2,d2
	cmp.l	#'batt',16+0(a2,d2.l)		; 16 is offset to 'lea (battmemname,pc),a1'
	bne.b	.findb2
	cmp.l	#'mem.',16+4(a2,d2.l)
	bne.b	.findb2
	cmp.l	#'reso',16+8(a2,d2.l)
	bne.b	.findb2
.errb2
	; find read_battmem routine
	move.w	#10240/2,d0
	moveq	#2,d1
.findb3	subq.w	#1,d0
;debug!	beq	.err
	beq	.isfixedb
	addq.l	#2,d1
	cmp.l	#$41ED0042,32+0(a2,d1.l)	; 32 is offset the 'bsr.w read_battmem'
	bne.b	.findb3
	cmp.l	#$70017201,32+4(a2,d1.l)
	bne.b	.findb3
	cmp.l	#$4EAEFFEE,32+8(a2,d1.l)
	bne.b	.findb3
	cmp.l	#$2C554E75,32+12(a2,d1.l)
	bne.b	.findb3

	move.w	(32+2,a2),d3			; .exitnull offset
	move.w	(48+2,a2),d4			; scsi_probescsi offset
	add.w	#32-50,d3			; adjust for the patch
	add.w	#48-42,d4

	; Patch A4000 scsi.device init bug

	move.l	a2,a3
	lea	(.a4000scsidev,pc),a0
	bsr	.patch
	move.w	d2,(16,a3)			; fix battmemname lea offset (ok!)
	move.w	d1,(32,a3)			; fix read_battmem bsr.w offset (ok!)
	move.w	d3,(50+2,a3)			; fix .exitnull beq.w offset
	move.w	d4,(42+2,a3)			; fix scsi_probescsi bsr.w offset (ok!)


	bra.b	.got_scsidev
.isfixedb
	bsr	.print
.got_scsidev
.no_v37scsi



	moveq	#1,d7

.err	tst.l	d7
	bne.b	.exit
.print	movem.l	d0-d1/a0-a2,-(sp)
	lea	(.errh,pc),a0
	move.l	a1,-(sp)
	move.l	sp,a1
	move.l	(printf,pc),a2
	jsr	(a2)
	addq.l	#4,sp
	movem.l	(sp)+,d0-d1/a0-a2
.exit	move.l	d7,d0
	rts



.patch	move.w	(a0)+,d0
.copy	move.w	(a0)+,(a2)+
	subq.w	#1,d0
	bne.b	.copy
	rts


PATCH	MACRO
.\1	dc.w	(.\1_END-*-2)>>1
	ENDM

	PATCH	consoledev
	dc.l	$2C5745EE
	dc.l	$00826002
	dc.l	$614A2452
	dc.l	$4A9266F8
	dc.l	$41EE126E
.consoledev_END

	PATCH	shell_resident
	dc.l	$671C4AAD
	dc.l	$FFD06624
	dc.l	$200B6720
	dc.l	$202B0004
	dc.l	$6A0C0C80
	dc.l	$FFFFFC19
	dc.l	$6E126002
	dc.l	$C0DE4AAD
	dc.l	$FFD46600
	dc.l	$00B05380
.shell_resident_END

.	PATCH	writechunkypixels
	dc.l	$48E700A2
	dc.l	$2248487A
	dc.l	$0022518F
	dc.l	$204F48A7
	dc.l	$F000244F
	dc.l	$2F042C6E
	dc.l	$01C84EAE
	dc.l	$FF284FEF
	dc.l	$001C4CDF
	dc.l	$4400588F
.writechunkypixels_END

	PATCH	writepixelarray8
	dc.l	$D87C000F
	dc.l	$7CFFC87C
	dc.l	$FFF06F2A
	dc.l	$2E002A01
	dc.l	$964148C3
	dc.l	$52836F1E
	dc.l	$7C002648
	dc.l	$2849204B
	dc.l	$20072205
	dc.l	$224C6122
	dc.l	$5285D5C4
	dc.l	$DC805383
	dc.l	$66EC4EAE
	dc.l	$FF1C2006
	dc.l	$4CDF1CFC
	dc.w	$4E75

	dc.l	$4E714E71
	dc.l	$4E714E71

	dc.l	$2F2EFF1E

	dc.w	$48E7
	dc.l	$FFFC48C2
	dc.l	$D47C000F
	dc.l	$C47CFFF0
	dc.l	$72102802
	dc.l	$4EAEFF1C

	dc.l	$206F0024
	dc.l	$26042068
	dc.l	$00049682
	dc.l	$10280005
	dc.l	$47F23800
	dc.l	$5088E68B
	dc.l	$4CDB30C0

	dc.l	$22587A00
	dc.l	$D3C31A23
	dc.l	$E29D1685
	dc.l	$1A23E29D
	dc.l	$16851A23
	dc.l	$E29D1685
	dc.l	$1A23E29D
	dc.l	$16851A23
	dc.l	$E29D1685
	dc.l	$1A23E29D
	dc.l	$16851A23
	dc.l	$E29D1685
	dc.l	$1A23E29D
	dc.l	$16851A23
	dc.l	$E29D1685
	dc.l	$1A23E29D
	dc.l	$16851A23
	dc.l	$E29D1685
	dc.l	$1A23E29D
	dc.l	$16851A23
	dc.l	$E29D1685
	dc.l	$1A23E29D
	dc.l	$16851A23
	dc.l	$E29D1685
	dc.l	$1A23E29D
	dc.l	$1685E3BD
	dc.l	$D7C132C5
	dc.l	$53006690

	dc.l	$48EB30C0
	dc.l	$FFF09481
	dc.l	$6E00FF6A

	dc.l	$700041EF
	dc.l	$00207200
	dc.l	$4CD7001C
	dc.l	$22587A01
	dc.l	$7CC02050
	dc.l	$4EAEFDD8
	dc.l	$4CDF3FFF
	dc.l	$20024E75
.writepixelarray8_END

	PATCH	initarea
	dc.l	$20C9C0FC
	dc.l	$000420C9
	dc.l	$D3C0E488
	dc.l	$20C920C9
	dc.l	$20806002
	dc.l	$421951C8
	dc.l	$FFFC4E75
.initarea_END

	PATCH	a4000scsidev
	dc.w	$48E7,$3F3C
	dc.w	$7C00

	dc.w	$42A7
	dc.w	$4FEF,$FFC0
	dc.w	$2A4F

	dc.w	$43FA,$0000
	dc.w	$4EAE,$FE0E
	dc.w	$4A80
	dc.w	$6708
	dc.w	$2A8E
	dc.w	$2C40
	dc.w	$6100,$0000

	dc.w	$49F9,$00DD,$2020
	dc.w	$7000
	dc.w	$6100,$0000
	dc.w	$4FEF,$0044
;;	dc.w	$4A80
	dc.w	$6700,$0000

	dc.w	$2A2E,$0114

	dc.w	$7006
	dc.w	$4EAE,$FCD6

	dc.w	$2C40
	dc.w	$4EAE,$FFD0
	dc.w	$2C78,$0004
.a4000scsidev_END


.errh	dc.b	'romfixes: couldn''t %s!',10,0

.nocon	dc.b	'find '
.conname	dc.b	'console.device',0
.badcon	dc.b	'patch console.device bug',0

.nodos	dc.b	'find '
.dosname	dc.b	'dos.library',0
.badram	dc.b	'patch ram disk stack size',0

.noramlib	dc.b	'find '
.ramlibname	dc.b	'ramlib',0
.badramlib	dc.b	'patch ramlib stack size',0
.badramlib_b	dc.b	'patch ramlib msgport sigbit',0

.noshell	dc.b	'find '
.shellname	dc.b	'shell',0
.badresident	dc.b	'patch Resident bug',0

.noexec	dc.b	'find '
.execname	dc.b	'exec.library',0
.noalert	dc.b	'patch exec/Alert() bug',0
.nofreepooled	dc.b	'patch exec/FreePooled() bug',0
.noreleasesemaphore
	dc.b	'patch exec/ReleaseSemaphore() bug',0

.nogfx	dc.b	'find '
.gfxname	dc.b	'graphics.library',0
.badwcp	dc.b	'patch graphics/WriteChunkyPixels() bug',0
.badwpa8	dc.b	'patch graphics/WritePixelArray8() & WritePixelLine8() bug',0
.badinitarea	dc.b	'patch graphics/InitArea() bug',0

.noutil	dc.b	'find '
.utilname	dc.b	'utility.library',0
.noumult64	dc.b	'patch utility/UMult64() bug',0

.noscsi	dc.b	'find '
.scsiname	dc.b	'scsi.device',0
.noscsiinit	dc.b	'patch A4000 scsi.device init bug',0

	CNOP	0,2
regs
rom_size	ds.l	1
rom_phys	ds.l	1
rom_log	ds.l	1
findresident	ds.l	1
installmodule	ds.l	1
printf	ds.l	1

	SECTION	VERSION,DATA

	dc.b	'$VER: romfixes_PATCH 1.9 (22.3.02)',0


	IFGT	0

	; shell/Resident bug
	; ------------------


	; fixed, 2nd try

.no_REM	move.l	a2,d0			;200A

	beq.b	.no_filepart		;671C
	tst.l	(-$0030,a5)		;4AADFFD0
	bne.b	.is_ADD			;6624
	move.l	a3,d0			;200B
	beq.b	.is_ADD			;6720
	move.l	(4,a3),d0		;202B0004
	bpl.b	.no_filepart		;6A0C
	cmp.l	#-999,d0		;0C80FFFFFC19
	bgt.b	.is_ADD			;6E12
	bra.b	.no_filepart		;6002
	dc.w	$C0DE			;C0DE
.no_filepart	tst.l	(-$002C,a5)		;4AADFFD4	REPLACE/S
	bne.w	.da_err			;660000B0
	subq.l	#1,d0			;5380

	ble.w	.da_err			;6F0000AA
.is_ADD	move.l	(-$0028,a5),d0		;202DFFD8	PURE/S



	; rom 39.106:

.no_REM	move.l	a2,d0			;200A

	beq.b	.no_filepart		;6716
	tst.l	(-$0030,a5)		;4AADFFD0
	bne.b	.is_ADD			;6624
	move.l	(4,a3),d0		;202B0004	;BUG! should test if a3=0 before!
	tst.l	d0			;4A80
	bpl.b	.no_filepart		;6A08
	cmp.l	#-999,d0		;0C80FFFFFC19
	bgt.b	.is_ADD			;6E14
.no_filepart	tst.l	(-$002C,a5)		;4AADFFD4	;REPLACE/S
	bne.w	.da_err			;660000B6
	cmp.l	#1,(4,a3)		;0CAB000000010004

	ble.w	.da_err			;6F0000AA
.is_ADD	move.l	(-$0028,a5),d0		;202DFFD8	;PURE/S



	; console.device bug
	; ------------------

	; fixed

	move.l	d7,-(sp)			;2F07
	lea	($126E,a6),a0			;41EE126E
	move.l	a6,-(sp)			;2F0E
	move.l	($0030,a6),a6			;2C6E0030
	jsr	(_LVOObtainSemaphore,a6)	;4EAEFDCC

	move.l	(sp),a6				;2C57
	lea	($0082,a6),a2			;45EE0082
	bra.b	.in				;6002
.loop	bsr.b	cd_processwindow		;614A
.in	move.l	(a2),a2				;2452
	tst.l	(a2)				;4A92
	bne.b	.loop				;66F8
	lea	($126E,a6),a0			;41EE126E

	move.l	($0030,a6),a6			;2C6E0030
	jsr	(_LVOReleaseSemaphore,a6)	;4EAEFDC6
	move.l	(sp)+,a6			;2C5F
	move.l	(sp)+,d7			;2E1F


	; rom 37.300:

	move.l	d7,-(sp)			;2F07	;start here:
	lea	($126E,a6),a0			;41EE126E
	move.l	a6,-(sp)			;2F0E
	move.l	($0030,a6),a6			;2C6E0030
	jsr	(_LVOObtainSemaphore,a6)	;4EAEFDCC

	move.l	(sp)+,a6			;2C5F
	lea	($0082,a6),a2			;45EE0082	;BUG: the console.device bug
.loop	bsr.b	cd_processwindow		;614C
	move.l	(a2),a2				;2452
	tst.l	(a2)				;4A92
	bne.b	.loop				;66F8
	lea	($126E,a6),a0			;41EE126E
	move.l	a6,-(sp)			;2F0E

	move.l	($0030,a6),a6			;2C6E0030
	jsr	(_LVOReleaseSemaphore,a6)	;4EAEFDC6
	move.l	(sp)+,a6			;2C5F
	move.l	(sp)+,d7			;2E1F


	; rom 40.68:

	move.l	d7,-(sp)			;2F07
	lea	($126E,a6),a0			;41EE126E
	move.l	a6,-(sp)			;2F0E
	move.l	($0030,a6),a6			;2C6E0030
	jsr	(_LVOObtainSemaphore,a6)	;4EAEFDCC

	move.l	(sp)+,a6			;2C5F
	lea	($0082,a6),a2			;45EE0082
.loop	bsr.b	cd_processwindow		;614C
	move.l	(a2),a2				;2452
	tst.l	(a2)				;4A92
	bne.b	.loop				;66F8
	lea	($126E,a6),a0			;41EE126E
	move.l	a6,-(sp)			;2F0E

	move.l	($0030,a6),a6			;2C6E0030
	jsr	(_LVOReleaseSemaphore,a6)	;4EAEFDC6
	move.l	(sp)+,a6			;2C5F
	move.l	(sp)+,d7			;2E1F



	; graphics/WriteChunkyPixels() bug
	; --------------------------------

	; fixed

	movem.w	d0/d1,-(sp)		;48A7C000	;4    {xstart, ystart}
	movem.l	a0/a2/a6,-(sp)		;48E700A2	;8    {rp, array, gfxbase} ***mod! -2
	move.l	a0,a1			;2248		;a1 = rp
	pea	(writechunkypixels_hook,pc) ;487A0022	;20	***mod! offs + 2
	subq.l	#8,sp			;518F		;28	***mod! - 2
	move.l	sp,a0			;204F		;a0 = hook
	movem.w	d0-d3,-(sp)		;48A7F000	;36   {xstart, ystart, xstop, ystop}
	move.l	sp,a2			;244F		;a2 = rect
	move.l	d4,-(sp)		;2F04		;40   bytesperrow
	move.l	(gb_LayersBase,a6),a6	;2C6E01C8
	jsr	(_LVODoHookClipRects,a6);4EAEFF28
	lea	(36-8,sp),sp		;4FEF001C
	movem.l	(sp)+,a2/a6		;4CDF4400	;***mod! + 2
	addq.l	#4,sp			;588F		;***mod! + 2
	rts				;4E75
writechunkypixels_hook


	; original (ROM 40.068_A1200)

	movem.w	d0/d1,-(sp)		;48A7C000	;4    {xstart, ystart}
	move.l	a6,-(sp)		;2F0E		;8    gfxbase
	move.l	a2,-(sp)		;2F0A		;12   array
	move.l	a0,-(sp)		;2F08		;16   rp
	move.l	a0,a1			;2248		;a1 = rp
	pea	(writechunkypixels_hook,pc) ;487A0020	;20
	lea	(-8,sp),sp		;4FEFFFF8	;28
	move.l	sp,a0			;204F		;a0 = hook
	movem.w	d0-d3,-(sp)		;48A7F000	;36   {xstart, ystart, xstop, ystop}
	move.l	sp,a2			;244F		;a2 = rect
	move.l	d4,-(sp)		;2F04		;40   bytesperrow
	move.l	(gb_LayersBase,a6),a6	;2C6E01C8
	jsr	(_LVODoHookClipRects,a6);4EAEFF28
	lea	(36,sp),sp		;4FEF0024
	move.l	(sp)+,a6		;2C5F
	rts				;4E75
writechunkypixels_hook

	; exec/FreePooled() bug
	; ---------------------

	; fixed (SetPatch)

_FreePooled	move.l	a0,d1		;2208
	beq.b	.exit		;675E
	move.l	a1,d1		;2209
	beq.b	.exit		;675A
	cmp.l	($0014,a0),d0	;B0A80014
	bcc.b	.big_free	;6456
	move.l	a3,-(sp)	;2F0B
	move.l	(a0),d1		;2210
.findmem	move.l	d1,a3		;2641
	move.l	(a3),d1		;2213
	beq.b	.nomem		;6762
	tst.l	(LN_TYPE,a3)	;4AAB0008
	beq.b	.nomem		;675C
	cmp.l	(MH_LOWER,a3),a1 ;B3EB0014
	bcs.b	.findmem	;65EE
	cmp.l	(MH_UPPER,a3),a1 ;B3EB0018
	bcc.b	.findmem	;64E8
	move.l	a3,a0		;204B
	jsr	(_LVODeallocate,a6) ;4EAEFF40
	move.l	(LN_PRED,a3),a1	;226B0004
	move.l	(LN_PRED,a1),d1	;22290004
	beq.b	.nope		;6716
	move.l	d1,a0		;2041
	move.l	a3,(a0)		;208B
	move.l	a0,(LN_PRED,a3)	;27480004
	move.l	a3,(LN_PRED,a1)	;234B0004
	move.l	(a3),a0		;2053
	move.l	a0,(a1)		;2288
	move.l	a1,(LN_PRED,a0)	;21490004
	move.l	a1,(a3)		;2689
.nope	move.l	a3,a1		;224B
	move.l	(sp)+,a3	;265F
	move.l	(MH_FREE,a1),d0	;2029001C	** fixed **
	add.l	(MH_LOWER,a1),d0 ;D0A90014
	sub.l	(MH_UPPER,a1),d0 ;90A90018
	beq.b	.free		;6706
.exit	rts			;4E75

.big_free	subq.l	#4,a1		;5989
	subq.l	#8,a1		;5189
.free	move.l	a1,d0		;2009
	move.l	(a1)+,a0	;2059
	move.l	(a1),a1		;2251
	move.l	a0,(a1)		;2288
	move.l	a1,(4,a0)	;21490004
	move.l	d0,a1		;2240
	jmp	(_LVOFreeVec,a6) ;4EEEFD4E

.nomem	move.l	(sp)+,a3	;265F
	move.l	d7,-(sp)	;2F07
	move.l	#$0100000F,d7	;2E3C0100000F
	jsr	(_LVOAlert,a6)	;4EAEFF94
	move.l	(sp)+,d7	;2E1F
	rts			;4E75


	; original (ROM39.106_A1200)

_LVOFreePooled	move.l	a0,d1		;2208
	beq.b	.exit		;675E
	move.l	a1,d1		;2209
	beq.b	.exit		;675A
	cmp.l	($0014,a0),d0	;B0A80014
	bcc.b	.big_free	;6456
	move.l	a3,-(sp)	;2F0B
	move.l	(a0),d1		;2210
.findmem	move.l	d1,a3		;2641
	move.l	(a3),d1		;2213
	beq.b	.nomem		;6762
	tst.l	(LN_TYPE,a3)	;4AAB0008
	beq.b	.nomem		;675C
	cmp.l	(MH_LOWER,a3),a1 ;B3EB0014
	bcs.b	.findmem	;65EE
	cmp.l	(MH_UPPER,a3),a1 ;B3EB0018
	bcc.b	.findmem	;64E8
	move.l	a3,a0		;204B
	bsr.w	_LVODeallocate	;6100F996
	move.l	(LN_PRED,a3),a1	;226B0004
	move.l	(LN_PRED,a1),d1	;22290004
	beq.b	.nope		;6716
	move.l	d1,a0		;2041
	move.l	a3,(a0)		;208B
	move.l	a0,(LN_PRED,a3)	;27480004
	move.l	a3,(LN_PRED,a1)	;234B0004
	move.l	(a3),a0		;2053
	move.l	a0,(a1)		;2288
	move.l	a1,(LN_PRED,a0)	;21490004
	move.l	a1,(a3)		;2689
.nope	move.l	a3,a1		;224B
	move.l	(sp)+,a3	;265F
	move.l	(MH_SIZE,a1),d0	;20290020	** bug, should be MH_FREE **
	add.l	(MH_LOWER,a1),d0 ;D0A90014
	sub.l	(MH_UPPER,a1),d0 ;90A90018
	beq.b	.free		;6706
.exit	rts			;4E75

.big_free	subq.l	#4,a1		;5989
	subq.l	#8,a1		;5189
.free	move.l	a1,d0		;2009
	move.l	(a1)+,a0	;2059
	move.l	(a1),a1		;2251
	move.l	a0,(a1)		;2288
	move.l	a1,(4,a0)	;21490004
	move.l	d0,a1		;2240
	jmp	(_LVOFreeVec,a6) ;4EEEFD4E

.nomem	move.l	(sp)+,a3	;265F
	move.l	d7,-(sp)	;2F07
	move.l	#$0100000F,d7	;2E3C0100000F
	jsr	(_LVOAlert,a6)	;4EAEFF94
	move.l	(sp)+,d7	;2E1F
	rts			;4E75


	; graphics/WritePuxelArray8 & WritePixelLine8 bug
	; -----------------------------------------------

	; fixed


	include	"exec/libraries.i"
	include	"graphics/gfx.i"
	include	"graphics/rastport.i"
	include	"graphics/graphics_lib.i"

WritePixelArray8
	movem.l	d2-d7/a2-a4,-(sp) ;48E73F38
	sub.w	d0,d2		;9440
	ext.l	d2		;48C2
	addq.l	#1,d2		;5282
	move.l	d2,d4		;2802
	add.w	#15,d4		;D87C000F		addi.w	#15,d4		;0644000F
	moveq	#-1,d6		;7CFF
	and.w	#-16,d4		;C87CFFF0		andi.w	#-16,d4		;0244FFF0
	ble.b	.exit2		;6F2A
	move.l	d0,d7		;2E00
	move.l	d1,d5		;2A01
	sub.w	d1,d3		;9641
	ext.l	d3		;48C3
	addq.l	#1,d3		;5283
	ble.b	.exit2		;6F1E
	moveq	#0,d6		;7C00
	move.l	a0,a3		;2648
	move.l	a1,a4		;2849

.dolines	move.l	a3,a0		;204B
	move.l	d7,d0		;2007
	move.l	d5,d1		;2205
	move.l	a4,a1		;224C
	bsr.b	_writepixelline8 ;6122
	addq.l	#1,d5		;5285
	add.l	d4,a2		;D5C4
	add.l	d0,d6		;DC80
	subq.l	#1,d3		;5383
	bne.b	.dolines	;66EC

	jsr	(_LVOWaitBlit,a6) ;4EAEFF1C
.exit2	move.l	d6,d0		;2006
.exit	movem.l	(sp)+,d2-d7/a2-a4 ;4CDF1CFC
	rts			;4E75

	dc.w	$4E71,$4E71,$4E71,$4E71
WritePixelLine8
	move.l	(_LVOWaitBlit+2,a6),-(sp) ;2F2EFF1E	+ 4

_writepixelline8
	movem.l	d0-d7/a0-a5,-(sp) ;48E7FFFC

	ext.l	d2		;48C2
	add.w	#15,d2		;D47C000F		addi.w	#15,d2		;0642000F
	and.w	#-16,d2		;C47CFFF0		andi.w	#-16,d2		;0242FFF0
	moveq	#16,d1		;7210
	move.l	d2,d4		;2802
	jsr	(_LVOWaitBlit,a6) ;4EAEFF1C

.oloop	move.l	(9*4,sp),a0	;206F0024		a1 (temprp) from stack
	move.l	d4,d3		;2604
	move.l	(rp_BitMap,a0),a0 ;20680004		move.l	(rp_BitMap,a1),a3 ;26690004
	sub.l	d2,d3		;9682
	move.b	(bm_Depth,a0),d0 ;1028 0005		move.b	(bm_Depth,a3),d0 ;102B0005
	lea	(a2,d3.l),a3	;47F23800
	addq.l	#bm_Planes,a0	;5088			lea	(bm_Planes,a3),a0 ;41EB0008
	lsr.l	#3,d3		;E68B
	movem.l	(a3)+,d6/d7/a4/a5 ;4CDB30C0

.iloop	move.l	(a0)+,a1	;2258
	moveq	#0,d5		;7A00
	add.l	d3,a1		;D3C3			lea	(a1,d3.l),a1	;43F13800
	move.b	-(a3),d5	;1A23
	ror.l	#1,d5		;E29D
	move.b	d5,(a3)		;1685
	move.b	-(a3),d5	;1A23
	ror.l	#1,d5		;E29D
	move.b	d5,(a3)		;1685
	move.b	-(a3),d5	;1A23
	ror.l	#1,d5		;E29D
	move.b	d5,(a3)		;1685
	move.b	-(a3),d5	;1A23
	ror.l	#1,d5		;E29D
	move.b	d5,(a3)		;1685
	move.b	-(a3),d5	;1A23
	ror.l	#1,d5		;E29D
	move.b	d5,(a3)		;1685
	move.b	-(a3),d5	;1A23
	ror.l	#1,d5		;E29D
	move.b	d5,(a3)		;1685
	move.b	-(a3),d5	;1A23
	ror.l	#1,d5		;E29D
	move.b	d5,(a3)		;1685
	move.b	-(a3),d5	;1A23
	ror.l	#1,d5		;E29D
	move.b	d5,(a3)		;1685
	move.b	-(a3),d5	;1A23
	ror.l	#1,d5		;E29D
	move.b	d5,(a3)		;1685
	move.b	-(a3),d5	;1A23
	ror.l	#1,d5		;E29D
	move.b	d5,(a3)		;1685
	move.b	-(a3),d5	;1A23
	ror.l	#1,d5		;E29D
	move.b	d5,(a3)		;1685
	move.b	-(a3),d5	;1A23
	ror.l	#1,d5		;E29D
	move.b	d5,(a3)		;1685
	move.b	-(a3),d5	;1A23
	ror.l	#1,d5		;E29D
	move.b	d5,(a3)		;1685
	move.b	-(a3),d5	;1A23
	ror.l	#1,d5		;E29D
	move.b	d5,(a3)		;1685
	move.b	-(a3),d5	;1A23
	ror.l	#1,d5		;E29D
	move.b	d5,(a3)		;1685
	move.b	-(a3),d5	;1A23
	ror.l	#1,d5		;E29D
	move.b	d5,(a3)		;1685
	rol.l	d1,d5		;E3BD
	add.l	d1,a3		;D7C1
	move.w	d5,(a1)+	;32C5
	subq.b	#1,d0		;5300
	bne.b	.iloop		;668E

	movem.l	d6/d7/a4/a5,(-16,a3) ;48EB30C0FFF0

	sub.l	d1,d2		;9481
	bgt	.oloop		;6E00FF76

	moveq	#0,d0		;7000
	lea	(8*4,sp),a0	;41EF0020	; a0 & a1 from stack
	moveq	#0,d1		;7200
	movem.l	(sp),d2-d4	;4CD7001C
	move.l	(a0)+,a1	;2258		; a1 = rp
	moveq	#1,d5		;7A01
	moveq	#-$40,d6	;7CC0		; d6 = $ffffffc0
	move.l	(a0),a0		;2050		; a0 = temprp
	jsr	(_LVOClipBlit,a6) ;4EAEFDD8

	movem.l	(sp)+,d0-d7/a0-a5 ;4CDF3FFF
	move.l	d2,d0		;2002
	rts			;4E75


	; original (ROM 40.068_A1200)

	include	"exec/libraries.i"
	include	"graphics/gfx.i"
	include	"graphics/rastport.i"
	include	"graphics/graphics_lib.i"

__LVOWritePixelArray8
	movem.l	d2-d7/a2-a4,-(sp) ;48E73F38
	sub.w	d0,d2		;9440
	ext.l	d2		;48C2
	addq.l	#1,d2		;5282
	move.l	d2,d4		;2802
	add.w	#15,d4		;D87C000F
	and.w	#$FFF0,d4	;C87CFFF0
	ble.b	.error		;6F34
	move.l	d0,d7		;2E00
	move.l	d1,d5		;2A01
	sub.w	d1,d3		;9641
	ext.l	d3		;48C3
	addq.l	#1,d3		;5283
	ble.b	.error		;6F28
	move.l	a0,a3		;2648
	move.l	a1,a4		;2849
	moveq	#0,d6		;7C00
	bra.b	.goloop		;6014

.dolines	move.l	a3,a0		;204B
	move.l	d7,d0		;2007
	move.l	d5,d1		;2205
	move.l	a4,a1		;224C
	jsr	(__LVOWritePixelLine8).l ;4EB900F85F3A
	addq.l	#1,d5		;5285
	add.l	d4,a2		;D5C4
	add.l	d0,d6		;DC80
.goloop	dbra	d3,.dolines	;51CBFFEA
	move.l	d6,d0		;2006
	movem.l	(sp)+,d2-d7/a2-a4 ;4CDF1CFC
	rts			;4E75

.error	moveq	#-1,d0		;70FF
	movem.l	(sp)+,d2-d7/a2-a4 ;4CDF1CFC
	rts			;4E75

__LVOWritePixelLine8
	movem.l	d0-d7/a0-a5,-(sp) ;48E7FFFC
	move.l	(rp_BitMap,a1),a3 ;26690004
	moveq	#0,d1		;7200
	move.b	(bm_Depth,a3),d1 ;122B0005
	lsl.w	#2,d1		;E549
	lea	(bm_Planes,a3),a0 ;41EB0008
	ext.l	d2		;48C2
	add.w	#15,d2		;D47C000F
	and.w	#-16,d2		;C47CFFF0
	move.l	d2,d4		;2802
.oloop	move.l	d4,d3		;2604
	sub.l	d2,d3		;9682
	lea	(16,a2,d3.l),a3 ;47F23810
	lsr.l	#3,d3		;E68B
	move.l	(a3),d6		;2C13
	move.l	(4,a3),d7	;2E2B0004
	move.l	(8,a3),a4	;286B0008
	move.l	(12,a3),a5	;2A6B000C
	moveq	#0,d0		;7000
.iloop	move.l	(a0,d0.w),a1	;22700000
	lea	(a1,d3.l),a1	;43F13800
	moveq	#0,d5		;7A00
	move.b	-(a3),d5	;1A23
	ror.l	#1,d5		;E29D
	move.b	d5,(a3)		;1685
	move.b	-(a3),d5	;1A23
	ror.l	#1,d5		;E29D
	move.b	d5,(a3)		;1685
	move.b	-(a3),d5	;1A23
	ror.l	#1,d5		;E29D
	move.b	d5,(a3)		;1685
	move.b	-(a3),d5	;1A23
	ror.l	#1,d5		;E29D
	move.b	d5,(a3)		;1685
	move.b	-(a3),d5	;1A23
	ror.l	#1,d5		;E29D
	move.b	d5,(a3)		;1685
	move.b	-(a3),d5	;1A23
	ror.l	#1,d5		;E29D
	move.b	d5,(a3)		;1685
	move.b	-(a3),d5	;1A23
	ror.l	#1,d5		;E29D
	move.b	d5,(a3)		;1685
	move.b	-(a3),d5	;1A23
	ror.l	#1,d5		;E29D
	move.b	d5,(a3)		;1685
	move.b	-(a3),d5	;1A23
	ror.l	#1,d5		;E29D
	move.b	d5,(a3)		;1685
	move.b	-(a3),d5	;1A23
	ror.l	#1,d5		;E29D
	move.b	d5,(a3)		;1685
	move.b	-(a3),d5	;1A23
	ror.l	#1,d5		;E29D
	move.b	d5,(a3)		;1685
	move.b	-(a3),d5	;1A23
	ror.l	#1,d5		;E29D
	move.b	d5,(a3)		;1685
	move.b	-(a3),d5	;1A23
	ror.l	#1,d5		;E29D
	move.b	d5,(a3)		;1685
	move.b	-(a3),d5	;1A23
	ror.l	#1,d5		;E29D
	move.b	d5,(a3)		;1685
	move.b	-(a3),d5	;1A23
	ror.l	#1,d5		;E29D
	move.b	d5,(a3)		;1685
	move.b	-(a3),d5	;1A23
	ror.l	#1,d5		;E29D
	move.b	d5,(a3)		;1685
	lea	(16,a3),a3	;47EB0010
	swap	d5		;4845
	move.w	d5,(a1)+	;32C5
	addq.b	#4,d0		;5800
	cmp.b	d0,d1		;B200
	bgt.b	.iloop		;6E88
	move.l	d6,(a3)		;2686
	move.l	d7,(4,a3)	;27470004
	move.l	a4,(8,a3)	;274C0008
	move.l	a5,(12,a3)	;274D000C
	subq.l	#8,d2		;5182
	subq.l	#8,d2		;5182
	bgt.w	.oloop		;6E00FF5A
	moveq	#0,d0		;7000
	moveq	#0,d1		;7200
	movem.l	(sp),d2-d4	;4CD7001C
	moveq	#1,d5		;7A01
	moveq	#3,d6		;7C03
	rol.l	#6,d6		;ED9E
	movem.l	(32,sp),a0/a1	;4CEF03000020
	exg	a0,a1		;C149
	jsr	(_LVOClipBlit,a6) ;4EAEFDD8
	jsr	(_LVOWaitBlit,a6) ;4EAEFF1C
	movem.l	(sp)+,d0-d7/a0-a5 ;4CDF3FFF
	move.l	d2,d0		;2002
	rts			;4E75



	; exec/ReleaseSemaphore bug
	; -------------------------

	; fixed

.mloop	move.l	a2,($0014,a1)	;234A0014
	addq.w	#1,(14,a2)	;526A000E
	jsr	(_LVOReplyMsg,a6) ;4EAEFE86
	move.l	($0028,a2),d1	;222A0028
.iloop	move.l	(a3),d0		;2013
	beq.b	lbC002E44	;67DA
	move.l	a3,a1		;224B
	move.l	d0,a3		;2640
	move.l	(8,a1),d0	;20290008
	beq.b	.nuller		;6712
	cmp.l	d0,d1		;B280
	bne.b	.iloop		;66EE
	move.l	(4,a1),a0	;20690004
	move.l	a3,(a0)		;208B
	move.l	a0,(4,a3)	;27480004
	move.l	d1,a1		;2241
	bra.b	lbC002E3A	;60B4

.nuller	cmp.l	($0014,a1),d1	;B2A90014
	bne.b	.iloop		;66DA
	move.l	(4,a1),a0	;20690004
	move.l	a3,(a0)		;208B
	move.l	a0,(4,a3)	;27480004
	bra.b	.mloop		;60B6


	; original (ROM 39.106_A1200)

.mloop	move.l	a2,($0014,a1)	;234A0014
	addq.w	#1,(14,a2)	;526A000E
	jsr	(_LVOReplyMsg,a6) ;4EAEFE86
	move.l	($0028,a2),d1	;222A0028
.iloop	move.l	(a3),d0		;2013
	beq.b	lbC002E44	;67DA
	move.l	a3,a1		;224B
	move.l	d0,a3		;2640
	move.l	(8,a1),d0	;20290008
	beq.b	.nuller		;6712
	cmp.l	d0,d1		;B280
	bne.b	.iloop		;66EE
	move.l	(4,a1),a0	;20690004
	move.l	a3,(a0)		;208B
	move.l	a0,(4,a3)	;27480004
	move.l	d1,a1		;2241
	bra.b	lbC002E3A	;60B4

.nuller	cmp.l	($0014,a1),d1	;B2A90014
	bne.b	.iloop		;66DA
	move.l	(4,a1),a0	;20690004
	move.l	a3,(a0)		;208B
	move.l	a0,(4,a3)	;27480004
	addq.w	#1,(14,a2)	;526A000E
	bra.b	.mloop		;60BA


	; utility/UMult64 bug
	; -------------------

	; fixed

_LVOUMult64	movem.l	d2-d4,-(sp)	;48E73800
	move.l	d1,d3		;2601
	mulu	d0,d3		;C6C0
	move.l	d1,d2		;2401
	swap	d2		;4842
	swap	d0		;4840
	mulu	d0,d2		;C4C0
	swap	d3		;4843
	move.l	d1,d4		;2801
	mulu	d0,d4		;C8C0
	add.w	d4,d3		;D644
	clr.w	d4		;4244
	swap	d4		;4844
	addx.l	d4,d2		;D584
	swap	d0		;4840
	swap	d1		;4841
	move.l	d1,d4		;2801
	mulu	d0,d4		;C8C0
	add.w	d4,d3		;D644
	clr.w	d4		;4244
	swap	d4		;4844
	addx.l	d4,d2		;D584
	swap	d3		;4843
	move.l	d2,d0		;2202		; ***
	move.l	d3,d1		;2003		; ***
	movem.l	(sp)+,d2-d4	;4CDF001C
	rts			;4E75


	; original (ROM 39.106_A1200)

_LVOUMult64	movem.l	d2-d4,-(sp)	;48E73800
	move.l	d1,d3		;2601
	mulu	d0,d3		;C6C0
	move.l	d1,d2		;2401
	swap	d2		;4842
	swap	d0		;4840
	mulu	d0,d2		;C4C0
	swap	d3		;4843
	move.l	d1,d4		;2801
	mulu	d0,d4		;C8C0
	add.w	d4,d3		;D644
	clr.w	d4		;4244
	swap	d4		;4844
	addx.l	d4,d2		;D584
	swap	d0		;4840
	swap	d1		;4841
	move.l	d1,d4		;2801
	mulu	d0,d4		;C8C0
	add.w	d4,d3		;D644
	clr.w	d4		;4244
	swap	d4		;4844
	addx.l	d4,d2		;D584
	swap	d3		;4843
	move.l	d2,d0		;2002
	move.l	d3,d1		;2203
	movem.l	(sp)+,d2-d4	;4CDF001C
	rts			;4E75




	; A4000 scsi.device initcode bug
	; ------------------------------

	; fixed

scsi_initcode	movem.l	d2-d7/a2-a5,-(sp)	;48E73F3C
	moveq	#0,d6			;7C00

	clr.l	-(sp)			;42A7		null by default
	lea	(-$40,sp),sp		;4FEFFFC0
	move.l	sp,a5			;2A4F

	lea	(battmemname,pc),a1	;43FAxxxx	try to open battmem.resource
	jsr	(_LVOOpenResource,a6)	;4EAEFE0E
	tst.l	d0			;4A80
	beq.b	.nobattres		;6708
	move.l	a6,(a5)			;2A8E		read the 2nd drive flag
	move.l	d0,a6			;2C40
	bsr.w	read_battmem		;6100xxxx
.nobattres
	lea	($00DD2020),a4		;49F900DD2020
	moveq	#0,d0			;7000
	bsr.w	scsi_probescsi		;6100xxxx
	lea	($44,sp),sp		;4FEF0044	release stack storage
;;	tst.l	d0			;4A80
	beq.w	.exitnull		;6700xxxx

	move.l	(ThisTask,a6),d5	;2A2E0114

	moveq	#6,d0			;7006
	jsr	(_LVOexecPrivate14,a6)	;4EAEFCD6

	move.l	d0,a6			;2C40
	jsr	(_LVAllocConfigDev,a6)	;4EAEFFD0
	move.l	(4).l,a6		;2C780004


	; original (ROM 40.68_A4000)

scsi_initcode	movem.l	d2-d7/a2-a5,-(sp)	;48E73F3C
	sub.l	a1,a1			;93C9
	jsr	(_LVOFindTask,a6)	;4EAEFEDA
	move.l	d0,d5			;2A00

	moveq	#6,d0			;7006
	jsr	(_LVOexecPrivate14,a6)	;4EAEFCD6
	tst.l	d0			;4A80
	bne.b	.got			;660E
	move.l	#$14030000,d7		;2E3C14030000
	jsr	(_LVOAlert,a6)		;4EAEFF94
	bra.w	.exitnull		;6000012E
.got
	moveq	#0,d6			;7C00
	lea	($00DD2020),a4		;49F900DD2020
	move.l	d0,-(sp)		;2F00
	moveq	#0,d0			;7000
	bsr.w	scsi_probescsi		;61002102
	move.l	d0,d1			;2200
	move.l	(sp)+,d0		;201F
	tst.l	d1			;4A81
	beq.w	.exitnull		;67000114

	move.l	d0,a6			;2C40 		34
	jsr	(_LVAllocConfigDev,a6)	;4EAEFFD0
	move.l	(4).l,a6		;2C7900000004


	; exec/CheckIO() BOOL return code "bug"
	; -------------------------------------

; - exec/CheckIO BOOL return code fix. SetPatch has a workaround for this,
;   but again better have this fixed in ROM already.
;  (this one is disable because of potential compatibility problems)

	; fixed

_LVOCheckIO	btst	#IOB_QUICK,(IO_FLAGS,a1);08290000001E
	bne.b	.ready			;660C
	cmp.b	#NT_REPLYMSG,(MN+LN_TYPE,a1) ;0C2900070008
	beq.b	.ready			;6704
	moveq	#0,d0			;7000
	rts				;4E75
.ready	moveq	#1,d0			;7001
	rts				;4E75


	; original (ROM 39.106_A1200)

_LVOCheckIO	btst	#IOB_QUICK,(IO_FLAGS,a1);08290000001E
	bne.b	.ready			;660C
	cmp.b	#NT_REPLYMSG,(MN+LN_TYPE,a1) ;0C2900070008
	beq.b	.ready			;6704
	moveq	#0,d0			;7000
	rts				;4E75
.ready	move.l	a1,d0			;2009
	rts				;4E75


	; graphics/InitArea() bug
	; -----------------------

	; fixed
_LVOInitArea
	move.l	a1,(a0)+		; 2 ai_VctrTbl
	mulu.w	#4,d0			; 4 get ptr to	note: mulu.w fill whole longword!
	move.l	a1,(a0)+		; 2 ai_VctrPtr
	adda.l	d0,a1			; 2 FlagTbl
	lsr.l	#2,d0			; 2 get original count
	move.l	a1,(a0)+		; 2 ai_FlagTbl
	move.l	a1,(a0)+		; 2 ai_FlagPtr
	move.l	d0,(a0)			; 2 ai_Count (=0) & ai_MaxCount
	bra.b	.goclr			; 2 clear the FlagTbl
.clr	clr.b	(a1)+			; 2
.goclr	dbf	d0,.clr			; 4
	rts				; 2 = 28

	;original (ROM 40.68_A1200), graphics 40.24:
_LVOInitArea
	move.l	a1,(ai_VctrPtr,a0)	; 4
	move.l	a1,(a0)			; 2 ai_VctrTbl
	move.w	d0,(ai_MaxCount,a0)	; 4 
	asl.w	#2,d0			; 2 get ptr to	note: because of below, limit d0 to 8191
	adda.w	d0,a1			; 2 GlagTbl	note: adda.w is signed, limit d0 to <32768
	move.l	a1,(ai_FlagPtr,a0)	; 4 
	move.l	a1,(ai_FlagTbl,a0)	; 4 
	clr.w	(ai_Count,a0)		; 4 
	rts				; 2 = 28

	ENDC
