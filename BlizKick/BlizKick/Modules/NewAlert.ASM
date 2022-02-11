; FILE: Source:modules/NewAlert.ASM          REV: 6 --- Display more info on Alert

*
* Modified by Harry Sintonen.
*
*   2.4.97  v2.0: removed self-modifying code.
*  11.9.00  v2.1: slightly improved the code in general, added MMU aware
*                 address zero clearing.
*

; NewAlert - Shows the Taskname within an Alert
; © Jens Lorenz 1997
; © Harry Sintonen 2000
;
; very strongly based upon:

;
; Example BlizKick Module
; ~~~~~~~~~~~~~~~~~~~~~~~
; This code shows how to create replacing BlizKick "Module".
; Should be quite self-explonary... (?)
;
; !CODE MUST BE FULLY PC-RELATIVE!
;
; Written by Harry Sintonen.
; This source code is Public Domain.

        incdir  "include:"
        include "exec/execbase.i"
        include "exec/nodes.i"
        include "exec/tasks.i"
        include "exec/alerts.i"
        include "dos/dosextens.i"
        include "blizkickmodule.i"              ; Some required...

_LVOSupervisor          EQU   -$1E
_LVORawDoFmt            EQU   -$20A
_LVOOpenLibraryTagged   EQU   -$32A
_LVOTimedDisplayAlert   EQU   -$336
_LVOCloseLibrary        EQU   -$19E


        SECTION MODULE,CODE

_DUMMY_LABEL
        BK_MOD BKMF_ReplaceMode!BKMF_ExtResBuf,_end,(RTF_COLDSTART)<<24+39<<16+NT_UNKNOWN<<8+$C9,_name,_name,_init

; Replace mode on, requires EXTRESBUF buffer, COLDSTART module, requires KS V39.x or better,
; module type NT_UNKNOWN, priority -55.

STACKBUF        EQU   300                       ; +100 - just to be safe ...

