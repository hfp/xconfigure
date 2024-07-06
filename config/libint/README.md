# LIBINT

## Overview

LIBINT consists of a compiler specializing the library by generating source files according to the needs of the desired application. XCONFIGURE scripts support both preconfigured LIBINT as well as starting from generic source code.

<a name="boostrap-for-cp2k"></a>After running the desired XCONFIGURE script on the generic source code, a compressed Tarball is left behind inside of the original directory (`libint-cp2k-lmax6.tgz`). The exported code (as generated for CP2K's requirements), can be unarchived, compiled, and installed using the XCONFIGURE scripts again (but faster because generating the source code is omitted).

For CP2K&#160;7.x and onwards, LIBINT&#160;2.5 (or later) is needed. For CP2K&#160;6.1 (and earlier), LIBINT&#160;1.1.x is required (1.2.x, 2.x, or any later version cannot be used).

## Version&#160;2.x<a name="version-25-and-later"></a>

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

**Note**: A rate limit applies to GitHub API requests of the same origin. If the download fails, it can be worth trying an authenticated request by using a GitHub account (`-u "user:password"`).

To download the latest generic source code package of LIBINT (small package but full [bootstrap for CP2K](README.md#boostrap-for-cp2k) applies):

```bash
wget https://github.com/evaleev/libint/archive/refs/tags/v2.9.0.tar.gz
```

Unpack the archive of choice and download the XCONFIGURE scripts:

```bash
# tar xvf libint-v2.6.0-cp2k-lmax-6.tgz && cd libint-v2.6.0-cp2k-lmax-6
tar v2.9.0.tar.gz && cd v2.9.0

wget --content-disposition https://github.com/hfp/xconfigure/raw/main/configure-get.sh
chmod +x configure-get.sh
./configure-get.sh libint
```

There can be issues with target flags requiring a build-system able to execute a binary compiled with the flags of choice. To avoid cross-compilation (not supported here), please rely on a build system that matches the target system. For example, to configure and make for an Intel Xeon Scalable processor such as "Cascadelake" or "Skylake" server ("SKX") using, e.g., Intel Compiler:

```bash
make distclean
./configure-libint-skx.sh
make -j $(nproc); make install
```

To build native code for the system running the scripts using, e.g., GNU Compiler:

```bash
make distclean
./configure-libint-gnu.sh
make -j $(nproc); make install
```

Make sure to run `make distclean` before reconfiguring for a different variant, e.g., changing between GNU and Intel compiler. Further, for different compiler versions, different targets (instruction set extensions), or any other difference, the configure-wrapper scripts support an additional argument (a "tagname"):

```bash
./configure-libint-hsw.sh tagname
```

As shown above, an arbitrary "tagname" can be given (without editing the script). This might be useful when building multiple variants of the LIBINT library.

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

## References

[https://github.com/cp2k/cp2k/blob/master/INSTALL.md#2g-libint-optional-enables-methods-including-hf-exchange](https://github.com/cp2k/cp2k/blob/master/INSTALL.md#2g-libint-optional-enables-methods-including-hf-exchange)  
[https://github.com/evaleev/libint/releases/tag/release-1-1-6](https://github.com/evaleev/libint/releases/tag/release-1-1-6)  
[https://github.com/cp2k/libint-cp2k/releases/latest](https://github.com/cp2k/libint-cp2k/releases/latest)
