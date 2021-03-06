; eZ80 ASM file: keyboard - a keyboard input driver

INCLUDE "keyboard.inc"
INCLUDE "main.inc"

XREF output_sequence

XDEF keyboard_init
XDEF keyboard_getchar

DEFC INT_PORT_A1 = $84
; Only the lower two bytes of the interrupt vector table entry are used,
; so we can use the other two to store some data between interrupts.
; This works as long as the interrupt table remains in RAM (which it should).
DEFC KEYBOARD_ISR_DATA = $86
; There are two bytes that are used by this driver. The upper byte contains
; the current status for both serial and scancode decoding. It can be used to
; determine if the lower byte contains a valid decoded key. If the 6 least
; significant bits of the status byte are not equal to $09, the routine is
; either waiting for more bits on the serial data stream or the remainder of an
; extended or key up scancode. The two most significant bits track the status
; of the control and shift modifiers.
; These bytes should only be accessed through keyboard_getchar which returns
; either an ASCII character, or a contol sequence, or a special key character,
; or 0 when there is no data available.

DEFC PA_DR   = $96
DEFC PA_DDR  = $97
DEFC PA_ALT1 = $98
DEFC PA_ALT2 = $99
DEFC PA_ALT0 = $A6
DEFC INT_P2  = $12

; upper status bits
DEFC KEYBOARD_CONTROL = 7
DEFC KEYBOARD_SHIFT = 6
DEFC KEYBOARD_KEYUP = 5
DEFC KEYBOARD_EXTENDED = 4

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
	; on PORT A pin 1, debug out on pin 3,
	; all others are inputs
	DEFB	PA_DR,   @00000000
	DEFB	PA_ALT2, @00000010
	DEFB	PA_ALT1, @00000010
	DEFB	PA_DDR,  @11111011
	; increase PORT A 1 interrupt priority
	DEFB	INT_P2,  @00000010
.end_keyboard_init_sequence

; returns a decoded character from the keyboard in C
; returns 0 when there are no characters to get
; trashes A and B
.keyboard_getchar
	LD	BC, (INTERRUPT_TABLE + KEYBOARD_ISR_DATA)
	; check 6 least significant bits against $09
	LD	A, B
	AND	A, $3F
	CP	A, $09
	; if the data is not valid, return 0
	JR	NZ, keyboard_getchar_fail
	; okay, the byte is valid, clear the buffer
	XOR	A, A
	LD	(INTERRUPT_TABLE + KEYBOARD_ISR_DATA), A
	RET
.keyboard_getchar_fail
	LD	C, 0
	RET

; this routine is called on every incoming bit from the keyboard
.keyboard_isr
	; save registers
	PUSH	AF
	PUSH	BC

	; for debugging
	LD	A, @00000100
	; eZ80 instruction: OUT0 (PA_DR), A
	DEFM	$ED, $39, PA_DR

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
	; next status
	DEC	B
	; test if lower nibble of B equals zero
	LD	A, B
	; eZ80 instruction: TST	A, $0F
	DEFB	$ED, $64, $0F
	; if not, we don't need to handle a wraparound
	JR	NZ, keyboard_isr_end_nowrap
	; if it is zero, wrap around
	; set lower nibble of B (status) to $B
	; note that this marks the end of the data byte receive
	; but not the end of the frame (parity and stop bit are following)
	AND	A, $F0
	OR	A, $0B
	LD	B, A
	JR	keyboard_isr_return

.keyboard_isr_frame_error
	; if we end up here, just start over waiting for a start bit
	; this also clears the upper status bits, which is OK
	LD	B, $09
	JR	keyboard_isr_return

.keyboard_isr_end_nowrap
	; check if we are at the beginning again
	; note that A still has a copy of B here
	; if yes, process the received scancode
	AND	A, $0F
	CP	A, $09
	; if not at the beginning, then return
	JR	NZ, keyboard_isr_return
	; fall through
