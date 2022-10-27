@echo on

set "CUDA_ARCH_LIST=-gencode arch=compute_35,code=sm_35 -gencode arch=compute_50,code=sm_50 -gencode arch=compute_60,code=sm_60 -gencode arch=compute_61,code=sm_61 -gencode arch=compute_70,code=sm_70 -gencode arch=compute_75,code=sm_75"

if %cuda_compiler_version% GEQ 11.0 (
    set "CUDA_ARCH_LIST=%CUDA_ARCH_LIST% -gencode arch=compute_80,code=sm_80"
)
if %cuda_compiler_version% GEQ 11.1 (
    set "CUDA_ARCH_LIST=%CUDA_ARCH_LIST% -gencode arch=compute_86,code=sm_86"
)

:: std=c++11 is required to compile some .cu files
:: TODO: See if that's required on Windows, and how to enable in that case

set CFLAGS=
set CXXFLAGS=
set CPPFLAGS=

md build
cd build
if errorlevel 1 exit /b 1

:: Must add --use-local-env to NVCC_FLAGS otherwise NVCC autoconfigs the host
:: compiler to cl.exe instead of the full path
cmake %CMAKE_ARGS% .. ^
  -G "Ninja" ^
  -DUSE_FORTRAN=OFF ^
  -DGPU_TARGET="All" ^
  -DCMAKE_INSTALL_PREFIX="%LIBRARY_PREFIX%" ^
  -DCMAKE_PREFIX_PATH="%LIBRARY_PREFIX%" ^
  -DCUDA_ARCH_LIST="%CUDA_ARCH_LIST%" ^
  -DLAPACK_LIBRARIES="%LIBRARY_PREFIX%\lib\lapack.lib;%LIBRARY_PREFIX%\lib\blas.lib" ^
  -DCMAKE_BUILD_TYPE=Release ^
  -DBUILD_SPARSE=OFF ^
  -DCMAKE_WINDOWS_EXPORT_ALL_SYMBOLS:BOOL=ON ^
  -DCUDA_NVCC_FLAGS="--use-local-env"
if errorlevel 1 exit /b 1

cmake --build . --config Release -j%CPU_COUNT% --verbose
if errorlevel 1 exit /b 1

cmake --install .
if errorlevel 1 exit /b 1
