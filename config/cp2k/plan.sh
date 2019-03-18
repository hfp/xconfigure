#!/bin/bash

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

if [ "" != "$1" ]; then
  TOTALNUMNODES=$1
  shift
fi
if [ "" != "$1" ]; then
  NCORESPERNODE=$1
  shift
fi
if [ "" != "$1" ]; then
  NTHREADSPERCORE=$1
  shift
fi
if [ "" != "$1" ]; then
  NPROCSPERNODE=$1
  shift
fi

SORT=$(command -v sort)
SEQ=$(command -v seq)
CUT=$(command -v cut)

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

if [ "" != "${SORT}" ] && [ "" != "${SEQ}" ] && [ "" != "${CUT}" ];
then
  echo "================================================================================"
  echo "Planning for ${TOTALNUMNODES} node(s) with ${NPROCSPERNODE}x$((NCORESPERNODE/NPROCSPERNODE)) core(s) per node and ${NTHREADSPERCORE} threads per core."
  echo "================================================================================"
  NRANKSPERNODE_MIN=$((TOTALNUMNODES*NPROCSPERNODE))
  NRANKSPERNODE_MAX=$((TOTALNUMNODES*NCORESPERNODE))
  NSQRT_MIN=$(isqrt $((NRANKSPERNODE_MIN)))
  NSQRT_MAX=$(isqrt $((NRANKSPERNODE_MAX)))
  for NSQRT in $(${SEQ} ${NSQRT_MIN} ${NSQRT_MAX}); do
    NRANKSPERNODE=$((NSQRT*NSQRT/TOTALNUMNODES))
    REST=$(((NCORESPERNODE%NRANKSPERNODE)))
    if [ "0" != "$((MIN_NRANKS   <= NRANKSPERNODE))" ] && \
       [ "0" != "$((MIN_USE*REST <= NCORESPERNODE))" ];
    then
      # criterion to add penalty in case of unbalanced load
      if [ "0" != "$((ODD_PENALTY*MIN_USE*REST <= NCORESPERNODE))" ] || \
         [ "0" = "$((NRANKSPERNODE%NPROCSPERNODE))" ];
      then
        LIST+="${NRANKSPERNODE};$((100*REST/NCORESPERNODE))\n"
      fi
    fi
  done
  NTHREADSPERNODE=$((NCORESPERNODE*NTHREADSPERCORE))
  WASTED=$((100*NRANKSPERNODE_MAX/(NSQRT_MAX*NSQRT_MAX)-100))
  echo "${NCORESPERNODE}x${NTHREADSPERCORE}: ${NCORESPERNODE} ranks per node with ${NTHREADSPERCORE} thread(s) per rank (${WASTED}% penalty)"
  for RESULT in $(echo -e ${LIST} | ${SORT} -t";" -u -k2n -k1nr); do
    NRANKSPERNODE=$(echo "${RESULT}" | ${CUT} -d";" -f1)
    NTHREADSPERRANK=$((NTHREADSPERNODE/NRANKSPERNODE))
    WASTED=$(echo "${RESULT}" | ${CUT} -d";" -f2)
    echo "${NRANKSPERNODE}x${NTHREADSPERRANK}: ${NRANKSPERNODE} ranks per node with ${NTHREADSPERRANK} thread(s) per rank (${WASTED}% penalty)"
  done
else
  echo "Error: missing prerequisites!"
  exit 1
fi

