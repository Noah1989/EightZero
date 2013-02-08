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

	; the status byte has to be interpreted like this:
	; $0B: getting parity bit
	; $0A: waiting for stop bit
	; $09: waiting for start bit <-default
	; $08..$01: getting data bits

	LD	A, $08
	CP	A, B
	; carry means that status greater than $08
	JR	C, keyboard_isr_get_frame_bit

	; get data bit
	LD	A, C
	LD	C, PA_DR
	; eZ80 instruction: TSTIO $01
	; note that this clears the carry flag
	DEFB	$ED, $74, $01
	JR	Z, keyboard_isr_data_bit_low
	SCF
.keyboard_isr_data_bit_low
	RRA
	LD	C, A
	;JR	keyboard_isr_next_status

.keyboard_isr_get_frame_bit
	; ... frame bits are currently ignored and not validated

.keyboard_isr_next_status
	DJNZ	keyboard_isr_end
	LD	B, $0B

.keyboard_isr_end
	; save data and status
	LD	(INTERRUPT_TABLE + KEYBOARD_ISR_DATA), BC
	; clear interrupt flag
	LD	A, $02
	; eZ80 instruction: OUT0 (PA_ALT0), A
	DEFB	$ED, $39, PA_ALT0
	; restore original state
	POP	BC
	POP	AF
	EI
	RETI
