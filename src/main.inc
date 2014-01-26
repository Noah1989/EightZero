; interrupt vector table address
; must be at 512 byte boundary
DEFC INTERRUPT_TABLE = $FC00

DEFC SYSTEM_STACK = $0000
DEFC USER_CODE = $D000
DEFC USER_STACK = $FA00
