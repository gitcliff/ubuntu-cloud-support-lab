#!/usr/bin/env bash
# ubuntu-diag.sh: a lightweight sosreport.
# Collects read-only diagnostic data from an Ubuntu host into a tarball you can
# attach to a support case.
#
# Usage: ubuntu-diag.sh [-o DIR] [-n] [-q] [-h] [-V]

set -euo pipefail

VERSION="0.1.0"
OUT_DIR="/tmp"
MAKE_TAR=1
QUIET=0
CMD_TIMEOUT=20

usage() {
  cat <<EOF
ubuntu-diag.sh ${VERSION}: collect Ubuntu diagnostic data for a support case

Usage: $(basename "$0") [options]

Options:
  -o DIR   write the report to DIR (default: /tmp)
  -n       don't create a tarball; leave the report directory
  -q       quiet: print only the final report path
  -h       show this help
  -V       print version

Every command it runs is read-only. Run with sudo for complete output.
EOF
}

log() {
  [[ $QUIET -eq 1 ]] || printf '[ubuntu-diag] %s\n' "$*" >&2
}

# collect <section> <name> <command> [args...]
# Runs a command and saves its stdout+stderr to <section>/<name>.txt.
# A missing command is recorded as SKIPPED, not treated as an error.
collect() {
  local section=$1 name=$2
  shift 2
  local dest="${REPORT_DIR}/${section}/${name}.txt"
  mkdir -p "${REPORT_DIR}/${section}"

  if ! command -v "$1" >/dev/null 2>&1; then
    echo "SKIPPED: '$1' not found" > "$dest"
    echo "${section}/${name}: skipped" >> "${REPORT_DIR}/summary.txt"
    return 0
  fi

  local rc=0
  {
    echo "# \$ $*"
    if command -v timeout >/dev/null 2>&1; then
      timeout "$CMD_TIMEOUT" "$@" 2>&1 || rc=$?
    else
      "$@" 2>&1 || rc=$?
    fi
  } > "$dest"
  echo "${section}/${name}: rc=${rc}" >> "${REPORT_DIR}/summary.txt"
}

# copy_file <section> <path>: copies a file if it exists and is readable.
copy_file() {
  local section=$1 path=$2
  [[ -r "$path" ]] || return 0
  mkdir -p "${REPORT_DIR}/${section}/files"
  cp "$path" "${REPORT_DIR}/${section}/files/$(echo "$path" | tr '/' '_' | sed 's/^_//')"
}

collect_system() {
  collect system os-release cat /etc/os-release
  collect system uname uname -a
  collect system uptime uptime
  collect system hostnamectl hostnamectl
  collect system timedatectl timedatectl
}

collect_linux() {
  collect linux failed-units systemctl --failed --no-pager
  collect linux journal-errors journalctl -p err -b --no-pager -n 200
  collect linux dmesg-tail dmesg -T --level=err,warn
  collect linux free free -h
  collect linux top-cpu ps -eo pid,ppid,user,%cpu,%mem,stat,cmd --sort=-%cpu
  collect linux vmstat vmstat 1 5
  collect linux apt-held apt-mark showhold
  collect linux snap-list snap list
  copy_file linux /var/log/apt/history.log
}

collect_networking() {
  collect networking ip-addr ip -br addr
  collect networking ip-route ip route
  collect networking resolvectl resolvectl status
  collect networking listening ss -tulpn
  collect networking ufw ufw status verbose
  copy_file networking /etc/hosts
  local f
  for f in /etc/netplan/*.yaml; do copy_file networking "$f"; done
}

collect_containers() {
  collect containers lxc-list lxc list
  collect containers docker-ps docker ps -a
  collect containers microk8s-status microk8s status
}

collect_storage() {
  collect storage lsblk lsblk -f
  collect storage df df -hT
  collect storage df-inodes df -i
  collect storage findmnt findmnt
  collect storage lvm-pvs pvs
  collect storage lvm-lvs lvs
  copy_file storage /proc/mdstat
  copy_file storage /etc/fstab
}

collect_virtualization() {
  collect virtualization kvm-ok kvm-ok
  collect virtualization virsh-list virsh list --all
  collect virtualization multipass-list multipass list
}

SECTIONS="system linux networking containers storage virtualization"

main() {
  local opt
  OPTIND=1
  while getopts ":o:nqhV" opt; do
    case $opt in
      o) OUT_DIR=$OPTARG ;;
      n) MAKE_TAR=0 ;;
      q) QUIET=1 ;;
      h) usage; return 0 ;;
      V) echo "$VERSION"; return 0 ;;
      :) echo "error: -$OPTARG needs an argument" >&2; usage >&2; return 2 ;;
      \?) echo "error: unknown option -$OPTARG" >&2; usage >&2; return 2 ;;
    esac
  done

  if [[ ! -d "$OUT_DIR" || ! -w "$OUT_DIR" ]]; then
    echo "error: output directory '$OUT_DIR' does not exist or is not writable" >&2
    return 1
  fi

  [[ $EUID -eq 0 ]] || log "warning: not running as root; some output will be incomplete"

  local name
  name="ubuntu-diag-$(hostname -s 2>/dev/null || echo host)-$(date +%Y%m%d-%H%M%S)"
  REPORT_DIR="${OUT_DIR%/}/${name}"
  mkdir -p "$REPORT_DIR"
  echo "ubuntu-diag ${VERSION} | $(date -u +%Y-%m-%dT%H:%M:%SZ)" > "${REPORT_DIR}/summary.txt"

  local s
  for s in $SECTIONS; do
    log "collecting ${s}"
    "collect_${s}"
  done

  if [[ $MAKE_TAR -eq 1 ]]; then
    tar -czf "${REPORT_DIR}.tar.gz" -C "$OUT_DIR" "$name"
    rm -rf "$REPORT_DIR"
    echo "${REPORT_DIR}.tar.gz"
  else
    echo "$REPORT_DIR"
  fi
}

if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
  main "$@"
fi
