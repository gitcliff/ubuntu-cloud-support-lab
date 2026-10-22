#!/usr/bin/env bash
# Points the primary interface at an unreachable DNS server via netplan.
set -euo pipefail
[[ $EUID -eq 0 ]] || { echo "run with sudo" >&2; exit 1; }
iface=$(ip -o route show default | awk '{print $5; exit}')
cat > /etc/netplan/99-lab-dns.yaml <<YAML
network:
  version: 2
  ethernets:
    ${iface}:
      dhcp4: true
      dhcp4-overrides:
        use-dns: false
      nameservers:
        addresses: [192.0.2.53]
YAML
chmod 600 /etc/netplan/99-lab-dns.yaml
netplan apply
resolvectl flush-caches
echo "Lab broken. Try: sudo apt update"
