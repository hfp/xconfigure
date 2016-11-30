# XCONFIGURE
[![License](https://img.shields.io/badge/license-BSD3-blue.svg)](LICENSE)

XCONFIGURE is a collection of configure wrapper scripts for various HPC applications. The purpose of the scripts is to configure the application in question to make use of Intel's software development tools (Intel Compiler, Intel MPI, Intel MKL). This may sounds cumbersome, but it actually helps to rely on a "build recipe", which is known to expose the highest performance or to reliably complete the build process.

Each application (or library) is hosted in a separate subdirectory. In order to configure (and ultimately build) an application, one may clone or [download](https://github.com/hfp/xconfigure/archive/master.zip) the entire collection.

```
git clone https://github.com/hfp/xconfigure.git
```

Alternatively, one can rely on a single script which then downloads a specific wrapper into the current working directory (of the desired application).

```
wget https://github.com/hfp/xconfigure/raw/master/configure-get.sh
./configure-get.sh qe hsw
```

To configure an application, please follow into one of the aforementioned subfolders and read the build recipe of this application e.g., **[qe](qe#quantum-espresso-qe)** in case of Quantum Espresso.
