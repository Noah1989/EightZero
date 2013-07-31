; eZ80 ASM file: monitor - a machine code monitor program

INCLUDE "monitor.inc"
INCLUDE "video.inc"
INCLUDE "keyboard.inc"

XREF video_fill
XREF video_copy
XREF video_start_write
XREF spi_transmit
XREF spi_transmit_A
XREF spi_deselect
XREF video_write
XREF video_write_C

XREF keyboard_getchar

XREF draw_box
XREF print_string
XREF put_hex

XREF icon_show
XREF icon_hide

XREF cursor_hide
XREF cursor_move

XREF loader_open

XREF fileman_start

XDEF monitor

; top-left screen coordinates of the main hex listing
DEFC ORIGIN_X = 2
DEFC ORIGIN_Y = 4

; screen coordinates of the address indicator
DEFC ADDRESS_X = 0
DEFC ADDRESS_Y = 2

; screen coordinate of the menu
DEFC MENU_X = 1
DEFC MENU_Y = 0

; default listing start address
DEFC LISTING_START = $E000

.border_character
	DEFB	$C4, $B3
.menu_string
	DEFM	"F1:Help F2:GoTo F3:Load F4:Send F5:Call F6:File"
.end_menu_string

.monitor_redraw
	; print menu
	LD	HL, menu_string
	LD	DE, MENU_X + MENU_Y*64
	LD	BC, #end_menu_string-menu_string
	CALL	video_copy
	; draw some borders and static labels
	LD	HL, border_character
	; horizontal borders
	LD	DE, 63*64
	LD	BC, 49
	CALL	video_fill
	LD	DE, [ADDRESS_Y - 1]*64
	LD	BC, 49
	CALL	video_fill
	LD	DE, [ADDRESS_Y + 1]*64
	LD	BC, 49
	CALL	video_fill
	LD	DE, [ORIGIN_Y + 32]*64
	LD	BC, 49
	CALL	video_fill
	; switch to vertical border character
	INC	HL
	; vertical borders
	LD	IY, ORIGIN_X + 47 + MENU_Y*64
	LD	B, 36
.monitor_vertical_border_loop
	; eZ80 instruction: LEA DE, IY + 0
	DEFB	$ED, $13, 0
	CALL	video_write
	; eZ80 instruction: LEA DE, IY + 63 - 47 - 2
	DEFB	$ED, $13, 63 - 47 - 2
	CALL	video_write
	; next line
	; eZ80 instruction: LEA IY, IY + 64
	DEFB	$ED, $33, 64
	DJNZ	monitor_vertical_border_loop
	; corners and T-pieces
	LD	C, $C1 ; <- _|_
	LD	DE, [ORIGIN_X - 1] + [ORIGIN_Y + 32]*64
	CALL	video_write_C
	LD	DE, [ORIGIN_X] + [ADDRESS_Y + 1]*64
	CALL	video_write_C
	INC	C ; <- $C2 T
	DEC	DE
	CALL	video_write_C
	LD	DE, ORIGIN_X + [ADDRESS_Y - 1]*64
	CALL	video_write_C
	INC	C ; <- $C3 |-
	LD	DE, 63 + [ADDRESS_Y - 1]*64
	CALL	video_write_C
	LD	DE, 63 + [ADDRESS_Y + 1]*64
	CALL	video_write_C
	LD	C, $BF ; <- top-right corner
	LD	DE, 49 + 63*64
	CALL	video_write_C
	INC	C ; <- bottom-left corner
	LD	DE, 63 + [ORIGIN_Y + 32]*64
	CALL	video_write_C
	LD	C, $B4 ; <- -|
	LD	DE, 49 + [ADDRESS_Y - 1]*64
	CALL	video_write_C
	LD	DE, 49 + [ADDRESS_Y + 1]*64
	CALL	video_write_C
	LD	C, $D9 ; <- bottom-right corner
	LD	DE, 49 + [ORIGIN_Y + 32]*64
	CALL	video_write_C
	INC	C ; <- $DA top-left corner
	LD	DE, 63 + 63*64
	CALL	video_write_C
	; top border address labels
	LD	DE, ORIGIN_X + ADDRESS_Y*64
	CALL	video_start_write
	CALL	spi_transmit
	LD	B, 16
	JR	monitor_top_address_labels_loop_start
