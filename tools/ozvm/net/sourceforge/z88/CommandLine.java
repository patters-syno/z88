/*
 * CommandLine.java
 * This	file is	part of	OZvm.
 *
 * OZvm	is free	software; you can redistribute it and/or modify	it under the terms of the
 * GNU General Public License as published by the Free Software	Foundation;
 * either version 2, or	(at your option) any later version.
 * OZvm	is distributed in the hope that	it will	be useful, but WITHOUT ANY WARRANTY;
 * without even	the implied warranty of	MERCHANTABILITY	or FITNESS FOR A PARTICULAR PURPOSE.
 * See the GNU General Public License for more details.
 * You should have received a copy of the GNU General Public License along with	OZvm;
 * see the file	COPYING. If not, write to the
 * Free	Software Foundation, Inc., 59 Temple Place - Suite 330,	Boston,	MA 02111-1307, USA.
 *
 * @author <A HREF="mailto:gbs@users.sourceforge.net">Gunther Strube</A>
 * $Id$
 *
 */
package net.sourceforge.z88;

import java.awt.event.KeyEvent;
import java.awt.event.KeyListener;
import java.io.File;
import java.io.FileNotFoundException;
import java.io.IOException;
import java.io.RandomAccessFile;
import java.util.ListIterator;

import javax.swing.JTextArea;
import javax.swing.JTextField;

import net.sourceforge.z88.datastructures.ApplicationDor;
import net.sourceforge.z88.datastructures.ApplicationInfo;
import net.sourceforge.z88.filecard.FileArea;
import net.sourceforge.z88.filecard.FileAreaExhaustedException;
import net.sourceforge.z88.filecard.FileAreaNotFoundException;
import net.sourceforge.z88.filecard.FileEntry;
import net.sourceforge.z88.screen.Z88display;

/**
 * The OZvm debug command line.
 */
public class CommandLine implements KeyListener {

	private static final String illegalArgumentMessage = "Illegal Argument";
	
	private	DebugGui debugGui;
	private	Blink z88;	

	/** The Z88 disassembly engine */
	private	Dz dz;

	/** The Breakpoint manager */
	private	Breakpoints breakPointManager;
	
	/** Access the Z88 memory model */
	private	Memory memory;
	
	private	JTextField commandInput;
	private	JTextArea commandOutput;
	private	CommandHistory cmdList;

	/**
	 * Constructor 
	 */
	public CommandLine() {
		
		debugGui = new DebugGui();
		z88 = Blink.getInstance();
		memory = Memory.getInstance();
		
		dz = Dz.getInstance();
		breakPointManager = z88.getBreakpoints();
		
		commandOutput =	debugGui.getCmdlineOutputArea();
		initDebugMode();
	}

	public DebugGui getDebugGui() {
		return debugGui;
	}
	
	private	void initDebugMode() {
		commandInput = debugGui.getCmdLineInputArea();
		commandInput.addActionListener(new java.awt.event.ActionListener() {
			public void actionPerformed(java.awt.event.ActionEvent e) {
				String cmdline = commandInput.getText();
				cmdList.addCommand(cmdline);
				commandInput.setText("");
				parseCommandLine(cmdline);
			}
		});
		commandInput.addKeyListener(this);
		cmdList	= new CommandHistory();

		commandOutput =	debugGui.getCmdlineOutputArea();
		displayCmdOutput("Type 'help' for available debugging commands");
	}

	public void displayCmdOutput(String msg) {
		if (commandOutput != null) {
			commandOutput.append(msg + "\n");
			commandOutput.setCaretPosition(commandOutput.getDocument().getLength());
		}
	}
		
	private	void cmdHelp() {
		displayCmdOutput("\nUse	F12 to toggle keyboard focus between debug command line	and Z88	window.");
		displayCmdOutput("All arguments	are in Hex: Local address = 64K	address	space,\nExtended address = 24bit address, eg. 073800 (bank 07h,	offset 3800h)");
		displayCmdOutput("Commands:");
		displayCmdOutput("run -	execute	virtual	Z88 from PC");
		displayCmdOutput("stop - stop virtual Z88 (or press F5 when Z88	window has focus)");
		displayCmdOutput("ldc filename <extended address> - Load file binary at	address");
		displayCmdOutput("z - trace (subroutine) code at PC and break at next instruction");
		displayCmdOutput(". - Single step instruction at PC");
		displayCmdOutput("dz - Disassembly at PC");
		displayCmdOutput("dz [local address | extended address]	- Disassemble at address");
		displayCmdOutput("wb <extended address>	<byte> [<byte>]	- Write	byte(s)	to memory");
		displayCmdOutput("m - View memory at PC");
		displayCmdOutput("m [local address | extended address] - View memory at	address");
		displayCmdOutput("bp - List breakpoints");
		displayCmdOutput("bl - Display Blink register contents");
		displayCmdOutput("bp <extended address>	- Toggle stop breakpoint");
		displayCmdOutput("bpd <extended	address> - Toggle display breakpoint");
		displayCmdOutput("sr - Blink: Segment Register Bank Binding");
		displayCmdOutput("rg - Display current Z80 Registers");
		displayCmdOutput("f/F -	Display	current	Z80 Flag Register");
		displayCmdOutput("cls -	Clear command output area\n");
		displayCmdOutput("dumpslot X -b [filename] - Dump slot 1-3 as 16K banks, optionally to dir/filename");
		displayCmdOutput("dumpslot X [filename]- Dump slot 1-3 as file with 'filename', or 'slotX.epr'\n");
		displayCmdOutput("fcdX cardhdr - Create a file area header in specified slot");
		displayCmdOutput("fcdX format - Create or re-format a file area in specified slot");
		displayCmdOutput("fcdX reclaim - Preserve active files and reclaim space of deleted files");
		displayCmdOutput("fcdX del filename - Mark 'oz' file in slot X file area as deleted");
		displayCmdOutput("fcdX ipf host-filename - Import file from OS file system into the file area");
		displayCmdOutput("fcdX ipd host-path - Import files from OS directory into the file area");
		displayCmdOutput("fcdX xpf filename host-dir - Export file to the operating system host-dir");
		displayCmdOutput("fcdX xpc host-dir - Export file card to host operating system host-dir");
		displayCmdOutput("");
		displayCmdOutput("savevm [filename] - save a snapshot of the current z88 to file.");
		displayCmdOutput("loadvm [filename] - load a Z88 snapshot (replaces current virtual machine).");
		displayCmdOutput("                    (default file is 'boot.z88'. Extension '.z88' is default)");
		displayCmdOutput("");
		displayCmdOutput("Blink registers are edited using their name, ex. INT 0B or int 00001011.");
		displayCmdOutput("TACK, ACK Blink interrupt acknowledge registers affects appropriate");
		displayCmdOutput("interrupt 'status' registers, ex. ACK 20 (00100000b) will acknowledge (reset)");
		displayCmdOutput("the FLAP interrupt in STA (acknowledge registers are not displayed, they serve");
		displayCmdOutput("only to reset interrupt status registers)."); 
		displayCmdOutput("Blink registers may be edited while Z88 is running. Available registers:");
		displayCmdOutput("COM, INT, STA, TACK, TMK, TSTA, ACK, PB0-3, SBR, SR0-3, TIM0-4");
		displayCmdOutput("");
		displayCmdOutput("Z80 Registers are	edited using their name, ex. A 01 or sp	1FFE");
		displayCmdOutput("Alternate registers are specified with ', ex.	a' 01 or BC' C000");
		displayCmdOutput("Flags	are toggled using FZ, FC, FN, FS, FV and FH commands or");
		displayCmdOutput("set/reset using 1 or 0 argument, eg. fz 1 to enable Zero flag.");
	}
	
