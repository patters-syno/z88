package net.sourceforge.z88;

import java.io.BufferedInputStream;
import java.io.InputStream;
import java.io.RandomAccessFile;
import java.io.IOException;
import java.net.URL;
import java.net.JarURLConnection;
import java.util.Timer;
import java.util.TimerTask;

import gameframe.GameFrameException;
import gameframe.input.KeyboardDevice;

/**
 * Blink chip, the "mind" of the Z88.
 * @author <A HREF="mailto:gstrube@tiscali.dk">Gunther Strube</A>
 * 
 * $Id$
 */
public final class Blink extends Z80 {

	/**
	 * Blink class default constructor.
	 */
	Blink() throws GameFrameException {
		super();
		
		// the segment register SR0 - SR3
		sR = new int[4];
		// all segment registers points at ROM bank 0
		for (int segment = 0; segment < sR.length; segment++) {
			sR[segment] = 0;
		}

		memory = new Bank[256]; // The Z88 memory addresses 256 banks = 4MB!
		nullBank = new Bank(Bank.EPROM);
		for (int bank = 0; bank < memory.length; bank++)
			memory[bank] = nullBank;

		slotCards = new Bank[4][];
		// Instantiate the slot containers for Cards...
		for (int slot = 0; slot < 4; slot++)
			slotCards[slot] = null; // nothing available in slots..

		RAMS = memory[0];				// point at ROM bank 0 (null at the moment)
		
		timerDaemon = new Timer(true);
		
		rtc = new Rtc(); 				// the Real Time Clock counter, not yet started...
		z80Int = new Z80interrupt(); 	// the INT signals each 10ms to Z80, not yet started...
		
		z88Display = new Z88display(this);				// create window, but without activity yet...
		z88Keyboard = z88Display.getKeyboardDevice();	// keys are read from Z88 Window... 
	}

	/**
	 * The main Timer daemon that runs the Rtc clock and sends 10ms interrupts
	 * to the Z80 virtual processor.
	 */
	private Timer timerDaemon = null;
	
	public Timer getTimerDaemon() {
		return timerDaemon;
	}

	/**
	 * The 640x64 pixel display (here a window).
	 */
	private Z88display z88Display;
			
	/**
	 * The keyboard hardware (wich will be mapped to IN port)
	 */
	private KeyboardDevice z88Keyboard;
	
	/**
	 * The Real Time Clock (RTC) inside the BLINK.
	 */
	private Rtc rtc;

	/**
	 * The 10ms interupt line to the Z80 processor.
	 */
	private Z80interrupt z80Int;

	/**
	 * The container for the current loaded card entities in the Z88 memory
	 * system for slot 0, 1, 2 and 3.
	 *
	 * Slot 0 will only keep a RAM Card in top 512K address space
	 * The ROM "Card" is only loaded once at OZvm boot
	 * and is never removed.
	 */
	private Bank slotCards[][];

	/**
	 * Main Blink Interrrupts (INT).
	 * 
	 * <PRE>
	 * BIT 7, KWAIT  If set, reading the keyboard will Snooze
	 * BIT 6, A19    If set, an active high on A19 will exit Coma
	 * BIT 5, FLAP   If set, flap interrupts are enabled
	 * BIT 4, UART   If set, UART interrupts are enabled
	 * BIT 3, BTL    If set, battery low interrupts are enabled
	 * BIT 2, KEY    If set, keyboard interrupts (Snooze or Coma) are enabl.
	 * BIT 1, TIME   If set, RTC interrupts are enabled
	 * BIT 0, GINT   If clear, no interrupts get out of blink
	 * </PRE>
	 */
	private int INT = 0;

	public static final int BM_INTKWAIT = 0x80;	// Bit 7, If set, reading the keyboard will Snooze
	public static final int BM_INTA19 = 0x40;	// Bit 6, If set, an active high on A19 will exit Coma
	public static final int BM_INTFLAP = 0x20;	// Bit 5, If set, flap interrupts are enabled
	public static final int BM_INTUART = 0x10;	// Bit 4, If set, UART interrupts are enabled
	public static final int BM_INTBTL = 0x08;	// Bit 3, If set, battery low interrupts are enabled
	public static final int BM_INTKEY = 0x04;	// Bit 2, If set, keyboard interrupts (Snooze or Coma) are enabl.
	public static final int BM_INTTIME = 0x02;	// Bit 1, If set, RTC interrupts are enabled
	public static final int BM_INTGINT = 0x01;	// Bit 0, If clear, no interrupts get out of blink

	/**
	 * Set main Blink Interrrupts (INT), Z80 OUT Write Register. 
	 * 
	 * <pre>
	 * BIT 7, KWAIT  If set, reading the keyboard will Snooze
	 * BIT 6, A19    If set, an active high on A19 will exit Coma
	 * BIT 5, FLAP   If set, flap interrupts are enabled
	 * BIT 4, UART   If set, UART interrupts are enabled>
	 * BIT 3, BTL    If set, battery low interrupts are enabled
	 * BIT 2, KEY    If set, keyboard interrupts (Snooze or Coma) are enabled
	 * BIT 1, TIME   If set, RTC interrupts are enabled
	 * BIT 0, GINT   If clear, no interrupts get out of blink
	 * </pre>
	 * 
	 * @param bits
	 */
	public void setBlinkInt(int bits) {
		bits &= ~BM_INTUART;		// OZvm does not support UART...
		bits |= 1;       			// force GINT = 1, always...
		setByte(0x04B1,0x20, bits);	// force update soft copy!
		INT = bits;		
	}

	/**
	 * Get main Blink Interrrupts (INT), Z80 OUT Write Register. 
	 * 
	 * <pre>
	 * BIT 7, KWAIT  If set, reading the keyboard will Snooze
	 * BIT 6, A19    If set, an active high on A19 will exit Coma
	 * BIT 5, FLAP   If set, flap interrupts are enabled
	 * BIT 4, UART   If set, UART interrupts are enabled>
	 * BIT 3, BTL    If set, battery low interrupts are enabled
	 * BIT 2, KEY    If set, keyboard interrupts (Snooze or Coma) are enabled
	 * BIT 1, TIME   If set, RTC interrupts are enabled
	 * BIT 0, GINT   If clear, no interrupts get out of blink
	 * </pre>
	 * 
	 * @return INT Blink Register
	 */
   	public int getBlinkInt() {
		return INT;
	}

	/**
	 * Acknowledge Main Blink Interrrupts (ACK)
	 * 
	 * <PRE>
	 * BIT 6, A19    Acknowledge active high on A19 
	 * BIT 5, FLAP   Acknowledge Flap interrupts
	 * BIT 3, BTL    Acknowledge battery low interrupt
	 * BIT 2, KEY    Acknowledge keyboard interrupt
	 * </PRE>
	 */
	private int ACK = 0;

	public static final int BM_ACKA19 = 0x40;	// Bit 6, Acknowledge A19 interrupt
	public static final int BM_ACKFLAP = 0x20;	// Bit 5, Acknowledge flap interrupt
	public static final int BM_ACKBTL = 0x08;	// Bit 3, Acknowledge battery low interrupt
	public static final int BM_ACKKEY = 0x04;	// Bit 2, Acknowledge keyboard interrupt
	
	/**
	 * Set Main Blink Interrupt Acknowledge (ACK), Z80 OUT Register
	 * 
	 * <PRE>
	 * BIT 6, A19    Acknowledge active high on A19 
	 * BIT 5, FLAP   Acknowledge Flap interrupts
	 * BIT 3, BTL    Acknowledge battery low interrupt
	 * BIT 2, KEY    Acknowledge keyboard interrupt
	 * </PRE>
	 * 
	 * @param bits
	 */
	public void setBlinkAck(int bits) {
		ACK = bits;
		
		STA &= ~bits;	// reset Blink occurred interrupts according to acknowledge...
        STA |= 1;       // force GINT = 1
	}

   	/**
	 * Get Main Blink Interrupt Acknowledge (ACK), Z80 OUT Register
	 * 
	 * <PRE>
	 * BIT 6, A19    Acknowledge active high on A19 
	 * BIT 5, FLAP   Acknowledge Flap interrupts
	 * BIT 3, BTL    Acknowledge battery low interrupt
	 * BIT 2, KEY    Acknowledge keyboard interrupt
	 * </PRE>
	 * 
	 * @param bits
	 */
	public int getBlinkAck() {
		return ACK;
	}

	/**
	 * Main Blink Interrupt Status (STA)
	 * 
	 * <PRE>
	 * Bit 7, FLAPOPEN, If set, flap open, else flap closed
	 * Bit 6, A19, If set, high level on A19 occurred during coma
	 * Bit 5, FLAP, If set, positive edge has occurred on FLAPOPEN
	 * Bit 4, UART, If set, an enabled UART interrupt is active
	 * Bit 3, BTL, If set, battery low pin is active
	 * Bit 2, KEY, If set, a column has gone low in snooze (or coma)
	 * Bit 1, TIME, If set, an enabled TIME interrupt is active
	 * Bit 0, not defined.
	 * </PRE>
	 */
	private int STA;

