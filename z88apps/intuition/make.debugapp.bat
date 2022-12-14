:: *************************************************************************************
:: Intuition Z88 application make script for DOS/Windows
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

:: compile Intuition application from scratch
:: Intuition application uses segment 2 for bank switching (Intuition application is located in segment 3)
del /S /Q *.err *.def *.lst *.obj *.bin *.map *.epr 2>nul >nul

:: return version of Mpm to command line environment.
:: Only V1.5 or later of Mpm supports macros
mpm -version 2>nul >nul
if ERRORLEVEL 15 goto COMPILE_INTUITION
echo Mpm version is less than V1.5, Intuition compilation aborted.
echo Mpm displays the following:
mpm
goto END

:COMPILE_INTUITION

mpm -b -g -DSEGMENT2 -I..\..\oz\def -l..\..\stdlib\standard.lib mthdbg tokens mthtext
mpm -b -DSEGMENT2 -I..\..\oz\def -l..\..\stdlib\standard.lib @debugapl
mpm -b -DSEGMENT2 romhdr

:: produce a complete 32K card image for OZvm, and make individual banks for RomCombiner.
z88card -szc 32 intuition.epr mthdbg.bin 3e0000 debugger.bin 3f0000 romhdr.bin 3f3fc0

:END