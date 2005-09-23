; *************************************************************************************
; FlashStore
; (C) Gunther Strube (gbs@users.sf.net) & Thierry Peycru (pek@users.sf.net), 1997-2005
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

Module SelectCard

; This module contains functionality that displays the card / file area selection pop-up
; window and cursor movement

     XDEF SelectFileArea, SelectCardCommand, SelectDefaultSlot, PollSlots, VduCursor
     XDEF selslot_banner, epromdev, DispSlotSize

     lib CreateWindow              ; Create an OZ window (with options banner, title, etc)
     lib RamDevFreeSpace           ; Get free space on RAM device
     lib FileEprRequest            ; Check for presence of Standard File Eprom Card or Area in slot
     lib FileEprFreeSpace          ; Return amount of deleted file space (in bytes)
     lib ApplEprType               ; check for presence of application card in slot
     lib FlashEprCardId            ; Return Intel Flash Eprom Device Code (if card available)

     XREF DispCmdWindow,pwait, rdch     ; fsapp.asm
     XREF greyscr, greyfont, nocursor   ; fsapp.asm
     XREF nogreyfont, notinyfont, cls   ; fsapp.asm
     xref GetCurrentSlot, DispMainWindow; fsapp.asm
     XREF PollFileFormatSlots           ; format.asm
     XREF FlashWriteSupport             ; format.asm
     XREF execute_format, noformat_msg  ; format.asm
     XREF CheckFlashCardID              ; format.asm
     XREF FileEpromStatistics,DispKSize ; filestat.asm
     XREF m16, ksize_txt                ; filestat.asm
     XREF PollFileCardWatermark         ; browse.asm
     XREF FilesAvailable,DispFilesWindow ; browse.asm
     XREF InitFirstFileBar              ; browse.asm
     XREF DispErrMsg, DispIntelSlotErr  ; errmsg.asm

     include "stdio.def"
     include "integer.def"
     include "fsapp.def"



; *************************************************************************************
;
; Display slot selection window to choose another Flash Card Device
;
.SelectCardCommand
                    CALL greyscr
                    call GetCurrentSlot           ; C = (curslot)
                    call PollSlots
                    or   a                        ; if no file areas were found, then
                    call z,PollFileFormatSlots    ; investigate slots 1-3 for Flash Cards that can be formatted
                    or   a
                    jr   nz,continue_selcard
                         ld   hl,selslot_banner
                         call DispMainWindow
                         LD   HL, noformat_msg    ; no file areas, nor flash cards available!
                         CALL DispErrMsg
                         ret
.continue_selcard
                    push bc
                    ld   hl, selslot_banner
                    call SelectFileArea           ; user selects a File Eprom Area in one of the external slots
                    pop  bc
                    jp   c, user_aborted
                    push af
                    call z, PollFileCardWatermark ; get watermark from selected slot
                    pop  af
                    jr   nz, user_aborted

                    call FilesAvailable
                    ret  nc                       ; file area found, let user select it...
                    call GetCurrentSlot           ; C = (curslot)
                    call FlashWriteSupport        ; is this an empty flash card with write/format support?
                    ret  c                        ; no flash write/format support for this slot.
                    jp   execute_format           ; prompt the user to format the flash card.
.user_aborted
                    ld   a,c
                    ld   (curslot),a              ; user aborted selection, restore original slot...
                    ret
; *************************************************************************************


; *************************************************************************************
; Display the contents of slots 1-3 in an easy understandable symbolically form.
;
; IN: HL = Window Banner Title
;
.SelectFileArea
                    CALL greyscr

                    push hl
                    ld   a, 64 | '3'
                    ld   bc, $004E
                    ld   de, $080F
                    call CreateWindow
                    ld   hl, selectdevhelp
                    call_oz GN_Sop           ; Display small help text in right side window

                    ld   a, 128 | '2'
                    ld   bc, $0016
                    ld   de, $082A
                    pop  hl
                    call CreateWindow        ; Device selection window.

                    ld   a,3                 ; begin from slot 3...
