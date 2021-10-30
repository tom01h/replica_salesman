#    IP base address = 0x20000000
import os

def init():
    global fd_h2c
    global fd_c2h

    fd_h2c = os.open("/dev/xdma0_h2c_0", os.O_WRONLY)
    fd_c2h = os.open("/dev/xdma0_c2h_0", os.O_RDONLY)
    return

def write64(address, data):
    os.pwrite(fd_h2c, data.to_bytes(8, byteorder='little'), address + 0x20000000)
    return

def read64(address):
    if address % 16 == 0:
        read64.rdata = int.from_bytes(os.pread(fd_c2h, 16, address + 0x20000000),'little')

    data = read64.rdata % (2 ** 64)
    read64.rdata = read64.rdata // (2 ** 64)
    return data

def vwait(cycle):
    return

def finish():
    return