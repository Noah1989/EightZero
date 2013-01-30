; main - startup code

ORG $E000

XREF videoinit

.main
	CALL	videoinit
.loop
	JR	loop