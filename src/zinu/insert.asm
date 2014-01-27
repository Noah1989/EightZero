INCLUDE	"zinu.inc"

XREF queuetab
XREF proctab

XDEF insert

; insert a process into a queue in descending key order
; IN:	pid8 A	ID of process to insert
;	qid8 L	ID of queue to use
;     	key8 H	key for the inserted process
; OUT:	int8 A	OK or SYSERR
.insert
	PUSH	DE
	LD	D, A
	; check for bad qid
	LD	A, L
	CP	A, NQENT-1
	JR	NC, insert_error_restore_DE
	; check for bad pid
	LD	A, D
	CP	A, NPROC
	JR	NC, insert_error_restore_DE
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
	JR	Z, insert_error_restore_BCIXDE
	; find queue head
	; IX <- queuetab + L*SIZEOF_qentry
	LD	IX, queuetab
	LD	B, SIZEOF_qentry
	LD	C, L
	INCLUDE	"eZ80/MLT_BC.asm"
	ADD	IX, BC
.insert_loop
	; get id of next process in list
	LD	E, (IX + qentry_qnext)
	; find entry for that process
	; IX <- queuetab + E*SIZEOF_qentry
	LD	IX, queuetab
	LD	B, SIZEOF_qentry
	LD	C, E
	INCLUDE	"eZ80/MLT_BC.asm"
	ADD	IX, BC
	; compare key
	LD	A, (IX + qentry_qkey)
	CP	A, H
	JR	NC, insert_loop
	; get old prev and put new pid there instead
	LD	A, (IX + qentry_qprev)
	LD	(IX + qentry_qprev), D
	; find the old prev
	LD	IX, queuetab
	LD	B, SIZEOF_qentry
	LD	C, A
	INCLUDE "eZ80/MLT_BC.asm"
	ADD	IX, BC
	; put new pid as next of old prev
	LD	(IX + qentry_qnext), D
	; find the insterted process entry
	; and connect it into the list
	LD	IX, queuetab
	LD	B, SIZEOF_qentry
	LD	C, D
	INCLUDE "eZ80/MLT_BC.asm"
	ADD	IX, BC
	LD	D, A ; don't need the new pid anymore
	; next <- found id from E
	; prev <- old prev from D (previously A)
IF qentry_next + 1 = qentry_prev
	INCLUDE	"eZ80/LD_IXd_ind_DE.asm"
	DEFB	qentry_qnext
ELSE
	LD	(IX + qentry_qnext), E
	LD	(IX + qentry_qprev), D
ENDIF
	; store key
	LD	(IX + qentry_qkey), H
	; success :)
	POP	BC
	POP	IX
	POP	DE
	LD	A, OK
	RET

.insert_error_restore_BCIXDE
	POP	BC
	POP	IX
.insert_error_restore_DE
	POP	DE
	LD	A, SYSERR
	RET