nbeta=32
niter=3000
dbeta=5e0
ncity=30
ninit=2      # 0 -> read cities; 1 -> continue; 2 -> random config.

import sys
import numpy as np
import random
import math
import matplotlib.pyplot as plt
import pickle

def calc_distance(x, ordering):
    orderd = x[ordering]
    r = orderd[1:] - orderd[:-1]
    r = r * r
    r = np.sum(r, axis=1)
    r = np.sqrt(r)
    return np.sum(r)

minimum_distance = 100e0
ordering = np.arange(0, ncity+1, 1)
ordering = np.tile(ordering, (nbeta, 1))
beta = np.arange(1, nbeta+1, 1, dtype = np.float32) * dbeta
distance_list = []

if ninit == 0:
    with open("salesman.pickle", "rb") as f:
        x, _, _, _, _ = pickle.load(f)
elif ninit == 1:
    with open("salesman.pickle", "rb") as f:
        x, ordering, minimum_ordering, minimum_distance, distance_list = pickle.load(f)
elif ninit == 2:
    x = np.random.rand(100, 2)
    x = x.astype(np.float32)
    x = np.insert(x, ncity, x[0], axis=0)

distance = np.zeros(nbeta, dtype = np.float32)
for ibeta in range(0, nbeta):
    distance[ibeta] = calc_distance(x, ordering[ibeta])

# Main loop #
for iter in range(1, niter+1):
    for ibeta in range(0, nbeta):
        info_kl = 1
        while info_kl == 1:
            k = random.randrange(1, ncity)
            l = random.randrange(1, ncity)
            if k != l:
                if k > l and iter % 2 == 0:
                    k, l = l, k
                info_kl = 0
        # Metropolis for each replica #
        if iter % 2 == 0:  # 2-opt
            ordering_fin = np.hstack((ordering[ibeta][0:k], ordering[ibeta][k:l][::-1], ordering[ibeta][l:]))
        else:              # or-opt (simple)
            p = ordering[ibeta][k]
            ordering_fin = np.hstack((ordering[ibeta][0:k], ordering[ibeta][k+1:]))
            if k < l:
                ordering_fin = np.hstack((ordering_fin[0:l],   p, ordering_fin[l:]))
            else:
                ordering_fin = np.hstack((ordering_fin[0:l+1], p, ordering_fin[l+1:]))
        distance_fin = calc_distance(x, ordering_fin)
        action_fin = distance_fin * beta[ibeta]
        action_init = distance[ibeta] * beta[ibeta]
        # Metropolis test #
        metropolis = random.random()
        if math.exp(action_init - action_fin) > metropolis:
            distance[ibeta] = distance_fin
            ordering[ibeta] = ordering_fin.copy()
    # Exchange replicas #
    for ibeta in range(iter % 2, nbeta-1, 2):
        action_init  = distance[ibeta] * beta[ibeta]   + distance[ibeta+1] * beta[ibeta+1]
        action_fin   = distance[ibeta] * beta[ibeta+1] + distance[ibeta+1] * beta[ibeta]
        # Metropolis test #
        metropolis = random.random()
        if math.exp(action_init - action_fin) > metropolis:
            ordering[ibeta], ordering[ibeta+1] = ordering[ibeta+1].copy(), ordering[ibeta].copy()
            distance[ibeta], distance[ibeta+1] = distance[ibeta+1],        distance[ibeta]
    # data output #
    if iter % 50 == 0:
        distance_32 = distance[31]
        if distance_32 < minimum_distance:
            minimum_distance = distance_32
            minimum_ordering = ordering[nbeta-1].copy()
        distance_list = np.append(distance_list, minimum_distance)
        print(iter, distance_32, minimum_distance)

# save point #
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