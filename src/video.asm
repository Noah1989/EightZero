; video - low level code for the gameduino video interface

XREF output_sequence

XDEF video_init
XDEF video_copy
XDEF video_fill
XDEF video_start_write
XDEF video_spi_transmit
XDEF video_spi_transmit_A
XDEF video_end_transfer
XDEF video_write
XDEF video_write_C
XDEF video_write_16
XDEF video_write_32

XDEF BG_COLOR
XDEF SCROLL_X
XDEF SCROLL_Y
XDEF PALETTE4A

XDEF RAM_PIC
XDEF RAM_CHR
XDEF RAM_PAL

XDEF RAM_SPR
XDEF RAM_SPRIMG

XDEF COLOR_A
XDEF COLOR_R
XDEF COLOR_G
XDEF COLOR_B

DEFC PB_DR = $9A
DEFC PB_DDR = $9B
DEFC PB_ALT2 = $9D
DEFC SPI_BRG_L = $B8
DEFC SPI_CTL = $BA
DEFC SPI_SR = $BB
DEFC SPI_TSR = $BC

DEFC BG_COLOR = $280E
DEFC SCROLL_X = $2804
DEFC SCROLL_Y = $2806
DEFC PALETTE4A = $2880

DEFC RAM_PIC = $0000
DEFC RAM_CHR = $1000
DEFC RAM_PAL = $2000

DEFC RAM_SPR = $3000
DEFC RAM_SPRIMG = $4000

DEFC COLOR_A = 2^15
DEFC COLOR_R = 2^10
DEFC COLOR_G = 2^5
DEFC COLOR_B = 2^0

; initialize PORTB and SPI
; pin usage:
; 0 - unused
; 1 - slave select for gameduino
; 2 - slave select input (always high)
; 3 - SCK
; 4 - unused
; 5 - unused
; 6 - MISO
; 7 - MOSI

.video_init
	LD	HL, video_init_sequence
	LD	B, #end_video_init_sequence-video_init_sequence
	CALL	output_sequence
.video_reset
	; background color
	LD	HL, bg_color_default
	LD	DE, BG_COLOR
	CALL	video_write_16
	; clear character RAM (64*64)
	LD	HL, clear_character
	LD	DE, RAM_PIC
	LD	BC, 64*64
	CALL	video_fill
	; hide all 256 sprites (on both pages) off screen
	; upper sprite control bits are set to zero
	LD	HL, sprite_offscreen_position
	LD	DE, RAM_SPR
	; 2 words per sprite, 256 sprites per page, 2 pages
	LD	BC, 2*256*2
	JR	video_fill_16
	;RET optimized away by JR above
.bg_color_default
	DEFW	@00000*COLOR_R | @00000*COLOR_G | @10000*COLOR_B
.clear_character
	DEFB	' '
.sprite_offscreen_position
	DEFW	400
.video_init_sequence
	; port configuration (see above)
	DEFB	PB_DR, $02
	DEFB	PB_DDR, $FD
	DEFB	PB_ALT2, $CC
	; fastest possible SPI speed
	DEFB	SPI_BRG_L, $03
	; enable SPI: mode 0, master
	DEFB	SPI_CTL, $30
.end_video_init_sequence

; wait for SPI transaction to complete
; preserves all registers except A'
; this trashes F' but not F
.video_spi_wait
	EX	AF, AF'
	LD	A, C
	LD	C, SPI_SR
.video_spi_wait_loop
	; check for SPIF (bit 7 in SPI_SR)
	; eZ80 instruction: TSTIO $80
	DEFB	$ED, $74, $80
	; '0' means SPI transfer not finished
	JR	Z, video_spi_wait_loop
	LD	C, A
	EX	AF, AF'
	RET

; start data write to video device
; DE contains the target address
.video_start_write
	; set address MSB to initiate write transaction
	LD	A, D
	OR	A, $80
	LD	D, A
	; bring slave select low (active)
	XOR	A, A
	; eZ80 instruction: OUT0 (PB_DR), A
	DEFB	$ED, $39, PB_DR
	; transmit address high byte
	; eZ80 instruction: OUT0 (SPI_TSR), D
	DEFB	$ED, $11, SPI_TSR
	CALL	video_spi_wait
	; transmit address low byte
	; eZ80 instruction: OUT0 (SPI_TSR), E
	DEFB	$ED, $19, SPI_TSR
	RET

; transfer byte to video device via SPI
; HL points to the byte to write
.video_spi_transmit
	LD	A, (HL)
; same as above but takes value from A
.video_spi_transmit_A
	CALL	video_spi_wait
	; transmit data byte
	; eZ80 instruction: OUT0 (SPI_TSR), A
	DEFB	$ED, $39, SPI_TSR
	RET

; end video read or write operation
.video_end_transfer
	CALL	video_spi_wait
	; bring slave select high (inactive)
	LD	A, $02
	; eZ80 instruction: OUT0 (PB_DR), A
	DEFB	$ED, $39, PB_DR
	RET

; write a single byte to video device
; DE contains the target address
; HL points to the byte to write
.video_write
	CALL	video_start_write
	CALL	video_spi_transmit
	JR	video_end_transfer
	;RET	optimized away by JR above

; write a single byte to video device
; DE contains the target address
; C contains the byte to write
.video_write_C
	CALL	video_start_write
	LD	A, C
	CALL	video_spi_transmit_A
	JR	video_end_transfer
	;RET	optimized away by JR above

; write 16-bit value to video device
; DE contains the target address
; HL points to the word to write
.video_write_16
	CALL	video_start_write
	CALL	video_spi_transmit
	INC	HL
	CALL	video_spi_transmit
	JR	video_end_transfer
	;RET	optimized away by JR above

; write 32-bit value to video device
; DE contains the target address
; HL points to the doubleword to write
.video_write_32
	CALL	video_start_write
	CALL	video_spi_transmit
	INC	HL
	CALL	video_spi_transmit
	INC	HL
	CALL	video_spi_transmit
	INC	HL
	CALL	video_spi_transmit
	JR	video_end_transfer
	;RET	optimized away by JR above


; fill video memory
; DE contains the fill start address
; HL points to the byte to fill with
; BC contains the number of bytes to write
.video_fill
	CALL	video_start_write
.video_fill_loop
	CALL	video_spi_transmit
	DEC	BC
	LD	A, B
	OR	A, C
	JR	NZ, video_fill_loop
	JR	video_end_transfer
	;RET	optimized away by JR above

; fill video memory with 16-bit values
; DE contains the fill start address
; HL points to the word to fill with
; BC contains the number of words to write
.video_fill_16
	CALL	video_start_write
.video_fill_16_loop
	CALL	video_spi_transmit
	INC	HL
	CALL	video_spi_transmit
	DEC	HL
	DEC	BC
	LD	A, B
	OR	A, C
	JR	NZ, video_fill_16_loop
	JR	video_end_transfer
	;RET	optimized away by JR above

; copy to video memory
; DE contains the target address
; HL points to the data to copy
; BC contains the number of bytes to copy
.video_copy
	CALL	video_start_write
.video_copy_loop
	CALL	video_spi_transmit
	INC	HL
	DEC	BC
	LD	A, B
	OR	A, C
	JR	NZ, video_copy_loop
	JR	video_end_transfer
	;RET	optimized away by JR above
