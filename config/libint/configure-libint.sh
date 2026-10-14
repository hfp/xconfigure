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
DEST=$(cd "${HERE}/.." && pwd -P)/libint/${ARCH}/${PRFX}
BUILD=build-${ARCH}-${PRFX}

if [ ! -e "${HERE}/CMakeLists.txt" ] || [ "${HERE}" != "$(pwd -P)" ]; then
  echo "Error: XCONFIGURE scripts must be located and executed in the application folder!"
  exit 1
fi

# generic source would first need to generate the library
if [ ! -e "${HERE}/include/libint2/config.h" ]; then
  echo "Error: LIBINT must be preconfigured, see https://www.cp2k.org/static/downloads/"
  exit 1
fi

FLAGS="-O2 ${TARGET}"

# install rule expects bundled Boost even if the C++ API is disabled
mkdir -p "${BUILD}/include/libint2/boost"
# installed CMake config requires Eigen even if the C++ API is disabled
sed -i 's/^\( *\)if *(NOT TARGET Eigen3::Eigen)$/\1if(NOT TARGET Eigen3::Eigen AND "@LIBINT2_REQUIRE_CXX_API@")/' \
  "${HERE}/cmake/libint2-config.cmake.in"

cmake -S "${HERE}" -B "${BUILD}" \
  -DCMAKE_INSTALL_PREFIX="${DEST}" -DCMAKE_INSTALL_LIBDIR=lib \
  -DCMAKE_BUILD_TYPE=Release -DCMAKE_POSITION_INDEPENDENT_CODE=ON \
  -DCMAKE_C_COMPILER=gcc -DCMAKE_C_FLAGS_RELEASE="${FLAGS} -DNDEBUG" \
  -DCMAKE_CXX_COMPILER=g++ -DCMAKE_CXX_FLAGS_RELEASE="${FLAGS} -DNDEBUG" \
  -DCMAKE_Fortran_COMPILER=gfortran -DCMAKE_Fortran_FLAGS_RELEASE="${FLAGS}" \
  -DBUILD_SHARED_LIBS=OFF -DBUILD_TESTING=OFF \
  -DLIBINT2_ENABLE_FORTRAN=ON -DLIBINT2_REQUIRE_CXX_API=OFF \
  "$@" && \
echo "Next: cmake --build ${BUILD} --target install -j $(nproc)"
