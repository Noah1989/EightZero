; serial - serial interface (uart) driver

INCLUDE "serial.inc"

XREF output_sequence

XDEF serial_init
XDEF serial_transmit
XDEF serial_receive

DEFC PD_ALT2 = $A5
DEFC UART0_THR = $C0
DEFC UART0_RBR = $C0
DEFC UART0_BRG_L = $C0
DEFC UART0_FCTL = $C2
DEFC UART0_LCTL = $C3
DEFC UART0_LSR = $C5

; initialize the serial interface
.serial_init
	LD	HL, serial_init_sequence
	LD	B, #end_serial_init_sequence-serial_init_sequence
	JP	output_sequence
	;RET optimized away by JP above
.serial_init_sequence
	DEFB	PD_ALT2, $03 ; alternative pin function
	DEFB	UART0_LCTL, $80 ; access baud rate register
	DEFB	UART0_BRG_L, $41 ; baud rate: 9600
	DEFB	UART0_LCTL, $03 ; 8 data bits, no parity, 1 stop bit
	DEFB	UART0_FCTL, $06 ; enable transmitter and receiver
.end_serial_init_sequence

; transmit a byte via the serial interface
; A contains the byte to transmit
; trashes C register
.serial_transmit
	LD	C, UART0_LSR
.serial_transmit_wait_loop
	; check for THRE (bit 5 in UART0_LSR)
	; eZ80 instruction: TSTIO $20
	DEFB	$ED, $74, $20
	; '0' means UART transmit holding register not empty
	JR	Z, serial_transmit_wait_loop
	; eZ80 instruction: OUT0 (UART0_THR), A
	DEFB	$ED, $39, UART0_THR
	RET

; receive a byte via the serial interface
; returns byte in A, if any
; C flag is set if a byte was received, cleared otherwise
; trashes C register
.serial_receive
	LD	C, UART0_LSR
	; check for DR (bit 0 in UART0_LSR)
	; eZ80 instruction: TSTIO $01 (clears C flag)
	DEFB	$ED, $74, $01
	; '0' means no data
	RET	Z
	; eZ80 instruction: IN0 A, (UART0_RBR)
	DEFB	$ED, $38, UART0_RBR
	SCF
	RET
