#!/bin/bash

# ==========================================
# ASIS-CODER BOOTSTRAP CHILD
# ==========================================
# Instala asis-coder completo en un dispositivo hijo (Raspberry, etc).
# Un solo comando, sin intervención manual.
#
# Uso (directo desde GitHub):
#   curl -fsSL https://raw.githubusercontent.com/johnolven/asis-coder/main/bootstrap-child.sh \
#       | bash -s -- --parent 192.168.50.1 --token <token> [--name <n>]
#
# O con asis-coder ya presente en el parent, se despliega con:
#   coder swarm bootstrap children 192.168.50.10 --user pi

set -e

PARENT_IP=""
TOKEN=""
NAME=""
BRANCH="main"
REPO_URL="https://github.com/johnolven/asis-coder.git"

while [ $# -gt 0 ]; do
    case "$1" in
        --parent) PARENT_IP="$2"; shift 2 ;;
        --token)  TOKEN="$2"; shift 2 ;;
        --name)   NAME="$2"; shift 2 ;;
        --branch) BRANCH="$2"; shift 2 ;;
        --repo)   REPO_URL="$2"; shift 2 ;;
        *) echo "Argumento desconocido: $1"; exit 1 ;;
    esac
done

if [ -z "$PARENT_IP" ] || [ -z "$TOKEN" ]; then
    echo "Uso: $0 --parent <ip> --token <t> [--name <n>] [--branch <b>] [--repo <url>]"
    exit 1
fi

[ -z "$NAME" ] && NAME="$(hostname)"

echo "════════════════════════════════════════"
echo "  ASIS-CODER BOOTSTRAP CHILD"
echo "════════════════════════════════════════"
echo "  Child name:  $NAME"
echo "  Parent:      $PARENT_IP"
echo "  Repo:        $REPO_URL ($BRANCH)"
echo "════════════════════════════════════════"
echo

need_sudo() {
    if [ "$EUID" -eq 0 ]; then SUDO=""
    elif command -v sudo >/dev/null; then SUDO="sudo"
    else echo "ERROR: se requiere sudo"; exit 1
    fi
}
need_sudo

echo "[1/6] Instalando dependencias del sistema..."
if command -v apt-get >/dev/null; then
    $SUDO apt-get update -qq
    $SUDO DEBIAN_FRONTEND=noninteractive apt-get install -y -qq \
        curl git tmux jq redis-tools openssh-client build-essential ca-certificates
elif command -v yum >/dev/null; then
    $SUDO yum install -y -q curl git tmux jq redis openssh-clients
elif command -v pacman >/dev/null; then
    $SUDO pacman -S --noconfirm curl git tmux jq redis openssh
else
    echo "Gestor de paquetes no soportado. Instala manualmente: curl git tmux jq redis-tools"
    exit 1
fi

echo "[2/6] Instalando Node.js si no existe..."
if ! command -v node >/dev/null; then
    curl -fsSL https://deb.nodesource.com/setup_20.x | $SUDO -E bash -
    $SUDO apt-get install -y -qq nodejs
fi
echo "  node: $(node --version)"
echo "  npm:  $(npm --version)"

echo "[3/6] Instalando Claude CLI si no existe..."
if ! command -v claude >/dev/null; then
    $SUDO npm install -g @anthropic-ai/claude-code 2>&1 | tail -3 || \
        npm install -g @anthropic-ai/claude-code 2>&1 | tail -3
fi
echo "  claude: $(command -v claude || echo 'NO INSTALADO - revisar permisos npm')"

echo "[4/6] Descargando asis-coder..."
INSTALL_DIR="$HOME/.local/asis-coder"
if [ -d "$INSTALL_DIR/.git" ]; then
    (cd "$INSTALL_DIR" && git fetch --all -q && git checkout -q "$BRANCH" && git pull -q)
else
    rm -rf "$INSTALL_DIR"
    git clone -q -b "$BRANCH" "$REPO_URL" "$INSTALL_DIR"
fi
chmod +x "$INSTALL_DIR/coder.sh"

# Symlink en PATH
mkdir -p "$HOME/.local/bin"
ln -sf "$INSTALL_DIR/coder.sh" "$HOME/.local/bin/coder"

# Asegurar PATH
if ! echo "$PATH" | grep -q "$HOME/.local/bin"; then
    echo 'export PATH="$HOME/.local/bin:$PATH"' >> "$HOME/.bashrc"
fi
export PATH="$HOME/.local/bin:$PATH"

echo "[5/6] Inicializando rol child y enrolando..."
bash "$INSTALL_DIR/coder.sh" swarm init --role child \
    --parent "$PARENT_IP" --token "$TOKEN" --name "$NAME" 2>&1 | grep -v "^DEBUG"

echo "[6/6] Configurando systemd para daemon persistente..."
SERVICE_FILE="/etc/systemd/system/asis-coder-daemon.service"
$SUDO tee "$SERVICE_FILE" >/dev/null <<EOF
[Unit]
Description=Asis-Coder Swarm Daemon (child worker)
After=network-online.target
Wants=network-online.target

[Service]
Type=simple
User=$USER
Environment=HOME=$HOME
Environment=PATH=$HOME/.local/bin:/usr/local/bin:/usr/bin:/bin
ExecStart=$HOME/.local/bin/coder swarm daemon start --foreground
Restart=always
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF

$SUDO systemctl daemon-reload
$SUDO systemctl enable asis-coder-daemon.service
$SUDO systemctl restart asis-coder-daemon.service

sleep 2
echo
echo "════════════════════════════════════════"
if $SUDO systemctl is-active --quiet asis-coder-daemon.service; then
    echo "  ✔ BOOTSTRAP COMPLETADO"
    echo "════════════════════════════════════════"
    echo "  Child:     $NAME ($(hostname -I | awk '{print $1}'))"
    echo "  Parent:    $PARENT_IP"
    echo "  Daemon:    activo (systemd)"
    echo
    echo "  En el parent puedes verificar con:"
    echo "    coder swarm device list"
    echo "    coder swarm run <project> <agent> 'echo hola'"
else
    echo "  ⚠ BOOTSTRAP COMPLETADO CON ADVERTENCIAS"
    echo "════════════════════════════════════════"
    echo "  El daemon no está activo. Revisa:"
    echo "    $SUDO systemctl status asis-coder-daemon.service"
    echo "    journalctl -u asis-coder-daemon.service -n 50"
fi
echo "════════════════════════════════════════"
