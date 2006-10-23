; **************************************************************************************************
; Screen driver functionality. The routines are located in Bank 0.
;
; This file is part of the Z88 operating system, OZ.     0000000000000000      ZZZZZZZZZZZZZZZZZZZ
;                                                       000000000000000000   ZZZZZZZZZZZZZZZZZZZ
; OZ is free software; you can redistribute it and/    0000            0000              ZZZZZ
; or modify it under the terms of the GNU General      0000            0000            ZZZZZ
; Public License as published by the Free Software     0000            0000          ZZZZZ
; Foundation; either version 2, or (at your option)    0000            0000        ZZZZZ
; any later version. OZ is distributed in the hope     0000            0000      ZZZZZ
; that it will be useful, but WITHOUT ANY WARRANTY;    0000            0000    ZZZZZ
; without even the implied warranty of MERCHANTA-       000000000000000000   ZZZZZZZZZZZZZZZZZZZZ
; BILITY or FITNESS FOR A PARTICULAR PURPOSE. See        0000000000000000  ZZZZZZZZZZZZZZZZZZZZ
; the GNU General Public License for more details.
; You should have received a copy of the GNU General Public License along with OZ; see the file
; COPYING. If not, write to:
;                                  Free Software Foundation, Inc.
;                                  59 Temple Place-Suite 330,
;                                  Boston, MA 02111-1307, USA.
;
; Source code was reverse engineered from OZ 4.0 (UK) ROM and made compilable by Jorma Oksanen.
; Additional development improvements, comments, definitions and new implementations by
; (C) Jorma Oksanen (jorma.oksanen@gmail.com), 2003
; (C) Thierry Peycru (pek@users.sf.net), 2005-2006
; (C) Gunther Strube (gbs@users.sf.net), 2005-2006
;
; Copyright of original (binary) implementation, V4.0:
; (C) 1987,88 by Trinity Concepts Limited, Protechnic Computers Limited & Operating Systems Limited.
;
; $Id$
;***************************************************************************************************

        Module ScrDrv4

        include "blink.def"
        include "misc.def"
        include "sysvar.def"
        include "lowram.def"

xdef    Beep_X
xdef    CallFuncDE
xdef    ClearCarry
xdef    ClearEOL
xdef    ClearEOW
xdef    ClearScr
xdef    CursorDown
xdef    CursorLeft
xdef    CursorRight
xdef    CursorUp
xdef    FindSDCmd
xdef    GetWdStartXY
xdef    MoveToXY
xdef    NewXValid
xdef    NewYValid
xdef    OSBlp
xdef    OSSr
xdef    PutBoxChar
xdef    ResetScrAttr
xdef    RestoreScreen
xdef    SaveScreen
xdef    ScrDrvGetAttrBits
xdef    ScreenBL
xdef    ScreenClose
xdef    ScreenCR
xdef    ScreenOpen
xdef    ScrollDown
xdef    ScrollUp
xdef    SetScrAttr
xdef    ToggleScrDrvFlags

xref    AtoN_upper                              ; bank0/misc5.asm
xref    MS1BankA                                ; bank0/misc5.asm
xref    Delay300Kclocks                         ; bank0/misc3.asm
xref    DrawOZwd                                ; bank0/ozwindow.asm
xref    OSFramePop                              ; bank0/misc4.asm
xref    OSFramePush                             ; bank0/misc4.asm
xref    RdHeaderedData                          ; bank0/filesys3.asm
xref    WrHeaderedData                          ; bank0/filesys3.asm

xref    OSSR_main                               ; bank7/ossr.asm
xref    ScrD_GetNewXY                           ; bank7/scrdrv1.asm
xref    ScrD_PutByte                            ; bank7/scrdrv1.asm
xref    ScrDrvAttrTable                         ; bank7/scrdrv1.asm
xref    Zero_ctrlprefix                         ; bank7/scrdrv1.asm



; bind screen into S1, $7800-$7fff

.ScreenOpen
        pop     hl
        ld      a, (BLSC_SR1)
        push    af
        ld      a, (ubScreenBase)

.scr_bind
        push    hl
        jp      MS1BankA


.ScreenClose
        pop     hl
        pop     af
        jr      scr_bind

; move to x,y

.MoveToXY
        ld      c, a                            ; C=first arg, B=second arg
        ex      de, hl
        call    ScrD_GetNewXY
        call    NewXYValid
        ret     nc
        ex      de, hl
        ret

