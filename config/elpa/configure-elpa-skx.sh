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

if [ "" = "$1" ]; then PRFX=intel-; else PRFX=$1-; shift; fi
HERE=$(cd "$(dirname "$0")" && pwd -P)
DEST=${HERE}/../elpa/${PRFX}skx

if [ ! -e ${HERE}/configure ] || [ "${HERE}" != "$(pwd -P)" ]; then
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
    MKLROOT=$(dirname ${MKL_INCFILE})/..
  fi
fi
if [ "" = "${MKLROOT}" ]; then
  MKL_INCFILE=$(ls -1 /usr/include/mkl/mkl.h 2>/dev/null | head -n1)
  if [ "" != "${MKL_INCFILE}" ]; then
    MKLROOT=$(dirname ${MKL_INCFILE})/../..
  fi
fi

CONFOPTS="--enable-avx512"
FPFLAGS="-fp-model fast=2 -complex-limited-range"
MKL_OMPRTL="intel_thread"
MKL_FCRTL="intel"

TARGET="-xCORE-AVX512 -qopt-zmm-usage=high"
FLAGS="-O2 ${TARGET} -I${MKLROOT}/include"
#FLAGS+="" #-ipo-separate

export LDFLAGS="-L${MKLROOT}/lib/intel64"
export CFLAGS="${FLAGS} -fno-alias -ansi-alias ${FPFLAGS}"
export CXXFLAGS="${CFLAGS}"
export FCFLAGS="${FLAGS} -I${MKLROOT}/include/intel64/lp64 -align array64byte -threads -heap-arrays 4096"
export LIBS="-lmkl_${MKL_FCRTL}_lp64 -lmkl_core -lmkl_${MKL_OMPRTL} -Wl,--as-needed -liomp5 -Wl,--no-as-needed"
export SCALAPACK_LDFLAGS="-lmkl_scalapack_lp64 -lmkl_blacs_intelmpi_lp64"
export F77FLAGS=${FCFLAGS}
export F90FLAGS=${FCFLAGS}
export FFLAGS=${FCFLAGS}

FC="ifx"; CC="icx"; CXX="icpx"
if [ ! "$(command -v ${FC})" ] || [ ! "$(command -v ${CC})" ] || [ ! "$(command -v ${CXX})" ]; then
  FC="ifort"
  CC="icc"
  CXX="icpc"
fi

export AR="xiar"
export FC="mpiifort -fc=${FC}"
export CC="mpiicc   -cc=${CC}"
export CXX="mpiicpc -cxx=${CXX}"
export F77=${FC}
export F90=${FC}

export MPICC=${CC}
export MPIFC=${FC}
export MPIF77=${F77}
export MPIF90=${F90}
export MPICXX=${CXX}

CC_VERSION_STRING=$(${CC} --version 2> /dev/null | head -n1 | sed "s/..* \([0-9][0-9]*\.[0-9][0-9]*\.*[0-9]*\)[ \S]*.*/\1/")
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
if [ -e ${HERE}/autogen.sh ]; then
  ./autogen.sh
fi

if [ ! -e ${HERE}/remove_xcompiler ]; then
  echo "#!/usr/bin/env bash" > ${HERE}/remove_xcompiler
  echo "remove=(-Xcompiler)" >> ${HERE}/remove_xcompiler
  echo "\${@/\${remove}}" >> ${HERE}/remove_xcompiler
  chmod +x ${HERE}/remove_xcompiler
fi

./configure --disable-option-checking \
  --disable-dependency-tracking \
  --host=x86_64-unknown-linux-gnu \
  --disable-mpi-module \
  --prefix=${DEST} ${CONFOPTS} "$@"

sed -i \
  -e "s/-openmp/-qopenmp -qoverride_limits/" \
  -e "s/all-am:\(.*\) \$(PROGRAMS)/all-am:\1/" \
  Makefile

if [ -e ${HERE}/config.h ]; then
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
    ln -fs libelpa_openmp.a libelpa.a
    ln -fs libelpa.a libelpa_mt.a
  fi
fi

