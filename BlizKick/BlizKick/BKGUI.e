-> FILE: ESrc:Own/BKGUI.e          REV: 521 --- BlizKick GUI
/* History
*/

OPT OSVERSION=37, PREPROCESS

MODULE 'tools/EasyGUI', 'tools/exceptions', 'amigalib/lists', 'utility',
       'gadtools', 'libraries/gadtools', 'exec/lists', 'exec/nodes',
       'dos/dos', 'dos/exall', 'dos/dosextens'
MODULE 'intuition/intuition','intuition/sghooks'

-> dirwalker flags
ENUM DWF_RECURSIVE=1, DWF_NOSOFT=2, DWF_NOHARD=4

ENUM ERR_NONE, ERR_NEW, ERR_STR, ERR_LOCK, ERR_ADO, ERR_NODE, ERR_LIB, ERR_PATT,
     ERR_OK, ERR_CANCEL, ERR_BREAK

RAISE ERR_NEW  IF New()=NIL,
      ERR_STR  IF String()=NIL,
      ERR_LOCK IF Lock()=NIL,
      ERR_BREAK IF CtrlC()=TRUE,
  ->    ERR_ADO  IF AllocDosObject()=NIL,
      ERR_LIB  IF OpenLibrary()=NIL
  ->    ERR_PATT IF ParsePatternNoCase()=-1

CONST BUF_SIZE=1024, FILENAME_SIZE=300
CONST PATTERNBUFF_SIZE=FILENAME_SIZE*2+2
ENUM DIR_NODE, POS_NODE, VOL_NODE, ASN_NODE, FILE_NODE, MAX_TYPE
CONST DIRSTRLEN=6

DEF pathStr[FILENAME_SIZE]:STRING, currPath[FILENAME_SIZE]:STRING,
    fileStr[FILENAME_SIZE]:STRING, patternStr[FILENAME_SIZE]:STRING,
    patternBuff[PATTERNBUFF_SIZE]:ARRAY

DEF listGad1, listGad2, listGad3, txtGad1, txtGad2, secs, micros,
    nameList1=NIL:PTR TO lh, nameList2=NIL:PTR TO lh, nameList3=NIL:PTR TO lh,
    posList=NIL:PTR TO lh, txtGadc, txtGvt, txtGv

DEF f_force,f_localfast,f_quickboot,f_speedrom,f_hogwaitblit,
    oldSel1=-1, oldSel2=-1, oldSel3=-1

DEF gh=NIL:PTR TO guihandle

DEF ksList=NIL:PTR TO lh,modList=NIL:PTR TO lh

OBJECT mynode
  succ:PTR TO mynode
  pred:PTR TO mynode
  type:CHAR
  pri:CHAR
  name:PTR TO CHAR
  userptr:LONG
ENDOBJECT

OBJECT module
  filename:PTR TO CHAR
  enable:CHAR
ENDOBJECT

OBJECT kickstart
  filename:PTR TO CHAR
  version:INT
  revision:INT
  size:LONG
ENDOBJECT

OBJECT setdata
  kickstart:PTR TO mynode  -> (kickstart)
  modules:lh               -> list of mynode (module)
  switches:LONG
ENDOBJECT

/* saved set
[SetName]
kickstart=DEVS:rom40068
module=MoveVBR
module=Preparemul
module=SoftSCSI
switches=$1

*/



PROC main() HANDLE
  DEF here=NIL
  utilitybase:=OpenLibrary('utility.library', 37)
  gadtoolsbase:=OpenLibrary('gadtools.library', 37)

  NEW nameList1, nameList2, nameList3
  newList(nameList1)
  newList(nameList2)
  newList(nameList3)

  addNode(nameList1, 'set1', 0, 0)
  addNode(nameList1, 'set2', 0, 0)
  addNode(nameList1, 'set3', 0, 0)

  /*
  addNode(nameList2, '34.5   256k', 0, 0)
  addNode(nameList2, '39.106 512k', 0, 0)
  addNode(nameList2, '40.68  512k', 0, 0)

  addNode(nameList3, '· SoftSCSI', 0, 0)
  addNode(nameList3, '· PrepareEmul', 0, 0)
  addNode(nameList3, '  Hackdisk', 0, 0)
  */

  getksList()
  getmodList()

  gui()

EXCEPT DO
  IF gadtoolsbase THEN CloseLibrary(gadtoolsbase)
  IF utilitybase THEN CloseLibrary(utilitybase)
  SELECT exception
  CASE ERR_OK
    PrintF('All ok\n')
  CASE ERR_CANCEL
    WriteF('Cancel\n')
  DEFAULT
    report_exception()
  ENDSELECT
