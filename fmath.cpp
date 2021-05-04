#include <Python.h>

static PyObject*
exp(PyObject *self, PyObject *args) {
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
        if(i != 1){
            z = ((int64_t)x * recip) >> 18;
        }
        if(y < 0){
            return Py_BuildValue("i", 0);
        }
    }

    return Py_BuildValue("i", y);
}

// メソッドの定義
static PyMethodDef FmathMethods[] = {
    {"exp", (PyCFunction)exp, METH_VARARGS, "Fmath0"},
    // 終了を示す
    {NULL, NULL, 0, NULL}
};

//モジュールの定義
static struct PyModuleDef fmathmodule = {
    PyModuleDef_HEAD_INIT,
    "fmath",
    NULL,
    -1,
    FmathMethods
};

// メソッドの初期化
PyMODINIT_FUNC PyInit_fmath (void) {
  return PyModule_Create(&fmathmodule);
}
