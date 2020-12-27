@echo on

set "CMAKE_PREFIX_PATH=%LIBRARY_PREFIX%"

set "CUDA_ARCH_LIST=-gencode arch=compute_37,code=sm_37 -gencode arch=compute_50,code=sm_50 -gencode arch=compute_60,code=sm_60 -gencode arch=compute_70,code=sm_70"

if %cuda_compiler_version% == "11.1" (
    set "CUDA_ARCH_LIST=%CUDA_ARCH_LIST% -gencode arch=compute_80,code=sm_80 -gencode arch=compute_86,code=sm_86"
)
if %cuda_compiler_version% ==  "11.0" (
    set "CUDA_ARCH_LIST=%CUDA_ARCH_LIST% -gencode arch=compute_80,code=sm_80"
)

:: std=c++11 is required to compile some .cu files
:: TODO: See if that's required on Windows, and how to enable in that case

md build
cd build
cmake.exe %CMAKE_ARGS% .. ^
  -G "NMake Makefiles JOM" ^
  -DUSE_FORTRAN=OFF ^
  -DGPU_TARGET="All" ^
  -DCMAKE_INSTALL_PREFIX="%LIBRARY_PREFIX%" ^
  -DCMAKE_PREFIX_PATH="%LIBRARY_PREFIX%" ^
  -DCUDA_ARCH_LIST="%CUDA_ARCH_LIST%" ^
  -DCUDA_TOOLKIT_INCLUDE="%CUDA_HOME%\include" ^
  -DLAPACK_LIBRARIES="%LIBRARY_PREFIX%\lib\lapack.lib;%LIBRARY_PREFIX%\lib\blas.lib" ^
  -DCMAKE_BUILD_TYPE=Release ^
  -DBUILD_SPARSE=OFF ^
  -DCMAKE_WINDOWS_EXPORT_ALL_SYMBOLS=ON
if errorlevel 1 exit 1

jom -j%CPU_COUNT% VERBOSE=1
if errorlevel 1 exit 1

jom install
if errorlevel 1 exit 1
