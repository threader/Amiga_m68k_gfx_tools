-> FILE: ESrc:Own/romupdatesplit.e          REV: 6 --- split V44 rom update to executables
/* History
   0      Started in January 2000.
   1      Quickly hacked up some ident code for BlizKick 1.20 beta.
   2      15th Jan 2000: Added proper system detection. Added computer
          specific switches. Use 'ALL' to emulate old way of operation.
   3      Added CPU, FPU and NOBOARDCHECK switches.
   4      18th Jan: Attnflags test was broken. Added support for some
          future stuff. :)
   5      28th Apr: Now generates neat comments for files by default,
          can be turned off with NOCOMMENT/S. Bugfix: FROM is no longer
          relative to TO.
   6      21st Mar 2002: Added support for AmigaOS 3.9 BoingBag2.
*/


/*
  V44 SetPatch compatible "devs:AmigaOS ROM Update" file
  ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
  by Harry "Piru" Sintonen. This information is 100% incorrect, or at
  least you must assume so. you have been warned. :)

  STRUCTURE romfileheader,0
  ULONG  numexecutables    ; number of valid executables included
  ULONG  file_1_offset
  ULONG  file_2_offset
  ULONG  file_numexecutables_offset
  ; there is no SIZEOF

  STRUCTURE exewrapper,0
  ULONG  ew_reqflags    ; flagset
  ULONG  ew_attnflags   ; attn flags bits that must be set for this module
  ULONG  ew_boardid     ; if bit 0 is set, (manufacturer<<16|product) board must be found
  ULONG  ew_unused      ; must be 0
  LABEL  executable
  ; there is no SIZEOF

  ; flags as of now
  BITDEF  REQ,OCS_DENISE1,0
  BITDEF  REQ,OCS_DENISE2,1
  BITDEF  REQ,ECS_DENISE1,2
  BITDEF  REQ,ECS_DENISE2,3
  BITDEF  REQ,A3000,4
  BITDEF  REQ,A600,5
  BITDEF  REQ,A1200,8
  BITDEF  REQ,A4000,9
  BITDEF  REQ,A4000T,10
  BITDEF  REQ,CD32,11
  BITDEF  REQ,UNKNOWN0,12
  BITDEF  REQ,UNKNOWN1,13

    scsi.device ->

    a300.ld.strip           A1200 IDE      IDE_scsidisk
    a600.ld.strip           A600 IDE       IDE_scsidisk
    a1000.ld.strip          A4000[T] IDE   IDE_scsidisk
    a4000t.ld.strip         A4000T SCSI    A4000T_scsidisk.devuce
    scsidisk.ld.strip       A3000[T]       scsidisk

    name: FileSystem.resource -> FILESYSRES
    filesystem -> FILESYSTEM
*/


OPT REG=5,RTD,020

MODULE 'dos/dos','dos/doshunks','exec/memory','exec/execbase',
       'graphics/gfxbase','exec/execbase'

MODULE 'expansion'

ENUM ARG_FROM,ARG_A600,ARG_A1200,ARG_A3000,ARG_A4000I,ARG_A4000S,
     ARG_CD32,ARG_CPU,ARG_FPU,ARG_NOBOARDCHECK,ARG_NOCOMMENT,
     ARG_ALL,ARG_TO,NUMARGS

ENUM ER_OK,ER_PARAM,ER_INPUTFILE,ER_OUTPUTFILE,ER_READ,ER_SEEK,ER_WRITE,
     ER_MEM,ER_CTRLC,ER_BADFILE


ENUM UNKNOWN,ROMUPDIDENT,FILESYSTEM,FILESYSRES,RAMHANDLER,CONSOLEDEVICE,
     UNKNOWNSCSI,UNKNOWNSCSIIDE,A300,A600,A1000,A4000,SCSIDISK,
     EXECLIB,SYSCHECK,BOOTMENU,SHELL,NUMOF

-> flags
SET REQF_OCS_DENISE1,REQF_OCS_DENISE2,REQF_ECS_DENISE1,REQF_ECS_DENISE2,
    REQF_A3000,REQF_A600,REQF_NONDEF6,REQF_NONDEF7,REQF_A1200,REQF_A4000,
    REQF_A4000T,REQF_CD32


DEF array[NUMARGS]:ARRAY OF LONG
DEF ifh,ofh,buf[5]:ARRAY OF LONG

DEF counts[NUMOF]:ARRAY OF LONG
DEF namebody[NUMOF]:ARRAY OF LONG

DEF attnflags=-1

DEF comment[80]:STRING

