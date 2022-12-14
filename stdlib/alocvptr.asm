     XLIB AllocVarPointer

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

     LIB malloc
     LIB Set_pointer

     DEFC SIZEOF_pointer = 3                           ; offset, bank


; ****************************************************************************************
;
; Create (allocate room) a pointer variable.
; The contents of the pointer variable is automatically reset to NULL (offset=0,bank=0).
;
;    IN: HL = local address to store pointer variable
;
;    OUT: BHL = pointer to allocated pointer variable
;
;    Registers changed after return:
;         ...CDE../IXIY same
;         AFB...HL/.... different
;
; ----------------------------------------------------------------------
; Design & programming by Gunther Strube, Copyright (C) InterLogic 1995
; ----------------------------------------------------------------------
;
.AllocVarPointer    PUSH IX
                    PUSH DE                   
                    PUSH BC
                    PUSH HL
                    POP  IX                            ; IX points at variable
                    LD   A, SIZEOF_pointer             ; allocate room for 'modulehdr' variable
                    CALL malloc                      
                    JR   C, exit_allocptr              ; Ups - no room...
                    LD   (IX+0),L
                    LD   (IX+1),H
                    LD   (IX+2),B                      ; ptr. to variable stored
                    XOR  A
                    LD   C,A                         
                    LD   D,A
                    LD   E,A
                    CALL Set_pointer                   ; *pointer = NULL
.exit_allocptr      LD   D,B
                    POP  BC
                    LD   B,D
                    POP  DE
                    POP  IX
                    RET
