; uitools - user interface tools

INCLUDE "uitools.inc"

XREF video_start_write
XREF video_spi_transmit
XREF video_spi_transmit_A
XREF video_end_transfer

XDEF dialog_style
XDEF draw_box
XDEF print_string
XDEF print_uint16

	; default dialog style
.dialog_style
.dialog_fill_character
	DEFB	' '
.dialog_border_character
	DEFB	$07 ; <- white square
.dialog_shadow_character
	DEFB	$00 ; <- black square

	; draw a fancy box with border and shadow
	; B = inner width, C = inner height
	; IY contains screen RAM address
	; HL points to fill character,
	;    followed by border character,
	;    followed by shadow character
.draw_box
	;upper border
	INC	HL
	; eZ80 instruction: LEA DE, IY - 65
	DEFB	$ED, $13, -65
	CALL	video_start_write
	; save B (DE is not needed anymore)
	LD	D, B
	; add 2 to B to calculate full width
	INC	B
	INC	B
.draw_box_upper_border_loop
	CALL	video_spi_transmit
	DJNZ	draw_box_upper_border_loop
	CALL	video_end_transfer
	; restore B
	LD	B, D

	; body
.draw_box_body_line_loop
	; eZ80 instruction: LEA DE, IY - 1
	DEFB	$ED, $13, -1
	; eZ80 instruction: LEA IY, IY + 64
	DEFB	$ED, $33, 64
	CALL	video_start_write
	; save B (DE is not needed anymore)
	LD	D, B
	; left border
	CALL	video_spi_transmit
	; inner fill
	DEC	HL
.draw_box_body_inner_loop
	CALL	video_spi_transmit
	DJNZ	draw_box_body_inner_loop
	; restore B
	LD	B, D
	INC	HL
	; right border and shadow
	CALL	video_spi_transmit
	INC	HL
	CALL	video_spi_transmit
	DEC	HL
	CALL	video_end_transfer
	DEC	C
	JR	NZ, draw_box_body_line_loop

	; bottom border and shadow
	; eZ80 instruction: LEA DE, IY - 1
	DEFB	$ED, $13, -1
	CALL	video_start_write
	; save B (DE is not needed anymore)
	LD	D, B
	; add 2 to B to calculate full width
	INC	B
	INC	B
.draw_box_bottom_border_loop
	CALL	video_spi_transmit
	DJNZ	draw_box_bottom_border_loop
	; shadow
	INC	HL
	CALL	video_spi_transmit
	CALL	video_end_transfer
	; restore B
	LD	B, D
	; bottom shadow
	; eZ80 instruction: LEA DE, IY + 64
	DEFB	$ED, $13, 64
	CALL	video_start_write
	INC	B
	INC	B
.draw_box_bottom_shadow_loop
	CALL	video_spi_transmit
	DJNZ	draw_box_bottom_shadow_loop
	JP	video_end_transfer
	;RET optimized away by JP above

.print_string_newline
	CALL	video_end_transfer
	; eZ80 instruction: LEA IY, IY + 64
	DEFB	$ED, $33, 64
	; print a null-terminated string on screen, handling newlines
	; IY contains screen RAM address
	; HL points to string
.print_string
	; eZ80 instruction: LEA DE, IY
	DEFB	$ED, $13, 0
	CALL	video_start_write
.print_string_loop
	LD	A, (HL)
	INC	HL
	; check for terminator
	OR	A, A
	; jump instead of call because we want to return after that
	JP	Z, video_end_transfer
	CP	A, 10 ; <- line feed
	JR	Z, print_string_newline
	CALL	video_spi_transmit_A
	JR	print_string_loop

.print_uint16
	CALL	video_start_write
	LD	BC, -10000
	CALL	print_uint16_digit
	LD	BC, -1000
	CALL	print_uint16_digit
	LD	BC, -100 ; sets B to $FF
	CALL	print_uint16_digit
	LD	C, -10 ; no need to change B
	CALL	print_uint16_digit
	LD	C, B ; BC becomes $FFFF (-1)
	CALL	print_uint16_digit
	JP	video_end_transfer
	;RET optimized away by JP above
.print_uint16_digit
	LD	A, '0' - 1
.print_uint16_digit_loop
	INC	A
	ADD	HL, BC
	JR	C, print_uint16_digit_loop
	SBC	HL, BC
	JP	video_spi_transmit_A
	;RET optimized away by JP above
