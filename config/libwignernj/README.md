# LIBWIGNERNJ

CP2K requires [libwignernj](https://github.com/susilehtola/libwignernj) (version&#160;0.8 or later). To download, configure, build, and install, one may proceed as shown below.

```bash
wget https://www.cp2k.org/static/downloads/libwignernj-0.8.0.tar.gz
tar xvf libwignernj-0.8.0.tar.gz
cd libwignernj-0.8.0

wget --content-disposition https://github.com/hfp/xconfigure/raw/main/configure-get.sh
chmod +x configure-get.sh
./configure-get.sh libwignernj
```

To configure, build, and install using the GNU Compiler Collection (`../libwignernj/<arch>/gnu`):

```bash
./configure-libwignernj.sh
cmake --build build-<arch>-gnu --target install -j $(nproc)
```

To use the Intel Compiler instead (`../libwignernj/<arch>/icx`):

```bash
./configure-libwignernj-icx.sh
cmake --build build-<arch>-icx --target install -j $(nproc)
```

Here, `<arch>` names the target as determined by the compiler (e.g., `sapphirerapids` or `neoverse-v2`), which allows to share the folder structure among different systems (`XCFG_ARCH` overrides the name). An optional first argument ("tagname") changes the name of the build and installation folder. Further arguments are passed to CMake.

## References

[https://github.com/susilehtola/libwignernj](https://github.com/susilehtola/libwignernj)  
[https://www.cp2k.org/static/downloads/](https://www.cp2k.org/static/downloads/)
