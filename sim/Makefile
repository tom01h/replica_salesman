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

VERILATOR_MAKE_OPTS = OPT_FAST="-O3"

DESIGN_SRCS = \
../rtl/replica_pkg.sv \
top.sv \
../rtl/replica_ram.sv \
../rtl/opt_route.sv \

VERILATOR_CPP_TB = tb.cpp

default: $(SIM_DIR)/$(PREFIX)

sim: $(SIM_DIR)/$(PREFIX)

$(SIM_DIR)/Vtop: $(DESIGN_SRCS) $(VERILATOR_CPP_TB)
	$(VERILATOR) $(VERILATOR_OPTS) $(DESIGN_SRCS) --exe ../$(VERILATOR_CPP_TB)
	cd $(SIM_DIR); make $(VERILATOR_MAKE_OPTS) -f $(PREFIX).mk $(PREFIX)__ALL.a
	cp /usr/local/share/verilator/include/verilated.cpp .
	cp /usr/local/share/verilator/include/verilated_vcd_c.cpp .
	python3 setup.py build_ext -I/usr/local/share/verilator/include -i

clean:
	rm -rf build/ sim/ tmp.vcd *.so cp verilated.cpp verilated_vcd_c.cpp

.PHONY:
