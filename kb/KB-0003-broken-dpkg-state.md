# KB-0003: apt / dpkg broken after interrupted upgrade

**Applies to:** Ubuntu 20.04, 22.04, 24.04
**Component:** apt, dpkg
**Last reviewed:** 2026-10-23

## Symptom

Running any `apt` or `dpkg` command fails with one or both of:

```
E: Could not get lock /var/lib/dpkg/lock-frontend. It is held by process <PID>
E: dpkg was interrupted, you must manually run
   'sudo dpkg --configure -a' to correct the problem.
```

## Cause

Two separate problems often occur together after an interrupted upgrade:

1. **Stale lock files.** `apt` and `dpkg` create lock files under
   `/var/lib/dpkg/` and `/var/cache/apt/` while running. If the process is
   killed or the terminal closes unexpectedly, the lock files are not removed.
   The next `apt` invocation sees the lock and refuses to run.

2. **Half-configured package.** If `dpkg` is killed while running a package's
   `postinst` script, it records the package as `half-configured` or
   `half-installed` in `/var/lib/dpkg/status`. Any subsequent `apt` run
   detects this and stops until the configuration is completed.

## Diagnosis

### Confirm no real process holds the lock

```bash
ps aux | grep -E 'apt|dpkg'
sudo lsof /var/lib/dpkg/lock-frontend
sudo lsof /var/lib/dpkg/lock
```

No output from `lsof` means the lock is stale. If a real PID is returned, wait
for that process to finish before proceeding.

### Find packages in an inconsistent state

```bash
dpkg -l | grep -E '^.H|^.U|^.F'
sudo dpkg --audit
```

`dpkg --audit` lists affected packages and recommends the corrective command.

## Resolution

**Only proceed after confirming no real apt/dpkg process is running.**

### 1. Remove stale lock files

```bash
sudo rm -f /var/lib/dpkg/lock-frontend
sudo rm -f /var/lib/dpkg/lock
sudo rm -f /var/cache/apt/archives/lock
```

### 2. Finish interrupted configuration

```bash
sudo dpkg --configure -a
```

This re-runs the `postinst` script for every package in an inconsistent state.

### 3. Fix any broken dependencies

```bash
sudo apt-get install -f
```

### 4. Verify

```bash
sudo apt update
dpkg -l | grep -E '^.H|^.U|^.F'   # should return nothing
```

## Related issue: held packages silently skipped by apt upgrade

If `apt upgrade` appears to do nothing, or skips a package without error:

```bash
apt-mark showhold          # list held packages
apt-cache policy <pkg>     # show version priorities
```

Release a hold with `sudo apt-mark unhold <package>`.

## Prevention

- Use `tmux` or `screen` for long-running upgrades so a dropped terminal does
  not interrupt `dpkg`.
- Prefer `Ctrl-C` over closing the terminal — it gives `dpkg` a chance to
  complete the current step.
- Always run `sudo dpkg --configure -a` after any unexpected interruption before
  the next `apt` command.

## Additional information

- `man dpkg`
- `man apt-get`
- `/var/lib/dpkg/status` — package state database
- Lab: [labs/01-linux/03-broken-apt-dpkg](../labs/01-linux/03-broken-apt-dpkg)
