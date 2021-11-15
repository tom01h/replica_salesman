from setuptools import setup, Extension

filelist  = ['top_pico.cpp']
setup(name='top_pico',
        version='1.0',
        ext_modules=[Extension('top_pico', filelist, libraries=['usb-1.0'])]
)