; eZ80 ASM file: monitor - a machine code monitor program

INCLUDE "main.inc"
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

XREF decompress
XREF draw_box
XREF print_string
XREF print_uint8
XREF print_sint8
XREF print_hex_byte
XREF print_hex_word
XREF put_hex

XREF icon_show
XREF icon_hide

XREF cursor_hide
XREF cursor_move

XREF loader_open

XREF fileman_start

XDEF monitor

DEFC MONITOR_TRAMPOLINE = $FB20
DEFC MONITOR_REG_A = $FB32
DEFC MONITOR_REG_F = $FB31
DEFC MONITOR_REG_B = $FB37
DEFC MONITOR_REG_C = $FB36
DEFC MONITOR_REG_D = $FB3A
DEFC MONITOR_REG_E = $FB39
DEFC MONITOR_REG_H = $FB3D
DEFC MONITOR_REG_L = $FB3C
DEFC MONITOR_ALT_A = $FB22
DEFC MONITOR_ALT_F = $FB21
DEFC MONITOR_ALT_B = $FB27
DEFC MONITOR_ALT_C = $FB26
DEFC MONITOR_ALT_D = $FB2A
DEFC MONITOR_ALT_E = $FB29
DEFC MONITOR_ALT_H = $FB2D
DEFC MONITOR_ALT_L = $FB2C
DEFC MONITOR_PC = $FB4A
DEFC MONITOR_SP = $FB47
DEFC MONITOR_IX = $FB40
DEFC MONITOR_IY = $FB44

; top-left screen coordinates of the main hex listing
DEFC ORIGIN_X = 2
DEFC ORIGIN_Y = 4

; screen coordinates of the address indicator
DEFC ADDRESS_X = 0
DEFC ADDRESS_Y = 2

; screen coordinate of the menu
DEFC MENU_X = 1
DEFC MENU_Y = 0

.print_bits
	CALL	video_start_write
	LD	B, 8
.monitor_byte_bits_loop
	RL	C
	LD	A, $07
	JR	C, monitor_byte_bits_print
	LD	A, $09
.monitor_byte_bits_print
	CALL	spi_transmit_A
	DJNZ	monitor_byte_bits_loop
	JP	spi_deselect


