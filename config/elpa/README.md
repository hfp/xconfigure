# ELPA<a name="eigenvalue-solvers-for-petaflop-applications-elpa"></a>

[Download](https://elpa.mpcdf.mpg.de/software/tarball-archive/ELPA_TARBALL_ARCHIVE.html) and unpack ELPA and make the configure wrapper scripts available in ELPA's root folder. Consider CP2K's download area (cache) as an [alternative source](https://www.cp2k.org/static/downloads) for downloading ELPA.

```bash
echo "wget --content-disposition https://www.cp2k.org/static/downloads/elpa-2021.11.002.tar.gz"
wget --content-disposition https://elpa.mpcdf.mpg.de/software/tarball-archive/Releases/2021.11.002/elpa-2021.11.002.tar.gz
tar xvf elpa-2021.11.002.tar.gz
cd elpa-2021.11.002

wget --content-disposition https://github.com/hfp/xconfigure/raw/main/configure-get.sh
chmod +x configure-get.sh
./configure-get.sh elpa
```

The scripts rely on Intel&#160;MKL (`MKLROOT`), and on the GNU Compiler Collection (`configure-elpa.sh`) or the Intel Compiler (`configure-elpa-icx.sh`). Code is generated for the system running the script. To configure, build, and install (`../elpa/<arch>/gnu`):

```bash
make clean
./configure-elpa.sh
make -j ; make install
```

Even if ELPA was just unpacked (and never built before), `make clean` is recommended in advance of building ELPA ("unknown module file format"). OpenMP is enabled by default, and `OMP=0` disables it. An optional first argument ("tagname") changes the name of the installation folder:

```bash
make clean
OMP=0 ./configure-elpa.sh gnu-noomp
make -j ; make install
```

Here, `<arch>` names the target as determined by the compiler (e.g., `sapphirerapids` or `neoverse-v2`), which allows to share the folder structure among different systems (`XCFG_ARCH` overrides the name).

## References

[https://github.com/cp2k/cp2k/blob/master/INSTALL.md#2l-elpa-optional-improved-performance-for-diagonalization](https://github.com/cp2k/cp2k/blob/master/INSTALL.md#2l-elpa-optional-improved-performance-for-diagonalization)  
[https://elpa.mpcdf.mpg.de/software/tarball-archive/ELPA_TARBALL_ARCHIVE.html](https://elpa.mpcdf.mpg.de/software/tarball-archive/ELPA_TARBALL_ARCHIVE.html)  
[https://www.cp2k.org/static/downloads](https://www.cp2k.org/static/downloads)
