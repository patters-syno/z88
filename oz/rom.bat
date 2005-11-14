:: -------------------------------------------------------------------------------------------------
:: OZ ROM compilation script for Windows/DOS
:: (C) Gunther Strube (gbs@users.sf.net) 2003-2005
::
:: OZ is free software; you can redistribute it and/or modify it under the terms of the
:: GNU General Public License as published by the Free Software Foundation;
:: either version 2, or (at your option) any later version.
:: OZ is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY;
:: without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
:: See the GNU General Public License for more details.
:: You should have received a copy of the GNU General Public License along with OZ;
:: see the file COPYING. If not, write to the
:: Free Software Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA 02111-1307, USA.
::
:: $Id$
:: -------------------------------------------------------------------------------------------------
@echo off

:: get OZ localisation compilation directive (first command line argument)
set ozlocale=%1

:: convert lower case argument to upper case ...
if "%ozlocale%"=="uk" set ozlocale=UK
if "%ozlocale%"=="fr" set ozlocale=FR
if "%ozlocale%"=="dk" set ozlocale=DK
if "%ozlocale%"=="fi" set ozlocale=FI
if "%ozlocale%"=="se" set ozlocale=FI
if "%ozlocale%"=="SE" set ozlocale=FI

:: compile known localisations
if "%ozlocale%"=="UK" goto COMPILE_OZ
if "%ozlocale%"=="FR" goto COMPILE_OZ
if "%ozlocale%"=="DK" goto COMPILE_OZ
if "%ozlocale%"=="FI" goto COMPILE_OZ

:: if no (or unknown) locale is specified, use default UK
ECHO Unknown or no locale argument specified
set ozlocale=UK

:COMPILE_OZ
if "%ozlocale%"=="UK" ECHO Compiling English Z88 ROM
if "%ozlocale%"=="DK" ECHO Compiling Danish Z88 ROM
if "%ozlocale%"=="FR" ECHO Compiling French Z88 ROM
if "%ozlocale%"=="FI" ECHO Compiling Swedish/Finish Z88 ROM

:: delete previous compiled files...
call cleanup

:: -------------------------------------------------------------------------------------------------
echo compiling kernel banks 0 and 7
call kernel %ozlocale% 2>nul >nul
dir bank0\*.err 2>nul >nul || goto COMPILE_BANK1
dir bank7\*.err 2>nul >nul || goto COMPILE_BANK1
goto COMPILE_ERROR

:: -------------------------------------------------------------------------------------------------
:COMPILE_BANK1
echo compiling bank 1
cd bank1
call bank1 2>nul >nul
cd ..
dir bank1\*.err 2>nul >nul || goto COMPILE_BANK2
goto COMPILE_ERROR

:: -------------------------------------------------------------------------------------------------
:COMPILE_BANK2
echo compiling bank 2
cd bank2
call bank2 2>nul >nul
cd ..
dir bank2\*.err 2>nul >nul || goto COMPILE_BANK3
goto COMPILE_ERROR

:: -------------------------------------------------------------------------------------------------
:COMPILE_BANK3
echo compiling bank 3
cd bank3
call bank3 2>nul >nul
cd ..
dir bank3\*.err 2>nul >nul || goto COMPILE_BANK6
goto COMPILE_ERROR

:: -------------------------------------------------------------------------------------------------
:COMPILE_BANK6
echo compiling bank 6
cd bank6
call bank6 2>nul >nul
cd ..
dir bank6\*.err 2>nul >nul || goto COMBINE_BANKS
goto COMPILE_ERROR

:: -------------------------------------------------------------------------------------------------
:: ROM was compiled successfully, combine the compiled 16K banks 0-7 into a complete 128K binary
:COMBINE_BANKS
echo Compiled Z88 ROM to "oz.bin" file.
copy /B /Y kernel.bn1+bank1\bank1.bin+bank2\bank2.bin+bank3\bank3.bin+banks45\pipedrm.dat+bank6\bank6.bin+kernel.bn0 oz.bin >nul
goto END

:COMPILE_ERROR
echo Compilation error occurred! Script aborted.
:END
