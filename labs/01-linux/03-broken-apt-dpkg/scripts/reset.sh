#!/usr/bin/env bash
set -euo pipefail
[[ $EUID -eq 0 ]] || { echo "run with sudo" >&2; exit 1; }

# ── Kill lock-holding processes ───────────────────────────────────────────────
if [ -f /tmp/lab03-lock-pids ]; then
    while IFS= read -r pid; do
        # Kill the setsid wrapper and its child sleep
        pkill -TERM -P "$pid" 2>/dev/null || true
        kill "$pid" 2>/dev/null || true
    done < /tmp/lab03-lock-pids
    rm -f /tmp/lab03-lock-pids
fi

# Fallback: fuser kills any remaining process holding the lock files
fuser -k /var/lib/dpkg/lock-frontend 2>/dev/null || true
fuser -k /var/lib/dpkg/lock          2>/dev/null || true
sleep 0.3

# Remove lingering lock files
rm -f /var/lib/dpkg/lock-frontend
rm -f /var/lib/dpkg/lock
rm -f /var/cache/apt/archives/lock

# ── Restore sl's postinst ─────────────────────────────────────────────────────
state=$(cat /tmp/lab03-postinst-state 2>/dev/null || echo "no_postinst")
if [ "$state" = "had_postinst" ] && [ -f /var/lib/dpkg/info/sl.postinst.orig ]; then
    cp -a /var/lib/dpkg/info/sl.postinst.orig /var/lib/dpkg/info/sl.postinst
    rm -f /var/lib/dpkg/info/sl.postinst.orig
else
    # sl had no original postinst — remove the injected one
    rm -f /var/lib/dpkg/info/sl.postinst
fi
rm -f /tmp/lab03-postinst-state

# ── Restore sl's dpkg status ──────────────────────────────────────────────────
sed -i '/^Package: sl$/,/^$/ {
    s/^Status: install ok half-configured$/Status: install ok installed/
}' /var/lib/dpkg/status

dpkg --configure -a 2>/dev/null || true
apt-get remove -y sl 2>/dev/null || true
apt-get autoremove -y 2>/dev/null || true

echo "Lab reset."
