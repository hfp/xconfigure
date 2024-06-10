# XCONFIGURE

XCONFIGURE is a collection of configure wrapper scripts for various HPC applications. The purpose of the scripts is to configure the application in question to make use of Intel's software development tools (Intel Compiler, Intel MPI, Intel MKL). XCONFIGURE helps to rely on a "build recipe", which is known to expose the highest performance or to reliably complete the build process.

> [Contributions](CONTRIBUTING.md#contributing) are very welcome!

Each application (or library) is hosted in a separate directory. To configure (and ultimately build) an application, one can rely on a single script which then downloads a specific wrapper into the current working directory (of the desired application).

```bash
wget --no-check-certificate https://github.com/hfp/xconfigure/raw/main/configure-get.sh
chmod +x configure-get.sh

echo "EXAMPLE: recipe for Quantum Espresso"
./configure-get.sh qe hsw
```

On systems without access to the Internet, one can [download](https://github.com/hfp/xconfigure/archive/master.zip) (or clone) the entire collection upfront. To configure an application, please open the [config](https://github.com/hfp/xconfigure/tree/master/config) folder directly or use the [documentation](https://xconfigure.readthedocs.io/) and then follow the build recipe of the desired application or library.

## Documentation

* [**ReadtheDocs**](https://xconfigure.readthedocs.io/): online documentation with full text search: [CP2K](https://github.com/hfp/xconfigure/tree/master/config/cp2k), [ELPA](https://github.com/hfp/xconfigure/tree/master/config/elpa), [LIBINT](https://github.com/hfp/xconfigure/tree/master/config/libint), [LIBXC](https://github.com/hfp/xconfigure/tree/master/config/libxc), [LIBXSMM](https://github.com/hfp/xconfigure/tree/master/config/libxsmm), [QE](https://github.com/hfp/xconfigure/tree/master/config/qe), and [TF](https://github.com/hfp/xconfigure/tree/master/config/tf).
* [**PDF**](https://github.com/hfp/xconfigure/raw/main/xconfigure.pdf): a single documentation file.

## Related Projects

* Spack Package Manager: [http://computation.llnl.gov/projects/spack-hpc-package-manager](http://computation.llnl.gov/projects/spack-hpc-package-manager)
* EasyBuild / EasyConfig (University of Gent): [https://github.com/easybuilders](https://github.com/easybuilders)

Please note that XCONFIGURE has a narrower scope when compared to the above package managers.

