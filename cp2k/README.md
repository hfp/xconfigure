## CP2K

### Build and Run Instructions
The build and run instructions for CP2K using Intel Tools are exercised at  
https://github.com/hfp/libxsmm/tree/master/documentation/cp2k.md ([pdf](https://raw.githubusercontent.com/hfp/libxsmm/master/documentation/cp2k.pdf)).

Please note, in terms of functionality it is beneficial to rely on [LIBINT](../libint#libint) and [LIBXC](../libxc#libxc), whereas [ELPA](../elpa#eigenvalue-solvers-for-petaflop-applications-elpa) eventually provides an improved performance.

### Sanity Check
There is nothing that can replace the full regression test suite to be clear. However in order to quickly check whether a build is sane or not, one can run for instance `tests/QS/benchmark/H2O-64.inp` and check if the SCF iteration prints like the following:

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

The column called "Convergence" has to monotonically converge towards zero.
