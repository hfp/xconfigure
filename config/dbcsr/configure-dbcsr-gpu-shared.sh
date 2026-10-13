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

if [ "" = "$1" ]; then PRFX=gnu-gpu-shared; else PRFX=$1-gpu-shared; shift; fi
HERE=$(cd "$(dirname "$0")" && pwd -P)
ROOT=$(cd "${HERE}/.." && pwd -P)
DEST=${ROOT}/dbcsr/${PRFX}
BUILD=build-${PRFX}

if [ ! -e "${HERE}/src/dbcsr_api.F" ] || [ "${HERE}" != "$(pwd -P)" ]; then
  echo "Error: XCONFIGURE scripts must be located and executed in the application folder!"
  exit 1
fi

# sibling folder, $<NAME>ROOT (e.g., LIBXSROOT), or $HOME
for DEP in libxs libxsmm libxstream; do
  VAR=$(tr "[:lower:]" "[:upper:]" <<<"${DEP}")ROOT
  for DIR in "${ROOT}/${DEP}" "${!VAR}" "${HOME}/${DEP}"; do
    if [ "${DIR}" ] && [ "$(ls "${DIR}"/lib*/"${DEP}".* 2>/dev/null)" ]; then
      echo "Found ${DEP}: ${DIR}"
      PREFIXES="${PREFIXES:+${PREFIXES};}${DIR}"
      if [ "libxsmm" = "${DEP}" ]; then CONFOPTS+=" -DUSE_LIBXSMM=ON"; fi
      break
    fi
  done
done

# DBCSR sets its own optimization level per build type
TARGET="-march=native -mtune=native"

# shellcheck disable=SC2086
cmake -S "${HERE}" -B "${BUILD}" \
  -DCMAKE_INSTALL_PREFIX="${DEST}" -DCMAKE_INSTALL_LIBDIR=lib \
  -DCMAKE_BUILD_TYPE=Release -DCMAKE_PREFIX_PATH="${PREFIXES}" \
  -DCMAKE_C_COMPILER=mpicc -DCMAKE_C_FLAGS="${TARGET}" \
  -DCMAKE_CXX_COMPILER=mpicxx -DCMAKE_CXX_FLAGS="${TARGET}" \
  -DCMAKE_Fortran_COMPILER=mpif90 -DCMAKE_Fortran_FLAGS="${TARGET}" \
  -DBUILD_SHARED_LIBS=ON -DBUILD_TESTING=OFF -DWITH_EXAMPLES=OFF \
  -DUSE_MPI=ON -DUSE_OPENMP=ON -DUSE_LIBXS=ON ${CONFOPTS} -DUSE_ACCEL=opencl \
  "$@" && \
echo "Next: cmake --build ${BUILD} --target install -j $(nproc)"
