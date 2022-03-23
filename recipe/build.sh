export CMAKE_LIBRARY_PATH=$PREFIX/lib:$PREFIX/include:$CMAKE_LIBRARY_PATH
export CMAKE_PREFIX_PATH=$PREFIX
export PATH=$PREFIX/bin:$PATH

CUDA_ARCH_LIST="-gencode arch=compute_37,code=sm_37"
CUDA_ARCH_LIST="${CUDA_ARCH_LIST} -gencode arch=compute_50,code=sm_50"
CUDA_ARCH_LIST="${CUDA_ARCH_LIST} -gencode arch=compute_60,code=sm_60"
CUDA_ARCH_LIST="${CUDA_ARCH_LIST} -gencode arch=compute_70,code=sm_70"

if [[ "$cuda_compiler_version" == "11.1" || "$cuda_compiler_version" == "11.2" ]]; then
  CUDA_ARCH_LIST="${CUDA_ARCH_LIST} -gencode arch=compute_80,code=sm_80"
  CUDA_ARCH_LIST="${CUDA_ARCH_LIST} -gencode arch=compute_86,code=sm_86"
elif [[ "$cuda_compiler_version" == "11.0" ]]; then
  CUDA_ARCH_LIST="${CUDA_ARCH_LIST} -gencode arch=compute_80,code=sm_80"
fi

CUDA_NVCC_FLAGS="${CUDA_NVCC_FLAGS} -Xfatbin -compress-all"
# CUDA_NVCC_FLAGS="${CUDA_NVCC_FLAGS} -std=c++11"
export CUDA_ARCH_LIST

mkdir build
cd build
cmake ${CMAKE_ARGS} .. \
  -DCUDA_SEPERABLE_COMPILATION=OFF \
  -DUSE_FORTRAN=OFF \
  -DGPU_TARGET="All" \
  -DCMAKE_INSTALL_PREFIX="${PREFIX}" \
  -DCUDA_NVCC_FLAGS="${CUDA_NVCC_FLAGS}" \
  -DCUDA_ARCH_LIST="${CUDA_ARCH_LIST}" \
  -DCUDA_TOOLKIT_INCLUDE="${CUDA_HOME}/include" \
  -DLAPACK_LIBRARIES="${PREFIX}/lib/liblapack${SHLIB_EXT};${PREFIX}/lib/libblas${SHLIB_EXT}"

make -j${CPU_COUNT} VERBOSE=1
make install
