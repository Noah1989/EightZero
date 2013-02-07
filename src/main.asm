; main - startup code

ORG $E000

XREF video_init
XREF video_copy

XREF keyboard_init

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

.loop
	JR	loop

.hello_string
	DEFM	"Hello, world!"
.end_hello_string
