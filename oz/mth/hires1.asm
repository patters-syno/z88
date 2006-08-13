; **************************************************************************************************
; The 8 bit width bitmap font (HIRES1).
;
; The original table was extracted out of Font bitmap from original V4.0 ROM using FontBitMap tool.
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
; Additional development improvements, comments, definitions and new implementations by
; (C) Thierry Peycru (pek@users.sf.net), 2005-2006
; (C) Gunther Strube (gbs@users.sf.net), 2005-2006
;
; $Id$
; ***************************************************************************************************

Module Hires1

org $0800                                       ; really starts at $0C00, declared $0800 because first 128 hires doesnt exist

; --------------------------------------------------------------------------------------------------
; IMPORTANT NOTE:
; --------------------------------------------------------------------------------------------------
; Up to 1024 hires characters can be displayed by the blink
; 768 ($300) from the hires0 bitmap font defined in RAM (granularity 8K)
; 256 ($100) from the hires1 bitmap font defined in ROM (granularity 2K)
; only 96 are used in hires1, beginning at 128 ($80), ending at 224($DF)
; that is why hires1 offset is defined 1K before ($80*8)
;
; chars $98-$9D are free (they were used for some lores1 chars mixed in original OZ ROM)
;
; --------------------------------------------------------------------------------------------------

defs    $400

; $80
;   #####
;  #######
;  ##   ##
;  ##   ##
;  ##   ##
;  #######
;   #####
;
defb @00111110
defb @01111111
defb @01100011
defb @01100011
defb @01100011
defb @01111111
defb @00111110
defb @00000000

; $81
;  #######
;  #######
;     ###
;    ###
;   ###
;  #######
;  #######
;
defb @01111111
defb @01111111
defb @00001110
defb @00011100
defb @00111000
defb @01111111
defb @01111111
defb @00000000

; $82
;  #   ###
;  #   # #
;  ### ###
;
;    ### #
;    # # #
;    ### #
;
defb @01000111
defb @01000101
defb @01110111
defb @00000000
defb @00011101
defb @00010101
defb @00011101
defb @00000000

; $83
;  ### # #
;  #   ##
;  ### # #
;
;  # ###
;  #  #
; ##  #
;
defb @01110101
defb @01000110
defb @01110101
defb @00000000
defb @01011100
defb @01001000
defb @11001000
defb @00000000

; $84
;
;   ## ###
;  #   # #
;  #   ###
;  #   # #
;   ## # #
;
;
defb @00000000
defb @00110111
defb @01000101
defb @01000111
defb @01000101
defb @00110101
defb @00000000
defb @00000000

; $85
;
;  ### ###
;  # # #
;  ### ###
;  #     #
;  #   ###
;
;
defb @00000000
defb @01110111
defb @01010100
defb @01110111
defb @01000001
defb @01000111
defb @00000000
defb @00000000

; $86
;
;   ##  ##
;  #   # #
;  #   # #
;  #   # #
;   ##  ##
;
;
defb @00000000
defb @00110011
defb @01000101
defb @01000101
defb @01000101
defb @00110011
defb @00000000
defb @00000000

; $87
;
;  ##   ##
;  # # #
;  # # ###
;  # #   #
;  ##  ##
;  #
;  #
defb @00000000
defb @01100011
defb @01010100
defb @01010111
defb @01010001
defb @01100110
defb @01000000
defb @01000000

; $88
; ########                                      ;
; ###   #                                       ;    ### #
; ## ####                                       ;   #    #
; ## ####                                       ;   #    #
; ## ####                                       ;   #    #
; ## ####                                       ;   #    #
; ###   #                                       ;    ### #
; ########                                      ;
defb @01111111                                  ;defb @00000000
defb @01100010                                  ;defb @00011101
defb @01011110                                  ;defb @00100001
defb @01011110                                  ;defb @00100001
defb @01011110                                  ;defb @00100001
defb @01011110                                  ;defb @00100001
defb @01100010                                  ;defb @00011101
defb @01111111                                  ;defb @00000000

