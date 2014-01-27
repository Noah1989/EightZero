SOURCES	= \
	zinu.asm start.asm \
	getitem.asm queue.asm insert.asm newqueue.asm \
	process.asm \
	end.asm
INCS	= *.inc

.PHONY: all clean program

all: zinu.bin

zinu.bin: $(SOURCES) $(INCS) eZ80/*.asm
	z80asm -l -b $(SOURCES)

clean:
	rm -vf *.map *.obj *.sym *.lst *.bin

program: all
	../../tool/bin2ram/bin2ram.py loader zinu.bin /dev/ttyUSB0