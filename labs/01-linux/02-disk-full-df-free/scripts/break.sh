#!/usr/bin/env bash
# Creates a "deleted-but-open" file: a service holds a log file open after an
# operator deletes it, so the disk blocks are never freed.
set -euo pipefail
[[ $EUID -eq 0 ]] || { echo "run with sudo" >&2; exit 1; }

install -d /opt/loggen

# The service script: opens the log file once at startup (exec 3>>),
# then keeps writing to that fd. Deleting the file while this is running
# leaves the fd — and the disk blocks — in place.
cat > /opt/loggen/loggen <<'APP'
#!/usr/bin/env bash
exec 3>> /opt/loggen/app.log
while true; do
    printf '%s log entry %s\n' "$(date -Is)" \
        "$(tr -dc 'a-z0-9' < /dev/urandom | head -c 60)" >&3
    sleep 0.5
done
APP
chmod 0755 /opt/loggen/loggen

cat > /etc/systemd/system/loggen.service <<'UNIT'
[Unit]
Description=Log generator (lab 02)
After=network.target

[Service]
ExecStart=/opt/loggen/loggen
Restart=always

[Install]
WantedBy=multi-user.target
UNIT

systemctl daemon-reload
systemctl enable --now loggen

# Give the service time to create and grow the log file
sleep 4

# Operator "cleans up" the log directory — but the service still holds fd 3 open
rm -f /opt/loggen/app.log

echo "Lab broken."
echo "  The operator deleted /opt/loggen/app.log to free space."
echo "  The loggen service is still running and holds the file open."
echo ""
echo "  Start investigating with:"
echo "    ls /opt/loggen/"
echo "    du -sh /opt/loggen/"
