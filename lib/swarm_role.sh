#!/bin/bash

# ==========================================
# MÓDULO SWARM ROLE - swarm_role.sh
# ==========================================
# Gestiona el rol de este dispositivo dentro del swarm:
#   - parent: orquestador con Redis broker local
#   - child:  worker que se conecta al parent vía Redis
# Guarda configuración en $SWARM_DIR/role.json

SWARM_ROLE_FILE="$SWARM_DIR/role.json"

swarm_role_help() {
    cat <<EOF
${SWARM_C_BOLD}coder swarm init${SWARM_C_RESET}  -  inicializar rol del dispositivo

  coder swarm init --role parent [--ip <ip>]
       Configura este dispositivo como ORQUESTADOR.
       Redis broker debe estar en este host.

  coder swarm init --role child --parent <ip> --token <t> [--name <n>]
       Configura este dispositivo como WORKER.
       Se auto-registra en el parent.

  coder swarm role          Muestra el rol actual
  coder swarm role reset    Borra la configuración de rol
EOF
}

swarm_role_get() {
    [ ! -f "$SWARM_ROLE_FILE" ] && { echo ""; return; }
    jq -r '.role // empty' "$SWARM_ROLE_FILE" 2>/dev/null
}

swarm_role_show() {
    if [ ! -f "$SWARM_ROLE_FILE" ] || [ -z "$(swarm_role_get)" ]; then
        swarm_warn "Este dispositivo no tiene rol configurado."
        echo "Ejecuta: coder swarm init --role parent | child"
        return 1
    fi
    echo -e "${SWARM_C_BOLD}Rol de este dispositivo:${SWARM_C_RESET}"
    jq . "$SWARM_ROLE_FILE"
}

swarm_role_reset() {
    if [ -f "$SWARM_ROLE_FILE" ]; then
        rm "$SWARM_ROLE_FILE"
        swarm_ok "Configuración de rol eliminada."
    fi
}

swarm_role_detect_ip() {
    # Intenta detectar la IP principal del host en la red del swarm (192.168.50.x)
    local ip
    ip="$(ip -4 addr show 2>/dev/null | grep -oE '192\.168\.50\.[0-9]+' | head -1)"
    if [ -z "$ip" ]; then
        ip="$(hostname -I 2>/dev/null | awk '{print $1}')"
    fi
    echo "$ip"
}

swarm_role_generate_token() {
    if command -v openssl >/dev/null 2>&1; then
        openssl rand -hex 16
    else
        head -c 16 /dev/urandom | xxd -p | tr -d '\n'
    fi
}

swarm_role_init_parent() {
    local ip="$1"
    [ -z "$ip" ] && ip="$(swarm_role_detect_ip)"
    local token
    if [ -f "$SWARM_ROLE_FILE" ] && [ "$(swarm_role_get)" = "parent" ]; then
        token="$(jq -r '.token' "$SWARM_ROLE_FILE")"
        swarm_info "Parent ya configurado, reusando token."
    else
        token="$(swarm_role_generate_token)"
    fi
    local hostname
    hostname="$(hostname)"
    jq -n --arg role parent \
          --arg ip "$ip" \
          --arg token "$token" \
          --arg host "$hostname" \
        '{
            role: $role,
            ip: $ip,
            hostname: $host,
            redis_host: $ip,
            token: $token,
            initialized_at: (now|todate)
        }' > "$SWARM_ROLE_FILE"
    swarm_ok "Dispositivo configurado como ${SWARM_C_BOLD}PARENT${SWARM_C_RESET}"
    echo
    echo -e "${SWARM_C_BOLD}Datos de enrolamiento (compártelos con los hijos):${SWARM_C_RESET}"
    echo "  IP del parent:  $ip"
    echo "  Token:          $token"
    echo
    echo "En cada dispositivo hijo, ejecuta:"
    echo -e "  ${SWARM_C_CYAN}coder swarm init --role child --parent $ip --token $token${SWARM_C_RESET}"
    echo
    # Verificar Redis
    if ! command -v redis-server >/dev/null 2>&1; then
        swarm_warn "Redis NO está instalado en este parent. Instala: sudo apt-get install -y redis-server redis-tools"
    else
        if ! grep -qE "^bind .*${ip}" /etc/redis/redis.conf 2>/dev/null; then
            swarm_warn "Redis no está configurado para aceptar conexiones desde la red del swarm."
            echo "En /etc/redis/redis.conf asegúrate de tener:"
            echo "  bind 127.0.0.1 $ip"
            echo "  protected-mode no"
            echo "Luego: sudo systemctl restart redis-server"
        else
            swarm_ok "Redis configurado para la red del swarm."
        fi
    fi
}

