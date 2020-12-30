from setuptools import setup, Extension
import glob

setup(name='xor64',
        version='1.0',
        ext_modules=[Extension('xor64', ['xor64.cpp'], extra_compile_args=['-DTRACE'])]
)
setup(name='fmath',
        version='1.0',
        ext_modules=[Extension('fmath', ['fmath.cpp'], extra_compile_args=['-DTRACE'])]
)
