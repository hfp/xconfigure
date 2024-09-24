#!/usr/bin/env bash
# shellcheck disable=SC2001
#
ROOT=${PWD}
ROOT=$(cd "$(dirname "$0")" && pwd -P)
BUILD=Linux-x86-64-intelx
VERSION=psmp

# Threads per core
MAXNT=${MAXNT:-1}

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

if [ "${GLIBC_TUNABLES}" ]; then
  export GLIBC_TUNABLES="${GLIBC_TUNABLES}:glibc.cpu.hwcaps=-AVX2"
else
  export GLIBC_TUNABLES="glibc.cpu.hwcaps=-AVX2" 
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

if [ -e "${ROOT}/mynodes.sh" ]; then
  HOSTS=$("${ROOT}/mynodes.sh" 2>/dev/null | tr -s '\n ' ',' | sed 's/^\(..*[^,]\),*$/\1/')
elif [ "${SLURM_NODELIST}" ] && command -v scontrol >/dev/null; then
  HOSTS=$(scontrol show hostnames 2>/dev/null | tr -s '\n ' ',' | sed 's/^\(..*[^,]\),*$/\1/')
else
  HOSTS=${HOSTS:-localhost}
fi

if [ "$1" ]; then
  HOSTS=$(cut -d, -f"1-$1" <<<"${HOSTS}")
  NUMNODES=$1
  shift
elif [ "${SLURM_JOB_NUM_NODES}" ]; then
  NUMNODES=${SLURM_JOB_NUM_NODES}
else
  NUMCOMMA=$(tr -cd ',' <<<"${HOSTS}" | wc -c)
  NUMNODES=$((NUMCOMMA+1))
fi

#HPCWL_COMMAND_PREFIX="aps -c mpi,omp"
#MPIRUNPREFX="perf stat -e tlb:tlb_flush,irq_vectors:call_function_entry,syscalls:sys_enter_munmap,syscalls:sys_enter_madvise,syscalls:sys_enter_brk"
#MPIRUNPREFX="numactl --cpunodebind=0 --membind=0 --"

PREFX=${HPCWL_COMMAND_PREFIX}
#PREFX="${PREFX} -gtool 'vtune -r vtune -data-limit 0 -collect hotspots -knob sampling-mode=hw -knob enable-stack-collection=true:$((NRANKS/2))=exclusive'"
#PREFX="${PREFX} -gtool 'advisor -project-dir=advisor --collect=survey:$((NRANKS/2))=exclusive'"
#PREFX="${PREFX} -gtool 'advisor -project-dir=advisor --collect=tripcounts --flop:$((NRANKS/2))=exclusive'"
#PREFX="${PREFX} -gtool 'advisor -project-dir=advisor --collect=roofline:$((NRANKS/2))=exclusive'"
#PREFX="${PREFX} ${ROOT}/multirun.sh 2"

# additional command-line arguments
ARGS="$*"

EXEVER=${EXEVER:-exe}
EXE=$(cd "${ROOT}/${EXEVER}/${BUILD}" && pwd -P)/cp2k.${VERSION}

