;main - startup code

ORG $E000

XREF videoinit

.main	call	videoinit
.loop	jr	loop
