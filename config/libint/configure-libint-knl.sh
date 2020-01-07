#!/bin/bash
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

if [ "" = "$1" ]; then PRFX=default-; else PRFX=$1-; shift; fi
HERE=$(cd $(dirname $0); pwd -P)
DEST=${HERE}/../libint/${PRFX}knl

if [[ ((! -e ${HERE}/configure.in) && (! -e ${HERE}/configure.ac)) || ("${HERE}" != "$(pwd -P)") ]]; then
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

CONFOPTS=""
TARGET="-xMIC-AVX512"

# consider more accurate FP-model
#FPCMODEL = -fp-model precise
#FPFMODEL = -fp-model source

export FLAGS="-O2 ${TARGET}" #-ipo-separate
export LDFLAGS=""
export CFLAGS="${FLAGS} ${FPCMODEL}"
export CXXFLAGS="${FLAGS} ${FPCMODEL}"
export FCFLAGS="${FLAGS} ${FPFMODEL} -align array64byte"
export LIBS="-lstdc++"

export AR="xiar"
export FC="ifort"
export CC="icc"
export CXX="icpc"
export F77=${FC}
export F90=${FC}

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

if [ -e ${HERE}/fortran/Makefile ] || [ -e ${HERE}/fortran/Makefile.in ]; then
  sed -i '/fortran_example:/!b;n;s/CXX/FC/g' ${HERE}/fortran/Makefile*
fi
# broken build system incl. "make -f ${HERE}/fortran/Makefile distclean"
if [ -e ${HERE}/fortran/Makefile ]; then
  cd ${HERE}/fortran
  make distclean
  cd ${HERE}
fi

#libtoolize
#aclocal
#autoheader
#automake -a
#autoconf

if [ ! -e ${HERE}/configure ]; then
  autoconf
fi

./configure --prefix=${DEST} ${CONFOPTS} \
  --with-cc-optflags="${CFLAGS}" \
  --with-cxx-optflags="${CXXFLAGS}" \
  --with-libderiv-max-am1=5 \
  --with-libint-max-am=6 \
  --disable-libtool \
  --enable-fortran \
  $*

