; **************************************************************************************************
; OS_Sr interface (kernel 1)
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
; (C) Thierry Peycru (pek@users.sf.net), 2005
; (C) Gunther Strube (gbs@users.sf.net), 2005
;
; Copyright of original (binary) implementation, V4.0:
; (C) 1987,88 by Trinity Concepts Limited, Protechnic Computers Limited & Operating Systems Limited.
;
; ***************************************************************************************************

        Module OSSr

        include "error.def"
        include "memory.def"
        include "stdio.def"
        include "saverst.def"
        include "handle.def"
        include "sysvar.def"
        include "oz.def"

xdef    OSSR_main
xdef    OSSr_Sus
xdef    OSSr_Fus                                ; OS_Ent
xdef    FreeMemHandle                           ; OpenMem, sub_F669


xref    AllocHandle                             ; [Kernel0]/handle.asm
xref    FreeHandle                              ; [Kernel0]/handle.asm
xref    VerifyHandle                            ; [Kernel0]/handle.asm

xref    FixPtr                                  ; [Kernel0]/memmisc.asm
xref    CopyMemBHL_DE                           ; [Kernel0]/memmisc.asm
xref    CopyMemDE_BHL                           ; [Kernel0]/memmisc.asm
xref    PutOSFrame_BC                           ; [Kernel0]/memmisc.asm
xref    PutOSFrame_DE                           ; [Kernel0]/memmisc.asm

xref    FreeMemData0                            ; [Kernel0]/filesys3.asm
xref    InitMemHandle                           ; [Kernel0]/filesys3.asm
xref    RewindFile                              ; [Kernel0]/filesys3.asm
xref    RestoreScreen                           ; [Kernel0]/scrdrv4.asm
xref    SaveScreen                              ; [Kernel0]/scrdrv4.asm
xref    MTHPrint                                ; [Kernel0]/mth0.asm

xref    DrawTopicWd                             ; [Kernel1]/mth1.asm
xref    GetCurrentWdInfo                        ; [Kernel1]/mth1.asm
xref    InitTopicWd                             ; [Kernel1]/mth1.asm
xref    RestoreActiveWd                         ; [Kernel1]/mth1.asm


;       ----

.OSSr_Err
        ld      a, RC_Fail
        scf
        ret
;
;save & restore screen file
;
;A = reason code:
; SR_SUS ($01) Save user screen
; SR_WPD ($03) Write parameter data (mailbox)
; SR_RPD ($04) Read parameter data (mailbox)
; SR_FUS ($05) Free user screen
; SR_CRM ($06) Remove card (not implemented)
; SR_CIN ($07) Insert card (not implemented)
; SR_PWT ($08) Page wait
; SR_RND ($09) Occasionally a random number (system use)
.OSSR_main
        or      a
        djnz    rus

;save user screen
;
;in:  -
;out: IX = screen image handle

.OSSr_Sus
        ld      a, HND_PROC
        call    AllocHandle
        ret     c
        call    InitMemHandle
        jp      c, sr_1
        call    SaveScreen
        ret     nc
.sr_1
        jp      FreeMemHandle

.rus
        djnz    wpd

;restore user screen
;
;in:  IX = screen image handle

        ld      a, HND_PROC
        call    VerifyHandle
        ret     c
        call    RewindFile
        call    RestoreScreen
        or      a
        jr      sr_1

.wpd
        djnz    rpd

;write mailbox
;
;DE = name of information type, 0=clear mailbox
;BHL = data
;C = data length

        ld      b, a
        inc     b
        dec     b
        call    z, FixPtr
        ld      (ubMailboxSize), bc             ; length/bank
        ld      (pMailbox), hl                  ; data
        ex      de, hl
        ld      bc, MBOXNAMEMAXLEN
        ld      de, MailBoxName
        xor     a
        ld      (ubMailBoxID), a                 ; mailbox control, store
        jp      CopyMemBHL_DE

.rpd
        djnz    fus

;read mailbox
;DE = name
;BHL = buffer
;C = bufsize
        ld      b, a
        ld      a, (ubMailBoxID)
        cp      MAILBOXID
        jr      nz, OSSr_Err                    ; no mail, exit
        push    bc
        push    hl
        ex      de, hl                          ; compare mailbox name
        call    FixPtr
        ld      de, MailBoxName
        OZ      GN_Cme                          ; compare null-terminated strings
        pop     hl
        pop     bc
        jr      nz, OSSr_Err
        ld      a, (ubMailboxLength)
        ld      c, a
        ld      a, (iy+OSFrame_C)
        ld      (iy+OSFrame_C), c
        cp      c
        jr      nc, sr_5
        ld      c, a
.sr_5
        xor     a
        ld      (ubMailBoxID), a
        ld      de, MailboxData
        jp      CopyMemDE_BHL
.fus
        djnz    crm

;free user screen
;
;IX = screen image handle

.OSSr_FUS
        ld      a, HND_PROC
        call    VerifyHandle
        ret     c

.FreeMemHandle
        push    af
        call    FreeMemData0
        ld      a, (ix+hnd_Type)
        call    FreeHandle
        pop     af
        ret

.crm
        djnz    cin
        ret

.cin
        djnz    pwt
        ret

.pwt
        djnz    rnd

;page wait
        OZ      OS_Pur                          ; purge keyboard buffer
.sr_11
        ld      a, (ubCLIActiveCnt)
        or      a
        ret     nz                              ; CLI active? exit

        call    GetCurrentWdInfo
        call    InitTopicWd
        call    MTHPrint
        defm    1,"2I7"
        defm    1,"2C",$FE
        defm    1,"3@",$20+0,$20+2
        defm    $7F,"C"
        defm    1,"G"
        defm    1,"T"
        defm    1,"B"
        defm    "PAGE WAIT"
        defm    1,"T"
        defm    1,"B"
        defm    10,10
        defm    1,$E0
        defm    10,"CONTINUE",10
        defm    1,$E4
        defm    10
        defm    "RESUME"
        defm    $7F,"N",0

        xor     a

.sr_12
        or      a
        jr      nz, sr_13
        OZ      OS_In
        jr      nc, sr_12                       ; go see if it's extended char
.sr_13
        push    af
        call    DrawTopicWd
        pop     af
        call    RestoreActiveWd
        ret     nc
        cp      RC_Susp
        scf
        jr      z, sr_11                        ; if pre-emption just redraw and wait more
        ret

.rnd
        djnz    sr_15

;random number
;out DEBC = random number

        ld      bc, (uwRandom1)
        ld      de, (uwRandom2)
        call    PutOSFrame_BC
        jp      PutOSFrame_DE

.sr_15
        ld      a, RC_Unk
        scf
        ret
