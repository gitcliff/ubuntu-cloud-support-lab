# Lab 01: DNS resolution fails, ping by IP works

| | |
|---|---|
| Domain | networking |
| Difficulty | ★★☆ |
| Time | ~45 min |
| Environment | Multipass `lab` VM |

## Scenario
> "`apt update` fails with 'Temporary failure resolving archive.ubuntu.com',
> but I can ping 1.1.1.1 fine. Nothing changed... except someone edited the network config."

## Learning objectives
- Understand the stub resolver (`127.0.0.53`) and systemd-resolved
- Use `resolvectl status`, `resolvectl query`, and `dig @server`
- Read and safely change netplan config with `netplan try`

## Break
```bash
sudo ./break.sh
```

## Symptoms / Diagnose / Root cause / Fix
_Fill in using [templates/lab.md](../../../templates/lab.md)._

<details><summary>Hint</summary>Compare <code>dig @127.0.0.53 ubuntu.com</code> with <code>dig @1.1.1.1 ubuntu.com</code>. Then look at which DNS server each link is using in <code>resolvectl status</code>.</details>

## Verify
```bash
resolvectl query archive.ubuntu.com && sudo apt update
```

## References
- `man resolvectl`, `man netplan`
- https://netplan.readthedocs.io

## Reset
```bash
sudo ./reset.sh
```