PROC main() HANDLE
  DEF rdargs=0,oname=0:PTR TO CHAR,ioerr,ret
  DEF r,pname[64]:STRING
  DEF name,fsize
  DEF lock=0,olddir,chdir=0,fib:PTR TO fileinfoblock
  DEF cpu,fpu

  IF (KickVersion(37)=0) OR ((Int(Long(4)+296) AND AFF_68020)=0)
    WriteF('Haha!\n'); RETURN 666
  ENDIF

  r:='$VER: romupdatesplit 1.0.4 (21.3.02)'
  FOR r:=0 TO NUMARGS-1; array[r]:=0; ENDFOR
  IF (rdargs:=ReadArgs('FROM=FILE/A,A600/S,A1200/S,A3000/S,A4000I/S,A4000S/S,' +
                       'CD32/S,CPU/K/N,FPU/K/N,NOBOARDCHECK/S,NOCOMMENT/S,' +
                       'ALL/S,TO',
                       array,NIL))=0 THEN Raise(ER_PARAM)

  name:=array[ARG_FROM]
  fsize:=FileLength(name)
  IF fsize<0 THEN Raise(ER_INPUTFILE)
  IF (fsize<20) OR (fsize AND 3) THEN Raise(ER_BADFILE)

  IF (ifh:=Open(name,MODE_OLDFILE))=NIL THEN Raise(ER_INPUTFILE)


  IF array[ARG_TO]
    IF (lock:=Lock(array[ARG_TO],ACCESS_READ))=NIL THEN Raise(ER_PARAM)

    IF (fib:=AllocDosObject(DOS_FIB,NIL))=NIL THEN Raise(ER_PARAM)
    ret:=Examine(lock,fib)
    IF ret THEN r:=fib.direntrytype
    FreeDosObject(DOS_FIB,fib)
    IF ret=0 THEN Raise(ER_PARAM)
    IF r<0
      PrintF('TO must be a directory.\n')
      Raise(ER_PARAM)
    ENDIF

    olddir:=CurrentDir(lock); chdir:=1
  ENDIF

  IF array[ARG_CPU]
    cpu:=Long(array[ARG_CPU])
    SELECT cpu
      CASE 68000;
        /* no-op */
      CASE 68010;
        attnflags:=attnflags OR AFF_68010
      CASE 68020;
        attnflags:=attnflags OR AFF_68010 OR AFF_68020
      CASE 68030;
        attnflags:=attnflags OR AFF_68010 OR AFF_68020 OR AFF_68030
      CASE 68040;
        attnflags:=attnflags OR AFF_68010 OR AFF_68020 OR AFF_68030 OR AFF_68040
      CASE 68060;
        attnflags:=attnflags OR AFF_68010 OR AFF_68020 OR AFF_68030 OR AFF_68040 OR $80
      DEFAULT;
        PrintF('bad CPU number \d\n',cpu)
        Raise(ER_PARAM)
    ENDSELECT
  ENDIF
  IF array[ARG_FPU]
    fpu:=Long(array[ARG_FPU])
    SELECT fpu
      CASE 68881;
        attnflags:=attnflags OR AFF_68881
      CASE 68882;
        attnflags:=attnflags OR AFF_68881 OR AFF_68882
      CASE 68040;
        attnflags:=attnflags OR AFF_68881 OR AFF_68882 OR AFF_FPU40
      CASE 68060;
        -> there's no AFF_FPU060
        attnflags:=attnflags OR AFF_68881 OR AFF_68882 OR AFF_FPU40
      DEFAULT;
        PrintF('bad FPU number \d\n',fpu)
        Raise(ER_PARAM)
    ENDSELECT
  ENDIF


  r:=0
  IF array[ARG_A600] THEN r++
  IF array[ARG_A1200] THEN r++
  IF array[ARG_A3000] THEN r++
  IF array[ARG_A4000I] THEN r++
  IF array[ARG_A4000S] THEN r++
  IF array[ARG_CD32] THEN r++

  IF r>1
    PrintF('specify only one of A600, A1200, A3000, A4000I, A4000S or CD32\n')
    Raise(ER_PARAM)
  ENDIF

  IF array[ARG_ALL] AND r
    PrintF('specify only ALL or specific machine type\n')
    Raise(ER_PARAM)
  ENDIF

  IF array[ARG_ALL] AND (array[ARG_CPU] OR array[ARG_FPU] OR
                         array[ARG_NOBOARDCHECK])
    PrintF('you must not use CPU, FPU and/or NOBOARDCHECK with ALL\n')
    Raise(ER_PARAM)
  ENDIF


  split(ifh,fsize)

