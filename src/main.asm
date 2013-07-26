; main - startup code

INCLUDE "main.inc"

ORG $E000

XREF serial_init
XREF keyboard_init
XREF video_init

XREF charmap_load
XREF icons_load
XREF cursor_init

XREF monitor

.main
	LD	A, INTERRUPT_TABLE/$100
	LD	I, A
	; stack below interrupt table
	LD	SP, INTERRUPT_TABLE

	CALL	serial_init
	CALL	keyboard_init
	CALL	video_init
	CALL	charmap_load
	CALL	icons_load
	CALL	cursor_init

	EI

	JP	monitor
