#!/bin/sh

PATH=/bin:/sbin:/usr/bin:/usr/sbin:/opt/local/bin:/opt/local/sbin

cat<<EOF
#################################
# OVERLAY FS mount in progress! #
#################################

EOF

# Mount /proc and /sys
mount -t proc proc /proc
mount -t sysfs sysfs /sys

# Start udev
/etc/init.d/udev start

# Wait for udev to complete the initialization
udevadm settle

# We need to create directories somewhere, therefore
# create a temporary fs mounted on /mnt
mount -t tmpfs inittemp /mnt

# Mount our RO filesystem somewhere
mkdir /mnt/lower
mount -o defaults,ro /dev/mmcblk0p2 /mnt/lower
if [ $? -ne 0 ]; then
	/bin/sh
fi

# We need a somewhere to put whatever is needed
# for overlayfs, let's use /mnt/rw
mkdir /mnt/rw
mount -t tmpfs root-rw /mnt/rw

# Used by overlayfs for the upper layer
mkdir /mnt/rw/upper

# Used by overlayfs as work area
mkdir /mnt/rw/work

# Used by overlayfs for the final result
mkdir /mnt/newroot

# Make the sandwich
mount -t overlay -o lowerdir=/mnt/lower,upperdir=/mnt/rw/upper,workdir=/mnt/rw/work overlayfs-root /mnt/newroot

# Generate a new /etc/fstab
mkdir /mnt/newroot/etc
(
	# Remove root mount from fstab (this is already a non-permanent modification)
	grep -v "/dev/root" /mnt/lower/etc/fstab

	# Document what we are doing within /etc/fstab
	cat<<-EOF
	# The original root mount has been removed by the overlay system.
	# This is only a temporary modification, the original fstab
	# stored on the disk can be found in /ro/etc/fstab.
	EOF
) > /mnt/newroot/etc/fstab

# Create mountpoints inside the new root filesystem-overlay
mkdir /mnt/newroot/ro
mkdir /mnt/newroot/rw

# Switch to the new rootfs
cd /mnt/newroot
pivot_root . mnt

exec chroot . sh -c "$(
cat<<END
# move ro and rw mounts to the new root
mount --move /mnt/mnt/lower/ /ro
mount --move /mnt/mnt/rw /rw

# unmount unneeded mounts so we can unmout the old readonly root
umount /mnt/mnt
umount /mnt/proc
umount /mnt/sys
umount /mnt/dev
umount /mnt

# continue with regular init
exec /sbin/init
END
)"