.keyboard_isr_scancode_received
	; process a received scancode
	; check for keyup
	LD	A, $F0
	CP	A, C
	JR	Z, keyboard_isr_scancode_received_keyup
	; check for extended code (start)
	LD	A, $E0
	CP	A, C
	JR	Z, keyboard_isr_scancode_received_extended_start
	; check control here because we don't need to differentiate between
	; left control ($14) and right control ($E0 $14)
	LD	A, $14
	CP	A, C
	JR	Z, keyboard_isr_scancode_received_control
	; is this the second byte of an extended keycode?
	BIT	KEYBOARD_EXTENDED, B
	JR	NZ, keyboard_isr_scancode_received_decode_extended
	; so this must be a regular one byte scancode
	; left shift
	LD	A, $12
	CP	A, C
	JR	Z, keyboard_isr_scancode_received_shift
	; right shift
	LD	A, $59
	CP	A, C
	JR	Z, keyboard_isr_scancode_received_shift
	; now we checked all regular scancodes for wich a key up is relevant
	; for all the others, it is just ignored
	BIT	KEYBOARD_KEYUP, B
	JR	NZ, keyboard_isr_scancode_received_ignore_keyup
	; F7 (weird code is outside the table)
	LD	A, $83
	CP	A, C
	JR	Z, keyboard_isr_scancode_received_F7
	; save HL here (remember, this is still inside the interrupt handler)
	PUSH	HL
	; use shifted table?
	BIT	KEYBOARD_SHIFT, B
	JR	NZ, keyboard_isr_scancode_received_decode_shifted
	; use regular code table
.keyboard_isr_scancode_received_decode_regular
	; the table starts with sancode $01
	LD	HL, keyboard_isr_scancode_table - $01
	JR	keyboard_isr_scancode_received_decode_lookup
	; use shifted code table
.keyboard_isr_scancode_received_decode_shifted
	; the table starts with sancode $01
	LD	HL, keyboard_isr_scancode_table_shifted - $01
	JR	keyboard_isr_scancode_received_decode_lookup
	; use extended code table
.keyboard_isr_scancode_received_decode_extended
	; remove the extended bit (if we are here, it got used)
	RES	KEYBOARD_EXTENDED, B
	; key up is irrelevant for keycodes processed here
	BIT	KEYBOARD_KEYUP, B
	JR	NZ, keyboard_isr_scancode_received_ignore_keyup
	; save HL, get byte from table
	PUSH	HL
	; the table starts with sancode $4A
	LD	HL, keyboard_isr_scancode_table_extended - $4A
	; fall through to common lookup code
.keyboard_isr_scancode_received_decode_lookup
	; we just want to add C to HL, so we put B away for a moment
	LD	A, B
	LD	B, 0
	ADD	HL, BC
	LD	C, (HL)
	LD	B, A
	; don't forget to restore HL ;-)
	POP	HL
	; and we're (almost) done. C now contains the decoded key code
.keyboard_isr_scancode_received_decoded
	; handle control modifier
	BIT	KEYBOARD_CONTROL, B
	JR	Z, keyboard_isr_return
	; make control sequence
	LD	A, C
	AND	A, $1F
	LD	C, A
	; (fall through) JR keyboard_isr_return

	; this is buried here in the middle because it's being jumped to
	; from all over the place with JR which can only jump 127 bytes
.keyboard_isr_return
	; save data and status
	LD	(INTERRUPT_TABLE + KEYBOARD_ISR_DATA), BC
	; clear interrupt flag
	LD	A, $02
	; eZ80 instruction: OUT0 (PA_ALT0), A
	DEFB	$ED, $39, PA_ALT0

	; for debugging
	XOR	A, A
	; eZ80 instruction: OUT0 (PA_DR), A
	DEFM	$ED, $39, PA_DR

	; restore original state and return
	POP	BC
	POP	AF
	EI
	RETI

.keyboard_isr_scancode_received_keyup
	SET	KEYBOARD_KEYUP, B
	JR	keyboard_isr_return

.keyboard_isr_scancode_received_ignore_keyup
	RES	KEYBOARD_KEYUP, B
	; also discard the data byte
	LD	C, 0
	JR	keyboard_isr_return

.keyboard_isr_scancode_received_extended_start
	SET	KEYBOARD_EXTENDED, B
	JR	keyboard_isr_return

.keyboard_isr_scancode_received_shift
	; remove the data byte because it has been processed now
	LD	C, 0
	BIT	KEYBOARD_KEYUP, B
	JR	NZ, keyboard_isr_scancode_received_shift_up
.keyboard_isr_scancode_received_shift_down
	SET	KEYBOARD_SHIFT, B
	JR	keyboard_isr_return
.keyboard_isr_scancode_received_shift_up
	RES	KEYBOARD_SHIFT, B
	; also clear the keyup bit
	RES	KEYBOARD_KEYUP, B
	JR	keyboard_isr_return