if [ "${I_MPI_ROOT}" ]; then
  #MPIRUNFLAGS="${MPIRUNFLAGS} -rdma"
  #MPIRUNFLAGS="${MPIRUNFLAGS} -genvall"
  MPIRUNFLAGS="${MPIRUNFLAGS} -perhost ${NRANKS}"
  if [ "0" != "${BOOTSTRAP}" ]; then
    if [ "${BOOTSTRAP}" ]; then
      MPIRUNFLAGS="${MPIRUNFLAGS} -bootstrap ${BOOTSTRAP}"
    else
      MPIRUNFLAGS="${MPIRUNFLAGS} -bootstrap ssh"
    fi
  fi
  if [[ "${MPIRUNFLAGS}" = *" -rdma "* ]]; then
    export MPICH_ASYNC_PROGRESS=${MPICH_ASYNC_PROGRESS:-1}
  fi
  if [ ! "${ACC_OPENCL_DEVIDS}" ] && [ ! "${ACC_OPENCL_DEVTYPE}" ] && \
       command -v ldd >/dev/null && ldd "${EXE}" | grep -q libOpenCL;
  then
    export I_MPI_OFFLOAD_RDMA=${I_MPI_OFFLOAD_RDMA:-1}
    export I_MPI_OFFLOAD=${I_MPI_OFFLOAD:-1}
  else
    export I_MPI_OFFLOAD=0
  fi
  if [ ! "${MPI_OPT}" ] || [ "0" != "${MPI_OPT}" ]; then
    export I_MPI_COLL_INTRANODE=${I_MPI_COLL_INTRANODE:-pt2pt}
    export I_MPI_DYNAMIC_CONNECTION=${I_MPI_DYNAMIC_CONNECTION:-1}
    export I_MPI_ADJUST_REDUCE=${I_MPI_ADJUST_REDUCE:-1}
    export I_MPI_ADJUST_BCAST=${I_MPI_ADJUST_BCAST:-1}
  fi
  export I_MPI_SHM_HEAP=${I_MPI_SHM_HEAP:-1}
  export I_MPI_DEBUG=${I_MPI_DEBUG:-4}
  #
  #export I_MPI_PIN_DOMAIN=${I_MPI_PIN_DOMAIN:-auto}
  #export I_MPI_PIN_ORDER=${I_MPI_PIN_ORDER:-bunch}
  #export I_MPI_FABRICS=shm:tcp
else
  MPIRUNFLAGS="${MPIRUNFLAGS} --report-bindings"
  MPIRUNFLAGS="${MPIRUNFLAGS} --map-by ppr:$(((NRANKS+NS-1)/NS)):package:PE=$((NC/NRANKS))"
fi

if [ -e "${ROOT}/mynodes.sh" ]; then
  HST="-host ${HOSTS}"
fi

RUN="${MPIRUNPREFX} mpirun ${HST} ${MPIRUNFLAGS} \
  -np $((NRANKS*NUMNODES)) ${NUMACTL} ${PREFX} \
${EXE} ${WORKLOAD} ${ARGS}"

# setup OpenMP environment
if [ ! "${OMP_NUM_THREADS}" ]; then
  NR=$(((NRANKS/NS)*NS)); if [ "0" = "${NR}" ] || [ "0" = "${NT}" ]; then NR=1; fi
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
HOSTNAME=$(hostname)
if [ "$(command -v sinfo)" ] && [ "$(command -v head)" ]; then
  NODEINFO=$(sinfo -N -n "${HOSTNAME}" --noheader -o "%P %f" | head -n1)
fi
if [ "${NODEINFO}" ] && [ "$(command -v sed)" ]; then
  echo "HOSTINFO: $(sed "s/..* ,*//" <<<"${NODEINFO}")"
  echo "PARTITION: $(sed "s/ .*//" <<<"${NODEINFO}")"
fi
echo
echo "EXE: ${EXE}"
ldd "${EXE}"
echo

# print environment
ENVPAT="^LD_PRELOAD\|^GLIBC_\|^LIBXSMM_\|^CUDA_\|^DBCSR_\|^ACC_\|^DBM_\|^MKL\|^OPENCL_\|=[0-9][0-9]*$"
ENVPAT+="\|^SLURM_\|^I_MPI_\|^PMI_\|^MPICH_\|^PSM3_\|^FI_\|^OMPI_\|^UCX_\|^OMP_\|^KMP_\|^ZEX_\|^IGC_"
env | grep "${ENVPAT}" | sort
echo

# print final command
echo "${RUN}" | xargs
echo

# prolog
PROLOG=${PROLOG:-${CHECK}}
if [ "${PROLOG}" ] && [ "0" != "${PROLOG}" ] && [ "${HOSTS}" ]; then
  echo "*** PROLOG ***"
  if command -v clinfo >/dev/null; then
    mpirun -host "${HOSTS}" -np ${NUMNODES} clinfo -l 2>/dev/null
  fi
  echo "**************"
fi

# evaluate/run job
eval "${RUN}"

# epilog
EPILOG=${EPILOG:-${CHECK}}
if [ "${EPILOG}" ] && [ "0" != "${EPILOG}" ] && [ "${HOSTS}" ]; then
  echo "*** EPILOG ***"
  if command -v clinfo >/dev/null; then
    mpirun -host "${HOSTS}" -np ${NUMNODES} clinfo -l 2>/dev/null
  fi
  echo "**************"
fi
