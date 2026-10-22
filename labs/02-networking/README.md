# 02 · Networking (20%)

| # | Lab | Key skills | Status |
|---|---|---|---|
| 01 | [DNS resolution fails, ping by IP works](01-dns-resolution) | systemd-resolved, resolvectl, netplan nameservers | worked example |
| 02 | Static IP lost after reboot | netplan YAML, `netplan try`, cloud-init network config | ☐ |
| 03 | Port open locally but unreachable remotely | ss, ufw, nftables, tcpdump | ☐ |
| 04 | Large transfers hang, small ones work | MTU, PMTUD, `ping -M do -s` | ☐ |
| 05 | Two LXD nodes can't talk | bridges, routes, `ip route`, `ip neigh` | ☐ |

Core commands: `ip`, `ss`, `resolvectl`, `dig`, `netplan`, `ufw`, `nft`, `tcpdump`, `mtr`, `curl -v`.
