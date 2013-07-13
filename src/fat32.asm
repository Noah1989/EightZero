;eZ80 ASM file: fat32 - FAT32 file system implementation

INCLUDE "fat32.inc"

XREF sdhc_read_block

.read_mbr
	LD	DE, 0
	LD	HL, 0
	CALL	sdhc_read_block
	RET