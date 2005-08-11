; *************************************************************************************
; FlashStore
; (C) Gunther Strube (gbs@users.sourceforge.net) & Thierry Peycru (pek@free.fr), 1997-2004
;
; FlashStore is free software; you can redistribute it and/or modify it under the terms of the
; GNU General Public License as published by the Free Software Foundation;
; either version 2, or (at your option) any later version.
; FlashStore is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY;
; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
; See the GNU General Public License for more details.
; You should have received a copy of the GNU General Public License along with FlashStore;
; see the file COPYING. If not, write to the
; Free Software Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA 02111-1307, USA.
;
; $Id$
;
; *************************************************************************************

Module CatalogFiles

; This module contains the Catalog Files command

     xdef CatalogCommand

     lib FileEprRequest            ; Check for presence of Standard File Eprom Card or Area in slot
     lib FileEprFirstFile          ; Return pointer to first File Entry on File Eprom
     lib FileEprNextFile           ; Return pointer to next File Entry on File Eprom
     lib FileEprFilename           ; Copy filename into buffer (null-term.) from cur. File Entry
     lib FileEprFileSize           ; Return file size of current File Entry on File Eprom
     lib FileEprFileStatus         ; Return Active/Deleted status of file entry
     lib FileEprCntFiles           ; Return total of active and deleted files
     lib CreateFilename            ; Create file(name) (OP_OUT) with path

     xref GetFirstFilePtr          ; browse.asm
     xref GetNextFilePtr           ; browse.asm
     xref FilesAvailable           ; browse.asm
     xref CompressedFileEntryName  ; browse.asm
     xref endf_msg                 ; browse.asm
     xref FileAreaBannerText       ; browse.asm
     xref cls, yesno, no_msg       ; fsapp.asm
     xref sopnln, pwait, ResSpace  ; fsapp.asm
     xref DispMainWindow           ; fsapp.asm
     xref disp_no_filearea_msg     ; errmsg.asm
     xref no_files                 ; errmsg.asm
     xref GetDefaultRamDevice      ; defaultram.asm
     xref InputFilename            ; fetchfile.asm

     ; system definitions
     include "stdio.def"
     include "fileio.def"
     include "integer.def"
     include "error.def"

     ; FlashStore popdown variables
     include "fsapp.def"



; *************************************************************************************
;
; Display name and size of stored files on Flash Eprom.
;
.CatalogCommand
                    ld   hl, catlg_banner
                    ld   bc, 15
                    call FileAreaBannerText
                    call DispMainWindow

                    call FilesAvailable
                    jp   c, disp_no_filearea_msg
                    jp   z, no_files             ; Fz = 1, no files available...

                    LD   HL,catlg_msg
                    CALL sopnln
                    LD   HL,filename_msg
                    CALL_OZ GN_sop
                    LD   DE,buf1
                    PUSH DE
                    CALL GetDefaultRamDevice
                    CALL GetDefaultListingFilename
                    POP  DE
                    LD   C,15
                    CALL InputFilename
                    ret  c                       ; user aborted command

                    CALL_OZ gn_nln
                    ld   b,0                     ; (local pointer)
                    ld   hl,buf1                 ; pointer to filename...
                    call CreateFilename          ; create file with and path
                    jr   nc, list_catalog        ; IX = handle of created file...
                    call_oz GN_Err
                    ret
.list_catalog
                    ld   hl,pdformat
                    ld   bc,12
                    call WriteLine               ; write PipeDream document format header to file...

                    ld   a,(curslot)
                    ld   c,a
                    call GetFirstFilePtr         ; BHL = first file entry
.cat_main_loop
                    ld   de, buf3+2              ; write filename at (DE), null-terminated
                    call CompressedFileEntryName ; copy filename from current file entry
                    call FileEprFileStatus
                    call CatalogueFile           ; catalogue current file
                    call GetNextFilePtr          ; get pointer to next File Entry in BHL...
                    jr   nc,cat_main_loop

                    call_oz GN_Cl                ; close file
                    call_oz gn_nln
                    ld   hl,catend_msg
                    call sopnln
                    call ResSpace
                    ret

.CatalogueFile
                    call nz,norm_aff
                    call z,tiny_aff

                    push bc
                    push hl
                    call FileEprFileSize          ; get size of File Entry in CDE
                    ld   (flen),de
                    ld   b,0
                    ld   (flen+2),bc

                    xor  a
                    ld   c,53
                    ld   hl,buf3
                    cpir                          ; find null-terminator
                    dec  hl
                    ld   b,c
                    inc  b
.pad_spaces_loop
                    ld   (hl),' '                 ; and pad with spaces after filename
                    inc  hl
                    djnz pad_spaces_loop

                    ex   de,hl                    ; DE points to where to write Ascii Integer
                    push de
                    ld   hl, flen                 ; the 24bit integer...
                    call_oz GN_pdn
                    ld   (de),a                   ; null-terminate string
                    ex   de,hl
                    pop  de
                    sbc  hl,de                    ; HL = length of Ascii integer, DE = start of Ascii integer
                    push de
                    ex   de,hl                    ; DE = length of...
                    sbc  hl,de
                    ld   b,d
                    ld   c,e
                    ex   de,hl                    ; DE = pointer to new right-justified Ascii integer location
                    pop  hl
                    ldir                          ; Ascii integer right-justified
                    ex   de,hl
                    ld   (hl),13

                    ld   hl, buf3
                    ld   bc,54
                    call WriteLine                ; List file data to Pipedream document

                    pop  hl
                    pop  bc
                    ret
.norm_aff
                    ld   a, 'F'
                    jr   dispsq
.tiny_aff           ld   a, 'd'
.dispsq             ld   de, buf3
                    ld   (de),a
                    inc  de
                    ld   a,' '
                    ld   (de),a
                    ret
; *************************************************************************************


; *************************************************************************************
; in:
;       bc = length of data
;       hl = pointer to data
;       ix = file handle
.WriteLine
                    ld   de,0
                    call_oz OS_Mv
                    ret
; *************************************************************************************


; *************************************************************************************
.GetDefaultListingFilename
                    ld   hl, defaultflnm
                    ld   bc,14
                    ldir
                    ret
; *************************************************************************************


; *************************************************************************************
.catlg_banner       defm "CATALOGUE FILES", 0
.catlg_msg          defm 13, 10, " List Catalogue to PipeDream file.",0
.filename_msg       defm 1,"2+C Filename: ",0
.catend_msg         defm " Catalogue written to file.", 0
.defaultflnm        defm "/filearea.pdd",0
.pdformat           defm "%CO:A,60,60%"
