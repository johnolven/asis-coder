#!/bin/bash

# ==========================================
# MÓDULO SWARM MANAGER - swarm_manager.sh
# ==========================================
# Ejecución distribuida: lanza Claude CLI (o cualquier comando) dentro de tmux
# en cada device asignado a un agente. Permite start/stop/status/logs/attach.

swarm_manager_help() {
    cat <<EOF
${SWARM_C_BOLD}coder swarm${SWARM_C_RESET}  -  control de ejecución

  start <project> [agent]         Lanzar agentes (todos o uno específico)
  stop <project> [agent]          Detener agentes
  status [project]                Ver estado global o de un proyecto
  logs <project> <agent> [--follow]
  attach <project> <agent>        Conectarse a la tmux session del agente
  run <project> <agent> "<cmd>"   Ejecutar comando arbitrario en el worktree
EOF
}

swarm_session_name() {
    local project="$1" agent="$2"
    echo "asis-${project}-${agent}"
}

swarm_start_agent() {
    local project="$1" agent="$2"
    local pfile
    pfile="$(swarm_project_file "$project")"
    local device branch wt task
    device="$(jq -r --arg a "$agent" '.agents[] | select(.name==$a) | .device' "$pfile")"
    branch="$(jq -r --arg a "$agent" '.agents[] | select(.name==$a) | .branch' "$pfile")"
    wt="$(jq -r --arg a "$agent" '.agents[] | select(.name==$a) | .worktree' "$pfile")"
    task="$(jq -r --arg a "$agent" '.agents[] | select(.name==$a) | .task' "$pfile")"

    if [ -z "$wt" ] || [ "$wt" = "null" ] || [ "$wt" = "" ]; then
        swarm_warn "Agente '$agent' sin worktree. Creándolo..."
        swarm_wt_create "$project" "$agent" "$branch" || return 1
        wt="$(jq -r --arg a "$agent" '.agents[] | select(.name==$a) | .worktree' "$pfile")"
    fi

    local session
    session="$(swarm_session_name "$project" "$agent")"
    swarm_info "Lanzando '$agent' en '$device' (session=$session)"

    # Detectar si ya existe la sesión
    local exists
    exists="$(swarm_wt_run_on_device "$device" "tmux has-session -t '$session' 2>/dev/null && echo YES || echo NO")"
    if echo "$exists" | grep -q YES; then
        swarm_warn "Sesión '$session' ya existe en '$device'."
        return 0
    fi

    # Construir prompt inicial para Claude
    local prompt
    if [ -n "$task" ] && [ "$task" != "null" ] && [ "$task" != "" ]; then
        prompt="$task"
    else
        prompt="Estás trabajando en el branch $branch del proyecto $project. Espera instrucciones."
    fi

    # Escape para pasar por shell remoto
    local escaped_prompt
    escaped_prompt="$(printf '%q' "$prompt")"

    swarm_wt_run_on_device "$device" bash -lc "
        set -e
        cd \"$wt\"
        tmux new-session -d -s \"$session\" -c \"$wt\" \"claude --dangerously-skip-permissions $escaped_prompt; bash\"
    "
    if [ $? -eq 0 ]; then
        swarm_ok "Agente '$agent' corriendo en '$device' (tmux: $session)"
        local tmp
        tmp="$(mktemp)"
        jq --arg a "$agent" --arg s "$session" \
            '(.agents[] | select(.name==$a) | .status)  = "running"
           | (.agents[] | select(.name==$a) | .session) = $s' \
            "$pfile" > "$tmp" && mv "$tmp" "$pfile"
    else
        swarm_error "Falló el arranque de '$agent' en '$device'."
        return 1
    fi
}

swarm_start() {
    local project="$1" only_agent="$2"
    local pfile
    pfile="$(swarm_project_file "$project")"
    [ ! -f "$pfile" ] && { swarm_error "Proyecto '$project' no existe."; return 1; }
    if [ -n "$only_agent" ]; then
        swarm_start_agent "$project" "$only_agent"
        return $?
    fi
    local agents
    agents="$(jq -r '.agents[].name' "$pfile")"
    if [ -z "$agents" ]; then
        swarm_warn "Proyecto '$project' sin agentes."
        return 0
    fi
    while read -r a; do
        [ -z "$a" ] && continue
        swarm_start_agent "$project" "$a"
    done <<< "$agents"
}

