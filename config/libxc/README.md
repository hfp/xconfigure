# LIBXC

To [download](https://gitlab.com/libxc/libxc/-/releases), configure, build, and install [LIBXC](https://www.tddft.org/programs/libxc/)&#160;2.x, 3.x (CP2K&#160;5.1 and earlier is only compatible with LIBXC&#160;3.0 or earlier), 4.x (CP2K&#160;7.1 and earlier is only compatible with LIBXC&#160;4.x), or 5.x (CP2K&#160;8.1 and later require LIBXC&#160;5.x), one may proceed as shown below. For CP2K, see also [How to compile the CP2K code](https://github.com/cp2k/cp2k/blob/master/INSTALL.md#2k-libxc-optional-wider-choice-of-xc-functionals)). In general, only the latest major release of LIBXC (by the time of the CP2K-release) is supported.

```bash
wget --content-disposition https://www.tddft.org/programs/libxc/down.php?file=5.1.2/libxc-5.1.2.tar.gz
tar xvf libxc-5.1.2.tar.gz
cd libxc-5.1.2

wget --no-check-certificate https://github.com/hfp/xconfigure/raw/master/configure-get.sh
chmod +x configure-get.sh
./configure-get.sh libxc
```

Please make the Intel Compiler available on the command line. This depends on the environment. For instance, many HPC centers rely on `module load`.

```bash
source /opt/intel/compilers_and_libraries_2020.4.304/linux/bin/compilervars.sh intel64
```

For example, to configure and make for an Intel Xeon Scalable processor ("SKX"):

```bash
make distclean
./configure-libxc-skx.sh
make -j; make install
```

**NOTE**: Please disregard messages during configuration suggesting `libtoolize --force`.

## References

[https://github.com/cp2k/cp2k/blob/master/INSTALL.md#2k-libxc-optional-wider-choice-of-xc-functionals](https://github.com/cp2k/cp2k/blob/master/INSTALL.md#2k-libxc-optional-wider-choice-of-xc-functionals)

