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
DEST=$(cd "${HERE}/.." && pwd -P)/libxc/${ARCH}/${PRFX}
BUILD=build-${ARCH}-${PRFX}

if [ ! -e "${HERE}/CMakeLists.txt" ] || [ ! -e "${HERE}/src/xc.h" ] || [ "${HERE}" != "$(pwd -P)" ]; then
  echo "Error: XCONFIGURE scripts must be located and executed in the application folder!"
  exit 1
fi

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
