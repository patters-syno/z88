; *************************************************************************************
; FlashStore
; (C) Gunther Strube (gbs@users.sf.net) & Thierry Peycru (pek@users.sf.net), 1997-2007
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
;
; *************************************************************************************

DEFC RAM_pages = 8                      ; allocate 7 * 256 (1.5K) bytes contigous memory from $2000...
DEFC BufferSize = 1024                  ; buffer for file I/O at $2000

DEFVARS $2000
{
     buffer         ds.b BufferSize
     buf1           ds.b 128
     buf2           ds.b 128            ; filename buffer...
     buf3           ds.b 256            ; for expanded filenames

     linecnt        ds.b 1
     freespacebar   ds.w 1              ; base pointer to UDG font memory for 'Q' - '@' characters.
     bytesperline   ds.w 1              ; number of bytes that represents each drawn vertical line in horisontal space bar
     MenuBarPosn    ds.b 1              ; Main Menu Bar vertical position in window (0 - 6)
     FileBarPosn    ds.b 1              ; File Bar vertical position in Catalogue window (0 - 6)
     WindowFilePtr  ds.p 1              ; Top Line Window Pointer to File Entry
     CursorFilePtr  ds.p 1              ; File Bar Pointer to current File Entry in File Area
     barMode        ds.b 1              ; menu bar or file bar movement?
     nlen           ds.b 1              ; length of filename
     flen           ds.l 1              ; length of file (32bit)
     free           ds.l 1              ; free bytes on File Area
     deleted        ds.l 1              ; total bytes of deleted file space in File Area
     active         ds.l 1              ; total bytes of active file space in File Area
     total          ds.l 1              ; total bytes of active+deleted file space in File Area
     file           ds.l 1              ; total count of active files in File Area
     fdel           ds.l 1              ; total count of deleted files on Flash Eprom
     savedfiles     ds.l 1              ; total of files saved in a "Save" session
     fbnk           ds.b 1              ; Eprom Bank (relative)
     fadr           ds.w 1              ; Eprom Bank offset address
     flentry        ds.p 1              ; pointer to existing file entry
     status         ds.b 1              ; general purpose status flag
     wcard_handle   ds.w 1              ; Wildcard handle from GN_OPW
     availslots     ds.b 5              ; array of available File Areas in all slots. [0] = total areas, [1]-[4] = file area size
     curslot        ds.b 1              ; the current selected slot (possibly containing File Area)
     dstslot        ds.b 1              ; file entry copy destination slot
     flashid        ds.w 1              ; the manufacturer and device code of the flash card in current slot
     watermark      ds.b 5              ; the current File Area watermark (File Header Ramdom ID & size of banks)
     ramdevno       ds.b 1              ; the default Ascii RAM Device slot number ('0' - '3').
     vdubufptr      ds.w 1              ; VDU buffer pointer for accumulated VDU sequenses (buid up VDU codes, ending with GN_Sop)
}

; Status flags
DEFC dspdelfiles = 0
DEFC overwrfiles = 1

; MTH Command Code Definitions
DEFC FlashStore_CC_sc = $80             ; Select Card
DEFC FlashStore_CC_cf = $81             ; Catalogue Files
DEFC FlashStore_CC_sv = $82             ; Select RAM Device
DEFC FlashStore_CC_fs = $83             ; File Save
DEFC FlashStore_CC_fl = $84             ; File Load
DEFC FlashStore_CC_fe = $85             ; File Erase
DEFC FlashStore_CC_bf = $86             ; Backup Files
DEFC FlashStore_CC_rf = $87             ; Restore Files
DEFC FlashStore_CC_ffa = $88            ; Format File Area
DEFC FlashStore_CC_tfv = $89            ; Change File View
DEFC FlashStore_CC_fc = $8A             ; Copy File Area
