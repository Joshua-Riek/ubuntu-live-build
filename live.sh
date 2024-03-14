#!/bin/bash

mkdir -p tmp
cd tmp || exit

# Query the system to locate livecd-rootfs auto script installation path
cp -r "$(dpkg -L livecd-rootfs | grep "auto$")" auto

# Create the config directory
sudo PROJECT=ubuntu SUBPROJECT=desktop-preinstalled SUITE=jammy ARCH=arm64 SUBARCH=raspi PREINSTALLED=true IMAGEFORMAT=ubuntu-image lb config

# Start the bootstrap, chroot, installer, binary, and source stages
sudo PROJECT=ubuntu SUBPROJECT=desktop-preinstalled SUITE=jammy ARCH=arm64 SUBARCH=raspi PREINSTALLED=true IMAGEFORMAT=ubuntu-image lb build 