	public void parseCommandLine(String cmdLineText) {
		String[] cmdLineTokens = cmdLineTokens = cmdLineText.split(" ");
		int arg;

		if (cmdLineTokens[0].compareToIgnoreCase("help") == 0) {
			cmdHelp();
		}

		if (cmdLineTokens[0].compareToIgnoreCase("savevm") == 0) {
			SaveRestoreVM srVm = new SaveRestoreVM();
			String vmFileName = OZvm.defaultVmFile;
			
			if (cmdLineTokens.length > 1) {
				vmFileName = cmdLineTokens[1];
				if (vmFileName.toLowerCase().lastIndexOf(".z88") == -1)
					vmFileName += ".z88"; // '.z88' extension was missing.
			}

			try {
				if (z88.getZ80engine() == null) {
					srVm.storeSnapShot(vmFileName, false);
					displayCmdOutput("Snapshot successfully saved to " + vmFileName);
				} else {
					displayCmdOutput("Snapshot can only be saved when Z88 is not running.");
				}							
			} catch (IOException e) {
				displayCmdOutput("Saving snapshot failed.");
			}
		}

		if (cmdLineTokens[0].compareToIgnoreCase("loadvm") == 0) {
			SaveRestoreVM srVm = new SaveRestoreVM();
			String vmFileName = OZvm.defaultVmFile;

			if (cmdLineTokens.length > 1) {
				vmFileName = cmdLineTokens[1];
				if (vmFileName.toLowerCase().lastIndexOf(".z88") == -1)
					vmFileName += ".z88"; // '.z88' extension was missing.
			}

			if (z88.getZ80engine() == null) {
				try {
					boolean autorun = srVm.loadSnapShot(vmFileName);
					displayCmdOutput("Snapshot successfully installed from " + vmFileName);
					if (autorun == true)
						z88.runZ80Engine(-1, true);
					else
						initDebugCmdline();
				} catch (IOException e) {
			    	// loading of snapshot failed - define a default Z88 system
			    	// as fall back plan.
					displayCmdOutput("Installation of snapshot failed. Z88 preset to default system.");
			    	memory.setDefaultSystem();
			    	z88.reset();				
			    	z88.resetBlinkRegisters();
				}
			} else {
				displayCmdOutput("Snapshot can only be installed when Z88 is not running.");
			}
		}
		
		if (cmdLineTokens[0].compareToIgnoreCase("cls")	== 0) {
			commandOutput.setText("");
		}

		if (cmdLineTokens[0].compareToIgnoreCase("apps") == 0) {
			ApplicationInfo appInfo = new ApplicationInfo();
			for (int slot=0; slot<4; slot++) {
				ListIterator appList = appInfo.getApplications(slot);
				if (appList != null) {
					displayCmdOutput("Slot " + slot + ":");
					while (appList.hasNext()) {
						ApplicationDor appDor = (ApplicationDor) appList.next();
						displayCmdOutput(appDor.getAppName() + ": Entry = " + Dz.extAddrToHex(appDor.getEntryPoint(), true));
					}					
				}
			}
		}
		
		if (cmdLineTokens[0].compareToIgnoreCase("run")	== 0) {
			if (z88.runZ80Engine(-1, true) == false)
				displayCmdOutput("Z88 is already running.");				
		}

		if (cmdLineTokens[0].compareToIgnoreCase("stop") == 0) {
			z88.stopZ80Execution();
		}

		if (cmdLineTokens[0].compareTo(".") == 0) {
			if (z88.getZ80engine() != null) {
				displayCmdOutput("Z88 is already running.");
				return;
			}

			z88.singleStepZ80();		// single stepping (no interrupts running)...
			displayCmdOutput(Z88Info.dzPcStatus(z88.PC()));

			debugGui.getCmdLineInputArea().setText(Dz.getNextStepCommand());
			debugGui.getCmdLineInputArea().setCaretPosition(debugGui.getCmdLineInputArea().getDocument().getLength());
			debugGui.getCmdLineInputArea().selectAll();
		}

		if (cmdLineTokens[0].compareToIgnoreCase("z") == 0) {
			if (z88.getZ80engine() != null) {
				displayCmdOutput("Z88 is already running.");
				return;
			} else {
				int nextInstrAddress = z88.decodeLocalAddress(dz.getNextInstrAddress(z88.PC()));
				if (breakPointManager.isCreated(nextInstrAddress) == true) {
					// there's already a breakpoint	at that	location...
					z88.runZ80Engine(-1, false);
				} else {
					breakPointManager.toggleBreakpoint(nextInstrAddress);	// set a temporary breakpoint at next instruction
					z88.runZ80Engine(nextInstrAddress, false);	// and automatically remove it when the	engine stops...
				}
			}
		}

		if (cmdLineTokens[0].compareToIgnoreCase("fcd1") == 0 | 
				cmdLineTokens[0].compareToIgnoreCase("fcd2") == 0 |
				cmdLineTokens[0].compareToIgnoreCase("fcd3") == 0) {
			fcdCommandline(cmdLineTokens);
		}
		
		if (cmdLineTokens[0].compareToIgnoreCase("dz") == 0) {
			dzCommandline(cmdLineTokens);
			displayCmdOutput("");
		}

		if (cmdLineTokens[0].compareToIgnoreCase("m") == 0) {
			viewMemory(cmdLineTokens);
			displayCmdOutput("");
		}

		if (cmdLineTokens[0].compareToIgnoreCase("bl") == 0) {
			displayCmdOutput(Z88Info.blinkRegisterDump());
		}

		if (cmdLineTokens[0].compareToIgnoreCase("sr") == 0) {
			displayCmdOutput(Z88Info.bankBindingInfo() + "\n");
			displayCmdOutput("");
		}

		if (cmdLineTokens[0].compareToIgnoreCase("rg") == 0) {
			displayCmdOutput("\n" + Z88Info.z80RegisterInfo());
			displayCmdOutput("");
		}

		if (cmdLineTokens[0].compareToIgnoreCase("bp") == 0) {
			try {
				bpCommandline(cmdLineTokens);
				displayCmdOutput("");
			} catch	(IOException e1) {
				e1.printStackTrace();
			}
		}

		if (cmdLineTokens[0].compareToIgnoreCase("bpd")	== 0) {
			try {
				bpdCommandline(cmdLineTokens);
				displayCmdOutput("");
			} catch	(IOException e1) {
				e1.printStackTrace();
			}
		}

		if (cmdLineTokens[0].compareToIgnoreCase("wb") == 0) {
			try {
				putByte(cmdLineTokens);
			} catch	(IOException e1) {
				e1.printStackTrace();
			}
		}

		if (cmdLineTokens[0].compareToIgnoreCase("ldc")	== 0) {
			try {
				RandomAccessFile file =	new RandomAccessFile(cmdLineTokens[1], "r");
				memory.loadBankBinary(Integer.parseInt(cmdLineTokens[2], 16), file);
				file.close();
				displayCmdOutput("File image '"	+ cmdLineTokens[1] + "'	loaded at " + cmdLineTokens[2] + ".");
			} catch	(IOException e)	{
				displayCmdOutput("Couldn't load	file image at ext.address: '" +	e.getMessage() + "'");
			}
			displayCmdOutput("");
		}

		if (cmdLineTokens[0].compareToIgnoreCase("dumpslot") == 0) {
			boolean exportAsBanks = false;
			int slotNumber = Integer.parseInt(cmdLineTokens[1]);
			String dumpFilename = "slot" + cmdLineTokens[1] + ".epr";
			String dumpDir = System.getProperty("user.dir");

			if (slotNumber > 0) {
				if (cmdLineTokens.length == 2) {
					// "dumpslot X"
					// dump the specified slot as a complete file
					// using a default "slotX.epr" filename				
				} else if (cmdLineTokens.length == 3) {
					// "dumpslot X -b" or "dumpslot X filename"
					if (cmdLineTokens[2].compareToIgnoreCase("-b") == 0) {
						dumpFilename = "slot" + cmdLineTokens[1] + "bank";
						exportAsBanks = true;
					} else {
						dumpFilename = cmdLineTokens[2]; 
					}
				} else if (cmdLineTokens.length == 4) {
					// "dumpslot X -b base-filename"
					// base filename (with optional path) for filename.bankNo
					if (cmdLineTokens[2].compareToIgnoreCase("-b") == 0)  
						exportAsBanks = true;						
					
					File fl = new File(cmdLineTokens[3]); 
					if (fl.isDirectory() == true) {
						dumpDir = fl.getAbsolutePath();
						dumpFilename = "slot" + cmdLineTokens[1] + "bank";
					} else {
						if (fl.getParent() != null) 
							dumpDir = new File(fl.getParent()).getAbsolutePath();
							
						dumpFilename = fl.getName(); 
					}
				}

				if (memory.isSlotEmpty(slotNumber) == false) {				
					try {
						memory.dumpSlot(slotNumber, exportAsBanks, dumpDir, dumpFilename);
						displayCmdOutput("Slot was dumped successfully to " + dumpDir);
					} catch (FileNotFoundException e1) {
						displayCmdOutput("Couldn't create file(s)!");
					} catch (IOException e1) {
						displayCmdOutput("I/O error while dumping slot!");
					}			
				} else {
					displayCmdOutput("Slot is empty!");
				}				
			}
		}
		
		if (cmdLineTokens[0].compareToIgnoreCase("com") == 0) {
			if (cmdLineTokens.length == 2) {
				arg = StringEval.toInteger(cmdLineTokens[1]); 
				if ( arg == -1 | arg > 255) {
					displayCmdOutput(illegalArgumentMessage);
					return;
				}
				else
					z88.setBlinkCom(arg);
			}
			displayCmdOutput(Z88Info.blinkComInfo());
		}
		
		if (cmdLineTokens[0].compareToIgnoreCase("int") == 0) {
			if (cmdLineTokens.length == 2) {
				arg = StringEval.toInteger(cmdLineTokens[1]); 
				if ( arg == -1 | arg > 255) {
					displayCmdOutput(illegalArgumentMessage);
					return;
				}
				else
					z88.setBlinkInt(arg);
			}
			displayCmdOutput(Z88Info.blinkIntInfo());
		}

		if (cmdLineTokens[0].compareToIgnoreCase("sta") == 0) {
			if (cmdLineTokens.length == 2) {
				arg = StringEval.toInteger(cmdLineTokens[1]); 
				if ( arg == -1 | arg > 255) {
					displayCmdOutput(illegalArgumentMessage);
					return;
				}
				else
					z88.setBlinkSta(arg);
			}
			displayCmdOutput(Z88Info.blinkStaInfo());
		}

		if (cmdLineTokens[0].compareToIgnoreCase("kbd") == 0) {
			if (cmdLineTokens.length == 2) {
				arg = StringEval.toInteger(cmdLineTokens[1]); 
				if ( arg == -1 | arg > 65535) {
					displayCmdOutput(illegalArgumentMessage);
					return;
				}
				else
					Z88Keyboard.getInstance().setKeyRow( arg >>> 8, arg & 0xFF);
			}			
			displayCmdOutput(Z88Keyboard.getInstance().getKbdMatrix());
		}
		
		if (cmdLineTokens[0].compareToIgnoreCase("ack") == 0) {
			if (cmdLineTokens.length == 2) {
				arg = StringEval.toInteger(cmdLineTokens[1]); 
				if ( arg == -1 | arg > 255) {
					displayCmdOutput(illegalArgumentMessage);
					return;
				}
				else
					z88.setBlinkAck(arg);
			}
			displayCmdOutput(Z88Info.blinkStaInfo());  // ACK affects STA
		}
		
		if (cmdLineTokens[0].compareToIgnoreCase("epr") == 0) {
			// Not yet implemented
		}

		if (cmdLineTokens[0].compareToIgnoreCase("tsta") == 0) {
			if (cmdLineTokens.length == 2) {
				arg = StringEval.toInteger(cmdLineTokens[1]); 
				if ( arg == -1 | arg > 255) {
					displayCmdOutput(illegalArgumentMessage);
					return;
				}
				else
					z88.setBlinkTsta(arg);
			}
			displayCmdOutput(Z88Info.blinkTstaInfo());
		}
		
		if (cmdLineTokens[0].compareToIgnoreCase("tack") == 0) {
			if (cmdLineTokens.length == 2) {
				arg = StringEval.toInteger(cmdLineTokens[1]); 
				if ( arg == -1 | arg > 255) {
					displayCmdOutput(illegalArgumentMessage);
					return;
				}
				else
					z88.setBlinkTack(arg);
			}
			displayCmdOutput(Z88Info.blinkTstaInfo()); // TACK affects TSTA
		}

		if (cmdLineTokens[0].compareToIgnoreCase("tmk") == 0) {
			if (cmdLineTokens.length == 2) {
				arg = StringEval.toInteger(cmdLineTokens[1]); 
				if ( arg == -1 | arg > 255) {
					displayCmdOutput(illegalArgumentMessage);
					return;
				}
				else
					z88.setBlinkTmk(arg);
			}
			displayCmdOutput(Z88Info.blinkTmkInfo());
		}
		
		
		if (cmdLineTokens[0].compareToIgnoreCase("pb0") == 0) {
			if (cmdLineTokens.length == 2) {
				arg = StringEval.toInteger(cmdLineTokens[1]); 
				if (arg == -1 | arg > 65535) {
					displayCmdOutput(illegalArgumentMessage);
					return;
				}
				else
					z88.setBlinkPb0(arg);
			}
			displayCmdOutput(Z88Info.blinkScreenInfo());
		}
		if (cmdLineTokens[0].compareToIgnoreCase("pb1") == 0) {
			if (cmdLineTokens.length == 2) {
				arg = StringEval.toInteger(cmdLineTokens[1]); 
				if (arg == -1 | arg > 65535) {
					displayCmdOutput(illegalArgumentMessage);
					return;
				}
				else
					z88.setBlinkPb1(arg);
			}
			displayCmdOutput(Z88Info.blinkScreenInfo());
		}
		if (cmdLineTokens[0].compareToIgnoreCase("pb2") == 0) {
			if (cmdLineTokens.length == 2) {
				arg = StringEval.toInteger(cmdLineTokens[1]); 
				if (arg == -1 | arg > 65535) {
					displayCmdOutput(illegalArgumentMessage);
					return;
				}
				else
					z88.setBlinkPb2(arg);
			}
			displayCmdOutput(Z88Info.blinkScreenInfo());
		}
		if (cmdLineTokens[0].compareToIgnoreCase("pb3") == 0) {
			if (cmdLineTokens.length == 2) {
				arg = StringEval.toInteger(cmdLineTokens[1]); 
				if (arg == -1 | arg > 65535) {
					displayCmdOutput(illegalArgumentMessage);
					return;
				}
				else
					z88.setBlinkPb3(arg);
			}
			displayCmdOutput(Z88Info.blinkScreenInfo());
		}
		if (cmdLineTokens[0].compareToIgnoreCase("sbr") == 0) {
			if (cmdLineTokens.length == 2) {
				arg = StringEval.toInteger(cmdLineTokens[1]); 
				if (arg == -1 | arg > 65535) {
					displayCmdOutput(illegalArgumentMessage);
					return;
				}
				else
					z88.setBlinkSbr(arg);
			}
			displayCmdOutput(Z88Info.blinkScreenInfo());
		}

		if (cmdLineTokens[0].compareToIgnoreCase("sr0") == 0) {
			if (cmdLineTokens.length == 2) {
				arg = StringEval.toInteger(cmdLineTokens[1]); 
				if ( arg == -1 | arg > 255) {
					displayCmdOutput(illegalArgumentMessage);
					return;
				}
				else
					z88.setSegmentBank(0, arg);
			}
			displayCmdOutput(Z88Info.blinkSegmentsInfo());
		}
		
		if (cmdLineTokens[0].compareToIgnoreCase("sr1") == 0) {
			if (cmdLineTokens.length == 2) {
				arg = StringEval.toInteger(cmdLineTokens[1]); 
				if ( arg == -1 | arg > 255) {
					displayCmdOutput(illegalArgumentMessage);
					return;
				}
				else
					z88.setSegmentBank(1, arg);
			}
			displayCmdOutput(Z88Info.blinkSegmentsInfo());
		}
		if (cmdLineTokens[0].compareToIgnoreCase("sr2") == 0) {
			if (cmdLineTokens.length == 2) {
				arg = StringEval.toInteger(cmdLineTokens[1]); 
				if ( arg == -1 | arg > 255) {
					displayCmdOutput(illegalArgumentMessage);
					return;
				}
				else
					z88.setSegmentBank(2, arg);
			}
			displayCmdOutput(Z88Info.blinkSegmentsInfo());
		}
		if (cmdLineTokens[0].compareToIgnoreCase("sr3") == 0) {
			if (cmdLineTokens.length == 2) {
				arg = StringEval.toInteger(cmdLineTokens[1]); 
				if ( arg == -1 | arg > 255) {
					displayCmdOutput(illegalArgumentMessage);
					return;
				}
				else
					z88.setSegmentBank(3, arg);
			}
			displayCmdOutput(Z88Info.blinkSegmentsInfo());
		}

		if (cmdLineTokens[0].compareToIgnoreCase("tim0") == 0) {
			if (cmdLineTokens.length == 2) {
				arg = StringEval.toInteger(cmdLineTokens[1]); 
				if (arg == -1 | arg > 255) {
					displayCmdOutput(illegalArgumentMessage);
					return;
				}
				else
					z88.setBlinkTim0(arg);
			}
			displayCmdOutput(Z88Info.blinkTimersInfo());
		}
		if (cmdLineTokens[0].compareToIgnoreCase("tim1") == 0) {
			if (cmdLineTokens.length == 2) {
				arg = StringEval.toInteger(cmdLineTokens[1]); 
				if (arg == -1 | arg > 255) {
					displayCmdOutput(illegalArgumentMessage);
					return;
				}
				else
					z88.setBlinkTim1(arg);
			}
			displayCmdOutput(Z88Info.blinkTimersInfo());
		}
		if (cmdLineTokens[0].compareToIgnoreCase("tim2") == 0) {
			if (cmdLineTokens.length == 2) {
				arg = StringEval.toInteger(cmdLineTokens[1]); 
				if (arg == -1 | arg > 255) {
					displayCmdOutput(illegalArgumentMessage);
					return;
				}
				else
					z88.setBlinkTim2(arg);
			}
			displayCmdOutput(Z88Info.blinkTimersInfo());
		}
		if (cmdLineTokens[0].compareToIgnoreCase("tim3") == 0) {
			if (cmdLineTokens.length == 2) {
				arg = StringEval.toInteger(cmdLineTokens[1]); 
				if (arg == -1 | arg > 255) {
					displayCmdOutput(illegalArgumentMessage);
					return;
				}
				else
					z88.setBlinkTim3(arg);
			}
			displayCmdOutput(Z88Info.blinkTimersInfo());
		}
		if (cmdLineTokens[0].compareToIgnoreCase("tim4") == 0) {
			if (cmdLineTokens.length == 2) {
				arg = StringEval.toInteger(cmdLineTokens[1]); 
				if (arg == -1 | arg > 255) {
					displayCmdOutput(illegalArgumentMessage);
					return;
				}
				else
					z88.setBlinkTim4(arg);
			}
			displayCmdOutput(Z88Info.blinkTimersInfo());
		}
		
		if (cmdLineTokens[0].compareToIgnoreCase("f") == 0) {
			if (cmdLineTokens.length == 2) {
				if (z88.getZ80engine() != null) {
					displayCmdOutput("Cannot change	F flag while Z88 is running!");
					return;
				}
				arg = StringEval.toInteger(cmdLineTokens[1]); 
				if (arg == -1 | arg > 255) {
					displayCmdOutput(illegalArgumentMessage);
					return;
				} else {
					z88.F(arg);
				}
			}			
			displayCmdOutput("F=" +	Z88Info.z80Flags() + " (" + Dz.byteToBin(z88.F(),true) + ")");
		}

		if (cmdLineTokens[0].compareToIgnoreCase("fz") == 0) {
			if (cmdLineTokens.length == 2) {
				if (z88.getZ80engine() != null) {
					displayCmdOutput("Cannot change	Zero flag while	Z88 is running!");
					return;
				}
				if (StringEval.toInteger(cmdLineTokens[1]) == 0)
					z88.fZ = false;
				else
					z88.fZ = true;
			} else {
				// toggle/invert flag status
				z88.fZ = !z88.fZ;
			}
			displayCmdOutput("F=" +	Z88Info.z80Flags() + " (" + Dz.byteToBin(z88.F(),true) + ")");
		}

		if (cmdLineTokens[0].compareToIgnoreCase("fc") == 0) {
			if (cmdLineTokens.length == 2) {
				if (z88.getZ80engine() != null) {
					displayCmdOutput("Cannot change	Carry flag while Z88 is	running!");
					return;
				}
				if (StringEval.toInteger(cmdLineTokens[1]) == 0)
					z88.fC = false;
				else
					z88.fC = true;
			} else {
				// toggle/invert flag status
				z88.fC = !z88.fC;
			}
			displayCmdOutput("F=" +	Z88Info.z80Flags() + " (" + Dz.byteToBin(z88.F(),true) + ")");
		}

		if (cmdLineTokens[0].compareToIgnoreCase("fs") == 0) {
			if (cmdLineTokens.length == 2) {
				if (z88.getZ80engine() != null) {
					displayCmdOutput("Cannot change	Sign flag while	Z88 is running!");
					return;
				}
				if (StringEval.toInteger(cmdLineTokens[1]) == 0)
					z88.fS = false;
				else
					z88.fS = true;
			} else {
				// toggle/invert flag status
				z88.fS = !z88.fS;
			}
			displayCmdOutput("F=" +	Z88Info.z80Flags() + " (" + Dz.byteToBin(z88.F(),true) + ")");
		}

		if (cmdLineTokens[0].compareToIgnoreCase("fh") == 0) {
			if (cmdLineTokens.length == 2) {
				if (z88.getZ80engine() != null) {
					displayCmdOutput("Cannot change	Half Carry flag	while Z88 is running!");
					return;
				}
				if (StringEval.toInteger(cmdLineTokens[1]) == 0)
					z88.fH = false;
				else
					z88.fH = true;
			} else {
				// toggle/invert flag status
				z88.fH = !z88.fH;
			}
			displayCmdOutput("F=" +	Z88Info.z80Flags() + " (" + Dz.byteToBin(z88.F(),true) + ")");
		}

		if (cmdLineTokens[0].compareToIgnoreCase("fn") == 0) {
			if (cmdLineTokens.length == 2) {
				if (z88.getZ80engine() != null) {
					displayCmdOutput("Cannot change	Add./Sub. flag while Z88 is running!");
					return;
				}
				if (StringEval.toInteger(cmdLineTokens[1]) == 0)
					z88.fN = false;
				else
					z88.fN = true;
			} else {
				// toggle/invert flag status
				z88.fN = !z88.fN;
			}
			displayCmdOutput("F=" +	Z88Info.z80Flags() + " (" + Dz.byteToBin(z88.F(),true) + ")");
		}

		if (cmdLineTokens[0].compareToIgnoreCase("fv") == 0) {
			if (cmdLineTokens.length == 2) {
				if (z88.getZ80engine() != null) {
					displayCmdOutput("Cannot change	Parity flag while Z88 is running!");
					return;
				}
				if (StringEval.toInteger(cmdLineTokens[1]) == 0)
					z88.fPV	= false;
				else
					z88.fPV	= true;
			} else {
				// toggle/invert flag status
				z88.fPV	= !z88.fPV;
			}
			displayCmdOutput("F=" +	Z88Info.z80Flags() + " (" + Dz.byteToBin(z88.F(),true) + ")");
		}

		if (cmdLineTokens[0].compareToIgnoreCase("a") == 0) {
			if (cmdLineTokens.length == 2) {
				if (z88.getZ80engine() != null) {
					displayCmdOutput("Cannot change	A register while Z88 is	running!");
					return;
				}
				arg = StringEval.toInteger(cmdLineTokens[1]); 
				if (arg == -1 | arg > 255) {
					displayCmdOutput(illegalArgumentMessage);
					return;
				} else {
					z88.A(arg);
				}
			}
			displayCmdOutput("A=" +	Dz.byteToHex(z88.A(),true) + " (" + Dz.byteToBin(z88.A(),true) + ")");
		}

		if (cmdLineTokens[0].compareToIgnoreCase("a'") == 0) {
			if (cmdLineTokens.length == 2) {
				if (z88.getZ80engine() != null) {
					displayCmdOutput("Cannot change	alternate A register while Z88 is running!");
					return;
				}
				arg = StringEval.toInteger(cmdLineTokens[1]); 
				if (arg == -1 | arg > 255) {
					displayCmdOutput(illegalArgumentMessage);
					return;
				} else {
					z88.ex_af_af();
					z88.A(arg);
					z88.ex_af_af();
				}
			}
			z88.ex_af_af();
			displayCmdOutput("A'=" + Dz.byteToHex(z88.A(),true) + " (" + Dz.byteToBin(z88.A(),true) + ")");
			z88.ex_af_af();
		}

		if (cmdLineTokens[0].compareToIgnoreCase("b") == 0) {
			if (cmdLineTokens.length == 2) {
				if (z88.getZ80engine() != null) {
					displayCmdOutput("Cannot change	B register while Z88 is	running!");
					return;
				}
				arg = StringEval.toInteger(cmdLineTokens[1]); 
				if (arg == -1 | arg > 255) {
					displayCmdOutput(illegalArgumentMessage);
					return;
				} else {
					z88.B(arg);
				}
			}
			displayCmdOutput("B=" +	Dz.byteToHex(z88.B(),true) + " (" + Dz.byteToBin(z88.B(),true) + ")");
		}

		if (cmdLineTokens[0].compareToIgnoreCase("c") == 0) {
			if (cmdLineTokens.length == 2) {
				if (z88.getZ80engine() != null) {
					displayCmdOutput("Cannot change	C register while Z88 is	running!");
					return;
				}
				arg = StringEval.toInteger(cmdLineTokens[1]); 
				if (arg == -1 | arg > 255) {
					displayCmdOutput(illegalArgumentMessage);
					return;
				} else {
					z88.C(arg);					
				}
			}
			displayCmdOutput("C=" +	Dz.byteToHex(z88.C(),true) + " (" + Dz.byteToBin(z88.C(),true) + ")");
		}

		if (cmdLineTokens[0].compareToIgnoreCase("b'") == 0) {
			if (cmdLineTokens.length == 2) {
				if (z88.getZ80engine() != null) {
					displayCmdOutput("Cannot change	alternate B register while Z88 is running!");
					return;
				}
				arg = StringEval.toInteger(cmdLineTokens[1]); 
				if (arg == -1 | arg > 255) {
					displayCmdOutput(illegalArgumentMessage);
					return;
				} else {
					z88.exx();
					z88.B(arg);
					z88.exx();
				}
			}
			z88.exx();
			displayCmdOutput("B'=" + Dz.byteToHex(z88.B(),true) + " (" + Dz.byteToBin(z88.B(),true) + ")");
			z88.exx();
		}

		if (cmdLineTokens[0].compareToIgnoreCase("c'") == 0) {
			if (cmdLineTokens.length == 2) {
				if (z88.getZ80engine() != null) {
					displayCmdOutput("Cannot change	alternate C register while Z88 is running!");
					return;
				}
				arg = StringEval.toInteger(cmdLineTokens[1]); 
				if (arg == -1 | arg > 255) {
					displayCmdOutput(illegalArgumentMessage);
					return;
				} else {
					z88.exx();
					z88.C(Integer.parseInt(cmdLineTokens[1], 16) & 0xFF);
					z88.exx();
				}
			}
			z88.exx();
			displayCmdOutput("C'=" + Dz.byteToHex(z88.C(),true) + " (" + Dz.byteToBin(z88.C(),true) + ")");
			z88.exx();
		}

		if (cmdLineTokens[0].compareToIgnoreCase("bc") == 0) {
			if (cmdLineTokens.length == 2) {
				if (z88.getZ80engine() != null) {
					displayCmdOutput("Cannot change	BC register while Z88 is running!");
					return;
				}
				arg = StringEval.toInteger(cmdLineTokens[1]); 
				if (arg == -1 | arg > 65535) {
					displayCmdOutput(illegalArgumentMessage);
					return;
				} else {
					z88.BC(arg);
				}
			}
			displayCmdOutput("BC=" + Dz.addrToHex(z88.BC(),true) + " (" + z88.BC() + "d)");
		}

		if (cmdLineTokens[0].compareToIgnoreCase("bc'")	== 0) {
			if (cmdLineTokens.length == 2) {
				if (z88.getZ80engine() != null) {
					displayCmdOutput("Cannot change	alternate BC register while Z88	is running!");
					return;
				}
				arg = StringEval.toInteger(cmdLineTokens[1]); 
				if (arg == -1 | arg > 65535) {
					displayCmdOutput(illegalArgumentMessage);
					return;
				} else {				
					z88.exx();
					z88.BC(arg);
					z88.exx();
				}				
			}
			z88.exx();
			displayCmdOutput("BC'="	+ Dz.addrToHex(z88.BC(),true) + " (" + z88.BC() + "d)");
			z88.exx();
		}

		if (cmdLineTokens[0].compareToIgnoreCase("d") == 0) {
			if (cmdLineTokens.length == 2) {
				if (z88.getZ80engine() != null) {
					displayCmdOutput("Cannot change	D register while Z88 is	running!");
					return;
				}
				arg = StringEval.toInteger(cmdLineTokens[1]); 
				if (arg == -1 | arg > 255) {
					displayCmdOutput(illegalArgumentMessage);
					return;
				} else {
					z88.D(arg);
				}
			}
			displayCmdOutput("D=" +	Dz.byteToHex(z88.D(),true) + " (" + Dz.byteToBin(z88.D(),true) + ")");
		}

		if (cmdLineTokens[0].compareToIgnoreCase("e") == 0) {
			if (cmdLineTokens.length == 2) {
				if (z88.getZ80engine() != null) {
					displayCmdOutput("Cannot change	E register while Z88 is	running!");
					return;
				}
				arg = StringEval.toInteger(cmdLineTokens[1]); 
				if (arg == -1 | arg > 255) {
					displayCmdOutput(illegalArgumentMessage);
					return;
				} else {
					z88.E(arg);
				}
			}
			displayCmdOutput("E=" +	Dz.byteToHex(z88.E(),true) + " (" + Dz.byteToBin(z88.E(),true) + ")");
		}

		if (cmdLineTokens[0].compareToIgnoreCase("d'") == 0) {
			if (cmdLineTokens.length == 2) {
				if (z88.getZ80engine() != null) {
					displayCmdOutput("Cannot change	alternate D register while Z88 is running!");
					return;
				}
				arg = StringEval.toInteger(cmdLineTokens[1]); 
				if (arg == -1 | arg > 255) {
					displayCmdOutput(illegalArgumentMessage);
					return;
				} else {
					z88.exx();
					z88.D(arg);
					z88.exx();
				}
			}
			z88.exx();
			displayCmdOutput("D'=" + Dz.byteToHex(z88.D(),true) + " (" + Dz.byteToBin(z88.D(),true) + ")");
			z88.exx();
		}

		if (cmdLineTokens[0].compareToIgnoreCase("e'") == 0) {
			if (cmdLineTokens.length == 2) {
				if (z88.getZ80engine() != null) {
					displayCmdOutput("Cannot change	alternate E register while Z88 is running!");
					return;
				}
				arg = StringEval.toInteger(cmdLineTokens[1]); 
				if (arg == -1 | arg > 255) {
					displayCmdOutput(illegalArgumentMessage);
					return;
				} else {
					z88.exx();
					z88.E(arg);
					z88.exx();
				}
			}
			z88.exx();
			displayCmdOutput("E'=" + Dz.byteToHex(z88.E(),true) + " (" + Dz.byteToBin(z88.E(),true) + ")");
			z88.exx();
		}

		if (cmdLineTokens[0].compareToIgnoreCase("de") == 0) {
			if (cmdLineTokens.length == 2) {
				if (z88.getZ80engine() != null) {
					displayCmdOutput("Cannot change	DE register while Z88 is running!");
					return;
				}
				arg = StringEval.toInteger(cmdLineTokens[1]); 
				if (arg == -1 | arg > 65535) {
					displayCmdOutput(illegalArgumentMessage);
					return;
				} else {				
					z88.DE(arg);
				}				
			}
			displayCmdOutput("DE=" + Dz.addrToHex(z88.DE(),true) + " (" + z88.DE() + "d)");
		}

		if (cmdLineTokens[0].compareToIgnoreCase("de'")	== 0) {
			if (cmdLineTokens.length == 2) {
				if (z88.getZ80engine() != null) {
					displayCmdOutput("Cannot change	alternate DE register while Z88	is running!");
					return;
				}
				arg = StringEval.toInteger(cmdLineTokens[1]); 
				if (arg == -1 | arg > 65535) {
					displayCmdOutput(illegalArgumentMessage);
					return;
				} else {				
					z88.exx();
					z88.DE(arg);
					z88.exx();
				}				
			}
			z88.exx();
			displayCmdOutput("DE'="	+ Dz.addrToHex(z88.DE(),true) + " (" + z88.DE() + "d)");
			z88.exx();
		}

		if (cmdLineTokens[0].compareToIgnoreCase("h") == 0) {
			if (cmdLineTokens.length == 2) {
				if (z88.getZ80engine() != null) {
					displayCmdOutput("Cannot change	H register while Z88 is	running!");
					return;
				}
				arg = StringEval.toInteger(cmdLineTokens[1]); 
				if (arg == -1 | arg > 255) {
					displayCmdOutput(illegalArgumentMessage);
					return;
				} else {
					z88.H(arg);
				}
			}
			displayCmdOutput("H=" +	Dz.byteToHex(z88.H(),true) + " (" + Dz.byteToBin(z88.H(),true) + ")");
		}

		if (cmdLineTokens[0].compareToIgnoreCase("l") == 0) {
			if (cmdLineTokens.length == 2) {
				if (z88.getZ80engine() != null) {
					displayCmdOutput("Cannot change	L register while Z88 is	running!");
					return;
				}
				arg = StringEval.toInteger(cmdLineTokens[1]); 
				if (arg == -1 | arg > 255) {
					displayCmdOutput(illegalArgumentMessage);
					return;
				} else {
					z88.L(arg);
				}
			}
			displayCmdOutput("L=" +	Dz.byteToHex(z88.L(),true) + " (" + Dz.byteToBin(z88.L(),true) + ")");
		}

		if (cmdLineTokens[0].compareToIgnoreCase("h'") == 0) {
			if (cmdLineTokens.length == 2) {
				if (z88.getZ80engine() != null) {
					displayCmdOutput("Cannot change	alternate H register while Z88 is running!");
					return;
				}
				arg = StringEval.toInteger(cmdLineTokens[1]); 
				if (arg == -1 | arg > 255) {
					displayCmdOutput(illegalArgumentMessage);
					return;
				} else {
					z88.exx();
					z88.H(arg);
					z88.exx();
				}
			}
			z88.exx();
			displayCmdOutput("H'=" + Dz.byteToHex(z88.H(),true) + " (" + Dz.byteToBin(z88.H(),true) + ")");
			z88.exx();
		}

		if (cmdLineTokens[0].compareToIgnoreCase("l'") == 0) {
			if (cmdLineTokens.length == 2) {
				if (z88.getZ80engine() != null) {
					displayCmdOutput("Cannot change	alternate L register while Z88 is running!");
					return;
				}
				arg = StringEval.toInteger(cmdLineTokens[1]); 
				if (arg == -1 | arg > 255) {
					displayCmdOutput(illegalArgumentMessage);
					return;
				} else {
					z88.exx();
					z88.L(arg);
					z88.exx();
				}
			}
			z88.exx();
			displayCmdOutput("L'=" + Dz.byteToHex(z88.L(),true) + " (" + Dz.byteToBin(z88.L(),true) + ")");
			z88.exx();
		}

		if (cmdLineTokens[0].compareToIgnoreCase("hl") == 0) {
			if (cmdLineTokens.length == 2) {
				if (z88.getZ80engine() != null) {
					displayCmdOutput("Cannot change	HL register while Z88 is running!");
					return;
				}
				arg = StringEval.toInteger(cmdLineTokens[1]); 
				if (arg == -1 | arg > 65535) {
					displayCmdOutput(illegalArgumentMessage);
					return;
				} else {				
					z88.HL(arg);
				}				
			}
			displayCmdOutput("HL=" + Dz.addrToHex(z88.HL(),true) + " (" + z88.HL() + "d)");
		}

		if (cmdLineTokens[0].compareToIgnoreCase("hl'")	== 0) {
			if (cmdLineTokens.length == 2) {
				if (z88.getZ80engine() != null) {
					displayCmdOutput("Cannot change	alternate HL register while Z88	is running!");
					return;
				}
				arg = StringEval.toInteger(cmdLineTokens[1]); 
				if (arg == -1 | arg > 65535) {
					displayCmdOutput(illegalArgumentMessage);
					return;
				} else {				
					z88.exx();
					z88.HL(arg);
					z88.exx();
				}				
			}
			z88.exx();
			displayCmdOutput("HL'="	+ Dz.addrToHex(z88.HL(),true) + " (" + z88.HL() + "d)");
			z88.exx();
		}

		if (cmdLineTokens[0].compareToIgnoreCase("ix") == 0) {
			if (cmdLineTokens.length == 2) {
				if (z88.getZ80engine() != null) {
					displayCmdOutput("Cannot change	IX register while Z88 is running!");
					return;
				}
				arg = StringEval.toInteger(cmdLineTokens[1]); 
				if (arg == -1 | arg > 65535) {
					displayCmdOutput(illegalArgumentMessage);
					return;
				} else {				
					z88.IX(arg);
				}				
			}
			displayCmdOutput("IX=" + Dz.addrToHex(z88.IX(),true) + " (" + z88.IX() + "d)");
		}

		if (cmdLineTokens[0].compareToIgnoreCase("iy") == 0) {
			if (cmdLineTokens.length == 2) {
				if (z88.getZ80engine() != null) {
					displayCmdOutput("Cannot change	IY register while Z88 is running!");
					return;
				}
				arg = StringEval.toInteger(cmdLineTokens[1]); 
				if (arg == -1 | arg > 65535) {
					displayCmdOutput(illegalArgumentMessage);
					return;
				} else {				
					z88.IY(arg);
				}				
			}
			displayCmdOutput("IY=" + Dz.addrToHex(z88.IY(),true) + " (" + z88.IY() + "d)");
		}

		if (cmdLineTokens[0].compareToIgnoreCase("sp") == 0) {
			if (cmdLineTokens.length == 2) {
				if (z88.getZ80engine() != null) {
					displayCmdOutput("Cannot change	SP register while Z88 is running!");
					return;
				}
				arg = StringEval.toInteger(cmdLineTokens[1]); 
				if (arg == -1 | arg > 65535) {
					displayCmdOutput(illegalArgumentMessage);
					return;
				} else {				
					z88.SP(arg);
				}				
			}
			displayCmdOutput("SP=" + Dz.addrToHex(z88.SP(),true) + " (" + z88.SP() + "d)");
		}

		if (cmdLineTokens[0].compareToIgnoreCase("pc") == 0) {
			if (cmdLineTokens.length == 2) {
				if (z88.getZ80engine() != null) {
					displayCmdOutput("Cannot change	PC register while Z88 is running!");
					return;
				}
				arg = StringEval.toInteger(cmdLineTokens[1]); 
				if (arg == -1 | arg > 65535) {
					displayCmdOutput(illegalArgumentMessage);
					return;
				} else {				
					z88.PC(arg);
				}				
			}
			displayCmdOutput("PC=" + Dz.addrToHex(z88.PC(),true) + " (" + z88.PC() + "d)");
		}
	}