.monitor_screen
	; escape character
	DEFB	-1
	; line 0
	DEFM	" F1:Help F2:GoTo F3:Load F4:Send F5:Call F6:File "
	DEFM	$B3, -1, 13, " ", $B3
	; line 1
	DEFM	$C4, $C4, $C2, -1, 46, $C4, $B4, -1, 13, " ", $C3
	; line 2
	DEFM	"  ", $B3, "0  1  2  3  4  5  6  7  8  9  A  B  C  D  E  F", $B3, -1, 13, " ", $B3
	; line 3
	DEFM	$C4, $C2, $C1, -1, 46, $C4, $B4, -1, 13, " ", $C3
	; line 4 - 19
	DEFM 	"0", $B3, -1, 47, " ", $B3, -1, 13, " ", $B3
	DEFM 	"1", $B3, -1, 47, " ", $B3, -1, 13, " ", $B3
	DEFM 	"2", $B3, -1, 47, " ", $B3, -1, 13, " ", $B3
	DEFM 	"3", $B3, -1, 47, " ", $B3, -1, 13, " ", $B3
	DEFM 	"4", $B3, -1, 47, " ", $B3, -1, 13, " ", $B3
	DEFM 	"5", $B3, -1, 47, " ", $B3, -1, 13, " ", $B3
	DEFM 	"6", $B3, -1, 47, " ", $B3, -1, 13, " ", $B3
	DEFM 	"7", $B3, -1, 47, " ", $B3, -1, 13, " ", $B3
	DEFM 	"8", $B3, -1, 47, " ", $B3, -1, 13, " ", $B3
	DEFM 	"9", $B3, -1, 47, " ", $B3, -1, 13, " ", $B3
	DEFM 	"A", $B3, -1, 47, " ", $B3, -1, 13, " ", $B3
	DEFM 	"B", $B3, -1, 47, " ", $B3, -1, 13, " ", $B3
	DEFM 	"C", $B3, -1, 47, " ", $B3, -1, 13, " ", $B3
	DEFM 	"D", $B3, -1, 47, " ", $B3, -1, 13, " ", $B3
	DEFM 	"E", $B3, -1, 47, " ", $B3, -1, 13, " ", $B3
	DEFM 	"F", $B3, -1, 47, " ", $B3, -1, 13, " ", $B3
	; line 20
	DEFM	$C4, $C1, -1, 36, $C4, $BF, -1, 10, " ", $B3, -1, 13, " ", $C3
	; line 21
	DEFM	-1, 38, " ", $B3, "  Memory  ", $B3, -1, 13, " ", $B3
	; line 22
	DEFM	-1, 4, " ", $DA, -1, 8, $C4, $BF, "   ", $DA, -1, 8, $C4, $BF, " "
	DEFM	$DA, -1, 7, $C4, $BF, " ", $C3, -1, 10, $C4, $B4, -1, 13, " ", $B3
	; line 23
	DEFM	-1, 4, " ", $B3, "SZ H PNC", $B3, "   ", $B3, "SZ H PNC", $B3, " "
	DEFM	$B3, "PC=", -1, 4, " ", $B3, " ", $B3, -1, 10, " ", $B3, -1, 13, " ", $B3
	; line 24
	DEFM	-1, 4, " ", $B3, -1, 8, " ", $B3, "   ", $B3, -1, 8, " ", $B3, " "
	DEFM	$C3, -1, 7, $C4, $B4, " ", $B3, -1, 10, " ", $B3, -1, 13, " ", $B3
	; line 25
	DEFM	" ", $DA, $C4, $C4, $C1, $C4, $C4, $BF, -1, 5, " "
	DEFM	$B3, $DA, $C4, $C4, $C1, $C4, $C4, $BF, -1, 5, " ", $B3, " "
	DEFM	$B3, "SP=", -1, 4, " ", $B3, " ", $B3, -1, 10, " ", $B3, -1, 13, " ", $B3
	; line 26
	DEFM	" ", $B3, " A=  ", $B3, " F=  ", $B3, $B3, "A'=  ", $B3, "F'=  ", $B3, " "
	DEFM	$C0, -1, 7, $C4, $D9, " ", $B3, " $", -1, 8, " ", $B3, -1, 13, " ", $B3
	; line 27
	DEFM	" ", $C3, -1, 5, $C4, $C5, -1, 5, $C4, $B4, $C3, -1, 5, $C4, $C5, -1, 5, $C4, $B4
	DEFM	"  Control  ", $B3, -1, 10, " ", $B3, -1, 13, " ", $B3
	; line 28
	DEFM	" ", $B3, " B=  ", $B3, " C=  ", $B3, $B3, "B'=  ", $B3, "C'=  ", $B3
	DEFM	-1, 11, " ", $B3, " ' '", -1, 6, " ", $B3, -1, 13, " ", $B3
	; line 29
	DEFM	" ", $C3, -1, 5, $C4, $C5, -1, 5, $C4, $B4, $C3, -1, 5, $C4, $C5, -1, 5, $C4, $B4
	DEFM	" ", $DA, -1, 7, $C4, $BF, " ", $B3, -1, 10, " ", $B3, -1, 13, " ", $B3
	; line 30
	DEFM	" ", $B3, " D=  ", $B3, " E=  ", $B3, $B3, "D'=  ", $B3, "E'=  ", $B3
	DEFM	" ", $B3, "IX=", -1, 4, " ", $B3, " ", $B3, "   Byte   ", $B3, -1, 13, " ", $B3
	; line 31
	DEFM	" ", $C3, -1, 5, $C4, $C5, -1, 5, $C4, $B4, $C3, -1, 5, $C4, $C5, -1, 5, $C4, $B4
	DEFM	" ", $C3, -1, 7, $C4, $B4, " ", $C3, -1, 10, $C4, $B4, -1, 13, " ", $B3
	; line 32
	DEFM	" ", $B3, " H=  ", $B3, " L=  ", $B3, $B3, "H'=  ", $B3, "L'=  ", $B3
	DEFM	" ", $B3, "IY=", -1, 4, " ", $B3, " ", $B3, -1, 10, " ", $B3, -1, 13, " ", $B3
	; line 33
	DEFM 	" ", $C0, -1, 5, $C4, $C1, -1, 5, $C4, $D9, $C0, -1, 5, $C4, $C1, -1, 5, $C4, $D9
	DEFM	" ", $C0, -1, 7, $C4, $D9, " ", $B3, -1, 10, " ", $B3, -1, 13, " ", $B3
	; line 34
	DEFM	"   Registers", -1, 4, " ", "Alternate", -1, 5, " ", "Index   ", $B3
	DEFM	-1, 10, " ", $B3, -1, 13, " ", $B3
	; line 35
	DEFM	-1, 38, " ", $B3, -1, 10, " ", $B3, -1, 13, " ", $B3
	; line 36
	DEFM	-1, 38, $C4, $C1, -1, 10, $C4, $D9, -1, 13, " ", $C0
	; line 37-62 (26*64 = 6*255 + 134)
	DEFM	-1, 255, " ", -1, 255, " ", -1, 255, " "
	DEFM	-1, 255, " ", -1, 255, " ", -1, 255, " "
	DEFM	-1, 134, " "
	; line 63
	DEFM	-1, 49, $C4, $BF, -1, 13, " ", $DA
	; end
	DEFM	-1, 0