swarm_stop_agent() {
    local project="$1" agent="$2"
    local pfile
    pfile="$(swarm_project_file "$project")"
    local device session
    device="$(jq -r --arg a "$agent" '.agents[] | select(.name==$a) | .device' "$pfile")"
    session="$(swarm_session_name "$project" "$agent")"
    swarm_info "Deteniendo '$agent' en '$device'..."
    swarm_wt_run_on_device "$device" "tmux kill-session -t '$session' 2>/dev/null || true"
    local tmp
    tmp="$(mktemp)"
    jq --arg a "$agent" \
        '(.agents[] | select(.name==$a) | .status) = "stopped"' \
        "$pfile" > "$tmp" && mv "$tmp" "$pfile"
    swarm_ok "Agente '$agent' detenido."
}

swarm_stop() {
    local project="$1" only_agent="$2"
    local pfile
    pfile="$(swarm_project_file "$project")"
    [ ! -f "$pfile" ] && { swarm_error "Proyecto '$project' no existe."; return 1; }
    if [ -n "$only_agent" ]; then
        swarm_stop_agent "$project" "$only_agent"
        return $?
    fi
    local agents
    agents="$(jq -r '.agents[].name' "$pfile")"
    while read -r a; do
        [ -z "$a" ] && continue
        swarm_stop_agent "$project" "$a"
    done <<< "$agents"
}

swarm_status() {
    local project="$1"
    if [ -n "$project" ]; then
        local pfile
        pfile="$(swarm_project_file "$project")"
        [ ! -f "$pfile" ] && { swarm_error "Proyecto '$project' no existe."; return 1; }
        echo -e "${SWARM_C_BOLD}Proyecto: $project${SWARM_C_RESET}"
        swarm_agent_list "$project"
        return 0
    fi
    for f in "$SWARM_PROJECTS_DIR"/*.json; do
        [ -e "$f" ] || continue
        local name
        name="$(jq -r '.name' "$f")"
        echo -e "${SWARM_C_BOLD}▸ Proyecto: $name${SWARM_C_RESET}"
        swarm_agent_list "$name"
        echo
    done
}

swarm_logs() {
    local project="$1" agent="$2" follow="$3"
    local pfile
    pfile="$(swarm_project_file "$project")"
    local device session
    device="$(jq -r --arg a "$agent" '.agents[] | select(.name==$a) | .device' "$pfile")"
    session="$(swarm_session_name "$project" "$agent")"

    if [ "$follow" = "--follow" ] || [ "$follow" = "-f" ]; then
        swarm_info "Siguiendo logs de '$agent' en '$device' (Ctrl+C para salir)..."
        swarm_wt_run_on_device "$device" "tmux pipe-pane -o -t '$session' 'cat >> /tmp/${session}.log'; tail -f /tmp/${session}.log"
    else
        swarm_wt_run_on_device "$device" "tmux capture-pane -p -t '$session' 2>/dev/null | tail -100"
    fi
}

swarm_attach() {
    local project="$1" agent="$2"
    local pfile
    pfile="$(swarm_project_file "$project")"
    local device session ip user port
    device="$(jq -r --arg a "$agent" '.agents[] | select(.name==$a) | .device' "$pfile")"
    session="$(swarm_session_name "$project" "$agent")"
    ip="$(swarm_device_field "$device" ip)"
    user="$(swarm_device_field "$device" user)"
    port="$(swarm_device_field "$device" port)"
    [ -z "$port" ] && port=22

    local my_ip
    my_ip="$(hostname -I 2>/dev/null | awk '{print $1}')"
    if [ "$ip" = "127.0.0.1" ] || [ "$ip" = "$my_ip" ]; then
        tmux attach -t "$session"
    else
        swarm_info "Abriendo tmux remoto en ${user}@${ip}:${port} (session=$session)"
        ssh -t -p "$port" "${user}@${ip}" "tmux attach -t '$session'"
    fi
}

swarm_run() {
    local project="$1" agent="$2"; shift 2
    local cmd="$*"
    local pfile
    pfile="$(swarm_project_file "$project")"
    local device wt
    device="$(jq -r --arg a "$agent" '.agents[] | select(.name==$a) | .device' "$pfile")"
    wt="$(jq -r --arg a "$agent" '.agents[] | select(.name==$a) | .worktree' "$pfile")"
    swarm_info "Ejecutando en $device:$wt > $cmd"
    swarm_wt_run_on_device "$device" "cd \"$wt\" && $cmd"
}
