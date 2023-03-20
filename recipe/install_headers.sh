set -exv

cp -pr ./include/ $PREFIX
install -D ./build/include/magma_config.h $PREFIX/include/magma_config.h
install -D ./build/lib/pkgconfig/magma.pc $PREFIX/lib/pkgconfig/magma.pc
