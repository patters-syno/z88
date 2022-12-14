; *************************************************************************************
; EazyLink - Fast Client/Server File Management, including support for PCLINK II protocol
; (C) Gunther Strube (hello@bits4fun.net) 1990-2012
;
; 32bit Cyclic Redundancy Checksum Management for EazyLink
; CRC algorithm from UnZip, by Garry Lancaster, Copyright 1999, released as GPL.
;
; EazyLink is free software; you can redistribute it and/or modify it under the terms of the
; GNU General Public License as published by the Free Software Foundation;
; either version 2, or (at your option) any later version.
; EazyLink is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY;
; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
; See the GNU General Public License for more details.
; You should have received a copy of the GNU General Public License along with EazyLink;
; see the file COPYING. If not, write to the
; Free Software Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA 02111-1307, USA.
;
; *************************************************************************************


     module Crc32File

     include "fileio.def"
     include "integer.def"
     include "rtmvars.def"

     xdef ESC_I_cmd, HexNibble

     lib FileEprFindFile, FileEprFileImage, FileEprFileEntryInfo
     lib FileEprTransferBlockSize, MemDefBank

     xref crctable
     xref ESC_N, ESC_Z, SendString, Debug_message, Message37
     xref CheckEprName, Set_TraFlag, Restore_TraFlag, Fetch_pathname
     xref Get_file_handle, Close_file, CheckFileAreaOfSlot, Msg_Command_aborted


; ************************************************************
; Get CRC-32 of file (RAM or File Card)
;
; Client:      ESC "i" <Filename> ESC "Z"
;
; Server:      ESC "N" <CRC32> ESC "Z"  (File found)
;              ESC "Z"                  (File not found)
;
.ESC_I_cmd     CALL Set_TraFlag
               CALL Fetch_pathname                ; load filename into filename_buffer
               CALL Restore_TraFlag
               JR   C,esc_i_aborted
               JR   Z,esc_i_aborted               ; timeout - communication stopped
               LD   HL, Message37
               CALL Debug_message                 ; "File CRC-32"
               LD   HL,filename_buffer
               CALL Debug_message                 ; write filename to screen

               CALL CheckEprName                  ; Path begins with ":EPR.x"?
               JR   Z, get_eprfilecrc32           ; Yes, try to get CRC-32 of file in File Area...

               LD   A, OP_IN                      ; open file for transfer...
               LD   D,H
               LD   E,L                           ; (explicit filename overwrite original fname)
               CALL Get_file_handle               ; open file
               JR   C, file_not_found             ; ups, file not available
               LD   (file_handle),IX

               LD   BC,FileBufferSize
               LD   DE,File_buffer
               CALL CrcRamFile
               CALL Close_file                    ; close file
.crc_result
               LD   (File_ptr),HL                 ; low word of CRC-32
               LD   (File_ptr+2),DE               ; high word of CRC-32

.send_filecrc32
               LD   HL, File_ptr                  ; convert 32bit integer
               LD   DE, filename_buffer           ; to an ASCII string
               CALL Int32Hex

               LD   HL,ESC_N
               CALL SendString
               JR   C, esc_i_aborted
               JR   Z, esc_i_aborted

               LD   HL,filename_buffer            ; write File CRC-32 as ASCII string to Client
               CALL SendString
               JR   C, esc_i_aborted
               JR   Z, esc_i_aborted
.file_not_found
               LD   HL,ESC_Z
               CALL SendString
               JR   C, esc_i_aborted
               JR   Z, esc_i_aborted
               JR   end_ESC_I_cmd

.esc_i_aborted CALL Msg_Command_aborted
.end_ESC_I_cmd
               XOR A
               RET
.get_eprfilecrc32                                 ; Get CRC-32 of File in File Area
               call    CheckFileAreaOfSlot
               jr      c,file_not_found           ; this slot had no file area (no card)...
               jr      nz,file_not_found          ; this slot had no file area (card, but no file area)

               ld      de,filename_buffer+6       ; search for filename beginning at "/" in filea area of slot C
               call    FileEprFindFile            ; search for filename on file eprom...
               jr      c,file_not_found           ; this slot had no file area (no card)...
               jr      nz,file_not_found          ; File Entry was not found...

               call    FileEprFileCrc32           ; return CRC in DEHL
               jr      crc_result


