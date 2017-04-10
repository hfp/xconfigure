#!/bin/sh
#############################################################################
# Copyright (c) 2013-2017, Intel Corporation                                #
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

TARGET="-xAVX"
OMPFLAG="-qopenmp -qoverride_limits"
#IPO="-ipo-separate"
OPTC=-O3
OPTF=-O2
if [ "" = "$1" ]; then PRFX=default-; else PRFX=$1-; shift; fi

# consider more accurate -fp-model (C/C++: precise, Fortran: source)
FPFLAGS="-fp-model fast=2 -complex-limited-range"
EXX_ACE="-D__EXX_ACE"

HERE=$(cd $(dirname $0); pwd -P)
export ELPAROOT="${HERE}/../elpa/${PRFX}snb-omp"
#export MKLRTL="sequential"
export MKLRTL="intel_thread"
export OPENMP="--enable-openmp"
export LD_LIBS="-Wl,--as-needed -liomp5 -Wl,--no-as-needed"
export MPIF90=mpiifort
export CC=mpiicc
export AR=xiar
export dir=none

#LIBXSMM="-Wl,--wrap=sgemm_,--wrap=dgemm_ ${HOME}/libxsmm/lib/libxsmmext.a ${HOME}/libxsmm/lib/libxsmm.a"
export BLAS_LIBS="${LIBXSMM} -Wl,--start-group \
    ${MKLROOT}/lib/intel64/libmkl_intel_lp64.a \
    ${MKLROOT}/lib/intel64/libmkl_core.a \
    ${MKLROOT}/lib/intel64/libmkl_${MKLRTL}.a \
    ${MKLROOT}/lib/intel64/libmkl_blacs_intelmpi_lp64.a \
  -Wl,--end-group"
export LAPACK_LIBS="${BLAS_LIBS}"
export SCALAPACK_LIBS="${MKLROOT}/lib/intel64/libmkl_scalapack_lp64.a"
#export SCALAPACK_LIBS="${HOME}/scalapack/${PRFX}snb/libscalapack.a"
export FFT_LIBS="${BLAS_LIBS}"

./configure ${OPENMP} --with-scalapack=intel --with-elpa=${ELPAROOT} \
  --with-elpa-include="-I${ELPAROOT}/include/elpa/modules" \
  --with-elpa-lib=${ELPAROOT}/lib/libelpa.a \
  $*

if [ -e make.inc ]; then
  INCFILE=${HERE}/make.inc
else
  INCFILE=${HERE}/make.sys
fi

# adjust generated configuration
SED_ELPAROOT=$(echo ${ELPAROOT} | sed -e "s/\//\\\\\//g")
sed -i \
  -e "s/-nomodule -openmp/-nomodule/" \
  -e "s/-par-report0 -vec-report0//" \
  -e "s/-D__FFTW3/-D__DFTI/" \
  ${INCFILE}
sed -i \
  -e "s/-D__ELPA /-D__ELPA3 -D__ELPA_2016 /" -e "s/-D__ELPA_2016/-D__ELPA_2017/" \
  -e "s/-D__FFTW/-D__DFTI/" -e "s/-D__DFTI/-D__DFTI ${EXX_ACE}/" \
  -e "s/^IFLAGS\s\s*=\s..*/IFLAGS         = -I\.\.\/include -I\$(MKLROOT)\/include\/fftw -I${SED_ELPAROOT}\/include\/elpa\/modules/" \
  -e "s/-O3/${OPTC} ${IPO} ${TARGET} ${FPFLAGS} -fno-alias -ansi-alias/" \
  -e "s/-O2 -assume byterecl -g -traceback/${OPTF} -align array64byte -threads -heap-arrays 4096 ${IPO} ${TARGET} ${FPFLAGS} -assume byterecl/" \
  -e "s/LDFLAGS        =/LDFLAGS        = -static-intel -static-libgcc -static-libstdc++/" \
  -e "s/-openmp/${OMPFLAG}/" \
  ${INCFILE}
# The __USE_3D_FFT definition may cause to block QE during startup
#sed -i -e "s/-D__DFTI/-D__DFTI -D__USE_3D_FFT/" ${INCFILE}
sed -i -e "s/-D__DFTI/-D__DFTI -D__NON_BLOCKING_SCATTER/" ${INCFILE}

