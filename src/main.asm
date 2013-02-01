; main - startup code

ORG $E000

XREF video_init
XREF video_copy

.main
	LD	SP, $FFFF
	CALL	video_init
	LD	HL, hello_string
	LD	BC, #end_hello_string-hello_string
	LD	DE, 3 + 64*3
	CALL	video_copy
.loop
	JR	loop

.hello_string
	DEFM	"Hello, world!"
.end_hello_string
