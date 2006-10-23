; **************************************************************************************************
; OZ Process functionality. The routines are located in Bank 0.
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

        Module Process3

        include "blink.def"
        include "director.def"
        include "error.def"
        include "fileio.def"
        include "syspar.def"
        include "sysvar.def"
        include "lowram.def"

xdef    ApplCaps
xdef    InitHlpActiveCmd
xdef    InitHlpActiveHelp
xdef    SetHlpActiveHelp
xdef    OSBye
xdef    OSEnt
xdef    OSExit
xdef    OSStk
xdef    OSUse

xref    AllocBadRAM1                            ; bank0/process2.asm
xref    BadAllocAndSwap                         ; bank0/process2.asm
xref    BadSwapAndFree                          ; bank0/process2.asm
xref    FreeBadRAM                              ; bank0/process2.asm
xref    IsBadUgly                               ; bank0/process2.asm
xref    sub_C2F3                                ; bank0/process2.asm
xref    sub_C39F                                ; bank0/process2.asm

xref    AllocMemFile_SizeHL                     ; bank0/filesys3.asm
xref    GetFileSize                             ; bank0/filesys3.asm
xref    RestoreAllAppData                       ; bank0/filesys3.asm
xref    SaveAllAppData                          ; bank0/filesys3.asm
xref    CancelOZcmd                             ; bank0/osin.asm
xref    ostin_4                                 ; bank0/osin.asm
xref    DORHandleFreeDirect                     ; bank0/dor.asm
xref    DrawOZwd                                ; bank0/ozwindow.asm
xref    InitApplWd                              ; bank0/scrdrv3.asm
xref    ScreenClose                             ; bank0/scrdrv4.asm
xref    ScreenOpen                              ; bank0/scrdrv4.asm
xref    MS1BankB                                ; bank0/misc5.asm
xref    MS2BankK1                               ; bank0/misc5.asm
xref    PutOSFrame_BHL                          ; bank0/misc5.asm
xref    OSFramePush                             ; bank0/misc4.asm
xref    OSFramePop                              ; bank0/misc4.asm
xref    SetActiveAppDOR                         ; bank0/mth2.asm

xref    ChkStkLimits                            ; bank7/process1.asm
xref    ClearMemDE_HL                           ; bank7/process1.asm
xref    ClearUnsafeArea                         ; bank7/process1.asm
xref    Mailbox2Stack                           ; bank7/process1.asm
xref    CopyMTHHelp_App                         ; bank7/mth1.asm
xref    DrawTopicWd                             ; bank7/mth1.asm
xref    OpenAppHelpFile                         ; bank7/mth1.asm
xref    InitUserAreaGrey                        ; bank7/scrdrv1.asm
xref    OSSr_Fus                                ; bank7/ossr.asm


;       ----

;       quit process (application)

.OSExit
        ld      a, RC_Quit                      ; exit
        jr      osent_1

;       enter an application

.OSEnt
        ld      a, RC_Draw                      ; enter

.osent_1
        push    ix
        push    iy
        ex      af, af'                         ; save Fc

        exx
        ld      de, $1ffe                       ; BC=used stack size
        ld      hl, 0
        add     hl, sp
        ex      de, hl
        sbc     hl, de
        ld      b, h
        ld      c, l

        ex      de, hl
        ld      de, stkBottom
        ld      (pStkEntUsedStkBottom), hl      ; used stack low limit
        ld      (uwStkEntUsedStkSize), bc       ; used stack size
        ldir                                    ; move down to stkBottom

        ex      de, hl                          ; reserve 256 bytes for temp stack
        ld      de, 256
        add     hl, de
        ld      (pStkTempStkTop), hl
        ld      sp, hl
        exx

        ex      af, af'                         ; restore Fc
        inc     b
        dec     b
        jp      z, osent_12                     ; enter/exit new process

        scf
        push    af                              ; A=RC, Fc=1, Fz=0

        ld      (pOSEntHandle), hl              ; IX=(pOSEntHandle)
        push    hl
        pop     ix
        call    RestoreAllAppData
        jr      z, osent_3                      ; didn't restore screen? skip

        pop     bc                              ; pop AF - we do this in BC to  keep flags
        ld      a, b
        cp      RC_Draw
        jr      nz, osent_2                     ; not OS_Ent? skip
        ld      b, RC_Susp                      ; change RC_Draw into RC_Susp as screen is OK
