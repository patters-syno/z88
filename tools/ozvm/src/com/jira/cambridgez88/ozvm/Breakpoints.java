/*
 * Breakpoints.java
 * This file is part of OZvm.
 * 
 * OZvm is free software; you can redistribute it and/or modify it under the terms of the 
 * GNU General Public License as published by the Free Software Foundation;
 * either version 2, or (at your option) any later version.
 * OZvm is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY;
 * without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
 * See the GNU General Public License for more details.
 * You should have received a copy of the GNU General Public License along with OZvm;
 * see the file COPYING. If not, write to the
 * Free Software Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA 02111-1307, USA.
 * 
 * @author <A HREF="mailto:gstrube@gmail.com">Gunther Strube</A>
 *
 */

package com.jira.cambridgez88.ozvm;

import java.util.Map;
import java.util.HashMap;
import java.util.Iterator;


/**
 * Manage breakpoint addresses in Z88 virtual machine.
 */
public class Breakpoints {
    private Map breakPoints;
	private Breakpoint bpSearchKey;
	
    /**
     * Just instantiate this Breakpoint Manager
     */
    public Breakpoints() {
        breakPoints = new HashMap();        
		bpSearchKey = new Breakpoint(0);	// just create a dummy search key object (used by internal lookup) 
    }


	/**
	 * Add (if not created) or remove breakpoint (if prev. created).
	 *
	 * @param address 24bit extended address
	 */
	public void toggleBreakpoint(int bpAddress) {
        Breakpoint bp = new Breakpoint(bpAddress);
        if (breakPoints.containsKey( bp) == false)
            breakPoints.put( bp, bp);
        else
            breakPoints.remove( bp);
	}

	
	/**
	 * Add (if not created) or remove breakpoint (if prev. created).
	 *
	 * @param address 24bit extended address
	 * @param stopStatus
	 */
	public void toggleBreakpoint(int bpAddress, boolean stopStatus ) {
		Breakpoint bp = new Breakpoint(bpAddress, stopStatus);
		if (breakPoints.containsKey( bp) == false)
			breakPoints.put( bp, bp);
		else
			breakPoints.remove(bp);
	}

	
	/**
	 * Get the original Z80 opcode, located at this breakpoint.
	 *
	 * @param address 24bit extended (breakpoint) address
	 * @return Z80 opcode of breakpoint, or -1 if breakpoint wasn't found
	 */
	public int getOrigZ80Opcode(int bpAddress) {
		bpSearchKey.setBpAddress(bpAddress);
		Breakpoint bpv = (Breakpoint) breakPoints.get(bpSearchKey);
		if (bpv != null) {
			return bpv.getCopyOfOpcode();
		} else
			return -1;
	}

	
	/**
	 * Check if this breakpoint has been created.
	 *
	 * @param address 24bit extended (breakpoint) address
	 * @return true if breakpoint was found, else false.
	 */
	public boolean isCreated(int bpAddress) {
		bpSearchKey.setBpAddress(bpAddress);
		Breakpoint bpv = (Breakpoint) breakPoints.get(bpSearchKey);
		if (bpv != null) {
			return true;
		} else
			return false;
	}
	
	
	/**
	 * Return <true> if breakpoint will stop Z80 execution.
	 * (<false> means that it is a display breakpoint) 
	 *
	 * @param bpAddress 24bit extended address
	 * @return true, if breakpoint is defined to stop execution.
	 */
	public boolean isStoppable(int bpAddress) {
		bpSearchKey.setBpAddress(bpAddress);

		Breakpoint bpv = (Breakpoint) breakPoints.get(bpSearchKey);
		if (bpv != null && bpv.stop == true) {
			return true;
		} else
			return false;
	}

	
	/**
	 * Mark breakpoint as active.
	 * 
	 * @param bpAddress
	 */
	public void activate(int bpAddress) {
		bpSearchKey.setBpAddress(bpAddress);

		Breakpoint bpv = (Breakpoint) breakPoints.get(bpSearchKey);
		if (bpv != null)
			bpv.active = true;		
	}

	
	/**
	 * Mark breakpoint as suspended.
	 * 
	 * @param bpAddress
	 */
	public void suspend(int bpAddress) {
		bpSearchKey.setBpAddress(bpAddress);

		Breakpoint bpv = (Breakpoint) breakPoints.get(bpSearchKey);
		if (bpv != null)
			bpv.active = false;		
	}

	
	/**
	 * Return <true> if breakpoint is active
	 * (<false> if breakpoint is suspended; ie. will be ignored)
	 *
	 * @param bpAddress 24bit extended address
	 * @return true, if breakpoint is defined as active
	 */
	public boolean isActive(int bpAddress) {
		bpSearchKey.setBpAddress(bpAddress);

		Breakpoint bpv = (Breakpoint) breakPoints.get(bpSearchKey);
		if (bpv != null && bpv.active == true) {
			return true;
		} else
			return false;
	}

	
    /**
     * List breakpoints into String, so that caller decides to display them.
     */
    public String displayBreakpoints() {
    	StringBuffer output = new StringBuffer(1024);
    	output.append("Breakpoints:\n");
        if (breakPoints.isEmpty() == true) {
            return new String("No Breakpoints defined.");
        } else {
            Iterator keyIterator = breakPoints.entrySet().iterator();

            while(keyIterator.hasNext()) {
                Map.Entry e = (Map.Entry) keyIterator.next();
                Breakpoint bp = (Breakpoint) e.getKey();

				output.append(Dz.extAddrToHex(bp.getBpAddress(),false));
				output.append(bp.stop == false ? "[d]" : "");
				output.append("\t");
            }
			output.append("\n");
        }
        
        return output.toString();
    }

    
    /**
     * List breakpoints into String, that can be saved in a property.<br>
     * Each breakpoint is written in hex, separated with a comma.
     * If a break is a display-breakpoint, it is preceeded with a '[d]'. 
     * If no breakpoints are defined, an empty string is returned.
     */
    public String breakpointList() {
    	StringBuffer output = new StringBuffer(1024);
        if (breakPoints.isEmpty() == true) {
            return "";
        } else {
            Iterator keyIterator = breakPoints.entrySet().iterator();

            while(keyIterator.hasNext()) {
                Map.Entry e = (Map.Entry) keyIterator.next();
                Breakpoint bp = (Breakpoint) e.getKey();

				output.append(bp.stop == false ? "[d]" : "");
				output.append(Dz.extAddrToHex(bp.getBpAddress(),false));
				if (keyIterator.hasNext() == true)
					output.append(",");
            }
        }
        
        return output.toString();
    }
    
    
    /**
     * Install the "breakpoint" instruction in Z88 memory for all
     * currently defined (and active) breakpoints.
     */
    public void installBreakpoints() {
        // now, set the breakpoint at the extended address;
        // the instruction opcode 40 ("LD B,B"; quite useless!).
        // which this virtual machine identifies as a "suspend" Z80 exection.
        if (breakPoints.isEmpty() == false) {
            Iterator keyIterator = breakPoints.entrySet().iterator();

            while(keyIterator.hasNext()) {
                Map.Entry e = (Map.Entry) keyIterator.next();
                Breakpoint bp = (Breakpoint) e.getKey();

                if ((bp.active == true) && (bp.stop == true)) {
                	Z88.getInstance().getMemory().setByte(bp.getBpAddress(), 0x40);	// use "LD B,B" as stop breakpoint
                } else {
                	Z88.getInstance().getMemory().setByte(bp.getBpAddress(), 0x49);	// use "LD C,C" as display breakpoint
                }
            }
        }
    }

    
    /**
     * Clear the "breakpoint" instruction; ie. restore original bitpattern
     * that was overwritten by the "breakpoint" instruction in Z88 memory.
     */
    public void clearBreakpoints() {
        // restore at the extended address;
        // the original instruction opcode that is preserved inside
        // the BreakPoint object
        if (breakPoints.isEmpty() == false) {
            Iterator keyIterator = breakPoints.entrySet().iterator();

            while(keyIterator.hasNext()) {
                Map.Entry e = (Map.Entry) keyIterator.next();
                Breakpoint bp = (Breakpoint) e.getKey();

                // restore the original opcode bit pattern...
                Z88.getInstance().getMemory().setByte(bp.getBpAddress(), bp.getCopyOfOpcode() & 0xFF);
            }
        }
    }

    
    /**
     * Remove all registered breakpoints withing this container 
     * (using the displayBreakpoints() method afterwards will 
     * return a "No Breakpoints defined." string).<p>
     * 
     * This method is typically used when a snapshot is being loaded 
     * that might contain a different set of breakpoints; the current
     * set therefore needs to be removed before a new is loaded.  
     */
    public void removeBreakPoints() {
    	breakPoints.clear();
    }

    
    // The breakpoint container.
    private class Breakpoint {
        private int addressKey;			// the 24bit address of the breakpoint
        private int instr;				// the original 8bit opcode at breakpoint
        private boolean stop;			// true = stoppable breakpoint, false = display breakpoint
        private boolean active;			// true = breakpoint is active, false = breakpoint is suspended

