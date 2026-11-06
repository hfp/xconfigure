# LIBVORI

[libvori](https://brehm-research.de/libvori.php) provides Voronoi integration and the BQB format (lossless compression of volumetric data) to CP2K, which is optional (`CP2K_USE_VORI`). To download, configure, build, and install, one may proceed as shown below.

```bash
wget https://www.cp2k.org/static/downloads/libvori-220621.tar.gz
tar xvf libvori-220621.tar.gz
cd libvori-220621

wget --content-disposition https://github.com/hfp/xconfigure/raw/main/configure-get.sh
chmod +x configure-get.sh
./configure-get.sh libvori
```

To configure, build, and install using the GNU Compiler Collection (`../libvori/<arch>/gnu`):

```bash
./configure-libvori.sh
cmake --build build-<arch>-gnu --target install -j $(nproc)
```

To use the Intel Compiler instead (`../libvori/<arch>/icx`):

```bash
./configure-libvori-icx.sh
cmake --build build-<arch>-icx --target install -j $(nproc)
```

Here, `<arch>` names the target as determined by the compiler (e.g., `sapphirerapids` or `neoverse-v2`), which allows to share the folder structure among different systems (`XCFG_ARCH` overrides the name). An optional first argument ("tagname") changes the name of the build and installation folder. Further arguments are passed to CMake. When configuring CP2K, `configure-cp2k.sh` finds the installation and enables libvori.

## References

[https://brehm-research.de/libvori.php](https://brehm-research.de/libvori.php)  
[https://www.cp2k.org/static/downloads/](https://www.cp2k.org/static/downloads/)
