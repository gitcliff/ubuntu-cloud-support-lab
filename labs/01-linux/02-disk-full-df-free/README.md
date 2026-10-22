# Lab 02: Disk full but `df` says space is free

|             |                    |
| ----------- | ------------------ |
| Domain      | linux              |
| Difficulty  | ★★☆                |
| Time        | ~40 min            |
| Environment | Multipass `lab` VM |

## Scenario

> "I deleted the log files an hour ago but `df` still shows the partition at the
> same usage. The application keeps failing to write new logs. Nothing makes sense."

## Learning objectives

- Understand how Unix file deletion works (directory entry vs. inode vs. disk blocks)
- Use `lsof +L1` to find deleted files still held open by a process
- Use `/proc/<pid>/fd/` as an alternative way to inspect open file descriptors
- Know when to restart a service vs. truncate a log in place
- Use `df -i` to distinguish block exhaustion from inode exhaustion

## Break

```bash
sudo bash scripts/break.sh
```

Do not read `break.sh` before you attempt to diagnose the problem.

## Symptoms

Run the following after breaking the lab and record what you see:

```bash
ls -lh /opt/loggen/
du -sh /opt/loggen/
df -h .
```

The directory listing will show `app.log` is gone, but `du` and `df` will reveal
that disk blocks are still consumed. Try to create a file:

```bash
touch /opt/loggen/test.txt
```

This should succeed here (the lab doesn't fill the disk), but on a production system
with a large log this is where you'd see `No space left on device`.

> Paste your actual output here when you run the lab.

## Diagnose

### Why is `df` still showing space used after deleting the file?

On Linux, deleting a file (`rm`) removes the directory entry but does not free the
underlying disk blocks until every open file descriptor pointing to that inode is
closed. If a process opened the file before `rm` was called, it keeps a valid fd
and continues reading/writing the data — from its perspective the file still exists.

`df` reports block usage at the filesystem level, so it sees the blocks as still
allocated. `ls` and `du` look at directory entries and inodes, so they do not show
the file. This gap between what `du` reports and what `df` reports is the
diagnostic signal.

### Step 1 — Confirm the gap

```bash
df -h /opt/loggen
du -sh /opt/loggen/
```

`df` and `du` should disagree on how much space is used under `/opt/loggen`.

### Step 2 — Find the deleted-but-open file

`lsof +L1` lists all open files whose link count has dropped below 1 — meaning they
have been unlinked (deleted) from the filesystem but are still held open:

```bash
sudo lsof +L1
```

Look for a row that names `/opt/loggen/app.log (deleted)`. Note the PID and the
file descriptor number (FD column).

Narrow it down:

```bash
sudo lsof +L1 | grep loggen
```

### Step 3 — Inspect via /proc

Every open file descriptor is visible in `/proc/<pid>/fd/`. Find the PID from
`lsof`, then:

```bash
sudo ls -la /proc/<pid>/fd/
```

The symlink for the open fd points to the path followed by ` (deleted)`. The size
of the underlying file is readable via the fdinfo or stat on the fd:

```bash
sudo stat /proc/<pid>/fd/<fdnumber>
```

### Step 4 — How much space is the deleted file occupying?

```bash
sudo lsof +L1 | awk 'NR>1 {print $7, $9}' | sort -rn | head
```

The seventh field is the file size in bytes. This tells you how much space will be
freed when the process releases the fd.

> Paste your actual `lsof +L1` output here.

## Root cause

The `loggen` service opened `/opt/loggen/app.log` at startup and kept the file
descriptor open. When the operator deleted the file with `rm`, the directory entry
was removed but the kernel kept the inode and its disk blocks allocated because
`loggen` still held an open fd. The space appeared to be freed (the file was gone
from `ls`) but was not actually freed at the filesystem level.

## Fix

Restart the service. This causes the process to exit, closing all its file
descriptors. The kernel then releases the blocks:

```bash
sudo systemctl restart loggen
```

After the restart, the service opens a fresh `app.log`. Verify the old deleted
inode is gone:

```bash
sudo lsof +L1 | grep loggen    # should return nothing
ls -lh /opt/loggen/app.log     # new file, small size
df -h /opt/loggen              # blocks freed
```

**Alternative fix without a restart (live systems):** If you cannot restart the
service, truncate the file through the `/proc/fd` path. This frees the blocks
without closing the fd:

```bash
# Find the pid and fd number from lsof +L1
sudo truncate -s 0 /proc/<pid>/fd/<fdnumber>
```

> Paste your post-fix `df -h` output here.

## Verify

```bash
sudo lsof +L1 | grep loggen    # no output = no more deleted-but-open files
ls -lh /opt/loggen/app.log     # new log file exists
df -h /opt/loggen              # usage has dropped
```

## Bonus: inode exhaustion

A different way `df` can mislead: your filesystem has free blocks but no free
inodes. You cannot create new files even though `df -h` shows space available.

```bash
df -i /opt/loggen
```

If `IUse%` is at 100%, you need to delete many small files to free inodes.
Common culprits: mail queues, package manager caches, and temp-file spam.

## Prevent

1. **Log rotation:** configure `logrotate` (or systemd's `logrotate` drop-in) to
   rotate and compress logs before they grow large.
2. **Structured logging:** write logs to `journald` (`StandardOutput=journal` in
   the unit file) so systemd manages retention automatically.
3. **Restart-aware log open:** services should re-open log files on `SIGUSR1` or
   `SIGHUP` so log rotation can replace the file without a full restart.
4. **Monitor:** alert on `df -h` above 80% and `df -i` above 80%.

## References

- `man lsof` — `-L` flag documentation
- `man proc` — `/proc/<pid>/fd` section
- `man logrotate`
- Lab: this file

## Reset

```bash
sudo bash scripts/reset.sh
```
