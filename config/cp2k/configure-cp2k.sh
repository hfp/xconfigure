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
ROOT=$(cd "${HERE}/.." && pwd -P)
DEST=${ROOT}/cp2k/${ARCH}/${PRFX}-cpu
BUILD=build-${ARCH}-${PRFX}-cpu

if [ ! -e "${HERE}/src/cp2k_info.F" ] || [ "${HERE}" != "$(pwd -P)" ]; then
  echo "Error: XCONFIGURE scripts must be located and executed in the application folder!"
  exit 1
fi

# sibling folder (architecture and flavor first), $<NAME>ROOT, or $HOME
for DEP in dbcsr fftw libint libxc libwignernj libxs libxsmm; do
  VAR=$(tr "[:lower:]" "[:upper:]" <<<"${DEP}")ROOT
  for DIR in "${ROOT}/${DEP}/${ARCH}/${PRFX}-cpu" "${ROOT}/${DEP}/${ARCH}/${PRFX}" "${ROOT}/${DEP}/${ARCH}" \
             "${ROOT}/${DEP}/${PRFX}-cpu" "${ROOT}/${DEP}/${PRFX}" "${ROOT}/${DEP}" "${!VAR}" \
             "${HOME}/${DEP}/${ARCH}/${PRFX}-cpu" "${HOME}/${DEP}/${ARCH}/${PRFX}" "${HOME}/${DEP}/${ARCH}" \
             "${HOME}/${DEP}/${PRFX}-cpu" "${HOME}/${DEP}/${PRFX}" "${HOME}/${DEP}";
  do
    if [ "${DIR}" ] && [ "$(ls -d "${DIR}"/lib*/cmake "${DIR}"/lib*/pkgconfig "${DIR}"/lib*/"${DEP}".* 2>/dev/null)" ]; then
      echo "Found ${DEP}: ${DIR}"
      PREFIXES="${PREFIXES:+${PREFIXES};}${DIR}"
      case "${DEP}" in
        libint) CONFOPTS+=" -DCP2K_USE_LIBINT2=ON" ;;
        libxc) CONFOPTS+=" -DCP2K_USE_LIBXC=ON" ;;
        libxs) CONFOPTS+=" -DCP2K_USE_LIBXS=ON" ;;
        libxsmm) CONFOPTS+=" -DCP2K_USE_LIBXSMM=ON" ;;
        fftw) FFTW=${DIR} ;;
      esac
      break
    fi
  done
done

# NVPL (e.g., Grace) provides FFTW's interface, NVPL=1 also selects its BLAS/LAPACK/ScaLAPACK
for DIR in ${NVPL_ROOT:+"${NVPL_ROOT}"} /usr; do
  # shellcheck disable=SC2012
  NVPLLIB=$(ls -d "${DIR}"/lib*/libnvpl_fftw.so "${DIR}"/lib/*/libnvpl_fftw.so 2>/dev/null | head -n1)
  if [ "${NVPLLIB}" ]; then NVPLLIB=$(dirname "${NVPLLIB}"); NVPLINC=${DIR}/include; break; fi
done
if [ "1" = "${NVPL}" ] && [ ! "${NVPLLIB}" ]; then
  echo "Error: NVPL requested but not found (NVPL_ROOT)!"
  exit 1
fi
if [ "${NVPLLIB}" ] && { [ "1" = "${NVPL}" ] || [ ! "${FFTW}" ]; }; then
  echo "Found NVPL: ${NVPLLIB}"
  CONFOPTS+=" -DCP2K_FFTW3_FOUND=ON -DCP2K_FFTW3_INCLUDE_DIRS=${NVPLINC}/nvpl_fftw"
  CONFOPTS+=" -DCP2K_FFTW3_LINK_LIBRARIES=${NVPLLIB}/libnvpl_fftw.so"
  CONFOPTS+=" -DCP2K_FFTW3_OMP_FOUND=ON -DCP2K_FFTW3_OMP_LINK_LIBRARIES=${NVPLLIB}/libnvpl_fftw.so"
fi
if [ "1" = "${NVPL}" ]; then  # DBCSR must use the same BLAS/LAPACK
  CONFOPTS+=" -DCP2K_BLAS_VENDOR=CUSTOM -DCP2K_BLAS_INCLUDE_DIRS=${NVPLINC}"
  CONFOPTS+=" -DCP2K_BLAS_LINK_LIBRARIES=${NVPLLIB}/libnvpl_blas_lp64_gomp.so;${NVPLLIB}/libnvpl_blas_core.so"
  CONFOPTS+=" -DCP2K_LAPACK_LINK_LIBRARIES=${NVPLLIB}/libnvpl_lapack_lp64_gomp.so;${NVPLLIB}/libnvpl_lapack_core.so"
  CONFOPTS+=" -DCP2K_SCALAPACK_VENDOR=NVPL"
  if [ "${NVPL_ROOT}" ]; then PREFIXES="${PREFIXES:+${PREFIXES};}${NVPL_ROOT}"; fi
fi

# CP2K sets its own optimization level per build type
# shellcheck disable=SC2086
cmake -S "${HERE}" -B "${BUILD}" \
  -DCMAKE_INSTALL_PREFIX="${DEST}" -DCMAKE_INSTALL_LIBDIR=lib \
  -DCMAKE_INSTALL_RPATH="${DEST}/lib" -DCMAKE_INSTALL_RPATH_USE_LINK_PATH=ON \
  -DCMAKE_BUILD_TYPE=Release -DCMAKE_PREFIX_PATH="${PREFIXES}" \
  -DCMAKE_C_COMPILER=mpicc -DCMAKE_C_FLAGS="${TARGET}" \
  -DCMAKE_CXX_COMPILER=mpicxx -DCMAKE_CXX_FLAGS="${TARGET}" \
  -DCMAKE_Fortran_COMPILER=mpif90 -DCMAKE_Fortran_FLAGS="${TARGET}" \
  -DCP2K_USE_MPI=ON -DCP2K_USE_ACCEL=NONE ${CONFOPTS} \
  "$@" && \
echo "Next: cmake --build ${BUILD} -j $(nproc)" && \
echo "  or: cmake --build ${BUILD} --target install -j $(nproc)  # installs into ${DEST}"
