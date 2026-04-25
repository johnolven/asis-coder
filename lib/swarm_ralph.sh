#!/bin/bash

# ==========================================
# MÓDULO SWARM RALPH - swarm_ralph.sh
# ==========================================
# Integración de Ralph (autonomous AI loop) con el swarm.
# Permite ejecutar loops autónomos de Claude Code en Raspberries
# para completar PRDs de forma desatendida.

RALPH_REPO="https://github.com/snarktank/ralph.git"
RALPH_BRANCH="main"

swarm_ralph_help() {
    cat <<EOF
${SWARM_C_BOLD}coder swarm ralph${SWARM_C_RESET}  -  ejecución autónoma con Ralph

Ralph ejecuta Claude Code repetidamente hasta completar todos los items del PRD.
Cada iteración = nueva instancia de Claude con contexto limpio.
Memoria entre iteraciones: git history + progress.txt + prd.json

${SWARM_C_BOLD}COMANDOS${SWARM_C_RESET}
  coder swarm ralph start <proyecto> <agente> --prd <prd.json> [--iterations N]
  coder swarm ralph stop <proyecto> <agente>
  coder swarm ralph status <proyecto> <agente>
  coder swarm ralph logs <proyecto> <agente> [--follow]
  coder swarm ralph progress <proyecto> <agente>
  coder swarm ralph validate <proyecto> <agente>  # Verifica build/tests

${SWARM_C_BOLD}OPCIONES${SWARM_C_RESET}
  --prd <file>          Archivo prd.json (obligatorio para start)
  --iterations <N>      Max iteraciones (default: 20)
  --follow, -f          Seguir logs en tiempo real

${SWARM_C_BOLD}FLUJO COMPLETO${SWARM_C_RESET}
  # 1. Genera PRD (con Claude usando skill /prd)
  "Crea un PRD para sistema de autenticación"
  → tasks/prd-auth.md

  # 2. Convierte a JSON (con Claude usando skill /ralph)
  "Convierte este PRD a formato Ralph"
  → prd.json

  # 3. Ejecuta loop autónomo en Raspberry
  coder swarm ralph start mi-app auth-agent --prd prd.json --iterations 20

  # 4. Monitorea progreso
  coder swarm ralph status mi-app auth-agent
  coder swarm ralph logs mi-app auth-agent --follow

  # 5. Valida resultado
  coder swarm ralph validate mi-app auth-agent

${SWARM_C_BOLD}EJEMPLO${SWARM_C_RESET}
  coder swarm project create auth-app --repo https://github.com/user/app.git
  coder swarm agent add auth-app auth-feature --device RB001 --branch feat/auth
  coder swarm ralph start auth-app auth-feature --prd prd-auth.json --iterations 30

  # Ralph trabajará hasta completar todos los items del PRD
  # Verifica progreso:
  coder swarm ralph progress auth-app auth-feature
  coder swarm ralph validate auth-app auth-feature
EOF
}

