#!/usr/bin/env bash
# shellcheck disable=SC2001
#
ROOT=$(cd "$(dirname "$0")" && pwd -P)

if [ "--help" = "$1" ] || [ "-help" = "$1" ] || [ "-h" = "$1" ]; then HELP=1; fi

VERSION=${CP2K_VERSION:-psmp}
BUILD=${CP2K_BUILD}

# Threads per core
MAXNT=${MAXNT:-1}

# consider the following in .bashrc
if [ "$(command -v ulimit)" ]; then
  ulimit -s unlimited
  ulimit -c0
fi 2>/dev/null

if [ ! "$(command -v gdb)" ]; then
  alias gdb=gdb-oneapi
fi

export CP2K_DATA_DIR=${CP2K_DATA_DIR:-${ROOT}/data}
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

if [ "0" != "${TUNE}" ]; then
  CP2K_GLIBC_TUNABLES="glibc.malloc.trim_threshold=-1"
  # glibc.malloc.mmap_max=0 can cause issues (GmmLib)
  #CP2K_GLIBC_TUNABLES+=":glibc.malloc.mmap_max=0"
  if [ "x86_64" = "$(uname -m)" ]; then
    CP2K_GLIBC_TUNABLES+=":glibc.cpu.hwcaps=-AVX2"
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

if [ ! "${EXE}" ]; then
  EXEVER=${EXEVER:-exe}
  BUILD=${BUILD:-Linux-x86-64-intelx}
  if [ "/" != "${EXEVER:0:1}" ]; then
    EXE=${ROOT}/${EXEVER}/${BUILD}/cp2k.${VERSION}
  else
    EXE=${EXEVER}/${BUILD}/cp2k.${VERSION}
  fi
  if [ ! -e "${EXE}" ]; then
    EXEVER=build; BUILD=bin
    EXE=${EXEVER}/${BUILD}/cp2k.${VERSION}
  fi
  # CMake build folders: CP2K_BUILD, build, build-<arch>-* (most recent), or a sole build-*
  if [ ! -e "${EXE}" ]; then
    # target name as determined by configure-cp2k*.sh, XCFG_ARCH overrides
    if [ "aarch64" = "$(uname -m)" ]; then TARGET="-mcpu=native"; else TARGET="-march=native -mtune=native"; fi
    # shellcheck disable=SC2086
    ARCH=${XCFG_ARCH:-$(echo | gcc ${TARGET} -x c -E -v - 2>&1 | grep -m1 "/cc1 " | grep -o -E " -m(cpu|arch)=[^ +]*" | head -n1 | cut -d= -f2)}
    ARCH=${ARCH:-$(uname -m)}
    BIN=bin/cp2k.${VERSION}
    # shellcheck disable=SC2012
    if [ "${CP2K_BUILD}" ] && [ -e "${ROOT}/${CP2K_BUILD}/${BIN}" ]; then
      CANDIDATE=${ROOT}/${CP2K_BUILD}/${BIN}  # e.g., CP2K_BUILD=build-alderlake-gnu-cpu
    elif [ "${CP2K_BUILD}" ]; then
      CANDIDATES=$(ls -1t "${ROOT}/build-${ARCH}-${CP2K_BUILD}"*/"${BIN}" 2>/dev/null)
    elif [ -e "${ROOT}/build/${BIN}" ]; then
      CANDIDATE=${ROOT}/build/${BIN}
    else
      CANDIDATES=$(ls -1t "${ROOT}/build-${ARCH}-"*/"${BIN}" 2>/dev/null)
      if [ ! "${CANDIDATES}" ]; then  # any build-*, but only if unambiguous
        CANDIDATES=$(ls -1t "${ROOT}/build-"*/"${BIN}" 2>/dev/null)
        if [ "${CANDIDATES}" ] && [ "1" != "$(wc -l <<<"${CANDIDATES}")" ]; then
          AMBIGUOUS=${CANDIDATES}; CANDIDATES=""
        fi
      fi
    fi
    if [ "${CANDIDATES}" ]; then
      CANDIDATE=$(head -n1 <<<"${CANDIDATES}")
      if [ "1" != "$(wc -l <<<"${CANDIDATES}")" ] && [ ! "${HELP}" ]; then
        >&2 echo "INFO: using the most recent of $(wc -l <<<"${CANDIDATES}") builds (CP2K_BUILD selects)"
      fi
    fi
    # installation folder of configure-cp2k*.sh
    INSTDIR=$(cd "${ROOT}/.." && pwd -P)/cp2k
    for DIR in "${INSTDIR}/${ARCH}/${CP2K_BUILD:-gnu}" "${INSTDIR}/${CP2K_BUILD:-gnu}"; do
      if [ ! "${CANDIDATE}" ] && [ -e "${DIR}/${BIN}" ]; then
        CANDIDATE=${DIR}/${BIN}
      fi
    done
    if [ -e "${CANDIDATE}" ]; then EXE=${CANDIDATE}; fi
  fi
  if [ "0" != "${VERBOSE}" ]; then
    export ACC_OPENCL_VERBOSE=${ACC_OPENCL_VERBOSE:-1}
    export LIBXSTREAM_VERBOSE=${LIBXSTREAM_VERBOSE:-1}
    export LIBXS_GEMM_PRINT=${LIBXS_GEMM_PRINT:-0}
  fi
