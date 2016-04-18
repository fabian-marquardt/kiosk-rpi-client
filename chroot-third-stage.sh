#!/bin/bash
source config.sh

check_root
check_dependencies
check_config
set -e

# Mount file systems
mount -t proc none $CHROOTDIR/proc
mount -t sysfs none $CHROOTDIR/sys
mount -t devpts devpts $CHROOTDIR/dev/pts

# Update sources.list
cat >$CHROOTDIR/etc/apt/sources.list<<EOF
deb http://ports.ubuntu.com/ ${RELEASE} main restricted universe multiverse
deb http://ports.ubuntu.com/ ${RELEASE}-updates main restricted universe multiverse
deb http://ports.ubuntu.com/ ${RELEASE}-security main restricted universe multiverse
deb http://ports.ubuntu.com/ ${RELEASE}-backports main restricted universe multiverse
EOF

# Full update
DEBIAN_FRONTEND=noninteractive DEBCONF_NONINTERACTIVE_SEEN=true LC_ALL=C LANGUAGE=C LANG=C chroot $CHROOTDIR apt-get update
# DEBIAN_FRONTEND=noninteractive DEBCONF_NONINTERACTIVE_SEEN=true LC_ALL=C LANGUAGE=C LANG=C chroot $CHROOTDIR apt-get -y -u dist-upgrade

# Install chromium
DEBIAN_FRONTEND=noninteractive DEBCONF_NONINTERACTIVE_SEEN=true LC_ALL=C LANGUAGE=C LANG=C chroot $CHROOTDIR apt-get -y install --no-install-recommends libexif12 chromium-browser openbox

# Clean apt cache
DEBIAN_FRONTEND=noninteractive DEBCONF_NONINTERACTIVE_SEEN=true LC_ALL=C LANGUAGE=C LANG=C chroot $CHROOTDIR apt-get clean

# Unmount file systems
umount $CHROOTDIR/proc
umount $CHROOTDIR/sys
umount $CHROOTDIR/dev/pts

# Clean up files
rm -f $CHROOTDIR/etc/apt/sources.list.save
rm -f $CHROOTDIR/etc/resolvconf/resolv.conf.d/original
rm -f $CHROOTDIR/root/.bash_history
rm -rf $CHROOTDIR/tmp/*
rm -rf $CHROOTDIR/dev/*
rm -f $CHROOTDIR/var/lib/urandom/random-seed
[ -L $CHROOTDIR/var/lib/dbus/machine-id ] || rm -f $CHROOTDIR/var/lib/dbus/machine-id
rm -f $CHROOTDIR/etc/machine-id
