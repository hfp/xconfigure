# Vc: SIMD Vector Classes for C++

To [download](https://github.com/VcDevel/Vc/releases/latest), configure, build, and install Vc, one may proceed as shown below.

```bash
wget --content-disposition https://github.com/VcDevel/Vc/archive/refs/tags/1.4.2.tar.gz
tar xvf Vc-1.4.2.tar.gz
cd Vc-1.4.2

wget --content-disposition https://github.com/hfp/xconfigure/raw/main/configure-get.sh
chmod +x configure-get.sh
./configure-get.sh vc
```

The scripts rely on the GNU Compiler Collection (`configure-vc.sh`) or on the Intel Compiler (`configure-vc-icx.sh`), and code is generated for the system running the script.

To configure, build, and install (`../vc/<arch>/gnu`):

```bash
make distclean
./configure-vc.sh
cd build; make -j; make install
```

Here, `<arch>` names the target as determined by the compiler (e.g., `sapphirerapids` or `neoverse-v2`), which allows to share the folder structure among different systems (`XCFG_ARCH` overrides the name).

## References

[https://github.com/VcDevel/Vc/releases](https://github.com/VcDevel/Vc/releases)  
[https://github.com/VcDevel/Vc](https://github.com/VcDevel/Vc)
