XDEF	_code
XDEF	_data

; code segment
ORG	$E000
; data segment
DEFVARS	$F000
{
	_data
}

._code