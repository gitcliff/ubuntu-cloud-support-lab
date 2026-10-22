# Case 0001: Production app down after reboot!!

| Field | Value |
|---|---|
| Severity | 2 (degraded: reports are delayed, nothing is lost) |
| Product | Ubuntu 24.04 LTS |
| Opened | 2026-10-22 08:14 UTC |
| SLA first response | 2 h |

## Customer's message
> Hi, after patching last night our reporting service is not running anymore.
> We didn't change anything. It's urgent, management needs the reports by noon.
> — Sam, Ops team

## Internal notes
- "Didn't change anything" + patching → maybe a package update, maybe a deploy that happened alongside it.
- Need: `systemctl status reportd`, `journalctl -u reportd -b`, `systemctl cat reportd`.
- Reproduced in lab 01-linux/01: exit 203/EXEC = binary not executable.

## First response (sent)
> Hi Sam,
>
> Thanks for reaching out. I understand the reports are needed by noon, so I'm
> treating this as a priority.
>
> To find the cause quickly, could you run the following and paste the output?
> ```
> sudo systemctl status reportd --no-pager
> sudo journalctl -u reportd -b --no-pager -n 50
> sudo systemctl cat reportd
> ```
> If it's easier, you can run our diagnostic script (`sudo ./ubuntu-diag.sh`) and
> attach the tarball it creates.
>
> I'll reply within 30 minutes of receiving the output.

## Resolution response (sent)
> Hi Sam,
>
> Thanks for the output. The service fails with `status=203/EXEC`, which means
> systemd couldn't run `/opt/reportd/reportd` because the file has lost its
> execute permission (it's `-rw-r--r--`). This is most likely from last night's
> deployment, which replaced the file, rather than from the OS patches.
>
> **To fix:**
> ```
> sudo chmod 755 /opt/reportd/reportd
> sudo systemctl restart reportd
> systemctl is-active reportd   # should print "active"
> ```
>
> **To prevent a repeat:** set the file mode explicitly in your deployment tooling
> (e.g. `mode: "0755"` in Ansible), and consider an alert on `systemctl --failed`.
>
> More detail: KB-0001. I'll keep this case open until you confirm the reports are
> running again.

## Lessons learned
- Customers often say "nothing changed". Ask what *did* happen around that time.
- Ask for exact commands, not "send logs".
