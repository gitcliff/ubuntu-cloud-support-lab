# Lab 02 completion checklist

## Environment

- [ ] Multipass `lab` VM is running
- [ ] You are logged in as a non-root user with `sudo` access

## Reproduce the failure

- [ ] Ran `sudo bash scripts/break.sh` and saw "Lab broken." message
- [ ] Ran `ls /opt/loggen/` and confirmed `app.log` is not listed
- [ ] Ran `du -sh /opt/loggen/` and noted the reported size
- [ ] Ran `df -h .` and noted the reported usage

## Diagnose

- [ ] Observed the gap between `du` and `df` output
- [ ] Ran `sudo lsof +L1` and found the loggen entry showing `(deleted)`
- [ ] Noted the PID and file descriptor number from `lsof` output
- [ ] Inspected `/proc/<pid>/fd/` and confirmed the deleted symlink
- [ ] Can explain in one sentence why `rm` did not free the blocks

## Fix and verify

- [ ] Restarted the service to release the file descriptor
- [ ] Confirmed `lsof +L1 | grep loggen` returns nothing
- [ ] Confirmed a new `app.log` was created by the restarted service
- [ ] Confirmed `df -h` shows lower usage after the fix

## Bonus

- [ ] Ran `df -i` and can explain the difference between block exhaustion and inode exhaustion
- [ ] Can describe the live truncation fix (`truncate -s 0 /proc/<pid>/fd/<n>`) and when to use it instead of a restart

## Document

- [ ] `notes.md` is filled with your actual commands and output
- [ ] KB article exists at `kb/KB-0002-disk-full-deleted-open-files.md`
- [ ] Support case exists at `support-cases/0002-disk-full-after-deleting-logs.md`

## Cleanup

- [ ] Ran `sudo bash scripts/reset.sh` and saw "Lab reset."
- [ ] Confirmed `systemctl status loggen` → `Unit loggen.service could not be found`
- [ ] Confirmed `/opt/loggen` is removed

## Definition of done

All boxes ticked **and** you can explain the `lsof +L1` technique from memory.
