; *************************************************************************************
; EazyLink - Fast Client/Server Remote File Management with PCLINK II protocol
;
; (C) Gunther Strube (gbs@users.sourceforge.net) 1990-2005
;
; EazyLink is free software; you can redistribute it and/or modify it under the terms of the
; GNU General Public License as published by the Free Software Foundation;
; either version 2, or (at your option) any later version.
; EazyLink is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY;
; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
; See the GNU General Public License for more details.
; You should have received a copy of the GNU General Public License along with EazyLink;
; see the file COPYING. If not, write to the
; Free Software Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA 02111-1307, USA.
;
; $Id$
;
; *************************************************************************************

    MODULE EasyLink_main

; ******************************************************************************
;
;  Converted to QL Z80 Cross Assembler format, 08.03.91             ** V2
;  Improved and converted to Z88 ROM application format, 18.12.91

;  V0.241, 10.11.90 - 28.06.91                                      ** V2
;  V0.25   10.07.91                                                 ** V2
;  V0.26   15.07.91                                                 ** V2
;  V0.27   01.08.91                                                 ** V2
;  V0.271  ????????      transmitting ESC B 00 ...                 ** V2
;                        calling PCLINK II 'Hello' will also install
;                        Auto Translation and Auto CR > CRLF conversion.

;  V0.272  01.10.91      bug in Fetch_RAM_devices: 'File not found'    ** V2
;                        error when current directory for application
;                        isn't the root directory. Wrong device specifier.

;  V0.273  05.10.91      program crash if Search_filer receives timeout  ** V2
;                        on transmitting files. IX handle for serial
;                        port wasn't re-installed on timeout error.


; V3 updates and improvements:

;  V1.0    03.05.92      only 512 bytes in segment 0 are used as working buffer.
;                        system information are no longer put on a stack and then
;                        transmitted, but sent immediately on each found name.

;                        esc_h1_cmd (fetch z88 devices):
;                        wildcard is in segment 0 due to a bug in OZ.
;                        A '*' is appended to remote wildcard specifies.
;                        (request of file names and directories)

;                        a 'soft reset' of the serial port is now issued to install
;                        the defined communication parameters in the Panel.
;                        in V2 the serial port wasn't 'soft reset' which caused
;                        protocol errors since the panel parameters wasn't installed
;                        in the serial port driver (the Panel popdown does this
;                        automatically when ENTER is pressed).
;                        PC-link II don't issue a soft reset either which means
;                        that if the serial port previously had been installed with
;                        'Xon/Xoff Yes', this would cause protocol errors with the
;                        IBM PC LINK II program.
;
; V1.1                   Extended protocol with additional commands included (Multilink V2)
; 09.06.93               Split up into modules for new Z80 Cross Assembler

; 4.2                    Serial port protokol algorithms improved.
; V4.3, 03.03.95         Automatical directory creation on receiving files from outside
; V4.4                   Extended protokol fetch filename & directories commands changed:
;                        The wildcard hmust be explicitly spercified, e.g. ":ram.1/dir/*"

; V4.5, 05.09.96         ESC "v" command added: Client gets version of EasyLink Server
;                             and file protocol level
;                        ESC "x" command added: Client queries for file size.
;                        ESC "u" command added: Client queries for file Update Date Stamp
;                             ("dd-mm-yyyy hh:mm:ss" format)
;                        ESC "f" command added: Client queries for existence of file.
; 08.09.96               ESC "U" command added: Client sets (Create/Update) date
;                             stamp of file in Z88

; V4.6, 22.08.97         ESC "r" command added: Client sets EasyLink Server to delete file on Z88
;                        ESC "z" command added: Client queries EasyLink Server to
;                             update (re-load) the translation table
;                        Server release "4.6", protocol version updated to "02"

; V4.7, 07.10.97         ESC "y" command added: Client requests for Directory Create
;                        ESC "w" command added: Client requests for File Rename
;                        ESC "U" command extended: Update Date Stamp added...
; 09.10.97               ESC "g" command added: Client requests for default Device/Directory
; 18.10.97               ESC "m" command added: Client requests for estimated free memory
;
; V4.8, 27.10.97         ESC "u" command extended: Create Date Stamp added
;                        ESC "p" command added: Set System Clock
; V4.8, 17.11.97         ESC "e" command added: Get System Clock
;                        Server release "4.8", protocol version updated to "04"
;
; V4.9, 18.12.97         EazyLink appears now as a single popdown, accessed by #L.
;                        Command menu implemented in separate window which allowes:
;                             1. Toggle translation ON/OFF
;                             2. Toggle Line Feed Conversion ON/OFF
;                             3. Use std. ISO/LATIN 1 translations
;                             4. Load translations
;                             5. Quit EazyLink.
;
; V5.0, 20.12.97         Several messages were not placed in log window. Now fixed.
;                        OZ internal keyboard queue purged while using hardware scanning
;                        of keybard.


    ; Various constant & operating system definitions...

     INCLUDE "defs.asm"
     INCLUDE "stdio.def"
     INCLUDE "error.def"
     INCLUDE "integer.def"
     INCLUDE "time.def"
     INCLUDE "fileio.def"
     INCLUDE "dor.def"
     INCLUDE "syspar.def"
     INCLUDE "serintfc.def"
     INCLUDE "director.def"
     INCLUDE "screen.def"

     LIB CreateWindow
     LIB CreateDirectory
     LIB RamDevFreeSpace
     LIB createfilename

     XREF LoadTranslations
     XREF menu_banner, Command_banner
     XREF extended_synch, pclink_Synch, EscCommands, Subroutines
     XREF msg_serdmpfile_enable, msg_serdmpfile_disable
     XREF Message1, Message2, Message10, Message11, Message12, Message13, Message21, Message22
     XREF Message23, Message24, Message25, Message26, Message27, Message28
     XREF Message29, Message30, Message31, Message32, Message33, Message34
     XREF Error_Message0, Error_Message1, Error_Message2, Error_Message3
     XREF Error_Message4, Error_Message5, Error_Message6
     XREF Serial_port, BaudRate, No_parameter, Yes_Parameter, EasyLinkVersion
     XREF Check_Synch, Send_Synch, GetByte, PutByte, Getbyte_ackn
     XREF FetchBytes
     XREF Get_file_handle, Close_file
     XREF ESC_N, ESC_Y, ESC_Z
     XREF SendString
     XREF Fetch_pathname
     XREF rw_date
     XREF Use_StdTranslations
     XREF Dump_serport_in_byte, serdmpfile_in, serdmpfile_out

     XDEF ErrHandler
     XDEF Write_message
     XDEF Msg_File_Open_error, Msg_Protocol_error, Msg_file_aborted, Msg_No_Room
     XDEF Msg_Command_aborted
     XDEF Set_Traflag, Restore_Traflag
     XDEF File_open_error, System_Error, Calc_hexnibble
     XDEF Open_serialport, Close_serialport
     XDEF ESC_T_cmd1, ESC_T_cmd2, ESC_C_cmd1, ESC_C_cmd2
     XDEF ESC_V_cmd, ESC_X_cmd, ESC_U_cmd, ESC_U_cmd2, ESC_F_cmd
     XDEF ESC_Z_cmd, ESC_R_cmd, ESC_Y_cmd, ESC_W_cmd
     XDEF ESC_G_cmd2, ESC_M_cmd, ESC_P_cmd, ESC_E_cmd, ESC_M_cmd2

IF DEBUGGING
; Run EazyLink Server inside Intuition application

    ORG $4000

    JR continue_ez   ; skip popdown init code

ELSE
     ORG $C000

;
; 'EazyLink' popdown DOR datastructure.
;
.EasyLink1_DOR DEFB 0, 0, 0                          ; link to parent
               DEFB 0, 0, 0
               DEFB 0, 0, 0
               DEFB $83                              ; DOR type - application ROM
               DEFB DOREnd6-DORStart6                ; total length of DOR
