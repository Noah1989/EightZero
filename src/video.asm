; eZ80 ASM file: video - low level code for the gameduino video interface

INCLUDE "video.inc"
INCLUDE "spi.inc"

XREF output_sequence
XREF spi_select
XREF spi_deselect
XREF spi_transmit
XREF spi_transmit_A
XREF spi_transmit_A_nowait

XDEF video_init
XDEF video_reset
XDEF video_copy
XDEF video_fill
XDEF video_start_write
XDEF video_write
XDEF video_write_C
XDEF video_write_16
XDEF video_write_32

.video_reset
	; background color
	LD	HL, bg_color_default
	LD	DE, BG_COLOR
	CALL	video_write_16
	; reset scroll position
	LD	HL, zerobyte
	LD	DE, SCROLL_X
	LD	BC, 2*2 ; 2 words
	CALL	video_fill
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
	DEFW	@00000*COLOR_R | @01100*COLOR_G | @01000*COLOR_B
.clear_character
	DEFB	' '
.sprite_offscreen_position
	DEFW	400
.zerobyte
	DEFB	0

; start data write to video device
; DE contains the target address
.video_start_write
	; set address MSB to initiate write transaction
	LD	A, D
	OR	A, $80
	LD	D, A
	; bring slave select low (active)
	LD	A, SPI_CS_VIDEO
	CALL	spi_select
	LD	A, D
	CALL	spi_transmit_A
	LD	A, E
	JP	spi_transmit_A
	; RET optimized away by JP above

; write a single byte to video device
; DE contains the target address
; HL points to the byte to write
.video_write
	CALL	video_start_write
	CALL	spi_transmit
	JP	spi_deselect
	;RET	optimized away by JP above

; write a single byte to video device
; DE contains the target address
; C contains the byte to write
.video_write_C
	CALL	video_start_write
	LD	A, C
	CALL	spi_transmit_A
	JP	spi_deselect
	;RET	optimized away by JP above

; write 16-bit value to video device
; DE contains the target address
; HL points to the word to write
.video_write_16
	CALL	video_start_write
	CALL	spi_transmit
	INC	HL
	CALL	spi_transmit
	JP	spi_deselect
	;RET	optimized away by JP above

; write 32-bit value to video device
; DE contains the target address
; HL points to the doubleword to write
.video_write_32
	CALL	video_start_write
	CALL	spi_transmit
	INC	HL
	CALL	spi_transmit
	INC	HL
	CALL	spi_transmit
	INC	HL
	CALL	spi_transmit
	JP	spi_deselect
	;RET	optimized away by JP above

; fill video memory
; DE contains the fill start address
; HL points to the byte to fill with
; BC contains the number of bytes to write
.video_fill
	CALL	video_start_write
.video_fill_loop
	CALL	spi_transmit
	DEC	BC
	LD	A, B
	OR	A, C
	JR	NZ, video_fill_loop
	JP	spi_deselect
	;RET	optimized away by JP above

; fill video memory with 16-bit values
; DE contains the fill start address
; HL points to the word to fill with
; BC contains the number of words to write
.video_fill_16
	CALL	video_start_write
.video_fill_16_loop
	CALL	spi_transmit
	INC	HL
	CALL	spi_transmit
	DEC	HL
	DEC	BC
	LD	A, B
	OR	A, C
	JR	NZ, video_fill_16_loop
	JP	spi_deselect
	;RET	optimized away by JP above

; copy to video memory
; DE contains the target address
; HL points to the data to copy
; BC contains the number of bytes to copy
.video_copy
	CALL	video_start_write
.video_copy_loop
	CALL	spi_transmit
	INC	HL
	DEC	BC
	LD	A, B
	OR	A, C
	JR	NZ, video_copy_loop
	JP	spi_deselect
	;RET	optimized away by JP above
