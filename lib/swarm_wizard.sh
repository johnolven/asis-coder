#!/bin/bash

# ==========================================
# MÓDULO SWARM WIZARD - swarm_wizard.sh
# ==========================================
# Interfaz interactiva para configurar el swarm:
# - Elige rol (parent/child)
# - Instala dependencias
# - Configura Redis (parent)
# - Enrola automáticamente (child)
# - Despliega a Raspberries (parent → children) sin comandos manuales

swarm_wizard_help() {
    cat <<EOF
${SWARM_C_BOLD}coder swarm wizard${SWARM_C_RESET}  -  configuración interactiva

Pregunta qué rol tiene este dispositivo y configura todo automáticamente.
EOF
}

_wiz_title() {
    echo
    echo -e "${SWARM_C_BOLD}════════════════════════════════════════${SWARM_C_RESET}"
    echo -e "${SWARM_C_BOLD}  $1${SWARM_C_RESET}"
    echo -e "${SWARM_C_BOLD}════════════════════════════════════════${SWARM_C_RESET}"
}

_wiz_prompt() {
    local msg="$1" default="$2" ans=""
    if [ -n "$default" ]; then
        read -p "$(echo -e "${SWARM_C_CYAN}?${SWARM_C_RESET} $msg [$default]: ")" ans
        ans="${ans:-$default}"
    else
        read -p "$(echo -e "${SWARM_C_CYAN}?${SWARM_C_RESET} $msg: ")" ans
    fi
    echo "$ans"
}

_wiz_prompt_secret() {
    local msg="$1" ans=""
    read -s -p "$(echo -e "${SWARM_C_CYAN}?${SWARM_C_RESET} $msg: ")" ans
    echo
    echo "$ans"
}

_wiz_confirm() {
    local msg="$1" default="${2:-Y}" ans=""
    local hint="[Y/n]"
    [ "$default" = "N" ] && hint="[y/N]"
    read -p "$(echo -e "${SWARM_C_YELLOW}?${SWARM_C_RESET} $msg $hint: ")" ans
    ans="${ans:-$default}"
    [[ "$ans" =~ ^[Yy] ]]
}

_wiz_menu() {
    local title="$1"; shift
    local options=("$@")
    echo >&2
    echo -e "${SWARM_C_BOLD}$title${SWARM_C_RESET}" >&2
    local i=1
    for opt in "${options[@]}"; do
        echo -e "  ${SWARM_C_CYAN}$i)${SWARM_C_RESET} $opt" >&2
        i=$((i+1))
    done
    local choice
    read -p "$(echo -e "${SWARM_C_CYAN}?${SWARM_C_RESET} Opción: ")" choice >&2
    echo "$choice"
}

