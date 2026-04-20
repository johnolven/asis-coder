#!/bin/bash

# ==========================================
# ASIS-CODER BOOTSTRAP PARENT
# ==========================================
# Configura un dispositivo como PARENT del swarm:
#   - Instala Redis, tmux, jq, git, node, claude CLI
#   - Configura Redis para escuchar en la red del swarm
#   - Inicializa asis-coder como rol parent (genera token)
#   - Instala systemd unit para el enrollment listener
#
# Uso:
#   curl -fsSL https://raw.githubusercontent.com/johnolven/asis-coder/main/bootstrap-parent.sh | bash
#   o localmente:  bash bootstrap-parent.sh [--ip 192.168.50.1] [--repo <url>] [--branch <b>]

set -e

SWARM_IP=""
REPO_URL="https://github.com/johnolven/asis-coder.git"
BRANCH="main"

while [ $# -gt 0 ]; do
    case "$1" in
        --ip)     SWARM_IP="$2"; shift 2 ;;
        --repo)   REPO_URL="$2"; shift 2 ;;
        --branch) BRANCH="$2"; shift 2 ;;
        *) echo "Argumento desconocido: $1"; exit 1 ;;
    esac
done

if [ -z "$SWARM_IP" ]; then
    SWARM_IP="$(ip -4 addr show 2>/dev/null | grep -oE '192\.168\.50\.[0-9]+' | head -1)"
    [ -z "$SWARM_IP" ] && SWARM_IP="$(hostname -I | awk '{print $1}')"
fi

echo "════════════════════════════════════════"
echo "  ASIS-CODER BOOTSTRAP PARENT"
echo "════════════════════════════════════════"
echo "  Swarm IP:  $SWARM_IP"
echo "  Repo:      $REPO_URL ($BRANCH)"
echo "════════════════════════════════════════"

if [ "$EUID" -eq 0 ]; then SUDO=""
elif command -v sudo >/dev/null; then SUDO="sudo"
else echo "ERROR: se requiere sudo"; exit 1
fi

echo "[1/7] Instalando dependencias..."
if command -v apt-get >/dev/null; then
    $SUDO apt-get update -qq
    $SUDO DEBIAN_FRONTEND=noninteractive apt-get install -y -qq \
        curl git tmux jq redis-server redis-tools openssh-client \
        build-essential ca-certificates openssl
fi

echo "[2/7] Instalando Node.js..."
if ! command -v node >/dev/null; then
    curl -fsSL https://deb.nodesource.com/setup_20.x | $SUDO -E bash -
    $SUDO apt-get install -y -qq nodejs
fi

echo "[3/7] Instalando Claude CLI..."
if ! command -v claude >/dev/null; then
    $SUDO npm install -g @anthropic-ai/claude-code 2>&1 | tail -3 || true
fi

echo "[4/7] Configurando Redis para red del swarm ($SWARM_IP)..."
REDIS_CONF="/etc/redis/redis.conf"
if [ -f "$REDIS_CONF" ]; then
    if ! $SUDO grep -qE "^bind .*${SWARM_IP}" "$REDIS_CONF"; then
        $SUDO sed -i "s/^bind 127.0.0.1.*$/bind 127.0.0.1 $SWARM_IP/" "$REDIS_CONF"
    fi
    $SUDO sed -i 's/^protected-mode yes/protected-mode no/' "$REDIS_CONF"
    $SUDO systemctl enable redis-server
    $SUDO systemctl restart redis-server
    echo "  Redis escuchando en: $(ss -tlnp 2>/dev/null | grep 6379 | awk '{print $4}' | tr '\n' ' ')"
fi

echo "[5/7] Descargando asis-coder..."
INSTALL_DIR="$HOME/.local/asis-coder"
if [ -d "$INSTALL_DIR/.git" ]; then
    (cd "$INSTALL_DIR" && git fetch --all -q && git checkout -q "$BRANCH" && git pull -q)
else
    rm -rf "$INSTALL_DIR"
    git clone -q -b "$BRANCH" "$REPO_URL" "$INSTALL_DIR"
fi
chmod +x "$INSTALL_DIR/coder.sh"
mkdir -p "$HOME/.local/bin"
ln -sf "$INSTALL_DIR/coder.sh" "$HOME/.local/bin/coder"
if ! echo "$PATH" | grep -q "$HOME/.local/bin"; then
    echo 'export PATH="$HOME/.local/bin:$PATH"' >> "$HOME/.bashrc"
fi
export PATH="$HOME/.local/bin:$PATH"

echo "[6/7] Inicializando rol parent..."
bash "$INSTALL_DIR/coder.sh" swarm init --role parent --ip "$SWARM_IP" 2>&1 | grep -v "^DEBUG"

echo "[7/7] Configurando systemd para el enrollment listener..."
SERVICE_FILE="/etc/systemd/system/asis-coder-enroll.service"
$SUDO tee "$SERVICE_FILE" >/dev/null <<EOF
[Unit]
Description=Asis-Coder Swarm Enrollment Listener (parent)
After=redis-server.service network-online.target
Wants=network-online.target redis-server.service

[Service]
Type=simple
User=$USER
Environment=HOME=$HOME
Environment=PATH=$HOME/.local/bin:/usr/local/bin:/usr/bin:/bin
ExecStart=$HOME/.local/bin/coder swarm enroll listen
Restart=always
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF

$SUDO systemctl daemon-reload
$SUDO systemctl enable asis-coder-enroll.service
$SUDO systemctl restart asis-coder-enroll.service

sleep 1
TOKEN="$(jq -r '.token' "$HOME/.config/coder-cli/swarm/role.json" 2>/dev/null)"

echo
echo "════════════════════════════════════════"
echo "  ✔ PARENT LISTO"
echo "════════════════════════════════════════"
echo "  IP:       $SWARM_IP"
echo "  Token:    $TOKEN"
echo "  Listener: $($SUDO systemctl is-active asis-coder-enroll.service 2>/dev/null)"
echo
echo "Para enrolar dispositivos hijo (Raspberries), ejecuta EN CADA UNO:"
echo
echo "  curl -fsSL ${REPO_URL%.git}/raw/${BRANCH}/bootstrap-child.sh | \\"
echo "      bash -s -- --parent $SWARM_IP --token $TOKEN"
echo
echo "O desde este parent (SSH masivo):"
echo "  coder swarm bootstrap children 192.168.50.10 192.168.50.11 ... --user pi"
echo "════════════════════════════════════════"
