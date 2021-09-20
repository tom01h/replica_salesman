#include "sim/Vtop.h"
#include "verilated.h"

#include <sys/types.h>
#include <sys/stat.h>
#include <fcntl.h>
#include <sys/mman.h>

union ulong_char {
    char c[8];
    unsigned long long ul;
    int i;
};

vluint64_t vcdstart = 0;
vluint64_t vcdend = vcdstart + 300000;
vluint64_t main_time;
Vtop* verilator_top;
#if TRACE  
#include "verilated_vcd_c.h"
VerilatedVcdC* tfp;
#endif
void eval()
{
  // negedge clk /////////////////////////////
  verilator_top->clk = 0;

  verilator_top->eval();

#if TRACE  
  if((main_time>=vcdstart)&((main_time<vcdend)|(vcdend==0)))
    tfp->dump(main_time);
#endif
  main_time += 5;

  // posegedge clk /////////////////////////////
  verilator_top->clk = 1;

  verilator_top->eval();

#if TRACE  
  if((main_time>=vcdstart)&((main_time<vcdend)|(vcdend==0)))
    tfp->dump(main_time);
#endif  
  main_time += 5;

  return;
}

void init () {
  return;
}

void write64(int address, unsigned long long data) {
  verilator_top->S_AXI_AWADDR = address;
  verilator_top->S_AXI_AWVALID = 1;
  verilator_top->S_AXI_WDATA = data;
  verilator_top->S_AXI_WVALID = 1;
  eval();
  verilator_top->S_AXI_AWVALID = 0;
  verilator_top->S_AXI_WVALID = 0;
  eval();

  return;
}

unsigned long long read64(int  address) {
  unsigned long long data;
  verilator_top->S_AXI_ARADDR = address;
  verilator_top->S_AXI_ARVALID = 1;
  while(verilator_top->S_AXI_ARREADY == 0){eval();}
  eval();
  verilator_top->S_AXI_ARVALID = 0;
  do {eval();} while(verilator_top->S_AXI_RVALID == 0);
  data = verilator_top->S_AXI_RDATA;

  return data;
}

void vwait(int times) {
  for(int i=0; i<times; i++){eval();}

  return;
}

/*
"top1: init"
"top2: write64"
"top3: read64"
"top4: vwait"
"top5: finish"
*/

int main(int argc, char **argv, char **env) {
  //////////////////// initialize mmap
  int fd = open("./tb.txt", O_RDWR, S_IRUSR | S_IWUSR);
  if(fd == -1){
    printf("file open error\n");
    exit(1);
  }
  struct stat st;
  if(fstat(fd, &st) < 0){
    exit(1);
  }
  volatile char *buf = (char *)mmap(NULL, st.st_size, PROT_READ|PROT_WRITE, MAP_SHARED, fd, 0);
  close(fd);

//////////////////// initialize verilator
  Verilated::commandArgs(argc,argv);
  Verilated::traceEverOn(true);
  main_time = 0;
  verilator_top = new Vtop;
#if TRACE  
  tfp = new VerilatedVcdC;
  verilator_top->trace(tfp, 99); // requires explicit max levels param
  tfp->open("tmp.vcd");
#endif
  main_time = 0;

  // initial begin /////////////////////////////
  verilator_top->S_AXI_BREADY = 1;
  verilator_top->S_AXI_AWVALID = 0;
  verilator_top->S_AXI_WSTRB = 0xff;
  verilator_top->S_AXI_WVALID = 0;
  verilator_top->S_AXI_ARVALID = 0;
  verilator_top->S_AXI_RREADY = 1;

  verilator_top->reset = 1;
  verilator_top->clk = 1;
  verilator_top->eval();

  main_time += 5;

  eval();eval();
  verilator_top->reset = 0;
  eval();eval();

  // main loop /////////////////////////////
  while(1){
    if(buf[0] != 0){
      if(buf[0] == 1){
        init();
      }
      else if(buf[0] == 2){
        union ulong_char address, data;
        for(int i=0; i<8; i++){
          address.c[i] = buf[i+8];
          data.c[i] = buf[i+16];
        }
        write64(address.i, data.ul);
      }
      else if(buf[0] == 3){
        union ulong_char address, data;
        for(int i=0; i<8; i++){
          address.c[i] = buf[i+8];
        }
        data.ul = read64(address.i);
        for(int i=0; i<8; i++){
          buf[i+16] = data.c[i];
        }
      }
      else if(buf[0] == 4){
        union ulong_char times;
        for(int i=0; i<8; i++){
          times.c[i] = buf[i+8];
        }
        vwait(times.i);
      }
      else if(buf[0] == 5){
        buf[0] = 0;
        break;
      }
      buf[0] = 0;
    }
  }

  // post process /////////////////////////////
  eval();eval();eval();eval();eval();
  delete verilator_top;
  #if TRACE  
  tfp->close();
  #endif  

  munmap((void*)buf, st.st_size);
  
  exit(0);
}