; $89
; ########                                      ;
; ####   #                                      ;     ###
; ##### ##                                      ;      #
; ##### ##                                      ;      #
; ##### ##                                      ;      #
; ##### ##                                      ;      #
;    #   #                                      ; ### ###
; ########                                      ;
defb @11111111                                  ;defb @00000000
defb @11110001                                  ;defb @00001110
defb @11111011                                  ;defb @00000100
defb @11111011                                  ;defb @00000100
defb @11111011                                  ;defb @00000100
defb @11111011                                  ;defb @00000100
defb @00010001                                  ;defb @11101110
defb @11111111                                  ;defb @00000000

; $8A
;  #######
;  #   ##
;  # ### #
;  #   #
;  # ### #
;  # ### #
;  #######
;
defb @01111111
defb @01000110
defb @01011101
defb @01000100
defb @01011101
defb @01011101
defb @01111111
defb @00000000

; $8B
; ########
; ## # ###
;  # # ###
;  # # ###
;  # # ###
;  # #   #
; ########
;
defb @11111111
defb @11010111
defb @01010111
defb @01010111
defb @01010111
defb @01010001
defb @11111111
defb @00000000

; $8C
; ########
; #  ### #
; # # # #
; #  ##
; # # # #
; #  ## #
; ########
;
defb @11111111
defb @10011101
defb @10101010
defb @10011000
defb @10101010
defb @10011010
defb @11111111
defb @00000000

; $8D
; ######
; #   ##
; ## #####
; ## #####
; ## #####
; ## ###
; ######
;
defb @11111100
defb @10001100
defb @11011111
defb @11011111
defb @11011111
defb @11011100
defb @11111100
defb @00000000

; $8E
; ########
; # ##   #
; # ## # #
; # ## # #
; # ## # #
; #  #   #
; ########
;
defb @11111111
defb @10110001
defb @10110101
defb @10110101
defb @10110101
defb @10010001
defb @11111111
defb @00000000

; $8F
; ######
;  ### #
;  ### ###
;  # # ###
;  # # ###
; # # ##
; ######
;
defb @11111100
defb @01110100
defb @01110111
defb @01010111
defb @01010111
defb @10101100
defb @11111100
defb @00000000

; $90
;
;     #
;    ###
;   ## ##
;  ##   ##
;   ## ##
;    ###
;     #
defb @00000000
defb @00001000
defb @00011100
defb @00110110
defb @01100011
defb @00110110
defb @00011100
defb @00001000

; $91
;
;  #######
;  #######
;  ##   ##
;  ##   ##
;  ##   ##
;  #######
;  #######
defb @00000000
defb @01111111
defb @01111111
defb @01100011
defb @01100011
defb @01100011
defb @01111111
defb @01111111


; $92
; #      #
;  #    ##
;   #   ##
;       ##
;      ###
;   # ####
;  #  ####
; #      #
defb @10000001
defb @01000011
defb @00100011
defb @00000011
defb @00000111
defb @00101111
defb @01001111
defb @10000001

; $93
; #      #
; ##    #
; ##   #
; ##
; ###
; #### #
; ####  #
; #      #
defb @10000001
defb @11000010
defb @11000100
defb @11000000
defb @11100000
defb @11110100
defb @11110010
defb @10000001

; $94
;
;  ##  #
; #   # #
; #   ###
; #   # #
;  ## # #
;
; ########
defb @00000000
defb @01100100
defb @10001010
defb @10001110
defb @10001010
defb @01101010
defb @00000000
defb @11111111

; $95
;
; ##  ##
; # # # #
; ##  # #
; # # # #
; # # ##
;
; #######
defb @00000000
defb @11001100
defb @10101010
defb @11001010
defb @10101010
defb @10101100
defb @00000000
defb @11111110

; $96
;
; # ##  ##
; # # # #
; # # # #
; # # # #
; # # # ##
;
; ########
defb @00000000
defb @10110011
defb @10101010
defb @10101010
defb @10101010
defb @10101011
defb @00000000
defb @11111111

; $97
;
;   ## # #
; # #  # #
; # ##  #
; # #  # #
;   ## # #
;
; ########
defb @00000000
defb @00110101
defb @10100101
defb @10110010
defb @10100101
defb @00110101
defb @00000000
defb @11111111

; $98
;
;
;
;
;
;
;
;
defb @00000000
defb @00000000
defb @00000000
defb @00000000
defb @00000000
defb @00000000
defb @00000000
defb @00000000

