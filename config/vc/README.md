# Vc: SIMD Vector Classes for C++

To [download](https://github.com/VcDevel/Vc/releases/latest), configure, build, and install Vc, one may proceed as shown below.

```bash
wget --content-disposition --no-check-certificate https://github.com/VcDevel/Vc/archive/refs/tags/1.4.2.tar.gz
tar xvf Vc-1.4.2.tar.gz
cd Vc-1.4.2

wget --content-disposition --no-check-certificate https://github.com/hfp/xconfigure/raw/main/configure-get.sh
chmod +x configure-get.sh
./configure-get.sh vc
```

Please make the intended compiler available on the command line. For instance, many HPC centers rely on `module load`.

```bash
source /opt/intel/compilers_and_libraries_2020.4.304/linux/bin/compilervars.sh intel64
```

For example, to configure and make for an Intel Xeon Scalable processor ("SKX"):

```bash
make distclean
./configure-vc.sh
cd build; make -j; make install
```

## References

[https://github.com/VcDevel/Vc/releases](https://github.com/VcDevel/Vc/releases)  
[https://github.com/VcDevel/Vc](https://github.com/VcDevel/Vc)

