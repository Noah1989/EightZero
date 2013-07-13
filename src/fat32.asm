;eZ80 ASM file: fat32 - FAT32 file system implementation

INCLUDE "fat32.inc"
INCLUDE "sdhc.inc"

XREF sdhc_read_block

; locations for global variables
DEFC VBR_SECTOR   = $FB00 ; 4 bytes
DEFC FAT_SECTOR   = $FB04 ; 4 bytes
DEFC DATA_SECTOR  = $FB08 ; 4 bytes
DEFC FAT_SIZE     = $FB0C ; 4 bytes
DEFC CLUSTER_SIZE = $FB10 ; 1 byte

DEFC MBR_OFFSET_PARTITION1_LBA = $1C6
DEFC VBR_OFFSET_RESERVED_SECTOR_COUNT = $0E
DEFC VBR_OFFSET_FAT_COUNT = $10
DEFC VBR_OFFSET_FAT_SIZE = $24
DEFC VBR_OFFSET_CLUSTER_SIZE = $0D

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
	; read some data (test)
	CALL	sdhc_read_block
	RET