	public static final int BM_STAFLAPOPEN = 0x80;	// Bit 7, If set, flap open, else flap closed 
	public static final int BM_STAA19 = 0x40;	// Bit 6, If set, high level on A19 occurred during coma
	public static final int BM_STAFLAP = 0x20;	// Bit 5, If set, positive edge has occurred on FLAPOPEN
	public static final int BM_STAUART = 0x10;	// Bit 4, If set, an enabled UART interrupt is active
	public static final int BM_STABTL = 0x08;	// Bit 3, If set, battery low pin is active
	public static final int BM_STAKEY = 0x04;	// Bit 2, If set, a column has gone low in snooze (or coma)
	public static final int BM_STATIME = 0x02;	// Bit 1, If set, an enabled TSTA interrupt is active
	
	/**
	 * Get Main Blink Interrupt Status (STA).
	 * 
	 * <PRE>
	 * Bit 7, FLAPOPEN, If set, flap open, else flap closed
	 * Bit 6, A19, If set, high level on A19 occurred during coma
	 * Bit 5, FLAP, If set, positive edge has occurred on FLAPOPEN
	 * Bit 4, UART, If set, an enabled UART interrupt is active
	 * Bit 3, BTL, If set, battery low pin is active
	 * Bit 2, KEY, If set, a column has gone low in snooze (or coma)
	 * Bit 1, TIME, If set, an enabled TSTA interrupt is active
	 * Bit 0, not defined.
	 * </PRE>
	 */
	public int getBlinkSta() {
        STA |= 1;       // force GINT = 1
		return STA;
	}
	
	/**
	 * Return Timer Interrupt Status (TSTA).
	 * 
	 * <PRE>
	 * BIT 2, MIN, Set if minute interrupt has occurred
	 * BIT 1, SEC, Set if second interrupt has occurred
	 * BIT 0, TICK, Set if tick interrupt has occurred
	 * </PRE>
	 * 
	 * @return TSTA
	 */
	public int getBlinkTsta() {
        return rtc.TSTA;
	}

	/**
	 * Set Timer interrupt acknowledge (TACK), Z80 OUT Write Register.
	 * 
	 * <PRE>
	 * BIT 2, MIN, Set to acknowledge minute interrupt
	 * BIT 1, SEC, Set to acknowledge
	 * BIT 0, TICK, Set to acknowledge tick interrupt
	 * </PRE>
	 */
	public void setBlinkTack(int bits) {
		rtc.TACK = bits;
		rtc.TSTA &= ~bits; 		// reset appropriate TSTA bits (the prev. raised interrupt get cleared) 
	}

	/**
	 * Get Timer interrupt acknowledge (TACK), Z80 OUT Write Register.
	 * 
	 * <PRE>
	 * BIT 2, MIN, Set to acknowledge minute interrupt
	 * BIT 1, SEC, Set to acknowledge
	 * BIT 0, TICK, Set to acknowledge tick interrupt
	 * </PRE>
	 */
	public int getBlinkTack() {
		return rtc.TACK;
	}

	/**
	 * Set Timer Interrupt Mask (TMK), Z80 OUT Write Register
	 *  
	 * <PRE>
	 * BIT 2, MIN, Set to enable minute interrupt
	 * BIT 1, SEC, Set to enable second interrupt
	 * BIT 0, TICK, Set enable tick interrupt
	 * </PRE>
	 */
	public void setBlinkTmk(int bits) {
		rtc.TMK = bits;
	}

	/**
	 * Get Timer Interrupt Mask (TMK), Z80 OUT Write Register
	 *  
	 * <PRE>
	 * BIT 2, MIN, Set to enable minute interrupt
	 * BIT 1, SEC, Set to enable second interrupt
	 * BIT 0, TICK, Set enable tick interrupt
	 * </PRE>
	 */
	public int getBlinkTmk() {
		return rtc.TMK;
	}

	/**
	 * Get current TIM0 register from the RTC.
	 * 
	 * @return int
	 */
	public int getBlinkTim0() {
		return rtc.TIM0;
	}

	/**
	 * Get current TIM1 register from the RTC.
	 * 
	 * @return int
	 */
	public int getBlinkTim1() {
		return rtc.TIM1;
	}

	/**
	 * Get current TIM2 register from the RTC.
	 * 
	 * @return int
	 */
	public int getBlinkTim2() {
		return rtc.TIM2;
	}

	/**
	 * Get current TIM3 register from the RTC.
	 * 
	 * @return int
	 */
	public int getBlinkTim3() {
		return rtc.TIM3;
	}

	/**
	 * Get current TIM4 register from the RTC.
	 * 
	 * @return int
	 */
	public int getBlinkTim4() {
		return rtc.TIM4;
	}

	/**
	 * LORES0 (PB0, 16bits).<br>
	 * The 6 * 8 pixel per char User Defined Fonts.
	 */
	private int PB0;

	/**
	 * Set LORES0 (PB0, 16bits).<br>
	 * The 6 * 8 pixel per char User Defined Fonts.
	 */
	public void setBlinkPb0(int bits) {
		PB0 = bits;
	}

	/**
	 * Get Address of LORES0 (PB0) in 24bit extended address format.<br>
	 * The 6 * 8 pixel per char User Defined Fonts.
	 */	
	public int getBlinkPb0() {
		int extAddressBank = (PB0 << 3) & 0xF700;
		int extAddressOffset = (PB0 << 1) & 0x003F;

		return (extAddressBank | extAddressOffset) << 8;
	}
	
	/**
	 * LORES1 (PB1, 16bits).<br>
	 * The 6 * 8 pixel per char fonts.
	 */
	private int PB1;

	/**
	 * Set LORES1 (PB1, 16bits).<br>
	 * The 6 * 8 pixel per char fonts.
	 */
	public void setBlinkPb1(int bits) {
		PB1 = bits;
	}

	/**
	 * Get Address of LORES1 (PB1) in 24bit extended address format.<br>
	 * The 6 * 8 pixel per char fonts.
	 */	
	public int getBlinkPb1() {
		int extAddressBank = (PB1 << 6) & 0xFF00;
		int extAddressOffset = (PB1 << 4) & 0x0030;

		return (extAddressBank | extAddressOffset) << 8;
	}
	
	/**
	 * HIRES0 (PB2) (16bits)
     * (The 8 * 8 pixel per char PipeDream Map, max. 256x8 pixels)
	 */
	private int PB2;

	/**
	 * Set HIRES0 (PB2) (16bits)
	 * (The 8 * 8 pixel per char PipeDream Map, max. 256x8 pixels)
	 */
	public void setBlinkPb2(int bits) {
		PB2 = bits;
	}

	/**
	 * Get Address of HIRES0 (PB2) in 24bit extended address format.
	 * (The 8 * 8 pixel per char PipeDream Map, max. 256x8 pixels)
	 */	
	public int getBlinkPb2() {
		int extAddressBank = (PB2 << 7) & 0xFF00;
		int extAddressOffset = (PB2 << 5) & 0x0020;

		return (extAddressBank | extAddressOffset) << 8;
	}
	
	/**
	 * HIRES1 (PB3) (16bits)
	 * (The 8 * 8 pixel per char fonts for the OZ window)
	 */
	private int PB3;

	/**
	 * Set HIRES1 (PB3) (16bits)
	 * (The 8 * 8 pixel per char fonts for the OZ window)
	 */
	public void setBlinkPb3(int bits) {
		PB3 = bits;
	}

	/**
	 * Get Address of HIRES1 (PB3) in 24bit extended address format.
	 * (The 8 * 8 pixel per char fonts for the OZ window)
	 */	
	public int getBlinkPb3() {
		int extAddressBank = (PB3 << 5) & 0xFF00;
		int extAddressOffset = (PB3 << 3) & 0x0038;

		return (extAddressBank | extAddressOffset) << 8;
	}
	
	/**
	 * Screen Base Register (16bits)
	 * (The Screen base File (2K size), containing char info about screen)
	 * If this register is 0, then the system cannot render the pixel screen.
	 */	
	private int SBR;

	/**
	 * Set Screen Base Register (16bits)
	 * (The Screen base File (2K size), containing char info about screen)
	 * If this register is 0, then the system cannot render the pixel screen.
	 */	
	public void setBlinkSbr(int bits) {
		SBR = bits;
	}

	/**
	 * Get Screen Base in 24bit extended address format.
	 * (The Screen base File (2K size), containing char info about screen)
	 * If this register is 0, then the system cannot render the pixel screen.
	 */	
	public int getBlinkSbr() {
		int extAddressBank = (SBR << 5) & 0xFF00;
		int extAddressOffset = (SBR << 3) & 0x0038;

		return (extAddressBank | extAddressOffset) << 8;
	}

	private int keybRowA15 = 0xFF;	// Keyboard scan Row 7F (01111111)
	private int keybRowA14 = 0xFF;	// Keyboard scan Row BF (10111111)
	private int keybRowA13 = 0xFF;	// Keyboard scan Row DF (11011111)
	private int keybRowA12 = 0xFF;	// Keyboard scan Row EF (11101111)
	private int keybRowA11 = 0xFF;	// Keyboard scan Row F7 (11110111)
	private int keybRowA10 = 0xFF;	// Keyboard scan Row FB (11111011)
	private int keybRowA9 = 0xFF;	// Keyboard scan Row FD (11111101)
	private int keybRowA8 = 0xFF;	// Keyboard scan Row FE (11111110)
	
