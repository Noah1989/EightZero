; eZ80 ASM file: uitools - user interface tools

INCLUDE "uitools.inc"

XREF video_start_write
XREF spi_transmit
XREF spi_transmit_A
XREF spi_deselect

XDEF draw_box
XDEF print_string
XDEF print_uint16
XDEF print_uint8
XDEF print_sint8
XDEF print_hex_byte
XDEF put_hex

	; draw a fancy box with border and shadow
	; B = inner width, C = inner height
	; IY contains screen RAM address
	;    of inner top left corner
.draw_box
	; eZ80 instruction: LEA DE, IY - 65
	DEFB	$ED, $13, -65
	CALL	video_start_write
	; save B (DE is not needed anymore)
	LD	D, B
	LD	A, $C9
	CALL	spi_transmit_A
	LD	A, $CD
.draw_box_upper_border_loop
	CALL	spi_transmit_A
	DJNZ	draw_box_upper_border_loop
	LD	A, $BB
	CALL	spi_transmit_A
	CALL	spi_deselect
	; restore B
	LD	B, D

	; body
	LD	HL, $C7BF
.draw_box_body_line_loop
	; eZ80 instruction: LEA DE, IY - 1
	DEFB	$ED, $13, -1
	; eZ80 instruction: LEA IY, IY + 64
	DEFB	$ED, $33, 64
	CALL	video_start_write
	; save B (DE is not needed anymore)
	LD	D, B
	; left border
	LD	A, $BA
	CALL	spi_transmit_A
	; inner fill
	LD	A, ' '
.draw_box_body_inner_loop
	CALL	spi_transmit_A
	DJNZ	draw_box_body_inner_loop
	; restore B
	LD	B, D
	; right border and shadow
	LD	A, H
	CALL	spi_transmit_A
	LD	A, L
	CALL	spi_transmit_A
	LD	HL, $BAB3
	CALL	spi_deselect
	DEC	C
	JR	NZ, draw_box_body_line_loop

	; bottom border and shadow
	; eZ80 instruction: LEA DE, IY - 1
	DEFB	$ED, $13, -1
	CALL	video_start_write
	; save B (DE is not needed anymore)
	LD	D, B
	LD	A, $C8
	CALL	spi_transmit_A
	LD	A, $D1
	CALL	spi_transmit_A
	DEC	B
	LD	A, $CD
.draw_box_bottom_border_loop
	CALL	spi_transmit_A
	DJNZ	draw_box_bottom_border_loop
	LD	A, $BC
	CALL	spi_transmit_A
	; shadow
	LD	A, $B3
	CALL	spi_transmit_A
	CALL	spi_deselect
	; restore B
	LD	B, D
	; bottom shadow
	; eZ80 instruction: LEA DE, IY + 64
	DEFB	$ED, $13, 64
	CALL	video_start_write
	LD	A, $C0
	CALL	spi_transmit_A
	LD	A, $C4
.draw_box_bottom_shadow_loop
	CALL	spi_transmit_A
	DJNZ	draw_box_bottom_shadow_loop
	LD	A, $D9
	CALL	spi_transmit_A
	JP	spi_deselect
	;RET optimized away by JP above

.print_string_newline
	CALL	spi_deselect
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
	JP	Z, spi_deselect
	CP	A, 10 ; <- line feed
	JR	Z, print_string_newline
	CALL	spi_transmit_A
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
	JP	spi_deselect
	;RET optimized away by JP above
.print_uint16_digit
	LD	A, '0' - 1
.print_uint16_digit_loop
	INC	A
	ADD	HL, BC
	JR	C, print_uint16_digit_loop
	SBC	HL, BC
	JP	spi_transmit_A
	;RET optimized away by JP above

; print 8 bit integer (signed)
.print_sint8
	CALL	video_start_write
	BIT	7, C
	JR	Z, print_sint8_positive
.print_sint8_negative
	LD	A, C
	NEG	A
	LD	C, A
	LD	A, '-'
	JR	print_sint8_common
.print_sint8_positive
	LD	A, '+'
.print_sint8_common
	CALL	spi_transmit_A
	JR	print_int8_common
; print 8 bit integer (unsigned)
.print_uint8
	CALL	video_start_write
.print_int8_common
	LD	B, 100
	CALL	print_uint8_digit
	LD	B, 10
	CALL	print_uint8_digit
	LD	B, 1
	CALL	print_uint8_digit
	JP	spi_deselect
	;RET optimized away by JP above
.print_uint8_digit
	LD	A, C
	LD	C, '0' - 1
.print_uint8_digit_loop
	INC	C
	SUB	A, B
	JR	NC, print_uint8_digit_loop
	ADD	A, B
	; swap A and C (trashes B)
	LD	B, A
	LD	A, C
	LD	C, B
	JP	spi_transmit_A
	;RET optimized away by JP above

.print_hex_byte
        CALL	video_start_write
        ; high nibble
        LD	A, (HL)
        RRA
        RRA
        RRA
        RRA
        CALL	put_hex
        ; low nibble
        LD	A, (HL)
        CALL	put_hex
        JP	spi_deselect
        ;RET optimized away by JP above

.put_hex
        OR      A, $F0
        DAA
        ADD     A, $A0
        ADC     A, $40
        JP      spi_transmit_A
        ;RET optimized away by JP above

