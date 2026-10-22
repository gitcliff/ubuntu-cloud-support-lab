#!/usr/bin/env bash
set -euo pipefail
[[ $EUID -eq 0 ]] || { echo "run with sudo" >&2; exit 1; }

systemctl disable --now loggen 2>/dev/null || true
rm -f /etc/systemd/system/loggen.service
rm -rf /opt/loggen
systemctl daemon-reload
systemctl reset-failed 2>/dev/null || true
echo "Lab reset."
