;eZ80 ASM file: fat32 - FAT32 file system implementation

INCLUDE "fat32.inc"
INCLUDE "sdhc.inc"

XREF sdhc_read_block

XDEF fat32_init
XDEF fat32_dir
XDEF fat32_find
XDEF fat32_load

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

DEFC DIR_OFFSET_FILE_CLUSTER_L = $1A
DEFC DIR_OFFSET_FILE_CLUSTER_H = $14

DEFC DIR_OFFSET_FILE_SIZE = $1C

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
	LD	A, (SDHC_BLOCK_BUFFER + VBR_OFFSET_CLUSTER_SIZE)
	LD	(CLUSTER_SIZE), A
	; get number of FATs (used way below)
	LD	A, (SDHC_BLOCK_BUFFER + VBR_OFFSET_FAT_COUNT)
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

; load file into memory
; DEHL points to file LBA
; BC contains file size
.fat32_load
	EXX
	LD	DE, FILE_BUFFER
	EXX
	PUSH	HL
	PUSH	BC
.fat32_load_loop
	CALL	sdhc_read_block
	EXX
	LD	HL, SDHC_BLOCK_BUFFER
	LD	BC, 512
	; eZ80: LDIR
	DEFM	$ED, $B0
	EXX
	; calculate remaining file size
	AND	A, A ; clear carry flag
	LD	BC, 512
	POP	HL ; original BC value
	SBC	HL, BC
	JR	C, fat32_load_return ; file size reached
	POP	BC ; original HL value
	DEC	SP ; just peek
	DEC	SP
	PUSH	HL ; remaining file size
	; put original HL back
	LD	H, B
	LD	L, C
	; go to next block
	LD	BC, 1
	ADD	HL, BC
	JR	NC, fat32_load_loop
	INC	DE
	JR	fat32_load_loop
.fat32_load_return
	POP	HL ; tidy up stack

; find file by index in directory
; DEHL points to directory LBA
; B contains file index
; returns pointer to directory entry in IX
; returns LFN in FILE_NAME_BUFFER
; returns file size in BC
; returns file LBA in DEHL
.fat32_find
	INC	B
	LD	(CURRENT_BLOCK), HL
	LD	(CURRENT_BLOCK + 2), DE
	PUSH	BC
	JR	fat32_find_read_block
.fat32_find_next_block
	PUSH	BC
	LD	HL, (CURRENT_BLOCK)
	LD	DE, (CURRENT_BLOCK + 2)
	LD	BC, 1
	ADD	HL, BC
	JR	NC, fat32_find_read_block
	INC	DE
.fat32_find_read_block
	; store current value
	LD	(CURRENT_BLOCK), HL
	LD	(CURRENT_BLOCK + 2), DE
	; read single block
	CALL	sdhc_read_block
	LD	IX, SDHC_BLOCK_BUFFER - 32
	POP	BC
.fat32_find_loop
	; eZ80: LEA IX, IX + 32
	DEFB	$ED, $32, 32
	LD	A, SDHC_BLOCK_BUFFER / $100 + 2
	CP	A, IXH
	JR	Z, fat32_find_next_block
	; ignore volume labels (and LFN entries)
	BIT	DIR_ATTRIBUTE_BIT_VOLUME_LABEL, (IX + DIR_OFFSET_ATTRIBUTES)
	JR	NZ, fat32_find_loop
	; check for deleted file
	LD	A, (IX + 0)
	CP	A, DIR_ENTRY_DELETED_MARKER
	JR	Z, fat32_find_loop
	; check for end of list
	AND	A, A
	RET	Z ; oops, nothing found
	; skip no. of files in B
	DJNZ	fat32_find_loop
	PUSH	IX
	; get lfn
	CALL	fat32_get_lfn
	POP	IX
	; lfn found?
	XOR	A, A
	LD	HL, FILE_NAME_BUFFER
	CP	A, (HL)
	; get regular 8.3 name if not
	CALL	Z, fat32_get_8dot3_name
	; eZ80: LD HL, (IX + DIR_OFFSET_FILE_CLUSTER_L)
	DEFM	$DD, $27, DIR_OFFSET_FILE_CLUSTER_L
	; eZ80; LD DE, (IX + DIR_OFFSET_FILE_CLUSTER_H)
	DEFM	$DD, $17, DIR_OFFSET_FILE_CLUSTER_H
	; substract 2 from cluster number,
	; because first cluster is cluster 2
	AND	A, A ; clears carry flag
	LD	BC, 2
	SBC	HL, BC
	JR	NC, fat32_find_lba
	DEC	HL
.fat32_find_lba
	; multiply cluster by cluster size
	LD	A, (CLUSTER_SIZE) ; always 2^n
.fat32_find_lba_loop
	SRL	A
	JR	Z, fat32_find_lba_result
	ADD	HL, HL
	EX	DE, HL
	ADC	HL, HL
	EX	DE, HL
	JR	fat32_find_lba_loop