	/**
	 * Fetch a keypress from the specified row matrix.
	 * 
	 * A few conventions have been defined to map the special keys in the Z88
	 * to a conventional computer keyboard:
	 * 		HELP			= F1
	 * 		INDEX 			= F2
	 * 		MENU			= F3
	 * 		L. & R. SHIFT	= F12
	 * 		<> (Diamond) 	= CTRL
	 * 		[] (Square)		= ALT 
	 * 
	 * @param row
	 * @return int
	 */
	public int getBlinkKbd(int row) {
		int keyColumn = 0xFF;	// Default to no keys pressed...

        if ( (INT & BM_INTKWAIT) == BM_INTKWAIT ) {
            // all rows are read by hardware when in snooze...
            row = 0;

			try {
				Thread.sleep(5);
			} catch (InterruptedException e) {
				e.printStackTrace(System.out);
			}			
        }
        
		do {
            // F5 was pressed, get out of here!
            if (stopZ88 == true) return 0xFF;
            
            switch(row) {
                case 0x7F:	// Row 01111111:
                            //			| D7     D6      D5      D4      D3      D2      D1      D0
                            // -------------------------------------------------------------------------
                            // A15 (#7) | RSH    SQR     ESC     INDEX   CAPS    .       /       �
                            keyColumn = keybRowA15;
                            break;

                case 0xBF:	// 10111111
                            //			| D7     D6      D5      D4      D3      D2      D1      D0
                            // -------------------------------------------------------------------------
                            // A14 (#6) | HELP   LSH     TAB     DIA     MENU    ,       ;       '
                            keyColumn = keybRowA14;
                            break;

                case 0xDF:	// 11011111
                            //			| D7     D6      D5      D4      D3      D2      D1      D0
                            // -------------------------------------------------------------------------
                            // A13 (#5) | [      SPACE   1       Q       A       Z       L       0
                            keyColumn = keybRowA13;
                            break;

                case 0xEF:	// 11101111
                            //			| D7     D6      D5      D4      D3      D2      D1      D0
                            // -------------------------------------------------------------------------			
                            // A12 (#4) | ]      LFT     2       W       S       X       M       P
                            keyColumn = keybRowA12;
                            break;

                case 0xF7:	// 11110111
                            //			| D7     D6      D5      D4      D3      D2      D1      D0			
                            // -------------------------------------------------------------------------
                            // A11 (#3) | -      RGT     3       E       D       C       K       9
                            keyColumn = keybRowA11;
                            break;

                case 0xFB:	// 11111011
                            //			| D7     D6      D5      D4      D3      D2      D1      D0			
                            // -------------------------------------------------------------------------
                            // A10 (#2) | =      DWN     4       R       F       V       J       O
                            keyColumn = keybRowA10;
                            break;

                case 0xFD:	// 11111101
                            //			| D7     D6      D5      D4      D3      D2      D1      D0			
                            // -------------------------------------------------------------------------
                            // A9  (#1) | \      UP      5       T       G       B       U       I
                            keyColumn = keybRowA9;
                            break;

                case 0xFE:	// 11111110
                            //			| D7     D6      D5      D4      D3      D2      D1      D0			
                            // -------------------------------------------------------------------------
                            // A8  (#0) | DEL    ENTER   6       Y       H       N       7       8
                            keyColumn = keybRowA8;
                            break;
                case 0x00:
                    if (keybRowA15 != 0xFF) { keyColumn = keybRowA15; }
                    if (keybRowA14 != 0xFF) { keyColumn = keybRowA14; }
                    if (keybRowA13 != 0xFF) { keyColumn = keybRowA13; }
                    if (keybRowA12 != 0xFF) { keyColumn = keybRowA12; }
                    if (keybRowA11 != 0xFF) { keyColumn = keybRowA11; }
                    if (keybRowA10 != 0xFF) { keyColumn = keybRowA10; }
                    if (keybRowA9 != 0xFF) { keyColumn = keybRowA9; }
                    if (keybRowA8 != 0xFF) { keyColumn = keybRowA8; }
                    
                    // if scanning for all rows, get out immediately...
                    // (whether key press or not)
                    return keyColumn;
            }		            

			if ( (INT & BM_INTKWAIT) == BM_INTKWAIT) {
				// Z80 snoozes... (wait a little bit, then ask again for key press from Blink)
				// (interrupts still occurs in Blink where keyboard is scanned each 10ms)
				try {
					Thread.sleep(5);
				} catch (InterruptedException e) {
					e.printStackTrace(System.out);
				}			
			}           

        }
		// Only get out of loop if we have INT.KWAIT (snooze) and a key was pressed...
		while( singleSteppingMode() == false && (INT & BM_INTKWAIT) == BM_INTKWAIT && keyColumn == 0xFF);
		
		return keyColumn;
	}

    
	/**
	 * System bank for lower 8K of segment 0.
	 * References bank 0x00 or 0x20 of slot 0.
	 */
	private Bank RAMS;

	/**
	 * Get Bank, referenced by it's number [0-255] in the BLINK memory model 
	 * 
	 * @return Bank
	 */
	public Bank getBank(final int bankNo) {
		return memory[bankNo & 0xFF];
	}

	/**
	 * Install Bank entity into BLINK 16K memory system [0-255].
	 *  
	 * @param bank
	 * @param bankNo
	 */
	public void setBank(final Bank bank, final int bankNo) {
		memory[bankNo & 0xFF] = bank;
	}

	/**
	 * Segment register array for SR0 - SR3.
	 * 
	 * <PRE>
	 * Segment register 0, SR0, bank binding for 0x2000 - 0x3FFF
	 * Segment register 1, SR1, bank binding for 0x4000 - 0x7FFF
	 * Segment register 2, SR2, bank binding for 0x8000 - 0xBFFF
	 * Segment register 3, SR3, bank binding for 0xC000 - 0xFFFF
	 * </PRE>
	 *
	 * Any of the registers contains a bank number, 0 - 255 that
	 * is currently bound into the corresponding segment in the
	 * Z80 address space.
	 */
	private int sR[];

	/**
	 * The Z88 memory organisation.
	 * Array for 256 x 16K banks = 4Mb memory
	 */
	private Bank memory[];

	/**
	 * Null bank. This is used in for unassigned banks,
	 * ie. when a card slot is empty in the Z88
	 * The contents of this bank contains 0xFF and is
	 * write-protected (just as an empty bank in an Eprom).
	 */
	private Bank nullBank;

	/**
	 * Get current bank [0; 255] binding in segments [0; 3]. 
	 *
	 * On the Z88, the 64K is split into 4 sections of 16K segments.
	 * Any of the 256 16K banks can be bound into the address space
	 * on the Z88. Bank 0 is special, however.
	 * Please refer to hardware section of the Developer's Notes.
	 * 
	 * @return int
	 */
	public int getSegmentBank(final int segment) {
		return sR[segment & 0x03];
	}

	/**
	 * Bind bank [0-255] to segments [0-3] in the Z80 address space.
	 * 
	 * On the Z88, the 64K is split into 4 sections of 16K segments. Any of the
	 * 256 x 16K banks can be bound into the address space on the Z88. Bank 0 is
	 * special, however. Please refer to hardware section of the Developer's
	 * Notes.
	 */
	public void setSegmentBank(final int segment, final int BankNo) {
		sR[segment & 0x03] = (BankNo & 0xFF);
	}

	/**
	 * Decode Z80 Address Space to extended Blink Address (offset,bank).
	 * 
	 * @param pc 16bit word that points into Z80 Local Address Space
	 * @return int 24bit extended address 
	 */
	public int decodeLocalAddress(final int pc) {
		int bankno;
		
		if (pc >= 0x2000) {
			bankno = sR[(pc >>> 14) & 0x03];
		} else {
			// return lower 8K Bank binding
			// Lower 8K is System Bank 0x00 (ROM on hard reset)
			// or 0x20 (RAM for Z80 stack and system variables)
			if ((COM & Blink.BM_COMRAMS) == Blink.BM_COMRAMS)
				bankno = 0x20;	// RAM Bank 20h
			else
				bankno = 0x00;	// ROM bank 00h
		}

		return (bankno << 16) | (pc & 0x3FFF);
	}
	
	/**
	 * Read byte from Z80 virtual memory model. <addr> is a 16bit word
	 * that points into the Z80 64K address space.
	 *
	 * On the Z88, the 64K is split into 4 sections of 16K segments.
	 * Any of the 256 16K banks can be bound into the address space
	 * on the Z88. Bank 0 is special, however.
	 * Please refer to hardware section of the Developer's Notes.
	 */
	public final int readByte(final int addr) {
		if (addr > 0x3FFF) {
			return memory[sR[addr >>> 14]].bank[addr & 0x3FFF];
		} else {
			if (addr < 0x2000)
				// return lower 8K Bank binding
				// Lower 8K is System Bank 0x00 (ROM on hard reset)
				// or 0x20 (RAM for Z80 stack and system variables)
				return RAMS.bank[addr];
			else {
				if ((sR[0] & 1) == 0) 
					// lower 8K of even bank bound into upper 8K of segment 0					
					return memory[sR[0] & 0xFE].bank[addr & 0x1FFF];
				else
					// upper 8K of even bank bound into upper 8K of segment 0
					// addr <= 0x3FFF...
					return memory[sR[0] & 0xFE].bank[addr];
			}
		}
	}

