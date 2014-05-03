DEFC	NDEVS = 1

DEFC	SERIAL0 = 0

DEFVARS 0
{
	dentry_dvnum	ds.b 1	; uint8
	dentry_dvminor	ds.b 1	; uint8
	dentry_dvname	ds.w 1	; char*
	dentry_dvinit	ds.w 1	; devcall (*)
	dentry_dvopen	ds.w 1	; devcall (*)
	dentry_dvclose	ds.w 1	; devcall (*)
	dentry_dvread	ds.w 1	; devcall (*)
	dentry_dvwrite	ds.w 1	; devcall (*)
	dentry_dvseek	ds.w 1	; devcall (*)
	dentry_dvgetc	ds.w 1	; devcall (*)
	dentry_dvputc	ds.w 1	; devcall (*)
	dentry_dvcntl	ds.w 1	; devcall (*)
	dentry_dvcsr	ds.w 1	; void*
	dentry_dvintr	ds.w 1	; void (*)
	dentry_dvirq	ds.b 1	; uint8
	SIZEOF_dentry
}