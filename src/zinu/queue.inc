; number of queue entries
; NPROC for processess
; + 2 for ready list (head and tail)
; + 2 for sleep list
; + 2 per semaphore
DEFC	NQENT	= NPROC + 2 + 2 + NSEM*2
DEFC	EMPTY	= -1
DEFC	MAXKEY	= 255
DEFC	MINKEY	= 0

DEFVARS 0
{
	qentry_qkey	ds.b 1 ; key8
	qentry_qnext	ds.b 1 ; qid8
	qentry_qprev	ds.b 1 ; qid8
	SIZEOF_qentry
}