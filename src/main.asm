; main - startup code

INCLUDE "main.inc"

ORG $0000

XREF serial_init
XREF keyboard_init
XREF video_init

XREF hexdigits_load
XREF linechars_load
XREF symbolchars_load
XREF icons_load
XREF cursor_init

XREF monitor

.main
	; initialize internal RAM
	XOR	A, A
	; eZ80 instruction: OUT0 (RAM_ADDR_U), A
	DEFB	$ED, $39, $B5
	; clear memory
	LD	HL, $C000
.clear
	LD	(HL), 0
	INC	HL
	LD	A, H
	OR	A, L
	JR	NZ, clear

	; set up interrupt table
	LD	A, INTERRUPT_TABLE/$100
	LD	I, A
	; stack below interrupt table
	LD	SP, INTERRUPT_TABLE

	; wait for peripherals to get ready
	LD	B, 16
	LD	DE, 0
.wait
	DEC	DE
	LD	A, D
	OR	A, E
	JR	NZ, wait
	DJNZ	wait

	CALL	serial_init
	CALL	keyboard_init
	CALL	video_init
	CALL	hexdigits_load
	CALL	linechars_load
	CALL	symbolchars_load
	CALL	icons_load
	CALL	cursor_init

	EI

	JP	monitor