.osent_2
        push    bc                              ; push AF

.osent_3
        pop     af                              ; prepare for call point at osent_4
        ld      ix, (uwAppStaticHnd)

.osent_4
        ld      sp, (pAppStackPtr)
        push    af

        ld      (uwAppStaticHnd), ix
        ld      a, (uwAppStaticHnd)
        call    InitAppMTH

        ld      a, SC_RES
        OZ      OS_Esc                          ; reset escape without flushing the input buffer
        call    ClearUnsafeArea                 ; always cleared

        pop     af
        push    af
        cp      RC_Quit
        jr      z, osent_5                      ; OS_Exit? skip

        ld      hl, (uwAppEnvOverhead)          ; allocate env file
        call    AllocMemFile_SizeHL
        call    MS2BankK1
        call    SetAppEnvHandle                 ; ld (pAppEnvHandle),ix  !! do it here
        jr      c, osent_10                     ; no file? cleanup and exit

.osent_5
        call    CancelOZcmd
        call    ScreenOpen
        xor     a                               ; clear these for first entry
        ld      (sbf_CtrlPrefix), a
        ld      (PrtSeqPrefix), a
        call    ScreenClose

        call    BadAllocAndSwap
        jr      nc, osent_6                     ; got memory? ok
        pop     af
        push    af
        cp      RC_Quit
        jr      nz, osent_9                     ; OS_Ent? cleanup and exit with Fc=1

.osent_6
        pop     af
        push    af
        xor     RC_Draw                         ; Fc=0 for ApplCaps, Fz=need_redraw flag
        ld      a, (ubAppDORFlags)
        jr      nz, osent_7                     ; no redraw needed? skip

        bit     AT_B_Popd, a
        call    z, InitApplWd                   ; not popdown? init window
.osent_7
        bit     AT_B_Popd, a
        call    z, ApplCaps                     ; not popdown? restore flags (Fc=0)

        call    DrawTopicWd

        ld      e, 0                            ; free bad app extra swap memory
        call    sub_C39F

        ld      ix, (pOSEntHandle)              ; free saved screen
        call    OSSr_Fus

        pop     af
.osent_8
        call    OSEntSub                        ; prepare for enter
        jp      ostin_4                         ; enter thru OS_Tin

.osent_9
        call    sub_C2F3                        ; free all bad memory
        ld      e, -1                           ; free memory marked SWAP
        call    sub_C39F
        call    CloseAppEnvHandle               ; close AppEnvHandle

.osent_10
        pop     hl
        inc     h
        dec     h
        call    z, FreeBadRAM                   ; RC_OK? free

.osent_11
        ld      hl, stkBottom                   ; restore stack
        ld      de, (pStkEntUsedStkBottom)
        ld      bc, (uwStkEntUsedStkSize)
        ldir
        ld      sp, (pStkEntUsedStkBottom)      ; restore SP, IY, IX
        pop     iy
        pop     ix
        scf
        ret

;       enter/exit new process

.osent_12
        cp      RC_Draw
        scf
        jr      nz, osent_8                     ; OS_Exit? return with Fc=1

        push    bc                              ; clear 64 bytes of app variables
        ld      bc, $3F
        ld      de, uwAppStaticHnd+1
        ld      hl, uwAppStaticHnd
        ld      (hl), 0                         ; !! ld (hl), b
        ldir
        pop     bc

        ld      a, 1
        ld      (ubAppCallLevel), a
        ld      a, c
        ld      (ubAppDynID), a
        ld      (uwAppStaticHnd), ix
        ld      a, (uwAppStaticHnd)
        call    SetActiveAppDOR
        call    CopyMTHHelp_App
        ld      bc, NQ_Ain
        OZ      OS_Nq                           ; enquire (fetch) parameter
        ld      (ubAppDORFlags), a
        bit     AT_B_Popd, a
        call    nz, InitUserAreaGrey            ; popdown? init screen
        call    MS1BankB
        set     6, d                            ; DOR in S1
        push    de
        set     6, h                            ; name in S1
        call    OpenAppHelpFile
        jr      c, osent_13                     ; no help file? skip
        ld      (pAppHelpHandle), ix
        ld      a, (ix+fhnd_Bank)
        ld      (ubAppHelpBank), a
        call    CopyMTHHelp_App
