#!/bin/bash

# *************************************************************************************
# FreeRam
# (C) Gunther Strube (hello@bits4fun.net) 1998
#
# FreeRam is free software; you can redistribute it and/or modify it under the terms of the
# GNU General Public License as published by the Free Software Foundation;
# either version 2, or (at your option) any later version.
# FreeRam is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY;
# without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
# See the GNU General Public License for more details.
# You should have received a copy of the GNU General Public License along with FreeRam;
# see the file COPYING. If not, write to the
# Free Software Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA 02111-1307, USA.
#
#
# *************************************************************************************

# ensure that we have an up-to-date standard library
cd ../../stdlib; ./makelib.sh; cd ../z88apps/freeram

# return version of Mpm to command line environment.
# validate that MPM is V1.5 or later - only this version or later supports macros
MPM_VERSIONTEXT=`mpm -version`

if test $? -lt 15; then
  echo Mpm version is less than V1.5, FreeRam compilation aborted.
  echo Mpm displays the following:
  mpm
  exit 1
fi

rm -f *.obj *.bin *.map freeram.63 freeram.epr
mpm -b -I../../oz/def -l../../stdlib/standard.lib freeram.asm
mpm -b romhdr

# Create a 16K Rom Card with FreeRam
z88card -f freeram.loadmap
