# DBCSR

To configure, build, and install [DBCSR](https://github.com/cp2k/dbcsr) for CP2K, one may proceed as shown below.

```bash
git clone https://github.com/cp2k/dbcsr.git
cd dbcsr

wget --content-disposition https://github.com/hfp/xconfigure/raw/main/configure-get.sh
chmod +x configure-get.sh
./configure-get.sh dbcsr
```

There are four flavors, which differ by the accelerator backend ("cpu" or "gpu") and by the kind of library (static or "shared"). The build relies on the GNU Compiler Collection and on MPI compiler wrappers (`mpicc`, `mpicxx`, `mpif90`). [LIBXS](https://github.com/hfp/libxs) is used for host-side small matrix multiplications, and the GPU flavors rely on OpenCL and [LIBXSTREAM](https://github.com/hfp/libxstream). Dependencies are found via `CMAKE_PREFIX_PATH`.

```bash
export CMAKE_PREFIX_PATH="$HOME/libxs;$HOME/libxstream"

./configure-dbcsr-gpu-shared.sh
cmake --build build-gnu-gpu-shared --target install -j $(nproc)
```

The above installs into `../dbcsr/gnu-gpu-shared`, and similarly for `configure-dbcsr-cpu.sh` (`gnu-cpu`), `configure-dbcsr-cpu-shared.sh` (`gnu-cpu-shared`), and `configure-dbcsr-gpu.sh` (`gnu-gpu`). An optional first argument changes the "gnu" part of the name, and further arguments are passed to CMake, e.g., to select another GPU backend:

```bash
./configure-dbcsr-gpu.sh gnu -DUSE_ACCEL=cuda -DWITH_GPU=H100
```

## References

[https://github.com/cp2k/dbcsr](https://github.com/cp2k/dbcsr)  
[https://cp2k.github.io/dbcsr/](https://cp2k.github.io/dbcsr/)
