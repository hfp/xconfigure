# QE<a name="#quantum-espresso-qe"></a><a name="#quantum-espresso"></a>

## Build Instructions

[Download](http://www.qe-forge.org/gf/project/q-e/frs/) and unpack [Quantum Espresso](http://www.quantum-espresso.org/), and make the configure wrapper scripts available in QE's root folder. Please note that the configure wrapper scripts support QE&#160;6.x (prior support for 5.x is dropped). Before building QE, one needs to complete the recipe for [ELPA](../elpa/README.md).

<a name="note"></a>**NOTE**: the ELPA configuration must correspond to the desired QE configuration e.g., `configure-elpa-skx-omp.sh` and `configure-qe-skx-omp.sh` ("omp"). The version ELPA&#160;2017.11.001 (and later) removed some bits from the ELPA1 legacy interface needed by QE (get_elpa_row_col_comms, etc.), hence ELPA&#160;2017.05.003 is the latest supported version!

```bash
http://www.qe-forge.org/gf/download/frsrelease/247/1132/qe-6.2.1.tar.gz
tar xvf qe-6.2.1.tar.gz
cd qe-6.2.1
wget --no-check-certificate https://github.com/hfp/xconfigure/raw/master/configure-get.sh
chmod +x configure-get.sh
./configure-get.sh qe
```

Please make the Intel Compiler available on the command line, which may vary with the computing environment. For instance, many HPC centers rely on `module load`.

```bash
source /opt/intel/compilers_and_libraries_2017.4.196/linux/bin/compilervars.sh intel64
```

For example, configure for an Intel Xeon&#160;E5v4 processor (formerly codenamed "Broadwell"), and build the desired application(s) e.g., "pw", "cp", or "all".

```bash
./configure-qe-hsw-omp.sh
make pw -j
```

Building "all" (or `make` without target argument) requires to repeat `make all` until no compilation error occurs. This is because of some incorrect build dependencies (build order issue which might have been introduced by the configure wrapper scripts). In case of starting over, one can run `make distclean`, reconfigure the application, and build it again. For different targets (instruction set extensions) or different versions of the Intel Compiler, the configure scripts support an additional argument ("default" is the default tagname):

```bash
./configure-qe-hsw-omp.sh tagname
```

As shown above, an arbitrary "tagname" can be given (without editing the script). This might be used to build multiple variants of QE. Please note: this tagname also selects the corresponding ELPA library (or should match the tagname used to build ELPA). Make sure to save your current QE build before building an additional variant!

## Run Instructions

To run Quantum Espresso in an optimal fashion depends on the workload and on the "parallelization levels", which can be exploited by the workload in question. These parallelization levels apply to execution phases (or major algorithms) rather than staying in a hierarchical relationship (levels). It is recommended to read some of the [primary references](http://www.quantum-espresso.org/wp-content/uploads/Doc/user_guide/node18.html) explaining these parallelization levels (a number of them can be found in the Internet including some presentation slides). Time to solution may *vary by factors* depending on whether these levels are orchestrated or not. To specify these levels, one uses command line arguments along with the QE executable(s):

* **`-npool`**: try to maximize the number of pools. The number depends on the workload e.g., if the number of k-points can be distributed among independent pools. Indeed, trial and error is a rather quick to check if workload fails to pass the initialization phase. One may use prime numbers: *2*, *3*, *5*, etc. (default is *1*). For example, when *npool=2* worked it might be worth trying *npool=4*. On the other hand, increasing the number pools duplicates the memory consumption accordingly (larger numbers are increasingly unlikely to work).
* **`-ndiag`**: this number determines the number of ranks per pool used for dense linear algebra operations (DGEMM and ZGEMM). For example, if *64* ranks are used in total per node and *npool=2*, then put *ndiag=32* (QE selects the next square number which is less-equal than the given number e.g., *ndiag=25* in the previous example).
* **`-ntg`**: specifies the number of tasks groups per pool being used for e.g., FFTs. One can start with `NTG=$((NUMNODES*NRANKS/(NPOOL*2)))`. If `NTG` becomes zero, `NTG=${NRANKS}` should be used (number of ranks per node). Please note the given formula is only a rule of thumb, and the number of task groups also depends on the number of ranks as the workload is scaled out.

To run QE, below command line can be a starting point ("numbers" are presented as Shell variables to better understand the inner mechanics). Important for hybrid builds (MPI and OpenMP together) are the given environment variables. The `KMP_AFFINITY` assumes Hyperthreading (SMT) is enabled (granularity=fine), and the "scatter" policy allows to easily run less than the maximum number of Hyperthreads per core. As a rule of thumb, OpenMP adds only little overhead (often not worth a pure MPI application) but allows to scale further out when compared to pure MPI builds.

```bash
mpirun -bootstrap ssh -genvall \
  -np $((NRANKS_PER_NODE*NUMNODES)) -perhost ${NRANKS} \
  -genv I_MPI_PIN_DOMAIN=auto -genv I_MPI_PIN_ORDER=bunch \
  -genv KMP_AFFINITY=compact,granularity=fine,1 \
  -genv OMP_NUM_THREADS=${NTHREADS_PER_RANK} \
  /path/to/pw.x \<command-line-arguments\>
```

## Performance

An info-script is available attempting to present a table (summary of all results), which is generated from log files (use `tee`, or rely on the output of the job scheduler). There are only certain file extensions supported (`.txt`, `.log`). If no file matches, then all files (independent of the file extension) are attempted to be parsed (which will go wrong eventually). For legacy reasons (run command is not part of the log, etc.), certain schemes for the filename are eventually parsed and translated as well.

```bash
./run-qe.sh | tee qe-asrf112-2x16x2.txt
ls -1 *.txt
qe-asrf112-2x16x2.txt
qe-asrf112-4x16x2.txt

./info.sh
AUSURF112         Nodes R/N T/R Cases/d Seconds NPOOL NDIAG NTG
qe-asrf112-2x16x2 2      32   2     533  162.35     2    25  32
qe-asrf112-4x16x2 4      16   4     714  121.82     2    25  32
```

Please note that the number of cases per day (Cases/d) are currently calculated with integer arithmetic and eventually lower than just rounding down (based on 86400 seconds per day). The number of seconds taken are end-to-end (wall time), i.e. total time to solution including any (sequential) phase in QE (initialization, etc.). Performance is higher if the workload requires more iterations (some publications present a metric based on iteration time).

## References

[https://software.intel.com/en-us/articles/quantum-espresso-for-the-intel-xeon-phi-processor](https://software.intel.com/en-us/articles/quantum-espresso-for-the-intel-xeon-phi-processor)  
[http://www.quantum-espresso.org/wp-content/uploads/Doc/user_guide/node18.html](http://www.quantum-espresso.org/wp-content/uploads/Doc/user_guide/node18.html)

