#!/usr/bin/env python

from distutils.core import setup, Extension
import sys
import os.path
import shutil
import sys

shutil.copyfile(os.path.join('python','MANIFEST.python'),'MANIFEST')

extra_link_args = []
if sys.platform != 'darwin':
    extra_link_args = ['-s']

extension = Extension("Pycluster.cluster", \
                      ["src/cluster.c", \
                       "python/clustermodule.c", \
                       "ranlib/src/ranlib.c", \
                       "ranlib/src/com.c",\
                       "ranlib/linpack/linpack.c"], \
                      include_dirs=['src','ranlib/src'], \
                      extra_link_args=extra_link_args \
                      )


setup(name="Pycluster",
      version="1.30",
      description="The C Clustering Library",
      author="Michiel de Hoon",
      author_email="mdehoon@c2b2.columbia.edu",
      url="http://bonsai.ims.u-tokyo.ac.jp/~mdehoon/software/software.html",
      license="Python License",
      package_dir = {'Pycluster':'python'},
      packages = ['Pycluster'],
      ext_modules=[extension]
      )
