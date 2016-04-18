#!/bin/bash
source config.sh

check_root
check_dependencies
check_config
set -e

# Parse command line arguments
while getopts ':h:p:u:' OPTION ; do
    case "$OPTION" in
        h)   HOSTNAME=$OPTARG;;
        p)   PASSWORD=$OPTARG;;
	u)   URL=$OPTARG;;
    esac
done

# Check if all mandatory parameters are set, otherwise print usage info
if [ -z "$HOSTNAME" ] || [ -z "$PASSWORD" ] || [ -z "$URL" ];
then
    echo "Usage: $0 -h <hostname> -p <password> -u <url>"
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
# Set special RPi config options here
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
useradd kiosk -s /bin/bash
mkdir /home/kiosk
chown kiosk:kiosk /home/kiosk
echo kiosk:$PASSWORD | chpasswd
echo root:$PASSWORD | chpasswd
EOF
chmod +x $MOUNTDIR/user-config.sh
chroot $MOUNTDIR /user-config.sh
rm $MOUNTDIR/user-config.sh

# Create xinitrc
cat >$MOUNTDIR/home/kiosk/.xinitrc<<EOF
#!/bin/bash
xset s off
xset -dpms
xset s noblank
chromium-browser --temp-profile --no-first-run --noerrdialogs --disable-translate --kiosk $URL &
exec openbox
EOF

# Create rc.local
cat >$MOUNTDIR/etc/rc.local<<EOF
#!/bin/bash
su - kiosk -c startx
exit 0
EOF

# Fix Xwrapper
cat >$MOUNTDIR/etc/X11/Xwrapper.config<<EOF
allowed_users=anybody
EOF

# Unmount image
umount $MOUNTDIR/boot
umount $MOUNTDIR
kpartx -vd ${IMGDIR}/${HOSTNAME}.img
