#!/bin/bash
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

TARGET="-xCORE-AVX512 -qopt-zmm-usage=high"
OMPFLAG="-qopenmp -qoverride_limits"
#IPO="-ipo-separate"
OPTC=-O3
OPTF=-O2
if [ "" = "$1" ]; then PRFX=default-; else PRFX=$1-; shift; fi

HERE=$(cd $(dirname $0); pwd -P)
if [ ! -e ${HERE}/configure ] || [ "${HERE}" != "$(pwd -P)" ]; then
  echo "Error: XCONFIGURE scripts must be located and executed in the application folder!"
  exit 1
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

# consider more accurate -fp-model (C/C++: precise, Fortran: source)
FPFLAGS="-fp-model fast=2 -complex-limited-range"
EXX_ACE="-D__EXX_ACE"

export ELPAROOT="${HERE}/../elpa/${PRFX}skx-omp"
export MKL_OMPRTL=intel_thread
#export MKL_OMPRTL=sequential
export MKL_FCRTL=intel
export OPENMP="--enable-openmp"
export LD_LIBS="-Wl,--as-needed -liomp5 -Wl,--no-as-needed"
export MPIF90=mpiifort
export F90=ifort
export FC=ifort
export CC=mpiicc
export AR=xiar
export dir=none

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
   [ "0" != "$((170006>CC_VERSION && 0!=CC_VERSION))" ]; \
then
  export CC="${CC} -D_Float128=__float128"
fi

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
  -e "s/-nomodule -openmp/-nomodule/" \
  -e "s/-par-report0 -vec-report0//" \
  -e "s/-D__ELPA_2016/-D__ELPA_2017/" \
  -e "s/-D__ELPA_2017/-D__ELPA_2018/" \
  -e "s/-D__FFTW3/-D__DFTI/" \
  -e "s/-I-I/-I/" \
  ${INCFILE}
sed -i \
  -e "s/-D__FFTW/-D__DFTI/" -e "s/-D__DFTI/-D__DFTI ${EXX_ACE}/" \
  -e "s/^IFLAGS\s\s*=\s\(..*\)/IFLAGS = -I\$(MKLROOT)\/include\/fftw -I\$(MKLROOT)\/include -I${SED_ELPAROOT}\/include\/elpa\/modules \1/" \
  -e "s/-O3/${OPTC} ${IPO} ${TARGET} ${FPFLAGS} -fno-alias -ansi-alias/" \
  -e "s/-O2 -assume byterecl -g -traceback/${OPTF} -align array64byte -threads -heap-arrays 4096 ${IPO} ${TARGET} ${FPFLAGS} -assume byterecl/" \
  -e "s/LDFLAGS\s\s*=/LDFLAGS = -static-intel -static-libgcc -static-libstdc++/" \
  -e "s/-openmp/${OMPFLAG}/" \
  ${INCFILE}
# The __USE_3D_FFT definition may cause to block QE during startup
#sed -i -e "s/-D__DFTI/-D__DFTI -D__USE_3D_FFT/" ${INCFILE}
#sed -i -e "s/-D__DFTI/-D__DFTI -D__NON_BLOCKING_SCATTER/" ${INCFILE}

# create some dummy sources needed for attached Makefile rule
mkdir -p ${HERE}/NEB/src
cp ${HERE}/PW/src/init_us_1.f90 ${HERE}/NEB/src 2> /dev/null
cp ${HERE}/PW/src/init_us_1.f90 ${HERE}/PP/src 2> /dev/null

# extended capabilities
echo >> ${INCFILE}
cat configure-qe-tbbmalloc.mak >> ${INCFILE}
echo >> ${INCFILE}
cat configure-qe-libxsmm.mak >> ${INCFILE}
echo >> ${INCFILE}

# Uncomment below line in case of compiler issue (ICE)
echo -e "default: all\n" >> ${INCFILE}
echo -e "init_us_1.o: init_us_1.f90\n\t\$(MPIF90) \$(F90FLAGS) -O1 -c \$<\n" >> ${INCFILE}
echo -e "new_ns.o: new_ns.f90\n\t\$(MPIF90) \$(F90FLAGS) -O1 -c \$<\n" >> ${INCFILE}
echo -e "us_exx.o: us_exx.f90\n\t\$(MPIF90) \$(F90FLAGS) ${OMPFLAG} -c \$<\n" >> ${INCFILE}
echo -e "wypos.o: wypos.f90\n\t\$(MPIF90) \$(F90FLAGS) ${OMPFLAG} -O0 -c \$<\n" >> ${INCFILE}
echo -e "lr_apply_liouvillian.o: lr_apply_liouvillian.f90\n\t\$(MPIF90) \$(F90FLAGS) ${OMPFLAG} -O1 -c \$<\n" >> ${INCFILE}
echo -e "realus.o: realus.f90\n\t\$(MPIF90) \$(F90FLAGS) ${OMPFLAG} -O1 -c \$<\n" >> ${INCFILE}

# patch source code files for modern ELPA
sed -i -e "s/\$(MOD_FLAG)\.\.\/ELPA\/src//" ${HERE}/Modules/Makefile
patch -N ${HERE}/LAXlib/dspev_drv.f90 ${HERE}/configure-qe-dspev_drv.patch
patch -N ${HERE}/LAXlib/zhpev_drv.f90 ${HERE}/configure-qe-zhpev_drv.patch
patch -N ${HERE}/PW/src/setup.f90 ${HERE}/configure-qe-setup_pw.patch

# reminder
echo "Ready to \"make all\"!"

