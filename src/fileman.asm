; eZ80 ASM file: fileman - a file manager

INCLUDE "fileman.inc"
INCLUDE "fat32.inc"
INCLUDE "keyboard.inc"

XREF video_reset
XREF sdhc_init
XREF fat32_init
XREF fat32_dir
XREF print_string
XREF keyboard_getchar

XDEF fileman_start

.fileman_start
	CALL	sdhc_init
	RET	C
	CALL	fat32_init
	CALL	video_reset
	EXX
	LD	DE, 64 + 1
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