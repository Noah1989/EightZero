; cursor - a cursor for the machine code monitor

XREF video_copy
XREF video_write_32
XREF video_start_write
XREF video_spi_transmit_A
XREF video_end_transfer

XREF PALETTE4A
XREF RAM_SPR
XREF RAM_SPRIMG

XREF COLOR_A
XREF COLOR_R
XREF COLOR_G
XREF COLOR_B

XDEF cursor_init
XDEF cursor_move

.cursor_default
	; X=20, Y=36, IMAGE=0, PAL=6, ROT=0, C=0
	DEFB	20, $E0, 36, $00

.cursor_init
	; load sprite image
	LD	HL, cursor_image
	LD	DE, RAM_SPRIMG
	LD	BC, #end_cursor_image-cursor_image
	CALL	video_copy
	; load colors (4-color palette A)
	LD	HL, cursor_colors
	LD	DE, PALETTE4A
	LD	BC, #end_cursor_colors-cursor_colors
	CALL	video_copy
	LD	BC, 0
	; fall through to move cursor to origin

; move the cursor to byte in listing
; B contains x location ($00..$0F)
; C contains y location ($00..$1F)
.cursor_move
	LD	DE, RAM_SPR
	CALL	video_start_write
	; DE = B*8*3 (relative x in pixels)
	LD	D, 8*3
	LD	E, B
	; eZ80 instruction: MLT DE
	DEFB	$ED, $5C
	LD	HL, cursor_default
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
	; RET optimized away by JP above

.cursor_image
	; cursor in 4 different sizes
	DEFB	$00, $02, $02, $02, $02, $01, $01, $00
	DEFB	$00, $01, $01, $02, $02, $02, $02, $00
	DEFB	$02, $0B, $0B, $0B, $09, $05, $04, $00
	DEFB	$00, $04, $05, $09, $0B, $0B, $0B, $02
	DEFB	$0B, $2C, $2C, $2C, $24, $14, $10, $00
	DEFB	$00, $10, $14, $24, $2C, $2C, $2C, $0B
	DEFB	$2F, $B0, $B0, $B0, $90, $50, $40, $00
	DEFB	$00, $40, $50, $90, $B0, $B0, $B0, $2F
	DEFB	$BF, $C0, $C0, $C0, $40, $40, $00, $00
	DEFB	$00, $00, $40, $40, $C0, $C0, $C0, $BF
	DEFB	$FF, $00, $00, $00, $00, $00, $00, $00
	DEFB	$00, $00, $00, $00, $00, $00, $00, $FF
	DEFB	$FF, $00, $00, $00, $00, $00, $00, $00
	DEFB	$00, $00, $00, $00, $00, $00, $00, $FF
	DEFB	$FF, $00, $00, $00, $00, $00, $00, $00
	DEFB	$00, $00, $00, $00, $00, $00, $00, $FF
	DEFB	$FF, $00, $00, $00, $00, $00, $00, $00
	DEFB	$00, $00, $00, $00, $00, $00, $00, $FF
	DEFB	$FF, $00, $00, $00, $00, $00, $00, $00
	DEFB	$00, $00, $00, $00, $00, $00, $00, $FF
	DEFB	$FF, $00, $00, $00, $00, $00, $00, $00
	DEFB	$00, $00, $00, $00, $00, $00, $00, $FF
	DEFB	$BF, $C0, $C0, $C0, $40, $40, $00, $00
	DEFB	$00, $00, $40, $40, $C0, $C0, $C0, $BF
	DEFB	$2F, $B0, $B0, $B0, $90, $50, $40, $00
	DEFB	$00, $40, $50, $90, $B0, $B0, $B0, $2F
	DEFB	$0B, $2C, $2C, $2C, $24, $14, $10, $00
	DEFB	$00, $10, $14, $24, $2C, $2C, $2C, $0B
	DEFB	$02, $0B, $0B, $0B, $09, $05, $04, $00
	DEFB	$00, $04, $05, $09, $0B, $0B, $0B, $02
	DEFB	$00, $02, $02, $02, $02, $01, $01, $00
	DEFB	$00, $01, $01, $02, $02, $02, $02, $00
.end_cursor_image

.cursor_colors
	DEFW	COLOR_A
	DEFW	@01100 * COLOR_G + @10100 * COLOR_R
	DEFW	@10000 * COLOR_G + @11000 * COLOR_R
	DEFW	@10100 * COLOR_G + @11100 * COLOR_R
.end_cursor_colors
