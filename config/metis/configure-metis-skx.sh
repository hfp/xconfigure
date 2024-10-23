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

if [ "" = "$1" ]; then PRFX=intel; else PRFX=$1; shift; fi
HERE=$(cd "$(dirname "$0")" && pwd -P)
DEST=${HERE}/../metis/${PRFX}-skx
CMAKE=$(command -v cmake)

if [ "" = "${CMAKE}" ]; then
  echo "Error: missing CMake!"
  exit 1
fi

if [ ! -e "${HERE}/BUILD.txt" ] || [ "${HERE}" != "$(pwd -P)" ]; then
  echo "Error: XCONFIGURE scripts must be located and executed in the application folder!"
  exit 1
fi

if [ "${HERE}" = "${DEST}" ]; then
  echo "Warning: METIS source directory equals installation folder!"
  read -p "Are you sure? Y/N" -n 1 -r
  if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    exit 1
  fi
fi

CONFOPTS="openmp=1"
TARGET="-xCORE-AVX512"

# consider more accurate FP-model
#FPCMODEL = -fp-model precise
#FPFMODEL = -fp-model source

export FLAGS="-fPIC ${TARGET}" #-ipo-separate
export LDFLAGS=""
export CFLAGS="${FLAGS} ${FPCMODEL}"
export CXXFLAGS="${FLAGS} ${FPCMODEL}"

AR=$(command -v xiar || echo "ar")
if [ "1" != "${INTEL}" ]; then
  CXX=$(command -v mpiicpx || echo "mpiicpc -cxx=icpx")
  CC=$(command -v mpiicx || echo "mpiicc -cc=icx")
  FC=$(command -v mpiifx || echo "mpiifort -fc=ifx")
else
  CXX="mpiicpc -cxx=$(command -v icpc || echo icpx)"
  CC="mpiicc -cc=$(command -v icc || echo icx)"
  FC="mpiifort"
fi

export FC CC CXX AR
make config prefix="${DEST}" cc="${CC}" ${CONFOPTS} "$@"
