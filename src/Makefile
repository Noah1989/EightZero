SOURCES = \
	main.asm loader.asm monitor.asm math.asm \
	ioutil.asm spi.asm serial.asm keyboard.asm \
	video.asm uitools.asm sdhc.asm fat32.asm \
	fileman.asm \
	sprite.asm cursor.asm icons.asm \
	hexdigits.asm linechars.asm symbolchars.asm


SPRITES = sprites.bin
CHARMAP = charmap.bin

INCS = ${SOURCES:.asm=.inc}
DEFS = ${SOURCES:.asm=.def}

.PHONY: all program clean

all: main.bin $(DEFS)

main.bin all.def: $(SOURCES) $(SPRITES) $(CHARMAP) $(INCS)
	z80asm -l -g -b $(SOURCES)
	@mv main.def all.def

%.def: all.def
	@echo generating $@ ...
	@echo "; functions" > $@
	@sed -n "/; Module $*/Is/;.*//p" $< >> $@
	@echo "\n; constants" >> $@
	@cat $*.inc >> $@

program: all
	@../tool/bin2ram/bin2ram.py loader main.bin /dev/ttyUSB1 || \
	../tool/bin2ram/bin2ram.py debugger main.bin /dev/ttyUSB0

clean:
	rm -r main.bin *.obj *.def *.lst *.map