.keyboard_isr_scancode_received_control
	; remove the extended bit in case this was right control
	RES	KEYBOARD_EXTENDED, B
	; remove the data byte because it has been processed now
	LD	C, 0
	BIT	KEYBOARD_KEYUP, B
	JR	NZ, keyboard_isr_scancode_received_control_up
.keyboard_isr_scancode_received_control_down
	SET	KEYBOARD_CONTROL, B
	JR	keyboard_isr_return
.keyboard_isr_scancode_received_control_up
	RES	KEYBOARD_CONTROL, B
	; also clear the keyup bit
	RES	KEYBOARD_KEYUP, B
	JR	keyboard_isr_return

.keyboard_isr_scancode_received_F7
	LD	C, K_F7
	JR	keyboard_isr_scancode_received_decoded

	; starts with scancode $01
.keyboard_isr_scancode_table
	DEFB	       K_F9,  0,     K_F5,  K_F3,  K_F1,  K_F2,  K_F12
	DEFB	0,     K_F10, K_F8,  K_F6,  K_F4,  9,     '`',   0
	DEFB	0,     0,     0,     0,     0,     'q',   '1',   0
	DEFB	0,     0,     'z',   's',   'a',   'w',   '2',   0
	DEFB	0,     'c',   'x',   'd',   'e',   '4',   '3',   0
	DEFB	0,     32,    'v',   'f',   't',   'r',   '5',   0
	DEFB	0,     'n',   'b',   'h',   'g',   'y',   '6',   0
	DEFB	0,     0,     'm',   'j',   'u',   '7',   '8',   0
	DEFB	0,     ',',   'k',   'i',   'o',   '0',   '9',   0
	DEFB	0,     '.',   '/',   'l',   ';',   'p',   '-',   0
	DEFB	0,     0,     39,    0,     '[',   '=',   0,     0
	DEFB	K_CPL, 0,     10,    ']',   0,     '\',   0,     0
	DEFB	0,     0,     0,     0,     0,     0,     8,     0
	DEFB	0,     '1',   0,     '4',   '7',   0,     0,     0
	DEFB	'0',   '.',   '2',   '5',   '6',   '8',   K_ESC, K_NML
	DEFB	K_F11, '+',   '3',   '-',   '*',   '9',   K_SCL

	; starts with scancode $01
.keyboard_isr_scancode_table_shifted
	DEFB	       K_F9,  0,     K_F5,  K_F3,  K_F1,  K_F2,  K_F12
	DEFB	0,     K_F10, K_F8,  K_F6,  K_F4,  9,     '~',   0
	DEFB	0,     0,     0,     0,     0,     'Q',   '!',   0
	DEFB	0,     0,     'Z',   'S',   'A',   'W',   '@',   0
	DEFB	0,     'C',   'X',   'D',   'E',   '$',   '#',   0
	DEFB	0,     32,    'V',   'F',   'T',   'R',   '%',   0
	DEFB	0,     'N',   'B',   'H',   'G',   'Y',   '^',   0
	DEFB	0,     0,     'M',   'J',   'U',   '&',   '*',   0
	DEFB	0,     '<',   'K',   'I',   'O',   ')',   '(',   0
	DEFB	0,     '>',   '?',   'L',   ':',   'P',   '_',   0
	DEFB	0,     0,     '"',   0,     '{',   '+',   0,     0
	DEFB	K_CPL, 0,     13,    '}',   0,     '|',   0,     0
	DEFB	0,     0,     0,     0,     0,     0,     8,     0
	DEFB	0,     '1',   0,     '4',   '7',   0,     0,     0
	DEFB	'0',   '.',   '2',   '5',   '6',   '8',   K_ESC, K_NML
	DEFB	K_F11, '+',   '3',   '-',   '*',   '9',   K_SCL

	; starts with scancode $4A
.keyboard_isr_scancode_table_extended
	DEFB	              '/',   0,     0,     0,     0,     0
	DEFB	0,     0,     0,     0,     0,     0,     0,     0
	DEFB	0,     0,     10,    0,     0,     0,     0,     0
	DEFB	0,     0,     0,     0,     0,     0,     0,     0
	DEFB	0,     K_END, 0,     K_LFA, K_HOM, 0,     0,     0
	DEFB	K_INS, K_DEL, K_DNA, 0,     K_RTA, K_UPA, 0,     K_BRK
	DEFB	0,     0,     K_PGD, 0,     K_PRS, K_PGU
