#!/bin/bash

# *************************************************************************************
#
# ZipUp & UnZip compile script for Linux/Unix/MAC OSX
# File compression/decompression utilities for ZIP files, (c) Garry Lancaster, 1999-2006
#
# ZipUtils is free software; you can redistribute it and/or modify it under the terms of the
# GNU General Public License as published by the Free Software Foundation;
# either version 2, or (at your option) any later version.
# ZipUtils is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY;
# without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
# See the GNU General Public License for more details.
# You should have received a copy of the GNU General Public License along with ZipUtils;
# see the file COPYING. If not, write to the
# Free Software Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA 02111-1307, USA.
#
#
# *************************************************************************************

cd unzip; ./makeapp.sh; cd ..
cd zipup; ./makeapp.sh; cd ..

rm -f *.obj *.bin *.map
mpm -b -I../../oz/def romheader.asm

# Create a 16K Rom Card with ZipUp & Unzip
z88card -f ziputils.loadmap