; *************************************************************************************
;
; Perform a CRC-32 of RAM file, already opened by caller, from current file pointer until EOF.
; If the complete file is to be CRC'ed then it is vital that the current file pointer
; is at the beginning of the file (use FA_PTR / OS_FWM to reset file pointer) before
; executing this routine.
;
; In:
;    IX = handle of opened file
;    DE = pointer to CRC buffer
;    BC = size of CRC buffer
;
; Out:
;    Fc = 0,
;    DEHL = CRC
;
; Registers changed after return:
;    ......../IXIY same
;    AFBCDEHL/.... different
;
.CrcRamFile         call initCrc             ; initialise CRC register D'E'B'C' to FFFFFFFF
.scanfile           push bc
                    push de
                    push bc
                    ld   hl,0
                    call oz_os_mv            ; read bytes from file (and preserve alternate bc, de)
                    pop  hl
                    cp   a
                    sbc  hl,bc
                    jr   z,crcend            ; move on if no bytes read
                    ld   b,h
                    ld   c,l                 ; BC=#bytes actually read
                    pop  hl
                    push hl
                    call CrcIterateBuffer    ; accumulate CRC on current value in D'E'B'C'
                    pop  de
                    pop  bc
                    jr   scanfile
.crcend
                    pop  af
                    pop  af
                    call CrcResult           ; get current CRC in D'E'B'C' and complement in
                    cp   a                   ; return in DEHL as CRC result
                    ret                      ; Fc = 0
.oz_os_mv
                    exx
                    push bc
                    push de
                    exx
                    call_oz(os_mv)
                    exx
                    pop  de
                    pop  bc
                    exx
                    ret
; *************************************************************************************


; *************************************************************************************
;
; Perform complete CRC of specified buffer contents.
; CRC value is initialized to FFFFFFFF before buffer scan and result is complemented
; and returned in DEHL.
;
; In:
;    HL= pointer to CRC buffer
;    BC = size of CRC buffer
;
; Out:
;    DEHL = CRC
;
; Registers changed after return:
;    ......../IXIY same
;    AFBCDEHL/.... different
;
.CrcBuffer
                    call initCrc
                    call CrcIterateBuffer
                    call CrcResult
                    ret
.initCrc
                    exx
                    ld   de,$FFFF            ; initialise CRC register D'E'B'C'
                    ld   bc,$FFFF
                    exx
                    ret
.CrcIterateBuffer
                    ld   a,(hl)              ; get byte
                    inc  hl                  ; increment address
                    dec  bc                  ; decrement bytes left
                    exx
                    xor  c
                    ld   l,a
                    xor  a
                    sla  l
                    rla
                    sla  l
                    rla                      ; AL=4xCRC index byte
                    add  a,crctable/256
                    ld   h,a                 ; HL=index into CRC table
                    ld   a,(hl)
                    inc  hl
                    xor  b
                    ld   c,a                 ; shift and XOR 2nd byte to low
                    ld   a,(hl)
                    inc  hl
                    xor  e
                    ld   b,a                 ; shift and XOR 3rd byte to 2nd
                    ld   a,(hl)
                    inc  hl
                    xor  d
                    ld   e,a                 ; shift and XOR high byte to 3rd
                    ld   d,(hl)              ; get new high byte
                    exx
                    ld   a,b
                    or   c
                    jr   nz,CrcIterateBuffer ; back for more
                    ret
.CrcResult
                    exx
                    ld   a,d
                    cpl
                    ld   d,a                 ; complement high byte
                    ld   a,e
                    cpl
                    ld   e,a                 ; complement 3rd byte
                    ld   a,b
                    cpl
                    ld   h,a                 ; complement 2nd byte
                    ld   a,c
                    cpl
                    ld   l,a                 ; complement low byte
                    ret                      ; exit with DEHL=CRC
.end_CrcBuffer


; ***************************************************************************************************
;
; Convert 32bit integer at (HL) to hexadecimal string at (DE)
; Integer is in low byte, high byte order
.Int32Hex
                    push hl
                    ex   de,hl
                    ld   bc,8
                    add  hl,bc
                    ex   de,hl
                    pop  hl
                    xor  a
                    ld   (de),a              ; DE points a null-terminator
                    dec  de                  ; ready for first nibble of lowest byte of 32bit integer

                    ld   b,4                 ; 32bit integer is 4 bytes
.conv_hexloop
                    ld   a,(hl)
                    and  $0f
                    call hexnibble
                    ld   (de),a
                    dec  de

                    ld   a,(hl)
                    and  $f0
                    rrca
                    rrca
                    rrca
                    rrca
                    call hexnibble
                    ld   (de),a
                    dec  de
                    inc  hl                  ; get ready for next byte of 32bit integer..
                    djnz conv_hexloop
                    ret