EXCEPT DO
  IF (exception="NEW") OR (exception="MEM") THEN exception:=ER_MEM

  IF exception
    IF ioerr:=IoErr()
      GetProgramName(pname,StrMax(pname)-1); PrintFault(ioerr,pname)
    ENDIF
    PrintF('Error \d: \s\n',exception,
           ListItem(['','argument error','could not open input file',
                    'could not open output file','read error',
                    'seek error','write error','no memory','break',
                    'bad file format'
                    ],exception))
    ret:=RETURN_ERROR
  ELSE
    ret:=RETURN_OK
  ENDIF

  IF chdir THEN CurrentDir(olddir)
  IF lock THEN UnLock(lock)

  IF ifh THEN Close(ifh)
  IF ofh THEN Close(ofh)
  IF exception AND oname THEN DeleteFile(oname)

  IF rdargs THEN FreeArgs(rdargs)
ENDPROC ret


PROC extractthis(head:PTR TO LONG)
  DEF cdui,card,a3000,a4000,ncrscsi,mlisa=0,hrdenise=0,
      gfxb:PTR TO gfxbase,flags,mask=0,attnf,af,
      execb:PTR TO execbase,lib,manu,prod,exp

  IF array[ARG_ALL] THEN RETURN TRUE

  -> flag test

  flags:=head[]

  IF flags AND $3F3F    -> OS 3.5 had: $0f3f

    gfxb:=gfxbase

    Forbid()
    IF (cdui:=FindResident('cdui.library'))
      IF (cdui<$f80000) OR (cdui>$ffffff)
        cdui:=0
      ENDIF
    ENDIF
    card:=FindResident('card.resource')
    a3000:=FindResident('A3000 bonus')
    a4000:=FindResident('A4000 bonus')
    ncrscsi:=FindResident('NCR scsi.device')
    Permit()
    
    IF (gfxb.chiprevbits0 AND GFXF_AA_MLISA)
      mlisa:=1
    ENDIF
    IF (gfxb.chiprevbits0 AND GFXF_HR_DENISE)
      hrdenise:=1
    ENDIF

    IF a4000
      IF ncrscsi
        mask:=REQF_A4000T
      ELSE
        mask:=REQF_A4000
      ENDIF
    ELSE
      IF a3000
        mask:=REQF_A3000
      ELSEIF cdui 
        mask:=REQF_CD32
      ELSEIF card
        IF mlisa
          mask:=REQF_A1200
        ELSE
          mask:=REQF_A600
        ENDIF
      ELSEIF hrdenise
        mask:=REQF_ECS_DENISE1 OR REQF_ECS_DENISE2
      ELSE
        mask:=REQF_OCS_DENISE1 OR REQF_OCS_DENISE2
      ENDIF
    ENDIF

    IF array[ARG_A600]
      mask:=REQF_A600
    ELSEIF array[ARG_A1200]
      mask:=REQF_A1200
    ELSEIF array[ARG_A3000]
      mask:=REQF_A3000
    ELSEIF array[ARG_A4000I]
      mask:=REQF_A4000
    ELSEIF array[ARG_A4000S]
      mask:=REQF_A4000T
    ELSEIF array[ARG_CD32]
      mask:=REQF_CD32
    ENDIF
    
    IF (flags AND mask)=0 THEN RETURN FALSE
  ENDIF

  -> attnflags test

  IF attnf:=head[2] AND $FFFF
    execb:=execbase
    IF attnflags<>-1
      af:=attnflags
    ELSE
      IF attnf AND $80
        -> 060 attnflag required... make sure
        -> 68060.library gets loaded...
        IF execb.attnflags AND AFF_68040
          IF (lib:=OpenLibrary('68060.library',0))
            CloseLibrary(lib)
          ENDIF
        ENDIF
      ENDIF
      af:=execb.attnflags
    ENDIF

    IF (attnf AND af)=0 THEN RETURN FALSE

  ENDIF


  -> manu/prod test
  IF array[ARG_NOBOARDCHECK]=0
    IF head[2] AND 1
      exp:=0
      IF (expansionbase:=OpenLibrary('expansion.library',37))
        manu:=Shr(head[2],16) AND $0FFFF
        prod:=head[2] AND $0FFFF
        exp:=FindConfigDev(NIL,manu,prod)
        CloseLibrary(expansionbase)
      ENDIF
      IF exp=0 THEN RETURN FALSE
    ENDIF
  ENDIF


  -> load this module!

ENDPROC TRUE


