# Evil Twin Lab: Taim Starlink LAB

This lab starts an isolated educational access point named `Taim Starlink LAB`.
It does not clone the real SSID, does not collect credentials, and does not
forward traffic to the Internet.

## Files

- `configs/hostapd-open.conf`: open AP configuration.
- `configs/hostapd-wpa2.conf`: WPA2 test AP configuration.
- `configs/dnsmasq.conf`: isolated DHCP/DNS configuration.
- `www/index.html`: educational landing page.
- `scripts/start-open.sh`: starts the open isolated AP.
- `scripts/start-wpa2.sh`: starts the WPA2 isolated AP.
- `scripts/stop.sh`: stops the lab AP and restores NetworkManager.
- `scripts/watch-logs.sh`: watches association, DHCP, and HTTP logs.

## Start the open educational AP

```bash
cd /home/majd/Documents/attacks/evil-twin-lab
sudo ./scripts/start-open.sh wlp4s0
```

Open another terminal to watch logs:

```bash
cd /home/majd/Documents/attacks/evil-twin-lab
./scripts/watch-logs.sh
```

Connect a lab device manually to `Taim Starlink LAB`. It should receive an IP
from `10.99.0.20` to `10.99.0.80` and can open:

```text
http://10.99.0.1:8080/
```

## Stop

```bash
cd /home/majd/Documents/attacks/evil-twin-lab
sudo ./scripts/stop.sh wlp4s0
```

## Optional WPA2 test mode

This remains educational and uses a test passphrase from
`configs/hostapd-wpa2.conf`.

```bash
cd /home/majd/Documents/attacks/evil-twin-lab
sudo ./scripts/start-wpa2.sh wlp4s0
```

## Safety boundaries

- No fake login pages.
- No password collection.
- No NAT or Internet forwarding.
- No deauth during this lab unless run as a separate controlled test.
- Do not use the exact real SSID in the first phase.
