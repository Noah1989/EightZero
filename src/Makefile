sources = main.asm ioutil.asm keyboard.asm video.asm \
          hexdigits.asm linechars.asm symbolchars.asm \
          uitools.asm cursor.asm monitor.asm

main.bin: $(sources)
	z80asm -v -l -a $(sources)

.PHONY: program
program: main.bin
	../tool/bin2ram/bin2ram.py main.bin /dev/ttyUSB0
