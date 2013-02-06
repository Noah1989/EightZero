; keyboard - a keyboard input driver

XREF INTERRUPT_TABLE

DEFC INT_PORT_A0 = $80

.keyboard_init
	LD	HL, INTERRUPT_TABLE  + INT_PORT_A0
	LD	(HL), keyboard_isr
	; ...
	RET

.keyboard_isr
	; ...
	RETI
