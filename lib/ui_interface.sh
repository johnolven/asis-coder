#!/bin/bash

# ==========================================
# MÓDULO DE INTERFAZ DE USUARIO - ui_interface.sh
# ==========================================
# Gestiona todas las interfaces de usuario, pantallas de bienvenida,
# modo interactivo y presentación visual del sistema

# Función para mostrar UI del modo interactivo
mostrar_ui_interactivo() {
    clear
    
    # Colores
    local CYAN='\033[0;36m'
    local PURPLE='\033[0;35m'
    local GREEN='\033[0;32m'
    local YELLOW='\033[1;33m'
    local BLUE='\033[0;34m'
    local BOLD='\033[1m'
    local DIM='\033[2m'
    local NC='\033[0m'
    
    # Cargar idioma
    load_language
    
    # Banner para modo interactivo
    echo -e "${CYAN}${BOLD}"
    echo "    $(get_text "interactive_welcome")"
    echo -e "${NC}"
    echo -e "${DIM}    ────────────────────────────────────────────────────────────────${NC}"
    
    # Información del proyecto
    local proyecto_detectado=$(detectar_proyecto_actual)
    if [ -n "$proyecto_detectado" ]; then
        echo -e "    ${BLUE}📁 $(get_text "project"):${NC} ${BOLD}$proyecto_detectado${NC}"
    fi
    
    # Información del LLM
    if [ -f "$CONFIG_FILE" ]; then
        source "$CONFIG_FILE" 2>/dev/null || true
        if [ -n "$llm_choice" ] && [ -n "$model" ]; then
            echo -e "    ${PURPLE}🤖 $(get_text "ai"):${NC} ${BOLD}$llm_choice${NC} (${DIM}$model${NC})"
        fi
    fi
    
    echo ""
    echo -e "${YELLOW}$(get_text "write_questions")${NC}"
    echo -e "${DIM}    $(get_text "exit_commands")${NC}"
    echo -e "${DIM}    ────────────────────────────────────────────────────────────────${NC}"
    echo ""
}

# Función para validar y mostrar UI principal
validar_y_mostrar_ui() {
    # Siempre mostrar la UI principal, la validación se hace en comandos específicos
    mostrar_ui_principal
}

