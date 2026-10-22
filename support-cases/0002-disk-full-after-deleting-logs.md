# Case 0002: Disk still full after deleting log files

| Field    | Value                                      |
|----------|--------------------------------------------|
| Severity | 2 (degraded: new logs cannot be written)   |
| Product  | Ubuntu 24.04 LTS                           |
| Opened   | 2026-10-22 09:41 UTC                       |
| SLA first response | 2 h                              |

## Customer's message

> Hi, our `/var/log` partition hit 100% last night. I deleted all the old log files
> this morning but `df` still shows it at 100% and the app is still failing to
> write logs. Did something go wrong with my filesystem? Do I need to reformat?
> — Alex, Platform team

## Internal notes

- "Deleted the files but df didn't change" is the classic deleted-but-open symptom.
- No reformat needed. Cause is almost certainly a daemon holding the log fd open.
- Need: `lsof +L1 | grep /var/log` output to confirm and identify the process.
- Reproduced in lab 01-linux/02: loggen holds fd open after `rm app.log`.

## First response (sent)

> Hi Alex,
>
> Thanks for writing in — this is a well-known Linux behaviour and does not require
> a reformat.
>
> When you delete a file with `rm`, Linux removes the filename but keeps the
> underlying disk blocks allocated as long as any running process still has the
> file open. A log-writing daemon almost certainly had the file open when you
> deleted it, which is why `df` hasn't changed.
>
> To confirm, please run the following and share the output:
>
> ```bash
> sudo lsof +L1 | grep /var/log
> ```
>
> This lists any files that have been deleted but are still held open by a process.
> Look for a row with `(deleted)` in the last column.
>
> I'll reply within 30 minutes of receiving the output.

## Resolution response (sent)

> Hi Alex,
>
> Thanks for the `lsof` output. I can see that `appd` (PID 4821) is still writing
> to the deleted file, which is why the space hasn't been freed.
>
> You have two options:
>
> **Option A — Restart the service (recommended):**
> ```bash
> sudo systemctl restart appd
> ```
> This closes the file descriptor and frees the blocks immediately. The service
> will create a fresh log file on startup.
>
> **Option B — Truncate without restarting (if downtime is not acceptable):**
> ```bash
> # Replace 4821 and 7 with the PID and FD number from lsof
> sudo truncate -s 0 /proc/4821/fd/7
> ```
> This zeros out the file in place. The process keeps running and the blocks are
> freed, but any log data written after deletion is lost.
>
> After either option, verify with:
> ```bash
> sudo lsof +L1 | grep /var/log   # should return nothing
> df -h /var/log                   # usage should drop
> ```
>
> To prevent this happening again: configure `logrotate` to send `SIGHUP` to the
> service after rotation so it reopens its log file automatically. See
> KB-0002 for details.
>
> Let me know once you've applied the fix and I'll keep this open until confirmed.

## Lessons learned

- Customers often interpret `df` as the ground truth for what files exist. Explain
  the difference between directory entries and inodes early.
- Always ask for `lsof +L1` output before suggesting a restart — it confirms the
  cause and identifies exactly which process to act on.
- Offer both the restart and the truncation option so the customer can choose based
  on their maintenance window.