ENDPROC

PROC getksList() HANDLE

  NEW ksList
  newList(ksList)

  dirwalker('DEVS:',DWF_RECURSIVE,{getksl_hook})
  
EXCEPT DO
  ReThrow()
ENDPROC
PROC getksl_hook(fib:PTR TO fileinfoblock,data)
  IF fib.entrytype<0
    IF fib.size AND ((fib.size AND $3FFFF)=0) AND (fib.size<=$80000)
      IF isKickfile(fib.filename)
        addNodeSort(nameList2, fib.filename, 0, 0)
      ENDIF
    ENDIF
  ENDIF
ENDPROC
PROC isKickfile(name:PTR TO CHAR)
  DEF buf[2]:ARRAY OF LONG,fh,got

  IF (fh:=Open(name,MODE_OLDFILE))
    got:=(Fread(fh,buf,8,1)=1)
    Close(fh)
    IF got AND ((buf[] AND $FFF8FFFF)=$11104EF9) AND (Shr(buf[1]+FileLength(name),16)=$0100) THEN RETURN TRUE
  ENDIF
ENDPROC FALSE


PROC getmodList() HANDLE

  NEW modList
  newList(modList)

  dirwalker('DEVS:Modules/',0,{getmodl_hook})
EXCEPT DO
  ReThrow()
ENDPROC
PROC getmodl_hook(fib:PTR TO fileinfoblock,data)
  DEF buf[64]:STRING
  IF fib.entrytype<0
    IF isModulefile(fib.filename)
      StringF(buf,'  \s',fib.filename)
      addNodeSort(nameList3, buf, 0, 0)
    ENDIF
  ENDIF
ENDPROC
PROC isModulefile(name:PTR TO CHAR)
  DEF sl,buf[2]:ARRAY OF LONG

  IF (sl:=LoadSeg(name))
    CopyMem(Shl(sl,2)+4,buf,8)
    UnLoadSeg(sl)
    IF buf[]=$707A4E75 THEN RETURN TRUE
  ENDIF
ENDPROC FALSE


/*
  DW00 - locking of directory failed
  DW01 - AllocDosObject(FIB) failed
  DW02 - Examine() failed
  DW03 - ExNext() failed
*/
PROC dirwalker(dirname,flags,hookfunc,userdata=NIL) HANDLE
  DEF dirlock=NIL,fib=NIL:PTR TO fileinfoblock,state,olddir=-1

  IF (dirlock:=Lock(dirname, ACCESS_READ))=NIL THEN Raise("DW00")
  IF (fib:=AllocDosObject(DOS_FIB,NIL))=NIL THEN Raise("DW01")

  IF Examine(dirlock,fib)=NIL THEN Raise("DW02")
  olddir:=CurrentDir(dirlock)

  SetIoErr(0)
  WHILE ExNext(dirlock,fib)
    state:=hookfunc(fib,userdata)
    EXIT state<0
    IF flags AND DWF_RECURSIVE
      IF (fib.entrytype=ST_SOFTLINK) AND (flags AND DWF_NOSOFT)
        state:=0
      ELSEIF (fib.entrytype=ST_LINKDIR) AND (flags AND DWF_NOHARD)
        state:=0
      ENDIF
      IF state AND (fib.entrytype>=0)
        dirwalker(fib.filename,flags,hookfunc,userdata)
      ENDIF
    ENDIF
  ENDWHILE

  IF (IoErr()<>ERROR_NO_MORE_ENTRIES) AND (state>=0) THEN Raise("DW03")

EXCEPT DO
  IF olddir<>-1 THEN CurrentDir(olddir)

  IF fib THEN FreeDosObject(DOS_FIB,fib)
  IF dirlock THEN UnLock(dirlock)

  ReThrow()
ENDPROC


-> GUI definition
CONST SETLIST_W=10, KSLIST_W=8, MODLIST_W=9, LIST_H=10
CONST SETSTR_MAX=16, KSSTR_MAX=16, MODSTR_MAX=16

