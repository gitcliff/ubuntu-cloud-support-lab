# 01 · Linux 

| # | Lab | Key skills | Status |
|---|---|---|---|
| 01 | [Service won't start after reboot](01-systemd-failed-service) | systemctl, journalctl, unit files | worked example |
| 02 | [Disk full but `df` says space is free](02-disk-full-df-free) | df -i, inodes, deleted-but-open files (`lsof +L1`) | ready to run |
| 03 | Broken apt / dpkg state | `dpkg --configure -a`, held packages, apt pinning | ☐ |
| 04 | Server is "slow" | load average, vmstat, iostat, sar, OOM killer | ☐ |
| 05 | Can't SSH in | sshd config, keys, permissions, PAM, `/var/log/auth.log` | ☐ |
| 06 | Unbootable after kernel update | GRUB, recovery mode, initramfs, `apt-mark hold` | ☐ |

Core commands to master: `systemctl`, `journalctl`, `ps`, `top/htop`, `vmstat`, `iostat`,
`sar`, `lsof`, `strace`, `dmesg`, `apt`, `dpkg`, `snap`.
