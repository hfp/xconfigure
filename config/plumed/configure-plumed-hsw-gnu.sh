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

if [ "" = "$1" ]; then PRFX=gnu-; else PRFX=$1-; shift; fi
HERE=$(cd "$(dirname "$0")" && pwd -P)
DEST=${HERE}/../plumed/${PRFX}hsw

if [ ! -e "${HERE}/configure.ac" ] || [ "${HERE}" != "$(pwd -P)" ]; then
  echo "Error: XCONFIGURE scripts must be located and executed in the application folder!"
  exit 1
fi

if [ "${HERE}" = "${DEST}" ]; then
  echo "Warning: PLUMED source directory equals installation folder!"
  read -p "Are you sure? Y/N" -n 1 -r
  if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    exit 1
  fi
fi

CONFOPTS="--disable-shared --disable-libsearch --disable-doc --enable-asmjit"
TARGET="-march=core-avx2"

export FLAGS="-O3 ${TARGET} -D__PLUMED_HAS_MPI -D__PLUMED_HAS_FFTW -D__PLUMED_HAS_ZLIB -I${MKLROOT}/include/fftw"
export LDFLAGS=""
export CFLAGS="${FLAGS}"
export CXXFLAGS="${FLAGS}"
export FCFLAGS="${FLAGS}"
export F77FLAGS=${FCFLAGS}
export F90FLAGS=${FCFLAGS}
export FFLAGS=${FCFLAGS}
export LIBS="-L${MKLROOT}/lib/intel64 -lmkl_rt -lz"

export AR="gcc-ar"
export FC="mpif90"
export CC="mpicc"
export CXX="mpicxx"
export F77=${FC}
export F90=${FC}

export MPICC=${CC}
export MPIFC=${FC}
export MPIF77=${F77}
export MPIF90=${F90}
export MPICXX=${CXX}

cat << EOM > .autom4te.cfg
begin-language: "Autoconf-without-aclocal-m4"
args: --no-cache
end-language: "Autoconf-without-aclocal-m4"
EOM

libtoolize
aclocal
#autoheader
#automake -a
autoconf

eval "./configure \
  --prefix=${DEST} ${CONFOPTS} \
  --host=x86_64-unknown-linux-gnu \
  $*"