; $99
;
;
;
;
;
;
;
;
defb @00000000
defb @00000000
defb @00000000
defb @00000000
defb @00000000
defb @00000000
defb @00000000
defb @00000000

; $9A
;
;
;
;
;
;
;
;
defb @00000000
defb @00000000
defb @00000000
defb @00000000
defb @00000000
defb @00000000
defb @00000000
defb @00000000

; $9B
;
;
;
;
;
;
;
;
defb @00000000
defb @00000000
defb @00000000
defb @00000000
defb @00000000
defb @00000000
defb @00000000
defb @00000000

; $9C
;
;
;
;
;
;
;
;
defb @00000000
defb @00000000
defb @00000000
defb @00000000
defb @00000000
defb @00000000
defb @00000000
defb @00000000

; $9D
;
;
;
;
;
;
;
;
defb @00000000
defb @00000000
defb @00000000
defb @00000000
defb @00000000
defb @00000000
defb @00000000
defb @00000000

; $9E
;
;  ##  ##
;  ##  ##
;
;
;
;
;
defb @00000000
defb @01100110
defb @01100110
defb @00000000
defb @00000000
defb @00000000
defb @00000000
defb @00000000

; $9F
;
;    ###
;   ## ##
;   ##
;  #####
;   ##
;  ######
;
defb @00000000
defb @00011100
defb @00110110
defb @00110000
defb @01111100
defb @00110000
defb @01111110
defb @00000000

; $A0
;
;
;
;
;
;
;
;
defb @00000000
defb @00000000
defb @00000000
defb @00000000
defb @00000000
defb @00000000
defb @00000000
defb @00000000

; $A1
;
;    ##
;    ##
;    ##
;    ##
;
;    ##
;
defb @00000000
defb @00011000
defb @00011000
defb @00011000
defb @00011000
defb @00000000
defb @00011000
defb @00000000

; $A2
;
;  ##  ##
;  ##  ##
;
;
;
;
;
defb @00000000
defb @01100110
defb @01100110
defb @00000000
defb @00000000
defb @00000000
defb @00000000
defb @00000000

; $A3
;
;   ## ##
;  #######
;   ## ##
;  #######
;   ## ##
;   ## ##
;
defb @00000000
defb @00110110
defb @01111111
defb @00110110
defb @01111111
defb @00110110
defb @00110110
defb @00000000

; $A4
;
;   #####
;  ## # ##
;   ###
;     ###
;  ## # ##
;   #####
;
defb @00000000
defb @00111110
defb @01101011
defb @00111000
defb @00001110
defb @01101011
defb @00111110
defb @00000000

; $A5
;
;  ##   #
;  ##  #
;     #
;    #
;   #  ##
;  #   ##
;
defb @00000000
defb @01100010
defb @01100100
defb @00001000
defb @00010000
defb @00100110
defb @01000110
defb @00000000

; $A6
;
;   ####
;  ##  ##
;   ####
;  ##  # #
;  ##  ##
;   #### #
;
defb @00000000
defb @00111100
defb @01100110
defb @00111100
defb @01100101
defb @01100110
defb @00111101
defb @00000000

; $A7
;
;      ##
;     ##
;    ##
;
;
;
;
defb @00000000
defb @00000110
defb @00001100
defb @00011000
defb @00000000
defb @00000000
defb @00000000
defb @00000000

; $A8
;
;     ##
;    ##
;    ##
;    ##
;    ##
;     ##
;
defb @00000000
defb @00001100
defb @00011000
defb @00011000
defb @00011000
defb @00011000
defb @00001100
defb @00000000

; $A9
;
;   ##
;    ##
;    ##
;    ##
;    ##
;   ##
;
defb @00000000
defb @00110000
defb @00011000
defb @00011000
defb @00011000
defb @00011000
defb @00110000
defb @00000000

; $AA
;
;    ##
;  ######
;   ####
;  ######
;    ##
;
;
defb @00000000
defb @00011000
defb @01111110
defb @00111100
defb @01111110
defb @00011000
defb @00000000
defb @00000000

; $AB
;
;    ##
;    ##
;  ######
;    ##
;    ##
;
;
defb @00000000
defb @00011000
defb @00011000
defb @01111110
defb @00011000
defb @00011000
defb @00000000
defb @00000000