# Función para mostrar la UI principal
mostrar_ui_principal() {
    local CYAN='\033[0;36m'
    local GREEN='\033[0;32m'
    local RED='\033[0;31m'
    local YELLOW='\033[1;33m'
    local BLUE='\033[0;34m'
    local PURPLE='\033[0;35m'
    local BOLD='\033[1m'
    local DIM='\033[2m'
    local NC='\033[0m'
    
    # Cargar idioma
    load_language
    
    clear
    
    # Banner ASCII
    echo -e "${CYAN}${BOLD}"
    echo "    ╔═══════════════════════════════════════════════════════════════╗"
    echo "    ║                                                               ║"
    echo "    ║     █████╗ ███████╗██╗███████╗       ██████╗ ██████╗ ██████╗ ███████╗██████╗  "
    echo "    ║    ██╔══██╗██╔════╝██║██╔════╝      ██╔════╝██╔═══██╗██╔══██╗██╔════╝██╔══██╗ "
    echo "    ║    ███████║███████╗██║███████╗█████╗██║     ██║   ██║██║  ██║█████╗  ██████╔╝ "
    echo "    ║    ██╔══██║╚════██║██║╚════██║╚════╝██║     ██║   ██║██║  ██║██╔══╝  ██╔══██╗ "
    echo "    ║    ██║  ██║███████║██║███████║      ╚██████╗╚██████╔╝██████╔╝███████╗██║  ██║ "
    echo "    ║    ╚═╝  ╚═╝╚══════╝╚═╝╚══════╝       ╚═════╝ ╚═════╝ ╚═════╝ ╚══════╝╚═╝  ╚═╝ "
    echo "    ║                                                               ║"
    echo "    ║           $(get_text "ai_assistant")                 ║"
    echo "    ║                 $(get_text "powered_by")                         ║"
    echo "    ╚═══════════════════════════════════════════════════════════════╝"
    echo -e "${NC}"
    
    # Verificar configuración
    local configurado=false
    if [ -f "$CONFIG_FILE" ]; then
        source "$CONFIG_FILE" 2>/dev/null || true
        if [ -n "$llm_choice" ]; then
            configurado=true
        fi
    fi
    
    # Detectar proyecto actual
    local proyecto_detectado=$(detectar_proyecto_actual)
    local contexto_existe=$(encontrar_archivo_contexto)
    
    # Estado del sistema
    echo -e "${BLUE}${BOLD}$(get_text "current_status"):${NC}"
    echo -e "${DIM}  ────────────────────────────────────────────────────────────────${NC}"
    
    if $configurado; then
        echo -e "  ${GREEN}✓${NC} $(get_text "configured") (${BOLD}$llm_choice${NC})"
    else
        echo -e "  ${RED}✗${NC} $(get_text "not_configured")"
    fi
    
    if [ -n "$proyecto_detectado" ]; then
        echo -e "  ${GREEN}✓${NC} $(get_text "project"): ${BOLD}$proyecto_detectado${NC}"
    else
        echo -e "  ${YELLOW}⚠${NC} $(get_text "project_not_detected")"
    fi
    
    if [ -n "$contexto_existe" ]; then
        echo -e "  ${GREEN}✓${NC} $(get_text "context_available")"
    else
        echo -e "  ${YELLOW}⚠${NC} $(get_text "no_context")"
    fi
    
    echo ""
    
    # Comandos principales
    local cmd_prefix=$(get_command_prefix)
    
    echo -e "${PURPLE}${BOLD}$(get_text "main_commands"):${NC}"
    echo -e "${DIM}  ────────────────────────────────────────────────────────────────${NC}"
    echo -e "  ${CYAN}${cmd_prefix} setup${NC}           # $(get_text "initial_setup")"
    echo -e "  ${CYAN}${cmd_prefix} -i${NC}              # $(get_text "interactive_mode")"
    echo -e "  ${CYAN}${cmd_prefix} \"pregunta\"${NC}      # $(get_text "direct_query")"
    echo -e "  ${CYAN}${cmd_prefix} -contexto${NC}       # $(get_text "generate_context")"
    echo -e "  ${CYAN}${cmd_prefix} /init${NC}           # $(get_text "init_project")"
    echo -e "  ${CYAN}${cmd_prefix} -llm${NC}            # $(get_text "change_ai")"
    echo -e "  ${CYAN}${cmd_prefix} config${NC}          # $(get_text "view_config")"
    echo -e "  ${CYAN}${cmd_prefix} test${NC}            # $(get_text "test_config")"
    echo -e "  ${CYAN}${cmd_prefix} -lang${NC}           # Change language / Cambiar idioma"
    
    echo ""
    echo -e "${GREEN}${BOLD}$(get_text "usage_examples"):${NC}"
    echo -e "${DIM}  ────────────────────────────────────────────────────────────────${NC}"
    echo -e "  📝 ${cmd_prefix} \"$(get_text "explain_project")\""
    echo -e "  🔍 ${cmd_prefix} \"$(get_text "find_bugs")\""
    echo -e "  🧪 ${cmd_prefix} \"$(get_text "generate_tests")\""
    echo -e "  📚 ${cmd_prefix} \"$(get_text "document_function")\""
    
    echo ""
    echo -e "${DIM}  ────────────────────────────────────────────────────────────────${NC}"
    echo -e "${DIM}    $(get_text "press_key")${NC}"
    echo -e "${DIM}  ────────────────────────────────────────────────────────────────${NC}"
}

