# LIBINT

LIBINT is a generator for integral code, and CP2K requires a library which is already generated with CP2K's settings (angular momentum, derivative order, etc.). Such preconfigured source code is available from [CP2K's download area](https://www.cp2k.org/static/downloads/) (`libint-v<version>-cp2k-lmax-<lmax>.tar.xz`, take "lmax-6" if unsure). XCONFIGURE does not support generic LIBINT source code (that is, generating the library).

```bash
wget https://www.cp2k.org/static/downloads/libint-v2.13.1-cp2k-lmax-6.tar.xz
tar xvf libint-v2.13.1-cp2k-lmax-6.tar.xz
cd libint-v2.13.1-cp2k-lmax-6

wget --content-disposition https://github.com/hfp/xconfigure/raw/main/configure-get.sh
chmod +x configure-get.sh
./configure-get.sh libint
```

To configure, build, and install using the GNU Compiler Collection (`../libint/<arch>/gnu`):

```bash
./configure-libint.sh
cmake --build build-<arch>-gnu --target install -j $(nproc)
```

To use the Intel Compiler instead (`../libint/<arch>/icx`):

```bash
./configure-libint-icx.sh
cmake --build build-<arch>-icx --target install -j $(nproc)
```

Here, `<arch>` names the target as determined by the compiler (e.g., `sapphirerapids` or `neoverse-v2`), which allows to share the folder structure among different systems (`XCFG_ARCH` overrides the name). The build relies on CMake and Python (Fortran interface). Neither Boost nor Eigen is necessary since the C++ API is not built. Code is generated for the system running the script (`-march=native`, `-mcpu=native` on Arm, or `-xHost`), i.e., a build system matching the target system is assumed.

An optional first argument ("tagname") changes the name of the build and installation folder, e.g., `./configure-libint.sh gnu-test` installs into `../libint/<arch>/gnu-test`. Further arguments are passed to CMake.

## References

[https://www.cp2k.org/static/downloads/](https://www.cp2k.org/static/downloads/)  
[https://github.com/evaleev/libint](https://github.com/evaleev/libint)
