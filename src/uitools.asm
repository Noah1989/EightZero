; uitools - user interface tools

XREF video_start_write
XREF video_spi_transmit
XREF video_end_transfer

XDEF draw_box

; draw a fancy box with border and shadow
; B = inner width, C = inner height, D = top, E = left
; HL points to fill character,
;    followed by border character,
;    followed by shadow character
.draw_box

	; calculate RAM_PIC position into IY
	; top*64 (lower byte)
	LD	A, D
	SLA	A
	SLA	A
	SLA	A
	SLA	A
	SLA	A
	SLA	A
	; top*64 (upper byte)
	SRL	D
	SRL	D
	; top*64 + left (lower byte)
	ADD	A, E
	LD	IYL, A
	; top*64 + left (upper byte)
	LD	A, D
	ADC	A, 0
	LD	IYH, A

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
