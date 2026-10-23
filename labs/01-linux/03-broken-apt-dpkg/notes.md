# Lab 03 working notes — Broken apt / dpkg state

**Date:** <!-- fill in when you run the lab -->
**Environment:** Ubuntu 24.04 LTS

Fill in each section as you work through the lab. Paste actual command output —
do not summarise or paraphrase it.

---

## Step 1 — Reproduce the failure

```bash
sudo bash scripts/break.sh
```

Output:
```
liff@cliff:~$ sudo bash break3.sh 
Reading package lists... Done
Building dependency tree... Done
Reading state information... Done
sl is already the newest version (5.02-1).
0 upgraded, 0 newly installed, 0 to remove and 151 not upgraded.
Lab broken.
  sl has a failing postinst and is stuck in 'half-configured' state.
  dpkg lock files are held by background processes.

  Start investigating with:
    sudo apt install curl

```

---

## Step 2 — Observe symptoms

```bash
sudo apt install curl
```
```
cliff@cliff:~$ sudo apt install curl
Reading package lists... Done
Building dependency tree... Done
Reading state information... Done
The following NEW packages will be installed:
  curl
0 upgraded, 1 newly installed, 0 to remove and 151 not upgraded.
1 not fully installed or removed.
Need to get 222 kB of archives.
After this operation, 569 kB of additional disk space will be used.
Get:1 http://ports.ubuntu.com/ubuntu-ports noble-updates/main arm64 curl arm64 8.5.0-2ubuntu10.16 [222 kB]
Fetched 222 kB in 2s (117 kB/s)                    
Selecting previously unselected package curl.
(Reading database ... 278836 files and directories currently installed.)
Preparing to unpack .../curl_8.5.0-2ubuntu10.16_arm64.deb ...
Unpacking curl (8.5.0-2ubuntu10.16) ...
Setting up sl (5.02-1) ...
postinst: error: required config directory /etc/sl is missing
dpkg: error processing package sl (--configure):
 installed sl package post-installation script subprocess returned error exit status 1
Setting up curl (8.5.0-2ubuntu10.16) ...
Processing triggers for man-db (2.12.0-4build2) ...
Errors were encountered while processing:
 sl
needrestart is being skipped since dpkg has failed
E: Sub-process /usr/bin/dpkg returned an error code (1)

```

Observations:
- Error mentioning lock file? No — the lock processes had not yet survived script
  exit at the time of this run (old break.sh without setsid). After re-running
  break.sh with setsid, `ps aux` confirms the lock processes are now alive.
- Error mentioning unconfigured package? Yes — "1 not fully installed or removed."
- Key error lines:
  - `postinst: error: required config directory /etc/sl is missing`
  - `dpkg: error processing package sl (--configure): installed sl package post-installation script subprocess returned error exit status 1`
  - `E: Sub-process /usr/bin/dpkg returned an error code (1)`

Notable: curl WAS installed successfully despite the sl failure. dpkg processed
packages in order — sl failed, curl succeeded, but the overall exit code is 1.
This shows a broken postinst blocks `dpkg --configure -a` but doesn't always
prevent other packages from being set up in the same run.

---

## Step 3 — Diagnose

### Check for a running apt/dpkg process

```bash
ps aux | grep -E 'apt|dpkg'
```
```
liff@cliff:~$ ps aux | grep -E 'apt|dpkg'
root       60349  0.0  0.0   7048  3116 ?        Ss   12:22   0:00 bash -c ( flock -x 9; sleep 3600 ) 9>/var/lib/dpkg/lock-frontend
root       60350  0.0  0.0   7048  3112 ?        Ss   12:22   0:00 bash -c ( flock -x 9; sleep 3600 ) 9>/var/lib/dpkg/lock
root       60352  0.0  0.0   7048  1780 ?        S    12:22   0:00 bash -c ( flock -x 9; sleep 3600 ) 9>/var/lib/dpkg/lock-frontend
root       60353  0.0  0.0   7048  1780 ?        S    12:22   0:00 bash -c ( flock -x 9; sleep 3600 ) 9>/var/lib/dpkg/lock
cliff      60799  0.0  0.0   6140  2092 pts/1    S+   12:30   0:00 grep --color=auto -E apt|dpkg
cliff@cliff:~$ 

```