	/**
	 * Read word (16bits) from Z80 virtual memory model. 
	 * <addr> is a 16bit word that points into the Z80 64K address space.
	 *
	 * On the Z88, the 64K is split into 4 sections of 16K segments.
	 * Any of the 256 16K banks can be bound into the address space
	 * on the Z88. Bank 0 is special, however.
	 * Please refer to hardware section of the Developer's Notes.
	 */
	public final int readWord(int addr) {
		Bank bankNo;
		
		if ( (addr & 0x3FFF) != 0x3FFF ) { 
			if (addr > 0x3FFF) {
				bankNo = memory[sR[addr >>> 14]];
				addr &= 0x3FFF;
				return bankNo.bank[addr+1] << 8 | bankNo.bank[addr];
			} else {
				if (addr < 0x2000) {
					// return lower 8K Bank binding
					// Lower 8K is System Bank 0x00 (ROM on hard reset)
					// or 0x20 (RAM for Z80 stack and system variables)
					return RAMS.bank[addr+1] << 8 | RAMS.bank[addr];
				} else {
					bankNo = memory[sR[0] & 0xFE];
					if ((sR[0] & 1) == 0) {
						// lower 8K of even bank bound into upper 8K of segment 0
						addr &= 0x1FFF; 
						return bankNo.bank[addr+1] << 8 | bankNo.bank[addr];
					} else {
						// upper 8K of even bank bound into upper 8K of segment 0
						// addr = [0x2000 - 0x3FFF]...
						return bankNo.bank[addr+1] << 8 | bankNo.bank[addr];
					}
				}
			}
		} else {
			// bank boundary will be crossed...
			return readByte(addr+1) << 8 | readByte(addr);
		}
	}

	/**
	 * Read Z80 instruction as a 4 byte entity from Z80 virtual memory model,
	 * starting from offset, onwards. <addr> is a 16bit word that points into
	 * the Z80 64K address space. Z80 instructions varies between 1 and 4 bytes,
	 * but here a complete 4 byte sequence is cached in the return argument,
	 * without knowing the actual length.
	 * 
	 * The instruction is returned as a 32bit integer for compactness, in low
	 * byte, high byte order, ie. lowest 8bit is the first byte of the
	 * instruction, highest 8bit of 32bit integer is the 4th byte of the
	 * instruction.
	 *  
	 * @param addr address offset in bank
	 * @return int 4 byte Z80 instruction 
	 */
	public final int readInstruction(int addr) {
		Bank bankNo;
		
		if ( (addr & 0x3FFF)+3 <= 0x3FFF ) { 
			if (addr > 0x3FFF) {
				bankNo = memory[sR[addr >>> 14]];
				addr &= 0x3FFF;
				// fetch instruction from segments 1 - 3
				return 	bankNo.bank[addr+3] << 24 | bankNo.bank[addr+2] << 16 |
						bankNo.bank[addr+1] << 8 | bankNo.bank[addr];
			} else {
				if (addr < 0x2000) {
					// return lower 8K Bank binding
					// Lower 8K is System Bank 0x00 (ROM on hard reset)
					// or 0x20 (RAM for Z80 stack and system variables)
					return RAMS.bank[addr+3] << 24 | RAMS.bank[addr+2] << 16 |
					       RAMS.bank[addr+1] << 8 | RAMS.bank[addr];
				} else {
					bankNo = memory[sR[0] & 0xFE];
					if ((sR[0] & 1) == 0) {
						addr &= 0x1FFF;
						// lower 8K of even bank bound into upper 8K of segment 0
						return 	bankNo.bank[addr+3] << 24 | bankNo.bank[addr+2] << 16 |
								bankNo.bank[addr+1] << 8 | bankNo.bank[addr];
					} else {
						// upper 8K of even bank bound into upper 8K of segment 0
						// addr <= 0x3FFF...
						return 	bankNo.bank[addr+3] << 24 | bankNo.bank[addr+2] << 16 |
								bankNo.bank[addr+1] << 8 | bankNo.bank[addr];
					}
				}
			}
		} else {
			// bank boundary will be crossed...
			return readByte(addr + 3) << 24 | readByte(addr + 2) << 16 |
				   readByte(addr + 1) << 8 | readByte(addr);
		}
	}

	/**
	 * Write byte to Z80 virtual memory model. <addr> is a 16bit word
	 * that points into the Z80 64K address space.
	 *
	 * On the Z88, the 64K is split into 4 sections of 16K segments.
	 * Any of the 256 16K banks can be bound into the address space
	 * on the Z88. Bank 0 is special, however.
	 * Please refer to hardware section of the Developer's Notes.
	 */
	public final void writeByte(final int addr, final int b) {
		Bank bankNo;
		
		if (addr > 0x3FFF) {
			// write byte to segments 1 - 3
			bankNo = memory[sR[addr >>> 14]];
			if (bankNo.type == Bank.RAM) bankNo.bank[addr & 0x3FFF] = b & 0xFF;
		} else {
			if (addr < 0x2000) {
				// return lower 8K Bank binding
				// Lower 8K is System Bank 0x00 (ROM on hard reset)
				// or 0x20 (RAM for Z80 stack and system variables)
				if (RAMS.type == Bank.RAM) RAMS.bank[addr] = b & 0xFF;
			} else {
				bankNo = memory[sR[0] & 0xFE];
				if (bankNo.type == Bank.RAM) {
					if ((sR[0] & 1) == 0) { 
						// lower 8K of even bank bound into upper 8K of segment 0 
						bankNo.bank[addr & 0x1FFF] = b & 0xFF;
					} else {
						// upper 8K of even bank bound into upper 8K of segment 0
						// addr <= 0x3FFF...
						bankNo.bank[addr] = b & 0xFF;
					}
				}
			}
		}
	}

	/**
	 * Write word (16bits) to Z80 virtual memory model. <addr> is a 16bit word
	 * that points into the Z80 64K address space.
	 *
	 * On the Z88, the 64K is split into 4 sections of 16K segments.
	 * Any of the 256 16K banks can be bound into the address space
	 * on the Z88. Bank 0 is special, however.
	 * Please refer to hardware section of the Developer's Notes.
	 */
	public final void writeWord(int addr, final int w) {
		Bank bankNo;
		
		if ( (addr & 0x3FFF) != 0x3FFF ) { 
			if (addr > 0x3FFF) {
				bankNo = memory[sR[addr >>> 14]];
				addr &= 0x3FFF;
				if (bankNo.type == Bank.RAM) {
					bankNo.bank[addr] = w & 0xFF; 
					bankNo.bank[addr+1] = (w >>> 8) & 0xFF;
				} 
			} else {
				if (addr < 0x2000) {
					// return lower 8K Bank binding
					// Lower 8K is System Bank 0x00 (ROM on hard reset)
					// or 0x20 (RAM for Z80 stack and system variables)
					if (RAMS.type == Bank.RAM) { 
						RAMS.bank[addr] = w & 0xFF;
						RAMS.bank[addr+1] = (w >>> 8) & 0xFF;
					} 
				} else {
					bankNo = memory[sR[0] & 0xFE];
					if (bankNo.type == Bank.RAM) {
						if ((sR[0] & 1) == 0) {
							addr &= 0x1FFF; 
							// lower 8K of even bank bound into upper 8K of segment 0 
							bankNo.bank[addr] = w & 0xFF;
							bankNo.bank[addr+1] = (w >>> 8) & 0xFF;
						} else {
							// upper 8K of even bank bound into upper 8K of segment 0
							// addr <= 0x3FFF...
							bankNo.bank[addr] = w & 0xFF;
							bankNo.bank[addr+1] = (w >>> 8) & 0xFF;
						}
					}
				}
			}
		} else {
			// bank boundary will be crossed...
			writeByte(addr, w & 0xFF);
			writeByte(addr+1, (w >>> 8) & 0xFF);
		}
	}

	/**
	 * The "internal" write byte method to be used in
	 * the OZvm debugging environment, allowing complete
	 * write permission.
	 * 
	 * @param offset within the 16K memory bank.
	 * @param bank number of the 4MB memory model (0-255). 
	 * @param bits to be written.
	 */
	public void setByte(final int offset, final int bankno, final int bits) {
		if (memory[bankno] != nullBank) {
			// we can only write to a real memory bank, not to an empty slot...
			memory[bankno].bank[0x3FFF & offset] = bits & 0xFF;
		}
	}

	/**
	 * The "internal" read byte method to be used in the OZvm 
	 * debugging environment.
	 * 
	 * @param offset
	 * @param bank
	 * @return int
	 */
	public int getByte(final int offset, final int bankno) {
		return memory[bankno].bank[offset & 0x3FFF];
	}

