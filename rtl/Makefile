SHELL = /bin/bash

SIM_DIR   = sim
VERILATOR = verilator
TOP       = sim_top
PREFIX    = V$(TOP)

DESIGN_SRCS = \
replica_pkg.sv \
sim_top.sv \
replica_ram.sv \
opt_route.sv \

VERILATOR_CPP_TB = tb.cpp

VERILATOR_OPTS = \
	-Wall \
	-Wno-WIDTH \
	-Wno-UNUSED \
	-Wno-BLKSEQ \
	--cc \
	-Wno-fatal \
	+1364-2005ext+v \
	+1800-2017ext+sv \
	--top-module $(TOP) \
	--prefix $(PREFIX) \
	--Mdir $(SIM_DIR) \
	--trace

VERILATOR_MAKE_OPTS = OPT="-O3"

default: $(SIM_DIR)/$(PREFIX)

sim: $(SIM_DIR)/$(PREFIX)

$(SIM_DIR)/$(PREFIX): $(DESIGN_SRCS) $(VERILATOR_CPP_TB)
	$(VERILATOR) $(VERILATOR_OPTS) $(DESIGN_SRCS) --exe ../$(VERILATOR_CPP_TB)
	cd $(SIM_DIR); make $(VERILATOR_MAKE_OPTS) -f $(PREFIX).mk $(PREFIX)__ALL.a
	cd $(SIM_DIR); make $(VERILATOR_MAKE_OPTS) -f $(PREFIX).mk $(PREFIX)

clean:
	rm -rf $(SIM_DIR)/ tmp.vcd

.PHONY:
