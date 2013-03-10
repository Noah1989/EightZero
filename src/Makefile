SOURCES = main.asm ioutil.asm keyboard.asm video.asm \
          hexdigits.asm linechars.asm symbolchars.asm \
          uitools.asm sprite.asm cursor.asm icons.asm \
          monitor.asm

SPRITES = icons0.spr

DEFS = ${SOURCES:.asm=.def}

.PHONY: all program clean

all: main.bin $(DEFS)

main.bin main.def: $(SOURCES) $(SPRITES)
	z80asm -l -g -b $(SOURCES)

%.def: main.def
	sed -n "/; Module $*/Is/;.*//p" $< > $@

program: all
	../tool/bin2ram/bin2ram.py main.bin /dev/ttyUSB0

clean:
	rm -r *.obj *.bin *.def *.lst *.map
