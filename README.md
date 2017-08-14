# [XCONFIGURE](https://github.com/hfp/xconfigure/raw/master/xconfigure.pdf)
[![License](https://img.shields.io/badge/license-BSD3-blue.svg)](LICENSE) [![ReadtheDocs](http://readthedocs.org/projects/xconfigure/badge/?version=latest "Read the Docs")](http://xconfigure.readthedocs.io/en/latest/)

XCONFIGURE is a collection of configure wrapper scripts for various HPC applications. The purpose of the scripts is to configure the application in question to make use of Intel's software development tools (Intel Compiler, Intel MPI, Intel MKL). This may sound cumbersome, but it helps to rely on a "build recipe", which is known to expose the highest performance or to reliably complete the build process.

Each application (or library) is hosted in a separate subdirectory. To configure (and ultimately build) an application, one may clone or [download](https://github.com/hfp/xconfigure/archive/master.zip) the entire collection.

```
git clone https://github.com/hfp/xconfigure.git
```

Alternatively, one can rely on a single script which then downloads a specific wrapper into the current working directory (of the desired application).

```
wget --no-check-certificate https://github.com/hfp/xconfigure/raw/master/configure-get.sh
chmod +x configure-get.sh
./configure-get.sh qe hsw
```

To configure an application, please follow into one of the subfolders and read the build recipe of this application e.g., **[qe](qe#quantum-espresso-qe)** in case of Quantum Espresso.

## Related Projects

* Spack Package Manager: http://computation.llnl.gov/projects/spack-hpc-package-manager
* EasyBuild / EasyConfig (University of Gent): https://github.com/hpcugent

Please note that XCONFIGURE has a narrower scope when compared to the above package managers.

