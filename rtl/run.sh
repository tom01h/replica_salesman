#/bin/sh

if [ ! -d work/ ]; then
    vlib.exe work
fi

vlog.exe replica_pkg.sv tb.sv sim_top.sv replica_ram.sv opt_route.sv

vsim.exe -c work.tb -lib work -do " \
add wave -noupdate /tb/* -recursive; \
run 1000ns; quit"

#add wave -noupdate /tb/sim_top/replica_ram/data ; \
#add wave -noupdate /tb/sim_top/replica_ram/ram ; \
