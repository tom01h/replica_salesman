#/bin/sh

dd if=/dev/zero of=tb.txt bs=1K count=1

./sim/Vtop &
python3 replica_salesman_sim.py

rm tb.txt