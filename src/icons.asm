; eZ80 ASM file: icons - some pretty 16x16 graphics for menus and dialogs

INCLUDE "icons.inc"
INCLUDE "video.inc"

XDEF icons_load
XDEF icon_show
XDEF icon_hide

XREF video_copy
XREF sprite_move

.icon_default_even
	; X=4, ROT=0, PAL=$4, Y=0, IMAGE=1, C=0
	DEFB	4, $40, 0, 1*2
.icon_default_odd
	; X=4, ROT=0, PAL=$6, Y=0, IMAGE=1, C=0
	DEFB	4, $60, 0, 1*2

; load icon sprites
.icons_load
	; load sprite image
	; load colors (16-color palette A)
	LD	HL, icons0
	LD	DE, PALETTE16A
	LD	BC, 16*2 ; <- 16 color words
	CALL	video_copy
	; HL now points to image data
	; start with image 1 (0 is cursor)
	LD	DE, RAM_SPRIMG + 256
	; 1 image, two 16-color sprites
	LD	BC, 256
	JP	video_copy
	; RET optimized away by JP above

; hide icon from screen
; A contains icon number
.icon_hide
	LD	BC, 51*256
; show icon on screen
; A contains icon number
; B contains x location in characters
; C contains y location in characters
.icon_show
	LD	DE, RAM_SPR + 4 ; sprite 1
	; check icon number
	BIT	0, A
	JR	NZ, icon_show_odd
.icon_show_even
	LD	HL, icon_default_even
	JR	icon_show_common
.icon_show_odd
	LD	HL, icon_default_odd
.icon_show_common
	DEC	B ; decrement x because default location represents x=1, y=0
	JP	sprite_move
	; RET optimized away by JP above

.icons0
	; 16-color "help" and "load" icons (1 sprite image)
	BINARY	"sprites.bin"
