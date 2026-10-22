# Lab 02 working notes — Disk full but `df` says space is free

**Date:** <!-- fill in when you run the lab -->
**Environment:** Multipass `lab` VM, Ubuntu 24.04 LTS

Fill in each section as you work through the lab. Paste actual command output —
do not summarise or paraphrase it.

---

## Step 1 — Reproduce the failure

```bash
sudo bash scripts/break.sh
```

Output:
```
<!-- paste here -->
```

---

## Step 2 — Observe symptoms

```bash
ls -lh /opt/loggen/
```
```
<!-- paste here -->
```

```bash
du -sh /opt/loggen/
```
```
<!-- paste here -->
```

```bash
df -h .
```
```
<!-- paste here -->
```

Observations:
- `app.log` present in listing? Yes / No
- `du` reports: ___
- `df` usage: ___
- Gap between `du` and `df`? Yes / No

---

## Step 3 — Diagnose

### lsof +L1

```bash
sudo lsof +L1
```
```
<!-- paste here -->
```

Key row I found:
```
<!-- paste the loggen row here -->
```

PID: ___
FD number: ___
File size shown: ___

### Inspect via /proc

```bash
sudo ls -la /proc/<pid>/fd/
```
```
<!-- paste here -->
```

```bash
sudo stat /proc/<pid>/fd/<fdnumber>
```
```
<!-- paste here -->
```

### My hypothesis

<!-- write your root cause hypothesis before reading the README fix section -->

---

## Step 4 — Root cause

<!-- state the root cause in your own words after you have confirmed it -->

---

## Step 5 — Fix

```bash
sudo systemctl restart loggen
```

Post-restart check:
```bash
sudo lsof +L1 | grep loggen
```
```
<!-- paste here — should be empty -->
```

```bash
ls -lh /opt/loggen/app.log
```
```
<!-- paste here -->
```

```bash
df -h /opt/loggen
```
```
<!-- paste here -->
```

---

## Step 6 — Bonus: inode check

```bash
df -i /opt/loggen
```
```
<!-- paste here -->
```

Notes on what the IUse% value means here:
<!-- your observations -->

---

## Step 7 — Reset

```bash
sudo bash scripts/reset.sh
```
```
<!-- paste here -->
```

Confirmed clean:
- `systemctl status loggen` → ___
- `ls /opt/loggen` → ___

---

## Key commands learned

| Command | Purpose |
|---|---|
| `lsof +L1` | List open files whose link count < 1 (deleted but still open) |
| `ls -la /proc/<pid>/fd/` | Inspect all file descriptors held by a process |
| `truncate -s 0 /proc/<pid>/fd/<n>` | Zero out a deleted-but-open file without restarting the process |
| `df -i` | Show inode usage (vs. block usage shown by default `df -h`) |
| `du -sh <dir>` | Report actual disk usage of a directory tree |

---

## Related

- KB article: [KB-0002-disk-full-deleted-open-files.md](../../../kb/KB-0002-disk-full-deleted-open-files.md)
- Support case: [0002-disk-full-after-deleting-logs.md](../../../support-cases/0002-disk-full-after-deleting-logs.md)
