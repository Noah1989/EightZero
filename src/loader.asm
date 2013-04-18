; loader - load data into ram from the serial interface

INCLUDE "loader.inc"
INCLUDE "keyboard.inc"

XREF keyboard_getchar
XREF serial_transmit
XREF serial_receive

XREF dialog_style
XREF draw_box
XREF print_string
XREF icon_show
XREF icon_hide

XREF video_start_write
XREF video_spi_transmit_A
XREF video_end_transfer
XREF video_write
XREF video_fill

XREF div_16_8

XDEF loader_open

DEFC LOADER_WIDTH = 31
DEFC LOADER_HEIGHT = 13
DEFC LOADER_TOP = 12
DEFC LOADER_LEFT = 10

DEFC ADDRESS_CHAR_OFFSET = $B0 ; cyan hex chars

.loader_help_string
	DEFM	"Load data into memory", 10
	DEFM	"from the serial interface.", 10, 10
	DEFM	"Target address: ", 10, 10, 10, 10
	DEFM	"Waiting for data...", 10, 10, 10
	DEFM	"Press ESC to cancel.", 0

.loader_done_string
	DEFM	"Data transfer complete.", 10, 10, 10
	DEFM	"Press ESC to close. ", 0

.progress_chars
	DEFB	0 ; black square
	DEFB	2 ; green square

	; opens the loader screen
.loader_open
	; box
	LD	BC, LOADER_WIDTH*256 + LOADER_HEIGHT
	LD	IY, LOADER_TOP*64 + LOADER_LEFT
	LD	HL, dialog_style
	CALL	draw_box
	; icon
	LD	BC, [LOADER_LEFT + 1]*256 + [LOADER_TOP + 1]
	LD	A, 1 ; icon 1
	CALL	icon_show
	; text
	LD	HL, loader_help_string
	LD	IY, [LOADER_TOP + 1]*64 + [LOADER_LEFT + 4]
	CALL	print_string
	; progress bar (location in IY is for later updates)
	LD	HL, progress_chars
	LD	DE, [LOADER_TOP + 6]*64 + [LOADER_LEFT + 4]
	LD	IY, [LOADER_TOP + 6]*64 + [LOADER_LEFT + 4]
	LD	BC, LOADER_WIDTH - 5
	CALL	video_fill
	; target address
	LD	DE, [LOADER_TOP + 4]*64 + [LOADER_LEFT + 20]
	CALL	video_start_write
	LD	B, IXH
	CALL	loader_print_byte
	LD	B, IXL
	CALL	loader_print_byte
	CALL	video_end_transfer
	JR	loader_wait_data_start
.loader_print_byte
	LD	A, B
	RRA
	RRA
	RRA
	RRA
	AND	A, $0F
	OR	A, ADDRESS_CHAR_OFFSET
	CALL	video_spi_transmit_A
	; low nibble
	LD	A, B
	AND	A, $0F
	OR	A, ADDRESS_CHAR_OFFSET
	JP	video_spi_transmit_A
	; RET optimized away by JP above

.loader_wait_data_start
	; wait for '!', respond with '?'
	CALL	loader_input_loop
	RET	NC ; cancelled by user
	CP	A, '!'
	JR	NZ, loader_wait_data_start
	LD	A, '?'
	CALL	serial_transmit

	; get number of bytes to receive into DE
	; (unsigned 16 bit int, little endian)
	CALL	loader_input_loop
	RET	NC ; cancelled by user
	LD	E, A ; low byte
	CALL	loader_input_loop
	RET	NC ; cancelled by user
	LD	D, A ; high byte

	; calculate bytes per progress bar step into HL
	; BC is used as a counter towards the next step
	LD	H, D
	LD	L, E
	LD	C, LOADER_WIDTH - 5
	CALL	div_16_8
	LD	B, H
	LD	C, L

	; ready to receive data
	LD	A, '!'
	CALL	serial_transmit


.loader_transfer_loop
	PUSH	BC
	CALL	loader_input_loop
	POP	BC
	RET	NC ; cancelled by user
	LD	(IX), A
	INC	IX
	; count down bytes to next progress step
	DEC	BC
	LD	A, B
	OR	A, C
	CALL	Z, loader_transfer_progress
	; loop until all bytes are received
	DEC	DE
	LD	A, D
	OR	A, E
	JR	NZ, loader_transfer_loop

	; fill progress bar and print done message
	LD	HL, progress_chars + 1
	LD	DE, [LOADER_TOP + 6]*64 + [LOADER_LEFT + 4]
	LD	BC, LOADER_WIDTH - 5
	CALL	video_fill
	LD	HL, loader_done_string
	LD	IY, [LOADER_TOP + 8]*64 + [LOADER_LEFT + 4]
	CALL	print_string

	; wait for the user to press ESC
.loader_done_loop
	CALL	keyboard_getchar
	LD	A, K_ESC
	CP	A, C
	JR	NZ, loader_done_loop ; ESC not pressed
	; exit
	CALL	icon_hide
	RET

.loader_transfer_progress
	PUSH	DE
	PUSH	HL
	LD	HL, progress_chars + 1
	; eZ80 instruction: LEA DE, IY
	DEFB	$ED, $13, 0
	CALL	video_write
	INC	IY
	POP	HL
	POP	DE
	; reset counter
	LD	B, H
	LD	C, L
	RET

	; wait for input
	; returns with C flag set if a byte was received
	; received byte is in A
	; returns with C flag cleared if ESC was pressed
	; this also hides the icon
.loader_input_loop
	CALL	serial_receive
	RET	C ; byte received
	CALL	keyboard_getchar
	LD	A, K_ESC
	CP	A, C
	JR	NZ, loader_input_loop ; ESC not pressed
	CALL	icon_hide
	OR	A, A ; clear carry flag
	RET
