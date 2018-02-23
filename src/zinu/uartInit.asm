INCLUDE	"zinu.inc"

XDEF	uartInit

; Initialize UART
; IN:	device*	IY	pointer to UART device

.uartInit

	PUSH	IY
	PUSH	BC

	; TODO: examine device minor number to select pin
	LD	BC, $00A5 ; PD_ALT2
	LD	A, $03    ; alternative pin function
	OUT	(C), A

	; get hardware CSR
	INCLUDE	"eZ80/LD_IY_IYdi.asm"
	DEFB	dentry_dvcsr

	INCLUDE	"eZ80/LEA_BC_IYd.asm"
	DEFB	UART_LCTL
	LD	A, $80 ; access baud rate register
	OUT	(C), A

	INCLUDE	"eZ80/LEA_BC_IYd.asm"
	DEFB	UART_BRG_L
	LD	A, $1A ; baud rate: 9600
	OUT	(C), A

	INCLUDE	"eZ80/LEA_BC_IYd.asm"
	DEFB	UART_LCTL
	LD	A, $03 ; 8 data bits, no parity, 1 stop bit
	OUT	(C), A

	INCLUDE	"eZ80/LEA_BC_IYd.asm"
	DEFB	UART_FCTL
	LD	A, $06 ; enable transmitter and receiver
	OUT	(C), A

	POP	BC
	POP	IY

	LD	A, OK
	RET