Real process found? Yes — 4 bash processes holding dpkg locks (PIDs 60349, 60350,
60352, 60353), all running as root with `?` in the TTY column (no controlling
terminal — setsid detached them from the shell). These are the flock-holding
background processes from break.sh. They are NOT a real apt/dpkg operation.

### Check who holds the lock files

```bash
sudo lsof /var/lib/dpkg/lock-frontend
```
```
COMMAND   PID USER   FD   TYPE DEVICE SIZE/OFF   NODE NAME
sleep   59839 root    9w   REG  252,0        0 524650 /var/lib/dpkg/lock-frontend
bash    60352 root    9w   REG  252,0        0 524650 /var/lib/dpkg/lock-frontend
flock   60354 root    9w   REG  252,0        0 524650 /var/lib/dpkg/lock-frontend
```

```bash
sudo lsof /var/lib/dpkg/lock
```
```
cliff@cliff:~$ sudo lsof /var/lib/dpkg/lock
lsof: WARNING: can't stat() fuse.gvfsd-fuse file system /run/user/1000/gvfs
      Output information may be incomplete.
lsof: WARNING: can't stat() fuse.portal file system /run/user/1000/doc
      Output information may be incomplete.
COMMAND   PID USER   FD   TYPE DEVICE SIZE/OFF   NODE NAME
sleep   59840 root    9w   REG  252,0        0 524649 /var/lib/dpkg/lock
bash    60353 root    9w   REG  252,0        0 524649 /var/lib/dpkg/lock
flock   60355 root    9w   REG  252,0        0 524649 /var/lib/dpkg/lock

```

Conclusion: genuine lock — three processes (sleep, bash, flock) hold fd 9 open
on lock-frontend. However, none of them are a real apt or dpkg operation. In a
real incident you would check the COMMAND column: if it shows `apt`, `apt-get`,
or `dpkg`, wait for it; if it shows anything else (or nothing), the lock is stale
and safe to remove.

### Find unconfigured packages

```bash
dpkg -l | grep -E '^.H|^.U|^.F'
```
```
cliff@cliff:~$ dpkg -l | grep -E '^.H|^.U|^.F'
iF  sl                                               5.02-1                                    arm64        Correct you if you type `sl' by mistake
cliff@cliff:~$ 

```

Package(s) in bad state: `sl` — state code `iF`:
- First letter `i` = desired state: **i**nstall
- Second letter `F` = current state: half-configured (**F**ailed to configure)
dpkg tried to run sl's postinst, it failed, and the package is stuck.

### dpkg audit

```bash
sudo dpkg --audit
```
```
liff@cliff:~$ sudo dpkg --audit
The following packages are only half configured, probably due to problems
configuring them the first time.  The configuration should be retried using
dpkg --configure <package> or the configure menu option in dselect:
 sl                   Correct you if you type `sl' by mistake

```

dpkg recommends: `dpkg --configure <package>` or the configure menu in dselect.
It identifies sl as the only package in an inconsistent state. This confirms
the scope — only sl is broken, no other packages are affected.

### Examine the failing postinst

```bash
cat /var/lib/dpkg/info/sl.postinst
```
```
#!/bin/bash
# Simulated broken postinst — do not edit
echo "postinst: error: required config directory /etc/sl is missing" >&2
exit 1
```

What does the script do? It unconditionally prints an error to stderr and exits
with code 1. dpkg interprets any non-zero postinst exit as a configuration
failure and marks the package `half-configured`. Every future apt/dpkg run
re-tries the postinst — and fails again — until the script is fixed.

### My hypothesis

Two problems block apt:

1. **Genuine but non-apt lock**: `/var/lib/dpkg/lock-frontend` and
   `/var/lib/dpkg/lock` are held by stray background processes (bash/flock/sleep,
   PIDs 60349–60354). They are not a real apt/dpkg operation, so it is safe to
   kill them and remove the lock files.

