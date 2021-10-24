from pynq import Overlay
from pynq import MMIO

def init():
    overlay = Overlay("./bit/replica_salesman.bit")

    mem_address = overlay.ip_dict['vtop_0/S_AXI']['phys_addr']
    mem_range = overlay.ip_dict['vtop_0/S_AXI']['addr_range']
    global mm_mem
    mm_mem = MMIO(mem_address, mem_range)
    return

def write64(address, data):
    mm_mem.write(address, data.to_bytes(8, byteorder='little'))
    return

def read64(address):
    return mm_mem.read(address, 8, 'little')

def vwait(cycle):
    return

def finish():
    return