.DORStart6     DEFB '@'                              ; Key to info section
               DEFB InfoEnd6-InfoStart6              ; length of info section
.InfoStart6    DEFW 0                                ; reserved...
               DEFB 'L'                              ; application key letter
               DEFB RAM_pages                        ; contiguous RAM
               DEFW 0                                ;
               DEFW 0                                ; Unsafe workspace
               DEFW 0                                ; Safe workspace
               DEFW EasyLink_entry                   ; Entry point of code in seg. 3
               DEFB 0                                ; bank binding to segment 0
               DEFB 0                                ; bank binding to segment 1
               DEFB 0                                ; bank binding to segment 2
               DEFB $3F                              ; bank binding to segment 3
               DEFB AT_Ugly | AT_Popd                ; Ugly popdown
               DEFB 0                                ; no caps lock
.InfoEnd6      DEFB 'H'                              ; Key to help section
               DEFB 12                               ; total length of help section
               DEFW EasyLink1_DOR
               DEFB $3F                              ; No topics - point to 3 zeros
               DEFW EasyLink1_DOR
               DEFB $3F                              ; No commands
               DEFW EasyLink_Notice
               DEFB $3F
               DEFB 0, 0, 0
               DEFB 'N'                              ; Key to name section
               DEFB NameEnd6-NameStart6              ; length of name
.NameStart6    DEFM "EazyLink", 0
.NameEnd6      DEFB $FF
.DOREnd6
ENDIF

.EasyLink_notice
               DEFB $7F
               DEFM "EazyLink V5.0.3 - flexible file transfer", $7F
               DEFB 0



; ***************************************************************************************************
;
; PC-Link Emulator with translation and CR > CRLF conversion de-activated
;
; We are somewhere in segment 3...
;
; Entry point for ugly popdown...
;
.EasyLink_entry
               JP   app_main
               SCF
               RET

.app_main
               LD   A,(IX+$02)                    ; IX points at information block
               CP   $20+RAM_pages                 ; get end page+1 of contiguous RAM
               JR   Z, continue_ez                ; end page OK, RAM allocated...

               LD   A,$07                         ; No Room for EazyLink, return to Index
               CALL_OZ(Os_Bye)                    ; EazyLink suicide...
.continue_ez
               LD   A,SC_Ena                      ; Enable escape detection
               CALL_OZ(Os_Esc)

               XOR  A
               LD   (MenuBarPosn),A               ; Display Menu Bar at top line the first time...
               LD   (UserToggles),A               ; Linefeed conversion OFF, Translations OFF

               CALL Appl_Main                     ; Call the code...
               JR   Kill



; *************************************************************************************
;
.Errhandler    PUSH AF
               CP   RC_susp
               JR   Z, exit_errh
               CP   RC_esc
               JR   Z, akn_esc
               CP   RC_quit
               JR   Z, kill
.exit_errh     POP  AF
               RET
.akn_esc
               LD   A,SC_ACK                      ; acknowledge ESC detection
               CALL_OZ(OS_Esc)
.Kill
               CALL Close_serialport              ; close streams to serial port...
               CALL Close_file                    ; close any opened/created file
               CALL Close_serportdump_filehandles ; close streams to serial port dump files (if open)
               CALL Restore_PanelSettings         ; restore original Panel Settings
               CALL_OZ(OS_pur)                    ; purge keyboard buffer
               XOR  A                             ; no error messages on quit
               CALL_OZ(OS_Bye)                    ; perform suicide, focus to Index...


; ***************************************************************************************************
.Appl_Main
               CALL LogWindow
               CALL CommandWindow
               CALL InitTraTable                  ; load translations file or install
               CALL InitHandles                   ; reset all I/O handles to zero
               CALL LoadTranslations              ; standard IBM - Z88 translation table.
               CALL ESC_T_cmd2                    ; No Auto translation
               CALL ESC_C_cmd2                    ; No CR conversion
               CALL Init_PanelSettings            ; set Transmit & Receive baud rates and store original values temporarily.
               CALL Open_serialport
               CALL Fetch_synch                   ; 111112 & 555556 synch and ESC cmds
               RET


; ***********************************************************************
;
; Display Command Window - use window "2"
;
.CommandWindow
               LD   A,192 | '2'
               LD   BC,$0000
               LD   DE,$081A
               LD   HL, command_banner
               CALL CreateWindow
               LD   B,0
               LD   HL, cmds
               CALL_OZ(Gn_Sop)
               RET
.cmds          DEFM 1, "2H2", 1, SD_DTS, 1, "2+T"
               DEFM " TOGGLE TRANSLATION MODE", 13, 10
               DEFM " TOGGLE LINEFEED MODE", 13, 10
               DEFM " USE ISO/IBM TRANSLATIONS", 13, 10
               DEFM " LOAD TRANSLATIONS", 13, 10
               DEFM " QUIT EAZYLINK", 13, 10
               DEFM 1, "2-T", 0


; ***********************************************************************
;
; Display Log Window - use window "3"
;
.LogWindow
               LD   A,128 | '3'
               LD   BC,$001C
               LD   DE,$083E
               LD   HL, menu_banner
               CALL CreateWindow
               RET


; *************************************************************************************
;
.DisplMenuBar  PUSH AF
               PUSH HL
               LD   HL,SelectMenuWindow
               CALL_OZ(Gn_Sop)
               LD   HL, xypos                     ; (old menu bar will be overwritten)
               CALL_OZ(Gn_Sop)
               LD   A,32                          ; display menu bar at (0,Y)
               CALL_OZ(Os_out)
               LD   A,(MenuBarPosn)               ; get Y position of menu bar
               ADD  A,32                          ; VDU...
               CALL_OZ(Os_out)
               LD   HL,MenuBarOn                  ; now display menu bar at cursor
               CALL_OZ(Gn_Sop)
               POP  HL
               POP  AF
               RET
.xypos         DEFM 1, "3@", 0
.SelectMenuWindow
               DEFM 1, "2H2", 1, "2-C", 0         ; activate menu window, no Cursor...
.MenuBarOn     DEFM 1, "2+R"                      ; set reverse video
               DEFM 1, "2A", 32+$1A, 0            ; XOR 'display' menu bar (20 chars wide)


; *************************************************************************************
;
.RemoveMenuBar PUSH AF
               PUSH HL
               LD   HL,SelectMenuWindow
               CALL_OZ(Gn_Sop)
               LD   HL, xypos                     ; (old menu bar will be overwritten)
               CALL_OZ(Gn_Sop)
               LD   A,32                          ; display menu bar at (0,Y)
               CALL_OZ(Os_out)
               LD   A,(MenuBarPosn)               ; get Y position of menu bar
               ADD  A,32                          ; VDU...
               CALL_OZ(Os_out)
               LD   HL,MenuBarOff                 ; now display menu bar at cursor
               CALL_OZ(Gn_Sop)
               POP  HL
               POP  AF
               RET
.MenuBarOff    DEFM 1, "2-R"                      ; set reverse video
               DEFM 1, "2A", 32+$1A, 0            ; apply 'display' menu bar (20 chars wide)


; *************************************************************************************
;
.Poll
.main_loop     CALL DisplMenuBar
               CALL ReadKeyboard
               CALL RemoveMenuBar
               LD   HL, MenuBarPosn
               CP   IN_ENT                        ; no shortcut cmd, ENTER ?
               JR   Z, get_command
               CP   IN_DWN                        ; Cursor Down ?
               JR   Z, MVbar_down
               CP   IN_UP                         ; Cursor Up ?
               JR   Z, MVbar_up
               CP   EOT
               CALL Z,EnableSerportLogging        ; <>D, Enable Serial port logging
               CP   SUB
               CALL Z,DisableSerportLogging         ; <>Z, Disable Serial port logging
               JR   main_loop                     ; ignore keypress, get another...

