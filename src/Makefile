SOURCES = \
	main.asm loader.asm monitor.asm math.asm \
	ioutil.asm serial.asm keyboard.asm video.asm \
	hexdigits.asm linechars.asm symbolchars.asm \
	uitools.asm sprite.asm cursor.asm icons.asm

SPRITES = icons0.spr

INCS = ${SOURCES:.asm=.inc}
DEFS = ${SOURCES:.asm=.def}

.PHONY: all program clean

all: main.bin $(DEFS)

main.bin all.def: $(SOURCES) $(SPRITES) $(INCS)
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
	rm -r *.obj *.bin *.def *.lst *.map
