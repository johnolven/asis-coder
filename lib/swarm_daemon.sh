#!/bin/bash

# ==========================================
# MÓDULO SWARM DAEMON - swarm_daemon.sh
# ==========================================
# Daemon worker que corre en un device 'child'.
# Escucha Redis en el parent y ejecuta comandos que llegan a su inbox.
#
# Protocolo:
#   - Inbox del worker: asis:worker:<name>
#   - Parent LPUSH comando, daemon BRPOP
#   - Comando JSON: {id, type, payload}
#   - Tipos:
#       ping                      → responde ack
#       shell                     → ejecuta bash y devuelve output
#       worktree_create           → crea git worktree
#       claude_start              → lanza claude en tmux
#       claude_stop               → mata tmux session
#       status                    → info del worker
#   - Respuesta en asis:ack:<id>  con {status, output}

SWARM_DAEMON_PID_FILE="$SWARM_DIR/daemon.pid"
SWARM_DAEMON_LOG="$SWARM_LOG_DIR/daemon.log"

swarm_daemon_help() {
    cat <<EOF
${SWARM_C_BOLD}coder swarm daemon${SWARM_C_RESET}  -  modo worker (solo en child)

  start [--foreground]   Inicia el daemon worker
  stop                   Detiene el daemon
  status                 Estado del daemon
  logs [--follow]        Ver logs del daemon
EOF
}

swarm_daemon_require_child() {
    if [ ! -f "$SWARM_ROLE_FILE" ]; then
        swarm_error "Este device no tiene rol. Ejecuta 'coder swarm init --role child ...'"
        return 1
    fi
    if [ "$(swarm_role_get)" != "child" ]; then
        swarm_error "El daemon solo corre en devices 'child'."
        return 1
    fi
    return 0
}

swarm_daemon_send_ack() {
    local redis_host="$1" id="$2" status="$3" output="$4"
    local ack
    ack="$(jq -nc --arg s "$status" --arg o "$output" --arg id "$id" \
        '{id:$id, status:$s, output:$o, ts:(now|todate)}')"
    redis-cli -h "$redis_host" LPUSH "asis:ack:${id}" "$ack" >/dev/null 2>&1
}

swarm_daemon_handle_cmd() {
    local redis_host="$1" name="$2" msg="$3"
    local id type payload
    id="$(echo "$msg" | jq -r '.id')"
    type="$(echo "$msg" | jq -r '.type')"
    payload="$(echo "$msg" | jq -r '.payload // empty')"
    local output="" status="ok"
    echo "[$(date '+%F %T')] CMD id=$id type=$type" >> "$SWARM_DAEMON_LOG"

    case "$type" in
        ping)
            output="pong from $name ($(hostname)) at $(date)"
            ;;
        status)
            output="$(jq -c '{role, name, ip, capabilities}' "$SWARM_ROLE_FILE")"
            ;;
        shell)
            output="$(bash -c "$payload" 2>&1)" || status="err"
            ;;
        worktree_create)
            local repo branch dir project
            repo="$(echo "$payload"    | jq -r '.repo')"
            branch="$(echo "$payload"  | jq -r '.branch')"
            dir="$(echo "$payload"     | jq -r '.dir')"
            project="$(echo "$payload" | jq -r '.project')"
            local base="$HOME/asis-swarm/$project"
            output="$(
                set -e
                mkdir -p "$base"
                if [ ! -d "$base/main" ]; then
                    git clone "$repo" "$base/main"
                else
                    (cd "$base/main" && git fetch --all --prune)
                fi
                cd "$base/main"
                if git show-ref --verify --quiet "refs/heads/$branch"; then
                    git worktree add "$dir" "$branch" 2>&1 || git worktree add "$dir" "$branch" -f 2>&1
                else
                    git worktree add -b "$branch" "$dir" 2>&1
                fi
                echo "WORKTREE_OK $dir"
            2>&1)" || status="err"
            ;;
        claude_start)
            local session wt task
            session="$(echo "$payload" | jq -r '.session')"
            wt="$(echo "$payload"      | jq -r '.worktree')"
            task="$(echo "$payload"    | jq -r '.task')"
            if tmux has-session -t "$session" 2>/dev/null; then
                output="session already running: $session"
            else
                local esc
                esc="$(printf '%q' "$task")"
                tmux new-session -d -s "$session" -c "$wt" \
                    "claude --dangerously-skip-permissions $esc; bash" 2>&1
                output="started session $session in $wt"
            fi
            ;;
        claude_stop)
            local session
            session="$(echo "$payload" | jq -r '.session')"
            tmux kill-session -t "$session" 2>&1
            output="stopped session $session"
            ;;
        claude_logs)
            local session
            session="$(echo "$payload" | jq -r '.session')"
            output="$(tmux capture-pane -p -t "$session" 2>&1 | tail -100)"
            ;;
        *)
            status="err"
            output="unknown cmd type: $type"
            ;;
    esac

    swarm_daemon_send_ack "$redis_host" "$id" "$status" "$output"
    echo "[$(date '+%F %T')] ACK id=$id status=$status" >> "$SWARM_DAEMON_LOG"
}

