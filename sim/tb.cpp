#include "svdpi.h"
#include "dpiheader.h"

#define PY_SSIZE_T_CLEAN
#include <Python.h>

#define nbeta (32)
#define dbeta (5)
#define ncity (30)

unsigned long long x[nbeta];

static PyObject *
get_ordering (PyObject *self, PyObject *args) {
  int array[ncity+1];
  int size;
  long val;
  PyObject *list;
  // 送られてきた値をパース
  if(!PyArg_ParseTuple(args, "i", &size))
    return NULL;

  v_get_ordering(array, size);

  list = PyList_New(0);
  for(int i = 0; i < size; i++){
    val = array[i];
    PyList_Append(list, Py_BuildValue("i", val));
  }

  return list;
}

static PyObject *
get_total (PyObject *self, PyObject *args) {
  int array[nbeta];
  int size;
  long val;
  PyObject *list;
  // 送られてきた値をパース
  if(!PyArg_ParseTuple(args, "i", &size))
    return NULL;

  v_get_total(array, size);

  list = PyList_New(0);
  for(int i = 0; i < size; i++){
    val = array[i];
    PyList_Append(list, Py_BuildValue("i", val));
  }

  return list;
}

static PyObject *
fin (PyObject *self, PyObject *args) {
  v_finish();

  Py_INCREF(Py_None);
  return Py_None;
}

static PyObject *
init (PyObject *self, PyObject *args) {
  v_init();

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

static PyObject*
write64(PyObject *self, PyObject *args) {
  int  address;
  unsigned long long data;
  // 送られてきた値をパース
  if(!PyArg_ParseTuple(args, "iK", &address, &data))
    return NULL;

  v_write64(address, data);

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

  v_read64(address, &data);

  return Py_BuildValue("K", data);
}

static PyObject*
vwait(PyObject *self, PyObject *args) {
  int  times;
  // 送られてきた値をパース
  if(!PyArg_ParseTuple(args, "i", &times))
    return NULL;

  v_wait(times);

  Py_INCREF(Py_None);
  return Py_None;
}

// メソッドの定義
static PyMethodDef TopMethods[] = {
  {"get_ordering",    (PyCFunction)get_ordering,    METH_VARARGS, "top2: get_ordering"},
  {"get_total",       (PyCFunction)get_total,       METH_VARARGS, "top5: get_total"},
  {"fin",             (PyCFunction)fin,             METH_NOARGS,  "top8: fin"},
  {"init",            (PyCFunction)init,            METH_NOARGS,  "top9: init"},
  {"c_init_random",   (PyCFunction)c_init_random,   METH_VARARGS, "top10: c_init_random"},
  {"c_run_random",    (PyCFunction)c_run_random,    METH_VARARGS, "top11: c_run_random"},
  {"c_exp",           (PyCFunction)c_exp,           METH_VARARGS, "top12: c_exp"},
  {"write64",         (PyCFunction)write64,         METH_VARARGS, "top13: write64"},
  {"read64",          (PyCFunction)read64,          METH_VARARGS, "top14: read64"},
  {"vwait",           (PyCFunction)vwait,           METH_VARARGS, "top15: vwait"},
  // 終了を示す
  {NULL, NULL, 0, NULL}
};

//モジュールの定義
static struct PyModuleDef toptmodule = {
  PyModuleDef_HEAD_INIT,  "top",  NULL,  -1,  TopMethods,
  NULL, NULL, NULL, NULL
};

// メソッドの初期化
PyMODINIT_FUNC PyInit_top (void) {
  return PyModule_Create(&toptmodule);
}

DPI_LINK_DECL
int c_tb() {
  PyObject *pName, *pModule, *pFunc;
  PyObject *pArgs;

  PyImport_AppendInittab("top", &PyInit_top);

  Py_Initialize();
  pName = PyUnicode_DecodeFSDefault("replica_salesman_sim");
  /* Error checking of pName left out */

  pModule = PyImport_Import(pName);
  Py_DECREF(pName);

  if (pModule != NULL) {
    pFunc = PyObject_GetAttrString(pModule, "py_tb");
    /* pFunc is a new reference */

    if (pFunc && PyCallable_Check(pFunc)) {
      pArgs = PyTuple_New(0);
      PyObject_CallObject(pFunc, pArgs);
      Py_DECREF(pArgs);
    }
    else {
      if (PyErr_Occurred())
        PyErr_Print();
      fprintf(stderr, "Cannot find function\n");
    }
    Py_XDECREF(pFunc);
    Py_DECREF(pModule);
  }
  else {
    PyErr_Print();
    fprintf(stderr, "Failed to load\n");
    return 1;
  }
  if (Py_FinalizeEx() < 0) {
    return 120;
  }

  return 0;
}
