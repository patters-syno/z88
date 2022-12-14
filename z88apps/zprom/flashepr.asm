;          ZZZZZZZZZZZZZZZZZZZZ
;        ZZZZZZZZZZZZZZZZZZZZ
;                     ZZZZZ
;                   ZZZZZ
;                 ZZZZZ           PPPPPPPPPPPPPP     RRRRRRRRRRRRRR       OOOOOOOOOOO     MMMM       MMMM
;               ZZZZZ             PPPPPPPPPPPPPPPP   RRRRRRRRRRRRRRRR   OOOOOOOOOOOOOOO   MMMMMM   MMMMMM
;             ZZZZZ               PPPP        PPPP   RRRR        RRRR   OOOO       OOOO   MMMMMMMMMMMMMMM
;           ZZZZZ                 PPPPPPPPPPPPPP     RRRRRRRRRRRRRR     OOOO       OOOO   MMMM MMMMM MMMM
;         ZZZZZZZZZZZZZZZZZZZZZ   PPPP               RRRR      RRRR     OOOOOOOOOOOOOOO   MMMM       MMMM
;       ZZZZZZZZZZZZZZZZZZZZZ     PPPP               RRRR        RRRR     OOOOOOOOOOO     MMMM       MMMM


; **************************************************************************************************
; This file is part of Zprom.
;
; Zprom is free software; you can redistribute it and/or modify it under
; the terms of the GNU General Public License as published by the Free Software Foundation;
; either version 2, or (at your option) any later version.
; Zprom is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY;
; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
; See the GNU General Public License for more details.
; You should have received a copy of the GNU General Public License along with the Zprom;
; see the file COPYING. If not, write to the
; Free Software Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA 02111-1307, USA.
;
;
;***************************************************************************************************


     MODULE FlashEprom

     LIB GreyApplWindow
     LIB FlashEprWriteBlock, MemDefBank
     LIB FlashEprBlockErase, FlashEprCardErase, FlashEprCardId
     LIB CreateWindow

     XREF fprg_prompt, fprg_banner
     XREF fble_prompt, fble_banner
     XREF FlEprInfo_banner
     XREF FlEprFormat_banner, FlEprFormat0_banner, FlEprFormat_prompt, FleprFmt0_prompt
     XREF EprErase_prompt
     XREF YesNoWindow, DispErrWindow, ReportWindow, Disp_EprAddrError
     XREF Check_Eprom, Get_Absrange, Verify_Eprom
     XREF Write_Err_msg
     XREF PresetBuffer_Hex8
     XREF InpLine, Get_Constant
     XREF FlashEprTypes

     XDEF ProgramFlashEprom, BlowFlashEprom, CheckBatteries
     XDEF FlashEprInfo, CheckFlashCard
     XDEF FLBE_command
     XDEF FLI_command


     INCLUDE "defs.asm"
     INCLUDE "stdio.def"
     INCLUDE "memory.def"


; ************************************************************************************************
; Program Flash Eprom
;
.ProgramFlashEprom  CALL BlowFlashEprom
                    RET  C                             ; an error occurred

                    LD   BC,$0210                      ; position of window
                    LD   DE,$0530                      ; size of message window
                    LD   HL,fprg_prompt
                    LD   IX,fprg_banner                ; pointer to menu banner
                    CALL ReportWindow                  ; display (menu) window with message
                    RET                                ; "success..."



; *********************************************************************************************************************
;
; Program current Eprom Bank at current range with the contents of the identical range in memory buffer
;
; Returns Fc = 1, if an Eprom Address couldn't be programmed.
;         Fc = 0, if programming were successful.
;
; All registers except IY are changed.
;
.BlowFlashEprom     CALL CheckFlashCard
                    RET  C                             ; Flash Eprom not inserted in slot 3

                    CALL DispProgMsg                   ; "Programming Flash Card..."

                    CALL Check_Eprom                   ; eprom already used at range?
                    RET  C

                    LD   A,(EprBank)                   ; get current EPROM bank to be blown...
                    LD   B,A                           ; into
                    PUSH IY
                    PUSH BC
                    CALL Get_AbsRange                  ; get start ranges in HL, DE, length in BC
                    PUSH BC
                    POP  IY                            ; IY = size of block
                    POP  BC                            ; B = Bank of Eprom
                    EX   DE,HL                         ; DE = Source pointer, HL = dest. pointer
                    SET  7,H
                    RES  6,H                           ; use segment 2 to blow data...
                    XOR  A                             ; use blow algorithm according to flash chip hardware.
                    CALL FlashEprWriteBlock            ; blow to Flash Eprom
                    POP  IY

                    JR   NC, block_written

                    EX   DE,HL                         ; HL = Source pointer (in buffer), DE = dest. pointer
                    JR   progerror

