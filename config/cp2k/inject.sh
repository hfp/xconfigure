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
SED=$(command -v sed)

if [ "$1" ] && [ "$2" ] && [ "$3" ] && [ "${SED}" ]; then
  MATCH="$1"
  FLAGS="$2"
  EXE="$3"
  shift 3
  ARGS="$(echo "$@" | ${SED} 's/"/\\"/g')"
  if [ "${ARGS}" ] && [ "$(echo "${ARGS}" | ${SED} -n "/${MATCH}/p" 2>/dev/null)" ]; then
    CMD="${EXE} ${FLAGS} ${ARGS}"
  elif [ "${ARGS}" ]; then
    CMD="${EXE} ${ARGS}"
  else
    CMD="${EXE}"
  fi
  exec ${CMD}
else
  echo "Error: missing prerequisites!"
  exit 1
fi
