sources = main.asm ioutil.asm keyboard.asm video.asm \
          hexdigits.asm linechars.asm monitor.asm

main.bin: $(sources)
	z80asm -v -l -a $(sources)

.PHONY: program
program: main.bin
	../tools/bin2ram/bin2ram.py main.bin /dev/ttyUSB0
