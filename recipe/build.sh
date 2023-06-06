set -exv

# This step is required when building from raw source archive
make generate --jobs ${CPU_COUNT}

# Duplicate lists because of https://bitbucket.org/icl/magma/pull-requests/32
CUDA_ARCH_LIST="sm_50,sm_60,sm_61,sm_70,sm_75,sm_80"
CUDAARCHS="50-real;52-real;60-real;61-real;70-real;75-real;80-real"

if [[ "$cuda_compiler_version" == "11.*" ]]; then
  CUDA_ARCH_LIST="${CUDA_ARCH_LIST},sm_35"
  CUDAARCHS="${CUDAARCHS};35-real"
fi

if [[ "$cuda_compiler_version" == "11.0" ]]; then
  CUDAARCHS="${CUDAARCHS};80-virtual"
fi

if [[ "$cuda_compiler_version" == "11.1" || "$cuda_compiler_version" == "11.2" ]]; then
  CUDA_ARCH_LIST="${CUDA_ARCH_LIST},sm_86"
  CUDAARCHS="${CUDAARCHS};86"
fi

if [[ "$cuda_compiler_version" == "12.*" ]]; then
  CUDA_ARCH_LIST="${CUDA_ARCH_LIST},sm_86,sm_89,sm_90"
  CUDAARCHS="${CUDAARCHS};86-real;89-real;90"
fi

# Jetsons are ARM devices, so target those minor versions too
if [[ "$target_platform" == "linux-aarch64" ]]; then
  CUDA_ARCH_LIST="${CUDA_ARCH_LIST},sm_72,sm_62,sm_53"
  CUDAARCHS="${CUDAARCHS};53-real;62-real;72-real"
fi

if [[ "$target_platform" == "linux-aarch64" && "$cuda_compiler_version" == "12.*" ]]; then
  CUDA_ARCH_LIST="${CUDA_ARCH_LIST},sm_87"
  CUDAARCHS="${CUDAARCHS};87-real"
fi

export CUDA_ARCH_LIST
export CUDAARCHS

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
