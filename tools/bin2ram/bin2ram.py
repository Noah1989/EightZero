#!/usr/bin/env python

import sys, os
import fdpexpect

if len(sys.argv) != 3:
    print 'Usage: bin2ram.py ../../src/main.bin /dev/ttyUSB0'
    exit()

image_filename = sys.argv[1]
print 'Loading binary image from', image_filename, '...'
image_file = open(image_filename, 'rb')
image_bytes = image_file.read()
image_file.close()

tty_filename = sys.argv[2]

print 'Opening', tty_filename, '...'
tty_file = os.open(tty_filename, os.O_RDWR|os.O_NONBLOCK|os.O_NOCTTY)
tty = fdpexpect.fdspawn(tty_file)

#tty.logfile = open("bin2ram.log", 'w')

print 'Identifying target...'
tty.send('i')
tty.expect('00 08 ..')
print 'Product ID:', tty.match.group()

def zdi_active():
    print 'Getting status...'
    tty.send('s')
    tty.expect('ZDI ACTIVE: ([01])')
    return tty.match.group(1) == '1'

if zdi_active():
    print 'ZDI is active.'
else:
    print 'ZDI is not active, breaking... '
    tty.send('b')
    tty.send('s')
    if not zdi_active():
        raise Exception('Could not activate ZDI.')

def get_program_counter():
    tty.send('r')
    tty.expect('PC: (.. ..)')
    return tty.match.group(1)

def reset_program_counter():
    print 'Setting PC to RAM start...'
    tty.send('0')
    tty.expect('E0 00')

    print 'Verifying PC...'
    program_counter = get_program_counter()
    if program_counter == 'E0 00':
        print 'PC is valid.'
    else:
        print 'Invalid PC: ', program_counter
        raise Exception('Could not set PC.')

reset_program_counter()

print 'Writing', len(image_bytes), 'bytes...'
for byte_to_write in image_bytes:
    hex_byte = '%0.2X' % ord(byte_to_write)
    tty.send('w')
    tty.send(hex_byte)
    tty.expect(hex_byte)
print 'Image written.'

print 'PC is now at: ', get_program_counter()

reset_program_counter()

print 'Continuing from break...'
tty.send('c')

print 'Done!'
