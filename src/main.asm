; eZ80 ASM file: main - startup code

INCLUDE "main.inc"

ORG $D000

XREF serial_init
XREF keyboard_init
XREF spi_init
XREF video_reset
XREF charmap_load
XREF icons_load
XREF cursor_init
XREF monitor

.main
	DI

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

	; set up stack
	LD	SP, SYSTEM_STACK

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
	CALL	spi_init

	EI

	CALL	video_reset
	CALL	charmap_load
	CALL	icons_load
	CALL	cursor_init

	JP	monitor

;XREF output_sequence
;.debug
;	DI
;	LD	HL, debug_sequence
;	LD	B, #end_debug_sequence-debug_sequence
;	CALL	output_sequence
;.debug_loop
;	JR	debug_loop
;.debug_sequence
;	; drive LED on PORT A PIN 2, all others are inputs
;	DEFB	$99, @00000000
;	DEFB	$98, @00000000
;	DEFB	$97, @11111011
;	DEFB	$96, @00000100
;.end_debug_sequence
