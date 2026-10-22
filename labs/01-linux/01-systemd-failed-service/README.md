# Lab 01: Service won't start after reboot

| | |
|---|---|
| Domain | linux |
| Difficulty | ★☆☆ |
| Time | ~30 min |
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
sudo ./break.sh
```

## Symptoms
_Fill in: output of `systemctl status reportd`._

## Diagnose
_Fill in: each command you ran and why._

Hints (open only when stuck):
<details><summary>Hint 1</summary>Look at the <code>code=exited, status=</code> part. What does 203 mean?</details>
<details><summary>Hint 2</summary><code>systemctl cat reportd</code>, then check that the ExecStart path exists and is executable.</details>

## Root cause
_Fill in._

## Fix
_Fill in._

## Verify
```bash
systemctl is-active reportd && journalctl -u reportd -n 5
```

## Prevent
_Fill in: e.g. config management, `systemd-analyze verify`, monitoring._

## References
- `man systemd.exec` (section "PROCESS EXIT CODES")
- `man journalctl`

## Reset
```bash
sudo ./reset.sh
```
