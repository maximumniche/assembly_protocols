; Program for outline of code to do SPI

.cpu 6502
.equ outputKIM, 0x1700 ; variable for address of SPI pins (where output will be sent from), bit 7 is MOSI, bit 6 is SS, bit 5 is SCLK
.equ outputSettings, 0x1701 ; variable for address of output settings, where we can set pins to inputs or outputs

.equ output, 0x1000 ; variable for address of output (for byte_send)

.equ byte1, 0x1001 ; variable for address of first byte sent (for spi_send)
.equ byte2, 0x1002 ; variable for address of second byte sent (for spi_send)

.org 0x0000

byte_send: ; subroutine to send 8 bits (bit 7 is data, bit 6 is CS/SS, bit 7 is CLK)

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

.org 0x2000 ; 