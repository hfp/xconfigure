#!/usr/bin/env bash
# shellcheck disable=SC2001
#
ROOT=${PWD}
ROOT=$(cd "$(dirname "$0")" && pwd -P)
BUILD=Linux-x86-64-intelx
VERSION=psmp

# Threads per core
if [ ! "${MAXNT}" ]; then
  MAXNT=1
fi

# consider the following in .bashrc
# ulimit -s unlimited
# ulimit -c0

export CP2K_DATA_DIR=${CP2K_DATA_DIR:-${ROOT}/data}
export ACC_OPENCL_VERBOSE=${ACC_OPENCL_VERBOSE:-1}
#NUMACTL="numactl --preferred=1"

# adjust default memory allocator
if [ "${TBBMALLOC}" ] && [ "0" != "${TBBMALLOC}" ] && [ "${TBBROOT}" ] && \
   [ -e "${TBBROOT}/lib/libtbbmalloc_proxy.so" ];
then
  if [ "${LD_PRELOAD}" ]; then
    export LD_PRELOAD=${TBBROOT}/lib/libtbbmalloc_proxy.so:${LD_PRELOAD}
  else
    export LD_PRELOAD=${TBBROOT}/lib/libtbbmalloc_proxy.so
  fi
fi

if [ "${LSB_JOBID}" ]; then
  JOBID=${LSB_JOBID};
elif [ "${PBS_JOBID}" ]; then
  JOBID=${PBS_JOBID}
elif [ "${SLURM_JOBID}" ]; then
  JOBID=${SLURM_JOBID}
elif [ "$(command -v squeue)" ]; then
  JOBID=$(squeue -u "${USER}" -h --format="%A" 2>/dev/null | head -n1)
fi
if [ "${JOBID}" ]; then  # cleanup
  JOBID=$(cut -d. -f1 <<<"${JOBID}")
fi

if [ "$1" ]; then
  if [ -f "$1" ]; then
    WORKLOAD=$1
  else
    >&2 echo "ERROR: $1 not found!"
    exit 1
  fi
  shift
else
  >&2 echo "Please use: $0 /file/to/workload.inp [ranks-per-node [num-nodes]]"
  exit 1
fi
WORKLOAD=$(cd "$(dirname "${WORKLOAD}")" && pwd -P)/$(basename "${WORKLOAD}")

if [ "$(command -v lscpu)" ]; then
  NS=$(lscpu | grep -m1 "Socket(s)" | tr -d " " | cut -d: -f2)
  if [ ! "${NS}" ]; then NS=1; fi
  if [[ ${NS} =~ ^[1-9][0-9]*$ ]]; then
    NC=$((NS*$(lscpu | grep -m1 "Core(s) per socket" | tr -d " " | cut -d: -f2)))
    NT=$(lscpu | grep -m1 "CPU(s)" | tr -d " " | cut -d: -f2)
    if [ ! "${NT}" ]; then
      NT=$((NC*$(lscpu | grep -m1 "Thread(s) per core" | tr -d " " | cut -d: -f2)))
    fi
  else
    NS=$(lscpu | grep -m1 "Cluster(s)" | tr -d " " | cut -d: -f2)
    NC=$((NS*$(lscpu | grep -m1 "Core(s) per cluster" | tr -d " " | cut -d: -f2)))
    NT=$(lscpu | grep -m1 "CPU(s)" | tr -d " " | cut -d: -f2)
    if [ ! "${NT}" ]; then
      NT=$((NC*$(lscpu | grep -m1 "Thread(s) per core" | tr -d " " | cut -d: -f2)))
    fi
  fi
elif [ -e /proc/cpuinfo ]; then
  NS=$(grep "physical id" /proc/cpuinfo | sort -u | wc -l | tr -d " ")
  if [ ! "${NS}" ]; then NS=1; fi
  NC=$((NS*$(grep -m1 "cpu cores" /proc/cpuinfo | tr -d " " | cut -d: -f2)))
  NT=$(grep -c "core id" /proc/cpuinfo | tr -d " ")
elif [ "Darwin" = "$(uname)" ]; then
  NS=$(sysctl hw.packages    | cut -d: -f2 | tr -d " ")
  NC=$(sysctl hw.physicalcpu | cut -d: -f2 | tr -d " ")
  NT=$(sysctl hw.logicalcpu  | cut -d: -f2 | tr -d " ")
fi
if [ "${NS}" ] && [ "${NC}" ] && [ "${NT}" ]; then
  HT=$((NT/NC))
  NC=$((NT/HT))
else
  NS=1 NC=1 NT=1 HT=1
fi

if [ "$1" ]; then
  NRANKS=$1
  shift
else
  NRANKS=${NC}
fi

if [ "$1" ]; then
  NUMNODES=$1
  shift
else
  NUMNODES=1
fi

if [ -e "${ROOT}/mynodes.sh" ] && [ "0" != "${MYNODES}" ]; then
  HOSTS=$("${ROOT}/mynodes.sh" 2>/dev/null | tr -s '\n ' ',' | sed 's/^\(..*[^,]\),*$/\1/')
fi
HOSTS=$(cut -d, -f1-${NUMNODES} <<<"${HOSTS}")
if [ ! "${HOSTS}" ]; then HOSTS=localhost; fi

