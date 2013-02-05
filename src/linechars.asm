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

DEFC SQUARE_SHADE = @10000

.linechars_load
	; 8 blank square characters
	LD	HL, zerobyte
	LD	DE, RAM_CHR + $08*16
	; 16 bytes per character
	LD	BC, 8 * 16
	CALL	video_fill
	; palette data
	LD	HL, square_colors
	LD	IY, RAM_PAL + $08*8
	LD	B, 8
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
; black  (000)
	DEFW	SQUARE_SHADE * (0*COLOR_R + 0*COLOR_G + 0*COLOR_B)
; blue   (001)
	DEFW	SQUARE_SHADE * (0*COLOR_R + 0*COLOR_G + 1*COLOR_B)
; green  (010)
	DEFW	SQUARE_SHADE * (0*COLOR_R + 1*COLOR_G + 0*COLOR_B)
; cyan   (011)
	DEFW	SQUARE_SHADE * (0*COLOR_R + 1*COLOR_G + 1*COLOR_B)
; red    (100)
	DEFW	SQUARE_SHADE * (1*COLOR_R + 0*COLOR_G + 0*COLOR_B)
; purple (101)
	DEFW	SQUARE_SHADE * (1*COLOR_R + 0*COLOR_G + 1*COLOR_B)
; yellow (110)
	DEFW	SQUARE_SHADE * (1*COLOR_R + 1*COLOR_G + 0*COLOR_B)
; white  (111)
	DEFW	SQUARE_SHADE * (1*COLOR_R + 1*COLOR_G + 1*COLOR_B)

.zerobyte
	DEFB	0
