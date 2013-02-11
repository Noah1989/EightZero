; keyboard - a keyboard input driver

XREF output_sequence

XREF INTERRUPT_TABLE

XDEF keyboard_init

XDEF KEYBOARD_ISR_DATA

DEFC INT_PORT_A1 = $84
; only the lower two bytes of the interrupt vector table entry are used
; so we can use the other two to store some data between interrupts
; this works as long as the interrupt table remains in RAM (which it should)
DEFC KEYBOARD_ISR_DATA = $86

DEFC PA_DR = $96
DEFC PA_DDR = $97
DEFC PA_ALT1 = $98
DEFC PA_ALT2 = $99
DEFC PA_ALT0 = $A6

.keyboard_init
	; set interrupt vector
	LD	HL, keyboard_isr
	LD	(INTERRUPT_TABLE + INT_PORT_A1), HL
	LD	HL, $0900
	LD	(INTERRUPT_TABLE + KEYBOARD_ISR_DATA), HL
	; initialize port pins
	LD	HL, keyboard_init_sequence
	LD	B, #end_keyboard_init_sequence-keyboard_init_sequence
	JP	output_sequence
	;RET	optimized away by JP above
.keyboard_init_sequence
	; falling edge triggered interrupt
	; on PORT A pin 1, all others are inputs
	DEFB	PA_DR, $00
	DEFB	PA_ALT2, $02
	DEFB	PA_ALT1, $02
	DEFB	PA_DDR, $FF
.end_keyboard_init_sequence

	; this routine is called on every incoming bit from the keyboard
.keyboard_isr
	; save registers
	PUSH	AF
	PUSH	BC

	; B: status; C: incoming byte
	LD	BC, (INTERRUPT_TABLE + KEYBOARD_ISR_DATA)

	; the lower nibble of the status byte
	; has to be interpreted like this:
	; $B: getting parity bit
	; $A: waiting for stop bit
	; $9: waiting for start bit <-default
	; $8..$1: getting data bits

	LD	A, B
	AND	A, $0F
	CP	A, $09
	; if status is greater than or equal to $9
	JR	NC, keyboard_isr_get_frame_bit

.keyboard_isr_get_data_bit
	; get data bit
	; C gets copied to A to make place for the TSTIO argument in C
	; we need the data byte in A anyways, due to the use of RAA below
	LD	A, C
	LD	C, PA_DR
	; eZ80 instruction: TSTIO $01
	; note that this clears the carry flag
	DEFB	$ED, $74, $01
	JR	Z, keyboard_isr_get_data_bit_low
.keyboard_isr_get_data_bit_high
	SCF
.keyboard_isr_get_data_bit_low
	RRA
	JR	keyboard_isr_next_status

.keyboard_isr_get_frame_bit
	LD	A, B
	AND	A, $0F
	CP	A, $0A
	; save data byte in A and set up C for the TSTIO coming later
	; note that LD does not affect the flags set by CP above
	LD	A, C
	LD	C, PA_DR
	; if status is equal to $A ($A = stop bit)
	JR	Z, keyboard_isr_get_stop_bit
	; if status is greater than $A ($B = parity bit)
	JR	NC, keyboard_isr_get_parity_bit
	; if status is less than $A ($9 = start bit)
.keyboard_isr_get_start_bit
	; eZ80 instruction: TSTIO $01
	DEFB	$ED, $74, $01
	; detect frame error (start bit should be 0)
	JR	NZ, keyboard_isr_frame_error
	JR	keyboard_isr_next_status
.keyboard_isr_get_parity_bit
	; get parity of data byte
	; note that the data byte is already in A
	OR	A, A
	; if the parity of the data byte is odd,
	; the parity bit should be 0, just like a start bit
	JP	PO, keyboard_isr_get_start_bit
	; otherwise we fall through to checking for a 1 (like a stop bit)
.keyboard_isr_get_stop_bit
	; eZ80 instruction: TSTIO $01
	DEFB	$ED, $74, $01
	; detect frame error (stop bit should be 1)
	JR	Z, keyboard_isr_frame_error
	;JR	keyboard_isr_next status

.keyboard_isr_next_status
	; get data byte back into C
	; note that both the data and frame bit routines put it in A
	LD	C, A
	; test if lower nibble of B equals zero
	DEC	B
	LD	A, B
	; eZ80 instruction: TST	A, $0F
	DEFB	$ED, $64, $0F
	; if not, we're done here
	JR	NZ, keyboard_isr_end_nowrap
	; if it is zero, wrap around
	; set lower nibble of B (status) to $B
	; note that this marks the end of the data byte receive
	; but not the end of the frame (parity and stop bit are following)
	AND	A, $F0
	OR	A, $0B
	LD	B, A
	; we can just skip the code below, because status is always $B here
	JR	keyboard_isr_return
.keyboard_isr_end_nowrap
	; check if we are at the beginning again
	; note that A still has a copy of B here
	; if yes, process the received scancode
	AND	A, $0F
	CP	A, $09
	JR	Z, keyboard_isr_scancode_received
.keyboard_isr_return
	; save data and status
	LD	(INTERRUPT_TABLE + KEYBOARD_ISR_DATA), BC
	; clear interrupt flag
	LD	A, $02
	; eZ80 instruction: OUT0 (PA_ALT0), A
	DEFB	$ED, $39, PA_ALT0
	; restore original state and return
	POP	BC
	POP	AF
	EI
	RETI

.keyboard_isr_frame_error
	; if we end up here, just start over waiting for a start bit
	; this also clears the upper status bits, which is OK
	LD	B, $09
	JR	keyboard_isr_return

.keyboard_isr_scancode_received
	; process a received scancode
	LD	B, $F9; <- just a test...
	JR	keyboard_isr_return
