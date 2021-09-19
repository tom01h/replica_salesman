'''
"top1: init"
"top2: write64"
"top3: read64"
"top4: vwait"
"top5: finish"
'''

import mmap

def init():
    f = open("tb.txt", "r+b")
    global mm
    mm = mmap.mmap(f.fileno(), 0)
    mm[0:1] = b"\1"
    while mm[0:1] != b'\0':
        pass
    return

def write64(address, data):
    mm[8:16] = address.to_bytes(8, byteorder='little')
    mm[16:24] = data.to_bytes(8, byteorder='little', signed=False)
    mm[0:1] = b"\2"
    while mm[0:1] != b'\0':
        pass
    return

def read64(address):
    mm[8:16] = address.to_bytes(8, byteorder='little')
    mm[0:1] = b"\3"
    while mm[0:1] != b'\0':
        pass
    data = int.from_bytes(mm[16:24], byteorder='little', signed=False)
    return data

def vwait(num):
    mm[8:16] = num.to_bytes(8, byteorder='little')
    mm[0:1] = b"\4"
    while mm[0:1] != b'\0':
        pass
    return

def finish():
    mm[0:1] = b"\5"
    while mm[0:1] != b'\0':
        pass
    return