;               RAM:    0000-3FFF (using half of a 62256 32Kx8 SRAM)
;               I/O:    4000-7FFF (the 6522 VIA is addressed at $6000-$600F)
;               ROM:    8000-FFFF (using all 32KB of EPROM or EEPROM)


        .debuginfo  +
        .setcpu     "65C02"

VIA     :=      $6000
PB      :=      VIA
PA      :=      VIA + 1
DDRB    :=      VIA + 2
DDRA    :=      VIA + 3

Itempl  =       $11		; temporary integer low byte
Itemph  =       Itempl + 1	; temporary integer high byte


.include "lcd.asm"
.include "utils.asm"

;------------------------------------------------------------------------------
;       Main RESET Vector (ROM Startup)
;------------------------------------------------------------------------------
.segment "CODE"
RESET:  JSR     INITS

MAIN:
IRQ_Vector:
NMI_Vector:
        JMP     MAIN


;------------------------------------------------------------------------------
;       System Initializations
;------------------------------------------------------------------------------
INITS:
;       Set on-board VIA data direction registers
        LDA     #$FF
        STA     DDRA            ; PORT A is all output
        STA     DDRB            ; PORT B is all output

        JSR     LCD_INIT

        LDX     #<LINE1
        LDY     #>LINE1
        JSR     PrintString

        LDX     #<LINE3
        LDY     #>LINE3
        JSR     PrintString

        LDA     #$40
        JSR     LCD_SET_DRAM_ADDRESS

        LDX     #<LINE2
        LDY     #>LINE2
        JSR     PrintString

        LDX     #<LINE4
        LDY     #>LINE4
        JSR     PrintString



        JMP     MAIN

PrintString:
        STX     Itempl
        STY     Itempl + 1
        LDY     #0
@loop:  LDA     (Itempl), Y
        BEQ     done
        JSR     WriteLCD
        INY
        BNE     @loop       ; if doesn't branch, string is too long
done:   RTS


WriteLCD:
        STA     PA
        JSR     LCD_WRITE
        RTS

LINE1:
        .byte "*  Potpourri 6502  *", 0
LINE2:
        .byte "********************", 0
LINE3:
        .byte "Main Menu:          ", 0
LINE4:
        .byte "A> MONITOR  B> BASIC", 0

;------------------------------------------------------------------------------
;       Startup Vectors
;------------------------------------------------------------------------------
.segment "VECTORS"
        .word NMI_Vector        ; NMI Vector
        .word RESET             ; RESET Vector
        .word IRQ_Vector        ; IRQ Vector

