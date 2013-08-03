; eZ80 ASM file: decompress - decompress run-length encoded data

INCLUDE "decompress.inc"

XDEF decompress

; decompress data:
; First data byte is escape character.
; Non-escape characters are decoded literally.
; Repeated characters are represented by
; escape character followed by repitition count
; followed by character to be repeated.
; Escape character followed by 0 marks end of data.
; HL points to data
; IY points to callback
; callback is called for each decoded character in A
; callback must not change BC and HL
.decompress
	LD	C, (HL)
.decompress_loop
	INC	HL
	LD	A, (HL)
	CP	A, C
	JR	Z, decompress_repeat
.decompress_literal
	LD	DE, decompress_loop
	PUSH	DE
	JP	(IY)
.decompress_repeat
	INC	HL
	LD	B, (HL)
	; check for end marker
	XOR	A, A
	OR	A, B
	RET 	Z
	INC	HL
	LD	A, (HL)
.decompress_repeat_loop
	LD	DE, decompress_repeat_return
	PUSH	DE
	JP	(IY)
.decompress_repeat_return
	DJNZ	decompress_repeat_loop
	JR	decompress_loop