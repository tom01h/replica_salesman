import matplotlib.pyplot as plt
import numpy as np
import math
import fmath

l = np.arange(-60, -20)
x  = np.copy(l) / 10
y9 = np.copy(x)
yf = np.copy(x)

e = math.e

y = e**x

idx = 0
for i in l:
    y9[idx] = fmath.exp(i, 9) / (1<<23)
    yf[idx] = fmath.exp(i, 15) / (1<<23)
    idx += 1

fig = plt.figure()
plt.plot(x, y)
plt.plot(x, yf)
plt.plot(x, y9)
plt.savefig("exp.png")
plt.clf()
