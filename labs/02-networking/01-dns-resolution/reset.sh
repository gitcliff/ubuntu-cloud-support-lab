#!/usr/bin/env bash
set -euo pipefail
[[ $EUID -eq 0 ]] || { echo "run with sudo" >&2; exit 1; }
rm -f /etc/netplan/99-lab-dns.yaml
netplan apply
resolvectl flush-caches
echo "Lab reset."