.disp_slot_loop
                    ld   (curslot),a

                    ld   c,a
                    call FlashWriteSupport
                    jp   z, flashcard_detected
.poll_for_ram_card
                    call RamDevFreeSpace
                    jr   c, poll_for_rom_card
                         LD   (free),A       ; A = size of RAM card in 16K banks, DE = free 256 byte pages
                         LD   HL,ramdev
                         XOR  A
                         CALL DisplayCard
                         dec  c
                         inc  b
                         inc  b
                         CALL VduCursor
                         EX   DE,HL          ; HL = free 256 bytes pages on RAM Card
                         LD   DE,4           ; HL / 4 = free space in K
                         CALL_OZ(GN_D16)
                         EX   DE,HL
                         LD   HL, freetxt
                         CALL_OZ(Gn_Sop)
                         CALL DispKSize      ; display free space in DE
                         LD   HL, ksize_txt
                         CALL_OZ(Gn_sop)
                         jp   nextline
.poll_for_rom_card
                    ld   h,c                      ; preserve a copy of slot nubmer...
                    call ApplEprType
                    jr   c, poll_for_eprom_card
                         ld   hl, epromdev
                         ld   (free),bc           ; C = size of physical card
                         ld   a,4                 ; display PadLock (FlashStore does not support write to Eprom)
                         call DisplayCard         ; display size of card as defined by ROM header
                         dec  c
                         inc  b
                         inc  b
                         CALL VduCursor
                         ld   hl, appstxt
                         call_oz(Gn_Sop)
                         inc  b
                         CALL VduCursor
                         push bc
                         call GetCurrentSlot      ; C = (curslot)
                         call FileEprRequest
                         ld   a,c
                         pop  bc
                         jr   c, eprom_nofiles    ; the Eprom Application Card had no file area...
                         jr   nz, eprom_nofiles
                         ld   hl, freetxt
                         call_oz(Gn_Sop)          ; display size of sub file area in K on Eprom
                         call DispFreeSpace
                         jp   nextline
.eprom_nofiles
                         ld   hl, nofilestxt
                         call_oz(Gn_Sop)
                         jp   nextline
.poll_for_eprom_card
                    ld   c,h                      ; poll slot C...
                    call FileEprRequest
                    jr   c, empty_slot
                    jr   nz, empty_slot
                         ld   hl, epromdev        ; C = size of File Area in 16K banks (if Fz = 1)
                         ld   a,d                 ; D = size of card in 16K banks
                         ld   (free),a
                         ld   a,4                 ; display PadLock (FlashStore does not support write to Eprom)
                         call DisplayCard         ; display size of card as defined by ROM header
                         dec  c
                         inc  b
                         inc  b
                         CALL VduCursor
                         ld   hl, freetxt        ; display "Files xxxxK"
                         call_oz(Gn_Sop)
                         ld   a,(free)
                         call DispFreeSpace
                         jp   nextline
.empty_slot
                    CALL SlotCardBoxCoord         ; the slot is empty (or contains an empty Eprom Card)
                    LD   A, @00000011             ; draw a grey outline box
                    CALL DrawCardBox
                    LD   A,C
                    ADD  A,2
                    LD   C,A
                    LD   A,B
                    ADD  A,3
                    LD   B,A
                    CALL VduCursor
                    ld   hl, emptytxt             ; and write "empty slot" in the middle of the grey box
                    call_oz(Gn_Sop)
                    jr   nextline
.flashcard_detected
                    ld   a,b
                    ld   (free),a                 ; size of Flash Card in 16K banks
                    ld   a,0
                    jr   nc, flash_writeable
                    set  2,a
.flash_writeable
                    ld   hl, flashdev
                    call DisplayCard
                    dec  c
                    inc  b
                    inc  b                        ; prepare for "applications" text
                    push bc
                    call GetCurrentSlot           ; C = (curslot)
                    call ApplEprType
                    ld   a,c
                    pop  bc
                    jr   c, flash_noapps
                         CALL VduCursor
                         ld   hl, appstxt
                         call_oz(Gn_Sop)
                         inc  b                    ; prepare for "files " text
