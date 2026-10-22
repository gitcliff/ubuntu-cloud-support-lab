# Lab 01 completion checklist

Use this list to confirm you have worked through every step of the lab yourself.
A lab is only done when you can tick every box **from memory**, not by reading the fix.

## Environment

- [ ] Multipass `lab` VM is running (`multipass list`)
- [ ] Repo is mounted at `/home/ubuntu/lab` inside the VM
- [ ] You are logged in as a non-root user with `sudo` access

## Reproduce the failure

- [ ] Ran `sudo bash break.sh` and saw "Lab broken." message
- [ ] Confirmed the service is failing with `sudo systemctl status reportd`
- [ ] Noted the exact exit code shown in the `Active:` line

## Diagnose

- [ ] Read the full unit file with `systemctl cat reportd`
- [ ] Identified the `ExecStart=` path: `/opt/reportd/reportd`
- [ ] Checked the file exists: `ls -l /opt/reportd/reportd`
- [ ] Confirmed the file permission is `0644` (no execute bit)
- [ ] Looked up what exit code `203/EXEC` means (`man systemd.exec`)
- [ ] Checked the journal for extra context: `journalctl -u reportd -b --no-pager`

## Root cause

- [ ] Can state the root cause in one sentence without looking at the README

## Fix and verify

- [ ] Applied the minimal fix: `sudo chmod 0755 /opt/reportd/reportd`
- [ ] Restarted the service: `sudo systemctl restart reportd`
- [ ] Confirmed active status: `systemctl is-active reportd` → `active`
- [ ] Confirmed journal output: `journalctl -u reportd -n 5 --no-pager`

## Document

- [ ] `notes.md` is filled in with your actual commands and output
- [ ] KB article exists at `kb/KB-0001-systemd-203-exec.md`
- [ ] Support case exists at `support-cases/0001-reportd-down-after-reboot.md`

## Cleanup

- [ ] Ran `sudo bash reset.sh` and saw "Lab reset." message
- [ ] Confirmed service is gone: `systemctl status reportd` → `Unit reportd.service could not be found`
- [ ] Confirmed files removed: `ls /opt/reportd` → No such file or directory

## Definition of done

All boxes above are ticked **and** you can explain the investigation to someone
else without referring to any notes.
