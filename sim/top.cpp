#include "sim/Vtop.h"
#include "verilated.h"
#include <Python.h>

#define nbeta (32)

unsigned long long x[nbeta];

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

static PyObject *
fin (PyObject *self, PyObject *args) {

  eval();eval();eval();eval();eval();
  delete verilator_top;
#if TRACE  
  tfp->close();
#endif  
  Py_INCREF(Py_None);
  return Py_None;
}

static PyObject *
init (PyObject *self, PyObject *args) {
  
  Py_INCREF(Py_None);
  return Py_None;
}

static PyObject*
write64(PyObject *self, PyObject *args) {
  int  address;
  unsigned long long data;
  // 送られてきた値をパース
  if(!PyArg_ParseTuple(args, "iK", &address, &data))
    return NULL;

  verilator_top->S_AXI_AWADDR = address;
  verilator_top->S_AXI_AWVALID = 1;
  verilator_top->S_AXI_WDATA = data;
  verilator_top->S_AXI_WVALID = 1;
  eval();
  verilator_top->S_AXI_AWVALID = 0;
  verilator_top->S_AXI_WVALID = 0;
  eval();

  Py_INCREF(Py_None);
  return Py_None;
}

static PyObject*
read64(PyObject *self, PyObject *args) {
  int  address;
  unsigned long long data;
  // 送られてきた値をパース
  if(!PyArg_ParseTuple(args, "i", &address))
    return NULL;

  verilator_top->S_AXI_ARADDR = address;
  verilator_top->S_AXI_ARVALID = 1;
  while(verilator_top->S_AXI_ARREADY == 0){eval();}
  eval();
  verilator_top->S_AXI_ARVALID = 0;
  do {eval();} while(verilator_top->S_AXI_RVALID == 0);
  data = verilator_top->S_AXI_RDATA;

  return Py_BuildValue("K", data);
}

static PyObject*
vwait(PyObject *self, PyObject *args) {
  int  times;
  // 送られてきた値をパース
  if(!PyArg_ParseTuple(args, "i", &times))
    return NULL;

  for(int i=0; i<times; i++){eval();}

  Py_INCREF(Py_None);
  return Py_None;
}

static PyObject*
c_init_random(PyObject *self, PyObject *args){
  PyObject *p_list, *p_value;
  unsigned long long val;
  // 送られてきた値をパース
  if(!PyArg_ParseTuple(args, "O!", &PyList_Type, &p_list))
    return NULL;

  for(int i = 0; i < nbeta; i++){
    p_value = PyList_GetItem(p_list, i);
    x[i] = PyLong_AsUnsignedLongLong(p_value);
  }

  Py_INCREF(Py_None);
  return Py_None;
}

static PyObject*
c_run_random(PyObject *self, PyObject *args) {
  unsigned int p, start, end, msk;
  unsigned int val;
  // 送られてきた値をパース
  if(!PyArg_ParseTuple(args, "IIII", &p, &start, &end, &msk))
    return NULL;

  do{
    x[p] = x[p] ^ (x[p] << 13);
    x[p] = x[p] ^ (x[p] >> 7);
    x[p] = x[p] ^ (x[p] << 17);
    val = x[p] & msk;
  }while(!((start <= val) && (val <= end)));

  return Py_BuildValue("I", val);
}

static PyObject*
c_save_random(PyObject *self, PyObject *args) {
  PyObject *list;
  unsigned long long val;

  list = PyList_New(0);

  for(int i = 0; i < nbeta; i++){
    val = x[i];
    PyList_Append(list, Py_BuildValue("K", val));
  }
  
  return list;
}

static PyObject*
c_exp(PyObject *self, PyObject *args) {
  int32_t x, y, z;
  int l;
  int32_t recip;
  
  // 送られてきた値をパース
  if(!PyArg_ParseTuple(args, "ii", &x, &l))
    return NULL;
  
  recip = int32_t((1.0/l) * (1<<15));
  y = 1<<23;
  z = ((int64_t)x * recip) >> 15;

  for(int i = l; i > 0; i--){
    recip = int32_t(1.0 / (i-1) * (1<<15));
    int64_t one = (int64_t)1<<(14+23);

    y = (one + (int64_t)z * y) >> 14;
    z = ((int64_t)x * recip) >> 15;

    if(y < 0){
      return Py_BuildValue("i", 0);
    }
  }

  return Py_BuildValue("i", y);
}

// メソッドの定義
static PyMethodDef TopMethods[] = {
  {"fin",             (PyCFunction)fin,             METH_NOARGS,  "top0: fin"},
  {"init",            (PyCFunction)init,            METH_NOARGS,  "top1: init"},
  {"write64",         (PyCFunction)write64,         METH_VARARGS, "top2: write64"},
  {"read64",          (PyCFunction)read64,          METH_VARARGS, "top3: read64"},
  {"vwait",           (PyCFunction)vwait,           METH_VARARGS, "top4: vwait"},
  {"c_init_random",   (PyCFunction)c_init_random,   METH_VARARGS, "top5: c_init_random"},
  {"c_run_random",    (PyCFunction)c_run_random,    METH_VARARGS, "top6: c_run_random"},
  {"c_save_random",   (PyCFunction)c_save_random,   METH_VARARGS, "top7: c_save_random"},
  {"c_exp",           (PyCFunction)c_exp,           METH_VARARGS, "top8: c_exp"},
  // 終了を示す
  {NULL, NULL, 0, NULL}
};

//モジュールの定義
static struct PyModuleDef toptmodule = {
  PyModuleDef_HEAD_INIT,
  "top",
  NULL,
  -1,
  TopMethods
};

// メソッドの初期化
PyMODINIT_FUNC PyInit_top (void) {
  //  Verilated::commandArgs(argc,argv);
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
  verilator_top->S_AXI_WSTRB = 1;
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

  return PyModule_Create(&toptmodule);
}
