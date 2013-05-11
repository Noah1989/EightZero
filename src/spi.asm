; spi - serial peripheral interface driver

INCLUDE "spi.inc"

XREF output_sequence

XDEF spi_init
XDEF spi_select
XDEF spi_deselect
XDEF spi_wait
XDEF spi_slow
XDEF spi_fast
XDEF spi_transmit
XDEF spi_transmit_A
XDEF spi_transmit_A_nowait

DEFC PB_DR = $9A
DEFC PB_DDR = $9B
DEFC PB_ALT1 = $9C
DEFC PB_ALT2 = $9D
DEFC SPI_BRG_L = $B8
DEFC SPI_CTL = $BA
DEFC SPI_SR = $BB
DEFC SPI_TSR = $BC

; initialize PORTB for use with SPI
; pin usage:
; PIN: ALT2 ALT1 DDR DR - description
; 0: 0 1 0 1 - GPIO slave select for sdhc card (high, open drain)
; 1: 0 0 0 1 - GPIO slave select for gameduino (high, push/pull)
; 2: 1 0 1 1 - alternative / slave select input (always high)
; 3: 1 0 1 1 - alternative / SCK
; 4: 0 0 1 1 - GPIO input / unused
; 5: 0 0 1 1 - GPIO input / unused
; 6: 1 0 1 1 - alternative / MISO
; 7: 1 0 1 1 - alternative / MOSI

.spi_init
	LD	HL, spi_init_sequence
	LD	B, #end_spi_init_sequence-spi_init_sequence
	JP	output_sequence
	; RET optimized away by JP above

.spi_init_sequence
	; port configuration (see above)
	DEFB	PB_DR,   @11111111
	DEFB	PB_DDR,  @11111100
	DEFB	PB_ALT1, @00000001
	DEFB	PB_ALT2, @11001100
	; fastest possible SPI speed
	DEFB	SPI_BRG_L, $03
	; enable SPI: mode 0, master
	DEFB	SPI_CTL, $30
.end_spi_init_sequence

; slect SPI device
; A contains CS bits:
; $00 - none (does not wait! use spi_deselect instead)
; $01 - sdhc
; $02 - video
.spi_select
	; safety check
	CP	A, $03
	RET	NC
	; active low
	CPL	A
	; eZ80 instruction: OUT0 (PB_DR), A
	DEFB	$ED, $39, PB_DR
	RET

.spi_deselect
	CALL	spi_wait
	LD	A, $FF
	; eZ80 instruction: OUT0 (PB_DR), A
	DEFB	$ED, $39, PB_DR
	RET

; wait for SPI transaction to complete
; preserves all registers except A'
; this trashes F' but not F
.spi_wait
	EX	AF, AF'
	LD	A, C
	LD	C, SPI_SR
.spi_wait_loop
	; check for SPIF (bit 7 in SPI_SR)
	; eZ80 instruction: TSTIO $80
	DEFB	$ED, $74, $80
	; '0' means SPI transfer not finished
	JR	Z, spi_wait_loop
	LD	C, A
	EX	AF, AF'
	RET

; transfer byte via SPI
; HL points to the byte to write
.spi_transmit
	LD	A, (HL)
; same as above but takes value from A
.spi_transmit_A
	CALL	spi_wait
.spi_transmit_A_nowait
	; transmit data byte
	; eZ80 instruction: OUT0 (SPI_TSR), A
	DEFB	$ED, $39, SPI_TSR
	RET