	/**
	 * Display current Z80 instruction and simple register dump,
	 * and preset a single stepping or subroutine debug command.
	 */
	public void initDebugCmdline() {
		displayCmdOutput(Z88Info.dzPcStatus(z88.PC()));
		getDebugGui().getCmdLineInputArea().setText(Dz.getNextStepCommand());
		getDebugGui().getCmdLineInputArea().setCaretPosition(getDebugGui().getCmdLineInputArea().getDocument().getLength());
		getDebugGui().getCmdLineInputArea().selectAll();
		getDebugGui().getCmdLineInputArea().grabFocus();	// Z88 is stopped, get focus to	debug command line.		
	}
	
	private	void fcdCommandline(String[] cmdLineTokens) {
		try {
			if (cmdLineTokens.length == 1) {
				// no sub-commands are specified, just list file area contents...
				FileArea fa = new FileArea(cmdLineTokens[0].getBytes()[3]-48);
				ListIterator fileEntries = fa.getFileEntries();

				if (fileEntries == null) {
					displayCmdOutput("File area is empty.");
				} else {
					displayCmdOutput("File area:");
					while (fileEntries.hasNext()) {
						FileEntry fe = (FileEntry) fileEntries.next();
						displayCmdOutput(fe.getFileName() + 
										((fe.isDeleted() == true) ? " [d]": "") + 
										", size=" + fe.getFileLength() + " bytes" +
										", entry=" + Dz.extAddrToHex(fe.getFileEntryPtr(),true));
					}					
				}
			} else if (cmdLineTokens.length == 2 & cmdLineTokens[1].compareToIgnoreCase("format") == 0) {
				// create or (re)format file area
				if (FileArea.create( cmdLineTokens[0].getBytes()[3]-48, true) == true) 
					displayCmdOutput("File area were created/formatted.");
				else
					displayCmdOutput("File area could not be created/formatted.");
			
			} else if (cmdLineTokens.length == 2 & cmdLineTokens[1].compareToIgnoreCase("cardhdr") == 0) {
				// just create a file area header
				if (FileArea.create( cmdLineTokens[0].getBytes()[3]-48, false) == true) 
					displayCmdOutput("File area header were created.");
				else
					displayCmdOutput("File area header could not be created.");
			
			} else if (cmdLineTokens.length == 2 & cmdLineTokens[1].compareToIgnoreCase("reclaim") == 0) {
				// reclaim deleted file space
 				FileArea fa = new FileArea(cmdLineTokens[0].getBytes()[3]-48);
				fa.reclaimDeletedFileSpace(); 
				displayCmdOutput("Deleted files have been removed from file area.");

			} else if (cmdLineTokens.length == 3 & cmdLineTokens[1].compareToIgnoreCase("del") == 0) {
				// mark file as deleted
				FileArea fa = new FileArea(cmdLineTokens[0].getBytes()[3]-48);
				if (fa.markAsDeleted(cmdLineTokens[2]) == true) 
					displayCmdOutput("File was marked as deleted.");
				else
					displayCmdOutput("File not found.");
				
			} else if (cmdLineTokens.length == 3 & cmdLineTokens[1].compareToIgnoreCase("ipf") == 0) {
				// import file from host file system into file area...
				FileArea fa = new FileArea(cmdLineTokens[0].getBytes()[3]-48);
				fa.importHostFile(new File(cmdLineTokens[2]));
				displayCmdOutput("File " + cmdLineTokens[2] + " was successfully imported.");
				
			} else if (cmdLineTokens.length == 3 & cmdLineTokens[1].compareToIgnoreCase("ipd") == 0) {
				// import all files from host file system directory into file area...
				FileArea fa = new FileArea(cmdLineTokens[0].getBytes()[3]-48);
				fa.importHostFiles(new File(cmdLineTokens[2]));
				displayCmdOutput("Directory '"+cmdLineTokens[2] + "' was successfully imported.");
				
			} else if (cmdLineTokens.length == 3 & cmdLineTokens[1].compareToIgnoreCase("xpc") == 0) {
				// export all files from file area to directory on host file system..
				FileArea fa = new FileArea(cmdLineTokens[0].getBytes()[3]-48);
				ListIterator fileEntries = fa.getFileEntries();
				if (fa.getActiveFileCount() == 0) {
					displayCmdOutput("No files available to export.");
				} else {
					while (fileEntries.hasNext()) {
						FileEntry fe = (FileEntry) fileEntries.next();

						if (fe.isDeleted() == false) {
							// strip the "oz" path of the filename
							String hostFileName = fe.getFileName();
							hostFileName = hostFileName.substring(hostFileName.lastIndexOf("/")+1);
							// and build a complete file name for the host file system
							hostFileName = cmdLineTokens[2] + File.separator + hostFileName;
	
							// create a new file in specified host directory
							RandomAccessFile expFile = new RandomAccessFile(hostFileName, "rw");						
							expFile.write(fe.getFileImage()); // export file image to host file system
							expFile.close();
							
							displayCmdOutput("Exported " + fe.getFileName() + " to " + hostFileName);
						}
					}					
				} 
				
			} else if (cmdLineTokens.length == 4 & cmdLineTokens[1].compareToIgnoreCase("xpf") == 0) {
				// export file from file area to directory on host file system
				FileArea fa = new FileArea(cmdLineTokens[0].getBytes()[3]-48);
				FileEntry fe = fa.getFileEntry(cmdLineTokens[2]);
				if (fe == null) {
					displayCmdOutput("File not found.");
				} else {
					// strip the "oz" path of the filename
					String hostFileName = fe.getFileName();
					hostFileName = hostFileName.substring(hostFileName.lastIndexOf("/")+1);
					// and build a complete file name for the host file system
					hostFileName = cmdLineTokens[3] + File.separator + hostFileName;

					// create a new file in specified host directory
					RandomAccessFile expFile = new RandomAccessFile(hostFileName, "rw");						
					expFile.write(fe.getFileImage()); // export file image to host file system
					expFile.close();
					
					displayCmdOutput("Exported " + fe.getFileName() + " to " + hostFileName);
				}
			} else {
				displayCmdOutput("Unknown file card command or missing arguments.");
			}
		} catch (FileAreaNotFoundException e) {
			displayCmdOutput("No file area found in slot.");
		} catch (FileAreaExhaustedException e) {
			displayCmdOutput("No more room in file area. One or several files could not be imported.");
		} catch (IOException e) {
			displayCmdOutput("I/O error occurred during import/export of files.");
		} 
	}
	
