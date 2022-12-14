     xlib displayblock

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
;
;***************************************************************************************************

     lib pixeladdress


; ******************************************************************
;
; Display block at (x,y) coordinate in graphics area.
; The block will be XOR'ed into graphics memory.
;
; in:  ix = pointer to graphics block definition
;      hl = (x,y) coordinate of block to be displayed
;
; out: none.
;
; ix points to a definition of the following structure:
;
;         .blockdef           defb end_blockdef-blockdef
;                             defb <width>,<heigth>
;
;                             ...  ; user data structure, if needed
;
;         .end_blockdef       defb byte, byte ...      ; <width> for all rows of block
;                             defb byte, byte ...
;                             ...
;                             defb byte, byte ...
;                             ; <height> of block (no. of rows)
;
; if ix = 0 (NULL) then displayblock returns immediatly.
; register usage:
;
;      iy  = offset (byte offset for displaying a single pixel row of block
;      b,c = shifted pixel graphics
;      de = address of current byte in graphics screen
;      h,l = bit position of byte in graphics screen
;
;      bc = blockptr, pointer to current byte of zetriz block graphics
;      hl  = (x,y)
;
; registers changed after return:
;  ......hl/ixiy ........ same
;  afbcde../.... afbcdehl different
;
; ----------------------------------------------------------------------
; Design & programming by Gunther Strube, Copyright (C) InterLogic 1995
; ----------------------------------------------------------------------
;
.displayblock       push ix
                    pop  bc
                    ld   a,b
                    or   c
                    ret  z              ; return if ix is a null-pointer...

                    push hl
                    push iy

                    push hl
                    exx
                    pop  hl             ; (x,y)
                    ld   b,0
                    ld   c,(ix+0)       ; get offset pointer to graphics
                    push ix
                    add  ix,bc
                    push ix
                    pop  bc             ; blockptr = bc (base of zetriz block graphics)
                    pop  ix
                    exx

                    call pixeladdress   ; addr,bitpos = pixeladdress(x,y)
                    inc  a
                    ld   c,a            ; c = bit position to shift in graphics byte

                    ld   b,(ix+2)       ; for h=0 to height-1
.block_row_loop     push bc             ;   c = bitpos
                    ld   iy,0           ;   offset = 0
                    ld   b,(ix+1)

.block_col_loop     push bc             ;   for w=0 to <width>-1
                    exx
                    ld   a,(bc)
                    inc  bc             ;     ++blockptr
                    exx
                    ld   h,a            ;     bitmask = (blockptr)
                    ld   l,0            ;     byte = 0

                    exx
                    ld   a,h            ;     if x mod 8 <> 0
                    and  @00000111
                    exx
                    jr   z, store_bitmask
.across_boundary    ld   l,h            ;        byte = bitmask
                    ld   h,0            ;        bitmask = 0
.shift_bitmask      add  hl,hl          ;        for c=bitpos to 0 step -1
                    dec  c              ;           sla byte: rl bitmask
                    jr   nz, shift_bitmask ;     endfor c
.store_bitmask      push iy             ;     preserve offset value
                    add  iy,de          ;     addr+offset
                    ld   a,(iy+0)
                    xor  h              ;
                    ld   (iy+0),a       ;     (addr+offset) xor bitmask
                    ld   a,(iy+8)
                    xor  l              ;
                    ld   (iy+8),a       ;     (addr+offset+8) xor byte
                    pop  iy
                    ld   bc,8
                    add  iy,bc          ;     offset += 8
                    pop  bc
                    djnz block_col_loop ;   end for w

                    exx
                    inc  l              ;   ++y
                    ld   a,l
                    exx
                    and  @00000111      ;   if y mod 8 = 0
                    jr   nz, next_col_byte
                    ld   a,256-7
                    add  a,e
                    ld   e,a
                    inc  d              ;      addr += 256-7
                    jr   block_endfor_h ;   else
.next_col_byte      inc  de             ;      ++addr
.block_endfor_h     pop  bc
                    djnz block_row_loop ; endfor h

                    pop  iy
                    pop  hl             ; hl = (x,y)
                    ret
