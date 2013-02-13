; main - startup code

ORG $E000

XREF RAM_PIC

XREF keyboard_init

XREF video_init

XREF hexdigits_load
XREF linechars_load

XREF monitor

XDEF INTERRUPT_TABLE

; interrupt vector table address
; must be at 512 byte boundary
DEFC INTERRUPT_TABLE = $FE00

.main
	LD	A, INTERRUPT_TABLE/$100
	LD	I, A
	LD	SP, INTERRUPT_TABLE - 1

	CALL	keyboard_init
	CALL	video_init
	CALL	hexdigits_load
	CALL	linechars_load

	EI

	JP	monitor
