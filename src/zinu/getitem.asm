INCLUDE	"zinu.inc"

XREF	queuetab

XDEF	getfirst
XDEF	getlast
XDEF	getitem

; remove a process from the font of a queue
; IN:	qid8 A	ID of queue from which
;		to remove process (unchecked)
; OUT:	pid8 A	ID of the removed process
.getfirst
	PUSH	IX
	PUSH	BC
	; find queue head
	; IX <- queuetab + A*struct_qentry
	LD	IX, queuetab
	LD	B, SIZEOF_qentry
	LD	C, A
INCLUDE	"eZ80/MLT_BC.asm"
	ADD	IX, BC
	; get first process after head
	LD	A, (IX + qentry_qnext)
	JR	check_return

; remove a process from the end of a queue
; IN:	qid8 A	ID of queue from which
;		to remove process (unchecked)
; OUT:	pid8 A	ID of the removed process
.getlast
	PUSH	IX
	PUSH	BC
	; find queue tail
	INC	A
	; IX <- queuetab + A*struct_qentry
	LD	IX, queuetab
	LD	B, SIZEOF_qentry
	LD	C, A
INCLUDE	"eZ80/MLT_BC.asm"
	ADD	IX, BC
	; get first process before tail
	LD	A, (IX + qentry_qprev)
	;JR	check return

.check_return
	; check for empty queue
	CP	A, NPROC
	JR	C, return
	LD	A, EMPTY
.return
	POP	BC
	POP	IX
	RET

; remove a process from an arbitrary point in a queue
; IN	pid8 A	ID of the process to remove
; OUT	pid8 A	unchanged
	PUSH	IX
	PUSH	BC
	PUSH	DE
	; find process qentry
	; IX <- queuetab + A*struct_qentry
	LD	IX, queuetab
	LD	B, SIZEOF_qentry
	LD	C, A
INCLUDE	"eZ80/MLT_BC.asm"
	ADD	IX, BC
	; get prev and next
IF qentry_qnext + 1 = qentry_qprev
INCLUDE "eZ80/LD_DE_IXd_ind.asm"
DEFB	qentry_qnext
ELSE
	LD	D, (IX + qentry_qprev)
	LD	E, (IX + qentry_qnext)
ENDIF
	; find prev entry
	; IX <- queuetab + D*struct_qentry
	LD	IX, queuetab
	LD	B, SIZEOF_qentry
	LD	C, D
INCLUDE	"eZ80/MLT_BC.asm"
	ADD	IX, BC
	; queuetab[prev].qnext = next
	LD	(IX + qentry_qnext), E
	; find next entry
	; IX <- queuetab + E*struct_qentry
	LD	IX, queuetab
	LD	B, SIZEOF_qentry
	LD	C, E
INCLUDE	"eZ80/MLT_BC.asm"
	ADD	IX, BC
	; queuetab[next].qprev = prev
	LD	(IX + qentry_qprev), D
	POP	DE
	POP	BC
	POP	IX
	RET