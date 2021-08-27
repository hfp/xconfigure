# METIS

To [download](http://glaros.dtc.umn.edu/gkhome/metis/metis/download), configure, build, and install METIS, one may proceed as shown below.

```bash
wget --no-check-certificate http://glaros.dtc.umn.edu/gkhome/fetch/sw/metis/metis-5.1.0.tar.gz
tar xvf metis-5.1.0.tar.gz
cd metis-5.1.0

wget --no-check-certificate https://github.com/hfp/xconfigure/raw/master/configure-get.sh
chmod +x configure-get.sh
./configure-get.sh metis
```

Please make the intended compiler available on the command line. For instance, many HPC centers rely on `module load`.

```bash
source /opt/intel/compilers_and_libraries_2020.4.304/linux/bin/compilervars.sh intel64
```

For example, to configure and make for an Intel Xeon Scalable processor ("SKX"):

```bash
make distclean
./configure-med-skx.sh
make -j; make install
```

## References

[http://glaros.dtc.umn.edu/gkhome/metis/metis/download](http://glaros.dtc.umn.edu/gkhome/metis/metis/download)  
[http://glaros.dtc.umn.edu/gkhome/views/metis](http://glaros.dtc.umn.edu/gkhome/views/metis)

