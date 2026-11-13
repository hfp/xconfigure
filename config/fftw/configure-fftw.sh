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
DEST=$(cd "${HERE}/.." && pwd -P)/fftw/${ARCH}/${PRFX}
BUILD=build-${ARCH}-${PRFX}

if [ ! -e "${HERE}/api/fftw3.h" ] || [ ! -e "${HERE}/configure" ] || [ "${HERE}" != "$(pwd -P)" ]; then
  echo "Error: XCONFIGURE scripts must be located and executed in the application folder!"
  exit 1
fi

# SIMD codelets for the build host (FFTW dispatches at runtime)
CONFOPTS="--enable-openmp --disable-shared --enable-static --with-pic"
if [ "aarch64" = "$(uname -m)" ]; then
  CONFOPTS+=" --enable-neon"
elif [ -e /proc/cpuinfo ]; then
  CPUFLAGS=" $(grep -m1 "^flags" /proc/cpuinfo | cut -d: -f2-) "
  for SIMD in sse2 avx avx2 avx512f; do
    if [[ "${CPUFLAGS}" == *" ${SIMD} "* ]]; then CONFOPTS+=" --enable-${SIMD%f}"; fi
  done
fi

FLAGS="-O2 ${TARGET}"

mkdir -p "${BUILD}" && cd "${BUILD}" || exit 1
# shellcheck disable=SC2086
"${HERE}/configure" --prefix="${DEST}" --libdir="${DEST}/lib" ${CONFOPTS} \
  CC=gcc CFLAGS="${FLAGS} -std=c17" F77=gfortran FFLAGS="${FLAGS}" \
  "$@" && \
echo "Next: make -C ${BUILD} install -j $(nproc)"
