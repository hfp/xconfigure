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

BASENAME=$(command -v basename)
TIMEOUT=$(command -v timeout)
CHMOD=$(command -v chmod)
WGET=$(command -v wget)
GREP=$(command -v grep)
CAT=$(command -v cat)
CUT=$(command -v cut)
TR=$(command -v tr)
LS=$(command -v ls)
RM=$(command -v rm)
MV=$(command -v mv)

TIMEOUT_ARGS="10s"
BASEURL=https://github.com/hfp/xconfigure/raw/master/config
ERROR_NOTFOUND=8
APPLICATION=$1
ARCHS=$2
KINDS=$3

if [ ! "${BASENAME}" ] || [ ! "${CHMOD}" ] || \
   [ ! "${WGET}" ] || [ ! "${GREP}" ] || \
   [ ! "${CAT}" ] || [ ! "${CUT}" ] || \
   [ ! "${TR}" ] || [ ! "${LS}" ] || \
   [ ! "${RM}" ] || [ ! "${MV}" ];
then
  echo "Error: prerequisites not found!"
  exit 1
fi
WGET="${WGET} --no-check-certificate --no-cache"

if [ "${TIMEOUT}" ] && [ "${TIMEOUT_ARGS}" ]; then
  WGET="${TIMEOUT} ${TIMEOUT_ARGS} ${WGET} --no-check-certificate --no-cache"
fi

if [ ! "${APPLICATION}" ]; then
  echo "Please use: $0 <application-name>"
  exit 1
fi

echo "Be patient, it can take up to 30 seconds before progress is shown..."
echo
if [ "$(${WGET} -q -S --spider ${BASEURL}/${APPLICATION}/README.md 2>/dev/null | ${GREP} '200 OK')" ]; then
  echo "Error: cannot find a recipe for application \"${APPLICATION}\"!"
  exit 1
fi

MSGBUFFER=$(mktemp .configure-XXXXXX.buf)
if [ ! "${ARCHS}" ]; then
  ARCHS="gnu snb hsw knl skx"
fi
if [ ! "${KINDS}" ]; then
  KINDS="omp gnu gnu-omp"
  for KIND in ${KINDS} ; do
    if [ "${ERROR_NOTFOUND}" != "$(${WGET} -N ${BASEURL}/${APPLICATION}/configure-${APPLICATION}-${KIND}.sh 2>${MSGBUFFER}; echo $?)" ]; then
      ${CAT} ${MSGBUFFER}
    fi
  done
  for ARCH in ${ARCHS} ; do
    if [ "${ERROR_NOTFOUND}" != "$(${WGET} -N ${BASEURL}/${APPLICATION}/configure-${APPLICATION}-${ARCH}.sh 2>${MSGBUFFER}; echo $?)" ]; then
      ${CAT} ${MSGBUFFER}
    fi
    for KIND in ${KINDS} ; do
      if [ "${ERROR_NOTFOUND}" != "$(${WGET} -N ${BASEURL}/${APPLICATION}/configure-${APPLICATION}-${ARCH}-${KIND}.sh 2>${MSGBUFFER}; echo $?)" ]; then
        ${CAT} ${MSGBUFFER}
      fi
    done
  done
  if [ "${ERROR_NOTFOUND}" != "$(${WGET} -N ${BASEURL}/${APPLICATION}/configure-${APPLICATION}.sh 2>${MSGBUFFER}; echo $?)" ]; then
    ${CAT} ${MSGBUFFER}
  fi
else
  for ARCH in ${ARCHS} ; do
    for KIND in ${KINDS} ; do
      if [ "${ERROR_NOTFOUND}" != "$(${WGET} -N ${BASEURL}/${APPLICATION}/configure-${APPLICATION}-${ARCH}-${KIND}.sh 2>${MSGBUFFER}; echo $?)" ]; then
        ${CAT} ${MSGBUFFER}
      fi
    done
  done
  if [ "${ERROR_NOTFOUND}" != "$(${WGET} -N ${BASEURL}/${APPLICATION}/configure-${APPLICATION}.sh 2>${MSGBUFFER}; echo $?)" ]; then
    ${CAT} ${MSGBUFFER}
  fi
fi

# attempt to get a list of non-default file names, and then download each file
if [ "${ERROR_NOTFOUND}" != "$(${WGET} -N ${BASEURL}/${APPLICATION}/.filelist 2>${MSGBUFFER}; echo $?)" ]; then
  ${CAT} ${MSGBUFFER}
fi
if [ -e .filelist ]; then
  ${CAT} .filelist | ${TR} -s " " | \
  while read LINE; do
    FILE=$(echo "${LINE}" | ${CUT} -d" " -f1)
    DIR=$(echo "${LINE}" | ${CUT} -d" " -f2)
    if [ "" != "${LINE}" ]; then # skip empty lines
      if [[ "${FILE}" =~ "://" ]]; then
        ${WGET} -N ${FILE}
      else
        ${WGET} -N ${BASEURL}/${APPLICATION}/${FILE}
      fi
      if [ "${FILE}" != "${DIR}" ] && [ -d ${DIR} ]; then
        ${MV} $(${BASENAME} ${FILE}) ${DIR}
      fi
    fi
  done
  # cleanup list of file names
  ${RM} .filelist
fi

# make all scripts executable (beyond application)
${CHMOD} +x *.sh 2>/dev/null
# cleanup message buffer
${RM} ${MSGBUFFER}

if [ ! "$(${LS} -1 configure-${APPLICATION}*.sh 2>/dev/null)" ]; then
  # display reminder about build recipe
  echo
  echo "There is no configuration needed! Please read:"
  echo "https://xconfigure.readthedocs.io/${APPLICATION}/"
fi