PROC getfiletype(ifh,offs,head:PTR TO LONG)
  DEF buf[2048]:ARRAY OF CHAR,r,wpt:PTR TO INT,
      name:PTR TO CHAR,idstring:PTR TO CHAR,len,hunk0,pos

  IF Seek(ifh,offs,OFFSET_BEGINNING)<0 THEN Raise(ER_SEEK)
  len:=Read(ifh,buf,2047)
  IF len<30 THEN Raise(ER_READ)
  buf[2047]:=0; buf[len]:=0
  IF Seek(ifh,offs,OFFSET_BEGINNING)<0 THEN Raise(ER_SEEK)

  IF Long(buf)<>HUNK_HEADER THEN Raise(ER_BADFILE)
  IF Long(buf+4) THEN Raise(ER_BADFILE)

  hunk0:=buf+28+Shl(Long(buf+8),2); IF hunk0>=(buf+2048) THEN Raise(ER_BADFILE)

  len:=len-(hunk0-buf); IF len<26 THEN Raise(ER_BADFILE)

  wpt:=hunk0
  FOR r:=0 TO Shr(len-26,1)
    IF (wpt[]++=$4AFC)
      IF Long(wpt)=(wpt-2-hunk0)
        name:=hunk0+Long(wpt+12)
        idstring:=hunk0+Long(wpt+16)
        IF (name>buf) AND (name<(buf+2048)) AND
           (idstring>buf) AND (idstring<(buf+2048))

          ->PrintF('name: "\s" idstring "\s"\n', name, idstring)

          IF idstring[]
            StrCopy(comment,idstring)
          ELSEIF name[]
            StrCopy(comment,name)
          ELSE
            comment[]:=0
          ENDIF
          -> strip linefeed and carriage returns
          WHILE (pos:=StrLen(comment)-1)>0 AND ((comment[pos]=10) OR (comment[pos]=13))
            comment[pos]:=0
          ENDWHILE

          IF StrCmp(name,'AmigaOS ROM Update')
            RETURN ROMUPDIDENT
          ELSEIF StrCmp(name,'filesystem')
            RETURN FILESYSTEM;
          ELSEIF StrCmp(name,'FileSystem.resource')
            RETURN FILESYSRES;
          ELSEIF StrCmp(name,'ram-handler')
            RETURN RAMHANDLER;
          ELSEIF StrCmp(name,'console.device')
            RETURN CONSOLEDEVICE;
          ELSEIF StrCmp(name,'NCR scsi.device')
            RETURN A4000;
          ELSEIF StrCmp(name,'scsi.device')

            IF StrCmp(idstring,'scsidisk ',STRLEN)
              RETURN SCSIDISK;
            ELSEIF StrCmp(idstring,'IDE_scsidisk ',STRLEN)

              IF head[] AND REQF_A600
                RETURN A600;
              ELSEIF head[] AND REQF_A1200
                RETURN A300;
              ELSEIF head[] AND REQF_A4000
                RETURN A1000;
              ENDIF

              RETURN UNKNOWNSCSIIDE;
            ENDIF

            RETURN UNKNOWNSCSI;
          ELSEIF StrCmp(name, 'exec.library')
            RETURN EXECLIB
          ELSEIF StrCmp(name, 'syscheck')
            RETURN SYSCHECK
          ELSEIF StrCmp(name, 'bootmenu')
            RETURN BOOTMENU
          ELSEIF StrCmp(name, 'shell')
            RETURN SHELL
          ENDIF
        ENDIF
      ENDIF
    ENDIF
  ENDFOR

ENDPROC UNKNOWN