# Función para mostrar UI de bienvenida
mostrar_ui_bienvenida() {
    local CYAN='\033[0;36m'
    local GREEN='\033[0;32m'
    local RED='\033[0;31m'
    local YELLOW='\033[1;33m'
    local BLUE='\033[0;34m'
    local PURPLE='\033[0;35m'
    local BOLD='\033[1m'
    local DIM='\033[2m'
    local NC='\033[0m'
    
    clear
    
    # Cargar idioma
    load_language
    
    # Banner de bienvenida
    echo -e "${CYAN}${BOLD}"
    echo "    ╔═══════════════════════════════════════════════════════════════╗"
    echo "    ║                                                               ║"
    echo "    ║     █████╗ ███████╗██╗███████╗       ██████╗ ██████╗ ██████╗ ███████╗██████╗  "
    echo "    ║    ██╔══██╗██╔════╝██║██╔════╝      ██╔════╝██╔═══██╗██╔══██╗██╔════╝██╔══██╗ "
    echo "    ║    ███████║███████╗██║███████╗█████╗██║     ██║   ██║██║  ██║█████╗  ██████╔╝ "
    echo "    ║    ██╔══██║╚════██║██║╚════██║╚════╝██║     ██║   ██║██║  ██║██╔══╝  ██╔══██╗ "
    echo "    ║    ██║  ██║███████║██║███████║      ╚██████╗╚██████╔╝██████╔╝███████╗██║  ██║ "
    echo "    ║    ╚═╝  ╚═╝╚══════╝╚═╝╚══════╝       ╚═════╝ ╚═════╝ ╚═════╝ ╚══════╝╚═╝  ╚═╝ "
    echo "    ║                                                               ║"
    echo "    ║           $(get_text "ai_assistant")                 ║"
    echo "    ║                 $(get_text "powered_by")                         ║"
    echo "    ╚═══════════════════════════════════════════════════════════════╝"
    echo -e "${NC}"
    
    # Información del sistema
    echo -e "${BLUE}${BOLD}$(get_text "system_status")${NC}"
    echo -e "${DIM}────────────────────────────────────────────────────────────────${NC}"
    
    # Verificar configuración
    if [ -f "$CONFIG_FILE" ]; then
        source "$CONFIG_FILE" 2>/dev/null || true
        if [ -n "$llm_choice" ]; then
            echo -e "   ${GREEN}✓${NC} $(get_text "llm_configured"): ${BOLD}$llm_choice${NC}"
            if [ -n "$model" ]; then
                echo -e "   ${GREEN}✓${NC} $(get_text "model"): ${BOLD}$model${NC}"
            fi
        else
            echo -e "   ${YELLOW}⚠${NC} $(get_text "llm_not_configured")"
        fi
    else
        echo -e "   ${RED}✗${NC} $(get_text "config_not_found")"
    fi
    
    # Verificar dependencias
    local deps_ok=true
    for cmd in curl jq; do
        if ! command -v "$cmd" >/dev/null 2>&1; then
            deps_ok=false
            echo -e "   ${RED}✗${NC} $(get_text "missing_dependency"): $cmd"
        fi
    done
    
    if $deps_ok; then
        echo -e "   ${GREEN}✓${NC} $(get_text "dependencies_verified")"
    fi
    
    # Detectar proyecto actual
    echo ""
    echo -e "${PURPLE}${BOLD}$(get_text "current_project")${NC}"
    echo -e "${DIM}────────────────────────────────────────────────────────────────${NC}"
    
    local proyecto_detectado=$(detectar_proyecto_actual)
    if [ -n "$proyecto_detectado" ]; then
        echo -e "   ${GREEN}✓${NC} $(get_text "type_detected"): ${BOLD}$proyecto_detectado${NC}"
    else
        echo -e "   ${YELLOW}⚠${NC} $(get_text "project_type_not_detected")"
    fi
    
    local contexto_existe=$(encontrar_archivo_contexto)
    if [ -n "$contexto_existe" ]; then
        echo -e "   ${GREEN}✓${NC} $(get_text "context_available"): ${DIM}$(basename "$contexto_existe")${NC}"
    else
        echo -e "   ${YELLOW}⚠${NC} $(get_text "context_not_generated")"
    fi
    
    local cmd_prefix=$(get_command_prefix)
    
    echo ""
    echo -e "${YELLOW}${BOLD}$(get_text "first_steps")${NC}"
    echo -e "${DIM}────────────────────────────────────────────────────────────────${NC}"
    
    if [ ! -f "$CONFIG_FILE" ] || [ -z "$llm_choice" ]; then
        echo -e "   ${BOLD}1.${NC} $(get_text "configure_llm"): ${CYAN}${cmd_prefix} setup${NC}"
    fi
    
    if [ -z "$contexto_existe" ]; then
        echo -e "   ${BOLD}2.${NC} $(get_text "generate_context"): ${CYAN}${cmd_prefix} -contexto${NC}"
    fi
    
    echo -e "   ${BOLD}3.${NC} $(get_text "initialize_project"): ${CYAN}${cmd_prefix} /init${NC}"
    echo -e "   ${BOLD}4.${NC} $(get_text "interactive_mode"): ${CYAN}${cmd_prefix} -i${NC}"
    
    echo ""
    echo -e "${GREEN}${BOLD}$(get_text "usage_examples")${NC}"
    echo -e "${DIM}────────────────────────────────────────────────────────────────${NC}"
    echo -e "   📝 ${cmd_prefix} \"$(get_text "explain_project")\""
    echo -e "   🔍 ${cmd_prefix} \"$(get_text "find_bugs")\""
    echo -e "   🧪 ${cmd_prefix} \"$(get_text "generate_tests")\""
    echo -e "   📚 ${cmd_prefix} \"$(get_text "document_function")\""
    
    echo ""
    echo -e "${DIM}────────────────────────────────────────────────────────────────${NC}"
    echo -e "${DIM}   $(get_text "press_key")${NC}"
    echo -e "${DIM}────────────────────────────────────────────────────────────────${NC}"
}

# Función para dar formato al código
dar_formato_codigo() {
    local contenido="$1"
    if command -v highlight &> /dev/null; then
        echo "$contenido" | highlight -O ansi --syntax=auto
    else
        echo "$contenido" | sed 's/^/    /'
    fi
}

