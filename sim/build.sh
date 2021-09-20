#/bin/sh

export WSLENV=PYTHONPATH/l
export PYTHONPATH=$PWD

rm -r __pycache__/  work cexports.obj cimports.dll dpiheader.h tb.obj lib.cp36-win32.pyd build/

vlib.exe work

export BASE=".." # "U:\home\tom01h\work\replica_salesman"

# cp ~/work/replica_salesman/sim/replica_salesman_sim.py .
# cp ~/work/replica_salesman/sim/top.py .
# cp ~/work/replica_salesman/sim/lib.cpp .

vlog.exe -sv -dpiheader   dpiheader.h               $BASE/rtl/replica_pkg.sv  $BASE/sim/tb.sv\
    $BASE/rtl/top.sv      $BASE/bus_if/bus_if.sv    $BASE/rtl/minimum.sv      $BASE/rtl/exp.sv \
    $BASE/rtl/node.sv     $BASE/rtl/sub_node.sv     $BASE/rtl/node_control.sv $BASE/rtl/node_reg.sv \
    $BASE/rtl/random.sv   $BASE/rtl/or_rand.sv      $BASE/rtl/tw_rand.sv \
    $BASE/rtl/distance.sv $BASE/rtl/metropolis.sv   $BASE/rtl/replica.sv      $BASE/rtl/replica_d.sv \
    $BASE/rtl/exchange.sv $BASE/rtl/opt_route_or.sv $BASE/rtl/opt_route_two.sv
vsim.exe tb -dpiexportobj cexports -c

python.exe $BASE/sim/setup_lib.py build_ext -i

dd if=/dev/zero of=tb.txt bs=1K count=1

#/mnt/c/intelFPGA_pro/20.3/modelsim_ase/gcc-4.2.1-mingw32vc12/bin/
g++.exe -O2 -c -g -I'.' -I'C:/intelFPGA_pro/20.3/modelsim_ase/include/' $BASE/sim/tb.cpp -o tb.obj
g++.exe -shared -o cimports.dll tb.obj cexports.obj -L'C:/intelFPGA_pro/20.3/modelsim_ase/win32aloem' -lmtipli

vsim.exe -c -sv_lib cimports tb -do " \
add wave -noupdate /tb/* -recursive; \
run 10us;quit -f" > /dev/null &

python.exe replica_salesman_sim.py

rm tb.txt

# rm replica_salesman_sim.py top.py lib.cpp