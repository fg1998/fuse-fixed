#!/bin/bash
current_dir=$(pwd)
mkdir fuse-bin

echo "Install dependencies"

sudo apt-get install libsdl1.2-dev libpng-dev zlib1g-dev libbz2-dev libaudiofile-dev bison flex devscripts x11proto-core-dev libdirectfb-dev libraspberrypi-dev

echo "**************************************************"
echo "              compiling libspectrum"
echo "**************************************************"
cd "$current_dir/libspectrum-1.4.4" 
autoreconf -f -i  
./configure --disable-shared
make clean
make

echo "**************************************************"
echo "              compiling fuse"
echo "**************************************************"

echo "Configuring Fuse" 
cd "$current_dir/fuse-1.5.8" 
autoreconf -f -i  

./configure --prefix="$current_dir/fuse-bin" --without-libao --without-gpm --without-gtk --without-libxml2 --with-sdl LIBSPECTRUM_CFLAGS="-I$current_dir/libspectrum-1.4.4" LIBSPECTRUM_LIBS="-L$current_dir/libspectrum-1.4.4/.libs -lspectrum"
make clean
make
make install

cp "$current_dir/tk90x.rom"  "$current_dir/fuse-bin/share/fuse/" 
cp "$current_dir/tk90x.sh"  "$current_dir/fuse-bin/"
cp "$current_dir/fuse.sh"  "$current_dir/fuse-bin"  