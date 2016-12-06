## Quantum Espresso (QE)

### Build Instructions
[Download](http://www.qe-forge.org/gf/project/q-e/frs/) and unpack [Quantum Espresso](http://www.quantum-espresso.org/), and make the configure wrapper scripts available in QE's root folder. However, before one needs to complete the [ELPA build recipe](../elpa#eigenvalue-solvers-for-petaflop-applications-elpa)!

```
wget http://www.qe-forge.org/gf/download/frsrelease/224/1044/qe-6.0.tar.gz
tar xvf qe-6.0.tar.gz
cd qe-6.0
wget https://github.com/hfp/xconfigure/raw/master/configure-get.sh
chmod +x configure-get.sh
./configure-get.sh qe
```

Please make the Intel Compiler available on the command line. This actually depends on the environment. For instance, many HPC centers rely on `module load`.

```
source /opt/intel/compilers_and_libraries_2017.0.098/linux/bin/compilervars.sh intel64
```

For example, configure for an Intel Xeon E5v4 processor (formerly codenamed "Broadwell"), and build the desired application(s) e.g., "pw", "cp", or "all".

```
./configure-qe-hsw-omp.sh
make pw -j
```

In case of starting over, one might run `make distclean`, reconfigure the application, and build it again. For different targets (instruction set extensions) or different versions of the Intel Compiler, the configure scripts support an additional argument ("default" is the default tagname):

```
./configure-qe-hsw-omp.sh tagname
```

As shown above, an arbitrary "tagname" can be given (without editing the script). This might be used to build multiple variants of QE. Please note: this tagname also selects the corresponding ELPA library (or should match the tagname used to build ELPA). Make sure to save your current QE build before building an additional variant!

### Run Instructions
TBD

### References
https://software.intel.com/en-us/articles/quantum-espresso-for-the-intel-xeon-phi-processor
