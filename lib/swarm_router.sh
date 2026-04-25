#!/bin/bash

# ==========================================
# MÓDULO SWARM ROUTER - swarm_router.sh
# ==========================================
# Punto de entrada para el subcomando `coder swarm ...`.
# Enruta a los módulos: device, project, agent, worktree, msg y control.

swarm_help() {
    cat <<EOF
${SWARM_C_BOLD}coder swarm${SWARM_C_RESET}  -  orquestación distribuida de agentes Claude
        (arquitectura padre/hijo con enrolamiento automático)

${SWARM_C_BOLD}INICIALIZACIÓN${SWARM_C_RESET}
  coder swarm wizard              ⭐ Configuración interactiva (recomendado)
  coder swarm init --role parent [--ip <ip>]
  coder swarm init --role child  --parent <ip> --token <t> [--name <n>]
  coder swarm role                Ver rol de este device
  coder swarm doctor              Diagnóstico

${SWARM_C_BOLD}ENROLAMIENTO${SWARM_C_RESET}  (automático al init child)
  coder swarm enroll list         (parent) Solicitudes pendientes
  coder swarm enroll process      (parent) Acepta todas las pendientes
  coder swarm enroll listen       (parent) Listener en vivo
  coder swarm enroll register     (child)  Reenviar registro

${SWARM_C_BOLD}DAEMON${SWARM_C_RESET}  (en cada child)
  coder swarm daemon start [--foreground]
  coder swarm daemon stop
  coder swarm daemon status
  coder swarm daemon logs [--follow]

${SWARM_C_BOLD}GESTIÓN${SWARM_C_RESET}  (en el parent)
  coder swarm device  ...     Inventario de dispositivos
  coder swarm project ...     Proyectos y repos
  coder swarm agent   ...     Asignar agentes a devices
  coder swarm worktree ...    git worktrees

${SWARM_C_BOLD}EJECUCIÓN${SWARM_C_RESET}  (en el parent)
  coder swarm start <project> [agent]
  coder swarm stop  <project> [agent]
  coder swarm status [project]
  coder swarm logs <project> <agent> [--follow]
  coder swarm attach <project> <agent>
  coder swarm run <project> <agent> "<cmd>"

${SWARM_C_BOLD}COMUNICACIÓN${SWARM_C_RESET}
  coder swarm msg ...         Mensajes entre agentes

${SWARM_C_BOLD}RALPH (EJECUCIÓN AUTÓNOMA)${SWARM_C_RESET}
  coder swarm ralph start <project> <agent> --prd <prd.json> [--iterations N]
  coder swarm ralph stop <project> <agent>
  coder swarm ralph status <project> <agent>
  coder swarm ralph logs <project> <agent> [--follow]
  coder swarm ralph progress <project> <agent>

  Ejecuta Claude Code repetidamente hasta completar todos los items del PRD.
  Usa skills: /prd → genera PRD | /ralph → convierte a JSON

${SWARM_C_BOLD}BOOTSTRAP AUTOMATIZADO${SWARM_C_RESET}  (recomendado)

En el PARENT (una sola línea):
  curl -fsSL https://raw.githubusercontent.com/johnolven/asis-coder/main/bootstrap-parent.sh | bash

Luego, desde el PARENT, desplegar en todas las Raspberries (una línea):
  coder swarm bootstrap children 192.168.50.10 192.168.50.11 192.168.50.12 192.168.50.13 --user pi

Verificar:
  coder swarm device list
  coder swarm project create mi-app --repo https://github.com/me/mi-app.git
  coder swarm agent add mi-app auth --device rb001 --branch feat/auth --task "..."
  coder swarm start mi-app

${SWARM_C_BOLD}BOOTSTRAP MANUAL${SWARM_C_RESET}  (por si no tienes SSH configurado)

En cada CHILD (desde la propia Raspberry):
  curl -fsSL https://raw.githubusercontent.com/johnolven/asis-coder/main/bootstrap-child.sh \\
      | bash -s -- --parent <parent-ip> --token <token>
EOF
}

swarm_doctor() {
    echo -e "${SWARM_C_BOLD}▸ Diagnóstico del swarm${SWARM_C_RESET}"
    local ok=1
    for tool in jq ssh tmux git; do
        if command -v "$tool" >/dev/null 2>&1; then
            swarm_ok "$tool: $(command -v $tool)"
        else
            swarm_error "$tool: FALTA"
            ok=0
        fi
    done
    if command -v redis-cli >/dev/null 2>&1; then
        swarm_ok "redis-cli: $(command -v redis-cli)"
    else
        swarm_warn "redis-cli: falta (opcional, necesario para 'coder swarm msg')"
    fi
    echo
    echo -e "${SWARM_C_BOLD}Directorios${SWARM_C_RESET}"
    echo "  SWARM_DIR:          $SWARM_DIR"
    echo "  SWARM_DEVICES_FILE: $SWARM_DEVICES_FILE"
    echo "  SWARM_PROJECTS_DIR: $SWARM_PROJECTS_DIR"
    echo "  SWARM_LOG_DIR:      $SWARM_LOG_DIR"
    [ -f "$SWARM_DEVICES_FILE" ] && swarm_ok "devices.json existe" || swarm_warn "devices.json no existe (ejecuta: coder swarm init)"
    [ $ok -eq 0 ] && return 1 || return 0
}

swarm_router() {
    swarm_init_dirs
    swarm_require_jq || return 1
    local cmd="$1"; shift || true
    case "$cmd" in
        init)    swarm_role_init "$@" ;;
        role)    swarm_role_cmd "$@" ;;
        wizard)  swarm_wizard_run "$@" ;;
        doctor)  swarm_doctor ;;

        enroll)  swarm_enroll_cmd "$@" ;;
        daemon)  swarm_daemon_cmd "$@" ;;
        bootstrap) swarm_bootstrap_cmd "$@" ;;

        device)   swarm_device_cmd "$@" ;;
        project)  swarm_project_cmd "$@" ;;
        agent)    swarm_agent_cmd "$@" ;;
        worktree|wt) swarm_worktree_cmd "$@" ;;

        start)    swarm_start "$@" ;;
        stop)     swarm_stop "$@" ;;
        status)   swarm_status "$@" ;;
        logs)     swarm_logs "$@" ;;
        attach)   swarm_attach "$@" ;;
        run)      swarm_run "$@" ;;

        msg)      swarm_comm_cmd "$@" ;;
        ralph)    swarm_ralph_cmd "$@" ;;

        ""|help|-h|--help) swarm_help ;;
        *) swarm_error "Subcomando 'swarm $cmd' desconocido."; swarm_help; return 1 ;;
    esac
}
