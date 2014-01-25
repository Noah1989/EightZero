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

XDEF editor_open_file

DEFC WINDOW_X = 0
DEFC WINDOW_Y = 3
DEFC WINDOW_H = 28
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
	DEFM	-1, 38, " ", $B3, -1, 10, 0, $B3, -1, 13, 0, $B3
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
	POP	BC
	LD	IY, WINDOW_X + WINDOW_Y*64
	LD	HL, FILE_BUFFER
	LD	E, WINDOW_H ; line counter
.editor_print_loop
	PUSH	DE
	CALL	print_line
	POP	DE
	; check for end of screen
	DEC	E
	JR	Z, editor_print_end
	; check for EOF
	LD	A, B
	OR	A, C
	JR	NZ, editor_print_loop
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
	LD	A, K_ESC
	CP	A, C
	JR	NZ, editor_input_loop
	CALL	editor_cursor_blink_off
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
	; column counter
	LD	E, 0
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
	; handle tab
	CP	A, 9
	JR	Z, print_line_tab
	CALL	spi_transmit_A
	INC	E
	JR	print_line_loop
.print_line_end
	; eZ80 instruction: LEA IY, IY + 64
	DEFB	$ED, $33, 64
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