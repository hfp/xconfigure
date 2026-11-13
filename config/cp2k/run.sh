#!/usr/bin/env bash
# Runs CP2K with MPI ranks and OpenMP threads pinned to the cores of each node (see --help).
# The script can be symlinked into CP2K's root directory, which is then ROOT.
# shellcheck disable=SC2001,SC2012
ROOT=$(cd "$(dirname "$0")" && pwd -P)

# variable is set and not "0" (unset means off)
is_on() { [ "$1" ] && [ "0" != "$1" ]; }
# variable is not "0" (unset means on)
not_off() { [ "0" != "$1" ]; }
# first existing file among the arguments
first_file() {
  local FILE RESULT=""
  for FILE in "$@"; do
    if [ -f "${FILE}" ]; then RESULT=${FILE}; break; fi
  done
  echo "${RESULT}"
}
# first launcher in PATH whose version does ("match") or does not ("skip") contain a pattern
find_launcher() {
  local CMD VER RESULT=""
  for CMD in $(type -ap mpirun mpiexec); do
    VER=$("${CMD}" --version 2>&1)
    if [[ "${VER}" = *"$2"* ]]; then
      if [ "match" = "$1" ]; then RESULT=${CMD}; break; fi
    elif [ "skip" = "$1" ]; then
      RESULT=${CMD}; break
    fi
  done
  echo "${RESULT}"
}
# comma-separated list from whitespace, newline, or comma-separated items
to_list() { tr -s '\n\t ,' ',' | sed 's/^,*//;s/,*$//'; }

# command line: [--help] [workload.inp [ranks-per-node [num-nodes]]] [cp2k-arguments]
if [ "--help" = "$1" ] || [ "-help" = "$1" ] || [ "-h" = "$1" ]; then HELP=1; shift; fi
if [ -f "$1" ]; then
  WORKLOAD=$(cd "$(dirname "$1")" && pwd -P)/$(basename "$1")
  shift
elif [ "$1" ] && [ ! "${EXE}" ] && [ ! "${HELP}" ]; then
  >&2 echo "ERROR: workload $1 is not an input file!"
  exit 1
fi
if [[ $1 =~ ^[1-9][0-9]*$ ]]; then RANKS_ARG=$1; shift; fi
if [[ $1 =~ ^[1-9][0-9]*$ ]]; then NODES_ARG=$1; shift; fi
ARGS="$*"
if [ ! "${WORKLOAD}" ] && [ ! "${EXE}" ] && [ ! "${HELP}" ]; then
  >&2 echo "Please use: $0 /file/to/workload.inp [ranks-per-node [num-nodes]] (or --help)"
  exit 1
fi

# executable: EXE, legacy locations, CMake build folders, or installation folder
VERSION=${CP2K_VERSION:-psmp}
BIN=bin/cp2k.${VERSION}
if [ ! "${EXE}" ]; then
  EXE=$(first_file "${ROOT}/exe/${CP2K_BUILD:-Linux-x86-64-intelx}/cp2k.${VERSION}" "${PWD}/build/${BIN}")
