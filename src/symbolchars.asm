; smbolchars - symbol and arrow characters

INCLUDE "symbolchars.inc"
INCLUDE "video.inc"

XREF video_copy
XREF video_write_32

XDEF symbolchars_load

.symbolchars_load
	; load character data
	LD	DE, RAM_CHR + ($10*16)
	LD	HL, symbolchars_characters
	LD	BC, #end_symbolchars_characters-symbolchars_characters
	CALL	video_copy

	LD	IY, RAM_PAL + ($10*8)
	; 4 symbols
	LD	B, 4
.linechars_load_palette_loop
	; eZ80 instruction: LEA DE, IY + 0
	DEFB	$ED, $13, 0
	; next palette (we just set the first two colors, the others are not used)
	; eZ80 instruction: LEA IY, IY + 8
	DEFB	$ED, $33, 4*2
	; same colors for all symbols
	LD	HL, symbolchars_colors
	CALL	video_write_32
	DJNZ	linechars_load_palette_loop
	RET


.symbolchars_characters
; up arrow
	DEFB	@00000000, @00000000
	DEFB	@00000001, @01000000
	DEFB	@00000101, @01010000
	DEFB	@00010001, @01000100

	DEFB	@00000001, @01000000
	DEFB	@00000001, @01000000
	DEFB	@00000001, @01000000
	DEFB	@00000000, @00000000

; down arrow
	DEFB	@00000000, @00000000
	DEFB	@00000001, @01000000
	DEFB	@00000001, @01000000
	DEFB	@00000001, @01000000

	DEFB	@00010001, @01000100
	DEFB	@00000101, @01010000
	DEFB	@00000001, @01000000
	DEFB	@00000000, @00000000

; left  arrow
	DEFB	@00000000, @00000000
	DEFB	@00000001, @00000000
	DEFB	@00000100, @00000000
	DEFB	@00010101, @01010100

	DEFB	@00010101, @01010100
	DEFB	@00000100, @00000000
	DEFB	@00000001, @00000000
	DEFB	@00000000, @00000000

; right arrow
	DEFB	@00000000, @00000000
	DEFB	@00000000, @01000000
	DEFB	@00000000, @00010000
	DEFB	@00010101, @01010100

	DEFB	@00010101, @01010100
	DEFB	@00000000, @00010000
	DEFB	@00000000, @01000000
	DEFB	@00000000, @00000000
.end_symbolchars_characters

.symbolchars_colors
	DEFW	$8000 ; transparent
	DEFW	$7FFF ; full white
