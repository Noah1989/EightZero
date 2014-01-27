INCLUDE	"zinu.inc"

XREF	queuetab

XDEF	getfirst
XDEF	getlast
XDEF	getitem

; remove a process from the font of a queue
; IN:	qid8 A	ID of queue from which
;		to remove a process (unchecked)
; OUT:	pid8 A	ID of the removed process or EMPTY
.getfirst
	PUSH	IX
	PUSH	BC
	; find queue head
	; IX <- queuetab + A*SIZEOF_qentry
	LD	IX, queuetab
	LD	B, SIZEOF_qentry
	LD	C, A
	INCLUDE	"eZ80/MLT_BC.asm"
	ADD	IX, BC
	; get first process after head
	LD	A, (IX + qentry_qnext)
	JR	checkempty_getitem

; remove a process from the end of a queue
; IN:	qid8 A	ID of queue from which
;		to remove a process (unchecked)
; OUT:	pid8 A	ID of the removed process or EMPTY
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
	;JR	checkempty_getitem

.checkempty_getitem
	; check for empty queue (at head or tail?)
	CP	A, NPROC
	; slide into getitem if not empty
	JR	C, getitem_internal
	; else return EMPTY
	LD	A, EMPTY
	POP	BC
	POP	IX
	RET

; remove a process from an arbitrary point in a queue
; IN	pid8 A	ID of the process to remove
; OUT	pid8 A	unchanged
.getitem
	PUSH	IX
	PUSH	BC
.getitem_internal
	PUSH	DE
	; find process qentry
	; IX <- queuetab + A*SIZEOF_qentry
	LD	IX, queuetab
	LD	B, SIZEOF_qentry
	LD	C, A
	INCLUDE	"eZ80/MLT_BC.asm"
	ADD	IX, BC
	; get prev and next
	; to stitch them together
IF qentry_qnext + 1 = qentry_qprev
	INCLUDE "eZ80/LD_DE_IXd_ind.asm"
	DEFB	qentry_qnext
ELSE
	LD	E, (IX + qentry_qnext)
	LD	D, (IX + qentry_qprev)
ENDIF
	; find prev entry
	; IX <- queuetab + D*SIZEOF_qentry
	LD	IX, queuetab
	LD	B, SIZEOF_qentry
	LD	C, D
	INCLUDE	"eZ80/MLT_BC.asm"
	ADD	IX, BC
	; prev.qnext <- next
	LD	(IX + qentry_qnext), E
	; find next entry
	; IX <- queuetab + E*SIZEOF_qentry
	LD	IX, queuetab
	LD	B, SIZEOF_qentry
	LD	C, E
	INCLUDE	"eZ80/MLT_BC.asm"
	ADD	IX, BC
	; next.qprev <- prev
	LD	(IX + qentry_qprev), D
	POP	DE
	POP	BC
	POP	IX
	RET