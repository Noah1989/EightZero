; eZ80 ASM file: main - startup code

INCLUDE "main.inc"

ORG $E000

XREF serial_init
XREF keyboard_init
XREF spi_init
XREF video_reset
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

	CALL	serial_init
	CALL	keyboard_init
	CALL	spi_init

	EI

	CALL	video_reset
	CALL	hexdigits_load
	CALL	linechars_load
	CALL	symbolchars_load
	CALL	icons_load
	CALL	cursor_init

	JP	monitor

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
