#!/bin/bash

# ==========================================
# MÓDULO COMÚN SWARM - swarm_common.sh
# ==========================================
# Utilidades compartidas por todos los módulos swarm:
# paths, helpers JSON, colores, logging, validaciones.

SWARM_DIR="$CONFIG_DIR/swarm"
SWARM_DEVICES_FILE="$SWARM_DIR/devices.json"
SWARM_PROJECTS_DIR="$SWARM_DIR/projects"
SWARM_LOG_DIR="$SWARM_DIR/logs"
SWARM_SSH_KEY="$HOME/.ssh/asis_swarm_ed25519"

# Colores
SWARM_C_RESET='\033[0m'
SWARM_C_BOLD='\033[1m'
SWARM_C_RED='\033[0;31m'
SWARM_C_GREEN='\033[0;32m'
SWARM_C_YELLOW='\033[1;33m'
SWARM_C_BLUE='\033[0;34m'
SWARM_C_CYAN='\033[0;36m'
SWARM_C_GRAY='\033[0;90m'

swarm_init_dirs() {
    mkdir -p "$SWARM_DIR" "$SWARM_PROJECTS_DIR" "$SWARM_LOG_DIR"
    if [ ! -f "$SWARM_DEVICES_FILE" ]; then
        echo '{"devices": []}' > "$SWARM_DEVICES_FILE"
    fi
}

swarm_require_jq() {
    if ! command -v jq >/dev/null 2>&1; then
        echo -e "${SWARM_C_RED}Error:${SWARM_C_RESET} jq no está instalado."
        echo "Instálalo con: sudo apt-get install -y jq"
        return 1
    fi
    return 0
}

swarm_require_ssh() {
    if ! command -v ssh >/dev/null 2>&1; then
        echo -e "${SWARM_C_RED}Error:${SWARM_C_RESET} ssh no está instalado."
        return 1
    fi
    return 0
}

swarm_log() {
    local level="$1"; shift
    local msg="$*"
    local ts
    ts="$(date '+%Y-%m-%d %H:%M:%S')"
    mkdir -p "$SWARM_LOG_DIR"
    echo "[$ts] [$level] $msg" >> "$SWARM_LOG_DIR/swarm.log"
}

swarm_info()    { echo -e "${SWARM_C_CYAN}ℹ${SWARM_C_RESET} $*"; swarm_log INFO "$*"; }
swarm_ok()      { echo -e "${SWARM_C_GREEN}✔${SWARM_C_RESET} $*"; swarm_log OK "$*"; }
swarm_warn()    { echo -e "${SWARM_C_YELLOW}⚠${SWARM_C_RESET} $*"; swarm_log WARN "$*"; }
swarm_error()   { echo -e "${SWARM_C_RED}✖${SWARM_C_RESET} $*"; swarm_log ERROR "$*"; }

swarm_device_get() {
    local name="$1"
    jq -r --arg n "$name" '.devices[] | select(.name==$n)' "$SWARM_DEVICES_FILE"
}

swarm_device_field() {
    local name="$1" field="$2"
    jq -r --arg n "$name" --arg f "$field" '.devices[] | select(.name==$n) | .[$f] // empty' "$SWARM_DEVICES_FILE"
}

swarm_device_exists() {
    local name="$1"
    local found
    found="$(jq -r --arg n "$name" '.devices[] | select(.name==$n) | .name' "$SWARM_DEVICES_FILE")"
    [ -n "$found" ]
}

swarm_ssh_cmd() {
    local name="$1"; shift
    local ip user port
    ip="$(swarm_device_field "$name" ip)"
    user="$(swarm_device_field "$name" user)"
    port="$(swarm_device_field "$name" port)"
    [ -z "$port" ] && port=22
    if [ -z "$ip" ] || [ -z "$user" ]; then
        swarm_error "Device '$name' no encontrado o sin ip/usuario."
        return 1
    fi
    ssh -o StrictHostKeyChecking=accept-new -o ConnectTimeout=5 \
        -p "$port" "${user}@${ip}" "$@"
}

swarm_scp_cmd() {
    local name="$1" src="$2" dst="$3"
    local ip user port
    ip="$(swarm_device_field "$name" ip)"
    user="$(swarm_device_field "$name" user)"
    port="$(swarm_device_field "$name" port)"
    [ -z "$port" ] && port=22
    scp -o StrictHostKeyChecking=accept-new -o ConnectTimeout=5 \
        -P "$port" "$src" "${user}@${ip}:${dst}"
}

swarm_project_file() {
    local project="$1"
    echo "$SWARM_PROJECTS_DIR/${project}.json"
}

swarm_project_exists() {
    local project="$1"
    [ -f "$(swarm_project_file "$project")" ]
}