	private	void bpCommandline(String[] cmdLineTokens) throws IOException {
		int bpAddress;

		if (cmdLineTokens.length == 2) {
			if (z88.getZ80engine() != null) {
				displayCmdOutput("Breakpoints cannot be	edited while Z88 is running.");
				return;
			} else {
				bpAddress = Integer.parseInt(cmdLineTokens[1], 16);

				if (bpAddress >	65535) {
					bpAddress &= 0xFF3FFF;	// strip segment mask
				} else {
					if (cmdLineTokens[1].length() == 6) {
						// bank	defined	as '00'
						bpAddress &= 0x3FFF;	// strip segment mask
					} else {
						bpAddress = z88.decodeLocalAddress(bpAddress); // local	address	-> ext.address
					}
				}
			}

			breakPointManager.toggleBreakpoint(bpAddress, true);
			displayCmdOutput(breakPointManager.displayBreakpoints());
		}

		if (cmdLineTokens.length == 1) {
			// no arguments, use PC	in current bank	binding
			displayCmdOutput(breakPointManager.displayBreakpoints());
		}
	}

	private	void bpdCommandline(String[] cmdLineTokens) throws IOException {
		int bpAddress;

		if (cmdLineTokens.length == 2) {
			if (z88.getZ80engine() != null) {
				displayCmdOutput("Display Breakpoints cannot be	edited while Z88 is running.");
				return;
			} else {
				bpAddress = Integer.parseInt(cmdLineTokens[1], 16);

				if (bpAddress >	65535) {
					bpAddress &= 0xFF3FFF;	// strip segment mask
				} else {
					if (cmdLineTokens[1].length() == 6) {
						// bank	defined	as '00'
						bpAddress &= 0x3FFF;	// strip segment mask
					} else {
						bpAddress = z88.decodeLocalAddress(bpAddress); // local	address	-> ext.address
					}
				}
			}

			breakPointManager.toggleBreakpoint(bpAddress, false);
			displayCmdOutput(breakPointManager.displayBreakpoints());
		}

		if (cmdLineTokens.length == 1) {
			// no arguments, use PC	in current bank	binding
			displayCmdOutput(breakPointManager.displayBreakpoints());
		}
	}

