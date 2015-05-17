#!/bin/bash
set -e
PWD=$(pwd)
CHROOTDIR=$PWD/chroot

# Root privileges check
if [[ $EUID -ne 0 ]]; then
  echo "Must be root to run this script."
  exit 1
fi

# Config parameters
PACKAGES=locales,console-setup,openssh-server,ifupdown,net-tools,ntp,ntpdate,iceweasel,xinit,openbox,x11-xserver-utils

# Path fix for use on non-debian systems which do not use sbin
PATH=/usr/local/sbin:/usr/sbin:/sbin:$PATH

# Obtain necessary dependencies
DEBOOTSTRAP=$(which debootstrap)
QEMUDEBOOTSTRAP=$(which qemu-debootstrap)
KPARTX=$(which kpartx)
QEMUARM=$(which qemu-arm-static)
BINFMT=$(cat /proc/sys/fs/binfmt_misc/arm | grep qemu-arm-static)

# Check if all dependencies are present
if [ -z $DEBOOTSTRAP ];
then
    echo "Dependency missing: debootstrap"
    exit 1
fi

if [ -z $QEMUDEBOOTSTRAP ];
then
    echo "Dependency missing: qemu-debootstrap"
    exit 1
fi

if [ -z $QEMUARM ];
then
    echo "Dependency missing: qemu-arm-static"
    exit 1
fi

if [ -z $BINFMT ];
then
    echo "Binfmt support for the ARM platform is not available. This is required to build the image on your PC."
    exit 1
fi

# Create directories
mkdir -p $CHROOTDIR

# Base installation
qemu-debootstrap --variant minbase --include $PACKAGES --arch armhf jessie $CHROOTDIR http://archive.raspbian.org/raspbian
