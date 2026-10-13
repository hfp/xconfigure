# CP2K<a name="cp2k-open-source-molecular-dynamics"></a>

This document describes building CP2K with CMake and with dependencies built by XCONFIGURE. All packages are placed into a common directory (`$HOME` is assumed), and the dependencies are installed next to CP2K:

* [DBCSR](../dbcsr/README.md): `dbcsr/gnu-cpu`, `dbcsr/gnu-gpu`, etc. (required)
* [LIBWIGNERNJ](../libwignernj/README.md): `libwignernj/gnu` (required)
* [LIBINT](../libint/README.md#libint): `libint/gnu`
* [LIBXC](../libxc/README.md#libxc): `libxc/gnu`
* [LIBXS](https://github.com/hfp/libxs): `libxs` (required for GPUs)
* [LIBXSTREAM](https://github.com/hfp/libxstream): `libxstream` (GPUs)
* `cp2k`

The prerequisites are the GNU Compiler Collection, MPI (compiler wrappers `mpicc`, `mpicxx`, and `mpif90`), CMake, Python, and LAPACK/ScaLAPACK as well as FFTW, e.g., Intel&#160;MKL (`MKLROOT`).

## Build Instructions<a name="build-instructions"></a><a name="current-release"></a>

```bash
cd $HOME && git clone https://github.com/cp2k/cp2k.git
cd cp2k

wget --content-disposition https://github.com/hfp/xconfigure/raw/main/configure-get.sh
chmod +x configure-get.sh
./configure-get.sh cp2k
```

To configure, build, and install CP2K (`../cp2k/gnu-cpu`), or CP2K with GPU support by the means of OpenCL (`../cp2k/gnu-gpu`):

```bash
./configure-cp2k.sh
cmake --build build-gnu-cpu --target install -j $(nproc)

./configure-cp2k-gpu.sh
cmake --build build-gnu-gpu --target install -j $(nproc)
```

For each dependency, the first of `../<name>/gnu-cpu` (`gnu-gpu`), `../<name>/gnu`, and `../<name>` containing a CMake or pkg-config package is used, and the corresponding feature of CP2K is enabled. For example, `dbcsr/gnu` can be a symbolic link to the desired flavor of DBCSR. The found locations are printed when configuring CP2K. Further dependencies can be supplied using the `CMAKE_PREFIX_PATH` environment variable, and arguments after an optional "tagname" (default: `gnu`) are passed to CMake:

```bash
CMAKE_PREFIX_PATH=$HOME/elpa/gnu ./configure-cp2k.sh gnu -DCP2K_USE_ELPA=ON
```

Code is generated for the system running the script (`-march=native`), i.e., a build system matching the target system is assumed.

## CP2K on GPUs

The OpenCL support enables DBCSR's OpenCL backend as well as CP2K's GPU-enabled DBM/DBT component. The OpenCL backend has comprehensive runtime-control by the means of [environment variables](https://cp2k.github.io/dbcsr/develop/page/3-developer-guide/3-programming/2-accelerator-backend/3-libsmm_ocl/index.html). This can be used to assign OpenCL devices, to aggregate sub-devices (devices are split into sub-devices by default), to extract kernel shapes used by a specific workload, and to subsequently tune specific kernels. DBCSR as well as CP2K's DBM component (`src/dbm`) can be exercised in a standalone fashion.

## Running CP2K<a name="run-instructions"></a><a name="performance"></a>

<a name="running-the-application"></a>Running CP2K may go beyond a single node, and pinning processes and threads become even more important. There are several schemes available. As a rule of thumb, a high rank-count for lower node-counts may yield best results unless the workload is very memory intensive. In the latter case, lowering the number of MPI-ranks per node is effective especially if a larger amount of memory is replicated rather than partitioned by the rank-count. In contrast (communication bound), a lower rank count for multi-node computations may be desired. To ease running CP2K, there are a number of supportive scripts provided by XCONFIGURE: `plan.sh` (see [here](plan.md)), `run.sh` (see [here](https://raw.githubusercontent.com/hfp/xconfigure/main/config/cp2k/run.sh)), and `info.sh`. The run-script executes `../cp2k/gnu/bin/cp2k.psmp` (e.g., `CP2K_BUILD=gnu-gpu` selects another installation, and `EXE` selects an executable).

<a name="info-script"></a>As soon as several experiments are finished, it becomes handy to summarize the log-output. For this case, an info-script (`info.sh`) is available attempting to present a table (summary of all results), which is generated from log files (`.txt` and `.out` extension by default). Log files can be captured with "tee", or the output is captured by the job scheduler.

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
