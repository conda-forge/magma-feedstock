@echo on

xcopy /s /k /y .\include\ %LIBRARY_PREFIX%
xcopy /s /k /y .\build\include\magma_config.h %LIBRARY_PREFIX%\include\magma_config.h
xcopy /s /k /y .\build\lib\pkgconfig\magma.pc %LIBRARY_PREFIX%\lib\pkgconfig\magma.pc
if errorlevel 1 exit \b 1
