
     MODULE Error_messages


     XREF Write_Msg

     ; Routines & strings globally available:
     XDEF Syntax_error
     XDEF Write_err_msg, Get_errmsg

     INCLUDE "defs.h"
     INCLUDE "error.def"
     INCLUDE "stdio.def"


; *******************************************************************
.Syntax_error       LD   A, RC_SNTX
                    CALL Write_Err_Msg
                    SCF
                    RET


; ******************************************************************************
.Write_err_msg      BIT  7,A                              ; Intuition error message?
                    CALL NZ, Get_errmsg
                    JP   NZ, Write_Msg
                    CP   A
                    CALL_OZ(Gn_Esp)                       ; get ext. pointer
                    CALL_OZ(Gn_Soe)                       ; write error msg. to std. output
                    CALL_OZ(Gn_Nln)                       ; terminate line with CRLF
                    RET


; ******************************************************************************
;
; Return pointer to error message from code in A                V0.26e
;
.Get_errmsg         PUSH AF
                    LD   D,0
                    LD   E,A
                    SLA  E                                ; word boundary
                    LD   HL, Errmsg_lookup
                    ADD  HL,DE                            ; HL points at index containing pointer
                    LD   E,(HL)
                    INC  HL
                    LD   D,(HL)                           ; pointer fetched in
                    EX   DE,HL                            ; HL
                    POP  AF
                    RET

.Errmsg_lookup      DEFW Error_msg_80
                    DEFW Error_msg_81
                    DEFW Error_msg_82
                    DEFW Error_msg_83
                    DEFW Error_msg_84

; Intuition specific errors
.Error_Msg_80       DEFM "unknown Z80 opcode",0
.Error_Msg_81       DEFM "unbalanced RET",0
.Error_Msg_82       DEFM "not found",0
.Error_Msg_83       DEFM "none",0
.Error_Msg_84       DEFM "KILL request",0
