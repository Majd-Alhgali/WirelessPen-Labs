#!/usr/bin/env bash
set -euo pipefail

IFACE="${1:-wlp4s0}"
LAB_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
RUNTIME_DIR="$LAB_DIR/runtime"
LOG_DIR="$LAB_DIR/logs"
HOSTAPD_CONF="$LAB_DIR/configs/hostapd-wpa2.conf"
DNSMASQ_CONF="$LAB_DIR/configs/dnsmasq.conf"
WEB_DIR="$LAB_DIR/www"

if [[ "${EUID:-$(id -u)}" -ne 0 ]]; then
  echo "Run with sudo: sudo $0 ${IFACE}" >&2
  exit 1
fi

for cmd in hostapd dnsmasq ip python3; do
  command -v "$cmd" >/dev/null 2>&1 || {
    echo "Missing required command: $cmd" >&2
    exit 1
  }
done

mkdir -p "$RUNTIME_DIR" "$LOG_DIR"

if [[ ! -d "/sys/class/net/$IFACE" ]]; then
  echo "Interface not found: $IFACE" >&2
  exit 1
fi

echo "[*] Starting isolated Evil Twin lab AP on $IFACE"
echo "[*] SSID: Taim Starlink LAB"
echo "[*] Mode: WPA2-PSK test only, isolated, no Internet forwarding"
echo "[*] Test passphrase is configured in configs/hostapd-wpa2.conf"

if command -v nmcli >/dev/null 2>&1; then
  nmcli dev disconnect "$IFACE" >/dev/null 2>&1 || true
  nmcli dev set "$IFACE" managed no >/dev/null 2>&1 || true
fi

rfkill unblock wlan >/dev/null 2>&1 || true
ip link set "$IFACE" down
ip addr flush dev "$IFACE"
ip link set "$IFACE" up
ip addr add 10.99.0.1/24 dev "$IFACE"
sysctl -w net.ipv4.ip_forward=0 >/dev/null

dnsmasq --conf-file="$DNSMASQ_CONF" --interface="$IFACE" \
  --pid-file="$RUNTIME_DIR/dnsmasq.pid" \
  --log-facility="$LOG_DIR/dnsmasq.log"

hostapd -i "$IFACE" "$HOSTAPD_CONF" >"$LOG_DIR/hostapd.log" 2>&1 &
echo "$!" > "$RUNTIME_DIR/hostapd.pid"
sleep 1
if ! kill -0 "$(cat "$RUNTIME_DIR/hostapd.pid")" 2>/dev/null; then
  echo "hostapd failed to start. Last log lines:" >&2
  tail -40 "$LOG_DIR/hostapd.log" >&2 || true
  "$LAB_DIR/scripts/stop.sh" "$IFACE" >/dev/null 2>&1 || true
  exit 1
fi

cd "$WEB_DIR"
python3 -m http.server 8080 --bind 10.99.0.1 >"$LOG_DIR/http.log" 2>&1 &
echo "$!" > "$RUNTIME_DIR/http.pid"

echo "[+] WPA2 lab AP started."
echo "[+] Client network: 10.99.0.0/24"
echo "[+] Local page: http://10.99.0.1:8080/"
echo "[!] Stop with: sudo $LAB_DIR/scripts/stop.sh $IFACE"
