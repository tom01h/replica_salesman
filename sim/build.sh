#/bin/sh

export WSLENV=PYTHONPATH/l
export PYTHONPATH=$PWD

rm -r __pycache__/  work cexports.obj cimports.dll dpiheader.h tb.obj

vlib.exe work

export BASE=".." # "U:\home\tom01h\work\replica_salesman"

# cp ~/work/replica_salesman/sim/replica_salesman_sim.py .

vlog.exe -sv -dpiheader   dpiheader.h            $BASE/rtl/replica_pkg.sv $BASE/sim/tb.sv\
    $BASE/rtl/top.sv      $BASE/bus_if/bus_if.sv    $BASE/rtl/exp.sv      $BASE/rtl/node.sv \
    $BASE/rtl/sub_node.sv $BASE/rtl/node_control.sv $BASE/rtl/node_reg.sv \
    $BASE/rtl/random.sv   $BASE/rtl/or_rand.sv      $BASE/rtl/tw_rand.sv \
    $BASE/rtl/distance.sv $BASE/rtl/metropolis.sv   $BASE/rtl/replica.sv  $BASE/rtl/replica_d.sv \
    $BASE/rtl/exchange.sv $BASE/rtl/opt_route_or.sv $BASE/rtl/opt_route_two.sv
vsim.exe tb -dpiexportobj cexports -c

#/mnt/c/intelFPGA_pro/20.3/modelsim_ase/gcc-4.2.1-mingw32vc12/bin/
g++.exe -c -g -I'C:/intelFPGA_pro/20.3/modelsim_ase/include/' $BASE/sim/tb.cpp -o tb.obj -I"C:/Users/tom01/AppData/Local/Programs/Python/Python36-32/include/"
g++.exe -shared -o cimports.dll tb.obj cexports.obj -L'C:/intelFPGA_pro/20.3/modelsim_ase/win32aloem' -lmtipli -L"C:/Users/tom01/AppData/Local/Programs/Python/Python36-32/libs/" -lpython36

vsim.exe -c -sv_lib cimports tb -do " \
add wave -noupdate /tb/* -recursive; \
run 10us;quit -f"

# rm replica_salesman_sim.py