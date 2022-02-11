-> FILE: ESrc:Own/applypatch.e          REV: 9 --- apply BlizKick patch module to rom
/* History
   0      started 11th Dec 1999.
   1      works.
   2      12th Dec: added SPEEDROM
   3      added HOGWAITBLIT
   4      added test for <>$f80000 rom
   5      no longer requires MODULES arg, now tests if any patches
          was applied.
   6      27th Mar 2000: added elfloadseg-patch ioerr bug workaround.
   7      12th Oct 2000: fixed small bug in SPEEDROM: the RT_END of the last
          ROMTag was made to point to $fffffe. Due some funny side effect
          ($1000000 - $fffffe) / 2 - 1 = 0) it caused the ROM's ROMTag scanner
          access longword at $fffffe, thus accessing non-existent memory.
          (maybe this was it Gunther... :-)
   8      31st Jan 2001: Now default to 'DEVS:Modules/' dir if BKMODPATH
          env variable cannot be found. Added IGNPATH option for completeness.
   9      11th Jan 2003: Fixed the wrong errormsg when kickfile doesn't exist.
*/

/*
  DESCRIPTION

    applypatch can be used to apply BlizKick "patch" kind of modules
    to rom image. Useful if BlizKick doesn't support your system for
    some reason, but you have a working maprom tool for it. applypatch
    can also be used to speed up BlizKick booting by pre-patching rom
    image. BlizKick commandline also gets quite a bit cleaner then. ;)


  FEATURES

  - support for all patch modules that don't try to add resident tags
  - includes HOGWAITBLIT patch of BlizKick
  - includes SPEEDROM patch of BlizKick (kicktag reconnect)


  RESTRICTIONS

  - works only with 512k ROM, 256K is obsolete really
  - requires about 520k memory for patching
  - for obvious reasons there is no undo :)


  NOTES

  - It's a fairly good idea to keep the original ROM images somewhere
    safe


  SAMPLE RUN

    > applypatch DEVS:rom40068.A1200 TO T:rom40068.A1200.patched HOGWAITBLIT \
      SPEEDROM NoClick FixMath404 SpeedyIDE PatchMath020 romfixes
    reading kickfile "DEVS:rom40068.A1200"...
    rom image ok, applying patches...
    applying hogwaitblit patch...
    applying NoClick patch...
    applying FixMath404 patch...
    applying SpeedyIDE patch...
    applying PatchMath020 patch...
    Patched DiceC Mulu routine at offset $27748
    applying romfixes patch...
    applying speedrom patch...

    ---- total 7 patches applied ----
    calculating new checksum for image... $04E7630B
    writing patched rom image to "T:rom40068.A1200.patched"...
    done.


  TODO

  - add support for non-EXTRESBUF InstallModule()
  - add support for non-EXTRESBUF modules


  AUTHOR & LEGAL CRAP

    applypatch is written by Harry "Piru" Sintonen 1999-2001.
    applypatch is public domain.

*/


OPT OSVERSION=33

MODULE 'exec/memory','dos/dos','dos/var'
MODULE 'hardware/dmabits'

ENUM ARG_KICKFILE,ARG_TO,ARG_MODULE,ARG_FORCE,ARG_SPEEDROM,
     ARG_HOGWAITBLIT,ARG_IGNPATH,NUMARGS

DEF progname[64]:STRING,array[NUMARGS]:ARRAY OF LONG,
    size=524288

PROC main()

  IF KickVersion(37)=0
    WriteF('get real! this program requires kickstart 2.04+\n')
    RETURN RETURN_FAIL
  ENDIF

  GetProgramName(progname,63); SetStr(progname,StrLen(progname))

ENDPROC main2()

PROC main2()
  DEF rdargs,r

  r:='$VER: applypatch 1.0.5 (11.1.03)'
  FOR r:=0 TO NUMARGS-1; array[r]:=0; ENDFOR
  IF (rdargs:=ReadArgs('FROM=KICKFILE/A,TO/K/A,MODULE/M,FORCE/S,' +
                       'SPEEDROM/S,HOGWAITBLIT/S,' +
                       'IGNPATH=IGNOREBKMODPATH/S',array,NIL))

    r:=main3(array[ARG_KICKFILE],array[ARG_MODULE])

    FreeArgs(rdargs)
  ELSE
    PrintFault(IoErr(),progname)
    r:=RETURN_ERROR
  ENDIF
ENDPROC r

ENUM ROMSUMOFFS=$7FFE8,ROMSIZEOFFS=$7FFEC,ROMIDOFFS=$7FFF0,
     BLIZKICK_ID="BlzK"