		/**
		 * Create a breakpoint object.
		 *
		 * @param bpAddress 24bit extended address
		 */
		Breakpoint(int bpAddress) {
			stop = true;	// default behaviour is to stop execution at breakpoint
			active = true; 	// when a breakpoint is created it is active by default

			// the encoded key for the SortedSet...
			addressKey = bpAddress;

			// the original 1 byte opcode bit pattern in Z88 memory.
			setCopyOfOpcode(Z88.getInstance().getMemory().getByte(bpAddress));
		}

		Breakpoint(int bpAddress, boolean stopAtAddress) {
			// use <false> to display register status, then continue, <true> to stop execution.
			stop = stopAtAddress;
			active = true; 	// when a breakpoint is created it is active by default 

			// the encoded key for the SortedSet...
			addressKey = bpAddress;

			// the original 1 byte opcode bit pattern in Z88 memory.
			setCopyOfOpcode(Z88.getInstance().getMemory().getByte(bpAddress));
		}

        private void setBpAddress(int bpAddress) {
            addressKey = bpAddress;
        }

        private int getBpAddress() {
            return addressKey;
        }

        private void setCopyOfOpcode(int z80instr) {
            instr = z80instr;
        }

        private int getCopyOfOpcode() {
            return instr;
        }

        // override interface with the actual implementation for this object.
        public int hashCode() {
            return addressKey;	// the unique key is a perfect hash code
        }

        // override interface with the actual implementation for this object.
        public boolean equals(Object bp) {
            if (!(bp instanceof Breakpoint)) {
                return false;
            }

            Breakpoint aBreakpoint = (Breakpoint) bp;
            if (addressKey == aBreakpoint.addressKey)
                return true;
            else
                return false;
        }
    }
}
