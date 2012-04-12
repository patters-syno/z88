/*********************************************************************************************
 EazyLink2 - Fast Client/Server Z88 File Management
 (C) Gunther Strube (gstrube@gmail.com) & Oscar Ernohazy 2012

 EazyLink2 is free software; you can redistribute it and/or modify it under the terms of the
 GNU General Public License as published by the Free Software Foundation;
 either version 2, or (at your option) any later version.
 EazyLink2 is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY;
 without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
 See the GNU General Public License for more details.
 You should have received a copy of the GNU General Public License along with EazyLink2;
 see the file COPYING. If not, write to the
 Free Software Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA 02111-1307, USA.

**********************************************************************************************/
#include <dirent.h>
#include "serialport.h"
#include "serialportsavail.h"

static const char *DEV_DIR_FSPEC("/dev/");
#ifdef Q_OS_MAC
static const QString SER_DEV_MASK("tty.");
#endif
#ifdef Q_OS_LINUX
static const QString SER_DEV_MASK("ttyS");
static const QString SER_DEV_MASK_USB("ttyUSB");
#endif

/**
  * Default constructor.
  */
SerialPortsAvail::SerialPortsAvail()
{
    get_portList();
}

/**
  * The Destructor
  */
SerialPortsAvail::~SerialPortsAvail(){}

/**
 * Obtain a list of available Serial ports
 * @return a list of serial port filenames.
 */
const QStringList&
SerialPortsAvail::get_portList()
{
    SerialPort port = SerialPort();
    QString devStr;

    /**
     * Fill the List with Serial port filenames
     */
    DIR *dirp = opendir(DEV_DIR_FSPEC);
    m_portlist.clear();
    m_portName.clear();

    if(!dirp){
        return m_portlist;
    }

    /**
     * Find all Matching device names
     */
    struct dirent *dp;

    while ((dp = readdir(dirp)) != NULL){
#ifdef Q_OS_LINUX
        if (dp->d_reclen){
#else
        if (dp->d_namlen){
#endif
            /**
             * Append the portname found
             */
            QString st(dp->d_name);
#ifdef Q_OS_LINUX
            if(st.contains(SER_DEV_MASK) || st.contains(SER_DEV_MASK_USB)){
#else
            if(st.contains(SER_DEV_MASK)){
#endif
                devStr.append(DEV_DIR_FSPEC);
                devStr.append(dp->d_name);
                port.setPortName(devStr);
                if (port.open(QIODevice::ReadWrite)) {
                    m_portlist << dp->d_name;
                    port.close();
                }
                devStr.clear();
            }
        }
    }

    closedir(dirp);

    if(!m_portlist.isEmpty()){
        m_portName = DEV_DIR_FSPEC + m_portlist.first();
    }
    return m_portlist;
}

/**
  * The the name of the first port available in the list.
  * @return the name of the first port.
  */
const QString &
SerialPortsAvail::getfirst_portName() const
{
    return m_portName;
}

/**
  * get the Fully qualified port name of the First available port.
  * @return the filename of the first port, or the path /dev/ if none.
  */
const QString &
SerialPortsAvail::get_fullportName(const QString &devname)
{
    m_portName = DEV_DIR_FSPEC + devname;
    return m_portName;
}
