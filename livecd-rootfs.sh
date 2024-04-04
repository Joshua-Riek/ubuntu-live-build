#!/bin/bash

set -eE 
trap 'echo Error: in $0 on line $LINENO' ERR

cd "$(dirname -- "$(readlink -f -- "$0")")"

mkdir -p build/livecd-rootfs
cd build/livecd-rootfs

git clone https://git.launchpad.net/~jjriek/livecd-rootfs -b ubuntu-rockchip
cd livecd-rootfs
sudo apt-get -y build-dep .
dpkg-buildpackage -us -uc
sudo apt-get -y install ../livecd-rootfs_*.deb
sudo apt-get -y install ../livecd-rootfs_*.deb

