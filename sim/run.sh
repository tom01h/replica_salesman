#/bin/sh

export WSLENV=PYTHONPATH/l
export PYTHONPATH=$PWD

dd if=/dev/zero of=tb.txt bs=1K count=1

vsim.exe -c -sv_lib cimports tb -do " \
add wave -noupdate /tb/* -recursive; \
run -all;quit -f" > /dev/null &

python.exe replica_salesman_sim.py

rm tb.txt