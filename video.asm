; video - low level code for the gameduino video interface

XREF outseq

XDEF videoinit

DEFC PB_DR = $9A
DEFC PB_DDR = $9B
DEFC PB_ALT2 = $9D
DEFC SPI_BRG_L = $B8
DEFC SPI_CTL = $BA

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
.videoinit
	LD	HL, videoinitseq
	LD	B, #end_videoinitseq-videoinitseq
	JP	outseq
.videoinitseq
	; port configuration (see above)
	DEFM	PB_DR, $02
	DEFM	PB_DDR, $FD
	DEFM	PB_ALT2, $CC
	; fastest possible SPI speed
	DEFM	SPI_BRG_L, $03
	; enable SPI: mode 0, master
	DEFM	SPI_CTL, $30
.end_videoinitseq