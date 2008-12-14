; **************************************************************************************************
; This file is part of Intuition.
;
; Intuition is free software; you can redistribute it and/or modify it under the terms of the
; GNU General Public License as published by the Free Software Foundation; either version 2, or
; (at your option) any later version.
; Intuition is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY;
; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
; See the GNU General Public License for more details.
; You should have received a copy of the GNU General Public License along with Intuition;
; see the file COPYING. If not, write to the
; Free Software Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA 02111-1307, USA.
;
; $Id$
;
;***************************************************************************************************

     MODULE ExtRoutine_uppersegment0

     LIB ExtCall

     INCLUDE "oz.def"

     XDEF ExtRoutine_s01


; ******************************************************************************
;
;
.ExtRoutine_s01   PUSH IX
                  EXX
                  LD   B, OZBANK_INTUITION | 1      ; bind in upper 8K of Intuition bank (DON'T RELY on soft copy!)
                  LD   C,0
                  POP  HL
                  EXX
                  CALL ExtCall              ; then dump contents of Z80 registers
                  RET

