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
DEST=${HERE}/../libxc/${PRFX}

if [ ! -e "${HERE}/configure.ac" ] || [ "${HERE}" != "$(pwd -P)" ]; then
  echo "Error: XCONFIGURE scripts must be located and executed in the application folder!"
  exit 1
fi

if [ "${HERE}" = "${DEST}" ]; then
  echo "Warning: LIBXC source directory equals installation folder!"
  read -p "Are you sure? Y/N" -n 1 -r
  if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    exit 1
  fi
fi

CONFOPTS=""
TARGET="-march=native -mtune=native"

export FLAGS="-O3 ${TARGET}"
export LDFLAGS=""
export CFLAGS="${FLAGS}"
export CXXFLAGS="${FLAGS}"
export FCFLAGS="${FLAGS}"
export LIBS=""

export AR="gcc-ar"
export FC="gfortran"
export CC="gcc"
export CXX="g++"

export F77=${FC} F90=${FC} MPIFC=${FC} MPICC=${CC}
export MPIF77=${F77} MPIF90=${F90} MPICXX=${CXX}
export F77FLAGS=${FCFLAGS}
export F90FLAGS=${FCFLAGS}
export FFLAGS=${FCFLAGS}

cat << EOM > .autom4te.cfg
begin-language: "Autoconf-without-aclocal-m4"
args: --no-cache
end-language: "Autoconf-without-aclocal-m4"
EOM

libtoolize
aclocal
autoheader
automake -a
autoconf

eval "./configure \
  --prefix=${DEST} ${CONFOPTS} \
  --host=x86_64-unknown-linux-gnu \
  $*"

