#!/bin/bash

# *************************************************************************************
#
# ZipUp & UnZip & XY-modem compile script for Linux/Unix/MAC OSX
#
# *************************************************************************************

# return version of Mpm to command line environment.
# validate that MPM is V1.5 or later - only this version or later supports macros
MPM_VERSIONTEXT=`mpm -version`

if test $? -lt 15; then
  echo Mpm version is less than V1.5, Ep-Fetch2 compilation aborted.
  echo Mpm displays the following:
  mpm
  exit 1
fi

# compile XY-Modem popdown from scratch
cd ../xymodem
rm -f *.obj *.bin *.map


mpm -b -I../../oz/def xy-modem.asm
cd ../ziputils

# --------------------------------------------------------------------

cd unzip; ./makeapp.sh; cd ..
cd zipup; ./makeapp.sh; cd ..

# Create a 16K Rom Card with ZipUp & Unzip & XY-modem
z88card -f ziputils+xymodem.loadmap
