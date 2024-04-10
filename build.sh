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
    cat << 'EOF' > ../config/hooks/001-tar.binary
#!/bin/bash -ex
# vi: ts=4 expandtab
#
# Generate the root directory/manifest for rootfs.tar.xz and squashfs

if [ -n "$SUBARCH" ]; then
    echo "Skipping rootfs build for subarch flavor build"
    exit 0
fi

. config/functions

rootfs_dir=rootfs.dir
mkdir $rootfs_dir
cp -a chroot/* $rootfs_dir

setup_mountpoint $rootfs_dir

env DEBIAN_FRONTEND=noninteractive chroot $rootfs_dir apt-get autoremove --purge --assume-yes
rm -rf $rootfs_dir/boot/grub

snap_prepare $rootfs_dir

for snap in core snapd lxd; do
    SNAP_NO_VALIDATE_SEED=1 snap_preseed $rootfs_dir "${snap}" stable
done

snap_validate_seed $rootfs_dir

teardown_mountpoint $rootfs_dir

(cd $rootfs_dir/ &&  tar -c --sort=name --xattrs *) | xz -3 -T0 > livecd.ubuntu-cpc.rootfs.tar.xz

exit 99999
EOF
chmod +x ../config/hooks/001-tar.binary
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
export IMAGEFORMAT=ext4
export IMAGE_TARGETS=tarball
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
if [[ "${PROJECT}" == "ubuntu" ]]; then
echo > config/seeded-snaps
sed -i 's/libgl1-amber-dri//g' config/package-lists/livecd-rootfs.list.chroot_install
else
echo "core" > config/seeded-snaps
echo "snapd" >> config/seeded-snaps
echo "lxd" >> config/seeded-snaps
fi

lb build 
lb binary
lb binary_chroot
lb binary_rootfs
lb binary_manifest
lb binary_package-lists 
lb binary_linux-image 
lb binary_includes 
lb binary_hooks

mv livecd.ubuntu-cpc.rootfs.tar.xz ubuntu-24.04-beta-preinstalled-$name-arm64.rootfs.tar.xz