swarm_ralph_start() {
    local project="$1" agent="$2" prd_file="" iterations=20
    shift 2

    while [ $# -gt 0 ]; do
        case "$1" in
            --prd) prd_file="$2"; shift 2 ;;
            --iterations) iterations="$2"; shift 2 ;;
            *) swarm_error "Argumento desconocido: $1"; return 1 ;;
        esac
    done

    if [ -z "$project" ] || [ -z "$agent" ]; then
        swarm_error "Uso: coder swarm ralph start <proyecto> <agente> --prd <file> [--iterations N]"
        return 1
    fi

    if [ -z "$prd_file" ] || [ ! -f "$prd_file" ]; then
        swarm_error "Archivo PRD no encontrado: $prd_file"
        swarm_info "Genera uno con: /prd (skill) y /ralph (skill)"
        return 1
    fi

    # Obtener info del agente
    local agent_info device_name
    agent_info="$(swarm_agent_get "$project" "$agent")"
    if [ -z "$agent_info" ]; then
        swarm_error "Agente '$agent' no existe en proyecto '$project'"
        return 1
    fi

    device_name="$(echo "$agent_info" | jq -r '.device')"
    local device_info
    device_info="$(swarm_device_get "$device_name")"
    if [ -z "$device_info" ]; then
        swarm_error "Device '$device_name' no existe"
        return 1
    fi

    local device_ip device_user device_port
    device_ip="$(echo "$device_info" | jq -r '.ip')"
    device_user="$(echo "$device_info" | jq -r '.user')"
    device_port="$(echo "$device_info" | jq -r '.port')"

    swarm_info "Iniciando Ralph en $device_name ($device_ip)"
    swarm_info "Proyecto: $project, Agente: $agent, Iteraciones: $iterations"

    # 1. Instalar Ralph en el device si no existe
    swarm_info "Verificando instalación de Ralph..."
    if ! swarm_ssh_cmd "$device_name" "[ -d ~/ralph ]"; then
        swarm_info "Instalando Ralph en $device_name..."
        swarm_ssh_cmd "$device_name" "git clone -q $RALPH_REPO ~/ralph 2>&1" || {
            swarm_error "Falló instalación de Ralph"
            return 1
        }
        swarm_ok "Ralph instalado"
    else
        # Actualizar Ralph
        swarm_ssh_cmd "$device_name" "cd ~/ralph && git pull -q origin $RALPH_BRANCH 2>&1" >/dev/null || true
        swarm_ok "Ralph actualizado"
    fi

    # 2. Obtener info del proyecto
    local project_info project_repo
    project_info="$(swarm_project_get "$project")"
    project_repo="$(echo "$project_info" | jq -r '.repo')"

    # 3. Clonar proyecto en el device si no existe
    local project_dir="/home/$device_user/swarm-projects/$project"
    swarm_info "Verificando proyecto en $device_name..."
    if ! swarm_ssh_cmd "$device_name" "[ -d $project_dir ]"; then
        swarm_info "Clonando proyecto..."
        swarm_ssh_cmd "$device_name" "mkdir -p /home/$device_user/swarm-projects && \
            git clone -q $project_repo $project_dir 2>&1" || {
            swarm_error "Falló clonado del proyecto"
            return 1
        }
        swarm_ok "Proyecto clonado"
    fi

    # 4. Copiar prd.json al device
    swarm_info "Copiando PRD al device..."
    scp -q -P "$device_port" "$prd_file" "${device_user}@${device_ip}:$project_dir/prd.json" || {
        swarm_error "Falló copia del PRD"
        return 1
    }
    swarm_ok "PRD copiado"

    # 5. Copiar ralph.sh y CLAUDE.md al proyecto
    swarm_ssh_cmd "$device_name" "cp ~/ralph/ralph.sh $project_dir/ && \
        cp ~/ralph/CLAUDE.md $project_dir/ && \
        chmod +x $project_dir/ralph.sh" || {
        swarm_error "Falló copia de scripts Ralph"
        return 1
    }

    # 6. Crear tmux session para Ralph
    local session_name="ralph-${project}-${agent}"
    swarm_info "Iniciando Ralph en tmux session: $session_name"

    swarm_ssh_cmd "$device_name" "tmux kill-session -t $session_name 2>/dev/null || true"

    local ralph_cmd="cd $project_dir && ./ralph.sh --tool claude $iterations 2>&1 | tee ralph.log"
    swarm_ssh_cmd "$device_name" "tmux new-session -d -s $session_name \"$ralph_cmd\"" || {
        swarm_error "Falló inicio de Ralph"
        return 1
    }

    # 7. Actualizar estado del agente
    swarm_agent_update_status "$project" "$agent" "ralph-running"

    swarm_ok "Ralph ejecutándose en $device_name"
    echo
    swarm_info "Monitorea progreso con:"
    echo "  coder swarm ralph status $project $agent"
    echo "  coder swarm ralph logs $project $agent --follow"
    echo "  coder swarm ralph progress $project $agent"
}

