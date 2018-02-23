XDEF	_doprnt

; Format and write output using 'func' to write characters
; IN:	char*	HL	format string
;	TODO		format arguments
;	void(*)	IX	pointer to function that writes char from A
;	void*	IY	argument for function in IX (passed through)
._doprnt
	PUSH	AF
	PUSH	HL
	PUSH	BC
	LD	BC, _doprnt_cont
._doprnt_loop
	LD	A, (HL)
	AND	A, A
	JR	Z, _doprnt_end
	PUSH	BC ; fake CALL (IX)
	JP	(IX)
._doprnt_cont
	INC	HL
	JR	_doprnt_loop
._doprnt_end
	POP	BC
	POP	HL
	POP	AF
	RET