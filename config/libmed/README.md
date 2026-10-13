# Med File Library (libmed)

To [download](https://salome-platform.org/downloads/), configure, build, and install libmed, one may proceed as shown below.

```bash
wget --content-disposition https://files.salome-platform.org/Salome/other/med-4.1.0.tar.gz
tar xvf med-4.1.0.tar.gz
cd med-4.1.0

wget --content-disposition https://github.com/hfp/xconfigure/raw/main/configure-get.sh
chmod +x configure-get.sh
./configure-get.sh libmed
```

The scripts rely on the GNU Compiler Collection (`configure-libmed.sh`) or on the Intel Compiler (`configure-libmed-icx.sh`), and code is generated for the system running the script.

**Note**: Please make the "hdf5-tools" command available or pay attention to the console output after configuring libmed. In general, an HDF5 development package is necessary to pass the default configuration as implemented by XCONFIGURE. One can adjust the configure wrapper script for custom-built HDF5 by pointing to an (non-default) installation location.

To configure, build, and install (`../libmed/gnu`):

```bash
make distclean
./configure-libmed.sh
make -j; make install
```

## References

[https://salome-platform.org/downloads/](https://salome-platform.org/downloads/)  
[http://wiki.opentelemac.org/doku.php?id=installation_linux_med](http://wiki.opentelemac.org/doku.php?id=installation_linux_med)  
[http://opentelemac.org/](http://opentelemac.org/)