	/**
	 * Implement Z88 input port BLINK hardware 
	 * (Registers STA, KBD, TSTA, TIM0-TIM4, RXD, RXE, UIT).
	 * 
	 * @param addrA8 Port number (low byte address)
	 * @param addrA15 high byte address
	 */	
	public final int inByte(int addrA8, int addrA15) {
		int res = 0;

		switch (addrA8) {
			case 0xB1:				
                res = getBlinkSta();		// STA, Main Blink Interrupt Status
				break;
				
			case 0xB2:
				res = getBlinkKbd(addrA15);	// KBD, get Keyboard column for specified row.
				break;
				
			case 0xB5:
                if ((INT & BM_INTTIME) == BM_INTTIME) {
                    res = getBlinkTsta();	// RTC interrupts are enabled, so TSTA is active...
                }
				break;

            case 0xD0:
				res = getBlinkTim0();	// TIM0, 5ms period, counts to 199  
				break;
				
			case 0xD1:
				res = getBlinkTim1();	// TIM1, 1 second period, counts to 59  
				break;
				
			case 0xD2:
				res = getBlinkTim2();	// TIM2, 1 minute period, counts to 255  
				break;
				
			case 0xD3:
				res = getBlinkTim3();	// TIM3, 256 minutes period, counts to 255     
				break;
				
			case 0xD4:
				res = getBlinkTim4();	// TIM4, 64K minutes Period, counts to 31        
				break;

			default :
				res = 0;			// RXD, RXE, UIT not yet implemented in BLINK ...
		}

		return res;
	}

	/**
	 * Implement Z88 output port Blink hardware. 
	 * (RTC, Screen, Keyboard, Memory model, Serial port, CPU state).
	 * 
	 * @param addrA8 LSB of port address
	 * @param addrA15 MSB of port address
	 * @param outByte the data to send to the hardware
	 */
	public final void outByte(final int addrA8, final int addrA15, final int outByte) {
		switch (addrA8) {
			case 0xD0 : // SR0, Segment register 0
			case 0xD1 : // SR1, Segment register 1
			case 0xD2 : // SR2, Segment register 2
			case 0xD3 : // SR3, Segment register 3
				setSegmentBank(addrA8, outByte);
				break;

			case 0xB0 : // COM, Set Command Register
				setBlinkCom(outByte);
				break;

			case 0xB1 : // INT, Set Main Blink Interrupts
				setBlinkInt(outByte);
				break;

			case 0xB4 : // TACK, Set Timer Interrupt Acknowledge
				setBlinkTack(outByte);
				break;

			case 0xB5 : // TMK, Set Timer interrupt Mask
				setBlinkTmk(outByte);
				break;

			case 0xB6 : // ACK, Acknowledge Main Interrupts				
				setBlinkAck(outByte);
				break;

			case 0x70 : // PB0, Pixel Base Register 0 (Screen)
				setBlinkPb0((addrA15 << 8) | outByte);
				break;				

			case 0x71 : // PB1, Pixel Base Register 1 (Screen)
				setBlinkPb1((addrA15 << 8) | outByte);
				break;				

			case 0x72 : // PB2, Pixel Base Register 2 (Screen)
				setBlinkPb2((addrA15 << 8) | outByte);
				break;				

			case 0x73 : // PB3, Pixel Base Register 3 (Screen)
				setBlinkPb3((addrA15 << 8) | outByte);
				break;				

			case 0x74 : // SBR, Screen Base Register 
				setBlinkSbr((addrA15 << 8) | outByte);
				break;				
		}
	}

    /** 
     * Internal signal that F5 key was pressed while Blink was reading the keyboard
     */
    private boolean stopZ88 = false;

    
    /** 
     * Check if F5 key was pressed while Blink was reading the keyboard
     */
	public boolean abortZ80() {
        if (stopZ88 == true) {
            stopZ88 = false;
            return true;
        } else {
            return false;
        }
	}
	
	
	public void haltZ80() {
		// Let the Blink know that a HALT instruction occured
		// so that the Z88 enters the correct state (coma, snooze, ...)

		long w = System.currentTimeMillis();		
		do {
			try {
				Thread.sleep(5);		// Z80 "sleeps" for 5ms ... (interrupts still occurs in Blink)
			} catch (InterruptedException e) {
				e.printStackTrace(System.out);
			}			
		}
		// Only get out of coma if an interrupt occurred..
		while(interruptTriggered() == false);
		w = System.currentTimeMillis() - w;
		
		// (back to main Z80 decode loop)
	}

	public void hardReset() {
		reset(); // reset Z80 registers
		resetRam(); // reset memory of all available RAM in Z88 memory
	}

	/**
	 * BLINK Command Register.
	 * 
	 * <PRE>
	 *	Bit	 7, SRUN
	 *	Bit	 6, SBIT
	 *	Bit	 5, OVERP
	 *	Bit	 4, RESTIM
	 *	Bit	 3, PROGRAM
	 *	Bit	 2, RAMS
	 *	Bit	 1, VPPON
	 *	Bit	 0, LCDON
	 * </PRE>
	 */
	private int COM;

	public static final int BM_COMSRUN = 0x80; // Bit 7, SRUN
	public static final int BM_COMSBIT = 0x40; // Bit 6, SBIT
	public static final int BM_COMOVERP = 0x20; // Bit 5, OVERP
	public static final int BM_COMRESTIM = 0x10; // Bit 4, RESTIM
	public static final int BM_COMPROGRAM = 0x08; // Bit 3, PROGRAM
	public static final int BM_COMRAMS = 0x04; // Bit 2, RAMS
	public static final int BM_COMVPPON = 0x02; // Bit 1, VPPON
	public static final int BM_COMLCDON = 0x01; // Bit 0, LCDON

	/**
	 * Set Blink Command Register flags, port $B0.
	 * 
	 * <PRE>
	 *	Bit	7, SRUN
	 *	Bit	6, SBIT
	 *	Bit	5, OVERP
	 *	Bit	4, RESTIM
	 *	Bit	3, PROGRAM
	 *	Bit	2, RAMS
	 *	Bit	1, VPPON
	 *	Bit	0, LCDON
	 * </PRE>
	 *
	 *	@param bits
	 */
	public void setBlinkCom(int bits) {

		if (rtc.isRunning() == true && ((bits & Blink.BM_COMRESTIM) == Blink.BM_COMRESTIM)) {
			// Stop Real Time Clock (RESTIM = 1)
			if (singleSteppingMode() == false) rtc.stop();
			rtc.reset();
		}

		if (rtc.isRunning() == false && ((bits & Blink.BM_COMRESTIM) == 0)) {
			// Real Time Clock is not running, and is asked to start (RESTIM = 0)... 
			if (singleSteppingMode() == false) rtc.start();
		}

		if ((bits & Blink.BM_COMRAMS) == Blink.BM_COMRAMS) {
			// Slot 0 RAM Bank 0x20 will be bound into lower 8K of segment 0
			RAMS = memory[0x20];
		} else {
			// Slot 0 ROM bank 0 is bound into lower 8K of segment 0
			RAMS = memory[0x00];
		}

		if ( ((bits & Blink.BM_COMLCDON) == Blink.BM_COMLCDON) && ((COM & Blink.BM_COMLCDON) == 0)) {
			z88Display.start();
		}

		if ( ((bits & Blink.BM_COMLCDON) == 0) && ((COM & Blink.BM_COMLCDON) == Blink.BM_COMLCDON)) {
			z88Display.stop();
		}

		COM = bits;
	}

	/**
	 * Get Blink Command Register flags, port $B0.
	 * 
	 * <PRE>
	 *	Bit	7, SRUN
	 *	Bit	6, SBIT
	 *	Bit	5, OVERP
	 *	Bit	4, RESTIM
	 *	Bit	3, PROGRAM
	 *	Bit	2, RAMS
	 *	Bit	1, VPPON
	 *	Bit	0, LCDON
	 * </PRE>
	 *
	 *	@return COM
	 */
	public final int getBlinkCom() {
		return COM;
	}
	
	/**
	 * Insert RAM Card into Z88 memory system.
	 * Size must be in modulus 32Kb (even numbered 16Kb banks).
	 * RAM may be inserted into slots 0 - 3.
	 * RAM is loaded from bottom bank of slot and upwards.
	 * Slot 0 (512Kb): banks 20 - 3F
	 * Slot 1 (1Mb):   banks 40 - 7F
	 * Slot 2 (1Mb):   banks 80 - BF
	 * Slot 3 (1Mb):   banks C0 - FF
	 *
	 * Slot 0 is special; max 512K RAM in top 512K address space.
	 * (bottom 512K address space in slot 0 is reserved for ROM, banks 00-1F)
	 */
	public void insertRamCard(int size, int slot) {
		int totalRamBanks, totalSlotBanks, curBank;

		slot %= 4; // allow only slots 0 - 3 range.
		size -= (size % 32768); // allow only modulus 32Kb RAM.
		totalRamBanks = size / 16384; // number of 16K banks in Ram Card

		Bank ramBanks[] = new Bank[totalRamBanks]; // the RAM card container
		for (curBank = 0; curBank < totalRamBanks; curBank++) {
			ramBanks[curBank] = new Bank(Bank.RAM);
		}

		slotCards[slot] = ramBanks;
		// remember Ram Card for future reference...
		loadCard(ramBanks, slot); // load the physical card into Z88 memory
	}
		
