INCLUDE	"zinu.inc"

XREF	devtab
XREF	test

XDEF	nulluser

.nulluser
	CALL	sysinit

	CALL	test

.nulluser_idle
	JR	nulluser_idle

.sysinit
	LD	DE, sysinit_next
	; initialize all devices
	LD	B, NDEVS
	; point IY to first device
	LD	IY, devtab
.sysinit_loop
	; get and call init function
	INCLUDE	"eZ80/LD_IX_IYdi.asm"
	DEFB	dentry_dvinit
	PUSH	DE ; fake CALL (IX)
	JP	(IX)
.sysinit_next
	; point IY to next device
	INCLUDE	"eZ80/LEA_IY_IYd.asm"
	DEFB	SIZEOF_dentry
	DJNZ	sysinit_loop
	RET