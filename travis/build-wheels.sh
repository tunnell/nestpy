#!/bin/bash
set -e -x

# Install a system package required by our library
yum install -y atlas-devel wget

# Have to manually build and install CMake since libc old
cd /root
wget -q https://www.nikhef.nl/~ctunnell/cmake-2.8.12.tar.gz
tar xvfz cmake-2.8.12.tar.gz
cd cmake-2.8.12
./bootstrap
make
make install
export PATH=$PATH:/usr/local/bin

# Compile wheels
for PYBIN in /opt/python/*/bin; do
    "${PYBIN}/pip" install -r /io/requirements_dev.txt
    "${PYBIN}/pip" wheel /io/ -w wheelhouse/
done

# Bundle external shared libraries into the wheels
for whl in wheelhouse/*.whl; do
    auditwheel repair "$whl" -w /io/wheelhouse/
done

# Install packages and test
for PYBIN in /opt/python/*/bin/; do
    "${PYBIN}/pip" install python-manylinux-demo --no-index -f /io/wheelhouse
    (cd "$HOME"; "${PYBIN}/nosetests" pymanylinuxdemo)
done
