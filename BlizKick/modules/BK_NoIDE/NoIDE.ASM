; FILE: Source:modules/NoIDE.ASM          REV: 1 --- NoIDE patch (better: hack)

;
; NoIDE -Module
; ~~~~~~~~~~~~~~~~~~~~~
; This patch module disables the scsi.device (irritating name: it manages the IDE-interface)
; If you don't have an IDE-HD, the boot process takes up to 30 secs longer than with one
; as the scsi.device tries to find a HD on every startup...
; NOTE: You can't access any IDE-devices with this patch installed! (Ach was...) ;)
;
; Written by Christian Sauer.
; This source code is Public Domain.
;

	include "blizkickmodule.i"      ; Some required...


	SECTION PATCH,CODE
_DUMMY_LABEL
	BK_PTC

; Code is run with following incoming parameters:
;
; a0=ptr to ROM start (buffer)  eg. $1DE087B8
; a1=ptr to ROM start (ROM)     eg. $00F80000 (do *not* access!)
; d0=ROM lenght in bytes        eg. $00080000
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

	moveq   #0,d7

	cmp.w   #37,($C,a0)                  ; Requires KS V37+
	blo.b   .exit

	lea     (_atname,pc),a1              ; _FindResident
	jsr     (a2)
	tst.l   d0
	beq.b   .exit
	move.l  d0,a2                        ; a2=scsi resident

	cmp.b   #37,(RT_VERSION,a2)          ; V37+
	blo.b   .exit
	bclr    #RTB_COLDSTART,(RT_FLAGS,a2) ; clear Coldstart-Flag
	moveq   #1,d7

.exit   move.l  d7,d0                        ; Valid counter?
	bne.b   .xit
	lea     (_error,pc),a0               ; a0=fmt
	pea     (_atname,pc)
	move.l  sp,a1                        ; a1=array
	jsr     (a4)                         ; Call _Printf
	addq.l  #4,sp
.fail   moveq   #0,d0                        ; Return fail
.xit    rts


_atname dc.b    'scsi.device',0

_error  dc.b    'NoIDE: This patch requires %s V37+!',10,0


	SECTION VERSION,DATA

	dc.b    '$VER: NoIDE_PATCH 1.0 (1.1.97)',0
