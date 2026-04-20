#!/bin/bash

# ==========================================
# MÓDULO SWARM BOOTSTRAP - swarm_bootstrap.sh
# ==========================================
# Despliegue masivo de children desde el parent vía SSH.
# Copia bootstrap-child.sh a cada IP dada y lo ejecuta con el token del parent.

swarm_bootstrap_help() {
    cat <<EOF
${SWARM_C_BOLD}coder swarm bootstrap${SWARM_C_RESET}  -  despliegue automatizado

  parent                                  Bootstrap de este device como parent
                                          (corre bootstrap-parent.sh)

  children <ip1> [ip2] ... [opciones]     SSH masivo a cada IP y ejecuta
                                          bootstrap-child.sh con el token actual

Opciones para 'children':
  --user <u>          Usuario SSH (default: pi)
  --port <p>          Puerto SSH (default: 22)
  --branch <b>        Branch del repo a instalar (default: main)
  --repo <url>        URL del repo (default: el oficial)
  --name-prefix <p>   Prefijo para autonombrar (rb → rb001, rb002...)

Ejemplos:
  coder swarm bootstrap parent
  coder swarm bootstrap children 192.168.50.10 192.168.50.11 192.168.50.12 --user pi
EOF
}

swarm_bootstrap_parent() {
    local script_path
    script_path="$(dirname "$LIB_DIR")/bootstrap-parent.sh"
    if [ ! -f "$script_path" ]; then
        swarm_error "bootstrap-parent.sh no encontrado en $script_path"
        return 1
    fi
    bash "$script_path" "$@"
}

swarm_bootstrap_children() {
    if [ "$(swarm_role_get)" != "parent" ]; then
        swarm_error "Este comando solo corre en el parent. Ejecuta antes: coder swarm init --role parent"
        return 1
    fi

    local ips=()
    local user="pi" port=22 branch="main"
    local repo_url="https://github.com/johnolven/asis-coder.git"
    local name_prefix=""

    while [ $# -gt 0 ]; do
        case "$1" in
            --user)        user="$2"; shift 2 ;;
            --port)        port="$2"; shift 2 ;;
            --branch)      branch="$2"; shift 2 ;;
            --repo)        repo_url="$2"; shift 2 ;;
            --name-prefix) name_prefix="$2"; shift 2 ;;
            -*) swarm_error "Argumento desconocido: $1"; return 1 ;;
            *)  ips+=("$1"); shift ;;
        esac
    done

    if [ ${#ips[@]} -eq 0 ]; then
        swarm_error "Debes dar al menos una IP."
        swarm_bootstrap_help
        return 1
    fi

    local parent_ip token bootstrap_path
    parent_ip="$(jq -r '.ip' "$SWARM_ROLE_FILE")"
    token="$(jq -r '.token' "$SWARM_ROLE_FILE")"
    bootstrap_path="$(dirname "$LIB_DIR")/bootstrap-child.sh"

    if [ ! -f "$bootstrap_path" ]; then
        swarm_error "bootstrap-child.sh no encontrado en $bootstrap_path"
        return 1
    fi

    swarm_info "Desplegando a ${#ips[@]} children (parent=$parent_ip, user=$user)"

    local idx=1 ok=0 fail=0
    for ip in "${ips[@]}"; do
        local child_name
        if [ -n "$name_prefix" ]; then
            child_name="$(printf '%s%03d' "$name_prefix" "$idx")"
        else
            child_name=""  # que el hijo use su hostname
        fi

        echo
        swarm_info "[$idx/${#ips[@]}] Desplegando en $user@$ip (name=${child_name:-<hostname>})"

        # 1) Copiar bootstrap al child
        if ! scp -o StrictHostKeyChecking=accept-new -o ConnectTimeout=10 \
              -P "$port" "$bootstrap_path" "${user}@${ip}:/tmp/bootstrap-child.sh" 2>&1; then
            swarm_error "SCP falló hacia $ip. Verifica SSH (ssh-copy-id $user@$ip)"
            fail=$((fail+1)); idx=$((idx+1)); continue
        fi

        # 2) Ejecutar
        local name_arg=""
        [ -n "$child_name" ] && name_arg="--name $child_name"

        if ssh -o StrictHostKeyChecking=accept-new -o ConnectTimeout=10 \
              -p "$port" "${user}@${ip}" \
              "chmod +x /tmp/bootstrap-child.sh && bash /tmp/bootstrap-child.sh \
                --parent $parent_ip --token $token --branch $branch --repo $repo_url $name_arg"; then
            swarm_ok "[$idx/${#ips[@]}] $ip listo"
            ok=$((ok+1))
        else
            swarm_error "[$idx/${#ips[@]}] $ip falló"
            fail=$((fail+1))
        fi
        idx=$((idx+1))
    done

    echo
    echo "════════════════════════════════════════"
    echo "  Bootstrap resumen: ${ok} OK, ${fail} FALLIDOS"
    echo "════════════════════════════════════════"
    swarm_info "Verifica con: coder swarm device list"
    swarm_info "Procesa enrolamientos pendientes: coder swarm enroll process"
}

swarm_bootstrap_cmd() {
    local sub="$1"; shift || true
    case "$sub" in
        parent)   swarm_bootstrap_parent "$@" ;;
        children) swarm_bootstrap_children "$@" ;;
        ""|help|-h|--help) swarm_bootstrap_help ;;
        *) swarm_error "Subcomando desconocido: $sub"; swarm_bootstrap_help; return 1 ;;
    esac
}