.osent_13
        pop     ix
        ld      hl, $1FFE
        ld      e, (ix+ADOR_UNSAFE)             ; DE=unsafe needed
        ld      d, (ix+ADOR_UNSAFE+1)
        or      a
        sbc     hl, de
        ld      (pAppUnSafeArea), hl
        ld      c, (ix+ADOR_SAFE)               ; BC=safe needed
        ld      b, (ix+$16)
        sbc     hl, bc
        call    IsBadUgly
        jr      z, osent_14                     ; nice? no extra stack
        ld      de, -320                        ; 40*PAGES_PER_KB*WORD_SIZEOF
        add     hl, de
        ld      (pAppBadMemTable), hl
.osent_14
        ld      sp, hl
        ex      de, hl
        ld      hl, (pAppUnSafeArea)
        call    ClearMemDE_HL                   ; clear safe workspace and bad allocation table
        ld      a, (ix+ADOR_FLAGS2)
        ld      b, a
        and     AT2_Cl|AT2_Icl                  ; caps/CAPS state
        ld      (ubAppKbdBits), a
        ld      a, b
        ld      (ubAppDORFlags2), a
        and     AT2_Ie                          ; ignore errors?
        rlca                                    ; defult error handler is either $00e0 or $00e1
        ld      hl, DefErrHandler
        add     a, l
        ld      l, a
        ld      a, 1
        OZ      OS_Erh                          ; Set (install) Error Handler
        ld      (ubOldCallLevel), a
        ld      a, SC_DIS
        OZ      OS_Esc                          ; disable escape detection
        ld      l, (ix+ADOR_ENVSIZE)            ; HL=env overhead
        ld      h, (ix+$12)
        ld      (uwAppEnvOverhead), hl
        ld      a, (ix+ADOR_BADSIZE)
        ld      (ubAppContRAM), a
        ld      l, (ix+ADOR_ENTRY)              ; HL=entry point
        ld      h, (ix+$18)
        push    hl
        ld      (pAppEntrypoint), hl
        push    ix                              ; point HL to bindings
        pop     hl
        ld      de, ADOR_BINDINGS
        add     hl, de
        ld      de, ubAppBindings
        ld      a, (eHlpAppDOR+2)
        and     $c0                            ; slot base
        ld      c, a
        ld      b, 4
.osent_15
        ld      a, (hl)                         ; get wanted binding
        or      a
        jr      z, osent_16                     ; zero? don't care
        and     $3F                             ; mask out slot
        or      c                               ; and replace with correct slot
.osent_16
        ld      (de), a                         ; store fixed bank
        inc     hl
        inc     de
        djnz    osent_15
        call    AllocBadRAM1
        jp      c, osent_11                     ; no memory? exit with Fc=1
        ld      hl, (ubAppBindings+2)           ; S3S2
        push    hl                              ; for OSFramePush
        ld      a, l
        ld      (BLSC_SR2), a
        ld      bc, 0
        ld      h, b
        ld      l, c
        ld      (pOSEntHandle), hl
        ld      de, unk_1864
        exx
        call    OSFramePush
        ld      ix, OSFramePop                  ; for the return
        push    ix
        ld      hl, word_1853
        push    hl
        ld      (hl), 3                         ; 03 20 .. 00
        inc     hl
        ld      (hl), $20
        inc     hl
        inc     hl
        ld      (hl), 0
        push    iy
        ld      (pAppStackPtr), sp
        ld      ix, (uwAppStaticHnd)            ; !! this is at osent_4-4, jp there
        ld      a, 1                            ; A=0, Fc=0, Fz=0
        or      a
        ld      a, RC_OK
        jp      osent_4                         ; enter thru Os_Ent

;       ----

.OSEntSub
        ex      af, af'
        call    ChkStkLimits
        call    AppBindS012
        ld      a, (ubOldCallLevel)
        ld      (ubAppCallLevel), a
        ld      hl, ubAppResCycle
        inc     (hl)
        ex      af, af'
        pop     hl                              ;  get return address
        ld      sp, (pAppStackPtr)
        jp      (hl)
