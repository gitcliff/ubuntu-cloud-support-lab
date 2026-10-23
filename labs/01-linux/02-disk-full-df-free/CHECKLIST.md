# Lab 02 completion checklist

## Environment

- [x] Ubuntu `lab` VM is running
- [x] You are logged in as a non-root user with `sudo` access

## Reproduce the failure

- [x] Ran `sudo bash scripts/break.sh` and saw "Lab broken." message
- [x] Ran `ls /opt/loggen/` and confirmed `app.log` is not listed
- [x] Ran `du -sh /opt/loggen/` and noted the reported size
- [x] Ran `df -h .` and noted the reported usage

## Diagnose

- [x] Observed the gap between `du` and `df` output
- [x] Ran `sudo lsof +L1` and found the loggen entry showing `(deleted)`
- [x] Noted the PID (19583) and file descriptor number (3) from `lsof` output
- [x] Inspected `/proc/19583/fd/` and confirmed fd 3 → `/opt/loggen/app.log (deleted)`
- [x] Can explain in one sentence why `rm` did not free the blocks

## Fix and verify

- [x] Restarted the service to release the file descriptor
- [x] Confirmed `lsof +L1 | grep loggen` returns nothing
- [x] Confirmed a new `app.log` (21K) was created by the restarted service
- [x] Confirmed `df -h` after fix — usage unchanged at 93% because the deleted file
      was only ~95 KB on a 16 GB volume; the mechanism is correct, scale was small

## Bonus

- [x] Ran `df -i` — IUse% 33%, 685,273 inodes free; no exhaustion; wrote explanation
- [ ] Can describe the live truncation fix (`truncate -s 0 /proc/<pid>/fd/<n>`) and when to use it instead of a restart

## Document

- [x] `notes.md` filled with actual commands and output (Steps 1–6 complete)
- [x] KB article exists at `kb/KB-0002-disk-full-deleted-open-files.md`
- [x] Support case exists at `support-cases/0002-disk-full-after-deleting-logs.md`

## Cleanup

- [ ] Ran `sudo bash scripts/reset.sh` and saw "Lab reset."
- [ ] Confirmed `systemctl status loggen` → `Unit loggen.service could not be found`
- [ ] Confirmed `/opt/loggen` is removed

## Definition of done

All boxes ticked **and** you can explain the `lsof +L1` technique from memory.
