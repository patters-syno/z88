#!/bin/bash

# *************************************************************************************
# RomUpdate - Popdown compile script
# (C) Gunther Strube (gstrube@gmail.com) 2005-2012
#
# RomUpdate is free software; you can redistribute it and/or modify it under the terms of the
# GNU General Public License as published by the Free Software Foundation;
# either version 2, or (at your option) any later version.
# RomUpdate is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY;
# without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
# See the GNU General Public License for more details.
# You should have received a copy of the GNU General Public License along with RomUpdate;
# see the file COPYING. If not, write to the
# Free Software Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA 02111-1307, USA.
#
#
# *************************************************************************************

# ensure that we have an up-to-date standard library
cd ../../stdlib; ./makelib.sh; cd ../z88apps/romupdate

rm -f *.obj *.bin *.map romupdate.epr
mpm -b -oromupdate.bin -DPOPDOWN -I../../oz/def -l../../stdlib/standard.lib @romupdate.popdown.prj
mpm -b romhdr
if test `find . -name '*.err' | wc -l` != 0; then
    cat *.err
else
    # Create a 16K Rom Card with RomUpdate
    makeapp.sh romupdate.epr romupdate.bin 3f0000 romhdr.bin 3f3fc0
fi
