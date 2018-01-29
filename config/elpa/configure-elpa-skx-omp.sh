s#!/bin/bash
#############################################################################
# Copyright (c) 2016-2018, Intel Corporation                                #
# All rights reserved.                                                      #
#                                                                           #
# Redistribution and use in source and binary forms, with or without        #
# modification, are permitted provided that the following conditions        #
# are met:                                                                  #
# 1. Redistributions of source code must retain the above copyright         #
#    notice, this list of conditions and the following disclaimer.          #
# 2. Redistributions in binary form must reproduce the above copyright      #
#    notice, this list of conditions and the following disclaimer in the    #
#    documentation and/or other materials provided with the distribution.   #
# 3. Neither the name of the copyright holder nor the names of its          #
#    contributors may be used to endorse or promote products derived        #
#    from this software without specific prior written permission.          #
#                                                                           #
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS       #
# "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT         #
# LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR     #
# A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT      #
# HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,    #
# SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED  #
# TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR    #
# PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF    #
# LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING      #
# NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS        #
# SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.              #
#############################################################################
# Hans Pabst (Intel Corp.)
#############################################################################

if [ "" = "$1" ]; then PRFX=default-; else PRFX=$1-; shift; fi
HERE=$(cd $(dirname $0); pwd -P)
DEST=${HERE}/../elpa/${PRFX}skx-omp

if [ "${HERE}" = "${DEST}" ]; then
  echo "Warning: ELPA source directory equals installation folder!"
  read -p "Are you sure? Y/N" -n 1 -r
  if [ ! $REPLY =~ ^[Yy]$ ]; then
    exit 1
  fi
fi

FPFLAGS="-fp-model fast=2 -complex-limited-range"
CONFOPTS="--enable-avx512 --enable-openmp"
MKLRTL="intel_thread"
TARGET="-xCORE-AVX512 -qopt-zmm-usage=high"
FLAGS="-O2 ${TARGET} -I${MKLROOT}/include"
#FLAGS+=" -ipo-separate"

export LDFLAGS="-L${MKLROOT}/lib/intel64"
export CFLAGS="${FLAGS} -fno-alias -ansi-alias ${FPFLAGS}"
export CXXFLAGS="${CFLAGS}"
export FCFLAGS="${FLAGS} -I${MKLROOT}/include/intel64/lp64 -align array64byte -threads -heap-arrays 4096"
export LIBS="-lmkl_intel_lp64 -lmkl_core -lmkl_${MKLRTL} -Wl,--as-needed -liomp5 -Wl,--no-as-needed"
export SCALAPACK_LDFLAGS="-lmkl_scalapack_lp64 -lmkl_blacs_intelmpi_lp64"

export AR="xiar"
export FC="mpiifort"
export CC="mpiicc"
export CXX="mpiicpc"

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
   [ "0" != "$((170006>CC_VERSION) && 0!=CC_VERSION))" ]; \
then
  export CC="${CC} -D_Float128=__float128"
fi

# Development versions may require autotools mechanics
if [ -e autogen.sh ]; then
  ./autogen.sh
fi

./configure --disable-option-checking \
  --disable-dependency-tracking \
  --host=x86_64-unknown-linux-gnu \
  --prefix=${DEST} ${CONFOPTS} $*

sed -i \
  -e "s/-openmp/-qopenmp -qoverride_limits/" \
  -e "s/all-am:\(.*\) \$(PROGRAMS)/all-am:\1/" \
  Makefile

if [ -e config.h ]; then
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

