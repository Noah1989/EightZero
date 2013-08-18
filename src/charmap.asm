; eZ80 ASM file: charmap - a character map loader

INCLUDE "charmap.inc"
INCLUDE "video.inc"

XREF video_copy
XREF video_write_16
XREF video_start_write
XREF spi_transmit
XREF spi_deselect

XDEF charmap_load

.charmap_load
	LD	HL, charmap_data
	LD	DE, RAM_CHR
	LD	BC, 256 * 16
	CALL	video_copy
	LD	DE, RAM_PAL
	CALL	video_start_write
.charmap_load_palette_loop
	; get number of characters
	; with the same palette
	LD	C, (HL)
	INC	HL
.charmap_load_palette_repeat
	; copy palette (4 words)
	LD	B, 4*2
.charmap_load_palette_copy
	CALL	spi_transmit
	INC	HL
	DJNZ	charmap_load_palette_copy
	; set back HL
	LD	DE, -4*2
	ADD	HL, DE
	DEC	C
	JR	NZ, charmap_load_palette_repeat
	; set HL to next entry
	LD	DE, 4*2
	ADD	HL, DE
	; check for end marker
	LD	A, (HL)
	AND	A, A
	JR	NZ, charmap_load_palette_loop
	CALL	spi_deselect
	; background color
	INC	HL
	LD	DE, BG_COLOR
	JP	video_write_16
	; RET optimized away by JP above

.charmap_data
;	BINARY "charmap.bin"
