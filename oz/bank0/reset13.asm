; -----------------------------------------------------------------------------
; Bank 0 @ S3           ROM offset $007b
;
; $Id$
; -----------------------------------------------------------------------------

        Module  Reset13

        include "all.def"
        include "sysvar.def"

        org     $c07b                           ; 134 bytes

xdef    Reset1
xdef    Bootstrap2
xdef    Reset3
xdef    ExpandMachine

defc    VerifySlotType          =$e757
defc    Reset2                  =$95a5
defc    InitRAM                 =$e177
defc    MarkSystemRAM           =$e3c4
defc    MarkSwapRAM             =$e3bf
defc    MS2BankK1               =$d71f
defc    RstRdPanelAttrs         =$aa99
defc    Reset4                  =$fe97
defc    Chk128KB                =$ff9f
defc    FirstFreeRAM            =$ffab

;       code in ROM, SP points to ROM too

.Reset1
        pop     de                              ; return to Bootstrap2
        ld      de, 1<<8|$3f                    ; check slot 1, max size 63 banks
        call    VerifySlotType                  ; !! 'jp' here, aliminates pop above

.Bootstrap2
        bit     1, d                            ; check for bootable ROM in slot 1
        jr      z, rst1_2                       ; not application ROM? skip
        ld      a, ($bffd)                      ; subtype
        cp      'Z'
        jp      z, $bff8                        ; enter ROM

.rst1_2
        ld      a, OZBANK_7
        out     (BL_SR2), a                     ; MS2b07
        jp      Reset2                          ; init internal RAM, blink and low-ram code and set SP

;       ----

.Reset3
        call    InitRAM
        ld      d, $20
        ld      bc, $10
        call    MarkSystemRAM                   ; b20, 0000-0fff - system variables
        ld      d, $20
        ld      bc, $1008
        call    MarkSwapRAM                     ; b20, 1000-17ff - swap RAM
        ld      d, $20
        ld      bc, $1808
        call    MarkSystemRAM                   ; b20, 1800-1fff - stack
        ld      d, $20
        ld      bc, $2020
        call    MarkSwapRAM                     ; b20, 2000-3fff - 8KB for bad apps
        ld      d, $21
        ld      bc, $3808
        call    MarkSystemRAM                   ; b21, 3800-3fff - SBF
        ld      d, $21
        ld      bc, $2003
        call    MarkSystemRAM                   ; b21, 2000-22ff - Hires0+Lores0

        call    ExpandMachine                   ; move Lores0/Hires0 and mark more swap RAM if expanded

        call    MS2BankK1                       ; bind in more code
        call    RstRdPanelAttrs
        jp      Reset4                          ; !! just MS2BankK1 again then jp Reset5

;       ----

.ExpandMachine
        call    Chk128KB
        ret     c                               ; not expanded? exit

        call    FirstFreeRAM                    ; b21/b40 for un-/expanded machine
        add     a, 3                            ; b24/b43
        push    af
        pop     de                              ; D=bank !! ld d,a

        push    de
        ld      bc, $0A
        call    MarkSystemRAM                   ; b24/b43, 0000-09ff - Hires0+Lores0

        pop     bc                              ; B=bank !! use C to keep bank through Os_Sci
        push    bc
        ld      h, 8
        ld      a, SC_LR0
        OZ      OS_Sci                          ; LORES0

        pop     bc                              ; B=bank
        push    bc
        ld      h, 0
        ld      a, SC_HR0
        OZ      OS_Sci                          ; HIRES0

        pop     de                              ; D=bank
        dec     d
        dec     d
        ld      bc, $80
        jp      MarkSwapRAM                     ; b22/b41, 0000-7fff - 32KB more for bad apps

