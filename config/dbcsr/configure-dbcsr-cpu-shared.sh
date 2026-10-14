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

if [ "" = "$1" ]; then PRFX=gnu-cpu-shared; else PRFX=$1-cpu-shared; shift; fi
HERE=$(cd "$(dirname "$0")" && pwd -P)
# target flags and their name (e.g., sapphirerapids), XCFG_ARCH overrides
if [ "aarch64" = "$(uname -m)" ]; then TARGET="-mcpu=native"; else TARGET="-march=native -mtune=native"; fi
# shellcheck disable=SC2086
ARCH=${XCFG_ARCH:-$(echo | gcc ${TARGET} -x c -E -v - 2>&1 | grep -m1 "/cc1 " | grep -o -E " -m(cpu|arch)=[^ +]*" | head -n1 | cut -d= -f2)}
ARCH=${ARCH:-$(uname -m)}
ROOT=$(cd "${HERE}/.." && pwd -P)
DEST=${ROOT}/dbcsr/${ARCH}/${PRFX}
BUILD=build-${ARCH}-${PRFX}

if [ ! -e "${HERE}/src/dbcsr_api.F" ] || [ "${HERE}" != "$(pwd -P)" ]; then
  echo "Error: XCONFIGURE scripts must be located and executed in the application folder!"
  exit 1
fi

# sibling folder, $<NAME>ROOT (e.g., LIBXSROOT), or $HOME
for DEP in libxs libxsmm; do
  VAR=$(tr "[:lower:]" "[:upper:]" <<<"${DEP}")ROOT
  for DIR in "${ROOT}/${DEP}/${ARCH}" "${ROOT}/${DEP}" "${!VAR}" "${HOME}/${DEP}/${ARCH}" "${HOME}/${DEP}"; do
    if [ "${DIR}" ] && [ "$(ls "${DIR}"/lib*/"${DEP}".* 2>/dev/null)" ]; then
      echo "Found ${DEP}: ${DIR}"
      PREFIXES="${PREFIXES:+${PREFIXES};}${DIR}"
      if [ "libxsmm" = "${DEP}" ]; then CONFOPTS+=" -DUSE_LIBXSMM=ON"; fi
      break
    fi
  done
done

# NVPL=1 selects NVPL's BLAS/LAPACK (e.g., Grace), which CP2K must use as well
if [ "1" = "${NVPL}" ]; then
  for DIR in ${NVPL_ROOT:+"${NVPL_ROOT}"} /usr; do
    # shellcheck disable=SC2012
    NVPLLIB=$(ls -d "${DIR}"/lib*/libnvpl_blas_core.so "${DIR}"/lib/*/libnvpl_blas_core.so 2>/dev/null | head -n1)
    if [ "${NVPLLIB}" ]; then NVPLLIB=$(dirname "${NVPLLIB}"); break; fi
  done
  if [ ! "${NVPLLIB}" ]; then
    echo "Error: NVPL requested but not found (NVPL_ROOT)!"
    exit 1
  fi
  echo "Found NVPL: ${NVPLLIB}"
  CONFOPTS+=" -DBLAS_LIBRARIES=${NVPLLIB}/libnvpl_blas_lp64_gomp.so;${NVPLLIB}/libnvpl_blas_core.so"
  CONFOPTS+=" -DLAPACK_LIBRARIES=${NVPLLIB}/libnvpl_lapack_lp64_gomp.so;${NVPLLIB}/libnvpl_lapack_core.so"
fi

# DBCSR sets its own optimization level per build type
# shellcheck disable=SC2086
cmake -S "${HERE}" -B "${BUILD}" \
  -DCMAKE_INSTALL_PREFIX="${DEST}" -DCMAKE_INSTALL_LIBDIR=lib \
  -DCMAKE_BUILD_TYPE=Release -DCMAKE_PREFIX_PATH="${PREFIXES}" \
  -DCMAKE_C_COMPILER=mpicc -DCMAKE_C_FLAGS="${TARGET}" \
  -DCMAKE_CXX_COMPILER=mpicxx -DCMAKE_CXX_FLAGS="${TARGET}" \
  -DCMAKE_Fortran_COMPILER=mpif90 -DCMAKE_Fortran_FLAGS="${TARGET}" \
  -DBUILD_SHARED_LIBS=ON -DBUILD_TESTING=OFF -DWITH_EXAMPLES=OFF \
  -DUSE_MPI=ON -DUSE_OPENMP=ON -DUSE_LIBXS=ON ${CONFOPTS} -DUSE_ACCEL=none \
  "$@" && \
echo "Next: cmake --build ${BUILD} --target install -j $(nproc)"
