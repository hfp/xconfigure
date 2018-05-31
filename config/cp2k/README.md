# CP2K<a name="cp2k-open-source-molecular-dynamics"></a>

This document focuses on building and running the [Intel branch of CP2K](https://github.com/cp2k/cp2k/tree/intel). However, it applies to CP2K in general (unless emphasized). The Intel branch is hosted at GitHub and is supposed to represent the master version of CP2K in a timely fashion. <a name="getting-the-source-code"></a>CP2K's main repository is hosted at SourceForge but it is automatically mirrored at GitHub. The LIBXSMM library can be found at [https://github.com/hfp/libxsmm](https://libxsmm.readthedocs.io). In terms of functionality (and performance) it is beneficial to rely on [LIBINT](../libint/README.md#libint) and [LIBXC](../libxc/README.md#libxc), whereas [ELPA](../elpa/README.md#eigenvalue-solvers-for-petaflop-applications-elpa) eventually improves the performance. For high performance, it is strongly recommended to use [LIBXSMM](../libxsmm/README.md#libxsmm) which has been incorporated since [CP2K&#160;3.0](https://www.cp2k.org/version_history). LIBXSMM is intended to substitute CP2K's "libsmm" library.

<a name="recommended-intel-compiler"></a>There are below Intel compiler releases (one can combine components from different versions), which are known to reproduce correct results (regression tests):

* Intel Compiler 2017 (u0, u1, u2, u3), *and* the **initial** release of MKL&#160;2017 (u0)
    * source /opt/intel/compilers_and_libraries_2017.[*whatever*]/linux/bin/compilervars.sh intel64
    * source /opt/intel/compilers_and_libraries_2017.0.098/linux/mkl/bin/mklvars.sh intel64
* Intel Compiler 2017 Update 4, and any later update of the 2017 suite (u4, u5, u6)
    * source /opt/intel/compilers_and_libraries_2017.4.196/linux/bin/compilervars.sh intel64
    * source /opt/intel/compilers_and_libraries_2017.5.239/linux/bin/compilervars.sh intel64
    * source /opt/intel/compilers_and_libraries_2017.6.256/linux/bin/compilervars.sh intel64
* Intel Compiler&#160;2018 suite is not validated (and fails at runtime)
* Intel MPI; usually any version is fine

There are no configuration wrapper scripts provided for CP2K, please follow below recipe. However, attempting to run below command yields an [info-script](#performance):

```bash
wget --no-check-certificate https://github.com/hfp/xconfigure/raw/master/configure-get.sh
chmod +x configure-get.sh
./configure-get.sh cp2k
```

<a name="info-script"></a>Of course, the above can be simplified:

```bash
wget --no-check-certificate https://github.com/hfp/xconfigure/raw/master/config/cp2k/info.sh
chmod +x info.sh
```

## Build Instructions<a name="build-and-run-instructions"></a>

### Build the CP2K/Intel Branch

To build [CP2K/Intel](https://github.com/cp2k/cp2k/tree/intel) from source, one may rely on Intel Compiler 16 or 17 series (the 2018 version may be supported at a later point in time). For the Intel Compiler&#160;2017 prior to Update&#160;4, one should source the compiler followed by sourcing a specific version of Intel&#160;MKL (to avoid an issue in Intel&#160;MKL):

```bash
source /opt/intel/compilers_and_libraries_2017.3.191/linux/bin/compilervars.sh intel64
source /opt/intel/compilers_and_libraries_2017.0.098/linux/mkl/bin/mklvars.sh intel64
```

Since Update&#160;4 of the 2017-suite, the compiler and libraries can be used right away (see [recommended](#recommended-intel-compiler) compiler):

```bash
source /opt/intel/compilers_and_libraries_2017.6.256/linux/bin/compilervars.sh intel64
```

LIBXSMM is automatically built in an out-of-tree fashion when building CP2K/Intel branch. The only prerequisite is that the LIBXSMMROOT path needs to be detected (or supplied on the `make` command line). A recipe targeting "Haswell" (HSW) may look like:

```bash
git clone https://github.com/hfp/libxsmm.git
git clone --branch intel https://github.com/cp2k/cp2k.git cp2k.git
ln -s cp2k.git/cp2k cp2k
cd cp2k/makefiles
make ARCH=Linux-x86-64-intelx VERSION=psmp AVX=2
```

To target "Knights Landing" (KNL), use "AVX=3 MIC=1" instead of "AVX=2". Similarly, the Intel&#160;Xeon Scalable processor "Skylake Server" (SKX) goes with "AVX=3 MIC=0".

To further adjust CP2K at build time of the application, additional key-value pairs can be passed at make's command line (like `ARCH=Linux-x86-64-intelx` or `VERSION=psmp`).

* **SYM**: set `SYM=1` to include debug symbols into the executable e.g., helpful with performance profiling.
* **DBG**: set `DBG=1` to include debug symbols, and to generate non-optimized code.

To further improve performance and versatility, one may supply LIBINTROOT, LIBXCROOT, and ELPAROOT when relying on CP2K/Intel's ARCH files (see later sections about these libraries).

### Build an Official Release

Since [CP2K&#160;3.0](https://www.cp2k.org/version_history), the mainline version (non-Intel branch) also supports LIBXSMM. CP2K&#160;6.1 includes `Linux-x86-64-intel.*` (`arch` directory) as a starting point for an own ARCH-file. Remember, performance is mostly related to libraries (`-O2` optimizations are sufficient in any case), more important for performance are target-flags such as `-xHost`. However, the flag `-fp-model source` (FORTRAN) and `-fp-model precise` (C/C++) are key for passing CP2K's regression tests. Please follow the [official guide](https://www.cp2k.org/howto:compile) and consider the [CP2K Forum](https://groups.google.com/forum/#!forum/cp2k) in case of trouble. If an own ARCH file is used or prepared, the LIBXSMM library needs to be built separately. Building LIBXSMM is rather simple; to build the master revision:

```bash
git clone https://github.com/hfp/libxsmm.git
cd libxsmm ; make
```

To build an official [release](https://github.com/hfp/libxsmm/releases):

```bash
wget https://github.com/hfp/libxsmm/archive/1.9.tar.gz
tar xvf 1.9.tar.gz
cd libxsmm-1.9 ; make
```

To [download](https://www.cp2k.org/download) and [build](https://www.cp2k.org/howto:compile) an official [CP2K release](https://sourceforge.net/projects/cp2k/files/), one can still use the ARCH files that are part of the CP2K/Intel branch. In this case, LIBXSMM is also built implicitly. Please note, that LIBXSMMROOT (which can be supplied on make's command line) is discovered automatically if it is located in the user's home directory, or when it is located in parallel to the CP2K sources (as shown below).

```bash
git clone https://github.com/hfp/libxsmm.git
wget https://sourceforge.net/projects/cp2k/files/cp2k-5.1.tar.bz2
tar xvf cp2k-5.1.tar.bz2
cd cp2k-5.1/arch
wget https://github.com/cp2k/cp2k/raw/intel/cp2k/arch/Linux-x86-64-intelx.arch
wget https://github.com/cp2k/cp2k/raw/intel/cp2k/arch/Linux-x86-64-intelx.popt
wget https://github.com/cp2k/cp2k/raw/intel/cp2k/arch/Linux-x86-64-intelx.psmp
wget https://github.com/cp2k/cp2k/raw/intel/cp2k/arch/Linux-x86-64-intelx.sopt
wget https://github.com/cp2k/cp2k/raw/intel/cp2k/arch/Linux-x86-64-intelx.ssmp
cd ../makefiles
source /opt/intel/compilers_and_libraries_2017.6.256/linux/bin/compilervars.sh intel64
make ARCH=Linux-x86-64-intelx VERSION=psmp AVX=2
```

To further improve performance and versatility, one may supply LIBINTROOT, LIBXCROOT, and ELPAROOT when relying on CP2K/Intel's ARCH files (see the following section about these libraries).

### LIBINT, LIBXC<a name="libint-and-libxc-dependencies"></a>, and ELPA<a name="eigenvalue-solvers-for-petaflop-applications-elpa"></a>

To configure, build, and install LIBINT (version&#160;1.1.5 and 1.1.6 have been tested), one can proceed with [https://xconfigure.readthedocs.io/libint/README/](../libint/README.md#libint). Also note there is no straightforward way to cross-compile LIBINT&#160;1.1.x for an instruction set extension that is not supported by the compiler host. To incorporate LIBINT into CP2K, the key `LIBINTROOT=/path/to/libint` needs to be supplied when using CP2K/Intel's ARCH files (make).

To configure, build, and install LIBXC (version&#160;3.0.0 has been tested), and one can proceed with [https://xconfigure.readthedocs.io/libxc/README/](../libxc/README.md#libxc). To incorporate LIBXC into CP2K, the key `LIBXCROOT=/path/to/libxc` needs to be supplied when using CP2K/Intel's ARCH files (make). After CP2K&#160;5.1, only the latest major release of LIBXC (by the time of the CP2K-release) will be supported (e.g., LIBXC&#160;4.x by the time of CP2K&#160;6.1).

To configure, build, and install the Eigenvalue SoLvers for Petaflop-Applications (ELPA), one can proceed with [https://xconfigure.readthedocs.io/libint/README/](../elpa/README/). To incorporate ELPA into CP2K, the key `ELPAROOT=/path/to/elpa` needs to be supplied when using CP2K/Intel's ARCH files (make). The Intel-branch defaults to ELPA-2017.05 (earlier versions can rely on the ELPA key-value pair e.g., `ELPA=201611`).

```bash
make ARCH=Linux-x86-64-intelx VERSION=psmp ELPAROOT=/path/to/elpa/default-arch
```

At runtime, a build of the Intel-branch supports an environment variable CP2K_ELPA:

* **CP2K_ELPA=-1**: requests ELPA to be enabled; the actual kernel type depends on the ELPA configuration.
* **CP2K_ELPA=0**: ELPA is not enabled by default (only on request via input file); same as non-Intel branch.
* **CP2K_ELPA**=&lt;not-defined&gt;: requests ELPA-kernel according to CPUID (default with CP2K/Intel-branch).

### Memory Allocation

Dynamic allocation of heap memory usually requires global book keeping eventually incurring overhead in shared-memory parallel regions of an application. For this case, specialized allocation strategies are available. To use such a strategy, memory allocation wrappers can be used to replace the default memory allocation at build-time or at runtime of an application.

To use the malloc-proxy of the Intel Threading Building Blocks (Intel TBB), rely on the `TBBMALLOC=1` key-value pair at build-time of CP2K. Usually, Intel TBB is already available when sourcing the Intel development tools (one can check the TBBROOT environment variable). To use TCMALLOC as an alternative, set `TCMALLOCROOT` at build-time of CP2K by pointing to TCMALLOC's installation path (configured per `./configure --enable-minimal --prefix=<TCMALLOCROOT>`).

## Run Instructions<a name="running-the-application"></a>

Running the application may go beyond a single node, however for first example the pinning scheme and thread affinization is introduced.
As a rule of thumb, a high rank-count for single-node computation (perhaps according to the number of physical CPU cores) may be preferred. In contrast (communication bound), a lower rank count for multi-node computations may be desired. In general, CP2K prefers the total rank-count to be a square-number (two-dimensional communication pattern) rather than a Power-of-Two (POT) number.

Running an MPI/OpenMP-hybrid application, an MPI rank-count that is half the number of cores might be a good starting point (below command could be for an HT-enabled dual-socket system with 16 cores per processor and 64 hardware threads).

```bash
mpirun -np 16 \
  -genv I_MPI_PIN_DOMAIN=auto -genv I_MPI_PIN_ORDER=bunch \
  -genv KMP_AFFINITY=compact,granularity=fine,1 \
  -genv OMP_NUM_THREADS=4 \
  cp2k/exe/Linux-x86-64-intelx/cp2k.psmp workload.inp
```

For an actual workload, one may try `cp2k/tests/QS/benchmark/H2O-32.inp`, or for example the workloads under `cp2k/tests/QS/benchmark_single_node` which are supposed to fit into a single node (in fact to fit into 16 GB of memory). For the latter set of workloads (and many others), LIBINT and LIBXC may be required.

The CP2K/Intel branch carries several "reconfigurations" and environment variables, which allow to adjust important runtime options. Most of these options are also accessible via the input file format (input reference e.g., [https://manual.cp2k.org/trunk/CP2K_INPUT/GLOBAL/DBCSR.html](https://manual.cp2k.org/trunk/CP2K_INPUT/GLOBAL/DBCSR.html)).

* **CP2K_RECONFIGURE**: environment variable for reconfiguring CP2K (default depends on whether the ACCeleration layer is enabled or not). With the ACCeleration layer enabled, CP2K is reconfigured (as if CP2K_RECONFIGURE=1 is set) e.g. an increased number of entries per matrix stack is populated, and otherwise CP2K is not reconfigured. Further, setting CP2K_RECONFIGURE=0 is disabling the code specific to the [Intel branch of CP2K](https://github.com/cp2k/cp2k/tree/intel), and relies on the (optional) LIBXSMM integration into [CP2K&#160;3.0](https://www.cp2k.org/version_history) (and later).
* **CP2K_STACKSIZE**: environment variable which denotes the number of matrix multiplications which is collected into a single stack. Usually the internal default performs best across a variety of workloads, however depending on the workload a different value can be better. This variable is relatively impactful since the work distribution and balance is affected.
* **CP2K_HUGEPAGES**: environment variable for disabling (0) huge page based memory allocation, which is enabled by default (if TBBROOT was present at build-time of the application).
* **CP2K_RMA**: enables (1) an experimental Remote Memory Access (RMA) based multiplication algorithm (requires MPI3).
* **CP2K_SORT**: enables (1) an indirect sorting of each multiplication stack according to the C-index (experimental).

## Sanity Check

There is nothing that can replace the full regression test suite. However, to quickly check whether a build is sane or not, one can run for instance `tests/QS/benchmark/H2O-64.inp` and check if the SCF iteration prints like the following:

```bash
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

## Performance

An info-script (`info.sh`) is [available](#info-script) attempting to present a table (summary of all results), which is generated from log files (use `tee`, or rely on the output of the job scheduler). There are only certain file extensions supported (`.txt`, `.log`). If no file matches, then all files (independent of the file extension) are attempted to be parsed (which will go wrong eventually). For legacy reasons (run command is not part of the log, etc.), certain schemes for the filename are eventually parsed and translated as well.

```bash
./run-cp2k.sh | tee cp2k-h2o64-2x32x2.txt
ls -1 *.txt
cp2k-h2o64-2x32x2.txt
cp2k-h2o64-4x16x2.txt

./info.sh [-best] /path/to/logs-or-cwd
H2O-64            Nodes R/N T/R Cases/d Seconds
cp2k-h2o64-2x32x2 2      32   4     807 107.237
cp2k-h2o64-4x16x2 4      16   8     872  99.962
```

Please note that the number of cases per day (Cases/d) are currently calculated with integer arithmetic and eventually lower than just rounding down (based on 86400 seconds per day). The number of seconds taken are end-to-end (wall time), i.e. total time to solution including any (sequential) phase (initialization, etc.). Performance is higher if the workload requires more iterations (some publications present a metric based on iteration time).

## References

[https://nholmber.github.io/2017/04/cp2k-build-cray-xc40/](https://nholmber.github.io/2017/04/cp2k-build-cray-xc40/)  
[https://www.cp2k.org/howto:compile](https://www.cp2k.org/howto:compile)

