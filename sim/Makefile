SHELL = /bin/bash

SIM_DIR = sim
VERILATOR = verilator
TOP       = top
PREFIX    = V$(TOP)

VERILATOR_OPTS = \
	-Wall \
	-Wno-WIDTH \
	-Wno-UNUSED \
	-Wno-BLKSEQ \
	--cc \
	+1364-2005ext+v \
	+1800-2017ext+sv \
	-Wno-fatal \
	--Mdir $(SIM_DIR) \
	--top-module $(TOP) \
	--prefix $(PREFIX) \
	#--trace \
	--trace-params \
	--trace-structs \
	--trace-underscore \
	--trace-depth 2 \


VERILATOR_MAKE_OPTS = OPT_FAST="-O2"

DESIGN_SRCS = \
../rtl/replica_pkg.sv \
../rtl/top.sv \
../bus_if/bus_if.sv \
../rtl/exp.sv\
../rtl/node.sv \
../rtl/sub_node.sv \
../rtl/node_control.sv \
../rtl/node_reg.sv \
../rtl/random.sv \
../rtl/distance.sv \
../rtl/metropolis.sv \
../rtl/replica.sv \
../rtl/replica_d.sv \
../rtl/exchange.sv \
../rtl/opt_route_or.sv \
../rtl/opt_route_two.sv \

VERILATOR_CPP_TB = top.cpp

default: $(SIM_DIR)/$(PREFIX)

sim: $(SIM_DIR)/$(PREFIX)

$(SIM_DIR)/Vtop: $(DESIGN_SRCS) $(VERILATOR_CPP_TB)
	$(VERILATOR) $(VERILATOR_OPTS) $(DESIGN_SRCS) --exe ../$(VERILATOR_CPP_TB)
	cp /usr/local/share/verilator/include/verilated.cpp .
	cp /usr/local/share/verilator/include/verilated_vcd_c.cpp .
	python3 setup.py build_ext -I/usr/local/share/verilator/include -i
	#python3 setup_trace.py build_ext -I/usr/local/share/verilator/include -i

clean:
	rm -rf build/ sim/ tmp.vcd *.so cp verilated.cpp verilated_vcd_c.cpp

.PHONY:
