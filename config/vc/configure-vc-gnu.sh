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
HERE=$(cd $(dirname $0); pwd -P)
DEST=${HERE}/../vc/${PRFX}
CMAKE=$(command -v cmake)

if [ "" = "${CMAKE}" ]; then
  echo "Error: missing CMake!"
  exit 1
fi

if [ ! -e ${HERE}/CMakeLists.txt ] || [ "${HERE}" != "$(pwd -P)" ]; then
  echo "Error: XCONFIGURE scripts must be located and executed in the application folder!"
  exit 1
fi

if [ "${HERE}" = "${DEST}" ]; then
  echo "Warning: Vc source directory equals installation folder!"
  read -p "Are you sure? Y/N" -n 1 -r
  if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    exit 1
  fi
else
  rm -f ${HERE}/CMakeCache.txt
fi

CONFOPTS="-DBUILD_TESTING=OFF"
TARGET="-march=native"

export FLAGS="-fPIC ${TARGET}"
export LDFLAGS=""
export CFLAGS="${FLAGS}"
export CXXFLAGS="${FLAGS}"
export FCFLAGS="${FLAGS}"
export F77FLAGS=${FCFLAGS}
export F90FLAGS=${FCFLAGS}
export FFLAGS=${FCFLAGS}

export AR="gcc-ar"
export FC="gfortran"
export CC="gcc"
export CXX="g++"
export F77=${FC}
export F90=${FC}

rm -rf ${HERE}/build
mkdir -p ${HERE}/build && cd ${HERE}/build

cmake -DCMAKE_INSTALL_PREFIX=${DEST} ${CONFOPTS} $* ${HERE}
echo "Remember to \"cd build\" before \"make; make install\""
