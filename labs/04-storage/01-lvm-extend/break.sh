#!/usr/bin/env bash
set -euo pipefail
[[ $EUID -eq 0 ]] || { echo "run with sudo" >&2; exit 1; }
d1=$(losetup -f --show /srv/disks/disk1.img)
d2=$(losetup -f --show /srv/disks/disk2.img)
echo "$d1 $d2" > /root/.lab-lvm-loops
pvcreate -q "$d1"
vgcreate -q vg_data "$d1"
lvcreate -q -l 100%FREE -n lv_data vg_data
mkfs.ext4 -q /dev/vg_data/lv_data
mkdir -p /data && mount /dev/vg_data/lv_data /data
echo "important" > /data/app.db
dd if=/dev/zero of=/data/fill bs=1M status=none 2>/dev/null || true
echo "Lab broken. /data is full. Spare disk: $d2"
