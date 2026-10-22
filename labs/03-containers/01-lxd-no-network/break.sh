#!/usr/bin/env bash
# Removes the NIC from the default profile and starts a container.
set -euo pipefail
[[ $EUID -eq 0 ]] || { echo "run with sudo" >&2; exit 1; }
lxc profile show default > /root/.lab-default-profile.yaml
lxc profile device remove default eth0
lxc launch ubuntu:24.04 web1
echo "Lab broken. Check: lxc list"
