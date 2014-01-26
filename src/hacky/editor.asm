; eZ80 asm file: editor - simple text editor

INCLUDE "main.inc"
INCLUDE "fat32.inc"
INCLUDE "keyboard.inc"

XREF draw_screen
XREF fat32_load
XREF video_start_write
XREF video_write_C
XREF spi_transmit_A
XREF spi_deselect
XREF keyboard_getchar
XREF print_uint16

XDEF editor_open_file

DEFC WINDOW_X = 0 ; some code relies on this to be 0
DEFC WINDOW_Y = 3
DEFC WINDOW_H = 28 ; should be dividable by 4
DEFC STATUS_X = 1
DEFC STATUS_Y = 33
DEFC CURSOR = $DB

.editor_screen
	; escape character
	DEFB	-1
	; line 0
	DEFM	" F1:Help   F2:Save   F3:Mark  F4:Replace F5:Copy "
	DEFM	$B3, -1, 13, 0, $B3
	; line 1
	DEFM	" F6:Move   F7:Search F8:Delete F9:Menu  ESC:Quit "
	DEFM	$B3, -1, 13, 0, $B3
	; line 2
	DEFM	-1, 49, $C4, $B4, -1, 13, 0, $C3
	; line 3-30
	DEFM	-1, 49, " ", $B3, -1, 13, 0, $B3
	DEFM	-1, 49, " ", $B3, -1, 13, 0, $B3
	DEFM	-1, 49, " ", $B3, -1, 13, 0, $B3
	DEFM	-1, 49, " ", $B3, -1, 13, 0, $B3
	DEFM	-1, 49, " ", $B3, -1, 13, 0, $B3
	DEFM	-1, 49, " ", $B3, -1, 13, 0, $B3
	DEFM	-1, 49, " ", $B3, -1, 13, 0, $B3
	DEFM	-1, 49, " ", $B3, -1, 13, 0, $B3
	DEFM	-1, 49, " ", $B3, -1, 13, 0, $B3
	DEFM	-1, 49, " ", $B3, -1, 13, 0, $B3
	DEFM	-1, 49, " ", $B3, -1, 13, 0, $B3
	DEFM	-1, 49, " ", $B3, -1, 13, 0, $B3
	DEFM	-1, 49, " ", $B3, -1, 13, 0, $B3
	DEFM	-1, 49, " ", $B3, -1, 13, 0, $B3
	DEFM	-1, 49, " ", $B3, -1, 13, 0, $B3
	DEFM	-1, 49, " ", $B3, -1, 13, 0, $B3
	DEFM	-1, 49, " ", $B3, -1, 13, 0, $B3
	DEFM	-1, 49, " ", $B3, -1, 13, 0, $B3
	DEFM	-1, 49, " ", $B3, -1, 13, 0, $B3
	DEFM	-1, 49, " ", $B3, -1, 13, 0, $B3
	DEFM	-1, 49, " ", $B3, -1, 13, 0, $B3
	DEFM	-1, 49, " ", $B3, -1, 13, 0, $B3
	DEFM	-1, 49, " ", $B3, -1, 13, 0, $B3
	DEFM	-1, 49, " ", $B3, -1, 13, 0, $B3
	DEFM	-1, 49, " ", $B3, -1, 13, 0, $B3
	DEFM	-1, 49, " ", $B3, -1, 13, 0, $B3
	DEFM	-1, 49, " ", $B3, -1, 13, 0, $B3
	DEFM	-1, 49, " ", $B3, -1, 13, 0, $B3
	; line 31
	DEFM	-1, 38, $C4, $C2, -1, 10, $C4, $B4, -1, 13, 0, $C3
	; line 32-35
	DEFM	-1, 38, " ", $B3, -1, 10, 0, $B3, -1, 13, 0, $B3
	DEFM	" 00000 bytes total", -1, 20, " ", $B3, -1, 10, 0, $B3, -1, 13, 0, $B3
	DEFM	-1, 38, " ", $B3, -1, 10, 0, $B3, -1, 13, 0, $B3
	DEFM	-1, 38, " ", $B3, -1, 10, 0, $B3, -1, 13, 0, $B3
	; line 36
	DEFM	-1, 38, $C4, $C1, -1, 10, $C4, $D9, -1, 13, 0, $C0
	; line 37-62 (26*64 = 6*255 + 134)
	DEFM	-1, 255, 0, -1, 255, 0, -1, 255, 0
	DEFM	-1, 255, 0, -1, 255, 0, -1, 255, 0
	DEFM	-1, 134, 0
	; line 63
	DEFM	-1, 49, $C4, $BF, -1, 13, 0, $DA
	; end
	DEFM	-1, 0

.editor_open_file
	PUSH	BC ; file size
	CALL	fat32_load
.editor_redraw
	LD	HL, editor_screen
	CALL	draw_screen
.editor_print
	POP	BC
	PUSH	BC
	LD	IY, WINDOW_X + WINDOW_Y*64
	LD	HL, FILE_BUFFER
	LD	E, WINDOW_H ; line counter
