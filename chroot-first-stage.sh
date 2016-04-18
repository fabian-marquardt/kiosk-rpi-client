#!/bin/bash
source config.sh

check_root
check_dependencies
check_config
set -e

# Create chroot directory
mkdir -p $CHROOTDIR

# First stage of debootstrap
debootstrap --foreign --keyring ./$KEYRING --variant $VARIANT --include $PACKAGES --arch $ARCH $RELEASE $CHROOTDIR $MIRROR

