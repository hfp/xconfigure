#!/bin/sh

WGET=$(which wget)

if [ "" != "${WGET}" ]; then
  if [ "" != "$1" ]; then
    ARCHS=$2
    KINDS=$3

    if [ "" = "${ARCHS}" ]; then
      ARCHS="snb hsw knl skx"
    fi
    if [ "" = "${KINDS}" ]; then
      KINDS="omp"
      for KIND in ${KINDS} ; do
        ${WGET} -N https://github.com/hfp/xconfigure/raw/master/$1/configure-$1-${KIND}.sh
      done
      for ARCH in ${ARCHS} ; do
        ${WGET} -N https://github.com/hfp/xconfigure/raw/master/$1/configure-$1-${ARCH}.sh
        for KIND in ${KINDS} ; do
          ${WGET} -N https://github.com/hfp/xconfigure/raw/master/$1/configure-$1-${ARCH}-${KIND}.sh
        done
      done
    else
      for ARCH in ${ARCHS} ; do
        for KIND in ${KINDS} ; do
          ${WGET} -N https://github.com/hfp/xconfigure/raw/master/$1/configure-$1-${ARCH}-${KIND}.sh
        done
      done
    fi
  else
    echo "Please use: $0 <application-name>"
    exit 1
  fi
else
  echo "Error: prerequisites not found!"
  exit 1
fi