.flash_noapps
                    CALL VduCursor
                    push bc
                    call GetCurrentSlot           ; C = (curslot)
                    call FileEprRequest
                    ld   a,c
                    pop  bc
                    jr   c, flash_nofiles
                    jr   nz, flash_nofiles
                         ld   hl, freetxt
                         call_oz(Gn_Sop)
                         call DispFreeSpace
                         jr   nextline
.flash_nofiles
                         ld   hl, nofilestxt
                         call_oz(Gn_Sop)
.nextline
                    ld   a,(curslot)
                    dec  a
                    jp   nz, disp_slot_loop

                    ; Now, user selects card (if possible) ...
                    CALL SelectDefaultSlot        ; preset menu bar at first available card file area
.select_slot_loop
                    call UserMenu
                    ret  c                        ; user aborted selection
                    ld   hl, availslots
                    ld   b,0
                    call GetCurrentSlot           ; C = (curslot)
                    add  hl,bc
                    xor  a
                    cp   (hl)
                    jr   z, check_empty_flcard    ; user selected apparently void or illegal slot
                    call InitFirstFileBar         ; initialize File Bar cursor for new slot..
                    cp   a                        ; slot selected successfully
                    ret

.check_empty_flcard
                    call FlashWriteSupport
                    jr   nz, select_slot_loop     ; no Flash Card in slot...
                    jp   nc, execute_format       ; empty flash card in slot (no file area, and erase/write support)

                    CALL DispCmdWindow
                    CALL DispMainWindow
                    CALL FileEpromStatistics
                    call DispIntelSlotErr         ; Intel Flash Card found in slot, but no erase/write support in slot
                    cp   a
                    ret
; *************************************************************************************


; *************************************************************************************
; IN
;    A = box draw args (padlock etc)
;    HL = label ("FLASH", "EPROM", "RAM")
;    (free) = size of card in 16K banks
; OUT
;    BC = (Y,X) of start of displayed label
.DisplayCard
                    CALL SlotCardBoxCoord
                    CALL DrawCardBox
                    INC  B              ; Y++
                    INC  C
                    INC  C
                    CALL VduCursor
                    CALL_OZ Gn_Sop      ; display device name (in HL)...
                    LD   A,(free)
                    call DispSlotSize   ; C = size of slot in 16K banks
                    RET
.DispSlotSize
                    push bc
                    push de
                    push hl

                    LD   H,0
                    LD   L,A
                    CALL m16
                    EX   DE,HL          ; size in DE...
                    CALL DispKSize
                    ld   a,'K'
                    call_oz(OS_Out)

                    pop  hl
                    pop  de
                    pop  bc
                    ret
.DispFreeSpace
                    push bc
                    push hl
                    call GetCurrentSlot ; C = (curslot)
                    call FileEprFreeSpace
                    push bc
                    pop  hl
                    ld   b,e            ; DEBC -> BHL
                    ld   c,0
                    ld   de,1024        ; BHL / 1024
                    CALL_OZ(Gn_D24)
                    ex   de,hl
                    inc  de
                    call DispKSize      ; no. of K free
                    ld   a, 'K'
                    call_oz OS_Out
                    pop  hl
                    pop  bc
                    ret
; *************************************************************************************


; *************************************************************************************
;
.UserMenu
.menu_loop     CALL DisplMenuBar
               CALL rdch
               CALL RemoveMenuBar
               LD   HL, curslot
               CP   IN_ESC                        ; ESC?
               JR   Z, abort_select
               CP   IN_ENT                        ; ENTER?
               RET  Z
               CP   IN_RGT                        ; Cursor Right ?
               JR   Z, MVbar_right
               CP   IN_LFT                        ; Cursor Left ?
               JR   Z, MVbar_left
               CP   '1'
               JR   C,menu_loop                   ; smaller than '1'
               CP   '4'
               JR   NC,menu_loop                  ; >= '4'
               SUB  A,48                          ; ['1'; '3'] keys selected
               LD   (HL),A
               CP   A
               RET
