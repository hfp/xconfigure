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
set -o noglob

# Example: find . -maxdepth 1 -mindepth 1 -type d | xargs -I{} ./info.sh --best {}
PATTERNS="*.txt *.out"

BEST=0
DEPTH=1
SORT="-k2,2g -k6,6g"
SORTBEST="-u -k2,2g"

while test $# -gt 0; do
  case "$1" in
  -h|--help)
    echo "$0 [options] [dir] [symbol]"
    exit 0;;
  -a|--all)
    SORT="-k1,1"
    ALL=1
    shift;;
  -b|--best)
    SORT+=" | sort ${SORTBEST}"
    BEST=1
    shift;;
  -d|--depth)
    DEPTH=$2
    shift 2;;
  *) break;;
  esac
done

if [ "$1" ] && [ -e "$1" ]; then
  OUTBASE=$(basename "$1" | tr '[:upper:]' '[:lower:]' | tr -d '-')
  FILEPATH="$1"
  if [ "${ALL}" ] && [ "0" != "${ALL}" ]; then
    OUTALL=cp2k-${OUTBASE}.txt
    SORT+=" | tee ${OUTALL}"
  elif [ "0" = "${BEST}" ]; then
    OUTBEST=cp2k-${OUTBASE}-best.txt
    OUTALL=cp2k-${OUTBASE}-all.txt
    SORT+=" | tee ${OUTALL} | sort ${SORTBEST} | tee ${OUTBEST}"
  else # best
    OUTBEST=cp2k-${OUTBASE}.txt
    SORT+=" | sort ${SORTBEST} | tee ${OUTBEST}"
  fi
  shift
else
  FILEPATH="."
fi
EXTRA=$1

for PATTERN in ${PATTERNS}; do
  FILES+="$(find "${FILEPATH}" -maxdepth "${DEPTH}" ! -type d -name "${PATTERN}" | grep -v "..*\.sh\|CMakeLists\.txt") "
done
FILES=$(xargs -n1 <<<"${FILES}")
if [ ! "${FILES}" ]; then
  >&2 echo "WARNING: '${PATTERNS}' does not match any logfile."
fi

FILE0=$(head -n1 <<<"${FILES}")
NUMFILES=0
if [ "${FILE0}" ]; then
  NUMFILES=$(wc -l <<<"${FILES}")
  PROJECT=$(grep -m1 "GLOBAL| Project name" "${FILE0}" | sed -n "s/..*\s\s*\(\w\)/\1/p")
  if [ "PROJECT" = "${PROJECT}" ]; then
    PROJECT=$(grep -m1 "GLOBAL| Method name" "${FILE0}" | sed -n "s/..*\s\s*\(\w\)/\1/p")
  fi
  HEADER=$(echo -e "$(printf %-23.23s "${PROJECT}")\tNodes\tR/N\tT/R\tCases/d\tSeconds")
  echo "${HEADER}"
fi

