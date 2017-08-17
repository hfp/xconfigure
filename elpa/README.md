## Eigenvalue SoLvers for Petaflop-Applications (ELPA)

### Build Instructions

#### ELPA 2017.05.001
[Download](http://elpa.mpcdf.mpg.de/elpa-tar-archive) and unpack ELPA, and make the configure wrapper scripts available in ELPA's root folder. It is recommended to package the state (Tarball or similar), which is achieved after downloading the wrapper scripts.

```
wget http://elpa.mpcdf.mpg.de/html/Releases/2017.05.001/elpa-2017.05.001.tar.gz
tar xvf elpa-2017.05.001.tar.gz
cd elpa-2017.05.001
wget --no-check-certificate https://github.com/hfp/xconfigure/raw/master/configure-get.sh
chmod +x configure-get.sh
./configure-get.sh elpa
```

Please make the Intel Compiler and Intel&#160;MKL available on the command line. This depends on the environment. For instance, many HPC centers rely on `module load`.

```
source /opt/intel/compilers_and_libraries_2017.4.196/linux/bin/compilervars.sh intel64
```

For example, to configure and make for an Intel Xeon&#160;E5v4 processor (formerly codenamed "Broadwell"):

```
make clean
./configure-elpa-hsw-omp.sh
make -j ; make install

make clean
./configure-elpa-hsw.sh
make -j ; make install
```

After building and installing the desired configuration(s), one may have a look at the installation:

```
[user@system elpa-2017.05.001]$ ls ../elpa
 default-hsw
 default-hsw-omp
```

For different targets (instruction set extensions) or for different versions of the Intel Compiler, the configure scripts support an additional argument ("default" is the default tagname):

```
./configure-elpa-hsw-omp.sh tagname
```

As shown above, an arbitrary "tagname" can be given (without editing the script). This might be used to build multiple variants of the ELPA library.

#### ELPA 2016.11.001
[Download](http://elpa.mpcdf.mpg.de/elpa-tar-archive) and unpack ELPA, and make the configure wrapper scripts available in ELPA's root folder. It is recommended to package the state (Tarball or similar), which is achieved after downloading the wrapper scripts. It appears that ELPA's `make clean` (or similar Makefile target) is cleaning up the entire directory including all "non-ELPA content" (the directory remains unclean such that subsequent builds may fail).

```
wget http://elpa.mpcdf.mpg.de/html/Releases/2016.11.001.pre/elpa-2016.11.001.pre.tar.gz
tar xvf elpa-2016.11.001.pre.tar.gz
cd elpa-2016.11.001.pre
wget --no-check-certificate https://github.com/hfp/xconfigure/raw/master/configure-get.sh
chmod +x configure-get.sh
./configure-get.sh elpa
```

Please make the Intel Compiler and Intel&#160;MKL available on the command line. This depends on the environment. For instance, many HPC centers rely on `module load`.

```
source /opt/intel/compilers_and_libraries_2017.4.196/linux/bin/compilervars.sh intel64
```

For example, to configure and make for an Intel Xeon E5v4 processor (formerly codenamed "Broadwell"):

```
./configure-elpa-hsw-omp.sh
make -j ; make install
```

#### ELPA Development Version

To rely on experimental functionality, one may git-clone the master branch of the ELPA repository instead of downloading a regular version.

```
git clone --branch ELPA_KNL https://gitlab.mpcdf.mpg.de/elpa/elpa.git
```

### References
[https://software.intel.com/en-us/articles/quantum-espresso-for-the-intel-xeon-phi-processor](https://software.intel.com/en-us/articles/quantum-espresso-for-the-intel-xeon-phi-processor)
[http://libxsmm.readthedocs.io/en/latest/cp2k/](http://libxsmm.readthedocs.io/en/latest/cp2k/)

