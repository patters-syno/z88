     XLIB FlashEprWriteBlock

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

     LIB MemDefBank           ; Bind bank, defined in B, into segment C. Return old bank binding in B
     LIB MemGetCurrentSlot    ; Get current slot number of this executing library routine in C
     LIB ExecRoutineOnStack   ; Clone small subroutine on system stack and execute it
     LIB FlashEprCardId       ; Identify Flash Memory Chip in slot C

     INCLUDE "flashepr.def"
     INCLUDE "memory.def"
     INCLUDE "blink.def"
     INCLUDE "error.def"


; ==========================================================================================
; Flash Eprom Commands for 28Fxxxx series (equal to all chips, regardless of manufacturer)

DEFC FE_RST = $FF           ; reset chip in read array mode
DEFC FE_RSR = $70           ; read status register
DEFC FE_CSR = $50           ; clear status register
DEFC FE_WRI = $40           ; byte write command
; ==========================================================================================


; ***************************************************************************
;
; Write a block of bytes to the Flash Eprom Card, from address
; DE to BHL of block size IY. If a block will cross a bank boundary, it is
; automatically continued on the next adjacent bank of the card.
; On return, BHL points at the byte after the last written byte.
;
; -------------------------------------------------------------------------
; The routine is used by the File Eprom Management libraries, but is well
; suited for other application purposes.
; -------------------------------------------------------------------------
;
; The routine can be told which programming algorithm to use (by specifying
; the FE_28F or FE_29F mnemonic in A); these parameters can be fetched when
; investigating which Flash Memory chip is available in the slot, using the
; FlashEprCardId routine that reports these constants.
;
; However, if neither of the constants are provided in A, the routine can
; be specified with A = 0 which internally polls the Flash Memory for
; identification and intelligently use the correct programming algorithm.
; The identified FE_28F or FE_29F constant is returned to the caller in A
; for future reference (when the block was successfully programmed to the card).
;
; Uses the segment mask of HL(where BHL memory will be bound into the Z80
; address space to blow the block of bytes (MM_S0 - MM_S3), which has to be
; in a different segment than DE is referring.
;
; BHL points to an absolute bank (which is part of the slot that the Flash
; Memory Card have been inserted into).
;
; Further, the local buffer must be available in local address space and not
; part of the segment used for blowing bytes.
;
; Important:
; INTEL I28Fxxxx series Flash chips require the 12V VPP pin in slot 3
; to successfully blow data to the memory chip. If the Flash Eprom card
; is inserted in slot 1 or 2, this routine will report a programming failure.
;
; It is the responsibility of the application (before using this call) to
; evaluate the Flash Memory (using the FlashEprCardId routine) and warn the
; user that an INTEL Flash Memory Card requires the Z88 slot 3 hardware, so
; this type of unnecessary error can be avoided.
;
; In :
;         A = FE_28F, FE_29F or 0 (poll card for blowing algorithm)
;         DE = local pointer to start of block (located in current address space)
;         BHL = extended address to start of destination (pointer into card)
;              (bits 7,6 of B is the slot mask)
;              (bits 7,6 of H = MM_Sx segment mask for BHL)
;         IY = size of block (at DE) to blow
; Out:
;         Success:
;              Fc = 0
;              A = FE_28F or FE_29F (depending on found card)
;              BHL updated
;         Failure:
;              Fc = 1
;              A = RC_BWR (block not blown properly)
;              A = RC_NFE (not a recognized Flash Memory Chip)
;              A = RC_UNK (chip type is unknown: use only FE_28F, FE_29F or 0)
;
; Registers changed on return:
;    ...CDE../IXIY ........ same
;    AFB...HL/.... afbcdehl different
;
; --------------------------------------------------------------------------------------------
; Design & programming by
;    Gunther Strube, Dec 1997, Jan-Apr 1998, Aug 2004, Oct 2005, Aug-Oct 2006
;    Thierry Peycru, Zlab, Dec 1997
;    Patrick Moore backported improvements from OZ 5.0 to standard library, July 2022
; --------------------------------------------------------------------------------------------
;
.FlashEprWriteBlock
                    PUSH IX
                    PUSH DE                                 ; preserve DE
                    PUSH BC                                 ; preserve C
                    EX   AF,AF'                             ; preserve FE Programming type in A'

                    LD   A,B
                    EXX
                    AND  @11000000
                    RLCA
                    RLCA                                    ; A = slot number of BHL
                    LD   C,A                                ; remember Flash Memory slot (of BHL pointer) number in C'
                    EXX

                    LD   A,H
                    RLCA
                    RLCA
                    AND  @00000011
                    LD   C,A                                ; C = MS_Sx
                    LD   A,B
                    CALL MemDefBank                         ; Bind slot x bank into segment C
                    PUSH BC                                 ; preserve old bank binding of segment C
                    LD   B,A                                ; but use current bank as reference...

                    DI                                      ; no maskable interrupts allowed while doing flash hardware commands...
                    CALL FEP_WriteBlock
                    EI                                      ; allow Blink interrupts again

                    LD   D,B                                ; preserve current Bank number of pointer...
                    POP  BC
                    CALL MemDefBank                         ; restore old segment C bank binding
                    LD   B,D

                    POP  DE
                    LD   C,E                                ; original C register restored...
                    POP  DE
                    POP  IX
                    RET


; ***************************************************************
;
; Write Block to BHL already bound, in slot x, of IY length.
; This routine will clone itself on the stack and execute there.
;
; In:
;         A' = FE_28F, FE_29F or 0
;         C' = slot number of BHL pointer
;         C  = MS_Sx segment specifier
;         DE = local pointer to start of block (available in current address space)
;         BHL = extended address to start of destination (pointer into card)
;         IY = size of block to blow
; Out:
;    Fc = 0, block blown successfully to the Flash Card
;         A = FE_28F or FE_29F, depending on found chip type
;         BHL = points at next free byte on Flash Eprom
;         DE = points beyond last byte of buffer
;    Fc = 1,
;         A = RC_BWR  (block not blown properly)
;         A = RC_UNK (pre-specified chip type is unknown: use only FE_28F, FE_29F or 0)
;         DE,BHL points at byte not blown properly (A = RC_BWR)
;
; Registers changed after return:
;    ......../IXIY same
;    AFBCDEHL/.... different
;
.FEP_WriteBlock
                    EX   AF,AF'                             ; FE Programming type in A
                    CP   FE_28F
                    JR   Z, check_slot3                     ; make sure that pre-selected INTEL flash is located in slot 3
                    CP   FE_29F
                    JR   Z, write_29F_block
                    OR   A
                    JR   Z, poll_chip_programming           ; chip type = 0 indicates to get chip type to program it...
                    SCF
                    LD   A, RC_Unk                          ; unknown chip type specified!
                    RET
.poll_chip_programming
                    PUSH BC
                    PUSH DE
                    PUSH HL
                    EXX
                    CALL FlashEprCardId                     ; Flash in slot C?
                    EXX
                    POP  HL
                    POP  DE
                    POP  BC
                    RET  C                                  ; Fc = 1, A = RC error code (Flash Memory not found)

                    CP   FE_28F                             ; now, we've got the chip type
                    JR   NZ, write_29F_block                ; and this one may be programmed in any slot...
.check_slot3
                    PUSH AF                                 ; remember FE_28F chip type
                    LD   A,3
                    EXX
                    CP   C                                  ; when chip is FE_28F series, we need to be in slot 3
                    JR   Z,write_28F_block                  ; to make a successful "write" of the byte...
                    EXX
                    POP  AF
                    SCF
                    LD   A, RC_BWR                          ; Oops, not in slot 3, signal error!
                    RET
.write_28F_block
                    EXX
                    LD   IX, FEP_ExecWriteBlock_28F
                    EXX
                    LD   BC, end_FEP_ExecWriteBlock_28F - FEP_ExecWriteBlock_28F
                    EXX
                    CALL ExecRoutineOnStack
.exit_blowblock
                    EX   AF,AF'
                    POP  AF                                 ; get chip type
                    EX   AF,AF'
                    RET  C                                  ; ignore chip type and return error code
                    EX   AF,AF'                             ; Block was successfully blown, return chip type in A
                    OR   A                                  ; Fc = 0 (signal successfull operation)
                    RET
.write_29F_block
                    PUSH AF                                 ; remember FE_29F chip type
                    EXX
                    LD   A,C
                    EXX
                    LD   IX, FEP_ExecWriteBlock_29F
                    EXX
                    LD   BC, end_FEP_ExecWriteBlock_29F - FEP_ExecWriteBlock_29F
                    EXX
                    CALL ExecRoutineOnStack
                    JR   exit_blowblock


; ***************************************************************
; Program block of data on an INTEL I28Fxxxx Flash Memory.
; (this routine is copied on the stack and executed there)
;
; IN:
;       BHL = pointer to blow data
;       C = MS_Sx segment specifier
;       DE = pointer to source data
;       IY = size of data
;
.FEP_ExecWriteBlock_28F
                    EXX
                    LD   BC,BLSC_COM                        ; Address of soft copy of COM register
                    LD   A,(BC)
                    SET  BB_COMVPPON,A                      ; VPP On
                    SET  BB_COMLCDON,A                      ; Force Screen enabled...
                    LD   (BC),A
                    OUT  (C),A                              ; signal to HW

                    PUSH IY
                    POP  HL                                 ; use HL as 16bit decrement counter
                    EXX

.WriteBlockLoop     EXX
                    LD   A,H
                    OR   L
                    DEC  HL
                    EXX
                    JR   Z, exit_write_block                ; block written successfully (Fc = 0)
                    PUSH BC

                    LD   A,(DE)
                    LD   B,A                                ; preserve to blown in B...
                    LD   (HL),FE_WRI
                    LD   (HL),A                             ; blow the byte...

.write_busy_loop    LD   (HL),FE_RSR                        ; Flash Eprom (R)equest for (S)tatus (R)egister
                    LD   A,(HL)                             ; returned in A
                    BIT  7,A
                    JR   Z,write_busy_loop                  ; still blowing...

                    LD   (HL), FE_CSR                       ; Clear Flash Eprom Status Register
                    LD   (HL), FE_RST                       ; Reset Flash Eprom to Read Array Mode

                    BIT  4,A
                    JR   NZ,write_error                     ; Error: byte wasn't blown properly

                    LD   A,(HL)                             ; read byte at (HL) just blown
                    CP   B                                  ; equal to original byte?
                    JR   Z, exit_write_byte                 ; byte blown successfully!
.write_error
                    LD   A, RC_BWR
                    SCF
.exit_write_byte
                    POP  BC
                    JR   C, exit_write_block

                    INC  DE                                 ; buffer++
                    LD   A,B
                    PUSH AF

                    LD   A,H                                ; BHL++
                    AND  @11000000                          ; preserve segment mask

                    RES  7,H
                    RES  6,H                                ; strip segment mask to determine bank boundary crossing
                    INC  HL                                 ; ptr++
                    BIT  6,H                                ; crossed bank boundary?
                    JR   Z, not_crossed                     ; no, offset still in current bank
                    INC  B
                    RES  6,H                                ; yes, HL = 0, B++
.not_crossed
                    OR   H                                  ; re-establish original segment mask for bank offset
                    LD   H,A

                    POP  AF
                    CP   B                                  ; was a new bank crossed?
                    JR   Z,WriteBlockLoop                   ; no...

                    PUSH BC                                 ; pointer crossed a new bank
                    PUSH HL
                    LD   A,C                                ; bind new bank into segment C...
                    OR   $D0
                    LD   H,$04
                    LD   L,A                                ; BC points at soft copy of cur. binding in segment C
                    LD   C,A
                    LD   (HL),B                             ; update soft copy
                    OUT  (C),B                              ; bind new bank...
                    POP  HL
                    POP  BC
                    JR   WriteBlockLoop
.exit_write_block
                    PUSH AF
                    EXX
                    LD   A,(BC)
                    RES  BB_COMVPPON,A                      ; VPP Off
                    LD   (BC),A
                    OUT  (C),A                              ; Signal to HW
                    EXX
                    POP  AF
                    RET
.end_FEP_ExecWriteBlock_28F


; ***************************************************************
; Program block of data on an AMD Flash Memory
; (this routine is copied on the stack and executed there)
;
; IN:
;       BHL = pointer to blow data
;       C = MS_Sx segment specifier
;       DE = pointer to source data
;       IY = size of data
;
.FEP_ExecWriteBlock_29F
                    EXX
                    PUSH IY
                    POP  BC                                 ; install block size (bytes remaining to be flashed)
                    EXX                                     ; (now in BC')

.WriteBlockLoop_29F EXX
                    LD   A,B
                    OR   C
                    DEC  BC                                 ; decrement block size counter
                    EXX
                    RET  Z                                  ; block written successfully (Fc = 0), return to caller
                    PUSH BC                                 ; preserve bank and MS_Sx while programming byte to card

                    LD   A,(DE)                             ; get byte to blow from source block
                    LD   B,A                                ; preserve a copy of byte for later verification

                    ; Adapted from AM29Fx_InitCmdMode mixed with the original stdlib code
                    ;     from the OZ 5.0 code (in os/kn1/osfep/osfep.asm)
                    ;     we can't use a CALL to another function since .FEP_ExecWriteBlock_29F to .end_FEP_ExecWriteBlock_29F
                    ;     will be copied to the stack for execution, so the whole routine has been inserted
                    ;
                    ; ***************************************************************************************************
                    ; Prepare AMD 29F/39F Command Mode sequence addresses.
                    ;
                    ; In:
                    ;       HL points into bound bank of Flash Memory
                    ; Out:
                    ;       BC = bank select sw copy address
                    ;       DE = address $2AAA + segment  (derived from HL)
                    ;       HL = address $1555 + segment  (derived from HL)
                    ;
                    ; Registers changed on return:
                    ;    AF....../IXIY same
                    ;    ..BCDEHL/.... different
                    ;
                    ; PUSH AF                               ; the original stdlib code didn't need to preserve AF here
                    LD   A,H
                    AND  @11000000
                    
                    ; changed to match original stdlib code behaviour
                    EXX                                     ; use alternate registers now to avoid overwriting the inputs
                    PUSH BC                                 ; preserve block size of data to blow (formerly BC')
                    ; end change

                    LD   D,A
                    LD   BC,BLSC_SR0
                    RLCA
                    RLCA
                    OR   C
                    LD   C,A                                ; BC = bank select sw copy address
                    LD   A,D
                    OR   $15
                    LD   H,A
                    LD   L,$55                              ; HL = address $1555 + segment
                    LD   A,D
                    OR   $2A
                    LD   D,A
                    LD   E,$AA                              ; DE = address $2AAA + segment
                    ; POP  AF
                    ; end AM29Fx_InitCmdMode


                    LD   A,$A0                              ; Execute Byte Program Mode

                    ; AM29Fx_CmdMode
                    ;     from the OZ 5.0 code (in os/lowram/flash.asm)
                    ;     we can't use a CALL to another function since .FEP_ExecWriteBlock_29F to .end_FEP_ExecWriteBlock_29F
                    ;     will be copied to the stack for execution, so the whole routine has been inserted
                    ;
                    ; ***************************************************************************************************
                    ; Execute AMD 29F/39F (or compatible) Flash Memory Chip Command
                    ; Maskable interrupts are be disabled while chip is in command mode.
                    ;
                    ; In:
                    ;       A = AMD Command code, if A=0 command is not sent
                    ;       BC = bank select sw copy address
                    ;       DE = address $2AAA + segment
                    ;       HL = address $1555 + segment
                    ; Out:
                    ;       -
                    ;
                    ; Registers changed on return:
                    ;    ..BCDEHL/IXIY same
                    ;    AF....../.... different
                    ;
                    ;DI                                     ; not needed here because interrupts are disabled for the whole FEP_WriteBlock call
                    PUSH AF
                    LD   A,(BC)                             ; get current bank
                    OR   $01                                ; A14=1 for 5555 address
                    OUT  (C),A                              ; select it
                    LD   (HL),E                             ; AA -> (5555), First Unlock Cycle
                    EX   DE,HL
                    AND  $FE                                ; A14=0
                    OUT  (C),A                              ; select it
                    LD   (HL),E                             ; 55 -> (2AAA), Second Unlock Cycle
                    EX   DE,HL
                    OR   $01                                ; A14=1
                    OUT  (C),A                              ; select it
                    POP  AF                                 ; get command
                    OR   A                                  ; is it 0?
                    JR   Z,cmdmode_exit                     ; don't write it if it is
                    LD   (HL),A                             ; A -> (5555), send command
.cmdmode_exit
                    LD   A,(BC)                             ; restore original bank
                    OUT  (C),A                              ; select it
                    ; end AM29Fx_CmdMode


                    JR continue                             ; .FEP_ExecWriteBlock_29F to .end_FEP_ExecWriteBlock_29F is longer than 128 bytes
                                                            ; too far for a single JR instruction to jump all the way back to the top for the loop 
.jr_staging_to_routine_top
                    JR WriteBlockLoop_29F
.continue
                    POP  BC                                 ; retrieve block size counter
                    EXX                                     ; store it back in BC' and retrieve byte to program
                    LD   (HL),B                             ; program byte to Flash Memory Address
.toggle_wait_loop
                    LD   A,(HL)                             ; get first DQ6 programming status
                    LD   C,A                                ; get a copy programming status (that is not XOR'ed)...
                    XOR  (HL)                               ; get second DQ6 programming status
                    BIT  6,A                                ; toggling?
                    JR   Z,toggling_done                    ; no, programming completed successfully!
                    BIT  5,C                                ;
                    JR   Z, toggle_wait_loop                ; we're toggling with no error signal and waiting to complete...

                    LD   A,(HL)                             ; DQ5 went high, we need to get two successive status
                    XOR  (HL)                               ; toggling reads to determine if we're still toggling
                    BIT  6,A                                ; which then indicates a programming error...
                    JR   NZ,program_err_29f                 ; damn, byte NOT programmed successfully!
.toggling_done
                    LD   A,(HL)                             ; we're back in Read Array Mode
                    CP   B                                  ; verify programmed byte (just in case!)
                    JR   Z,exit_write_byte_29F              ; byte was successfully programmed!
.program_err_29f
                    LD   (HL),$F0                           ; F0 -> (XXXXX), force Flash Memory to Read Array Mode
                    LD   A, RC_BWR
                    SCF
.exit_write_byte_29F
                    POP  BC                                 ; get current bank and segment for block data
                    RET  C

                    INC  DE                                 ; buffer++
                    LD   A,B
                    PUSH AF

                    LD   A,H                                ; BHL++
                    AND  @11000000                          ; preserve segment mask

                    RES  7,H
                    RES  6,H                                ; strip segment mask to determine bank boundary crossing
                    INC  HL                                 ; ptr++
                    BIT  6,H                                ; crossed bank boundary?
                    JR   Z, not_crossed_29F                 ; no, offset still in current bank
                    INC  B
                    RES  6,H                                ; yes, HL = 0, B++
.not_crossed_29F
                    OR   H                                  ; re-establish original segment mask for bank offset
                    LD   H,A

                    POP  AF
                    CP   B                                  ; was a new bank crossed?
                    JR   Z,WriteBlockLoop_29F               ; no...

                    PUSH BC                                 ; pointer crossed a new bank
                    PUSH HL
                    LD   A,C                                ; bind new bank into segment C...
                    OR   $D0
                    LD   H,$04
                    LD   L,A                                ; BC points at soft copy of cur. binding in segment C
                    LD   C,A
                    LD   (HL),B                             ; first update soft copy..
                    OUT  (C),B                              ; bind new bank...
                    POP  HL
                    POP  BC
                    JR   jr_staging_to_routine_top          ; JR WriteBlockLoop_29F (but it's more than 128 bytes away so we need 2 jumps) 
.end_FEP_ExecWriteBlock_29F