.HexNibble          cp   $0a
                    jr   nc, hexnibble_16
                    add  a,$30
                    ret
.hexnibble_16       add  a,$37
                    ret


; ***************************************************************************************************
;
; Standard Z88 File Eprom Format.
;
; Generate CRC-32 of file entry in file area.
;
; IN:
;         BHL = pointer to file entry to be CRC-32 scanned
; OUT:
;         Fc = 0,
;              DEHL = CRC-32
;         Fc = 1,
;              File Entry at BHL was not found.
;                   A = RC_Onf
;
; Registers changed on return:
;    ......../..IY ........ same
;    AFBCDEHL/IX.. afbcdehl different
;
; -------------------------------------------------------------------------
; Design & Programming by Gunther Strube, June 2012
; -------------------------------------------------------------------------
;
.FileEprFileCrc32
                    push hl
                    ld   hl,$FFFF
                    ld   (file_ptr),hl
                    ld   (file_ptr+2),hl          ; initialise CRC register
                    pop  hl

                    push bc
                    push hl

                    call FileEprFileEntryInfo     ; return CDE = file image size, A = length of entry filename
                    jr   c, exit_FileEprCrc32     ; File entry not recognised, exit with error...
                    push bc
                    push de
                    exx
                    pop  de
                    pop  bc                       ; File Entry File Image size in 'CDE
                    exx

                    pop  hl
                    pop  bc                       ; BHL = pointer to entry in File Area
                    res  7,h
                    res  6,h                      ; discard segment mask, if any...
                    call FileEprFileImage         ; adjust BHL pointer to first byte of file image (beyond file entry header)
                    call Crc32FileEntry           ; Now, CRC-32-scan the file image, optionally across banks inn file area
                    exx
                    ld   bc,(file_ptr)
                    ld   de,(file_ptr+2)          ; get accumulated CRC
                    exx
                    jp   CrcResult                ; complete the final CRC-32 result in DEHL
.exit_FileEprCrc32
                    pop  hl
                    pop  bc
                    ret


; **************************************************************************
.Crc32FileEntry
.crc32_file_loop
                    exx                           ; file size = 0?
                    ld   a,d
                    or   e
                    exx
                    jr   nz,init_blocksize        ; file size not yet 0
                    exx
                    inc  c
                    dec  c
                    exx
                    ret  z                        ; File entry was successfully CRC-32 scanned (CDE = 0)!
.init_blocksize
                    call FileEprTransferBlockSize ; get block size in hl' based on current BHL pointer
                    exx                           ; and remaining file size in cde'
                    push bc
                    push de                       ; preserve remaining file size
                    exx

                    call EprFileCrc32Block        ; CRC-32 scan file entry at BHL block size IX

                    exx
                    pop  de
                    pop  bc                       ; restore remaining file size = CDE
                    exx
                    jr   crc32_file_loop          ; then get next block from source file

.EprFileCrc32Block
                    push bc                       ; preserve B (HL)
                    set  7,h
                    res  6,h                      ; use segment 2 to bind data block of file entry into address space
                    ld   a,b
                    exx
                    ld   b,a
                    ld   c, $02                   ; Use C = MS_S2 of BHL source data block
                    call MemDefBank               ; Bind bank of source data into segment C
                    push bc                       ; preserve old bank binding of segment C
                    push hl                       ; hl' (from FileEprTransferBlockSize) block size to be in main BC

                    ld   bc,(file_ptr)
                    ld   de,(file_ptr+2)          ; get current CRC in BC'DE'
                    exx
                    pop  bc                       ; now BHL source block in current address space

                    call CrcIterateBuffer         ; CRC-32 scan block at (HL), BC size

                    exx
                    ld   (file_ptr),bc
                    ld   (file_ptr+2),de

                    pop  bc
                    call MemDefBank               ; restore old segment C bank binding of BHL source data block
                    exx

                    res  7,h
                    res  6,h                      ; strip segment mask to become bank offset again..
                    pop  bc                       ; original B restored

                    inc  h                        ; source pointer crossed bank boundary?
                    dec  h                        ; (HL = 0, because segment specifier went into next segment)
                    ret  nz                       ; nope (within 16k offset)
                    inc  b                        ; remaining block of file is in next bank of file area
                    ret