.MVbar_down    LD   A,(HL)                        ; get Y position of menu bar
               CP   4                             ; has m.bar already reached bottom?
               JR   Z,Mbar_topwrap
               INC  A
               LD   (HL),A                        ; update new m.bar position
               JR   main_loop                     ; display new m.bar position

.Mbar_topwrap  LD   A,0
               LD   (HL),A
               JR   main_loop

.MVbar_up      LD   A,(HL)                        ; get Y position of menu bar
               CP   0                             ; has m.bar already reached top?
               JR   Z,Mbar_botwrap
               DEC  A
               LD   (HL),A                        ; update new m.bar position
               JR   main_loop

.Mbar_botwrap  LD   A,4
               LD   (HL),A
               JR   main_loop

.get_command   PUSH HL
               LD   A,(HL)                        ; use menu bar position as index to command
               CALL ActivateCommand               ; then execute...
               POP  HL
               JR   main_loop


; ******************************************************************************************
.ReadKeyboard
               LD   HL, -1
               LD   (PopDownTimeout),HL           ; reset timeout to approx 10 minutes
.ReadKeyboard_loop
               LD   BC,5                          ; keyboard polled, now check serial port...
               LD   IX,(serport_handle)
               CALL_OZ (Os_Gbt)                   ; get a byte from serial port
               CALL C, Errhandler                 ; no byte available (or ESC pressed)...
               CALL NC,Dump_serport_in_byte       ; save a copy to the log dump file
               JR   NC, evaluate_byte             ; then let it be processed by main loop.

               CALL C,ScanKeyboard                ; scan the keyboard, if no byte from serport
               CP   0
               RET  NZ                            ; Fc = 0, Fz = 0, return Key Code in A...
               JR   ReadKeyboard_loop
.evaluate_byte                                    ; byte available from serial port
               POP  HL                            ; remove this RETurn address
               POP  HL                            ; get RETurn address to Fetch_synch
               JP   (HL)


; ******************************************************************************************
;
; Scan keyboard, and return key codes for <ENTER>, <UP> and <DOWN> in A register.
; Return 0, if other keys are pressed, or keyboard timeout.
;
.ScanKeyboard  LD   BC,1
               CALL_OZ(OS_Tin)
               JR   C, CheckKeybTimeout
               CP   0
               JR   Z, ScanKeyboard
               CP   IN_DWN
               RET  Z
               CP   IN_UP
               RET  Z
               CP   IN_ENT
               RET  Z
               CP   EOT                 ; <>D
               RET  Z
               CP   SUB                 ; <>Z
               RET  Z
               XOR  A
               RET

.CheckKeybTimeout
               CP   RC_Time
               JR   Z, UpdateTimeout
               SCF
               CALL Errhandler
               RET                      ; return error to caller of ScanKeyboard
.UpdateTimeout
               LD   HL,(PopDownTimeout)
               LD   BC,5
               SBC  HL,BC
               LD   (PopDownTimeout),HL
               CALL C, ShutDown         ; 10 minute timeout reached, switch off
               XOR  A                   ; return 0, no valid key pressed
               RET
.ShutDown      CALL_OZ(OS_Off)
               RET


; ******************************************************************************************
;
; Activate command defined by index in A
;
.ActivateCommand
               RLCA                               ; index word boundary...
               LD   B,0
               LD   C,A
               LD   HL,Command_lookup             ; base of table
               ADD  HL,BC                         ; point at command index
               LD   E,(HL)                        ; get pointer to subroutine
               INC  HL
               LD   D,(HL)
               EX   DE,HL                         ; HL points at command subroutine
               JP   (HL)                          ; activate

.Command_lookup
               DEFW User_ToggleTranslation        ; toggle File Translation
               DEFW User_ToggleLineFeed           ; toggle File Linefeed Conversion
               DEFW User_StdTranslations          ; Use explicitly the ISO/IBM translations
               DEFW User_LoadTranslations         ; re-load "translate.dat" translations
               DEFW Kill                          ; Terminate EazyLink
               DEFW disp_running


; ******************************************************************************************
;
.User_ToggleTranslation
               PUSH HL
               LD   HL, UserToggles
               LD   A,2
               XOR  (HL)
               LD   (HL),A
               BIT  1,(HL)
               PUSH AF
               CALL Z,ESC_T_cmd2                  ; File Translation OFF
               POP  AF
               CALL NZ,ESC_T_cmd1                 ; File Translation ON
               POP  HL
               JR   disp_running


; ******************************************************************************************
;
.User_ToggleLineFeed
               PUSH HL
               LD   HL, UserToggles
               LD   A,1
               XOR  (HL)
               LD   (HL),A
               BIT  0,(HL)
               PUSH AF
               CALL Z,ESC_C_cmd2                  ; CR conversion OFF
               POP  AF
               CALL NZ,ESC_C_cmd1                 ; CR conversion ON
               POP  HL
               JR   disp_running


; ******************************************************************************************
;
.User_StdTranslations
               CALL Use_StdTranslations           ; Use ISO/IBM translations...
               JR   disp_running


; ******************************************************************************************
;
.User_LoadTranslations
               CALL LoadTranslations              ; Load external "translate.dat" file...
.disp_running  LD   HL,message1                   ; 'Running'
               CALL Write_message
               RET


; ***********************************************************************
.Fetch_synch
               LD   HL,message1                   ; 'Running'
               CALL Write_message
.fetch_synch_loop
               CALL Poll                          ; get byte from serial port (and manage menu)
               CP   $01                           ; extended command protocol synch?
               JR   NZ,check_pclink_synch

               LD   IY,extended_synch
               LD   H,(IY+0)                      ; start and body of sequense...
               LD   L,(IY+1)                      ; end of sequense...
               CALL Check_synch                   ; is it really a synch?
               RET  C                             ; return on system error
               JR   Z,Fetch_synch_loop            ; timeout or bad synch...
               CALL Send_synch                    ; acknowledge synch to terminal
               RET  C                             ; return on system error
               JR   Z,Fetch_synch_loop            ; timeout - communication stopped
               CALL Extended_ESC_commands         ; synch sent - wait for commands
               RET  C                             ; return on system error (ESC key)
               JR   Z,Fetch_synch                 ; command executed, wait for new
               RET                                ; ESC "Q" command received...

.check_pclink_synch
               CP   $05
               JR   NZ,Fetch_synch_loop           ; ignore byte...
               LD   IY,pclink_synch
               LD   H,(IY+0)                      ; start and body of sequense...
               LD   L,(IY+1)                      ; end of sequense...
               CALL Check_synch                   ; is it really a synch?
               RET  C                             ; return on system error
               JR   Z,Fetch_synch_loop            ; timeout or bad synch...
               CALL Send_synch                    ; acknowledge - B = length of synch
               RET  C                             ; return on system error
               JR   Z,Fetch_synch_loop            ; timeout - communication stopped
               CALL Pclink_ESC_commands           ; synch sent - wait for commands
               RET  C                             ; return on system error
               JR   Z,Fetch_synch                 ; command executed, wait for new
               RET                                ; ESC "Q" command received...



; ***********************************************************************
.Extended_ESC_commands                            ; synch sent - wait for commands
               CALL FetchBytes
               RET  C
               RET  Z
               CP   0
               LD   A,B
               JP   Z, Msg_Protocol_error         ; no ESC id, protocol error...
               CALL EscCommand                    ; Find command, and execute
               RET