.monitor_trampoline_template
	LD	HL, 0
	PUSH	HL
	POP	AF
	LD	BC, 0
	LD	DE, 0
	LD	HL, 0
	EX	AF, AF'
	EXX
	LD	HL, 0
	PUSH	HL
	POP	AF
	LD	BC, 0
	LD	DE, 0
	LD	HL, 0
	LD	IX, 0
	LD	IY, 0
	LD	SP, USER_STACK
	CALL	USER_CODE
	LD	(MONITOR_SP), SP
	LD	SP, SYSTEM_STACK
	JP	monitor_entry
.end_monitor_trampoline_template

.monitor_redraw
	LD	DE, RAM_PIC
	CALL	video_start_write
	LD	HL, monitor_screen
	LD	IY, spi_transmit_A
	CALL	decompress
	JP	spi_deselect
	;RET optimized away by JP above

.monitor
	LD	DE, MONITOR_TRAMPOLINE
	LD	HL, monitor_trampoline_template
	LD	BC, #end_monitor_trampoline_template-monitor_trampoline_template
	LDIR
	CALL	monitor_redraw
	JR	monitor_main_loop
.monitor_entry
	LD	(MONITOR_REG_L), HL
	PUSH	AF
	POP	HL
	LD	(MONITOR_REG_F), HL
	LD	(MONITOR_REG_C), BC
	LD	(MONITOR_REG_E), DE
	EX	AF, AF'
	EXX
	LD	(MONITOR_ALT_L), HL
	PUSH	AF
	POP	HL
	LD	(MONITOR_ALT_F), HL
	LD	(MONITOR_ALT_C), BC
	LD	(MONITOR_ALT_E), DE
	LD	(MONITOR_IX), IX
	LD	(MONITOR_IY), IY
	CALL	monitor_redraw
.monitor_main_loop
	; main display loop
	LD	HL, (MONITOR_PC)
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
	; bits
	LD	C, (HL)
	LD	DE, RAM_PIC + 40 + 24*64
	CALL	print_bits
	; hex
	LD	DE, RAM_PIC + 41 + 26*64
	CALL	print_hex_byte
	; decimal (unsigned)
	LD	C, (HL)
	LD	DE, RAM_PIC + 45 + 26*64
	CALL	print_uint8
	; char
	LD	C, (HL)
	LD	DE, RAM_PIC + 41 + 28*64
	CALL	video_write_C
	; decimal (signed)
	LD	C, (HL)
	LD	DE, RAM_PIC + 44 + 28*64
	CALL	print_sint8
	; registers
	LD	DE, RAM_PIC + 5 + 26*64
	LD	HL, MONITOR_REG_A
	CALL	print_hex_byte
	LD	DE, RAM_PIC + 11 + 26*64
	DEC	HL; MONITOR_REG_F
	CALL	print_hex_byte
	LD	C, (HL)
	LD	DE, RAM_PIC + 5 + 24*64
	CALL	print_bits
	LD	DE, RAM_PIC + 5 + 28*64
	LD	HL, MONITOR_REG_B
	CALL	print_hex_byte
	LD	DE, RAM_PIC + 11 + 28*64
	DEC	HL; MONITOR_REG_C
	CALL	print_hex_byte
	LD	DE, RAM_PIC + 5 + 30*64
	LD	HL, MONITOR_REG_D
	CALL	print_hex_byte
	LD	DE, RAM_PIC + 11 + 30*64
	DEC	HL; MONITOR_REG_E
	CALL	print_hex_byte
	LD	DE, RAM_PIC + 5 + 32*64
	LD	HL, MONITOR_REG_H
	CALL	print_hex_byte
	LD	DE, RAM_PIC + 11 + 32*64
	DEC	HL; MONITOR_REG_L
	CALL	print_hex_byte
	; alternate registers
	LD	DE, RAM_PIC + 18 + 26*64
	LD	HL, MONITOR_ALT_A
	CALL	print_hex_byte
	LD	DE, RAM_PIC + 24 + 26*64
	DEC	HL; MONITOR_ALT_F
	CALL	print_hex_byte
	LD	C, (HL)
	LD	DE, RAM_PIC + 18 + 24*64
	CALL	print_bits
	LD	DE, RAM_PIC + 18 + 28*64
	LD	HL, MONITOR_ALT_B
	CALL	print_hex_byte
	LD	DE, RAM_PIC + 24 + 28*64
	DEC	HL; MONITOR_ALT_C
	CALL	print_hex_byte
	LD	DE, RAM_PIC + 18 + 30*64
	LD	HL, MONITOR_ALT_D
	CALL	print_hex_byte
	LD	DE, RAM_PIC + 24 + 30*64
	DEC	HL; MONITOR_ALT_E
	CALL	print_hex_byte
	LD	DE, RAM_PIC + 18 + 32*64
	LD	HL, MONITOR_ALT_H
	CALL	print_hex_byte
	LD	DE, RAM_PIC + 24 + 32*64
	DEC	HL; MONITOR_ALT_L
	CALL	print_hex_byte
	; PC / SP
	LD	DE, RAM_PIC + 32 + 23*64
	LD	HL, MONITOR_PC
	CALL	print_hex_word
	LD	DE, RAM_PIC + 32 + 25*64
	LD	HL, MONITOR_SP
	CALL	print_hex_word
	; IX / IY
	LD	DE, RAM_PIC + 32 + 30*64
	LD	HL, MONITOR_IX
	CALL	print_hex_word
	LD	DE, RAM_PIC + 32 + 32*64
	LD	HL, MONITOR_IY
	CALL	print_hex_word
	; memory listing
	LD	IY, RAM_PIC + ORIGIN_X + ORIGIN_Y*64
	LD	HL, (MONITOR_PC)
	LD	L, 0	; write 16 lines
	LD	C, 16