; search attribute table, return
; tHiLo in DE, ~tHiLo in BC
; chg: .FBCDE../....

.ScrDrvGetAttrBits
        call    AtoN_upper
        ld      c, a
.sdgab_1
        ld      a, (de)
        or      a
        ccf
        ret     z
        cp      c
        inc     de
        jr      z, sdgab_2
        inc     de
        inc     de
        jr      sdgab_1
.sdgab_2
        push    af
        push    hl
        ex      de, hl
        ld      a, (hl)
        ld      e, a                            ; tLo
        xor     $FF                             ; !! 'cpl'
        ld      c, a                            ; ~tLo
        inc     hl
        ld      a, (hl)
        ld      d, a                            ; tHi
        xor     $FF                             ; !! 'cpl'
        ld      b, a                            ; ~tHi
        pop     hl
        pop     af
        ret

;       ----

; out: Fc=0, DE=func
;  Fc=1, not found
.FindSDCmd
        ld      a, (sbf_VDUbuffer)
        call    AtoN_upper
        ld      c, a
        ld      a, (sbf_VDU1)
        call    AtoN_upper
        ld      b, a                            ; c,b = command
.sdfc_1
        ld      a, (de)
        or      a
        ccf
        ret     z                               ; not found Fc=1
        cp      c
        inc     de
        jr      nz, sdfc_next
        ld      a, (de)
        or      a
        jr      z, sdfc_match
        cp      b
        jr      z, sdfc_match
.sdfc_next
        inc     de
        inc     de
        inc     de
        jr      sdfc_1
.sdfc_match
        push    hl
        ex      de, hl
        inc     hl
        ld      e, (hl)
        inc     hl
        ld      d, (hl)
        pop     hl
        ret


; set attributes
.SetScrAttr
        dec     e                               ; E=-1
; reset attributes
;       ----
.ResetScrAttr
        ld      bc, sbf_VDUbuffer
.attr_1
        inc     bc
        ld      a, (bc)
        or      a
        ret     z
        exx
        ld      de, ScrDrvAttrTable
        call    ScrDrvGetAttrBits
        exx                                     ; if E=0 then just mask flags
        inc     e
        dec     e
        exx
        jr      nz, attr_2
        ld      de, 0                           ; no toggle bits
.attr_2
        call    nc, ToggleScrDrvFlags
        exx
        jr      attr_1

;       ----
.ToggleScrDrvFlags
        call    AtoN_upper
        ret     c                               ; not alpha
        ld      a, (ix+wdf_flagsLo)
        and     c
        xor     e                               ; tLo
        ld      (ix+wdf_flagsLo), a
        ld      a, (ix+wdf_flagsHi)
        and     b
        xor     d                               ; tHi
        ld      (ix+wdf_flagsHi), a
        ret

;       ----
; call function with following parameters:
; A,B,C - first 3 VDU arguments-$20
; E - 0
; Fc=1
.CallFuncDE
        ld      a, (sbf_VDU3)
        sub     $20
        ld      c, a                            ; arg3
        ld      a, (sbf_VDU2)
        sub     $20
        ld      b, a                            ; arg2
        ld      a, (sbf_VDU1)
        sub     $20                             ; arg1
        push    de
        ld      e, 0
        scf
        ret

; Box Characters
.PutBoxChar
        and     @00001111                       ; $01-0F
        or      @10000000                       ; $81-8F
        ld      bc, $fe01                      ;  LORES $181-$18F
        jp      ScrD_PutByte

.ScreenCR
        ld      l, (ix+wdf_startx)
        ret

;       ----
; cursor backwards
;
; Fc=0 if no line change
.CursorLeft
        bit     WDFH_B_HSCROLL, (ix+wdf_flagsHi)
        jr      z, bs_1
        ld      a, l
        cp      (ix+wdf_lmargin)
        ld      b, 0
        jr      z, bs_3                         ; need scrolling
.bs_1
        dec     l
        dec     l
        call    NewXValid
        jr      c, bs_2                         ; left edge? previous line
        inc     l
        ld      a, (hl)                         ; attributes
        dec     l
        and     LCDA_SPECMASK
        cp      LCDA_NULLCHAR
        jr      z, CursorLeft                   ; null char? backspace again
        cp      a                               ; Fc=0, Fz=1
        ret
