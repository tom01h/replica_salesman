from setuptools import setup, Extension

filelist  = ['top.cpp']
setup(name='top',
        version='1.0',
        ext_modules=[Extension('top', filelist)]
)