fi
if [ ! "${EXE}" ]; then
  # target name as determined by configure-cp2k*.sh, XCFG_ARCH overrides
  if [ "aarch64" = "$(uname -m)" ]; then TARGET="-mcpu=native"; else TARGET="-march=native -mtune=native"; fi
  # shellcheck disable=SC2086
  ARCH=${XCFG_ARCH:-$(echo | gcc ${TARGET} -x c -E -v - 2>&1 | grep -m1 "/cc1 " | grep -o -E " -m(cpu|arch)=[^ +]*" | head -n1 | cut -d= -f2)}
  ARCH=${ARCH:-$(uname -m)}
  if [ "${CP2K_BUILD}" ]; then  # e.g., CP2K_BUILD=build-alderlake-gnu-cpu or CP2K_BUILD=gnu-gpu
    LATEST=$(ls -1t "${ROOT}/build-${ARCH}-${CP2K_BUILD}"*/"${BIN}" 2>/dev/null)
    EXE=$(first_file "${ROOT}/${CP2K_BUILD}/${BIN}" "$(head -n1 <<<"${LATEST}")")
  else
    LATEST=$(ls -1t "${ROOT}/build-${ARCH}-"*/"${BIN}" 2>/dev/null)
    if [ ! "${LATEST}" ]; then  # any build-*, but only if unambiguous
      LATEST=$(ls -1t "${ROOT}/build-"*/"${BIN}" 2>/dev/null)
      if [ "1" -lt "$(grep -c . <<<"${LATEST}")" ]; then AMBIGUOUS=${LATEST}; LATEST=""; fi
    fi
    EXE=$(first_file "${ROOT}/build/${BIN}" "$(head -n1 <<<"${LATEST}")")
  fi
  if [ "${LATEST}" ] && [ "$(head -n1 <<<"${LATEST}")" = "${EXE}" ] && \
     [ "1" -lt "$(grep -c . <<<"${LATEST}")" ] && [ ! "${HELP}" ];
  then
    >&2 echo "INFO: using the most recent of $(grep -c . <<<"${LATEST}") builds (CP2K_BUILD selects)"
  fi
  if [ ! "${EXE}" ]; then  # installation folder of configure-cp2k*.sh
    INSTDIR=$(cd "${ROOT}/.." && pwd -P)/cp2k
    EXE=$(first_file "${INSTDIR}/${ARCH}/${CP2K_BUILD:-gnu}/${BIN}" "${INSTDIR}/${CP2K_BUILD:-gnu}/${BIN}")
  fi