PROC main3(kickfile,modules:PTR TO LONG)
  DEF r,rom:PTR TO LONG,fh,sum,suc=0,err=0
  DEF modpath[256]:STRING,lock=NIL,olddir

  PrintF('reading kickfile "\s"...\n',kickfile)

  IF (fh:=Open(kickfile,MODE_OLDFILE))=NIL
    PrintFault(IoErr(),progname)
    PrintF('could not open kickfile "\s"\n',kickfile)
    RETURN RETURN_ERROR
  ENDIF

  IF FileLength(kickfile)<>size
    PrintF('kickfile "\s" length not \d\n',kickfile,size)
    Close(fh)
    RETURN RETURN_ERROR
  ENDIF

  IF (rom:=New(size))=0
    PrintFault(IoErr(),progname)
    Close(fh)
    PrintF('could not allocate \d bytes of memory\n',size)
    RETURN RETURN_ERROR
  ENDIF

  r:=Read(fh,rom,size); Close(fh); fh:=0
  IF r<>size
    PrintFault(IoErr(),progname)
    PrintF('error reading kickfile "\s"\n',kickfile)
    RETURN RETURN_ERROR
  ENDIF

  IF (Long(rom+ROMSIZEOFFS)<>size) OR
    ((rom[] AND $FFF8FFFF)<>$11104EF9)
    PrintF('bad rom image!\n')
    RETURN RETURN_ERROR
  ENDIF

  r:=Long(rom+4) AND $FFFF0000
  IF r<>$F80000
    PrintF('rom image not located at $00F80000, but $\h[08]!\n',r)
    RETURN RETURN_ERROR
  ENDIF

  IF (sum:=romresum(rom,size))<>Long(rom+ROMSUMOFFS)
    IF array[ARG_FORCE]
      PrintF('bad rom checksum $\h[08] should be $\h[08], overrided ' +
             'by FORCE/n',
             sum,Long(rom+ROMSUMOFFS))
    ELSE
      PrintF('bad rom checksum $\h[08] should be $\h[08], can be\n' +
             'overrided with FORCE switch\n',
             sum,Long(rom+ROMSUMOFFS))
      RETURN RETURN_ERROR
    ENDIF
  ENDIF

  IF Long(rom+ROMIDOFFS)=BLIZKICK_ID
    IF array[ARG_FORCE]
      PrintF('rom image has been used with BlizKick, but FORCE used\n')
    ELSE
      PrintF('rom image has been used with BlizKick before, can be\n' +
             'overrided with FORCE switch\n')
      RETURN RETURN_ERROR
    ENDIF
  ENDIF

  PrintF('rom image ok, applying patches...\n')

  -> apply hogwaitblit if enabled
  IF array[ARG_HOGWAITBLIT]
    PrintF('\e[1mapplying hogwaitblit patch...\e[22m\n')
    IF puthogwaitblit(rom,size)
      suc++
    ELSE
      err++
      PrintF('could not patch!\n')
    ENDIF
  ENDIF

  IF modules

    IF array[ARG_IGNPATH] = 0
      -> change dir to ENV:BKMODPATH or fallback to 'DEVS:Modules/'
      IF GetVar('BKMODPATH',modpath,256,GVF_GLOBAL_ONLY) = -1
        IF GetVar('ENVARC:BKMODPATH',modpath,256,GVF_GLOBAL_ONLY) = -1
          StrCopy(modpath, 'DEVS:Modules/')
        ENDIF
      ENDIF
      IF (lock:=Lock(modpath,ACCESS_READ))
        olddir:=CurrentDir(lock)
      ENDIF
    ENDIF

    -> process all modules

    WHILE modules[]
      PrintF('\e[1mapplying \s patch...\e[22m\n',modules[]); Flush(stdout)
      IF applypatch(modules[],rom,size) THEN suc++ ELSE err++
      modules++
    ENDWHILE

    -> back to orig dir

    IF lock
      CurrentDir(olddir)
      UnLock(lock); lock:=0
    ENDIF

  ENDIF

  -> apply speedrom, if enabled
  IF array[ARG_SPEEDROM]
    PrintF('\e[1mapplying speedrom patch...\e[22m\n')
    IF speedrom(rom,size)
      suc++
    ELSE
      err++
      PrintF('could not patch!\n')
    ENDIF
  ENDIF

  IF err
    PrintF('\n\d patch\s failed, output file "\s" not written\n',
           err,IF err=1 THEN '' ELSE 'es',array[ARG_TO])
  ELSE

    IF suc=0
      PrintF('\n---- total 0 patches applied ----\ndestination file "\s" not written!\n',
             array[ARG_TO])
    ELSE

      PrintF('\n---- total \d patch\s applied ----\ncalculating new checksum for image...',
             suc,IF suc=1 THEN '' ELSE 'es')

      -> resum rom

      PutLong(rom+ROMSUMOFFS,sum:=romresum(rom,size))

      PrintF(' $\h[08]\nwriting patched rom image to "\s"...\n',sum,array[ARG_TO])

      -> write rom

      IF (fh:=Open(array[ARG_TO],MODE_NEWFILE))=NIL
        PrintFault(IoErr(),progname)
        PrintF('could not open file "\s" for writing\n',array[ARG_TO])
        RETURN RETURN_ERROR
      ENDIF

      r:=Write(fh,rom,size); Close(fh); fh:=0
      IF r<>size
        PrintFault(IoErr(),progname)
        DeleteFile(array[ARG_TO])
        PrintF('error writing to "\s", destination file deleted\n',array[ARG_TO])
        RETURN RETURN_ERROR
      ENDIF
    ENDIF

  ENDIF

  PrintF('done.\n')

