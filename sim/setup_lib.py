from setuptools import setup, Extension

filelist  = ['lib.cpp']
setup(name='lib',
        version='1.0',
        ext_modules=[Extension('lib', filelist)]
)