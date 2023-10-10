set -exv

# This step is required when building from raw source archive
# make generate --jobs ${CPU_COUNT}

# Unlike libmagma-feedstock, this feedstock has plenty of time

# 11.2 supports archs 3.5 - 8.6
# 11.8 supports archs 3.5 - 9.0
# 12.x supports archs 5.0 - 9.0

# Duplicate lists because of https://bitbucket.org/icl/magma/pull-requests/32
export CUDA_ARCH_LIST="sm_50,sm_52,sm_60,sm_61,sm_70,sm_75,sm_80"
export CUDAARCHS="50-real;52-real;60-real;61-real;70-real;75-real;80-real"

if [[ "$cuda_compiler_version" == "11.2" ]]; then
  export CUDA_ARCH_LIST="${CUDA_ARCH_LIST},sm_35"
  export CUDAARCHS="${CUDAARCHS};35-real;86"
fi

if [[ "$cuda_compiler_version" == "11.8" ]]; then
  export CUDA_ARCH_LIST="${CUDA_ARCH_LIST},sm_35,sm_86,sm_89,sm_90"
  export CUDAARCHS="${CUDAARCHS};35-real;86-real;89-real;90"
fi

if [[ "$cuda_compiler_version" == "12.0" ]]; then
  export CUDA_ARCH_LIST="${CUDA_ARCH_LIST},sm_86,sm_89,sm_90"
  export CUDAARCHS="${CUDAARCHS};86-real;89-real;90"
fi

# Jetsons are ARM devices, so target those minor versions too
if [[ "$target_platform" == "linux-aarch64" ]]; then
  export CUDA_ARCH_LIST="${CUDA_ARCH_LIST},sm_72,sm_62,sm_53"
  export CUDAARCHS="${CUDAARCHS};53-real;62-real;72-real"
  if [[ "$cuda_compiler_version" == "12."* ]]; then
  export CUDA_ARCH_LIST="${CUDA_ARCH_LIST},sm_87"
  export CUDAARCHS="${CUDAARCHS};87-real"
  fi
fi


# Remove CXX standard flags added by conda-forge. std=c++11 is required to
# compile some .cu files
export CXXFLAGS="${CXXFLAGS//-std=c++17/-std=c++11}"

# Conda-forge nvcc compiler flags environment variable doesn't match CMake environment variable
# Redirect it so that the flags are added to nvcc calls
export CUDAFLAGS="${CUDAFLAGS} ${CUDA_CFLAGS}"

mkdir build
cd build

cmake $SRC_DIR \
  -G "Ninja" \
  -DBUILD_SHARED_LIBS:BOOL=ON \
  -DCMAKE_BUILD_TYPE=Release \
  -DGPU_TARGET=$CUDA_ARCH_LIST \
  -DMAGMA_ENABLE_CUDA:BOOL=ON \
  -DUSE_FORTRAN:BOOL=OFF \
  -DCMAKE_CUDA_SEPARABLE_COMPILATION:BOOL=OFF \
  ${CMAKE_ARGS}

# Explicitly name build targets to avoid building tests
cmake --build . \
    --config Release \
    --parallel ${CPU_COUNT} \
    --target magma_sparse \
    --verbose

install ./lib/libmagma_sparse.so $PREFIX/lib/libmagma_sparse.so
