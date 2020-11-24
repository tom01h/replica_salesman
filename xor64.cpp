#include <Python.h>

unsigned long long x[32];

static PyObject*
init(PyObject *self, PyObject *args){
    int p;
    unsigned long long seed;
    PyObject *list;
    // 送られてきた値をパース
    if(!PyArg_ParseTuple(args, "iK", &p, &seed))
        return NULL;

    x[p] = seed;

    Py_INCREF(Py_None);
    return Py_None;
}

static PyObject*
random(PyObject *self, PyObject *args) {
    int p, start, end, msk;
    unsigned int val;
    // 送られてきた値をパース
    if(!PyArg_ParseTuple(args, "iiii", &p, &start, &end, &msk))
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
static PyMethodDef Xor64Methods[] = {
    {"init",   (PyCFunction)init,   METH_VARARGS, "xor641: init"},
    {"random", (PyCFunction)random, METH_VARARGS, "xor642: random"},
    // 終了を示す
    {NULL, NULL, 0, NULL}
};

//モジュールの定義
static struct PyModuleDef xor64module = {
    PyModuleDef_HEAD_INIT,
    "xor64",
    NULL,
    -1,
    Xor64Methods
};

// メソッドの初期化
PyMODINIT_FUNC PyInit_xor64 (void) {
  return PyModule_Create(&xor64module);
}
