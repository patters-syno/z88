; *************************************************************************************
; RomUpdate
; (C) Gunther Strube (hello@bits4fun.net) 2005-2011
;
; RomUpdate is free software; you can redistribute it and/or modify it under the terms of the
; GNU General Public License as published by the Free Software Foundation;
; either version 2, or (at your option) any later version.
; RomUpdate is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY;
; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
; See the GNU General Public License for more details.
; You should have received a copy of the GNU General Public License along with RomUpdate;
; see the file COPYING. If not, write to the
; Free Software Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA 02111-1307, USA.
;
; *************************************************************************************

     MODULE Banks

     include "error.def"
     include "memory.def"
     include "fileio.def"

     ; RomUpdate runtime variables
     include "romupdate.def"

     lib MemDefBank, SafeBHLSegment
     lib RamDevFreeSpace, MemReadByte, FlashEprWriteBlock

     xref CrcBuffer, CrcFile, CheckCrc, GetTotalFreeRam
     xref MsgCrcCheckBankFile, ErrMsgBankFile, ErrMsgCrcFailBankFile

     xdef RegisterPreservedSectorBanks, PreserveSectorBanks, CheckPreservedSectorBanks
     xdef RestoreSectorBanks, DeletePreservedSectorBanks
     xdef ValidateRamBankFile
     xdef BlowBufferToBank, CheckBankFreeSpace, IsBankUsed, CopyBank, CopyMemory
     xdef OpenRamBankFile, LoadRamBankFile, CheckBankFileCrc


