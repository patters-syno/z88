:: *************************************************************************************
::
:: UnZip - File extraction utility for ZIP files, (c) Garry Lancaster, 1999-2006
:: This file is part of UnZip.
::
:: UnZip is free software; you can redistribute it and/or modify it under the terms of the
:: GNU General Public License as published by the Free Software Foundation;
:: either version 2, or (at your option) any later version.
:: UnZip is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY;
:: without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
:: See the GNU General Public License for more details.
:: You should have received a copy of the GNU General Public License along with UnZip;
:: see the file COPYING. If not, write to the
:: Free Software Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA 02111-1307, USA.
::
::
:: *************************************************************************************

@echo off

del /S /Q *.obj *.bin *.map 2>nul >nul

:: return version of Mpm to command line environment.
:: Only V1.5 or later of Mpm supports macros
mpm -version 2>nul >nul
if ERRORLEVEL 15 goto COMPILE_UNZIP
echo Mpm version is less than V1.5, UnZip compilation aborted.
echo Mpm displays the following:
mpm
goto END

:COMPILE_UNZIP

mpm -b -I..\..\..\oz\def crctable.asm
mpm -b -I..\..\..\oz\def @unzip.prj

:END
