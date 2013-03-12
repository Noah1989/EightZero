; sprite - functions for sprite manipulation

INCLUDE "sprite.inc"

XREF video_start_write
XREF video_spi_transmit_A
XREF video_end_transfer

XDEF sprite_move

	; move sprite to character location relative to default position
	; B contains x location in characters (8 pixels)
	; C contains y location in characters (8 pixels)
	; DE points to absolute RAM_SPR address for sprite
	; HL points to sprite default configuration (4 bytes)
.sprite_move
	CALL	video_start_write
	; DE = B*8 (relative x in pixels)
	LD	D, 8
	LD	E, B
	; eZ80 instruction: MLT DE
	DEFB	$ED, $5C
	LD	A, (HL)
	ADD	A, E
	CALL	video_spi_transmit_A
	INC	HL
	LD	A, (HL)
	ADC	A, D
	CALL	video_spi_transmit_A
	; DE = C*8 (relative y in pixels)
	LD	D, 8
	LD	E, C
	; eZ80 instruction: MLT DE
	DEFB	$ED, $5C
	INC	HL
	LD	A, (HL)
	ADD	A, E
	CALL	video_spi_transmit_A
	INC	HL
	LD	A, (HL)
	ADC	A, D
	CALL	video_spi_transmit_A
	JP	video_end_transfer
