#!/bin/bash

# *************************************************************************************
# EazyLink application make script for Unix/Linux for Intuition debugging
# (C) Gunther Strube (gstrube@gmail.com) 2005-2012
#
# EazyLink is free software; you can redistribute it and/or modify it under the terms of the
# GNU General Public License as published by the Free Software Foundation;
# either version 2, or (at your option) any later version.
# EazyLink is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY;
# without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
# See the GNU General Public License for more details.
# You should have received a copy of the GNU General Public License along with EazyLink;
# see the file COPYING. If not, write to the
# Free Software Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA 02111-1307, USA.
#
#
# *************************************************************************************

# ensure that we have an up-to-date standard library
cd ../../stdlib; ./makelib.sh; cd ../z88apps/eazylink

# compile EazyLink application (debug version) from scratch
rm -f *.obj *.bin *.map *.63 *.epr
mpm -b -DDEBUGGING -I../../oz/def -l../../stdlib/standard.lib @eazylink
