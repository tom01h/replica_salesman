#include "verilated.h"
#include "verilated_vcd_c.h"
#include "Vsim_top.h"

vluint64_t main_time = 0;
vluint64_t vcdstart = 0;
vluint64_t vcdend = vcdstart + 300000;

VerilatedVcdC* tfp;
Vsim_top* verilator_top;

void eval()
{
  // negedge clk /////////////////////////////
  verilator_top->clk = 0;

  verilator_top->eval();

  if((main_time>=vcdstart)&((main_time<vcdend)|(vcdend==0)))
    tfp->dump(main_time);
  main_time += 5;

  // posegedge clk /////////////////////////////
  verilator_top->clk = 1;

  verilator_top->eval();

  if((main_time>=vcdstart)&((main_time<vcdend)|(vcdend==0)))
    tfp->dump(main_time);
  main_time += 5;

  return;
}

int main(int argc, char **argv) {

  // Verilator setup /////////////////////////////
  Verilated::commandArgs(argc, argv);
  Verilated::traceEverOn(true);
  tfp = new VerilatedVcdC;
  verilator_top = new Vsim_top;
  verilator_top->trace(tfp, 99); // requires explicit max levels param
  tfp->open("tmp.vcd");
  main_time = 0;

  // initial begin /////////////////////////////
  verilator_top->reset = 1;
  verilator_top->eval();
  tfp->dump(main_time);
  main_time += 5;

  eval();eval();
  verilator_top->reset = 0;
  eval();eval();

  // $finish; end /////////////////////////////
  while (!Verilated::gotFinish()) {
    eval();
  }
  delete verilator_top;
  tfp->close();
  return 0;
}
