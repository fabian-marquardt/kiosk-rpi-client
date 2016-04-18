#!/bin/bash

# Config parameters
MIRROR=http://ports.ubuntu.com/
RELEASE=trusty
ARCH=armhf
VARIANT=minbase
PACKAGES=locales,console-setup,netbase,ifupdown,net-tools,isc-dhcp-client,ntp,ntpdate,openssh-server,vim,xserver-xorg,xinit,x11-xserver-utils
KEYRING=ubuntu-archive-keyring.gpg

# Directories
PWD=$(pwd)
CHROOTDIR=$PWD/chroot
FWDIR=$PWD/firmware
IMGDIR=$PWD/images
MOUNTDIR=$PWD/mnt

# Path fix for use on non-debian systems
export PATH=/usr/local/sbin:/usr/sbin:/sbin:/bin:$PATH

# Obtain necessary dependencies
DEBOOTSTRAP=$(which debootstrap)
QEMUARM=$(which qemu-arm-static)
BINFMT=$(cat /proc/sys/fs/binfmt_misc/qemu-arm | grep qemu-arm-static)
KPARTX=$(which kpartx)

# Common functions
check_root(){
  if [[ $EUID -ne 0 ]]; then
    echo "Must be root to run this script."
    exit 1
  fi
}

check_dependencies(){
  if [ -z "$DEBOOTSTRAP" ];
  then
    echo "Dependency missing: debootstrap"
    exit 1
  fi

  if [ -z "$QEMUARM" ];
  then
    echo "Dependency missing: qemu-arm-static"
    exit 1
  fi

  if [ -z "$BINFMT" ];
  then
    echo "Binfmt support for the ARM platform is not available. This is required to build the image on your PC."
    exit 1
  fi

  if [ -z "$KPARTX" ];
  then
    echo "Dependency missing: kpartx"
    exit 1
  fi
}

check_config(){
  if [ -z "$CHROOTDIR" ];
  then
    echo "Configuration setting \$CHROOTDIR is missing. Aborting."
    exit 1
  fi

  if [ -z "$FWDIR" ];
  then
    echo "Configuration setting \$FWDIR is missing. Aborting."
    exit 1
  fi

  if [ -z "$IMGDIR" ];
  then
    echo "Configuration setting \$IMGDIR is missing. Aborting."
    exit 1
  fi

  if [ -z "$MOUNTDIR" ];
  then
    echo "Configuration setting \$MOUNTDIR is missing. Aborting."
    exit 1
  fi

  if [ -z "$MIRROR" ];
  then
    echo "Configuration setting \$MIRROR is missing. Aborting."
    exit 1
  fi

  if [ -z "$RELEASE" ];
  then
    echo "Configuration setting \$RELEASE is missing. Aborting."
    exit 1
  fi

  if [ -z "$ARCH" ];
  then
    echo "Configuration setting \$ARCH is missing. Aborting."
    exit 1
  fi

  if [ -z "$VARIANT" ];
  then
    echo "Configuration setting \$VARIANT is missing. Aborting."
    exit 1
  fi

  if [ -z "$PACKAGES" ];
  then
    echo "Configuration setting \$PACKAGES is missing. Aborting."
    exit 1
  fi

  if [ -z "$KEYRING" ];
  then
    echo "Configuration setting \$KEYRING is missing. Aborting."
    exit 1
  fi
}
