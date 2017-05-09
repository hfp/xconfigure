## Eigenvalue SoLvers for Petaflop-Applications (ELPA)

### Build Instructions
[Download](http://elpa.mpcdf.mpg.de/elpa-tar-archive) and unpack ELPA, and make the configure wrapper scripts available in ELPA's root folder. It is recommended to package the state (Tarball or similar), which is achieved after downloading the wrapper scripts. It appears that ELPA's `make clean` (or simliar Makefile target) is cleaning up the entire directory including all "non-ELPA content" (the directory still remains unclean enough to make subsequent builds unsuccessful).

```
wget http://elpa.mpcdf.mpg.de/html/Releases/2016.11.001.pre/elpa-2016.11.001.pre.tar.gz
tar xvf elpa-2016.11.001.pre.tar.gz
cd elpa-2016.11.001.pre
wget --no-check-certificate https://github.com/hfp/xconfigure/raw/master/configure-get.sh
chmod +x configure-get.sh
./configure-get.sh elpa
```

To rely on experimental Intel AVX-512 kernels, one may git-clone the KNL-branch of the ELPA repository instead of downloading the version mentioned above. It appears that these kernels settle with foundational instructions (MIC/KNL and Core/SKX are fine).

```
git clone --branch ELPA_KNL https://gitlab.mpcdf.mpg.de/elpa/elpa.git
```

Please make the Intel Compiler available on the command line. This actually depends on the environment. For instance, many HPC centers rely on `module load`.

```
source /opt/intel/compilers_and_libraries_2017.0.098/linux/bin/compilervars.sh intel64
```

For example, to configure and make for an Intel Xeon E5v4 processor (formerly codenamed "Broadwell"):

```
./configure-elpa-hsw-omp.sh
make -j ; make install
```

For different targets (instruction set extensions) or different versions of the Intel Compiler, the configure scripts support an additional argument ("default" is the default tagname):

```
./configure-elpa-hsw-omp.sh tagname
```

As shown above, an arbitrary "tagname" can be given (without editing the script). This might be used to build multiple variants of the ELPA library.

### References
https://software.intel.com/en-us/articles/quantum-espresso-for-the-intel-xeon-phi-processor