2. **Failing postinst**: sl is `half-configured`. Its postinst unconditionally
   exits 1, so every configure attempt fails. Removing the locks alone will not
   fix the problem — dpkg will immediately hit the postinst error next.

Fix order:
1. Kill lock processes and remove lock files.
2. Run `dpkg --configure -a` → observe the postinst error.
3. Restore the original postinst from the backup left by break.sh.
4. Run `dpkg --configure -a` again → should succeed.

---

## Step 4 — Root cause

sl's postinst at `/var/lib/dpkg/info/sl.postinst` was replaced with a script that
always exits 1. sl is recorded as `half-configured` in `/var/lib/dpkg/status`,
so dpkg re-runs the postinst on every package operation — and fails every time.

The error message `postinst: error: required config directory /etc/sl is missing`
comes directly from the broken postinst. In a real incident this kind of error
means the postinst has a hard dependency (a directory, a user account, a service)
that wasn't created or that was removed after installation.

Additional finding: sl does not ship a postinst in its package. break.sh's backup
step (`cp sl.postinst sl.postinst.orig`) silently failed because sl.postinst did
not exist before break.sh created the broken one. Therefore the correct fix is to
**delete** the injected postinst file rather than restore a backup:
`sudo rm /var/lib/dpkg/info/sl.postinst`

The lock processes ARE alive (confirmed by ps and lsof), but the Step 2 apt run
pre-dated the working setsid flock, so no lock error appeared in that output.

---

## Step 5 — Fix

```bash
sudo rm -f /var/lib/dpkg/lock-frontend
sudo rm -f /var/lib/dpkg/lock
sudo rm -f /var/cache/apt/archives/lock
```

First configure attempt (will fail — observe the postinst error):
```bash
sudo dpkg --configure -a
```
```
cliff@cliff:~$ sudo dpkg --configure -a
Setting up sl (5.02-1) ...
postinst: error: required config directory /etc/sl is missing
dpkg: error processing package sl (--configure):
 installed sl package post-installation script subprocess returned error exit status 1
Errors were encountered while processing:
 sl

```

Attempted backup restore — FAILED:
```bash
sudo cp /var/lib/dpkg/info/sl.postinst.orig /var/lib/dpkg/info/sl.postinst
sudo dpkg --configure -a
```
```
cp: cannot stat '/var/lib/dpkg/info/sl.postinst.orig': No such file or directory
Setting up sl (5.02-1) ...
postinst: error: required config directory /etc/sl is missing
dpkg: error processing package sl (--configure):
 installed sl package post-installation script subprocess returned error exit status 1
```

Root of this failure: sl has NO postinst in its real Debian package. The
`cp -a ... .orig` in break.sh silently failed (suppressed by `|| true`) because
the source file did not exist before break.sh wrote the broken one. There is no
original to restore from.

Correct fix — remove the injected postinst entirely:
```bash
sudo rm /var/lib/dpkg/info/sl.postinst
sudo dpkg --configure -a
```

```bash
sudo apt-get install -f
```
```
cliff@cliff:~$ sudo apt-get install -f
Reading package lists... Done
Building dependency tree... Done
Reading state information... Done
0 upgraded, 0 newly installed, 0 to remove and 151 not upgraded.
1 not fully installed or removed.
After this operation, 0 B of additional disk space will be used.
Setting up sl (5.02-1) ...
postinst: error: required config directory /etc/sl is missing
dpkg: error processing package sl (--configure):
 installed sl package post-installation script subprocess returned error exit status 1
Errors were encountered while processing:
 sl
needrestart is being skipped since dpkg has failed
E: Sub-process /usr/bin/dpkg returned an error code (1)

```

---

## Step 6 — Verify

