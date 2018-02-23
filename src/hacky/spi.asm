; eZ80 ASM file: spi - serial peripheral interface driver

INCLUDE "spi.inc"
INCLUDE "main.inc"

XREF output_sequence

XDEF spi_init
XDEF spi_select
XDEF spi_deselect
XDEF spi_slow
XDEF spi_fast
XDEF spi_transmit
XDEF spi_transmit_A
XDEF spi_receive

DEFC INT_SPI = $7C
; two unused bytes in interrupt vector table
DEFC SPI_ISR_STATUS = $7E
DEFC SPI_ISR_BUFFER = $7F

DEFC PB_DR = $9A
DEFC PB_DDR = $9B
DEFC PB_ALT1 = $9C
DEFC PB_ALT2 = $9D
DEFC SPI_BRG_L = $B8
DEFC SPI_CTL = $BA
DEFC SPI_SR = $BB
DEFC SPI_TSR = $BC
DEFC SPI_RBR = $BC

; SPI mode 0, master, interrupt enabled
DEFC SPI_MODE = @10110000

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
	;set interrupt vector
	LD	HL, spi_isr
	LD	(INTERRUPT_TABLE + INT_SPI), HL
	LD	HL, $000
	LD	(INTERRUPT_TABLE + SPI_ISR_STATUS), HL
	; initialize port / SPI
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
	DEFB	SPI_BRG_L, 3
	; enable SPI: mode 0, master, enable interrupt
	DEFB	SPI_CTL, SPI_MODE
.end_spi_init_sequence

; set SPI speed to 125kHz (assuming 10MHz system clock)
.spi_slow
	; deselect and disable SPI
	CALL	spi_deselect
	LD	A, 0
	; eZ80 instruction: OUT0 (SPI_CTL), A
	DEFB	$ED, $39, SPI_CTL
	; set baud rate
	LD	A, 40
	; eZ80 instruction: OUT0 (SPI_BRG_L), A
	DEFB	$ED, $39, SPI_BRG_L
	; re-enable SPI
	LD	A, SPI_MODE
	; eZ80 instruction: OUT0 (SPI_CTL), A
	DEFB	$ED, $39, SPI_CTL
	RET

; set SPI speed to fastest possible value
.spi_fast
	; deselect and disable SPI
	CALL	spi_deselect
	LD	A, 0
	; eZ80 instruction: OUT0 (SPI_CTL), A
	DEFB	$ED, $39, SPI_CTL
	; set baud rate
	LD	A, 3
	; eZ80 instruction: OUT0 (SPI_BRG_L), A
	DEFB	$ED, $39, SPI_BRG_L
	; re-enable SPI
	LD	A, SPI_MODE
	; eZ80 instruction: OUT0 (SPI_CTL), A
	DEFB	$ED, $39, SPI_CTL
	RET

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

; wait until transfer complete and deselect SPI device
.spi_deselect
	LD	A, (INTERRUPT_TABLE + SPI_ISR_STATUS)
	AND	A, A
	JR	NZ, spi_deselect
	LD	A, $FF
	; eZ80 instruction: OUT0 (PB_DR), A
	DEFB	$ED, $39, PB_DR
	RET

; transmit byte via SPI
; HL points to the byte to write
.spi_transmit
	LD	A, (HL)
; same as above but takes value from A
.spi_transmit_A
	EX	AF, AF'
	; wait until buffer is empty
.spi_transmit_wait
	DI
	LD	A, (INTERRUPT_TABLE + SPI_ISR_STATUS)
	; test staus
	; $00: buffer empty, spi transfer complete
	; $01: buffer empty, spi transfer in progress
	; $02; buffer full
	CP	A, $01
	; transfer immediately, if possible
	JR	C, spi_transmit_out
	; put byte on buffer, if possible
	JR	Z, spi_transmit_buffer
	; else wait...
	EI
	JR	spi_transmit_wait
.spi_transmit_buffer
	INC	A
	LD	(INTERRUPT_TABLE + SPI_ISR_STATUS), A
	EX	AF, AF'
	LD	(INTERRUPT_TABLE + SPI_ISR_BUFFER), A
	EI
	RET
.spi_transmit_out
	INC	A
	LD	(INTERRUPT_TABLE + SPI_ISR_STATUS), A
	EX	AF, AF'
	; transmit data byte
	; eZ80 instruction: OUT0 (SPI_TSR), A
	DEFB	$ED, $39, SPI_TSR
	EI
	RET

.spi_receive
	; transmit dummy data
	LD	A, $FF
	CALL	spi_transmit_A
	; wait for transfer complete
.spi_receive_wait
	LD	A, (INTERRUPT_TABLE + SPI_ISR_STATUS)
	AND	A, A
	JR	NZ, spi_receive_wait
	; get byte
	; eZ80 instruction: IN0 A, (SPI_RBR)
	DEFB	$ED, $38, SPI_RBR
	RET

; SPI interrupt service routine
.spi_isr
	;save registers
	PUSH	AF
	; get and decrement status
	LD	A, (INTERRUPT_TABLE + SPI_ISR_STATUS)
	DEC	A
	LD	(INTERRUPT_TABLE + SPI_ISR_STATUS), A
	; if status is zero now,
	; there is nothing in the buffer to transmit
	JR	Z, spi_isr_return
.spi_isr_transmit
	; transmit byte in buffer
	LD	A, (INTERRUPT_TABLE + SPI_ISR_BUFFER)
	; eZ80 instruction: OUT0 (SPI_TSR), A
	DEFB	$ED, $39, SPI_TSR
.spi_isr_return
	; clear SPI flags by reading SPI_SR
	; eZ80 instruction: IN0 A, (SPI_SR)
	DEFB	$ED, $38, SPI_SR
	; check for write collision
	; this can happen at slow SPI speeds
	AND	A, @01000000
	JR	NZ, spi_isr_transmit
	; restore registers
	POP	AF
	EI
	RETI