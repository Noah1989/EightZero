;eZ80 ASM file: fat32 - FAT32 file system implementation

INCLUDE "fat32.inc"
INCLUDE "sdhc.inc"

XREF sdhc_read_block

XDEF fat32_init
XDEF fat32_dir

DEFC MBR_OFFSET_PARTITION1_LBA        = $1C6

DEFC VBR_OFFSET_RESERVED_SECTOR_COUNT = $0E
DEFC VBR_OFFSET_FAT_COUNT             = $10
DEFC VBR_OFFSET_FAT_SIZE              = $24
DEFC VBR_OFFSET_CLUSTER_SIZE          = $0D

DEFC DIR_OFFSET_ATTRIBUTES = $0B
DEFC DIR_ATTRIBUTE_BIT_READONLY     = 0
DEFC DIR_ATTRIBUTE_BIT_HIDDEN       = 1
DEFC DIR_ATTRIBUTE_BIT_SYSTEM       = 2
DEFC DIR_ATTRIBUTE_BIT_VOLUME_LABEL = 3
DEFC DIR_ATTRIBUTE_BIT_SUBDIRECTORY = 4
DEFC DIR_ATTRIBUTE_BIT_ARCHIVE      = 5
DEFC DIR_ATTRIBUTE_BIT_DEVICE       = 6
DEFC DIR_ATTRIBUTE_BIT_RESERVED     = 7

DEFC DIR_ENTRY_DELETED_MARKER = $E5
DEFC DIR_LFN_END_BIT = 6

; initialize FAT32 file system
; requires an initialized SDHC card
.fat32_init
	; read MBR
	LD	DE, 0
	LD	HL, 0
	CALL	sdhc_read_block
	; get LBA of first partition (high word)
	LD	HL, SDHC_BLOCK_BUFFER + MBR_OFFSET_PARTITION1_LBA + 2
	; eZ80 instruction: LD DE, (HL)
	DEFM	$ED, $17
	; now read the low word
	DEC 	HL
	DEC 	HL
	; eZ80 instruction: LD HL, (HL)
	DEFM	$ED, $27
	; save partition LBA (VBR sector number)
	LD	(VBR_SECTOR), HL
	LD	(VBR_SECTOR + 2), DE
	; read VBR
	CALL	sdhc_read_block
	; get cluster size
	LD	HL, SDHC_BLOCK_BUFFER + VBR_OFFSET_CLUSTER_SIZE
	LD	A, (HL)
	LD	(CLUSTER_SIZE), A
	; get number of FATs
	LD	HL, SDHC_BLOCK_BUFFER + VBR_OFFSET_FAT_COUNT
	LD	A, (HL)
	; get FAT size (high word)
	LD	HL, SDHC_BLOCK_BUFFER + VBR_OFFSET_FAT_SIZE + 2
	; eZ80 instruction: LD DE, (HL)
	DEFM	$ED, $17
	; now read the low word
	DEC 	HL
	DEC 	HL
	; eZ80 instruction: LD HL, (HL)
	DEFM	$ED, $27
	; store FAT size
	LD	(FAT_SIZE), HL
	LD	(FAT_SIZE + 2), DE
	; get number of reserved sectors (only 2 bytes)
	LD	HL, SDHC_BLOCK_BUFFER + VBR_OFFSET_RESERVED_SECTOR_COUNT
	; eZ80 instruction: LD BC, (HL)
	DEFM	$ED, $07
	; load VBR sector number
	LD	HL, (VBR_SECTOR)
	LD	DE, (VBR_SECTOR + 2)
	; skip reserved sectors to find FAT
	ADD	HL, BC
	JR	NC, fat32_init_found_fat
	INC	DE
.fat32_init_found_fat
	; store FAT sector number
	LD	(FAT_SECTOR), HL
	LD	(FAT_SECTOR + 2), DE
	; calculate first cluster LBA
.fat32_init_calc_data_sector_loop
	LD	BC, (FAT_SIZE)
	ADD	HL, BC
	LD	BC, (FAT_SIZE + 2)
	EX	DE, HL
	ADC	HL, BC
	EX	DE, HL
	DEC	A ; <- contains FAT count
	JR	NZ, fat32_init_calc_data_sector_loop
	LD	(DATA_SECTOR), HL
	LD	(DATA_SECTOR + 2), DE
	RET

; scan directory entries
; DEHL contains directory LBA
; IY contains callback address
; callback:
; file name in FILE_NAME_BUFFER
; IX points to directory entry
; DE points to end of file name
; callback must retain IX and IY
.fat32_dir
	CALL	sdhc_read_block
	LD	IX, SDHC_BLOCK_BUFFER - 32
.fat32_dir_loop
	; eZ80: LEA IX, IX + 32
	DEFB	$ED, $32, 32
	; ignore volume labels (and LFN entries)
	BIT	DIR_ATTRIBUTE_BIT_VOLUME_LABEL, (IX + DIR_OFFSET_ATTRIBUTES)
	JR	NZ, fat32_dir_loop
	; check for deleted file
	LD	A, (IX + 0)
	CP	A, DIR_ENTRY_DELETED_MARKER
	JR	Z, fat32_dir_loop
	; check for end of list
	AND	A, A
	RET	Z
	PUSH	IX
	; get long file name (ASCII only)
	LD	DE, FILE_NAME_BUFFER
.fat32_dir_lfn_loop
	; eZ80: LEA IX, IX - 32
	DEFB	$ED, $32, -32
	; eZ80: LEA HL, IX + 1
	DEFB	$ED, $22, 1
	LD	C, $FF ; <- keeps LDI from decrementing B
	LD	B, 5
.fat32_dir_lfn_loop1
	LDI
	INC	HL ; ignore upper byte
	DJNZ	fat32_dir_lfn_loop1
	INC	HL ; skip 3 bytes
	INC	HL
	INC	HL
	LD	B, 6
.fat32_dir_lfn_loop2
	LDI
	INC	HL ; ignore upper byte
	DJNZ	fat32_dir_lfn_loop2
	INC	HL ; skip 2 bytes
	INC	HL
	; last two characters
	LDI
	INC	HL; ignore upper byte
	LDI
	; check for last LFN entry
	BIT	DIR_LFN_END_BIT, (IX + 0)
	JR	Z, fat32_dir_lfn_loop
	POP	IX
	XOR	A, A
	LD	(DE), A
	; callback
	LD	HL, fat32_dir_loop
	PUSH	HL
	JP	(IY)
