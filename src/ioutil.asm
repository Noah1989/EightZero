; ioutil - i/o utility functions

XDEF output_sequence

; write sequence to i/o registers on page 0
; HL points to list of addresses (low byte only) and values
; B must be equal to the length of the list in bytes
.output_sequence
	LD	C, (HL)
	INC	HL
	; eZ80 OTIM instuction (ED 83):
	;	({UU, $00, C}) <- (HL)
	;	B <- B-1
	;	C <- C+1
	;	HL <- HL+1
	DEFB	$ED, $83
	DJNZ	output_sequence
	RET