.PClink_ESC_commands                              ; synch sent - wait for commands
               CALL Getbyte_ackn
               RET  C
               RET  Z
               CP   ESC
               JP   NZ, Msg_Protocol_error        ; no ESC id, protocol error...
               CALL Getbyte_ackn
               RET  C
               RET  Z
               CALL EscCommand                    ; Find command, and execute
               RET


.EscCommand    LD   HL,EscCommands
               LD   B, TotalOfCmds                ; total of different commands
               LD   C,0                           ; offset counter
.find_command_loop
               CP   (HL)
               JR   Z,found_command
               INC  C
               INC  HL
               DJNZ,find_command_loop
               XOR  A
               RET

.found_command CALL RemoveMenuBar                 ; remove menu bar while serial port activity...
               LD   B,0                           ; communication commences...
               SLA  C                             ; offset * 2 (find word boundary)
               LD   HL,subroutines
               ADD  HL,BC                         ; offset to address
               LD   E,(HL)                        ; subroutine returns to calling
               INC  HL
               LD   D,(HL)                        ; program by issuing a RET.
               EX   DE,HL
               JP   (HL)                          ; - go to subroutine...

.GreyCommandWindow
               PUSH HL
               LD   HL, greycmdwin
               CALL_OZ(GN_Sop)
               POP  HL
               RET
.greycmdwin    DEFM 1, "2H2", 1, "2G+", 0



; ***********************************************************************
.Calc_HexNibble
               CP   '@'                           ; digit >= "A"?
               JR   NC,hex_alpha                  ; digit is in interval "A" - "F"
               SUB  48                            ; digit is in interval "0" - "9"
               RET
.hex_alpha     SUB  55
               RET




; ***********************************************************************
.File_open_error
               CALL Msg_File_open_Error
               CALL Getbyte                       ; get a byte from remote computer
               RET  C                             ; up; ups... not possible anyway!
               RET  Z                             ; ...
               LD   A,$01                         ; signal error to remote computer ...
               CALL Putbyte
               RET  C
               XOR  A                             ; C = 0, Z = 1
               RET                                ; indicate continue in main loop



; ************************************************************
; Get EasyLink Version and file protocol level
;
; Client:      ESC "v"
;
; Server:      ESC "N" <Version> ESC "Z"
;
.ESC_V_cmd     LD   HL,message21
               CALL Write_message
               LD   HL,ESC_N
               CALL SendString
               JR   C, esc_v_aborted
               JR   Z, esc_v_aborted
               LD   HL,EasyLinkVersion
               CALL SendString
               JR   C, esc_v_aborted
               JR   Z, esc_v_aborted
               LD   HL,ESC_Z
               CALL SendString
               JR   C, esc_v_aborted
               JR   Z, esc_v_aborted
               XOR  A
               RET

.esc_v_aborted CALL Msg_Command_aborted
               XOR A
               RET


; ************************************************************
; Get size of file
;
; Client:      ESC "x" <Filename> ESC "Z"
;
; Server:      ESC "N" <Size> ESC "Z"   (File found)
;              ESC "Z"                  (File not found)
;
.ESC_X_cmd     CALL Set_TraFlag
               CALL Fetch_pathname                ; load filename into filename_buffer
               CALL Restore_TraFlag
               JR   C,esc_x_aborted
               JR   Z,esc_x_aborted               ; timeout - communication stopped
               LD   HL, Message22
               CALL Write_message                 ; "Get size of file."
               LD   HL,filename_buffer
               CALL Write_message                 ; write filename to screen

               LD   A, op_in                      ; open file for transfer...
               LD   D,H
               LD   E,L                           ; (explicit filename overwrite original fname)
               CALL Get_file_handle               ; open file
               JR   C, file_not_found             ; ups, file not available
               LD   (file_handle),IX

               LD   A, FA_EXT
               LD   DE,0
               CALL_OZ(OS_Frm)                    ; get size of file
               LD   (File_ptr),BC
               LD   (File_ptr+2),DE               ; low byte, high byte sequense
               CALL Close_file                    ; close file

               LD   HL, File_ptr                  ; convert 32bit integer
               LD   DE, filename_buffer           ; to an ASCII string
               LD   A, 1                          ; disable zero blanking
               CALL_OZ(GN_Pdn)
               XOR  A
               LD   (DE),A                        ; null-terminate string

               LD   HL,ESC_N
               CALL SendString
               JR   C, esc_x_aborted
               JR   Z, esc_x_aborted

               LD   HL,filename_buffer            ; write File length as ASCII string to Client
               CALL SendString
               JR   C, esc_x_aborted
               JR   Z, esc_x_aborted
.file_not_found
               LD   HL,ESC_Z
               CALL SendString
               JR   C, esc_x_aborted
               JR   Z, esc_x_aborted
               XOR  A
               RET

.esc_x_aborted CALL Msg_Command_aborted
               XOR A
               RET


; ************************************************************
; Get <Create> and <Update> Date stamp of file
;
; Client:      ESC "u" <Filename> ESC "Z"
;
; Server:      ESC "N" <Create Date Stamp>        (File found)
;              ESC "N" <Update Date Stamp
;              ESC "Z"                            or
;
;              ESC "Z"                            (File not found)
;
.ESC_U_cmd     CALL Set_TraFlag
               CALL Fetch_pathname                ; load filename into filename_buffer
               CALL Restore_TraFlag
               JP   C,esc_u_aborted
               JP   Z,esc_u_aborted               ; timeout - communication stopped
               LD   HL, Message23
               CALL Write_message                 ; "Get date stamps"
               LD   HL,filename_buffer
               CALL Write_message                 ; write filename to screen

               LD   DE,creation_date
               LD   H,dr_rd
               LD   L,'C'                         ; get Create Date Stamp
               CALL rw_date                       ; name of file in <filename_buffer>
               JR   C, file_not_avail             ; ups, file not available

               LD   A, @10110001                  ; Century output, European format, Leading zeroes
               LD   C, '/'                        ; use C as interfield delimeter
               LD   B, 0                          ; Numeric month
               LD   HL, Creation_date+3           ; pointer to internal date
               LD   DE, file_buffer               ; pointer to ASCII date, DD-MM-YYYY
               CALL_OZ(Gn_Pdt)
               LD   HL, Creation_date             ; pointer to internal time, DE pointer to ASCII time
               LD   A,@00100011                   ; begin with a space, Leading zeroes, display seconds
               CALL_OZ(Gn_Ptm)                    ; convert internal time to ASCII...
               XOR  A
               LD   (DE),A                        ; null-terminate string

               LD   HL,ESC_N
               CALL SendString
               JR   C, esc_u_aborted
               JR   Z, esc_u_aborted

               LD   HL,file_buffer                ; write Date Stamp ASCII string to Client
               CALL SendString
               JR   C, esc_u_aborted
               JR   Z, esc_u_aborted

               LD   DE,update_date
               LD   H,dr_rd
               LD   L,'U'                         ; get Update Date Stamp
               CALL rw_date                       ; name of file in <filename_buffer>
               JR   C, file_not_avail             ; ups, file not available

               LD   A, @10110001                  ; Century output, European format, Leading zeroes
               LD   C, '/'                        ; use C as interfield delimeter
               LD   B, 0                          ; Numeric month
               LD   HL, Update_date+3             ; pointer to internal date
               LD   DE, file_buffer               ; pointer to ASCII date, DD-MM-YYYY
               CALL_OZ(Gn_Pdt)
               LD   HL, Update_date               ; pointer to internal time, DE pointer to ASCII time
               LD   A,@00100011                   ; begin with a space, Leading zeroes, display seconds
               CALL_OZ(Gn_Ptm)                    ; convert internal time to ASCII...
               XOR  A
               LD   (DE),A                        ; null-terminate string

               LD   HL,ESC_N
               CALL SendString
               JR   C, esc_u_aborted
               JR   Z, esc_u_aborted

               LD   HL,file_buffer                ; write Date Stamp ASCII string to Client
               CALL SendString
               JR   C, esc_u_aborted
               JR   Z, esc_u_aborted
