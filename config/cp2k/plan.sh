#!/bin/bash
#############################################################################
# Copyright (c) 2019, Intel Corporation                                     #
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

# number of systems (clusters nodes)
TOTALNUMNODES=1
# number of physical cores per node
NCORESPERNODE=16
# number of sockets per system
NPROCSPERNODE=2
# number of threads per core
NTHREADSPERCORE=2
# min. number of ranks per node
MIN_NRANKS=$((2*NPROCSPERNODE))
# percentage in 100/MIN_USE
MIN_USE=$((4*NPROCSPERNODE))
# unbalanced rank-count
ODD_PENALTY=3

SORT=$(command -v sort)
HEAD=$(command -v head)
SEQ=$(command -v seq)
CUT=$(command -v cut)

if [ "" != "${HOME}" ]; then
  CONFIGFILE=${HOME}/.xconfigure-cp2k-plan
else
  HERE=$(cd $(dirname $0); pwd -P)
  CONFIGFILE=${HERE}/.xconfigure-cp2k-plan
fi

function isqrt {
  s=1073741824; x=$1; y=0
  while [ "0" != "$((0 < s))" ]; do
    b=$((y | s)); y=$((y >> 1))
    if [ "0" != "$((b <= x))" ]; then
      x=$((x - b)); y=$((y | s))
    fi
    s=$((s >> 2))
  done
  echo "${y}"
}

if [ "" != "${SORT}" ] && [ "" != "${HEAD}" ] && [ "" != "${SEQ}" ] && [ "" != "${CUT}" ];
then
  if [ "" != "$1" ]; then
    TOTALNUMNODES=$1
    shift
  fi
  OUTPUT=0
  if [ "" = "$1" ]; then
    if [ -e ${HOME}/.xconfigure-cp2k-plan ]; then  # remind configuration
      NCORESPERNODE=$(${CUT} -d" " -f1 ${HOME}/.xconfigure-cp2k-plan)
    fi
  else
    NCORESPERNODE=$1
    OUTPUT=1
    shift
  fi
  if [ "" = "$1" ]; then
    if [ -e ${HOME}/.xconfigure-cp2k-plan ]; then  # remind configuration
      NTHREADSPERCORE=$(${CUT} -d" " -f2 ${HOME}/.xconfigure-cp2k-plan)
    fi
  else
    NTHREADSPERCORE=$1
    OUTPUT=1
    shift
  fi
  if [ "" = "$1" ]; then
    if [ -e ${HOME}/.xconfigure-cp2k-plan ]; then  # remind configuration
      NPROCSPERNODE=$(${CUT} -d" " -f3 ${HOME}/.xconfigure-cp2k-plan)
    fi
  else
    NPROCSPERNODE=$1
    OUTPUT=1
    shift
  fi
  # remember system configuration
  if [ "0" != "${OUTPUT}" ]; then
    echo "${NCORESPERNODE} ${NTHREADSPERCORE} ${NPROCSPERNODE}" > ${HOME}/.xconfigure-cp2k-plan 2> /dev/null
  fi
  echo "================================================================================"
  echo "Planning for ${TOTALNUMNODES} node(s) with ${NPROCSPERNODE}x$((NCORESPERNODE/NPROCSPERNODE)) core(s) per node and ${NTHREADSPERCORE} threads per core."
  echo "================================================================================"
  NCORESTOTAL=$((TOTALNUMNODES*NCORESPERNODE))
  NRANKSMIN=$((TOTALNUMNODES*NPROCSPERNODE))
  NSQRT_MIN=$(isqrt $((NRANKSMIN)))
  NSQRT_MAX=$(isqrt $((NCORESTOTAL)))
  for NSQRT in $(${SEQ} ${NSQRT_MIN} ${NSQRT_MAX}); do
    NRANKSPERNODE=$((NSQRT*NSQRT/TOTALNUMNODES))
    PENALTY=$((NCORESPERNODE%NRANKSPERNODE))
    # criterion to add penalty in case of unbalanced load
    if [ "0" != "$((ODD_PENALTY*MIN_USE*PENALTY <= NCORESPERNODE))" ] || \
       [ "0" = "$((NRANKSPERNODE%NPROCSPERNODE))" ];
    then
      if [ "0" != "$((MIN_USE*PENALTY <= NCORESPERNODE))" ] && \
         [ "0" != "$((MIN_NRANKS <= NRANKSPERNODE))" ];
      then
        PENALTY=$(((100*PENALTY+NCORESPERNODE-1)/NCORESPERNODE))
        RESULTS+="${NRANKSPERNODE};${PENALTY}\n"
      fi
    fi
  done
  RESULTS=$(echo -e ${RESULTS} | ${SORT} -t";" -u -k2n -k1nr)
  NRANKSPERNODE_TOP=$(echo "${RESULTS}" | ${CUT} -d";" -f1 | ${HEAD} -n1)
  NTHREADSPERNODE=$((NCORESPERNODE*NTHREADSPERCORE))
  PENALTY_NCORES=$((NCORESTOTAL-NSQRT_MAX*NSQRT_MAX))
  PENALTY_TOP=$(((100*PENALTY_NCORES+NCORESTOTAL-1)/NCORESTOTAL))
  NRANKSPERNODE=${NCORESPERNODE}
  while [ "0" != "$((NRANKSPERNODE_TOP < NRANKSPERNODE))" ]; do
    # criterion to add penalty in case of unbalanced load
    if [ "0" != "$((ODD_PENALTY*MIN_USE*PENALTY_NCORES <= NCORESTOTAL))" ] || \
       [ "0" = "$((NRANKSPERNODE%NPROCSPERNODE))" ];
    then
      NTHREADSPERRANK=$((NTHREADSPERNODE/NRANKSPERNODE))
      if [ "0" != "$((MIN_USE*PENALTY_NCORES <= NCORESTOTAL))" ]; then
        echo "${NRANKSPERNODE}x${NTHREADSPERCORE}: ${NRANKSPERNODE} ranks per node with ${NTHREADSPERRANK} thread(s) per rank (${PENALTY_TOP}% penalty)"
      fi
    fi
    NRANKSPERNODE=$((NRANKSPERNODE >> 1))
  done
  if [ "0" != "$((NRANKSPERNODE_TOP < NCORESPERNODE))" ]; then
    echo "--------------------------------------------------------------------------------"
  fi
  OUTPUT=0
  for RESULT in ${RESULTS}; do
    NRANKSPERNODE=$(echo "${RESULT}" | ${CUT} -d";" -f1)
    NTHREADSPERRANK=$((NTHREADSPERNODE/NRANKSPERNODE))
    PENALTY=$(echo "${RESULT}" | ${CUT} -d";" -f2)
    if [ "0" != "$((PENALTY <= PENALTY_TOP))" ]; then
      echo "${NRANKSPERNODE}x${NTHREADSPERRANK}: ${NRANKSPERNODE} ranks per node with ${NTHREADSPERRANK} thread(s) per rank (${PENALTY}% penalty)"
      OUTPUT=1
    fi
  done
  if [ "0" != "${OUTPUT}" ]; then
    echo "--------------------------------------------------------------------------------"
  fi
else
  echo "Error: missing prerequisites!"
  exit 1
fi

