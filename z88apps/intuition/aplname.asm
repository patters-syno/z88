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

     MODULE Name_application

     XREF Write_Msg
     XREF SkipSpaces, Syntax_error
     XDEF Name_application, nofile_msg

     INCLUDE "director.def"

; ******************************************************************************
;
; Define a name for the 'Z80debug' application
;
.Name_application   CALL SkipSpaces
                    JP   C, Syntax_error          ; name must be defined
                    CALL_OZ(Dc_Nam)               ; define application name
                    RET