.file_not_avail
               LD   HL,ESC_Z
               CALL SendString
               JR   C, esc_u_aborted
               JR   Z, esc_u_aborted
               XOR  A
               RET

.esc_u_aborted CALL Msg_Command_aborted
               XOR A
               RET



; ************************************************************
; Set File Create & Update Date stamp of file
; Format of Date Stamp: "dd/mm/yyyy hh:nn:ss"
;
; Client:      ESC "U" <Filename>
;              ESC "N" <CreateDateStamp>
;              ESC "N" <UpdateDateStamp>
;              ESC "Z"
;
; Server:      ESC "Y"                            (Date stamp executed)
;              ESC "Z"                            (File not found)
;
.ESC_U_cmd2    CALL Set_TraFlag
               CALL Fetch_pathname                ; load filename into filename_buffer
               CALL Restore_TraFlag
               JR   C,esc_u_aborted
               JR   Z,esc_u_aborted               ; timeout - communication stopped
               LD   HL, Message25
               CALL Write_message                 ; "Set Date Stamp."

               LD   HL,file_buffer                ; get create date stamp
.date1_loop    CALL Getbyte
               JR   C,esc_u_aborted
               JR   Z,esc_u_aborted               ; timeout - communication stopped
               CP   ESC
               JR   Z,enddate1_ident
               LD   (HL),A
               INC  HL
               JR   date1_loop
.enddate1_ident
               CALL Getbyte                       ; ESC 'N'
               JR   C,esc_u_aborted
               JR   Z,esc_u_aborted               ; timeout - communication stopped
               LD   (HL), 0                       ; Null-terminate received date stamp.

               LD   HL,DirName_stack              ; get update date stamp
.date2_loop    CALL Getbyte
               JR   C,esc_u_aborted
               JR   Z,esc_u_aborted               ; timeout - communication stopped
               CP   ESC
               JR   Z,enddate2_ident
               LD   (HL),A
               INC  HL
               JR   date2_loop
.enddate2_ident
               CALL Getbyte                       ; ESC 'N'
               JR   C,esc_u_aborted
               JR   Z,esc_u_aborted               ; timeout - communication stopped
               LD   (HL), 0                       ; Null-terminate received date stamp.

               LD   HL,filename_buffer
               CALL_OZ(Gn_Sop)                    ; Filename...
               LD   HL, comma
               CALL_OZ(Gn_Sop)
               CALL_OZ(Gn_Nln)
               LD   HL, file_buffer
               CALL_OZ(Gn_sop)                    ; Create date stamp
               LD   HL, comma
               CALL_OZ(Gn_Sop)
               LD   HL, DirName_stack
               CALL_OZ(Gn_sop)                    ; Update Date Stamp
               CALL Write_Message

               ld   hl, file_buffer               ; convert ASCII date Stamp to internal format
               ld   de, Creation_date+3           ; result at (de)
               ld   b, 10                         ; read max. 10 characters
               ld   c, '/'                        ; delimeter
               ld   a, @00110000                  ; european format, '/' delimted
               call_oz(Gn_Gdt)                    ; convert ASCII date to internal format

               ld   hl, file_buffer+11            ; point at ASCII time stamp
               ld   de, Creation_date
               call_oz(Gn_Gtm)                    ; convert ASCII time to internal format

               ld   hl, DirName_stack             ; convert ASCII date Stamp to internal format
               ld   de, Update_date+3             ; result at (de)
               ld   b, 10                         ; read max. 10 characters
               ld   c, '/'                        ; delimeter
               ld   a, @00110000                  ; european format, '/' delimted
               call_oz(Gn_Gdt)                    ; convert ASCII date to internal format

               ld   hl, DirName_stack+11          ; point at ASCII time stamp
               ld   de, Update_date
               call_oz(Gn_Gtm)                    ; convert ASCII time to internal format

               LD   DE, Creation_date
               LD   H, dr_wr
               LD   L, 'C'                        ; Set Create Date Stamp
               CALL rw_date                       ; name of file in <filename_buffer>
               JP   C, file_not_avail             ; ups, file not available

               LD   DE, Update_date
               LD   H, dr_wr
               LD   L, 'U'                        ; Set Update Date Stamp
               CALL rw_date                       ; name of file in <filename_buffer>

               LD   HL,ESC_Y                      ; Signal "Date Stamp executed"
               CALL SendString
               JP   C, esc_u_aborted
               JP   Z, esc_u_aborted
               XOR  A
               RET
.comma         DEFM ", ", 0



; ************************************************************
; Set System Clock
;
; Client:      ESC "p" <System Date>              "dd/mm/yyyy"
;              ESC "N" <System Time>              "hh:nn:ss"
;              ESC "Z"
;
; Server:      ESC "Y"                            (System Time is set)
;              ESC "Z"                            (Illegal parameters)
;
.ESC_p_cmd     LD   HL, Message32
               CALL Write_message                 ; "Set System Clock."

               CALL Fetch_pathname                ; Get Ascii Date
               JR   C,esc_p_aborted
               JR   Z,esc_p_aborted               ; timeout - communication stopped

               ld   hl, filename_buffer           ; convert ASCII date Stamp to internal format
               ld   de, Creation_date+3           ; result at (de)
               ld   b, 10                         ; read max. 10 characters
               ld   c, '/'                        ; delimeter
               ld   a, @00110000                  ; european format, '/' delimted
               call_oz(Gn_Gdt)                    ; convert ASCII date to internal format

               CALL Fetch_pathname                ; Get Ascii Time
               JR   C,esc_p_aborted
               JR   Z,esc_p_aborted               ; timeout - communication stopped

               ld   hl, filename_buffer           ; point at ASCII time stamp
               ld   de, Creation_date
               call_oz(Gn_Gtm)                    ; convert ASCII time to internal format

               CALL SetSystemClock                ; Set the Z88 clock, using Creation Date setting
               JR   C, illegal_datetime_format    ; System Clock has been set

               LD   HL,ESC_Y                      ; Signal "System Clock has been set"
               CALL SendString
               JR   C, esc_p_aborted
               JR   Z, esc_p_aborted
               XOR  A
               RET

.illegal_datetime_format

               LD   HL,ESC_Z                      ; Signal "Date/Time parameter illegal"
               CALL SendString
               JR   C, esc_p_aborted
               JR   Z, esc_p_aborted
               XOR  A
               RET
.esc_p_aborted CALL Msg_Command_aborted
               XOR A
               RET


; ************************************************************
; Set System Clock
;
.SetSystemClock
               LD   HL, routine
               LD   DE, File_buffer
               LD   BC, routine_end - routine
               LDIR                               ; copy routine to segment 0...
               CALL File_buffer                   ; and execute...
               PUSH AF
               CALL_OZ(Os_pur)                    ; Purge keyboard buffer to
               POP  AF                            ; get system timers working
               RET                                ; again
.routine
               LD   HL, Creation_Date+3
               CALL_OZ(Gn_Pmd)
               RET  C
               LD   HL, Creation_Date
               CALL_OZ(Gn_Pmt)
               RET
.routine_end



