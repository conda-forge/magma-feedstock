@echo on

set "CUDA_ARCH_LIST=-gencode arch=compute_37,code=sm_37 -gencode arch=compute_50,code=sm_50 -gencode arch=compute_60,code=sm_60 -gencode arch=compute_70,code=sm_70"

if %cuda_compiler_version% == "11.2" (
    set "CUDA_ARCH_LIST=%CUDA_ARCH_LIST% -gencode arch=compute_80,code=sm_80 -gencode arch=compute_86,code=sm_86"
)
if %cuda_compiler_version% == "11.1" (
    set "CUDA_ARCH_LIST=%CUDA_ARCH_LIST% -gencode arch=compute_80,code=sm_80 -gencode arch=compute_86,code=sm_86"
)
if %cuda_compiler_version% ==  "11.0" (
    set "CUDA_ARCH_LIST=%CUDA_ARCH_LIST% -gencode arch=compute_80,code=sm_80"
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
:: compiler to cl.exe instead of the full path. MSVC does not support full
:: C++11 standard
:: https://learn.microsoft.com/en-us/cpp/build/reference/std-specify-language-standard-version?view=msvc-160
cmake %CMAKE_ARGS% .. ^
  -G "Ninja" ^
  -DCMAKE_WINDOWS_EXPORT_ALL_SYMBOLS:BOOL=ON ^
  -DCMAKE_BUILD_TYPE=Release ^
  -DCMAKE_INSTALL_PREFIX="%LIBRARY_PREFIX%" ^
  -DCMAKE_PREFIX_PATH="%LIBRARY_PREFIX%" ^
  -DCUDA_ARCH_LIST="%CUDA_ARCH_LIST%" ^
  -DGPU_TARGET="all" ^
  -DMAGMA_ENABLE_CUDA:BOOL=ON ^
  -DBUILD_SPARSE=OFF ^
  -DUSE_FORTRAN=OFF ^
  -DCUDA_NVCC_FLAGS="--use-local-env --fatbin"
if errorlevel 1 exit /b 1

cmake --build . --config Release -j%CPU_COUNT% --verbose --target magma magma_sparse
if errorlevel 1 exit /b 1

cmake --install .
if errorlevel 1 exit /b 1