.block_written      LD   A,(EprBank)                   ; get current EPROM bank to be blown...
                    LD   B,A                           ; into
                    LD   C, MS_S2                      ; segment 2
                    CALL MemDefBank                    ; Bind in destination bank (B, C = Ms_Sx)
                    CALL Get_AbsRange                  ; get start ranges in HL, DE, length in BC
                    CALL Verify_Eprom
                    JR   C, progerror
                    RET
.progerror
                    LD   A,7
                    CALL_OZ(Os_out)                    ; warning bleep
                    LD   A,13                          ; "Byte incorrectly blown in Eprom at "
                    CALL Disp_EprAddrError
                    SCF
                    RET


; ************************************************************************************************
;
.DispProgMsg        PUSH AF
                    PUSH BC
                    PUSH DE
                    PUSH HL
                    CALL GreyApplWindow
                    LD   A,192 | '4'
                    LD   BC,$0312                      ; position of window
                    LD   DE,$0228                      ; size of message window
                    LD   HL,prog_banner
                    CALL CreateWindow                  ; create according to parameters
                    LD   A,1
                    CALL_OZ(Os_Out)
                    LD   A,$7F
                    CALL_OZ(Os_Out)                    ; reset toggles
                    POP  HL
                    POP  DE
                    POP  BC
                    POP  AF
                    RET
.prog_banner        DEFM "Programming Flash Eprom...", 0



; ************************************************************************************************
;
; IN:
;    HL = banner message
;
.DispFormatMsg      PUSH AF
                    PUSH BC
                    PUSH DE
                    CALL GreyApplWindow
                    LD   A,192 | '4'
                    LD   BC,$0312                      ; position of window
                    LD   DE,$0228                      ; size of message window
                    CALL CreateWindow                  ; create according to parameters
                    LD   A,1
                    CALL_OZ(Os_Out)
                    LD   A,$7F
                    CALL_OZ(Os_Out)                    ; reset toggles
                    POP  DE
                    POP  BC
                    POP  AF
                    RET
.format0_banner     DEFM "Erasing Flash Eprom Sector...", 0
.format1_banner     DEFM "Erasing Complete Flash Eprom...", 0



; ************************************************************************************************
; CC_flbe  -   Flash Eprom Block Erase
;
.FLBE_command
                    CALL CheckFlashCard
                    RET  C                             ; Flash Eprom not inserted in slot 3

                    LD   BC,$0210                      ; postion of error window
                    LD   DE,$0428                      ; size of error window
                    LD   HL, FleprFmt0_prompt
                    LD   IX,FlEprFormat0_banner        ; pointer to menu banner
                    CALL YesNoWindow
                    RET  C                             ; ESC pressed...
                    JR   Z, format_all

                    LD   L,0
                    CALL PresetBuffer_Hex8             ; preset buffer with '00'
                    LD   A,3                           ; set cursor at end of block number
                    LD   BC,$0210                      ; display menu at (15,2)
                    LD   DE,FlEprFormat_prompt
                    LD   HL,FlEprFormat_banner
                    CALL InpLine                       ; enter address
                    CP   IN_ESC                        ; <ESC> pressed during input?
                    RET  Z                             ; Yes, abort command.
                    LD   C,8
                    EX   DE,HL                         ; get block number
                    CALL Get_Constant                  ; Block Number in E
                    RET  C

                    LD   HL, format0_banner
                    CALL DispFormatMsg

                    LD   A,E
                    AND  15                            ; Block number range is 0 - 15
                    LD   B,A
                    LD   A,(EprBank)
                    AND  @11000000
                    RLCA
                    RLCA
                    LD   C,A                           ; derived slot number from Bank (number)
                    CALL FlashEprBlockErase
                    JR   C, format_error