# create some dummy sources needed for attached Makefile rule
mkdir -p ${HERE}/NEB/src
cp ${HERE}/PW/src/init_us_1.f90 ${HERE}/NEB/src 2> /dev/null
cp ${HERE}/PW/src/init_us_1.f90 ${HERE}/PP/src 2> /dev/null

# Uncomment below block in case of compiler issue (ICE)
echo >> ${INCFILE}
cat configure-qe-tbbmalloc.mak >> ${INCFILE}
echo -e "default: all\n" >> ${INCFILE}
echo -e "init_us_1.o: init_us_1.f90\n\t\$(MPIF90) \$(F90FLAGS) -O1 -c \$<\n" >> ${INCFILE}
echo -e "new_ns.o: new_ns.f90\n\t\$(MPIF90) \$(F90FLAGS) -O1 -c \$<\n" >> ${INCFILE}
echo -e "us_exx.o: us_exx.f90\n\t\$(MPIF90) \$(F90FLAGS) ${OMPFLAG} -c \$<\n" >> ${INCFILE}
echo -e "wypos.o: wypos.f90\n\t\$(MPIF90) \$(F90FLAGS) ${OMPFLAG} -O0 -c \$<\n" >> ${INCFILE}
echo -e "lr_apply_liouvillian.o: lr_apply_liouvillian.f90\n\t\$(MPIF90) \$(F90FLAGS) ${OMPFLAG} -O1 -c \$<\n" >> ${INCFILE}
echo -e "realus.o: realus.f90\n\t\$(MPIF90) \$(F90FLAGS) ${OMPFLAG} -O1 -c \$<\n" >> ${INCFILE}

#sed -i -e "s/\$(MOD_FLAG)\.\.\/ELPA\/src/\$(MOD_FLAG)${ELPAROOT}\/src/" ${HERE}/Modules/Makefile
sed -i -e "s/\$(MOD_FLAG)\.\.\/ELPA\/src//" ${HERE}/Modules/Makefile

# patch source code files for modern ELPA
if [ -e ${HERE}/install/config.log ] && [ "" = "$(grep 'unrecognized options: --with-elpa$' ${HERE}/install/config.log)" ]; then
  if [ -e ${HERE}/LAXlib/dspev_drv.f90 ]; then
    patch -N ${HERE}/LAXlib/dspev_drv.f90 ${HERE}/configure-qe-dspev_drv.patch
  else
    patch -N ${HERE}/Modules/dspev_drv.f90 ${HERE}/configure-qe-dspev_drv.patch
  fi
  if [ -e ${HERE}/LAXlib/zhpev_drv.f90 ]; then
    patch -N ${HERE}/LAXlib/zhpev_drv.f90 ${HERE}/configure-qe-zhpev_drv.patch
  else
    patch -N ${HERE}/Modules/zhpev_drv.f90 ${HERE}/configure-qe-zhpev_drv.patch
  fi
  patch -N ${HERE}/PW/src/setup.f90 ${HERE}/configure-qe-setup_pw.patch
fi
if [ -e ${HERE}/LAXlib/dspev_drv.f90 ]; then
  patch -N ${HERE}/LAXlib/dspev_drv.f90 ${HERE}/configure-qe-dspev_drv-2017.patch
else
  patch -N ${HERE}/Modules/dspev_drv.f90 ${HERE}/configure-qe-dspev_drv-2017.patch
fi
if [ -e ${HERE}/LAXlib/zhpev_drv.f90 ]; then
  patch -N ${HERE}/LAXlib/zhpev_drv.f90 ${HERE}/configure-qe-zhpev_drv-2017.patch
else
  patch -N ${HERE}/Modules/zhpev_drv.f90 ${HERE}/configure-qe-zhpev_drv-2017.patch
fi
patch -N ${HERE}/PW/src/setup.f90 ${HERE}/configure-qe-setup_pw-2017.patch

# patch other source code files
#patch -N ${HERE}/Modules/wavefunctions.f90 ${HERE}/configure-qe-wavefunctions.patch
#patch -N ${HERE}/FFTXlib/fft_parallel.f90 ${HERE}/configure-qe-fft_parallel.patch
patch -N ${HERE}/FFTXlib/fftw.c ${HERE}/configure-qe-fftw.patch

# reminder
echo "Ready to \"make all\"!"

