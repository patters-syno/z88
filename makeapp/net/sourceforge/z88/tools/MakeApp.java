/*
 * MakeApp.java
 * This file is part of MakeApp.
 * 
 * MakeApp is free software; you can redistribute it and/or modify it under the terms of the 
 * GNU General Public License as published by the Free Software Foundation;
 * either version 2, or (at your option) any later version.
 * MakeApp is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY;
 * without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
 * See the GNU General Public License for more details.
 * You should have received a copy of the GNU General Public License along with MakeApp;
 * see the file COPYING. If not, write to the
 * Free Software Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA 02111-1307, USA.
 * 
 * @author <A HREF="mailto:gbs@users.sourceforge.net">Gunther Strube</A>
 * $Id$  
 *
 */

package net.sourceforge.z88.tools;

import java.io.FileNotFoundException;
import java.io.IOException;
import java.io.RandomAccessFile;

/**
 * Simple command line tool that creates a 16K bank file where
 * small binary files are loaded into at various offsets.
 * Finally, the bank is saved to a new file.
 * 
 * The tool is used to combine various Z88 application files into
 * a single 16K bank, typically as part of an application card.
 */
public class MakeApp {
	
	public static void main(String[] args) {
		RomBank bank = new RomBank();

		try {
			if (args.length >= 1) {
				int arg = 0;
				
				RandomAccessFile bankFile = new RandomAccessFile(args[arg++], "rw");
				
				while (arg < args.length) {
					RandomAccessFile binaryFile =  new RandomAccessFile(args[arg++], "r");
					int offset = Integer.parseInt(args[arg++], 16) & 0x3FFF;
					
					byte codeBuffer[] = new byte[(int) binaryFile.length()];
					binaryFile.readFully(codeBuffer);
					bank.loadBytes(codeBuffer, offset);
				}
								
				byte bankDump[] = bank.dumpBytes(0, Bank.BANKSIZE); 
				bankFile.write(bankDump);
				bankFile.close();
			} else {
				System.out.println("Usage: Load binary files a into 16K memory area, and save contents");
				System.out.println("to a new file. Offsets are specified in hex (truncated to 16K offsets)");
				System.out.println("Example:");
				System.out.println("java -jar makeapp.jar appl.epr code.bin c000 romhdr.bin 3fc0");
				System.out.println("(load 1st file at 0000, 2nd file at 3fc0, and save 16K bank to appl.epr)");
			}
		} catch (FileNotFoundException e) {
			System.out.println("Couldn't load file image:\n" + e.getMessage() + "\nprogram terminated.");
			return;
		} catch (IOException e) {
			System.out.println("Problem with bank image or I/O:\n" + e.getMessage() + "\nprogram terminated.");
			return;
		}		
	}
}