; $AC
;
;
;
;
;
;    ##
;   ##
;
defb @00000000
defb @00000000
defb @00000000
defb @00000000
defb @00000000
defb @00011000
defb @00110000
defb @00000000

; $AD
;
;
;
;  ######
;
;
;
;
defb @00000000
defb @00000000
defb @00000000
defb @01111110
defb @00000000
defb @00000000
defb @00000000
defb @00000000

; $AE
;
;
;
;
;
;    ##
;    ##
;
defb @00000000
defb @00000000
defb @00000000
defb @00000000
defb @00000000
defb @00011000
defb @00011000
defb @00000000

; $AF
;
;      ##
;     ##
;    ##
;   ##
;  ##
;
;
defb @00000000
defb @00000110
defb @00001100
defb @00011000
defb @00110000
defb @01100000
defb @00000000
defb @00000000

; $B0
;
;   #####
;  ##   ##
;  ## ####
;  #### ##
;  ##   ##
;   #####
;
defb @00000000
defb @00111110
defb @01100011
defb @01101111
defb @01111011
defb @01100011
defb @00111110
defb @00000000

; $B1
;
;    ##
;   ###
;    ##
;    ##
;    ##
;    ##
;
defb @00000000
defb @00011000
defb @00111000
defb @00011000
defb @00011000
defb @00011000
defb @00011000
defb @00000000

; $B2
;
;   ####
;  ##  ##
;     ##
;    ##
;   ##
;  ######
;
defb @00000000
defb @00111100
defb @01100110
defb @00001100
defb @00011000
defb @00110000
defb @01111110
defb @00000000

; $B3
;
;  ######
;      ##
;    ###
;      ##
;  ##  ##
;   ####
;
defb @00000000
defb @01111110
defb @00000110
defb @00011100
defb @00000110
defb @01100110
defb @00111100
defb @00000000

; $B4
;
;     ##
;    ###
;   # ##
;  #  ##
;  ######
;     ##
;
defb @00000000
defb @00001100
defb @00011100
defb @00101100
defb @01001100
defb @01111110
defb @00001100
defb @00000000

; $B5
;
;  ######
;  ##
;  #####
;      ##
;      ##
;  #####
;
defb @00000000
defb @01111110
defb @01100000
defb @01111100
defb @00000110
defb @00000110
defb @01111100
defb @00000000

; $B6
;
;   ####
;  ##
;  #####
;  ##  ##
;  ##  ##
;   ####
;
defb @00000000
defb @00111100
defb @01100000
defb @01111100
defb @01100110
defb @01100110
defb @00111100
defb @00000000

; $B7
;
;  ######
;      ##
;     ##
;    ##
;   ##
;  ##
;
defb @00000000
defb @01111110
defb @00000110
defb @00001100
defb @00011000
defb @00110000
defb @01100000
defb @00000000

; $B8
;
;   ####
;  ##  ##
;   ####
;  ##  ##
;  ##  ##
;   ####
;
defb @00000000
defb @00111100
defb @01100110
defb @00111100
defb @01100110
defb @01100110
defb @00111100
defb @00000000

; $B9
;
;   ####
;  ##  ##
;   #####
;      ##
;      ##
;   ####
;
defb @00000000
defb @00111100
defb @01100110
defb @00111110
defb @00000110
defb @00000110
defb @00111100
defb @00000000

; $BA
;
;
;    ##
;    ##
;
;    ##
;    ##
;
defb @00000000
defb @00000000
defb @00011000
defb @00011000
defb @00000000
defb @00011000
defb @00011000
defb @00000000

; $BB
;
;
;    ##
;    ##
;
;    ##
;   ##
;
defb @00000000
defb @00000000
defb @00011000
defb @00011000
defb @00000000
defb @00011000
defb @00110000
defb @00000000

; $BC
;
;     ##
;    ##
;   ##
;    ##
;     ##
;
;
defb @00000000
defb @00001100
defb @00011000
defb @00110000
defb @00011000
defb @00001100
defb @00000000
defb @00000000

; $BD
;
;
;   ####
;
;   ####
;
;
;
defb @00000000
defb @00000000
defb @00111100
defb @00000000
defb @00111100
defb @00000000
defb @00000000
defb @00000000

