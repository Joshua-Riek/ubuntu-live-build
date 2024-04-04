#!/bin/bash

set -x

cd "$(dirname -- "$(readlink -f -- "$0")")"

mkdir -p build/chroot
cd build

# Query the system to locate livecd-rootfs auto script installation path
cp -r "$(dpkg -L livecd-rootfs | grep "auto$")" auto

export ARCH=arm64
export SUITE=noble
export IMAGEFORMAT=ext4
export IMAGE_TARGETS=tarball
export PROJECT=ubuntu-cpc
export EXTRA_PPAS="jjriek/rockchip jjriek/rockchip-multimedia jjriek/panfork-mesa"

lb config \
	--architecture arm64 \
	--bootstrap-qemu-arch arm64 \
	--bootstrap-qemu-static /usr/bin/qemu-aarch64-static \
	--archive-areas "main restricted universe multiverse" \
	--parent-archive-areas "main restricted universe multiverse" \
    --mirror-bootstrap "http://ports.ubuntu.com" \
    --parent-mirror-bootstrap "http://ports.ubuntu.com" \
    --mirror-chroot-security "http://ports.ubuntu.com" \
    --parent-mirror-chroot-security "http://ports.ubuntu.com" \
    --mirror-binary-security "http://ports.ubuntu.com" \
    --parent-mirror-binary-security "http://ports.ubuntu.com" \
    --mirror-binary "http://ports.ubuntu.com" \
    --parent-mirror-binary "http://ports.ubuntu.com" \
    --keyring-packages ubuntu-keyring \
    --linux-flavours rockchip

cp -rv ../config ./

lb build 
lb binary
lb binary_chroot
lb binary_rootfs
lb binary_manifest
lb binary_package-lists 
lb binary_linux-image 
lb binary_includes 
lb binary_hooks

mv livecd.ubuntu-cpc.rootfs.tar.xz ubuntu-24.04-beta-preinstalled-server-arm64.rootfs.tar.xz
