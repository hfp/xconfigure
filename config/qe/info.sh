#!/bin/bash
#############################################################################
# Copyright (c) 2015-2018, Intel Corporation                                #
# All rights reserved.                                                      #
#                                                                           #
# Redistribution and use in source and binary forms, with or without        #
# modification, are permitted provided that the following conditions        #
# are met:                                                                  #
# 1. Redistributions of source code must retain the above copyright         #
#    notice, this list of conditions and the following disclaimer.          #
# 2. Redistributions in binary form must reproduce the above copyright      #
#    notice, this list of conditions and the following disclaimer in the    #
#    documentation and/or other materials provided with the distribution.   #
# 3. Neither the name of the copyright holder nor the names of its          #
#    contributors may be used to endorse or promote products derived        #
#    from this software without specific prior written permission.          #
#                                                                           #
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS       #
# "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT         #
# LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR     #
# A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT      #
# HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,    #
# SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED  #
# TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR    #
# PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF    #
# LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING      #
# NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS        #
# SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.              #
#############################################################################
# Hans Pabst (Intel Corp.)
#############################################################################

PATTERN="*.txt"

GUESS=0
BEST=0
if [ "-best" = "$1" ]; then
  SORT="sort -k2,2n -k6,6n | sort -u -k2,2n"
  BEST=1
  shift
else
  SORT="sort -k2,2n -k6,6n"
fi

if [ "" != "$1" ] && [ -e $1 ]; then
  FILEPATH="$1"
  shift
else
  FILEPATH="."
fi

NUMFILES=$(find ${FILEPATH} -maxdepth 1 -type f -name "${PATTERN}" | wc -l)
if [ "0" = "${NUMFILES}" ]; then
  PATTERN="*"
fi

PROJECT=$(basename $(find ${FILEPATH} -maxdepth 1 -type f -name "${PATTERN}" -exec grep "Reading input from" {} \; \
                   | sed -n "s/..*\/\([^\s][^\s]*\)/\1/p" | head -n1) .in 2> /dev/null | tr [:lower:] [:upper:])
if [ ".IN" = "${PROJECT}" ]; then
  PROJECT=$(basename $(cd ${FILEPATH}; pwd -P) | tr [:lower:] [:upper:])
fi

NUMFILES=$(find ${FILEPATH} -maxdepth 1 -type f -name "${PATTERN}" | wc -l)
if [ "0" != "${NUMFILES}" ]; then
  echo -e "$(printf %-23.23s ${PROJECT})\tNodes\tR/N\tT/R\tCases/d\tSeconds\tNPOOL\tNDIAG\tNTG"
fi

