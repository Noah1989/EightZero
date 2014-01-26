; eZ80 ASM file: fileman - a file manager

INCLUDE "fileman.inc"
INCLUDE "video.inc"
INCLUDE "keyboard.inc"
INCLUDE "fat32.inc"

XREF video_reset
XREF video_copy
XREF video_fill
XREF video_write
XREF video_write_C
XREF video_start_write
XREF spi_transmit
XREF spi_transmit_A
XREF spi_deselect
XREF print_string
XREF print_uint8
XREF draw_screen
XREF keyboard_getchar
XREF sdhc_init
XREF fat32_init
XREF fat32_dir
XREF fat32_find
XREF editor_open_file

XDEF fileman_start

; main window inner dimensions
DEFC WINDOW_X = 0
DEFC WINDOW_Y = 3
; status output location
DEFC STATUS_X = 1
DEFC STATUS_Y = 33

.fileman_screen
	; escape character
	DEFB	-1
	; line 0
	DEFM	" F1:Help   F2:Menu   F3:View   F4:Edit   F5:Copy "
	DEFM	$B3, -1, 13, 0, $B3
	; line 1
	DEFM	" F6:Move   F7:MkDir  F8:Delete F9:Load  ESC:Quit "
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
	DEFM	" 000 files total", -1, 22, " ", $B3, -1, 10, 0, $B3, -1, 13, 0, $B3
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

.fileman_start
	CALL	sdhc_init
	RET	C
	CALL	fat32_init
.fileman_redraw
	; draw screen
	LD	HL, fileman_screen
	CALL	draw_screen
.fileman_dir
	; list files
	EXX
	LD	DE, [WINDOW_X + 1] + WINDOW_Y*64
	LD	C, 0
	EXX
	LD	HL, (DATA_SECTOR)
	LD	DE, (DATA_SECTOR + 2)
	LD	IY, fileman_dir_callback
	CALL	fat32_dir
	; print file count
	LD	A, (DIR_FILE_COUNT)
	LD	C, A
	LD	DE, [STATUS_X] + STATUS_Y*64
	CALL	print_uint8
	; selected entry
	LD	E, 0
	LD	C, $1A ; arrow
	CALL	fileman_print_cursor
.fileman_input_loop
	CALL	keyboard_getchar
	LD	A, K_UPA
	CP	A, C
	JR	Z, fileman_input_up
	LD	A, K_DNA
	CP	A, C
	JR	Z, fileman_input_dn
	LD	A, K_F4
	CP	A, C
	JR	Z, fileman_edit
	LD	A, K_ESC
	CP	A, C
	JR	NZ, fileman_input_loop
	RET

.fileman_input_up
	LD	A, -1
	JR	fileman_input_updn
.fileman_input_dn
	LD	A, 1
.fileman_input_updn
	ADD	A, E ; E = old entry
	LD	D, A ; D = new entry
	LD	A, (DIR_FILE_COUNT)
	DEC	A
	CP	A, D
	JR	C, fileman_input_loop
	LD	C, ' '
	CALL	fileman_print_cursor
	LD	E, D
	LD	C, $1A
	CALL	fileman_print_cursor
	JR	fileman_input_loop

.fileman_edit
	LD	B, E
	LD	HL, (DATA_SECTOR)
	LD	DE, (DATA_SECTOR + 2)
	CALL	fat32_find
	CALL	editor_open_file
	JR	fileman_redraw

.fileman_print_cursor
	PUSH	DE
	LD	D, 64
	LD	HL, WINDOW_X + WINDOW_Y*64
	; eZ80: MLT DE
	DEFM	$ED, $5C
	ADD	HL, DE
	EX	DE, HL
	CALL	video_write_C
	POP	DE
	RET

.fileman_dir_callback
	EXX
	LD	IYH, D
	LD	IYL, E
	LD	HL, FILE_NAME_BUFFER
	CALL	print_string
	; eZ80: LEA DE, IY + 64
	DEFB	$ED, $13, 64
	INC	C
	EXX
	LD	IY, fileman_dir_callback
	RET