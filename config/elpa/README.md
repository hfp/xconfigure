# ELPA<a name="eigenvalue-solvers-for-petaflop-applications-elpa"></a>

## Build Instructions

### ELPA 2021

[Download](https://elpa.mpcdf.mpg.de/software/tarball-archive/ELPA_TARBALL_ARCHIVE.html) and unpack ELPA and make the configure wrapper scripts available in ELPA's root folder. Consider CP2K's download area (cache) as an [alternative source](https://www.cp2k.org/static/downloads) for downloading ELPA.

**Note**: Please use [ELPA&#160;2017.11.001](#elpa-2017) for CP2K&#160;6.1.

```bash
echo "wget --content-disposition --no-check-certificate https://www.cp2k.org/static/downloads/elpa-2021.05.001.tar.gz"
wget --content-disposition --no-check-certificate https://elpa.mpcdf.mpg.de/software/tarball-archive/Releases/2021.05.002_bugfix/elpa-2021.05.002_bugfix.tar.gz
tar xvf elpa-2021.05.002_bugfix.tar.gz
cd elpa-2021.05.002_bugfix

wget --content-disposition --no-check-certificate https://github.com/hfp/xconfigure/raw/master/configure-get.sh
chmod +x configure-get.sh
./configure-get.sh elpa
```

Please make the Intel Compiler and Intel&#160;MKL available on the command line. This depends on the environment. For instance, many HPC centers rely on `module load`.

```bash
source /opt/intel/compilers_and_libraries_2020.4.304/linux/bin/compilervars.sh intel64
```

For example, to configure and make for an Intel Xeon Scalable processor ("SKX"):

```bash
make clean
./configure-elpa-skx-omp.sh
make -j ; make install

make clean
./configure-elpa-skx.sh
make -j ; make install
```

Even if ELPA was just unpacked (and never built before), `make clean` is recommended in advance of building ELPA ("unknown module file format"). After building and installing the desired configuration(s), one may have a look at the installation:

```bash
[user@system elpa-2021.05.002_bugfix]$ ls ../elpa
 intel-skx
 intel-skx-omp
```

For different targets (instruction set extensions) or for different versions of the Intel Compiler, the configure scripts support an additional argument ("default" is the default tagname):

```bash
./configure-elpa-skx-omp.sh tagname
```

As shown above, an arbitrary "tagname" can be given (without editing the script). This might be used to build multiple variants of the ELPA library.

### ELPA 2020

[Download](https://elpa.mpcdf.mpg.de/software/tarball-archive/ELPA_TARBALL_ARCHIVE.html) and unpack ELPA and make the configure wrapper scripts available in ELPA's root folder. Consider CP2K's download area (cache) as an [alternative source](https://www.cp2k.org/static/downloads) for downloading ELPA.

**Note**: Please use [ELPA&#160;2017.11.001](#elpa-2017) for CP2K&#160;6.1.

```bash
echo "wget --content-disposition --no-check-certificate https://elpa.mpcdf.mpg.de/software/tarball-archive/Releases/2020.11.001/elpa-2020.11.001.tar.gz"
wget --content-disposition --no-check-certificate https://www.cp2k.org/static/downloads/elpa-2020.11.001.tar.gz
tar xvf elpa-2020.11.001.tar.gz
cd elpa-2020.11.001

wget --content-disposition --no-check-certificate https://github.com/hfp/xconfigure/raw/master/configure-get.sh
chmod +x configure-get.sh
./configure-get.sh elpa
```

Please make the Intel Compiler and Intel&#160;MKL available on the command line. This depends on the environment. For instance, many HPC centers rely on `module load`.

```bash
source /opt/intel/compilers_and_libraries_2020.4.304/linux/bin/compilervars.sh intel64
```

For example, to configure and make for an Intel Xeon Scalable processor ("SKX"):

```bash
make clean
./configure-elpa-skx-omp.sh
make -j ; make install

make clean
./configure-elpa-skx.sh
make -j ; make install
```

Even if ELPA was just unpacked (and never built before), `make clean` is recommended in advance of building ELPA ("unknown module file format"). After building and installing the desired configuration(s), one may have a look at the installation:

```bash
[user@system elpa-2020.11.001]$ ls ../elpa
 intel-skx
 intel-skx-omp
```

### ELPA 2019

[Download](https://elpa.mpcdf.mpg.de/software/tarball-archive/ELPA_TARBALL_ARCHIVE.html) and unpack ELPA and make the configure wrapper scripts available in ELPA's root folder.

**Note**: Please use [ELPA&#160;2017.11.001](#elpa-2017) for CP2K&#160;6.1.

```bash
wget --content-disposition --no-check-certificate https://elpa.mpcdf.mpg.de/software/tarball-archive/Releases/2019.11.001/elpa-2019.11.001.tar.gz
tar xvf elpa-2019.11.001.tar.gz
cd elpa-2019.11.001

wget --content-disposition --no-check-certificate https://github.com/hfp/xconfigure/raw/master/configure-get.sh
chmod +x configure-get.sh
./configure-get.sh elpa
```

Please make the Intel Compiler and Intel&#160;MKL available on the command line. This depends on the environment. For instance, many HPC centers rely on `module load`.

```bash
source /opt/intel/compilers_and_libraries_2020.4.304/linux/bin/compilervars.sh intel64
```

For example, to configure and make for an Intel Xeon Scalable processor ("SKX"):

```bash
make clean
./configure-elpa-skx-omp.sh
make -j ; make install

make clean
./configure-elpa-skx.sh
make -j ; make install
```

Even if ELPA was just unpacked (and never built before), `make clean` is recommended in advance of building ELPA ("unknown module file format"). After building and installing the desired configuration(s), one may have a look at the installation:

```bash
[user@system elpa-2019.11.001]$ ls ../elpa
 intel-skx
 intel-skx-omp
```

### ELPA 2018

Please use [ELPA&#160;2017.11.001](#elpa-2017) for CP2K&#160;6.1. For CP2K&#160;7.1, please rely on [ELPA&#160;2019](#elpa-2019). ELPA&#160;2018 **fails or crashes in several regression tests** in CP2K (certain rank-counts produce an incorrect decomposition), and hence ELPA&#160;2018 should be avoided in production.

### ELPA 2017

[Download](https://elpa.mpcdf.mpg.de/software/tarball-archive/ELPA_TARBALL_ARCHIVE.html) and unpack ELPA and make the configure wrapper scripts available in ELPA's root folder. It is recommended to package the state (Tarball or similar), which is achieved after downloading the wrapper scripts.

**Note**: In Quantum Espresso, the __ELPA_2018 interface must be used for ELPA 2017.11 (`-D__ELPA_2018`). The __ELPA_2017 preprocessor definition triggers the ELPA1 legacy interface (get_elpa_row_col_comms, etc.), which was removed in ELPA&#160;2017.11. This is already considered when using XCONFIGURE's wrapper scripts.

```bash
wget --content-disposition --no-check-certificate https://elpa.mpcdf.mpg.de/software/tarball-archive/Releases/2017.11.001/elpa-2017.11.001.tar.gz
tar xvf elpa-2017.11.001.tar.gz
cd elpa-2017.11.001

wget --content-disposition --no-check-certificate https://github.com/hfp/xconfigure/raw/master/configure-get.sh
chmod +x configure-get.sh
./configure-get.sh elpa
```

Please make the Intel Compiler and Intel&#160;MKL available on the command line. This depends on the environment. For instance, many HPC centers rely on `module load`.

```bash
source /opt/intel/compilers_and_libraries_2020.4.304/linux/bin/compilervars.sh intel64
```

For example, to configure and make for an Intel Xeon Scalable processor ("SKX"):

```bash
make clean
./configure-elpa-skx-omp.sh
make -j ; make install

make clean
./configure-elpa-skx.sh
make -j ; make install
```

Even if ELPA was just unpacked (and never built before), `make clean` is recommended in advance of building ELPA ("unknown module file format").

## References

[https://github.com/cp2k/cp2k/blob/master/INSTALL.md#2l-elpa-optional-improved-performance-for-diagonalization](https://github.com/cp2k/cp2k/blob/master/INSTALL.md#2l-elpa-optional-improved-performance-for-diagonalization)  
[https://elpa.mpcdf.mpg.de/software/tarball-archive/ELPA_TARBALL_ARCHIVE.html](https://elpa.mpcdf.mpg.de/software/tarball-archive/ELPA_TARBALL_ARCHIVE.html)  
[https://www.cp2k.org/static/downloads](https://www.cp2k.org/static/downloads)