; *************************************************************************************
; Register the banks of the 64K sector that is not part of the DOR of the found
; application in the [presvdbanks] array. Empty (containing FF's) banks are marked as 0.
;
; This routine might also be used in a generic way to register all complementary banks
; of specified bank no. in B register, within the sector that must be preserved.
;
; The array will contain the numbers of the absolute banks that are going to be
; preserved as ":RAM.-/bank.<bankno>" files. The array contains four items, where a
; single item is 0, which is the bank of the application to be updated (hence
; not preserved as a bank file).
;
; If a bank that logically should be preserved (it is not the bank to be updated) and
; the contents of that bank is empty (ie. all FF's), then it will not be registered
; to be preserved (marked as 0) (which saves space in RAM filing system, and 'update' time).
;
; IN:
;       B = number of bank containing code to be updated (ie. not to be preserved)
; OUT:
;       [presvdbanks] array updated with bank numbers to be preserved in sector
;
; Registers changed after return:
;    ..B.DEHL/IXIY same
;    AF.C..../.... different
;
.RegisterPreservedSectorBanks
                    push de
                    ld   de,presvdbanks+3               ; point at end of array
                    ld   c,3
.preserve_loop
                    ld   a,b
                    and  @11111100
                    or   c
                    cp   b
                    call z,notpreserved                 ; don't register the bank which is to be updated
                    call nz,preservebank                ; this bank is to be preserved (not part of DOR)
                    inc  c
                    dec  c
                    jr   z, exit_regpresvbanks          ; sector is scanned for banks to be preserved
                    dec  c
                    dec  de
                    jr   preserve_loop
.notpreserved       ld   a,0                            ; indicate bank not to be preserved as 0
.preserve           ld   (de),a
                    ret
.preservebank       call IsBankUsed                     ; only preserve bank if it contains data...
                    jr   nz, preserve
                    jr   notpreserved                   ; bank contained only FF's, not necessary to preserve...
.exit_regpresvbanks
                    pop  de
                    ret
; *************************************************************************************


; *************************************************************************************
; Save the banks to RAM filing system to be preserved (before sector erase) as
; ":RAM.-/bank.<bankno>" files. Three out of the four banks in the 64K sector is
; preserved. The remaining bank is handled separately which contains the code to be
; updated.
;
; Before the bank is preserved to a RAM file, a CRC is made of the bank and
; stored at [presvdbankcrcs]. The CRC is checked before the bank is later restored to
; ensure that the RAM file is an exact match of the original bank contents on the card.
;
; IN:
;       None.
; OUT:
;       Fc = 1, No room, file I/O error or CRC mismatch when preserving banks to RAM filing system
;       Fc = 0, banks were successfully preserved to RAM filing system and CRC checked.
;
; Registers changed after return:
;    ......../..IY same
;    AFBCDEHL/IX.. different
;
.PreserveSectorBanks
                    ld   de,presvdbanks+3               ; point at end of array
                    ld   b,3
.presrvbank_loop
                    ld   a,(de)
                    or   a
                    call nz,preservesectorbank          ; this bank is to be preserved as a file
                    ret  c                              ; an error occurred while preserving a bank...

                    inc  b
                    dec  b
                    ret  z                              ; sector banks have been preserved
                    dec  b
                    dec  de
                    jr   presrvbank_loop
.preservesectorbank
                    push bc
                    push de
                    ld   b,a
                    ld   a, OP_OUT
                    call GetPassiveBankFileHandle
                    jr   c, exit_preservebank           ; couldn't create file (in use?)...

                    ld   hl,0
                    call SafeBHLSegment                 ; HL points at start of 'free' segment in Z80 address space
                                                        ; (C = Segment specifier of free segment)
                    pop  de
                    push de
                    ld   a,(de)                         ; get bank (number) to be preserved
                    ld   b,a
                    push bc
                    call MemDefBank                     ; bind bank into Z80 address space
                    push bc                             ; (preserve old bank binding)

                    push hl
                    ld   bc, banksize
                    push bc
                    ld   de,0
                    oz   OS_MV                          ; copy bank contents to file...
                    pop  bc
                    pop  hl

                    push af
                    call CrcBuffer                      ; calculate CRC-32 of 16K bank at (HL), returned in DEHL
                    pop  af                             ; restored OS_MV status
                    pop  bc
                    call MemDefBank                     ; restore old bank binding

                    push af
                    oz   GN_Cl                          ; close file (copy of bank)
                    pop  af
                    pop  bc                             ; return OS_MV status (RC_ROOM error, or bank successfully copied to file)
                    jr   c, exit_preservebank           ; I/O error...

                    ld   a,b
                    and  @00000011                      ; bank no within sector
                    add  a,a
                    add  a,a                            ; index offset for CRC array
                    push hl
                    ld   hl,presvdbankcrcs              ; base pointer of array of bank CRC's
                    ld   b,0
                    ld   c,a
                    add  hl,bc                          ; offset pointer to this bank CRC
                    push hl
                    pop  bc
                    pop  hl
                    ld   a,l
                    ld   (bc),a                         ; presvdbankcrcs[bankNo] = CRC
                    inc  bc
                    ld   a,h
                    ld   (bc),a
                    inc  bc
                    ld   a,e
                    ld   (bc),a
                    inc  bc
                    ld   a,d
                    ld   (bc),a                         ; CRC registered for bankNo
.exit_preservebank
                    pop  de
                    pop  bc
                    ret
; *************************************************************************************


; *************************************************************************************
; CRC check the sector banks of the 64K sector that was preserved in RAM
; filing system as ":RAM.-/bank.<bankno>" files.
;
; IN:
;       None.
; OUT:
;       Fc = 1,
;         File I/O error (A = RC_xx reason code)
;       Fc = 0,
;         Fz = 1, all (preserved file) banks were successfully CRC checked
;         Fz = 0, a preserved bank didn't match original CRC from card
;
; Registers changed after return:
;    ......../..IY same
;    AFBCDEHL/IX.. different
;
.CheckPreservedSectorBanks
                    ld   de,presvdbanks+3               ; point at end of array
                    ld   b,3
.checkcrc_loop
                    ld   a,(de)
                    or   a
                    call nz,checkcrcbank                ; compare CRC of bank file with CRC from card
                    ret  c                              ; an I/O error occurred before CRC checking the bank...
                    ret  nz                             ; CRC error!

                    inc  b
                    dec  b
                    ret  z                              ; all sector banks have been successfully CRC checked
                    dec  b
                    dec  de
                    jr   checkcrc_loop
.checkcrcbank
                    push bc
                    push de
                    ld   b,a
                    call CrcTempBankFile                ; Calculate CRC of passive bank B file in DEHL
                    jr   c, exit_checkcrcbank           ; open error when CRC checking buffer!

                    pop  bc
                    push bc
                    ld   a,(bc)
                    and  @00000011                      ; get bank (number) within sector...
                    ld   bc,presvdbankcrcs              ; base pointer to array of preserved bank CRC's
                    add  a,a
                    add  a,a                            ; sector bank no * 4 = pointer to array offset
                    add  a,c
                    ld   c,a
                    ld   a,0
                    adc  a,b
                    ld   b,a                            ; pointer to stored CRC of preserved bank within array
                    call CheckCrc                       ; is the CRC of buffer contents the same as CRC from original bank?
.exit_checkcrcbank
                    pop  de
                    pop  bc
                    ret
; *************************************************************************************


; *************************************************************************************
; Restore the banks into the 64K sector that was previously preserved in RAM filing
; system as ":RAM.-/bank.<bankno>" files. The banks to be restored are registered in
; the [presvdbanks] array.
;
; Restoring the banks has only meaning if the sector has been erased.
; When the passive banks have been restored, the temporary file in :RAM.- are
; automatically deleted.
;
; IN:
;       None.
; OUT:
;       Fc = 1, file I/O or a bank was not successfully restored to sector (likely a blow error).
;       Fc = 0, all banks were successfully restored to sector on Flash Card.
;
; Registers changed after return:
;    ......../.... same
;    AFBCDEHL/IXIY different
;
.RestoreSectorBanks
                    ld   de,presvdbanks+3               ; point at end of array
                    ld   b,3
.restorebank_loop
                    ld   a,(de)
                    or   a
                    call nz,restorebank                 ; this bank is to be restored from file
                    ret  c                              ; an error occurred while restoring a bank...

                    inc  b
                    dec  b
                    jr   z, deltmpfiles                 ; sector banks have been restored, clean up temp files...
                    dec  b
                    dec  de
                    jr   restorebank_loop
.deltmpfiles
                    call DeletePreservedSectorBanks     ; get rid of temporary ":RAM.-/bank.x" files...
                    ret
.restorebank
                    push bc
                    push de
                    ld   b,a
                    call LoadTempBankFile               ; get passive bank B into buffer
                    jr   c, exit_restorebanks           ; I/O error!

                    pop  de
                    push de
                    ld   a,(de)                         ; get (number) in sector to be restored
                    ld   b,a
                    xor  a                              ; poll for flash programming algorithm...
                    call BlowBufferToBank
.exit_restorebanks                                      ; report back if a Flash programming error occurred
                    pop  de
                    pop  bc
                    ret
; *************************************************************************************


; *************************************************************************************
; Validate bank contents to be 'empty' or containing data; an empty bank only
; contains FFh bytes.
;
; IN:
;       A = Bank number (absolute)
; OUT:
;       Fz = 1, Bank was empty
;       Fz = 0, Bank contains data / code
;
; Registers changed after return:
;    A.BCDEHL/IXIY same
;    .F....../.... different
;
.IsBankUsed
                    push bc
                    push af
                    push hl

                    ld   hl,0
                    call SafeBHLSegment                 ; HL points at start of 'free' segment in Z80 address space
                                                        ; (C = Segment specifier of free segment)
                    ld   b,a
                    call MemDefBank                     ; bind bank into Z80 address space
                    push bc                             ; (preserve old bank binding)
                    ld   bc, banksize
.check_empty_bank
                    ld   a,(hl)
                    inc  hl
                    cp   $ff
                    jr   nz, bank_not_empty             ; a non-empty byte was found in the bank...
                    dec  bc
                    ld   a,b
                    or   c                              ; return Fz = 1, if last byte of bank was checked
                    jr   nz, check_empty_bank
.bank_not_empty
                    pop  bc
                    call MemDefBank                     ; restore old bank binding

                    pop  hl
                    pop  bc
                    ld   a,b                            ; original A restored
                    pop  bc
                    ret
; *************************************************************************************


; *************************************************************************************
; Delete the preserved bank files from RAM filing system (named as ":RAM.-/bank.<bankno>").
; No error status is returned. This is a 'cleanup' function.
;
; Registers changed after return:
;    AFBCDEHL/IXIY same
;    ......../.... different
;
.DeletePreservedSectorBanks
                    push af
                    push bc
                    push de
                    push hl

                    ld   de,presvdbanks+3               ; point at end of array
                    ld   b,3
.delbankfile_loop
                    ld   a,(de)
                    or   a
                    call nz,delbankfile                 ; this bank file is to be deleted

                    inc  b
                    dec  b
                    jr   z, exit_delpresrvbfiles        ; sector banks have been preserved
                    dec  b
                    dec  de
                    jr   delbankfile_loop
.delbankfile
                    push bc
                    push de
                    ld   b,a
                    call GetPassiveBankFilename         ; filename based on bank number in B,
                    ld   b,0                            ; HL points at filename...
                    oz   GN_Del                         ; delete temporary preserved bank file
                    pop  de
                    pop  bc
                    ret
.exit_delpresrvbfiles
                    pop  hl
                    pop  de
                    pop  bc
                    pop  af
                    ret
; *************************************************************************************


; *************************************************************************************
;
; Check if there is enough free RAM available to store the temporary passive bank
; files (registered to be preserved for the sector). Each bank file occupies approx.
; 67 pages (each page is 256 bytes) in the RAM filing system.
;
; IN:
;       None.
; OUT:
;       Fc = 1, insufficient free RAM space to preserve passive banks.
;       Fc = 0, all banks may be preserved in RAM filing system
;       DE = total pages needed to preserve banks to RAM
;       HL = total pages of free RAM in Z88.
;
; Registers changed after return:
;    ..BC..../IXIY same
;    AF..DEHL/.... different
;
.CheckBankFreeSpace
                    push bc
                    ld   de,presvdbanks+3               ; point at end of array
                    ld   bc,$0300                       ; accumulated amount of needed bank pages
.calc_bankspace
                    ld   a,(de)
                    or   a
                    jr   z, check_next_bank             ; this bank is not registered to be preserved (= 0)...
                    ld   a,67
                    add  a,c
                    ld   c,a                            ; another 68 RAM pages is needed for registered bank
.check_next_bank
                    inc  b
                    dec  b
                    jr   z, comp_free_ram               ; sector scanned for registered banks, compare with free ram
                    dec  b
                    dec  de
                    jr   calc_bankspace
.comp_free_ram
                    push bc
                    call GetTotalFreeRam
                    pop  de
                    push hl                             ; necessary space for preserved banks in BC
                    sbc  hl,de                          ; Return Fc = 1, if there isn't enough free space for banks...
                    pop  hl                             ; return HL & DE page numbers...

                    pop  bc
                    ret
; *************************************************************************************


; *************************************************************************************
; Generate preserved bank filename ":RAM.-/bank.<bankno>" and return HL to start
; of filename (built in filename buffer). Bank numbers are truncated to 0-3 range.
;
; IN:
;       B = bank number
; OUT:
;       (filename) = complete bank filename added with bank number extension
;       HL = points to start of filename
;
; Registers changed after return:
;    AFBCDE../IXIY same
;    ......HL/.... different
;
.GetPassiveBankFilename
                    push af
                    push de
                    call CpyBaseBankFileName
                    ld   a,b
                    and  @00000011                      ; preserve only bank number within sector
                    or   48                             ; make bank number an ascii number...
                    ld   (de),a                         ; and append it as the filename extension
                    inc  de
                    xor  a
                    ld   (de),a                         ; null terminate filename
                    pop  de
                    ld   hl, filename                   ; return pointer to start of filename
                    pop  af
                    ret
; *************************************************************************************


; *************************************************************************************
; Get file handle for temporary bank file ":RAM.-/bank.<bankno>".
;
; IN:
;    A = OP_xx reason code for GN_Opf
;    B = Bank number
; OUT:
;    Fc = 0
;         IX = file handle
;    Fc = 1
;         file open error (A = reason code)
;
; Registers changed after return:
;    ..BCDEHL/..IY same
;    AF....../IX.. different
;
.GetPassiveBankFileHandle
                    call GetPassiveBankFilename         ; filename based on bank number in B
                    ld   d,h
                    ld   e,l
                    ld   bc,128                         ; local filename
                    oz   GN_Opf                         ; return file handle in IX (if successfull)
                    ret
; *************************************************************************************


; *************************************************************************************
; CRC calculate the (passive) bank in temporary RAM file, defined by bank B
;
; IN:
;    B = (absolute) bank number of passive bank file
;
; OUT:
;    Fc = 0,
;         DEHL = CRC value of passive bank file
;    Fc = 1,
;         file open, I/O error (A = reason code)
;
; Registers changed after return:
;    ......../..IY same
;    AFBCDEHL/IX.. different
;
.CrcTempBankFile
                    ld   a, OP_IN
                    call GetPassiveBankFileHandle
                    ret  c                              ; couldn't open file ...

                    push iy
                    ld   bc,1024
                    ld   hl,0
                    add  hl,sp
                    push hl
                    pop  iy                             ; remember old SP
                    sbc  hl,bc
                    ld   sp,hl                          ; make a 1K CRC buffer on stack
                    ex   de,hl                          ; DE points at start of buffer, BC = length of buffer
                    call CrcFile

                    oz   GN_Cl                          ; close file
                    ld   sp,iy                          ; restore original SP
                    pop  iy
                    ret
; *************************************************************************************



; *************************************************************************************
; CRC check bank file, defined by filename in [bankfilename], by loading file into
; a buffer and issue a CRC32 calculation, then compare the CRC fetched from the
; configuration file in [bankfilecrc].
;
; Return to caller if the CRC matched, otherwise jump to error routine and exit program
;
.ValidateRamBankFile
                    call MsgCrcCheckBankFile            ; display progress message for CRC check of bank file
                    call LoadRamBankFile
                    jp   c,ErrMsgBankFile               ; couldn't open file (in use / not found?)...

                    ld   hl,buffer
                    ld   bc,banksize                    ; 16K buffer
                    call CrcBuffer                      ; calculate CRC-32 of bank file, returned in DEHL
                    call CheckBankFileCrc               ; check the CRC-32 of the bank file with the CRC of the config file
                    jp   nz,ErrMsgCrcFailBankFile       ; CRC didn't match: the file is corrupt and will not be updated to card!
                    ret
; *************************************************************************************



; *************************************************************************************
; Check the calculated CRC in DEHL with the CRC of the config file to validate that
; the binary bank file is not corrupted during transfer (or was corrupted in the
; RAM filing system).
;
; IN:
;       DEHL = calculated CRC
; OUT:
;       Fz = 1, CRC is valid
;       Fz = 0, CRC does not match the CRC from the Config file
;
; Registers changed after return:
;    ..BCDEHL/IXIY same
;    AF....../.... different
;
.CheckBankFileCrc
                    push bc
                    ld   bc,bankfilecrc
                    call CheckCrc
                    pop  bc
                    ret
; *************************************************************************************


; *************************************************************************************
; Load (passive) bank into buffer from temporary RAM file, defined by bank B
;
; IN:
;    B = (absolute) bank number of passive bank file
;
; OUT:
;    Fc = 0,
;         (buffer contains temp. bank file)
;         HL = start of buffer
;         BC = length of buffer
;    Fc = 1,
;         file open, I/O error (A = reason code)
;
; Registers changed after return:
;    ......../..IY same
;    AFBCDEHL/IX.. different
;
.LoadTempBankFile
                    ld   a, OP_IN
                    call GetPassiveBankFileHandle
                    ret  c                              ; couldn't open file ...

                    ld   bc, banksize
                    ld   de,buffer
                    ld   hl,0
                    oz   OS_MV                          ; copy bank file contents into buffer...
                    push af
                    oz   GN_Cl                          ; close file
                    pop  af                             ; return I/O error, if any...
                    ret
; *************************************************************************************


; *************************************************************************************
; Load specified bank file(name) from RAM filing system into 16K buffer.
;
; Registers changed after return:
;    ......../..IY same
;    AFBCDEHL/IX.. different
;
.LoadRamBankFile
                    call OpenRamBankFile
                    ret  c
                    ld   bc,banksize
                    ld   de,buffer
                    ld   hl,0
                    oz   OS_MV                          ; copy bank file contents into buffer...
                    push af
                    oz   GN_Cl                          ; close file
                    pop  af
                    ret
; *************************************************************************************


; *************************************************************************************
; Open bank file in RAM filing system (for reading only), which is specified in
; [bankfilename] variable.
;
; Returns the usual GN_Opf file parameters.
;
.OpenRamBankFile
                    ld   bc,128
                    ld   hl,bankfilename                ; (local) filename to card image
                    ld   de,filename                    ; output buffer for expanded filename (max 128 byte)...
                    ld   a, op_in
                    oz   GN_Opf
                    ret
; *************************************************************************************


; *************************************************************************************
; Copy 16K Bank to buffer
;
; IN:
;    B = Bank no. (absolute)
; OUT:
;    Fc = 0
;    (buffer) = bank
;
; Registers changed after return:
;    ..BCDEHL/IXIY same
;    AF....../.... different
;
.CopyBank
                    push bc
                    push de
                    push hl

                    ld   hl,0                           ; BHL points to start of bank
                    ld   de,buffer
                    exx
                    ld   bc,banksize
                    exx
                    call CopyMemory                     ; (BHL) -> (DE)

                    pop  hl
                    pop  de
                    pop  bc
                    ret
; *************************************************************************************


; *************************************************************************************
; Copy memory contents from (BHL) to (DE).
; NB: pointers and lengths in combination must stay with bank boundaries.
;
; In:
;    BHL = pointer to source (if B=0 then HL is also a local address space)
;    DE = local address space destination pointer
;    bc' = total no bytes to copy
;
; Out:
;
; Registers changed after return:
;    ......../IXIY same
;    AFBCDEHL/.... different
;
.CopyMemory
                    inc  b
                    dec  b
                    jr   z, copymem                     ; copy local address space memory...
if POPDOWN
                    set  7,h
                    res  6,h                            ; for RomUpdate popdown version, force bank offset to use segment 2
                    ld   c,MS_S2                        ; (RomUpdate popdown code is running in segment 3)
else
                    set  7,h
                    set  6,h                            ; for RomUpdate BBC BASIC version, force bank offset to use segment 3
                    ld   c,MS_S3                        ; (RomUpdate BBC BASIC code is running in segment 0 & 1)
endif
                    call MemDefBank                     ; get bank into address space
                    push bc
                    call copymem
                    pop  bc
                    jp   MemDefBank
.copymem
                    exx
                    push bc
                    exx
                    pop  bc
                    ldir                                ; (BHL++) -> (DE++)
                    ret
; *************************************************************************************


; *************************************************************************************
; Blow contents of 16K buffer to bank B in Flash Card
;
; IN:
;       A = FE_28F, FE_29F or 0 (poll card for blowing algorithm)
;       B = Bank number (absolute)
; OUT:
;       Fc = 1, bank was not blown properly to Flash Card.
;              A = RC_ error code
;       Fc = 0, bank were successfully blown to Flash Card.
;
; Registers changed after return:
;    ..BCDEHL/IXIY same
;    AF....../.... different
;
.BlowBufferToBank
                    push bc
                    push de
                    push hl
                    push iy

                    ld   de,buffer                      ; blow contents of buffer to bank
                    ld   iy, banksize
if POPDOWN
                    ld   hl,$8000                       ; blow from start of bank (in segment 2)...
else
                    ld   hl,$c000                       ; BBC BASIC: blow from start of bank (in segment 3)...
endif
                    call FlashEprWriteBlock
                    pop  iy
                    pop  hl
                    pop  de
                    pop  bc
                    ret
; *************************************************************************************


; *************************************************************************************
; Copy base filename ":RAM.-/bank." to (filename), and return DE to point at first
; character after filename (so that en extension and null-terminator might be added).
;
; IN:
;       None.
; OUT:
;       (filename) = contains ":RAM.-/bank."
;
; Registers changed after return:
;    A.BC..HL/IXIY same
;    .F..DE../.... different
;
.CpyBaseBankFileName
                    push bc
                    push hl
                    ld   bc, 12
                    ld   hl, presvbankflnm
                    ld   de, filename
                    ldir
                    pop  hl
                    pop  bc
                    ret
; *************************************************************************************

.presvbankflnm      defm ":RAM.-/bank."                 ; base filename for preserved bank in sector
