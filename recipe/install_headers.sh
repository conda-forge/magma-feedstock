set -exv

mkdir $PREFIX/include
cp -pr ./include/*.h $PREFIX/include
cp -pr ./sparse/include/*.h $PREFIX/include
install -D ./build/include/magma_config.h $PREFIX/include/magma_config.h
install -D ./build/lib/pkgconfig/magma.pc $PREFIX/lib/pkgconfig/magma.pc
