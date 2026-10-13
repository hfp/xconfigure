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
DEST=$(cd "${HERE}/.." && pwd -P)/libwignernj/${PRFX}
BUILD=build-${PRFX}

if [ ! -e "${HERE}/wignernjConfig.cmake.in" ] || [ "${HERE}" != "$(pwd -P)" ]; then
  echo "Error: XCONFIGURE scripts must be located and executed in the application folder!"
  exit 1
fi

TARGET="-march=native -mtune=native"
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