	private	void dzCommandline(String[] cmdLineTokens) {
		boolean	localAddressing	= true;
		int dzAddr = 0,	dzBank = 0;
		StringBuffer dzLine = new StringBuffer(64);

		if (cmdLineTokens.length == 2) {
			// one argument; the local Z80 64K address or a	compact	24bit extended address
			dzAddr = Integer.parseInt(cmdLineTokens[1], 16);
			if (dzAddr > 65535) {
				dzBank = (dzAddr >>> 16) & 0xFF;
				dzAddr &= 0xFFFF;	// bank	offset (with simulated segment addressing)
				localAddressing	= false;
			} else {
				if (cmdLineTokens[1].length() == 6) {
					// bank	defined	as '00'
					dzBank = 0;
					localAddressing	= false;
				} else {
					localAddressing	= true;
				}
			}
		} else {
			if (cmdLineTokens.length == 1) {
				// no arguments, use PC	in current bank	binding	(use local addressing)...
				dzAddr = z88.PC();
				localAddressing	= true;
			} else {
				displayCmdOutput("Illegal argument.");
				return;
			}
		}

		if (localAddressing == true) {
			for (int dzLines = 0;  dzLines < 16; dzLines++)	{
				int origAddr = dzAddr;
				dzAddr = dz.getInstrAscii(dzLine, dzAddr, false, true);
				displayCmdOutput(Dz.addrToHex(origAddr,false) +	" (" + Dz.extAddrToHex(z88.decodeLocalAddress(origAddr),false).toString() + ") " + dzLine.toString());
			}

			debugGui.getCmdLineInputArea().setText("dz "	+ Dz.addrToHex(dzAddr,false));
		} else {
			// extended addressing
			for (int dzLines = 0;  dzLines < 16; dzLines++)	{
				int origAddr = dzAddr;
				dzAddr = dz.getInstrAscii(dzLine, dzAddr, dzBank, false, true);
				displayCmdOutput(Dz.extAddrToHex((dzBank << 16)	| origAddr,false) + " "	+ dzLine);
			}

			debugGui.getCmdLineInputArea().setText("dz "	+ Dz.extAddrToHex((dzBank << 16) | dzAddr,false));
		}
		debugGui.getCmdLineInputArea().setCaretPosition(debugGui.getCmdLineInputArea().getDocument().getLength());
		debugGui.getCmdLineInputArea().selectAll();
	}

