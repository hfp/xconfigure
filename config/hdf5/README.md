# HDF5

To [download](https://support.hdfgroup.org/ftp/HDF5/releases/), configure, build, and install HDF5, one may proceed as shown below.

```bash
wget --content-disposition https://support.hdfgroup.org/ftp/HDF5/releases/hdf5-1.12/hdf5-1.12.1/src/hdf5-1.12.1.tar.bz2
tar xvf hdf5-1.12.1.tar.bz2
cd hdf5-1.12.1

wget --content-disposition https://github.com/hfp/xconfigure/raw/main/configure-get.sh
chmod +x configure-get.sh
./configure-get.sh hdf5
```

The scripts rely on the GNU Compiler Collection (`configure-hdf5.sh`) or on the Intel Compiler (`configure-hdf5-icx.sh`), and code is generated for the system running the script.

To configure, build, and install (`../hdf5/gnu`):

```bash
make distclean
./configure-hdf5.sh
make -j; make install
```

## References

[https://support.hdfgroup.org/ftp/HDF5/releases/](https://support.hdfgroup.org/ftp/HDF5/releases/)  
[https://hdfgroup.org/](https://hdfgroup.org/)
