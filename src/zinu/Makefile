SOURCES	= \
	zinu.asm start.asm conf.asm nulluser.asm \
	doprnt.asm kprintf.asm \
	ioerr.asm ionull.asm \
	uartInit.asm uartRead.asm uartWrite.asm uartGetc.asm uartPutc.asm uartControl.asm uartInterrupt.asm \
	getitem.asm queue.asm insert.asm newqueue.asm \
	process.asm \
	test.asm \
	end.asm
INCS	= *.inc

.PHONY: all clean program

all: zinu.bin

zinu.bin: $(SOURCES) $(INCS) eZ80/*.asm
	z80asm -l -b $(SOURCES)

clean:
	rm -vf *.map *.obj *.sym *.lst *.bin

program: all
	../../tool/bin2ram/bin2ram.py debugger zinu.bin /dev/ttyUSB1