# CP2K

## Build and Run Instructions

The build and run instructions for CP2K using Intel Software Development Tools are exercised at 
[http://libxsmm.readthedocs.io/cp2k/](http://libxsmm.readthedocs.io/cp2k/) ([pdf](https://github.com/hfp/libxsmm/raw/master/documentation/cp2k.pdf)).

Please note, in terms of functionality it is beneficial to rely on [LIBINT](../libint/README.md#libint) and [LIBXC](../libxc/README.md#libxc), whereas [ELPA](../elpa/README.md#eigenvalue-solvers-for-petaflop-applications-elpa) eventually improves the performance. For high performance, it is strongly recommended to make use of [LIBXSMM](../libxsmm/README.md#libxsmm).

## Sanity Check

There are the following Intel compiler releases, which are known to reproduce correct results:

* Intel Compiler 2017 (**any**), and the **initial** release of MKL&#160;2017 ("update 0")
  * source /opt/intel/compilers_and_libraries_2017.[*whatever*]/linux/bin/compilervars.sh intel64
  * source /opt/intel/compilers_and_libraries_2017.0.098/linux/mkl/bin/mklvars.sh intel64
* Intel Compiler 2017 Update 4, and any later update of the 2017 suite
  * source /opt/intel/compilers_and_libraries_2017.4.196/linux/bin/compilervars.sh intel64
  * source /opt/intel/compilers_and_libraries_2017.5.239/linux/bin/compilervars.sh intel64

At this time, Intel Compiler&#160;2018 suite is not validated. There is nothing that can replace the full regression test suite - just to be clear. However, to quickly check whether a build is sane or not, one can run for instance `tests/QS/benchmark/H2O-64.inp` and check if the SCF iteration prints like the following:

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

The column called "Convergence" has to monotonically converge towards zero.

## References

[http://libxsmm.readthedocs.io/cp2k/](http://libxsmm.readthedocs.io/cp2k/)

