#!/usr/bin/env sh
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
EXE=$(command -v $1)
SED=$(command -v sed)
PS=$(command -v ps)

if [ ! -e "${EXE}" ]; then
  NDEVICES=$1
  shift
fi

if [ "" != "$1" ] && [ "" != "${SED}" ] && [ "" != "${PS}" ]; then
  CPU=$(${PS} --pid $$ -ho pid,psr | ${SED} -n "s/..*[[:space:]][[:space:]]*\(..*\)$/\1/p")
  PAT=$(${SED} -n "/^processor[[:space:]]*: ${CPU}/,/^physical id[[:space:]]*:/p" /proc/cpuinfo)
  SKT=$(echo "${PAT}" | ${SED} -n "s/^physical id[[:space:]]*: \(..*\)/\1/p")
  if [ "" != "${NDEVICES}" ]; then
    CUDA_VISIBLE_DEVICES=$((SKT%NDEVICES)) "$@"
  else
    CUDA_VISIBLE_DEVICES=${SKT} "$@"
  fi
else
  echo "Error: missing prerequisites!"
  exit 1
fi
