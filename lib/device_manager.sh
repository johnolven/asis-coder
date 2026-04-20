#!/bin/bash

# ==========================================
# MÓDULO DEVICE MANAGER - device_manager.sh
# ==========================================
# Gestiona el inventario de dispositivos físicos (AGX, Raspberries, otros)
# que forman el enjambre distribuido. Guarda en JSON y usa SSH para probarlos.

swarm_device_help() {
    cat <<EOF
${SWARM_C_BOLD}coder swarm device${SWARM_C_RESET}  -  gestión de dispositivos

  add <ip> --name <n> [--type rpi|agx|other] [--user <u>] [--port <p>]
  list
  show <name>
  remove <name>
  test <name>                Probar conectividad y detectar tools
  setup <name>               Instalar dependencias (claude-cli, tmux, git)
EOF
}

swarm_device_add() {
    local ip="$1"; shift
    local name="" type="other" user="$USER" port=22
    while [ $# -gt 0 ]; do
        case "$1" in
            --name)  name="$2"; shift 2 ;;
            --type)  type="$2"; shift 2 ;;
            --user)  user="$2"; shift 2 ;;
            --port)  port="$2"; shift 2 ;;
            *) swarm_error "Argumento desconocido: $1"; return 1 ;;
        esac
    done
    if [ -z "$ip" ] || [ -z "$name" ]; then
        swarm_error "Uso: coder swarm device add <ip> --name <nombre> [--type <tipo>] [--user <usuario>] [--port <puerto>]"
        return 1
    fi
    if swarm_device_exists "$name"; then
        swarm_error "Ya existe un device con nombre '$name'. Usa 'remove' primero o escoge otro nombre."
        return 1
    fi
    local tmp
    tmp="$(mktemp)"
    jq --arg name "$name" \
       --arg ip   "$ip"   \
       --arg type "$type" \
       --arg user "$user" \
       --arg port "$port" \
       '.devices += [{
            "name": $name,
            "ip": $ip,
            "type": $type,
            "user": $user,
            "port": ($port|tonumber),
            "added_at": (now|todate),
            "status": "unknown"
        }]' "$SWARM_DEVICES_FILE" > "$tmp" && mv "$tmp" "$SWARM_DEVICES_FILE"
    swarm_ok "Device '$name' agregado ($user@$ip:$port, tipo=$type)."
    swarm_info "Para probar: coder swarm device test $name"
}

swarm_device_list() {
    local count
    count="$(jq '.devices | length' "$SWARM_DEVICES_FILE")"
    if [ "$count" = "0" ]; then
        swarm_info "No hay devices registrados. Usa: coder swarm device add <ip> --name <n>"
        return 0
    fi
    printf "${SWARM_C_BOLD}%-12s %-16s %-8s %-20s %-10s${SWARM_C_RESET}\n" \
        "NAME" "IP" "TYPE" "USER@HOST" "STATUS"
    jq -r '.devices[] | [.name, .ip, .type, (.user+"@"+.ip+":"+(.port|tostring)), .status] | @tsv' \
        "$SWARM_DEVICES_FILE" \
        | while IFS=$'\t' read -r name ip type host status; do
            local color="$SWARM_C_GRAY"
            case "$status" in
                ok|online)  color="$SWARM_C_GREEN" ;;
                error|down) color="$SWARM_C_RED" ;;
                unknown)    color="$SWARM_C_YELLOW" ;;
            esac
            printf "%-12s %-16s %-8s %-20s ${color}%-10s${SWARM_C_RESET}\n" \
                "$name" "$ip" "$type" "$host" "$status"
        done
}

swarm_device_show() {
    local name="$1"
    if [ -z "$name" ] || ! swarm_device_exists "$name"; then
        swarm_error "Device '$name' no encontrado."
        return 1
    fi
    jq --arg n "$name" '.devices[] | select(.name==$n)' "$SWARM_DEVICES_FILE"
}

swarm_device_remove() {
    local name="$1"
    if [ -z "$name" ] || ! swarm_device_exists "$name"; then
        swarm_error "Device '$name' no encontrado."
        return 1
    fi
    local tmp
    tmp="$(mktemp)"
    jq --arg n "$name" '.devices |= map(select(.name != $n))' \
        "$SWARM_DEVICES_FILE" > "$tmp" && mv "$tmp" "$SWARM_DEVICES_FILE"
    swarm_ok "Device '$name' eliminado."
}