.abort_select
               SCF
               RET
.MVbar_right   LD   A,(HL)
               CP   3                             ; has m.bar already reached right edge?
               JR   Z,Mbar_rightwrap
               INC  A
               LD   (HL),A                        ; update new m.bar position
               JR   menu_loop                     ; display new m.bar position

.Mbar_rightwrap LD   A,1
               LD   (HL),A
               JR   menu_loop

.MVbar_left    LD   A,(HL)
               CP   1                             ; has m.bar already reached left edge?
               JR   Z,Mbar_leftwrap
               DEC  A
               LD   (HL),A                        ; update new m.bar position
               JR   menu_loop

.Mbar_leftwrap LD   A,3
               LD   (HL),A
               JR   menu_loop
; *************************************************************************************


; *************************************************************************************
;
.DisplMenuBar  PUSH AF
               PUSH BC
               PUSH HL
               LD   HL,SelectMenuWindow
               CALL_OZ(Gn_Sop)
               CALL SlotCardBoxCoord
               LD   A,C
               ADD  A,9
               LD   C,A                           ; display menu bar at (Y,6) of card box
               LD   A,B
               ADD  A,6                           ; display menu bar at bottom line of card box
               LD   B,A
               CALL VduCursor
               LD   HL,MenuBarOn                  ; now display menu bar at cursor
               CALL_OZ(Gn_Sop)
               POP  HL
               POP  BC
               POP  AF
               RET
; *************************************************************************************


; *************************************************************************************
;
.RemoveMenuBar PUSH AF
               PUSH HL
               LD   HL,SelectMenuWindow
               CALL_OZ(Gn_Sop)
               CALL SlotCardBoxCoord
               LD   A,C
               ADD  A,9
               LD   C,A                           ; display menu bar at (Y,6) of card box
               LD   A,B
               ADD  A,6                           ; display menu bar at bottom line of card box
               LD   B,A
               CALL VduCursor
               LD   HL,MenuBarOff                 ; now display menu bar at cursor
               CALL_OZ(Gn_Sop)
               POP  HL
               POP  AF
               RET
; *************************************************************************************


; *************************************************************************************
; Poll all external slots for file areas and return A = count of found file areas,
; or 0 if none were found.
;
.PollSlots
                    push bc
                    push de
                    push hl

                    ld   hl, availslots+1    ; point to counter of available slots
                    push hl
                    ld   c,1                 ; begin with external slot 1
                    ld   e,0                 ; counter of available file eproms
.poll_loop
                    push bc                  ; preserve slot number...
                    call FileEprRequest      ; File Eprom Card or area available in slot C?
                    pop  bc
                    jr   c, no_fileepr
                    jr   nz, no_fileepr      ; no header was found, but a card was available of some sort
                         inc  e              ; File Eprom found
                         pop  hl
                         ld   (hl),c         ; size of file eprom in 16K banks
                         inc  hl
                         push hl
                         jr   next_slot
.no_fileepr
                         pop  hl
                         ld   (hl),0         ; indicate no file eprom
                         inc  hl
                         push hl
.next_slot
                    inc  c
                    ld   a,c
                    cp   4
                    jr   nz, poll_loop

                    ld   a,e
                    pop  hl
                    ld   (availslots),a      ; store total of File Eprom's found

                    pop  hl
                    pop  de
                    pop  bc
                    cp   a                   ; Fc = 0
                    ret
; *************************************************************************************


; *************************************************************************************
.SelectDefaultSlot                              ; select the first available Card File Area
                    ld   hl, availslots+3		; beginning from slot 3, towards slot 1...
                    ld   b,3
                    xor  a
.sel_slot_loop
                    cp   (hl)
                    jr   nz, found_slot
                    dec  hl
                    djnz sel_slot_loop
.found_slot
                    ld   a,b
                    ld   (curslot),a         ; current slot selected...
                    cp   a
                    ret
; *************************************************************************************