	private	int getMemoryAscii(StringBuffer	memLine, int memAddr) {
		int memHex, memAscii;

		memLine.delete(0,255);
		for (memHex=memAddr; memHex < memAddr+16; memHex++) {
			memLine.append(Dz.byteToHex(z88.readByte(memHex),false)).append(" ");
		}

		for (memAscii=memAddr; memAscii	< memAddr+16; memAscii++) {
			int b =	z88.readByte(memAscii);
			memLine.append(	(b >= 32 && b <= 127) ?	Character.toString( (char) b) :	"." );
		}

		return memAscii;
	}

	private	int getMemoryAscii(StringBuffer	memLine, int memAddr, int memBank) {
		int memHex, memAscii;

		memLine.delete(0,255);
		for (memHex=memAddr; memHex < memAddr+16; memHex++) {
			memLine.append(Dz.byteToHex(memory.getByte(memHex,memBank),false)).append(" ");
		}

		for (memAscii=memAddr; memAscii	< memAddr+16; memAscii++) {
			int b =	memory.getByte(memAscii,memBank);
			memLine.append(	(b >= 32 && b <= 127) ?	Character.toString( (char) b) :	"." );
		}

		return memAscii;
	}


	private	void putByte(String[] cmdLineTokens) throws IOException	{
		int argByte[], memAddress, memBank, aByte;

		if (cmdLineTokens.length >= 3 &	cmdLineTokens.length <=	18) {
			memAddress = Integer.parseInt(cmdLineTokens[1],	16);
			memBank	= (memAddress >>> 16) &	0xFF;
			memAddress &= 0xFFFF;
			argByte	= new int[cmdLineTokens.length - 2];
			for (aByte= 0; aByte < cmdLineTokens.length - 2; aByte++) {
				argByte[aByte] = Integer.parseInt(cmdLineTokens[2 + aByte], 16);
			}
		} else {
			displayCmdOutput("Illegal argument(s).");
			return;
		}

		StringBuffer memLine = new StringBuffer(256);
		getMemoryAscii(memLine, memAddress, memBank);
		displayCmdOutput("Before:\n" + memLine);
		for (aByte= 0; aByte < cmdLineTokens.length - 2; aByte++) {
			memory.setByte(memAddress + aByte, memBank, argByte[aByte]);
		}

		getMemoryAscii(memLine, memAddress, memBank);
		displayCmdOutput("After:\n" + memLine);
	}


