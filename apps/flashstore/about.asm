; *************************************************************************************
; FlashStore
; (C) Gunther Strube (gbs@users.sourceforge.net) & Thierry Peycru (pek@free.fr), 1997-2005
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

Module AboutFlashStore

     LIB CreateWindow                   ; create an OZ window (with options banner, title, etc)

     XDEF AboutCommand, catalog_banner

     XREF greyscr, pwait                ; fsapp.asm

     include "stdio.def"
     include "fsapp.def"


; *************************************************************************************
;
.AboutCommand
                    CALL greyscr

                    ld   a, 128 | '3'
                    ld   bc, $0013
                    ld   de, $0849
                    ld   hl, flashstore_banner
                    call CreateWindow
                    ld   hl, copyrightmsg
                    CALL_OZ GN_Sop
                    call pwait
                    ret
; *************************************************************************************


; *************************************************************************************
;
.DispDispZlabLogo
                    LD   HL, zlab_logo
                    CALL_OZ(Gn_Sop)
                    RET
; *************************************************************************************


; *************************************************************************************
;
. DispInterLogicLogo
                    LD   HL, InterLogic_logo
                    CALL_OZ(Gn_Sop)
                    RET
; *************************************************************************************



; *************************************************************************************
;
; Text constants
;

.catalog_banner
.flashstore_banner
                    DEFM "FLASHSTORE V1.8 beta", 0

.copyrightmsg
                    DEFM 1, "2JC"
                    DEFM "Development: G.Strube (gbs@users.sf.net) & T.Peycru (pek@free.fr)", 13, 10
                    DEFM "User Interface & testing: V.Gerhardi (vic@rakewell.com)", 13, 10
                    DEFM "(C) Copyright T.Peycru, & G.Strube, 1997-2005. All rights reserved"
                    DEFM 1, "2JN"
                    DEFM 1,"3@",32+9,32+4, "This software is released as Open Source (GPL licence)."
                    DEFM 1,"3@",32+9,32+5, "Get latest news, updates for FlashStore and other Z88"
                    DEFM 1,"3@",32+9,32+6, "software at http://z88.sf.net or http://www.rakewell.com"
.InterLogic_logo
                    defb 1, 138, '=', 'L', @10000000, @10000000, @10000000, @10000000, @10000000, @10000000, @10000000, @10000000
                    defb 1, 138, '=', 'M', @10000000, @10000000, @10000000, @10010000, @10010001, @10000010, @10010000, @10010000
                    defb 1, 138, '=', 'N', @10000000, @10000000, @10000000, @10000000, @10000000, @10101011, @10010000, @10000000
                    defb 1, 138, '=', 'O', @10000000, @10000000, @10000000, @10100000, @10100001, @10111011, @10100001, @10100000
                    defb 1, 138, '=', 'P', @10000000, @10000000, @10000000, @10100010, @10000010, @10110011, @10000010, @10100010
                    defb 1, 138, '=', 'Q', @10000000, @10000000, @10000000, @10000000, @10000000, @10110000, @10000000, @10000000
                    defb 1, 138, '=', 'R', @10000000, @10000000, @10000111, @10000111, @10000111, @10000111, @10000011, @10000011
                    defb 1, 138, '=', 'S', @10000000, @10000000, @10111111, @10111111, @10101111, @10101110, @10101101, @10101110
                    defb 1, 138, '=', 'T', @10000000, @10000000, @10111111, @10111111, @10011111, @10101110, @10110101, @10101110
                    defb 1, 138, '=', 'U', @10000000, @10000000, @10111111, @10111111, @10011110, @10111110, @10110111, @10101110
                    defb 1, 138, '=', 'V', @10000000, @10000000, @10111111, @10111111, @10111110, @10111101, @10111011, @10111101
                    defb 1, 138, '=', 'W', @10000000, @10000000, @10111100, @10111100, @10111100, @10111100, @10111000, @10111000
                    defb 1, 138, '=', 'X', @10000001, @10000000, @10000000, @10000000, @10000000, @10000000, @10000000, @10000000
                    defb 1, 138, '=', 'Y', @10101111, @10111111, @10011111, @10000111, @10000001, @10000000, @10000000, @10000000
                    defb 1, 138, '=', 'Z', @10011111, @10111111, @10111111, @10111111, @10111111, @10001111, @10000000, @10000000
                    defb 1, 138, '=', 'a', @10011110, @10111111, @10111111, @10111111, @10111111, @10111111, @10000000, @10000000
                    defb 1, 138, '=', 'b', @10111110, @10111111, @10111111, @10111100, @10110000, @10000000, @10000000, @10000000
                    defb 1, 138, '=', 'c', @10110000, @10100000, @10000000, @10000000, @10000000, @10000000, @10000000, @10000000

                    defm 1,"3@",32+1,32+4, 1,"2?","L",1,"2?","M",1,"2?","N",1,"2?","O",1,"2?","P",1,"2?","Q"
                    defm 1,"3@",32+1,32+5, 1,"2?","R",1,"2?","S",1,"2?","T",1,"2?","U",1,"2?","V",1,"2?","W"
                    defm 1,"3@",32+1,32+6, 1,"2?","X",1,"2?","Y",1,"2?","Z",1,"2?","a",1,"2?","b",1,"2?","c"
.zlab_logo
                    defm 1,138,"=",64,63,32,39,39,39,38,36,32
                    defm 1,138,"=",65,63,128,63,63,48,128,128,3
                    defm 1,138,"=",66,63,128,63,63,3,15,60,48
                    defm 1,138,"=",67,63,1,57,57,49,1,1,1
                    defm 1,138,"=",68,32,32,35,39,39,32,38,38
                    defm 1,138,"=",69,15,60,48,63,63,128,3,6
                    defm 1,138,"=",70,128,128,3,63,63,128,35,22
                    defm 1,138,"=",71,9,25,57,57,57,1,33,17
                    defm 1,138,"=",72,38,38,38,38,38,39,32,63
                    defm 1,138,"=",73,6,7,6,6,6,54,128,63
                    defm 1,138,"=",74,22,55,22,22,22,23,128,63
                    defm 1,138,"=",75,17,33,17,9,9,49,1,63

                    defm 1,"3@",32+68,32+4,1,"2?","@",1,"2?","A",1,"2?","B",1,"2?","C"
                    defm 1,"3@",32+68,32+5,1,"2?","D",1,"2?","E",1,"2?","F",1,"2?","G"
                    defm 1,"3@",32+68,32+6,1,"2?","H",1,"2?","I",1,"2?","J",1,"2?","K"
                    defb 0
