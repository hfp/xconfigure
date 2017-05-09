#!/bin/sh
#############################################################################
# Copyright (c) 2017, Intel Corporation                                     #
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

if [ "" = "$1" ]; then PRFX=default; else PRFX=$1; shift; fi
HERE=$(cd $(dirname $0); pwd -P)
DEST=${HERE}/../libint/${PRFX}

if [ "${HERE}" = "${DEST}" ]; then
  echo "Warning: LIBINT source directory equals installation folder!"
  read -p "Are you sure? Y/N" -n 1 -r
  if [ ! $REPLY =~ ^[Yy]$ ]; then
    exit 1
  fi
fi

FPFLAGS=""
CONFOPTS=""
TARGET="-xHost"

export FLAGS="-O2 ${TARGET} -ipo-separate"
export LDFLAGS=""
export CFLAGS="${FLAGS} ${FPFLAGS}"
export CXXFLAGS="${CFLAGS}"
export FCFLAGS="${FLAGS} -align array64byte"
export LIBS=""

export AR="xiar"
export FC="ifort"
export CC="icc"
export CXX="icpc"

aclocal
autoheader
#automake -a
autoconf

./configure --prefix=${DEST} ${CONFOPTS} \
  --with-cc-optflags="-O2 -xCORE-AVX2" \
  --with-cxx-optflags="-O2 -xCORE-AVX2" \
  --with-libderiv-max-am1=4 \
  --with-libint-max-am=5 \
  $*

