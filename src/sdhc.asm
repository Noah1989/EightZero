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

XDEF sdhc_init
XDEF sdhc_read_block

DEFC PB_DR = $9A

DEFC SD_GO_IDLE_STATE = 0
DEFC SD_SEND_IF_COND = 8
DEFC SD_READ_SINGLE_BLOCK = 17
DEFC SD_APP_CMD = 55
DEFC SD_APP_SEND_OP_COND = 41

; initialize SDHC card
; returns with carry flag cleared on success
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
.sdhc_init_dummy_clock_loop
	CALL	spi_transmit_A
	DJNZ	sdhc_init_dummy_clock_loop
	; send CMD0 (GO_IDLE_STATE)
	LD	C, SD_GO_IDLE_STATE
	LD	DE, 0
	LD	HL, 0
	EXX
	LD	B, 0
.sdhc_init_go_idle_loop
	EXX
	CALL	sdhc_command
	; check if B == $01
	DEC	B
	JR	Z, sdhc_init_card_idle
	EXX
	DJNZ	sdhc_init_go_idle_loop
	EXX
	CALL	sdhc_error
	DEFM	"Card not responding.", 0
.sdhc_init_card_idle
	; send CMD8 (SEND_IF_COND)
	LD	C, SD_SEND_IF_COND
	LD	DE, $0000
	LD	HL, $01AA
	EXX
	LD	B, 0
.sdhc_init_send_if_cond_loop
	EXX
	CALL	sdhc_command
	; check if B == $01
	DEC	B
	JR	Z, sdhc_init_send_op_cond
	EXX
	DJNZ	sdhc_init_send_if_cond_loop
	EXX
	CALL	sdhc_error
	DEFM	"Not an SDHC 2.0 card.", 0
.sdhc_init_send_op_cond
	; send ACMD 41 (SEND_OP_COND)
	LD	C, SD_APP_SEND_OP_COND
	LD	DE, $4000 ; HCS bit set
	LD	HL, $0000
	EXX
	LD	B, 0
.sdhc_init_send_op_cond_loop
	EXX
	CALL	sdhc_app_command
	; check if B == $00
	INC	B
	DEC	B
	JR	Z, sdhc_init_card_ready
	EXX
	DJNZ	sdhc_init_send_op_cond_loop
	EXX
	CALL	sdhc_error
	DEFM	"Could not initialize card.", 0
.sdhc_init_card_ready
	; SD card can now operate at full speed
	CALL	spi_fast
	; clear carry flag to indicate success
	XOR	A, A
	RET

; read block from SDHC card
; DEHL contains block address
.sdhc_read_block
	LD	C, SD_READ_SINGLE_BLOCK
	CALL	sdhc_command
	; check if B == 0 (success)
	INC	B
	DEC	B
	JR	Z, sdhc_read_block_ready
	CALL	sdhc_error
	DEFM	"Cannot read block.", 0
.sdhc_read_block_ready
	; wait for start block token ($FE)
	LD	A, SPI_CS_SDHC
	CALL	spi_select
	LD	BC, 0
.sdhc_read_block_wait_loop
	CALL	spi_receive
	CP	A, $FE
	JR	Z, sdhc_read_block_receive
	DEC	BC
	LD	A, B
	OR	A, C
	JR	NZ, sdhc_read_block_wait_loop
	; timout
	CALL	spi_deselect
	; extra 8 clock cycles
	CALL	spi_receive
	CALL	sdhc_error
	DEFM	"Timeout reading block", 0
.sdhc_read_block_receive
	LD	HL, SDHC_BLOCK_BUFFER
	LD	BC, 512
.sdhc_read_block_receive_loop
	CALL	spi_receive
	LD	(HL), A
	INC	HL
	DEC	BC
	LD	A, B
	OR	A, C
	JR	NZ, sdhc_read_block_receive_loop
	; ignore CRC (16 bit)
	CALL	spi_receive
	CALL	spi_receive
	; deselect card
	CALL	spi_deselect
	; extra 8 clock cycles
	CALL	spi_receive
	; clear carry flag to indicate success
	XOR	A, A
	RET

; send app command to SDHC
; sends CMD55, then falls through to sdhc_command
.sdhc_app_command
	; select card
	LD	A, SPI_CS_SDHC
	CALL	spi_select
	; send command
	LD	A, 55 | $40 ; <- first to bits are always '01'
	CALL	spi_transmit_A
	; send argument (0)
	XOR	A, A
	CALL	spi_transmit_A
	CALL	spi_transmit_A
	CALL	spi_transmit_A
	CALL	spi_transmit_A
	; send CRC
	CALL	spi_transmit_A
	; wait for response
	LD	B, 0
.sdhc_app_command_wait_response
	CALL	spi_receive
	; check if A != $FF
	INC	A
	JR	NZ, sdhc_app_command_response_received
	DJNZ	sdhc_app_command_wait_response
	; timeout...
	DEC	A
	LD	B, A
	RET
.sdhc_app_command_response_received
	; response is not used
	CALL	spi_deselect
	; extra 8 clock cycles
	CALL	spi_receive
	; fall through
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
	LD	A, C
	CP	A, SD_SEND_IF_COND
	JR	NZ, sdhc_command_crc0
.sdhc_connand_crc8
	LD	A, $87 ; <- CRC for CMD8
	DEFB	$C2 ; <- JP NZ, xxxx skips the next two bytes
.sdhc_command_crc0
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
	; falling through here will return $FF (timeout)
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
	CALL	print_string
	; carry flag indicates error
	SCF
	; exit to caller, note that we don't PUSH HL
	RET

.space_char
	DEFB	$20