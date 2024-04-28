#!/bin/bash

set -x

cd "$(dirname -- "$(readlink -f -- "$0")")"

mkdir -p build/chroot
cd build

# Query the system to locate livecd-rootfs auto script installation path
cp -r "$(dpkg -L livecd-rootfs | grep "auto$")" auto

while [ "$#" -gt 0 ]; do
    case "${1}" in
        -s|--server)
            export PROJECT=ubuntu-cpc
            name="server"
            shift
            ;;
        -d|--desktop)
            export SUBPROJECT=desktop-preinstalled
            export PROJECT=ubuntu
            name="desktop"
            shift
            ;;
        -v|--verbose)
            set -x
            shift
            ;;
        -*)
            echo "Error: unknown argument \"${1}\""
            exit 1
            ;;
        *)
            shift
            ;;
    esac
done

export ARCH=arm64
export SUITE=noble
export IMAGEFORMAT=none
export IMAGE_TARGETS=none
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

sed -i 's/libgl1-amber-dri//g' config/package-lists/livecd-rootfs.list.chroot_install
echo "snapd/classic=stable" > config/seeded-snaps
echo "core22/classic=stable" >> config/seeded-snaps
echo "lxd/classic=stable" >> config/seeded-snaps

echo "mali-g610-firmware" > config/package-lists/my.list.chroot
echo "rockchip-multimedia-config" >> config/package-lists/my.list.chroot

if [ "${PROJECT}" == "ubuntu" ]; then
    echo "ubuntu-desktop-rockchip" >> config/package-lists/my.list.chroot
    echo "oem-config-gtk" >> config/package-lists/my.list.chroot
    echo "ubiquity-frontend-gtk" >> config/package-lists/my.list.chroot
    echo "ubiquity-slideshow-ubuntu" >> config/package-lists/my.list.chroot
    echo "gstreamer1.0-rockchip1" >> config/package-lists/my.list.chroot
    echo "chromium-browser" >> config/package-lists/my.list.chroot
    echo "libv4l-rkmpp" >> config/package-lists/my.list.chroot
    echo "localechooser-data" >> config/package-lists/my.list.chroot
else
    echo "ubuntu-server-rockchip" >> config/package-lists/my.list.chroot
fi

lb build 

(cd chroot/ &&  tar -p -c --sort=name --xattrs *) | xz -3 -T0 > ubuntu-24.04-preinstalled-$name-arm64.rootfs.tar.xz
