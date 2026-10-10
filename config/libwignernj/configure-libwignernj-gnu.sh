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
DEST=${HERE}/../libwignernj/${PRFX}

if [ ! -e "${HERE}/wignernjConfig.cmake.in" ] || [ "${HERE}" != "$(pwd -P)" ]; then
  echo "Error: XCONFIGURE scripts must be located and executed in the application folder!"
  exit 1
fi

if [ "${HERE}" = "${DEST}" ]; then
  echo "Warning: libwignernj source directory equals installation folder!"
  read -p "Are you sure? Y/N" -n 1 -r
  if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    exit 1
  fi
fi

CONFOPTS="--with-pic"
TARGET="-march=native -mtune=native"

export FLAGS="-O3 ${TARGET}"
export LDFLAGS=""
export CFLAGS="${FLAGS}"
export CXXFLAGS="${FLAGS}"
export FCFLAGS="${FLAGS}"
export LIBS=""

export AR="gcc-ar"
export FC="gfortran"
export CC="gcc"
export CXX="g++"

export F77=${FC} F90=${FC} MPIFC=${FC} MPICC=${CC}
export MPIF77=${F77} MPIF90=${F90} MPICXX=${CXX}
export F77FLAGS=${FCFLAGS}
export F90FLAGS=${FCFLAGS}
export FFLAGS=${FCFLAGS}

mkdir -p ${HERE}/build && cd ${HERE}/build
cmake .. -DCMAKE_INSTALL_PREFIX="${DEST}" \
  -DCMAKE_BUILD_TYPE="Release" -DCMAKE_POSITION_INDEPENDENT_CODE=ON \
  -DCMAKE_Fortran_COMPILER="${FC}" -DCMAKE_Fortran_FLAGS="${FCFLAGS}" \
  -DCMAKE_CXX_COMPILER="${CXX}" -DCMAKE_CXX_FLAGS="${CXXFLAGS}" \
  -DCMAKE_C_COMPILER="${CC}" -DCMAKE_C_FLAGS="${CFLAGS}" \
  -DWIGNERNJ_BUILD_LTO=OFF -DWIGNERNJ_BUILD_FORTRAN=OFF \
  -DWIGNERNJ_BUILD_TESTS=OFF -DWIGNERNJ_BUILD_CXX_TESTS=OFF \
  -DWIGNERNJ_BUILD_EXAMPLES=OFF \
  -DCMAKE_INSTALL_LIBDIR=lib
