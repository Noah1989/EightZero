; math - math functions

XDEF div_16_8

; divide 16 bit value by 8 bit value
; input: HL = dividend, C = divisor
; result: HL = quotient, A = remainder
.div_16_8
	XOR	A, A
	LD	B, 16
.div_18_8_loop
	ADD	HL, HL
	RLA
	CP	A, C
	JR	C, div_18_8_nosub
	SUB	A, C
	INC	L
.div_18_8_nosub
	DJNZ	div_18_8_loop
	RET
