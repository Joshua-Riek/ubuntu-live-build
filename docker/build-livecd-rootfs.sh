#!/bin/bash

set -eE 
trap 'echo Error: in $0 on line $LINENO' ERR

tmp_dir=$(mktemp -d)
cd "${tmp_dir}" || exit 1

# Clone the livecd rootfs fork
git clone https://github.com/Joshua-Riek/livecd-rootfs -b upstream
cd livecd-rootfs || exit 1

# Install build deps
apt-get update
apt-get build-dep . -y

# Build the package
dpkg-buildpackage -us -uc

# Install the custom livecd rootfs package
apt-get install ../livecd-rootfs_*.deb --assume-yes --allow-downgrades 
dpkg -i ../livecd-rootfs_*.deb
apt-mark hold livecd-rootfs

rm -rf "${tmp_dir}"
