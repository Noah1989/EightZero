main.bin: main.asm ioutil.asm video.asm
	z80asm -v -l -a main ioutil video

.PHONY: program
program: main.bin
	../tools/bin2ram/bin2ram.py main.bin /dev/ttyUSB0
