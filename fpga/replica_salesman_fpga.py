#    address = 0x00000  # run
#    address = 0x01000  # random seeds
#    address = 0x02000  # total distance
#    address = 0x08000  # ordering
#    address = 0x10000  # two point distance

nbeta=32
niter=3000
#niter=6
dbeta=5
ncity=30
ninit=2      # 0 -> read cities; 1 -> continue; 2 -> random config; 3 -> re run.

from pynq import Overlay
from pynq import MMIO

import numpy as np
import random
import math
import matplotlib.pyplot as plt
import pickle
import top as top

def py_tb():
    def calc_distance_i(ordering):
        distance = 0
        for icity in range(0, ncity):
            distance += distance_2[ordering[icity]][ordering[icity+1]]
        return distance

    def delta_distance_i(ordering, k, l, opt):
        if opt == 0:       # 2-opt
            delta  = distance_2[ordering[k-1]][ordering[l-1]] + distance_2[ordering[k]][ordering[l]]
            delta -= distance_2[ordering[k-1]][ordering[k]]   + distance_2[ordering[l-1]][ordering[l]]
        else:              # or-opt (simple)
            delta  = distance_2[ordering[k]][ordering[l+1]] + distance_2[ordering[k]][ordering[l]]   + distance_2[ordering[k-1]][ordering[k+1]]
            delta -= distance_2[ordering[k-1]][ordering[k]] + distance_2[ordering[k]][ordering[k+1]] + distance_2[ordering[l]][ordering[l+1]]
        return delta

    ordering = np.arange(0, ncity+1, 1)
    ordering = np.tile(ordering, (nbeta, 1))
    beta = np.arange(1, nbeta+1, 1, dtype = np.int32) * dbeta
    distance_list = []
    distance_i = np.zeros(nbeta, dtype = np.int32)
    distance_2 = np.zeros((ncity+1, ncity+1), dtype = np.int32)

    seeds = [random.randrange(1<<64) for i in range(nbeta)]

    if ninit == 0:
        with open("salesman.pickle", "rb") as f:
            x, _, _, _, _ = pickle.load(f)
    elif ninit == 1:
        with open("salesman.pickle", "rb") as f:
            x, ordering, minimum_ordering, minimum_distance, distance_list, seeds = pickle.load(f)
    elif ninit == 2:
        x = np.random.rand(ncity, 2)
        x = x.astype(np.float32)
        x = np.insert(x, ncity, x[0], axis=0)
    elif ninit == 3:
        with open("initial.pickle", "rb") as f:
            x, ordering, minimum_ordering, minimum_distance, distance_list, seeds = pickle.load(f)

    top.c_init_random(seeds)

    for icity in range(0, ncity+1):
        r = x[icity] - x
        r = r * r
        r = np.sum(r, axis=1)
        r = np.sqrt(r)
        distance_2[icity] = r*(2**17)

    for ibeta in range(0, nbeta):
        distance_i[ibeta] = calc_distance_i(ordering[ibeta])

    if ninit == 0 or ninit == 2:
        minimum_distance = distance_i[nbeta-1]/(2**17)
        minimum_ordering = ordering[nbeta-1].copy()

    # save point #
    with open("initial.pickle", "wb") as f:
        pickle.dump((x, ordering, minimum_ordering, minimum_distance, distance_list, seeds), f)

########### RTL Sim ###########

    #top.init()
    overlay = Overlay("./bit/replica_salesman.bit")

    mem_address = overlay.ip_dict['vtop_0/S_AXI']['phys_addr']
    mem_range = overlay.ip_dict['vtop_0/S_AXI']['addr_range']
    mm_mem = MMIO(mem_address, mem_range)

    address = 0x01000  # random seeds
    for data in seeds:
        mm_mem.write(address, data.to_bytes(8, byteorder='little'))
        address += 8
        
    address = 0x08000  # ordering
    for ibeta in [3,2,1,0, 7,6,5,4, 11,10,9,8, 15,14,13,12, 19,18,17,16, 23,22,21,20, 27,26,25,24, 31,30,29,28]:
        i = 0
        data = 0
        for c in ordering[ibeta]:
            data += int(c * 2 ** (i * 8))
            if i == 7:
                mm_mem.write(address, data.to_bytes(8, byteorder='little'))
                address += 8
                data = 0
                i = 0
            else:
                i += 1
        if i != 0:
            mm_mem.write(address, data.to_bytes(8, byteorder='little'))
            address += 8

    address = 0x10000  # two point distance
    for i in range(1, ncity+1):
        for j in range(0, i):
            data = int(distance_2[i][j])
            mm_mem.write(address, data.to_bytes(8, byteorder='little'))
            address += 8

    address = 0x02000  # total distance
    for ibeta in [3,2,1,0, 7,6,5,4, 11,10,9,8, 15,14,13,12, 19,18,17,16, 23,22,21,20, 27,26,25,24, 31,30,29,28]:
        data = int(distance_i[ibeta])
        mm_mem.write(address, data.to_bytes(8, byteorder='little'))
        address += 8

    address = 0x00000  # run
    data = niter
    mm_mem.write(address, data.to_bytes(8, byteorder='little'))

    while data != 0:
        data = mm_mem.read(address, 8, 'little')
        #top.vwait(100)

    rtl_ordering = np.zeros_like(ordering)

    address = 0x08000  # ordering
    #for ibeta in reversed(range(0, nbeta)):
    for ibeta in [3,2,1,0, 7,6,5,4, 11,10,9,8, 15,14,13,12, 19,18,17,16, 23,22,21,20, 27,26,25,24, 31,30,29,28]:
        for icity in range(0, ncity+1):
            if icity % 8 == 0:
                data = mm_mem.read(address, 8, 'little')
                address += 8

            c = data // 256**(7-icity%8) % 256
            rtl_ordering[ibeta][icity] = c
    
    rtl_distance_i = np.zeros_like(distance_i)

    address = 0x02000  # total distance
    #for ibeta in reversed(range(0, nbeta)):
    for ibeta in [3,2,1,0, 7,6,5,4, 11,10,9,8, 15,14,13,12, 19,18,17,16, 23,22,21,20, 27,26,25,24, 31,30,29,28]:
        rtl_distance_i[ibeta] = mm_mem.read(address, 8, 'little')
        address += 8

