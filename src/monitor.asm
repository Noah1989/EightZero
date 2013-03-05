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

XREF draw_box
XREF print_string
XREF icon_show
XREF icon_hide

XREF cursor_hide
XREF cursor_move

XREF SCROLL_X

XREF RAM_PIC

XREF K_ESC
XREF K_F1
XREF K_F5
XREF K_UPA
XREF K_LFA
XREF K_DNA
XREF K_RTA
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
DEFC SPACE_CHARACTER = $00 ; <- black square

; default listing start address
DEFC LISTING_START = $E000

.dialog_style
.dialog_fill_character
	DEFB	' '
.dialog_border_character
	DEFB	$07 ; <- white square
.dialog_shadow_character
	DEFB	$00 ; <- black square
.border_character
	DEFB	$08 ; <- gray square
.menu_string
	DEFM	"F1:Help  F2:GoTo  F3:Load  F4:Copy  F5:Call"
.end_menu_string

.monitor_redraw
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
	XOR	A, A
	SUB	A, B
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
	JR	Z, monitor_help
	LD	A, K_F5
	CP	A, C
	JR	Z, monitor_call
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
	JR	C, monitor_main_loop_listing
	; ignore if above $F
	; eZ80 instruction: TST A, $F0
	DEFB	$ED, $64, $F0
	JR	NZ, monitor_main_loop_listing
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
	EX	DE, HL
	ADD	IX, DE
	LD	HL, monitor_call_return
	; save DE (original HL value) and IX
	PUSH	DE
	PUSH	IX
	; return address for called function
	PUSH	HL
	JP	(IX)
.monitor_call_return
	; redraw monitor user interface
	CALL	monitor_redraw
	; restore IX and original HL
	POP	IX
	POP	HL
	LD	A, IXH
	AND	A, 1
	LD	IXH, A
	; always reposition cursor
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
	LD	HL, dialog_style
	CALL	draw_box
	LD	BC, [HELP_LEFT + 1]*256 + [HELP_TOP + 1]
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
	DEFM	$10, " ", $11, " ", $12, " ", $13, "    move cursor", 10, 10
	DEFM	"PgUp PgDn  scroll 256 bytes", 10, 10
	DEFM	"0..9 A..F  modify selected byte", 10, 10, 10
	DEFM	"Press ESC to close this window.", 0
