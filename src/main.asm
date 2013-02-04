; main - startup code

ORG $E000

XREF RAM_PIC

XREF video_init
XREF video_copy
XREF video_start_write
XREF video_spi_write
XREF video_end_transfer

XREF hexdigits_load

.main
	LD	SP, $FFFF
	CALL	video_init
	CALL	hexdigits_load
	LD	HL, hello_string
	LD	BC, #end_hello_string-hello_string
	LD	DE, RAM_PIC + 3 + 3*64
	CALL	video_copy

	LD	DE, RAM_PIC + 3 + 5*64
	LD	HL, buffer
	LD	(HL), $80
	LD	B, 8
.bar
	LD	C, B
	CALL	video_start_write
	LD	B, 16
.foo
	CALL	video_spi_write
	INC	(HL)
	DJNZ	foo
	CALL	video_end_transfer
	INC	D
	LD	B, C
	DJNZ	bar


.loop
	JR	loop

.hello_string
	DEFM	"Hello, world!"
.end_hello_string

.buffer
	DEFM	0
