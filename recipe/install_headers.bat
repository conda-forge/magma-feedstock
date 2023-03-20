@echo on

xcopy /s /k /y .\include\*.h %LIBRARY_PREFIX%
cp .\build\include\magma_config.h %LIBRARY_PREFIX%\include\magma_config.h
md  %LIBRARY_PREFIX%\lib\pkgconfig
cp .\build\lib\pkgconfig\magma.pc %LIBRARY_PREFIX%\lib\pkgconfig\magma.pc
if errorlevel 1 exit \b 1
