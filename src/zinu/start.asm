XREF	_data
XREF	_data_end
XREF	_data_init_newqueue

.start
	; initialize the data segment
	LD	HL, _data
	LD	BC, #_data_end-_data
.clear_data_loop
	LD	(HL), 0
	DEC	BC
	LD	A, B
	OR	A, C
	JR	NZ, clear_data_loop
	CALL	_data_init_newqueue