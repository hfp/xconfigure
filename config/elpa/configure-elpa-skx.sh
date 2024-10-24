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

CONFOPTS+=" --without-threading-support-check-during-build --enable-openmp --enable-avx512"
CONFOPTS+=" --disable-single-precision --disable-skew-symmetric-support"
CONFOPTS+=" --disable-fortran-tests --disable-c-tests --disable-cpp-tests"
CONFOPTS+=" --with-test-programs=no"

MKL_OMPRTL="intel_thread"
MKL_FCRTL="intel"
MKL_BITS="ilp64"

TARGET="-xCORE-AVX512"
TARGET_GNU="-mavx512f -mavx512cd -mavx512dq -mavx512bw -mavx512vl -mfma"
FLAGS="-O3 -I${MKLROOT}/include"

CFLAGS="${FLAGS} -qopenmp -fno-alias -ansi-alias -fp-model fast ${TARGET}"
CXXFLAGS="${CFLAGS}"
FCFLAGS="${FLAGS} -I${MKLROOT}/include/intel64/${MKL_BITS}"
SCALAPACK_LDFLAGS="-lmkl_scalapack_${MKL_BITS} -lmkl_blacs_intelmpi_${MKL_BITS}"
LIBS="-lmkl_${MKL_FCRTL}_${MKL_BITS} -lmkl_core -lmkl_${MKL_OMPRTL} -Wl,--as-needed -liomp5 -Wl,--no-as-needed"
LDFLAGS="-L${MKLROOT}/lib/intel64"

AR=$(command -v xiar || echo "ar")
if [ "1" != "${INTEL}" ]; then
  CXX=$(command -v mpiicpx || echo "mpiicpc -cxx=icpx")
  CC=$(command -v mpiicx || echo "mpiicc -cc=icx")
else
  CXX="mpiicpc -cxx=$(command -v icpc || echo icpx)"
  CC="mpiicc -cc=$(command -v icc || echo icx)"
fi

if [ "0" != "${GPU}" ]; then # incl. undefined
  CONFOPTS+=" --enable-intel-gpu-backend=sycl --enable-intel-gpu-sycl-kernels"
  CXXFLAGS+=" -I$(dirname "$(command -v ${CXX})")/../linux/include/sycl -fsycl-targets=spir64 -fsycl"
  LIBS+=" -lmkl_sycl -lsycl -lsvml"
fi
if [ "1" != "${INTEL}" ]; then
  if [ "0" != "${INTEL}" ]; then
    FC=$(command -v mpiifx || echo "mpiifort -fc=ifx")
    FCFLAGS+=" ${TARGET} -align array64byte -threads -qopenmp"
    CONFOPTS+=" --enable-ifx-compiler"
  else
    FCFLAGS+=" ${TARGET_GNU}"
    FC=mpif90
  fi
else
  FCFLAGS+=" ${TARGET} -align array64byte -threads -qopenmp"
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
  --host=x86_64-unknown-linux-gnu \
  --disable-mpi-module \
  --prefix="${DEST}" ${CONFOPTS} "$@"

if [ -e "${HERE}/Makefile" ]; then
  sed -i \
    -e "s/all-am:\(.*\) \$(PROGRAMS)/all-am:\1/" \
    Makefile
fi

if [ -e "${HERE}/config.h" ]; then
  VERSION=$(grep ' VERSION ' config.h | cut -s -d' ' -f3 | sed -e 's/^\"//' -e 's/\"$//')
  if [ "" != "${VERSION}" ]; then
    if [ "0" != "$(grep ' WITH_OPENMP' config.h | cut -s -d' ' -f3 | sed -e 's/^\"//' -e 's/\"$//')" ]; then
      ELPA=elpa_openmp
    else
      ELPA=elpa
    fi
    mkdir -p ${DEST}/include/${ELPA}-${VERSION}
    if [ ! -e ${DEST}/include/elpa ]; then
      CWD=$(pwd)
      cd ${DEST}/include
      ln -s ${ELPA}-${VERSION} elpa
      cd ${CWD}
    fi
    mkdir -p ${DEST}/lib
    cd ${DEST}/lib
    if [ -e libelpa_openmp.so ]; then ln -fs libelpa_openmp.so libelpa.so; fi
    if [ -e libelpa_openmp.a ]; then ln -fs libelpa_openmp.a libelpa.a; fi
    if [ -e libelpa.so ]; then ln -fs libelpa.so libelpa_mt.so; fi
    if [ -e libelpa.a ]; then ln -fs libelpa.a libelpa_mt.a; fi
  fi
fi
