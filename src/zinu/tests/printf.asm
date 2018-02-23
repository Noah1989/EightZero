.test_kprintf
	; Nothing to do here.
	; If we see the result,
	; kprintf must work.
	XOR	A, A
	RET

XREF sprintf
.test_sprintf
	LD	DE, test_buffer
	LD	HL, test_sprintf_text
	CALL	sprintf
	LD	B, #test_sprintf_text_end-test_sprintf_text
.test_sprintf_loop
	LD	A, (DE)
	SUB	A, (HL)
	RET	NZ
	INC	DE
	INC	HL
	DJNZ	test_sprintf_loop
	; A shoud be 0 here
	RET
.test_sprintf_text
	DEFM	"sprintf test string", 0
.test_sprintf_text_end