	/**
	 * Load ROM image (from opened file ressource) into Z88 memory system, slot 0.
	 *
	 * @param rom 
	 * @throws IOException
	 */
	public void loadRomBinary(RandomAccessFile rom) throws IOException {
		if (rom.length() > (1024 * 512)) {
			throw new IOException("Max 512K ROM!");
		}
		if (rom.length() % (Bank.SIZE * 2) > 0) {
			throw new IOException("ROM must be in even banks!");
		}

		Bank romBanks[] = new Bank[(int) rom.length() / Bank.SIZE];
		// allocate ROM container
		byte bankBuffer[] = new byte[Bank.SIZE];
		// allocate intermediate load buffer

		for (int curBank = 0; curBank < romBanks.length; curBank++) {
			romBanks[curBank] = new Bank(Bank.ROM);
			rom.readFully(bankBuffer); // load 16K from file, sequentially
			romBanks[curBank].loadBytes(bankBuffer, 0);
			// and load fully into bank
		}

		// complete ROM image now loaded into container
		// insert container into Z88 memory, slot 0, banks $00 onwards.
		loadCard(romBanks, 0);
		RAMS = memory[0];				// point at ROM bank 0
	}

	/**
	 * Load ROM image (from opened file ressource inside JAR) 
	 * into Z88 memory system, slot 0.
	 *
	 * @param jarRessource 
	 * @throws IOException
	 */
	public void loadRomBinary(URL jarRessource) throws IOException {
		JarURLConnection jarConnection = (JarURLConnection)jarRessource.openConnection();
				
		if (jarConnection.getJarEntry().getSize() > (1024 * 512)) {
			throw new IOException("Max 512K ROM!");
		}
		if (jarConnection.getJarEntry().getSize() % (Bank.SIZE * 2) > 0) {
			throw new IOException("ROM must be in even banks!");
		}

		Bank romBanks[] = new Bank[(int) jarConnection.getJarEntry().getSize() / Bank.SIZE];
		// allocate ROM container
		byte bankBuffer[] = new byte[Bank.SIZE];
		// allocate intermediate load buffer

		InputStream is = jarConnection.getInputStream();
		BufferedInputStream bis = new BufferedInputStream( is, Bank.SIZE );
		
		for (int curBank = 0; curBank < romBanks.length; curBank++) {
			romBanks[curBank] = new Bank(Bank.ROM);
			int bytesRead = bis.read(bankBuffer, 0, Bank.SIZE);	// load 16K from file, sequentially
			romBanks[curBank].loadBytes(bankBuffer, 0); 		// and load fully into bank
		}

		// complete ROM image now loaded into container
		// insert container into Z88 memory, slot 0, banks $00 onwards.
		loadCard(romBanks, 0);
		RAMS = memory[0];				// point at ROM bank 0
	}

	/**
	 * Load Card (RAM/ROM/EPROM) into Z88 memory system.
	 * Size is in modulus 32Kb (even numbered 16Kb banks).
	 * Slot 0 (512Kb): banks 00 - 1F (ROM), banks 20 - 3F (RAM)
	 * Slot 1 (1Mb):   banks 40 - 7F (RAM or EPROM)
	 * Slot 2 (1Mb):   banks 80 - BF (RAM or EPROM)
	 * Slot 3 (1Mb):   banks C0 - FF (RAM or EPROM)
	 *
	 * @param card
	 * @param slot
	 */
	private void loadCard(Bank card[], int slot) {
		int totalSlotBanks, slotBank, curBank;

		if (slot == 0) {
			// Define bottom bank for ROM/RAM
			slotBank = (card[0].getType() != Bank.RAM) ? 0x00 : 0x20;
			// slot 0 has 32 * 16Kb = 512K address space for RAM or ROM
			totalSlotBanks = 32;
		} else {
			slotBank = slot << 6; // convert slot number to bottom bank of slot
			totalSlotBanks = 64;
			// slots 1 - 3 have 64 * 16Kb = 1Mb address space
		}

		for (curBank = 0; curBank < card.length; curBank++) {
			setBank(card[curBank], slotBank++);
			// "insert" 16Kb bank into Z88 memory
			--totalSlotBanks;
		}

		// - the bottom of the slot has been loaded with the Card.
		// Now, we need to fill the 1MB address space in the slot with the card.
		// Note, that most cards and the internal memory do not exploit
		// the full lMB addressing range, but only decode the lower address lines.
		// This means that memory will appear more than once within the lMB range.
		// The memory of a 32K card in slot 1 would appear at banks $40 and $41,
		// $42 and $43, ..., $7E and $7F. Alternatively a 128K EPROM in slot 3 would
		// appear at $C0 to $C7, $C8 to $CF, ..., $F8 to $FF.
		// This way of addressing is assumed by the system.
		// Note that the lowest and highest bank in an EPROM can always be addressed
		// by looking at the bank at the bottom of the 1MB address range and the bank
		// at the top respectively.
		while (totalSlotBanks > 0) {
			for (curBank = 0; curBank < card.length; curBank++) {
				setBank(card[curBank], slotBank++);
				// "shadow" card banks into remaining slot
				--totalSlotBanks;
			}
		}
	}

	/**
	 * Scan available slots for Ram Cards, and reset them..
	 */
	public void resetRam() {
		RAMS = memory[0];	// RAMS now points at cards' bank 0
		
		for (int slot = 0; slot < slotCards.length; slot++) {
			// look at bottom bank in Card for type; only reset RAM Cards...
			if (slotCards[slot] != null
				&& slotCards[slot][0].getType() == Bank.RAM) {
				// reset all banks in Card of current slot
				for (int cardBank = 0;
					cardBank < slotCards[slot].length;
					cardBank++) {
					Bank b = slotCards[slot][cardBank];
					for (int bankOffset = 0;
						bankOffset < Bank.SIZE;
						bankOffset++) {
						b.bank[bankOffset] = 0;
					}
				}
			}
		}
	}
	
	/**
	 * This class represents a 16K memory block or bank of memory.
	 * The characteristics of a bank can be that it's part of a Ram card (or the
	 * internal memory of the Z88), an Eprom card or a 1MB Flash Card.
	 */
	private final class Bank {
		private static final int RAM = 0;		// 32Kb, 128Kb, 512Kb, 1Mb
		private static final int ROM = 1;		// 128Kb 
		private static final int EPROM = 2;		// 32Kb, 128Kb & 256Kb
		private static final int FLASH = 3;		// 1Mb Flash
		private static final int SIZE = 16384;	// Always 16384 bytes in a bank
		
		private int type;
		private int bank[];
	
		Bank() {
			type = Bank.RAM;
			bank = new int[Bank.SIZE];	// all default memory cells are 0.
		}
	
		Bank(int banktype) {
			type = banktype;
			bank = new int[Bank.SIZE];
		
			if (type != Bank.RAM) {
				for (int i=0; i<memory.length; i++)
					bank[i] = 0xFF;	// empty Eprom or Flash stores FF's
			}
		}
	
		private int getType() {
			return type;
		}
	
		/**
		 * Load bytes from buffer array of block.length
		 * to bank offset, onwards.
		 * Naturally, loading is only allowed inside 16Kb boundary.
		 */
		private void loadBytes(byte[] block, int offset) {
			offset %= Bank.SIZE;	// stay within boundary..
			int length = (offset+block.length) > Bank.SIZE ? Bank.SIZE-offset : block.length;

			int bufidx=0;
			while(length-- > 0)
				bank[offset++] = block[bufidx++] & 0xFF;
		}
	} /* Bank */


	public void startInterrupts() {
		z80Int.start();
		if ( (getBlinkCom() & Blink.BM_COMRESTIM) == 0 ) rtc.start();        
        z88Display.start();
	}

	public void stopInterrupts() {
		z80Int.stop();        
        rtc.stop();        
        z88Display.stop();
	}

	/** 
	 * RTC, BLINK Real Time Clock, updated each 5ms.
	 */
	public final class Rtc {

		private Rtc() {
			rtcRunning = false;
			
			// enable minute, second and 1/100 second interrups
			TMK = BM_TMKMIN | BM_TMKSEC | BM_TMKTICK;
			TSTA = TACK = 0;

			// first interrupt events needs an acknowledge!
			TACK = BM_TACKMIN | BM_TACKSEC | BM_TACKTICK;
		}

		private final class Counter extends TimerTask {
			/**
			 * Execute the RTC counter each 5ms, and set the various RTC interrupts
			 * if they are enabled, but only if INT.TIME = 1.
			 * 
			 * @see java.lang.Runnable#run()
			 */
			public void run() {

				if (++tick > 1) {
					// 1/100 second has passed
					tick = 0;
					if (((INT & BM_INTTIME) == BM_INTTIME) && ((TMK & BM_TMKTICK) == BM_TMKTICK)) {
						// INT.TIME interrupts are enabled and TMK.TICK interrupts are enabled:
						// Signal that a tick interrupt occurred
						TSTA |= BM_TSTATICK; // TSTA.BM_TSTATICK = 1
					}
				}

				if (++TIM0 > 199) {
					// 1 second has passed...
					TIM0 = 0;
										
					if (((INT & BM_INTTIME) == BM_INTTIME) && ((TMK & BM_TMKSEC) == BM_TMKSEC)) {
						// INT.TIME interrupts are enabled and TMK.SEC interrupts are enabled:
						// Signal that a second interrupt occurred
						TSTA |= BM_TSTASEC; // TSTA.BM_TSTASEC = 1
					}

					if (++TIM1 > 59) {
						// 1 minute has passed
						TIM1 = 0;
						if (((INT & BM_INTTIME) == BM_INTTIME) && ((TMK & BM_TMKMIN) == BM_TMKMIN)) {
							// INT.TIME interrupts are enabled and TMK.MIN interrupts are enabled:
							// Signal that a minute interrupt occurred
							TSTA |= BM_TSTAMIN; // TSTA.BM_TSTAMIN = 1
						}

						if (++TIM2 > 255) {
							TIM2 = 0; // 256 minutes has passed
							if (++TIM3 > 255) {
								TIM3 = 0; // 65536 minutes has passed
								if (++TIM4 > 31) {
									TIM4 = 0; // 65536 * 32 minutes has passed
								}
							}
						}
					}
				}
			}
		}

