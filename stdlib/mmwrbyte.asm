     XLIB MemWriteByte

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
; $Id$  
;
;***************************************************************************************************

     LIB MemDefBank


; ******************************************************************************
;
; Set byte in C, at pointer in BHL,A.
;
;    Register affected on return:
;         AFBCDEHL/IXIY same
;         ......../.... different
;
; ----------------------------------------------------------------------
; Design & programming by Gunther Strube, InterLogic, 1995-97
; ----------------------------------------------------------------------
;
.MemWriteByte       PUSH HL
                    PUSH DE
                    PUSH AF
                    PUSH BC

                    LD   E,A
                    XOR  A
                    LD   D,A
                    ADD  HL,DE                    ; add offset to pointer

                    LD   A,H
                    RLCA
                    RLCA
                    AND  3                        ; top address bits of pointer identify
                    LD   C,A                      ; B = Bank, C = MS_Sx Segment Specifier

                    CALL MemDefBank               ; page in bank temporarily
                    POP  DE
                    LD   (HL),E                   ; write byte at extended address
                    CALL MemDefBank               ; restore prev. binding

                    LD   B,D
                    LD   C,E                      ; BC restored...
                    POP  AF
                    POP  DE
                    POP  HL
                    RET