for FILE in ${FILES}; do
  BASENAME=$(basename "${FILE}" | rev | cut -d. -f2- | rev)
  NODERANKS=$(grep "\(mpirun\|mpiexec\)" "${FILE}" | grep "\-np" | sed -n "s/..*-np\s\s*\([^\s][^\s]*\).*/\1/p" | tail -n1 | cut -d" " -f1)
  RANKS=$(grep "\(mpirun\|mpiexec\)" "${FILE}" | grep -o "\-\(perhost\|npernode\)..*$" | tr -s " " | cut -d" " -f2 | tail -n1 | tr -d -c "[:digit:]")
  if [ ! "${RANKS}" ]; then
    RANKS=$(grep "GLOBAL| Total number of message passing processes" "${FILE}" | grep -m1 -o "[0-9][0-9]*")
  fi
  if [ ! "${RANKS}" ]; then RANKS=1; fi
  # OpenMPI
  NODES=$(grep "cpu-bind=" "${FILE}" | cut -d- -f3 | cut -d, -f1 | sort -u | wc -l)
  if [ ! "${NODES}" ]; then # fallback
    for TOKEN in $(tr -s "[=_=][=-=]" " " <<<"${BASENAME}"); do
      NODES=$(sed -n "s/^\([0-9][0-9]*\)\(x[0-9][0-9]*\)*$/\1/p;s/^\([0-9][0-9]*\)n$/\1/p;s/^n\([0-9][0-9]*\)$/\1/p" <<<"${TOKEN}")
      if [ "${NODES}" ]; then break; fi
    done
  fi
  if [ ! "${NODERANKS}" ]; then
    NODERANKS=${RANKS}
    if [ "${NODES}" ] && [ "0" != "${NODES}" ] && [ "0" != "$((NODES<=NODERANKS))" ]; then
      RANKS=$((NODERANKS/NODES))
    fi
  fi
  if [ "${NODERANKS}" ] && [ "${RANKS}" ] && [ "0" != "${RANKS}" ]; then
    NODES=$((NODERANKS/RANKS))
    TPERR=$(grep OMP_NUM_THREADS "${FILE}" | tail -n1 | sed -n "s/.*\sOMP_NUM_THREADS=\([0-9][0-9]*\)\s.*/\1/p")
    if [ ! "${TPERR}" ]; then
      TPERR=$(grep "GLOBAL| Number of threads for this process" "${FILE}" | grep -m1 -o "[0-9][0-9]*")
      if [ ! "${TPERR}" ] || [ "0" = "${TPERR}" ]; then TPERR=1; fi
    fi
    DURATION=$(grep "CP2K                                 1" "${FILE}" | tr -s "\n" " " | tr -s " " | cut -d" " -f7)
    TWALL=$(cut -d. -f1 <<<"${DURATION}" | sed -n "s/\([0-9][0-9]*\)/\1/p")
    if [ "${TWALL}" ] && [ "0" != "${TWALL}" ]; then
      echo -e -n "$(printf %-23.23s "${BASENAME}")\t${NODES}\t${RANKS}\t${TPERR}"
      echo -e -n "\t$((86400/TWALL))\t${DURATION}"
      if [ "${EXTRA}" ]; then
        EXTRAVAL=$(grep -m1 "${EXTRA}" "${FILE}" | sed "s/\s*\w*${EXTRA}\w*\s*//" | tr -s " " | cut -d" " -f5)
        echo -e -n "\t\t${EXTRAVAL}"
      fi
      NDEVS=$(grep -m1 "\[0\] MPI startup(): \(Stacks\|Tiles\).*: " "${FILE}" | sed -n "s/..*\s\s*\(\w\)/\1/p")
      ACCON=$(grep -m1 " DBCSR| ACC: Number of devices/node" "${FILE}" | sed -n "s/..*\s\s*\(\w\)/\1/p")
      if [ ! "${NDEVS}" ]; then NDEVS=${ACCON}; fi
      if [ ! "${NDEVS}" ]; then NDEVS=0; fi
      if [ ! "${ACCON}" ]; then NDEVS=0; fi
      if [ "${NDEVS}" ] && [ "0" != "$((RANKS<NDEVS))" ]; then NDEVS=${RANKS}; fi
      if [ "${NDEVS}" ]; then
        DEVIDS=$(grep -m1 "ACC_OPENCL_DEVIDS" "${FILE}" | sed -n "s/..*=\(\w\)/\1/p" | tr -cd ,)
        if [ ! "${DEVIDS}" ]; then
          DEVIDS=$(grep -m1 "CUDA_VISIBLE_DEVICES" "${FILE}" | sed -n "s/..*=\(\w\)/\1/p" | tr -cd ,)
        fi
        if [ "${DEVIDS}" ]; then
          DEVIDS=$(wc -c <<<"${DEVIDS}")
          NDEVS=$((DEVIDS<NDEVS?(DEVIDS+1):NDEVS))
        fi
        if [ "0" != "$((0<NDEVS))" ]; then echo -e -n "\t\t${NDEVS} ACC"; fi
      fi
      echo
    elif [ "0" != "${NUMFILES}" ] && [ "0" = "${BEST}" ]; then
      echo -e -n "$(printf %-23.23s "${BASENAME}")\t${NODES}\t${RANKS}\t${TPERR}"
      echo -e -n "\t0\t-"
      echo
    fi
  fi
done | eval "sort ${SORT}"

if [ "${HEADER}" ]; then
  HEADER=$(sed 's/\//\\\//g' <<<"${HEADER}")
  if [ "${OUTBEST}" ] && [ -e "${OUTBEST}" ]; then
    sed -i "1s/^/${HEADER}\n/" "${OUTBEST}"
  fi
  if [ "${OUTALL}" ] && [ -e "${OUTALL}" ]; then
    sed -i "1s/^/${HEADER}\n/" "${OUTALL}"
  fi
fi
