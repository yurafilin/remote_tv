#!/usr/bin/env python3
"""Roku ECP proof-of-concept — runs on your laptop, stdlib only (no pip install).

Roku External Control Protocol:
  - discovery: SSDP M-SEARCH (UDP multicast 239.255.255.250:1900, ST: roku:ecp)
  - control:   plain HTTP on port 8060  (POST /keypress/<KEY>, GET /query/device-info)

Usage:
  python3 roku_proof.py discover
  python3 roku_proof.py info  <ip>
  python3 roku_proof.py key   <ip> home
  python3 roku_proof.py keys
"""
import socket
import sys
import urllib.request

SSDP_ADDR = "239.255.255.250"
SSDP_PORT = 1900
ECP_PORT = 8060

# our logical key -> Roku ECP key name
KEYS = {
    "power": "PowerOff", "home": "Home", "back": "Back",
    "up": "Up", "down": "Down", "left": "Left", "right": "Right",
    "ok": "Select", "volume_up": "VolumeUp", "volume_down": "VolumeDown",
    "mute": "VolumeMute", "play_pause": "Play",
    "rewind": "Rev", "fast_forward": "Fwd", "replay": "InstantReplay", "info": "Info",
}


def discover(timeout=3):
    msg = "\r\n".join([
        "M-SEARCH * HTTP/1.1",
        f"HOST: {SSDP_ADDR}:{SSDP_PORT}",
        'MAN: "ssdp:discover"',
        "ST: roku:ecp",
        "MX: 2",
        "", "",
    ]).encode()

    sock = socket.socket(socket.AF_INET, socket.SOCK_DGRAM, socket.IPPROTO_UDP)
    sock.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
    sock.setsockopt(socket.IPPROTO_IP, socket.IP_MULTICAST_TTL, 2)
    sock.settimeout(timeout)

    found = {}
    try:
        sock.sendto(msg, (SSDP_ADDR, SSDP_PORT))
        while True:
            data, addr = sock.recvfrom(2048)
            text = data.decode(errors="ignore")
            if "roku" not in text.lower():
                continue
            if addr[0] not in found:
                found[addr[0]] = _header(text, "LOCATION")
    except socket.timeout:
        pass
    except OSError as e:
        print(f"SSDP send/recv failed (network blocked?): {e}")
    finally:
        sock.close()
    return found


def _header(text, name):
    for line in text.split("\r\n"):
        if line.lower().startswith(name.lower() + ":"):
            return line.split(":", 1)[1].strip()
    return None


def device_info(ip):
    url = f"http://{ip}:{ECP_PORT}/query/device-info"
    with urllib.request.urlopen(url, timeout=5) as r:
        return r.read().decode()


def send_key(ip, key):
    roku_key = KEYS.get(key, key)  # accept our name or a raw Roku name
    url = f"http://{ip}:{ECP_PORT}/keypress/{roku_key}"
    req = urllib.request.Request(url, method="POST", data=b"")
    with urllib.request.urlopen(req, timeout=5) as r:
        return r.status


def main(argv):
    cmd = argv[0] if argv else "help"
    if cmd == "discover":
        devices = discover()
        if not devices:
            print("No Roku found on this network (or SSDP blocked).")
        for ip, loc in devices.items():
            print(f"{ip}\t{loc}")
    elif cmd == "info" and len(argv) >= 2:
        print(device_info(argv[1]))
    elif cmd == "key" and len(argv) >= 3:
        print(f"{argv[2]} -> HTTP {send_key(argv[1], argv[2])}")
    elif cmd == "keys":
        for ours, roku in KEYS.items():
            print(f"{ours:14} {roku}")
    else:
        print(__doc__)


if __name__ == "__main__":
    main(sys.argv[1:])
