:: *************************************************************************************
:: RomUpdate - BBC BASIC compile script
:: (C) Gunther Strube (hello@bits4fun.net) 2005-2014
::
:: RomUpdate is free software; you can redistribute it and/or modify it under the terms of the
:: GNU General Public License as published by the Free Software Foundation;
:: either version 2, or (at your option) any later version.
:: RomUpdate is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY;
:: without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
:: See the GNU General Public License for more details.
:: You should have received a copy of the GNU General Public License along with RomUpdate;
:: see the file COPYING. If not, write to the
:: Free Software Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA 02111-1307, USA.
::
::
:: *************************************************************************************
@echo off

:: ensure that we have an up-to-date standard library
cd ..\..\stdlib
call makelib.bat
cd ..\z88apps\romupdate

:: this is actually to be run as a BBC BASIC program on the Z88
del /S /Q *.obj *.bin romupdate.bas *.map 2>nul >nul

:: return version of Mpm to command line environment.
:: Only V1.5 or later of Mpm supports macros
mpm -version 2>nul >nul
if ERRORLEVEL 15 goto COMPILE_ROMUPDATE
echo Mpm version is less than V1.5, RomUpdate compilation aborted.
echo Mpm displays the following:
mpm
goto END

:COMPILE_ROMUPDATE

mpm -b -crc32 -oromupdate.bas -DBBCBASIC -I..\..\oz\def -l..\..\stdlib\standard.lib @romupdate.bbcbasic.prj

dir *.err 2>nul >nul || goto END
type *.err

:END