PREFX=${HPCWL_COMMAND_PREFIX}
#MPIRUNPREFX="perf stat -e tlb:tlb_flush,irq_vectors:call_function_entry,syscalls:sys_enter_munmap,syscalls:sys_enter_madvise,syscalls:sys_enter_brk"
#MPIRUNPREFX="numactl --cpunodebind=0 --membind=0 --"
#PREFX="${PREFX} -gtool 'vtune -r vtune -data-limit 0 -collect hotspots -knob sampling-mode=hw -knob enable-stack-collection=true:$((NRANKS/2))=exclusive'"
#PREFX="${PREFX} -gtool 'advisor -project-dir=advisor --collect=survey:$((NRANKS/2))=exclusive'"
#PREFX="${PREFX} -gtool 'advisor -project-dir=advisor --collect=tripcounts --flop:$((NRANKS/2))=exclusive'"
#PREFX="${PREFX} -gtool 'advisor -project-dir=advisor --collect=roofline:$((NRANKS/2))=exclusive'"
#PREFX="${PREFX} ${ROOT}/multirun.sh 2"
ARGS="$*"

if [ "${I_MPI_ROOT}" ]; then
  MPIRUNFLAGS="-genvall"
  #MPIRUNFLAGS="${MPIRUNFLAGS} -rdma"
  MPIRUNFLAGS="${MPIRUNFLAGS} -bootstrap ssh"
  MPIRUNFLAGS="${MPIRUNFLAGS} -perhost ${NRANKS}"
  #
  #export I_MPI_FABRICS=shm:ofi
  export I_MPI_COLL_INTRANODE=${I_MPI_COLL_INTRANODE:-pt2pt}
  export I_MPI_DYNAMIC_CONNECTION=${I_MPI_DYNAMIC_CONNECTION:-1}
  export I_MPI_ADJUST_REDUCE=${I_MPI_ADJUST_REDUCE:-1}
  export I_MPI_ADJUST_BCAST=${I_MPI_ADJUST_BCAST:-1}
  export I_MPI_SHM_HEAP=${I_MPI_SHM_HEAP:-1}
  #
  export I_MPI_DEBUG=${I_MPI_DEBUG:-4}
  export I_MPI_PIN_DOMAIN=${I_MPI_PIN_DOMAIN:-auto}
  export I_MPI_PIN_ORDER=${I_MPI_PIN_ORDER:-bunch}
  #
  if [[ "${MPIRUNFLAGS}" =~ "-rdma" ]]; then
    export MPICH_ASYNC_PROGRESS=${MPICH_ASYNC_PROGRESS:-1}
  fi
else
  HOSTS=$(sed 's/^\(..*[^,]\),*$/\1/' <<<"${HOSTS}" | sed -e "s/,/:${NC},/g" -e "s/$/:${NC}/")
  MPIRUNFLAGS="${MPIRUNFLAGS} --report-bindings"
  MPIRUNFLAGS="${MPIRUNFLAGS} --map-by ppr:$(((NRANKS+NS-1)/NS)):package:PE=$((NC/NRANKS))"
fi

if [ "0" != "${MYNODES}" ]; then
  HST="-host ${HOSTS}"
fi

EXEVER=${EXEVER:-exe}
EXE=${ROOT}/${EXEVER}/${BUILD}/cp2k.${VERSION}
RUN="${MPIRUNPREFX} mpirun ${HST} ${MPIRUNFLAGS} \
  -np $((NRANKS*NUMNODES)) ${NUMACTL} ${PREFX} \
${EXE} ${WORKLOAD} ${ARGS}"

# setup OpenMP environment
if [ ! "${OMP_NUM_THREADS}" ]; then
  NR=$(((NRANKS/NS)*NS)); if [ "0" = "${NT}" ]; then NR=1; fi
  MC=$((NC/NR)); if [ "0" = "${MC}" ]; then MC=1; fi
  MT=$((HT<=MAXNT?HT:MAXNT))
  NTHREADS=$((MC*MT))
  if [ "${NT}" != "$((NRANKS*NTHREADS))" ]; then
    export OMP_NUM_THREADS=${NTHREADS}
    if [ ! "${OMP_PLACES}" ] && [ "1" = "${MT}" ]; then
      export OMP_PLACES=cores
    fi
  fi
fi
# OMP_PROC_BIND: default
export OMP_PROC_BIND=${OMP_PROC_BIND:-close}

# change into workload directory
cd "$(dirname "${WORKLOAD}")" || exit

# print some system info and commands
echo "$(cd "$(dirname "${EXE}")" && pwd -P)"
ldd "${EXE}"
echo

# print environment
env | grep \
  "^LD_PRELOAD\|^GLIBC_\|^LIBXSMM_\|^CUDA_\|^I_MPI_\|^PMI_\|^MPICH_\|^OMPI_\|^OMP_\|^ZEX_\|^IGC_\|^DBCSR_\|^ACC_\|^DBM_\|^MKL_\|^OPENCL_" \
    | sort
echo

# print final command
echo "${RUN}" | xargs
echo

# finally evaluate/run
eval "${RUN}"
