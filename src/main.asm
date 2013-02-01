; main - startup code

ORG $E000

XREF video_init

.main
	LD	SP, $FFFF
	CALL	video_init
.loop
	JR	loop
