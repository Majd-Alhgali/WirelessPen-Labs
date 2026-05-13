#!/usr/bin/env bash
set -euo pipefail

IFACE="${1:-wlp4s0}"
LAB_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
RUNTIME_DIR="$LAB_DIR/runtime"

if [[ "${EUID:-$(id -u)}" -ne 0 ]]; then
  echo "Run with sudo: sudo $0 ${IFACE}" >&2
  exit 1
fi

stop_pid_file() {
  local file="$1"
  local name="$2"
  if [[ -f "$file" ]]; then
    local pid
    pid="$(cat "$file" 2>/dev/null || true)"
    if [[ -n "$pid" ]] && kill -0 "$pid" 2>/dev/null; then
      echo "[*] Stopping $name ($pid)"
      kill "$pid" 2>/dev/null || true
      sleep 1
      kill -9 "$pid" 2>/dev/null || true
    fi
    rm -f "$file"
  fi
}

stop_pid_file "$RUNTIME_DIR/hostapd.pid" hostapd
stop_pid_file "$RUNTIME_DIR/dnsmasq.pid" dnsmasq
stop_pid_file "$RUNTIME_DIR/http.pid" http

if [[ -d "/sys/class/net/$IFACE" ]]; then
  ip addr flush dev "$IFACE" || true
  ip link set "$IFACE" down || true
  ip link set "$IFACE" up || true
fi

if command -v nmcli >/dev/null 2>&1; then
  nmcli dev set "$IFACE" managed yes >/dev/null 2>&1 || true
fi

systemctl restart NetworkManager >/dev/null 2>&1 || true

echo "[+] Lab AP stopped. NetworkManager restored if available."
