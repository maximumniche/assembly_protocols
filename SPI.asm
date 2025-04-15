; Program for outline of code to do MOSI SPI

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

    ; setup, need to send data to set decode mode, intensity, scan limit, and shutdown mode of MAX7219
    set_up:

        ; send data to set decode mode to code B decode for all digits
        LDA #0x09
        STA output
        JSR byte_send
        LDA #0xFF
        STA output
        JSR byte_send

        ; send data to set intensity to max
        LDA #0x0A
        STA output
        JSR byte_send
        LDA #0x0F
        STA output

        ; send data to set scan limit to all digits
        LDA #0x0B
        STA output
        JSR byte_send
        LDA #0x07
        STA output
        JSR byte_send

        ; send data to set shutdown mode to OFF aka normal operation
        LDA #0x0C
        STA output
        JSR byte_send
        LDA #0x01
        STA output
        JSR byte_send

    ; send data for number 1 to digit 0 of display in code B decode

    LDA #0x01 ; address for digit 0
    STA output
    JSR byte_send
    LDA #0x01 ; data byte for number 0
    STA output
    JSR byte_send

    BRK ; end program



byte_send: ; subroutine to send 8 bits (bit 7 is data, bit 6 is CS/SS, bit 5 is CLK)

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

setup: ; setup subroutine

    clear_decimal_mode:
        CLD
    
    set_initial_output_state: ; set outputKIM to 0x00
        LDA #0x00
        STA outputKIM
    
    make_output: ; make port A an output
        LDA #0xFF
        STA outputSettings
    
    set_low: ; Pull SS and CLK pin low by ANDing with outputKIM and storing it back
            LDA outputKIM
            AND #0b11011111  ; Pull CLK (bit 5) low
            AND #0b10111111  ; Pull SS (bit 6) low
            STA outputKIM
            
    RTS


.org 0x2000 ; 

; put data or whatever here
; .include "file.txt" or something