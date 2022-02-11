-> FILE: ESrc:Own/AspectFont.e          REV: 93 --- Remove "Magic" comment from guide file
/* History
   92     1st release.
   93     Removed Enforcer hit.
*/

OPT OSVERSION=37

MODULE 'dos/dos','dos/dosasl','dos/rdargs','exec/memory','dos/dosextens'
MODULE 'utility'
MODULE 'intuition/intuition','intuition/screens','graphics/gfx',
       'graphics/displayinfo'

ENUM ER_NOERR,ER_UTIL,ER_ARGS,ER_OPEN,ER_READ,ER_WRITE,ER_MEM,ER_BREAK

ENUM BUFLEN=32768

PROC main() HANDLE
  DEF array:PTR TO LONG,rfh=NIL,wfh=NIL,rbuf=NIL
  DEF rdargs=NIL,flen,done=FALSE,q=TRUE,ioerr,one2one=TRUE
  DEF tt:PTR TO process

  array:=[0,0,0]
  tt:='$VER: AspectFont 37.2 (22.3.97)\n'; tt:='$COPYRIGHT: Copyright © 1997 Harry Sintonen'
  tt:=FindTask(NIL)
  IF (utilitybase:=OpenLibrary('utility.library',37))=NIL THEN Raise(ER_UTIL)
  IF (rdargs:=ReadArgs('FROM/A,TO/A,QUIET/S',array,NIL))=NIL THEN Raise(ER_ARGS)
  q:=Not(array[2])

  IF q THEN PrintF('AspectFont 37.2 -- Fix AmigaGuide document font by screen aspect\nCopyright © 1997 Harry Sintonen.\n\n')

  flen:=FileLength(array[])
  IF (rfh:=Open(array[],OLDFILE))=NIL THEN Raise(ER_OPEN)
  IF (wfh:=Open(array[1],NEWFILE))=NIL THEN Raise(ER_OPEN)

  IF q THEN PrintF('Processing file \a\s\a, \d bytes...\n',array[],flen)

  IF (rbuf:=AllocVec(BUFLEN,MEMF_ANY OR MEMF_CLEAR))=NIL THEN Raise(ER_MEM)

  one2one:=getaspect(IF tt.windowptr>0 THEN tt.windowptr::window.wscreen ELSE NIL,NIL)

  REPEAT
    IF CtrlC() THEN Raise(ER_BREAK)
    IF Fgets(rfh,rbuf,BUFLEN)
      IF one2one
        IF (Strnicmp(rbuf,'@COMMENT ASPECTFONT ',STRLEN)=0)
          IF q THEN PrintF(' o Enabled \s',rbuf+20)
          IF FputC(wfh,"@")<>"@" THEN Raise(ER_WRITE)
          IF Fputs(wfh,rbuf+20-5) THEN Raise(ER_WRITE)
        ELSE
          IF Fputs(wfh,rbuf) THEN Raise(ER_WRITE)
        ENDIF
      ELSE
        IF Fputs(wfh,rbuf) THEN Raise(ER_WRITE)
      ENDIF
    ELSE
      IF IoErr()
        Raise(ER_READ)
      ELSE
        done:=TRUE
      ENDIF
    ENDIF
  UNTIL done

  IF q THEN PrintF('Done!\n')

EXCEPT DO
  ioerr:=IoErr()
  IF rbuf THEN FreeVec(rbuf)
  IF rfh THEN Close(rfh)
  IF wfh THEN Close(wfh)
  IF exception AND array[1] THEN DeleteFile(array[1])
  IF rdargs THEN FreeArgs(rdargs)
  IF utilitybase THEN CloseLibrary(utilitybase)

  IF exception
    IF exception=ER_BREAK; ioerr:=ERROR_BREAK; ENDIF
    IF (exception="NEW") OR (exception="MEM") THEN exception:=ER_MEM
    IF ioerr AND q THEN PrintFault(ioerr,'AspectFont')
    IF q AND ioerr<>ERROR_BREAK THEN
      PrintF('Error: Could not \s!\n',
              ListItem(['','open utillity.library V37','get arguments','open file','read file','write file',
                        'allocate enough memory',''],exception))
    RETURN 10
  ENDIF
ENDPROC

PROC getaspect(inscr,name:PTR TO CHAR)
  DEF ret=FALSE,scr:PTR TO screen,dinfo:displayinfo,scale

  IF inscr
    scr:=inscr
  ELSE
    IF (scr:=LockPubScreen(name))=NIL THEN RETURN ret
  ENDIF

  IF GetDisplayInfoData(NIL,dinfo,SIZEOF displayinfo,DTAG_DISP,GetVPModeID(scr.viewport))
    scale:=Div(Mul(dinfo.resolution.x,10),dinfo.resolution.y)
    -> PrintF('Ratioh: \d Ratiov: \d Scale=\d\n',dinfo.resolution.x,dinfo.resolution.y,scale)
    IF (scale>=3) AND (scale<=6) THEN ret:=TRUE
  ENDIF

  IF Not(inscr)
    UnlockPubScreen(name,NIL)
  ENDIF
ENDPROC ret
