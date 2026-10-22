#!/usr/bin/env bash
set -euo pipefail
[[ $EUID -eq 0 ]] || { echo "run with sudo" >&2; exit 1; }
umount /data 2>/dev/null || true
vgremove -f -q vg_data 2>/dev/null || true
if [[ -f /root/.lab-lvm-loops ]]; then
  for l in $(cat /root/.lab-lvm-loops); do pvremove -q -f "$l" 2>/dev/null || true; losetup -d "$l" || true; done
  rm -f /root/.lab-lvm-loops
fi
echo "Lab reset."
