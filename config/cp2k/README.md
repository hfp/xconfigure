# CP2K<a name="cp2k-open-source-molecular-dynamics"></a>

This document describes building CP2K with several (optional) libraries, which may be beneficial in terms of functionality and performance.

* Intel Math Kernel Library (also per Linux' distro's package manager) acts as:
    * LAPACK/BLAS and ScaLAPACK library
    * FFTw library
* [LIBXSMM](https://github.com/hfp/libxsmm) (replaces LIBSMM)
* [LIBINT](../libint/README.md#libint) (version 1.1.5 or 1.1.6)
* [LIBXC](../libxc/README.md#libxc) (version 4.3 or any 4.x)
* [ELPA](../elpa/README.md#eigenvalue-solvers-for-petaflop-applications-elpa) (version 2017.11.001)

The ELPA library eventually improves the performance (must be currently enabled for each input file even if CP2K was built with ELPA). There is also the option to auto-tune additional routines in CP2K (integrate/collocate) and to collect the generated code into an archive referred as LIBGRID.

For high performance, [LIBXSMM](../libxsmm/README.md#libxsmm) (see also [https://libxsmm.readthedocs.io](https://libxsmm.readthedocs.io)) has been incorporated since [CP2K&#160;3.0](https://www.cp2k.org/version_history). When CP2K is built with LIBXSMM, CP2K's "libsmm" library is not used and hence libsmm does not need to be built and linked with CP2K.

## Getting Started<a name="build-and-run-instructions"></a>

There are no configuration wrapper scripts provided for CP2K since a configure-step is usually not required, and the application can be built right away. CP2K's `install_cp2k_toolchain.sh` (under `tools/toolchain`) is out of scope in this document (it builds the entire tool chain from source including the compiler).

Although there are no configuration wrapper scripts for CP2K, below command delivers e.g., an [info-script](#performance) and a script for [planning](#plan-script) CP2K execution:

```bash
wget --no-check-certificate https://github.com/hfp/xconfigure/raw/master/configure-get.sh
chmod +x configure-get.sh
./configure-get.sh cp2k
```

<a name="info-script"></a>Of course, the scripts can be also download manually:

```bash
wget --no-check-certificate https://github.com/hfp/xconfigure/raw/master/config/cp2k/info.sh
chmod +x info.sh
wget --no-check-certificate https://github.com/hfp/xconfigure/raw/master/config/cp2k/plan.sh
chmod +x plan.sh
```

## Step-by-step Guide<a name="build-an-official-release"></a>

<a name="getting-the-source-code"></a>This step-by-step guide aims to build an MPI/OpenMP-hybrid version of the official release of CP2K by using the GNU Compiler Collection, Intel MPI, Intel MKL, LIBXSMM, ELPA, LIBXC, and LIBINT. Internet connectivity is assumed on the build-system. Please note that such limitations can be worked around or avoided with additional steps. However, this simple step-by-step guide aims to make some reasonable assumptions.

As the step-by-step guide uses GNU Fortran (version 7.x or 8.x is recommended), only Intel MKL (2019.x recommended) and Intel MPI (2018.x recommended) need to be sourced (sourcing all Intel development tools of course does not harm).

```bash
source /opt/intel/compilers_and_libraries_2018.5.274/linux/mpi/intel64/bin/mpivars.sh
source /opt/intel/compilers_and_libraries_2019.3.199/linux/mkl/bin/mklvars.sh intel64
```

To install Intel Math Kernel Library and Intel MPI from a public repository depends on the Linux distribution's package manager. For newer distributions, both libraries are likely part of the official repositories. Otherwise a suitable repository must be added to the package manager (not subject of this document). For example, installing with `yum` looks like:

```bash
sudo yum install intel-mkl-2019.4-070.x86_64
sudo yum install intel-mpi-2018.3-051.x86_64
```

Please note, the ARCH file (used later/below to build CP2K) attempts to find Intel MKL even if the `MKLROOT` environment variable is not present. The MPI library is implicitly known when using compiler wrapper scripts (no need for `I_MPI_ROOT`). Installing the proper software stack and drivers for an HPC fabric to be used by MPI is out of scope in this document. If below checks fails, the MPI's bin-folder must be added to the path.

```text
$ mpif90 --version
  GNU Fortran (GCC) 8.2.0
  Copyright (C) 2018 Free Software Foundation, Inc.
  This is free software; see the source for copying conditions.  There is NO
  warranty; not even for MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
```

<a name="eigenvalue-solvers-for-petaflop-applications-elpa"></a>The first step builds ELPA. Do not use an ELPA-version newer than 2017.11.001.

```bash
cd $HOME
wget https://elpa.mpcdf.mpg.de/html/Releases/2017.11.001/elpa-2017.11.001.tar.gz
tar xvf elpa-2017.11.001.tar.gz
cd elpa-2017.11.001
wget --no-check-certificate https://github.com/hfp/xconfigure/raw/master/configure-get.sh
chmod +x configure-get.sh
./configure-get.sh elpa
./configure-elpa-skx-gnu-omp.sh
make -j
make install
make clean
```

<a name="libint-and-libxc-dependencies"></a>The second step builds LIBINT (1.1.6 recommended, newer version cannot be used). This library does not compile on an architecture with less CPU-features than the target (e.g., `configure-libint-skx-gnu.sh` implies to build on Skylake or Cascadelake server).

```bash
cd $HOME
wget --no-check-certificate https://github.com/evaleev/libint/archive/release-1-1-6.tar.gz
tar xvf release-1-1-6.tar.gz
cd libint-release-1-1-6
wget --no-check-certificate https://github.com/hfp/xconfigure/raw/master/configure-get.sh
chmod +x configure-get.sh
./configure-get.sh libint
./configure-libint-skx-gnu.sh
make -j
make install
make distclean
```

The third step builds LIBXC (any version of the 4.x series can be used).

```bash
cd $HOME
wget --content-disposition http://www.tddft.org/programs/octopus/down.php?file=libxc/4.3.4/libxc-4.3.4.tar.gz
tar xvf libxc-4.3.4.tar.gz
cd libxc-4.3.4
wget --no-check-certificate https://github.com/hfp/xconfigure/raw/master/configure-get.sh
chmod +x configure-get.sh
./configure-get.sh libxc
./configure-libxc-skx-gnu.sh
make -j
make install
make distclean
```

The fourth step makes LIBXSMM available, which is compiled as part of the next step.

```bash
cd $HOME
wget --no-check-certificate https://github.com/hfp/libxsmm/archive/1.12.1.tar.gz
tar xvf 1.12.1.tar.gz
```

This last step builds the PSMP-variant of CP2K. Please re-download the ARCH-files from GitHub as mentioned below (avoid reusing older/outdated files). If Intel MKL is not found, the key `MKLROOT=/path/to/mkl` can be added to Make's command line. To select a different MPI implementation one can try e.g., `MKL_MPIRTL=openmpi` (experimental: `patch -p0 src/mpiwrap/message_passing.F mpi-wrapper.diff`).

```bash
cd $HOME
wget https://github.com/cp2k/cp2k/archive/v6.1.0.tar.gz
tar xvf v6.1.0.tar.gz
cd cp2k-6.1.0
wget --no-check-certificate https://github.com/hfp/xconfigure/raw/master/configure-get.sh
chmod +x configure-get.sh
./configure-get.sh cp2k
patch -p0 src/pw/fft/fftw3_lib.F intel-mkl.diff
rm -rf exe lib obj
cd makefiles
make ARCH=Linux-x86-64-intelx VERSION=psmp GNU=1 AVX=3 MIC=0 \
  LIBINTROOT=$HOME/libint/gnu-skx \
  LIBXCROOT=$HOME/libxc/gnu-skx \
  ELPAROOT=$HOME/elpa/gnu-skx-omp -j
```

The CP2K executable should be now ready (`exe/Linux-x86-64-intelx/cp2k.psmp`). A quick check may look like:

```text
$ LIBXSMM_VERBOSE=1 exe/Linux-x86-64-intelx/cp2k.psmp
  [...]
  LIBXSMM_VERSION: release-1.12.1 (23085056)
  LIBXSMM_TARGET: skx
```

Have a look at [Running CP2K](#running-cp2k) to learn more about pinning MPI processes (and OpenMP threads), and to try a first workload.

## Intel Compiler<a name="build-instructions"></a>

<a name="recommended-intel-compiler"></a>Below are the releases of the Intel Compiler, which are known to reproduce correct results according to the regression tests:

* Intel Compiler&#160;2017 (u0, u1, u2, u3), *and* the **initial** release of MKL&#160;2017 (u0)
    * source /opt/intel/compilers_and_libraries_2017.[*u0-u3*]/linux/bin/compilervars.sh intel64  
      source /opt/intel/compilers_and_libraries_2017.0.098/linux/mkl/bin/mklvars.sh intel64
* Intel Compiler&#160;2017 Update&#160;4, and any later update of the 2017 suite (u4, u5, u6, u7)
    * source /opt/intel/compilers_and_libraries_2017.[*u4-u7*]/linux/bin/compilervars.sh intel64
* Intel Compiler&#160;2018 (u3, u4, u5): only with CP2K/development (not with CP2K&#160;6.1 or earlier)
    * source /opt/intel/compilers_and_libraries_2018.3.222/linux/bin/compilervars.sh intel64
    * source /opt/intel/compilers_and_libraries_2018.5.274/linux/bin/compilervars.sh intel64
* Intel Compiler&#160;2019 (u1, u2, u3): failure at runtime
* Intel MPI; usually any version is fine: Intel MPI 2018 is recommended

Please note, with respect to component versions it is possible to source from different Intel suites.

## Intel ARCH File

CP2K&#160;6.1 includes `Linux-x86-64-intel.*` (`arch` directory) as a starting point for writing an own ARCH-file (note: `Linux-x86-64-intel.*` vs. `Linux-x86-64-intelx.*`). Remember, performance critical code is often located in libraries (hence `-O2` optimizations for CP2K's source code are enough in almost all cases), more important for performance are target-flags such as `-march=native` (`-xHost`) or `-mavx2 -mfma`. Prior to Intel Compiler 2018, the flag `-fp-model source` (FORTRAN) and `-fp-model precise` (C/C++) were key for passing CP2K's regression tests. If an own ARCH file is used or prepared, all libraries including LIBXSMM need to be built separately and referred in the link-line of the ARCH-file. In addition, CP2K may need to be informed and certain preprocessor symbols need to be given during compilation (`-D` compile flag). For further information, please follow the [official guide](https://www.cp2k.org/howto:compile) and consider the [CP2K Forum](https://groups.google.com/forum/#!forum/cp2k) in case of trouble.

The purpose of the Intel ARCH files is to avoid writing an own ARCH-file even when GNU Compiler is used. Taking the Intel ARCH files that are part of the CP2K/Intel fork automatically picks up the correct paths for Intel libraries. These paths are determined by using the environment variables setup when the Intel tools are source'd. Similarly, LIBXSMMROOT (which can be supplied on Make's command line) is discovered automatically if it is in the user's home directory, or when it is in parallel to the CP2K directory. The Intel ARCH files not only work with CP2K/Intel fork but even if an official release of CP2K is built (which is also encouraged). Of course, one can download the afore mentioned Intel ARCH files manually<a name="get-the-arch-files"></a>:

```bash
cd cp2k-6.1.0/arch
wget https://github.com/hfp/cp2k/raw/master/arch/Linux-x86-64-intelx.arch
wget https://github.com/hfp/cp2k/raw/master/arch/Linux-x86-64-intelx.popt
wget https://github.com/hfp/cp2k/raw/master/arch/Linux-x86-64-intelx.psmp
wget https://github.com/hfp/cp2k/raw/master/arch/Linux-x86-64-intelx.sopt
wget https://github.com/hfp/cp2k/raw/master/arch/Linux-x86-64-intelx.ssmp
```

## Running CP2K<a name="run-instructions"></a>

<a name="running-the-application"></a>Running CP2K may go beyond a single node, and pinning processes and threads becomes even more important. There are several schemes available. As a rule of thumb, a high rank-count for lower node-counts may yield best results unless the workload is very memory intensive. In the latter case, lowering the number of MPI-ranks per node is effective especially if a larger amount of memory is replicated rather than partitioned by the rank-count. In contrast (communication bound), a lower rank count for multi-node computations may be desired.

<a name="plan-script"></a>Most important, in most cases CP2K prefers a total rank-count to be a square-number which leads to some complexity when aiming for rank/thread combinations that exhibit good performance properties. Please refer to the [documentation](plan.md) of the script for planning MPI/OpenMP-hybrid (`plan.sh`), which illustrates running CP2K's PSMP-binary on an HT-enabled dual-socket system with 24&#160;cores per processor/socket (96&#160;hardware threads). The single-node execution with 16&#160;ranks and 6&#160;threads per rank looks like (`1x16x6`):

```bash
mpirun -np 16 \
  -genv I_MPI_PIN_DOMAIN=auto -genv I_MPI_PIN_ORDER=bunch \
  -genv OMP_PLACES=threads -genv OMP_PROC_BIND=SPREAD \
  -genv OMP_NUM_THREADS=6 \
  exe/Linux-x86-64-intelx/cp2k.psmp workload.inp
```

For an MPI command line targeting 8&#160;nodes, `plan.sh` was used to setup 8&#160;ranks per node with 12&#160;threads per rank (`8x8x12`):

```bash
mpirun -perhost 8 -host node1,node2,node3,node4,node5,node6,node7,node8 \
  -genv I_MPI_PIN_DOMAIN=auto -genv I_MPI_PIN_ORDER=bunch \
  -genv OMP_PLACES=threads -genv OMP_PROC_BIND=SPREAD \
  -genv OMP_NUM_THREADS=12 -genv I_MPI_DEBUG=4 \
  exe/Linux-x86-64-intelx/cp2k.psmp workload.inp
```

**NOTE**: the [documentation](plan.md) of `plan.sh` also motivates and explains the MPI environment variables as shown in above MPI command lines.

## Performance

The [script](#plan-script) for planning MPI-execution (`plan.sh`) is highly recommend along with reading the section about [how to run CP2K](#run-instructions). For CP2K, the MPI-communication patterns can be tuned in most MPI-implementations. For Intel MPI, the following setting can be beneficial:

```bash
export I_MPI_COLL_INTRANODE=pt2pt
export I_MPI_ADJUST_REDUCE=1
export I_MPI_ADJUST_BCAST=1
```

For large-scale runs, the startup can be tuned, but typically this is not necessary. However, the following may be useful (and does not harm):

```bash
export I_MPI_DYNAMIC_CONNECTION=1
export I_MPI_HARD_FINALIZE=1
```

Intel MPI usually nicely determines the fabric settings for both Omnipath and Infiniband, and no adjustment is needed. However, people often prefer explicit settings even if it does not differ from what is determined automatically. For example, Infiniband with RDMA can be set explicitly by using `mpirun -rdma` which can be also achieved with environment variables:

```bash
echo "'mpirun -rdma' and/or environment variables for Infiniband"
export I_MPI_FABRICS=shm:dapl
export I_MPI_RDMA_TRANSLATION_CACHE=1
export I_MPI_CHECK_DAPL_PROVIDER_COMPATIBILITY=0
```

As soon as several experiments are finished, it becomes handy to summarize the log-output. For this case, an info-script (`info.sh`) is [available](#info-script) attempting to present a table (summary of all results), which is generated from log files (use `tee`, or rely on the output of the job scheduler). There are only certain file extensions supported (`.txt`, `.log`). If no file matches, then all files (independent of the file extension) are attempted to be parsed (which will go wrong eventually). If for some reason the command to launch CP2K is not part of the log and the run-arguments cannot be determined otherwise, the number of nodes is eventually parsed by using the filename of the log itself (e.g., first occurrence of a number along with an optional "n" is treated as the number of nodes used for execution).

```text
./run-cp2k.sh | tee cp2k-h2o64-2x32x2.txt
ls -1 *.txt
cp2k-h2o64-2x32x2.txt
cp2k-h2o64-4x16x2.txt

./info.sh [-best] /path/to/logs-or-cwd
H2O-64            Nodes R/N T/R Cases/d Seconds
cp2k-h2o64-2x32x2 2      32   4     807 107.237
cp2k-h2o64-4x16x2 4      16   8     872  99.962
```

Please note that the "Cases/d" metric is calculated with integer arithmetic and hence represents fully completed cases per day (based on 86400 seconds per day). The number of seconds (as shown) is end-to-end (wall time), i.e. total time to solution including any (sequential) phase (initialization, etc.). Performance is higher if the workload requires more iterations (some publications present a metric based on iteration time).

## Sanity Check

There is nothing that can replace the full regression test suite. However, to quickly check whether a build is sane or not, one can run for instance `tests/QS/benchmark/H2O-64.inp` and check if the SCF iteration prints like the following:

```text
  Step     Update method      Time    Convergence         Total energy    Change
  ------------------------------------------------------------------------------
     1 OT DIIS     0.15E+00    0.5     0.01337191     -1059.6804814927 -1.06E+03
     2 OT DIIS     0.15E+00    0.3     0.00866338     -1073.3635678409 -1.37E+01
     3 OT DIIS     0.15E+00    0.3     0.00615351     -1082.2282197787 -8.86E+00
     4 OT DIIS     0.15E+00    0.3     0.00431587     -1088.6720379505 -6.44E+00
     5 OT DIIS     0.15E+00    0.3     0.00329037     -1092.3459788564 -3.67E+00
     6 OT DIIS     0.15E+00    0.3     0.00250764     -1095.1407783214 -2.79E+00
     7 OT DIIS     0.15E+00    0.3     0.00187043     -1097.2047924571 -2.06E+00
     8 OT DIIS     0.15E+00    0.3     0.00144439     -1098.4309205383 -1.23E+00
     9 OT DIIS     0.15E+00    0.3     0.00112474     -1099.2105625375 -7.80E-01
    10 OT DIIS     0.15E+00    0.3     0.00101434     -1099.5709299131 -3.60E-01
    [...]
```

The column called "Convergence" must monotonically converge towards zero.

## Development<a name="build-the-cp2kintel-branch"></a>

<a name="build-the-intel-fork-of-cp2k"></a>The [Intel fork of CP2K](https://github.com/hfp/cp2k.git) was formerly a branch of CP2K's Git-mirror. CP2K is meanwhile natively hosted at GitHub. Ongoing work in the Intel branch was supposed to tightly track the master version of CP2K, which is also true for the fork. In addition, valuable topics may be upstreamed in a timelier fashion. To build [CP2K/Intel](https://github.com/hfp/cp2k.git) from source for experimental purpose, one may rely on [Intel Compiler 16, 17, or 18 series](#recommended-intel-compiler):

```bash
source /opt/intel/compilers_and_libraries_2018.3.222/linux/bin/compilervars.sh intel64
```

LIBXSMM is automatically built in an out-of-tree fashion when building CP2K/Intel fork. The only prerequisite is that the LIBXSMMROOT path needs to be detected (or supplied on the `make` command line). LIBXSMMROOT is automatically discovered automatically if it is in the user's home directory, or when it is in parallel to the CP2K directory. By default (no `AVX` or `MIC` is given), the build process is carried out by using the `-xHost` target flag. For example, to explicitly target "Skylake" (SKX):

```bash
git clone https://github.com/hfp/libxsmm.git
git clone https://github.com/hfp/cp2k.git
cd cp2k; rm -rf exe lib obj
make ARCH=Linux-x86-64-intelx VERSION=psmp AVX=3 MIC=0
```

Most if not all hot-spots in CP2K are covered by libraries (e.g., LIBXSMM). It can be beneficial to rely on the GNU Compiler tool-chain. To only use Intel libraries such as Intel MPI and Intel MKL, one can rely on the GNU-key (`GNU=1`):

```bash
git clone https://github.com/hfp/libxsmm.git
git clone https://github.com/hfp/cp2k.git
cd cp2k; rm -rf exe lib obj
make ARCH=Linux-x86-64-intelx VERSION=psmp AVX=3 MIC=0 GNU=1
```

The GNU tool-chain requires to configure LIBINT, LIBXC, and ELPA accordingly (e.g., `configure-elpa-skx-gnu-omp.sh` instead of `configure-elpa-skx-omp.sh`). To further adjust CP2K at build time, additional key-value pairs (like `ARCH=Linux-x86-64-intelx` or `VERSION=psmp`) can be passed at Make's command line when relying on CP2K/Intel's ARCH files.

* **SYM**: set `SYM=1` to include debug symbols into the executable e.g., helpful with performance profiling.
* **DBG**: set `DBG=1` to include debug symbols, and to generate non-optimized code.

<a name="memory-allocation"></a>Dynamic allocation of heap memory usually requires global book keeping eventually incurring overhead in shared-memory parallel regions of an application. For this case, specialized allocation strategies are available. To use such a strategy, memory allocation wrappers can be used to replace the default memory allocation at build-time or at runtime of an application.

To use the malloc-proxy of the Intel Threading Building Blocks (Intel TBB), rely on the `TBBMALLOC=1` key-value pair at build-time of CP2K (default: `TBBMALLOC=0`). Usually, Intel TBB is already available when sourcing the Intel development tools (one can check the TBBROOT environment variable). To use TCMALLOC as an alternative, set `TCMALLOCROOT` at build-time of CP2K by pointing to TCMALLOC's installation path (configured per `./configure --enable-minimal --prefix=<TCMALLOCROOT>`).

## References

[https://nholmber.github.io/2017/04/cp2k-build-cray-xc40/](https://nholmber.github.io/2017/04/cp2k-build-cray-xc40/)  
[https://xconfigure.readthedocs.io/cp2k/plan/](https://xconfigure.readthedocs.io/cp2k/plan/)  
[https://www.cp2k.org/howto:compile](https://www.cp2k.org/howto:compile)

