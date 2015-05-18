#!/bin/bash
set -e
PWD=$(pwd)
CHROOTDIR=$PWD/chroot
FWDIR=$PWD/firmware
IMGDIR=$PWD/images
MOUNTDIR=$PWD/mnt

# Root privileges check
if [[ $EUID -ne 0 ]]; then
  echo "Must be root to run this script."
  exit 1
fi

# Path fix for use on non-debian systems which do not use sbin
PATH=/usr/local/sbin:/usr/sbin:/sbin:$PATH

# Parse command line arguments
while getopts ':h:p:' OPTION ; do
    case "$OPTION" in
        h)   HOSTNAME=$OPTARG;;
        p)   PASSWORD=$OPTARG;;
    esac
done

# Check if all mandatory parameters are set, otherwise print usage info
if [ -z $HOSTNAME ] || [ -z $PASSWORD ];
then
    echo "Usage: $0 -h <hostname> -p <password>"
    exit 1
fi

# Obtain necessary dependencies
KPARTX=$(which kpartx)
QEMUARM=$(which qemu-arm-static)
BINFMT=$(cat /proc/sys/fs/binfmt_misc/arm | grep qemu-arm-static)

# Check if all dependencies are present
if [ -z $KPARTX ];
then
    echo "Dependency missing: kpartx"
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
mkdir -p $IMGDIR
mkdir -p $MOUNTDIR

# Create image
dd if=/dev/zero of=${IMGDIR}/${HOSTNAME}.img bs=1MB count=2048

# Create partitions
fdisk ${IMGDIR}/${HOSTNAME}.img<<EOF
n
p
1

+64M
t
c
n
p
2


w
EOF

# Create filesystems and mount partitions
LOOPDEV=$(kpartx -va ${IMGDIR}/${HOSTNAME}.img  | sed -E 's/.*(loop[0-9])p.*/\1/g' | head -1)
sleep 3 # some wait time here because the loop devices may take a moment to appear correctly
mkfs.ext4 /dev/mapper/${LOOPDEV}p2
mkfs.vfat /dev/mapper/${LOOPDEV}p1
mount /dev/mapper/${LOOPDEV}p2 $MOUNTDIR
mkdir -p $MOUNTDIR/boot
mount /dev/mapper/${LOOPDEV}p1 $MOUNTDIR/boot

# Copy files
cp -va $CHROOTDIR/* $MOUNTDIR
mkdir -p $MOUNTDIR/opt/
mkdir -p $MOUNTDIR/lib/modules/
cp -vr $FWDIR/hardfp/opt/* $MOUNTDIR/opt/
cp -vr $FWDIR/modules/* $MOUNTDIR/lib/modules/
cp -vr $FWDIR/boot/* $MOUNTDIR/boot/

# Set bootloader config
cat >$MOUNTDIR/boot/config.txt<<EOF
kernel=kernel.img
arm_freq=800
core_freq=250
sdram_freq=400
over_voltage=0
gpu_mem=16
EOF

cat >$MOUNTDIR/boot/cmdline.txt<<EOF
dwc_otg.lpm_enable=0 root=/dev/mmcblk0p2 rootfstype=ext4 rootwait
EOF

# Configure hostname
echo $HOSTNAME >$MOUNTDIR/etc/hostname

# Configure network settings
cat >$MOUNTDIR/etc/network/interfaces<<EOF
auto lo
iface lo inet loopback

auto eth0
iface eth0 inet dhcp
EOF

# Create fstab
cat >$MOUNTDIR/etc/fstab<<EOF
proc /proc proc defaults 0 0
/dev/mmcblk0p1 /boot vfat defaults 0 0
/dev/mmcblk0p2 / ext4 defaults 0 0
EOF

# Create user account
cat >$MOUNTDIR/user-config.sh<<EOF
#!/bin/bash
useradd kiosk
echo kiosk:$PASSWORD | chpasswd
echo root:$PASSWORD | chpasswd
EOF
chmod +x $MOUNTDIR/user-config.sh
chroot $MOUNTDIR /user-config.sh
rm $MOUNTDIR/user-config.sh

# Unmount image
umount $MOUNTDIR/boot
umount $MOUNTDIR
kpartx -vd ${IMGDIR}/${HOSTNAME}.img
