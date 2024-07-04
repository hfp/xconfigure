# LIBINT

## Overview

For CP2K&#160;7.x and onwards, LIBINT&#160;2.5 (or later) is needed. For CP2K&#160;6.1 (and earlier), LIBINT&#160;1.1.x is required (1.2.x, 2.x, or any later version cannot be used).

## Version&#160;2.5 (and later)

LIBINT generates code to an extent that is often specific to the application. The downloads from [LIBINT's home page](https://github.com/evaleev/libint/releases) are not configured for CP2K, which can be handled by XCONFIGURE. LIBINT configured for CP2K, can be [downloaded](https://github.com/cp2k/libint-cp2k/releases/latest) as well (take "lmax-6" if unsure).

To just determine the download-URL of an already configured package:

```bash
curl -s https://api.github.com/repos/cp2k/libint-cp2k/releases/latest \
| grep "browser_download_url" | grep "lmax-6" \
| sed "s/..*: \"\(..*[^\"]\)\".*/\1/"
```

To download the lmax6-version right away, run the following command:

```bash
curl -s https://api.github.com/repos/cp2k/libint-cp2k/releases/latest \
| grep "browser_download_url" | grep "lmax-6" \
| sed "s/..*: \"\(..*[^\"]\)\".*/url \1/" \
| curl -LOK-
```

To download the latest version of LIBINT:

```bash
wget https://github.com/evaleev/libint/archive/refs/tags/v2.9.0.tar.gz
```

**Note**: A rate limit applies to GitHub API requests of the same origin. If the download fails, it can be worth trying an authenticated request by using a GitHub account (`-u "user:password"`).

To unpack the archive and to download the configure wrapper (lmax6-version is assumed):

```bash
tar xvf libint-v2.6.0-cp2k-lmax-6.tgz
cd libint-v2.6.0-cp2k-lmax-6

wget --content-disposition https://github.com/hfp/xconfigure/raw/main/configure-get.sh
chmod +x configure-get.sh
./configure-get.sh libint
```

There are spurious issues about specific target flags requiring a build-system able to execute compiled binaries. To avoid cross-compilation (not supported here), please rely on a build system that matches the target system. For example, to configure and make for an Intel Xeon Scalable processor such as "Cascadelake" or "Skylake" server ("SKX"):

```bash
make distclean
./configure-libint-skx.sh
make -j $(nproc); make install
```

Make sure to run `make distclean` before reconfiguring a different variant, e.g., GNU and Intel variant. Further, for different targets (instruction set extensions) or different compilers, the configure-wrapper scripts support an additional argument ("default" is the default tagname):

```bash
./configure-libint-hsw.sh tagname
```

As shown above, an arbitrary "tagname" can be given (without editing the script). This might be used to build multiple variants of the LIBINT library.

## Version&#160;1.x

[Download](https://github.com/evaleev/libint/archive/release-1-1-6.tar.gz) and unpack LIBINT and make the configure wrapper scripts available in LIBINT's root folder. Please note that the "automake" package is a prerequisite.

```bash
wget --content-disposition https://github.com/evaleev/libint/archive/release-1-1-6.tar.gz
tar xvf release-1-1-6.tar.gz
cd libint-release-1-1-6

wget --content-disposition https://github.com/hfp/xconfigure/raw/main/configure-get.sh
chmod +x configure-get.sh
./configure-get.sh libint
```

For example, to configure and make for an Intel Xeon&#160;E5v4 processor (formerly codenamed "Broadwell"):

```bash
make distclean
./configure-libint-hsw.sh
make -j $(nproc); make install
```

The version 1.x line of LIBINT does not support to cross-compile for an architecture. If cross-compilation is necessary, one can rely on the [Intel Software Development Emulator](https://software.intel.com/en-us/articles/intel-software-development-emulator) (Intel SDE) to compile LIBINT for targets, which cannot execute on the compile-host.

```bash
/software/intel/sde/sde -knl -- make
```

To speed-up compilation, "make" might be carried out in phases: after "printing the code" (c-files), the make execution continues with building the object-file where no SDE needed. The latter phase can be sped up by interrupting "make" and executing it without SDE. The root cause of the entire problem is that the driver printing the c-code is (needlessly) compiled using the architecture-flags that are not supported on the host.

## Boostrap for CP2K

LIBINT consists of a compiler specializing the library by generating source files according to the needs of the desired application. XCONFIGURE scripts support both preconfigured LIBINT as well as the generic source code.

After running the desired XCONFIGURE script on the generic source code, `make export` will create a compressed Tarball inside of the directory (`libint-cp2k-lmax6.tgz`). The exported code was generated for CP2K's requirements, can be unarchived, compiled, and installed the usual way.

## References

[https://github.com/cp2k/cp2k/blob/master/INSTALL.md#2g-libint-optional-enables-methods-including-hf-exchange](https://github.com/cp2k/cp2k/blob/master/INSTALL.md#2g-libint-optional-enables-methods-including-hf-exchange)  
[https://github.com/evaleev/libint/releases/tag/release-1-1-6](https://github.com/evaleev/libint/releases/tag/release-1-1-6)  
[https://github.com/cp2k/libint-cp2k/releases/latest](https://github.com/cp2k/libint-cp2k/releases/latest)
