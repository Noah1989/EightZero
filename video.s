; video.s - low level code for the gameduino video interface

  PB_DR  = 0x9A
  PB_DDR = 0x9B  

; initialize PORTB and SPI
; pin usage:
; 0 - unused
; 1 - slave select for gameduino
; 2 - slave select input (always high)
; 3 - SCK
; 4 - unused
; 5 - unused
; 6 - MISO
; 7 - MOSI  
video_init:
  ld	HL, #video_init_seq
  jr	io_out_seq
video_init_seq:
  .db	PB_DR, 0x02
  .db   0