; *************************************************************************************
; Draw a minimalistic Z88 Card outline using VDU Box characters.
;
; IN:
;     A = BIT 0: draw card box in grey colour
;     A = BIT 1: draw only outline (not the card label line)
;     A = BIT 2: draw Padlock on left bottom edge.
;    BC = (Y,X)
;
.DrawCardBox
                    PUSH BC
                    PUSH HL
                    PUSH AF

                    BIT  0,A
                    JR   Z, use_nocursor
                    LD   HL, greyfont   ; draw the card box in grey colour.
                    CALL_OZ GN_Sop
.use_nocursor
                    LD   HL, nocursor
                    CALL_OZ GN_Sop

                    CALL VduCursor      ; set VDU Cursor at (Y,X)
                    LD   HL,cardtop     ; draw top edge of card box
                    CALL_OZ GN_Sop
                    INC  B              ; Y++
                    CALL DrawCardSides
                    INC  B              ; Y++
                    CALL VduCursor      ; set VDU Cursor at (Y,X)
                    POP  AF
                    PUSH AF
                    BIT  1,A
                    JR   Z, draw_middleline
                    CALL DrawCardSides
                    JR   next_cardside
.draw_middleline
                    LD   HL,cardmiddle  ; draw middle line of card box
                    CALL_OZ GN_Sop
.next_cardside
                    INC  B              ; Y++
                    CALL DrawCardSides
                    INC  B              ; Y++
                    CALL DrawCardSides
                    INC  B              ; Y++
                    CALL DrawCardSides
                    INC  B              ; Y++
                    CALL VduCursor      ; set VDU Cursor at (Y,X)
                    LD   HL,cardbottom  ; draw bottom edge of card box
                    CALL_OZ GN_Sop

                    LD   HL, nogreyfont
                    CALL_OZ GN_Sop
                    LD   HL, notinyfont
                    CALL_OZ GN_Sop

                    LD   A,C
                    ADD  A,9            ; (Y,X+9)
                    LD   C,A
                    CALL VduCursor      ; set VDU cursor for slot number (bottom right edge)
                    LD   A,32
                    CALL_OZ OS_Out
                    LD   A,(curslot)
                    ADD  A,48           ; -> Ascii slot number
                    CALL_OZ OS_Out
                    LD   A,32
                    CALL_OZ OS_Out

                    POP  AF
                    PUSH AF
                    BIT  2,A
                    JR   Z, exit_DrawCardBox
                    LD   A,C
                    SUB  A,7            ; (Y,X+7)
                    LD   C,A
                    CALL VduCursor
                    LD   HL, padlock
                    CALL_OZ GN_Sop
.exit_DrawCardBox
                    POP  AF
                    POP  HL
                    POP  BC
                    RET
; BC = Y,X
.DrawCardSides      PUSH BC
                    CALL VduCursor      ; set VDU Cursor at (Y,X)
                    LD   HL, cardside
                    PUSH HL
                    CALL_OZ GN_Sop      ; draw left side
                    LD   A,C
                    ADD  A,13
                    LD   C,A
                    CALL VduCursor      ; set VDU Cursor at (Y,X+13)
                    POP  HL
                    CALL_OZ GN_Sop      ; draw right side
                    POP  BC
                    RET
; *************************************************************************************


; *************************************************************************************
; Place window cursor at (Y,X)
; B = Y window coordinate, C = X window Coordinate
.VduCursor          PUSH AF
                    PUSH HL
                    LD   HL, xypos
                    CALL_OZ GN_Sop
                    LD   A,C            ; X
                    ADD  A,32
                    CALL_OZ OS_Out
                    LD   A,B            ; Y
                    ADD  A,32
                    CALL_OZ OS_Out
                    POP  HL
                    POP  AF
                    RET
; *************************************************************************************


; *************************************************************************************
; Return VDU Card Box (0,X) coordinate for slot X (1-3) fetched in (curslot)
;
; OUT:
;    BC = (Y,X)
;
.SlotCardBoxCoord
                    PUSH AF
                    PUSH HL
                    LD   A,(curslot)
                    DEC  A              ; first card box displayed at (0,0)
                    LD   B,A            ; X coord multiply counter
                    JR   Z, cardbox_x_coord
