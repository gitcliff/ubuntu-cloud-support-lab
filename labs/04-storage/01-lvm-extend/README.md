# Lab 01: Grow a full LVM volume online

| | |
|---|---|
| Domain | storage |
| Difficulty | ★☆☆ |
| Time | ~30 min |
| Environment | Multipass `lab` VM (uses loop disks in `/srv/disks`) |

## Scenario
> "Our `/data` volume is 100% full and the app is throwing write errors. We've attached
> a new disk. Can we grow it without downtime?"

## Learning objectives
- The PV → VG → LV stack, and `pvs`, `vgs`, `lvs`
- `vgextend`, then `lvextend -r` (resizes the filesystem too)
- Why ext4/xfs can grow online, and why shrinking is different

## Break
```bash
sudo ./break.sh
```
This creates `vg_data/lv_data` on one 1 GB disk mounted at `/data`, fills it,
and leaves `/dev/loop` for disk 2 unused.

## Verify
```bash
df -h /data   # more free space, app files still present
```

## Reset
```bash
sudo ./reset.sh
```
