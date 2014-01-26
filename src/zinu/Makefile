SOURCES	= zinu.asm getitem.asm queue.asm
INCS	= *.inc

.PHONY: all clean

all: zinu.bin

zinu.bin: $(SOURCES) $(INCS)
	z80asm -l -b $(SOURCES)

clean:
	rm -vf *.map *.obj *.sym *.lst *.bin