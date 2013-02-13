; monitor - a machine code monitor program

XREF video_start_write
XREF video_spi_transmit_A
XREF video_end_transfer
XREF video_write_C

XREF keyboard_getchar

XREF RAM_PIC

XREF K_PGD
XREF K_PGU

XDEF monitor

; top-left screen coordinates of the main hex listing
DEFC ORIGIN_X = 2
DEFC ORIGIN_Y = 4

; screen coordinates of the address indicator
DEFC ADDRESS_X = 0
DEFC ADDRESS_y = 2

DEFC LISTING_CHAR_OFFSET = $F0 ; <- white hex digits
DEFC ADDRESS_CHAR_OFFSET = $B0 ; <- cyan hex digits
DEFC SPACE_CHARACTER = $08 ; <- black square

; default listing start address
DEFC LISTING_START = $E000

.monitor
	LD	HL, LISTING_START

	; main display loop
.monitor_main_loop
	; address indicator
	LD	DE, RAM_PIC + ADDRESS_X + ADDRESS_y*64
	CALL	video_start_write
	; high nibble
	LD	A, H
	RRA
	RRA
	RRA
	RRA
	AND	A, $0F
	OR	A, ADDRESS_CHAR_OFFSET
	CALL	video_spi_transmit_A
	; low nibble
	LD	A, H
	AND	A, $0F
	OR	A, ADDRESS_CHAR_OFFSET
	CALL	video_spi_transmit_A
	CALL	video_end_transfer

	; main display loop without address indicator
.monitor_main_loop_listing
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
	OR	A, LISTING_CHAR_OFFSET
	CALL	video_spi_transmit_A
	; low nibble
	LD	A, (HL)
	AND	A, $0F
	OR	A, LISTING_CHAR_OFFSET
	CALL	video_spi_transmit_A
	INC	HL
	DJNZ	monitor_line_loop
	CALL	video_end_transfer
	DEC	C
	JR	NZ, monitor_outer_loop
	; page up/down
	; note that H has been incremented by 2 because we printed 512 bytes
	DEC	H
	CALL	keyboard_getchar
	; page down
	LD	A, K_PGD
	CP	A, C
	; page down pressed, effective increment: 1
	JR	Z, monitor_main_loop
	DEC	H
	; page up
	LD	A, K_PGU
	CP	A, C
	; page up _not_ pressed, no effective change
	JR	NZ, monitor_main_loop_listing
	; page up pressed, effective decrement: 1
	DEC	H
	JR	monitor_main_loop
