set -exv

export CUDA_ARCH_LIST="-gencode arch=compute_35,code=sm_35 -gencode arch=compute_50,code=sm_50 -gencode arch=compute_60,code=sm_60 -gencode arch=compute_61,code=sm_61 -gencode arch=compute_70,code=sm_70 -gencode arch=compute_75,code=sm_75"

if awk "BEGIN {exit !($cuda_compiler_version >= 11.0)}"; then
  CUDA_ARCH_LIST="$CUDA_ARCH_LIST -gencode arch=compute_80,code=sm_80"
fi
if awk "BEGIN {exit !($cuda_compiler_version >= 11.1)}"; then
  CUDA_ARCH_LIST="$CUDA_ARCH_LIST -gencode arch=compute_86,code=sm_86"
fi

# Remove CXX standard flags added by conda-forge. std=c++11 is required to
# compile some .cu files
CPPFLAGS="${CPPFLAGS//-std=c++17/-std=c++11}"
CXXFLAGS="${CXXFLAGS//-std=c++17/-std=c++11}"

mkdir build
cd build
rm -rf *

# Upstream doesn't properly pass host compiler args to NVCC, so we have to pass
# them here with CUDA_NVCC_FLAGS.
cmake $SRC_DIR \
  -G "Unix Makefiles" \
  -DBUILD_SHARED_LIBS:BOOL=ON \
  -DCMAKE_BUILD_TYPE=Release \
  -DCMAKE_INSTALL_PREFIX=$PREFIX \
  -DCUDA_ARCH_LIST="$CUDA_ARCH_LIST" \
  -DGPU_TARGET="all" \
  -DMAGMA_ENABLE_CUDA:BOOL=ON \
  -DUSE_FORTRAN:BOOL=OFF \
  -DCUDA_NVCC_FLAGS="" \
  ${CMAKE_ARGS}

# Explicitly name build targets to avoid building tests
cmake --build . \
    --parallel ${CPU_COUNT} \
    --target lib sparse-lib \
    --verbose

cmake --install .
