; icons - some pretty 16x16 graphics for menus and dialogs

INCLUDE "icons.inc"
INCLUDE "video.inc"

XDEF icons_load
XDEF icon_show
XDEF icon_hide

XREF video_copy
XREF sprite_move

.icon_default
	; X=4, ROT=0, PAL=$4, Y=0, IMAGE=1, C=0
	DEFB	4, $40, 0, 1*2

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

.icon_hide
	LD	BC, 51*256
	; show icon on screen
	; B contains x location in characters
	; C contains y location in characters
.icon_show
	LD	DE, RAM_SPR + 4 ; sprite 1
	LD	HL, icon_default
	DEC	B ; default location represents x=1, y=0
	JP	sprite_move
	; RET optimized away by JP above

; 16-color "help" and "load" icons (1 sprite image)
.icons0
	BINARY	"icons0.spr"
