# LIBXC

To configure, build, and install [LIBXC](http://www.tddft.org/programs/octopus/wiki/index.php/Libxc:download) 2.x, 3.x, and 4.x, one may proceed as shown below. Please note that CP2K&#160;5.0 (and 4.x) are only compatible with LIBXC&#160;3.0 (or earlier, see also [How to compile the CP2K code](https://www.cp2k.org/howto:compile#k_libxc_optional_wider_choice_of_xc_functionals)). The CP2K development version (after 5.x and later) as well as the Intel branch (shortly prior to 5.x and later) support LIBXC&#160;4.x.

```bash
wget --content-disposition http://www.tddft.org/programs/octopus/down.php?file=libxc/4.0.1/libxc-4.0.1.tar.gz
tar xvf libxc-4.0.1.tar.gz
cd libxc-4.0.1
wget --no-check-certificate https://github.com/hfp/xconfigure/raw/master/configure-get.sh
chmod +x configure-get.sh
./configure-get.sh libxc
```

Please make the Intel Compiler available on the command line. This depends on the environment. For instance, many HPC centers rely on `module load`.

```bash
source /opt/intel/compilers_and_libraries_2017.4.196/linux/bin/compilervars.sh intel64
```

For example, to configure and make for an Intel Xeon Scalable processor ("SKX"):

```bash
make distclean
./configure-libxc-skx.sh
make -j; make install
```