swarm_ralph_stop() {
    local project="$1" agent="$2"

    if [ -z "$project" ] || [ -z "$agent" ]; then
        swarm_error "Uso: coder swarm ralph stop <proyecto> <agente>"
        return 1
    fi

    local agent_info device_name
    agent_info="$(swarm_agent_get "$project" "$agent")"
    [ -z "$agent_info" ] && { swarm_error "Agente no encontrado"; return 1; }

    device_name="$(echo "$agent_info" | jq -r '.device')"
    local session_name="ralph-${project}-${agent}"

    swarm_info "Deteniendo Ralph en $device_name..."
    swarm_ssh_cmd "$device_name" "tmux kill-session -t $session_name 2>/dev/null" || true

    swarm_agent_update_status "$project" "$agent" "idle"
    swarm_ok "Ralph detenido"
}

swarm_ralph_status() {
    local project="$1" agent="$2"

    if [ -z "$project" ] || [ -z "$agent" ]; then
        swarm_error "Uso: coder swarm ralph status <proyecto> <agente>"
        return 1
    fi

    local agent_info device_name
    agent_info="$(swarm_agent_get "$project" "$agent")"
    [ -z "$agent_info" ] && { swarm_error "Agente no encontrado"; return 1; }

    device_name="$(echo "$agent_info" | jq -r '.device')"
    local session_name="ralph-${project}-${agent}"

    echo -e "${SWARM_C_BOLD}Ralph Status: $project/$agent${SWARM_C_RESET}"
    echo "Device: $device_name"
    echo

    # Check tmux session
    if swarm_ssh_cmd "$device_name" "tmux has-session -t $session_name 2>/dev/null"; then
        swarm_ok "Ralph loop: RUNNING"

        # Get last few lines of log
        local recent_log
        recent_log="$(swarm_ssh_cmd "$device_name" "tail -20 /home/\$USER/swarm-projects/$project/ralph.log 2>/dev/null" | tail -5)"

        if [ -n "$recent_log" ]; then
            echo
            echo "Últimas líneas del log:"
            echo "$recent_log"
        fi
    else
        swarm_warn "Ralph loop: NOT RUNNING"
    fi

    # Show prd.json status
    echo
    swarm_ralph_progress "$project" "$agent"
}

swarm_ralph_logs() {
    local project="$1" agent="$2" follow=false
    shift 2

    while [ $# -gt 0 ]; do
        case "$1" in
            --follow|-f) follow=true; shift ;;
            *) shift ;;
        esac
    done

    if [ -z "$project" ] || [ -z "$agent" ]; then
        swarm_error "Uso: coder swarm ralph logs <proyecto> <agente> [--follow]"
        return 1
    fi

    local agent_info device_name
    agent_info="$(swarm_agent_get "$project" "$agent")"
    [ -z "$agent_info" ] && { swarm_error "Agente no encontrado"; return 1; }

    device_name="$(echo "$agent_info" | jq -r '.device')"
    local log_file="/home/\$USER/swarm-projects/$project/ralph.log"

    if $follow; then
        swarm_info "Siguiendo logs de Ralph en $device_name (Ctrl+C para salir)..."
        swarm_ssh_cmd "$device_name" "tail -f $log_file 2>/dev/null || echo 'Log no disponible'"
    else
        swarm_ssh_cmd "$device_name" "tail -50 $log_file 2>/dev/null || echo 'Log no disponible'"
    fi
}