.fat32_find_lba_result
	; get absolute LBA
	LD	BC, (DATA_SECTOR)
	ADD	HL, BC
	EX	DE, HL
	LD	BC, (DATA_SECTOR + 2)
	ADC	HL, BC
	EX	DE, HL
.fat32_find_size
	; eZ80: LD BC, (IX + DIR_OFFSET_FILE_SIZE)
	DEFM	$DD, $07, DIR_OFFSET_FILE_SIZE
	RET

; scan directory entries
; DEHL contains directory LBA
; IY contains callback address
; callback:
; file name in FILE_NAME_BUFFER
; callback must retain IX and IY
.fat32_dir
	;reset file count
	XOR	A, A
	LD	(DIR_FILE_COUNT), A
	LD	(CURRENT_BLOCK), HL
	LD	(CURRENT_BLOCK + 2), DE
	JR	fat32_dir_read_block
.fat32_dir_next_block
	LD	HL, (CURRENT_BLOCK)
	LD	DE, (CURRENT_BLOCK + 2)
	LD	BC, 1
	ADD	HL, BC
	JR	NC, fat32_dir_read_block
	INC	DE
.fat32_dir_read_block
	; store current value
	LD	(CURRENT_BLOCK), HL
	LD	(CURRENT_BLOCK + 2), DE
	; read single block
	CALL	sdhc_read_block
	LD	IX, SDHC_BLOCK_BUFFER - 32
.fat32_dir_loop
	; eZ80: LEA IX, IX + 32
	DEFB	$ED, $32, 32
	LD	A, SDHC_BLOCK_BUFFER / $100 + 2
	CP	A, IXH
	JR	Z, fat32_dir_next_block
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
	; count files
	LD	HL, DIR_FILE_COUNT
	INC	(HL)
	; save pointer to original entry
	PUSH	IX
	; get lfn
	CALL	fat32_get_lfn
	POP	IX
	; lfn found?
	XOR	A, A
	LD	HL, FILE_NAME_BUFFER
	CP	A, (HL)
	; get regular 8.3 name if not
	CALL	Z, fat32_get_8dot3_name
	; callback
	LD	HL, fat32_dir_loop
	PUSH	HL
	JP	(IY)

.fat32_get_lfn
	; get long file name (ASCII only)
	LD	DE, FILE_NAME_BUFFER
.fat32_get_lfn_loop
	; eZ80: LEA IX, IX - 32
	DEFB	$ED, $32, -32
	LD	A, SDHC_BLOCK_BUFFER / $100 - 1
	CP	A, IXH
	CALL	Z, fat32_get_lfn_rewind_block
	LD	A, (IX + DIR_OFFSET_ATTRIBUTES)
	; return if there is no LFN entry here
	AND	A, $0F
	CP	A, $0F
	JR	NZ, fat32_get_lfn_return
	; eZ80: LEA HL, IX + 1
	DEFB	$ED, $22, 1
	LD	C, $FF ; <- keeps LDI from decrementing B
	LD	B, 5
.fat32_get_lfn_loop1
	LDI
	INC	HL ; ignore upper byte
	DJNZ	fat32_get_lfn_loop1
	INC	HL ; skip 3 bytes
	INC	HL
	INC	HL
	LD	B, 6
.fat32_get_lfn_loop2
	LDI
	INC	HL ; ignore upper byte
	DJNZ	fat32_get_lfn_loop2
	INC	HL ; skip 2 bytes
	INC	HL
	; last two characters
	LDI
	INC	HL; ignore upper byte
	LDI
	; check for last LFN entry
	BIT	DIR_LFN_END_BIT, (IX + 0)
	JR	Z, fat32_get_lfn_loop
.fat32_get_lfn_return
	; add zero byte to end of string
	XOR	A, A
	LD	(DE), A
	; read original block
	LD	HL, (CURRENT_BLOCK)
	LD	DE, (CURRENT_BLOCK + 2)
	JP	sdhc_read_block
	;RET optimized away by JP above

.fat32_get_lfn_rewind_block
	PUSH	DE
	LD	HL, (CURRENT_BLOCK)
	LD	DE, (CURRENT_BLOCK + 2)
	LD	BC, 1
	AND	A, A ; clear carry
	SBC	HL, BC
	JR	NC, fat32_get_lfn_rewind_read
	DEC	DE
.fat32_get_lfn_rewind_read
	CALL	sdhc_read_block
	LD	IX, SDHC_BLOCK_BUFFER + 512 - 32
	POP	DE
	RET

.fat32_get_8dot3_name
	LD	DE, FILE_NAME_BUFFER
	; eZ80: LEA HL, IX + 0
	DEFB	$ED, $22, 0
	LD	BC, 8
	LDIR
.fat32_get_8dot3_name_unpad
	DEC	DE
	LD	A, (DE)
	CP	A, ' '
	JR	Z, fat32_get_8dot3_name_unpad
	INC	DE
	EX	DE, HL
	LD	(HL), '.'
	EX	DE, HL
	INC	DE
	LD	BC, 3
	LDIR
	XOR	A, A
	LD	(DE), A
	RET