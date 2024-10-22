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
DEST=${HERE}/../metis/${PRFX}
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
TARGET="-xHost"

# consider more accurate FP-model
#FPCMODEL = -fp-model precise
#FPFMODEL = -fp-model source

export FLAGS="-fPIC ${TARGET}" #-ipo-separate
export LDFLAGS=""
export CFLAGS="${FLAGS} ${FPCMODEL}"
export CXXFLAGS="${FLAGS} ${FPCMODEL}"
export FCFLAGS="${FLAGS} ${FPFMODEL} -align array64byte"
export F77FLAGS=${FCFLAGS}
export F90FLAGS=${FCFLAGS}
export FFLAGS=${FCFLAGS}

FC="ifx"; CC="icx"; CXX="icpx"; AR=$(command -v xiar || echo "ar")
if [ "1" = "${INTEL}" ] || 
   [ ! "$(command -v ${FC})" ] || [ ! "$(command -v ${CC})" ] || [ ! "$(command -v ${CXX})" ];
then
  FC="ifort"
  if [ "1" != "${INTEL}" ]; then
    CC="icc"
    CXX="icpc"
  fi
fi

export FC CC CXX AR
export F77=${FC}
export F90=${FC}

make config prefix="${DEST}" cc=${CC} ${CONFOPTS} "$@"
