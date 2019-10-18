#!/bin/bash
#############################################################################
# Copyright (c) 2018-2019, Intel Corporation                                #
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

if [ "" = "$1" ]; then PRFX=gnu-; else PRFX=$1-; shift; fi
HERE=$(cd $(dirname $0); pwd -P)
DEST=${HERE}/../libint/${PRFX}hsw

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
TARGET="-march=core-avx2"

export FLAGS="-O3 ${TARGET}"
export LDFLAGS=""
export CFLAGS="${FLAGS}"
export CXXFLAGS="${FLAGS}"
export FCFLAGS="${FLAGS}"
export LIBS="-lstdc++"

export AR="gcc-ar"
export FC="gfortran"
export CC="gcc"
export CXX="g++"
export F77=${FC}
export F90=${FC}

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

