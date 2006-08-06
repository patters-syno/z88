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
; (C) Thierry Peycru (pek@users.sf.net), 2005-2006
; (C) Gunther Strube (gbs@users.sf.net), 2005-2006
;
; Copyright of original (binary) implementation, V4.0:
; (C) 1987,88 by Trinity Concepts Limited, Protechnic Computers Limited & Operating Systems Limited.
;
; $Id$
;***************************************************************************************************
;
; all keymap tables in one page
;
; structure of shift, square, and diamond tables:
;
;	dc.b n			  number of character pairs in table
;	dc.b inchar,outchar	  translates inchar into outchar
;	dc.b inchar,outchar,...   entries are ordered in ascending inchar order
;
; capsable table:
;
;	dc.b n			  number of character pairs in table
;	dc.b lcase,ucase	  translates lcase into ucase and vice versa
;	dc.b lcase,ucase,...	  entries can be unsorted, but why not sort them?
;
; structure of deadkey table:
;
;	dc.b n			  number of deadkeys in table
;	dc.b keycode,offset	  keycode of deadkey, offset into subtable for that key
;	dc.b keycode,offset,...   offset is table address low byte
;				  entries are ordered in ascending keycode order
;
;	dc.b char		  deadkey subtables start with extra byte - 8x8 char code for OZ window
;	dc.b n			  after that they follow standard table format of num + n*(in,out)
;	dc.b inchar, outchar,...
;
;
;*UDRL	cursor keys		ff fe fd fc
;*S	space			20
;^MTDE	enter tab del esc	e1 e2 e3 e4
;#MIH	menu index help 	e5 e6 e7
;!DSLRC <> [] ls rs cl		c8 b8 aa a9 a8
;
MODULE  Keymap_UK

ORG     $0000
xdef    Keymap_UK

.KeyMap_UK
        defb    $38,$37,$6E,$68,$79,$36,$E1,$E3     ; 8  7  n  h  y  6  ^M ^D
        defb    $69,$75,$62,$67,$74,$35,$FF,$5C     ; i  u  b  g  t  5  *U \
        defb    $6F,$6A,$76,$66,$72,$34,$FE,$3D     ; o  j  v  f  r  4  *D =
        defb    $39,$6B,$63,$64,$65,$33,$FD,$2D     ; 9  k  c  d  e  3  *R -
        defb    $70,$6D,$78,$73,$77,$32,$FC,$5D     ; p  m  x  s  w  2  *L ]
        defb    $30,$6C,$7A,$61,$71,$31,$20,$5B     ; 0  l  z  a  q  1  *S [
        defb    $27,$3B,$2C,$E5,$C8,$E2,$aa,$E7     ; '  ;  ,  #M !D ^T !L #H
        defb    $A3,$2F,$2E,$E8,$E6,$1B,$B8,$a9     ; �  /  .  !C #I ^E !S !R



.ShiftTable
	defb	(CapsTable - ShiftTable - 1)/2
        defb    $1b,$d4                                 ; ^E d4
        defb    $20,$d0                                 ; *S d0
        defb    $27,$22                                 ; '  "
        defb    $2c,$3c                                 ; ,  <
        defb    $2d,$5f                                 ; -  _
        defb    $2e,$3e                                 ; .  >
        defb    $2f,$3f                                 ; /  ?
        defb    $30,$29                                 ; 0  )
        defb    $31,$21                                 ; 1  !
        defb    $32,$40                                 ; 2 @
        defb    $33,$23                                 ; 3 #
        defb    $34,$24                                 ; 4 $
        defb    $35,$25                                 ; 5 %
        defb    $36,$5e                                 ; 6 ^
        defb    $37,$26                                 ; 7 &
        defb    $38,$2a                                 ; 8 *
        defb    $39,$28                                 ; 9 (
        defb    $3b,$3a                                 ; ;  :
        defb    $3d,$2b                                 ; =  +
        defb    $5b,$7b                                 ; [  {
        defb    $5c,$7c                                 ; \  |
        defb    $5d,$7d                                 ; ]  }
        defb    $a3,$7e                                 ; �  ~

.CapsTable
	defb	0

.DmndTable
	defb	(SqrTable - DmndTable - 1)/2
        defb    $1b,$c4                                 ; ^E    c4
        defb    $20,$a0                                 ; *S    a0
        defb    $27,$60                                 ; '     `
        defb    $2b,$00                                 ; +     00
        defb    $2c,$1b                                 ; ,     1b
        defb    $2d,$1f                                 ; -     1f
        defb    $2e,$1d                                 ; .     1d
        defb    $2f,$1c                                 ; /     1c
        defb    $3d,$00                                 ; =     00
        defb    $a3,$a4                                 ; �     �

.SqrTable	; 22 keys
	defb	(DeadTable - SqrTable - 1)/2
        defb    $1B,$B4
        defb    $20,$B0
        defb    $2B,$80                                 ; special []+ command
        defb    $2D,$9F                                 ; special []- command
        defb    $3D,$80                                 ; special []+ command
        defb    $5B,$1B
        defb    $5C,$1C
        defb    $5D,$1D
        defb    $A3,$1E

.DeadTable
        defb    0