; ioutul.s i/o utility functions

; write sequence to i/o registers
; HL points to list of addresses and values
; terminates if zero address entry is found
io_out_seq:
  xor	A, A
io_out_seq_loop:
  ld	C, (HL)
  cp	A, C
  ret	Z
  inc	HL
  otim
  jr	io_out_seq_loop
  
