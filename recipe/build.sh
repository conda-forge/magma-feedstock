set -exv

# This step is required when building from raw source archive
make generate --jobs ${CPU_COUNT}

# https://en.wikipedia.org/wiki/CUDA#GPUs_supported
# The logic for the targeted archs is as follows:
# 1. We build the minimum supported arch with both real and virtual to maximize
# compatability
# 2. Skip all deprecated archs after min supported
# 3. Start cutting minor versions in order to fit into 6 hour build time
# Duplicate lists because of https://bitbucket.org/icl/magma/pull-requests/32
export CUDA_ARCH_LIST="sm_35,sm_60,sm_61,sm_70,sm_75,sm_80,sm_86"
export CUDAARCHS="35-virtual;60-virtual;61-real;70-virtual;75-real;80-virtual;86"

# Only build the lowest non-deprecated arch to minimize build time
if [[ "$target_platform" == "linux-ppc64le" || "$target_platform" == "linux-aarch64" ]]; then
  export CUDA_ARCH_LIST="sm_60"
  export CUDAARCHS="60"
fi

# Remove CXX standard flags added by conda-forge. std=c++11 is required to
# compile some .cu files
CXXFLAGS="${CXXFLAGS//-std=c++17/-std=c++11}"

mkdir build
cd build
rm -rf *

cmake $SRC_DIR \
  -G "Ninja" \
  -DBUILD_SHARED_LIBS:BOOL=ON \
  -DCMAKE_BUILD_TYPE=Release \
  -DCMAKE_INSTALL_PREFIX=$PREFIX \
  -DGPU_TARGET=$CUDA_ARCH_LIST \
  -DMAGMA_ENABLE_CUDA:BOOL=ON \
  -DUSE_FORTRAN:BOOL=OFF \
  -DCMAKE_CUDA_SEPARABLE_COMPILATION:BOOL=ON \
  ${CMAKE_ARGS}

# Explicitly name build targets to avoid building tests
cmake --build . \
    --parallel ${CPU_COUNT} \
    --target magma magma_sparse \
    --verbose

cmake --install .