.bs_2
        ld      l, (ix+wdf_endx)                ; end of line
        call    CursorUp                        ; previous line
        scf                                     ; Fc=1
        ret
.bs_3
        push    hl
        ld      d, h
        ld      l, (ix+wdf_lmargin)
        ld      e, (ix+wdf_rmargin)
        ld      a, e
        sub     l
        jr      z, bs_5
        ld      c, a                            ; bytes to copy
        inc     b                               ; test direction
        jr      z, bs_4
        dec     b                               ; B=0
        ld      l, e
        dec     l
        inc     e
        lddr                                    ; move chars right
        jr      bs_5
.bs_4
        ld      e, l
        inc     l
        inc     l
        ldir                                    ; move chars left
.bs_5
        pop     hl                              ; put $000, space
        xor     a
        ld      (hl), a
        inc     l
        ld      (hl), a
        dec     l
        ret

;       ----
; advance cursor
;
; Fc=0 if no line change
.CursorRight
        bit     WDFH_B_HSCROLL, (ix+wdf_flagsHi)
        jr      z, sdht_1
        ld      a, l
        cp      (ix+wdf_rmargin)
        ld      b, $ff
        jr      z, bs_3                         ; need scrolling
.sdht_1
        call    NewXValid
        jr      c, sdht_2                       ; right edge? next line
        inc     l
        inc     l
        inc     l
        ld      a, (hl)                         ; attributes
        dec     l
        and     LCDA_SPECMASK
        cp      LCDA_NULLCHAR
        jr      z, CursorRight                  ; null? forward again
        call    NewXValid
        ret     nc                              ; x ok, return Fc=0
.sdht_2
        ld      l, (ix+wdf_startx)              ; start of line
        call    CursorDown                      ; next line
        scf                                     ; Fc=1
        ret

;       ----

; previous line
.CursorUp
        call    ScrollLock
        dec     h
        call    NewYValid
        jr      c, vt_1
        cp      a                               ; Fc=0, no scrolling
        ret
.vt_1
        bit     WDFH_B_VSCROLL, (ix+wdf_flagsHi)
        jr      z, vt_2
        call    ScrollDown
        scf                                     ; Fc=1, screen scrolled
        ret
.vt_2
        ld      h, (ix+wdf_endy)                ; wrap to last line
        scf                                     ; Fc=1, wrap
        ret


;       ----

.CursorDown
        call    ScrollLock
        inc     h
        call    NewYValid
        jr      c, lf_1
        cp      a                               ; Fc=0, no wrap/scroll
        ret
.lf_1
        bit     WDFH_B_VSCROLL, (ix+wdf_flagsHi)
        jr      z, lf_3
        bit     WDFH_B_DELAY, (ix+wdf_flagsHi)
        jr      z, lf_2
        ex      de, hl
        call    Delay300Kclocks
        ex      de, hl

.lf_2
        call    ScrollUp                        ; scroll up
        scf                                     ; Fc=1, scroll
        ret

.lf_3
        ld      h, (ix+wdf_starty)              ; wrap to first line
        scf                                     ; Fc=1, wrap
        ret

;       ----

; freeze output if <> and lshift down

.ScrollLock
        ld      a, $bf                          ; row6
        in      a, (BL_KBD)
        add     a, $50                          ; check for sh-l and <> !! add a,$51
        inc     a
        jr      z, ScrollLock
        ret

;       ----

; clear to EOW

.ClearEOW
        push    hl
        call    ClearEOWm
        pop     hl
        ret
;       ----
.ClearScr
        ld      c, (ix+wdf_OpenFlags)
        bit     WDFO_B_BORDERS, c
        call    nz, WdBorders
        call    Zero_ctrlprefix
        call    GetWdStartXY

.ClearEOWm
        call    sub_FD8B
        ld      a, (ix+wdf_OpenFlags)
        bit     WDFO_B_6, a
        jr      z, ff_2
        ld      bc, [LCDA_HIRES|LCDA_UNDERLINE|LCDA_CH8]<<8|$A0
        bit     WDFO_B_5, a
        jr      z, ff_2
        ld      bc, [LCDA_REVERSE|LCDA_FLASH|LCDA_GREY|LCDA_UNDERLINE|LCDA_CH8]<<8|$FF

.ff_2
        call    ceol_1
        ret     c
        call    GetWdStartX                     ; !! stupidity, ld it here
        ld      e, (ix+wdf_flagsHi)
        push    de
        res     WDFH_B_VSCROLL, (ix+wdf_flagsHi)
        call    CursorDown
        pop     de
        ld      (ix+wdf_flagsHi), e
        jr      nc, ff_2

