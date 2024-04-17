#!/usr/bin/env bash
# shellcheck disable=SC2001,SC2034
#
ROOT=${PWD}
ROOT=$(cd "$(dirname "$0")" && pwd -P)
BUILD=Linux-x86-64-intelx
VERSION=psmp

# Threads per core
if [ ! "${MAXNT}" ]; then
  MAXNT=1
fi

# consider the following in your .bashrc
# ulimit -s unlimited
# ulimit -c0

if [ ! "${CP2K_DATA_DIR}" ]; then
  export CP2K_DATA_DIR=${ROOT}/data
fi

#NUMACTL="numactl --preferred=1"
#export MPICH_ASYNC_PROGRESS=1
#export LIBXSMM_VERBOSE=1
if [ ! "${ACC_OPENCL_VERBOSE}" ]; then
  export ACC_OPENCL_VERBOSE=1
fi
if [ ! "${EXEVER}" ]; then
  EXEVER=exe
fi

EXE=${ROOT}/${EXEVER}/${BUILD}/cp2k.${VERSION}
EXEDIR=$(cd "$(dirname "${EXE}")" && pwd -P)

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

#MPIRUNPREFX="perf stat -e tlb:tlb_flush,irq_vectors:call_function_entry,syscalls:sys_enter_munmap,syscalls:sys_enter_madvise,syscalls:sys_enter_brk "
PREFX=${HPCWL_COMMAND_PREFIX}
#PREFX="${PREFX} -gtool 'amplxe-cl -r vtune -data-limit 0 -collect hotspots -knob sampling-mode=hw -knob enable-stack-collection=true:0=exclusive'"
#PREFX="${PREFX} -gtool 'advixe-cl -project-dir=advisor --collect=survey:4=exclusive'"
#PREFX="${PREFX} -gtool 'advixe-cl -project-dir=advisor --collect=tripcounts --flop:4=exclusive'"
#PREFX="${PREFX} -gtool 'advixe-cl -project-dir=advisor --collect=roofline:4=exclusive'"
#PREFX="${PREFX} ${ROOT}/multirun.sh 2"
#MPIRUNPREFX="numactl --cpunodebind=0 --membind=0 --"
ARGS=""

if [ "$1" ] && [ -f "$1" ]; then
  WORKLOAD=$1
  shift
else
  WORKLOAD=${ROOT}/tests/QS/benchmark/H2O-32.inp
fi
WORKLOAD=$(cd "$(dirname "${WORKLOAD}")" && pwd -P)/$(basename "${WORKLOAD}")

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
HOST=$(cut -d, -f1 <<<"${HOSTS}")

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

if [ "${I_MPI_ROOT}" ]; then
  #export I_MPI_FABRICS=shm
  export I_MPI_COLL_INTRANODE=pt2pt
  export I_MPI_DYNAMIC_CONNECTION=1
  export I_MPI_ADJUST_REDUCE=1
  export I_MPI_ADJUST_BCAST=1
  export I_MPI_SHM_HEAP=1
  #
  if [ ! "${I_MPI_HYDRA_BOOTSTRAP}" ]; then
    MPIRUNFLAGS="${MPIRUNFLAGS} -bootstrap ssh"
  fi
  #
  MPIRUNFLAGS="-genvall"
  #MPIRUNFLAGS="${MPIRUNFLAGS} -rdma"
  MPIRUNFLAGS="${MPIRUNFLAGS} -genv I_MPI_DEBUG 4"
  MPIRUNFLAGS="${MPIRUNFLAGS} -genv I_MPI_PIN_DOMAIN auto"
  MPIRUNFLAGS="${MPIRUNFLAGS} -genv I_MPI_PIN_ORDER bunch"
  NPERNODE=-perhost
  ENVFLAG=-genv
  ENVEQ=' '
else
  HOSTS=$(sed 's/^\(..*[^,]\),*$/\1/' <<<"${HOSTS}" | sed -e "s/,/:${NC},/g" -e "s/$/:${NC}/")
  MPIRUNFLAGS="${MPIRUNFLAGS} --report-bindings"
  MPIRUNFLAGS="${MPIRUNFLAGS} --map-by slot:PE=${NC}"
  NPERNODE=-npernode
  ENVFLAG=-x
  ENVEQ='='
fi

if [ "0" != "${MYNODES}" ]; then
  HST="-host ${HOSTS}"
fi

RUN="${MPIRUNPREFX} mpirun ${HST} ${MPIRUNFLAGS} \
  -np $((NRANKS*NUMNODES)) ${NPERNODE} ${NRANKS} \
  ${NUMACTL} ${PREFX} \
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
if [ ! "${OMP_PROC_BIND}" ]; then
  export OMP_PROC_BIND=close
fi

# print some system info and commands
cd "$(dirname "${WORKLOAD}")" || exit
echo "${EXEDIR}"
ldd "${EXE}"
if [ "$(command -v numactl)" ]; then numactl -H; fi
echo "${RUN}"
echo

# print environment
env | grep "^LIBXSMM_\|^CUDA_\|^I_MPI_\|^PMI_\|^MPICH_\|^OMPI_\|^OMP_\|^ZEX_\|^IGC_\|^ACC_\|^DBM_\|^MKL_"
echo

# finally evaluate/run
eval "${RUN}"
