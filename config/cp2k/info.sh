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

BC=$(which bc 2> /dev/null)
PATTERN="*.txt"

BEST=0
if [ "-best" = "$1" ]; then
  SORT="sort -k2,2n -k6,6n | sort -u -k2,2n"
  BEST=1
  shift
else
  SORT="sort -k2,2n -k6,6n"
fi

if [ "-depth" = "$1" ]; then
  DEPTH=$2
  shift 2
fi
if [ "" = "${DEPTH}" ]; then
  DEPTH=1
fi

if [ "" != "$1" ] && [ -e "$1" ]; then
  FILEPATH="$1"
  shift
else
  FILEPATH="."
fi

NUMFILES=$(find ${FILEPATH} -maxdepth ${DEPTH} -type f -name "${PATTERN}" | wc -l)
if [ "0" = "${NUMFILES}" ]; then
  PATTERN="*"
fi

FILES=$(find ${FILEPATH} -maxdepth ${DEPTH} -type f -name "${PATTERN}" | grep -v "..*\.sh")
FILE0=$(echo "${FILES}" | head -n1)
PRINTFLOPS=0
NUMFILES=0
if [ "" != "${FILE0}" ]; then
  NUMFILES=$(echo "${FILES}" | wc -l)
  PROJECT=$(grep "GLOBAL| Project name" "${FILE0}" | sed -n "s/..*\s\s*\(\w\)/\1/p" | head -n1)
  if [ "PROJECT" = "${PROJECT}" ]; then
    PROJECT=$(grep "GLOBAL| Method name" "${FILE0}" | sed -n "s/..*\s\s*\(\w\)/\1/p" | head -n1)
  fi
  if [ "" != "${BC}" ]; then
    if [ "LIBTEST" = "${PROJECT}" ] || [ "TEST" = "${PROJECT}" ]; then
      PRINTFLOPS=1
    fi
  fi
  echo -e -n "$(printf %-23.23s "${PROJECT}")\tNodes\tR/N\tT/R\tCases/d\tSeconds"
  if [ "0" != "${PRINTFLOPS}" ]; then
    echo -e -n "\tGFLOPS/s"
  fi
  echo
fi

for FILE in ${FILES}; do
  BASENAME=$(basename "${FILE}" | rev | cut -d. -f2- | rev)
  NODERANKS=$(grep "\(mpirun\|mpiexec\)" "${FILE}" | grep "\-np" | sed -n "s/..*-np\s\s*\([^\s][^\s]*\).*/\1/p" | tail -n1 | cut -d" " -f1)
  RANKS=$(grep "\(mpirun\|mpiexec\)" "${FILE}" | grep -o "\-\(perhost\|npernode\)..*$" | tr -s " " | cut -d" " -f2 | tail -n1 | tr -d -c "[:digit:]")
  if [ "" = "${RANKS}" ]; then
    RANKS=$(grep "GLOBAL| Total number of message passing processes" "${FILE}" | grep -m1 -o "[0-9][0-9]*")
    if [ "" = "${RANKS}" ]; then RANKS=1; fi
  fi
  if [ "" = "${NODERANKS}" ]; then
    for TOKEN in $(echo "${BASENAME}" | tr -s "[=_=][=-=]" " "); do
      NODES=$(echo "${TOKEN}" | sed -n "s/^\([0-9][0-9]*\)\(x[0-9][0-9]*\)*$/\1/p;s/^\([0-9][0-9]*\)n$/\1/p;s/^n\([0-9][0-9]*\)$/\1/p")
      if [ "" != "${NODES}" ]; then
        break
      fi
    done
    NODERANKS=${RANKS}
    if [ "" != "${NODES}" ] && [ "0" != "${NODES}" ] && [ "0" != "$((NODES<=NODERANKS))" ]; then
      RANKS=$((NODERANKS/NODES))
    fi
  fi
  if [ "" != "${NODERANKS}" ] && [ "" != "${RANKS}" ] && [ "0" != "${RANKS}" ]; then
    NODES=$((NODERANKS/RANKS))
    TPERR=$(grep OMP_NUM_THREADS "${FILE}" | tail -n1 | sed -n "s/.*\sOMP_NUM_THREADS=\([0-9][0-9]*\)\s.*/\1/p")
    if [ "" = "${TPERR}" ]; then
      TPERR=$(grep "GLOBAL| Number of threads for this process" "${FILE}" | grep -m1 -o "[0-9][0-9]*")
      if [ "" = "${TPERR}" ] || [ "0" = "${TPERR}" ]; then TPERR=1; fi
    fi
    DURATION=$(grep "CP2K                                 1" "${FILE}" | tr -s "\n" " " | tr -s " " | cut -d" " -f7)
    TWALL=$(echo "${DURATION}" | cut -d. -f1 | sed -n "s/\([0-9][0-9]*\)/\1/p")
    if [ "" != "${TWALL}" ] && [ "0" != "${TWALL}" ]; then
      echo -e -n "$(printf %-23.23s "${BASENAME}")\t${NODES}\t${RANKS}\t${TPERR}"
      echo -e -n "\t$((86400/TWALL))\t${DURATION}"
      if [ "0" != "${PRINTFLOPS}" ]; then
        FLOPS=$(sed -n "s/ marketing flops\s\s*\(..*\)$/\1/p" "${FILE}" | sed -e "s/[eE]+*/\*10\^/")
        TBCSR=$(sed -n "s/ dbcsr_multiply_generic\s\s*\(..*\)$/\1/p" "${FILE}" | tr -s " " | rev | cut -d" " -f1 | rev)
        if [ "" != "${FLOPS}" ] && [ "" != "${TBCSR}" ]; then
          GFLOPS=$(echo "scale=3;((${FLOPS})/(${TBCSR}*10^9))" | ${BC})
          echo -e -n "\t${GFLOPS}"
        fi
      fi
      echo
    elif [ "0" != "${NUMFILES}" ] && [ "0" = "${BEST}" ]; then
      echo -e -n "$(printf %-23.23s "${BASENAME}")\t${NODES}\t${RANKS}\t${TPERR}"
      echo -e -n "\t0\t-"
      echo
    fi
  fi
done | eval "${SORT}"
