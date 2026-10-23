# Lab 03 completion checklist

## Environment

- [ ] Ubuntu `lab` VM is running
- [ ] You are logged in as a non-root user with `sudo` access

## Reproduce the failure

- [ ] Ran `sudo bash scripts/break.sh` and saw "Lab broken." message
- [ ] Ran `sudo apt update` and observed the lock / unconfigured-package error
- [ ] Ran `sudo apt install curl` and confirmed it also fails

## Diagnose

- [ ] Ran `ps aux | grep -E 'apt|dpkg'` and confirmed no real process holds the lock
- [ ] Ran `sudo lsof /var/lib/dpkg/lock-frontend` and confirmed stale (no output)
- [ ] Ran `sudo lsof /var/lib/dpkg/lock` and confirmed stale (no output)
- [ ] Ran `dpkg -l | grep -E '^.H|^.U|^.F'` and identified the half-configured package
- [ ] Ran `sudo dpkg --audit` and read what it recommends
- [ ] Can explain the difference between a stale lock and a genuine lock

## Fix and verify

- [ ] Removed the three stale lock files with `rm -f`
- [ ] Ran `sudo dpkg --configure -a` and watched it complete the postinst
- [ ] Ran `sudo apt-get install -f` to resolve any remaining broken dependencies
- [ ] Confirmed `sudo apt update` succeeds
- [ ] Confirmed `dpkg -l | grep -E '^.H|^.U|^.F'` returns nothing

## Bonus: held packages

- [ ] Used `sudo apt-mark hold <package>` to hold a package
- [ ] Confirmed `apt-mark showhold` lists it
- [ ] Ran `sudo apt upgrade` and noted it was skipped
- [ ] Released it with `sudo apt-mark unhold <package>`
- [ ] Ran `apt-cache policy <package>` and can read the priority output

## Document

- [ ] `notes.md` is filled with actual commands and output
- [ ] KB article exists at `kb/KB-0003-broken-dpkg-state.md`
- [ ] Support case exists at `support-cases/0003-apt-broken-after-interruption.md`

## Cleanup

- [ ] Ran `sudo bash scripts/reset.sh` and saw "Lab reset."
- [ ] Confirmed `sudo apt update` runs cleanly after reset
- [ ] Confirmed `dpkg -l sl` shows the package is removed

## Definition of done

All boxes ticked **and** you can explain why `dpkg --configure -a` is safe to run
and what it does differently from reinstalling the package.