.monitor_top_address_labels_loop
	LD	A, ' '
	CALL	spi_transmit_A
	CALL	spi_transmit_A
.monitor_top_address_labels_loop_start
	LD	A, 16
	SUB	A, B
	CALL	put_hex
	DJNZ	monitor_top_address_labels_loop
	CALL	spi_transmit
	CALL	spi_deselect
	; left border address labels
	LD	IY, ORIGIN_X - 2 + ORIGIN_Y*64
	LD	B, 32
.monitor_left_address_labels_loop
	; eZ80 instruction: LEA DE, IY + 0
	DEFB	$ED, $13, 0
	; next line
	; eZ80 instruction: LEA IY, IY + 64
	DEFB	$ED, $33, 64
	CALL	video_start_write
	XOR	A, A
	SUB	A, B
	CALL	put_hex
	CALL	spi_transmit
	CALL	spi_deselect
	DJNZ	monitor_left_address_labels_loop
	RET

.monitor
	CALL	monitor_redraw
	; reset HL to RAM start
	LD	HL, LISTING_START
	; IX tracks the cursor address relative to HL
	LD	IX, 0
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
	CALL	put_hex
	; low nibble
	LD	A, H
	CALL	put_hex
	CALL	spi_deselect

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
	LD	A, ' '
	CALL	spi_transmit_A
.monitor_line_loop_start
	; high nibble
	LD	A, (HL)
	RRA
	RRA
	RRA
	RRA
	CALL	put_hex
	; low nibble
	LD	A, (HL)
	CALL	put_hex
	INC	HL
	DJNZ	monitor_line_loop
	CALL	spi_deselect
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
	JR	NZ, monitor_main_loop_arrow_keys
	; page up pressed, effective decrement: 1
	DEC	H
	JR	monitor_main_loop
	; handle arrow keys
.monitor_main_loop_arrow_keys
	LD	A, K_LFA
	CP	A, C
	JR	Z, monitor_cursor_left
	LD	A, K_RTA
	CP	A, C
	JR	Z, monitor_cursor_right
	LD	A, K_UPA
	CP	A, C
	JR	Z, monitor_cursor_up
	LD	A, K_DNA
	CP	A, C
	JR	Z, monitor_cursor_down
	; handle function keys
.monitor_main_loop_function_keys
	LD	A, K_F1
	CP	A, C
	JP	Z, monitor_help
	LD	A, K_F3
	CP	A, C
	JR	Z, monitor_load
	LD	A, K_F5
	CP	A, C
	JR	Z, monitor_call
	LD	A, K_F6
	CP	A, C
	JP	Z, monitor_file
	; handle hex input
.monitor_main_loop_hex_input
	LD	A, C
	; decode ascii
	SUB	A, '0'
	; ignore if below '0'
	JR	C, monitor_main_loop_listing
	; handle 0..9
	CP	A, $A
	JR	C, monitor_hex_input_write
	; to lowercase
	OR	A, $20
	; decode a..f
	SUB	A, 'a' - ('9' + 1)
	; ignore if below $A
	CP	A, $A
	JP	C, monitor_main_loop_listing
	; ignore if above $F
	; eZ80 instruction: TST A, $F0
	DEFB	$ED, $64, $F0
	JP	NZ, monitor_main_loop_listing
