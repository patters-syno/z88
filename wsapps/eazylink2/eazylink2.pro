#-------------------------------------------------
#
# Project created by QtCreator 2011-10-07T00:27:24
#
#-------------------------------------------------

QT       += core gui

TARGET = eazylink2
TEMPLATE = app


SOURCES += main.cpp\
        mainwindow.cpp\
        serialport.cpp \ 
    z88serialport.cpp

HEADERS  += mainwindow.h\
         serialport.h\
         serialport_p.h \
    z88serialport.h

FORMS    += mainwindow.ui