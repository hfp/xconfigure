# LIBXC

To [download](https://www.cp2k.org/static/downloads/), configure, build, and install [LIBXC](https://libxc.gitlab.io/) for CP2K (LIBXC&#160;7.1 or later), one may proceed as shown below.

```bash
wget https://www.cp2k.org/static/downloads/libxc-7.1.2.tar.bz2
tar xvf libxc-7.1.2.tar.bz2
cd libxc-7.1.2

wget --content-disposition https://github.com/hfp/xconfigure/raw/main/configure-get.sh
chmod +x configure-get.sh
./configure-get.sh libxc
```

To configure, build, and install using the GNU Compiler Collection (`../libxc/<arch>/gnu`):

```bash
./configure-libxc.sh
cmake --build build-<arch>-gnu --target install -j $(nproc)
```

To use the Intel Compiler instead (`../libxc/<arch>/icx`):

```bash
./configure-libxc-icx.sh
cmake --build build-<arch>-icx --target install -j $(nproc)
```

Here, `<arch>` names the target as determined by the compiler (e.g., `sapphirerapids` or `neoverse-v2`), which allows to share the folder structure among different systems (`XCFG_ARCH` overrides the name). The Fortran interface and third-order derivatives (`MAXORDER=3`) are built as needed by CP2K. An optional first argument ("tagname") changes the name of the build and installation folder. Further arguments are passed to CMake.

## References

[https://libxc.gitlab.io/](https://libxc.gitlab.io/)  
[https://gitlab.com/libxc/libxc](https://gitlab.com/libxc/libxc)
