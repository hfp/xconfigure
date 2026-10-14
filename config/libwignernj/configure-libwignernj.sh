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
# target flags and their name (e.g., sapphirerapids), XCFG_ARCH overrides
if [ "aarch64" = "$(uname -m)" ]; then TARGET="-mcpu=native"; else TARGET="-march=native -mtune=native"; fi
# shellcheck disable=SC2086
ARCH=${XCFG_ARCH:-$(echo | gcc ${TARGET} -x c -E -v - 2>&1 | grep -m1 "/cc1 " | grep -o -E " -m(cpu|arch)=[^ +]*" | head -n1 | cut -d= -f2)}
ARCH=${ARCH:-$(uname -m)}
DEST=$(cd "${HERE}/.." && pwd -P)/libwignernj/${ARCH}/${PRFX}
BUILD=build-${ARCH}-${PRFX}

if [ ! -e "${HERE}/wignernjConfig.cmake.in" ] || [ "${HERE}" != "$(pwd -P)" ]; then
  echo "Error: XCONFIGURE scripts must be located and executed in the application folder!"
  exit 1
fi

FLAGS="-O2 ${TARGET}"

cmake -S "${HERE}" -B "${BUILD}" \
  -DCMAKE_INSTALL_PREFIX="${DEST}" -DCMAKE_INSTALL_LIBDIR=lib \
  -DCMAKE_BUILD_TYPE=Release -DCMAKE_POSITION_INDEPENDENT_CODE=ON \
  -DCMAKE_C_COMPILER=gcc -DCMAKE_C_FLAGS_RELEASE="${FLAGS} -DNDEBUG" \
  -DBUILD_SHARED_LIBS=OFF -DWIGNERNJ_BUILD_LTO=OFF \
  -DWIGNERNJ_BUILD_FORTRAN=OFF -DWIGNERNJ_BUILD_EXAMPLES=OFF \
  -DWIGNERNJ_BUILD_TESTS=OFF -DWIGNERNJ_BUILD_CXX_TESTS=OFF \
  "$@" && \
echo "Next: cmake --build ${BUILD} --target install -j $(nproc)"
