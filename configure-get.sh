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
# shellcheck disable=SC2012

BASENAME=$(command -v basename)
TIMEOUT=$(command -v timeout)
CHMOD=$(command -v chmod)
WGET=$(command -v wget)
TAIL=$(command -v tail)
SED=$(command -v gsed)
CUT=$(command -v cut)
TR=$(command -v tr)
LS=$(command -v ls)
RM=$(command -v rm)
MV=$(command -v mv)

# GNU sed is desired (macOS)
if [ ! "${SED}" ]; then
  SED=$(command -v sed)
fi

TIMEOUT_ARGS="--foreground 10s"
BASEURL=https://github.com/hfp/xconfigure/raw/master/config
ERROR_NOTFOUND=8
APPLICATION=$1
#NBACKUPS=3
ARCHS=$2
KINDS=$3

if [ ! "${BASENAME}" ] || [ ! "${CHMOD}" ] || [ ! "${WGET}" ] || [ ! "${TAIL}" ] || \
   [ ! "${CUT}" ] || [ ! "${TR}" ] || [ ! "${LS}" ] || [ ! "${RM}" ] || [ ! "${MV}" ];
then
  >&2 echo "ERROR: prerequisites not found!"
  exit 1
fi
WGET="${WGET} --no-check-certificate --no-cache"

if [ "${TIMEOUT}" ] && [ "${TIMEOUT_ARGS}" ]; then
  WGET="${TIMEOUT} ${TIMEOUT_ARGS} ${WGET}"
fi

if [ ! "${APPLICATION}" ]; then
  >&2 echo "Please use: $0 <application-name>"
  exit 1
fi

# check if configure-get.sh was duplicated by wget
SELF=$(${LS} -1t "$0".* 2>/dev/null | tail -n1)
if [ "${SELF}" ]; then
  >&2 echo "WARNING: $0 was duplicated by wget!"
  ${MV} "${SELF}" "$0"
  chmod +x "$0"
  exec "$0" "$*"
  exit $?
fi

echo "Be patient, it can take up to 30 seconds before progress is shown..."
echo
if [ "$(${WGET} -q -S --spider "${BASEURL}/${APPLICATION}/README.md" 2>/dev/null | ${SED} -n '/200 OK/p')" ]; then
  >&2 echo "ERROR: cannot find a recipe for application \"${APPLICATION}\"!"
  exit 1
fi

MSGBUFFER=$(mktemp .configure-XXXXXX.buf)
if [ ! "${ARCHS}" ]; then
  ARCHS="gnu snb hsw knl skx"
fi
if [ ! "${KINDS}" ]; then
  KINDS="omp gnu gnu-omp"
  for KIND in ${KINDS}; do
    if [ "${ERROR_NOTFOUND}" != "$(${WGET} -N "${BASEURL}/${APPLICATION}/configure-${APPLICATION}-${KIND}.sh" 2>"${MSGBUFFER}"; echo "$?")" ]; then
      ${SED} "" "${MSGBUFFER}"
    fi
  done
  for ARCH in ${ARCHS}; do
    if [ "${ERROR_NOTFOUND}" != "$(${WGET} -N "${BASEURL}/${APPLICATION}/configure-${APPLICATION}-${ARCH}.sh" 2>"${MSGBUFFER}"; echo "$?")" ]; then
      ${SED} "" "${MSGBUFFER}"
    fi
    for KIND in ${KINDS}; do
      if [ "${ERROR_NOTFOUND}" != "$(${WGET} -N "${BASEURL}/${APPLICATION}/configure-${APPLICATION}-${ARCH}-${KIND}.sh" 2>"${MSGBUFFER}"; echo "$?")" ]; then
        ${SED} "" "${MSGBUFFER}"
      fi
    done
  done
  if [ "${ERROR_NOTFOUND}" != "$(${WGET} -N "${BASEURL}/${APPLICATION}/configure-${APPLICATION}.sh" 2>"${MSGBUFFER}"; echo "$?")" ]; then
    ${SED} "" "${MSGBUFFER}"
  fi
else
  for ARCH in ${ARCHS}; do
    for KIND in ${KINDS}; do
      if [ "${ERROR_NOTFOUND}" != "$(${WGET} -N "${BASEURL}/${APPLICATION}/configure-${APPLICATION}-${ARCH}-${KIND}.sh" 2>"${MSGBUFFER}"; echo "$?")" ]; then
        ${SED} "" "${MSGBUFFER}"
      fi
    done
  done
  if [ "${ERROR_NOTFOUND}" != "$(${WGET} -N "${BASEURL}/${APPLICATION}/configure-${APPLICATION}.sh" 2>"${MSGBUFFER}"; echo "$?")" ]; then
    ${SED} "" "${MSGBUFFER}"
  fi
fi

# attempt to get a list of non-default file names, and then download each file
if [ "${ERROR_NOTFOUND}" != "$(${WGET} -N "${BASEURL}/${APPLICATION}/.filelist" 2>"${MSGBUFFER}"; echo "$?")" ]; then
  ${SED} "" "${MSGBUFFER}"
fi
if [ -e .filelist ]; then
  if [ "${NBACKUPS}" ] && [ "0" != "${NBACKUPS}" ]; then
    BACKUP="--backups=${NBACKUPS}"
  fi
  ROOTDIR=${PWD}
  ${TR} -s " " <.filelist | \
  while read -r LINE; do
    FILE=$(${CUT} -d" " -f1 <<<"${LINE}")
    DIR=$(${CUT} -d" " -f2 <<<"${LINE}")
    if [ "${LINE}" ]; then # skip empty lines
      if [ "${FILE}" != "${DIR}" ] && [ -d "${DIR}" ]; then
        cd "${DIR}" || exit 1
      elif [[ "${FILE}" = *".sh" ]] && [ ! "${NBACKUPS}" ]; then
        FILENAME=$(${BASENAME} "${FILE}")
        if [ -e "${FILENAME}" ]; then
          >&2 echo "WARNING: ${FILENAME} exists hence not updated!"
          continue
        fi
      fi
      if [[ "${FILE}" =~ "://" ]]; then
        eval "${WGET} -N ${BACKUP} ${FILE} 2>/dev/null"
      else
        eval "${WGET} -N ${BACKUP} ${BASEURL}/${APPLICATION}/${FILE} 2>/dev/null"
      fi
      if [ "${FILE}" != "${DIR}" ]; then
        cd "${ROOTDIR}" || exit 1
      else
        if [[ "${FILE}" = *".git.diff" ]] && [ "$(command -v git)" ]; then
          git apply "${FILE}" 2>/dev/null
        fi
      fi
    fi
  done
  # cleanup list of file names
  ${RM} .filelist
fi

# make all scripts executable (beyond application)
${CHMOD} +x ./*.sh 2>/dev/null
# cleanup message buffer
${RM} "${MSGBUFFER}"

# cleanup old core dump files
HERE=$(cd "$(dirname "$0")" && pwd -P)
${RM} -f "${HERE}/core.*"

if [ ! "$(${LS} -1 "configure-${APPLICATION}"*.sh 2>/dev/null)" ]; then
  # display reminder about build recipe
  echo
  echo "There is no configuration needed! Please read:"
  echo "https://xconfigure.readthedocs.io/${APPLICATION}/"
fi