fi
if [ "${EXE}" ] && [[ "${EXE}" != */* ]]; then  # command name
  EXE=$(command -v "${EXE}" || echo "${EXE}")
fi
if [ -e "${EXE}" ]; then
  EXEDIR=$(cd "$(dirname "${EXE}")" && pwd -P)
  EXE=${EXEDIR}/$(basename "${EXE}")
fi

if [ "${HELP}" ]; then
  cat <<EOM
Usage: $0 [workload.inp [ranks-per-node [num-nodes]]] [cp2k-arguments]

Runs CP2K with MPI ranks pinned to their own cores and OpenMP threads pinned
within each rank. By default, the ranks-per-node are the number of cores per
node (a single rank for a serial executable or without MPI launcher), and the
nodes are taken from HOSTS, from mynodes.sh in CP2K's root directory, or from
Slurm. The command line takes precedence over Slurm.

Executable (EXE overrides the selection below):
  exe/<CP2K_BUILD>/cp2k.<CP2K_VERSION> (legacy, default: Linux-x86-64-intelx)
  build/bin relative to the current directory (legacy)
  <CP2K_BUILD>/bin or build-<arch>-<CP2K_BUILD>*/bin if CP2K_BUILD is given, otherwise:
    build/bin in CP2K's root directory (e.g., a symbolic link to a build folder)
    build-<arch>-*/bin, the most recent if there are several
    build-*/bin if there is only one (any target)
  ../cp2k/<arch>/<CP2K_BUILD>/bin and ../cp2k/<CP2K_BUILD>/bin (default: gnu)

MPI launcher: mpirun or mpiexec (Intel MPI, MPICH, or OpenMPI as reported by
the launcher's version), or srun if there is no such launcher.

Environment:
  CP2K_VERSION=psmp      Kind of executable (cp2k.psmp), e.g., ssmp or pdbg
  CP2K_BUILD=<name>      Build folder, flavor (e.g., gnu-gpu), or tagname
  XCFG_ARCH=<arch>       Target name instead of the compiler's (gcc)
  CP2K_DATA_DIR=<path>   Data directory (default: CP2K's root directory/data)
  MAXNT=1                Threads per core
  OMP_NUM_THREADS=<n>    Threads per rank instead of the cores per rank
  PIN=0                  No process or thread binding
  VERBOSE=0              Quiet libraries and MPI, no details about the run
  TUNE=0                 No glibc tunables (malloc trim threshold, AVX2 off)
  TBBMALLOC=1            Preload TBB's malloc proxy (requires TBBROOT)
  IMPI=1, IMPI=0         Prefer or avoid Intel MPI's launcher
  MPICH=1                Prefer MPICH's launcher, e.g., over oneAPI's
  MPI_OPT=1              Tuned Intel MPI, no launcher for a single rank
  BOOTSTRAP=<name>       Bootstrap of Intel MPI or MPICH (ssh if numeric)
  OVERSUBSCRIBE=1        More ranks than slots (OpenMPI)
  HOSTS=<a,b,...>        Comma-separated list of nodes
  CHECK=1                Run PROLOG and EPILOG (numactl -H, clinfo -l)
  CHECK_EXE=<path>       Run executable once per node before CP2K
  NUMACTL=<command>      Prefix of the executable, e.g., "numactl --preferred=1"
  HPCWL_COMMAND_PREFIX   Prefix of the executable, e.g., a debugger or profiler
  MPIRUNPREFX=<command>  Prefix of the MPI launcher
  MPIRUNFLAGS=<flags>    Additional flags of the MPI launcher

Examples:
  HPCWL_COMMAND_PREFIX="gdb -ex run -ex backtrace --args" $0 workload.inp 1
  HPCWL_COMMAND_PREFIX="aps -c mpi,omp" $0 workload.inp
  HPCWL_COMMAND_PREFIX="-gtool 'vtune -r vtune -collect hotspots:0=exclusive'" $0 workload.inp
  HPCWL_COMMAND_PREFIX="${ROOT}/multirun.sh 2" $0 workload.inp
  MPIRUNPREFX="numactl --cpunodebind=0 --membind=0 --" $0 workload.inp

EOM
  if [ -e "${EXE}" ]; then
    echo "Executable: ${EXE}"
  else
    echo "Executable: not found"
  fi
  exit 0
fi

if [ ! -e "${EXE}" ]; then
  if [ "${AMBIGUOUS}" ]; then
    >&2 echo "ERROR: several builds found, please select one with CP2K_BUILD=<folder>:"
    >&2 sed -e "s|^${ROOT}/||" -e "s|/${BIN}$||" -e "s/^/  /" <<<"${AMBIGUOUS}"
  else
    >&2 echo "ERROR: ${EXE:-cp2k.${VERSION}} executable not found (see $0 --help)!"
  fi
  exit 1
fi

# topology: sockets (NS), cores (NC), hardware threads (NT), threads per core (HT)
NS=0; NC=0; NT=0
if command -v lscpu >/dev/null; then
  CPUS=$(lscpu -p=CORE,SOCKET 2>/dev/null | grep -v "^#")
  NT=$(grep -c . <<<"${CPUS}")
  NC=$(sort -u <<<"${CPUS}" | grep -c .)
  NS=$(cut -d, -f2 <<<"${CPUS}" | sort -u | grep -c .)
elif [ -e /proc/cpuinfo ]; then
  NT=$(grep -c "^processor" /proc/cpuinfo)
  NC=$(grep -E "^(physical id|core id)" /proc/cpuinfo | paste -d, - - | sort -u | grep -c .)
  NS=$(grep "^physical id" /proc/cpuinfo | sort -u | grep -c .)
elif [ "Darwin" = "$(uname)" ]; then
  NT=$(sysctl -n hw.logicalcpu)
  NC=$(sysctl -n hw.physicalcpu)
  NS=$(sysctl -n hw.packages)
fi
if [ "0" = "${NT:-0}" ]; then NT=$(getconf _NPROCESSORS_ONLN 2>/dev/null || echo 1); fi
if [ "0" = "${NC:-0}" ]; then NC=${NT}; fi
if [ "0" = "${NS:-0}" ]; then NS=1; fi
HT=$(((NT+NC-1)/NC))  # rounded up (hybrid CPUs may have SMT on some cores only)

# MPI launcher (MPIKIND): none for a serial executable
if [[ "${VERSION}" != s* ]]; then
  if is_on "${MPICH}"; then
    MPIRUN=$(find_launcher match "HYDRA build")
  elif is_on "${IMPI}"; then
    MPIRUN=$(find_launcher match "Intel(R) MPI")
  elif [ "0" = "${IMPI}" ]; then
    MPIRUN=$(find_launcher skip "Intel(R) MPI")
  fi
  if [ ! "${MPIRUN}" ]; then
    MPIRUN=$(command -v mpirun || command -v mpiexec)
  fi
fi
if [ "${MPIRUN}" ]; then
  case "$("${MPIRUN}" --version 2>&1)" in
    *"Intel(R) MPI"*)        MPIKIND=intel ;;
    *"HYDRA build"*)         MPIKIND=mpich ;;
    *"Open MPI"*|*OpenRTE*)  MPIKIND=openmpi ;;
    *)                       MPIKIND=other ;;
  esac
