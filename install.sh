#!/bin/bash

set -e

# Colores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Función para imprimir mensajes con color
print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Detectar sistema operativo
detect_os() {
    if [[ "$OSTYPE" == "linux-gnu"* ]]; then
        OS="linux"
        if command -v apt-get >/dev/null 2>&1; then
            DISTRO="debian"
        elif command -v yum >/dev/null 2>&1; then
            DISTRO="rhel"
        elif command -v pacman >/dev/null 2>&1; then
            DISTRO="arch"
        fi
    elif [[ "$OSTYPE" == "darwin"* ]]; then
        OS="macos"
    else
        print_error "Sistema operativo no soportado: $OSTYPE"
        exit 1
    fi
}

# Instalar dependencias según el sistema
install_dependencies() {
    print_status "Verificando e instalando dependencias base..."

    local missing=()
    for cmd in curl jq git ssh tmux; do
        command -v "$cmd" >/dev/null 2>&1 || missing+=("$cmd")
    done

    if [ ${#missing[@]} -gt 0 ]; then
        print_status "Instalando dependencias faltantes: ${missing[*]}"
        case "$OS" in
            "linux")
                case "$DISTRO" in
                    "debian")
                        sudo apt-get update && sudo apt-get install -y curl jq file git openssh-client tmux
                        ;;
                    "rhel")
                        sudo yum install -y curl jq file git openssh-clients tmux
                        ;;
                    "arch")
                        sudo pacman -S --noconfirm curl jq file git openssh tmux
                        ;;
                esac
                ;;
            "macos")
                if command -v brew >/dev/null 2>&1; then
                    brew install curl jq git tmux
                else
                    print_error "Homebrew no está instalado. Instala manualmente: curl, jq, git, tmux"
                    exit 1
                fi
                ;;
        esac
    fi
    print_success "Dependencias base verificadas"
}

install_swarm_extras() {
    print_status "Verificando dependencias opcionales para swarm..."

    if ! command -v redis-server >/dev/null 2>&1; then
        print_warning "redis-server no encontrado (opcional, para comunicación entre agentes)"
        read -p "  Instalar Redis? [y/N] " answer
        if [[ "$answer" =~ ^[Yy] ]]; then
            case "$OS" in
                "linux")
                    case "$DISTRO" in
                        "debian") sudo apt-get install -y redis-server redis-tools ;;
                        "rhel")   sudo yum install -y redis ;;
                        "arch")   sudo pacman -S --noconfirm redis ;;
                    esac
                    ;;
                "macos") brew install redis ;;
            esac
        fi
    else
        print_success "Redis instalado"
    fi

    if ! command -v claude >/dev/null 2>&1; then
        print_warning "claude CLI no encontrado (necesario para los agentes)"
        print_status "Instala con: npm install -g @anthropic-ai/claude-code"
    else
        print_success "Claude CLI instalado"
    fi
}

# Obtener la ruta absoluta del directorio del proyecto
PROJECT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
BIN_DIR="$HOME/.local/bin"
CONFIG_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/coder-cli"

print_status "Iniciando instalación de Asis-coder..."

# Detectar sistema operativo
detect_os
print_status "Sistema detectado: $OS"

# Instalar dependencias
install_dependencies
install_swarm_extras

# Crear directorios necesarios
print_status "Creando directorios..."
mkdir -p "$BIN_DIR"
mkdir -p "$CONFIG_DIR"

# Crear un enlace simbólico en $BIN_DIR
print_status "Creando enlace simbólico..."
ln -sf "$PROJECT_DIR/coder.sh" "$BIN_DIR/coder"

# Hacer el script ejecutable
chmod +x "$PROJECT_DIR/coder.sh"

# Agregar al PATH si no está
if [[ ":$PATH:" != *":$BIN_DIR:"* ]]; then
    print_status "Agregando $BIN_DIR al PATH..."
    
    # Detectar shell y agregar al archivo apropiado
    if [ -n "$ZSH_VERSION" ]; then
        echo 'export PATH="$HOME/.local/bin:$PATH"' >> "$HOME/.zshrc"
        print_status "PATH agregado a .zshrc"
    elif [ -n "$BASH_VERSION" ]; then
        echo 'export PATH="$HOME/.local/bin:$PATH"' >> "$HOME/.bashrc"
        print_status "PATH agregado a .bashrc"
    fi
    
    export PATH="$BIN_DIR:$PATH"
fi

print_success "Asis-coder se ha instalado correctamente!"
print_status "Ubicación: $BIN_DIR/coder -> $PROJECT_DIR/coder.sh"
print_status ""
print_status "Para empezar a usar:"
print_status "  1. Reinicia tu terminal o ejecuta: source ~/.bashrc (o ~/.zshrc)"
print_status "  2. Ve a tu proyecto: cd /ruta/a/tu/proyecto"
print_status "  3. Ejecuta: coder -contexto"
print_status "  4. Haz tu primera consulta: coder \"explica este proyecto\""
print_status ""
print_status "Swarm (orquestación distribuida):"
print_status "  1. coder swarm init"
print_status "  2. coder swarm device add <ip> --name <n> --type rpi --user pi"
print_status "  3. coder swarm device setup <n>    (instala dependencias en el device)"
print_status "  4. coder swarm project create <p> --repo <url>"
print_status "  5. coder swarm agent add <p> <a> --device <n> --branch <b> --task \"...\""
print_status "  6. coder swarm start <p>"
print_status "  7. coder swarm doctor              (diagnóstico completo)"
print_status ""
print_warning "Nota: Necesitarás configurar tu API key de OpenAI o Anthropic en el primer uso"