.GetWdStartXY
        ld      h, (ix+wdf_starty)
.GetWdStartX
        ld      l, (ix+wdf_startx)
        ret

;       ----

.ClearEOL
        call    sub_FD8B

.ceol_1
        call    NewXYValid
        ret     c
        push    hl

.ceol_2
        bit     WDFO_B_6, (ix+wdf_OpenFlags)
        jr      z, ceol_4

        ld      a, l
        sub     (ix+wdf_startx)                 ; left offset
        bit     1, a                            ; check mod(xpos,4)=0
        jr      nz, ceol_3
        bit     2, a
        jr      nz, ceol_3
        ld      a, LCDA_NULLCHAR
        inc     hl
        ld      (hl), a
        jr      ceol_9

.ceol_3
        bit     WDFO_B_5, (ix+wdf_OpenFlags)
        jr      z, ceol_4
        inc     bc                              ; increment char

.ceol_4
        bit     WDFO_B_GREY, (ix+wdf_OpenFlags)
        jr      z, ceol_6

        ld      c, (hl)                         ; char
        inc     hl
        ld      a, (hl)                         ; attrs
        dec     hl

        bit     LCDA_B_GREY, a
        res     LCDA_B_TINY, a
        jr      z, ceol_5
        or      LCDA_TINY
.ceol_5
        or      LCDA_GREY
        ld      b, a
.ceol_6
        bit     WDFO_B_UNGREY, (ix+wdf_OpenFlags)
        jr      z, ceol_8
        ld      c, (hl)                         ; char
        inc     hl
        ld      a, (hl)                         ; attr
        dec     hl
        bit     LCDA_B_TINY, a
        res     LCDA_B_GREY, a
        jr      z, ceol_7
        or      LCDA_GREY

.ceol_7
        and     $7f                     ; ~LCDA_TINY
        ld      b, a

.ceol_8
        ld      (hl), c
        inc     hl
        ld      (hl), b
.ceol_9
        dec     hl
        ld      e, (ix+wdf_flagsHi)
        push    de
        res     WDFH_B_VSCROLL, (ix+wdf_flagsHi)
        inc     l
        inc     l
        call    NewXValid
        pop     de
        ld      (ix+wdf_flagsHi), e
        jr      nc, ceol_2
        pop     hl
        cp      a
        ret

;       ----

.ScrollUp
        push    hl
        ld      h, (ix+wdf_starty)

.su_1
        inc     h
        call    su_2
        jr      nc, su_1

        dec     h
        ld      l, (ix+wdf_startx)
        call    ClearEOL
        pop     hl
        dec     h
        call    NewYValid
        ret     nc
        inc     h
        cp      a
        ret

.su_2
        call    NewYValid
        ret     c
        dec     h
        call    NewYValid
        ld      d, h
        inc     h
        ret     c
        ld      l, (ix+wdf_startx)
        ld      e, l
        ld      a, (ix+wdf_endx)
        sub     l
        inc     a
        inc     a
        ld      c, a
        ld      b, 0
        ldir
        cp      a
        ret

.ScrollDown
        push    hl
        ld      h, (ix+wdf_endy)

.sd_1
        dec     h
        call    sd_2
        jr      nc, sd_1
        inc     h
        ld      l, (ix+wdf_startx)
        call    ClearEOL
        pop     hl
        inc     h
        call    NewYValid
        ret     nc
        dec     h
        cp      a
        ret

.sd_2
        call    NewYValid                       ; !! add hl,bc etc to re-use code
        ret     c
        inc     h
        call    NewYValid
        ld      d, h
        dec     h
        ret     c
        ld      l, (ix+wdf_startx)
        ld      e, l
        ld      a, (ix+wdf_endx)
        sub     l
        inc     a                               ; width
        inc     a
        ld      c, a
        ld      b, 0
        ldir
        cp      a
        ret

;       ----

.GetWdEnd
        ld      l, (ix+wdf_endx)
        ld      h, (ix+wdf_endy)
        ret

;       ----

.sub_FD8B
        ld      a, (ix+wdf_flagsLo)
        and     WDFL_REVERSE|WDFL_FLASH|WDFL_GREY|WDFL_ULINE
        ld      b, a
        ld      c, 0
        ret

