# LIBINT

## Overview

For CP2K&#160;6.1 (and earlier), LIBINT&#160;1.1.x is required (1.2.x, 2.x, or any later version cannot be used). [Download](https://github.com/evaleev/libint/archive/release-1-1-6.tar.gz) and unpack LIBINT and make the configure wrapper scripts available in LIBINT's root folder. Please note that the "automake" package is a prerequisite.

Please make the Intel Compiler available on the command line. This depends on the environment. For instance, many HPC centers rely on `module load`.

```bash
source /opt/intel/compilers_and_libraries_2018.5.274/linux/bin/compilervars.sh intel64
```

**NOTE**: CP2K&#160;6.1 (and earlier) depend on [LIBINT&#160;1.1.x](#version1x) and a newer version of LIBINT cannot be used! CP2K&#160;7.x (and later) rely on LIBINT&#160;2.5 (or later) and cannot use the preconfigured library as provided on [LIBINT's home page](https://github.com/evaleev/libint).

## Version&#160;2.5 (and later)

For CP2K&#160;7.x and onwards, LIBINT&#160;2.5 (or later) is needed. LIBINT generates code according to the requested configuration. The preconfigured downloads from [LIBINT's home page](https://github.com/evaleev/libint) cannot be used. Please [download](https://github.com/cp2k/libint-cp2k/releases/latest) (take "lmax-6" if unsure), unpack LIBINT, and make the configure wrapper scripts available in LIBINT's root folder.

To determine the download-URL of the latest version (a suitable variant can be "lmax-6"):

```bash
curl -s https://api.github.com/repos/cp2k/libint-cp2k/releases/latest \
| grep "browser_download_url" | grep "lmax-6" \
| sed "s/..*: \"\(..*[^\"]\)\".*/\1/"
```

To download the lmax6-version and the configure wrapper scripts, run the following command:

```bash
curl -s https://api.github.com/repos/cp2k/libint-cp2k/releases/latest \
| grep "browser_download_url" | grep "lmax-6" \
| sed "s/..*: \"\(..*[^\"]\)\".*/url \1/" \
| curl -LOK-

wget --no-check-certificate https://github.com/hfp/xconfigure/raw/master/configure-get.sh
chmod +x configure-get.sh
./configure-get.sh libint
```

For example, to configure and make for an Intel Xeon Scalable processor such as "Cascadelake" or "Skylake" server ("SKX"):

```bash
make distclean
./configure-libxc-skx.sh
make -j; make install
```

Further, for different targets (instruction set extensions) or different compilers, the configure-wrapper scripts support an additional argument ("default" is the default tagname):

```bash
./configure-libint-hsw.sh tagname
```

As shown above, an arbitrary "tagname" can be given (without editing the script). This might be used to build multiple variants of the LIBINT library.

## Version&#160;1.x

```bash
wget --no-check-certificate https://github.com/evaleev/libint/archive/release-1-1-6.tar.gz
tar xvf release-1-1-6.tar.gz
cd libint-release-1-1-6

wget --no-check-certificate https://github.com/hfp/xconfigure/raw/master/configure-get.sh
chmod +x configure-get.sh
./configure-get.sh libint
```

For example, to configure and make for an Intel Xeon&#160;E5v4 processor (formerly codenamed "Broadwell"):

```bash
make distclean
./configure-libint-hsw.sh
make -j; make install
```

The version 1.x line of LIBINT does not support to cross-compile for an architecture. If cross-compilation is necessary, one can rely on the [Intel Software Development Emulator](https://software.intel.com/en-us/articles/intel-software-development-emulator) (Intel SDE) to compile LIBINT for targets, which cannot execute on the compile-host.

```bash
/software/intel/sde/sde -knl -- make
```

To speed-up compilation, "make" might be carried out in phases: after "printing the code" (c-files), the make execution continues with building the object-file where no SDE needed. The latter phase can be sped up by interrupting "make" and executing it without SDE. The root cause of the entire problem is that the driver printing the c-code is (needlessly) compiled using the architecture-flags that are not supported on the host.

