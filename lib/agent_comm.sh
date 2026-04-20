#!/bin/bash

# ==========================================
# MÓDULO AGENT COMM - agent_comm.sh
# ==========================================
# Comunicación entre agentes vía Redis (corriendo en la AGX como broker).
# Protocolo simple:
#   - Canal por proyecto:     asis:<project>:events
#   - Inbox por agente:       asis:<project>:inbox:<agent>
#   - Mensajes JSON: {from, to, type, payload, ts}

swarm_comm_help() {
    cat <<EOF
${SWARM_C_BOLD}coder swarm msg${SWARM_C_RESET}  -  comunicación entre agentes

  setup                                   Verificar/instalar Redis en AGX
  send <project> <from> <to> "<texto>"    Enviar mensaje (to='*' = broadcast)
  read <project> <agent>                  Leer inbox del agente
  listen <project> <agent>                Seguir inbox en vivo (bloquea)
  bus <project>                           Ver el canal de eventos del proyecto
EOF
}

swarm_comm_broker_host() {
    # IP de la AGX en la red del switch (gateway del swarm)
    echo "192.168.50.1"
}

swarm_comm_require_redis_cli() {
    if ! command -v redis-cli >/dev/null 2>&1; then
        swarm_error "redis-cli no está instalado. Instala: sudo apt-get install -y redis-tools"
        return 1
    fi
    return 0
}

swarm_comm_setup() {
    swarm_info "Configurando Redis broker en la AGX..."
    if ! command -v redis-server >/dev/null 2>&1; then
        swarm_warn "redis-server no está instalado."
        echo "Ejecuta en la AGX: sudo apt-get install -y redis-server redis-tools"
        return 1
    fi
    # Verificar que Redis escuche en 192.168.50.1 para que las Raspberries lo alcancen
    local bind_ok
    bind_ok="$(grep -E '^bind .*192\.168\.50\.1' /etc/redis/redis.conf 2>/dev/null)"
    if [ -z "$bind_ok" ]; then
        swarm_warn "Redis NO está configurado para escuchar en 192.168.50.1"
        echo "Edita /etc/redis/redis.conf:"
        echo "  bind 127.0.0.1 192.168.50.1"
        echo "  protected-mode no"
        echo "Luego: sudo systemctl restart redis-server"
    else
        swarm_ok "Redis configurado para la red del swarm."
    fi
    redis-cli -h "$(swarm_comm_broker_host)" ping 2>/dev/null \
        && swarm_ok "Broker Redis responde en $(swarm_comm_broker_host)" \
        || swarm_warn "Broker no responde aún."
}

swarm_comm_send() {
    local project="$1" from="$2" to="$3"; shift 3
    local text="$*"
    swarm_comm_require_redis_cli || return 1
    if [ -z "$project" ] || [ -z "$from" ] || [ -z "$to" ] || [ -z "$text" ]; then
        swarm_error "Uso: coder swarm msg send <project> <from> <to> \"<texto>\""
        return 1
    fi
    local host
    host="$(swarm_comm_broker_host)"
    local msg
    msg="$(jq -nc --arg p "$project" --arg f "$from" --arg t "$to" --arg x "$text" \
        '{project:$p, from:$f, to:$t, type:"text", payload:$x, ts:(now|todate)}')"
    # Evento en canal del proyecto
    redis-cli -h "$host" PUBLISH "asis:${project}:events" "$msg" >/dev/null
    # Inbox (si es broadcast, saltamos inbox individual)
    if [ "$to" != "*" ]; then
        redis-cli -h "$host" LPUSH "asis:${project}:inbox:${to}" "$msg" >/dev/null
        redis-cli -h "$host" LTRIM "asis:${project}:inbox:${to}" 0 999 >/dev/null
    fi
    swarm_ok "Mensaje enviado de '$from' a '$to' (proyecto $project)."
}

swarm_comm_read() {
    local project="$1" agent="$2"
    swarm_comm_require_redis_cli || return 1
    local host
    host="$(swarm_comm_broker_host)"
    local key="asis:${project}:inbox:${agent}"
    local count
    count="$(redis-cli -h "$host" LLEN "$key")"
    if [ "$count" = "0" ]; then
        swarm_info "Inbox de '$agent' vacío."
        return 0
    fi
    swarm_info "Inbox de '$agent' ($count mensajes):"
    redis-cli -h "$host" LRANGE "$key" 0 -1 | while read -r line; do
        echo "  $line" | jq -r '"  [\(.ts)] \(.from) → \(.to): \(.payload)"' 2>/dev/null || echo "  $line"
    done
}

swarm_comm_listen() {
    local project="$1" agent="$2"
    swarm_comm_require_redis_cli || return 1
    local host
    host="$(swarm_comm_broker_host)"
    swarm_info "Escuchando inbox de '$agent' (Ctrl+C para salir)..."
    while true; do
        local msg
        msg="$(redis-cli -h "$host" BRPOP "asis:${project}:inbox:${agent}" 0 2>/dev/null | tail -1)"
        [ -n "$msg" ] && echo "$msg" | jq -r '"[\(.ts)] \(.from) → \(.to): \(.payload)"' 2>/dev/null
    done
}

swarm_comm_bus() {
    local project="$1"
    swarm_comm_require_redis_cli || return 1
    local host
    host="$(swarm_comm_broker_host)"
    swarm_info "Canal 'asis:${project}:events' (Ctrl+C para salir)..."
    redis-cli -h "$host" SUBSCRIBE "asis:${project}:events"
}

swarm_comm_cmd() {
    local sub="$1"; shift
    case "$sub" in
        setup)  swarm_comm_setup ;;
        send)   swarm_comm_send "$@" ;;
        read)   swarm_comm_read "$@" ;;
        listen) swarm_comm_listen "$@" ;;
        bus)    swarm_comm_bus "$@" ;;
        ""|help|-h|--help) swarm_comm_help ;;
        *) swarm_error "Subcomando desconocido: $sub"; swarm_comm_help; return 1 ;;
    esac
}
