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
NCORESPERNODE=1
# number of sockets per system
NPROCSPERNODE=1
# number of threads per core
NTHREADSPERCORE=1
# min. number of ranks per node
MIN_NRANKS=$((1*NPROCSPERNODE))
# percentage in 100/MIN_USE
MIN_USE=$((1*MIN_NRANKS))
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

function suggest {
  ncoretotal=$1; ncoresnode=$2
  while [ "${total}" != "${ncoretotal}" ] && [ "0" != "$((ncoresnode < ncoretotal))" ]; do
    total=${ncoretotal}
    nsqrt=$(isqrt ${ncoretotal})
    nodes=$((nsqrt*nsqrt/ncoresnode))
    ncoretotal=$((nodes*ncoresnode))
  done
  echo "$(((ncoretotal+ncoresnode-1)/ncoresnode))"
}

if [ "" != "${SORT}" ] && [ "" != "${HEAD}" ] && [ "" != "${SEQ}" ] && [ "" != "${CUT}" ];
then
  if [ "" != "$1" ]; then
    TOTALNUMNODES=$1
    shift
  fi
  if [ -e /proc/cpuinfo ] && \
     [ "" != "$(command -v grep)" ] && \
     [ "" != "$(command -v wc)" ] && \
     [ "" != "$(command -v tr)" ];
  then
    NS=$(grep "physical id" /proc/cpuinfo | ${SORT} -u | wc -l | tr -d " ")
    NC=$((NS*$(grep "core id" /proc/cpuinfo | ${SORT} -u | wc -l | tr -d " ")))
    NT=$(grep "core id" /proc/cpuinfo | wc -l | tr -d " ")
  elif [ "Darwin" = "$(uname)" ] && \
       [ "" != "$(command -v sysctl)" ] && \
       [ "" != "$(command -v tr)" ];
  then
    NS=$(sysctl hw.packages | ${CUT} -d: -f2 | tr -d " ")
    NC=$(sysctl hw.physicalcpu | ${CUT} -d: -f2 | tr -d " ")
    NT=$(sysctl hw.logicalcpu | ${CUT} -d: -f2 | tr -d " ")
  fi
  if [ "" != "${NC}" ] && [ "" != "${NT}" ]; then
    HT=$((NT/NC))
  fi
  OUTPUT=0
  if [ "" = "$1" ]; then
    if [ -e ${CONFIGFILE} ]; then  # remind configuration
      NCORESPERNODE=$(${CUT} -d" " -f1 ${CONFIGFILE})
    elif [ "" != "${NC}" ]; then
      NCORESPERNODE=${NC}
    fi
  else
    NCORESPERNODE=$1
    OUTPUT=1
    shift
  fi
  if [ "" = "$1" ]; then
    if [ -e ${CONFIGFILE} ]; then  # remind configuration
      NTHREADSPERCORE=$(${CUT} -d" " -f2 ${CONFIGFILE})
    elif [ "" != "${HT}" ]; then
      NTHREADSPERCORE=${HT}
    fi
  else
    NTHREADSPERCORE=$1
    OUTPUT=1
    shift
  fi
  if [ "" = "$1" ]; then
    if [ -e ${CONFIGFILE} ]; then  # remind configuration
      NPROCSPERNODE=$(${CUT} -d" " -f3 ${CONFIGFILE})
    elif [ "" != "${NS}" ]; then
      NPROCSPERNODE=${NS}
    fi
  else
    NPROCSPERNODE=$1
    OUTPUT=1
    shift
  fi
  # remember system configuration
  if [ "0" != "${OUTPUT}" ]; then
    echo "${NCORESPERNODE} ${NTHREADSPERCORE} ${NPROCSPERNODE}" > ${CONFIGFILE} 2> /dev/null
  fi
  NCORESTOTAL=$((TOTALNUMNODES*NCORESPERNODE))
  NCORESOCKET=$((NCORESPERNODE/NPROCSPERNODE))
  echo "================================================================================"
  echo "${NCORESTOTAL} cores: ${TOTALNUMNODES} node(s) with ${NPROCSPERNODE}x${NCORESOCKET} core(s) per node and ${NTHREADSPERCORE} thread(s) per core"
  echo "================================================================================"
  NRANKSMIN=$((TOTALNUMNODES*NPROCSPERNODE))
  NSQRT_MIN=$(isqrt ${NRANKSMIN})
  NSQRT_MAX=$(isqrt ${NCORESTOTAL})
  for NSQRT in $(${SEQ} ${NSQRT_MIN} ${NSQRT_MAX}); do
    NSQR=$((NSQRT*NSQRT))
    NRANKSPERNODE=$((NSQR/TOTALNUMNODES))
    if [ "${NSQR}" == "$((TOTALNUMNODES*NRANKSPERNODE))" ]; then
      PENALTY=$((NCORESPERNODE%NRANKSPERNODE))
      # criterion to add penalty in case of unbalanced load
      if [ "0" != "$((ODD_PENALTY*MIN_USE*PENALTY <= NCORESPERNODE))" ] || \
         [ "0" = "$((NRANKSPERNODE%NPROCSPERNODE))" ];
      then
        if [ "0" != "$((MIN_USE*PENALTY <= NCORESPERNODE))" ] && \
           [ "0" != "$((MIN_NRANKS <= NRANKSPERNODE))" ];
        then
          PENALTY=$(((100*PENALTY+NCORESPERNODE-1)/NCORESPERNODE))
          RESULTS+="${NRANKSPERNODE};${PENALTY};${NSQRT}\n"
        fi
      fi
    fi
  done
  RESULTS=$(echo -e "${RESULTS}" | ${SORT} -t";" -u -k2n -k1nr)
  NRANKSPERNODE_TOP=$(echo "${RESULTS}" | ${CUT} -d";" -f1 | ${HEAD} -n1)
  NTHREADSPERNODE=$((NCORESPERNODE*NTHREADSPERCORE))
  NSQR_MAX=$((NSQRT_MAX*NSQRT_MAX))
  PENALTY_NCORES=$((NCORESTOTAL-NSQR_MAX))
  PENALTY_TOP=$(((100*PENALTY_NCORES+NCORESTOTAL-1)/NCORESTOTAL))
  NRANKSPERNODE=${NCORESPERNODE}
  OUTPUT_POT=0
  while [ "0" != "$((NRANKSPERNODE_TOP < NRANKSPERNODE))" ]; do
    # criterion to add penalty in case of unbalanced load
    if [ "0" != "$((ODD_PENALTY*MIN_USE*PENALTY_NCORES <= NCORESTOTAL))" ] || \
       [ "0" = "$((NRANKSPERNODE%NPROCSPERNODE))" ];
    then
      NTHREADSPERRANK=$((NTHREADSPERNODE/NRANKSPERNODE))
      if [ "0" != "$((MIN_USE*PENALTY_NCORES <= NCORESTOTAL))" ]; then
        echo "[${NRANKSPERNODE}x${NTHREADSPERCORE}]: ${NRANKSPERNODE} ranks per node with ${NTHREADSPERRANK} thread(s) per rank (${PENALTY_TOP}% penalty)"
        OUTPUT_POT=$((OUTPUT_POT+1))
      fi
    fi
    NRANKSPERNODE=$((NRANKSPERNODE >> 1))
  done
  if [ "0" != "${OUTPUT_POT}" ]; then
    echo "--------------------------------------------------------------------------------"
  fi
  OUTPUT_SQR=0
  if [ "" != "$(command -v tr)" ]; then # reorder by decreasing rank-count
    RESULTS=$(echo -e "${RESULTS}" | tr " " "\n" | ${SORT} -t";" -k1nr -k2n)
  fi
  for RESULT in ${RESULTS}; do
    NRANKSPERNODE=$(echo "${RESULT}" | ${CUT} -d";" -f1)
    NTHREADSPERRANK=$((NTHREADSPERNODE/NRANKSPERNODE))
    PENALTY=$(echo "${RESULT}" | ${CUT} -d";" -f2)
    if [ "0" != "$((PENALTY <= PENALTY_TOP))" ] || [ "0" != "$((OUTPUT_SQR<OUTPUT_POT))" ]; then
      NSQRT=$(echo "${RESULT}" | ${CUT} -d";" -f3)
      echo "[${NRANKSPERNODE}x${NTHREADSPERRANK}]: ${NRANKSPERNODE} ranks per node with ${NTHREADSPERRANK} thread(s) per rank (${PENALTY}% penalty) -> ${NSQRT}x${NSQRT}"
      OUTPUT_SQR=$((OUTPUT_SQR+1))
    fi
  done
  if [ "0" != "${OUTPUT_SQR}" ]; then
    echo "--------------------------------------------------------------------------------"
  fi
  NUMNODES_LO=$(suggest ${NSQR_MAX} ${NCORESPERNODE})
  NUMNODES_HI=$(suggest $((NSQR_MAX*TOTALNUMNODES/NUMNODES_LO)) ${NCORESPERNODE})
  if [ "${TOTALNUMNODES}" != "${NUMNODES_HI}" ] && [ "0" != "${NUMNODES_HI}" ]; then
    if [ "${TOTALNUMNODES}" != "${NUMNODES_LO}" ] && [ "${NUMNODES_LO}" != "${NUMNODES_HI}" ]; then
      echo "Try also ${NUMNODES_LO} and ${NUMNODES_HI} nodes!"
    else
      echo "Try also ${NUMNODES_HI} node(s)!"
    fi
  fi
else
  echo "Error: missing prerequisites!"
  exit 1
fi