fi
if [ -d "$(dirname "${EXE}")" ]; then
  EXEDIR=$(cd "$(dirname "${EXE}")" && pwd -P)
  EXE=${EXEDIR}/$(basename "${EXE}")
fi

if [ "${HELP}" ]; then
  cat <<EOM
Usage: $0 [workload.inp [ranks-per-node [num-nodes]]] [cp2k-arguments]

Runs CP2K with MPI ranks and OpenMP threads pinned to the cores of each node.
By default, the ranks-per-node are the number of cores per node, and the nodes
are taken from Slurm, from mynodes.sh in CP2K's root directory, or HOSTS.

Executable (EXE overrides the selection below):
  exe/<CP2K_BUILD>/cp2k.<CP2K_VERSION> (legacy, default: Linux-x86-64-intelx)
  build/bin relative to the current directory (legacy)
  <CP2K_BUILD>/bin or build-<arch>-<CP2K_BUILD>*/bin if CP2K_BUILD is given, otherwise:
    build/bin in CP2K's root directory (e.g., a symbolic link to a build folder)
    build-<arch>-*/bin, the most recent if there are several
    build-*/bin if there is only one (any target)
  ../cp2k/<arch>/<CP2K_BUILD>/bin and ../cp2k/<CP2K_BUILD>/bin (default: gnu)

