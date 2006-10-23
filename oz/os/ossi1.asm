; **************************************************************************************************
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
; $Id: ossi1.asm 2005 2005-11-23 21:31:34Z gbs $
;***************************************************************************************************

        Module OS_Si1

        include "blink.def"
        include "buffer.def"
        include "ctrlchar.def"
        include "handle.def"
        include "misc.def"
        include "syspar.def"
        include "sysvar.def"
        include "serintfc.def"
        include "lowram.def"

xdef    OSSiHrd1
xdef    OSSiSft1
xdef    OSSiEnq1
xdef    OSSiFtx1
xdef    OSSiFrx1
xdef    OSSiTmo1

xref    BfSta                                   ; bank0/buffer.asm
xref    BfPur                                   ; bank0/buffer.asm
xref    Ld_IX_RxBuf                             ; bank0/ossi0.asm
xref    Ld_IX_TxBuf                             ; bank0/ossi0.asm
xref    WrRxc                                   ; bank0/ossi0.asm
xref    EI_TDRE                                 ; bank0/ossi0.asm

.OSSiHrd1
        push    bc
        push    de
        ld      a,FN_AH
        ld      b,HN_SER
        OZ      OS_Fn                           ; allocate serial handle
        pop     de
        pop     bc
        jr      c, hrst_1

        ld      (SerRXHandle), ix               ; save handle in
        ld      (ix+shnd_RxBuf), c
        ld      (ix+shnd_RxBuf+1), b
        ld      (ix+shnd_TxBuf), e
        ld      (ix+shnd_TxBuf+1), d

        ld      a, $FF
        out     (BL_TXD), a                     ; clear TDRE int

        ld      a, BM_RXCSHTW|BM_RXCUART|BM_RXCIRTS|BR_9600
        call    WrRxC

        ld      a, BM_TXCATX|BR_9600
        ld      (BLSC_TXC), a
        out     (BL_TXC), a

        xor     a                               ; no XON/XOFF
        ld      (cSerXonXoffChar), a            ; !! clear ubSerFlowControl as well

        dec     a
        out     (BL_UAK), a                     ; clear DCD/CTS ints

        in      a, (BL_RXD)                     ; clear RDRF int
        ld      a, BM_UITDCDI
        ld      (BLSC_UIT), a
        out     (BL_UIT), a

        ld      a, BM_RXCSHTW|BM_RXCIRTS|BR_9600
        call    WrRxC

        ld      a, 0                            ; no parity
        ld      (ubSerParity), a

        ld      a, (BLSC_INT)
        or      BM_STAUART
        ld      (BLSC_INT), a
        out     (BL_INT), a

        or      a                               ; Fc=0 !! unnecessary

.hrst_1
        ret

;       ----

.OSSiSft1
        ld      (ix+shnd_Timeout), <60000       ; !! default timeout 600.00 seconds
        ld      (ix+shnd_Timeout+1), >60000
        call    OSSiFtx1
        call    OSSiFrx1

        ld      bc, PA_Rxb                      ; get receive speed
        call    EnquireParam
        call    BaudToReg
        ld      b, a                            ; !! 'or BM_RXCSHTW|BM_RXCIRTS'
        ld      a, BM_RXCSHTW|BM_RXCIRTS
        or      b
        call    WrRxC

        ld      bc, PA_Txb                      ; get transmit speed
        call    EnquireParam
        call    BaudToReg
        ld      b, a
        ld      a, (BLSC_TXC)
        and     ~7                              ; mask out baud rate
        or      b                               ; insert new speed
        ld      (BLSC_TXC), a
        out     (BL_TXC), a

        ld      bc, PA_Par                      ; get parity
        call    EnquireParam
        ld      c, 3                            ; ?? probably TDRH_START|TDRH_STOP, not used
        ld      a, e
        cp      'N'                             ; none
        jr      z, srst_1

        set     PAR_B_PARITY, c
        cp      'E'                             ; even
        jr      z, srst_1

        set     PAR_B_ODD, c
        cp      'O'                             ; odd
        jr      z, srst_1

        set     PAR_B_STICKY, c
        cp      'S'                             ; space
        jr      z, srst_1

        set     PAR_B_MARK, c

.srst_1
        ld      a, c
        ld      (ubSerParity), a

        ld      bc, PA_Xon                      ; get Xon/Xoff
        call    EnquireParam
        ld      a, (ubSerFlowControl)
        and     ~(FLOW_XONXOFF|FLOW_TXSTOP)
        ld      c, a
        ld      a, e
        cp      'Y'
        jr      nz, srst_2
        set     FLOW_B_XONXOFF, c
        ld      a, XON
        ld      (cSerXonXoffChar), a
        call    EI_TDRE

.srst_2
        ld      a, c
        ld      (ubSerFlowControl), a

        or      a                               ; Fc=0
        ret

;       ----

.EnquireParam
        ld      de, 2                           ; return parameter in DE
        OZ      OS_Nq
        ret

;       ----

.BaudToReg
        ex      af, af'                         ; !! unnecesary
        xor     a                               ; count from 0 upwards
        ex      af, af'
        ld      b, d                            ; baud rate into BC
        ld      c, e
        ld      hl, BaudRates
.b2r_1
        ld      e, (hl)                         ; de=(hl)++
        inc     hl
        ld      d, (hl)
        inc     hl
        ld      a, d                            ; use 9600 if end of list
        or      e
        ld      a, BR_9600
        jr      z, b2r_3

        ex      de, hl
        sbc     hl, bc
        ex      de, hl
        jr      z, b2r_2                        ; found? exit

        ex      af, af'                         ; increment and loop
        inc     a
        ex      af, af'
        jr      b2r_1

.b2r_2
        ex      af, af'
.b2r_3
        or      a                               ; !! unnecessary
        ret

.BaudRates
        defw    75, 300, 600, 1200, 2400, 9600, 19200, 38400
        defw    0

;       ----

.OSSiEnq1
        call    OZ_DI                           ; !! 'push/pop IX' at start/end to
        push    af                              ; !! eliminate one 'push/pop' pair
        push    ix
        call    Ld_IX_TxBuf                     ; get TxBuf status
        call    BfSta
        pop     ix
        push    hl

        push    ix
        call    Ld_IX_RxBuf                     ; get RxBuf status
        call    BfSta
        pop     ix

        ex      de, hl                          ; DE=RxStatus
        pop     bc                              ; BC=TxStatus
        pop     af
        call    OZ_EI
        in      a, (BL_UIT)                     ; A=int status
        or      a
        ret

;       ----

.OSSiTmo1
        ld      (ix+shnd_Timeout), c
        ld      (ix+shnd_Timeout+1), b
        ret

;       ----

.OSSiFtx1
        push    ix
        call    Ld_IX_TxBuf
        jr      FlushBuf

;       ----

.OSSiFrx1
        push    ix
        call    Ld_IX_RxBuf

.FlushBuf
        call    BfPur
        pop     ix
        ret