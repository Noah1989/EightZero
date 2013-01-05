; ioutil - i/o utility functions

XDEF outseq

; write sequence to i/o registers on page 0
; HL points to list of addresses (low byte only) and values
; B must be equal to the length of the list in bytes
.outseq
	ld	C, (HL)
	inc	HL
	; eZ80 otim instuction (ED 83):
	;	({UU, $00, C}) <- (HL)
	;	B <- B-1
	;	C <- C+1
	;	HL <- HL+1
	DEFM	$ED & $83
	djnz	outseq
