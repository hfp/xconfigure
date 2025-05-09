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
# shellcheck disable=SC2012,SC2086,SC2164

if [ "" = "$1" ]; then PRFX=gnu; else PRFX=$1; shift; fi
HERE=$(cd "$(dirname "$0")" && pwd -P)
DEST=${HERE}/../elpa/${PRFX}-skx

if [[ (! -e "${HERE}/configure") && (! -e "${HERE}/autogen.sh") ]] || [ "${HERE}" != "$(pwd -P)" ]; then
  echo "Error: XCONFIGURE scripts must be located and executed in the application folder!"
  exit 1
fi

if [ "${HERE}" = "${DEST}" ]; then
  echo "Warning: ELPA source directory equals installation folder!"
  read -p "Are you sure? Y/N" -n 1 -r
  if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    exit 1
  fi
fi

# attempt to detect MKLROOT
if [ "" = "${MKLROOT}" ]; then
  MKL_INCFILE=$(ls -1 /opt/intel/compilers_and_libraries_*/linux/mkl/include/mkl.h 2>/dev/null | head -n1)
  if [ "" != "${MKL_INCFILE}" ]; then
    MKLROOT=$(dirname "${MKL_INCFILE}")/..
  fi
fi
if [ "" = "${MKLROOT}" ]; then
  MKL_INCFILE=$(ls -1 /usr/include/mkl/mkl.h 2>/dev/null | head -n1)
  if [ "" != "${MKL_INCFILE}" ]; then
    MKLROOT=$(dirname "${MKL_INCFILE}")/../..
  fi
fi

CONFOPTS+=" --without-threading-support-check-during-build --enable-avx512"
CONFOPTS+=" --disable-single-precision --disable-skew-symmetric-support"
CONFOPTS+=" --disable-fortran-tests --disable-c-tests --disable-cpp-tests"
CONFOPTS+=" --disable-scalapack-tests --without-test-programs"

MKL_OMPRTL="gnu_thread"
MKL_FCRTL="gf"
MKL_BITS="lp64"

TARGET="-mavx512f -mavx512cd -mavx512dq -mavx512bw -mavx512vl -mfma"
FLAGS="-I${MKLROOT}/include -O3 ${TARGET}"
if [ "0" != "${OMP}" ]; then
  CONFOPTS+=" --enable-openmp"
fi

export CFLAGS="${FLAGS}"
export CXXFLAGS="${CFLAGS}"
export FCFLAGS="${FLAGS} -I${MKLROOT}/include/intel64/${MKL_BITS}"
export LIBS="-lmkl_${MKL_FCRTL}_${MKL_BITS} -lmkl_core -lmkl_${MKL_OMPRTL} -Wl,--as-needed -lgomp -lm -Wl,--no-as-needed"
export SCALAPACK_LDFLAGS="-lmkl_scalapack_${MKL_BITS} -lmkl_blacs_intelmpi_${MKL_BITS}"
export LDFLAGS="-L${MKLROOT}/lib/intel64"

export AR="gcc-ar"
export FC="mpif90"
export CC="mpicc"
export CXX="mpicxx"

export F77=${FC} F90=${FC} MPIFC=${FC} MPICC=${CC}
export MPIF77=${F77} MPIF90=${F90} MPICXX=${CXX}
export F77FLAGS=${FCFLAGS}
export F90FLAGS=${FCFLAGS}
export FFLAGS=${FCFLAGS}

# Development versions may require autotools mechanics
if [ -e "${HERE}/autogen.sh" ]; then
  if command -v libtoolize >/dev/null; then libtoolize; fi
  ./autogen.sh
fi

if [ ! -e "${HERE}/remove_xcompiler" ]; then
  echo "#!/usr/bin/env bash" > "${HERE}/remove_xcompiler"
  echo "remove=(-Xcompiler)" >> "${HERE}/remove_xcompiler"
  echo "\${@/\${remove}}" >> "${HERE}/remove_xcompiler"
  chmod +x "${HERE}/remove_xcompiler"
fi

./configure --disable-option-checking \
  --disable-dependency-tracking \
  --host=x86_64-unknown-linux-gnu \
  --disable-mpi-module \
  --prefix="${DEST}" ${CONFOPTS} "$@"

if [ -e "${HERE}/Makefile" ]; then
  sed -i "s/all-am:\(.*\) \$(PROGRAMS)/all-am:\1/" Makefile
fi