PROC split(ifh,fsize)
  DEF num,seektable:PTR TO LONG,t,r,stack,
      head[5]:ARRAY OF LONG,fname[32]:STRING,seg,size,
      cnts[12]:STRING,type

  IF Read(ifh,{num},4)<>4 THEN Raise(ER_READ)

  IF num=HUNK_HEADER
    PrintF('this file is already single executable!\n')
    Raise(ER_PARAM)
  ENDIF

  IF num>$ffff THEN Raise(ER_BADFILE)

  t:=Shl(num,2)
  seektable:=NewR(t+4)

  IF Read(ifh,seektable,t)<>t THEN Raise(ER_READ)

  FOR r:=0 TO num-1
    IF CtrlC() THEN Raise(ER_CTRLC)
    IF seektable[r] AND 3 THEN Raise(ER_BADFILE)
    IF Seek(ifh,seektable[r],OFFSET_BEGINNING)<0 THEN Raise(ER_SEEK)
    IF Read(ifh,head,20)<>20 THEN Raise(ER_READ)
    IF (Int(head+4)<>0) OR (head[3]<>0) OR (head[4]<>HUNK_HEADER)
      Raise(ER_BADFILE)
    ENDIF
  ENDFOR

  FOR r:=0 TO NUMOF-1; counts[r]:=0; ENDFOR

  namebody[UNKNOWN]:='unknown'
  namebody[ROMUPDIDENT]:='romupdate.idtag'
  namebody[FILESYSTEM]:='FastFileSystem'
  namebody[FILESYSRES]:='FileSystem.resource'
  namebody[RAMHANDLER]:='ram-handler'
  namebody[CONSOLEDEVICE]:='console.device'
  namebody[UNKNOWNSCSI]:='unknown.ld.strip'
  namebody[UNKNOWNSCSIIDE]:='unknown_ide.ld.strip'

  IF (array[ARG_ALL]=0) OR (array[ARG_A600] OR array[ARG_A1200] OR
     array[ARG_A3000] OR
     array[ARG_A4000I] OR array[ARG_A4000S] OR array[ARG_CD32])

    namebody[A300]:='scsi.device'
    namebody[A600]:='scsi.device'
    namebody[A1000]:='scsi.device'
    namebody[A4000]:='NCR scsi.device'
    namebody[SCSIDISK]:='scsi.device'

  ELSE

    namebody[A300]:='a300.ld.strip'
    namebody[A600]:='a600.ld.strip'
    namebody[A1000]:='a1000.ld.strip'
    namebody[A4000]:='a4000.ld.strip'
    namebody[SCSIDISK]:='scsidisk.ld.strip'

  ENDIF

  namebody[EXECLIB]:='exec.library'
  namebody[SYSCHECK]:='syscheck'
  namebody[BOOTMENU]:='bootmenu'
  namebody[SHELL]:='shell'

  FOR r:=0 TO num-1
    IF CtrlC() THEN Raise(ER_CTRLC)
    IF Seek(ifh,seektable[r],OFFSET_BEGINNING)<0 THEN Raise(ER_SEEK)
    IF Read(ifh,head,16)<>16 THEN Raise(ER_READ)

    size:=-16-seektable[r]+IF r<(num-1) THEN seektable[r+1] ELSE fsize
    PutLong({filesize},size)
    stack:=4096
    IF seg:=InternalLoadSeg(ifh,NIL,[{readfunc},
                                     {allocfunc},
                                     {freefunc}]:LONG,{stack})=NIL
      Raise(ER_BADFILE)
    ENDIF
    InternalUnLoadSeg(seg,{freefunc})

    IF extractthis(head)

      type:=getfiletype(ifh,seektable[r]+16,head)

      StringF(cnts,'.\d',counts[type])
      StringF(fname,'\s\s',namebody[type],IF counts[type] THEN cnts ELSE '')

      PrintF('\d[02]: flags $\h[04]  offset $\h[06]  len $\h[06]  "\s"\n',
             r,head[],seektable[r]+16,size,fname)

      IF Seek(ifh,seektable[r]+16,OFFSET_BEGINNING)<0 THEN Raise(ER_SEEK)
      IF (ofh:=Open(fname,MODE_NEWFILE))=NIL THEN Raise(ER_OUTPUTFILE)
      readwrite(size)
      Close(ofh); ofh:=0

      IF array[ARG_NOCOMMENT]=0
        IF comment[]
          SetComment(fname,comment)
        ENDIF
      ENDIF

      counts[type]:=counts[type]+1

    ENDIF

  ENDFOR

  RETURN
filesize:
  LONG 0
readfunc:
  LEA    filesize(PC),A0
  TST.L  (A0)
  BGE.B  readok
  MOVEQ  #0,D0
  RTS
readok:
  CMP.L  (A0),D3
  BLS.B  readskip
  MOVE.L (A0),D3
readskip:
  SUB.L  D3,(A0)
  JMP    Read(A6)

allocfunc:
  MOVEQ  #0,D1
  JMP    AllocMem(A6)

freefunc:
  JMP    FreeMem(A6)
ENDPROC

PROC readwrite(l)
  DEF len,buf[8192]:ARRAY OF CHAR,buflen=8192
  IF (len:=l AND $1FFFFFFF)=0 THEN RETURN

  IF len<buflen THEN buflen:=len

  WHILE len
    IF CtrlC() THEN Raise(ER_CTRLC)
    IF (l:=Read(ifh,buf,buflen))<1 THEN Raise(ER_READ)
    IF Write(ofh,buf,l)<>l THEN Raise(ER_WRITE)
    len:=len-l
    IF len<buflen THEN buflen:=len
  ENDWHILE
ENDPROC


