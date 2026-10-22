# 04 · Storage (15%)

| # | Lab | Key skills | Status |
|---|---|---|---|
| 01 | [Grow a full LVM volume online](01-lvm-extend) | pvcreate, vgextend, lvextend -r | worked example |
| 02 | Filesystem goes read-only | dmesg, fsck, `/etc/fstab`, remount | ☐ |
| 03 | Degraded RAID 1 | mdadm, `/proc/mdstat`, replace a disk | ☐ |
| 04 | NFS mount hangs | showmount, exports, nfs versions, `soft`/`hard` | ☐ |

Stretch: MicroCeph 3-node cluster on LXD VMs; recover from an OSD failure.

Core commands: `lsblk`, `blkid`, `pvs/vgs/lvs`, `mdadm`, `mount`, `findmnt`, `fsck`, `xfs_repair`.
