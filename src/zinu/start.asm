XREF	_data
XREF	_data_end

XREF	_data_init_conf
XREF	_data_init_newqueue

XREF	nulluser

.start
	; initialize stack
	LD	SP, 0
	; initialize the data segment
	LD	HL, _data
	LD	BC, #_data_end-_data
.clear_data_loop
	LD	(HL), 0
	DEC	BC
	LD	A, B
	OR	A, C
	JR	NZ, clear_data_loop
	; initialize static variables
	CALL	_data_init_conf
	CALL	_data_init_newqueue

	JP	nulluser