# CP2K<a name="cp2k-open-source-molecular-dynamics"></a>

<a name="getting-the-source-code"></a>This document focuses on building and running the [Intel fork of CP2K](https://github.com/hfp/cp2k.git). The fork was formerly a branch of CP2K's Git-mirror; CP2K is meanwhile natively hosted at GitHub. This work is supposed to track the master version of CP2K in a timely fashion. The LIBXSMM library is highly recommended and can be found at [https://github.com/hfp/libxsmm](https://libxsmm.readthedocs.io). In terms of functionality (and performance) it is beneficial to rely on [LIBINT](../libint/README.md#libint) and [LIBXC](../libxc/README.md#libxc), whereas [ELPA](../elpa/README.md#eigenvalue-solvers-for-petaflop-applications-elpa) eventually improves the performance. For high performance, [LIBXSMM](../libxsmm/README.md#libxsmm) has been incorporated since [CP2K&#160;3.0](https://www.cp2k.org/version_history) (and intends to substitute CP2K's "libsmm" library).

<a name="recommended-intel-compiler"></a>Below are the releases of the Intel Compiler, which are known to reproduce correct results according to the regression tests (it is possible to combine components from different versions):

* Intel Compiler&#160;2017 (u0, u1, u2, u3), *and* the **initial** release of MKL&#160;2017 (u0)
    * source /opt/intel/compilers_and_libraries_2017.[*u0-u3*]/linux/bin/compilervars.sh intel64  
      source /opt/intel/compilers_and_libraries_2017.0.098/linux/mkl/bin/mklvars.sh intel64
* Intel Compiler&#160;2017 Update&#160;4, and any later update of the 2017 suite (u4, u5, u6, u7)
    * source /opt/intel/compilers_and_libraries_2017.[*u4-u7*]/linux/bin/compilervars.sh intel64
* Intel Compiler&#160;2018 (u3, u5): only with CP2K/development (not with CP2K&#160;6.1 or earlier)
    * source /opt/intel/compilers_and_libraries_2018.3.222/linux/bin/compilervars.sh intel64
    * source /opt/intel/compilers_and_libraries_2018.5.274/linux/bin/compilervars.sh intel64
* Intel Compiler&#160;2019 (u1, u2, u3): failure at runtime
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

### Build the Intel-fork of CP2K<a name="build-the-cp2kintel-branch"></a>

To build [CP2K/Intel](https://github.com/hfp/cp2k.git) from source, one may rely on [Intel Compiler 16, 17, or 18 series](#recommended-intel-compiler):

```bash
source /opt/intel/compilers_and_libraries_2018.3.222/linux/bin/compilervars.sh intel64
```

LIBXSMM is automatically built in an out-of-tree fashion when building CP2K/Intel fork. The only prerequisite is that the LIBXSMMROOT path needs to be detected (or supplied on the `make` command line). LIBXSMMROOT is automatically discovered automatically if it is in the user's home directory, or when it is in parallel to the CP2K directory. By default (no `AVX` or `MIC` is given), the build process is carried out using the `-xHost` target flag. For example, to explicitly target "Skylake" (SKX):

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

Using the GNU tool-chain requires to configure LIBINT, LIBXC, and ELPA accordingly (e.g., `configure-elpa-skx-gnu-omp.sh` instead of `configure-elpa-skx-omp.sh`). To further adjust CP2K at build time, additional key-value pairs can be passed at Make's command line (like `ARCH=Linux-x86-64-intelx` or `VERSION=psmp`).

* **SYM**: set `SYM=1` to include debug symbols into the executable e.g., helpful with performance profiling.
* **DBG**: set `DBG=1` to include debug symbols, and to generate non-optimized code.

To further improve performance and versatility, one should supply LIBINTROOT, LIBXCROOT, and ELPAROOT. These keys are valid when relying on CP2K/Intel's ARCH files (see later sections about these libraries).

### Build an Official Release

Here are two ways to build an [official release of CP2K](https://github.com/cp2k/cp2k/releases) using an Intel tool chain:

* Use the ARCH files from CP2K/intel fork.
* Write an own ARCH file.

LIBXSMM is supported since [CP2K&#160;3.0](https://www.cp2k.org/version_history). CP2K&#160;6.1 includes `Linux-x86-64-intel.*` (`arch` directory) as a starting point for writing an own ARCH-file (note: `Linux-x86-64-intel.*` vs. `Linux-x86-64-intelx.*`). Remember, performance is mostly related to libraries (`-O2` optimizations are sufficient in any case), more important for performance are target-flags such as `-xHost`. Prior to Intel Compiler 2018, the flag `-fp-model source` (FORTRAN) and `-fp-model precise` (C/C++) are key for passing CP2K's regression tests. Please follow the [official guide](https://www.cp2k.org/howto:compile) and consider the [CP2K Forum](https://groups.google.com/forum/#!forum/cp2k) in case of trouble. If an own ARCH file is used or prepared, the LIBXSMM library needs to be built separately. Building LIBXSMM is rather simple; to build the master revision:

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

Taking the ARCH files that are part of the CP2K/Intel fork automatically picks up the correct paths for Intel libraries. These paths are determined by using the environment variables setup when the Intel tools are source'd. Similarly, LIBXSMMROOT (which can be supplied on Make's command line) is discovered automatically if it is in the user's home directory, or when it is in parallel to the CP2K directory (as demonstrated below).

```bash
git clone https://github.com/hfp/libxsmm.git
https://github.com/cp2k/cp2k/releases/download/v6.1.0/cp2k-6.1.tar.bz2
tar xvf cp2k-6.1.tar.bz2
```

To download the ARCH files from the Intel-fork, simply run the following:

```bash
cd cp2k-6.1
wget --no-check-certificate https://github.com/hfp/xconfigure/raw/master/configure-get.sh
chmod +x configure-get.sh
./configure-get.sh cp2k
```

<a name="get-the-arch-files"></a>Alternatively, one can download the afore mentioned ARCH-files manually:

```bash
cd cp2k-6.1/arch
wget https://github.com/hfp/cp2k/raw/master/arch/Linux-x86-64-intelx.arch
wget https://github.com/hfp/cp2k/raw/master/arch/Linux-x86-64-intelx.popt
wget https://github.com/hfp/cp2k/raw/master/arch/Linux-x86-64-intelx.psmp
wget https://github.com/hfp/cp2k/raw/master/arch/Linux-x86-64-intelx.sopt
wget https://github.com/hfp/cp2k/raw/master/arch/Linux-x86-64-intelx.ssmp
```

To build the official CP2K sources/release now works the same way as for the Intel-fork:

```bash
source /opt/intel/compilers_and_libraries_2018.3.222/linux/bin/compilervars.sh intel64
cd cp2k-6.1/makefiles; make ARCH=Linux-x86-64-intelx VERSION=psmp AVX=2
```

To further improve performance and versatility, one may supply LIBINTROOT, LIBXCROOT, and ELPAROOT when relying on CP2K/Intel's ARCH files (see the following section about these libraries).

### LIBINT, LIBXC<a name="libint-and-libxc-dependencies"></a>, and ELPA<a name="eigenvalue-solvers-for-petaflop-applications-elpa"></a>

To configure, build, and install LIBINT (version&#160;1.1.5 and 1.1.6 have been tested), one can proceed with [https://xconfigure.readthedocs.io/libint/](../libint/README.md#libint). Also note there is no straightforward way to cross-compile LIBINT&#160;1.1.x for an instruction set extension that is not supported by the compiler host. To incorporate LIBINT into CP2K, the key `LIBINTROOT=/path/to/libint` needs to be supplied when using CP2K/Intel's ARCH files (make).

To configure, build, and install LIBXC (version&#160;3.0.0 has been tested), and one can proceed with [https://xconfigure.readthedocs.io/libxc/](../libxc/README.md#libxc). To incorporate LIBXC into CP2K, the key `LIBXCROOT=/path/to/libxc` needs to be supplied when using CP2K/Intel's ARCH files (make). After CP2K&#160;5.1, only the latest major release of LIBXC (by the time of the CP2K-release) will be supported (e.g., LIBXC&#160;4.x by the time of CP2K&#160;6.1).

To configure, build, and install the Eigenvalue SoLvers for Petaflop-Applications (ELPA), one can proceed with [https://xconfigure.readthedocs.io/libint/](../elpa/). To incorporate ELPA into CP2K, the key `ELPAROOT=/path/to/elpa` needs to be supplied when using CP2K/Intel's ARCH files (make). The Intel-fork defaults to ELPA-2017.11 (earlier versions can rely on the ELPA key-value pair e.g., `ELPA=201611`).

```bash
make ARCH=Linux-x86-64-intelx VERSION=psmp ELPAROOT=/path/to/elpa/default-arch
```

At runtime, a build of the Intel-fork supports an environment variable CP2K_ELPA:

* **CP2K_ELPA=-1**: requests ELPA to be enabled; the actual kernel type depends on the ELPA configuration.
* **CP2K_ELPA=0**: ELPA is not enabled by default (only on request via input file); same as non-Intel fork.
* **CP2K_ELPA**=&lt;not-defined&gt;: requests ELPA-kernel according to CPUID (default with CP2K/Intel-fork).

### Step-by-step Guide

This step-by-step guide attempts to build the official release of CP2K. Internet connectivity is assumed on the build-system. Please note that such limitations can be worked around or avoided with additional steps. However, this simple step-by-step guide aims to make some reasonable assumptions.

The first step builds ELPA. Do not use an ELPA-version newer than 2017.11.001.

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

The second step builds LIBINT, which should not be cross-compiled. Simply compile on the real target-architecture.

```bash
cd $HOME
wget --no-check-certificate https://github.com/evaleev/libint/archive/release-1-1-6.tar.gz
tar xvf release-1-1-6.tar.gz
cd libint-release-1-1-6
wget --no-check-certificate https://github.com/hfp/xconfigure/raw/master/configure-get.sh
chmod +x configure-get.sh
./configure-get.sh libint
configure-libint-skx-gnu.sh
make -j
make install
make distclean
```

The third step builds LIBXC.

```bash
cd $HOME
wget --content-disposition http://www.tddft.org/programs/octopus/down.php?file=libxc/4.2.3/libxc-4.2.3.tar.gz
tar xvf libxc-4.2.3.tar.gz
cd libxc-4.2.3
wget --no-check-certificate https://github.com/hfp/xconfigure/raw/master/configure-get.sh
chmod +x configure-get.sh
./configure-get.sh libxc
configure-libxc-skx-gnu.sh
make -j
make install
make distclean
```

The fourth step makes LIBXSMM available, which is compiled as part of the next step.

```bash
cd $HOME
wget https://github.com/hfp/libxsmm/archive/master.tar.gz
tar xvf libxsmm-master.tar.gz
```

This last step builds the PSMP-variant of CP2K. Please re-download the ARCH-files from GitHub as mentioned below (do not reuse older/outdated files).

```bash
cd $HOME
wget https://github.com/cp2k/cp2k/archive/v6.1.0.tar.gz
tar xvf cp2k-6.1.0.tar.gz
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

The CP2K executable should be now ready (`exe/Linux-x86-64-intelx/cp2k.psmp`).

### Memory Allocation

Dynamic allocation of heap memory usually requires global book keeping eventually incurring overhead in shared-memory parallel regions of an application. For this case, specialized allocation strategies are available. To use such a strategy, memory allocation wrappers can be used to replace the default memory allocation at build-time or at runtime of an application.

To use the malloc-proxy of the Intel Threading Building Blocks (Intel TBB), rely on the `TBBMALLOC=1` key-value pair at build-time of CP2K (default: `TBBMALLOC=0`). Usually, Intel TBB is already available when sourcing the Intel development tools (one can check the TBBROOT environment variable). To use TCMALLOC as an alternative, set `TCMALLOCROOT` at build-time of CP2K by pointing to TCMALLOC's installation path (configured per `./configure --enable-minimal --prefix=<TCMALLOCROOT>`).

## Run Instructions<a name="running-the-application"></a>

Running CP2K may go beyond a single node, and pinning processes and threads becomes even more important. There are several scheme available. As a rule of thumb, a high rank-count for lower node-counts may yield best results unless the workload is very memory intensive. In the latter case, lowering the number of MPI-ranks per node is effective especially if a larger amount of memory is replicated rather than partitioned by the rank-count. In contrast (communication bound), a lower rank count for multi-node computations may be desired. Most important, CP2K prefers a total rank-count to be a square-number (two-dimensional communication pattern) rather than a Power-of-Two (POT) number. This property can be as dominant as wasting cores per node is more effective than fully utilizing the entire node (sometimes a frequency upside over an "all-core turbo" emphasizes this property further). Counter-intuitively, even an unbalanced rank-count per node i.e., different rank-counts per socket can be an advantage.

<a name="plan-script"></a>Because of the above mentioned complexity, a script for planning MPI-execution (`plan.sh`) is available. Here is a first example for running the PSMP-binary i.e., MPI/OpenMP-hybrid CP2K on an HT-enabled dual-socket system with 24 cores per processor/socket (96 hardware threads). A first step would be to run with 48 ranks and 2 threads per core. However, a second try could be the following:

```bash
mpirun -np 16 \
  -genv I_MPI_PIN_DOMAIN=auto -genv I_MPI_PIN_ORDER=bunch \
  -genv OMP_PLACES=threads -genv OMP_PROC_BIND=SPREAD \
  -genv OMP_NUM_THREADS=6 \
  exe/Linux-x86-64-intelx/cp2k.psmp workload.inp
```

It is recommended to set `I_MPI_DEBUG=4`, which displays/logs the pinning and thread affinization (with no performance penalty) at startup of the application. The recommended `I_MPI_PIN_ORDER=bunch` ensures that ranks per node are split as even as possible with respect to sockets e.g., running 36 ranks on a 2x20-core system puts 2x18 ranks (instead of 20+16 ranks). To [plan](#plan-script) for running on 8 nodes (with the above mentioned 48-core system type) may look like:

```
./plan.sh 8 48
================================================================================
Planning for 8 node(s) with 2x24 core(s) per node and 2 threads per core.
================================================================================
48x2: 48 ranks per node with 2 thread(s) per rank (6% penalty)
24x4: 24 ranks per node with 4 thread(s) per rank (0% penalty)
12x8: 12 ranks per node with 8 thread(s) per rank (0% penalty)
8x12: 8 ranks per node with 12 thread(s) per rank (0% penalty)
6x16: 6 ranks per node with 16 thread(s) per rank (0% penalty)
4x24: 4 ranks per node with 24 thread(s) per rank (0% penalty)
```

The script (`plan.sh <num-node> <num-cores-per-node> <num-threads-per-core> <num-sockets>`) displays the MPI/OpenMP setup sorted by increasing waste (except for the first entry where potential communication overhead is shown) of compute in order to suit the square-number preference. For the seconds setup, the MPI command line may look like:

```bash
mpirun -perhost 24 -host node1,node2,node3,node4,node5,node6,node7,node8 \
  -genv I_MPI_PIN_DOMAIN=auto -genv I_MPI_PIN_ORDER=bunch \
  -genv OMP_PLACES=threads -genv OMP_PROC_BIND=SPREAD \
  -genv OMP_NUM_THREADS=4 -genv I_MPI_DEBUG=4 \
  exe/Linux-x86-64-intelx/cp2k.psmp workload.inp
```

## Sanity Check

There is nothing that can replace the full regression test suite. However, to quickly check whether a build is sane or not, one can run for instance `tests/QS/benchmark/H2O-64.inp` and check if the SCF iteration prints like the following:

```
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

The [script](#plan-script) for planning MPI-execution (`plan.sh`) is highly recommend along with reading the section about [how to run CP2K](#run-instructions). As soon as several experiments finished, it becomes handy to summarize the log-output. For this use case, an info-script (`info.sh`) is [available](#info-script) attempting to present a table (summary of all results), which is generated from log files (use `tee`, or rely on the output of the job scheduler). There are only certain file extensions supported (`.txt`, `.log`). If no file matches, then all files (independent of the file extension) are attempted to be parsed (which will go wrong eventually). If for some reason the command to launch CP2K is not part of the log and the run-arguments cannot be determined otherwise, the number of nodes is eventually parsed using the filename of the log itself (e.g., first occurrence of a number along with an optional "n" is treated as the number of nodes used for execution).

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

