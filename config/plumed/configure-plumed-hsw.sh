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

if [ "" = "$1" ]; then PRFX=intel-; else PRFX=$1-; shift; fi
HERE=$(cd $(dirname $0); pwd -P)
DEST=${HERE}/../plumed/${PRFX}hsw

if [ ! -e ${HERE}/configure.ac ] || [ "${HERE}" != "$(pwd -P)" ]; then
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

CONFOPTS=""
TARGET="-xCORE-AVX2"

# consider more accurate FP-model
#FPCMODEL = -fp-model precise
#FPFMODEL = -fp-model source

export FLAGS="-O2 ${TARGET}" #-ipo-separate
export LDFLAGS=""
export CFLAGS="${FLAGS} ${FPCMODEL}"
export CXXFLAGS="${FLAGS} ${FPCMODEL}"
export FCFLAGS="${FLAGS} ${FPFMODEL} -align array64byte"
export LIBS=""

export AR="xiar"
export FC="ifort"
export CC="icc"
export CXX="icpc"
export F77=${FC}
export F90=${FC}

libtoolize
aclocal
#autoheader
#automake -a
autoconf

./configure \
  --prefix=${DEST} ${CONFOPTS} \
  --host=x86_64-unknown-linux-gnu \
  $*