swarm_ralph_progress() {
    local project="$1" agent="$2"

    if [ -z "$project" ] || [ -z "$agent" ]; then
        swarm_error "Uso: coder swarm ralph progress <proyecto> <agente>"
        return 1
    fi

    local agent_info device_name
    agent_info="$(swarm_agent_get "$project" "$agent")"
    [ -z "$agent_info" ] && { swarm_error "Agente no encontrado"; return 1; }

    device_name="$(echo "$agent_info" | jq -r '.device')"
    local prd_file="/home/\$USER/swarm-projects/$project/prd.json"

    echo -e "${SWARM_C_BOLD}Progreso del PRD: $project/$agent${SWARM_C_RESET}"
    echo

    # Get prd.json from device
    local prd_content
    prd_content="$(swarm_ssh_cmd "$device_name" "cat $prd_file 2>/dev/null")"

    if [ -z "$prd_content" ]; then
        swarm_warn "PRD no disponible"
        return 1
    fi

    # Parse and show progress
    local total_stories completed_stories
    total_stories="$(echo "$prd_content" | jq '.userStories | length')"
    completed_stories="$(echo "$prd_content" | jq '[.userStories[] | select(.passes == true)] | length')"

    echo "User Stories: $completed_stories / $total_stories completadas"
    echo

    # Show each story status
    echo "$prd_content" | jq -r '.userStories[] |
        "\(.id): \(.title) - \(if .passes then "✓ DONE" else "○ PENDING" end)"'

    echo
    if [ "$completed_stories" -eq "$total_stories" ]; then
        swarm_ok "PRD COMPLETO"
    else
        swarm_info "En progreso... ($completed_stories/$total_stories)"
    fi
}

swarm_ralph_detect_project_type() {
    local project="$1" agent="$2"

    local agent_info device_name
    agent_info="$(swarm_agent_get "$project" "$agent")"
    [ -z "$agent_info" ] && return 1

    device_name="$(echo "$agent_info" | jq -r '.device')"
    local project_dir="/home/\$USER/swarm-projects/$project"

    # Check for project type markers
    local project_type=""

    if swarm_ssh_cmd "$device_name" "[ -f $project_dir/package.json ]"; then
        project_type="nodejs"
    elif swarm_ssh_cmd "$device_name" "[ -f $project_dir/requirements.txt ] || [ -f $project_dir/setup.py ] || [ -f $project_dir/pyproject.toml ]"; then
        project_type="python"
    elif swarm_ssh_cmd "$device_name" "[ -f $project_dir/go.mod ]"; then
        project_type="go"
    elif swarm_ssh_cmd "$device_name" "[ -f $project_dir/Cargo.toml ]"; then
        project_type="rust"
    elif swarm_ssh_cmd "$device_name" "[ -f $project_dir/composer.json ]"; then
        project_type="php"
    elif swarm_ssh_cmd "$device_name" "[ -f $project_dir/pom.xml ] || [ -f $project_dir/build.gradle ]"; then
        project_type="java"
    else
        project_type="unknown"
    fi

    echo "$project_type"
}

