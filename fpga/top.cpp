#include <Python.h>

#define nbeta (32)

unsigned long long x[nbeta];

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
  z = ((int64_t)x * recip) >> 18;

  for(int i = l; i > 0; i--){
    recip = int32_t(1.0 / (i-1) * (1<<15));
    int64_t one = (int64_t)1<<(14+23);

    y = (one + (int64_t)z * y) >> 14;
    z = ((int64_t)x * recip) >> 18;

    if(y < 0){
      return Py_BuildValue("i", 0);
    }
  }

  return Py_BuildValue("i", y);
}

// メソッドの定義
static PyMethodDef TopMethods[] = {
  {"c_init_random",   (PyCFunction)c_init_random,   METH_VARARGS, "top0: c_init_random"},
  {"c_run_random",    (PyCFunction)c_run_random,    METH_VARARGS, "top1: c_run_random"},
  {"c_save_random",   (PyCFunction)c_save_random,   METH_VARARGS, "top2: c_save_random"},
  {"c_exp",           (PyCFunction)c_exp,           METH_VARARGS, "top3: c_exp"},
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
  return PyModule_Create(&toptmodule);
}
