INCLUDE	"zinu.inc"

XREF	_doprnt
XREF	devtab

XDEF	kprintf

; perform a synchronous character write to UART device
; IN:	char	A	character to write
;	device*	IY	pointer to UART device
.kputc
	PUSH	IY
	PUSH	DE
	PUSH	BC

	; get hardware CSR
	INCLUDE	"eZ80/LD_IY_IYdi.asm"
	DEFB	dentry_dvcsr

	; disable UART interrupts
	INCLUDE	"eZ80/LEA_BC_IYd.asm"
	DEFB	UART_IER
	IN	D, (C)
	LD	E, 0
	OUT	(C), E

	; wait for transmit hold register empty
.kputc_wait
	INCLUDE	"eZ80/LEA_BC_IYd.asm"
	DEFB	UART_LSR
	IN	E, (C)
	BIT	UART_LSR_THRE, E
	JR	Z, kputc_wait

	; send one character
	INCLUDE	"eZ80/LEA_BC_IYd.asm"
	DEFB	UART_THR
	OUT	(C), A

	; restore UART0 interrupts
	INCLUDE	"eZ80/LEA_BC_IYd.asm"
	DEFB	UART_IER
	OUT	(C), D

	POP	BC
	POP	DE
	POP	IY
	RET

; kernel printf: formatted, unbuffered output to UART0
; IN:	char*	HL	format string
;	TODO		format args
.kprintf
	PUSH	IX
	LD	IX, kputc
	LD	IY, devtab + SERIAL0*SIZEOF_dentry
	CALL	_doprnt
	POP	IX
	RET