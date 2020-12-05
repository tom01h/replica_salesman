#/bin/sh

export WSLENV=PYTHONPATH/l
export PYTHONPATH=$PWD

rm -r __pycache__/  work cexports.obj cimports.dll dpiheader.h tb.obj

vlib.exe work

vlog.exe -sv -dpiheader dpiheader.h ../rtl/replica_pkg.sv tb.sv top.sv \
    ../rtl/replica.sv ../rtl/random.sv  ../rtl/distance.sv ../rtl/exchange.sv \
    ../rtl/metropolis.sv ../rtl/opt_route.sv
vsim.exe tb -dpiexportobj cexports -c

#/mnt/c/intelFPGA_pro/20.3/modelsim_ase/gcc-4.2.1-mingw32vc12/bin/
g++.exe -c -g -I'C:/intelFPGA_pro/20.3/modelsim_ase/include/' tb.cpp -o tb.obj -I"C:/Users/tom01/AppData/Local/Programs/Python/Python36-32/include/"
g++.exe -shared -o cimports.dll tb.obj cexports.obj -L'C:/intelFPGA_pro/20.3/modelsim_ase/win32aloem' -lmtipli -L"C:/Users/tom01/AppData/Local/Programs/Python/Python36-32/libs/" -lpython36

vsim.exe -c -sv_lib cimports tb -do " \
add wave -noupdate /tb/* -recursive; \
run 10us;quit -f"