########### RTL Sim ###########

    # Main loop #
    for iter in range(1, niter+1):
        opt = iter % 2
        for ibeta in range(0, nbeta):
            info_kl = 1
            while info_kl == 1:
                if opt == 0:       # 2-opt
                    msk = ( 1<<(math.ceil(math.log2(ncity))) ) -1
                    k = top.c_run_random(ibeta, 1, ncity, msk)
                    l = top.c_run_random(ibeta, 1, ncity, msk)
                    if k != l:
                        if k > l:
                            k, l = l, k
                        info_kl = 0
                else:              # or-opt (simple)
                    msk = ( 1<<(math.ceil(math.log2(ncity-1))) ) -1
                    k = top.c_run_random(ibeta, 1, ncity-1, msk)
                    l = top.c_run_random(ibeta, 0, ncity-1, msk)
                    if k != l and k != l + 1:
                        info_kl = 0
            # Metropolis for each replica #
            if opt == 0:       # 2-opt
                ordering_fin = np.hstack((ordering[ibeta][0:k], ordering[ibeta][k:l][::-1], ordering[ibeta][l:]))
            else:              # or-opt (simple)
                p = ordering[ibeta][k]
                ordering_fin = np.hstack((ordering[ibeta][0:k], ordering[ibeta][k+1:]))
                if k < l:
                    ordering_fin = np.hstack((ordering_fin[0:l],   p, ordering_fin[l:]))
                else:
                    ordering_fin = np.hstack((ordering_fin[0:l+1], p, ordering_fin[l+1:]))
            delta_distance = delta_distance_i(ordering[ibeta], k, l, opt)
            # Metropolis test #
            metropolis = (top.c_run_random(ibeta, 0, 2**23-1, 2**23-1))
            if delta_distance < 0 or top.c_exp(int(-delta_distance * beta[ibeta]), 15) > metropolis:
                distance_i[ibeta] += delta_distance
                ordering[ibeta] = ordering_fin.copy()

        # Exchange replicas #
        if opt == 0:       # 2-opt
            for ibeta in range(0, nbeta-1, 2):
                action = (distance_i[ibeta+1] - distance_i[ibeta]) * dbeta
                # Metropolis test #
                metropolis = (top.c_run_random(ibeta, 0, 2**23-1, 2**23-1))
                if action >=0 or top.c_exp(action, 15) > metropolis:
                    ordering[ibeta],   ordering[ibeta+1]   = ordering[ibeta+1].copy(), ordering[ibeta].copy()
                    distance_i[ibeta], distance_i[ibeta+1] = distance_i[ibeta+1],      distance_i[ibeta]
        else:
            metropolis = (top.c_run_random(0, 0, 2**23-1, 2**23-1))  # dummy
            for ibeta in range(2, nbeta-1, 2):
                action = (distance_i[ibeta] - distance_i[ibeta-1]) * dbeta
                # Metropolis test #
                metropolis = (top.c_run_random(ibeta, 0, 2**23-1, 2**23-1))
                if action >=0 or top.c_exp(action, 15) > metropolis:
                    ordering[ibeta-1],   ordering[ibeta]   = ordering[ibeta].copy(), ordering[ibeta-1].copy()
                    distance_i[ibeta-1], distance_i[ibeta] = distance_i[ibeta],      distance_i[ibeta-1]
        for ibeta in range(1, nbeta, 2):
            metropolis = (top.c_run_random(ibeta, 0, 2**23-1, 2**23-1))  # dummy

        # data output #
        if iter % 50 == 0 or iter == niter:
            distance_f = distance_i[nbeta-1]/(2**17)
            if distance_f < minimum_distance:
                minimum_distance = distance_f
                minimum_ordering = ordering[nbeta-1].copy()
            distance_list = np.append(distance_list, minimum_distance)
            print(iter, distance_f, minimum_distance)

    np.set_printoptions(linewidth = 100)
    # compare ordiering #
    if(np.array_equal(ordering, rtl_ordering)):
        print("OK: ordering")
    else:
        for ibeta in range(0, nbeta):
            if(not np.array_equal(ordering[ibeta], rtl_ordering[ibeta])):
                print("NG: ordering", ibeta)
                print(ordering[ibeta])
                print(rtl_ordering[ibeta])

    # compare total distance #
    if(np.array_equal(distance_i, rtl_distance_i)):
        print("OK: total distance")
    else:
        print("NG: total distance")
        print(distance_i)
        print(rtl_distance_i)

    # save point #
    seeds = top.c_save_random()
    with open("salesman.pickle", "wb") as f:
        pickle.dump((x, ordering, minimum_ordering, minimum_distance, distance_list, seeds), f)

    """
    fig = plt.figure()
    ax = fig.add_subplot(111)
    orderd = x[minimum_ordering].T
    plt.plot(orderd[0], orderd[1], marker='+')
    plt.axis([0, 1, 0, 1])
    ax.set_aspect('equal', adjustable='box')
    plt.savefig("salesman.png")
    plt.clf()

    plt.plot(distance_list[::2], marker='+')
    plt.savefig("distance.png")
    plt.clf()
    """

    return

if __name__ == '__main__':
    py_tb()
    #top.fin()
