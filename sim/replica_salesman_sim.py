nbeta=32
#niter=3000
niter=6
dbeta=5e0
ncity=30
ninit=2      # 0 -> read cities; 1 -> continue; 2 -> random config.

import sys
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

    minimum_distance = 100e0
    ordering = np.arange(0, ncity+1, 1)
    ordering = np.tile(ordering, (nbeta, 1))
    beta = np.arange(1, nbeta+1, 1, dtype = np.float32) * dbeta
    distance_list = []
    distance_i = np.zeros(nbeta, dtype = np.int32)
    distance_2 = np.zeros((ncity+1, ncity+1), dtype = np.int32)

    top.init()

    seeds = [random.randrange(1<<64) for i in range(nbeta)]
    top.c_init_random(seeds)
    top.set_random(seeds)
        
    if ninit == 0:
        with open("salesman.pickle", "rb") as f:
            x, _, _, _, _ = pickle.load(f)
    elif ninit == 1:
        with open("salesman.pickle", "rb") as f:
            x, ordering, minimum_ordering, minimum_distance, distance_list = pickle.load(f)
    elif ninit == 2:
        x = np.random.rand(ncity, 2)
        x = x.astype(np.float32)
        x = np.insert(x, ncity, x[0], axis=0)

    for ibeta in reversed(range(0, nbeta)):
        top.set_ordering(ordering[ibeta].tolist())

    for icity in range(0, ncity+1):
        r = x[icity] - x
        r = r * r
        r = np.sum(r, axis=1)
        r = np.sqrt(r)
        distance_2[icity] = r*(2**17)
    top.set_distance(ncity+1, distance_2.ravel().tolist())

    for ibeta in range(0, nbeta):
        distance_i[ibeta] = calc_distance_i(ordering[ibeta])
    top.set_total(distance_i.tolist())

    # Main loop #
    for iter in range(1, niter+1):
        opt_list = np.zeros(nbeta, dtype = np.int32)
        opt = iter % 2
        for ibeta in range(0, nbeta):
            opt_list[ibeta] = opt*2+1
        top.run_random(opt_list.tolist())
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
            metropolis = random.random()
            if math.exp(-delta_distance/(2**17) * beta[ibeta]) > metropolis:
                distance_i[ibeta] += delta_distance
                ordering[ibeta] = ordering_fin.copy()
                if opt == 0:       # 2-opt
                    opt_com = 1
                else:              # or-opt (simple)
                    if k < l:
                        opt_com = 2
                    else:
                        opt_com = 3
            else:
                opt_com = 0
            opt_list[ibeta] = opt_com
        top.delta_distance(opt_list.tolist())

        # Exchange replicas #
        if(iter%2):
            top.set_command(1)
        for ibeta in range(iter % 2, nbeta-1, 2):
            action = (distance_i[ibeta+1] - distance_i[ibeta]) * dbeta
            # Metropolis test #
            metropolis = random.random()
            if math.exp(action/(2**17)) > metropolis:
                ordering[ibeta],   ordering[ibeta+1]   = ordering[ibeta+1].copy(), ordering[ibeta].copy()
                distance_i[ibeta], distance_i[ibeta+1] = distance_i[ibeta+1],      distance_i[ibeta]
                top.set_command(3)
                top.set_command(2)
            else:
                top.set_command(1)
                top.set_command(1)
        if(iter%2):
            top.set_command(1)
        top.run_opt(0)

        # data output #
        if iter % 50 == 0 or iter == niter:
            distance_32 = distance_i[31]/(2**17)
            if distance_32 < minimum_distance:
                minimum_distance = distance_32
                minimum_ordering = ordering[nbeta-1].copy()
            distance_list = np.append(distance_list, minimum_distance)
            print(iter, distance_32, minimum_distance)

    # compare ordiering #
    rtl_ordering = np.zeros_like(ordering)
    for ibeta in reversed(range(0, nbeta)):
        rtl_ordering[ibeta] = top.get_ordering(ncity+1)

    np.set_printoptions(linewidth = 100)
    if(np.array_equal(ordering, rtl_ordering)):
        print("OK: ordering")
    else:
        for ibeta in range(0, nbeta):
            if(not np.array_equal(ordering[ibeta], rtl_ordering[ibeta])):
                print("NG: ordering", ibeta)
                print(ordering[ibeta])
                print(rtl_ordering[ibeta])

    # compare total distance #
    rtl_distance_i = np.flip(top.get_total(nbeta))
    if(np.array_equal(distance_i, rtl_distance_i)):
        print("OK: total distance")
    else:
        print("NG: total distance")
        print(distance_i)
        print(rtl_distance_i)

    # save point #
    top.fin()

    with open("salesman.pickle", "wb") as f:
        pickle.dump((x, ordering, minimum_ordering, minimum_distance, distance_list), f)

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

    return

if __name__ == '__main__':
    py_tb()