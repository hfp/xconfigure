# LIBXC

To configure, build, and install [LIBXC](http://www.tddft.org/programs/octopus/wiki/index.php/Libxc:download), one may proceed as shown below.

```bash
wget http://www.tddft.org/programs/octopus/down.php?file=libxc/libxc-3.0.0.tar.gz
tar xvf libxc-3.0.0.tar.gz
cd libxc-3.0.0
wget --no-check-certificate https://github.com/hfp/xconfigure/raw/master/configure-get.sh
chmod +x configure-get.sh
./configure-get.sh libxc
```

Please make the Intel Compiler available on the command line. This depends on the environment. For instance, many HPC centers rely on `module load`.

```bash
source /opt/intel/compilers_and_libraries_2017.0.098/linux/bin/compilervars.sh intel64
```

For example, to configure and make for an Intel Xeon Scalable processor ("SKX"):

```bash
make distclean
./configure-libxc-skx.sh
make -j; make install
```

