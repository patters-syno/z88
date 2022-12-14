; *************************************************************************************
; RomCombiner
; (c) Garry Lancaster, 2000-2012 (yahoogroups@zxplus3e.plus.com)
;
; RomCombiner is free software; you can redistribute it and/or modify it under the terms of the
; GNU General Public License as published by the Free Software Foundation;
; either version 2, or (at your option) any later version.
; RomCombiner is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY;
; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
; See the GNU General Public License for more details.
; You should have received a copy of the GNU General Public License along with RomCombiner;
; see the file COPYING. If not, write to the
; Free Software Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA 02111-1307, USA.
;
;
; *************************************************************************************

; RomCombiner M/C routines to read/write ROM pages

     module romcode

     xdef crctable
     xref CrcBuffer
     
     org $b500

     ; These libraries refer to V0.8 or greater of stdlib:
     lib FlashEprCardID, FlashEprCardErase, FlashEprBlockErase, FlashEprWriteBlock

     include "flashepr.def"
     include "memory.def"

     include "../romupdate/crctable.asm"

; Jump sub routine table (to define nice, static CALL addresses in BBC BASIC)
     jp   blowbank      ; $B90F
     jp   checkbank     ; $B97E
     jp   readbank      ; $B9A0
     jp   eraseflash    ; $B9B4
     jp   crc32bank     ; $B9D4

; The BLOWBANK routine blows bank B (00-ff) to standard EPROM type C,
; with data stored at DE. On exit, HL=0 if successful, or address
; of failed byte (in segment 3)
; If C=0, blows a bank of a Flash EPROM

.blowbank
     xor  a
     cp   c              ; is it a FLASH eprom?
     jr   z,blowflash    ; move on if so
     di
     ld   hl,$c000
     ld   a,($4D3)
     push af
     ld   a,b
     or   $c0            ; mask for slot 3
     ld   ($4D3),a
     out  ($D3),a
.nextbyte
     ld   b,75
     ld   a,c
     out  ($B3),a
.proloop
     ld   a,$0E
     out  ($B0),a
     ld   a,(de)
     ld   (hl),a
     ld   a,$04
     out  ($B0),a
     ld   a,(de)
     cp   (hl)
     jr   z,byteok
     djnz proloop
     jr   exit
.byteok
     ld   a,76
     sub  b
     ld   b,a
.ovploop
     out  ($B0),a
     ld   a,(de)
     ld   (hl),a
     ld   a,$04
     out  ($B0),a
     djnz ovploop
     inc  de
     inc  hl
     ld   a,h
     or   l
     jr   nz,nextbyte
.exit
     ld   a,$05
     out  ($B0),a
.exit2
     pop  af
     ld   ($4D3),a
     out  ($D3),a
     ei
     ret

.blowflash               ; DE points at buffer to blow
     push bc             ; bank B contains slot specifier
     ld   a,b
     and  @11000000
     rlca
     rlca
     ld   c,a            ; slot C (of bank B)
     call FlashEprCardID
     pop  bc
     ld   hl,$c000       ; destination start address of bank (use segment 3 to blow data)
     ret  c              ; exit if not Flash card
     ld   iy,256         ; blow bank in 256 byte blocks
     ld   c,a            ; copy of Flash type
.flash_blow_bank_loop
     ld   a,c            ; A = flash type programming
     call FlashEprWriteBlock
     ret  c
     inc  d              ; get ready to blow next page of 16K buffer
     ld   a,h
     and  $3f            ; remove segment specifier
     or   l              ; when HL = 0, whole bank has been blown...
     jr   nz,flash_blow_bank_loop     
     ld   hl,0000        ; HL = 0 indicate success to BBC BASIC
     ret                 

; Subroutine to check blocks of an EPROM are properly erased
; On entry, B=bank to check (00-3f)
; On exit, HL=0 if no error, or $ffff if error

.checkbank
     ld   a,($4D3)
     push af
     ld   a,b
     or   $c0            ; mask for slot 3
     ld   ($4D3),a
     out  ($D3),a
     ld   hl,$c000
     ld   a,$ff
     ld   c,64           ; 64 x 256 bytes=16K
.cknextpage
     ld   b,0
.cknextbyte
     and  (hl)
     inc  hl
     djnz cknextbyte
     dec  c
     jr   nz,cknextpage
     inc  a
     jr   z,exit2        ; exit with HL=0 if all bytes $ff
     dec  hl             ; else flag error with HL=$ffff
     jr   exit2

; The READBANK routine reads page B to address DE

.readbank
     ld   a,($4D3)
     push af
     ld   a,b
     ld   ($4D3),a
     out  ($D3),a
     ld   hl,$C000
     ld   bc,$4000
     ldir
     jr   exit2

; Subroutine to erase blocks of a Flash EPROM
; On entry, C=slot number, E=block to erase ($ff=all)
; On exit, HL=0 if no error, or $ffff if error
.eraseflash
     call FlashEprCardID ; check for Flash EPROM in slot 3
     ld   hl,$ffff
     jr   c,eraseerr     ; exit if not Flash device
     ld   a,e
     cp   $ff
     jr   z,eraseall     ; erase whole card

     ld   b,e            ; erase block in slot 3
     call FlashEprBlockErase
     jr   checkerror
.eraseall                ; erase complete card in slot 3
     call FlashEprCardErase
.checkerror
     jr   c,eraseerr
     ld   hl,0           ; indicate success to BBC BASIC
     ret
.eraseerr
     ld   hl,$ffff
     ret

; This routine is called from BBC BASIC with 
;   HL = pointer to bank buffer
;   BC = size of bank   
; the CRC32 is returned back to BBC BASIC in HL H'L' (high word, low word)
;
.crc32bank
     call CrcBuffer     ; this routine returns CRC32 in DEHL
     ex   de,hl         ; HL is now high word
     push de
     exx
     pop  hl            ; H'L' is low word
     exx
     ret
     