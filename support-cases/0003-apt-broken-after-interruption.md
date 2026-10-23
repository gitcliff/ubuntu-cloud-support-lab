# Case 0003: apt broken — can't install or update anything

| Field    | Value                                           |
|----------|-------------------------------------------------|
| Severity | 2 (degraded: system cannot receive security updates) |
| Product  | Ubuntu 24.04 LTS                                |
| Opened   | 2026-10-23 08:55 UTC                            |
| SLA first response | 2 h                                   |

## Customer's message

> Hi, I was running `apt upgrade` last night and my terminal disconnected halfway
> through. Now every time I try to run `apt` or `dpkg` I get errors about lock
> files and unconfigured packages. I can't install anything and I'm worried about
> missing security patches.
> — Jordan, Infrastructure team

## Internal notes

- Dropped terminal mid-upgrade → classic stale lock + half-configured package.
- Need: output of `sudo apt update`, `ps aux | grep apt`, `sudo lsof /var/lib/dpkg/lock`,
  `dpkg -l | grep '^.H'`, `sudo dpkg --audit`.
- Reproduced in lab 01-linux/03: break.sh leaves sl in half-configured state + stale locks.
- Fix order matters: remove locks first, then `dpkg --configure -a`, then `apt-get install -f`.

## First response (sent)

> Hi Jordan,
>
> This is a known situation when an apt/dpkg session is interrupted — it leaves
> stale lock files and an unconfigured package that blocks all future apt runs.
> It's recoverable without reinstalling anything.
>
> Before we make any changes, I need to confirm no apt process is still running
> in the background. Please run the following and share the output:
>
> ```bash
> ps aux | grep -E 'apt|dpkg'
> sudo lsof /var/lib/dpkg/lock-frontend
> sudo lsof /var/lib/dpkg/lock
> sudo dpkg --audit
> ```
>
> I'll reply within 30 minutes of receiving the output.

## Resolution response (sent)

> Hi Jordan,
>
> Thanks — confirmed no live process holds the locks. Here are the steps to fix
> it, in order:
>
> **Step 1 — Remove the stale lock files:**
> ```bash
> sudo rm -f /var/lib/dpkg/lock-frontend
> sudo rm -f /var/lib/dpkg/lock
> sudo rm -f /var/cache/apt/archives/lock
> ```
>
> **Step 2 — Finish the interrupted configuration:**
> ```bash
> sudo dpkg --configure -a
> ```
> This re-runs the setup script for the package that was left half-configured.
> You should see it complete without errors.
>
> **Step 3 — Fix any broken dependencies:**
> ```bash
> sudo apt-get install -f
> ```
>
> **Step 4 — Verify everything is clean:**
> ```bash
> sudo apt update
> dpkg -l | grep -E '^.H|^.U|^.F'   # should return nothing
> ```
>
> To avoid this in future: run long apt operations inside `tmux` or `screen`.
> If your terminal drops, you can reattach to the session and the upgrade
> continues unaffected.
>
> More detail in KB-0003. I'll keep this open until you confirm apt is working.

## Lessons learned

- Always ask for `lsof` on the lock files before telling the customer to remove
  them — if a real process holds the lock, removing it would corrupt the database.
- The fix order matters: locks first, then `--configure -a`, then `install -f`.
  Doing them out of order can cause additional errors.
- `tmux`/`screen` advice is worth giving every time this case appears — it
  prevents the recurrence entirely.
