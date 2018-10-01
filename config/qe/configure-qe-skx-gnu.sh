#!/bin/bash
#############################################################################
# Copyright (c) 2018, Intel Corporation                                     #
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

TARGET="-mavx512f -mavx512cd -mavx512dq -mavx512bw -mavx512vl -mfma"
#IPO="-flto -Wl,-flto"
FPFLAGS="-ffast-math"
EXX_ACE="-D__EXX_ACE"
OPTC=-O3
OPTF=-O3
if [ "" = "$1" ]; then PRFX=gnu-; else PRFX=$1-; shift; fi


HERE=$(cd $(dirname $0); pwd -P)
export ELPAROOT="${HERE}/../elpa/${PRFX}skx"
#export OPENMP="--enable-openmp"
#export LD_LIBS="-Wl,--as-needed -lgomp -lm -Wl,--no-as-needed"

#export MKL_OMPRTL=sequential
export MKL_OMPRTL=gnu_thread
export MKL_FCRTL=gf
export MPIF90=mpif90
export F90=gfortran
export FC=gfortran
export CC=mpigcc
export AR=gcc-ar
export dir=none

#LIBXSMM="-Wl,--wrap=sgemm_,--wrap=dgemm_ ${HOME}/libxsmm/lib/libxsmmext.a ${HOME}/libxsmm/lib/libxsmm.a"
export BLAS_LIBS="${LIBXSMM} -Wl,--start-group \
    ${MKLROOT}/lib/intel64/libmkl_${MKL_FCRTL}_lp64.a \
    ${MKLROOT}/lib/intel64/libmkl_core.a \
    ${MKLROOT}/lib/intel64/libmkl_${MKL_OMPRTL}.a \
    ${MKLROOT}/lib/intel64/libmkl_blacs_intelmpi_lp64.a \
  -Wl,--end-group"
export LAPACK_LIBS="${BLAS_LIBS}"
export SCALAPACK_LIBS="${MKLROOT}/lib/intel64/libmkl_scalapack_lp64.a"
#export SCALAPACK_LIBS="${HOME}/scalapack/${PRFX}skx/libscalapack.a"
export FFT_LIBS="${BLAS_LIBS}"

rm -f make.sys make.inc
./configure ${OPENMP} --with-scalapack=intel --with-elpa=${ELPAROOT} \
  --with-elpa-include="-I${ELPAROOT}/include/elpa/modules" \
  --with-elpa-lib=${ELPAROOT}/lib/libelpa.a \
  $*

if [ -e ${HERE}/make.inc ]; then
  INCFILE=${HERE}/make.inc
else
  INCFILE=${HERE}/make.sys
fi

# adjust generated configuration
SED_ELPAROOT=$(echo ${ELPAROOT} | sed -e "s/\//\\\\\//g")
sed -i \
  -e "s/-D__ELPA_2016/-D__ELPA_2017/" \
  -e "s/-D__ELPA_2017/-D__ELPA_2018/" \
  -e "s/-D__FFTW3/-D__DFTI/" \
  -e "s/-I-I/-I/" \
  ${INCFILE}
sed -i \
  -e "s/-D__FFTW/-D__DFTI/" -e "s/-D__DFTI/-D__DFTI ${EXX_ACE}/" \
  -e "s/^IFLAGS\s\s*=\s\(..*\)/IFLAGS = -I\$(MKLROOT)\/include\/fftw -I\$(MKLROOT)\/include -I${SED_ELPAROOT}\/include\/elpa\/modules \1/" \
  -e "s/^FFLAGS\s\s*=\s-O3/FFLAGS = ${OPTF} ${IPO} ${TARGET} ${FPFLAGS} -ffpe-summary=none/" \
  -e "s/^CFLAGS\s\s*=\s-O3/CFLAGS = ${OPTC} ${IPO} ${TARGET} ${FPFLAGS}/" \
  -e "s/-x f95-cpp-input -fopenmp/-x f95-cpp-input/" \
  ${INCFILE}

# extended capabilities
echo >> ${INCFILE}
cat configure-qe-tbbmalloc.mak >> ${INCFILE}
echo >> ${INCFILE}
cat configure-qe-libxsmm.mak >> ${INCFILE}
echo >> ${INCFILE}

# patch source code files for modern ELPA
sed -i -e "s/\$(MOD_FLAG)\.\.\/ELPA\/src//" ${HERE}/Modules/Makefile
patch -N ${HERE}/LAXlib/dspev_drv.f90 ${HERE}/configure-qe-dspev_drv.patch
patch -N ${HERE}/LAXlib/zhpev_drv.f90 ${HERE}/configure-qe-zhpev_drv.patch
patch -N ${HERE}/PW/src/setup.f90 ${HERE}/configure-qe-setup_pw.patch

# reminder
echo "Ready to \"make all\"!"

