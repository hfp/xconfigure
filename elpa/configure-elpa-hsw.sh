#!/bin/sh

if [ "" = "$1" ]; then PRFX=2017-; else PRFX=$1-; shift; fi
HERE=$(cd $(dirname $0); pwd -P)
DEST=${HERE}/../elpa/${PRFX}hsw

if [ "${HERE}" = "${DEST}" ]; then
  echo "Warning: ELPA source directory equals installation folder!"
  read -p "Are you sure? Y/N" -n 1 -r
  if [ ! $REPLY =~ ^[Yy]$ ]; then
    exit 1
  fi
fi

FPFLAGS="-fp-model fast=2 -complex-limited-range"
#CONFOPTS="--enable-openmp"
MKLRTL="intel_thread"
TARGET="-xCORE-AVX2"

export FLAGS="-O2 ${TARGET} -I${MKLROOT}/include -ipo-separate"
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

./configure --host=x86_64-unknown-linux-gnu --prefix=${DEST} ${CONFOPTS} $*

sed -i \
  -e "s/-openmp/-qopenmp -qoverride_limits/" \
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
    cd ${DEST}/include ; ln -fs ${ELPA}-${VERSION} elpa
    mkdir -p ${DEST}/lib
    cd ${DEST}/lib
    ln -fs libelpa_openmp.a libelpa.a
    ln -fs libelpa.a libelpa_mt.a
  fi
fi

