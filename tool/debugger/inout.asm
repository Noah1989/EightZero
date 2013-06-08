usart_init:
        ; set baud rate (9600 @ 1MHz Clock)
        ldi     temp, 12
        out     UBRRH, zero
        out     UBRRL, r16
        sbi     UCSRA, U2X
        ; enable receiver and transmitter
        ldi     temp, (1<<RXEN)|(1<<TXEN)
        out     UCSRB, r16
        ; set frame format: 8data, 1stop bit, no parity
        ldi     temp, (1<<UCSZ1)|(1<<UCSZ0)
        out     UCSRC, r16
        ret

write_hex_byte:
	mov     tmph, temp
	swap    temp
	rcall   write_hex_nibble
	mov     temp, tmph
	rcall   write_hex_nibble
	ldi     temp, ' '
	rcall   usart_transmit
	ret
	
write_hex_nibble:
	andi    temp, 0x0F
	subi    temp, -'0'
	cpi     temp, '9'+1
	brlo    write_hex_nibble_out
	subi    temp, ('9'+1)-'A'
write_hex_nibble_out:
    rcall   usart_transmit
	ret	
	
read_hex_byte:
    rcall   read_hex_nibble
    swap    temp
    mov     tmph, temp
    rcall   read_hex_nibble
    or      temp, tmph
    ret
	
read_hex_nibble:
    rcall   usart_receive    
    subi    temp, '0'
    ; ignore invalid characters
    brlo    read_hex_nibble    
    cpi     temp, 0x0A
    ; return if 0..9
    brlo    read_hex_nibble_end   
    cpi     temp, 'a'-'0'
    ; continue if not small letters
    brlo    read_hex_nibble_letter
    ; small letter to capital letter
    subi    temp, 'a'-'A'
read_hex_nibble_letter:
    subi    temp, 'A'-('9'+1)
    cpi     temp, 0x0A
    ; ignore invalid (too small)
    brlo    read_hex_nibble
    cpi     temp,  0x10
    ; ignore invalid (too large)
    brsh    read_hex_nibble
read_hex_nibble_end:
    ret
        
write_string:
        ; write null terminated string at Z location to output
        lpm     temp, Z+        
        tst     temp
        breq    write_string_end
        rcall   usart_transmit
        rjmp    write_string 
write_string_end:
        ret 
        
write_newline:
        ldi     temp, 13
        rcall   usart_transmit
        ldi     temp, 10
        rcall   usart_transmit
        ret    

usart_transmit:
        ; wait for empty transmit buffer
        sbis    UCSRA, UDRE
        rjmp    usart_transmit        
        ; send byte
        out     UDR, temp
        ret

usart_receive:
        ; wait for data to be received
        sbis    UCSRA, RXC
        rjmp    usart_receive
        in      temp, UDR
        ret
