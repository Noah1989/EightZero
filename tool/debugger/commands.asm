command_table:
        ;word-aligned, little endian
        .dw     '?', help
        .dw     'i', read_product_id
        .dw     's', read_status
        .dw     'b', break_next
        .dw     'c', continue_from_break
        .dw     'r', read_cpu_registers
        .dw     'm', read_memory
        .dw     'w', write_memory
        .dw     '+', increase_pc
        .dw     '-', decrease_pc
        .dw     '0', reset_pc
        .dw     0

help:
        ldi     ZH, HIGH(help_string*2)
        ldi     ZL, LOW(help_string*2)
        rcall   write_string
        ret
help_string:
        .db     "?: help ", 13, 10
        .db     "i: read product id", 13, 10
        .db     "s: read status", 13, 10
        .db     "b: break on next instruction", 13, 10
        .db     "c: continue from break", 13, 10
        .db     "r: read CPU registers ", 13, 10
        .db     "m: read from memory at PC ", 13, 10
        .db     "w: write to memory at PC", 13, 10
        .db     "+: increase PC", 13, 10
        .db     "-: decrease PC", 13, 10
        .db     "0: set PC to RAM start ", 13, 10, 0

read_product_id:
        ; high
        ldi     addr, ZDI_ID_H
        rcall   zdi_read
        mov     temp, data
        rcall   write_hex_byte
        ; low
        ldi     addr, ZDI_ID_L
        rcall   zdi_read
        mov     temp, data
        rcall   write_hex_byte
        ; revision
        ldi     addr, ZDI_ID_REV
        rcall   zdi_read
        mov     temp, data
        rcall   write_hex_byte
        ; newline
        rcall   write_newline
        ret


read_status:
        ; get status
        ldi     addr, ZDI_STAT
        rcall   zdi_read
        ; print bits
        clr     temp
        ldi     ZH, HIGH(read_status_string_zdi_active*2)
        ldi     ZL, LOW(read_status_string_zdi_active*2)
        bst     data, ZDI_ACTIVE
        rcall   read_status_print_bit
        ldi     ZH, HIGH(read_status_string_halt_slp*2)
        ldi     ZL, LOW(read_status_string_halt_slp*2)
        bst     data, HALT_SLP
        rcall   read_status_print_bit
        ldi     ZH, HIGH(read_status_string_adl*2)
        ldi     ZL, LOW(read_status_string_adl*2)
        bst     data, ADL
        rcall   read_status_print_bit
        ldi     ZH, HIGH(read_status_string_madl*2)
        ldi     ZL, LOW(read_status_string_madl*2)
        bst     data, MADL
        rcall   read_status_print_bit
        ldi     ZH, HIGH(read_status_string_ief1*2)
        ldi     ZL, LOW(read_status_string_ief1*2)
        bst     data, IEF1
read_status_print_bit:
        rcall   write_string
        bld     temp, 0
        rcall   write_hex_nibble
        rcall   write_newline
        ret
read_status_string_zdi_active:
        .db     "ZDI ACTIVE: ", 0, 0
read_status_string_halt_slp:
        .db     "HALT/SLEEP: ", 0, 0
read_status_string_adl:
        .db     "  ADL MODE: ", 0, 0
read_status_string_madl:
        .db     " MIXED ADL: ", 0, 0
read_status_string_ief1:
        .db     "INT ENABLE: ", 0, 0


break_next:
        ldi     addr, ZDI_BRK_CTL
        ldi     data, 1<<BRK_NEXT
        rcall   zdi_write
        ret

continue_from_break:
        ldi     addr, ZDI_BRK_CTL
        ldi     data, 0
        rcall   zdi_write
        ret

read_cpu_registers:
        ; first read command and label string
        ldi     readcmd, READ_AF
        ldi     ZH, HIGH(read_cpu_registers_string_af*2)
        ldi     ZL, LOW(read_cpu_registers_string_af*2)
read_cpu_registers_loop:
        rcall   read_cpu_registers_print
        ; next string (skip padding zero byte)
        adiw    ZL, 1
        ; next read command
        inc     readcmd
        cpi     readcmd, READ_PC
        brlo    read_cpu_registers_loop
