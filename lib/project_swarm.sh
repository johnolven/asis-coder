#!/bin/bash

# ==========================================
# MÓDULO PROJECT SWARM - project_swarm.sh
# ==========================================
# Proyectos distribuidos y asignación de agentes a devices.
# Un proyecto = JSON en $SWARM_PROJECTS_DIR/<project>.json con repo + lista de agentes.

swarm_project_help() {
    cat <<EOF
${SWARM_C_BOLD}coder swarm project${SWARM_C_RESET}  -  gestión de proyectos

  create <name> --repo <url>        Crear proyecto
  list                              Listar proyectos
  show <name>                       Ver detalles y agentes
  remove <name>                     Eliminar proyecto (no borra worktrees)

${SWARM_C_BOLD}coder swarm agent${SWARM_C_RESET}  -  agentes dentro de un proyecto

  add <project> <agent-name> --device <d> --branch <b> [--task "<texto>"]
  list <project>
  remove <project> <agent-name>
  task <project> <agent-name> "<nueva tarea>"
EOF
}

swarm_project_create() {
    local name="$1"; shift
    local repo=""
    while [ $# -gt 0 ]; do
        case "$1" in
            --repo) repo="$2"; shift 2 ;;
            *) swarm_error "Argumento desconocido: $1"; return 1 ;;
        esac
    done
    if [ -z "$name" ] || [ -z "$repo" ]; then
        swarm_error "Uso: coder swarm project create <nombre> --repo <url-git>"
        return 1
    fi
    if swarm_project_exists "$name"; then
        swarm_error "Proyecto '$name' ya existe."
        return 1
    fi
    local pfile
    pfile="$(swarm_project_file "$name")"
    jq -n --arg name "$name" --arg repo "$repo" \
        '{name:$name, repo:$repo, created_at:(now|todate), agents:[]}' > "$pfile"
    swarm_ok "Proyecto '$name' creado."
    swarm_info "Agrega agentes: coder swarm agent add $name <agent> --device <d> --branch <b>"
}

