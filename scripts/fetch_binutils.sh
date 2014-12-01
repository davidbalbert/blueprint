#!/bin/sh

ROOT_DIR=$(pwd)

echo
echo "Installing Binutils into ./tools... This should only happen once."
echo

curl -o binutils-2.24.tar.bz2 http://ftp.gnu.org/gnu/binutils/binutils-2.24.tar.bz2

tar xvjf binutils-2.24.tar.bz2

cd binutils-2.24

./configure --prefix=$ROOT_DIR/tools --target=x86_64-linux-gnu --disable-nls --disable-werror
make
make install

cd $ROOT_DIR

rm -rf binutils-2.24
rm binutils-2.24.tar.bz2
