#!/bin/bash
source config.sh

check_root
check_dependencies
check_config
set -e

# Copy qemu-arm-static to the chroot
cp $QEMUARM $CHROOTDIR/usr/bin

# Copy keyring to chroot
mkdir -p $CHROOTDIR/usr/share/keyrings/
cp $KEYRING $CHROOTDIR/usr/share/keyrings/ubuntu-archive-keyring.gpg

# Second stage of debootstrap
DEBIAN_FRONTEND=noninteractive DEBCONF_NONINTERACTIVE_SEEN=true LC_ALL=C LANGUAGE=C LANG=C chroot $CHROOTDIR /debootstrap/debootstrap --second-stage

