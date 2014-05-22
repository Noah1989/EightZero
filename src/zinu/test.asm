INCLUDE	"zinu.inc"

XREF	kprintf

XDEF	test

DEFVARS -1
{
	test_name	ds.b 32
	test_name_end	ds.b 1
}

.test_list
	DEFM	"kprintf", 0
	DEFW	test_kprintf
	DEFB	0 ; end marker

.test
	LD	IY, test_list
.test_loop
	; check for end marker
	XOR	A, A
	CP	A, (IY)
	JR	Z, test_done
	; clear test name
	LD	A, '.'
	LD	HL, test_name
	LD	B, #test_name_end-test_name
.test_reset_name_loop
	LD	(HL), A
	INC	HL
	DJNZ	test_reset_name_loop
	XOR	A, A ; <- 0
	LD	(test_name_end), A
	; load test name
	LD	D, IYH
	LD	E, IYL
	LD	HL, test_name
	EX	DE, HL
.test_load_name_loop
	CP	A, (HL)
	JR	Z, test_print_name
	LDI
	JR	test_load_name_loop
.test_print_name
	; print test name
	EX	DE, HL
	LD	HL, test_name
	CALL	kprintf
	EX	DE, HL
.test_run
	; run the test
	INC	HL
	INCLUDE	"eZ80/LD_IX_HLi.asm"
	INC	HL
	INC	HL
	EX	DE, HL
	LD	IYH, D ; point IY
	LD	IYL, E ; to next entry
	DEC	A  ; contains $FF now
	LD	HL, test_return
	PUSH	HL ; fake CALL
	JP	(IX)
.test_return
	; check result
	AND	A, A
	JR	Z, test_passed

.test_failed
	LD	HL, test_failed_text
	CALL	kprintf
	HALT
.test_failed_text
	DEFM	"FAILED", 13, 10, 0

.test_passed
	LD	HL, test_passed_text
	CALL	kprintf
	JR	test_loop
.test_passed_text
	DEFM	"PASSED", 13, 10, 0

.test_done
	LD	HL, test_done_text
	CALL	kprintf
	RET
.test_done_text
	DEFM	"TEST DONE", 13, 10, 0

.test_kprintf
	; Nothing to do here.
	; If we see the result,
	; kprintf must work.
	XOR	A, A
	RET