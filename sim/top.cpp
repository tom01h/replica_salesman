#include "sim/Vtop.h"
#include "verilated.h"
#include "verilated_vcd_c.h"
#include <Python.h>

vluint64_t vcdstart = 0;
vluint64_t vcdend = vcdstart + 300000;
vluint64_t main_time;
VerilatedVcdC* tfp;
Vtop* verilator_top;

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

static PyObject*
set_ordering (PyObject *self, PyObject *args){
  PyObject *p_list, *p_value;
  int size;
  long val;
  // 送られてきた値をパース
  if(!PyArg_ParseTuple(args, "O!", &PyList_Type, &p_list))
    return NULL;
  // リストのサイズ取得
  size = PyList_Size(p_list);

  verilator_top->run_command = 1;
  verilator_top->command = 2;
  eval();
  verilator_top->run_command = 0;
  verilator_top->ordering_in_valid = 1;
  for(int i = 0; i < size/8; i++){
    val = 0;
    for(int j = 0; j < 8; j++){
      p_value = PyList_GetItem(p_list, i*8 + j);
      val *= 256;
      val += PyLong_AsLong(p_value);
    }
    verilator_top->ordering_in_data = val;
    eval();
  }
  val = 0;
  for(int j = 0; j < size%8; j++){
    p_value = PyList_GetItem(p_list, size/8*8 + j);
    val *= 256;
    val += PyLong_AsLong(p_value);
  }
  for(int j = size%8; j<8; j++){
    val *= 256;
  }  
  verilator_top->ordering_in_data = val;
  eval();
  verilator_top->ordering_in_valid = 0;

  Py_INCREF(Py_None);
  return Py_None;
}

static PyObject *
get_ordering (PyObject *self, PyObject *args) {
  int size;
  long val, inthert_val;
  PyObject *list;
  // 送られてきた値をパース
  if(!PyArg_ParseTuple(args, "i", &size))
    return NULL;

  verilator_top->run_command = 1;
  verilator_top->command = 2;
  eval();
  verilator_top->run_command = 0;
  eval();
  eval();
  list = PyList_New(0);
  for(int i = 0; i < size/8; i++){
    eval();
    val = verilator_top->ordering_out_data;
    for(int j = 0; j < 8; j++){
      inthert_val = val / 0x100000000000000L;
      val %= 0x100000000000000L;
      val *= 0x100;
      PyList_Append(list, Py_BuildValue("i", inthert_val));
    }
  }
  eval();
  val = verilator_top->ordering_out_data;
  for(int j = 0; j < size%8; j++){
    inthert_val = val / 0x100000000000000L;
    val %= 0x100000000000000L;
    val *= 0x100;
    PyList_Append(list, Py_BuildValue("i", inthert_val));
  }

  return list;
}

static PyObject *
set_opt (PyObject *self, PyObject *args) {
  int command, K, L;
  // 送られてきた値をパース
  if(!PyArg_ParseTuple(args, "iii", &command, &K, &L))
    return NULL;

  verilator_top->set_opt = 1;
  verilator_top->opt_com = command;
  verilator_top->K = K;
  verilator_top->L = L;
  eval();
  verilator_top->set_opt = 0;

  Py_INCREF(Py_None);
  return Py_None;
}

static PyObject *
set_command (PyObject *self, PyObject *args) {
  int command;
  // 送られてきた値をパース
  if(!PyArg_ParseTuple(args, "i", &command))
    return NULL;

  verilator_top->set_command = 1;
  verilator_top->command = command;
  eval();
  verilator_top->set_command = 0;

  Py_INCREF(Py_None);
  return Py_None;
}

static PyObject *
run_opt (PyObject *self, PyObject *args) {
  int command;
  // 送られてきた値をパース
  if(!PyArg_ParseTuple(args, "i", &command))
    return NULL;

  eval();
  verilator_top->run_command = 1;
  verilator_top->command = command;
  eval();
  verilator_top->run_command = 0;
  eval();
  eval();
  eval();
  eval();
  eval();
  eval();

  Py_INCREF(Py_None);
  return Py_None;
}

static PyObject *
fin (PyObject *self, PyObject *args) {

  eval();eval();eval();eval();eval();
  delete verilator_top;
  tfp->close();
  
  Py_INCREF(Py_None);
  return Py_None;
}

// メソッドの定義
static PyMethodDef TopMethods[] = {
  {"set_ordering", (PyCFunction)set_ordering, METH_VARARGS, "top1: set_ordering"},
  {"get_ordering", (PyCFunction)get_ordering, METH_VARARGS, "top2: get_ordering"},
  {"set_opt",      (PyCFunction)set_opt,      METH_VARARGS, "top3: set_opt"},
  {"set_command",  (PyCFunction)set_command,  METH_VARARGS, "top4: set_command"},
  {"run_opt",      (PyCFunction)run_opt,      METH_VARARGS, "top5: run_opt"},
  {"fin",          (PyCFunction)fin,          METH_NOARGS,  "top6: fin"},
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
  tfp = new VerilatedVcdC;
  verilator_top = new Vtop;
  verilator_top->trace(tfp, 99); // requires explicit max levels param
  tfp->open("tmp.vcd");

  main_time = 0;

  // initial begin /////////////////////////////
  verilator_top->reset = 1;
  verilator_top->clk = 1;
  verilator_top->eval();

  main_time += 5;

  eval();eval();
  verilator_top->reset = 0;
  eval();eval();

  return PyModule_Create(&toptmodule);
}
