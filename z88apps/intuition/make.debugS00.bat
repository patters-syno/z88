:: *************************************************************************************
:: Intuition make script (DOS/Windows) to build executable for upper 8K segment 0
:: (C) Gunther Strube (hello@bits4fun.net) 1991-2014
::
:: Intuition is free software; you can redistribute it and/or modify it under the terms of the
:: GNU General Public License as published by the Free Software Foundation;
:: either version 2, or (at your option) any later version.
:: Intuition is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY;
:: without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
:: See the GNU General Public License for more details.
:: You should have received a copy of the GNU General Public License along with Intuition;
:: see the file COPYING. If not, write to the
:: Free Software Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA 02111-1307, USA.
::
::
:: *************************************************************************************

@echo off

:: ensure that we have an up-to-date standard library
cd ..\..\stdlib
call makelib.bat
cd ..\z88apps\intuition

:: compile Intuition code from scratch
:: Intuition uses segment 3 for bank switching (Intuition is located at $2000 - upper 8K of segment 0)
del /S /Q *.err *.def *.lst *.obj *.bin *.map 2>nul >nul

:: return version of Mpm to command line environment.
:: Only V1.5 or later of Mpm supports macros
mpm -version 2>nul >nul
if ERRORLEVEL 15 goto COMPILE_INTUITION
echo Mpm version is less than V1.5, Intuition compilation aborted.
echo Mpm displays the following:
mpm
goto END

:COMPILE_INTUITION

mpm -b -g -DINT_SEGM0 -DSEGMENT3 -I..\..\oz\def -l..\..\stdlib\standard.lib @debug0b
mpm -b -DINT_SEGM0 -DSEGMENT3 -I..\..\oz\def -l..\..\stdlib\standard.lib @debug0a

:: combine the two images as a single 16K executable, to be executed at $2000 in upper 8K segment 0
:: 'debug0a.bin' is the bootstrap and the core instruction debugger
:: 'debug0b.bin' contains the debugger command line
z88card debugS00.bin debug0a.bin 0000 debug0b.bin 2000

:: delete the redundant output binaries
del debug0a.bin debug0b.bin

:END