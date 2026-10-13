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

if [ "" = "$1" ]; then PRFX=gnu-gpu; else PRFX=$1-gpu; shift; fi
HERE=$(cd "$(dirname "$0")" && pwd -P)
DEST=$(cd "${HERE}/.." && pwd -P)/dbcsr/${PRFX}
BUILD=build-${PRFX}

if [ ! -e "${HERE}/src/dbcsr_api.F" ] || [ "${HERE}" != "$(pwd -P)" ]; then
  echo "Error: XCONFIGURE scripts must be located and executed in the application folder!"
  exit 1
fi

# DBCSR sets its own optimization level per build type
TARGET="-march=native -mtune=native"

cmake -S "${HERE}" -B "${BUILD}" \
  -DCMAKE_INSTALL_PREFIX="${DEST}" -DCMAKE_INSTALL_LIBDIR=lib \
  -DCMAKE_BUILD_TYPE=Release \
  -DCMAKE_C_COMPILER=mpicc -DCMAKE_C_FLAGS="${TARGET}" \
  -DCMAKE_CXX_COMPILER=mpicxx -DCMAKE_CXX_FLAGS="${TARGET}" \
  -DCMAKE_Fortran_COMPILER=mpif90 -DCMAKE_Fortran_FLAGS="${TARGET}" \
  -DBUILD_SHARED_LIBS=OFF -DBUILD_TESTING=OFF -DWITH_EXAMPLES=OFF \
  -DUSE_MPI=ON -DUSE_OPENMP=ON -DUSE_LIBXS=ON -DUSE_ACCEL=opencl \
  "$@" && \
echo "Next: cmake --build ${BUILD} --target install -j $(nproc)"
