INCLUDE	"zinu.inc"

XREF	queuetab

XDEF	_data_init_newqueue

DEFVARS -1
{
	nextqid	ds.b 1 ; qid8
}

._data_init_newqueue
	LD	A, NPROC
	LD	(nextqid), A
	RET

; allocate and initialize a queue in global queuetab
; OUT:	qid8 A	ID of allocated queue or SYSERR
.newqueue
	PUSH	HL
	LD	HL, nextqid
	LD	A, (HL)
	; check for table overflow
	CP	A, NQENT
	JR	NC, newqueue_error_restore_HL
	; increment index for next call
	INC	(HL)
	INC	(HL)
	PUSH	IX
	PUSH	BC
	; find queue head
	LD	IX, queuetab
	LD	B, SIZEOF_qentry
	LD	C, A
	INCLUDE	"eZ80/MLT_BC.asm"
	ADD	IX, BC
	INC	A ; tail
	; initialize head
	LD	(IX + qentry_qnext), A
	LD	(IX + qentry_qprev), EMPTY
	LD	(IX + qentry_qkey), MAXKEY
	DEC	A ; head again
	; initialize tail
	LD	(IX + SIZEOF_qentry + qentry_qnext), EMPTY
	LD	(IX + SIZEOF_qentry + qentry_qprev), A
	LD	(IX + SIZEOF_qentry + qentry_qkey), MINKEY
	; return qid in A
	POP	BC
	POP	IX
	POP	HL
	RET

.newqueue_error_restore_HL
	POP	HL
	LD	A, SYSERR
	RET