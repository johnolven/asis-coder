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
    echo "    ║                    $(get_text "welcome_title")                        ║"
    echo "    ║                                                               ║"
    echo "    ║              $(get_text "welcome_subtitle")               ║"
    echo "    ║                                                               ║"
    echo "    ║    $(get_text "welcome_desc")          ║"
    echo "    ║                                        ║"
    echo "    ║                                                               ║"
    echo "    ╚═══════════════════════════════════════════════════════════════╝"
    echo -e "${NC}"
    echo ""
    
    # Información del sistema
    echo -e "${BLUE}${BOLD}🔍 Estado del Sistema${NC}"
    echo -e "${DIM}────────────────────────────────────────────────────────────────${NC}"
    
    # Verificar configuración
    if [ -f "$CONFIG_FILE" ]; then
        source "$CONFIG_FILE" 2>/dev/null || true
        if [ -n "$llm_choice" ]; then
            echo -e "   ${GREEN}✓${NC} LLM configurado: ${BOLD}$llm_choice${NC}"
            if [ -n "$model" ]; then
                echo -e "   ${GREEN}✓${NC} Modelo: ${BOLD}$model${NC}"
            fi
        else
            echo -e "   ${YELLOW}⚠${NC} LLM no configurado"
        fi
    else
        echo -e "   ${RED}✗${NC} Configuración no encontrada"
    fi
    
    # Verificar dependencias
    local deps_ok=true
    for cmd in curl jq; do
        if ! command -v "$cmd" >/dev/null 2>&1; then
            deps_ok=false
            echo -e "   ${RED}✗${NC} Dependencia faltante: $cmd"
        fi
    done
    
    if $deps_ok; then
        echo -e "   ${GREEN}✓${NC} Dependencias verificadas"
    fi
    
    # Detectar proyecto actual
    echo ""
    echo -e "${PURPLE}${BOLD}📁 Proyecto Actual${NC}"
    echo -e "${DIM}────────────────────────────────────────────────────────────────${NC}"
    
    local proyecto_detectado=$(detectar_proyecto_actual)
    if [ -n "$proyecto_detectado" ]; then
        echo -e "   ${GREEN}✓${NC} Tipo detectado: ${BOLD}$proyecto_detectado${NC}"
    else
        echo -e "   ${YELLOW}⚠${NC} Tipo de proyecto no detectado"
    fi
    
    local contexto_existe=$(encontrar_archivo_contexto)
    if [ -n "$contexto_existe" ]; then
        echo -e "   ${GREEN}✓${NC} Contexto disponible: ${DIM}$(basename "$contexto_existe")${NC}"
    else
        echo -e "   ${YELLOW}⚠${NC} Contexto no generado"
    fi
    
    local cmd_prefix=$(get_command_prefix)
    
    echo ""
    echo -e "${YELLOW}${BOLD}🚀 Primeros Pasos${NC}"
    echo -e "${DIM}────────────────────────────────────────────────────────────────${NC}"
    
    if [ ! -f "$CONFIG_FILE" ] || [ -z "$llm_choice" ]; then
        echo -e "   ${BOLD}1.${NC} Configura tu LLM: ${CYAN}${cmd_prefix} setup${NC}"
    fi
    
    if [ -z "$contexto_existe" ]; then
        echo -e "   ${BOLD}2.${NC} Genera contexto: ${CYAN}${cmd_prefix} -contexto${NC}"
    fi
    
    echo -e "   ${BOLD}3.${NC} Inicializa proyecto: ${CYAN}${cmd_prefix} /init${NC}"
    echo -e "   ${BOLD}4.${NC} Modo interactivo: ${CYAN}${cmd_prefix} -i${NC}"
    
    echo ""
    echo -e "${GREEN}${BOLD}💡 Ejemplos de Uso${NC}"
    echo -e "${DIM}────────────────────────────────────────────────────────────────${NC}"
    echo -e "   📝 ${cmd_prefix} \"explica este proyecto\""
    echo -e "   🔍 ${cmd_prefix} \"encuentra bugs en mi código\""
    echo -e "   🧪 ${cmd_prefix} \"genera tests para el módulo de auth\""
    echo -e "   📚 ${cmd_prefix} \"documenta esta función\""
    
    echo ""
    echo -e "${DIM}────────────────────────────────────────────────────────────────${NC}"
    echo -e "${DIM}   Presiona cualquier tecla para continuar o Ctrl+C para salir${NC}"
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
    
    echo -e "${BLUE}${BOLD}🔧 Configuración Inicial de Asis-coder${NC}"
    echo -e "${DIM}═══════════════════════════════════════════════════════════════${NC}"
    echo ""
    
    # Verificar dependencias
    echo -e "${YELLOW}📋 Paso 1: Verificando dependencias...${NC}"
    check_dependencies
    echo -e "${GREEN}✅ Dependencias verificadas${NC}"
    echo ""
    
    # Configurar LLM
    echo -e "${YELLOW}🤖 Paso 2: Configurando LLM...${NC}"
    update_llm_choice
    echo ""
    
    # Configurar proyecto
    echo -e "${YELLOW}📁 Paso 3: Configuración del proyecto${NC}"
    echo "¿Quieres inicializar este proyecto con Asis-coder? (y/n)"
    read -p "$(echo -e "${CYAN}> ${NC}")" init_choice
    if [[ "$init_choice" == "y" || "$init_choice" == "Y" ]]; then
        echo ""
        inicializar_proyecto
    fi
    
    echo ""
    echo -e "${GREEN}${BOLD}🎉 ¡Configuración completada exitosamente!${NC}"
    local cmd_prefix=$(get_command_prefix)
    
    echo ""
    echo -e "${BLUE}${BOLD}💡 Comandos útiles para empezar:${NC}"
    echo -e "${DIM}────────────────────────────────────────────────────────────────${NC}"
    echo -e "   ${CYAN}${cmd_prefix} -i${NC}               # Modo chat interactivo"
    echo -e "   ${CYAN}${cmd_prefix} \"pregunta\"${NC}      # Consulta directa"
    echo -e "   ${CYAN}${cmd_prefix} -contexto${NC}        # Regenerar contexto del proyecto"
    echo -e "   ${CYAN}${cmd_prefix} /init${NC}            # Inicializar proyecto"
    echo -e "   ${CYAN}${cmd_prefix} -llm${NC}             # Cambiar modelo de IA"
    echo ""
    echo -e "${DIM}¡Ya puedes empezar a usar Asis-coder! 🚀${NC}"
} 