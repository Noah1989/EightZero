INCLUDE	"zinu.inc"

XREF	kprintf

XDEF	test

.test
	LD	HL, test_passed
	CALL	kprintf
	RET
.test_passed
	DEFM	"PASSED", 13, 10, 0