		TimerTask countRtc = null;
		
		/**
		 * Internal counter, 2 ticks = 1/100 second (10ms)
		 */
		private int tick = 0;

		/**
		 * TIM0, 5 millisecond period, counts to 199, Z80 IN Register
		 */
		private int TIM0 = 0;
		
		/**
		 * TIM1, 1 second period, counts to 59, Z80 IN Register
		 */
		private int TIM1 = 0;
		 
		/**
		 * TIM2, 1 minutes period, counts to 255, Z80 IN Register
		 */
		private int TIM2 = 0;
		
		/**
		 * TIM3, 256 minutes period, counts to 255, Z80 IN Register
		 */
		private int TIM3 = 0;

		/**
		 * TIM4, 64K minutes period, counts to 31, Z80 IN Register
		 */
		private int TIM4 = 0;
		
		/**
		 * TSTA, Timer interrupt status, Z80 IN Read Register
		 */
		private int TSTA = 0;

		// Set if minute interrupt has occurred
		public static final int BM_TSTAMIN = 0x04;
		// Set if second interrupt has occurred
		public static final int BM_TSTASEC = 0x02;
		// Set if tick interrupt has occurred
		public static final int BM_TSTATICK = 0x01;

		/**
		 * TMK, Timer interrupt mask, Z80 OUT Write Register
		 */
		private int TMK = 0;
		 
		// Set to enable minute interrupt
		public static final int BM_TMKMIN = 0x04;
		// Set to enable second interrupt
		public static final int BM_TMKSEC = 0x02;
		// Set to enable tick interrupt
		public static final int BM_TMKTICK = 0x01;

		/**
		 * TACK, Timer interrupt acknowledge, Z80 OUT Write Register
		 */
		private int TACK = 0;
		
		// Set to acknowledge minute interrupt
		public static final int BM_TACKMIN = 0x04; 
		// Set to acknowledge second interrupt
		public static final int BM_TACKSEC = 0x02; 
		// Set to acknowledge tick interrupt
		public static final int BM_TACKTICK = 0x01;

		private boolean rtcRunning = false; // Rtc counting?

		/**
		 * Stop the Rtc counter, but don't reset the counters themselves.
		 */
		public void stop() {
			if (countRtc != null)
				countRtc.cancel();
			rtcRunning = false;
		}

		/**
		 * Start the Rtc counter immediately, and execute the run() method every
		 * 5 millisecond.
		 */
		public void start() {
			if (rtcRunning == false) {
				rtcRunning = true;
				countRtc = new Counter();
				timerDaemon.scheduleAtFixedRate(countRtc, 0, 5);
			}
		}

		/**
		 * Reset time counters. Performed when COM.RESTIM = 1.
		 */
		public void reset() {
			TIM0 = TIM1 = TIM2 = TIM3 = TIM4 = 0;
		}

		/**
		 * Is the RTC running?
		 * 
		 * @return boolean
		 */
		public boolean isRunning() {
			return rtcRunning;
		}

	} /* Rtc class */

	/** 
	 * The BLINK supplies the INT signal to the Z80 processor.
	 * An INT is fired each 10ms, which the Z80 responds to through IM 1
	 * (executing a RST 38H instruction).
	 */
	private final class Z80interrupt {

		private TimerTask intIm1 = null;
		
