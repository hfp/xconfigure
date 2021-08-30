# HDF5

To [download](https://support.hdfgroup.org/ftp/HDF5/releases/), configure, build, and install HDF5, one may proceed as shown below.

```bash
wget --no-check-certificate https://support.hdfgroup.org/ftp/HDF5/releases/hdf5-1.12/hdf5-1.12.1/src/hdf5-1.12.1.tar.bz2
tar xvf hdf5-1.12.1.tar.bz2
cd hdf5-1.12.1

wget --no-check-certificate https://github.com/hfp/xconfigure/raw/master/configure-get.sh
chmod +x configure-get.sh
./configure-get.sh hdf5
```

Please make the intended compiler available on the command line. For instance, many HPC centers rely on `module load`.

```bash
source /opt/intel/compilers_and_libraries_2020.4.304/linux/bin/compilervars.sh intel64
```

For example, to configure and make for an Intel Xeon Scalable processor ("SKX"):

```bash
make distclean
./configure-hdf5-skx.sh
make -j; make install
```

## References

[https://support.hdfgroup.org/ftp/HDF5/releases/](https://support.hdfgroup.org/ftp/HDF5/releases/)  
[https://hdfgroup.org/](https://hdfgroup.org/)

