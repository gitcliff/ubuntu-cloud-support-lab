# Lab 03: Broken apt / dpkg state

|             |                    |
| ----------- | ------------------ |
| Domain      | linux              |
| Difficulty  | ★★☆                |
| Time        | ~40 min            |
| Environment | Multipass `lab` VM |

## Scenario

> "I was running `apt upgrade` last night and the terminal closed mid-way.
> Now every time I run `apt` I get errors about locks and unconfigured packages.
> Nothing installs and I can't update the system."

## Learning objectives

- Understand how dpkg and apt use lock files and why stale locks occur
- Distinguish a genuine lock (process running) from a stale lock (process dead)
- Use `dpkg --configure -a` to retry failed package configuration
- Read a `postinst` script and understand why it can block an entire apt run
- Read and interpret `/var/lib/dpkg/status` entries
- Understand held packages and apt pinning as a related concept

## Break

```bash
sudo bash scripts/break.sh
```

Do not read `break.sh` before you attempt the lab.

## Symptoms

Run the following after breaking the lab and record what you see:

```bash
sudo apt install curl
```

(`apt update` only fetches package lists and will succeed even with a broken dpkg
state — `apt install` or `apt upgrade` is what triggers the errors.)

You will see two errors layered on top of each other:

```
E: Could not get lock /var/lib/dpkg/lock-frontend. It is held by process <PID>
```

After the lock is cleared (see Diagnose), a second error surfaces:

```
Sub-process /usr/bin/dpkg returned an error code (1)
```

This is because sl's `postinst` script is broken and fails every time dpkg
tries to finish configuring it.

> Paste your actual output here when you run the lab.

## Diagnose

### Why does this happen?

`apt` and `dpkg` use lock files under `/var/lib/dpkg/` and `/var/cache/apt/` to
prevent two processes modifying the package database simultaneously. When an
`apt` or `dpkg` process is killed, crashes, or the terminal is closed, those lock
files are left behind. The next `apt` invocation sees the lock and refuses to run,
even though no process is actually holding it.

Separately, if `dpkg` is killed while running a package's `postinst` script, it
records the package as `half-configured` or `half-installed` in
`/var/lib/dpkg/status`. Any subsequent `apt` run detects this and refuses to
proceed until the interrupted configuration is finished.

### Step 1 — Check for a running apt or dpkg process

Before removing any lock, confirm no real process holds it:

```bash
ps aux | grep -E 'apt|dpkg'
```

If you see an actual `apt` or `dpkg` process, wait for it or kill it intentionally.
If the list is empty (other than the `grep` itself), the locks are stale.

### Step 2 — Identify stale lock files

```bash
sudo lsof /var/lib/dpkg/lock-frontend 2>/dev/null || echo "no process holds the lock"
sudo lsof /var/lib/dpkg/lock          2>/dev/null || echo "no process holds the lock"
```

`lsof` returns the process holding a file open. No output means the lock is stale.

### Step 3 — Check for unconfigured packages

```bash
dpkg -l | grep -E '^.H|^.U|^.F'
```

The first two characters of each row in `dpkg -l` show the desired/current state:
- `iH` — installed, half-configured
- `iU` — installed, unpacked (postinst not yet run)
- `iF` — installed, half-installed (files not fully extracted)

Alternatively, check the status file directly:

```bash
grep -A5 "half-configured\|half-installed" /var/lib/dpkg/status
```

### Step 4 — Check what dpkg reports

```bash
sudo dpkg --audit
```

`dpkg --audit` lists all packages in an inconsistent state and suggests the
corrective action.

### Step 5 — Read the postinst script

Once locks are cleared and you run `dpkg --configure -a`, it will fail and show
which package's postinst errored. Read that script:

```bash
cat /var/lib/dpkg/info/<package>.postinst
```

The script's exit code, the error message it prints, and the line it fails on
are the root cause of this second layer of the problem.

> Paste your actual diagnostic output here.

## Root cause

Two problems were introduced:

1. **Stale locks** — background processes hold `flock(2)` exclusive locks on
   `/var/lib/dpkg/lock-frontend` and `/var/lib/dpkg/lock`, blocking any new
   `apt` invocation.

2. **Failing postinst** — sl's `/var/lib/dpkg/info/sl.postinst` was replaced
   with a script that always exits 1. `sl` is marked `half-configured` in
   `/var/lib/dpkg/status`, so dpkg re-runs postinst on every `apt` call —
   and fails every time, preventing any package operation from completing.

## Fix

### 1. Remove stale locks (only after confirming no real process holds them)

```bash
sudo rm -f /var/lib/dpkg/lock-frontend
sudo rm -f /var/lib/dpkg/lock
sudo rm -f /var/cache/apt/archives/lock
```

### 2. Attempt configuration — observe the postinst failure

```bash
sudo dpkg --configure -a
```

This will fail immediately with the postinst error. Read the error message — it
tells you which package failed and why.

### 3. Investigate the postinst

```bash
cat /var/lib/dpkg/info/sl.postinst
```

You will see a script that always exits 1. In a real incident this might be a
missing config file, a failed service start, or a misconfigured dependency.

### 4. Fix the postinst

`sl` ships **no postinst** in its real package — break.sh injected one. The fix
is to remove the injected file:

```bash
sudo rm /var/lib/dpkg/info/sl.postinst
```

In production, where you cannot simply delete the script, you would identify and
fix the underlying cause first (create the missing directory, fix the config, etc.)
then re-run configure. If the package truly cannot be configured, force-remove it:

```bash
sudo dpkg --remove --force-remove-reinstreq sl
```

### 5. Retry configuration

```bash
sudo dpkg --configure -a
```

### 6. Clean up any remaining broken dependencies

```bash
sudo apt-get install -f
```

## Verify

```bash
sudo apt update
sudo apt install curl
dpkg -l | grep -E '^.H|^.U|^.F'   # should return nothing
```

> Paste your post-fix output here.

## Bonus: held packages and apt pinning

A related scenario: a package is **held** so `apt upgrade` skips it silently.

```bash
# Put a package on hold
sudo apt-mark hold <package>

# List held packages
apt-mark showhold

# Release the hold
sudo apt-mark unhold <package>
```

Apt **pinning** (via `/etc/apt/preferences`) assigns priorities to packages or
repositories, controlling which version apt will select. A misconfigured pin can
cause `apt upgrade` to appear to do nothing, or to downgrade packages
unexpectedly.

```bash
# Show effective priorities for a package
apt-cache policy <package>

# Show all pin rules in effect
apt-cache policy
```

## Prevent

- Never kill an active `apt` or `dpkg` process. Use a persistent terminal
  (`tmux`, `screen`, or a systemd service unit) for long-running upgrades.
- If an upgrade must be interrupted, prefer `Ctrl-C` over killing the terminal,
  which gives dpkg a chance to complete the current step cleanly.
- After any unexpected interruption, always run `sudo dpkg --configure -a` before
  the next `apt` invocation.
- Use `unattended-upgrades` with proper logging so background updates are visible
  and interruptible.

## References

- `man dpkg`
- `man apt-get`
- `man apt-mark`
- `man apt_preferences` (pinning)
- `/var/lib/dpkg/status` — the package state database
- Lab: this file

## Reset

```bash
sudo bash scripts/reset.sh
```
