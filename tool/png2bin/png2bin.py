#!/usr/bin/env python2

import sys, struct
from PIL import Image

def to_argb1555(r, g, b, a):
    r = (r >> 3) & 31
    g = (g >> 3) & 31
    b = (b >> 3) & 31
    if (a == 0):
        return 1 << 15
    else:
        return (r << 10) + (g << 5) + (b << 0)

def make_sprites16():
    images = [Image.open(filename) for filename in sys.argv[2:]]

    palette = set()
    for image in images:
        for (count, color) in image.getcolors():
            palette.add(to_argb1555(*color))
            if len(palette) > 4:
                raise Exception('Too many colors in palette.')
    palette = list(reversed(sorted(palette)))
    print "Used", len(palette), "colors out of 16."
    palette += [0]*(16-len(palette))

    outfile = open('sprites.bin', 'wb')
    outfile.write("".join(struct.pack("<H", color) for color in palette))
    indexed = [[palette.index(to_argb1555(*color)) for color in image.getdata()] for image in images]
    pairs = [(indexed[i],indexed[i+1]) for i in range(0,len(indexed),2)]
    for pair in pairs:
        outfile.write("".join(struct.pack("B", index1 + (index2 << 4))
                              for (index1, index2) in zip(*pair)))

    print outfile.tell(), "bytes written."
    outfile.close()
    print "Done."

def make_charmap():

    def getbox(row, column):
        return (column*8, row*8, column*8 + 8, row*8 + 8)

    image = Image.open(sys.argv[2])
    characters = [image.crop(getbox(row, column)) for row in range(16) for column in range(16)]

    palettes = [{'num_chars': 0, 'colors': set()}]
    for character in characters:
        colors = set()
        for (count, color) in character.getcolors():
            colors.add(to_argb1555(*color))
            if len(colors) > 4:
                raise Exception('Too many colors in character.')
        palette = palettes[-1]
        if len(palette['colors'] | colors) > 4:
            palette = {'num_chars': 1, 'colors': colors}
            palettes.add(palette)
        else:
            palette['num_chars'] += 1
            palette['colors'] |= colors

    outfile = open('charmap.bin', 'wb')

    character_iter = iter(characters)
    for palette in palettes:
        for i in range(palette['num_chars']):
            character = character_iter.next()
            palette['colors'] = list(reversed(sorted(palette['colors'])))
            pixels = [palette['colors'].index(to_argb1555(*color)) for color in character.getdata()]
            blocks = [pixels[i:i+4] for i in range(0, len(pixels), 4)]
            for block in blocks:
                byte = 0
                for pixel in block:
                    byte <<= 2
                    byte += pixel
                outfile.write(struct.pack("B", byte))

    for palette in palettes:
        palette['colors'] += [0]*(4-len(palette['colors']))
        outfile.write(struct.pack("B", palette['num_chars']%256))
        outfile.write("".join(struct.pack("<H", color) for color in palette['colors']))

    outfile.write(struct.pack("B", 0))
    outfile.write(struct.pack("<H", to_argb1555(*characters[0].getpixel((0, 0)))))
    outfile.write(struct.pack("<H", to_argb1555(*characters[255].getpixel((0, 0)))))

    print outfile.tell(), "bytes written."
    outfile.close()
    print "Done."

def error_unknown_format():
    raise Exception('Unknown format')

if len(sys.argv) < 2:
    raise Exception('No format specified')

{
    'sprite16': make_sprites16,
    'charmap' : make_charmap
}.get(sys.argv[1], error_unknown_format)()