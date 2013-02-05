; main - startup code

ORG $E000

XREF RAM_PIC

XREF video_init
XREF video_copy
XREF video_start_write
XREF video_spi_write
XREF video_end_transfer

XREF hexdigits_load
XREF linechars_load

XREF monitor

.main
	LD	SP, $FFFF
	CALL	video_init
	CALL	hexdigits_load
	CALL	linechars_load
	JP	monitor
