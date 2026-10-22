#!/usr/bin/env bash
# Creates a service whose ExecStart points at a non-executable file.
set -euo pipefail
[[ $EUID -eq 0 ]] || { echo "run with sudo" >&2; exit 1; }

install -d /opt/reportd
cat > /opt/reportd/reportd <<'APP'
#!/usr/bin/env bash
while true; do echo "report generated $(date -Is)"; sleep 30; done
APP
chmod 0644 /opt/reportd/reportd   # the bug: not executable

cat > /etc/systemd/system/reportd.service <<'UNIT'
[Unit]
Description=Internal report daemon
After=network-online.target

[Service]
ExecStart=/opt/reportd/reportd
Restart=on-failure
RestartSec=2

[Install]
WantedBy=multi-user.target
UNIT

systemctl daemon-reload
systemctl enable --now reportd 2>/dev/null || true
echo "Lab broken. Start investigating with: systemctl status reportd"
