#include "sim/Vtop.h"
#include "verilated.h"
#include <Python.h>

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
  verilator_top->c_exchange = 2;
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
  verilator_top->c_exchange = 2;
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

static PyObject*
set_distance (PyObject *self, PyObject *args){
  PyObject *p_list, *p_value;
  int size;
  long val;
  // 送られてきた値をパース
  if(!PyArg_ParseTuple(args, "iO!", &size, &PyList_Type, &p_list))
    return NULL;

  verilator_top->distance_w_addr = 0;
  verilator_top->distance_write = 1;
  for(int i=1; i<size; i++){
    for(int j=0; j<i; j++){
      p_value = PyList_GetItem(p_list, i*size + j);
      val = PyLong_AsLong(p_value);
      //printf("%d\n", val);
      verilator_top->distance_w_data = val;
      eval();
      verilator_top->distance_w_addr += 1;
    }
  }
  verilator_top->distance_write = 0;
  
  Py_INCREF(Py_None);
  return Py_None;
}

static PyObject*
set_total (PyObject *self, PyObject *args){
  PyObject *p_list, *p_value;
  int size;
  long val;
  // 送られてきた値をパース
  if(!PyArg_ParseTuple(args, "O!", &PyList_Type, &p_list))
    return NULL;
  // リストのサイズ取得
  size = PyList_Size(p_list);

  verilator_top->c_metropolis = 2;
  for(int i = 0; i < size; i++){
    p_value = PyList_GetItem(p_list, i);
    val = PyLong_AsLong(p_value);
    verilator_top->total_in_data = val;
    eval();
  }
  verilator_top->c_metropolis = 0;

  Py_INCREF(Py_None);
  return Py_None;
}

static PyObject *
get_total (PyObject *self, PyObject *args) {
  int size;
  long val;
  PyObject *list;
  // 送られてきた値をパース
  if(!PyArg_ParseTuple(args, "i", &size))
    return NULL;

  list = PyList_New(0);
  verilator_top->c_metropolis = 2;
  for(int i = 0; i < size; i++){
    val = verilator_top->total_out_data;
    PyList_Append(list, Py_BuildValue("i", val));
    eval();
  }
  verilator_top->c_metropolis = 0;
  eval();

  return list;
}

static PyObject *
delta_distance (PyObject *self, PyObject *args) {
  int command, K, L;
  // 送られてきた値をパース
  if(!PyArg_ParseTuple(args, "iii", &command, &K, &L))
    return NULL;

  verilator_top->run_distance = 1;
  verilator_top->opt_com = command;
  verilator_top->K = K;
  verilator_top->L = L;
  eval();
  verilator_top->run_distance = 0;
  for(int c = 0; c < 20; c++){eval();}
  verilator_top->c_metropolis = 1;
  eval();
  verilator_top->c_metropolis = 0;

  Py_INCREF(Py_None);
  return Py_None;
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
  verilator_top->c_exchange = command;
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
  verilator_top->c_exchange = command;
  eval();
  verilator_top->run_command = 0;
  verilator_top->c_metropolis = 3;
  eval();
  verilator_top->c_metropolis = 0;
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

// メソッドの定義
static PyMethodDef TopMethods[] = {
  {"set_ordering",    (PyCFunction)set_ordering,    METH_VARARGS, "top1: set_ordering"},
  {"get_ordering",    (PyCFunction)get_ordering,    METH_VARARGS, "top2: get_ordering"},
  {"set_distance",    (PyCFunction)set_distance,    METH_VARARGS, "top3: set_distance"},
  {"set_total",       (PyCFunction)set_total,       METH_VARARGS, "top4: set_total"},
  {"get_total",       (PyCFunction)get_total,       METH_VARARGS, "top5: get_total"},
  {"delta_distance",  (PyCFunction)delta_distance,  METH_VARARGS, "top6: delta_distance"},
  {"set_opt",         (PyCFunction)set_opt,         METH_VARARGS, "top7: set_opt"},
  {"set_command",     (PyCFunction)set_command,     METH_VARARGS, "top8: set_command"},
  {"run_opt",         (PyCFunction)run_opt,         METH_VARARGS, "top9: run_opt"},
  {"fin",             (PyCFunction)fin,             METH_NOARGS,  "top10: fin"},
  {"init",            (PyCFunction)init,            METH_NOARGS,  "top11: init"},
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
  verilator_top->reset = 1;
  verilator_top->clk = 1;
  verilator_top->eval();

  main_time += 5;

  eval();eval();
  verilator_top->reset = 0;
  eval();eval();

  return PyModule_Create(&toptmodule);
}
