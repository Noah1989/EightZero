main.hex: *.asm *.inc
	avra main.asm

program: main.hex
	avrdude -c usbasp -p t2313 -U flash:w:main.hex
