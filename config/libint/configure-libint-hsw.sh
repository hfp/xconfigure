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

if [ "" = "$1" ]; then PRFX=intel; else PRFX=$1; shift; fi
HERE=$(cd "$(dirname "$0")" && pwd -P)
DEST=${HERE}/../libint/${PRFX}-hsw

if [[ ((! -e "${HERE}/configure.in") && (! -e "${HERE}/autogen.sh") && (! -e "${HERE}/CMakeLists.txt")) \
   || ("${HERE}" != "$(pwd -P)") ]];
then
  echo "Error: XCONFIGURE scripts must be located and executed in the application folder!"
  exit 1
fi

if [ "${HERE}" = "${DEST}" ]; then
  echo "Warning: LIBINT source directory equals installation folder!"
  read -p "Are you sure? Y/N" -n 1 -r
  if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    exit 1
  fi
fi

CONFOPTS="--with-libderiv-max-am1=5 --with-libint-max-am=6 --enable-fortran --disable-libtool --with-cc-optflags=\"\${CFLAGS}\""
TARGET="-xCORE-AVX2"

# consider more accurate FP-model
#FPCMODEL = -fp-model precise
#FPFMODEL = -fp-model source

export FLAGS="-O2 ${TARGET}" #-ipo-separate
export LDFLAGS=""
export CFLAGS="${FLAGS} ${FPCMODEL}"
export CXXFLAGS="${FLAGS} ${FPCMODEL}"
export FCFLAGS="${FLAGS} ${FPFMODEL} -align array64byte"
export F77FLAGS=${FCFLAGS}
export F90FLAGS=${FCFLAGS}
export FFLAGS=${FCFLAGS}
export LIBS="-lstdc++"

FC="ifx"; CC="icx"; CXX="icpx"
if [ "1" = "${INTEL}" ] || \
   [ ! "$(command -v ${FC})" ] || [ ! "$(command -v ${CC})" ] || [ ! "$(command -v ${CXX})" ];
then
  FC="ifort"
  if [ "1" != "${INTEL}" ]; then
    CC="icc"
    CXX="icpc"
  fi
fi

export AR="xiar"
export FC CC CXX
export F77=${FC}
export F90=${FC}

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

if [ -e "${HERE}/configure.in" ] || [ -e "${HERE}/autogen.sh" ]; then
  if [ -e "${HERE}/fortran/Makefile" ] || [ -e "${HERE}/fortran/Makefile.in" ]; then
    sed -i '/fortran_example:/!b;n;s/CXX/FC/g' "${HERE}"/fortran/Makefile*
  fi
  if [ -e "${HERE}/fortran/Makefile" ]; then
    cd "${HERE}/fortran" || exit 1
    make distclean
    cd "${HERE}" || exit 1
  fi
  if [ -e "${HERE}/autogen.sh" ]; then
    if [ "${BOOST_ROOT}" ] && [ -d "${BOOST_ROOT}/include" ]; then
      export CPATH=${BOOST_ROOT}/include:${CPATH}
    fi
    "${HERE}/autogen.sh"
  elif [ ! -e "${HERE}/configure" ]; then
    autoconf
  fi
  eval "./configure --prefix=${DEST} ${CONFOPTS} \
    --enable-eri=1 --enable-eri2=1 --enable-eri3=1 --with-max-am=6 --with-opt-am=3 \
    --with-eri-max-am=6,5 --with-eri2-max-am=8,7 --with-eri3-max-am=8,7 \
    --with-libint-exportdir=libint-cp2k-lmax6 --disable-unrolling \
    --with-real-type=libint2::simd::VectorAVXDouble --enable-fma \
    --with-cxxgen-optflags=\"${CXXFLAGS}\" \
    $*"
  if [ -e "${HERE}/autogen.sh" ]; then
    make export -j "$(nproc)"
    tar -xf libint-cp2k-lmax6.tgz --strip-components=1 --overwrite
  else
    exit 0
  fi
fi

# preconfigured
if [ ! -e "${HERE}/CMakeLists.txt" ] || [ ! "$(command -v cmake)" ]; then
  echo "Error: XCONFIGURE requires CMake to build LIBINT!"
  exit 1
fi
rm -f "${HERE}/CMakeCache.txt"
cmake . -DCMAKE_INSTALL_PREFIX="${DEST}" \
  -DCMAKE_CXX_COMPILER="${CXX}" -DCMAKE_CXX_FLAGS="${CXXFLAGS}" \
  -DREQUIRE_CXX_API=OFF -DENABLE_FORTRAN=ON