swarm_ralph_validate() {
    local project="$1" agent="$2"

    if [ -z "$project" ] || [ -z "$agent" ]; then
        swarm_error "Uso: coder swarm ralph validate <proyecto> <agente>"
        return 1
    fi

    local agent_info device_name
    agent_info="$(swarm_agent_get "$project" "$agent")"
    [ -z "$agent_info" ] && { swarm_error "Agente no encontrado"; return 1; }

    device_name="$(echo "$agent_info" | jq -r '.device')"
    local project_dir="/home/\$USER/swarm-projects/$project"

    echo -e "${SWARM_C_BOLD}Validando proyecto: $project/$agent${SWARM_C_RESET}"
    echo "Device: $device_name"
    echo

    # Detect project type
    local project_type
    project_type="$(swarm_ralph_detect_project_type "$project" "$agent")"
    swarm_info "Tipo detectado: $project_type"
    echo

    local validation_result=0

    case "$project_type" in
        nodejs)
            swarm_info "Ejecutando validación Node.js..."
            echo "  → npm install"
            if swarm_ssh_cmd "$device_name" "cd $project_dir && npm install >/dev/null 2>&1"; then
                swarm_ok "npm install: PASS"
            else
                swarm_error "npm install: FAIL"
                validation_result=1
            fi

            echo "  → npm run build (si existe)"
            if swarm_ssh_cmd "$device_name" "cd $project_dir && npm run build >/dev/null 2>&1"; then
                swarm_ok "npm run build: PASS"
            else
                swarm_warn "npm run build: SKIP (no existe o falló)"
            fi

            echo "  → npm test (si existe)"
            if swarm_ssh_cmd "$device_name" "cd $project_dir && npm test -- --passWithNoTests >/dev/null 2>&1"; then
                swarm_ok "npm test: PASS"
            else
                swarm_warn "npm test: SKIP (no existe o falló)"
            fi
            ;;

        python)
            swarm_info "Ejecutando validación Python..."
            echo "  → pip install -r requirements.txt"
            if swarm_ssh_cmd "$device_name" "cd $project_dir && pip install -q -r requirements.txt >/dev/null 2>&1"; then
                swarm_ok "pip install: PASS"
            else
                swarm_warn "pip install: SKIP (no requirements.txt)"
            fi

            echo "  → pytest (si existe)"
            if swarm_ssh_cmd "$device_name" "cd $project_dir && python -m pytest >/dev/null 2>&1"; then
                swarm_ok "pytest: PASS"
            else
                swarm_warn "pytest: SKIP"
            fi

            echo "  → python -m py_compile *.py"
            if swarm_ssh_cmd "$device_name" "cd $project_dir && find . -name '*.py' -exec python -m py_compile {} + 2>&1"; then
                swarm_ok "syntax check: PASS"
            else
                swarm_error "syntax check: FAIL"
                validation_result=1
            fi
            ;;

        go)
            swarm_info "Ejecutando validación Go..."
            echo "  → go build"
            if swarm_ssh_cmd "$device_name" "cd $project_dir && go build ./... >/dev/null 2>&1"; then
                swarm_ok "go build: PASS"
            else
                swarm_error "go build: FAIL"
                validation_result=1
            fi

            echo "  → go test"
            if swarm_ssh_cmd "$device_name" "cd $project_dir && go test ./... >/dev/null 2>&1"; then
                swarm_ok "go test: PASS"
            else
                swarm_warn "go test: SKIP"
            fi
            ;;

        rust)
            swarm_info "Ejecutando validación Rust..."
            echo "  → cargo build"
            if swarm_ssh_cmd "$device_name" "cd $project_dir && cargo build >/dev/null 2>&1"; then
                swarm_ok "cargo build: PASS"
            else
                swarm_error "cargo build: FAIL"
                validation_result=1
            fi

            echo "  → cargo test"
            if swarm_ssh_cmd "$device_name" "cd $project_dir && cargo test >/dev/null 2>&1"; then
                swarm_ok "cargo test: PASS"
            else
                swarm_warn "cargo test: SKIP"
            fi
            ;;

        *)
            swarm_warn "Tipo de proyecto desconocido, no hay validaciones automáticas"
            swarm_info "Define validaciones manualmente en el PRD"
            ;;
    esac

    echo
    if [ $validation_result -eq 0 ]; then
        swarm_ok "VALIDACIÓN: PASS"
    else
        swarm_error "VALIDACIÓN: FAIL"
    fi

    return $validation_result
}

swarm_ralph_cmd() {
    local sub="$1"; shift || true
    case "$sub" in
        start)    swarm_ralph_start "$@" ;;
        stop)     swarm_ralph_stop "$@" ;;
        status)   swarm_ralph_status "$@" ;;
        logs)     swarm_ralph_logs "$@" ;;
        progress) swarm_ralph_progress "$@" ;;
        validate) swarm_ralph_validate "$@" ;;
        ""|help|-h|--help) swarm_ralph_help ;;
        *) swarm_error "Subcomando desconocido: $sub"; swarm_ralph_help; return 1 ;;
    esac
}
