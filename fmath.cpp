#include <Python.h>

static PyObject*
exp(PyObject *self, PyObject *args) {
    int ix;
    int l;
    unsigned int val;
    // 送られてきた値をパース
    if(!PyArg_ParseTuple(args, "ii", &ix, &l))
        return NULL;
    
    float x, y, z;
    
    x = float(ix)/10;

    z = x / l;
    y = 1.0;

    for(int i = l; i > 0; i--){
        y = 1 + z * y;
        if(i != 1){
            z = x / (i-1);
        }
        if(y < 0){
            return Py_BuildValue("i", 0);
        }
    }

    val = (unsigned int)(y * (1<<23));

    return Py_BuildValue("i", val);
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