elif [[ "${VERSION}" != s* ]] && command -v srun >/dev/null; then
  MPIKIND=srun
else
  MPIKIND=none
fi

# layout: ranks per node, nodes and hosts, cores (MC) and threads (MT) per rank
if [ "none" = "${MPIKIND}" ]; then
  NRANKS=${RANKS_ARG:-1}
else
  NRANKS=${RANKS_ARG:-${SLURM_NTASKS_PER_NODE%%[!0-9]*}}
  NRANKS=${NRANKS:-${NC}}
fi
if [ ! "${HOSTS}" ] && [ -e "${ROOT}/mynodes.sh" ]; then
  HOSTS=$("${ROOT}/mynodes.sh" 2>/dev/null | to_list)
fi
if [ ! "${HOSTS}" ] && [ "${SLURM_JOB_NODELIST}" ] && command -v scontrol >/dev/null; then
  HOSTS=$(scontrol show hostnames 2>/dev/null | to_list)
fi
HOSTS=$(to_list <<<"${HOSTS:-localhost}")
NUMNODES=${NODES_ARG:-${SLURM_JOB_NUM_NODES}}
NUMNODES=${NUMNODES:-$(tr ',' '\n' <<<"${HOSTS}" | grep -c .)}
HOSTS=$(cut -d, -f"1-${NUMNODES}" <<<"${HOSTS}")
NHOSTS=$(tr ',' '\n' <<<"${HOSTS}" | grep -c .)
if [ "${NUMNODES}" -gt "${NHOSTS}" ] && [ ! "${SLURM_JOB_NODELIST}" ]; then
  >&2 echo "WARNING: ${NUMNODES} nodes but only ${NHOSTS} host(s) given, ranks of several nodes share a host!"
fi
NP=$((NRANKS*NUMNODES))
if [ "none" = "${MPIKIND}" ] && [ "1" != "${NP}" ]; then
  >&2 echo "ERROR: ${NP} ranks requested but no MPI launcher found (or serial executable)!"
  exit 1
fi
MC=$((NC/NRANKS)); if [ "0" = "${MC}" ]; then MC=1; fi
MAXNT=${MAXNT:-1}
MT=$((HT<MAXNT?HT:MAXNT))

# launcher flags (MPIFLAGS), and the command to run something once per node (PERNODE)
PREFX=${HPCWL_COMMAND_PREFIX}
if [[ "${PREFX}" = "gdb "* ]] && ! command -v gdb >/dev/null && command -v gdb-oneapi >/dev/null; then
  PREFX="gdb-oneapi ${PREFX#gdb }"
