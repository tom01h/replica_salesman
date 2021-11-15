#    address = 0x00000  # run
#    address = 0x00010  # siter
#    address = 0x00f00  # reset
#    address = 0x01000  # random seeds
#    address = 0x02000  # total distance
#    address = 0x03000  # minimum ordering
#    address = 0x04000  # saved distance
#    address = 0x08000  # ordering
#    address = 0x10000  # two point distance

nbeta=160
node_num = 4
siter=5000
niter=2000000
dbeta=5
ncity=100
ninit=2      # 0 -> read cities; 1 -> continue; 2 -> random config; 3 -> re run.

import time
import numpy as np
import random
import math
import matplotlib
matplotlib.use('Agg')
import matplotlib.pyplot as plt
import pickle
import lib
import top_pico as top

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

    global distance_list

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

    lib.c_init_random(seeds)

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

    top.init()

    address = 0x00f00  # soft_reset
    data = 0
    top.write64(address, data)

    address = 0x01000  # random seeds
    for data in seeds:
        top.write64(address, data)
        address += 8
        
    ordering_list = np.arange(nbeta).reshape((-1, node_num))
    ordering_list = np.fliplr(ordering_list).reshape(-1)
    address = 0x08000  # ordering
    for ibeta in ordering_list:
        i = 0
        data = 0
        for c in ordering[ibeta]:
            data += int(c * 2 ** (i * 8))
            if i == 7:
                top.write64(address, data)
                address += 8
                data = 0
                i = 0
            else:
                i += 1
        if i != 0:
            top.write64(address, data)
            address += 8

    address = 0x10000  # two point distance
    for i in range(1, ncity+1):
        for j in range(0, i):
            data = int(distance_2[i][j])
            top.write64(address, data)
            address += 8

    address = 0x02000  # total distance
    for ibeta in ordering_list:
        data = int(distance_i[ibeta])
        top.write64(address, data)
        address += 8

    address = 0x00010  # siter
    data = siter
    top.write64(address, data)

    address = 0x00000  # run
    data = niter
    top.write64(address, data)

    start = time.perf_counter()

    while data != 0:
        data = top.read64(address)
        top.vwait(100)

    elapsed_time = time.perf_counter() - start
    print ("FPGA_time:{0}".format(elapsed_time) + "[sec]")
    
    rtl_minimum_ordering = np.zeros_like(minimum_ordering)
    rtl_ordering = np.zeros_like(ordering)
    rtl_seeds    = np.zeros_like(seeds)
    rtl_distance_list = []

    address = 0x03000  # minimum ordering
    for icity in range(0, ncity+1):
        if icity % 8 == 0:
            data = top.read64(address)
            address += 8

        c = data // 256**(7-icity%8) % 256
        rtl_minimum_ordering[icity] = c

    address = 0x08000  # ordering
    #for ibeta in reversed(range(0, nbeta)):
    for ibeta in ordering_list:
        for icity in range(0, ncity+1):
            if icity % 8 == 0:
                data = top.read64(address)
                address += 8

            c = data // 256**(7-icity%8) % 256
            rtl_ordering[ibeta][icity] = c

    rtl_distance_i = np.zeros_like(distance_i)

    address = 0x02000  # total distance
    #for ibeta in reversed(range(0, nbeta)):
    for ibeta in ordering_list:
        rtl_distance_i[ibeta] = top.read64(address)
        address += 8

    address = 0x01000  # random seeds
    for i in range(nbeta):
        rtl_seeds[i] = top.read64(address)
        address += 8

    address = 0x04000  # saved distance
    for i in range(niter//siter):
        rtl_distance_list = np.append(rtl_distance_list, top.read64(address)/(2**17))
        address += 8

    address = 0x00f00  # soft_reset
    data = 1
    top.write64(address, data)

########### RTL Sim ###########
    '''########### Golden Model ###########

    start = time.perf_counter()

    # Main loop #
    for iter in range(1, niter+1):
        opt = iter % 2
        for ibeta in range(0, nbeta):
            info_kl = 1
            while info_kl == 1:
                if opt == 0:       # 2-opt
                    msk = ( 1<<(math.ceil(math.log2(ncity))) ) -1
                    k = lib.c_run_random(ibeta, 1, ncity, msk)
                    l = lib.c_run_random(ibeta, 1, ncity, msk)
                    if k != l:
                        if k > l:
                            k, l = l, k
                        info_kl = 0
                else:              # or-opt (simple)
                    msk = ( 1<<(math.ceil(math.log2(ncity-1))) ) -1
                    k = lib.c_run_random(ibeta, 1, ncity-1, msk)
                    l = lib.c_run_random(ibeta, 0, ncity-1, msk)
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
            metropolis = (lib.c_run_random(ibeta, 0, 2**23-1, 2**23-1))
            if delta_distance < 0 or lib.c_exp(int(-delta_distance * beta[ibeta]), 15) > metropolis:
                distance_i[ibeta] += delta_distance
                ordering[ibeta] = ordering_fin.copy()

        # Exchange replicas #
        if opt == 0:       # 2-opt
            for ibeta in range(0, nbeta-1, 2):
                action = (distance_i[ibeta+1] - distance_i[ibeta]) * dbeta
                # Metropolis test #
                metropolis = (lib.c_run_random(ibeta, 0, 2**23-1, 2**23-1))
                if action >=0 or lib.c_exp(action, 15) > metropolis:
                    ordering[ibeta],   ordering[ibeta+1]   = ordering[ibeta+1].copy(), ordering[ibeta].copy()
                    distance_i[ibeta], distance_i[ibeta+1] = distance_i[ibeta+1],      distance_i[ibeta]
        else:
            metropolis = (lib.c_run_random(0, 0, 2**23-1, 2**23-1))  # dummy
            for ibeta in range(2, nbeta-1, 2):
                action = (distance_i[ibeta] - distance_i[ibeta-1]) * dbeta
                # Metropolis test #
                metropolis = (lib.c_run_random(ibeta, 0, 2**23-1, 2**23-1))
                if action >=0 or lib.c_exp(action, 15) > metropolis:
                    ordering[ibeta-1],   ordering[ibeta]   = ordering[ibeta].copy(), ordering[ibeta-1].copy()
                    distance_i[ibeta-1], distance_i[ibeta] = distance_i[ibeta],      distance_i[ibeta-1]
        for ibeta in range(1, nbeta, 2):
            metropolis = (lib.c_run_random(ibeta, 0, 2**23-1, 2**23-1))  # dummy

        # update minimum #
        if iter % 2 == 0: # 2-opt 結果だけを対象にする
            distance_f = distance_i[nbeta-1]/(2**17)
            if distance_f < minimum_distance:
                minimum_distance = distance_f
                minimum_ordering = ordering[nbeta-1].copy()

        # data output #
        if iter % siter == 0 or iter == niter: # if 0: 時間計測時
            distance_list = np.append(distance_list, minimum_distance)
            print(iter, distance_f, minimum_distance)

    elapsed_time = time.perf_counter() - start
    print ("model_time:{0}".format(elapsed_time) + "[sec]")
    
    seeds = lib.c_save_random()

    np.set_printoptions(linewidth = 100)
    # compare minimum ordiering #
    if(np.array_equal(minimum_ordering, rtl_minimum_ordering)):
        print("OK: minimum ordering")
    else:
        print("NG: minimum ordering")
        print(minimum_ordering)
        print(rtl_minimum_ordering)

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

    # compare random seeds #
    if(np.array_equal(seeds, rtl_seeds)):
        print("OK: random seeds")
    else:
        print("NG: random seeds")
        print(seeds)
        print(rtl_seeds)

    # compare saved distance #
    if(np.array_equal(distance_list, rtl_distance_list)):
        print("OK: saved distance")
    else:
        print("NG: saved distance")
        print(distance_list)
        print(rtl_distance_list)

    '''########### Golden Model ###########
    ########### SKIP Golden Model ###########
    minimum_ordering = rtl_minimum_ordering
    ordering = rtl_ordering
    distance_i = rtl_distance_i
    seeds = rtl_seeds
    distance_list = rtl_distance_list
    ########### SKIP Golden Model ###########

    # save point #
    with open("salesman.pickle", "wb") as f:
        pickle.dump((x, ordering, minimum_ordering, minimum_distance, distance_list, seeds), f)

    global orderd
    orderd = x[minimum_ordering].T

    return

if __name__ == '__main__':
    py_tb()

    fig = plt.figure()
    ax = fig.add_subplot(111)
    plt.plot(orderd[0], orderd[1], marker='+')
    plt.axis([0, 1, 0, 1])
    ax.set_aspect('equal', adjustable='box')
    plt.savefig("salesman.png")
    plt.clf()

    plt.plot(distance_list[::1], marker='+')
    plt.ylim(0, 10)
    plt.savefig("distance.png")
    plt.clf()

    top.finish()