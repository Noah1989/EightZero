#!/usr/bin/env python2

import sys, os, struct
import pexpect, fdpexpect

if len(sys.argv) != 4:
    print 'Usage: bin2ram.py debugger ../../src/main.bin /dev/ttyUSB0'
    exit()

def program_through_debugger():
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
    default_delay = tty.delaybeforesend
    tty.delaybeforesend = 0
    for byte_to_write in image_bytes:
        hex_byte = '%0.2X' % ord(byte_to_write)
        tty.send('w')
        tty.send(hex_byte)
        tty.expect(hex_byte)
    print 'Image written.'
    tty.delaybeforesend = default_delay

    print 'PC is now at: ', get_program_counter()

    reset_program_counter()

    print 'Continuing from break...'
    tty.send('c')

def program_through_loader():
    print 'Initiating data transfer...'
    tty.send('!')
    tty.expect('\?')
    size = len(image_bytes)
    print 'Sending size:', size, 'bytes...'
    tty.send(struct.pack('<H', size))
    tty.expect('!')
    print 'Sending data...'
    for bytes in [image_bytes[i:i+16] for i in range(0, len(image_bytes), 16)]:
        tty.send(bytes)

programmer_arg = sys.argv[1]
if programmer_arg == 'debugger':
    programmer = program_through_debugger
    print 'Programming through ZDI debugger...'
elif programmer_arg == 'loader':
    programmer = program_through_loader
    print 'Programming through loader program...'
else:
    raise Exception("Invalid programming method '" + programmer_arg + "'.")

image_filename = sys.argv[2]
print 'Loading binary image from', image_filename, '...'
image_file = open(image_filename, 'rb')
image_bytes = image_file.read()
image_file.close()

tty_filename = sys.argv[3]

print 'Opening', tty_filename, '...'
tty_file = os.open(tty_filename, os.O_RDWR|os.O_NONBLOCK|os.O_NOCTTY)
tty = fdpexpect.fdspawn(tty_file, timeout=3)

#tty.logfile = open("bin2ram.log", 'w')

try:
    programmer()
    os.close(tty_file)
    print 'Done!'
except pexpect.TIMEOUT:
    print "Timeout."
    exit(1)