fi
case "${MPIKIND}" in
  intel|mpich)
    MPIFLAGS="-ppn ${NRANKS}"
    if [ "1" != "${NHOSTS}" ] && [ ! "${SLURM_JOB_NODELIST}" ]; then
      HST="-hosts ${HOSTS}"
    fi
    if is_on "${BOOTSTRAP}"; then
      if [[ ${BOOTSTRAP} =~ ^[+-]?[0-9]+$ ]]; then HST+=" -bootstrap ssh"; else HST+=" -bootstrap ${BOOTSTRAP}"; fi
    fi
    MPIFLAGS+=" ${HST}"
    PERNODE="${MPIRUN} -ppn 1 ${HST} -np ${NUMNODES}"
    if [ "intel" = "${MPIKIND}" ]; then
      # Intel MPI pins in its launcher, but may not by default (e.g., hybrid CPU)
      if not_off "${PIN}"; then export I_MPI_PIN=${I_MPI_PIN:-1}; else export I_MPI_PIN=${I_MPI_PIN:-0}; fi
      if not_off "${VERBOSE}"; then export I_MPI_DEBUG=${I_MPI_DEBUG:-4}; fi
    elif not_off "${PIN}"; then
      MPIFLAGS+=" -bind-to core:${MC}"
    else
      MPIFLAGS+=" -bind-to none"
    fi
    # library settings (MPICH-based, i.e., Intel MPI as well)
    if is_on "${MPI_OPT}"; then
      export I_MPI_COLL_INTRANODE=${I_MPI_COLL_INTRANODE:-pt2pt}
      export I_MPI_DYNAMIC_CONNECTION=${I_MPI_DYNAMIC_CONNECTION:-1}
      export I_MPI_ADJUST_REDUCE=${I_MPI_ADJUST_REDUCE:-1}
      export I_MPI_ADJUST_BCAST=${I_MPI_ADJUST_BCAST:-1}
    fi
    if [ "1" = "${NHOSTS}" ]; then
      export I_MPI_FABRICS=${I_MPI_FABRICS:-shm}
    fi
    if [[ " ${MPIRUNFLAGS} " = *" -rdma "* ]]; then
      export MPICH_ASYNC_PROGRESS=${MPICH_ASYNC_PROGRESS:-1}
    fi
    if not_off "${I_MPI_OFFLOAD}" && ldd "${EXE}" 2>/dev/null | grep -q libOpenCL; then
      export MPICH_GPU_SUPPORT_ENABLED=${MPICH_GPU_SUPPORT_ENABLED:-1}
      export I_MPI_OFFLOAD_RDMA=${I_MPI_OFFLOAD_RDMA:-1}
      export I_MPI_OFFLOAD=${I_MPI_OFFLOAD:-1}
    else
      export I_MPI_OFFLOAD=${I_MPI_OFFLOAD:-0}
    fi
    export I_MPI_SHM_HEAP=${I_MPI_SHM_HEAP:-1}
    export MPICH_MALLOC_FALLBACK=${MPICH_MALLOC_FALLBACK:-1}
    export FI_MLX_INJECT=${FI_MLX_INJECT:-0}
    ;;
  openmpi)
    if not_off "${PIN}"; then
      MPIFLAGS="--map-by ppr:${NRANKS}:node:PE=${MC}"
    else
      MPIFLAGS="--map-by ppr:${NRANKS}:node --bind-to none"
    fi
    if [ "1" != "${NHOSTS}" ] && [ ! "${SLURM_JOB_NODELIST}" ]; then
      HST="--host $(sed "s/\([^,][^,]*\)/\1:${NRANKS}/g" <<<"${HOSTS}")"
      MPIFLAGS+=" ${HST}"
    fi
    if is_on "${OVERSUBSCRIBE}"; then MPIFLAGS+=" --oversubscribe"; fi
    if not_off "${VERBOSE}"; then MPIFLAGS+=" --report-bindings"; fi
    PERNODE="${MPIRUN} --map-by ppr:1:node ${HST} -np ${NUMNODES}"
    ;;
  srun)
    MPIFLAGS="--nodes=${NUMNODES} --ntasks-per-node=${NRANKS}"
    if not_off "${PIN}"; then
      MPIFLAGS+=" --cpus-per-task=$((MC*HT)) --cpu-bind=cores"
    else
      MPIFLAGS+=" --cpu-bind=none"
    fi
    PERNODE="srun --nodes=${NUMNODES} --ntasks-per-node=1"
    ;;
  other)
    PERNODE="${MPIRUN} -np ${NUMNODES}"
    ;;
esac

# environment
ulimit -s unlimited 2>/dev/null
ulimit -c 0 2>/dev/null
export CP2K_DATA_DIR=${CP2K_DATA_DIR:-${ROOT}/data}
export LD_LIBRARY_PATH=${EXEDIR}${LD_LIBRARY_PATH:+:${LD_LIBRARY_PATH}}
if is_on "${TBBMALLOC}" && [ -e "${TBBROOT}/lib/libtbbmalloc_proxy.so" ]; then
  export LD_PRELOAD=${TBBROOT}/lib/libtbbmalloc_proxy.so${LD_PRELOAD:+:${LD_PRELOAD}}
fi
if not_off "${TUNE}"; then
  # glibc.malloc.mmap_max=0 can cause issues (GmmLib)
  TUNABLES="glibc.malloc.trim_threshold=-1"
  if [ "x86_64" = "$(uname -m)" ]; then TUNABLES+=":glibc.cpu.hwcaps=-AVX2"; fi
  export GLIBC_TUNABLES=${GLIBC_TUNABLES:+${GLIBC_TUNABLES}:}${TUNABLES}
fi
if not_off "${VERBOSE}"; then
  export ACC_OPENCL_VERBOSE=${ACC_OPENCL_VERBOSE:-1}
  export LIBXSTREAM_VERBOSE=${LIBXSTREAM_VERBOSE:-1}
  export LIBXS_GEMM_PRINT=${LIBXS_GEMM_PRINT:-0}