		/**
		 * 
		 * The Blink scans the hardware keyboard each 10ms...
		 *
		 * <PRE>
		 *	------------------------------------------------------------------------
		 *	UK Keyboard matrix
		 *	-------------------------------------------------------------------------
		 *			 | D7     D6      D5      D4      D3      D2      D1      D0
		 *	-------------------------------------------------------------------------
		 *	A15 (#7) | RSH    SQR     ESC     INDEX   CAPS    .       /       �
		 *	A14 (#6) | HELP   LSH     TAB     DIA     MENU    ,       ;       '
		 *	A13 (#5) | [      SPACE   1       Q       A       Z       L       0
		 *	A12 (#4) | ]      LFT     2       W       S       X       M       P
		 *	A11 (#3) | -      RGT     3       E       D       C       K       9
		 *	A10 (#2) | =      DWN     4       R       F       V       J       O
		 *	A9  (#1) | \      UP      5       T       G       B       U       I
		 *	A8  (#0) | DEL    ENTER   6       Y       H       N       7       8
		 *	-------------------------------------------------------------------------
		 * </PRE>
		 */ 
		private void scanKeyboard() {
			int currentKey = z88Keyboard.getCurrentlyPressedKey();
			int shiftKey = 0xFF, altKey=0xFF, ctrlKey=0xFF;
			
			switch (currentKey) {			
				case KeyboardDevice.NO_KEYS_PRESSED:
					keybRowA15 = keybRowA14 = keybRowA13 = keybRowA12 = 
					keybRowA11 = keybRowA10 = keybRowA9 = keybRowA8 = 0xFF;
					return;
				case java.awt.event.KeyEvent.VK_F5:
					stopZ88 = true;
					return;				
			}

			// a keypress is available, put it into the appropriate Z88 hardware keyrow...
			// if this key exists in the Z88 world...
			int row = 0xFE;		// start with A8, then upwards..
			int keyColumn = 0xFF;
			for (int scanRow=0; scanRow<8; scanRow++) {
				switch(row) {
					case 0x7F:	// Row 01111111:
								//			| D7     D6      D5      D4      D3      D2      D1      D0
								// -------------------------------------------------------------------------
								// A15 (#7) | RSH    SQR     ESC     INDEX   CAPS    .       /       �

                                // check for two-key combinations, here as ALT or SHIFT with another key...
                                if (z88Keyboard.isKeyDown(java.awt.event.KeyEvent.VK_ALT) == true) altKey = 0xBF; // SQUARE
                                if (z88Keyboard.isKeyDown(java.awt.event.KeyEvent.VK_SHIFT) == true) shiftKey = 0x7F; // (Right or Left) SHIFT
                                
								switch(currentKey) {
									case java.awt.event.KeyEvent.VK_F12: keybRowA15 = keyColumn = 0x7F; break; 		// RIGHT SHIFT
									case java.awt.event.KeyEvent.VK_ALT: keybRowA15 = keyColumn = 0xBF; break;		// SQUARE (10111111)
									case java.awt.event.KeyEvent.VK_ESCAPE: keybRowA15 = keyColumn = 0xDF; break;	// ESC
									case java.awt.event.KeyEvent.VK_F2: keybRowA15 = keyColumn = 0xEF; break;		// INDEX
									case java.awt.event.KeyEvent.VK_CAPS_LOCK: keybRowA15 = keyColumn = 0xF7; break;// CAPS LOCK
									// D2
									// D1
									// D0
									default: keybRowA15 = 0xFF;	// no keys pressed in row...
								}
								
								keybRowA15 = (~altKey ^ shiftKey) ^ (~keybRowA15); 
								
						break;

					case 0xBF:	// 10111111
								//			| D7     D6      D5      D4      D3      D2      D1      D0
								// -------------------------------------------------------------------------
								// A14 (#6) | HELP   LSH     TAB     DIA     MENU    ,       ;       '

                                // check for two-key combinations, here as SHIFT or CTRL with another key...
								if (z88Keyboard.isKeyDown(java.awt.event.KeyEvent.VK_CONTROL) == true) ctrlKey = 0xEF; // DIAMOND
								if (z88Keyboard.isKeyDown(java.awt.event.KeyEvent.VK_SHIFT) == true) shiftKey = 0xBF; // (Right or Left) SHIFT

								switch(currentKey) {
									case java.awt.event.KeyEvent.VK_F1: keybRowA14 = keyColumn = 0x7F; break; 		// HELP
									case java.awt.event.KeyEvent.VK_F12: keybRowA14 = keyColumn = 0xBF; break;		// LEFT SHIFT (10111111) (F12 = both shift keys down)
									case java.awt.event.KeyEvent.VK_SHIFT: keybRowA14 = keyColumn = 0xBF; break;	// SHIFT
                                    case java.awt.event.KeyEvent.VK_DELETE: keybRowA14 = keyColumn = 0xBF; break;   // SHIFT: Here (PC) DELETE = SHIFT BACKSPACE 
									case java.awt.event.KeyEvent.VK_TAB: keybRowA14 = keyColumn = 0xDF; break;		// TAB
									case java.awt.event.KeyEvent.VK_CONTROL: keybRowA14 = keyColumn = 0xEF; break;	// DIAMOND
									case java.awt.event.KeyEvent.VK_F3: keybRowA14 = keyColumn = 0xF7; break;		// MENU 
									// D2
									// D1
									// D0
									default: keybRowA14 = 0xFF;	// no keys pressed in row...
								}
			
								keybRowA14 = (~ctrlKey ^ shiftKey) ^ (~keybRowA14); 
						break;

					case 0xDF:	// 11011111
								//			| D7     D6      D5      D4      D3      D2      D1      D0
								// -------------------------------------------------------------------------
								// A13 (#5) | [      SPACE   1       Q       A       Z       L       0
								switch(currentKey) {
									// D7
									case java.awt.event.KeyEvent.VK_SPACE: keybRowA13 = keyColumn = 0xBF; break;	// SPACE (10111111)
                                    case java.awt.event.KeyEvent.VK_1: keybRowA13 = keyColumn = 0xDF; break;
                                    case java.awt.event.KeyEvent.VK_Q: keybRowA13 = keyColumn = 0xEF; break;
                                    case java.awt.event.KeyEvent.VK_A: keybRowA13 = keyColumn = 0xF7; break;
                                    case java.awt.event.KeyEvent.VK_Z: keybRowA13 = keyColumn = 0xFB; break;
                                    case java.awt.event.KeyEvent.VK_L: keybRowA13 = keyColumn = 0xFD; break;
                                    case java.awt.event.KeyEvent.VK_0: keybRowA13 = keyColumn = 0xFE; break;
									default: keybRowA13 = 0xFF;	// no keys pressed in row...
								}												
						break;

					case 0xEF:	// 11101111
								//			| D7     D6      D5      D4      D3      D2      D1      D0
								// -------------------------------------------------------------------------			
								// A12 (#4) | ]      LFT     2       W       S       X       M       P
								switch(currentKey) {
									// D7
									case java.awt.event.KeyEvent.VK_LEFT: keybRowA12 = keyColumn = 0xBF; break;		// LEFT CURSOR (10111111)
                                    case java.awt.event.KeyEvent.VK_2: keybRowA12 = keyColumn = 0xDF; break;
                                    case java.awt.event.KeyEvent.VK_W: keybRowA12 = keyColumn = 0xEF; break;
                                    case java.awt.event.KeyEvent.VK_S: keybRowA12 = keyColumn = 0xF7; break;
                                    case java.awt.event.KeyEvent.VK_X: keybRowA12 = keyColumn = 0xFB; break;
                                    case java.awt.event.KeyEvent.VK_M: keybRowA12 = keyColumn = 0xFD; break;
                                    case java.awt.event.KeyEvent.VK_P: keybRowA12 = keyColumn = 0xFE; break;                                    
									default: keybRowA12 = 0xFF;	// no keys pressed in row...
								}
						break;
				
					case 0xF7:	// 11110111
								//			| D7     D6      D5      D4      D3      D2      D1      D0			
								// -------------------------------------------------------------------------
								// A11 (#3) | -      RGT     3       E       D       C       K       9
								switch(currentKey) {
									// D7
									case java.awt.event.KeyEvent.VK_RIGHT: keybRowA11 = keyColumn = 0xBF; break;	// RIGHT CURSOR (10111111)
                                    case java.awt.event.KeyEvent.VK_3: keybRowA11 = keyColumn = 0xDF; break;
                                    case java.awt.event.KeyEvent.VK_E: keybRowA11 = keyColumn = 0xEF; break;
                                    case java.awt.event.KeyEvent.VK_D: keybRowA11 = keyColumn = 0xF7; break;
                                    case java.awt.event.KeyEvent.VK_C: keybRowA11 = keyColumn = 0xFB; break;
                                    case java.awt.event.KeyEvent.VK_K: keybRowA11 = keyColumn = 0xFD; break;
                                    case java.awt.event.KeyEvent.VK_9: keybRowA11 = keyColumn = 0xFE; break;
									default: keybRowA11 = 0xFF;	// no keys pressed in row...
								}
						break;
				
					case 0xFB:	// 11111011
								//			| D7     D6      D5      D4      D3      D2      D1      D0			
								// -------------------------------------------------------------------------
								// A10 (#2) | =      DWN     4       R       F       V       J       O
								switch(currentKey) {
									// D7
									case java.awt.event.KeyEvent.VK_DOWN: keybRowA10 = keyColumn = 0xBF; break;		// DOWN CURSOR (10111111)
                                    case java.awt.event.KeyEvent.VK_4: keybRowA10 = keyColumn = 0xDF; break;
                                    case java.awt.event.KeyEvent.VK_R: keybRowA10 = keyColumn = 0xEF; break;
                                    case java.awt.event.KeyEvent.VK_F: keybRowA10 = keyColumn = 0xF7; break;
                                    case java.awt.event.KeyEvent.VK_V: keybRowA10 = keyColumn = 0xFB; break;
                                    case java.awt.event.KeyEvent.VK_J: keybRowA10 = keyColumn = 0xFD; break;
                                    case java.awt.event.KeyEvent.VK_O: keybRowA10 = keyColumn = 0xFE; break;
									default: keybRowA10 = 0xFF;	// no keys pressed in row...
								}
						break;
				
					case 0xFD:	// 11111101
								//			| D7     D6      D5      D4      D3      D2      D1      D0			
								// -------------------------------------------------------------------------
								// A9  (#1) | \      UP      5       T       G       B       U       I
								switch(currentKey) {
									// D7
									case java.awt.event.KeyEvent.VK_UP: keybRowA9 = keyColumn = 0xBF; break;		// UP CURSOR
                                    case java.awt.event.KeyEvent.VK_5: keybRowA9 = keyColumn = 0xDF; break;
                                    case java.awt.event.KeyEvent.VK_T: keybRowA9 = keyColumn = 0xEF; break;
                                    case java.awt.event.KeyEvent.VK_G: keybRowA9 = keyColumn = 0xF7; break;
                                    case java.awt.event.KeyEvent.VK_B: keybRowA9 = keyColumn = 0xFB; break;
                                    case java.awt.event.KeyEvent.VK_U: keybRowA9 = keyColumn = 0xFD; break;
                                    case java.awt.event.KeyEvent.VK_I: keybRowA9 = keyColumn = 0xFE; break;                                    
									default: keybRowA9 = 0xFF;	// no keys pressed in row...
								}
						break;
				
					case 0xFE:	// 11111110
								//			| D7     D6      D5      D4      D3      D2      D1      D0			
								// -------------------------------------------------------------------------
								// A8  (#0) | DEL    ENTER   6       Y       H       N       7       8
								switch(currentKey) {
									case java.awt.event.KeyEvent.VK_BACK_SPACE: keybRowA8 = keyColumn = 0x7F; break; 	// BACKSPACE
                                    case java.awt.event.KeyEvent.VK_DELETE: keybRowA8 = keyColumn = 0x7F; break;        // (PC) DELETE = SHIFT BACKSPACE
									case java.awt.event.KeyEvent.VK_ENTER: keybRowA8 = keyColumn = 0xBF; break;			// ENTER
                                    case java.awt.event.KeyEvent.VK_6: keybRowA8 = keyColumn = 0xDF; break;
                                    case java.awt.event.KeyEvent.VK_Y: keybRowA8 = keyColumn = 0xEF; break;
                                    case java.awt.event.KeyEvent.VK_H: keybRowA8 = keyColumn = 0xF7; break;
                                    case java.awt.event.KeyEvent.VK_N: keybRowA8 = keyColumn = 0xFB; break;
                                    case java.awt.event.KeyEvent.VK_7: keybRowA8 = keyColumn = 0xFD; break;
                                    case java.awt.event.KeyEvent.VK_8: keybRowA8 = keyColumn = 0xFE; break;
									default: keybRowA8 = 0xFF;	// no keys pressed in row...
								}
						break;
				}
				
				row <<= 1;		// look at next row...
				row |= 1;		// make sure that left shift always contains 1 at bit 0...
				row &= 0xFF;	// only 8bit boundary...
			}
            
			if ( (keyColumn != 0xFF) && ((INT & Blink.BM_INTKEY) == Blink.BM_INTKEY) ) {
                // If keyboard interrupts are enabled, then signal that a key was pressed.
				STA |= BM_STAKEY;
			}
		}


		/**
		 * Send an INT each 10ms to the Z80 processor...
		 */
		private final class Int10ms extends TimerTask {
			public void run() {
                scanKeyboard();  // Blink always scans the keyboard...
                
                // signal Maskable interrupt to be executed, as soon as Z80 is ready to grab it...
                setNmi(false);
                setInterruptSignal();
			}
		}

		/**
		 * Stop the 10ms interrupt. 
		 */
		public void stop() {
			if (intIm1 != null) {
				intIm1.cancel();
			}
		}

		/**
		 * Start interrupt to the Z80 after a 10ms delay, and execute the run()
		 * method every 10 millisecond.
		 */
		public void start() {
			intIm1 = new Int10ms();
			timerDaemon.scheduleAtFixedRate(intIm1, 10, 10);
		}
	} /* Z80interrupt class */
}
