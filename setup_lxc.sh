#!/usr/bin/env bash
# ============================================================================
# Linux LXC Setup Script for KTMB Shuttle Tebrau Sniper
# Tested on Debian 12 / Ubuntu 22.04+ / Ubuntu 24.04 LXC Containers (Proxmox)
# ============================================================================
set -euo pipefail

APP_DIR="/opt/ktmb-shuttle-bot"
echo "[*] Setting up KTMB Shuttle Bot in ${APP_DIR}..."

# 1. Install system packages (Python, Xvfb, Fluxbox, x11vnc, noVNC for remote browser access)
export DEBIAN_FRONTEND=noninteractive
apt-get update
apt-get install -y \
    python3 python3-venv python3-pip curl git \
    xvfb fluxbox x11vnc novnc websockify

# 2. Copy repo files if running from another directory
if [ "$(pwd)" != "${APP_DIR}" ]; then
    mkdir -p "${APP_DIR}"
    cp -r . "${APP_DIR}/"
fi
cd "${APP_DIR}"

# 3. Create Python virtual environment & install Playwright + Chromium + OS dependencies
python3 -m venv .venv
.venv/bin/pip install --upgrade pip
.venv/bin/pip install -r requirements.txt
.venv/bin/playwright install --with-deps chromium

# 4. Initialize .env if not present
if [ ! -f .env ]; then
    cp .env.example .env
    echo "[!] Created ${APP_DIR}/.env from template. Please edit it with your credentials!"
fi

# 5. Install systemd services (Display stack + Bot service)
cp systemd/ktmb-display.service /etc/systemd/system/ktmb-display.service
cp systemd/ktmb-sniper.service /etc/systemd/system/ktmb-sniper.service
systemctl daemon-reload
systemctl enable ktmb-display.service

echo ""
echo "============================================================================"
echo "[+] Installation Complete!"
echo "1. Edit your configuration:"
echo "     nano ${APP_DIR}/.env"
echo "2. Start the virtual display + NoVNC server (port 6080):"
echo "     systemctl start ktmb-display.service"
echo "3. Open http://<LXC-IP>:6080/vnc.html in your browser to view the LXC screen"
echo "4. Start the KTMB Sniper service:"
echo "     systemctl enable --now ktmb-sniper.service"
echo "5. Watch live logs:"
echo "     journalctl -u ktmb-sniper.service -f"
echo "============================================================================"