# ---------- Parent wizard ----------
_wiz_parent() {
    _wiz_title "CONFIGURAR COMO PARENT"
    echo "Este dispositivo será el orquestador del swarm (broker Redis)."
    echo

    local default_ip
    default_ip="$(ip -4 addr show 2>/dev/null | grep -oE '192\.168\.50\.[0-9]+' | head -1)"
    [ -z "$default_ip" ] && default_ip="$(hostname -I | awk '{print $1}')"
    local swarm_ip
    swarm_ip="$(_wiz_prompt "IP para el swarm" "$default_ip")"

    # 1. Dependencias
    echo
    swarm_info "Verificando dependencias..."
    local missing=()
    for cmd in jq tmux redis-server redis-cli git ssh; do
        command -v "$cmd" >/dev/null 2>&1 || missing+=("$cmd")
    done
    if [ ${#missing[@]} -gt 0 ]; then
        swarm_warn "Faltan: ${missing[*]}"
        if _wiz_confirm "¿Instalar con apt-get?"; then
            sudo apt-get update -qq
            sudo DEBIAN_FRONTEND=noninteractive apt-get install -y -qq \
                curl git tmux jq redis-server redis-tools openssh-client sshpass
        else
            swarm_error "No se puede continuar sin dependencias."
            return 1
        fi
    fi

    # 2. Configurar Redis
    echo
    swarm_info "Configurando Redis para escuchar en $swarm_ip..."
    local redis_conf="/etc/redis/redis.conf"
    if [ -f "$redis_conf" ]; then
        if ! sudo grep -qE "^bind .*${swarm_ip}" "$redis_conf"; then
            sudo sed -i "s/^bind 127.0.0.1.*$/bind 127.0.0.1 $swarm_ip/" "$redis_conf"
        fi
        sudo sed -i 's/^protected-mode yes/protected-mode no/' "$redis_conf"
        sudo systemctl enable redis-server >/dev/null 2>&1
        sudo systemctl restart redis-server
        if redis-cli -h "$swarm_ip" ping 2>/dev/null | grep -q PONG; then
            swarm_ok "Redis escuchando en $swarm_ip:6379"
        else
            swarm_error "Redis no responde en $swarm_ip"
            return 1
        fi
    fi

    # 3. Init rol parent
    echo
    swarm_info "Inicializando rol parent..."
    swarm_role_init_parent "$swarm_ip"

    # 4. Systemd unit para enrollment listener
    echo
    if _wiz_confirm "¿Configurar enrollment listener como servicio systemd?"; then
        local service_file="/etc/systemd/system/asis-coder-enroll.service"
        local bin_path
        bin_path="$(command -v coder || echo "$HOME/.local/bin/coder")"
        [ ! -x "$bin_path" ] && bin_path="$SCRIPT_DIR/coder.sh"

        sudo tee "$service_file" >/dev/null <<EOF
[Unit]
Description=Asis-Coder Swarm Enrollment Listener
After=redis-server.service network-online.target
Wants=network-online.target redis-server.service

[Service]
Type=simple
User=$USER
Environment=HOME=$HOME
Environment=PATH=$HOME/.local/bin:/usr/local/bin:/usr/bin:/bin
ExecStart=$bin_path swarm enroll listen
Restart=always
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF
        sudo systemctl daemon-reload
        sudo systemctl enable asis-coder-enroll.service >/dev/null 2>&1
        sudo systemctl restart asis-coder-enroll.service
        sleep 1
        if systemctl is-active --quiet asis-coder-enroll.service; then
            swarm_ok "Listener activo (asis-coder-enroll.service)"
        else
            swarm_warn "Listener no arrancó. Revisa: journalctl -u asis-coder-enroll.service"
        fi
    fi

    # 5. Deploy a children (opcional)
    echo
    if _wiz_confirm "¿Desplegar a dispositivos hijo ahora?"; then
        _wiz_deploy_children
    fi

    _wiz_title "PARENT LISTO"
    local token
    token="$(jq -r '.token' "$SWARM_ROLE_FILE")"
    echo "  IP:     $swarm_ip"
    echo "  Token:  $token"
    echo
    echo "Para agregar más children después:"
    echo "  coder swarm wizard"
    echo "  → opción 'Agregar child al swarm existente'"
    echo
}

_wiz_deploy_children() {
    _wiz_title "DESPLEGAR A CHILDREN"

    local default_user="pi"
    local user
    user="$(_wiz_prompt "Usuario SSH en las Raspberries" "$default_user")"

    echo
    echo "Ingresa las IPs de los hijos, separadas por espacio."
    echo "Ejemplo: 192.168.50.10 192.168.50.11 192.168.50.12"
    local ips_line
    ips_line="$(_wiz_prompt "IPs" "")"
    if [ -z "$ips_line" ]; then
        swarm_warn "Sin IPs. Saltando deploy."
        return 0
    fi

    read -ra ips <<< "$ips_line"

    # ¿SSH ya configurado?
    echo
    local needs_keys=false
    for ip in "${ips[@]}"; do
        if ! ssh -o BatchMode=yes -o ConnectTimeout=3 -o StrictHostKeyChecking=accept-new \
              "${user}@${ip}" 'echo ok' >/dev/null 2>&1; then
            needs_keys=true
            break
        fi
    done

    local password=""
    if $needs_keys; then
        swarm_warn "SSH sin llaves. Necesito la contraseña de '$user' para configurar acceso."
        if ! command -v sshpass >/dev/null 2>&1; then
            swarm_info "Instalando sshpass..."
            sudo apt-get install -y -qq sshpass
        fi
        password="$(_wiz_prompt_secret "Contraseña de $user")"

        # Generar llave si no existe
        if [ ! -f "$HOME/.ssh/id_ed25519" ] && [ ! -f "$HOME/.ssh/id_rsa" ]; then
            swarm_info "Generando llave SSH..."
            ssh-keygen -t ed25519 -N "" -f "$HOME/.ssh/id_ed25519" -q
        fi

        echo
        swarm_info "Copiando llave a cada child..."
        for ip in "${ips[@]}"; do
            echo -n "  → ${user}@${ip}: "
            if sshpass -p "$password" ssh-copy-id -o StrictHostKeyChecking=accept-new \
                "${user}@${ip}" >/dev/null 2>&1; then
                echo -e "${SWARM_C_GREEN}ok${SWARM_C_RESET}"
            else
                echo -e "${SWARM_C_RED}falló${SWARM_C_RESET}"
            fi
        done
    fi

    # Desplegar con bootstrap-child
    echo
    swarm_info "Desplegando asis-coder + daemon en cada child..."
    swarm_bootstrap_children "${ips[@]}" --user "$user"

    # Procesar enrolamientos
    echo
    swarm_info "Procesando enrolamientos pendientes..."
    sleep 2
    swarm_enroll_process

    echo
    swarm_info "Estado final:"
    swarm_device_list
}

# ---------- Child wizard ----------
_wiz_child() {
    _wiz_title "CONFIGURAR COMO CHILD"
    echo "Este dispositivo se registrará en un parent existente."
    echo

    local parent_ip token name
    parent_ip="$(_wiz_prompt "IP del parent" "192.168.50.1")"
    token="$(_wiz_prompt "Token de enrolamiento" "")"
    if [ -z "$token" ]; then
        swarm_error "El token es obligatorio. Obténlo en el parent con: coder swarm role"
        return 1
    fi
    name="$(_wiz_prompt "Nombre de este child" "$(hostname)")"

    # Dependencias
    echo
    swarm_info "Verificando dependencias..."
    local missing=()
    for cmd in jq tmux redis-cli git; do
        command -v "$cmd" >/dev/null 2>&1 || missing+=("$cmd")
    done
    if ! command -v claude >/dev/null 2>&1; then
        missing+=("claude")
    fi
    if [ ${#missing[@]} -gt 0 ]; then
        swarm_warn "Faltan: ${missing[*]}"
        if _wiz_confirm "¿Instalar ahora?"; then
            sudo apt-get update -qq
            sudo DEBIAN_FRONTEND=noninteractive apt-get install -y -qq \
                curl git tmux jq redis-tools build-essential
            if ! command -v node >/dev/null; then
                curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash -
                sudo apt-get install -y -qq nodejs
            fi
            if ! command -v claude >/dev/null; then
                sudo npm install -g @anthropic-ai/claude-code || \
                    npm install -g @anthropic-ai/claude-code
            fi
        else
            return 1
        fi
    fi

    # Init rol child
    echo
    swarm_info "Inicializando como child y enrolando..."
    swarm_role_init_child --parent "$parent_ip" --token "$token" --name "$name"

    # Systemd daemon
    echo
    if _wiz_confirm "¿Arrancar daemon como servicio systemd?"; then
        local service_file="/etc/systemd/system/asis-coder-daemon.service"
        local bin_path
        bin_path="$(command -v coder || echo "$HOME/.local/bin/coder")"
        [ ! -x "$bin_path" ] && bin_path="$SCRIPT_DIR/coder.sh"

        sudo tee "$service_file" >/dev/null <<EOF
[Unit]
Description=Asis-Coder Swarm Daemon (child worker)
After=network-online.target
Wants=network-online.target

[Service]
Type=simple
User=$USER
Environment=HOME=$HOME
Environment=PATH=$HOME/.local/bin:/usr/local/bin:/usr/bin:/bin
ExecStart=$bin_path swarm daemon start --foreground
Restart=always
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF
        sudo systemctl daemon-reload
        sudo systemctl enable asis-coder-daemon.service >/dev/null 2>&1
        sudo systemctl restart asis-coder-daemon.service
        sleep 1
        if systemctl is-active --quiet asis-coder-daemon.service; then
            swarm_ok "Daemon activo"
        else
            swarm_warn "Daemon no arrancó. Revisa: journalctl -u asis-coder-daemon.service"
        fi
    else
        swarm_info "Iniciando daemon en background..."
        swarm_daemon_start
    fi

    _wiz_title "CHILD LISTO"
    echo "  Nombre:   $name"
    echo "  Parent:   $parent_ip"
    echo
    echo "En el parent, ejecuta 'coder swarm device list' para verlo."
}

# ---------- Entry point ----------
swarm_wizard_run() {
    clear 2>/dev/null || true
    echo -e "${SWARM_C_BOLD}"
    cat <<'EOF'
   ___      _      _____          __
  / _ |___ (_)__  / ___/__  ___/ ___/___
 / __ / _ \/ (_-< / /__/ _ \/ _  / -_) __/
/_/ |_\___/_/___/ \___/\___/\_,_/\__/_/

   Swarm Wizard
EOF
    echo -e "${SWARM_C_RESET}"
    echo "Configuración interactiva del enjambre distribuido."

    local current_role
    current_role="$(swarm_role_get)"
    if [ -n "$current_role" ]; then
        echo
        swarm_warn "Este dispositivo ya tiene rol: $current_role"

        if [ "$current_role" = "parent" ]; then
            local choice
            choice="$(_wiz_menu "¿Qué deseas hacer?" \
                "Desplegar a dispositivos hijo (children)" \
                "Reconfigurar este dispositivo" \
                "Cancelar")"

            case "$choice" in
                1) _wiz_deploy_children; return 0 ;;
                2) ;; # continuar a reconfiguración
                *) swarm_info "Cancelado."; return 0 ;;
            esac
        else
            if ! _wiz_confirm "¿Continuar y reconfigurar?" "N"; then
                exit 0
            fi
        fi
    fi

    local choice
    choice="$(_wiz_menu "¿Qué rol tendrá este dispositivo?" \
        "PARENT (orquestador, un device único en el swarm)" \
        "CHILD (worker que se conecta a un parent existente)" \
        "Cancelar")"

    case "$choice" in
        1) _wiz_parent ;;
        2) _wiz_child  ;;
        *) swarm_info "Cancelado." ;;
    esac
}