ENDPROC

PROC puthogwaitblit(rom,size)

  MOVEM.L D1-D7/A0-A6,-(A7)

  MOVE.L  rom,A0
  MOVE.L  size,D0

  MOVEQ   #0,D7

  CMP.W   #39,$C(A0)         -> Requires rom 39+
  BCS.B   phwb_exit

  LEA     -4(A0,D0.L),A1

  MOVE.L  #$08390006,D0
  phwb_find:
  ADDQ.L  #2,A0
  CMPA.L  A1,A0
  BEQ.B   phwb_exit
  CMP.L   (A0),D0
  BNE.B   phwb_find
  CMP.L   #$00DFF002,4(A0)
  BNE.B   phwb_find
  CMP.L   #$66024E75,8(A0)
  BNE.B   phwb_find

  CMP.L   #$08390006,-8(A0)  -> No KS 1.x!
  BEQ.B   phwb_exit
  CMP.L   #$4A3900DF,-6(A0)  -> KS 2.x/3.x:
  BNE.B   phwb_exit
  SUBQ.L  #6,A0
  LEA     phwb_waitblit(PC),A1
  MOVEQ   #21,D0             -> 42/2
  phwb_copy:
  MOVE.W  (A1)+,(A0)+
  SUBQ.L  #1,D0
  BNE.B   phwb_copy
  MOVEQ   #1,D7

  phwb_exit:
  MOVE.L  D7,D0
  MOVEM.L (A7)+,D1-D7/A0-A6
  RETURN  D0

  -> 3.0  48 bytes
  -> 3.1  48 bytes
  phwb_waitblit:
  BTST    #6,$DFF002         -> 8 DMAB_BLTDONE=14 dmaconr
  BNE.B   phwb_wb_gowait     -> 2
  RTS                        -> 2
  phwb_wb_gowait:
  MOVE.L  A0,-(A7)           -> 2
  LEA     $DFF002,A0         -> 6 dmaconr
  MOVE.W  #$8400,148(A0)     -> 6 DMAF_SETCLR OR DMAF_BLITHOG dmacon-dmaconr
  phwb_wb_wait:
  BTST    #6,(A0)            -> 4 DMAB_BLTDONE=14 DMAB_BLTDONE-8
  BNE.B   phwb_wb_wait       -> 2
  MOVE.W  #$0400,148(A0)     -> 6 DMAF_BLITHOG dmacon-dmaconr
  MOVE.L  (A7)+,A0           -> 2
  RTS                        -> 2 =42

ENDPROC

PROC speedrom(rom,size)

  -> Reconnect resident modules:

  MOVEM.L D1-D7/A0-A6,-(A7)

  MOVE.L  rom,A0
  MOVE.L  size,D0

  MOVE.L  #$01000000,D2
  SUB.L   D0,D2
  MOVE.L  A0,A5
  SUB.L   D2,A5      -> a5=difference

  MOVEQ   #-28,D1    -> -(RT_SIZE+2),D1
  ADD.L   D0,D1
  SUB.L   A1,A1
  sr_find:
  SUBQ.L  #2,D1
  BLS.B   sr_done
  CMP.W   #$4AFC,(A0)+  -> RTC_MATCHWORD,(A0)+
  BNE.B   sr_find
  MOVEQ   #2,D0
  ADD.L   (A0),D0    -> RT_MATCHTAG-2(A0),D0
  ADD.L   A5,D0
  CMP.L   A0,D0
  BNE.B   sr_find
  SUBQ.L  #2,A0
  MOVE.L  A1,D0
  BEQ.B   sr_is_1st
  MOVE.L  A0,D0
  SUB.L   A5,D0
  MOVE.L  D0,6(A1)   -> RT_ENDSKIP(A1)
  sr_is_1st:
  MOVE.L  A0,A1
  LEA     26(A0),A0  ->RT_SIZE(A0),A0
  BRA.B   sr_find
  sr_done:
  MOVE.L  A1,D0
  BEQ.B   sr_none
  -> make last RT_ENDSKIP point $00FFFFFA
  MOVE.L  #$00FFFFFA,6(A1)
  sr_none:
  MOVEQ   #1,D7

  MOVE.L  D7,D0
  MOVEM.L (A7)+,D1-D7/A0-A6