; ************************************************************
; Get Z88 System Clock
;
; Client:      ESC "e"
;
; Server:      ESC "N" <System Clock Date>
;              ESC "N" <System Clock Time>
;              ESC "Z"
;
.ESC_E_cmd     LD   HL, Message33
               CALL Write_message                 ; "Get System Clock"

               LD   DE, creation_date
               CALL_OZ(Gn_Gmd)                    ; store machine date at (DE)

               LD   A, @10110001                  ; Century output, European format, Leading zeroes
               LD   C, '/'                        ; use C as interfield delimeter
               LD   B, 0                          ; Numeric month
               LD   HL, Creation_date             ; pointer to internal date
               LD   DE, file_buffer               ; pointer to ASCII date, DD-MM-YYYY
               CALL_OZ(Gn_Pdt)
               XOR  A
               LD   (DE),A                        ; null-terminate ASCII

               LD   HL,ESC_N
               CALL SendString
               JR   C, esc_e_aborted
               JR   Z, esc_e_aborted

               LD   HL, file_buffer
               CALL SendString                    ; ESC "N" <System Date>
               JR   C, esc_e_aborted
               JR   Z, esc_e_aborted

               LD   DE, creation_date
               CALL_OZ(Gn_Gmt)                    ; store machine time at (DE)

               LD   HL, Creation_date             ; pointer to internal time
               LD   DE, file_buffer               ; pointer to write Ascii version...
               LD   A,@00100001                   ; Leading zeroes, display seconds
               CALL_OZ(Gn_Ptm)                    ; convert internal time to ASCII...
               XOR  A
               LD   (DE),A                        ; null-terminate string

               LD   HL,ESC_N
               CALL SendString
               JR   C, esc_e_aborted
               JR   Z, esc_e_aborted

               LD   HL,file_buffer                ; ESC "N" <System Time>
               CALL SendString
               JR   C, esc_e_aborted
               JR   Z, esc_e_aborted

               LD   HL,ESC_Z                      ; ESC "Z" - end of Date/time strings
               CALL SendString
               JR   C, esc_e_aborted
               JR   Z, esc_e_aborted
               XOR  A
               RET

.esc_e_aborted CALL Msg_Command_aborted
               XOR A
               RET



; ************************************************************
; Check for existence of file
;
; Client:      ESC "f" <Filename> ESC "Z"
;
; Server:      ESC "Y"                  (File found)
;              ESC "Z"                  (File not found)
;
.ESC_F_cmd     LD   HL, Message24
               CALL Write_message                 ; "File exist?"
               CALL Set_TraFlag
               CALL Fetch_pathname                ; load filename into filename_buffer
               CALL Restore_TraFlag
               JR   C,esc_f_aborted
               JR   Z,esc_f_aborted               ; timeout - communication stopped

               LD   HL,filename_buffer
               CALL Write_message                 ; write filename to screen

               LD   A, op_in                      ; open file for transfer...
               LD   D,H
               LD   E,L                           ; (explicit filename overwrite original fname)
               CALL Get_file_handle               ; open file
               JR   C, file_not_exist             ; ups, file not available
               LD   (file_handle),IX
               CALL Close_file                    ; close file

               LD   HL,ESC_Y                      ; Signal "File exist!"
               CALL SendString
               JR   C, esc_f_aborted
               JR   Z, esc_f_aborted
               XOR  A
               RET
.file_not_exist
               LD   HL,ESC_Z                      ; Signal "File does not exist!"
               CALL SendString
               JR   C, esc_f_aborted
               JR   Z, esc_f_aborted
               XOR  A
               RET
.esc_f_aborted CALL Msg_Command_aborted
               XOR A
               RET



; ************************************************************
; Rename Z88 filename
;
; Client:      ESC "w" <OrigFilename>
;              ESC "N" <NewFilename>
;              ESC "Z"
;
; Server:      ESC "Y"                  (File renamed)
;              ESC "Z"                  (Filename invalid or I/O error)
;
.ESC_W_cmd     LD   HL, Message29
               CALL Write_message                 ; "Rename file "
               CALL Set_TraFlag
               CALL Fetch_pathname                ; load filename into filename_buffer
               CALL Restore_TraFlag
               JR   C,esc_w_aborted
               JR   Z,esc_w_aborted               ; timeout - communication stopped
               LD   B,0
               LD   HL, filename_buffer
               CALL_OZ(Gn_Sop)
               LD   HL, to_msg                    ; " to "
               CALL_OZ(Gn_Sop)
               CALL Write_message                 ; display filename...

               LD   HL,file_buffer                ; get local filename
.locfile_loop  CALL Set_TraFlag
               CALL Getbyte
               CALL Restore_TraFlag
               JR   C,esc_w_aborted
               JR   Z,esc_w_aborted               ; timeout - communication stopped
               CP   ESC
               JR   Z,endof_locfile
               LD   (HL),A
               INC  HL
               JR   locfile_loop
.endof_locfile CALL Getbyte                       ; ESC 'Z'
               JR   C,esc_w_aborted
               JR   Z,esc_w_aborted               ; timeout - communication stopped
               LD   (HL), 0                       ; Null-terminate received filename.

               LD   HL,file_buffer
               CALL Write_message                 ; display local filename

               LD   HL, filename_buffer           ; point at original filename
               LD   DE, file_buffer               ; point at new, local filename
               CALL_OZ(Gn_Ren)
               JR   C, not_renamed

               LD   HL,ESC_Y                      ; Signal "File renamed"
               CALL SendString
               JR   C, esc_w_aborted
               JR   Z, esc_w_aborted
               XOR  A
               RET
.not_renamed
               LD   HL,ESC_Z                      ; Signal "Couldn't rename file"
               CALL SendString
               JR   C, esc_w_aborted
               JR   Z, esc_w_aborted
               XOR  A
               RET
.esc_w_aborted CALL Msg_Command_aborted
               XOR A
               RET

.to_msg        DEFM " to ", 0



; ************************************************************
; Create Z88 directory
;
; Client:      ESC "y" <DirectoryPath> ESC "Z"
;
; Server:      ESC "Y"                  (Directory created)
;              ESC "Z"                  (Directory path invalid or in use)
;
.ESC_Y_cmd     LD   HL, Message28
               CALL Write_Message                 ; "Delete file/dir "

               CALL Set_TraFlag
               CALL Fetch_pathname                ; load filename into filename_buffer
               CALL Restore_TraFlag
               JR   C,esc_y_aborted
               JR   Z,esc_y_aborted               ; timeout - communication stopped
               LD   B,0
               LD   HL, filename_buffer
               CALL Write_message                 ; display filename...

               LD   B, 0
               CALL CreateDirectory
               JR   C, dir_in_use

               LD   HL,ESC_Y                      ; Signal "Directory created"
               CALL SendString
               JR   C, esc_y_aborted
               JR   Z, esc_y_aborted
               XOR  A
               RET
.dir_in_use
               LD   HL,ESC_Z                      ; Signal "Couldn't create/in use"
               CALL SendString
               JR   C, esc_y_aborted
               JR   Z, esc_y_aborted
               XOR  A
               RET
.esc_y_aborted CALL Msg_Command_aborted
               XOR A
               RET



; ************************************************************
; Delete Z88 file or directory
;
; Client:      ESC "r" <Filename> ESC "Z"
;
; Server:      ESC "Y"                  (File found and deleted)
;              ESC "Z"                  (File not found)
;
.ESC_R_cmd     LD   HL, Message27
               CALL Write_Message                 ; "Delete file/dir "

               CALL Set_TraFlag
               CALL Fetch_pathname                ; load filename into filename_buffer
               CALL Restore_TraFlag
               JR   C,esc_r_aborted
               JR   Z,esc_r_aborted               ; timeout - communication stopped
               LD   HL, filename_buffer
               CALL Write_message                 ; display filename...

               LD   B,0
               LD   HL, filename_buffer
               CALL_OZ(Gn_Del)                    ;
               JR   C, file_in_use                ; ups, file not available or in use

               LD   HL,ESC_Y                      ; Signal "File/Directory deleted"
               CALL SendString
               JR   C, esc_r_aborted
               JR   Z, esc_r_aborted
               XOR  A
               RET
.file_in_use
               LD   HL,ESC_Z                      ; Signal "File does not exist/in use"
               CALL SendString
               JR   C, esc_r_aborted
               JR   Z, esc_r_aborted
               XOR  A
               RET
