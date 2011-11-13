:: *************************************************************************************
::
:: Tester & Example Package compile script for DOS/Windows
:: Tester & Example Package (c) Garry Lancaster 2000-2011
::
:: Tester & Example Package is free software; you can redistribute it and/or modify
:: it under the terms of the GNU General Public License as published by the Free Software
:: Foundation; either version 2, or (at your option) any later version.
:: Tester & Example Package is distributed in the hope that it will be useful, but
:: WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
:: FOR A PARTICULAR PURPOSE.
:: See the GNU General Public License for more details.
:: You should have received a copy of the GNU General Public License along with
:: Tester & Example Package; see the file COPYING. If not, write to the
:: Free Software Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA 02111-1307, USA.
::
::
:: *************************************************************************************

del *.obj *.sym *.bin *.map *.6? tester.epr

:: Assemble the popdown and MTH
..\..\tools\mpm\mpm -b -I..\..\oz\def @tester.prj

:: Assemble the card header
..\..\tools\mpm\mpm -b -I..\..\oz\def romheader.asm

:: Create a 16K Rom Card with Tester & Example Package
..\..\tools\makeapp\makeapp.bat -f tester.loadmap

