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

// メソッドの定義
static PyMethodDef Xor64Methods[] = {
    {"c_init_random",   (PyCFunction)c_init_random,   METH_VARARGS, "xor641: c_init_random"},
    {"c_run_random",    (PyCFunction)c_run_random,    METH_VARARGS, "xor62: c_run_random"},
    {"c_save_random",   (PyCFunction)c_save_random,   METH_VARARGS, "xor643: c_save_random"},
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
