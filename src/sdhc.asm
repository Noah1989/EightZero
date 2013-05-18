; eZ80 ASM file: sdhc - a sdhc card driver

INCLUDE "sdhc.inc"
INCLUDE "spi.inc"

XREF spi_slow
XREF spi_fast
XREF spi_select
XREF spi_wait
XREF spi_deselect
XREF spi_transmit_A
XREF spi_transmit_A_nowait
XREF spi_receive

XREF video_fill
XREF print_string

DEFC PB_DR = $9A

DEFC SD_GO_IDLE_STATE = 0

.sdhc_init
	; detect card in slot (pulls PIN 0 high)
	LD	C, PB_DR
	; eZ80 instruction: TSTIO $01
	DEFB	$ED, $74, $01
	JR	NZ, sdhc_init_card_detected
	CALL	sdhc_error
	DEFM	"No card in slot.", 0
.sdhc_init_card_detected
	CALL	spi_slow
	; select nothing
	XOR	A, A
	CALL	spi_select
	; 80 dummy clock pulses
	LD	B, 10
	LD	A, $FF
.sdhc_dummy_clock_loop
	CALL	spi_transmit_A
	DJNZ	sdhc_dummy_clock_loop
	; send go idle command
	LD	C, SD_GO_IDLE_STATE
	LD	DE, 0
	LD	HL, 0
	EXX
	LD	B, 0
.sdhc_go_idle_loop
	EXX
	CALL	sdhc_command
	; check if B == $01
	DEC	B
	JR	Z, sdhc_init_card_idle
	EXX
	DJNZ	sdhc_go_idle_loop
	EXX
	CALL	sdhc_error
	DEFM	"Card not responding.", 0
.sdhc_init_card_idle
	CALL	sdhc_error
	DEFM	"Not implemented.", 0

; send command to SDHC card
; C contains command
; DEHL contains argument
; returns response in B ($FF is timeout)
.sdhc_command
	; select card
	LD	A, SPI_CS_SDHC
	CALL	spi_select
	; send command
	LD	A, C
	OR	A, $40 ; <- first to bits are always '01'
	CALL	spi_transmit_A
	; send argument (big endian)
	LD	A, D
	CALL	spi_transmit_A
	LD	A, E
	CALL	spi_transmit_A
	LD	A, H
	CALL	spi_transmit_A
	LD	A, L
	CALL	spi_transmit_A
	; send CRC
	LD	A, $95 ; <- CRC for CMD0 (others ignore CRC)
	CALL	spi_transmit_A
	; wait for response
	LD	B, 0
.sdhc_command_wait_response
	CALL	spi_receive
	; check if A != $FF
	INC	A
	JR	NZ, sdhc_command_response_received
	DJNZ	sdhc_command_wait_response
.sdhc_command_response_received
	DEC	A
	LD	B, A
	CALL	spi_deselect
	; extra 8 clock cycles
	CALL	spi_receive
	RET

.sdhc_error
	; reset SPI speed
	CALL	spi_fast
	; clear line
	LD	HL, space_char
	LD	DE, 1*64
	LD	BC, 64
	CALL	video_fill
	; message is given inline
	POP	HL
	LD	IY, 1*64 + 1
	JP	print_string
	; exit to caller, note that we don't PUSH HL
	;RET optimized away by JP above

.space_char
	DEFB	$20