;       ----
.WdBorders
        ld      a, (ix+wdf_endy)
        sub     (ix+wdf_starty)
        inc     a
        ld      b, a                            ; height
        push    bc

;       draw left border

        call    GetWdStartXY                    ; !! stupidity, ld l,wdf_startx here
        dec     l                               ; left one char
        dec     l
        ld      h, (ix+wdf_endy) ; last line

.bd_1
        ld      (hl), $8A                       ; VDU $18A, vertical bar
        inc     l
        ld      (hl), 1
        dec     l
        dec     h                               ; previous line
        djnz    bd_1

        bit     WDFO_B_BRACKETS, c
        jr      z, bd_2                         ; no brackets
        inc     h                               ; 1st line
        ld      (hl), $BE                       ; VDU $1BE, window left bracket
        inc     l
        ld      (hl), 1

.bd_2
        pop     bc

;       draw right border

        call    GetWdEnd
        inc     l                               ; right one char
        inc     l

.bd_3
        ld      (hl), $8A                       ; VDU $18A, vertical bar
        inc     l
        ld      (hl), 1
        dec     l
        dec     h                               ; previous line
        djnz    bd_3

        bit     WDFO_B_BRACKETS, c
        ret     z                               ; no brackets
        inc     h                               ; last line
        ld      (hl), $BF                       ; VDU $1BF, window right bracket
        inc     l
        ld      (hl), 1
        ret

;       ----

.ClearCarry
        cp      a                               ; nop routine, remove
        ret

;       ----

.NewXYValid
        call    ClearCarry
        ret     c
        call    NewYValid
        ret     c

;       Fc=0 if L inside window

.NewXValid
        ld      a, l
        cp      (ix+wdf_startx)                 ; Fc=1 if L<StartX
        ret     c
        cp      (ix+wdf_endx)
        jr      nz, nxv_1                       ; Fc=0 if L<=EndX  !! ret z; ccf; ret
        scf
.nxv_1
        ccf
        ret

;       Fc=0 if H inside window

.NewYValid
        ld      a, h
        cp      (ix+wdf_starty)                 ; Fc=1 if H<StartY
        ret     c
        cp      (ix+wdf_endy)
        jr      nz, nyv_1                       ; Fc=0 if H<=EndY  !! ret z; ccf; ret
        scf
.nyv_1
        ccf
        ret


; Beep sequence (VDU)

.OSBlp
        push    hl
        ld      hl, ubSoundActive
        ex      af, af'
        call    OZ_DI

        ex      af, af'
        cp      1                               ; Fc=1 if A=0
        rl      a                               ; A=2*A, 1 if A was 0
        ld      (hl), 1
        inc     hl
        ld      (hl), a                         ; sound count
        inc     hl
        ld      (hl), b                         ; space count
        inc     hl
        ld      (hl), c                         ; mark count

        ex      af, af'
        call    OZ_EI
        pop     hl
        or      a
        ret

.Beep_X
        push    af
        push    bc
        ld      a, 2
        ld      bc, $50A
        jr      bl_1

.ScreenBL
        push    af
        push    bc
        ld      a, 1
        ld      bc, $14

.bl_1
        CALL_OZ OS_Blp                          ; Bleep
        pop     bc
        pop     af
        ret

;       ----

.OSSr
        call    OSFramePush
        push    bc
        ld      b, a
        pop     af
        call    OSSR_main
        jp      OSFramePop

;       ----

.RestoreScreen
        ld      e, 0
        jr      SrScreen

.SaveScreen
        ld      e, -1

.SrScreen
        call    ScreenOpen
        ld      h, SBF_PAGE                     ; address high byte
        ld      b, 8                            ; lines to do

.srs_1
        push    bc
        push    hl
        ld      a, $A3                          ; this type
        ld      bc, 2*114                       ; this many bytes
        ld      l, 2*10                         ; address low byte - skip 10 chars
        call    srscr_rwline
        pop     hl
        pop     bc
        jr      c, srs_2
        inc     h                               ; next line
        djnz    srs_1
        call    DrawOZwd
        or      a

.srs_2
        ex      af, af'
        call    ScreenClose
        ex      af, af'
        ret

.srscr_rwline
        push    de
        inc     e
        jr      z, srscr_wline
        call    RdHeaderedData
        pop     de
        ret

.srscr_wline
        call    WrHeaderedData
        pop     de
        ret