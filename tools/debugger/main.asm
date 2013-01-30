.nolist
.include "tn2313def.inc"
.list


.def zero = r1
.def temp = r16
.def tmph = r17
.def command = r18
.def addr = r19
.def data = r20
.def readcmd = r21
.def counter = r22

start:
        rjmp    init

.include "inout.asm"
.include "zdi.asm"
.include "commands.asm"

init:
        clr     zero
        rcall   usart_init

ready:
        ; print ready string
        ldi     ZH, HIGH(ready_string*2)
        ldi     ZL, LOW(ready_string*2)
        rcall   write_string
        rjmp    prompt
ready_string:
        .db     13, 10, "ready.", 13, 10, 0, 0

prompt:
        ; print prompt string
        ldi     ZH, HIGH(prompt_string*2)
        ldi     ZL, LOW(prompt_string*2)
        rcall   write_string
        rjmp    input
prompt_string:
        .db     "debug: ", 0

input:  
        ; get user input
        rcall   usart_receive
        mov     command, temp
        ; echo back and newline
        rcall   usart_transmit
        rcall   write_newline

decode_command:        
        ldi     ZH, HIGH(command_table*2)
        ldi     ZL, LOW(command_table*2)
decode_command_loop:        
        ; get command from table
        lpm     temp, Z
        ; end of table?
        tst     temp
        breq    decode_command_unknown
        ; found command?
        cp      temp, command
        breq    decode_command_found
        ; next entry
        adiw    ZL, 4
        rjmp    decode_command_loop
decode_command_found:
        ; get address and call it
        adiw    ZL, 2
        lpm     temp, Z+
        lpm     tmph, Z       
        movw    ZH:ZL, tmph:temp
        icall
        rjmp    prompt
decode_command_unknown:
        ldi     ZH, HIGH(decode_command_unknown_string*2)
        ldi     ZL, LOW(decode_command_unknown_string*2)
        rcall   write_string
        rjmp    prompt
decode_command_unknown_string:
        .db     "error: unknown command.", 13, 10, 0

