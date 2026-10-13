# METIS

To download, configure, build, and install METIS, one may proceed as shown below. METIS&#160;5.1.0 is part of ParMETIS&#160;4.0.3, which is available from [CP2K's download area](https://www.cp2k.org/static/downloads/).

```bash
wget https://www.cp2k.org/static/downloads/parmetis-4.0.3.tar.gz
tar xvf parmetis-4.0.3.tar.gz
cd parmetis-4.0.3/metis

wget --content-disposition https://github.com/hfp/xconfigure/raw/main/configure-get.sh
chmod +x configure-get.sh
./configure-get.sh metis
```

The scripts rely on the GNU Compiler Collection (`configure-metis.sh`) or on the Intel Compiler (`configure-metis-icx.sh`), and code is generated for the system running the script.

To configure, build, and install (`../metis/gnu`):

```bash
make distclean
./configure-metis.sh
make -j; make install
```

## References

[https://www.cp2k.org/static/downloads/](https://www.cp2k.org/static/downloads/)  
[https://github.com/KarypisLab/METIS](https://github.com/KarypisLab/METIS)
