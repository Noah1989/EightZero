; eZ80 ASM file: unlock - unlocks the internal flash ROM

XREF output_sequence

XDEF unlock_flash

DEFC FLASH_KEY = $F5
DEFC FLASH_FDIV = $F9
DEFC FLASH_PROT = $FA
DEFC FLASH_PGCTL = $FF

.unlock_flash
	LD	HL, unlock_sequence
	LD	B, #end_unlock_sequence-unlock_sequence
	JP	output_sequence
	;RET

.unlock_sequence
	DEFB	FLASH_KEY, $B6
	DEFB	FLASH_KEY, $49
	DEFB	FLASH_FDIV, 51 ; 10 MHz * 5.1 µS
	DEFB	FLASH_KEY, $B6
	DEFB	FLASH_KEY, $49
	DEFB	FLASH_PROT, $00 ; unlock all pages
.end_unlock_sequence
	; manually increase sequence length above
	; by two bytes to perform a mass erase
	; (this requires this routine to be in RAM)
	DEFB	FLASH_PGCTL, $01 ; mass erase