INCLUDE	"zinu.inc"

XREF	proctab
XREF	getfirst

XDEF	queuetab

DEFVARS -1
{
	queuetab	ds.b SIZEOF_qentry*NQENT
}

; insert a process at the tail of a queue
; IN:	pid8 A	ID of process to insert
;	qid8 L	ID of queue to use
; OUT:	pid8 A	unchanged if valid, else SYSERR
.enqueue
	PUSH	HL
	LD	H, A
	; check for bad qid
	LD	A, L
	CP	A, NQENT-1
	JR	NC, queue_error_restore_HL
	; check for bad pid
	LD	A, H
	CP	A, NPROC
	JR	NC, queue_error_restore_HL
	PUSH	IX
	PUSH	BC
	; check if process exists
	LD	IX, proctab
	LD	B, SIZEOF_procent
	LD	C, A
	INCLUDE	"eZ80/MLT_BC.asm"
	ADD	IX, BC
IF PR_FREE = 0
	XOR	A, A
ELSE
	LD	A, PR_FREE
ENDIF
	CP	A, (IX + procent_prstate)
	JR	Z, queue_error_restore_BCIXHL
	; find tail entry
	INC	L ; tail qid
	LD	IX, queuetab
	LD	B, SIZEOF_qentry
	LD	C, L
	INCLUDE	"eZ80/MLT_BC.asm"
	ADD	IX, BC
	; A <- tail.qprev; tail.qprev <- pid
	LD	A, (IX + qentry_qprev)
	LD	(IX + qentry_qprev), H
	; find tail's old prev entry
	LD	IX, queuetab
	LD	B, SIZEOF_qentry
	LD	C, A
	INCLUDE	"eZ80/MLT_BC.asm"
	ADD	IX, BC
	; prev.qnext <- pid
	LD	(IX + qentry_qnext), H
	; find pid entry
	; and put it between tail and prev
	LD	IX, queuetab
	LD	B, SIZEOF_qentry
	LD	C, H
	INCLUDE	"eZ80/MLT_BC.asm"
	ADD	IX, BC
	LD	B, H ; rescue pid
	LD	H, A ; H = prev, L = tail
IF qentry_qnext + 1 = qentry_qprev
	INCLUDE "eZ80/LD_IXdi_HL.asm"
	DEFB	qentry_qnext
ELSE
	LD	(IX + qentry_qnext), L
	LD	(IX + qentry_qprev), H
ENDIF
	; return original pid
	LD	A, B
	POP	BC
	POP	IX
	POP	HL
	RET

.queue_error_restore_BCIXHL
	POP	BC
	POP	IX
.queue_error_restore_HL
	POP	HL
.queue_error
	LD	A, SYSERR
	RET

; remove and return the first process on a list
; IN:	qid8 A	ID of queue to use
; OUT:	pid8 A	ID of process removed, or EMPTY, or SYSERR
.dequeue
	; check for bad qid
	CP	A, NQENT-1
	JR	NC, queue_error
	CALL	getfirst
	CP	A, EMPTY
	RET	Z
	PUSH	IX
	PUSH	BC
	; find pid entry
	; and set prev/next to EMPTY
	LD	IX, queuetab
	LD	B, SIZEOF_qentry
	LD	C, A
	INCLUDE	"eZ80/MLT_BC.asm"
	ADD	IX, BC
IF qentry_qnext + 1 = qentry_qprev
	LD	BC, EMPTY~$FF + (EMPTY~$FF)*$100
	INCLUDE "eZ80/LD_IXdi_BC.asm"
	DEFB	qentry_qnext
ELSE
	LD	B, EMPTY
	LD	(IX + qentry_qnext), B
	LD	(IX + qentry_qprev), B
ENDIF
	POP	BC
	POP	IX
	RET
