# CP2K<a name="cp2k-open-source-molecular-dynamics"></a>

This document describes building CP2K with several (optional) libraries, which may be beneficial for functionality or performance.

* [**LIBXSMM**](https://github.com/libxsmm/libxsmm) targets DBCSR, DBM/DBT, GRID, and other components
* [**LIBINT**](../libint/README.md#libint) enables a wide range of workloads (almost necessary)
* [**LIBXC**](../libxc/README.md#libxc) enables exchange-correlation functionals for DFT
* **MPI** is auto-detected (Intel MPI and OpenMPI supported)
* **MKL** or Intel Math Kernel Library (also per Linux distro's package manager):
    * Provides LAPACK/BLAS and ScaLAPACK library
    * Provides FFTw library
* [ELPA](../elpa/README.md#eigenvalue-solvers-for-petaflop-applications-elpa) for matrix diagonalization

For functionality and performance, all **bold** dependencies are almost necessary or highly recommended. For instance, [LIBXSMM](../libxsmm/README.md#libxsmm) (see also [https://libxsmm.readthedocs.io](https://libxsmm.readthedocs.io)) has been incorporated since [CP2K&#160;3.0](https://www.cp2k.org/version_history) and enables high performance in several components of CP2K. The ELPA library eventually improves the performance over ScaLAPACK (also refer to `PREFERRED_DIAG_LIBRARY` in [CP2K's Input Reference](https://manual.cp2k.org/trunk/CP2K_INPUT.html)).

**Note**: CP2K's `install_cp2k_toolchain.sh` (under `tools/toolchain`) as well as CMake based builds are out of scope in this document (see [official guide](https://www.cp2k.org/howto:compile)).

For CP2K, XCONFIGURE provides a collection of helper scripts, optional patches, and an ARCH-file supporting:

* GNU Compiler Collection (default if `ifx` or `ifort` are not available, explicit with `make ARCH=Linux-x86-64-intelx VERSION=psmp GNU=1`)
* Intel Compiler (default if `ifx` is available, explicit with `make ARCH=Linux-x86-64-intelx VERSION=psmp INTEL=2`)

**Note**: Intel Classic Compiler is used by default if `ifort` is available but `ifx` or `gfortran` are not available, and it can be explicitly selected with `make ARCH=Linux-x86-64-intelx VERSION=psmp INTEL=1`).

## Step-by-step Guide<a name="current-release"></a>

This step-by-step guide assumes the GNU Compiler Collection (GNU&#160;Fortran), Intel&#160;MPI and Intel&#160;MKL as prerequisites (adding an Intel repository to the Linux distribution's package manager, installing Intel MKL and Intel MPI or supporting an HPC fabric is out of scope in this document. is not subject of this document). Building LIBXSMM, LIBINT, and LIBXC is part of the steps.

<a name="offline-environment"></a>**Note**: in an offline-environment, it is best to [download](https://github.com/hfp/xconfigure/archive/refs/heads/main.zip) the entire XCONFIGURE project upfront and upload to the target system. Offline limitations can be worked around and overcome with additional steps. This step-by-step guide assumes Internet connectivity.

**1**) <a name="getting-started"></a>First, please download `configure-get.sh` to any location and make the prerequisites available (GNU Compiler Collection, Intel MPI and Intel MKL):

```bash
wget https://github.com/hfp/xconfigure/raw/main/configure-get.sh
chmod +x configure-get.sh

source /opt/intel/oneapi/mpi/latest/env/vars.sh
source /opt/intel/oneapi/mkl/latest/env/vars.sh
```

For the following steps, it is necessary to place LIBINT, LIBXC, LIBXSMM, and CP2K into a common directory (`$HOME` is assumed).

**2**) <a name="libint-and-libxc-dependencies"></a>The second step builds a LIBINT which is already [preconfigured](https://github.com/cp2k/libint-cp2k/releases) for CP2K. To fully [bootstrap LIBINT](../libint/README.md#boostrap-for-cp2k) is out of scope for this step.

```bash
cd $HOME && curl -s https://api.github.com/repos/cp2k/libint-cp2k/releases/latest \
| grep "browser_download_url" | grep "lmax-6" \
| sed "s/..*: \"\(..*[^\"]\)\".*/url \1/" \
| curl -LOK-
```

A rate limit applies to anonymous GitHub API requests of the same origin. If the download fails, it can be worth trying an authenticated request relying on a GitHub account (`-u "user:password"`).

```bash
cd $HOME && tar xvf libint-v2.6.0-cp2k-lmax-6.tgz
rm libint-v2.6.0-cp2k-lmax-6.tgz
cd libint-v2.6.0-cp2k-lmax-6

/path/to/configure-get.sh libint
./configure-libint-gnu.sh

make -j $(nproc)
make install
make distclean
```

There can be issues about target flags requiring a build-system able to execute compiled binaries. To avoid cross-compilation (not supported here), please rely on a build-host matching the capabilities of the target system.

**3**) The third step builds LIBXC.

```bash
cd $HOME && wget https://gitlab.com/libxc/libxc/-/archive/6.2.2/libxc-6.2.2.tar.bz2
tar xvf libxc-6.2.2.tar.bz2

rm libxc-6.2.2.tar.bz2
cd libxc-6.2.2

/path/to/configure-get.sh libxc
./configure-libxc-gnu.sh

make -j $(nproc)
make install
make distclean
```

During configuration, please disregard any messages suggesting `libtoolize --force`.

**4**) The fourth step makes LIBXSMM available, which is compiled as part of the last step.

```bash
#cd $HOME && git clone https://github.com/libxsmm/libxsmm.git && cd libxsmm && git checkout develop
cd $HOME && wget https://github.com/libxsmm/libxsmm/archive/refs/heads/develop.zip
mkdir libxsmm && cd libxsmm && unzip $HOME/libxsmm-develop.zip
#make GNU=1 -j $(nproc)
```

It can be useful to build LIBXSMM also in a separate fashion (see last/commented line above). This can be useful for building a stand-alone reproducer in DBCSR's GPU backend as well as CP2K's DBM reproducer.

**5**) <a name="getting-the-source-code"></a>This last step builds CP2K and LIBXSMM inside of CP2K's source directory. A serial version `VERSION=ssmp` as opposed to `VERSION=psmp` is possible, however OpenMP remains a requirement of CP2K's code base.

<a name="missing-git-submodules"></a>Downloading GitHub-generated assets from from [https://github.com/cp2k/cp2k/releases](https://github.com/cp2k/cp2k/releases) like "*Source code (zip)*" or "*Source code (tar.gz)*" will miss submodules which are subsequently missed when building CP2K.

```bash
cd $HOME && git clone https://github.com/cp2k/cp2k.git
cd $HOME/cp2k && git pull && git submodule update --init --recursive
cd $HOME/cp2k/exts/dbcsr && git checkout develop && git pull

cd $HOME/cp2k && /path/to/configure-get.sh cp2k
```

Applying XCONFIGURE for CP2K in an offline-environment is out of scope here, but one can `cp /path/to/xconfigure/config/cp2k/*.sh /path/to/cp2k`, `cp /path/to/xconfigure/config/cp2k/Linux-x86-64-intelx.* /path/to/cp2k/arch`, and eventually `git apply cpassert.git.diff`.

<a name="build-instructions"></a>Building CP2K proceeds with:

```bash
rm -rf exe lib obj
make -j $(nproc) \
  ARCH=Linux-x86-64-intelx VERSION=psmp cp2k \
  GNU=1
```

The initial output of the build looks like:

```text
Discovering programs ...
================================================================================
Using the following libraries:
LIBXSMMROOT=/path/to/libxsmm
LIBINTROOT=/path/to/libint/gnu
LIBXCROOT=/path/to/libxc/gnu
================================================================================
LIBXSMM develop (Linux)
--------------------------------------------------------------------------------
```

Once the build is completed, the CP2K executable is ready (`exe/Linux-x86-64-intelx/cp2k.psmp`):

```text
$ LIBXSMM_VERBOSE=1 exe/Linux-x86-64-intelx/cp2k.psmp
  [...]
  LIBXSMM_VERSION: develop
  LIBXSMM_TARGET: spr
```

The ARCH-file attempts to auto-detect optional libraries using `I_MPI_ROOT`, `MKLROOT` environment variables as well as searching certain standard locations. LIBXSMM, LIBINT, and LIBXC are expected in directories parallel to CP2K's root directory. In general, build-keys such as `LIBXSMMMROOT`, `LIBINTROOT`, `LIBXCROOT`, `ELPAROOT`, and others are supported.

## CP2K on GPUs

Please simply apply `USE_ACCEL=opencl` (like `USE_ACCEL=cuda` for CUDA) to XCONFIGURE's [build instructions](#build-instructions). The OpenCL support enables DBCSR's OpenCL backend as well as CP2K's GPU-enabled DBM/DBT component.

Further, DBCSR can be built stand-alone and used to exercise and test GPU accleration as well, which is not subject of XCONFIGURE. Further, within DBCSR some driver code exists to exercise GPU performance in a stand-alone fashion (does not even rely on DBCSR's build system; see [DBCSR ACCelerator Interface](https://cp2k.github.io/dbcsr/develop/page/3-developer-guide/3-programming/2-accelerator-backend/index.html)). The OpenCL backend in DBCSR provides [pretuned kernels](https://github.com/cp2k/dbcsr/tree/develop/src/acc/opencl/smm/params) for CP2K. Similarly, CP2K's DBM component (`/path/to/cp2k/src/dbm`) can be built and exercised in a stand-alone fashion.

The OpenCL backend has comprehensive runtime-control by the means of [environment variables](https://cp2k.github.io/dbcsr/develop/page/3-developer-guide/3-programming/2-accelerator-backend/3-libsmm_ocl/index.html). This can be used to assign OpenCL devices, to aggregate sub-devices (devices are split into sub-devices by default), to extract kernel shapes used by a specific workload, and to subsequently tune specific kernels.

## Running CP2K<a name="run-instructions"></a><a name="performance"></a>

<a name="running-the-application"></a>Running CP2K may go beyond a single node, and pinning processes and threads becomes even more important. There are several schemes available. As a rule of thumb, a high rank-count for lower node-counts may yield best results unless the workload is very memory intensive. In the latter case, lowering the number of MPI-ranks per node is effective especially if a larger amount of memory is replicated rather than partitioned by the rank-count. In contrast (communication bound), a lower rank count for multi-node computations may be desired. To ease running CP2K, there are a number of supportive scripts provided by XCONFIGURE: `plan.sh` (see [here](plan.md)), `run.sh` (see [here](https://raw.githubusercontent.com/hfp/xconfigure/main/config/cp2k/run.sh)), and `info.sh`.

<a name="info-script"></a>As soon as several experiments are finished, it becomes handy to summarize the log-output. For this case, an info-script (`info.sh`) is available attempting to present a table (summary of all results), which is generated from log files (`.txt` and `.out` extension by default). Log files can be captured with `tee`, or the output is captured by the job scheduler.

```text
./run.sh benchmarks/QS/H2O-64.inp | tee cp2k-h2o64-20240725b.txt
ls -1 *.txt
cp2k-h2o64-20240725a.txt
cp2k-h2o64-20240725b.txt

./info.sh [-best] [/path/to/logs]
H2O-64               Nodes R/N T/R Cases/d Seconds
cp2k-h2o64-20240725a 2      32   4     807 107.237
cp2k-h2o64-20240725b 4      16   8     872  99.962
```

**Note**: the "*Cases/d*" metric is calculated with integer arithmetic and hence represents fully completed cases per day (based on 86400 seconds per day). The number of seconds (as shown) is end-to-end (wall time), i.e., total time to solution including any (sequential) phase (initialization, etc.). Performance is higher if the workload requires more iterations (some publications present a metric based on iteration time).

## Sanity Check

There is nothing that can replace the full regression test suite. However, to quickly check whether a build is sane or not, one can run for instance `benchmarks/QS/H2O-64.inp` and check if the SCF iteration prints like the following:

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

The column called "*Convergence*" must monotonically converge towards zero.

## References

[https://nholmber.github.io/2017/04/cp2k-build-cray-xc40/](https://nholmber.github.io/2017/04/cp2k-build-cray-xc40/)  
[https://xconfigure.readthedocs.io/cp2k/plan/](https://xconfigure.readthedocs.io/cp2k/plan/)  
[https://www.cp2k.org/static/downloads](https://www.cp2k.org/static/downloads)  
[https://www.cp2k.org/howto:compile](https://www.cp2k.org/howto:compile)