.AppBindS012
        ld      hl, ubAppBindings+2
        ld      bc, BLSC_SR2
        call    BindSx
        call    BindSx
.BindSx
        ld      a, (hl)
        ld      (bc), a
        out     (c), a
        cpd
        ret

;       ----

; Fc=0 - restore caps flags
; Fc=1 - remember caps flags
.ApplCaps
        ld      hl, KbdData+kbd_flags           ; kbd_flags
        ld      de, ubAppKbdBits                ; application kbd cfg
        jr      nc, apc_1
        ex      de, hl
.apc_1
        ld      a, (de)                         ; !! bits match - and 3; or (hl); ld (hl),a
        res     KBF_B_CAPSE, (hl)
        res     KBF_B_CAPS, (hl)
        rrca
        jr      nc, apc_2
        inc     (hl)                            ; CAPSE
.apc_2
        rrca
        jr      nc, apc_3
        set     KBF_B_CAPS, (hl)
.apc_3
        jp      DrawOZwd

;       ----

; stack file current process

.OSStk
        push    ix
        call    Mailbox2Stack
        call    AppReleaseMem
        scf                                     ; Fc=1, remember caps flags
        call    ApplCaps
        call    SaveAllAppData
        jr      c, osstk_1
        call    UpdEnvOverhead
        or      a                               ; Fc=0
        ld      a, (ubAppHelpBank)
        or      1
        ld      b, a
        push    ix
        pop     hl
        call    PutOSFrame_BHL
.osstk_1
        pop     ix
        ret

;       ----

.UpdEnvOverhead
        call    GetFileSize                     ; HL=size
        ret     c                               ; error? exit
        ld      de, (uwAppEnvOverhead)          ; store size if larger than previous
        sbc     hl, de
        ret     c
        add     hl, de
        ld      (uwAppEnvOverhead), hl
        ret

;       ----

;       exit current application

.OSBye
        call    OSFramePush
        push    af

        xor     a                               ; remove error handler
        ld      h, a
        ld      l, a
        inc     a
        OZ      OS_Erh

        call    Mailbox2Stack

        ld      ix, (pAppHelpHandle)
        call    DORHandleFreeDirect

        call    AppReleaseAllMem
        call    FreeBadRAM

        pop     af
        OZ      DC_Bye
        jr      $PC                             ; crash if we come back here

;       ----

.AppReleaseMem
        call    IsBadUgly
        jr      z, CloseAppEnvHandle
        and     AT_UGLY
        jr      nz, AppReleaseAllMem
        ld      a, RC_Esc
        ex      af, af'

        ld      hl, (pAppEntrypoint)            ; call enquiry function
        inc     hl
        inc     hl
        inc     hl
        ld      a, (ubAppBindings+3)
        call    JpAHL

        ex      af, af'
        jr      nc, arm_1

.AppReleaseAllMem
        ld      bc, $2000                       ; BC-DE is free, ie. none
        ld      d, b
        ld      e, c
.arm_1
        call    BadSwapAndFree

.CloseAppEnvHandle
        ld      ix, (pAppEnvHandle)
        OZ      OS_Cl

.SetAppEnvHandle
        ld      (pAppEnvHandle), ix
        ret

;       ----

;       fetch information about process card usage
;
;IN:    IX,B
;OUT:   A bits0-3

.OSUse
        ld      c, 0
        push    ix
        pop     hl
        call    osuse_1
        ld      l, b
.osuse_1
        ld      h, 0
        add     hl, hl
        add     hl, hl
        ld      a, h
        cp      3
        ccf
        adc     a, 0                            ; A=0/1/2/4
        rlca
        or      c
        ld      c, a
        ld      (iy+OSFrame_A), a
        ret

;       ----

.InitAppMTH
        ld      (ubHlpActiveApp), a

.InitHlpActiveHelp
        ld      a, 1

.SetHlpActiveHelp
        ld      (ubHlpActiveHelp), a
        ld      a, 1
        ld      (ubHlpActiveTpc), a

.InitHlpActiveCmd
        ld      a, 1
        ld      (ubHlpActiveCmd), a
        ret
