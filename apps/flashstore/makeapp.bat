del *.obj
del *.bin
del *.map
del *.epr
mpm -bv -I..\oz\sysdef -l..\stdlib\standard.lib fsapp
mpm -bv romhdr
java -jar e:\z88\makeapp.jar flashstore.epr fsapp.bin 3f0000 romhdr.bin 3f3fc0
java -jar e:\z88\z88.jar ram1 1024 s2 flashstore.epr epr3 512 28f 