;  IN: a6 = execbase
        dc.l    'NewA'                          ; magic ID (don't change or move!)
_init   bsr.w   clear0                          ; clear 0 longword (don't move! must be .w!)
        movem.l d2/d3/a2/a3/a6,-(sp)		; the movem must be at _init + 4 !

        move.l  LastAlert(a6),d2
        moveq   #-1,d0                          ; Display no alert?
        sub.l   a2,a2                           ; return code = 0
        cmp.l   d0,d2
        beq     .exit

        lea     -STACKBUF(sp),sp
        move.l  sp,a3

        ; default: 'Software Failure'
        lea     SoftFail(pc),a0
        move.l  d2,d0
        swap    d0
        cmp.b   #(AG_NoMemory>>16),d0
        bne.b   .skip0
        ; 'not enough memory'
        lea     NoMem(pc),a0
        bra.b   .skip1
.skip0
        tst.l   d2                              ; AT_DeadEnd set?
        bmi.b   .skip1
        tst.w   d0                              ; general purpose alert code defined?
        beq.b   .skip1
        ; 'Recoverable Alert'
        lea     Recoverable(pc),a0
.skip1
        bsr     .dostr
        lea     PressLeftie(pc),a0
        bsr     .dostr
        lea     Copyright(pc),a0
        bsr     .dostr

        clr.b   (a3)+                           ; put x-pos upper
        lea     ErrorFmt(pc),a0
        lea     LastAlert(a6),a1
        lea     .PutChar(pc),a2
        jsr     _LVORawDoFmt(a6)
        lea     37(a3),a3                       ; Adjust a3
        st      (a3)+

* decode the TaskName / CLICommandName *
        lea     NoTask(pc),a2                   ; No Task
        move.l  (LastAlert+4)(a6),d0            ; ^Task -> d0
        beq     .fmttaskname                    ; if 0
        move.l  d0,a0                           ; Task/Process
        cmp.b   #NT_TASK,LN_TYPE(a0)            ; is it a task?
        beq.b   .task                           ; no CLI-Checking needed

        ; ok, it's a process, check if it's a CLI too

        move.l  pr_CLI(a0),d0                   ; process.cli -> d0
        beq.b   .task                           ; no cli-struct -> get the Taskname
        subq.l  #8,sp
        move.l  pr_TaskNum(a0),(sp)             ; store process.tasknum
        lsl.l   #2,d0                           ; d0 was a BPTR !!!
        move.l  d0,a0                           ; BADDR(process.cli) -> a0
        move.l  cli_CommandName(a0),d0          ; cli.commandname -> a0
        beq.b   .nocliname                      ; NULL name? hs
        move.l  d0,4(sp)                        ; cli.commandname -> ArgArray
        lsl.l   #2,d0                           ; d0 was a BSTR
        move.l  d0,a0
        tst.b   (a0)                            ; Length = 0 ?
        bne.b   .fmtcliname                     ;  -> got CommandName there

.nocliname
        lea     NoCLIName(pc),a0                ; get the errorstring
        move.l  a0,d0
        lsr.l   #2,d0                           ; -> BPTR
        move.l  d0,4(sp)
;        bra.b   .fmtcliname

* Format the CLICommandName + CLI-Number *
.fmtcliname
        lea     CLINameFmt(pc),a0
        move.l  sp,a1
        lea     .PutChar(pc),a2
        jsr     _LVORawDoFmt(a6)
        addq.l  #8,sp
        bra.b   .display                        ; display the alert

* It's a task *
.task
        lea     NoTaskName(pc),a2               ; default: No TaskName
        move.l  LN_NAME(a0),d0                  ; tc.ln.name = NULL ?
        beq.b   .fmttaskname
        move.l  d0,a0
        tst.b   (a0)                            ; Len = 0 ?
        beq.b   .fmttaskname
        move.l  a0,a2                           ; use the tc.ln.name

* Format the TaskName *
.fmttaskname
        lea     TaskNameFmt(pc),a0
        move.l  a2,-(sp)                        ; a2 = ^TaskName
        move.l  sp,a1
        lea     .PutChar(pc),a2
        jsr     _LVORawDoFmt(a6)
        addq.l  #4,sp
;        bra.b  .display

.display
        moveq   #3,d0                           ; 3=intuition.library
        jsr     _LVOOpenLibraryTagged(a6)       ; if this fails we're fucked anyway :-)
        move.l  (LastAlert+3*4)(a6),a1          ; alert timeout
        move.l  a6,a3
        move.l  d0,a6
        move.l  d2,d0                           ; alert number
        move.l  sp,a0                           ; alert string
        moveq   #70,d1                          ; alert y-size
        jsr     _LVOTimedDisplayAlert(a6)
        move.l  d0,a2
        move.l  a6,a1
        move.l  a3,a6
        jsr     _LVOCloseLibrary(a6)

        lea     STACKBUF(sp),sp

        bsr     clear0                          ; clear 0 longword

        moveq   #-1,d0                          ; No alert on next round, please!
        move.l  d0,LastAlert(a6)

.exit   move.l  a2,d0
        movem.l (sp)+,d2/d3/a2/a3/a6
        rts

* Copy the whole String *
.dostr  clr.b   (a3)+
.copy   move.b  (a0)+,(a3)+
        bne.b   .copy
        st      (a3)+
        rts

* Copy one Char *
.PutChar
        move.b  d0,(a3)+
        clr.b   (a3)
        rts

; routine that makes sure the longword at position 0 is really set
; to zero. (Blizzard PPCs have MMU setup active at alert.hook time!)

;  IN: a6 = execbase
; OUT: d1/a0/a1 trashed
clear0	btst	#3,$129(a6)		; do we have 68040 or 68060?
	beq.b	.no040plus

	move.l	a5,a0
	lea	.clrit(pc),a1
	lea	runnommu_s(pc),a5
	jsr	_LVOSupervisor(a6)
	move.l	a0,a5
.no040plus
.clrit	clr.l	(0).w
	rts

;  IN: a1 = routine to run in supervisor, mmu disabled, end with rts
;      d0/d2-d7/a0/a2-a4 = whatever you like
;      a6 = execbase
; OUT: d1 = trashed
;      d0/d2-d7/a0/a2-a4 = whatever you like
;
runnommu_s
	ori.w	#$700,sr

	movec	tc,d1
	move.l	d1,-(sp)
	movec	cacr,d1
	move.l	d1,-(sp)
	movec	dtt1,d1
	move.l	d1,-(sp)
	movec	dtt0,d1
	move.l	d1,-(sp)
	movec	itt1,d1
	move.l	d1,-(sp)
	movec	itt0,d1
	move.l	d1,-(sp)
	cpusha	bc			;make sure the above is written
	cinva	bc

	move.l	#$00FFC000,d1		;mark 32-bit: Cacheable, Writethrough
	movec	d1,itt0	
	movec	d1,itt1
	movec	d1,dtt1
	move.l	#$0000C040,d1		;mark 24-bit-DMA: Cache-Inhibited, Precise Exception Model
	movec	d1,dtt0
	move.l	#$80008000,d1		;instcache + datacache
	movec	d1,cacr
	moveq	#0,d1			;turn off possible MMU mapping
	pflusha
	movec	d1,tc
	cpusha	bc
	cinva	bc

	jsr	(a1)

	cpusha	bc
	move.l	(sp)+,d1
	movec	d1,itt0
	move.l	(sp)+,d1
	movec	d1,itt1
	move.l	(sp)+,d1
	movec	d1,dtt0
	move.l	(sp)+,d1
	movec	d1,dtt1
	move.l	(sp)+,d1
	movec	d1,cacr
	move.l	(sp)+,d1
	pflusha
	movec	d1,tc
	cpusha	bc
	cinva	bc
	nop
	rte


************** Data **************

_name   dc.b    'alert.hook',13,10,0

        CNOP    0,4                             ; we make BPTR of NoCLIName..
NoCLIName
        dc.b    18,'» No CommandName «',0

APOS1   MACRO
        IFNE    ((\1)>>8)
        FAIL    APOS1: x-position can't be >255 !
        MEXIT
        ENDC
        dc.b    ((\1)&$ff),(\2)
        ENDM
APOS2   MACRO
        IFEQ    ((\1)>>8)
        FAIL    APOS2: x-position can't be <256 !
        MEXIT
        ENDC
        dc.b    ((\1)>>8),((\1)&$ff),(\2)
        ENDM

NoMem   APOS1   38,15
        dc.b    'not enough memory.',0
SoftFail
        APOS1   38,15
        dc.b    'Software Failure.',0
Recoverable
        APOS1   38,15
        dc.b    'Recoverable Alert.',0
EBTrashed
        APOS1   38,15
        dc.b    'ExecBase Trashed.',0
Copyright
        APOS1   38,60
        dc.b    '(NewAlert by Jens Lorenz 1997 & Harry Sintonen 2000)',0
PressLeftie
        APOS1   234,15
        dc.b    'Press left mouse button to continue.',0
ErrorFmt
        APOS1   142,30
        dc.b    'Error:  %04x %04x   Task: %08lx',0

TaskNameFmt
        APOS2   270,45
        dc.b    'TaskName: %-35.35s',0
CLINameFmt
        APOS2   270,45
        dc.b    'CLI #%-3.3ld: %-35.35b',0

NoTask
        dc.b    '» No Task «',0
NoTaskName
        dc.b    '» No TaskName «',0

        CNOP    0,2
_end


   SECTION  VERSION,DATA

        dc.b    '$VER: alert.hook_MODULE 2.1 (11.9.00)',0

