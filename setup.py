from setuptools import setup, Extension
import glob

setup(name='top',
        version='1.0',
        ext_modules=[Extension('xor64', ['xor64.cpp'], extra_compile_args=['-DTRACE'])]
)