# Función para ofrecer instalación global
ofrecer_instalacion_global() {
    if is_running_with_npx; then
        local BLUE='\033[0;34m'
        local GREEN='\033[0;32m'
        local YELLOW='\033[1;33m'
        local CYAN='\033[0;36m'
        local BOLD='\033[1m'
        local DIM='\033[2m'
        local NC='\033[0m'
        
        echo ""
        echo -e "${YELLOW}${BOLD}$(get_text "global_install_available")${NC}"
        echo -e "${DIM}────────────────────────────────────────────────────────────────${NC}"
        echo -e "$(get_text "currently_using_npx")"
        echo -e "$(get_text "would_you_like_global")"
        echo ""
        echo -e "${GREEN}$(get_text "with_global_install")${NC}"
                   echo -e "   ${CYAN}coder setup${NC}      # $(get_text "initial_configuration")"
        echo -e "   ${CYAN}coder -i${NC}         # $(get_text "interactive_mode")"
        echo -e "   ${CYAN}coder \"pregunta\"${NC} # $(get_text "direct_query")"
        echo ""
        echo -e "$(get_text "install_globally_question")"
        read -p "$(echo -e "${CYAN}> ${NC}")" install_choice
        
        if [[ "$install_choice" == "y" || "$install_choice" == "Y" ]]; then
            echo ""
            echo -e "${YELLOW}$(get_text "installing_globally")${NC}"
            if npm install -g asis-coder; then
                echo -e "${GREEN}$(get_text "installed_successfully")${NC}"
                echo ""
                echo -e "${BLUE}${BOLD}$(get_text "now_you_can_use")${NC}"
                echo -e "   ${CYAN}coder setup${NC}"
                echo -e "   ${CYAN}coder -i${NC}"
                echo -e "   ${CYAN}coder \"tu pregunta\"${NC}"
                echo ""
                echo -e "${DIM}$(get_text "press_enter_continue")${NC}"
                read
            else
                echo -e "${YELLOW}$(get_text "could_not_install")${NC}"
                echo ""
            fi
        else
            echo -e "${BLUE}$(get_text "ok_continue_npx")${NC}"
            echo ""
        fi
    fi
}

# Función para configuración inicial completa
configuracion_inicial_completa() {
    mostrar_ui_bienvenida
    
    # Esperar input del usuario
    read -n 1 -s
    clear
    
    local BLUE='\033[0;34m'
    local GREEN='\033[0;32m'
    local YELLOW='\033[1;33m'
    local CYAN='\033[0;36m'
    local BOLD='\033[1m'
    local DIM='\033[2m'
    local NC='\033[0m'
    
    echo -e "${BLUE}${BOLD}$(get_text "initial_setup_title")${NC}"
    echo -e "${DIM}═══════════════════════════════════════════════════════════════${NC}"
    echo ""
    
    # Ofrecer instalación global si se está ejecutando con npx
    ofrecer_instalacion_global
    
    # Verificar dependencias
    echo -e "${YELLOW}$(get_text "step_1_dependencies")${NC}"
    check_dependencies
    echo -e "${GREEN}✅ $(get_text "dependencies_verified")${NC}"
    echo ""
    
    # Configurar LLM
    echo -e "${YELLOW}$(get_text "step_2_llm")${NC}"
    update_llm_choice
    echo ""
    
    # Configurar proyecto
    echo -e "${YELLOW}$(get_text "step_3_project")${NC}"
    echo "$(get_text "initialize_project_question")"
    read -p "$(echo -e "${CYAN}> ${NC}")" init_choice
    if [[ "$init_choice" == "y" || "$init_choice" == "Y" ]]; then
        echo ""
        inicializar_proyecto
    fi
    
    echo ""
    echo -e "${GREEN}${BOLD}$(get_text "setup_completed")${NC}"
    local cmd_prefix=$(get_command_prefix)
    
    echo ""
    echo -e "${BLUE}${BOLD}$(get_text "useful_commands")${NC}"
    echo -e "${DIM}────────────────────────────────────────────────────────────────${NC}"
    echo -e "   ${CYAN}${cmd_prefix} -i${NC}               # $(get_text "interactive_chat_mode")"
    echo -e "   ${CYAN}${cmd_prefix} \"pregunta\"${NC}      # $(get_text "direct_query")"
    echo -e "   ${CYAN}${cmd_prefix} -contexto${NC}        # $(get_text "regenerate_context")"
    echo -e "   ${CYAN}${cmd_prefix} /init${NC}            # $(get_text "initialize_project")"
    echo -e "   ${CYAN}${cmd_prefix} -llm${NC}             # $(get_text "change_ai_model")"
    echo ""
    echo -e "${DIM}$(get_text "ready_to_use")${NC}"
} 