.monitor_line_outer_loop
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
	JR	NZ, monitor_line_outer_loop
	; let HL point to where PC is stored
	LD	HL, MONITOR_PC
	; page up/down
	CALL	keyboard_getchar
	; page down
	LD	A, K_PGD
	CP	A, C
	JP	NZ, monitor_main_loop_page_up
	; page down pressed - increment PC upper byte
	INC	HL
	INC	(HL)
	DEC	HL
	JP	monitor_main_loop
	; page up
.monitor_main_loop_page_up
	LD	A, K_PGU
	CP	A, C
	JR	NZ, monitor_main_loop_arrow_keys
	; page up pressed, decrement PC upper byte
	INC	HL
	DEC	(HL)
	DEC	HL
	JP	monitor_main_loop
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
	JP	Z, monitor_load
	LD	A, K_F5
	CP	A, C
	JP	Z, MONITOR_TRAMPOLINE
	LD	A, K_F6
	CP	A, C
	JP	Z, monitor_file
	; + and -
.monitor_main_loop_input_plusminus
	LD	A, '+'
	CP	A, C
	JR	NZ, monitor_main_loop_input_noplus
	; LD HL, (HL)
	DEFB	$ED, $27
	INC	(HL)
	JP	monitor_main_loop
.monitor_main_loop_input_noplus
	LD	A, '-'
	CP	A, C
	JR	NZ, monitor_main_loop_input_nominus
	; LD HL, (HL)
	DEFB	$ED, $27
	DEC	(HL)
	JP	monitor_main_loop
.monitor_main_loop_input_nominus
	; handle hex input
.monitor_main_loop_hex_input
	LD	A, C
	; decode ascii
	SUB	A, '0'
	; ignore if below '0'
	JP	C, monitor_main_loop
	; handle 0..9
	CP	A, $A
	JR	C, monitor_hex_input_write
	; to lowercase
	OR	A, $20
	; decode a..f
	SUB	A, 'a' - ('9' + 1)
	; ignore if below $A
	CP	A, $A
	JP	C, monitor_main_loop
	; ignore if above $F
	; eZ80 instruction: TST A, $F0
	DEFB	$ED, $64, $F0
	JP	NZ, monitor_main_loop
.monitor_hex_input_write
	; let HL point to data at PC
	; LD HL, (HL)
	DEFB	$ED, $27
	; insert halfbyte
	RLD
	JP	monitor_main_loop

.monitor_cursor_left
	DEC	(HL)
	JR	monitor_cursor_update
.monitor_cursor_right
	INC	(HL)
	JR	monitor_cursor_update
.monitor_cursor_up
	LD	A, (HL)
	SUB	A, 16
	LD	(HL), A
	JR	monitor_cursor_update
.monitor_cursor_down
	LD	A, (HL)
	ADD	A, 16
	LD	(HL), A
.monitor_cursor_update
	; x location for cursor
	LD	A, (HL)
	AND	A, $0F
	LD	B, A
	; y location for cursor
	LD	A, (HL)
	AND	A, $F0
	RLCA
	RLCA
	RLCA
	RLCA
	LD	C, A
	CALL	cursor_move
	JP	monitor_main_loop

.monitor_load
	; save HL and IXL
	PUSH	HL
	PUSH	IX
	; calculate selected address into IX
	LD	A, H
	LD	IXH, A
	; hide cursor (trashes registers, but not IX)
	CALL	cursor_hide
	; loader screen
	CALL	loader_open
	CALL	monitor_redraw
	; restore IXL and HL
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
	CALL	monitor_redraw
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
