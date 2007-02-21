        module FileEprActiveSpace

; **************************************************************************************************
; This file is part of the Z88 Standard Library.
;
; The Z88 Standard Library is free software; you can redistribute it and/or modify it under
; the terms of the GNU General Public License as published by the Free Software Foundation;
; either version 2, or (at your option) any later version.
; The Z88 Standard Library is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY;
; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
; See the GNU General Public License for more details.
; You should have received a copy of the GNU General Public License along with the
; Z88 Standard Library; see the file COPYING. If not, write to the
; Free Software Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA 02111-1307, USA.
;
; $Id$
;
; ***************************************************************************************************

        xdef FileEprActiveSpace
        xref FileEprTotalSpace

        include "error.def"

; ***************************************************************************************************
;
; Standard Z88 File Eprom Format, including support for sub File Eprom
; area in application cards (below application banks in first free 64K boundary)
;
; Return amount of active (visible) file space in File Eprom Area, inserted in slot C.
; (API wrapper of FileEprTotalSpace)
;
; IN:
;    C = slot number containing File Eprom Area
;
; OUT:
;    Fc = 0, File Eprom available
;         DEBC = Active space (amount of visible files) in bytes
;                (DE = high 16bit, BC = low 16bit)
;
;    Fc = 1,
;         A = RC_ONF
;         File Eprom was not found in slot C.
;
; Registers changed after (succesful) return:
;    A.....HL/IXIY same
;    .FBCDE../.... different
;
; ------------------------------------------------------------------------
; Design & programming by Gunther Strube, InterLogic, July 2005
; ------------------------------------------------------------------------
;
.FileEprActiveSpace
        push    hl
        push    af

        call    FileEprTotalSpace
        jr      c,err_FileEprActiveSpace        ; File Area not available
        push    hl
        ld      d,0                             ; BHL = Amount of active file space in bytes
        ld      e,b
        pop     bc                              ; BHL -> DEBC

        pop     hl
        ld      a,h                             ; original A restored
        pop     hl                              ; original HL restored
        ret
.err_FileEprActiveSpace
        pop     hl                              ; discard old AF...
        pop     hl                              ; original HL restored
        ret