PROC gui_init(in_gh)
  DEF tfile[32]:STRING, cmd[64]:STRING, verstr[256]:STRING, fh, f=FALSE
  gh:=in_gh   -> SET GLOBAL gh!!

  ->makeinvstr(strGad1)
  ->makeinvstr(strGad2)
  ->activategad(strGad2,gh.wnd)
  ->setgadgetattrs(txtGadc,[GTTX_JUSTIFICATION,GTJ_CENTER,NIL])

  StringF(tfile,'T:BKGuiTmp.\h',FindTask(NIL))
  StringF(cmd,'Version >\s `WHICH BlizKick` FILE FULL',tfile)
  IF SystemTagList(cmd,NIL)=0
    IF (fh:=Open(tfile,OLDFILE))
      IF Fgets(fh,verstr,256)
        IF StrLen(verstr)>0 THEN IF verstr[StrLen(verstr)-1]=10 THEN verstr[StrLen(verstr)-1]:=0
        SetStr(verstr,StrLen(verstr))
        f:=TRUE
      ENDIF
      Close(fh)
    ENDIF
  ENDIF
  StringF(cmd,'DELETE >NIL: \s FORCE',tfile)
  SystemTagList(cmd,NIL)
  IF Not(f) THEN StrCopy(verstr,'info not available')

  settxt(gh, txtGvt, 'BlizKick version')
  ->settxt(gh, txtGv, '1.10 (xx.xx.97)')
  settxt(gh, txtGv, verstr)
ENDPROC