.block_formatted
                    LD   BC,$0311                      ; position of window
                    LD   DE,$0530                      ; size of message window
                    LD   HL,fble_prompt
                    LD   IX,FlEprFormat_banner         ; pointer to menu banner
                    CALL ReportWindow                  ; display (menu) window with message
                    RET

.format_error       LD   A,22
                    CALL Write_Err_msg
                    SCF
                    RET

.format_all         LD   HL, format1_banner
                    CALL DispFormatMsg
                    LD   A,(EprBank)
                    AND  @11000000
                    RLCA
                    RLCA
                    LD   C,A                           ; derived slot number from Bank (number)
                    CALL FlashEprCardErase
                    JR   C, format_error
.card_formatted
                    LD   BC,$0311                      ; position of window
                    LD   DE,$0530                      ; size of message window
                    LD   HL,EprErase_prompt
                    LD   IX,FlEprFormat0_banner        ; pointer to menu banner
                    CALL ReportWindow                  ; display (menu) window with message
                    RET


; ************************************************************************************************
;
;
.FLI_command        CALL CheckFlashCard
                    RET  C                             ; Ups - Flash Eprom not available in slot 3
                                                       ; A = Device Code
                    CALL FlashEprInfo                  ; HL = pointer to Mnemonic...
                    LD   BC,$0210                      ; position of window
                    LD   DE,$0530                      ; size of message window
                    LD   IX,FlEprInfo_banner           ; pointer to menu banner
                    CALL ReportWindow                  ; display (menu) window with message
                    RET


; ************************************************************************************************
; Fetch Intel Flash Eprom Device Code and return information of chip.
;
; IN:
;    None.
;
; OUT:
;    Fc = 0, Flash Eprom Recognized in slot 3
;         B = total of Blocks on Flash Eprom
;         HL = pointer to Mnemonic description of Flash Eprom
;    Fc = 1, Flash Eprom not found in slot 3, or Device code not found
;
.FlashEprInfo       LD   A,(EprBank)
                    AND  @11000000
                    RLCA
                    RLCA
                    LD   C,A                      ; derived slot number from Bank number)
                    CALL FlashEprCardId
                    RET  C

                    LD   A,L                      ; get Device Code
                    LD   C,H                      ; get Manufacturer Code
                    PUSH DE
                    LD   HL, FlashEprTypes
                    LD   B,(HL)                   ; no. of Flash Eprom Types in table
                    INC  HL
.find_loop          CP   (HL)                     ; device code found?
                    JR   NZ, get_next
                         INC  HL                  ; points at manufacturer code
                         LD   E,A
                         LD   A,(HL)
                         CP   C
                         LD   A,E
                         DEC  HL
                         JR   NZ,get_next
                         INC  HL
                         INC  HL
                         LD   B,(HL)              ; B = total of block on Flash Eprom
                         INC  HL
                         INC  HL                  ; points at mnemonic string description.
                         LD   E,(HL)
                         INC  HL
                         LD   D,(HL)
                         EX   DE,HL               ; HL = pointer to mnemonic string
                         POP  DE
                         RET                      ; Fc = 0, Flash Eprom data returned...
.get_next
                    LD   DE, 6                    ; each table entry is 6 bytes (3 x 2 16bit words)
                    ADD  HL,DE
                    DJNZ find_loop                ; point at next entry...
                    SCF
                    POP  DE                       ; Flash Eprom Device Code not recognised
                    RET


; ************************************************************************************************
; Check presence of Flash Eprom in slot that is part of the current (absolute) Bank number.
;
.CheckFlashCard     LD   A,(EprBank)
                    AND  @11000000
                    RLCA
                    RLCA
                    LD   C,A                      ; derived slot number from Bank (number)
                    CALL FlashEprCardId
                    RET  NC

                    LD   A,23
                    CALL Write_Err_msg
                    SCF
                    RET
