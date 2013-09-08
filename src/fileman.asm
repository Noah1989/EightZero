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
XREF keyboard_getchar
XREF sdhc_init
XREF fat32_init
XREF fat32_dir

XDEF fileman_start

; screen coordinate of the menu
DEFC MENU_X = 1
DEFC MENU_Y = 0

; main window inner dimensions
DEFC WINDOW_X = 1
DEFC WINDOW_Y = 5
DEFC WINDOW_WIDTH = 49
DEFC WINDOW_HEIGHT = 32

.border_char
	DEFB	$08 ; <- gray square
.background_car
	DEFB	$20 ; <- space

.menu_string
	DEFM	"F1:Help F2:Menu F3:View F4:Edit F5:Copy F6:Move"
.end_menu_string
.title_string
	DEFM	$08, " Name                                     ", $08 ," Size ", $08
.end_title_string

.fileman_start
	CALL	sdhc_init
	RET	C
	CALL	fat32_init
        ; print menu
        LD      HL, menu_string
        LD      DE, MENU_X + MENU_Y*64
        LD      BC, #end_menu_string-menu_string
        CALL    video_copy
        ; title border
        LD	HL, border_char
        LD	DE, [WINDOW_X - 1] + [WINDOW_Y - 3]*64
        LD	BC, WINDOW_WIDTH + 2
        CALL	video_fill
        ; title
        LD	HL, title_string
        LD	DE, [WINDOW_X - 1] + [WINDOW_Y - 2]*64
        LD	BC, #end_title_string-title_string
        CALL	video_copy
        ; top horizontal border
        LD	HL, border_char
        LD	DE, [WINDOW_X - 1] + [WINDOW_Y - 1]*64
        LD	BC, WINDOW_WIDTH + 2
        CALL	video_fill
        ; vertical border and content
        LD      IY, [WINDOW_X - 1] + WINDOW_Y*64
        EXX
        LD      B, WINDOW_HEIGHT
.fileman_window_loop
	EXX
	; eZ80 instruction: LEA DE, IY + 0
	DEFB    $ED, $13, 0
	CALL    video_start_write
	; left  border line
	CALL	spi_transmit
	; inner space
	INC	HL
	LD	B, WINDOW_WIDTH - 7
.fileman_fill_line_loop1
	CALL	spi_transmit
	DJNZ	fileman_fill_line_loop1
	DEC	HL
	; size seperator
	CALL	spi_transmit
	INC	HL
	LD	B, 6
.fileman_fill_line_loop2
	CALL	spi_transmit
	DJNZ	fileman_fill_line_loop2
        DEC	HL
        ; right border line
        CALL	spi_transmit
        CALL	spi_deselect
        ; next line
        ; eZ80 instruction: LEA IY, IY + 64
        DEFB    $ED, $33, 64
        EXX
        DJNZ    fileman_window_loop
        EXX
        ; bottom border
        ; eZ80 instruction: LEA DE, IY + 0
        DEFB    $ED, $13, 0
	LD	BC, WINDOW_WIDTH + 2
	CALL	video_fill
        ; list files
	EXX
	LD	DE, [WINDOW_X + 1] + WINDOW_Y*64
	EXX
	LD	HL, (DATA_SECTOR)
	LD	DE, (DATA_SECTOR + 2)
	LD	IY, fileman_dir_callback
	CALL	fat32_dir
.fileman_input_loop
	CALL	keyboard_getchar
	LD	A, K_ESC
	CP	A, C
	JR	NZ, fileman_input_loop
	RET

.fileman_dir_callback
	EXX
	LD	IYH, D
	LD	IYL, E
	LD	HL, FILE_NAME_BUFFER
	CALL	print_string
	; eZ80: LEA DE, IY + 64
	DEFB	$ED, $13, 64
	EXX
	LD	IY, fileman_dir_callback
	RET