swarm_daemon_loop() {
    swarm_daemon_require_child || return 1
    local redis_host name inbox
    redis_host="$(jq -r '.redis_host' "$SWARM_ROLE_FILE")"
    name="$(jq -r '.name' "$SWARM_ROLE_FILE")"
    inbox="asis:worker:${name}"
    echo "[$(date '+%F %T')] daemon start (name=$name, inbox=$inbox, redis=$redis_host)" >> "$SWARM_DAEMON_LOG"

    # Publicar heartbeat inicial
    redis-cli -h "$redis_host" SET "asis:worker:${name}:heartbeat" "$(date -u +%s)" EX 120 >/dev/null 2>&1

    while true; do
        # Heartbeat cada ciclo (refresca TTL)
        redis-cli -h "$redis_host" SET "asis:worker:${name}:heartbeat" "$(date -u +%s)" EX 120 >/dev/null 2>&1
        local line payload
        line="$(redis-cli -h "$redis_host" BRPOP "$inbox" 30 2>/dev/null)"
        [ -z "$line" ] && continue
        payload="$(echo "$line" | tail -1)"
        [ -z "$payload" ] && continue
        swarm_daemon_handle_cmd "$redis_host" "$name" "$payload" &
    done
}

swarm_daemon_start() {
    swarm_daemon_require_child || return 1
    local foreground=false
    [ "$1" = "--foreground" ] || [ "$1" = "-f" ] && foreground=true

    if [ -f "$SWARM_DAEMON_PID_FILE" ]; then
        local pid
        pid="$(cat "$SWARM_DAEMON_PID_FILE")"
        if kill -0 "$pid" 2>/dev/null; then
            swarm_warn "Daemon ya corriendo (pid=$pid)"
            return 0
        fi
    fi

    if $foreground; then
        swarm_info "Iniciando daemon en foreground..."
        swarm_daemon_loop
    else
        mkdir -p "$SWARM_LOG_DIR"
        nohup bash -c "
            source '$SCRIPT_DIR/lib/swarm_common.sh'
            source '$SCRIPT_DIR/lib/swarm_role.sh'
            source '$SCRIPT_DIR/lib/swarm_daemon.sh'
            swarm_init_dirs
            swarm_daemon_loop
        " >>"$SWARM_DAEMON_LOG" 2>&1 &
        local pid=$!
        echo "$pid" > "$SWARM_DAEMON_PID_FILE"
        swarm_ok "Daemon iniciado (pid=$pid). Logs: $SWARM_DAEMON_LOG"
    fi
}

swarm_daemon_stop() {
    if [ ! -f "$SWARM_DAEMON_PID_FILE" ]; then
        swarm_warn "No hay daemon corriendo (no pid file)"
        return 0
    fi
    local pid
    pid="$(cat "$SWARM_DAEMON_PID_FILE")"
    if kill "$pid" 2>/dev/null; then
        swarm_ok "Daemon detenido (pid=$pid)"
    else
        swarm_warn "Proceso $pid no existe"
    fi
    rm -f "$SWARM_DAEMON_PID_FILE"
}

swarm_daemon_status() {
    if [ ! -f "$SWARM_DAEMON_PID_FILE" ]; then
        echo "daemon: stopped"
        return 0
    fi
    local pid
    pid="$(cat "$SWARM_DAEMON_PID_FILE")"
    if kill -0 "$pid" 2>/dev/null; then
        echo -e "daemon: ${SWARM_C_GREEN}running${SWARM_C_RESET} (pid=$pid)"
    else
        echo -e "daemon: ${SWARM_C_RED}dead${SWARM_C_RESET} (stale pid=$pid)"
    fi
}

swarm_daemon_logs() {
    [ ! -f "$SWARM_DAEMON_LOG" ] && { swarm_info "Sin logs aún."; return 0; }
    if [ "$1" = "--follow" ] || [ "$1" = "-f" ]; then
        tail -f "$SWARM_DAEMON_LOG"
    else
        tail -100 "$SWARM_DAEMON_LOG"
    fi
}

swarm_daemon_cmd() {
    local sub="$1"; shift || true
    case "$sub" in
        start)   swarm_daemon_start "$@" ;;
        stop)    swarm_daemon_stop ;;
        status)  swarm_daemon_status ;;
        logs)    swarm_daemon_logs "$@" ;;
        ""|help|-h|--help) swarm_daemon_help ;;
        *) swarm_error "Subcomando desconocido: $sub"; swarm_daemon_help; return 1 ;;
    esac
}
