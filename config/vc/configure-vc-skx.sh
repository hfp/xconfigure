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

if [ "" = "$1" ]; then PRFX=intel-; else PRFX=$1-; shift; fi
HERE=$(cd $(dirname $0); pwd -P)
DEST=${HERE}/../vc/${PRFX}skx
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
TARGET="-xCORE-AVX512 -qopt-zmm-usage=high"

# consider more accurate FP-model
#FPCMODEL = -fp-model precise
#FPFMODEL = -fp-model source

export FLAGS="-fPIC ${TARGET}" #-ipo-separate
export LDFLAGS=""
export CFLAGS="${FLAGS} ${FPCMODEL}"
export CXXFLAGS="${FLAGS} ${FPCMODEL}"

export AR="xiar"
export FC="ifort"
export CC="icc"
export CXX="icpc"

rm -rf ${HERE}/build
mkdir -p ${HERE}/build && cd ${HERE}/build

cmake -DCMAKE_INSTALL_PREFIX=${DEST} ${CONFOPTS} $* ${HERE}
echo "Remember to \"cd build\" before \"make; make install\""
