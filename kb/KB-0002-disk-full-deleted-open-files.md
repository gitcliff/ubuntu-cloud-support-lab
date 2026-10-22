# KB-0002: Disk space not freed after deleting a file

**Applies to:** Ubuntu 20.04, 22.04, 24.04
**Component:** Linux filesystem, process file descriptors
**Last reviewed:** 2026-10-22

## Symptom

`df -h` shows the partition is full (or still heavily used) even after large files
have been deleted. `ls` and `du` confirm the files are gone, but `df` does not
change.

## Cause

On Linux, `rm` removes the directory entry for a file but does not immediately free
the underlying disk blocks. The kernel keeps the inode — and its allocated blocks —
alive until every open file descriptor pointing to it is closed.

If a running process opened the file before it was deleted (common with log files
written by long-running daemons), that process holds a file descriptor that prevents
block reclamation. The file is invisible to `ls` and `du` (no directory entry), but
`df` still counts the blocks as used.

## Diagnosis

Use `lsof +L1` to list all open files whose link count has dropped below 1:

```bash
sudo lsof +L1
```

A row with `(deleted)` in the NAME column identifies a deleted-but-open file.
The SIZE/OFF column shows how much space it is holding.

Narrow down by process name or directory:

```bash
sudo lsof +L1 | grep <service-name>
sudo lsof +L1 | grep /var/log
```

You can also inspect the process directly via `/proc`:

```bash
sudo ls -la /proc/<pid>/fd/
```

The fd symlink path will end in ` (deleted)` for any unlinked file.

## Resolution

### Option 1 — Restart the process (preferred)

```bash
sudo systemctl restart <service>
```

The process exits, all its file descriptors are closed, and the kernel frees the
blocks. The service re-opens a fresh log file on startup.

### Option 2 — Truncate in place (no restart required)

If a restart would cause downtime, zero out the file through the `/proc` path.
The fd stays open and the process continues writing, but the blocks are freed:

```bash
# Find pid and fd number from lsof +L1
sudo truncate -s 0 /proc/<pid>/fd/<fdnumber>
```

Note: this only works if the process appends rather than seeks. Check that the
service's log continues to grow normally after truncation.

## Verification

```bash
sudo lsof +L1 | grep <service>    # should return nothing
df -h <partition>                  # usage should have dropped
```

## Related issue: inode exhaustion

If `df -h` shows free block space but you still cannot create files, check inode
usage:

```bash
df -i <partition>
```

If `IUse%` is at 100%, you have run out of inodes. Free them by deleting large
numbers of small files (mail queues, temp files, package caches):

```bash
sudo apt clean
sudo journalctl --vacuum-size=500M
```

## Prevention

- Configure `logrotate` (or `StandardOutput=journal` in the systemd unit) so logs
  are rotated before they grow large.
- Services should re-open log files on `SIGHUP` to allow hot rotation without a
  full restart.
- Monitor both `df -h` and `df -i` and alert above 80%.

## Additional information

- `man lsof` — `-L` flag
- `man proc` — the `/proc/<pid>/fd` filesystem
- Lab: [labs/01-linux/02-disk-full-df-free](../labs/01-linux/02-disk-full-df-free)
