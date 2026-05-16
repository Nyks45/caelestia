#!/usr/bin/env python3
import os, json, subprocess, socket, time

def hyprctl(args):
    subprocess.run(["hyprctl"] + args, capture_output=True)

sock_path = os.path.join(
    os.environ.get("XDG_RUNTIME_DIR", "/run/user/1000"),
    "hypr",
    os.environ["HYPRLAND_INSTANCE_SIGNATURE"],
    ".socket2.sock",
)

def set_bars():
    out = subprocess.run(["hyprctl", "clients", "-j"], capture_output=True, text=True).stdout
    try:
        clients = json.loads(out)
    except:
        return
    out2 = subprocess.run(["hyprctl", "activewindow", "-j"], capture_output=True, text=True).stdout
    try:
        focused = json.loads(out2).get("address", "")
    except:
        focused = ""
    hyprctl(["reload", "config-only"])
    for c in clients:
        addr = c.get("address", "")
        if addr and addr != focused:
            hyprctl(["keyword", "windowrule", "hyprbars:no_bar true", f"address:0x{addr}"])

set_bars()
sock = socket.socket(socket.AF_UNIX, socket.SOCK_STREAM)
sock.connect(sock_path)
buf = b""
while True:
    data = sock.recv(4096)
    if not data:
        break
    buf += data
    while b"\n" in buf:
        line, buf = buf.split(b"\n", 1)
        event = line.decode().strip()
        if event.startswith("activewindowv2>>"):
            set_bars()
