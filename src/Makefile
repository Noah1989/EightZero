sources = main.asm ioutil.asm keyboard.asm video.asm \
          hexdigits.asm linechars.asm symbolchars.asm \
          uitools.asm sprite.asm cursor.asm icons.asm \
          monitor.asm

sprites = icons0.spr

main.bin: $(sources) $(sprites)
	z80asm -v -l -a $(sources)

.PHONY: program
program: main.bin
	../tool/bin2ram/bin2ram.py main.bin /dev/ttyUSB0
