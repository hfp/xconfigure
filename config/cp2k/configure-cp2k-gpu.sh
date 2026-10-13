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
ROOT=$(cd "${HERE}/.." && pwd -P)
DEST=${ROOT}/cp2k/${PRFX}-gpu
BUILD=build-${PRFX}-gpu

if [ ! -e "${HERE}/src/cp2k_info.F" ] || [ "${HERE}" != "$(pwd -P)" ]; then
  echo "Error: XCONFIGURE scripts must be located and executed in the application folder!"
  exit 1
fi

# sibling folder (flavor-specific first), $<NAME>ROOT, or $HOME
for DEP in dbcsr libint libxc libwignernj libxs libxsmm libxstream; do
  VAR=$(tr "[:lower:]" "[:upper:]" <<<"${DEP}")ROOT
  for DIR in "${ROOT}/${DEP}/${PRFX}-gpu" "${ROOT}/${DEP}/${PRFX}" "${ROOT}/${DEP}" "${!VAR}" \
             "${HOME}/${DEP}/${PRFX}-gpu" "${HOME}/${DEP}/${PRFX}" "${HOME}/${DEP}";
  do
    if [ "${DIR}" ] && [ "$(ls -d "${DIR}"/lib*/cmake "${DIR}"/lib*/pkgconfig "${DIR}"/lib*/"${DEP}".* 2>/dev/null)" ]; then
      echo "Found ${DEP}: ${DIR}"
      PREFIXES="${PREFIXES:+${PREFIXES};}${DIR}"
      case "${DEP}" in
        libint) CONFOPTS+=" -DCP2K_USE_LIBINT2=ON" ;;
        libxc) CONFOPTS+=" -DCP2K_USE_LIBXC=ON" ;;
        libxs) CONFOPTS+=" -DCP2K_USE_LIBXS=ON" ;;
        libxsmm) CONFOPTS+=" -DCP2K_USE_LIBXSMM=ON" ;;
      esac
      break
    fi
  done
done

# CP2K sets its own optimization level per build type
TARGET="-march=native -mtune=native"

# shellcheck disable=SC2086
cmake -S "${HERE}" -B "${BUILD}" \
  -DCMAKE_INSTALL_PREFIX="${DEST}" -DCMAKE_INSTALL_LIBDIR=lib \
  -DCMAKE_INSTALL_RPATH="${DEST}/lib" -DCMAKE_INSTALL_RPATH_USE_LINK_PATH=ON \
  -DCMAKE_BUILD_TYPE=Release -DCMAKE_PREFIX_PATH="${PREFIXES}" \
  -DCMAKE_C_COMPILER=mpicc -DCMAKE_C_FLAGS="${TARGET}" \
  -DCMAKE_CXX_COMPILER=mpicxx -DCMAKE_CXX_FLAGS="${TARGET}" \
  -DCMAKE_Fortran_COMPILER=mpif90 -DCMAKE_Fortran_FLAGS="${TARGET}" \
  -DCP2K_USE_MPI=ON -DCP2K_USE_ACCEL=OPENCL ${CONFOPTS} \
  "$@" && \
echo "Next: cmake --build ${BUILD} -j $(nproc)" && \
echo "  or: cmake --build ${BUILD} --target install -j $(nproc)  # installs into ${DEST}"
