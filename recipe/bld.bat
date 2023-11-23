@echo on

:: This step is required when building from raw source archive
:: make generate --jobs %CPU_COUNT%
:: if errorlevel 1 exit /b 1

:: Duplicate lists because of https://bitbucket.org/icl/magma/pull-requests/32
SET "CUDA_ARCH_LIST=sm_50,sm_60,sm_61,sm_70,sm_75,sm_80"
SET "CUDAARCHS=50-real;52-real;60-real;61-real;70-real;75-real;80-real"

IF "%cuda_compiler_version%" == "11.0" (
  SET "CUDA_ARCH_LIST=%CUDA_ARCH_LIST%,sm_35"
  SET "CUDAARCHS=%CUDAARCHS%;35-real;80-virtual"
)

IF "%cuda_compiler_version%" == "11.1" (
  SET "CUDA_ARCH_LIST=%CUDA_ARCH_LIST%,sm_35,sm_86"
  SET "CUDAARCHS=%CUDAARCHS%;35-real;86"
)

IF "%cuda_compiler_version%" == "11.2" (
  SET "CUDA_ARCH_LIST=%CUDA_ARCH_LIST%,sm_35,sm_86"
  SET "CUDAARCHS=%CUDAARCHS%;35-real;86"
)

IF "%cuda_compiler_version%" == "12.0" (
  SET "CUDA_ARCH_LIST=%CUDA_ARCH_LIST%,sm_86,sm_89,sm_90"
  SET "CUDAARCHS=%CUDAARCHS%;86-real;89-real;90"
)

md build
cd build
if errorlevel 1 exit /b 1

:: Must add --use-local-env to NVCC_FLAGS otherwise NVCC autoconfigs the host
:: compiler to cl.exe instead of the full path. MSVC does not accept a
:: C++11 standard argument, and defaults to C++14
:: https://learn.microsoft.com/en-us/cpp/overview/visual-cpp-language-conformance?view=msvc-160
:: https://learn.microsoft.com/en-us/cpp/build/reference/std-specify-language-standard-version?view=msvc-160
cmake %SRC_DIR% ^
  -G "Ninja" ^
  -DCMAKE_WINDOWS_EXPORT_ALL_SYMBOLS:BOOL=ON ^
  -DCMAKE_BUILD_TYPE=Release ^
  -DGPU_TARGET="%CUDA_ARCH_LIST%" ^
  -DMAGMA_ENABLE_CUDA:BOOL=ON ^
  -DUSE_FORTRAN:BOOL=OFF ^
  -DCMAKE_CUDA_FLAGS="--use-local-env" ^
  -DCMAKE_CUDA_SEPARABLE_COMPILATION:BOOL=OFF
if errorlevel 1 exit /b 1

cmake --build . ^
    --config Release ^
    --parallel %CPU_COUNT% ^
    --target magma_sparse ^
    --verbose
if errorlevel 1 exit /b 1

cp .\lib\magma_sparse.lib %LIBRARY_PREFIX%\lib\magma_sparse.lib
cp .\magma_sparse.dll %LIBRARY_PREFIX%\bin\magma_sparse.dll
if errorlevel 1 exit /b 1

cd ..
md %LIBRARY_PREFIX%\include
xcopy /s /k /y .\include\*.h %LIBRARY_PREFIX%\include
xcopy /s /k /y .\sparse\include\*.h %LIBRARY_PREFIX%\include
cp .\build\include\magma_config.h %LIBRARY_PREFIX%\include\magma_config.h
md  %LIBRARY_PREFIX%\lib\pkgconfig
cp .\build\lib\pkgconfig\magma.pc %LIBRARY_PREFIX%\lib\pkgconfig\magma.pc
if errorlevel 1 exit \b 1
