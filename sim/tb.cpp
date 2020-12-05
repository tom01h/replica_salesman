#include "svdpi.h"
#include "dpiheader.h"

#define PY_SSIZE_T_CLEAN
#include <Python.h>

#define nbeta (32)
#define dbeta (5)
#define ncity (30)

unsigned long long x[nbeta];

static PyObject*
set_ordering (PyObject *self, PyObject *args){
  int array[ncity+1];
  PyObject *p_list, *p_value;
  int size;
  // 送られてきた値をパース
  if(!PyArg_ParseTuple(args, "O!", &PyList_Type, &p_list))
    return NULL;
  // リストのサイズ取得
  size = PyList_Size(p_list);

  for(int i = 0; i < size; i++){
    p_value = PyList_GetItem(p_list, i);
    array[i] = PyLong_AsLong(p_value);
  }

  v_set_ordering(array, size);

  Py_INCREF(Py_None);
  return Py_None;
}

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

static PyObject*
set_distance (PyObject *self, PyObject *args){
  int array[(ncity+1)*(ncity+1)];
  PyObject *p_list, *p_value;
  int size, l_size;
  // 送られてきた値をパース
  if(!PyArg_ParseTuple(args, "iO!", &size, &PyList_Type, &p_list))
    return NULL;

  l_size = PyList_Size(p_list);

  for(int i = 0; i < l_size; i++){
    p_value = PyList_GetItem(p_list, i);
    array[i] = PyLong_AsLong(p_value);
  }

  v_set_distance(array, size);
  
  Py_INCREF(Py_None);
  return Py_None;
}

static PyObject*
set_total (PyObject *self, PyObject *args){
  int array[nbeta];
  PyObject *p_list, *p_value;
  int size;
  // 送られてきた値をパース
  if(!PyArg_ParseTuple(args, "O!", &PyList_Type, &p_list))
    return NULL;
  // リストのサイズ取得
  size = PyList_Size(p_list);

  for(int i = 0; i < size; i++){
    p_value = PyList_GetItem(p_list, i);
    array[i] = PyLong_AsLong(p_value);
  }

  v_set_total(array, size);

  Py_INCREF(Py_None);
  return Py_None;
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
delta_distance (PyObject *self, PyObject *args) {
  int array[nbeta];
  PyObject *p_list, *p_value;
  int size;
  // 送られてきた値をパース
  if(!PyArg_ParseTuple(args, "O!", &PyList_Type, &p_list))
    return NULL;

  for(int i = 0; i < nbeta; i++){
    p_value = PyList_GetItem(p_list, i);
    array[i] = PyLong_AsLong(p_value);
  }

  v_delta_distance(array);

  Py_INCREF(Py_None);
  return Py_None;
}

static PyObject *
set_command (PyObject *self, PyObject *args) {
  int command;
  // 送られてきた値をパース
  if(!PyArg_ParseTuple(args, "i", &command))
    return NULL;

  v_set_command(command);

  Py_INCREF(Py_None);
  return Py_None;
}

static PyObject *
run_opt (PyObject *self, PyObject *args) {
  int command;
  // 送られてきた値をパース
  if(!PyArg_ParseTuple(args, "i", &command))
    return NULL;

  v_run_opt(command);

  Py_INCREF(Py_None);
  return Py_None;
}

static PyObject*
set_random (PyObject *self, PyObject *args){
  unsigned long long array[nbeta];
  PyObject *p_list, *p_value;
  unsigned long long val;
  // 送られてきた値をパース
  if(!PyArg_ParseTuple(args, "O!", &PyList_Type, &p_list))
    return NULL;

  for(int i = 0; i < nbeta; i++){
    p_value = PyList_GetItem(p_list, i);
    array[i] = PyLong_AsUnsignedLongLong(p_value);
  }

  v_set_random(array);

  Py_INCREF(Py_None);
  return Py_None;
}

static PyObject *
run_random (PyObject *self, PyObject *args) {
  int array[nbeta];
  PyObject *p_list, *p_value;
  int size;
  // 送られてきた値をパース
  if(!PyArg_ParseTuple(args, "O!", &PyList_Type, &p_list))
    return NULL;

  for(int i = 0; i < nbeta; i++){
    p_value = PyList_GetItem(p_list, i);
    array[i] = PyLong_AsLong(p_value);
  }

  v_run_random(array);

  Py_INCREF(Py_None);
  return Py_None;
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

// メソッドの定義
static PyMethodDef TopMethods[] = {
  {"set_ordering",    (PyCFunction)set_ordering,    METH_VARARGS, "top1: set_ordering"},
  {"get_ordering",    (PyCFunction)get_ordering,    METH_VARARGS, "top2: get_ordering"},
  {"set_distance",    (PyCFunction)set_distance,    METH_VARARGS, "top3: set_distance"},
  {"set_total",       (PyCFunction)set_total,       METH_VARARGS, "top4: set_total"},
  {"get_total",       (PyCFunction)get_total,       METH_VARARGS, "top5: get_total"},
  {"delta_distance",  (PyCFunction)delta_distance,  METH_VARARGS, "top6: delta_distance"},
  {"set_command",     (PyCFunction)set_command,     METH_VARARGS, "top7: set_command"},
  {"run_opt",         (PyCFunction)run_opt,         METH_VARARGS, "top8: run_opt"},
  {"set_random",      (PyCFunction)set_random,      METH_VARARGS, "top9: set_random"},
  {"run_random",      (PyCFunction)run_random,      METH_VARARGS, "top10: run_random"},
  {"fin",             (PyCFunction)fin,             METH_NOARGS,  "top11: fin"},
  {"init",            (PyCFunction)init,            METH_NOARGS,  "top12: init"},
  {"c_init_random",   (PyCFunction)c_init_random,   METH_VARARGS, "top13: c_init_random"},
  {"c_run_random",    (PyCFunction)c_run_random,    METH_VARARGS, "top14: c_run_random"},
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
