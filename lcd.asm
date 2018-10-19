;------------------------------------------------------------------------------
;       At the moment, the LCD is connected as:
;               DB7:0   =       PA7:0
;               RS      =       PB1
;               EN      =       PB0
;       TODO:   Convert to 4 bit mode and free up four pins
;------------------------------------------------------------------------------
.segment "LCD"

;===============================================================================
;                   |                     Instruction Code                     |
;                   |----+-----+-----+-----+-----+-----+-----+-----+-----+-----|
; Instruction       | RS | R/W | DB7 | DB6 | DB5 | DB4 | DB3 | DB2 | DB1 | DB0 |
;-------------------+----+-----+-----+-----+-----+-----+-----+-----+-----+-----|
; Clear Display     |  0 |  0  |  0  |  0  |  0  |  0  |  0  |  0  |  0  |  1  |
;-------------------+----+-----+-----+-----+-----+-----+-----+-----+-----+-----|
; Return Home       |  0 |  0  |  0  |  0  |  0  |  0  |  0  |  0  |  1  |  x  |
;-------------------+----+-----+-----+-----+-----+-----+-----+-----+-----+-----|
; Entry Mode Set    |  0 |  0  |  0  |  0  |  0  |  0  |  0  |  1  | I/D |  SH |
;-------------------+----+-----+-----+-----+-----+-----+-----+-----+-----+-----|
; Disp ON/OFF Ctrl  |  0 |  0  |  0  |  0  |  0  |  0  |  1  |  D  |  C  |  B  |
;-------------------+----+-----+-----+-----+-----+-----+-----+-----+-----+-----|
; Cursor/Disp Shft  |  0 |  0  |  0  |  0  |  0  |  1  | S/C | R/L |  x  |  x  |
;-------------------+----+-----+-----+-----+-----+-----+-----+-----+-----+-----|
; Function Set      |  0 |  0  |  0  |  0  |  1  |  DL |  N  |  F  |  x  |  x  |
;-------------------+----+-----+-----+-----+-----+-----+-----+-----+-----+-----|
; Set CGRAM Address |  0 |  0  |  0  |  1  | AC5 | AC4 | AC3 | AC2 | AC1 | AC0 |
;-------------------+----+-----+-----+-----+-----+-----+-----+-----+-----+-----|
; Set DDRAM Address |  0 |  0  |  1  | AC6 | AC5 | AC4 | AC3 | AC2 | AC1 | AC0 |
;-------------------+----+-----+-----+-----+-----+-----+-----+-----+-----+-----|
; Rd Busy Flg & Addr|  0 |  1  | BF  | AC6 | AC5 | AC4 | AC3 | AC2 | AC1 | AC0 |
;-------------------+----+-----+-----+-----+-----+-----+-----+-----+-----+-----|
; Write Data to RAM |  1 |  0  |  D7 |  D6 |  D5 |  D4 |  D3 |  D2 |  D1 |  D0 |
;-------------------+----+-----+-----+-----+-----+-----+-----+-----+-----+-----|
; Read Data frm RAM |  1 |  1  |  D7 |  D6 |  D5 |  D4 |  D3 |  D2 |  D1 |  D0 |
;===============================================================================

