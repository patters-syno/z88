; -----------------------------------------------------------------------------
; Bank 0 @ S3           ROM offset $0101
;
; $Id$
; -----------------------------------------------------------------------------

        Module  Misc2

        include "all.def"
        include "sysvar.def"

        org     $c101                           ; 261 bytes

defc    MS2BankB                =$d719
defc    OSFramePushMain         =$d55c
defc    MS2BankA                =$d721
defc    MS2BankK1               =$d71f
defc    OZCallJump              =$0095
defc    OZCallReturn2           =$00ac
defc    OSFramePush             =$d555
defc    ScreenOpen              =$faea
defc    ScreenClose             =$faf6
defc    OSFramePop              =$d582
defc    OSIsq                   =$adb8
defc    StorePrefixed           =$adcc
defc    PrFilterCall            =$f9a5
defc    OSEprTable              =$8f00
defc    GetOSFrame_BC           =$d6d7
defc    OSAlmMain               =$983e
defc    SetPendingOZwd          =$cdb2
defc    osfpop_1                =$d584

defc    PrntCtrlSeq             =$afc3
defc    PrntChar                =$afc0

;       ----

;       all 2-byte calls use OSframe

.CallDC
        ld      a, OZBANK_DC                    ; Bank 2, $80xx
        jr      ozc_2                           ; !! defb OP_LDBCnn to skip over 'ld a'
.CallGN
        ld      a, OZBANK_GN                    ; Bank 3, $80xx
.ozc_2
        ld      d, $80
        jr      ozc_3

.CallOS2byte
        ld      a, OZBANK_0                     ; Bank 0, $FFxx
        ld      d, $FF

;       !! could read second byte in CallOZMain, increase HL once and do
;       !! the second inc here - it's just 'ld l,(hl) there to get into E here

.ozc_3
        pop     bc                              ; S2/S3
        pop     hl                              ; caller PC
        ld      e, (hl)                         ; get op byte
        bit     7, h                            ; if op byte in S3, bind bank
        jr      z, ozc_4                        ; in S2 and read op byte from there
        bit     6, h
        jr      z, ozc_4
        push    hl                              ; !! res/set 6,h instead of push/pop
        push    af
        call    MS2BankB
        pop     af
        set     7, h                            ; S2 !! set unnecessary
        res     6, h
        ld      e, (hl)                         ; get op byte
        pop     hl

.ozc_4
        inc     hl
        push    hl                              ; caller PC

        ld      hl, ozc_ret                     ; return here
        jp      OSFramePushMain
.ozc_ret
        cp      a                               ; Fz=1, Fc=0
        ex      af, af'                         ; alt register
        call    MS2BankA                        ; bind code in
        exx                                     ; alt registers

        ex      de, hl                          ; function address into DE
        ld      e, (hl)
        inc     l
        ld      d, (hl)

        set     6, h                            ; or $4000 - return into S3
        ld      l, 3
        push    hl                              ; return address
        push    de                              ; function address
        ex      af, af'
        push    af                              ; caller A
        ex      af, af'
        push    af                              ; code bank
        call    MS2BankK1
        exx                                     ; main registers
        jp      OZCallJump                      ; bind code into S3 and ret to it

.OzCallInvalid
        ld      a, 0
        scf
        jp      OZCallReturn2
        ret                                     ; !! unused

;       ----

;       send character directly to printer filter

.OSPrt
        call    OSFramePush
        ex      af, af'                         ; we need screen because prt sequence buffer is in SBF
        call    ScreenOpen                      ; !! this is also done in OSPrtMain, unnecessary here?
        ex      af, af'

.prt_1
        ld      hl, (ubCLIActiveCnt)            ; !! just L
        inc     l
        dec     l
        jr      z, prt_2                        ; no cli, print direct

        OZ      DC_Prt                          ; otherwise use DC
        jr      nc, prt_x                       ; no error? exit
        cp      RC_Time
        jr      z, prt_1                        ; timeout? retry forever
        scf
        jr      prt_x

.prt_2
        call    OSPrtMain

.prt_x
        ex      af, af'
        call    ScreenClose
        ex      af, af'
        jp      OSFramePop

;       ----

.OSPrtMain
        push    bc
        ex      af, af'
        call    ScreenOpen
        ex      af, af'

        ld      hl, (PrtSeqPrefix)              ; ld l,(PrtSeqPrefix)
        inc     l
        dec     l
        jr      nz, prtm_2                      ; have ctrl sequence? add to it
        cp      $20
        jr      nc, prtm_3                      ; not ctrl char? print
        cp      ESC
        jr      z, prtm_3                       ; ESC? print
        cp      7                               ; 00-06, 0E-1F: ctrl sequence
        jr      c, prtm_1                       ; otherwise print
        cp      $0E
        jr      c, prtm_3

.prtm_1
        ld      (PrtSeqPrefix), a               ; store prefix char
        ld      hl, PrtSequence                 ; init sequence
        call    OSIsq
        or      a                               ; Fc=0
        jr      prtm_x

.prtm_2
        ld      hl, PrtSequence                 ; put into buffer
        call    StorePrefixed
        ccf
        jr      nc, prtm_x                      ; not done yet? exit, Fc=0

        ld      a, (PrtSeqPrefix)               ; ctrl char
        ld      bc, (PrtSequence)               ; c,(PrtSequence) - length
        ld      b, 0
        ld      de, PrtSeqBuf                   ; buffer

        ld      l, <PrntCtrlSeq
        jr      prtm_4
.prtm_3
        ld      l, <PrntChar
.prtm_4
        call    PrFilterCall
        ex      af, af'
        xor     a                               ; reset prefix
        ld      (PrtSeqPrefix), a
        ex      af, af'

.prtm_x
        ex      af, af'
        call    ScreenClose
        ex      af, af'
        pop     bc
        ret

;       ----

;       Eprom Interface

;       we have OSFrame so remembering S2 is unnecessary, as is remembering IY

.OSEpr
        ld      b, 7                            ; ld bc,7<<8|2
        ld      c, 2
        OZ      OS_Mpb                          ; MS2b07 and remember S3 !! use MS2BankK1
        push    bc                              ; !! ospop restores S2/IY
        push    iy

        ld      bc, osepr_ret                   ; push return address
        push    bc
        push    hl                              ; save HL
        ld      hl, OSEprTable                  ; get function address
        ld      b, 0
        ld      c, a
        add     hl, bc
        ex      (sp), hl                        ; restore HL, push function
        jp      GetOSFrame_BC                   ; get caller BC and ret to function, then here

.osepr_ret
        pop     iy
        pop     bc                              ; restore S2
        push    af
        OZ      OS_Mpb
        pop     af
        ret                                     ; return thru ospop

;       ----

;       alarm manipulation

.OSAlm
        call    OSFramePush

        ld      c, b    
        ld      b, a

        call    OZ_DI
        push    af

        ld      a, c
        set     6, (iy+OSFrame_F)               ; Fz=1
        call    OSAlmMain

        pop     af
        call    OZ_EI

        call    SetPendingOZwd                  ; request OZ window redraw
        jp      osfpop_1

;       ----

