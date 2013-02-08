; main - startup code

ORG $E000

XREF video_init
XREF video_copy

XREF keyboard_init

XREF KEYBOARD_ISR_DATA

XDEF INTERRUPT_TABLE

; interrupt vector table address
; must be at 512 byte boundary
DEFC INTERRUPT_TABLE = $FE00

.main
	LD	A, INTERRUPT_TABLE/$100
	LD	I, A
	LD	SP, INTERRUPT_TABLE - 1

	CALL	video_init
	CALL	keyboard_init

	LD	HL, hello_string
	LD	BC, #end_hello_string-hello_string
	LD	DE, 3 + 64*3
	CALL	video_copy

	EI

	; just a test: copy raw keyboard data to video RAM
	; enjoy random characters when pressing some keys :)
.loop
	LD	HL, INTERRUPT_TABLE + KEYBOARD_ISR_DATA
	LD	BC, 2
	LD	DE, 3 + 64*5
	CALL	video_copy
	JR	loop

.hello_string
	DEFM	"Hello, world!"
.end_hello_string