.editor_print_loop
	PUSH	DE
	CALL	print_line
	; eZ80 instruction: LEA IY, IY + 64
	DEFB	$ED, $33, 64
	POP	DE
	; check for end of screen
	DEC	E
	JR	Z, editor_print_size
	; check for EOF
	LD	A, B
	OR	A, C
	JR	NZ, editor_print_loop
.editor_print_eof
	LD	(HL), $FF
.editor_print_size
	LD	DE, STATUS_X + STATUS_Y*64
	POP	HL ; file size
	PUSH	HL
	CALL	print_uint16
.editor_print_end
	; cursor screen position
	LD	IY, WINDOW_X + WINDOW_Y*64
	; cursor file position
	LD	HL, FILE_BUFFER
	CALL	editor_cursor_blink_on
.editor_input_loop
	LD	A, (INTERRUPT_TABLE + $54 + 2)
	BIT	0, A
	CALL	NZ, editor_cursor_update
	CALL	keyboard_getchar
	LD	A, C
	; tabs and line breaks
	CP	A, 9
	JP	Z, editor_ins_char
	CP	A, 10
	JP	Z, editor_ins_char
	; escape
	CP	A, K_ESC
	JR	Z, editor_exit
	; arrows
	CP	A, K_RTA
	JR	Z, editor_next
	CP	A, K_LFA
	JR	Z, editor_prev
	CP	A, K_UPA
	JR	Z, editor_up
	CP	A, K_DNA
	JR	Z, editor_down
	; backspace
	CP	A, 8
	JR	Z, editor_backspace
	; delete
	CP	A, K_DEL
	JP	Z, editor_del_char
	; ignore other control chars
	CP	A, $20
	JR	C, editor_input_loop
	; printable characters
	CP	A, $7F
	JR	C, editor_ins_char
	JR	editor_input_loop
.editor_exit
	CALL	editor_cursor_blink_off
	POP	BC ; tidy up stack
	RET

.editor_up
	CALL	editor_cursor_0
	CALL	editor_find_line_start
	JR	editor_prev_nocursor

.editor_down
	CALL	editor_cursor_0
	LD	A, (HL)
	CP	A, $FF ; EOF guard
	JR	Z, editor_next_end_noinc
	LD	A, 10
	CPIR
	DEC	HL
	JR	editor_next_nocursor

.editor_next
	CALL	editor_cursor_0
.editor_next_nocursor
	LD	A, (HL)
	CP	A, $FF ; EOF guard
	JR	Z, editor_next_end_noinc
	CP	A, 10
	JR	Z, editor_next_line
	CP	A, 9
	JR	Z, editor_next_tab
	INC	IY
.editor_next_end
	INC	HL
.editor_next_end_noinc
	CALL	editor_cursor_1
	JR	editor_input_loop
.editor_next_line
	; eZ80 instruction: LEA IY, IY + 64
	DEFB	$ED, $33, 64
	LD	A, IYL
	AND	A, -64
	LD	IYL, A
	JR	editor_next_end
.editor_next_tab
	LD	A, IYL
	AND	A, -8
	ADD	A, 8
	LD	IYL, A
	JR	editor_next_end

.editor_backspace
	CALL	editor_cursor_0
	DEC	HL
	DEC	IY
	LD	A, FILE_BUFFER / $100 - 1
	CP	A, H
	JR	NZ, editor_del_char
	INC	IY
	; fall through
.editor_prev_stop
	INC	HL
	JR	editor_prev_end
.editor_prev
	CALL	editor_cursor_0
.editor_prev_nocursor
	DEC	HL
	LD	A, FILE_BUFFER / $100 - 1
	CP	A, H
	JR	Z, editor_prev_stop
	LD	A, (HL)
	CP	A, 10
	JR	Z, editor_prev_line
	CP	A, 9
	JR	Z, editor_prev_tab
	DEC	IY
.editor_prev_end
	CALL	editor_cursor_1
	JP	editor_input_loop
.editor_prev_line
	; eZ80 instruction: LEA IY, IY - 64
	DEFB	$ED, $33, -64
.editor_prev_tab
	CALL	editor_find_line_start
	JR	editor_prev_end

.editor_ins_char
	AND	A, A
	LD	A, C
	LD	BC, FILE_BUFFER
	PUSH	HL ; file position
	SBC	HL, BC
	POP	BC ; file position
	EX	DE, HL ; rel. pos now in DE
	POP	HL ; file size
	PUSH	HL ; remains on stack
	SBC	HL, DE ; tail size now in HL
	LD	B, H ; BC <- tail size
	LD	C, L
	POP	DE ; file size
	PUSH	DE
	LD	HL, FILE_BUFFER
	ADD	HL, DE ; HL <- end of file
	LD	D, H
	LD	E, L
	; move tail by one byte
	INC	DE
	INC	BC
	LDDR
	INC	HL
	; HL should point to original file position
	LD	(HL), A
	; increase size
	POP	BC
	INC	BC
	PUSH	BC
	LD	A, (HL)
	CP	A, 10 inserted newline?
	JP	Z, editor_redraw
	PUSH	HL
	CALL	print_line
	POP	HL
	JP	editor_next

