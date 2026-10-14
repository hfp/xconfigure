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

if [ "" = "$1" ]; then PRFX=icx; else PRFX=$1; shift; fi
HERE=$(cd "$(dirname "$0")" && pwd -P)
# target flags and their name (e.g., sapphirerapids), XCFG_ARCH overrides
TARGET="-xHost"
# shellcheck disable=SC2086
ARCH=${XCFG_ARCH:-$(echo | icx ${TARGET} -x c -c -o /dev/null - -### 2>&1 | grep -o -E '"-target-cpu" "[^"]*"' | head -n1 | cut -d'"' -f4)}
ARCH=${ARCH:-$(uname -m)}
DEST=${HERE}/../metis/${ARCH}/${PRFX}
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

# CMake 4 removed compatibility with versions older than 3.5
export CMAKE_POLICY_VERSION_MINIMUM=3.5

CONFOPTS="openmp=1"

# consider more accurate FP-model
#FPCMODEL = -fp-model precise
#FPFMODEL = -fp-model source

export FLAGS="-fPIC ${TARGET}" #-ipo-separate
export LDFLAGS=""
export CFLAGS="${FLAGS} ${FPCMODEL}"
export CXXFLAGS="${FLAGS} ${FPCMODEL}"
export FCFLAGS="${FLAGS} ${FPFMODEL} -align array64byte"

AR="ar"
CXX="icpx"
CC="icx"
FC="ifx"

export FC CC CXX AR
export F77=${FC} F90=${FC} MPIFC=${FC} MPICC=${CC}
export MPIF77=${F77} MPIF90=${F90} MPICXX=${CXX}
export F77FLAGS=${FCFLAGS}
export F90FLAGS=${FCFLAGS}
export FFLAGS=${FCFLAGS}

make config prefix="${DEST}" cc="${CC}" ${CONFOPTS} "$@"