for FILE in $(find ${FILEPATH} -maxdepth 1 -type f -name "${PATTERN}"); do
  BASENAME=$(basename ${FILE} | rev | cut -d. -f2- | rev)
  NODERANKS=$(grep "^mpirun" ${FILE} | grep "\-np" | sed -n "s/..*-np\s\s*\([^\s][^\s]*\).*/\1/p" | tail -n1 | cut -d" " -f1)
  TPERR=$(grep OMP_NUM_THREADS ${FILE} | tail -n1 | sed -n "s/.*\sOMP_NUM_THREADS=\([0-9][0-9]*\)\s.*/\1/p")
  if [ "" = "${TPERR}" ]; then
    TPERR=$(grep "Threads/MPI process:" ${FILE} | grep -m1 -o "[0-9][0-9]*")
    if [ "" = "${TPERR}" ] || [ "0" = "${TPERR}" ]; then TPERR=1; GUESS=1; fi
  fi
  RANKS=$(grep "^mpirun" ${FILE} | grep "\-perhost" | sed -n "s/..*-perhost\s\s*\([^\s][^\s]*\).*/\1/p" | cut -d" " -f1 | tail -n1 | tr -dc [:digit:])
  if [ "" = "${RANKS}" ]; then
    RANKS=$(sed -n "s/ *Number of MPI processes:  *\([0-9][0-9]*\)\s*$/\1/p" ${FILE})
    if [ "" = "${RANKS}" ]; then
      RANKS=$(sed -n "s/ *Parallel version (..*), running on  *\([0-9][0-9]*\) ..*$/\1/p" ${FILE})
      if [ "" != "${RANKS}" ]; then
        RANKS=$((RANKS/TPERR))
      else
        RANKS=1; GUESS=1;
      fi
    fi
    if [ "" = "${RANKS}" ]; then RANKS=1; GUESS=1; fi
  fi
  if [ "" = "${NODERANKS}" ]; then
    for TOKEN in $(echo "${BASENAME}" | tr -s [=_=][=-=] " "); do
      NODES=$(echo "${TOKEN}" | sed -n "s/^\([0-9][0-9]*\)\(x[0-9][0-9]*\)*$/\1/p;s/^\([0-9][0-9]*\)n$/\1/p;s/^n\([0-9][0-9]*\)$/\1/p")
      if [ "" != "${NODES}" ]; then
        break
      fi
    done
    NODERANKS=${RANKS}
    if [ "" != "${NODES}" ] && [ "0" != "$((NODES<=NODERANKS))" ]; then
      RANKS=$((NODERANKS/NODES))
    else
      GUESS=1
    fi
  fi
  if [ "" != "${NODERANKS}" ] && [ "" != "${RANKS}" ] && [ "0" != "${RANKS}" ]; then
    NODES=$((NODERANKS/RANKS))
    XTOTAL=$(grep "PWSCF        :" ${FILE})
    if [ "" = "${XTOTAL}" ]; then
      XTOTAL=$(grep "CP           :" ${FILE})
    fi
    TOTAL=$(echo "${XTOTAL}" | sed -n "s/.\+ CPU \+\(.\+\) WALL/\1/p" | tr -dc [:graph:] \
      | sed -n "s/^\([0-9]\+d\)*\([0-9]\+h\)*\([0-9]\+m\)*\([0-9]*\.[0-9]*s\)*$/\1  \2  \3  \4/p" \
      | tr " " "\n" | tac | tr -s "\n" " ")
    FSCDS=$(echo "${TOTAL}" | cut -d" " -f1 | sed -n "s/.*\(\.[0-9]\+\)s/\1/p")
    SECDS=$(echo "${TOTAL}" | cut -d" " -f1 | sed -n "s/\([0-9]\+\)\..*/\1/p")
    MINTS=$(echo "${TOTAL}" | cut -d" " -f2 | sed -n "s/[^0-9]//p")
    HOURS=$(echo "${TOTAL}" | cut -d" " -f3 | sed -n "s/[^0-9]//p")
    NDAYS=$(echo "${TOTAL}" | cut -d" " -f4 | sed -n "s/[^0-9]//p")
    if [ "" = "${SECDS}" ]; then SECDS=0; fi
    if [ "" = "${MINTS}" ]; then MINTS=0; fi
    if [ "" = "${HOURS}" ]; then HOURS=0; fi
    if [ "" = "${NDAYS}" ]; then NDAYS=0; fi
    TWALL=$((SECDS + 60 * MINTS + 3600 * HOURS + 86400 * NDAYS))
    RANPP=$(grep "proc/nbgrp/npool/nimage =" ${FILE} | cut -d= -f2 | tr -s " " | cut -d" " -f2 | tr -dc [:digit:])
    if [ "" = "${RANPP}" ] || [ "0" = "${RANPP}" ]; then RANPP=${RANKS}; fi
    NPOOL=$((NODERANKS/RANPP))
    NDIAG=$(($(grep "size of sub-group:" ${FILE} | cut -d: -f2 | cut -dp -f1)))
    if [ "0" = "${NDIAG}" ]; then NDIAG=$((RANPP/2)); fi
    if [ "0" = "${NDIAG}" ]; then NDIAG=1; fi
    NTG=$(grep "fft and procs/group =" ${FILE} | cut -d= -f2 | tr -s " " | cut -d" " -f2 | tr -dc [:digit:])
    if [ "0" != "${TWALL}" ]; then
      echo -e -n "$(printf %-23.23s ${BASENAME})\t${NODES}\t${RANKS}\t${TPERR}"
      echo -e -n "\t$((86400/TWALL))\t$(printf %-7.7s ${TWALL}${FSCDS})"
      echo -e -n "\t${NPOOL}"
      echo -e -n "\t${NDIAG}"
      echo -e -n "\t${NTG}"
      echo
    elif [ "0" != "${NUMFILES}" ] && [ "0" = "${BEST}" ] && [ "0" = "${GUESS=1}" ]; then
      echo -e -n "$(printf %-23.23s ${BASENAME})\t${NODES}\t${RANKS}\t${TPERR}"
      echo -e -n "\t0\t-"
      echo -e -n "\t${NPOOL}"
      echo -e -n "\t${NDIAG}"
      echo -e -n "\t${NTG}"
      echo
    fi
  fi
done | eval ${SORT}

