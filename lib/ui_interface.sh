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
    
    # Banner para modo interactivo
    echo -e "${CYAN}${BOLD}"
    echo "    ✻ ¡Bienvenido al Modo Interactivo de Asis-coder!"
    echo -e "${NC}"
    echo -e "${DIM}    ────────────────────────────────────────────────────────────────${NC}"
    
    # Información del proyecto
    local proyecto_detectado=$(detectar_proyecto_actual)
    if [ -n "$proyecto_detectado" ]; then
        echo -e "    ${BLUE}📁 Proyecto:${NC} ${BOLD}$proyecto_detectado${NC}"
    fi
    
    # Información del LLM
    if [ -f "$CONFIG_FILE" ]; then
        source "$CONFIG_FILE" 2>/dev/null || true
        if [ -n "$llm_choice" ] && [ -n "$model" ]; then
            echo -e "    ${PURPLE}🤖 IA:${NC} ${BOLD}$llm_choice${NC} (${DIM}$model${NC})"
        fi
    fi
    
    echo ""
    echo -e "${YELLOW}💬 Escribe tus preguntas y presiona Enter${NC}"
    echo -e "${DIM}    Comandos: ${BOLD}salir${NC}${DIM}, ${BOLD}exit${NC}${DIM}, ${BOLD}quit${NC}${DIM} para terminar${NC}"
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
    
    clear
    
    # Banner ASCII
    echo -e "${CYAN}${BOLD}"
    echo "    ╔═══════════════════════════════════════════════════════════════╗"
    echo "    ║                                                               ║"
    echo "    ║     █████╗ ███████╗██╗███████╗      ██████╗ ██████╗ ██████╗  ║"
    echo "    ║    ██╔══██╗██╔════╝██║██╔════╝     ██╔════╝██╔═══██╗██╔══██╗ ║"
    echo "    ║    ███████║███████╗██║███████╗     ██║     ██║   ██║██║  ██║ ║"
    echo "    ║    ██╔══██║╚════██║██║╚════██║     ██║     ██║   ██║██║  ██║ ║"
    echo "    ║    ██║  ██║███████║██║███████║     ╚██████╗╚██████╔╝██████╔╝ ║"
    echo "    ║    ╚═╝  ╚═╝╚══════╝╚═╝╚══════╝      ╚═════╝ ╚═════╝ ╚═════╝  ║"
    echo "    ║                                                               ║"
    echo "    ║           🤖 Tu Asistente de Desarrollo con IA 🚀             ║"
    echo "    ║                        v$VERSION                                   ║"
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
    echo -e "${BLUE}${BOLD}📊 Estado Actual:${NC}"
    echo -e "${DIM}  ────────────────────────────────────────────────────────────────${NC}"
    
    if $configurado; then
        echo -e "  ${GREEN}✓${NC} Configurado (${BOLD}$llm_choice${NC})"
    else
        echo -e "  ${RED}✗${NC} No configurado"
    fi
    
    if [ -n "$proyecto_detectado" ]; then
        echo -e "  ${GREEN}✓${NC} Proyecto: ${BOLD}$proyecto_detectado${NC}"
    else
        echo -e "  ${YELLOW}⚠${NC} Proyecto no detectado"
    fi
    
    if [ -n "$contexto_existe" ]; then
        echo -e "  ${GREEN}✓${NC} Contexto disponible"
    else
        echo -e "  ${YELLOW}⚠${NC} Sin contexto"
    fi
    
    echo ""
    
    # Comandos principales
    echo -e "${PURPLE}${BOLD}🚀 Comandos Principales:${NC}"
    echo -e "${DIM}  ────────────────────────────────────────────────────────────────${NC}"
    echo -e "  ${CYAN}coder setup${NC}           # Configuración inicial completa"
    echo -e "  ${CYAN}coder -i${NC}              # Modo chat interactivo"
    echo -e "  ${CYAN}coder \"pregunta\"${NC}      # Consulta directa"
    echo -e "  ${CYAN}coder -contexto${NC}       # Generar contexto del proyecto"
    echo -e "  ${CYAN}coder /init${NC}           # Inicializar proyecto"
    echo -e "  ${CYAN}coder -llm${NC}            # Cambiar modelo de IA"
    echo -e "  ${CYAN}coder config${NC}          # Ver/cambiar configuración"
    echo -e "  ${CYAN}coder test${NC}            # Probar configuración"
    
    echo ""
    echo -e "${GREEN}${BOLD}💡 Ejemplos de Uso:${NC}"
    echo -e "${DIM}  ────────────────────────────────────────────────────────────────${NC}"
    echo -e '  📝 coder "explica este proyecto"'
    echo -e '  🔍 coder "encuentra bugs en mi código"'
    echo -e '  🧪 coder "genera tests para el módulo de auth"'
    echo -e '  📚 coder "documenta esta función"'
    
    echo ""
    echo -e "${DIM}  ────────────────────────────────────────────────────────────────${NC}"
    echo -e "${DIM}    Presiona cualquier tecla para continuar o Ctrl+C para salir${NC}"
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
    
    # Banner de bienvenida
    echo -e "${CYAN}${BOLD}"
    echo "    ╔═══════════════════════════════════════════════════════════════╗"
    echo "    ║                    🎉 ¡BIENVENIDO! 🎉                        ║"
    echo "    ║                                                               ║"
    echo "    ║              ASIS-CODER - Configuración Inicial               ║"
    echo "    ║                                                               ║"
    echo "    ║    Tu asistente de desarrollo con IA está listo para          ║"
    echo "    ║    ayudarte a programar más eficientemente                    ║"
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
    
    echo ""
    echo -e "${YELLOW}${BOLD}🚀 Primeros Pasos${NC}"
    echo -e "${DIM}────────────────────────────────────────────────────────────────${NC}"
    
    if [ ! -f "$CONFIG_FILE" ] || [ -z "$llm_choice" ]; then
        echo -e "   ${BOLD}1.${NC} Configura tu LLM: ${CYAN}coder setup${NC}"
    fi
    
    if [ -z "$contexto_existe" ]; then
        echo -e "   ${BOLD}2.${NC} Genera contexto: ${CYAN}coder -contexto${NC}"
    fi
    
    echo -e "   ${BOLD}3.${NC} Inicializa proyecto: ${CYAN}coder /init${NC}"
    echo -e "   ${BOLD}4.${NC} Modo interactivo: ${CYAN}coder -i${NC}"
    
    echo ""
    echo -e "${GREEN}${BOLD}💡 Ejemplos de Uso${NC}"
    echo -e "${DIM}────────────────────────────────────────────────────────────────${NC}"
    echo -e '   📝 coder "explica este proyecto"'
    echo -e '   🔍 coder "encuentra bugs en mi código"'
    echo -e '   🧪 coder "genera tests para el módulo de auth"'
    echo -e '   📚 coder "documenta esta función"'
    
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
    echo ""
    echo -e "${BLUE}${BOLD}💡 Comandos útiles para empezar:${NC}"
    echo -e "${DIM}────────────────────────────────────────────────────────────────${NC}"
    echo -e "   ${CYAN}coder -i${NC}               # Modo chat interactivo"
    echo -e "   ${CYAN}coder \"pregunta\"${NC}      # Consulta directa"
    echo -e "   ${CYAN}coder -contexto${NC}        # Regenerar contexto del proyecto"
    echo -e "   ${CYAN}coder /init${NC}            # Inicializar proyecto"
    echo -e "   ${CYAN}coder -llm${NC}             # Cambiar modelo de IA"
    echo ""
    echo -e "${DIM}¡Ya puedes empezar a usar Asis-coder! 🚀${NC}"
} 