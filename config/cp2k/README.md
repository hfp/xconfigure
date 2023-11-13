# CP2K<a name="cp2k-open-source-molecular-dynamics"></a>

This document describes building CP2K with several (optional) libraries, which may be beneficial in terms of functionality and performance.

* Intel Math Kernel Library (also per Linux' distro's package manager) acts as:
    * LAPACK/BLAS and ScaLAPACK library
    * FFTw library
* [LIBXSMM](https://github.com/libxsmm/libxsmm) (replaces LIBSMM)
* [LIBINT](../libint/README.md#libint) (depends on CP2K version)
* [PLUMED](https://www.plumed.org/) (version 2.x)
* [LIBXC](../libxc/README.md#libxc) (version 4.x)
* [ELPA](../elpa/README.md#eigenvalue-solvers-for-petaflop-applications-elpa) (depends on CP2K version)

The ELPA library eventually improves the performance (must be currently enabled for each input file even if CP2K was built with ELPA). There is also the option to auto-tune additional routines in CP2K (integrate/collocate) and to collect the generated code into an archive referred as LIBGRID.

For high performance, [LIBXSMM](../libxsmm/README.md#libxsmm) (see also [https://libxsmm.readthedocs.io](https://libxsmm.readthedocs.io)) has been incorporated since [CP2K&#160;3.0](https://www.cp2k.org/version_history). When CP2K is built with LIBXSMM, CP2K's "libsmm" library is not used and hence libsmm does not need to be built and linked with CP2K.

## Getting Started<a name="build-and-run-instructions"></a>

There are no configuration wrapper scripts provided for CP2K since a configure-step is usually not required, and the application can be built right away. CP2K's `install_cp2k_toolchain.sh` (under `tools/toolchain`) is out of scope in this document (it builds the entire tool chain from source including the compiler).

Although there are no configuration wrapper scripts for CP2K, below command delivers, e.g., an [info-script](#performance) and a script for [planning](#plan-script) CP2K execution:

```bash
wget --content-disposition --no-check-certificate https://github.com/hfp/xconfigure/raw/master/configure-get.sh
chmod +x configure-get.sh
./configure-get.sh cp2k
```

<a name="info-script"></a>Of course, the scripts can be also download manually:

```bash
wget --content-disposition --no-check-certificate https://github.com/hfp/xconfigure/raw/master/config/cp2k/info.sh
chmod +x info.sh
wget --content-disposition --no-check-certificate https://github.com/hfp/xconfigure/raw/master/config/cp2k/plan.sh
chmod +x plan.sh
```

## Step-by-step Guide<a name="build-instructions"></a>

<a name="getting-the-source-code"></a>This step-by-step guide aims to build an MPI/OpenMP-hybrid version of the official release of CP2K by using the GNU Compiler Collection, Intel&#160;MPI, Intel&#160;MKL, LIBXSMM, ELPA, LIBXC, and LIBINT. Internet connectivity is assumed on the build-system. Please note that such limitations can be worked around or avoided with additional steps. However, this simple step-by-step guide aims to make some reasonable assumptions.

<a name="build-an-official-release"></a>There are step-by-step guides for the [current](#current-release) release (v7.1) and the [previous](#previous-release) release (v6.1).

### Current Release<a name="current-release"></a>

This step-by-step guide uses (**a**)&#160;GNU Fortran (version 8.x, or 9.x, 9.1 is not recommended), or (**b**)&#160;Intel Compiler (version 19.1 "2020"). In any case, Intel&#160;MKL (2018, 2019, 2020 recommended) and Intel&#160;MPI (2018, 2020 recommended) need to be sourced. The following components are used:

* Intel Math Kernel Library (also per Linux' distro's package manager) acts as:
    * LAPACK/BLAS and ScaLAPACK library
    * FFTw library
* [LIBXSMM](https://github.com/libxsmm/libxsmm) (replaces LIBSMM)
* [LIBINT](../libint/README.md#libint) (2.x from CP2K.org!)
* [PLUMED](https://www.plumed.org/) (version 2.x)
* [LIBXC](../libxc/README.md#libxc) (version 4.x, not 5.x)
* [ELPA](../elpa/README.md#eigenvalue-solvers-for-petaflop-applications-elpa) (version 2020.05.001 or 2020.11.001)

To install Intel Math Kernel Library and Intel&#160;MPI from a public repository depends on the Linux distribution's package manager (mixing and matching recommended Intel components is possible). For newer distributions, Intel&#160;MKL and Intel&#160;MPI libraries are likely part of the official repositories. Otherwise a suitable repository must be added to the package manager (not subject of this document).

```bash
source /opt/intel/compilers_and_libraries_2020.4.304/linux/mpi/intel64/bin/mpivars.sh
source /opt/intel/compilers_and_libraries_2020.4.304/linux/mkl/bin/mklvars.sh intel64
```

If Intel Compiler is used, the following (or similar) makes the compiler and all necessary libraries available.

```bash
source /opt/intel/compilers_and_libraries_2020.4.304/linux/bin/compilervars.sh intel64
```

Please note, the ARCH file (used later/below to build CP2K) attempts to find Intel&#160;MKL even if the `MKLROOT` environment variable is not present. The MPI library is implicitly known when using compiler wrapper scripts (no need for `I_MPI_ROOT`). Installing the proper software stack and drivers for an HPC fabric to be used by MPI is out of scope in this document. If below check fails (GNU&#160;GCC only), the MPI's bin-folder must be added to the path.

```text
$ mpif90 --version
  GNU Fortran (GCC) 8.3.0
  Copyright (C) 2018 Free Software Foundation, Inc.
  This is free software; see the source for copying conditions.  There is NO
  warranty; not even for MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
```

**1**) <a name="eigenvalue-solvers-for-petaflop-applications-elpa"></a>The first step builds ELPA. Please rely on ELPA&#160;2020.

```bash
cd $HOME
echo "wget --content-disposition --no-check-certificate https://elpa.mpcdf.mpg.de/software/tarball-archive/Releases/2020.11.001/elpa-2020.11.001.tar.gz"
wget --content-disposition --no-check-certificate https://www.cp2k.org/static/downloads/elpa-2020.11.001.tar.gz
tar xvf elpa-2020.11.001.tar.gz

cd elpa-2020.11.001
wget --content-disposition --no-check-certificate https://github.com/hfp/xconfigure/raw/master/configure-get.sh
chmod +x configure-get.sh
./configure-get.sh elpa
```

a) GNU&#160;GCC

```bash
./configure-elpa-skx-gnu-omp.sh
```

b) Intel Compiler

```bash
./configure-elpa-skx-omp.sh
```

Build and install ELPA:

```bash
make -j
make install
make clean
```

**2**) <a name="libint-and-libxc-dependencies"></a>The second step builds LIBINT ([preconfigured](https://github.com/cp2k/libint-cp2k/releases) for CP2K).

```bash
cd $HOME
curl -s https://api.github.com/repos/cp2k/libint-cp2k/releases/latest \
| grep "browser_download_url" | grep "lmax-6" \
| sed "s/..*: \"\(..*[^\"]\)\".*/url \1/" \
| curl -LOK-
tar xvf libint-v2.6.0-cp2k-lmax-6.tgz
```

**Note**: A rate limit applies to GitHub API requests of the same origin. If the download fails, it can be worth trying an authenticated request by using a GitHub account (`-u "user:password"`).

```bash
cd libint-v2.6.0-cp2k-lmax-6
wget --content-disposition --no-check-certificate https://github.com/hfp/xconfigure/raw/master/configure-get.sh
chmod +x configure-get.sh
./configure-get.sh libint
```

**Note**: There are spurious issues about specific target flags requiring a build-system able to execute compiled binaries. To avoid cross-compilation (not supported here), please rely on a build system that matches the target system.

a) GNU&#160;GCC

```bash
./configure-libint-skx-gnu.sh
```

b) Intel Compiler

```bash
./configure-libint-skx.sh
```

Build and install LIBINT:

```bash
make -j
make install
make distclean
```

**3**) The third step builds LIBXC.

```bash
cd $HOME
wget --content-disposition --no-check-certificate https://gitlab.com/libxc/libxc/-/archive/4.3.4/libxc-4.3.4.tar.bz2
tar xvf libxc-4.3.4.tar.bz2

cd libxc-4.3.4
wget --content-disposition --no-check-certificate https://github.com/hfp/xconfigure/raw/master/configure-get.sh
chmod +x configure-get.sh
./configure-get.sh libxc
```

**Note**: LIBXC&#160;5.x is not supported. Please also disregard messages during configuration suggesting `libtoolize --force`.

a) GNU&#160;GCC

```bash
./configure-libxc-skx-gnu.sh
```

b) Intel Compiler

```bash
./configure-libxc-skx.sh
```

Build and install LIBXC:

```bash
make -j
make install
make distclean
```

**4**) The fourth step builds [Plumed2](https://github.com/plumed/plumed2/releases/latest).

```bash
cd $HOME
wget --content-disposition --no-check-certificate https://github.com/plumed/plumed2/archive/v2.6.1.tar.gz
tar xvf v2.6.1.tar.gz

cd plumed2-2.6.1
wget --content-disposition --no-check-certificate https://github.com/hfp/xconfigure/raw/master/configure-get.sh
chmod +x configure-get.sh
./configure-get.sh plumed
```

a) GNU&#160;GCC

```bash
./configure-plumed-skx-gnu.sh
```

b) Intel Compiler

```bash
./configure-plumed-skx.sh
```

Build and install Plumed2:

```bash
make -j
make install
make distclean
```

**5**) The fifth step makes LIBXSMM [available](https://github.com/libxsmm/libxsmm/releases/latest), which is compiled as part of the last step.

```bash
cd $HOME
wget --content-disposition --no-check-certificate https://github.com/libxsmm/libxsmm/archive/1.16.1.tar.gz
tar xvf 1.16.1.tar.gz
```

**6**) This last step builds the PSMP-variant of CP2K. Please re-download the ARCH-files from GitHub as mentioned below (avoid reusing older/outdated files). If Intel&#160;MKL is not found, the key `MKLROOT=/path/to/mkl` can be added to Make's command line. To select a different MPI implementation one can try, e.g., `MKL_MPIRTL=openmpi`.

```bash
cd $HOME
wget https://github.com/cp2k/cp2k/releases/download/v7.1.0/cp2k-7.1.tar.bz2
tar xvf cp2k-7.1.tar.bz2
```

<a name="missing-git-submodules"></a>**Note**: Do not download the package `v7.1.0.tar.gz` from [https://github.com/cp2k/cp2k/releases](https://github.com/cp2k/cp2k/releases) which was automatically generated by GitHub (it misses the source code from Git-submodules).

```bash
cd cp2k-7.1
wget --content-disposition --no-check-certificate https://github.com/hfp/xconfigure/raw/master/configure-get.sh
chmod +x configure-get.sh
./configure-get.sh cp2k
```

It is possible to supply `LIBXSMMMROOT`, `LIBINTROOT`, `LIBXCROOT`, and `ELPAROOT` (see below). However, the ARCH-file attempts to [auto-detect](#autodetectroot) these libraries.

a) GNU&#160;GCC

```bash
rm -rf exe lib obj
make ARCH=Linux-x86-64-intelx VERSION=psmp AVX=3 GNU=1 \
  LIBINTROOT=$HOME/libint/gnu-skx \
  LIBXCROOT=$HOME/libxc/gnu-skx \
  ELPAROOT=$HOME/elpa/gnu-skx-omp -j
```

b) Intel Compiler

```bash
rm -rf exe lib obj
make ARCH=Linux-x86-64-intelx VERSION=psmp AVX=3 \
  LIBINTROOT=$HOME/libint/intel-skx \
  LIBXCROOT=$HOME/libxc/intel-skx \
  ELPAROOT=$HOME/elpa/intel-skx-omp -j
```

The above mentioned auto-detection of libraries goes further: GCC is used automatically if no Intel Compiler was sourced. Also, if cross-compilation is not necessary (`make ARCH=Linux-x86-64-intelx VERSION=psmp AVX=3`), `AVX` can be dropped as well from Make's command line (`make ARCH=Linux-x86-64-intelx VERSION=psmp`). The initial output of the build looks like:

```text
Discovering programs ...
================================================================================
Using the following libraries:
LIBXSMMROOT=/path/to/libxsmm
LIBINTROOT=/path/to/libint/gnu-skx
LIBXCROOT=/path/to/libxc/gnu-skx
ELPAROOT=/path/to/elpa/gnu-skx-omp
================================================================================
LIBXSMM release-1.16.1 (Linux)
--------------------------------------------------------------------------------
```

Once the build completed, the CP2K executable should be ready (`exe/Linux-x86-64-intelx/cp2k.psmp`):

```text
$ LIBXSMM_VERBOSE=1 exe/Linux-x86-64-intelx/cp2k.psmp
  [...]
  LIBXSMM_VERSION: release-1.16.1
  LIBXSMM_TARGET: clx
```

Have a look at [Running CP2K](#running-cp2k) to learn more about pinning MPI processes (and OpenMP threads), and to try a first workload.

### Previous Release<a name="previous-release"></a>

As the step-by-step guide uses GNU Fortran (version 7.x, 8.x, or 9.x, 9.1 is not recommended), only Intel&#160;MKL (2019.x recommended) and Intel&#160;MPI (2018.x recommended) need to be sourced (sourcing all Intel development tools of course does not harm). The following components are used:

* Intel Math Kernel Library (also per Linux' distro's package manager) acts as:
    * LAPACK/BLAS and ScaLAPACK library
    * FFTw library
* [LIBXSMM](https://github.com/libxsmm/libxsmm) (replaces LIBSMM)
* [LIBINT](../libint/README.md#libint) (version 1.1.5 or 1.1.6)
* [PLUMED](https://www.plumed.org/) (version 2.x)
* [LIBXC](../libxc/README.md#libxc) (version 4.x)
* [ELPA](../elpa/README.md#eigenvalue-solvers-for-petaflop-applications-elpa) (version 2017.11.001)

**Note**: GNU&#160;GCC version 7.x, 8.x, or 9.x is recommended (CP2K built with GCC&#160;9.1 may not pass regression tests).

```bash
source /opt/intel/compilers_and_libraries_2018.5.274/linux/mpi/intel64/bin/mpivars.sh
source /opt/intel/compilers_and_libraries_2019.3.199/linux/mkl/bin/mklvars.sh intel64
```

To install Intel Math Kernel Library and Intel&#160;MPI from a public repository depends on the Linux distribution's package manager. For newer distributions, both libraries are likely part of the official repositories. Otherwise a suitable repository must be added to the package manager (not subject of this document). For example, installing with `yum` looks like:

```bash
sudo yum install intel-mkl-2019.4-070.x86_64
sudo yum install intel-mpi-2018.3-051.x86_64
```

Please note, the ARCH file (used later/below to build CP2K) attempts to find Intel&#160;MKL even if the `MKLROOT` environment variable is not present. The MPI library is implicitly known when using compiler wrapper scripts (no need for `I_MPI_ROOT`). Installing the proper software stack and drivers for an HPC fabric to be used by MPI is out of scope in this document. If below check fails, the MPI's bin-folder must be added to the path.

```text
$ mpif90 --version
  GNU Fortran (GCC) 8.3.0
  Copyright (C) 2018 Free Software Foundation, Inc.
  This is free software; see the source for copying conditions.  There is NO
  warranty; not even for MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
```

The first step builds ELPA. Do not use an ELPA-version newer than 2017.11.001.

```bash
cd $HOME
wget https://elpa.mpcdf.mpg.de/software/tarball-archive/Releases/2017.11.001/elpa-2017.11.001.tar.gz
tar xvf elpa-2017.11.001.tar.gz

cd elpa-2017.11.001
wget --content-disposition --no-check-certificate https://github.com/hfp/xconfigure/raw/master/configure-get.sh
chmod +x configure-get.sh
./configure-get.sh elpa

./configure-elpa-skx-gnu-omp.sh
make -j
make install
make clean
```

The second step builds LIBINT (1.1.6 recommended, newer version cannot be used). This library does not compile on an architecture with less CPU-features than the target (e.g., `configure-libint-skx-gnu.sh` implies to build on "Skylake" or "Cascadelake" server).

```bash
cd $HOME
wget --content-disposition --no-check-certificate https://github.com/evaleev/libint/archive/release-1-1-6.tar.gz
tar xvf release-1-1-6.tar.gz

cd libint-release-1-1-6
wget --content-disposition --no-check-certificate https://github.com/hfp/xconfigure/raw/master/configure-get.sh
chmod +x configure-get.sh
./configure-get.sh libint

./configure-libint-skx-gnu.sh
make -j
make install
make distclean
```

The third step builds LIBXC.

```bash
cd $HOME
wget --content-disposition --no-check-certificate https://gitlab.com/libxc/libxc/-/archive/4.3.4/libxc-4.3.4.tar.bz2
tar xvf libxc-4.3.4.tar.bz2

cd libxc-4.3.4
wget --content-disposition --no-check-certificate https://github.com/hfp/xconfigure/raw/master/configure-get.sh
chmod +x configure-get.sh
./configure-get.sh libxc

./configure-libxc-skx-gnu.sh
make -j
make install
make distclean
```

The fourth step builds [Plumed2](https://github.com/plumed/plumed2/releases/latest).

```bash
cd $HOME
wget --content-disposition --no-check-certificate https://github.com/plumed/plumed2/archive/v2.6.1.tar.gz
tar xvf v2.6.1.tar.gz

cd plumed2-2.6.1
wget --content-disposition --no-check-certificate https://github.com/hfp/xconfigure/raw/master/configure-get.sh
chmod +x configure-get.sh
./configure-get.sh plumed
./configure-plumed-skx.sh
```

Build and install Plumed2:

```bash
make -j
make install
make distclean
```

The fifth step makes LIBXSMM [available](https://github.com/libxsmm/libxsmm/releases/latest), which is compiled as part of the last step.

```bash
cd $HOME
wget --content-disposition --no-check-certificate https://github.com/libxsmm/libxsmm/archive/1.16.1.tar.gz
tar xvf 1.16.1.tar.gz
```

This last step builds the PSMP-variant of CP2K. Please re-download the ARCH-files from GitHub as mentioned below (avoid reusing older/outdated files). If Intel&#160;MKL is not found, the key `MKLROOT=/path/to/mkl` can be added to Make's command line. To select a different MPI implementation one can try, e.g., `MKL_MPIRTL=openmpi`.

```bash
cd $HOME
wget https://github.com/cp2k/cp2k/archive/v6.1.0.tar.gz
tar xvf v6.1.0.tar.gz

cd cp2k-6.1.0
wget --content-disposition --no-check-certificate https://github.com/hfp/xconfigure/raw/master/configure-get.sh
chmod +x configure-get.sh
./configure-get.sh cp2k

wget --content-disposition --no-check-certificate https://github.com/hfp/xconfigure/raw/master/config/cp2k/mpi-wrapper.diff
patch -p0 src/mpiwrap/message_passing.F mpi-wrapper.diff
wget --content-disposition --no-check-certificate https://github.com/hfp/xconfigure/raw/master/config/cp2k/intel-mkl.diff
patch -p0 src/pw/fft/fftw3_lib.F intel-mkl.diff
```

It is possible to supply `LIBXSMMMROOT`, `LIBINTROOT`, `LIBXCROOT`, and `ELPAROOT` (see below). However, the ARCH-file attempts to [auto-detect](#autodetectroot) these libraries.

```bash
rm -rf exe lib obj
cd makefiles
make ARCH=Linux-x86-64-intelx VERSION=psmp AVX=3 GNU=1 \
  LIBINTROOT=$HOME/libint/gnu-skx \
  LIBXCROOT=$HOME/libxc/gnu-skx \
  ELPAROOT=$HOME/elpa/gnu-skx-omp -j
```

The above mentioned auto-detection of libraries goes further: GCC is used automatically if no Intel Compiler was sourced. Also, if cross-compilation is not necessary (`make ARCH=Linux-x86-64-intelx VERSION=psmp AVX=3`), `AVX` can be dropped as well from Make's command line (`make ARCH=Linux-x86-64-intelx VERSION=psmp`). The initial output of the build looks like:

```text
Discovering programs ...
================================================================================
Using the following libraries:
LIBXSMMROOT=/path/to/libxsmm
LIBINTROOT=/path/to/libint/gnu-skx
LIBXCROOT=/path/to/libxc/gnu-skx
ELPAROOT=/path/to/elpa/gnu-skx-omp
================================================================================
LIBXSMM release-1.16.1 (Linux)
--------------------------------------------------------------------------------
```

Once the build completed, the CP2K executable should be ready (`exe/Linux-x86-64-intelx/cp2k.psmp`):

```text
$ LIBXSMM_VERBOSE=1 exe/Linux-x86-64-intelx/cp2k.psmp
  [...]
  LIBXSMM_VERSION: release-1.16.1
  LIBXSMM_TARGET: clx
```

Have a look at [Running CP2K](#running-cp2k) to learn more about pinning MPI processes (and OpenMP threads), and to try a first workload.

## Intel Compiler<a name="recommended-intel-compiler"></a>

Below are the releases of the Intel Compiler, which are known to reproduce correct results according to the regression tests. It is also possible to mix and match different component versions by sourcing from different Intel suites.

* Intel Compiler&#160;2017 (u0, u1, u2, u3), *and* the **initial** release of MKL&#160;2017 (u0)
    * source /opt/intel/compilers_and_libraries_2017.[*u0-u3*]/linux/bin/compilervars.sh intel64  
      source /opt/intel/compilers_and_libraries_2017.0.098/linux/mkl/bin/mklvars.sh intel64
* Intel Compiler&#160;2017 Update&#160;4, and any later update of the 2017 suite (u4, u5, u6, u7)
    * source /opt/intel/compilers_and_libraries_2017.[*u4-u7*]/linux/bin/compilervars.sh intel64
* Intel Compiler&#160;2018 (u3, u4, u5): only with CP2K/development (not with CP2K&#160;6.1 or earlier)
    * source /opt/intel/compilers_and_libraries_2018.3.222/linux/bin/compilervars.sh intel64
    * source /opt/intel/compilers_and_libraries_2018.5.274/linux/bin/compilervars.sh intel64
* Intel Compiler&#160;2019 and 2020: only suitable for CP2K&#160;7.1 (and later)
    * source /opt/intel/compilers_and_libraries_2020.4.304/linux/bin/compilervars.sh intel64
    * Avoid 2019u1, 2019u2, 2019u3
* Intel MPI; usually any version is fine: Intel MPI 2018 and 2020 are recommended

**Note**: Intel Compiler&#160;2019 (and likely later) is not recommended for CP2K&#160;6.1 (and earlier).

## Intel ARCH File

CP2K&#160;6.1 includes `Linux-x86-64-intel.*` (`arch` directory) as a starting point for writing an own ARCH-file (note: `Linux-x86-64-intel.*` vs. `Linux-x86-64-intelx.*`). Remember, performance critical code is often located in libraries (hence `-O2` optimizations for CP2K's source code are enough in almost all cases), more important for performance are target-flags such as `-march=native` (`-xHost`) or `-mavx2 -mfma`. Prior to Intel Compiler 2018, the flag `-fp-model source` (FORTRAN) and `-fp-model precise` (C/C++) were key for passing CP2K's regression tests. If an own ARCH file is used or prepared, all libraries including LIBXSMM need to be built separately and referred in the link-line of the ARCH-file. In addition, CP2K may need to be informed and certain preprocessor symbols need to be given during compilation (`-D` compile flag). For further information, please follow the [official guide](https://www.cp2k.org/howto:compile) and consider the [CP2K Forum](https://groups.google.com/forum/#!forum/cp2k) in case of trouble.

The purpose of the Intel ARCH files is to avoid writing an own ARCH-file even when GNU Compiler is used. Taking the Intel ARCH files that are part of the CP2K/Intel fork automatically picks up the correct paths for Intel libraries. These paths are determined by using the environment variables setup when the Intel tools are source'd. <a name="#autodetectroot"></a>Similarly, LIBXSMMMROOT, LIBINTROOT, LIBXCROOT, and ELPAROOT (which can be supplied on Make's command line) are discovered automatically if it is in the user's home directory, or when it is in parallel to the CP2K directory. The Intel ARCH files not only work with CP2K/Intel fork but even if an official release of CP2K is built (which is also encouraged). Of course, one can download the afore mentioned Intel ARCH files manually<a name="get-the-arch-files"></a>:

```bash
cd cp2k-6.1.0/arch
wget https://github.com/cp2k/cp2k/raw/master/arch/Linux-x86-64-intelx.arch
wget https://github.com/cp2k/cp2k/raw/master/arch/Linux-x86-64-intelx.popt
wget https://github.com/cp2k/cp2k/raw/master/arch/Linux-x86-64-intelx.psmp
wget https://github.com/cp2k/cp2k/raw/master/arch/Linux-x86-64-intelx.sopt
wget https://github.com/cp2k/cp2k/raw/master/arch/Linux-x86-64-intelx.ssmp
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

**Note**: the [documentation](plan.md) of `plan.sh` also motivates and explains the MPI environment variables as shown in above MPI command lines.

## CP2K on GPUs

This section shows how to build CP2K with DBCSR's OpenCL backend (`USE_ACCEL=opencl` like `USE_ACCEL=opencl` for CUDA). Any other dependencies like LIBINT, LIBXC, and others are auto-detected and can be made available using XCONFIGURE as well. LIBXSMM is a prerequisite and building it, is managed by using the ARCH-file as fetched below (`configure-get.sh cp2k`).

```bash
git clone -b main https://github.com/libxsmm/libxsmm.git
git clone https://github.com/cp2k/cp2k.git

cd cp2k
git submodule update --init --recursive
cd exts/dbcsr
git fetch
git checkout develop
cd ../..
wget --no-check-certificate https://github.com/hfp/xconfigure/raw/master/configure-get.sh
chmod +x configure-get.sh
./configure-get.sh cp2k

rm -rf exe lib obj
echo "Intel MPI, Intel MKL, and GNU Fortran are made available"
make ARCH=Linux-x86-64-intelx VERSION=psmp NDEBUG=2 USE_ACCEL=opencl -j
```

DBCSR can be built stand-alone and used to exercise and test GPU accleration as well, which is not subject of XCONFIGURE. Further, within DBCSR some driver code exists to exercise GPU performance in a stand-alone fashion as well. The latter is not even subject to DBCSR's build system and simply required GNU Make (see [DBCSR ACCelerator Interface](https://cp2k.github.io/dbcsr/develop/page/3-developer-guide/3-programming/2-accelerator-backend/index.html)). The mentioned SMM driver can be used to [auto-tune](https://cp2k.github.io/dbcsr/develop/page/3-developer-guide/3-programming/2-accelerator-backend/3-libsmm_ocl/1-autotune.html) or [bulk-tune](https://cp2k.github.io/dbcsr/develop/page/3-developer-guide/3-programming/2-accelerator-backend/3-libsmm_ocl/2-bulktune.html) kernels for the OpenCL backend.

**Note**: if the GNU Fortran compiler rejects Intel MPI because of an incompatible MPI module, please list the content of the directory `${I_MPI_ROOT}/include/gfortran` and select the closest version matching the GNU Fortran compiler using `GNUVER`, e.g., `make ARCH=Linux-x86-64-intelx VERSION=psmp NDEBUG=2 USE_ACCEL=opencl GNUVER=11.1.0` for GNU Fortran&#160;12.2.

```bash
make ARCH=Linux-x86-64-intelx VERSION=psmp NDEBUG=2 USE_ACCEL=opencl GNUVER=11.1.0 cp2k
```

**Note**: for more comprehensive builds of CP2K, please refer to CP2K's Toolchain, e.g., it is possible to blend the OpenCL backend with other GPU-enabled code written in CUDA.

The OpenCL backend provides [pretuned kernels](https://github.com/cp2k/dbcsr/tree/develop/src/acc/opencl/smm/params) and comprehensive runtime-control by the means of [environment variables](https://cp2k.github.io/dbcsr/develop/page/3-developer-guide/3-programming/2-accelerator-backend/3-libsmm_ocl/index.html). This can be used to assign OpenCL devices, to aggregate sub-devices (devices are split into sub-devices by default), to extract kernel shapes used by a specific workload, and to subsequently tune specific kernels.

## Performance

The [script](#plan-script) for planning MPI-execution (`plan.sh`) is highly recommend along with reading the section about [how to run CP2K](#run-instructions). For CP2K, the MPI-communication patterns can be tuned in most MPI-implementations. For Intel&#160;MPI, the following setting can be beneficial:

```bash
export I_MPI_COLL_INTRANODE=pt2pt
export I_MPI_ADJUST_REDUCE=1
export I_MPI_ADJUST_BCAST=1
```

For large-scale runs, the startup can be tuned, but typically this is not necessary. However, the following may be useful (and does not harm):

```bash
export I_MPI_DYNAMIC_CONNECTION=1
```

Intel&#160;MPI usually nicely determines the fabric settings for both Omnipath and InfiniBand, and no adjustment is needed. However, people often prefer explicit settings even if it does not differ from what is determined automatically. For example, InfiniBand with RDMA can be set explicitly by using `mpirun -rdma` which can be also achieved with environment variables:

```bash
echo "'mpirun -rdma' and/or environment variables for InfiniBand"
export I_MPI_FABRICS=shm:dapl
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

Please note that the "Cases/d" metric is calculated with integer arithmetic and hence represents fully completed cases per day (based on 86400 seconds per day). The number of seconds (as shown) is end-to-end (wall time), i.e., total time to solution including any (sequential) phase (initialization, etc.). Performance is higher if the workload requires more iterations (some publications present a metric based on iteration time).

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

## References

[https://nholmber.github.io/2017/04/cp2k-build-cray-xc40/](https://nholmber.github.io/2017/04/cp2k-build-cray-xc40/)  
[https://xconfigure.readthedocs.io/cp2k/plan/](https://xconfigure.readthedocs.io/cp2k/plan/)  
[https://www.cp2k.org/static/downloads](https://www.cp2k.org/static/downloads)  
[https://www.cp2k.org/howto:compile](https://www.cp2k.org/howto:compile)