PROC gui()
  myeasygui({gui_init},'BlizKickGUI 1.0 © 1997 Harry Sintonen',
    [BEVEL,
      ->[EQROWS,
      [ROWS,
        [COLS,
          txtGadc:=[TEXT,'Set',NIL,FALSE,SETLIST_W],
          [TEXT,'Kickstart',NIL,FALSE,KSLIST_W],
          [TEXT,'Modules',NIL,FALSE,MODLIST_W],
          [TEXT,'Switches',NIL,FALSE,0]
        ],
        [COLS,
          [EQROWS,
            listGad1:=[LISTV,{a_list1},NIL,SETLIST_W,LIST_H-4,nameList1,0,NIL,0],
            txtGad1:=[TEXT,NIL,NIL,TRUE,1],
            [COLS,
              [SBUTTON,{b_snew},'New'],
              [SBUTTON,{b_sdel},'Del']
            ]
          ],
          [EQROWS,
            listGad2:=[LISTV,{a_list2},NIL,KSLIST_W,LIST_H-2,nameList2,0,NIL,0],
            txtGad2:=[TEXT,NIL,NIL,TRUE,1]
          ],
          listGad3:=[LISTV,{a_list3},NIL,MODLIST_W,LIST_H,nameList3,0,NIL,0],
          [ROWS,
            [BEVELR,
              [EQROWS,
                ->[TEXT,NIL,NIL,FALSE,1],[SPACEV],
                [CHECK,{c_force},'Force',f_force,FALSE],[SPACEV],
                [CHECK,{c_localfast},'LocalFast',f_localfast,FALSE],[SPACEV],
                [CHECK,{c_quickboot},'QuickBoot',f_quickboot,FALSE],[SPACEV],
                [CHECK,{c_speedrom},'SpeedROM',f_speedrom,FALSE],[SPACEV],
                [CHECK,{c_hogwaitblit},'HogWaitBlit',f_hogwaitblit,FALSE]
                ->[SPACEV],[TEXT,NIL,NIL,FALSE,1]
              ]
            ],
            txtGvt:=[TEXT,NIL,NIL,FALSE,1],
            txtGv:=[TEXT,'BlizKick 1.10 (04/01/97)',NIL,TRUE,1]
          ]
        ],
        [BAR],
        [COLS,
          [BUTTON,{b_kick},'Kick'],
          [SPACEH],
          [BUTTON,{b_save},'Save settings'],
          [SPACEH],
          [BUTTON,{b_cancel},'Cancel']
        ]
      ]
    ]
  )
ENDPROC


PROC settxt(gh:PTR TO guihandle, gadget, str, newmax=0) HANDLE
  DEF gad:PTR TO gadget,slen,gslen,gadstr
  IF gad:=findgadget(gh, gadget)
    IF Not(gad.gadgettype AND GTYP_REQGADGET)
      IF gad.userdata=NIL THEN Raise(0)
      IF Long(gad.userdata)>65536 THEN Raise(0)   -> normally 16?
      gadstr:=Long(gad.userdata+4)
      slen:=StrLen(str)+1
      IF gad.gadgettype AND GTYP_GTYPEMASK THEN Raise(0)
      IF gadstr
        gslen:=Max(StrLen(gadstr)+1, newmax)   ->  needs to be fixed!!
      ELSE
        gadstr:=New(gslen:=Max(slen,newmax))
        PutLong(gad.userdata+4,gadstr)
      ENDIF

      -> PrintF('gslen: \d newmax: \d\n',gslen,newmax)

      IF gslen<slen THEN slen:=gslen-1
      CopyMem(str,gadstr,slen)
      Gt_SetGadgetAttrsA(gad,gh.wnd,NIL,[GTTX_TEXT,gadstr,NIL])  -> gui update
    ENDIF
  ENDIF
EXCEPT DO
  ReThrow()
ENDPROC

/*
PROC settxt(gh:PTR TO guihandle, gadget, str)
  DEF gad:PTR TO gadget
  IF gad:=findgadget(gh, gadget)
    IF Not(gad.gadgettype AND GTYP_REQGADGET)
      Gt_SetGadgetAttrsA(gad,gh.wnd,NIL,[GTTX_TEXT,str,NIL])
    ENDIF
  ENDIF
ENDPROC

PROC activategad(gadget,win)
  DEF gad:PTR TO gadget
  IF gad:=findgadget(gh, gadget)
    IF Not(gad.gadgettype AND GTYP_REQGADGET)
      IF Not(gad.flags AND GFLG_DISABLED)
        PrintF('!!\n')
        IF ActivateGadget(gad,win,NIL)=0 THEN PrintF('failed!\n')
      ENDIF
    ENDIF
  ENDIF
ENDPROC

PROC makeinvstr(gadget)
  DEF gad:PTR TO gadget,sinfo:PTR TO stringinfo,ext:PTR TO stringextend

  IF gad:=findgadget(gh, gadget)
    IF ((gad.gadgettype AND GTYP_GTYPEMASK)=GTYP_STRGADGET)
      IF (gad.activation AND GACT_STRINGEXTEND) OR ((gad.flags) AND GFLG_STRINGEXTEND)
        sinfo:=gad.specialinfo
        ext:=sinfo.extension
        ext.pens[0]:=0; ext.pens[1]:=0
        ext.activepens[0]:=0; ext.activepens[1]:=0
      ENDIF
    ENDIF
  ENDIF
ENDPROC
*/

-> GUI definition
PROC asksetname(oldname)
  DEF s

  IF (s:=String(SETSTR_MAX))=NIL THEN Raise(ERR_NEW)
  StrCopy(s,oldname,SETSTR_MAX)

  myeasygui(NIL,'Set name',
    [BEVEL,
      [ROWS,
        [TEXT,'Name for set',NIL,FALSE,12],
        [STR,1,NIL,s,SETSTR_MAX,8],
        [BAR],
        [COLS,
          [BUTTON,1,'Ok'],
          [SPACEH],
          [BUTTON,0,'Cancel']
        ]
      ]
    ]
  )
ENDPROC s



-> Change the displayed list
PROC changeList(list, sel_Ptr, listGad, changefunc=0, flags=0) HANDLE
  DEF realgad

  -> Deselect
  ^sel_Ptr:=-1

  -> Remove list (without display glitch)
  setlistvlabels(gh, listGad, -1)

  -> Change list contents
  IF changefunc THEN changefunc(list)

EXCEPT DO
  -> Reattach list
  setlistvlabels(gh, listGad, list)

  IF (flags AND 1)
    -> Set list to pos 0
   IF realgad:=findgadget(gh, listGad)
     Gt_SetGadgetAttrsA(realgad, gh.wnd, NIL, [GTLV_TOP, 0, NIL])
   ENDIF
  ENDIF
  ReThrow()
ENDPROC

-> Add a new mynode to the list
PROC addNode(list, name, type, pri, userptr=NIL) HANDLE
  DEF node=NIL:PTR TO mynode, s=NIL
  NEW node
  IF name
    s:=StrCopy(String(StrLen(name)), name)
  ENDIF
  node.name:=s
  node.type:=type
  node.pri:=pri
  node.userptr:=userptr
  AddTail(list, node)
EXCEPT
  IF node THEN END node
  IF s THEN DisposeLink(s)
  Throw(ERR_NODE,type)
ENDPROC

->#define SORTDEBUG
PROC addNodeSort(list:PTR TO lh, name, type, pri, userptr=NIL) HANDLE
  DEF node=NIL:PTR TO mynode, s=NIL, worknode:PTR TO mynode
  NEW node
  IF name
    s:=StrCopy(String(StrLen(name)), name)
  ENDIF
  node.name:=s
  node.type:=type
  node.pri:=pri
  node.userptr:=userptr

  worknode:=list.tailpred -> Ptr to last node
  #ifdef SORTDEBUG
  IF worknode<>list
     PrintF('>> "\s" tailpred: \h \s[20]\n',s,list.tailpred,list.tailpred.name)
  ELSE
     PrintF('>> "\s" tailpred: none\n',s)
  ENDIF
  #endif
  WHILE worknode<>list
    #ifdef SORTDEBUG
    PrintF('\h: \s[20]\n',worknode.name,worknode.name)
    #endif
    EXIT Stricmp(s,worknode.name)>0
    worknode:=worknode.pred
  ENDWHILE
  #ifdef SORTDEBUG
  IF worknode<>list
    PrintF('insert: \s[20] after \s[20]\n',s,worknode.name)
  ELSE
    PrintF('insert: as first\n')
  ENDIF
  #endif
  Insert(list, node, IF worknode=(list+4) THEN 0 ELSE worknode)
  ->Insert(list, node, worknode) ->IF worknode=(list+4) THEN 0 ELSE worknode)