swarm_role_init_child() {
    local parent_ip="" token="" name=""
    while [ $# -gt 0 ]; do
        case "$1" in
            --parent) parent_ip="$2"; shift 2 ;;
            --token)  token="$2"; shift 2 ;;
            --name)   name="$2"; shift 2 ;;
            *) swarm_error "Argumento desconocido: $1"; return 1 ;;
        esac
    done
    if [ -z "$parent_ip" ] || [ -z "$token" ]; then
        swarm_error "Uso: coder swarm init --role child --parent <ip> --token <t> [--name <n>]"
        return 1
    fi
    [ -z "$name" ] && name="$(hostname)"
    local my_ip
    my_ip="$(swarm_role_detect_ip)"

    # Probar conectividad Redis con el parent
    if ! command -v redis-cli >/dev/null 2>&1; then
        swarm_error "redis-cli no está instalado. Instala: sudo apt-get install -y redis-tools"
        return 1
    fi
    if ! redis-cli -h "$parent_ip" -t 3 ping 2>/dev/null | grep -q PONG; then
        swarm_error "No se puede alcanzar Redis en $parent_ip:6379"
        echo "Verifica que el parent esté encendido y Redis acepte conexiones."
        return 1
    fi

    # Detectar capacidades
    local has_claude has_tmux has_node
    has_claude="$(command -v claude >/dev/null && echo true || echo false)"
    has_tmux="$(command -v tmux   >/dev/null && echo true || echo false)"
    has_node="$(command -v node   >/dev/null && echo true || echo false)"
    local kernel arch
    kernel="$(uname -s)"
    arch="$(uname -m)"

    # Guardar rol local
    jq -n --arg name "$name" \
          --arg parent "$parent_ip" \
          --arg ip "$my_ip" \
          --arg token "$token" \
          --arg host "$(hostname)" \
          --arg kernel "$kernel" \
          --arg arch "$arch" \
          --argjson has_claude "$has_claude" \
          --argjson has_tmux "$has_tmux" \
          --argjson has_node "$has_node" \
        '{
            role: "child",
            name: $name,
            ip: $ip,
            hostname: $host,
            parent_ip: $parent,
            redis_host: $parent,
            token: $token,
            capabilities: {
                claude: $has_claude,
                tmux:   $has_tmux,
                node:   $has_node,
                kernel: $kernel,
                arch:   $arch
            },
            initialized_at: (now|todate),
            enrolled: false
        }' > "$SWARM_ROLE_FILE"
    swarm_ok "Dispositivo configurado como ${SWARM_C_BOLD}CHILD${SWARM_C_RESET} '${name}'"
    swarm_info "Enviando enrolamiento al parent ($parent_ip)..."
    swarm_enroll_register
}

swarm_role_init() {
    local role="" ip="" parent="" token="" name=""
    # Leer args hasta encontrar --role
    local args=("$@")
    local i=0
    while [ $i -lt ${#args[@]} ]; do
        case "${args[$i]}" in
            --role) role="${args[$((i+1))]}"; i=$((i+2)) ;;
            --ip)   ip="${args[$((i+1))]}"; i=$((i+2)) ;;
            *) i=$((i+1)) ;;
        esac
    done
    case "$role" in
        parent) swarm_role_init_parent "$ip" ;;
        child)  swarm_role_init_child "$@" ;;
        "")     swarm_role_help ;;
        *)      swarm_error "Rol desconocido: $role (usa parent|child)"; return 1 ;;
    esac
}

swarm_role_cmd() {
    local sub="$1"; shift || true
    case "$sub" in
        ""|show) swarm_role_show ;;
        reset)   swarm_role_reset ;;
        *)       swarm_error "Subcomando desconocido: $sub"; swarm_role_help; return 1 ;;
    esac
}