Environment:
  CP2K_VERSION=psmp      Kind of executable (cp2k.psmp), e.g., ssmp or pdbg
  CP2K_BUILD=<name>      Build folder, flavor (e.g., gnu-gpu), or tagname
  XCFG_ARCH=<arch>       Target name instead of the compiler's (gcc)
  CP2K_DATA_DIR=<path>   Data directory (default: CP2K's root directory/data)
  MAXNT=1                Threads per core
  OMP_NUM_THREADS=<n>    Threads per rank instead of the cores per rank
  VERBOSE=0              Quiet libraries and MPI (I_MPI_DEBUG, --report-bindings)
  TUNE=0                 No glibc tunables (malloc trim threshold, AVX2 off)
  TBBMALLOC=1            Preload TBB's malloc proxy (requires TBBROOT)
  MPI_OPT=1              Tuned Intel MPI, no launcher for a single rank
  MPI_OPT=0              No process placement (OpenMPI)
  BOOTSTRAP=<name>       Bootstrap of Intel MPI (ssh if numeric), oversubscribe (OpenMPI)
  HOSTS=<a,b,...>        Comma-separated list of nodes
  CHECK=1                Run PROLOG and EPILOG (numactl -H, clinfo -l)
  CHECK_EXE=<path>       Run executable once per node before CP2K
  NUMACTL=<command>      Prefix of the executable, e.g., "numactl --preferred=1"
  HPCWL_COMMAND_PREFIX   Prefix of the executable, e.g., "gdb -ex run --args"
  MPIRUNPREFX=<command>  Prefix of the MPI launcher
  MPIRUNFLAGS=<flags>    Additional flags of the MPI launcher

EOM
  if [ -e "${EXE}" ]; then
    echo "Executable: ${EXE}"
  else
    echo "Executable: not found"
  fi
  exit 0
fi

if [ -e "${EXE}" ]; then
  export LD_LIBRARY_PATH=${EXEDIR}:${LD_LIBRARY_PATH}
elif [ "${AMBIGUOUS}" ]; then
  >&2 echo "ERROR: several builds found, please select one with CP2K_BUILD=<folder>:"
  >&2 sed -e "s|^${ROOT}/||" -e "s|/${BIN}$||" -e "s/^/  /" <<<"${AMBIGUOUS}"
  exit 1
else
  >&2 echo "ERROR: ${EXE} executable not found (see $0 --help)!"
  exit 1
fi

if [ "$1" ]; then
  if [ -f "$1" ]; then
    WORKLOAD=$(cd "$(dirname "$1")" && pwd -P)/$(basename "$1")
    shift
  elif [ "${EXEVER}" ]; then
    >&2 echo "ERROR: workload $1 is not an input file!"
    exit 1
  fi
elif [ "${EXEVER}" ]; then
  >&2 echo "Please use: $0 /file/to/workload.inp [ranks-per-node [num-nodes]] (or --help)"
  exit 1
fi

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

if [ "${SLURM_NTASKS_PER_NODE}" ]; then
  NRANKS=${SLURM_NTASKS_PER_NODE}
elif [ "$1" ]; then
  if [[ $1 =~ ^[1-9][0-9]*$ ]]; then
    NRANKS=$1
    shift
  else
    >&2 echo "ERROR: $1 does not specify rank-count per node!"
    exit 1
  fi
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

if [ "${SLURM_JOB_NUM_NODES}" ]; then
  NUMNODES=${SLURM_JOB_NUM_NODES}
elif [ "$1" ]; then
  if [[ $1 =~ ^[1-9][0-9]*$ ]]; then
    HOSTS=$(cut -d, -f"1-$1" <<<"${HOSTS}")
    NUMNODES=$1
    shift
  else
    >&2 echo "ERROR: $1 does not specify node-count!"
    exit 1
  fi
else
  NUMCOMMA=$(tr -cd ',' <<<"${HOSTS}" | wc -c)
  NUMNODES=$((NUMCOMMA+1))
fi

#HPCWL_COMMAND_PREFIX="aps -c mpi,omp"
#HPCWL_COMMAND_PREFIX="aps --counters -c mpi --stat-level=5"
#HPCWL_COMMAND_PREFIX="gdb -ex run -ex backtrace --args"
#MPIRUNPREFX="perf stat -e tlb:tlb_flush,irq_vectors:call_function_entry,syscalls:sys_enter_munmap,syscalls:sys_enter_madvise,syscalls:sys_enter_brk"
#MPIRUNPREFX="numactl --cpunodebind=0 --membind=0 --"

PREFX=${HPCWL_COMMAND_PREFIX}
#EVNTS="BR_MISP_RETIRED.ALL_BRANCHES,BR_INST_RETIRED.ALL_BRANCHES,MEM_INST_RETIRED.ALL_STORES,MEM_INST_RETIRED.ALL_LOADS"
#PREFX="${PREFX} -gtool 'emon -v -q -X -t0 -C "${EVNTS}":$((NRANKS/2))=exclusive'"
#PREFX="${PREFX} -gtool 'vtune -r vtune -data-limit 0 -collect hotspots -knob sampling-mode=hw -knob enable-stack-collection=true:$((NRANKS/2))=exclusive'"
#PREFX="${PREFX} -gtool 'advisor -project-dir=advisor --collect=survey:$((NRANKS/2))=exclusive'"
#PREFX="${PREFX} -gtool 'advisor -project-dir=advisor --collect=tripcounts --flop:$((NRANKS/2))=exclusive'"
#PREFX="${PREFX} -gtool 'advisor -project-dir=advisor --collect=roofline:$((NRANKS/2))=exclusive'"
#PREFX="${PREFX} -gtool 'unitrace --chrome-kernel-logging --opencl -o unitrace.out:$((NRANKS/2))=exclusive'"
#PREFX="${PREFX} unitrace --chrome-kernel-logging --opencl -o ${ROOT}/unitrace.\${PMI_RANK:-0}"
#PREFX="${PREFX} ${ROOT}/multirun.sh 2"

# additional command-line arguments
ARGS="$*"

MPIRUN=$(command -v mpirun)
if [ ! "${MPIRUN}" ]; then
  MPIRUN=$(command -v mpiexec)
fi

if [[ "${I_MPI_ROOT}" && "0" != "${IMPI}" ]] || \
   [[ "${MPICH}" && "0" != "${MPICH}" ]];
then
  if [ "${MPIRUN}" ]; then
    #MPIRUNFLAGS="${MPIRUNFLAGS} -rdma"
    #MPIRUNFLAGS="${MPIRUNFLAGS} -genvall"
    MPIRUNFLAGS="${MPIRUNFLAGS} -perhost ${NRANKS}"
    if [ "${BOOTSTRAP}" ] && [ "0" != "${BOOTSTRAP}" ]; then
      if ! [[ ${BOOTSTRAP} =~ ^[+-]?[0-9]+$ ]]; then
        MPIRUNFLAGS="${MPIRUNFLAGS} -bootstrap ${BOOTSTRAP}"
      else
        MPIRUNFLAGS="${MPIRUNFLAGS} -bootstrap ssh"
      fi
    fi
    if [ "${EXEVER}" ] && [ "0" != "${VERBOSE}" ]; then
      export I_MPI_DEBUG=${I_MPI_DEBUG:-4}
    fi
    if [[ "${MPIRUNFLAGS}" = *" -rdma "* ]]; then
      export MPICH_ASYNC_PROGRESS=${MPICH_ASYNC_PROGRESS:-1}
    fi
    if [ "${MPI_OPT}" ] && [ "0" != "${MPI_OPT}" ]; then
      export I_MPI_COLL_INTRANODE=${I_MPI_COLL_INTRANODE:-pt2pt}
      export I_MPI_DYNAMIC_CONNECTION=${I_MPI_DYNAMIC_CONNECTION:-1}
      export I_MPI_ADJUST_REDUCE=${I_MPI_ADJUST_REDUCE:-1}
      export I_MPI_ADJUST_BCAST=${I_MPI_ADJUST_BCAST:-1}
    fi
    if [ "1" = "${NUMNODES}" ]; then
      export I_MPI_FABRICS=${I_MPI_FABRICS:-shm}
    fi
    export I_MPI_SHM_HEAP=${I_MPI_SHM_HEAP:-1}
    #
    #export I_MPI_PIN_DOMAIN=${I_MPI_PIN_DOMAIN:-auto}
    #export I_MPI_PIN_ORDER=${I_MPI_PIN_ORDER:-bunch}
  fi
  if [ "0" != "${I_MPI_OFFLOAD}" ] && \
     command -v ldd >/dev/null && ldd "${EXE}" 2>/dev/null | grep -q libOpenCL;
  then
    export MPICH_GPU_SUPPORT_ENABLED=${MPICH_GPU_SUPPORT_ENABLED:-1}
    export I_MPI_OFFLOAD_RDMA=${I_MPI_OFFLOAD_RDMA:-1}
    export I_MPI_OFFLOAD=${I_MPI_OFFLOAD:-1}
  else
    export I_MPI_OFFLOAD=${I_MPI_OFFLOAD:-0}
  fi
  export MPICH_MALLOC_FALLBACK=${MPICH_MALLOC_FALLBACK:-1}
  export FI_MLX_INJECT=${FI_MLX_INJECT:-0}
elif [ "${MPIRUN}" ]; then
  if [ "${BOOTSTRAP}" ] && [ "0" != "${BOOTSTRAP}" ]; then
    MPIRUNFLAGS="${MPIRUNFLAGS} --oversubscribe"
  fi
  if [ "${EXEVER}" ] && [ "0" != "${VERBOSE}" ] && [ ! "${IMPI}" ]; then
    MPIRUNFLAGS="${MPIRUNFLAGS} --report-bindings"
  fi
  if [ "0" != "${MPI_OPT}" ]; then
    # Depending on OpenMPI version: package <-> socket
    if ${MPIRUN} --map-by ppr:$(((NRANKS+NS-1)/NS)):package:PE=$((NC/NRANKS)) true 2>/dev/null; then
      MPIRUNFLAGS="${MPIRUNFLAGS} --map-by ppr:$(((NRANKS+NS-1)/NS)):package:PE=$((NC/NRANKS))"
    else
      MPIRUNFLAGS="${MPIRUNFLAGS} --map-by ppr:$(((NRANKS+NS-1)/NS)):socket:PE=$((NC/NRANKS))"
    fi
  fi
fi

if [ "${MPIRUN}" ] && [ "${CP2K_GLIBC_TUNABLES}" ]; then
  if [ "${GLIBC_TUNABLES}" ]; then
    export GLIBC_TUNABLES="${GLIBC_TUNABLES}:${CP2K_GLIBC_TUNABLES}"
  else
    export GLIBC_TUNABLES="${CP2K_GLIBC_TUNABLES}"
  fi
fi

if [ "${HOSTS}" ] && [ "1" != "${NUMNODES}" ] && [ ! "${SLURM_NODELIST}" ]; then
  HST="-host ${HOSTS}"
fi

if [ ! "${MPI_OPT}" ] || [ "0" = "${MPI_OPT}" ] || \
   [ "1" != "$((NRANKS*NUMNODES))" ] || \
   [ "${HST}" ] || [ "${PREFX}" ];
then
  if [ "${MPIRUN}" ]; then
    RUN="${MPIRUNPREFX} ${MPIRUN} ${HST} ${MPIRUNFLAGS} \
        -np $((NRANKS*NUMNODES)) ${NUMACTL} ${PREFX} \
      ${EXE} ${WORKLOAD} ${ARGS}"
  elif [ "$(command -v srun)" ]; then
    RUN="${MPIRUNPREFX} srun \
        --cpu-bind=sockets \
        ${NUMACTL} ${PREFX} \
      ${EXE} ${WORKLOAD} ${ARGS}"
  fi
else
  RUN="${MPIRUNPREFX} ${NUMACTL} ${EXE} ${WORKLOAD} ${ARGS}"
fi

# setup OpenMP environment
NR=$(((NRANKS/NS)*NS)); if [ "0" = "${NR}" ] || [ "0" = "${NT}" ]; then NR=1; fi
MC=$((NC/NR)); if [ "0" = "${MC}" ]; then MC=1; fi
MT=$((HT<=MAXNT?HT:MAXNT))
NTHREADS=${OMP_NUM_THREADS:-$((MC*MT))}
if [ "${VERBOSE}" ] && [ "0" != "${VERBOSE}" ]; then
  echo "OMP: NS=${NS} NC=${NC} NT=${NT} MAXHT=${MAXNT} HT=${HT} MT=${MT}"
fi
if [ "1" != "${HT}" ] && [ "1" = "${MT}" ]; then
  export OMP_PROC_BIND=${OMP_PROC_BIND:-close}
  export OMP_PLACES=${OMP_PLACES:-cores}
else
  export OMP_PROC_BIND=${OMP_PROC_BIND:-true}
fi
if [ ! "${OMP_NUM_THREADS}" ]; then
  export OMP_NUM_THREADS=${NTHREADS}
fi

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

# print additional info
if [ "${EXEVER}" ] || [[ "${VERBOSE}" && "0" != "${VERBOSE}" ]]; then
  # print details about executable
  echo "EXE: ${EXE}"
  ldd "${EXE}" 2>/dev/null
  echo
  # print environment
  ENVPAT="^LD_PRELOAD\|^GLIBC_\|^LIBXS\|^CUDA_\|^DBCSR_\|^ACC_\|^DBM_\|^MKL\|^OPENCL_\|^[^ _].*=[0-9][0-9]*$"
  ENVPAT+="\|^SLURM_\|^I_MPI_\|^PMI_\|^MPICH_\|^PSM3_\|^FI_\|^OMPI_\|^UCX_\|^OMP_\|^KMP_\|^ZEX_\|^IGC_"
  env | grep "${ENVPAT}" | sort
  echo "PWD=${PWD}"
  ENVGEN=$(command -v iga64)
  if [ "${ENVGEN}" ]; then echo "GEN=$(cd "$(dirname "${ENVGEN}")/../.." 2>/dev/null && pwd -P)"; fi
  echo
fi

# check and prolog
if [ "${MPIRUN}" ]; then
  if [ "${CHECK_EXE}" ] && [ -e "${CHECK_EXE}" ]; then
    echo "*** CHECK ***"
    eval "${MPIRUN} ${HST} -np ${NUMNODES} ${CHECK_EXE} 2>/dev/null"
    echo "*************"
  fi
  PROLOG=${PROLOG:-${CHECK}}
  if [ "${PROLOG}" ] && [ "0" != "${PROLOG}" ] && [ "${HOSTS}" ]; then
    echo "*** PROLOG ***"
    if command -v numactl >/dev/null; then
      eval "${MPIRUN} ${HST} -np ${NUMNODES} numactl -H 2>/dev/null"
      echo
    fi
    if command -v clinfo >/dev/null; then
      eval "${MPIRUN} ${HST} -np ${NUMNODES} clinfo -l 2>/dev/null"
    fi
    echo "**************"
  fi
fi

# print job command
echo "${RUN}" | xargs
echo
# evaluate/run job
eval "${RUN}"

# epilog
if [ "${MPIRUN}" ]; then
  EPILOG=${EPILOG:-${CHECK}}
  if [ "${EPILOG}" ] && [ "0" != "${EPILOG}" ] && [ "${HOSTS}" ]; then
    echo "*** EPILOG ***"
    if command -v clinfo >/dev/null; then
      eval "${MPIRUN} ${HST} -np ${NUMNODES} clinfo -l 2>/dev/null"
    fi
    echo "**************"
  fi
fi
