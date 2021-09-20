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
	--trace \
	--trace-params \
	--trace-underscore \
	#--trace-depth 2 \
	#--trace-structs \


VERILATOR_MAKE_OPTS = OPT_FAST="-O2 -DTRACE"

DESIGN_SRCS = \
../rtl/replica_pkg.sv \
../rtl/top.sv \
../bus_if/bus_if.sv \
../rtl/minimum.sv\
../rtl/exp.sv\
../rtl/node.sv \
../rtl/sub_node.sv \
../rtl/node_control.sv \
../rtl/node_reg.sv \
../rtl/random.sv \
../rtl/or_rand.sv \
../rtl/tw_rand.sv \
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

$(SIM_DIR)/$(PREFIX): $(DESIGN_SRCS) $(VERILATOR_CPP_TB)
	python3 setup_lib.py build_ext -i
	$(VERILATOR) $(VERILATOR_OPTS) $(DESIGN_SRCS) --exe ../$(VERILATOR_CPP_TB)
	cd sim; make $(VERILATOR_MAKE_OPTS) -f $(PREFIX).mk $(PREFIX)__ALL.a
	cd sim; make $(VERILATOR_MAKE_OPTS) -f $(PREFIX).mk $(PREFIX)

clean:
	rm -rf sim/ build/ __pycache__/ tmp.vcd lib.cpython-38-x86_64-linux-gnu.so

.PHONY:
