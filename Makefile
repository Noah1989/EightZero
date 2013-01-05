main.bin: main.asm ioutil.asm video.asm
	z80asm -l -a main ioutil video

