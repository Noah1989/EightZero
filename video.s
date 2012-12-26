; video.s - low level code for the gameduino video interface

  PB_DR     = 0x9A
  PB_DDR    = 0x9B
  PB_ALT2   = 0x9D
  SPI_BRG_L = 0xB8
  SPI_CTL   = 0xBA

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
  .db	PB_DDR, 0xFD
  .db	PB_ALT2, 0xCC
  .db	SPI_BRG_L, 0x03
  .db	SPI_CTL, 0x00
  .db	SPI_CTL, 0x30
  .db   0
