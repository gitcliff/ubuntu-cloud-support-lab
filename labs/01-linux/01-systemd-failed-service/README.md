# Lab 01: Service won't start after reboot

|             |                    |
| ----------- | ------------------ |
| Domain      | linux              |
| Difficulty  | ★☆☆                |
| Time        | ~30 min            |
| Environment | Multipass `lab` VM |

## Scenario

> "We deployed a small internal app called `reportd`. It ran fine yesterday,
> but after this morning's reboot it's down and won't come back."

## Learning objectives

- Read `systemctl status` and spot exit codes such as `203/EXEC`
- Use `journalctl -u` with `-b` and `-xe`
- Know where unit files live and how `daemon-reload` works

## Break

```bash
sudo bash break.sh
```

## Symptoms


```
cliff@cliff:~$ sudo systemctl status reportd
    u25cf reportd.service - Internal report daemon
     Loaded: loaded (/etc/systemd/system/reportd.service; enabled; preset: enabled)
     Active: activating (auto-restart) (Result: exit-code) since Thu 2026-10-22 15:04:39 UTC; 995ms ago
    Process: 9258 ExecStart=/opt/reportd/reportd (code=exited, status=203/EXEC)
   Main PID: 9258 (code=exited, status=203/EXEC)
        CPU: 410us
```

![Terminal output showing reportd failing with status 203/EXEC](screenshots/status.png)

## Diagnose


Start by checking the service's current state and the error systemd reports:

```bash
sudo systemctl status reportd
```

Look for the `Active` state and the `ExecStart` exit status. Here, `203/EXEC`
means systemd could not execute the service's program. Record what you find,
then investigate the unit and executable below.

Hints (open only when stuck):

<details><summary>Hint 1</summary>Look at the <code>code=exited, status=</code> part. What does 203 mean?</details>
<details><summary>Hint 2</summary><code>systemctl cat reportd</code>, then check that the ExecStart path exists and is executable.</details>

## Root cause

`/opt/reportd/reportd` is set to mode `0644`, so it has no execute permission.
The service's `ExecStart` tries to run that file directly, which systemd reports
as `203/EXEC`.

## Fix

Make the program executable, then restart the service:

```bash
sudo chmod 0755 /opt/reportd/reportd
sudo systemctl restart reportd
```

## Verify

```bash
systemctl is-active reportd && journalctl -u reportd -n 5
```

The service should show as active and running:

```text
cliff@cliff:~$ sudo systemctl status reportd
● reportd.service - Internal report daemon
      Loaded: loaded (/etc/systemd/system/reportd.service; enabled; preset: enabled)
      Active: active (running) since Thu 2026-10-22 15:19:16 UTC; 3min 17s ago
    Main PID: 10270 (bash)
        Tasks: 2 (limit: 4537)
      Memory: 860.0K (peak: 1.4M)
          CPU: 91ms
      CGroup: /system.slice/reportd.service
                 ├─10270 bash /opt/reportd/reportd
                 └─10323 sleep 30
```

Example journal output:

```text
cliff@cliff:~$ journalctl -u reportd -n 5
Oct 22 16:04:35 cliff reportd[10270]: report generated 2026-10-22T16:04:35+00:00
Oct 22 16:05:05 cliff reportd[10270]: report generated 2026-10-22T16:05:05+00:00
Oct 22 17:00:00 cliff reportd[10270]: report generated 2026-10-22T17:00:00+00:00
Oct 22 17:21:59 cliff reportd[10270]: report generated 2026-10-22T17:21:59+00:00
Oct 22 17:22:29 cliff reportd[10270]: report generated 2026-10-22T17:22:29+00:00
```

## Prevent

Use packaging or configuration management to deploy `/opt/reportd/reportd` with
mode `0755`. Add a deployment check that fails if the program is not executable,
and validate the unit file before enabling or restarting the service:

```bash
test -x /opt/reportd/reportd
sudo systemd-analyze verify /etc/systemd/system/reportd.service
```

Monitor `reportd` so a future startup failure is detected promptly.

## References

- `man systemd.exec` (section "PROCESS EXIT CODES")
- `man journalctl`

## Reset

```bash
sudo ./reset.sh
```
