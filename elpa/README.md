## Eigenvalue SoLvers for Petaflop-Applications (ELPA)
[Download](http://elpa.mpcdf.mpg.de/elpa-tar-archive) and unpack ELPA, and make the configure wrapper scripts available in ELPA's root folder.

```
wget http://elpa.mpcdf.mpg.de/html/Releases/2016.05.004/elpa-2016.05.004.tar.gz
tar xvf elpa-2016.05.004.tar.gz
cd elpa-2016.05.004
wget https://github.com/hfp/xconfigure/raw/master/configure-get.sh
chmod +x configure-get.sh
./configure-get.sh elpa
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

For a further reference, one may have a look at  
https://software.intel.com/en-us/articles/quantum-espresso-for-the-intel-xeon-phi-processor.
