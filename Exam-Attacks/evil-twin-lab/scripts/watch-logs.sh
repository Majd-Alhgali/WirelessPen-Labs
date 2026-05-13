#!/usr/bin/env bash
set -euo pipefail

LAB_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
LOG_DIR="$LAB_DIR/logs"

mkdir -p "$LOG_DIR"
touch "$LOG_DIR/hostapd.log" "$LOG_DIR/dnsmasq.log" "$LOG_DIR/http.log"

echo "[*] Watching logs. Press Ctrl+C to stop watching."
tail -F "$LOG_DIR/hostapd.log" "$LOG_DIR/dnsmasq.log" "$LOG_DIR/http.log"
