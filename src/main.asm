; main - startup code

INCLUDE "main.inc"

ORG $E000

XREF keyboard_init

XREF video_init

XREF hexdigits_load
XREF linechars_load
XREF symbolchars_load
XREF icons_load
XREF cursor_init

XREF monitor

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
	CALL	icons_load
	CALL	cursor_init

	EI

	JP	monitor
