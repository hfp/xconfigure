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
HERE=$(cd $(dirname $0); pwd -P)
DEST=${HERE}/../elpa/${PRFX}

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
MKL_OMPRTL="gnu_thread"
MKL_FCRTL="gf"
TARGET="-march=native"
FLAGS="-O3 ${TARGET} -I${MKLROOT}/include"

export LDFLAGS="-L${MKLROOT}/lib/intel64"
export CFLAGS="${FLAGS}"
export CXXFLAGS="${CFLAGS}"
export FCFLAGS="${FLAGS} -I${MKLROOT}/include/intel64/lp64"
export LIBS="-lmkl_${MKL_FCRTL}_lp64 -lmkl_core -lmkl_${MKL_OMPRTL} -Wl,--as-needed -lgomp -lm -Wl,--no-as-needed"
export SCALAPACK_LDFLAGS="-lmkl_scalapack_lp64 -lmkl_blacs_intelmpi_lp64"

export AR="gcc-ar"
export FC="mpif90"
export CC="mpigcc"
export CXX="mpigxx"

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
  --prefix=${DEST} ${CONFOPTS} $*

sed -i \
  -e "s/-openmp/-qopenmp -qoverride_limits/" \
  -e "s/all-am:\(.*\) \$(PROGRAMS)/all-am:\1/" \
  Makefile

if [ -e ${HERE}/config.h ]; then
  VERSION=$(grep ' VERSION ' config.h | cut -s -d' ' -f3 | sed -e 's/^\"//' -e 's/\"$//')
  if [ "" != "${VERSION}" ]; then
    if [ "1" = "$(grep ' WITH_OPENMP ' config.h | cut -s -d' ' -f3 | sed -e 's/^\"//' -e 's/\"$//')" ]; then
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

