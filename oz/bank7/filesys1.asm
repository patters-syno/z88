; -----------------------------------------------------------------------------
; Bank 7 @ S2           ROM offset $1dcdd
;
; $Id$
; -----------------------------------------------------------------------------

        Module Filesys1

        org     $9cdd                           ; 145 bytes

        include "dor.def"
	include	"time.def"
        include "sysvar.def"

xdef    IsSpecialHandle
xdef    OpenMem
xdef    OSRen
xdef    OSDel
xdef    FileNameDate

;       bank 0

xref    AllocHandle
xref    CopyMemHL_DE
xref    DORHandleFree
xref    DORHandleFreeDirect
xref    DORHandleInUse
xref    GetOSFrame_HL
xref    InitMemHandle
xref    RewindFile
xref    MvToFile
xref    VerifyHandle

;       bank 7

xref    FreeMemHandle

;       ----

;       check that IX is in range 0-8

.IsSpecialHandle
        push    ix
        pop     hl
        ld      de, -9
        add     hl, de
        ret     c                               ; Fc=1 if IX>8
        push    ix
        pop     de
        ret


;       ----
.OpenMem
        push    bc
        push    hl
        ld      a, HND_FILE
        call    AllocHandle
        jr      c, omem_2
        call    InitMemHandle
        pop     hl
        pop     bc
        jr      c, omem_1
        ld      d, b
        ld      b, 0
        call    MvToFile
        ld      (ix+fhnd_attr), FATR_READABLE|FATR_WRITABLE|FATR_MEMORY
        jp      nc, RewindFile
.omem_1
        jp      FreeMemHandle
.omem_2
        pop     hl
        pop     bc
        ret


; file rename
;       ----
.OSRen
        ld      a, HND_DEV
        call    VerifyHandle
        ret     c
        call    DORHandleInUse
        jp      c, DORHandleFree
        cp      a                               ; Fz=1
        call    FileNameDate
        jp      DORHandleFreeDirect


; file delete
;       ----
.OSDel
        ld      a, DR_DEL                       ; delete DOR
        OZ      OS_Dor                          ; DOR interface
        ret


;       ----
.FileNameDate
        ex      af, af'                         ; preserve Fz and Fc
        ld      hl, -17                         ; reserve stack buffer
        add     hl, sp
        ld      sp, hl
        ex      de, hl
        ex      af, af'
        jr      nz, flnd_2                      ; Fz=0? don't rename
        push    af
        call    GetOSFrame_HL                   ; copy HL to stack buffer
        push    de
        ld      c, 17
        call    CopyMemHL_DE
        pop     de
        ld      a, DR_WR                        ; write DOR record
        ld      bc, 'N'<<8|17                   ; Name, 17 chars
        OZ      OS_Dor
.flnd_1
        jr      c, flnd_1                       ; crash if fail
        pop     af
.flnd_2
        push    af
        ld      h, d                            ; HL=stack buffer
        ld      l, e
.flnd_3
        ld      d, h                            ; DE=stack buffer
        ld      e, l
        OZ      GN_Gmd                          ; get current machine date in internal format
        ld      c, (hl)
        OZ      GN_Gmt                          ; get (read) machine time in internal format
        jr      nz, flnd_3                      ; inconsistent, read again
        ld      bc, 3                           ; copy time after date
        ldir
        ex      de, hl                          ; DE=datetime
        ld      a, DR_WR                        ; write DOR record
        ld      bc, 'U'<<8|6                    ; Update, 6 bytes
        OZ      OS_Dor
        pop     af
        jr      nc, flnd_4                      ; Fc=0? don't set creation date
        ld      a, DR_WR                        ; write DOR record
        ld      bc, 'C'<<8|6                    ; Create, 6 bytes
        OZ      OS_Dor
.flnd_4
        ld      hl, 17                          ; restore stack
        add     hl, sp
        ld      sp, hl
        ret
