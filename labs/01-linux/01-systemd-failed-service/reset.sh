#!/usr/bin/env bash
set -euo pipefail
[[ $EUID -eq 0 ]] || { echo "run with sudo" >&2; exit 1; }
systemctl disable --now reportd 2>/dev/null || true
rm -f /etc/systemd/system/reportd.service
rm -rf /opt/reportd
systemctl daemon-reload
systemctl reset-failed
echo "Lab reset."
