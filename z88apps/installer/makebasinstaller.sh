#!/bin/bash

# *************************************************************************************
#
# Installer/Bootstrap/Packages compile script for Linux/Unix/MAC OSX
# Installer/Bootstrap/Packages (c) Garry Lancaster 1998-2011
#
# Installer/Bootstrap/Packages is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by the Free Software
# Foundation; either version 2, or (at your option) any later version.
# Installer/Bootstrap/Packages is distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
# FOR A PARTICULAR PURPOSE.
# See the GNU General Public License for more details.
# You should have received a copy of the GNU General Public License along with
# Installer/Bootstrap/Packages; see the file COPYING. If not, write to the
# Free Software Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA 02111-1307, USA.
#
# $Id$
#
# *************************************************************************************

rm -f *.obj *.sym *.bin *.map installer.c

# Assemble the BASIC installer codefile
../../tools/mpm/mpm -b -oinstaller.c -I../../oz/def -DBASINST @basinstaller.prj