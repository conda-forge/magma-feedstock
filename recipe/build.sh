set -exv

# This step is required when building from raw source archive
# make generate --jobs ${CPU_COUNT}

# Only about 7 virtual archs can be built 6 hours for CUDA 11
# Only about 8 archs fit into the default 2GB address space; could use
# -mcmodel=medium to increase address space

# 11.2 supports archs 3.5 - 8.6
# 11.8 supports archs 3.5 - 9.0
# 12.x supports archs 5.0 - 9.0

# Duplicate lists because of https://bitbucket.org/icl/magma/pull-requests/32
# Use the same arches as https://github.com/pytorch/pytorch/blob/07fa6e2c8b003319f85a469307f1b1dd73f6026c/.ci/magma/Makefile#L7
# Only difference is 37 is replaced with 35.

export CUDA_ARCH_LIST="sm_50,sm_60,sm_70,sm_80"
export CUDAARCHS="50-real;60-real;70-real;80-real"

if [[ "$cuda_compiler_version" == "11.2" ]]; then
  export CUDA_ARCH_LIST="${CUDA_ARCH_LIST},sm_35,sm_86"
  export CUDAARCHS="${CUDAARCHS};35-real;86"

elif [[ "$cuda_compiler_version" == "11.8" ]]; then
  export CUDA_ARCH_LIST="${CUDA_ARCH_LIST},sm_35,sm_86,sm_90"
  export CUDAARCHS="${CUDAARCHS};35-real;86-real;90"

elif [[ "$cuda_compiler_version" == "12."* ]]; then
  export CUDA_ARCH_LIST="${CUDA_ARCH_LIST},sm_86,sm_90"
  export CUDAARCHS="${CUDAARCHS};86-real;90"

else
  echo "Unsupported CUDA version. Please update build.sh"
  exit 1
fi

# Conda-forge nvcc compiler flags environment variable doesn't match CMake environment variable
# Redirect it so that the flags are added to nvcc calls
export CUDAFLAGS="${CUDAFLAGS} ${CUDA_CFLAGS}"

# Compress SASS and PTX in the binary to reduce disk usage
export CUDAFLAGS="${CUDAFLAGS} -Xfatbin -compress-all"

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

case "$target_platform" in
    linux-64)
        STRIP_CMD="x86_64-conda-linux-gnu-strip"
        ;;
    linux-aarch64)
        STRIP_CMD="aarch64-conda-linux-gnu-strip"
        ;;
    linux-ppc64le)
        STRIP_CMD="powerpc64le-conda-linux-gnu-strip"
        ;;
    *)
        X="unknown"
        ;;
esac
$BUILD_PREFIX/bin/$STRIP_CMD ./lib/libmagma_sparse.so

install ./lib/libmagma_sparse.so $PREFIX/lib/libmagma_sparse.so

cd ..
mkdir $PREFIX/include
cp -pr ./include/*.h $PREFIX/include
cp -pr ./sparse/include/*.h $PREFIX/include
install -D ./build/include/magma_config.h $PREFIX/include/magma_config.h
install -D ./build/lib/pkgconfig/magma.pc $PREFIX/lib/pkgconfig/magma.pc
