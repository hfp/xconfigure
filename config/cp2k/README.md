# CP2K

## Build and Run Instructions

The build and run instructions for CP2K using Intel Software Development Tools are exercised at 
[http://libxsmm.readthedocs.io/cp2k/](http://libxsmm.readthedocs.io/cp2k/) ([PDF](https://github.com/hfp/libxsmm/raw/master/documentation/cp2k.pdf)). In terms of functionality (and performance) it is beneficial to rely on [LIBINT](../libint/README.md#libint) and [LIBXC](../libxc/README.md#libxc), whereas [ELPA](../elpa/README.md#eigenvalue-solvers-for-petaflop-applications-elpa) eventually improves the performance. For high performance, it is strongly recommended to use [LIBXSMM](../libxsmm/README.md#libxsmm).

There are no configuration wrapper scripts provided for CP2K, please rely on the afore mentioned recipe (URLs). However, attempting to run below command yields an [info-script](#performance):

```bash
wget --no-check-certificate https://github.com/hfp/xconfigure/raw/master/configure-get.sh
chmod +x configure-get.sh
./configure-get.sh cp2k
```

Of course, the above can be simplified:

```bash
wget --no-check-certificate https://github.com/hfp/xconfigure/raw/master/config/cp2k/info.sh
chmod +x info.sh
```

## Sanity Check

There are the following Intel compiler releases, which are known to reproduce correct results:

* Intel Compiler 2017 (**any**), and the **initial** release of MKL&#160;2017 ("update 0")
    * source /opt/intel/compilers_and_libraries_2017.[*whatever*]/linux/bin/compilervars.sh intel64
    * source /opt/intel/compilers_and_libraries_2017.0.098/linux/mkl/bin/mklvars.sh intel64
* Intel Compiler 2017 Update 4, and any later update of the 2017 suite
    * source /opt/intel/compilers_and_libraries_2017.4.196/linux/bin/compilervars.sh intel64
    * source /opt/intel/compilers_and_libraries_2017.5.239/linux/bin/compilervars.sh intel64

Intel Compiler&#160;2018 suite is not validated. There is nothing that can replace the full regression test suite - just to be clear. However, to quickly check whether a build is sane or not, one can run for instance `tests/QS/benchmark/H2O-64.inp` and check if the SCF iteration prints like the following:

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

An info-script (`info.sh`) is available attempting to present a table (summary of all results), which is generated from log files (use `tee`, or rely on the output of the job scheduler). There are only certain file extensions supported (`.txt`, `.log`). If no file matches, then all files (independent of the file extension) are attempted to be parsed (which will go wrong eventually). For legacy reasons (run command is not part of the log, etc.), certain schemes for the filename are eventually parsed and translated as well.

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

[http://libxsmm.readthedocs.io/cp2k/](http://libxsmm.readthedocs.io/cp2k/)

