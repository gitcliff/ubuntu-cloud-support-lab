#!/usr/bin/env bash
# Simulates a broken dpkg state:
#   1. Installs sl cleanly, then replaces its postinst with a failing script.
#   2. Marks sl as half-configured so dpkg will re-run the postinst on the
#      next apt invocation — which then fails with error code 1.
#   3. Holds /var/lib/dpkg/lock-frontend with a real flock so apt also shows
#      the "Could not get lock" error. Uses disown + setsid to survive script exit.
set -euo pipefail
[[ $EUID -eq 0 ]] || { echo "run with sudo" >&2; exit 1; }

# ── Part 1: install sl cleanly ────────────────────────────────────────────────
apt-get install -y sl

# ── Part 2: replace sl's postinst with a failing script ──────────────────────
# sl ships no postinst; record whether one existed so reset.sh knows what to do.
if [ -f /var/lib/dpkg/info/sl.postinst ]; then
    cp -a /var/lib/dpkg/info/sl.postinst /var/lib/dpkg/info/sl.postinst.orig
    echo "had_postinst" > /tmp/lab03-postinst-state
else
    echo "no_postinst" > /tmp/lab03-postinst-state
fi

cat > /var/lib/dpkg/info/sl.postinst <<'POSTINST'
#!/bin/bash
# Simulated broken postinst — do not edit
echo "postinst: error: required config directory /etc/sl is missing" >&2
exit 1
POSTINST
chmod 755 /var/lib/dpkg/info/sl.postinst

# Mark sl as half-configured so dpkg re-runs the postinst next time
sed -i '/^Package: sl$/,/^$/ {
    s/^Status: install ok installed$/Status: install ok half-configured/
}' /var/lib/dpkg/status

# ── Part 3: hold lock files with a real flock that survives script exit ───────
# setsid puts the subshell in a new session (no SIGHUP on parent exit).
# disown removes it from bash's job table.
setsid bash -c '( flock -x 9; sleep 3600 ) 9>/var/lib/dpkg/lock-frontend' &
disown $!
echo $! > /tmp/lab03-lock-pids

setsid bash -c '( flock -x 9; sleep 3600 ) 9>/var/lib/dpkg/lock' &
disown $!
echo $! >> /tmp/lab03-lock-pids

sleep 0.5   # wait for flock to acquire

echo "Lab broken."
echo "  sl has a failing postinst and is stuck in 'half-configured' state."
echo "  dpkg lock files are held by background processes."
echo ""
echo "  Start investigating with:"
echo "    sudo apt install curl"
