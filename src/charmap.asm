; eZ80 ASM file: charmap - a character map loader

INCLUDE "charmap.inc"
INCLUDE "video.inc"

XREF video_copy
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
	LD	C, 0

.charmap_data
	BINARY "charmap.bin"