fi
if not_off "${PIN}"; then  # PIN=0: threads float like the ranks
  if [ "1" = "${MT}" ]; then PLACES=cores; else PLACES=threads; fi
  export OMP_PLACES=${OMP_PLACES:-${PLACES}}
  export OMP_PROC_BIND=${OMP_PROC_BIND:-close}
fi
export OMP_NUM_THREADS=${OMP_NUM_THREADS:-$((MC*MT))}

# command: direct (no launcher, or MPI_OPT and a single rank), srun, or MPI launcher
if [ "none" = "${MPIKIND}" ] || { is_on "${MPI_OPT}" && [ "1" = "${NP}" ] && [ ! "${PREFX}" ]; }; then
  RUN="${MPIRUNPREFX} ${NUMACTL} ${PREFX} ${EXE} ${WORKLOAD} ${ARGS}"
elif [ "srun" = "${MPIKIND}" ]; then
  RUN="${MPIRUNPREFX} srun ${MPIFLAGS} ${MPIRUNFLAGS} ${NUMACTL} ${PREFX} ${EXE} ${WORKLOAD} ${ARGS}"
else
  RUN="${MPIRUNPREFX} ${MPIRUN} ${MPIFLAGS} ${MPIRUNFLAGS} -np ${NP} ${NUMACTL} ${PREFX} ${EXE} ${WORKLOAD} ${ARGS}"
fi

# report
if [ "${WORKLOAD}" ]; then cd "$(dirname "${WORKLOAD}")" || exit 1; fi
if command -v sinfo >/dev/null; then
  NODEINFO=$(sinfo -N -n "$(hostname)" --noheader -o "%P %f" 2>/dev/null | head -n1)
fi
if [ "${NODEINFO}" ]; then
  echo "HOSTINFO: $(sed "s/..* ,*//" <<<"${NODEINFO}")"
  echo "PARTITION: $(sed "s/ .*//" <<<"${NODEINFO}")"
fi
echo
if not_off "${VERBOSE}"; then
  echo "OMP: NS=${NS} NC=${NC} NT=${NT} HT=${HT} MAXNT=${MAXNT} MT=${MT} MC=${MC} MPI=${MPIKIND}"
  echo "EXE: ${EXE}"
  ldd "${EXE}" 2>/dev/null
  echo
  ENVPAT="^LD_PRELOAD\|^GLIBC_\|^LIBXS\|^CUDA_\|^DBCSR_\|^ACC_\|^DBM_\|^MKL\|^OPENCL_\|^[^ _].*=[0-9][0-9]*$"
  ENVPAT+="\|^SLURM_\|^I_MPI_\|^PMI_\|^MPICH_\|^PSM3_\|^FI_\|^OMPI_\|^UCX_\|^OMP_\|^KMP_\|^ZEX_\|^IGC_"
  env | grep "${ENVPAT}" | sort
  echo "PWD=${PWD}"
  ENVGEN=$(command -v iga64)
  if [ "${ENVGEN}" ]; then echo "GEN=$(cd "$(dirname "${ENVGEN}")/../.." 2>/dev/null && pwd -P)"; fi
  echo
fi

# check and prolog (once per node)
if [ "${CHECK_EXE}" ] && [ -e "${CHECK_EXE}" ]; then
  echo "*** CHECK ***"
  eval "${PERNODE} ${CHECK_EXE} 2>/dev/null"
  echo "*************"
fi
if is_on "${PROLOG:-${CHECK}}"; then
  echo "*** PROLOG ***"
  if command -v numactl >/dev/null; then
    eval "${PERNODE} numactl -H 2>/dev/null"
    echo
  fi
  if command -v clinfo >/dev/null; then
    eval "${PERNODE} clinfo -l 2>/dev/null"
  fi
  echo "**************"
fi

# run
tr -s " " <<<"${RUN}" | sed "s/^ //;s/ $//"
echo
eval "${RUN}"
RESULT=$?

# epilog (once per node)
if is_on "${EPILOG:-${CHECK}}"; then
  echo "*** EPILOG ***"
  if command -v clinfo >/dev/null; then
    eval "${PERNODE} clinfo -l 2>/dev/null"
  fi
  echo "**************"
fi
exit ${RESULT}