; $BE
;
;   ##
;    ##
;     ##
;    ##
;   ##
;
;
defb @00000000
defb @00110000
defb @00011000
defb @00001100
defb @00011000
defb @00110000
defb @00000000
defb @00000000

; $BF
;
;   ####
;  ##  ##
;     ##
;    ##
;
;    ##
;
defb @00000000
defb @00111100
defb @01100110
defb @00001100
defb @00011000
defb @00000000
defb @00011000
defb @00000000

; $C0
;
;   ######
;  ##   ##
;  ## ####
;  ## ###
;  ##
;   #####
;
defb @00000000
defb @00111111
defb @01100011
defb @01101111
defb @01101110
defb @01100000
defb @00111110
defb @00000000

; $C1
;
;   ####
;  ##  ##
;  ##  ##
;  ######
;  ##  ##
;  ##  ##
;
defb @00000000
defb @00111100
defb @01100110
defb @01100110
defb @01111110
defb @01100110
defb @01100110
defb @00000000

; $C2
;
;  #####
;  ##  ##
;  #####
;  ##  ##
;  ##  ##
;  #####
;
defb @00000000
defb @01111100
defb @01100110
defb @01111100
defb @01100110
defb @01100110
defb @01111100
defb @00000000

; $C3
;
;   ####
;  ##  ##
;  ##
;  ##
;  ##  ##
;   ####
;
defb @00000000
defb @00111100
defb @01100110
defb @01100000
defb @01100000
defb @01100110
defb @00111100
defb @00000000

; $C4
;
;  #####
;  ##  ##
;  ##  ##
;  ##  ##
;  ##  ##
;  #####
;
defb @00000000
defb @01111100
defb @01100110
defb @01100110
defb @01100110
defb @01100110
defb @01111100
defb @00000000

; $C5
;
;  ######
;  ##
;  #####
;  ##
;  ##
;  ######
;
defb @00000000
defb @01111110
defb @01100000
defb @01111100
defb @01100000
defb @01100000
defb @01111110
defb @00000000

; $C6
;
;  ######
;  ##
;  #####
;  ##
;  ##
;  ##
;
defb @00000000
defb @01111110
defb @01100000
defb @01111100
defb @01100000
defb @01100000
defb @01100000
defb @00000000

; $C7
;
;   ####
;  ##  ##
;  ##
;  ## ###
;  ##   #
;   ####
;
defb @00000000
defb @00111100
defb @01100110
defb @01100000
defb @01101110
defb @01100010
defb @00111100
defb @00000000

; $C8
;
;  ##  ##
;  ##  ##
;  ######
;  ##  ##
;  ##  ##
;  ##  ##
;
defb @00000000
defb @01100110
defb @01100110
defb @01111110
defb @01100110
defb @01100110
defb @01100110
defb @00000000

; $C9
;
;   ####
;    ##
;    ##
;    ##
;    ##
;   ####
;
defb @00000000
defb @00111100
defb @00011000
defb @00011000
defb @00011000
defb @00011000
defb @00111100
defb @00000000

; $CA
;
;   #####
;     ##
;     ##
;     ##
;  ## ##
;   ###
;
defb @00000000
defb @00111110
defb @00001100
defb @00001100
defb @00001100
defb @01101100
defb @00111000
defb @00000000

; $CB
;
;  ##  ##
;  ## ##
;  ####
;  ####
;  ## ##
;  ##  ##
;
defb @00000000
defb @01100110
defb @01101100
defb @01111000
defb @01111000
defb @01101100
defb @01100110
defb @00000000

; $CC
;
;  ##
;  ##
;  ##
;  ##
;  ##
;  ######
;
defb @00000000
defb @01100000
defb @01100000
defb @01100000
defb @01100000
defb @01100000
defb @01111110
defb @00000000

; $CD
;
;  ##   ##
;  ### ###
;  ## # ##
;  ## # ##
;  ##   ##
;  ##   ##
;
defb @00000000
defb @01100011
defb @01110111
defb @01101011
defb @01101011
defb @01100011
defb @01100011
defb @00000000

; $CE
;
;  ##  ##
;  ##  ##
;  ### ##
;  ## ###
;  ##  ##
;  ##  ##
;
defb @00000000
defb @01100110
defb @01100110
defb @01110110
defb @01101110
defb @01100110
defb @01100110
defb @00000000

