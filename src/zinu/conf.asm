INCLUDE	"zinu.inc"

XREF	ionull
XREF	ioerr

XREF	uartInit
XREF	uartRead
XREF	uartWrite
XREF	uartGetc
XREF	uartPutc
XREF	uartControl
XREF	uartInterrupt

XDEF	_data_init_conf

XDEF	devtab

DEFVARS -1
{
	devtab	ds.b SIZEOF_dentry*NDEVS
}

._data_init_conf
	LD	DE, devtab
	LD	HL, _data_init_conf_devtab_content
	LD	BC, SIZEOF_dentry*NDEVS
	LDIR
	RET
	; Format of entries is:
	; dev-number, minor-number, dev-name,
	; init, open, close,
	; read, write, seek,
	; getc, putc, control,
	; dev-csr-address, intr-handler, irq
._data_init_conf_devtab_content
	DEFB	0, 0
	DEFW	name_SERIAL0
	DEFW	uartInit, ionull, ionull
	DEFW	uartRead, uartWrite, ioerr
	DEFW	uartGetc, uartPutc, uartControl
	DEFW	UART0_CSR, uartInterrupt,  0 ; TODO: irq

.name_SERIAL0
	DEFM	"SERIAL0", 0