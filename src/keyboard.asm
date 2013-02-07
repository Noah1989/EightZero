; keyboard - a keyboard input driver

XREF output_sequence

XREF INTERRUPT_TABLE

XDEF keyboard_init

DEFC INT_PORT_A1 = $84
; only the lower two bytes of the interrupt vector table entry are used
; so we can use the other two to store some data between interrupts
; this works as long as the interrupt table remains in RAM (which it should)
DEFC KEYBOARD_ISR_DATA = $86

DEFC PA_DR = $96
DEFC PA_DDR = $97
DEFC PA_ALT1 = $98
DEFC PA_ALT2 = $99

.keyboard_init
	; set interrupt vector
	LD	HL, keyboard_isr
	LD	(INTERRUPT_TABLE + INT_PORT_A1), HL
	LD	HL, $0800
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
	; $0A: getting parity bit
	; $09: waiting for stop bit
	; $08: waiting for start bit <-default
	; $07..$00: getting data bits

	LD	A, $07
	CP	A, B
	; no carry means that status is not greater than 7
	JR	NC, keyboard_isr_get_data_bit

	;...

.keyboard_isr_get_data_bit
	;...

	; restore original state
	POP	BC
	POP	AF
	EI
	RETI
