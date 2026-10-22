# Lab 01 working notes — Service won't start after reboot

**Date:** 2026-10-22
**Environment:** Multipass `lab` VM, Ubuntu 24.04 LTS

---

## Step 1 — Reproduce the failure

```bash
sudo bash break.sh
```

Output:
```
Lab broken. Start investigating with: systemctl status reportd
```

What the script did (checked after the lab):
- Created `/opt/reportd/reportd` (a bash loop script) with mode `0644` — no execute bit
- Installed `/etc/systemd/system/reportd.service`
- Ran `systemctl daemon-reload && systemctl enable --now reportd`

---

## Step 2 — Observe symptoms

```bash
sudo systemctl status reportd
```

Output:
```
● reportd.service - Internal report daemon
     Loaded: loaded (/etc/systemd/system/reportd.service; enabled; preset: enabled)
     Active: activating (auto-restart) (Result: exit-code) since Thu 2026-10-22 15:04:39 UTC; 995ms ago
    Process: 9258 ExecStart=/opt/reportd/reportd (code=exited, status=203/EXEC)
   Main PID: 9258 (code=exited, status=203/EXEC)
        CPU: 410us
```

Key observations:
- `Active: activating (auto-restart)` — the service keeps restarting and failing
- `status=203/EXEC` — this is the critical clue; systemd couldn't execute the binary
- `Restart=on-failure` in the unit file explains the loop

---

## Step 3 — Diagnose

### Check the journal for more detail

```bash
sudo journalctl -u reportd -b --no-pager -n 20
```

Output: repeated lines showing `Failed with result 'exit-code'`. No `Permission denied`
message here, but the exit code already tells the story.

### Read the unit file

```bash
systemctl cat reportd
```

Output:
```
# /etc/systemd/system/reportd.service
[Unit]
Description=Internal report daemon
After=network-online.target

[Service]
ExecStart=/opt/reportd/reportd
Restart=on-failure
RestartSec=2

[Install]
WantedBy=multi-user.target
```

This tells me the exact path systemd is trying to run: `/opt/reportd/reportd`.

### Check whether the file exists and its permissions

```bash
ls -l /opt/reportd/reportd
```

Output:
```
-rw-r--r-- 1 root root 64 Oct 22 15:04 /opt/reportd/reportd
```

The permission bits are `rw-r--r--` (mode `0644`). There is no `x` anywhere — the
file cannot be executed by anyone. That is the root cause.

### Confirm with a direct test

```bash
sudo -u root test -x /opt/reportd/reportd && echo executable || echo NOT executable
```

Output: `NOT executable`

### What does 203/EXEC mean?

`man systemd.exec` → section "PROCESS EXIT CODES":

> **203/EXEC** — The process could not be executed. The most common cause is that
> the executable was not found, was not executable, or the interpreter specified
> in a script's shebang was not found.

---

## Step 4 — Root cause

`/opt/reportd/reportd` has mode `0644`. No execute bit is set.
When systemd calls `execve()` on that path, the kernel returns `EACCES`, and
systemd translates that into exit code `203/EXEC`.

---

## Step 5 — Fix

Minimal fix — add the execute bit:

```bash
sudo chmod 0755 /opt/reportd/reportd
sudo systemctl restart reportd
```

Why `0755`? Owner gets read/write/execute (`7`), group and others get read/execute
(`5`). This matches the least-privilege convention for a system daemon binary.

---

## Step 6 — Verify

```bash
systemctl is-active reportd
```

Output: `active`

```bash
journalctl -u reportd -n 5 --no-pager
```

Output:
```
Oct 22 16:04:35 cliff reportd[10270]: report generated 2026-10-22T16:04:35+00:00
Oct 22 16:05:05 cliff reportd[10270]: report generated 2026-10-22T16:05:05+00:00
Oct 22 17:00:00 cliff reportd[10270]: report generated 2026-10-22T17:00:00+00:00
Oct 22 17:21:59 cliff reportd[10270]: report generated 2026-10-22T17:21:59+00:00
Oct 22 17:22:29 cliff reportd[10270]: report generated 2026-10-22T17:22:29+00:00
```

The daemon is running and generating reports every 30 seconds. Fixed.

---

## Step 7 — Prevent

Two quick checks that would catch this before it becomes a production incident:

```bash
# Fails immediately if the binary is not executable
test -x /opt/reportd/reportd

# Validates the unit file syntax before enabling
sudo systemd-analyze verify /etc/systemd/system/reportd.service
```

Add both to a deployment pipeline or CI check.

---

## Step 8 — Reset

```bash
sudo bash reset.sh
```

Output: `Lab reset.`

Confirmed clean:
```bash
systemctl status reportd
# → Unit reportd.service could not be found.

ls /opt/reportd
# → ls: cannot access '/opt/reportd': No such file or directory
```

---

## Key commands learned

| Command | Purpose |
|---|---|
| `systemctl status <unit>` | Show current state and last exit code |
| `systemctl cat <unit>` | Print the unit file as systemd loaded it |
| `journalctl -u <unit> -b` | All logs for the unit since last boot |
| `journalctl -u <unit> -xe` | Logs with context and explanations |
| `systemctl daemon-reload` | Re-read unit files after editing |
| `systemctl reset-failed` | Clear the failed state after fixing |
| `man systemd.exec` | Reference for exit codes including 203/EXEC |

---

## Related

- KB article: [KB-0001-systemd-203-exec.md](../../../kb/KB-0001-systemd-203-exec.md)
- Support case: [0001-reportd-down-after-reboot.md](../../../support-cases/0001-reportd-down-after-reboot.md)
