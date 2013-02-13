; monitor - a machine code monitor program

XREF video_start_write
XREF video_spi_transmit_A
XREF video_end_transfer

XREF RAM_PIC

XDEF monitor

; top-left screen coordinates of the main hex listing
DEFC ORIGIN_X = 2
DEFC ORIGIN_Y = 4

DEFC HEX_CHAR_OFFSET = $F0 ; <- white hex digits
DEFC SPACE_CHARACTER = $08 ; <- black square

; default listing start address
DEFC LISTING_START = $E000

.monitor
	LD	HL, LISTING_START
	LD	IY, RAM_PIC + ORIGIN_X + ORIGIN_Y*64
	; write 32 lines
	LD	C, 32
.monitor_outer_loop
	; eZ80 instruction: LEA DE, IY + 0
	DEFB	$ED, $13, 0
	; next line
	; eZ80 instruction: LEA IY, IY + 64
	DEFB	$ED, $33, 64
	LD	B, 16
	CALL	video_start_write
	JR	monitor_line_loop_start
.monitor_line_loop
	; space
	LD	A, SPACE_CHARACTER
	CALL	video_spi_transmit_A
.monitor_line_loop_start
	; high nibble
	LD	A, (HL)
	RRA
	RRA
	RRA
	RRA
	AND	A, $0F
	OR	A, HEX_CHAR_OFFSET
	CALL	video_spi_transmit_A
	; low nibble
	LD	A, (HL)
	AND	A, $0F
	OR	A, HEX_CHAR_OFFSET
	CALL	video_spi_transmit_A
	INC	HL
	DJNZ	monitor_line_loop
	CALL	video_end_transfer
	DEC	C
	JR	NZ, monitor_outer_loop
	JR	monitor
