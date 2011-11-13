     XLIB Set_long

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

     LIB Bind_bank_s1


; ******************************************************************************
;
;    Set long integer (in debc) at pointer in BHL,A.
;
;    Register affected on return:
;         ..BCDEHL/IXIY ..bcde..   same
;         AF....../.... af....hl   different
;
; ----------------------------------------------------------------------
; Design & programming by Gunther Strube, Copyright (C) InterLogic 1995
; ----------------------------------------------------------------------
;
.Set_long           PUSH HL
                    PUSH DE
                    LD   D,0
                    LD   E,A
                    ADD  HL,DE                    ; set pointer at offset
                    LD   A,B
                    CALL Bind_bank_s1             ; page in bank temporarily
                    PUSH HL
                    EXX
                    POP  HL
                    LD   (HL),C
                    INC  HL
                    LD   (HL),B
                    INC  HL
                    LD   (HL),E
                    INC  HL
                    LD   (HL),D
                    EXX
                    CALL Bind_bank_s1             ; restore prev. binding
                    POP  DE
                    POP  HL
                    RET