read_cpu_registers_print:
        ; label
        rcall   write_string
        ; command
        ldi     addr, ZDI_RW_CTL
        mov     data, readcmd
        rcall   zdi_write
        ; get high
        ldi     addr, ZDI_RD_H
        rcall   zdi_read
        mov     temp, data
        rcall   write_hex_byte
        ; get lower
        ldi     addr, ZDI_RD_L
        rcall   zdi_read
        mov     temp, data
        rcall   write_hex_byte
        ; newline
        rcall   write_newline
        ret
read_cpu_registers_string_af:
        .db     "FA: ", 0, 0
read_cpu_registers_string_bc:
        .db     "BC: ", 0, 0
read_cpu_registers_string_de:
        .db     "DE: ", 0, 0
read_cpu_registers_string_hl:
        .db     "HL: ", 0, 0
read_cpu_registers_string_ix:
        .db     "IX: ", 0, 0
read_cpu_registers_string_iy:
        .db     "IY: ", 0, 0
read_cpu_registers_string_sp:
        .db     "SP: ", 0, 0
read_cpu_registers_string_pc:
        .db     "PC: ", 0, 0



read_memory:
        rcall   get_pc
        ; read 8 bytes
        ldi     counter, 8
read_memory_loop:    
        ; read byte
        ldi     addr, ZDI_RD_MEM
        rcall   zdi_read
        mov     temp, data
        rcall   write_hex_byte
        ; inc PC
        adiw    XL, 1
        rcall   set_pc
        ; next
        dec     counter
        brne    read_memory_loop
        ; restore PC
        sbiw    XL, 8
        rcall   set_pc        
        ; newline
        rcall   write_newline
        ret

write_memory:
        ; get byte
        rcall   read_hex_byte
        mov     data, temp
        ; echo back
        rcall   write_hex_byte
        ; write memory
        ldi     addr, ZDI_WR_MEM
        rcall   zdi_write
        ; newline
        rcall   write_newline
        ret

get_pc:
        ; get PC
        ldi     addr, ZDI_RW_CTL
        ldi     data, READ_PC
        rcall   zdi_write
        ; get PC high
        ldi     addr, ZDI_RD_H
        rcall   zdi_read
        mov     XH, data
        ; get PC lower
        ldi     addr, ZDI_RD_L
        rcall   zdi_read
        mov     XL, data
        ret

set_pc:
        ; PC high
        ldi     addr, ZDI_WR_DATA_H
        mov     data, XH
        rcall   zdi_write
        ; PC lower
        ldi     addr, ZDI_WR_DATA_L
        mov     data, XL
        rcall   zdi_write
        ; set PC
        ldi     addr, ZDI_RW_CTL
        ldi     data, WRITE_PC
        rcall   zdi_write
        ret

print_pc:                
        mov     temp, XH
        rcall   write_hex_byte
        mov     temp, XL
        rcall   write_hex_byte
        rcall   write_newline
        ret

increase_pc:
        rcall   get_pc
        adiw    XL, 1
        rcall   set_pc
        rcall   print_pc
        ret

decrease_pc:
        rcall   get_pc
        sbiw    XL, 1
        rcall   set_pc
        rcall   print_pc
        ret


reset_pc:
        ; this sets RAM_ADDR_U to 0x00 and PC to $E000
        
        ;!; ADL mode on
        ;!ldi     addr, ZDI_RW_CTL
        ;!ldi     data, SET_ADL
        ;!rcall   zdi_write
        
        ; RAM_ADDR_U value: 0x00
        ldi     addr, ZDI_WR_DATA_L
        ldi     data, 0x00
        rcall   zdi_write
        ; load value into A
        ; gets loaded into RAM_ADDR_U
        ; by executing an instruction
        ldi     addr, ZDI_RW_CTL
        ldi     data, WRITE_AF
        rcall   zdi_write
        ; eZ80: OUT0 (RAM_ADDR_U), A -> ED 39 B5
        ldi     addr, ZDI_IS2
        ldi     data, 0xB5
        rcall   zdi_write
        ldi     addr, ZDI_IS1
        ldi     data, 0x39
        rcall   zdi_write
        ldi     addr, ZDI_IS0
        ldi     data, 0xED
        rcall   zdi_write
        
        ;!; ADL mode off
        ;!ldi     addr, ZDI_RW_CTL
        ;!ldi     data, RESET_ADL
        ;!rcall   zdi_write
        
        ldi     XH, 0xE0
        ldi     XL, 0x00
        rcall   set_pc
        rcall   print_pc
        ret
