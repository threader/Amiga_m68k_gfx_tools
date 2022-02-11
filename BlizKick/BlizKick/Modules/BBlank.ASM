; FILE: Source:modules/BBlank.ASM          REV: 2 --- BorderBlank

*
* Modified by Harry Sintonen. Changes by me are marked with ;hs comment.
*

;
; BorderBlank-Module for BlizKick
; ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
; Written by Jens Lorenz.
; This source code is Public Domain.

        incdir  "Include:"
        include "blizkickmodule.i"              ; Some required...

_LVOOpenLibraryTagged   EQU   -$32A
_LVOCloseLibrary        EQU   -$19E

        SECTION MODULE,CODE
_DUMMY_LABEL
 BK_MOD BKMF_SingleMode,_end,(RTF_COLDSTART)<<24+39<<16+NT_UNKNOWN<<8+(256-48),_name,_idstr,_init  ;hs
; Singlemode on,
; COLDSTART module, requires KS V39.x or better, module type NT_UNKNOWN, priority -48.
; before BootMenu -> in BootMenu BBlank already activated

;hs  Note that if you need to have negative priority (-pri) you *must* use
;hs  +(256-pri). For example to get priority -48 use +(256-48).

_init   move.l  (4).w,a6
        moveq   #1,d0
        jsr     _LVOOpenLibraryTagged(a6)       ; open graphics.library
        tst.l   d0                              ;hs Need to be tested!
        beq.b   .exit                           ; sorry, but we need the gfx-lib
        move.l  d0,a1

        bset.b  #5,$1E3(a1)                     ; set the magic bit in bp3bits of gfxbase
* RemakeDisplay() not needed -> no Screen open

        jmp     _LVOCloseLibrary(a6)            ; close the gfx-lib ;hs exit

.exit   rts

_name   dc.b    'BBlank',0
_idstr  dc.b    'BBlank 1.0 (8.4.97)',0
        CNOP    0,2
_end

        SECTION VERSION,DATA

        dc.b    '$VER: BBlank_MODULE 1.0 (8.4.97)',0
