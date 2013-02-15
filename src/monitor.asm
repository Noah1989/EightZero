; monitor - a machine code monitor program

XREF video_fill
XREF video_copy
XREF video_start_write
XREF video_spi_transmit
XREF video_spi_transmit_A
XREF video_end_transfer
XREF video_write
XREF video_write_C

XREF keyboard_getchar

XREF SCROLL_X

XREF RAM_PIC

XREF K_PGD
XREF K_PGU

XDEF monitor

; top-left screen coordinates of the main hex listing
DEFC ORIGIN_X = 3
DEFC ORIGIN_Y = 5

; screen coordinates of the address indicator
DEFC ADDRESS_X = 1
DEFC ADDRESS_Y = 3

; screen coordinate of the menu
DEFC MENU_X = 1
DEFC MENU_Y = 0

DEFC LISTING_CHAR_OFFSET = $F0 ; <- white hex digits
DEFC ADDRESS_CHAR_OFFSET = $B0 ; <- cyan hex digits
DEFC SPACE_CHARACTER = $08 ; <- black square

; default listing start address
DEFC LISTING_START = $E000

.border_character
	DEFB	$0F ; <- gray square

.menu_string
	DEFM	"F1:Help  F2:GoTo  F3:Load  F4:Copy  F5:Call"
.end_menu_string

.monitor
	; scroll 4px to the left
	LD	C, 4
	LD	DE, SCROLL_X
	CALL	video_write_C
	; print menu
	LD	HL, menu_string
	LD	DE, MENU_X + MENU_Y*64
	LD	BC, #end_menu_string-menu_string
	CALL	video_copy
	; draw some borders and static labels
	LD	HL, border_character
	; horizontal borders
	LD	DE, [ADDRESS_Y - 1]*64
	LD	BC, 51
	CALL	video_fill
	LD	DE, [ADDRESS_Y + 1]*64
	LD	BC, 51
	CALL	video_fill
	LD	DE, [ORIGIN_Y + 32]*64
	LD	BC, 51
	CALL	video_fill
	; small border left of address
	LD	DE, ADDRESS_X - 1 + ADDRESS_Y*64
	CALL	video_write
	; top border address labels
	LD	DE, ORIGIN_X + ADDRESS_Y*64
	CALL	video_start_write
	CALL	video_spi_transmit
	LD	B, 16
	JR	monitor_top_address_labels_loop_start
.monitor_top_address_labels_loop
	LD	A, SPACE_CHARACTER
	CALL	video_spi_transmit_A
	CALL	video_spi_transmit_A
.monitor_top_address_labels_loop_start
	LD	A, ADDRESS_CHAR_OFFSET + 16
	SUB	A, B
	CALL	video_spi_transmit_A
	DJNZ	monitor_top_address_labels_loop
	CALL	video_spi_transmit
	CALL	video_end_transfer
	; left border address labels
	LD	IY, ORIGIN_X - 3 + ORIGIN_Y*64
	LD	B, 32
.monitor_left_address_labels_loop
	; eZ80 instruction: LEA DE, IY + 0
	DEFB	$ED, $13, 0
	; next line
	; eZ80 instruction: LEA IY, IY + 64
	DEFB	$ED, $33, 64
	CALL	video_start_write
	CALL	video_spi_transmit
	LD	A, B
	NEG	A
	OR	A, $F0
	ADD	A, ADDRESS_CHAR_OFFSET + 16
	CALL	video_spi_transmit_A
	CALL	video_spi_transmit
	CALL	video_end_transfer
	DJNZ	monitor_left_address_labels_loop
	; right vertical border
	LD	IY, ORIGIN_X + 47 + ORIGIN_Y*64
	LD	B, 32
.monitor_right_border_loop
	; eZ80 instruction: LEA DE, IY + 0
	DEFB	$ED, $13, 0
	; next line
	; eZ80 instruction: LEA IY, IY + 64
	DEFB	$ED, $33, 64
	CALL	video_write
	DJNZ	monitor_right_border_loop

	; reset HL to RAM start
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
