; Program for outline of code to do MOSI SPI with 7-segment MAX7219

.cpu 6502
.equ outputKIM, 0x1700 ; variable for address of SPI pins (where output will be sent from), bit 7 is MOSI, bit 6 is SS, bit 5 is SCLK
.equ outputSettings, 0x1701 ; variable for address of output settings, where we can set pins to inputs or outputs

.equ output, 0x1000 ; variable for address of output (for byte_send)

.equ byte1, 0x1001 ; variable for address of display address byte
.equ byte2, 0x1002 ; variable for address of display digit byte 

.org 0x0200

main:
    ; example code to display a 1 to the rightmost digit of a MAX7219 7 segment display with SPI
    ; data sheet: https://www.analog.com/media/en/technical-documentation/data-sheets/max7219-max7221.pdf
    ; ideally you would put the setup and sending of address and data bytes in their own subroutines (which are like functions) to optimize process

    JSR setup
    JSR initialize

    ; send data for number 1 to digit 0 of display in code B decode
    
    ; send bytes to display 0 on digit 7 (Address 0x08 -> data[0])
    LDA #0x08
    STA byte1
    LDA #0x0F
    STA byte2
    
    JSR bytes_send
    
    ; display 0 on digit 6 (Address 0x07 -> data[1])
    LDA #0x07
    STA byte1
    LDA #0x0F
    STA byte2
    
    JSR bytes_send
    
    ; display 0 on digit 5 (Address 0x06 -> data[2])
    LDA #0x06
    STA byte1
    LDA #0x0F
    STA byte2
    
    JSR bytes_send
    
    ; display 0 on digit 4 (Address 0x05 -> data[3])
    LDA #0x05
    STA byte1
    LDA #0x0F
    STA byte2
    
    JSR bytes_send
    
    ; display 0 on digit 3 (Address 0x04 -> data[4])
    LDA #0x04
    STA byte1
    LDA #0x0F
    STA byte2
    
    JSR bytes_send
    
    ; display 0 on digit 2 (Address 0x03 -> data[5])
    LDA #0x03
    STA byte1
    LDA #0x0F
    STA byte2
    
    JSR bytes_send
    
    ; display 0 on digit 1 (Address 0x02 -> data[6])
    LDA #0x02
    STA byte1
    LDA #0x0F
    STA byte2
    
    JSR bytes_send
    
    ; display 1 on digit 0 (Address 0x01 -> data[7])
    LDA #0x01
    STA byte1
    LDA #0x01
    STA byte2
    
    JSR bytes_send


    BRK ; end program



byte_send: ; subroutine to send 8 bits

    set_clk_low: ; set the clock low before getting data in pin 7
        LDA outputKIM
        AND #0b11011111   ; Pull CLK (bit 5) low
        STA outputKIM
    
    set_counter: ; counter to see how many bits have been sent of byte
        LDX #0x08
        
    send_output: ; send byte of data
        
        ; store output bit in outputKIM bit 7
        LDA output ; load output into accumulator
        AND #0b10000000 ; AND output so only last bit is recognized
        ORA outputKIM ; OR output to what's in 0x1700, nothing is changed except last bit
        STA outputKIM ; store result in KIM output bit
        
        ASL output ; arithmetic shift left of output1 to move next output1 bit to bit 0
    
    clk_cycle: ; simulate a clock cycle that occurs
               ; data has to be stable before clock rising edge
        
        LDA outputKIM ;load outputKIM into memory
        EOR #0b00100000 ; Invert SCLK (bit 5)
        STA outputKIM ; Store into outputKIM
        
        LDA outputKIM ; load outputKIM
        EOR #0b00100000 ; Invert SCLK (bit 5)
        STA outputKIM ; Store into outputKIM
        
        LDA outputKIM ; set final digit of outputKIM to 0 so it is modified correctly on next edge
        AND #0b01111111
        STA outputKIM
        
        DEX ; decrement number of bits remaining to be sent
        
        BNE send_output ; jump to send_output for next bit
        
    RTS ; end subroutine


bytes_send: ; subroutine to send 2 bytes for MAX7219 display
    
    ; set SS pin low
    set_ss_low:
        LDA outputKIM
        AND #0b10111111 ; Pull SS (bit 6) low
        STA outputKIM
    
    ; send address byte
    send_address:
        LDA byte1
        STA output
        JSR byte_send
    
    ; send data byte
    send_data:
        LDA byte2
        STA output
        JSR byte_send
    
    ; set SS pin high
    set_ss_high:
        LDA outputKIM
        ORA #0b01000000 ; Pull SS (bit 6) high
        STA outputKIM
        
    RTS ; end subroutine
    
setup: ; setup subroutine

    clear_decimal_mode:
        CLD
    
    set_initial_output_state: ; set outputKIM to 0x00
        LDA #0x00
        STA outputKIM
    
    make_output: ; make port A an output
        LDA #0xFF
        STA outputSettings
    
    set_low: ; Pull SS and CLK pin to low by AND with outputKIM and storing it back
            LDA outputKIM
            AND #0b11011111  ; Pull CLK (bit 5) low
            AND #0b10111111  ; Pull SS (bit 6) low
            STA outputKIM
            
    RTS

initialize: ; Initialize MAX7219 subroutine

    ; Set Decode Mode to code B (Address 0x09 -> Data 0xFF)
    LDA #0x09
    STA byte1
    LDA #0xFF
    STA byte2
    JSR bytes_send

    ; Set Intensity (Address 0x0A -> Data 0x0F)
    LDA #0x0A
    STA byte1
    LDA #0x0F
    STA byte2
    JSR bytes_send

    ; Set Scan Limit (Address 0x0B -> Data 0x07)
    LDA #0x0B
    STA byte1
    LDA #0x07
    STA byte2
    JSR bytes_send

    ; Turn on display (Address 0x0C -> Data 0x01)
    LDA #0x0C
    STA byte1
    LDA #0x01
    STA byte2
    JSR bytes_send

    ; Exit Display Test Mode (Address 0x0F -> Data 0x00)
    LDA #0x0F
    STA byte1
    LDA #0x00
    STA byte2
    JSR bytes_send
    
    RTS ; end subroutine



; put data or whatever here
; .include "file.txt" or something