;===============================================================================
; Instruction       | Description                                    |Exe Time |
;-------------------+------------------------------------------------+---------|
;                   |                                                |         |
; Clear Display     | Write “20H” to DDRAM and set DDRAM address     | 1.53 ms |
;                   | to “00H” from AC.                              |         |
;-------------------+------------------------------------------------+---------|
;                   |                                                |         |
; Return Home       | Set DDRAM address to “00H” from AC and return  | 1.53 ms |
;                   | cursor to its original position if shifted.    |         |
;-------------------+------------------------------------------------+---------|
;                   |                                                |         |
; Entry Mode Set    | Assign cursor moving direction and enable the  |  39 µs  |
;                   | shift of entire display .                      |         |
;-------------------+------------------------------------------------+---------|
;                   |                                                |         |
; Disp ON/OFF Ctrl  | Set display (D), cursor (C), and blinking of   |  39 µs  |
;                   | cursor (B) on/off control bit.                 |         |
;-------------------+------------------------------------------------+---------|
;                   | Set cursor moving and display shift control    |         |
; Cursor/Disp Shft  | bit, and the direction, without changing of    |  39 µs  |
;                   | DDRAM data.                                    |         |
;-------------------+------------------------------------------------+---------|
;                   | Set interface data length (DL : 4-bit/8-bit),  |         |
; Function Set      | numbers of display line (N : 1-line/ 2-line,   |  39 µs  |
;                   | Display font type (F:0 ...)                    |         |
;-------------------+------------------------------------------------+---------|
;                   |                                                |         |
; Set CGRAM Address | Set CGRAM address in address counter.          |  39 µs  |
;                   |                                                |         |
;-------------------+------------------------------------------------+---------|
;                   |                                                |         |
; Set DDRAM Address | Set DDRAM address in address counter.          |  39 µs  |
;                   |                                                |         |
;-------------------+------------------------------------------------+---------|
;                   | Whether during internal operation or not can   |         |
; Rd Busy Flg & Addr| be known by reading BF.  The contents of       |  0 µs   |
;                   | address counter can also be read.              |         |
;-------------------+------------------------------------------------+---------|
;                   |                                                |         |
; Write Data to RAM | Write data into internal RAM (DDRAM/CGRAM).    |  43 µs  |
;                   |                                                |         |
;-------------------+------------------------------------------------+---------|
;                   |                                                |         |
; Read Data frm RAM | Read data from internal RAM (DDRAM/CGRAM).     |  43 µs  |
;                   |                                                |         |
;===============================================================================



;------------------------------------------------------------------------------
;       Initialize the LCD module
;       Notice we're initializing the module three times.  It's been mentioned
;       that this is a good practice due to experience by seasoned coders
;       who have run into this before.
;       http://wilsonminesco.com/6502primer/LCDcode.asm
;------------------------------------------------------------------------------
LCD_INIT:
        JSR     DELAY1          ; Allow some time for the LCD module to warm up
        JSR     DELAY1
        JSR     LCD_CLEAR
        JSR     LCD_SET_DISPLAY_ON
        JSR     DELAY1
        JSR     LCD_CLEAR
        JSR     LCD_SET_DISPLAY_ON
        JSR     DELAY1
        JSR     LCD_CLEAR
        JSR     LCD_SET_DISPLAY_ON
        JSR     DELAY1
        RTS


;------------------------------------------------------------------------------
;       Clear Display
;       RS  R/W DB7 DB6 DB5 DB4 DB3 DB2 DB1 DB0
;       === === === === === === === === === ===
;        0   0   0   0   0   0   0   0   0   1 
;
;       Clear all the display data by writing "20H" (space code) to all DDRAM 
;       addresses, and set the DDRAM addresses to "00H" in the AC 
;       (address counter). Return cursor to original status, namely, bring the
;       cursor to the left edge on first line of the display. Make entry mode 
;       increment (I/D = "1")
;------------------------------------------------------------------------------
LCD_CLEAR:
        LDA     #%00000001
        STA     PA
        JSR     LCD_TOGGLE_EN
        RTS

;------------------------------------------------------------------------------
;       Display ON/OFF
;       RS  R/W DB7 DB6 DB5 DB4 DB3 DB2 DB1 DB0
;       === === === === === === === === === ===
;        0   0   0   0   0   0   1   D   C   B 
;
;       Control display/cursor/blink ON/OFF 1-bit register.
;       D : Display ON/OFF control bit
;               When D = “1”, entire display is turned on.
;               When D = “0”, display is turned off, but display data remains in
;               DDRAM.
;       C : Cursor ON/OFF control bit
;               When C = “1”, cursor is turned on.
;               When C = “0”, cursor disappears in current display, but I/D 
;               register retains its data.
;       B : Cursor Blink ON/OFF control bit
;               When B = “1”, cursor blink is on, which performs alternately 
;               between all the “1” data and display characters at the cursor 
;               position.
;               When B = “0”, blink is off.
;------------------------------------------------------------------------------
LCD_SET_DISPLAY_ON:
        LDA     PA
        ORA     #%00001111
        STA     PA
        JSR     LCD_TOGGLE_EN
        RTS


;------------------------------------------------------------------------------
;       Return Home
;       RS  R/W DB7 DB6 DB5 DB4 DB3 DB2 DB1 DB0
;       === === === === === === === === === ===
;        0   0   0   0   0   0   0   0   1   X 
;
;       Return Home is the cursor return home instruction.  Set DDRAM address 
;       to "00H" in the address counter.  Return cursor to its original site 
;       and return display to its original status, if shifted. 
;       Contents of DDRAM does not change.
;------------------------------------------------------------------------------
LCD_RETURN_HOME:
        LDA     PA
        ORA     #%00000010
        STA     PA
        JSR     LCD_TOGGLE_EN
        RTS


;------------------------------------------------------------------------------
;       Name:           LCD_TOGGLE_EN
;       Desc:           Toggles PB0 (the LCD EN pin) with a delay in between
;       Destroys:       Nothing
;------------------------------------------------------------------------------
LCD_TOGGLE_EN:
        JSR     DELAY1
        PHA

        LDA     PB
        ORA     #%00000001
        STA     PB
        JSR     DELAY1

        LDA     PB
        AND     #%11111110
        STA     PB
        JSR     DELAY1

        LDA     PB
        ORA     #%00000001
        STA     PB
        JSR     DELAY1

        PLA
        RTS


;------------------------------------------------------------------------------
;       Write data to RAM
;       RS  R/W DB7 DB6 DB5 DB4 DB3 DB2 DB1 DB0
;       === === === === === === === === === ===
;        1   0   D7  D6  D5  D4  D3  D2  D1  D0
;
;       Write binary 8-bit data to DDRAM/CGRAM.
;       The selection of RAM from DDRAM, and CGRAM, is set by the previous 
;       address set instruction: DDRAM address set, and CGRAM address set. 
;       RAM set instruction can also determine the AC direction to RAM.
;       After write operation, the address is automatically increased/decreased
;       by 1, according to the entry mode.
;------------------------------------------------------------------------------
LCD_WRITE:
;       Prepare for write...set RS to 1
        LDA     PB
        ORA     #%00000010
        STA     PB
        JSR     LCD_TOGGLE_EN

        RTS
