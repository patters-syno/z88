
     MODULE Parse_commandline

     XDEF SkipSpaces, GetChar, UpperCase


     INCLUDE "defs.h"


; **********************************************************************************
;
; Skip spaces in input buffer, and point at first non-space character
; Entry; HL points at position to start skipping spaces...
; On return HL will point at first non-space character.
; If EOL occurs, Fc = 1, otherwise Fc = 0.
;
; Register status after return:
;
;       A.BCDE../IXIY  same
;       .F....HL/....  different
;
.SkipSpaces       PUSH BC
                  LD   B,A
.SpacesLoop       LD   A,(HL)
                  OR   A                    ; EOL ?
                  JR   Z, EOL_reached
                  CP   32
                  JR   NZ, Exit_SkipSpaces  ; x <> spaces!
                  INC  HL
                  JR   SpacesLoop
.EOL_reached      SCF                       ; Ups, EOL!
                  JR   Restore_A
.Exit_SkipSpaces  XOR  A                    ; Fc = 0
.Restore_A        LD   A,B
                  POP  BC
                  RET


; **********************************************************************************
;
; GetChar routine
; - Return a char, in A, from input buffer by the current pointer, HL
;   If EOL reached, return Fc = 1, otherwise Fc = 0
;
; Status of registers on return:
;
;       ..BCDE../IXIY  same
;       AF....HL/....  different
;
.GetChar          LD   A,(HL)               ; get char at current buffer pointer
                  INC  HL                   ; get ready for next char
                  OR   A                    ; EOL ?
                  RET  NZ                   ; No, null-terminator not yet reached
.no_char_read     SCF
                  RET


; ***********************************************************************************
;
; Convert Character to upper Case
; Character to be converted, in A, and returned in A
;
; Register status after return:
;
;       .FBCDEHL/IXIY  same
;       A......./....  different
;
.UpperCase        PUSH BC                   ; save Flag register
                  PUSH AF
                  CP   'a'
                  JR   NC, test_lwcase      ; x  > "a", x > "z" ?
                  JR   return_char          ; x  < "a", ignore
.test_lwcase      CP   123
                  JR   NC, return_char      ; x > "z", ignore...
                  SUB  32                   ; convert to upper case...
.return_char      LD   B,A
                  POP  AF
                  LD   A,B
                  POP  BC
                  RET
