set -exv

export CMAKE_LIBRARY_PATH=$PREFIX/lib:$PREFIX/include:$CMAKE_LIBRARY_PATH
export CMAKE_PREFIX_PATH=$PREFIX
export PATH=$PREFIX/bin:$PATH

export CUDA_ARCH_LIST="-gencode arch=compute_35,code=sm_35 -gencode arch=compute_50,code=sm_50 -gencode arch=compute_60,code=sm_60 -gencode arch=compute_61,code=sm_61 -gencode arch=compute_70,code=sm_70 -gencode arch=compute_75,code=sm_75"

if awk "BEGIN {exit !($cuda_compiler_version >= 11.0)}"; then
  CUDA_ARCH_LIST="$CUDA_ARCH_LIST -gencode arch=compute_80,code=sm_80"
fi
if awk "BEGIN {exit !($cuda_compiler_version >= 11.1)}"; then
  CUDA_ARCH_LIST="$CUDA_ARCH_LIST -gencode arch=compute_86,code=sm_86"
fi

# std=c++11 is required to compile some .cu files
CPPFLAGS="${CPPFLAGS//-std=c++17/-std=c++14}"
CXXFLAGS="${CXXFLAGS//-std=c++17/-std=c++14}"

mkdir build
cd build

cmake $SRC_DIR \
  -G "Ninja" \
  -DCMAKE_BUILD_TYPE=Release \
  -DUSE_FORTRAN=OFF \
  -DGPU_TARGET="All" \
  -DCMAKE_INSTALL_PREFIX=$PREFIX \
  -DCUDA_ARCH_LIST="$CUDA_ARCH_LIST" \
  -DCUDA_TOOLKIT_INCLUDE=$CUDA_HOME/include \
  -DLAPACK_LIBRARIES="$PREFIX/lib/liblapack${SHLIB_EXT};${PREFIX}/lib/libblas${SHLIB_EXT}" \
  ${CMAKE_ARGS}

cmake --build . -j${CPU_COUNT} --verbose

cmake --install .