.get_x_coord        ADD  A,13
                    DJNZ get_x_coord
.cardbox_x_coord    LD   C,A
                    LD   B,0
                    POP  HL
                    POP  AF
                    RET
; *************************************************************************************


; *************************************************************************************
; Text constants

.selslot_banner     DEFM "SELECT FILE CARD AREA",0
.noflash_msg        DEFM 1,"BNo Flash Cards found in slots 1-3.",1,"B",0

.xypos              DEFM 1,"3@",0

.cardtop            defm 1, "2*C", 1, "2*E", 1, "2*E", 1, "2*E", 1, "2*E", 1, "2*E", 1, "2*E" ; Top left corner
                    defm 1, "2*E", 1, "2*E", 1, "2*E", 1, "2*E", 1, "2*E", 1, "2*E", 1, "2*F" ; Top right corner
                    defb 0
.cardmiddle         defm 1, "2*K", 1, "2*E", 1, "2*E", 1, "2*E", 1, "2*E", 1, "2*E", 1, "2*E" ; Left T-section
                    defm 1, "2*E", 1, "2*E", 1, "2*E", 1, "2*E", 1, "2*E", 1, "2*E", 1, "2*N" ; Rigth T-section
                    defb 0
.cardbottom         defm 1, "2*I", 1, "2*E", 1, "2*E", 1, "2*E", 1, "2*E", 1, "2*E", 1, "2*E" ; Bottom left corner
                    defm 1, "2*E", 1, "2*E", 1, "2*E", 1, "2*E", 1, "2*E", 1, "2*E", 1, "2*L" ; Bottom right corner
                    defb 0
.cardside           DEFM 1, "2*J", 0

.padlock            DEFM 1, 138, '=', 'Z'
                    DEFM @10001100
                    DEFM @10010010
                    DEFM @10010010
                    DEFM @10111111
                    DEFM @10111111
                    DEFM @10111111
                    DEFM @10111111
                    DEFM @10011110
                    DEFM " ", 1, "2?Z", " ", 0

.selectdevhelp      DEFM 1,"2JC", 1,"3-SC"
                    DEFM "Select card", 13, 10
                    DEFM "with either", 13, 10
                    DEFM 1,"B1", 1 ,"B ", 1, "B2", 1,"B or ", 1,"B3", 1, "B", 13, 10
                    DEFM "or", 13, 10
                    DEFM "move cursor", 13, 10
                    DEFM "over the card", 13, 10
                    DEFM 13, 10
                    DEFM 1, SD_ENT, " selects it", 0

.epromdev           DEFM 1,"2+T", "EPROM ", 0
.flashdev           DEFM 1,"2+T", "FLASH ", 0
.ramdev             DEFM 1,"2+T", "RAM ",0
.freetxt            DEFM 1,"2+T", " FREE ", 0
.appstxt            DEFM 1,"2+T", "APPLICATIONS",0
.nofilestxt         DEFM 1,"2+T", "NO FILE AREA",0
.slottxt1           DEFM "SLOT ",0
.slottxt2           DEFM ": ",0
.emptytxt           DEFM 1,"2+T", "EMPTY SLOT", 1,"2-T", 0
.selvdu             DEFM 1,"3-SC"               ; no vertical scrolling, no cursor
                    DEFM 1,"2+T",0

.SelectMenuWindow
                    DEFM 1,"2H2",1,"2-C",0     ; activate menu window, no Cursor...
.MenuBarOn          DEFM 1,"4+F+R"             ; enable flash and inverse video
                    DEFM 1,"2A",32+3,0         ; XOR 'display' menu bar (3 chars wide)
.MenuBarOff         DEFM 1,"4-F-R"             ; disable flash & set normal video
                    DEFM 1,"2A",32+3,0         ; apply 'display' menu bar (3 chars wide)