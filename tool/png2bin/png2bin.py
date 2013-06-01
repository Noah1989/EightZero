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

palette = set()
images = [Image.open(filename) for filename in sys.argv[1:]]

for image in images:
    for (count, color) in image.getcolors():
        palette.add(to_argb1555(*color))
        if len(palette) > 16:
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
