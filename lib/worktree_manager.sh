#!/bin/bash

# ==========================================
# MÓDULO WORKTREE MANAGER - worktree_manager.sh
# ==========================================
# Wrapper sobre `git worktree` para crear áreas de trabajo paralelas por agente.
# Funciona tanto local como remoto (vía SSH al device asignado).

swarm_worktree_help() {
    cat <<EOF
${SWARM_C_BOLD}coder swarm worktree${SWARM_C_RESET}  -  gestión de git worktrees

  create <project> <agent> <branch>   Crear worktree para un agente
  list <project>                      Listar worktrees del proyecto
  remove <project> <agent>            Eliminar worktree de un agente
EOF
}

# Ejecuta un comando git o shell dentro del device del agente.
# Si el device es local (127.0.0.1 o el host actual) corre directo.
swarm_wt_run_on_device() {
    local device="$1"; shift
    local ip
    ip="$(swarm_device_field "$device" ip)"
    if [ -z "$ip" ]; then
        swarm_error "Device '$device' no existe."
        return 1
    fi
    local my_ip
    my_ip="$(hostname -I 2>/dev/null | awk '{print $1}')"
    if [ "$ip" = "127.0.0.1" ] || [ "$ip" = "$my_ip" ]; then
        bash -c "$*"
    else
        swarm_ssh_cmd "$device" "$@"
    fi
}

swarm_wt_base_dir() {
    local project="$1" device="$2"
    local remote_base
    remote_base="$(swarm_device_field "$device" workdir)"
    [ -z "$remote_base" ] && remote_base='$HOME/asis-swarm'
    echo "${remote_base}/${project}"
}

# Clona el repo en el device si aún no existe
swarm_wt_ensure_repo() {
    local project="$1" device="$2" repo_url="$3"
    local base
    base="$(swarm_wt_base_dir "$project" "$device")"
    swarm_wt_run_on_device "$device" bash -lc "
        set -e
        mkdir -p \"$base\"
        if [ ! -d \"$base/main\" ]; then
            git clone \"$repo_url\" \"$base/main\"
        else
            cd \"$base/main\" && git fetch --all --prune
        fi
    "
}

swarm_wt_create() {
    local project="$1" agent="$2" branch="$3"
    if [ -z "$project" ] || [ -z "$agent" ] || [ -z "$branch" ]; then
        swarm_error "Uso: coder swarm worktree create <project> <agent> <branch>"
        return 1
    fi
    local pfile
    pfile="$(swarm_project_file "$project")"
    if [ ! -f "$pfile" ]; then
        swarm_error "Proyecto '$project' no existe."
        return 1
    fi
    local repo_url device
    repo_url="$(jq -r '.repo' "$pfile")"
    device="$(jq -r --arg a "$agent" '.agents[] | select(.name==$a) | .device' "$pfile")"
    if [ -z "$device" ] || [ "$device" = "null" ]; then
        swarm_error "Agente '$agent' no asignado a ningún device en proyecto '$project'."
        return 1
    fi
    swarm_wt_ensure_repo "$project" "$device" "$repo_url"
    local base wt_path
    base="$(swarm_wt_base_dir "$project" "$device")"
    wt_path="${base}/${agent}"
    swarm_info "Creando worktree en $device: $wt_path (branch=$branch)"
    swarm_wt_run_on_device "$device" bash -lc "
        set -e
        cd \"$base/main\"
        if git show-ref --verify --quiet \"refs/heads/$branch\"; then
            git worktree add \"$wt_path\" \"$branch\" 2>/dev/null || git worktree add \"$wt_path\" \"$branch\" -f
        else
            git worktree add -b \"$branch\" \"$wt_path\"
        fi
    "
    if [ $? -eq 0 ]; then
        swarm_ok "Worktree listo para agente '$agent' en device '$device'."
        # Guardar path del worktree en el proyecto
        local tmp
        tmp="$(mktemp)"
        jq --arg a "$agent" --arg p "$wt_path" --arg b "$branch" \
            '(.agents[] | select(.name==$a) | .worktree) = $p
             | (.agents[] | select(.name==$a) | .branch)   = $b' \
            "$pfile" > "$tmp" && mv "$tmp" "$pfile"
    else
        swarm_error "Fallo creando worktree."
        return 1
    fi
}

swarm_wt_list() {
    local project="$1"
    local pfile
    pfile="$(swarm_project_file "$project")"
    [ ! -f "$pfile" ] && { swarm_error "Proyecto '$project' no existe."; return 1; }
    jq -r '.agents[] | [.name, .device, .branch, (.worktree // "-")] | @tsv' "$pfile" \
        | while IFS=$'\t' read -r agent device branch wt; do
            printf "  %-15s dev=%-10s branch=%-20s wt=%s\n" "$agent" "$device" "$branch" "$wt"
        done
}

swarm_wt_remove() {
    local project="$1" agent="$2"
    local pfile
    pfile="$(swarm_project_file "$project")"
    [ ! -f "$pfile" ] && { swarm_error "Proyecto '$project' no existe."; return 1; }
    local device wt base
    device="$(jq -r --arg a "$agent" '.agents[] | select(.name==$a) | .device' "$pfile")"
    wt="$(jq -r --arg a "$agent" '.agents[] | select(.name==$a) | .worktree // ""' "$pfile")"
    base="$(swarm_wt_base_dir "$project" "$device")"
    if [ -n "$wt" ] && [ "$wt" != "null" ]; then
        swarm_wt_run_on_device "$device" bash -lc "
            cd \"$base/main\" 2>/dev/null && git worktree remove --force \"$wt\" 2>/dev/null || rm -rf \"$wt\"
        "
        swarm_ok "Worktree removido para agente '$agent'."
    fi
}

swarm_worktree_cmd() {
    local sub="$1"; shift
    case "$sub" in
        create) swarm_wt_create "$@" ;;
        list)   swarm_wt_list "$@" ;;
        remove|rm) swarm_wt_remove "$@" ;;
        ""|help|-h|--help) swarm_worktree_help ;;
        *) swarm_error "Subcomando desconocido: $sub"; swarm_worktree_help; return 1 ;;
    esac
}