```bash
sudo apt update
```
```
cliff@cliff:~$ sudo apt update
Hit:1 http://ports.ubuntu.com/ubuntu-ports noble InRelease
Hit:2 http://ports.ubuntu.com/ubuntu-ports noble-updates InRelease
Hit:3 http://ports.ubuntu.com/ubuntu-ports noble-backports InRelease
Get:4 http://ports.ubuntu.com/ubuntu-ports noble-security InRelease [126 kB]
Get:5 http://ports.ubuntu.com/ubuntu-ports noble-security/main arm64 Packages [1,206 kB]
Get:6 http://ports.ubuntu.com/ubuntu-ports noble-security/universe arm64 Packages [1,298 kB]
Fetched 2,629 kB in 3s (782 kB/s)   
Reading package lists... Done
Building dependency tree... Done
Reading state information... Done
151 packages can be upgraded. Run 'apt list --upgradable' to see them.

```

```bash
dpkg -l | grep -E '^.H|^.U|^.F'
```
```
liff@cliff:~$ dpkg -l | grep -E '^.H|^.U|^.F'
iF  sl                                               5.02-1                                    arm64        Correct you if you type `sl' by mistake
cliff@cliff:~$ 

```

---



Notes on what the priority numbers mean:

`apt-cache policy` shows a priority number next to each version source. apt picks
the version with the highest priority when deciding what to install or upgrade to.

| Priority | Meaning |
|---|---|
| < 0 | Never install this version, even if requested explicitly |
| 0–99 | Only install if no other version is available |
| 100 | Default for packages already installed (`/var/lib/dpkg/status`) |
| 500 | Default for packages in a configured repository |
| 990 | Default when `-t <release>` (target release) is specified |
| > 1000 | Install even if it would mean a downgrade |

When you run `apt-mark hold <package>`, apt does NOT change the priority number.
Instead it sets the package's **desired state** in dpkg to `hold`. apt checks
that flag and skips the package during `upgrade` or `dist-upgrade`, regardless
of what the priority says. `apt-cache policy` will still show the candidate
version — the hold is what prevents it from being acted on.

Paste the actual `apt-cache policy sl` output above and compare the Installed
and Candidate lines — if they differ, that version gap is what a hold is
preventing from being applied.

---

## Step 8 — Reset

```bash
sudo bash scripts/reset.sh
```
```
liff@cliff:~$ sudo bash reset1.sh 
[sudo] password for cliff: 
Reading package lists... Done
Building dependency tree... Done
Reading state information... Done
The following packages will be REMOVED:
  sl
0 upgraded, 0 newly installed, 1 to remove and 151 not upgraded.
After this operation, 56.3 kB disk space will be freed.
(Reading database ... 278843 files and directories currently installed.)
Removing sl (5.02-1) ...
Processing triggers for man-db (2.12.0-4build2) ...

Running kernel seems to be up-to-date.

No services need to be restarted.

No containers need to be restarted.

User sessions running outdated binaries:
 cliff @ user manager service: gnome-session-b[1813], systemd[1661]

No VM guests are running outdated hypervisor (qemu) binaries on this host.
Reading package lists... Done
Building dependency tree... Done
Reading state information... Done
0 upgraded, 0 newly installed, 0 to remove and 151 not upgraded.
Lab reset.

```

Confirmed clean:
- Reset output shows `Removing sl (5.02-1)` and `Lab reset.` — sl removed cleanly
- `sudo apt update` → paste output here
- `dpkg -l sl` → paste output here (expect "no packages found" or "dpkg-query: no packages found")

---

## Key commands learned

| Command | Purpose |
|---|---|
| `sudo dpkg --configure -a` | Finish configuring all packages left in an interrupted state |
| `sudo apt-get install -f` | Fix broken dependencies after a partial install |
| `sudo dpkg --audit` | List all packages in an inconsistent state |
| `dpkg -l \| grep '^.H'` | Find half-configured packages |
| `sudo lsof /var/lib/dpkg/lock` | Check whether the dpkg lock is held by a real process |
| `apt-mark hold/unhold` | Pin a package version so upgrades skip it |
| `apt-mark showhold` | List all currently held packages |
| `apt-cache policy <pkg>` | Show candidate version, installed version, and pin priorities |

---

## Related

- KB article: [KB-0003-broken-dpkg-state.md](../../../kb/KB-0003-broken-dpkg-state.md)
- Support case: [0003-apt-broken-after-interruption.md](../../../support-cases/0003-apt-broken-after-interruption.md)