.monitor_hex_input_write
	; calculate IX = HL + IX (and save original HL value in DE)
	; note that L is zero here, so IXL does not change
	EX	DE, HL
	ADD	IX, DE
	; eZ80 instruction: LEA HL, IX
	DEFB	$ED, $22, $00
	; insert halfbyte
	RLD
	; restore HL from DE
	EX	DE, HL
	; restore IXH
	LD	A, IXH
	SUB	A, H
	LD	IXH, A
	JP	monitor_main_loop_listing

.monitor_cursor_left
	DEC	IX
	JR	monitor_cursor_update
.monitor_cursor_right
	INC	IX
	JR	monitor_cursor_update
.monitor_cursor_up
	; eZ80 instruction: LEA IX, IX - 16
	DEFB	$ED, $32, -16
	JR	monitor_cursor_update
.monitor_cursor_down
	; eZ80 instruction: LEA IX, IX + 16
	DEFB	$ED, $32, 16
.monitor_cursor_update
	; clamp IX to $01FF
	LD	A, IXH
	AND	A, 1
	LD	IXH, A
	; x location for cursor
	LD	A, IXL
	AND	A, $0F
	LD	B, A
	; y location for cursor
	LD	A, IXL
	AND	A, $F0
	ADD	A, IXH
	RLCA
	RLCA
	RLCA
	RLCA
	LD	C, A
	PUSH	HL
	CALL	cursor_move
	POP	HL
	JP	monitor_main_loop

.monitor_call
	; save HL and IX
	PUSH	HL
	PUSH	IX
	; calculate selected address into IX
	EX	DE, HL
	ADD	IX, DE
	LD	HL, monitor_call_return
	; return address for called code
	PUSH	HL
	; hide cursor (trashes registers, but not IX)
	CALL	cursor_hide
	; call into selected code
	JP	(IX)
.monitor_call_return
	; redraw monitor user interface
	CALL	monitor_redraw
	; restore IX and HL
	POP	IX
	POP	HL
	; always reposition cursor
	JP	monitor_cursor_update

.monitor_load
	; save HL and IX
	PUSH	HL
	PUSH	IX
	; calculate selected address into IX
	EX	DE, HL
	ADD	IX, DE
	; hide cursor (trashes registers, but not IX)
	CALL	cursor_hide
	; loader screen
	CALL	loader_open
	; restore IX and HL
	POP	IX
	POP	HL
	; always reposition cursor
	JP	monitor_cursor_update

.monitor_file
	PUSH	HL
	PUSH	IX
	CALL	cursor_hide
	CALL	fileman_start
	CALL	monitor_redraw
	POP	IX
	POP	HL
	JP	monitor_cursor_update

DEFC HELP_WIDTH = 37
DEFC HELP_HEIGHT = 13
DEFC HELP_TOP = 12
DEFC HELP_LEFT = 7
.monitor_help
	PUSH	HL
	CALL	cursor_hide
	LD	BC, HELP_WIDTH*256 + HELP_HEIGHT
	LD	IY, HELP_TOP*64 + HELP_LEFT
	CALL	draw_box
	LD	BC, [HELP_LEFT + 1]*256 + [HELP_TOP + 1]
	XOR	A, A ; icon 0
	CALL	icon_show
	LD	HL, monitor_help_string
	LD	IY, [HELP_TOP + 1]*64 + [HELP_LEFT + 4]
	CALL	print_string
	; wait for keypress
.monitor_help_pause
	CALL	keyboard_getchar
	LD	A, K_ESC
	CP	A, C
	JR	NZ, monitor_help_pause
	CALL	icon_hide
	POP	HL
	; reposition cursor
	JP	monitor_cursor_update
.monitor_help_string
	DEFM	"This program can view and change", 10
	DEFM	"memory locations on the machine.", 10, 10
	DEFM	$18, " ", $19, " ", $1A, " ", $1B, "    move cursor", 10, 10
	DEFM	"PgUp PgDn  scroll 256 bytes", 10, 10
	DEFM	"0..9 A..F  modify selected byte", 10, 10, 10
	DEFM	"Press ESC to close this window.", 0
