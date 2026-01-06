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

if [ "" = "$1" ]; then PRFX=intel; else PRFX=$1; shift; fi
HERE=$(cd "$(dirname "$0")" && pwd -P)
DEST=${HERE}/../elpa/${PRFX}

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

if [ -e /proc/cpuinfo ] && [ "" = "$(grep -m1 flags /proc/cpuinfo | grep avx512f)" ]; then
  CONFOPTS="--disable-avx512"
elif [ "Darwin" = "$(uname)" ] && [ "x86_64" = "$(uname -m)" ] && \
     [ "" = "$(sysctl -a machdep.cpu.leaf7_features | grep AVX512F)" ];
then
  CONFOPTS="--disable-avx512"
fi

CONFOPTS+=" --without-threading-support-check-during-build"
CONFOPTS+=" --disable-single-precision --disable-skew-symmetric-support"
CONFOPTS+=" --disable-scalapack-tests --without-test-programs"
CONFOPTS+=" --disable-fortran-tests --enable-Fortran-tests"
CONFOPTS+=" --disable-c-tests --disable-cpp-tests"

MKL_OMPRTL="intel_thread"
MKL_FCRTL="intel"
MKL_BITS="lp64"

TARGET="-xHost"
FLAGS="-I${MKLROOT}/include -O3 ${TARGET}"
if [ "0" != "${OMP}" ]; then
  CONFOPTS+=" --enable-openmp"
  FLAGS+=" -qopenmp"
fi

CFLAGS="${FLAGS} -fno-alias -ansi-alias -fp-model fast"
CXXFLAGS="${CFLAGS}"
FCFLAGS="${FLAGS} -I${MKLROOT}/include/intel64/${MKL_BITS} -align array64byte -threads"
LIBS="-lmkl_${MKL_FCRTL}_${MKL_BITS} -lmkl_core -lmkl_${MKL_OMPRTL} -Wl,--as-needed -liomp5 -Wl,--no-as-needed"
SCALAPACK_LDFLAGS="-lmkl_scalapack_${MKL_BITS} -lmkl_blacs_intelmpi_${MKL_BITS}"
LDFLAGS="-L${MKLROOT}/lib/intel64"

AR=$(command -v xiar || echo "ar")
if [ "1" != "${INTEL}" ]; then
  CXX=$(command -v mpiicpx || echo "mpiicpc -cxx=icpx")
  CC=$(command -v mpiicx || echo "mpiicc -cc=icx")
else
  CXX="mpiicpc -cxx=$(command -v icpc || echo icpx)"
  CC="mpiicc -cc=$(command -v icc || echo icx)"
fi

if [ "1" != "${INTEL}" ]; then
  FC=$(command -v mpiifx || echo "mpiifort -fc=ifx")
  CONFOPTS+=" --enable-ifx-compiler"
  if [ "0" != "${GPU}" ]; then # incl. undefined
    CONFOPTS+=" --enable-intel-gpu-backend=sycl --enable-gpu-streams=sycl --enable-intel-gpu-sycl-kernels"
    CXXISYCL=$(dirname "$(command -v ${CXX})")/../linux/include/sycl
    CXXFLAGS+=" -I${CXXISYCL} -fsycl -fsycl-targets=spir64"
    LIBS+=" -lmkl_sycl" # -lsvml
    LDFLAGS+=" -Wc,-fsycl"
  fi
else
  FC="mpiifort"
fi

export CXXFLAGS CFLAGS FCFLAGS LDFLAGS LIBS
export SCALAPACK_LDFLAGS

export CXX CC FC AR
export F77=${FC} F90=${FC} MPIFC=${FC} MPICC=${CC}
export MPIF77=${F77} MPIF90=${F90} MPICXX=${CXX}
export F77FLAGS=${FCFLAGS}
export F90FLAGS=${FCFLAGS}
export FFLAGS=${FCFLAGS}

CC_VERSION_STRING=$(${CC} --version 2>/dev/null | head -n1 | sed "s/..* \([0-9][0-9]*\.[0-9][0-9]*\.*[0-9]*\)[ \S]*.*/\1/")
CC_VERSION_MAJOR=$(echo "${CC_VERSION_STRING}" | cut -d"." -f1)
CC_VERSION_MINOR=$(echo "${CC_VERSION_STRING}" | cut -d"." -f2)
CC_VERSION_PATCH=$(echo "${CC_VERSION_STRING}" | cut -d"." -f3)
CC_VERSION_COMPONENTS=$(echo "${CC_VERSION_MAJOR} ${CC_VERSION_MINOR} ${CC_VERSION_PATCH}" | wc -w)
if [ "3" = "${CC_VERSION_COMPONENTS}" ]; then
  CC_VERSION=$((CC_VERSION_MAJOR * 10000 + CC_VERSION_MINOR * 100 + CC_VERSION_PATCH))
elif [ "2" = "${CC_VERSION_COMPONENTS}" ]; then
  CC_VERSION=$((CC_VERSION_MAJOR * 10000 + CC_VERSION_MINOR * 100))
  CC_VERSION_PATCH=0
else
  CC_VERSION_STRING=""
  CC_VERSION=0
fi

if [ "0" != "$((180000<=CC_VERSION && 180001>CC_VERSION))" ] || \
   [ "0" != "$((170006>CC_VERSION && 0!=CC_VERSION))" ]; \
then
  export CC="${CC} -D_Float128=__float128"
fi

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
  --prefix="${DEST}" ${CONFOPTS} "$@"

if [ -e "${HERE}/src/GPU/vendor_agnostic_general_layer_template.F90" ] && command -v patch >/dev/null; then
  if patch -p0 --dry-run ${HERE}/src/GPU/vendor_agnostic_general_layer_template.F90 ${HERE}/vendor_agnostic_general_layer_template.F90.diff >/dev/null; then
    patch -p0 ${HERE}/src/GPU/vendor_agnostic_general_layer_template.F90 ${HERE}/vendor_agnostic_general_layer_template.F90.diff
  fi
fi

if [ -e "${HERE}/Makefile" ]; then
  TARGET=$(sed -n 's/\(libelpa_..*_public.la\):..*/\1/p' ${HERE}/Makefile)
  sed -i "s/all-am:\(.*\)\$(PROGRAMS)\(.*\)/all-am:\1\2/" ${HERE}/Makefile
  sed -i "s/all-am:\(.*\)\$(LTLIBRARIES)\(.*\)/all-am:\1\2/" ${HERE}/Makefile
  sed -i "s/all-am:\(.*\)/all-am: ${TARGET}\1/" ${HERE}/Makefile
fi