swarm_device_set_status() {
    local name="$1" status="$2"
    local tmp
    tmp="$(mktemp)"
    jq --arg n "$name" --arg s "$status" \
        '(.devices[] | select(.name==$n) | .status) = $s' \
        "$SWARM_DEVICES_FILE" > "$tmp" && mv "$tmp" "$SWARM_DEVICES_FILE"
}

swarm_device_test() {
    local name="$1"
    if [ -z "$name" ] || ! swarm_device_exists "$name"; then
        swarm_error "Device '$name' no encontrado."
        return 1
    fi
    local ip user port
    ip="$(swarm_device_field "$name" ip)"
    user="$(swarm_device_field "$name" user)"
    port="$(swarm_device_field "$name" port)"
    [ -z "$port" ] && port=22

    swarm_info "Probando conectividad con $user@$ip:$port ..."
    if ! ping -c1 -W2 "$ip" >/dev/null 2>&1; then
        swarm_error "Ping falló hacia $ip"
        swarm_device_set_status "$name" "down"
        return 1
    fi
    swarm_ok "Ping OK"

    local ssh_out
    ssh_out="$(ssh -o StrictHostKeyChecking=accept-new -o ConnectTimeout=5 \
        -o BatchMode=yes -p "$port" "${user}@${ip}" \
        'echo OK; uname -a; command -v claude >/dev/null && echo HAS_CLAUDE || echo NO_CLAUDE; command -v tmux >/dev/null && echo HAS_TMUX || echo NO_TMUX; command -v git >/dev/null && echo HAS_GIT || echo NO_GIT' 2>&1)"
    local rc=$?
    if [ $rc -ne 0 ]; then
        swarm_error "SSH falló. Configura tu llave con: ssh-copy-id -p $port ${user}@${ip}"
        echo "$ssh_out"
        swarm_device_set_status "$name" "error"
        return 1
    fi
    swarm_ok "SSH OK"
    echo "$ssh_out" | sed 's/^/    /'

    local has_claude has_tmux has_git
    has_claude="$(echo "$ssh_out" | grep -c '^HAS_CLAUDE$' || true)"
    has_tmux="$(echo "$ssh_out"   | grep -c '^HAS_TMUX$'   || true)"
    has_git="$(echo "$ssh_out"    | grep -c '^HAS_GIT$'    || true)"

    if [ "$has_claude" -gt 0 ] && [ "$has_tmux" -gt 0 ] && [ "$has_git" -gt 0 ]; then
        swarm_device_set_status "$name" "ok"
        swarm_ok "Device '$name' listo para el swarm."
    else
        swarm_device_set_status "$name" "online"
        swarm_warn "Faltan dependencias. Ejecuta: coder swarm device setup $name"
    fi
}

swarm_device_setup() {
    local name="$1"
    if [ -z "$name" ] || ! swarm_device_exists "$name"; then
        swarm_error "Device '$name' no encontrado."
        return 1
    fi
    swarm_info "Instalando dependencias en '$name' (requiere sudo en el device)..."
    swarm_ssh_cmd "$name" bash -s <<'REMOTE'
set -e
if command -v apt-get >/dev/null 2>&1; then
    sudo apt-get update -y
    sudo apt-get install -y git tmux curl jq
fi
if ! command -v node >/dev/null 2>&1; then
    curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash -
    sudo apt-get install -y nodejs
fi
if ! command -v claude >/dev/null 2>&1; then
    sudo npm install -g @anthropic-ai/claude-code || npm install -g @anthropic-ai/claude-code
fi
echo "---"
echo "node: $(node -v 2>/dev/null || echo missing)"
echo "claude: $(command -v claude || echo missing)"
echo "tmux: $(command -v tmux || echo missing)"
echo "git: $(command -v git || echo missing)"
REMOTE
    local rc=$?
    if [ $rc -eq 0 ]; then
        swarm_ok "Setup completado en '$name'."
        swarm_device_test "$name"
    else
        swarm_error "Setup falló. Revisa credenciales/sudo en el device."
    fi
}

swarm_device_cmd() {
    local sub="$1"; shift
    case "$sub" in
        add)     swarm_device_add "$@" ;;
        list|ls) swarm_device_list ;;
        show)    swarm_device_show "$@" ;;
        remove|rm) swarm_device_remove "$@" ;;
        test)    swarm_device_test "$@" ;;
        setup)   swarm_device_setup "$@" ;;
        ""|help|-h|--help) swarm_device_help ;;
        *) swarm_error "Subcomando desconocido: $sub"; swarm_device_help; return 1 ;;
    esac
}