swarm_project_list() {
    local any=0
    for f in "$SWARM_PROJECTS_DIR"/*.json; do
        [ -e "$f" ] || continue
        any=1
        local name repo agents
        name="$(jq -r '.name' "$f")"
        repo="$(jq -r '.repo' "$f")"
        agents="$(jq '.agents | length' "$f")"
        printf "  ${SWARM_C_BOLD}%-15s${SWARM_C_RESET} agents=%-3s repo=%s\n" "$name" "$agents" "$repo"
    done
    [ $any -eq 0 ] && swarm_info "No hay proyectos. Crea uno: coder swarm project create <n> --repo <url>"
}

swarm_project_show() {
    local name="$1"
    local pfile
    pfile="$(swarm_project_file "$name")"
    if [ ! -f "$pfile" ]; then
        swarm_error "Proyecto '$name' no existe."; return 1
    fi
    jq . "$pfile"
}

swarm_project_remove() {
    local name="$1"
    local pfile
    pfile="$(swarm_project_file "$name")"
    [ ! -f "$pfile" ] && { swarm_error "Proyecto '$name' no existe."; return 1; }
    rm "$pfile"
    swarm_ok "Proyecto '$name' eliminado (worktrees quedan en los devices)."
}

swarm_agent_add() {
    local project="$1" agent="$2"; shift 2
    local device="" branch="" task=""
    while [ $# -gt 0 ]; do
        case "$1" in
            --device) device="$2"; shift 2 ;;
            --branch) branch="$2"; shift 2 ;;
            --task)   task="$2"; shift 2 ;;
            *) swarm_error "Argumento desconocido: $1"; return 1 ;;
        esac
    done
    if [ -z "$project" ] || [ -z "$agent" ] || [ -z "$device" ] || [ -z "$branch" ]; then
        swarm_error "Uso: coder swarm agent add <project> <agent> --device <d> --branch <b> [--task \"...\"]"
        return 1
    fi
    local pfile
    pfile="$(swarm_project_file "$project")"
    [ ! -f "$pfile" ] && { swarm_error "Proyecto '$project' no existe."; return 1; }
    if ! swarm_device_exists "$device"; then
        swarm_error "Device '$device' no existe. Regístralo con: coder swarm device add"
        return 1
    fi
    local exists
    exists="$(jq -r --arg a "$agent" '.agents[] | select(.name==$a) | .name' "$pfile")"
    if [ -n "$exists" ]; then
        swarm_error "Agente '$agent' ya existe en '$project'."
        return 1
    fi
    local tmp
    tmp="$(mktemp)"
    jq --arg a "$agent" --arg d "$device" --arg b "$branch" --arg t "$task" \
       '.agents += [{
            name:$a, device:$d, branch:$b, task:$t,
            worktree:"", status:"idle", pid:0, session:"",
            created_at:(now|todate)
        }]' "$pfile" > "$tmp" && mv "$tmp" "$pfile"
    swarm_ok "Agente '$agent' asignado a device '$device' (branch=$branch)."
    swarm_info "Crea su worktree: coder swarm worktree create $project $agent $branch"
}

swarm_agent_list() {
    local project="$1"
    local pfile
    pfile="$(swarm_project_file "$project")"
    [ ! -f "$pfile" ] && { swarm_error "Proyecto '$project' no existe."; return 1; }
    local count
    count="$(jq '.agents | length' "$pfile")"
    if [ "$count" = "0" ]; then
        swarm_info "Proyecto '$project' sin agentes."
        return 0
    fi
    printf "${SWARM_C_BOLD}%-15s %-10s %-20s %-8s %s${SWARM_C_RESET}\n" \
        "AGENT" "DEVICE" "BRANCH" "STATUS" "TASK"
    jq -r '.agents[] | [.name, .device, .branch, .status, .task] | @tsv' "$pfile" \
        | while IFS=$'\t' read -r a d b s t; do
            printf "%-15s %-10s %-20s %-8s %s\n" "$a" "$d" "$b" "$s" "$t"
        done
}

swarm_agent_remove() {
    local project="$1" agent="$2"
    local pfile
    pfile="$(swarm_project_file "$project")"
    [ ! -f "$pfile" ] && { swarm_error "Proyecto '$project' no existe."; return 1; }
    local tmp
    tmp="$(mktemp)"
    jq --arg a "$agent" '.agents |= map(select(.name != $a))' "$pfile" > "$tmp" && mv "$tmp" "$pfile"
    swarm_ok "Agente '$agent' removido."
}

swarm_agent_task() {
    local project="$1" agent="$2"; shift 2
    local task="$*"
    local pfile
    pfile="$(swarm_project_file "$project")"
    [ ! -f "$pfile" ] && { swarm_error "Proyecto '$project' no existe."; return 1; }
    local tmp
    tmp="$(mktemp)"
    jq --arg a "$agent" --arg t "$task" \
        '(.agents[] | select(.name==$a) | .task) = $t' \
        "$pfile" > "$tmp" && mv "$tmp" "$pfile"
    swarm_ok "Tarea del agente '$agent' actualizada."
}

swarm_project_cmd() {
    local sub="$1"; shift
    case "$sub" in
        create) swarm_project_create "$@" ;;
        list|ls) swarm_project_list ;;
        show)   swarm_project_show "$@" ;;
        remove|rm) swarm_project_remove "$@" ;;
        ""|help|-h|--help) swarm_project_help ;;
        *) swarm_error "Subcomando desconocido: $sub"; swarm_project_help; return 1 ;;
    esac
}

swarm_agent_cmd() {
    local sub="$1"; shift
    case "$sub" in
        add)    swarm_agent_add "$@" ;;
        list|ls) swarm_agent_list "$@" ;;
        remove|rm) swarm_agent_remove "$@" ;;
        task)   swarm_agent_task "$@" ;;
        ""|help|-h|--help) swarm_project_help ;;
        *) swarm_error "Subcomando desconocido: $sub"; swarm_project_help; return 1 ;;
    esac
}
