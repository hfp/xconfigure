# FFTW

To download, configure, build, and install [FFTW](https://www.fftw.org/) (double precision with OpenMP support as needed by CP2K), one may proceed as shown below.

```bash
wget https://www.fftw.org/fftw-3.3.11.tar.gz
tar xvf fftw-3.3.11.tar.gz
cd fftw-3.3.11

wget --content-disposition https://github.com/hfp/xconfigure/raw/main/configure-get.sh
chmod +x configure-get.sh
./configure-get.sh fftw
```

To configure, build, and install using the GNU Compiler Collection (`../fftw/<arch>/gnu`):

```bash
./configure-fftw.sh
make -C build-<arch>-gnu install -j $(nproc)
```

To use the Intel Compiler instead (`../fftw/<arch>/icx`):

```bash
./configure-fftw-icx.sh
make -C build-<arch>-icx install -j $(nproc)
```

Here, `<arch>` names the target as determined by the compiler (e.g., `sapphirerapids` or `neoverse-v2`), which allows to share the folder structure among different systems (`XCFG_ARCH` overrides the name). SIMD support is enabled according to the system running the script (SSE2, AVX, AVX2, AVX-512, or NEON on Arm). An optional first argument ("tagname") changes the name of the build and installation folder. Further arguments are passed to FFTW's configure script.

FFTW is not needed if CP2K relies on Intel&#160;MKL, or if NVPL provides FFTW's interface (e.g., on NVIDIA Grace).

## References

[https://www.fftw.org/](https://www.fftw.org/)  
[https://www.cp2k.org/static/downloads/](https://www.cp2k.org/static/downloads/)
