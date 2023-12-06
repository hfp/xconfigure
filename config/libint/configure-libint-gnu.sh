#!/usr/bin/env bash
###############################################################################
# Copyright (c) Intel Corporation - All rights reserved.                      #
# This file is part of the XCONFIGURE project.                                #
#                                                                             #
# For information on the license, see the LICENSE file.                       #
# Further information: https://github.com/hfp/xconfigure/                     #
# SPDX-License-Identifier: BSD-3-Clause                                       #
###############################################################################
# Hans Pabst (Intel Corp.)
###############################################################################

if [ "" = "$1" ]; then PRFX=gnu; else PRFX=$1; shift; fi
HERE=$(cd "$(dirname "$0")" && pwd -P)
DEST=${HERE}/../libint/${PRFX}

if [[ ((! -e ${HERE}/configure.in) && (! -e ${HERE}/configure.ac) && (! -e ${HERE}/CMakeLists.txt)) \
    || ("${HERE}" != "$(pwd -P)") ]];
then
  echo "Error: XCONFIGURE scripts must be located and executed in the application folder!"
  exit 1
fi

if [ "${HERE}" = "${DEST}" ]; then
  echo "Warning: LIBINT source directory equals installation folder!"
  read -p "Are you sure? Y/N" -n 1 -r
  if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    exit 1
  fi
fi

CONFOPTS=""
TARGET="-march=native -mtune=native"

export FLAGS="-O3 ${TARGET}"
export LDFLAGS=""
export CFLAGS="${FLAGS}"
export CXXFLAGS="${FLAGS} -std=c++17"
export FCFLAGS="${FLAGS}"
export F77FLAGS=${FCFLAGS}
export F90FLAGS=${FCFLAGS}
export FFLAGS=${FCFLAGS}
export LIBS="-lstdc++"

export AR="gcc-ar"
export FC="gfortran"
export CC="gcc"
export CXX="g++"
export F77=${FC}
export F90=${FC}

if [ -e ${HERE}/CMakeLists.txt ] && [ ! -e ${HERE}/configure.in ] && [ ! -e ${HERE}/configure.ac ]; then
  if [ ! "$(command -v cmake)" ]; then
    echo "Error: XCONFIGURE requires CMake to build LIBINT!"
    exit 1
  fi
  cmake . -DCMAKE_INSTALL_PREFIX="${DEST}" \
    -DCMAKE_CXX_COMPILER="${CXX}" -DCMAKE_CXX_FLAGS="${CXXFLAGS}" \
    -DREQUIRE_CXX_API=OFF -DENABLE_FORTRAN=ON
else
  if [ -e ${HERE}/fortran/Makefile ] || [ -e ${HERE}/fortran/Makefile.in ]; then
    sed -i '/fortran_example:/!b;n;s/CXX/FC/g' ${HERE}/fortran/Makefile*
  fi
  # broken build system incl. "make -f ${HERE}/fortran/Makefile distclean"
  if [ -e ${HERE}/fortran/Makefile ]; then
    cd ${HERE}/fortran
    make distclean
    cd ${HERE}
  fi

  if [ ! -e ${HERE}/configure ]; then
    autoconf
  fi

  ./configure --prefix=${DEST} ${CONFOPTS} \
    --with-cc-optflags="${CFLAGS}" \
    --with-cxx-optflags="${CXXFLAGS}" \
    --with-libderiv-max-am1=5 \
    --with-libint-max-am=6 \
    --disable-libtool \
    --enable-fortran \
    "$@"
fi
