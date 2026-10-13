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
DEST=$(cd "${HERE}/.." && pwd -P)/libxc/${PRFX}
BUILD=build-${PRFX}

if [ ! -e "${HERE}/CMakeLists.txt" ] || [ ! -e "${HERE}/src/xc.h" ] || [ "${HERE}" != "$(pwd -P)" ]; then
  echo "Error: XCONFIGURE scripts must be located and executed in the application folder!"
  exit 1
fi

TARGET="-xHost"
FLAGS="-O2 ${TARGET}"

cmake -S "${HERE}" -B "${BUILD}" \
  -DCMAKE_INSTALL_PREFIX="${DEST}" -DCMAKE_INSTALL_LIBDIR=lib \
  -DCMAKE_BUILD_TYPE=Release -DCMAKE_POSITION_INDEPENDENT_CODE=ON \
  -DCMAKE_C_COMPILER=icx -DCMAKE_C_FLAGS_RELEASE="${FLAGS} -DNDEBUG" \
  -DCMAKE_Fortran_COMPILER=ifx -DCMAKE_Fortran_FLAGS_RELEASE="${FLAGS}" \
  -DBUILD_SHARED_LIBS=OFF -DBUILD_TESTING=OFF \
  -DENABLE_FORTRAN=ON -DMAXORDER=3 \
  "$@" && \
echo "Next: cmake --build ${BUILD} --target install -j $(nproc)"
