#!/usr/bin/env python3
import os, json, subprocess, socket

def hyprctl(args):
    subprocess.run(["hyprctl"] + args)

sock_path = os.path.join(
    os.environ.get("XDG_RUNTIME_DIR", "/run/user/1000"),
    "hypr",
    os.environ["HYPRLAND_INSTANCE_SIGNATURE"],
    ".socket2.sock",
)

out = subprocess.run(["hyprctl", "activewindow", "-j"], capture_output=True, text=True).stdout
try:
    focused = json.loads(out).get("address", "")
except:
    focused = ""

hyprctl(["reload", "config-only"])
hyprctl(["keyword", "windowrule", "hyprbars:bar_color rgba(13131700)", "class:.*"])
if focused:
    hyprctl(["keyword", "windowrule", "hyprbars:bar_color rgba(1313178C)", f"address:0x{focused}"])

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
            addr = event.split(">>", 1)[1].strip()
            if addr:
                hyprctl(["reload", "config-only"])
                hyprctl(["keyword", "windowrule", "hyprbars:bar_color rgba(13131700)", "class:.*"])
                hyprctl(["keyword", "windowrule", "hyprbars:bar_color rgba(1313178C)", f"address:0x{addr}"])