.editor_del_char
	LD	A, (HL)
	CP	A, $FF ; EOF guard
	JP	Z, editor_input_loop
	AND	A, A
	LD	BC, FILE_BUFFER
	PUSH	HL ; file position
	SBC	HL, BC
	POP	BC ; file position
	EX	DE, HL ; rel. pos now in DE
	POP	HL ; file size
	PUSH	HL ; remains on stack
	SBC	HL, DE ; tail size now in HL
	LD	D, B ; DE <- original file position
	LD	E, C
	LD	B, H ; BC <- tail size
	LD	C, L
	LD	H, D ; HL <- original file position
	LD	L, E
	PUSH	HL ; copy on stack
	; move tail by one byte
	INC	HL
	LDIR
	; restore file position
	POP	HL
	; decrease size
	POP	BC
	DEC	BC
	PUSH	BC
	CP	A, 9 ; deleted a tab?
	JP	Z, editor_redraw
	CP	A, 10 ; or newline?
	JP	Z, editor_redraw
	PUSH	HL
	CALL	print_line
	POP	HL
	JP	editor_input_loop

.editor_find_line_start
	LD	A, IYL
	AND	A, -64
	LD	IYL, A
	AND	A, A
	LD	BC, FILE_BUFFER
	PUSH	HL ; file position
	SBC	HL, BC
	LD	B, H ; rel pos in BC
	LD	C, L ; to avoid underflov
	INC	BC ; allow one more
	POP	HL ; file position
	LD	A, 10
	; find beginning of line
	DEC	HL
	CPDR
	INC	HL
	INC	HL
	RET

.editor_cursor_update
	AND	A, $FE
	LD	(INTERRUPT_TABLE + $54 + 2), A
	BIT	1, A
	JR	Z, editor_cursor_0
.editor_cursor_1
	; eZ80 instruction: LEA DE, IY
	DEFB	$ED, $13, 0
	LD	C, CURSOR
	JP	video_write_C
	;RET
.editor_cursor_0
	; eZ80 instruction: LEA DE, IY
	DEFB	$ED, $13, 0
	LD	C, (HL)
	LD	A, $1F
	CP	A, C
	JR	C, edit_cursor_0_write
	LD	C, ' '
.edit_cursor_0_write
	JP	video_write_C
	;RET

.editor_cursor_blink_on
	; cursor blink using timer0
	LD	A, @00010101 ; timer enable, cont. mode, div 64
	; OUT0 ($60), A
	DEFM	$ED, $39, $60
	XOR	A, A ; MAX reload time
	; OUT0 ($63), A
	DEFM	$ED, $39, $63
	; OUT0 ($64), A
	DEFM	$ED, $39, $64
	LD	IX, editor_cursor_blink_isr
	LD	(INTERRUPT_TABLE + $54), IX
	XOR	A, A
	LD	(INTERRUPT_TABLE + $54 + 2) , A
	LD	A, $01 ; timer interrupt enable
	; OUT0 ($61), A
	DEFM	$ED, $39, $61
	RET
.editor_cursor_blink_off
	; disable cursor blink timer
	XOR	A, A
	; OUT0 ($60)
	DEFM	$ED, $39, $60
	JR	editor_cursor_0
	;RET
.editor_cursor_blink_isr
	PUSH	AF
	LD	A, (INTERRUPT_TABLE + $54 + 2)
	CPL	A
	LD	(INTERRUPT_TABLE + $54 + 2), A
	XOR	A, A
	IN	A, ($62)
	POP	AF
	EI
	RETI


.print_line
	; eZ80 instruction: LEA DE, IY
	DEFB	$ED, $13, 0
	CALL	video_start_write
	; column counter (mod 8)
	LD	A, IYL
	; WINDOW_X=0, else: SUB A, WINDOW_X
	AND	A, 7
	LD	E, A
.print_line_loop
	; EOF?
	LD	A, B
	OR	A, C
	JR	Z, print_line_end
	; get character
	LD	A, (HL)
	INC	HL
	DEC	BC
	; check for end of line
	CP	A, 10
	JR	Z, print_line_end
	CP	A, $FF ; EOF
	JR	Z, print_line_end
	; handle tab
	CP	A, 9
	JR	Z, print_line_tab
	CALL	spi_transmit_A
	INC	E
	JR	print_line_loop
.print_line_end
	LD	A, ' '
	CALL	spi_transmit_A
	JP	spi_deselect
	; RET optimized away by JP above
.print_line_tab
	LD	A, ' '
	CALL	spi_transmit_A
	INC	E
	LD	A, 7
	AND	A, E
	JR	NZ, print_line_tab
	JR	print_line_loop