; $CF
;
;   ####
;  ##  ##
;  ##  ##
;  ##  ##
;  ##  ##
;   ####
;
defb @00000000
defb @00111100
defb @01100110
defb @01100110
defb @01100110
defb @01100110
defb @00111100
defb @00000000

; $D0
;
;  #####
;  ##  ##
;  #####
;  ##
;  ##
;  ##
;
defb @00000000
defb @01111100
defb @01100110
defb @01111100
defb @01100000
defb @01100000
defb @01100000
defb @00000000

; $D1
;
;   #####
;  ##   ##
;  ##   ##
;  ## # ##
;  ##  #
;   ### ##
;
defb @00000000
defb @00111110
defb @01100011
defb @01100011
defb @01101011
defb @01100100
defb @00111011
defb @00000000

; $D2
;
;  #####
;  ##  ##
;  #####
;  ####
;  ## ##
;  ##  ##
;
defb @00000000
defb @01111100
defb @01100110
defb @01111100
defb @01111000
defb @01101100
defb @01100110
defb @00000000

; $D3
;
;   #####
;  ##   ##
;   ###
;     ###
;  ##   ##
;   #####
;
defb @00000000
defb @00111110
defb @01100011
defb @00111000
defb @00001110
defb @01100011
defb @00111110
defb @00000000

; $D4
;
;  ######
;    ##
;    ##
;    ##
;    ##
;    ##
;
defb @00000000
defb @01111110
defb @00011000
defb @00011000
defb @00011000
defb @00011000
defb @00011000
defb @00000000

; $D5
;
;  ##  ##
;  ##  ##
;  ##  ##
;  ##  ##
;  ##  ##
;   ####
;
defb @00000000
defb @01100110
defb @01100110
defb @01100110
defb @01100110
defb @01100110
defb @00111100
defb @00000000

; $D6
;
;  ##  ##
;  ##  ##
;  ##  ##
;  ##  ##
;   #  #
;    ##
;
defb @00000000
defb @01100110
defb @01100110
defb @01100110
defb @01100110
defb @00100100
defb @00011000
defb @00000000

; $D7
;
;  ##   ##
;  ##   ##
;  ## # ##
;  ## # ##
;  ### ###
;  ##   ##
;
defb @00000000
defb @01100011
defb @01100011
defb @01101011
defb @01101011
defb @01110111
defb @01100011
defb @00000000

; $D8
;
;  ##   ##
;   ## ##
;    ###
;    ###
;   ## ##
;  ##   ##
;
defb @00000000
defb @01100011
defb @00110110
defb @00011100
defb @00011100
defb @00110110
defb @01100011
defb @00000000

; $D9
;
;  ##  ##
;  ##  ##
;   ####
;    ##
;    ##
;    ##
;
defb @00000000
defb @01100110
defb @01100110
defb @00111100
defb @00011000
defb @00011000
defb @00011000
defb @00000000

; $DA
;
;  ######
;      ##
;     ##
;    ##
;   ##
;  ######
;
defb @00000000
defb @01111110
defb @00000110
defb @00001100
defb @00011000
defb @00110000
defb @01111110
defb @00000000

; $DB
;
;   ####
;   ##
;   ##
;   ##
;   ##
;   ####
;
defb @00000000
defb @00111100
defb @00110000
defb @00110000
defb @00110000
defb @00110000
defb @00111100
defb @00000000

; $DC
;
;  ##
;   ##
;    ##
;     ##
;      ##
;
;
defb @00000000
defb @01100000
defb @00110000
defb @00011000
defb @00001100
defb @00000110
defb @00000000
defb @00000000

; $DD
;
;   ####
;     ##
;     ##
;     ##
;     ##
;   ####
;
defb @00000000
defb @00111100
defb @00001100
defb @00001100
defb @00001100
defb @00001100
defb @00111100
defb @00000000

; $DE
;
;   ####
;  ##  ##
;
;
;
;
;
defb @00000000
defb @00111100
defb @01100110
defb @00000000
defb @00000000
defb @00000000
defb @00000000
defb @00000000

; $DF
;
;
;
;
;
;  ######
;  ######
;
defb @00000000
defb @00000000
defb @00000000
defb @00000000
defb @00000000
defb @01111110
defb @01111110
defb @00000000
