DEFC	NPROC	= 32

DEFGROUP
{
	PR_FREE,
	PR_CURR,
	PR_READY,
	PR_RECV,
	PR_SLEEP,
	PR_SUSP,
	PR_WAIT,
	PR_RECTIM
}

DEFVARS 0
{
	procent_prstate		ds.b 1
	procent_prprio		ds.b 1
	procent_prstkptr	ds.w 1
	SIZEOF_procent
}