.esc_r_aborted CALL Msg_Command_aborted
               XOR A
               RET


; ************************************************************
; Get RAM defaults
;
; Client:      ESC "g"
;
; Server:      ESC "N" <Default Device>      (Panel Default Device)
;              ESC "N" <Default Directory>   (Panel Default Directory)
;              ESC "Z"
;
.ESC_G_cmd2    LD   HL, Message30
               Call Write_Message                 ; "Get Default Dev/Dir"

               LD    A, 255
               LD   BC, PA_Dev                    ; Read default device
               LD   DE, file_buffer               ; buffer for device name
               CALL Fetch_Parameter
               LD   B,0
               LD   C,A
               EX   DE,HL
               ADD  HL,BC
               LD   (HL),0                        ; null-terminate device name

               LD   HL,ESC_N
               CALL SendString
               JR   C, esc_g2_aborted
               JR   Z, esc_g2_aborted

               LD   HL,file_buffer                ; Send default device to Client
               CALL SendString
               JR   C, esc_g2_aborted
               JR   Z, esc_g2_aborted

               LD    A, 255
               LD   BC, PA_Dir                    ; Read default directory
               LD   DE, file_buffer               ; buffer for device name
               CALL Fetch_Parameter
               LD   B,0
               LD   C,A
               EX   DE,HL
               ADD  HL,BC
               LD   (HL),0                        ; null-terminate device name

               LD   HL,ESC_N
               CALL SendString
               JR   C, esc_g2_aborted
               JR   Z, esc_g2_aborted

               LD   HL,file_buffer                ; Send default device to Client
               CALL SendString
               JR   C, esc_g2_aborted
               JR   Z, esc_g2_aborted

               LD   HL,ESC_Z
               CALL SendString                    ; Default strings transmitted
               JR   C, esc_g2_aborted
               JR   Z, esc_g2_aborted
               XOR  A
               RET

.esc_g2_aborted
               CALL Msg_Command_aborted
               XOR A
               RET


; ************************************************************
; Get estimated free RAM memory
;
; Client:      ESC "m"
;
; Server:      ESC "N" <FreeMemory>          (Estimated free memory in bytes)
;              ESC "Z"
;
.ESC_M_cmd     LD   HL, Message31
               Call Write_Message                 ; "Get Estimated Free RAM"
.global_free_space
               CALL TotalFreeSpace                ; return DE = free pages in system
.send_free_bytes
               LD   B,E
               LD   C,0
               LD   E,D
               LD   D,0                           ; <free pages> * 256
               LD   (File_ptr),BC
               LD   (File_ptr+2),DE               ; low byte, high byte sequense

               LD   HL, File_ptr                  ; convert 32bit integer
               LD   DE, filename_buffer           ; to an ASCII string
               LD   A, 1                          ; disable zero blanking
               CALL_OZ(GN_Pdn)
               XOR  A
               LD   (DE),A                        ; null-terminate string

               LD   HL,ESC_N
               CALL SendString                    ; String transmitted
               JR   C, esc_m_aborted
               JR   Z, esc_m_aborted

               LD   HL,filename_buffer            ; Send string to Client
               CALL SendString
               JR   C, esc_m_aborted
               JR   Z, esc_m_aborted
.no_Ram_Device
               LD   HL,ESC_Z
               CALL SendString                    ; String transmitted
               JR   C, esc_m_aborted
               JR   Z, esc_m_aborted
               XOR  A
               RET
.esc_m_aborted
               CALL Msg_Command_aborted
               XOR A
               RET


; ************************************************************
; Get explicit free memory in specified RAM card slot
;
; <RamDeviceNumber> = "0", "1", "2", "3" or "-" (all)
;
; Client:      ESC "M" <RamDeviceNumber> ESC "Z"
;
; Server:      ESC "N" <FreeMemory>          (RAM device found, free memory in bytes)
;              ESC "Z"
;                                  or
;              ESC "Z"                       (RAM device not found)
;
.ESC_M_cmd2    LD   HL, Message34
               Call Write_Message            ; "Get Explicit Free RAM"

               CALL Fetch_pathname           ; load filename into filename_buffer
               JR   C,esc_m_aborted
               JR   Z,esc_m_aborted          ; timeout - communication stopped

               LD   A,(filename_buffer)      ; get RAM device number
               CP   '-'
               JR   Z, global_free_space     ; request for global free space

               SUB  48
               CALL RamDevFreeSpace
               JR   C, no_Ram_Device         ; RAM device not available...
               JR   send_free_bytes


; ************************************************************
;
; Scan all slots for RAM Cards, and get total amount of free
; space.
;
; IN:
;    -
; OUT:
;    DE = total free 256 bytes pages in system.
;
.TotalFreeSpace
               PUSH AF
               PUSH BC
               PUSH HL

               LD   BC,$0400                      ; scan all 4 slots, 0 - 3 ...
               LD   HL,0
.scan_ram_loop
               LD   A,C
               CALL RamDevFreeSpace
               JR   C, scan_next_Ram
               ADD  HL,DE                         ; add pages to sum of all pages
               INC  C
.scan_next_Ram DJNZ scan_ram_loop
               EX   DE,HL

               POP  HL
               POP  BC
               POP  AF
               RET


; ************************************************************
;
; Update translation table (re-load from "/translate.dat")
;
; Client:      ESC "Z"
;
.ESC_Z_cmd     LD   HL, Message26
               CALL Write_message                 ; "Update translations"
               CALL LoadTranslations              ; fetch "translate.dat" from filing system,
               XOR  A                             ; if available...
               RET


; ************************************************************
.ESC_C_cmd1    LD   HL,message12
               CALL Write_message

               LD   HL, CRLF_flag                   ; Remote activation of auto CRLF conversion
               LD   (HL), $FF
               XOR  A
               RET


; ************************************************************
.ESC_C_cmd2    LD   HL,message13
               CALL Write_message

               LD   HL, CRLF_flag                   ; Remote de-activation of auto CRLF conversion
               LD   (HL), 0
               XOR  A
               RET


; ************************************************************
.ESC_T_cmd1    LD   HL,message10
               CALL Write_message

               LD   A, $FF                   ; Remote activation of auto translation
               LD   (tra_flag), A
               LD   (tra_flag_copy), A
               XOR  A
               RET


; ************************************************************
.ESC_T_cmd2    LD   HL,message11
               CALL Write_message

               LD   A, 0                     ; Remote de-activation of auto translation
               LD   (tra_flag), A
               LD   (tra_flag_copy), A
               XOR  A
               RET


; ***********************************************************************
.Open_serialport
               LD   A,op_up
               LD   HL,serial_port
               LD   DE,filename_buffer
               CALL Get_file_handle               ; get INPUT/OUTPUT handle for ":COM.0" device
               LD   (serport_handle), IX
               RET


; ***********************************************************************
.Close_serialport
               PUSH AF
               PUSH IX
               LD   IX,(serport_handle)
               CALL_OZ(Gn_Cl)
               POP  IX
               POP  AF
               RET


; ***********************************************************************
.EnableSerportLogging
               PUSH HL
               CALL Create_serportdump_files
               LD   HL, msg_serdmpfile_enable
               CALL Write_message
               POP  HL
               RET


; ***********************************************************************
.DisableSerportLogging
               PUSH HL
               CALL Close_serportdump_filehandles
               LD   HL, msg_serdmpfile_disable
               CALL Write_message
               POP  HL
               RET


; ***********************************************************************
.Close_serportdump_filehandles
               PUSH AF
               PUSH IX
               PUSH HL

               LD   HL,(serfile_in_handle)
               LD   A,H
               OR   L
               JR   Z, close_out_handle                     ; serport dump IN file not open
               PUSH HL
               POP  IX
               CALL_OZ(Gn_Cl)

