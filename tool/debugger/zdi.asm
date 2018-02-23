.equ ZDI_PORT =  PORTB
.equ ZDI_DDR = DDRB
.equ ZDI_PIN = PINB
.equ ZDA = PB0
.equ ZCL = PB1

; ZDI write-only registers
.equ ZDI_BRK_CTL = 0x10
.equ ZDI_WR_DATA_L = 0x13
.equ ZDI_WR_DATA_H = 0x14
.equ ZDI_WR_DATA_U = 0x15
.equ ZDI_RW_CTL = 0x16
.equ ZDI_IS4 = 0x21
.equ ZDI_IS3 = 0x22
.equ ZDI_IS2 = 0x23
.equ ZDI_IS1 = 0x24
.equ ZDI_IS0 = 0x25
.equ ZDI_WR_MEM = 0x30

; ZDI read-only registers
.equ ZDI_ID_L = 0x00
.equ ZDI_ID_H = 0x01
.equ ZDI_ID_REV = 0x02
.equ ZDI_STAT = 0x03
.equ ZDI_RD_L = 0x10
.equ ZDI_RD_H = 0x11
.equ ZDI_RD_U = 0x12
.equ ZDI_RD_MEM = 0x20

; ZDI status bits
.equ ZDI_ACTIVE = 7
.equ HALT_SLP = 5
.equ ADL = 4
.equ MADL = 3
.equ IEF1 = 2

; ZDU break control bits
.equ BRK_NEXT = 7

; ZDU Read/Write Control Register Functions
.equ READ_AF = 0x00
.equ READ_BC = 0x01
.equ READ_DE = 0x02
.equ READ_HL = 0x03
.equ READ_IX = 0x04
.equ READ_IY = 0x05
.equ READ_SP = 0x06
.equ READ_PC = 0x07
.equ SET_ADL = 0x08
.equ RESET_ADL = 0x09
.equ WRITE_AF = 0x80
.equ WRITE_BC = 0x81
.equ WRITE_DE = 0x82
.equ WRITE_HL = 0x83
.equ WRITE_IX = 0x84
.equ WRITE_IY = 0x85
.equ WRITE_SP = 0x86
.equ WRITE_PC = 0x87


zdi_read:
        ; send start signal and address
        rcall zdi_start_addr
        ; read/write bit
        cbi     ZDI_PORT, ZCL
        sbi     ZDI_PORT, ZDA
        sbi     ZDI_PORT, ZCL    
        ; separator
        cbi     ZDI_PORT, ZCL
        sbi     ZDI_PORT, ZDA
        sbi     ZDI_PORT, ZCL                
        ; read data
        cbi     ZDI_DDR, ZDA
        ldi     temp, 8
        clr     data
        clc
zdi_read_loop:
        ; clock        
        cbi     ZDI_PORT, ZCL
        sbi     ZDI_PORT, ZCL
        ; get bit into carry
        sbic    ZDI_PIN, ZDA
        sec
        ; shift carry into data
        rol     data
        dec     temp
        brne    zdi_read_loop
        ; end of data
        cbi     ZDI_PORT, ZCL
        sbi     ZDI_PORT, ZCL
        ; release clock
        cbi     ZDI_DDR, ZCL
        ret

zdi_write:
        ; send start signal and address
        rcall zdi_start_addr
        ; read/write bit
        cbi     ZDI_PORT, ZCL
        cbi     ZDI_PORT, ZDA
        sbi     ZDI_PORT, ZCL    
        ; separator
        cbi     ZDI_PORT, ZCL
        sbi     ZDI_PORT, ZDA
        sbi     ZDI_PORT, ZCL                
        ; write data       
        ldi     temp, 8        
zdi_write_loop:
        ; ZCL low        
        cbi     ZDI_PORT, ZCL
        ; MSB into carry
        rol     data
        brcs    zdi_write_bit_set
        cbi     ZDI_PORT, ZDA
        rjmp    zdi_write_continue
zdi_write_bit_set:
        sbi     ZDI_PORT, ZDA
zdi_write_continue:
        ; ZCL high
        sbi     ZDI_PORT, ZCL
        dec     temp
        brne    zdi_write_loop
        ; additional rol to retain original data value
        rol     data
        ; end of data
        cbi     ZDI_PORT, ZCL
        sbi     ZDI_PORT, ZCL
        ; release clock and data
        cbi     ZDI_DDR, ZCL
        cbi     ZDI_DDR, ZDA
        ret

zdi_start_addr:
        ; start signal:  ZDA falling while ZCL is high        
        sbi     ZDI_PORT, ZCL
        sbi     ZDI_DDR, ZCL        
        cbi     ZDI_PORT, ZDA
        sbi     ZDI_DDR, ZDA    
        ; 7-bit adress    
        ldi     temp, 7
zdi_start_addr_loop:
        ; ZCL low
        cbi     ZDI_PORT, ZCL
        ; output bit
        rol     addr
        brmi    zdi_start_addr_bit_set
        cbi     ZDI_PORT, ZDA
        rjmp    zdi_start_addr_continue
zdi_start_addr_bit_set:
        sbi     ZDI_PORT, ZDA
zdi_start_addr_continue:
        ; ZCL high
        sbi     ZDI_PORT, ZCL
        dec     temp
        brne    zdi_start_addr_loop
        ; additional rols to retain original addr value
        rol     addr
        rol     addr
        ret
