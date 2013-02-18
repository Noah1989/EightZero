; linechars - line drawing and other misc. characters

XREF video_fill
XREF video_write_16

XREF RAM_CHR
XREF RAM_PAL

XREF COLOR_A
XREF COLOR_R
XREF COLOR_G
XREF COLOR_B

XDEF linechars_load

DEFC SQUARE_SHADE_1 = @10000
DEFC SQUARE_SHADE_2 = @11000
DEFC SQUARE_SHADE_3 = @11100

.linechars_load
	; 16 blank square characters
	LD	HL, zerobyte
	LD	DE, RAM_CHR
	; 16 bytes per character
	LD	BC, 16*16
	CALL	video_fill
	; palette data
	LD	HL, square_colors
	LD	IY, RAM_PAL
	LD	B, 16
.linechars_load_palette_loop
	; eZ80 instruction: LEA DE, IY + 0
	DEFB	$ED, $13, 0
	; next palette (we just set the first color, the others are not used)
	; eZ80 instruction: LEA IY, IY + 8
	DEFB	$ED, $33, 4*2
	CALL	video_write_16
	INC	HL
	DJNZ	linechars_load_palette_loop
	RET

.square_colors
; black
	DEFW	SQUARE_SHADE_1 * (0*COLOR_R + 0*COLOR_G + 0*COLOR_B)
; blue
	DEFW	SQUARE_SHADE_1 * (0*COLOR_R + 0*COLOR_G + 1*COLOR_B)
; green
	DEFW	SQUARE_SHADE_1 * (0*COLOR_R + 1*COLOR_G + 0*COLOR_B)
; cyan
	DEFW	SQUARE_SHADE_1 * (0*COLOR_R + 1*COLOR_G + 1*COLOR_B)
; red
	DEFW	SQUARE_SHADE_1 * (1*COLOR_R + 0*COLOR_G + 0*COLOR_B)
; purple
	DEFW	SQUARE_SHADE_1 * (1*COLOR_R + 0*COLOR_G + 1*COLOR_B)
; yellow
	DEFW	SQUARE_SHADE_1 * (1*COLOR_R + 1*COLOR_G + 0*COLOR_B)
; white
	DEFW	SQUARE_SHADE_2 * (1*COLOR_R + 1*COLOR_G + 1*COLOR_B)
; gray
	DEFW	SQUARE_SHADE_1 * (1*COLOR_R + 1*COLOR_G + 1*COLOR_B)
; light blue
	DEFW	SQUARE_SHADE_3 * (0*COLOR_R + 0*COLOR_G + 1*COLOR_B)
; light green
	DEFW	SQUARE_SHADE_3 * (0*COLOR_R + 1*COLOR_G + 0*COLOR_B)
; light cyan
	DEFW	SQUARE_SHADE_3 * (0*COLOR_R + 1*COLOR_G + 1*COLOR_B)
; light red
	DEFW	SQUARE_SHADE_3 * (1*COLOR_R + 0*COLOR_G + 0*COLOR_B)
; light purple
	DEFW	SQUARE_SHADE_3 * (1*COLOR_R + 0*COLOR_G + 1*COLOR_B)
; light yellow
	DEFW	SQUARE_SHADE_3 * (1*COLOR_R + 1*COLOR_G + 0*COLOR_B)
; bright white
	DEFW	SQUARE_SHADE_3 * (1*COLOR_R + 1*COLOR_G + 1*COLOR_B)

.zerobyte
	DEFB	0
