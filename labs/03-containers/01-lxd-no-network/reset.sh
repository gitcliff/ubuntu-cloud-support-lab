#!/usr/bin/env bash
set -euo pipefail
[[ $EUID -eq 0 ]] || { echo "run with sudo" >&2; exit 1; }
lxc delete -f web1 2>/dev/null || true
if [[ -f /root/.lab-default-profile.yaml ]]; then
  lxc profile edit default < /root/.lab-default-profile.yaml
  rm -f /root/.lab-default-profile.yaml
fi
echo "Lab reset."
