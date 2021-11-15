#define PY_SSIZE_T_CLEAN
#include <Python.h>

#include <libusb.h>
#define PMODUSB_VID       0x2E8A
#define PMODUSB_PID       0x0A
#define PMODUSB_INTF      2
#define PMODUSB_READ_EP   0x84
#define PMODUSB_WRITE_EP  0x03
libusb_context *usb_ctx;
libusb_device_handle *dev_handle;

struct send_com_t {
  unsigned char com[4];
  unsigned int address;
};

struct send_data_t {
  unsigned char com[4];
  unsigned int address;
  unsigned long data;
};

void device_close()
{
  if (dev_handle)
    libusb_close(dev_handle);
  if (usb_ctx)
    libusb_exit(usb_ctx);
}

static PyObject*
init(PyObject *self, PyObject *args) {
  int ret;

  if (libusb_init(&usb_ctx) < 0) {
    printf("[ERROR] libusb init failed!\n");
    return NULL;
  }
  dev_handle = libusb_open_device_with_vid_pid(usb_ctx, PMODUSB_VID, PMODUSB_PID);
  if (!dev_handle) {
    printf("[ERROR] failed to open usb device!\n");
    libusb_exit(usb_ctx);
    return NULL;
  }
  ret = libusb_claim_interface(dev_handle, PMODUSB_INTF);
  if (ret) {
    printf("[!] libusb error while claiming PMODUSB interface\n");
    libusb_close(dev_handle);
    libusb_exit(usb_ctx);
    return NULL;
  }
  
  Py_INCREF(Py_None);
  return Py_None;
}

static PyObject*
write64(PyObject *self, PyObject *args) {
  unsigned int address;
  unsigned long long data;

  if(!PyArg_ParseTuple(args, "IK", &address, &data))
    return NULL;

  int r;
  int actual_length = 0;

  struct send_data_t send_data;

  send_data.com[0] = 1;
  send_data.com[1] = 6;
  send_data.com[2] = 0;
  send_data.address = address;
  send_data.data = data;

  r = libusb_bulk_transfer(dev_handle, PMODUSB_WRITE_EP, &send_data.com[0], 16, &actual_length, 1000);
  if ( r != 0 ){
    printf("[!] libusb error while writing PMODUSB interface\n");
    device_close();
    return NULL;
  }

  Py_INCREF(Py_None);
  return Py_None;
}

static PyObject*
read64(PyObject *self, PyObject *args) {
  unsigned int address;
  unsigned long long val = 0;

  if(!PyArg_ParseTuple(args, "I", &address))
    return NULL;

  int r;
  int actual_length = 0;

  struct send_com_t send_data;

  send_data.com[0] = 0;
  send_data.com[1] = 6;
  send_data.com[2] = 0;
  send_data.address = address;

  r = libusb_bulk_transfer(dev_handle, PMODUSB_WRITE_EP, &send_data.com[0], 8, &actual_length, 1000);
  if ( r != 0 ){
    printf("[!] libusb error while reading PMODUSB interface\n");
    device_close();
    return NULL;
  }
  do {
    r = libusb_bulk_transfer(dev_handle, PMODUSB_READ_EP, (unsigned char*)&val, 64, &actual_length, 2000);
    if (r < 0) {
      device_close();
      return NULL;
    }
  } while (actual_length == 0);

  return Py_BuildValue("K", val);
}

static PyObject*
vwait(PyObject *self, PyObject *args) {
  unsigned int n;

  if(!PyArg_ParseTuple(args, "I", &n))
    return NULL;
  Py_INCREF(Py_None);
  return Py_None;
}

static PyObject*
finish(PyObject *self, PyObject *args) {
  device_close();
  
  Py_INCREF(Py_None);
  return Py_None;
}

static PyMethodDef TopMethods[] = {
  {"init",     (PyCFunction)init,     METH_NOARGS,  "lib1: init"},
  {"write64",  (PyCFunction)write64,  METH_VARARGS, "lib2: wite64"},
  {"read64",   (PyCFunction)read64,   METH_VARARGS, "lib3: read64"},
  {"vwait",    (PyCFunction)vwait,    METH_VARARGS, "lib4: vwait"},
  {"finish",   (PyCFunction)finish,   METH_NOARGS,  "lib5: finish"},

  {NULL, NULL, 0, NULL}
};

static struct PyModuleDef topmodule = {
  PyModuleDef_HEAD_INIT,  "top_pico",  NULL,  -1,  TopMethods,
  NULL, NULL, NULL, NULL
};

PyMODINIT_FUNC PyInit_top_pico (void) {
  return PyModule_Create(&topmodule);
}