.close_out_handle
               LD   HL,(serfile_out_handle)
               LD   A,H
               OR   L
               JR   Z, exit_Close_serportdump_filehandles   ; serport dump OUT file not open
               PUSH HL
               POP  IX
               CALL_OZ(Gn_Cl)

.exit_Close_serportdump_filehandles
               LD   HL,0
               LD   (serfile_out_handle),HL
               LD   (serfile_in_handle),HL

               POP  HL
               POP  IX
               POP  AF
               RET


; ***********************************************************************
.Create_serportdump_files
               PUSH AF
               PUSH BC
               PUSH HL
               PUSH IX

               ; close current dump files, if they're open
               LD   HL,(serfile_in_handle)
               LD   A,H
               OR   L
               CALL NZ,Close_serportdump_filehandles

               ; then flush old files and create new ones...
               LD   B,0                   ; filename is local...
               LD   HL,serdmpfile_in
               CALL createfilename
               CALL C,Close_serportdump_filehandles
               JR   C,exit_Create_serportdump_files
               LD   (serfile_in_handle),IX

               LD   HL,serdmpfile_out
               CALL createfilename
               CALL C,Close_serportdump_filehandles
               JR   C,exit_Create_serportdump_files
               LD   (serfile_out_handle),IX

.exit_Create_serportdump_files
               POP  IX
               POP  HL
               POP  BC
               POP  AF
               RET


; ************************************************************
.Set_TraFlag   EX   AF,AF'
               LD   A, (tra_flag)
               LD   (tra_flag_copy),A
               LD   A,$FF
               LD   (tra_flag),A
               EX   AF,AF'
               RET


; ************************************************************
.Restore_Traflag
               EX   AF,AF'
               LD   A,(tra_flag_copy)
               LD   (tra_flag),A
               EX   AF,AF'
               RET


; ***********************************************************************
.Init_PanelSettings                               ; Copy original parameters in buffers:
               CALL Fetch_PanelSettings

               ; Relevant parameters are now copied. Install now (temporarily) the new
               ; serial port parameters (9600 baud , No Xon/Xoff, No Parity):

               CALL Define_PanelSettings
               RET


; ***********************************************************************
.Fetch_PanelSettings
               LD    A, 2                         ; max 2 bytes (word)
               LD   BC, PA_Txb                    ; Transmit Baud rate
               LD   DE, Cpy_Pa_Txb+1              ; buffer for baud rate
               CALL Fetch_Parameter
               JP   C, System_error
               DEC  DE
               LD   (DE), A                       ; remember length of PA_Txb
               LD    A, 2
               LD   BC, PA_Rxb
               LD   DE, Cpy_PA_Rxb+1
               CALL Fetch_Parameter
               JP   C, System_error
               DEC  DE
               LD   (DE), A                       ; remember length of PA_Rxb
               LD   A, 1
               LD   BC, PA_Xon
               LD   DE, Cpy_PA_Xon
               CALL Fetch_Parameter
               JP   C, System_error
               LD   A, 1
               LD   BC, PA_Par
               LD   DE, Cpy_PA_Par
               CALL Fetch_Parameter
               JP   C, System_error
               RET


; ***********************************************************************
; serial port parameters: 9600 baud, No Xon/Xoff, No Parity
;
.Define_PanelSettings
               LD   A, 2                          ; word size
               LD   BC, PA_Txb                    ; new transmit baud rate, 9600
               LD   HL, BaudRate
               CALL_OZ (Os_Sp)
               LD   BC, PA_Rxb                    ; new receive baud rate, 9600
               CALL_OZ (Os_Sp)
               LD   A, 1
               LD   BC, PA_Xon                    ; Xon/Xoff No
               LD   HL, No_Parameter
               CALL_OZ (Os_Sp)
               LD   BC, PA_Par                    ; No Parity
               LD   HL, No_Parameter
               CALL_OZ (Os_Sp)
               XOR  A
               LD   BC, PA_Gfi                    ; install new parameters
               CALL_OZ (Os_Sp)
               RET


; ***********************************************************************
; Restore Panel settings to original values that was present before
; MultiLink was called.
.Restore_PanelSettings
               LD   A, (Cpy_PA_Txb)                ; fetch length of parameter (Transmit baud rate)
               LD   BC, PA_Txb
               LD   HL, Cpy_PA_Txb+1               ; address of parameter
               CALL_OZ (Os_Sp)
               JP   C, System_error
               LD   A, (Cpy_PA_Rxb)                ; fetch length of parameter (Transmit baud rate)
               LD   BC, PA_Rxb
               LD   HL, Cpy_PA_Rxb+1               ; address of parameter
               CALL_OZ (Os_Sp)
               JP   C, System_error
               LD   A, 1
               LD   BC, PA_Xon                     ; Xon/Xoff
               LD   HL, Cpy_PA_Xon
               CALL_OZ (Os_Sp)
               LD   A, 1
               LD   BC, PA_Par                     ; Parity
               LD   HL, Cpy_PA_Par
               CALL_OZ (Os_Sp)
               XOR  A
               LD   BC, PA_Gfi                     ; install original parameters
               CALL_OZ (Os_Sp)
               RET


; ***********************************************************************
; Fetch a system parameter:
; BC = Parameter offset,   A = number of bytes to be read,
; DE = Buffer to put bytes
; - Returns A = bytes actually read
.Fetch_Parameter
               PUSH DE                              ; save pointer to buffer
               CALL_OZ (Os_Nq)
               POP  DE
               RET


; ***********************************************************************
; Reset all I/O handles to zero.
;
.InitHandles   PUSH HL
               LD   HL,0
               LD   (serport_handle),HL
               LD   (serfile_in_handle),HL
               LD   (serfile_out_handle),HL
               LD   (file_handle),HL
               LD   (wildcard_handle),HL
               POP  HL
               RET

; ***********************************************************************
; Reset both translation tables to identical lookup values ( 0 - 255 )
;
.InitTraTable
               PUSH AF
               PUSH BC
               PUSH DE
               PUSH HL
               XOR  A
               LD   B,0                           ; 256 bytes to initiate
               LD   HL,TraTableIn
               LD   DE,TraTableOut
.initTraTable_loop
               LD   (HL),A                        ;  FOR a = 0 TO 255
               LD   (DE),A                        ;    TraTable_in(b) = a
               INC  HL                            ;    TraTable_out(b) = a
               INC  DE                            ;  END FOR a
               INC  A
               DJNZ,initTraTable_loop
               POP  HL
               POP  DE
               POP  BC
               POP  AF
               RET


; ***********************************************************************
.System_error  PUSH AF
               CALL_OZ (Gn_Err)                   ; display system error
               POP  AF
               RET


; ***********************************************************************
.Write_message PUSH AF
               PUSH HL
               PUSH HL
               LD   HL, vdulog
               CALL_OZ (Gn_Sop)
               POP  HL
               CALL_OZ (Gn_Sop)
               CALL_OZ (Gn_Nln)
               POP  HL
               POP  AF
               RET
.vdulog        DEFM 1, "2H3", 0                 ; use log window for message


; ***********************************************************************
.Msg_File_open_error
               LD   HL, error_message1
               CALL Write_message
               RET


; ***********************************************************************
.Msg_Protocol_error
               LD   HL, error_message3
               CALL Write_message
               CALL DisableSerportLogging
               RET


; ***********************************************************************
.Msg_file_aborted
               LD   HL, error_message4
               CALL Write_message
               RET


; ***********************************************************************
.Msg_No_Room   LD   HL, error_message5
               CALL Write_message
               RET


; ***********************************************************************
.Msg_Command_aborted
               LD   HL,error_message2
               CALL Write_message                 ; No flags will be changed...
               RET

