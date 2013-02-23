; main - startup code

ORG $E000

XREF RAM_PIC

XREF keyboard_init

XREF video_init

XREF hexdigits_load
XREF linechars_load
XREF symbolchars_load

XREF cursor_init

XREF monitor

XDEF INTERRUPT_TABLE

; interrupt vector table address
; must be at 512 byte boundary
DEFC INTERRUPT_TABLE = $FE00

.main
	LD	A, INTERRUPT_TABLE/$100
	LD	I, A
	; stack below interrupt table
	LD	SP, INTERRUPT_TABLE

	CALL	keyboard_init
	CALL	video_init
	CALL	hexdigits_load
	CALL	linechars_load
	CALL	symbolchars_load
	CALL	cursor_init

	EI

	JP	monitor