ENDPROC D0

ENUM BKMODULE_ID=$707A4E75,BKEP_ID=$4E71

PROC applypatch(patch,rom,size)
  DEF ret=0,seg,module:PTR TO LONG

  IF (seg:=Lock(patch,ACCESS_READ))
    UnLock(seg)

    IF (seg:=LoadSeg(patch))

      module:=Shl(seg,2)+4

      IF module[]=BKMODULE_ID
        IF module[1]=BKEP_ID

          MOVEM.L D1-D7/A0-A6,-(A7)
          LEA     findresident(PC),A2
          LEA     installmodule(PC),A3
          MOVE.L  dosbase,D6
          MOVE.L  execbase,A6
          MOVE.L  rom,A0
          LEA     $F80000,A1
          MOVE.L  #$80000,D0
          MOVE.L  module,A5
          LEA     printf(PC),A4
          JSR     8(A5)
          MOVEM.L (A7)+,D1-D7/A0-A6
          MOVE.L  D0,ret

          IF ret=0
            PrintF('failed, module returned error\n')
          ENDIF

        ELSE
          PrintF('failed, only patch modules supported!\n')
        ENDIF
      ELSE
        PrintF('failed, not a blizkick module!\n')
      ENDIF

      UnLoadSeg(seg)
    ELSE
      PrintFault(IoErr(),progname)
      PrintF('failed, could not load module!\n')
    ENDIF
  ELSE
    PrintFault(IoErr(),progname)
    PrintF('failed, could not load module!\n')
  ENDIF
  RETURN ret


->  IN: a0=ptr to ROM, d0=rom len, a1=ptr to resident name
-> OUT: d0=ptr to resident (buf) or NULL
findresident:
  MOVEM.L D1-D7/A0-A6,-(A7)
  MOVEQ   #1,D6
  MOVE.L  A1,A3
  MOVE.L  #$01000000,D2
  SUB.L   D0,D2      -> d2=rom start (rom)
  MOVE.L  A0,A5
  SUB.L   D2,A5      -> A5=diff
  MOVEQ   #26-2,D1   ->RT_SIZE-2,D1
  SUB.L   D1,D0
  MOVE.W  #$4AFC,D1  ->RTC_MATCHWORD,D1
  fr_find:
  SUBQ.L  #2,D0
  BLS.B   fr_exit_nf
  CMP.W   (A0)+,D1
  BNE.B   fr_find
  MOVEQ   #2,D2
  ADD.L   (A0),D2    ->RT_MATCHTAG-2(A0),D2
  ADD.L   A5,D2
  CMP.L   A0,D2
  BNE.B   fr_find
  MOVE.L  12(A0),A1  ->RT_NAME-2(A0),A1
  ADD.L   A5,A1
  MOVE.L  A3,A2
  fr_compare:
  CMPM.B  (A2)+,(A1)+
  BNE.B   fr_find
  TST.B   -1(A2)
  BNE.B   fr_compare

  MOVE.L  A0,D0
  SUBQ.L  #2,D0

  fr_exit2:
  MOVEM.L (A7)+,D1-D7/A0-A6
  RTS

  fr_exit_nf:
  MOVEQ   #0,D0
  BRA.B   fr_exit2


->  IN: a0=ptr to ROM, d0=rom len, a1=ptr to module, d6=dosbase
-> OUT: d0=success
installmodule:
  MOVEQ   #0,D0
  RTS

->  IN: a0=FmtString, a1=Array (may be 0), d6=dosbase
printf:
  EXG     D6,A6
  MOVEM.L D0-D2/A0-A1,-(A7)
  MOVE.L  A0,D1
  MOVE.L  A1,D2
  JSR     -$3BA(A6)   -> _LVOVPrintF
  MOVEM.L (A7)+,D0-D2/A0-A1
  EXG     D6,A6
  RTS

ENDPROC


PROC romresum(rom,size)
  MOVE.L  rom,A0
  MOVE.L  size,D0
  MOVE.L  D0,D1
  LSR.L   #2,D1
  MOVE.L  -$18(A0,D0.L),D0
  NOT.L   D0
  rr_loop:
  ADD.L   (A0)+,D0
  BCC.B   rr_skip
  ADDQ.L  #1,D0
  rr_skip:
  SUBQ.L  #1,D1
  BNE.B   rr_loop
  NOT.L   D0
ENDPROC D0
