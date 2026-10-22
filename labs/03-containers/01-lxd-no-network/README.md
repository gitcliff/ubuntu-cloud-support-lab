# Lab 01: LXD container has no network

| | |
|---|---|
| Domain | containers |
| Difficulty | ★★☆ |
| Time | ~40 min |
| Environment | Multipass `lab` VM with LXD |

## Scenario
> "New containers come up without an IPv4 address. Old ones still work until they restart."

## Learning objectives
- How LXD networking works: `lxdbr0`, its built-in dnsmasq (DHCP), and NAT
- Inspect with `lxc network show`, `lxc config show --expanded`, `lxc profile show`
- Tell a profile problem apart from a bridge problem

## Break
```bash
sudo ./break.sh
```

<details><summary>Hint</summary>Run <code>lxc config show web1 --expanded</code>. Which device gives the container its NIC, and where does it come from?</details>

## Verify
```bash
lxc list web1   # should show an IPv4 address
lxc exec web1 -- ping -c1 ubuntu.com
```

## Reset
```bash
sudo ./reset.sh
```
