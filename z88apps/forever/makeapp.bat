:: *************************************************************************************
::
:: Z88 Forever compile script for Linux/Unix/MAC OSX
:: Z88 Forever compilation ROM, (c) Garry Lancaster, 1998-2011
::
:: Z88 Forever is free software; you can redistribute it and/or modify it under the terms of the
:: GNU General Public License as published by the Free Software Foundation;
:: either version 2, or (at your option) any later version.
:: Z88 Forever is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY;
:: without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
:: See the GNU General Public License for more details.
:: You should have received a copy of the GNU General Public License along with Z88 Forever;
:: see the file COPYING. If not, write to the
:: Free Software Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA 02111-1307, USA.
::
:: $Id$
::
:: *************************************************************************************

del *.obj *.sym *.bin *.map *.6? forever.epr

:: Ensure that we have an up-to-date standard library (needed for FreeRAM)
cd ..\..\stdlib
call makelib.bat
cd ..\z88apps\forever

:: Assemble the Public Domain ROM
cd ..\pdrom
call makeapp.bat

:: Assemble Z80Dis
cd ..\zdis
..\..\tools\mpm\mpm -b -I..\..\oz\def -rDA92 zdis.asm

:: Assemble ZMonitor
cd ..\zmonitor
..\..\tools\mpm\mpm -b -I..\..\oz\def -rEF00 zmonitor.asm

:: Assemble Lockup
cd ..\lockup
..\..\tools\mpm\mpm -b -I..\..\oz\def -rFA00 lockup.asm

:: Assemble AlarmSafe
cd ..\alarmsafe
..\..\tools\mpm\mpm -b -I..\..\oz\def -rFCB8 alarmsafe.asm

:: Assemble FileView
cd ..\fview
..\..\tools\mpm\mpm -b -I..\..\oz\def -rC460 fview.asm

:: Assemble EP-Fetch2
cd ..\epfetch
..\..\tools\mpm\mpm -b -I..\..\oz\def -rC600 epfetch2.asm

:: Assemble FreeRAM
cd ..\freeram
..\..\tools\mpm\mpm -b -I..\..\oz\def -rD500 -l..\..\stdlib\standard.lib freeram.asm

:: Assemble Installer, Bootstrap & Packages
cd ..\installer
..\..\tools\mpm\mpm -b -I..\..\oz\def -oibp3e.bin -DBANK3E -rDC00 @ibp.prj

:: Assemble the card header
cd ..\forever
..\..\tools\mpm\mpm -b -I..\..\oz\def romheader.asm

:: Create a 32K Rom Card
..\..\tools\makeapp\makeapp.sh -f forever.loadmap

