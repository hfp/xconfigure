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
  if [ "$1" ] && [ "$(echo "$@" | ${SED} -n "/${MATCH}/p" 2>/dev/null)" ]; then
    exec ${EXE} ${FLAGS} "$@"
  elif [ "$1" ]; then
    exec ${EXE} "$@"
  else
    exec ${EXE}
  fi
else
  echo "Error: missing prerequisites!"
  exit 1
fi
