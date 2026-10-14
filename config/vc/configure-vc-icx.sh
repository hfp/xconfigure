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
DEST=${HERE}/../vc/${ARCH}/${PRFX}
CMAKE=$(command -v cmake)

if [ "" = "${CMAKE}" ]; then
  echo "Error: missing CMake!"
  exit 1
fi

if [ ! -e "${HERE}/CMakeLists.txt" ] || [ "${HERE}" != "$(pwd -P)" ]; then
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
  rm -f "${HERE}/CMakeCache.txt"
fi

# CMake 4 removed compatibility with versions older than 3.5
export CMAKE_POLICY_VERSION_MINIMUM=3.5

CONFOPTS="-DBUILD_TESTING=OFF"

rm -rf "${HERE}/build"
mkdir -p "${HERE}/build"
cd "${HERE}/build" || exit 1

cmake -DCMAKE_INSTALL_PREFIX="${DEST}" -DCMAKE_CXX_COMPILER=icpx ${CONFOPTS} "$@" "${HERE}"
echo
echo "Remember to \"cd build\" before \"make; make install\""
