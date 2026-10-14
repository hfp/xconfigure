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
DEST=${HERE}/../libmed/${ARCH}/${PRFX}

if [ ! -e "${HERE}/configure.ac" ] || [ "${HERE}" != "$(pwd -P)" ]; then
  echo "Error: XCONFIGURE scripts must be located and executed in the application folder!"
  exit 1
fi

if [ "${HERE}" = "${DEST}" ]; then
  echo "Warning: LIBMED source directory equals installation folder!"
  read -p "Are you sure? Y/N" -n 1 -r
  if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    exit 1
  fi
fi

CONFOPTS="--disable-dependency-tracking"

export FLAGS="-O3 ${TARGET}"
export LDFLAGS=""
export CFLAGS="${FLAGS}"
export CXXFLAGS="${FLAGS}"
export FCFLAGS="${FLAGS}"

export AR="gcc-ar"
export FC="mpif90"
export CC="mpicc"
export CXX="mpicxx"

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
#autoheader
#automake -a
autoconf

eval "./configure \
  --prefix=${DEST} ${CONFOPTS} \
  --host=x86_64-unknown-linux-gnu \
  $*"