EXCEPT
  IF node THEN END node
  IF s THEN DisposeLink(s)
  Throw(ERR_NODE,type)
ENDPROC

-> Free a list of mynodes and empty it
PROC freeNodes(list:PTR TO lh, userfreefunc=NIL)
  DEF worknode:PTR TO mynode, nextnode
  worknode:=list.head  -> First node
  WHILE nextnode:=worknode.succ
    IF userfreefunc THEN userfreefunc(worknode.userptr)
    IF worknode.name THEN DisposeLink(worknode.name)
    END worknode
    worknode:=nextnode
  ENDWHILE
  newList(list)
ENDPROC


-> GUI actions:

PROC a_list1(info, sel)
  DEF node:PTR TO ln, s, m, i=0
  CurrentTime({s}, {m})
  node:=nameList1.head  -> First node
  WHILE node.succ AND (i<sel)
    node:=node.succ
    INC i
  ENDWHILE
  settxt(gh, txtGad1, node.name, SETSTR_MAX)
  IF (sel=oldSel1) AND DoubleClick(secs, micros, s, m)
    Raise(ERR_OK)  -> Double click
  ENDIF
  secs:=s; micros:=m; oldSel1:=sel
ENDPROC

PROC a_list2(info, sel)
  DEF node:PTR TO ln, i=0
  node:=nameList2.head  -> First node
  WHILE node.succ AND (i<sel)
    node:=node.succ
    INC i
  ENDWHILE
  settxt(gh, txtGad2, node.name, KSSTR_MAX)
  oldSel2:=sel

ENDPROC

PROC a_list3(info, sel)
  DEF node:PTR TO ln, i=0
  node:=nameList3.head  -> First node
  WHILE node.succ AND (i<sel)
    node:=node.succ
    INC i
  ENDWHILE
  -> change mode
  ->PrintF('Change mode.\n')
  node.name[0]:=IF node.name[0]=" " THEN "·" ELSE " "

  ->list, sel_Ptr, listGad
  changeList(nameList3,{sel},listGad3)

  oldSel3:=sel
ENDPROC

PROC b_kick(info) IS Raise(ERR_OK)

PROC b_save(info)
  settxt(gh, txtGad1, 'Save! :)', SETSTR_MAX)
ENDPROC

PROC b_cancel(info) IS Raise(ERR_CANCEL)

PROC c_force(info,bool) IS f_force:=bool
PROC c_localfast(info,bool) IS f_localfast:=bool
PROC c_quickboot(info,bool) IS f_quickboot:=bool
PROC c_speedrom(info,bool) IS f_speedrom:=bool
PROC c_hogwaitblit(info,bool) IS f_hogwaitblit:=bool

PROC b_snew(info)
  PrintF('Newname: \s\n',asksetname(''))
ENDPROC
PROC b_sdel(info)
  PrintF('Set Del\n')
ENDPROC


PROC setgadgetattrs(gadget,taglist)
  DEF realgad
  IF realgad:=findgadget(gh, gadget)
    Gt_SetGadgetAttrsA(realgad, gh.wnd, NIL, taglist)
  ENDIF
ENDPROC



-> guiinit() locks Workbench screen! :(
PROC myeasygui(initcodeptr,windowtitle,gui,info=NIL,screen=NIL,textattr=NIL) HANDLE
  DEF res=-1,lock=0, gh=NIL:PTR TO guihandle

  IF Not(screen)
    lock:=LockPubScreen(NIL)
    screen:=lock
  ENDIF

  IF (gh:=guiinit(windowtitle,gui,info,screen,textattr))

    IF lock THEN UnlockPubScreen(NIL,lock)

    IF initcodeptr THEN initcodeptr(gh)

    WHILE res<0
      Wait(gh.sig)
      res:=guimessage(gh)
    ENDWHILE
  ELSE
    IF lock THEN UnlockPubScreen(NIL,lock)
  ENDIF
EXCEPT DO
  cleangui(gh)
  ReThrow()
ENDPROC res

/*
              [TEXT,'BlizKick version',NIL,FALSE,1],
              [TEXT,'1.10 (xx.xx.97)',NIL,TRUE,1]
*/