	private	void viewMemory(String[] cmdLineTokens)	{
		boolean	localAddressing	= true;
		int memAddr = 0, memBank = 0;
		StringBuffer memLine = new StringBuffer(256);

		if (cmdLineTokens.length == 2) {
			// one argument; the local Z80 64K address or 24bit compact ext. address
			memAddr	= Integer.parseInt(cmdLineTokens[1], 16);

			if (memAddr > 65535) {
				memBank	= (memAddr >>> 16) & 0xFF;
				memAddr	&= 0xFFFF;
				localAddressing	= false;
			} else {
				if (cmdLineTokens[1].length() == 6) {
					// bank	defined	as '00'
					memBank	= 0;
					localAddressing	= false;
				} else {
					localAddressing	= true;
				}
			}
		} else {
			if (cmdLineTokens.length == 1) {
				// no arguments, use PC	in current bank	binding	(use local addressing)...
				memAddr	= z88.PC();
				localAddressing	= true;
			} else {
				displayCmdOutput("Illegal argument.");
				return;
			}
		}

		if (localAddressing == true) {
			for (int memLines = 0;	memLines < 16; memLines++) {
				int origAddr = memAddr;
				memAddr	= getMemoryAscii(memLine, memAddr);
				displayCmdOutput(Dz.addrToHex(origAddr,	false) + " (" +
						Dz.extAddrToHex(z88.decodeLocalAddress(origAddr),false).toString() + ")	" +
						memLine.toString());
			}

			debugGui.getCmdLineInputArea().setText("m " + Dz.addrToHex(memAddr,false));
		} else {
			// extended addressing
			for (int memLines = 0;	memLines < 16; memLines++) {
				int origAddr = memAddr;
				memAddr	= getMemoryAscii(memLine, memAddr, memBank);
				memAddr	&= 0xFFFF; // stay within bank boundary..
				displayCmdOutput(Dz.extAddrToHex((memBank << 16) | origAddr,false) + " " + memLine.toString());
			}

			debugGui.getCmdLineInputArea().setText("m " + Dz.extAddrToHex((memBank << 16) | memAddr,false));
		}

		debugGui.getCmdLineInputArea().setCaretPosition(debugGui.getCmdLineInputArea().getDocument().getLength());
		debugGui.getCmdLineInputArea().selectAll();
	}

	
	public void keyPressed(KeyEvent	e) {
		switch (e.getKeyCode())	{
			case KeyEvent.VK_F12:
				Z88display.getInstance().grabFocus();
				break;

			case KeyEvent.VK_UP:
				// replace current contents of command line with previous
				// input from command history and remember new position	in list.
				String prevCmd = cmdList.browsePrevCommand();
				if (prevCmd != null) {
					debugGui.getCmdLineInputArea().setText(prevCmd);
					debugGui.getCmdLineInputArea().setCaretPosition(debugGui.getCmdLineInputArea().getDocument().getLength());
					debugGui.getCmdLineInputArea().selectAll();
				}
				break;

			case KeyEvent.VK_DOWN:
				// replace current contents of command line with next
				// input from command history and remember new position	in list.
				String nextCmd = cmdList.browseNextCommand();
				if (nextCmd != null) {
					debugGui.getCmdLineInputArea().setText(nextCmd);
					debugGui.getCmdLineInputArea().setCaretPosition(debugGui.getCmdLineInputArea().getDocument().getLength());
					debugGui.getCmdLineInputArea().selectAll();
				}
				break;
		}
	}

	public void keyReleased(KeyEvent arg0) {
	}

	public void keyTyped(KeyEvent arg0) {
	}	
}