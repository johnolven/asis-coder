#!/bin/bash

# ==========================================
# MÓDULO DE CONFIGURACIÓN - config.sh
# ==========================================
# Gestiona la configuración del sistema, variables de entorno,
# archivos de configuración y configuración inicial

# Variables globales de configuración
USER_HOME="$HOME"
CONFIG_DIR="$USER_HOME/.config/coder-cli"
BIN_DIR="$USER_HOME/.local/bin"
LOG_FILE="$CONFIG_DIR/coder.log"
CONFIG_FILE="$CONFIG_DIR/config.json"
DEBUG=false
VERSION="1.0.1"

# Inicializar directorios necesarios
init_config_directories() {
    mkdir -p "$CONFIG_DIR"
    mkdir -p "$BIN_DIR"
}

# Función para escribir logs
log() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" >> "$LOG_FILE" 2>/dev/null || true
    if $DEBUG; then
        echo "LOG: $1"
    fi
}

# Función para actualizar un valor en el archivo de configuración
update_config_value() {
    local key="$1"
    local value="$2"
    
    # Crear archivo de configuración si no existe
    touch "$CONFIG_FILE"
    
    # Si la clave ya existe, actualizarla; si no, agregarla
    if grep -q "^${key}=" "$CONFIG_FILE"; then
        # Usar sed para actualizar la línea existente (compatible con macOS)
        sed -i '' "s|^${key}=.*|${key}='${value}'|" "$CONFIG_FILE"
    else
        # Agregar nueva línea
        echo "${key}='${value}'" >> "$CONFIG_FILE"
    fi
    
    chmod 600 "$CONFIG_FILE"
}

# Función para obtener un valor del archivo de configuración
get_config_value() {
    local key="$1"
    if [ -f "$CONFIG_FILE" ]; then
        grep "^${key}=" "$CONFIG_FILE" | cut -d"'" -f2
    fi
}

# Función para verificar si la configuración actual es válida
is_config_valid() {
    if [ ! -f "$CONFIG_FILE" ]; then
        return 1
    fi
    
    source "$CONFIG_FILE" 2>/dev/null || return 1
    
    # Verificar que hay un LLM seleccionado
    if [ -z "$llm_choice" ]; then
        return 1
    fi
    
    # Verificar que la API key correspondiente existe
    case "$llm_choice" in
        "chatgpt")
            [ -n "$chatgpt_api_key" ] || return 1
            ;;
        "claude")
            [ -n "$claude_api_key" ] || return 1
            ;;
        "gemini")
            [ -n "$gemini_api_key" ] || return 1
            ;;
        *)
            return 1
            ;;
    esac
    
    # Verificar que hay un modelo configurado
    if [ -z "$model" ]; then
        return 1
    fi
    
    return 0
}

# Función para obtener configuración de API
get_api_config() {
    # Si la configuración es válida, solo cargarla
    if is_config_valid; then
        source "$CONFIG_FILE"
        return 0
    fi
    
    # Si no es válida, proceder con la configuración
    if [ -f "$CONFIG_FILE" ]; then
        source "$CONFIG_FILE"
    fi

    if [ -z "$llm_choice" ] || { [ -z "$chatgpt_api_key" ] && [ -z "$claude_api_key" ] && [ -z "$gemini_api_key" ]; }; then
        update_llm_choice
    fi

    if [ "$llm_choice" == "chatgpt" ] && [ -z "$chatgpt_api_key" ]; then
        update_api_token
    elif [ "$llm_choice" == "claude" ] && [ -z "$claude_api_key" ]; then
        update_api_token
    elif [ "$llm_choice" == "gemini" ] && [ -z "$gemini_api_key" ]; then
        update_api_token
    fi

    if [ -z "$model" ]; then
        update_model
    fi
}

# Función para mostrar el estado completo de configuración
mostrar_estado_configuracion() {
    local CYAN='\033[0;36m'
    local GREEN='\033[0;32m'
    local RED='\033[0;31m'
    local YELLOW='\033[1;33m'
    local BOLD='\033[1m'
    local DIM='\033[2m'
    local NC='\033[0m'
    
    clear
    echo -e "${CYAN}${BOLD}⚙️  CONFIGURACIÓN DE ASIS-CODER${NC}"
    echo -e "${DIM}════════════════════════════════════════════════════════════════${NC}"
    echo ""
    
    if [ -f "$CONFIG_FILE" ]; then
        source "$CONFIG_FILE" 2>/dev/null || true
        
        echo -e "${YELLOW}${BOLD}🤖 Configuración de LLMs:${NC}"
        echo -e "${DIM}────────────────────────────────────────────────────────────────${NC}"
        
        # ChatGPT
        if [ -n "$chatgpt_api_key" ]; then
            echo -e "   ${GREEN}✓${NC} ChatGPT: API configurada"
            if [ "$llm_choice" == "chatgpt" ]; then
                echo -e "     ${BOLD}→ ACTIVO${NC} (Modelo: ${model:-gpt-4o-mini})"
            fi
        else
            echo -e "   ${RED}✗${NC} ChatGPT: No configurado"
        fi
        
        # Claude
        if [ -n "$claude_api_key" ]; then
            echo -e "   ${GREEN}✓${NC} Claude: API configurada"
            if [ "$llm_choice" == "claude" ]; then
                echo -e "     ${BOLD}→ ACTIVO${NC} (Modelo: ${model:-claude-3-5-sonnet-20241022})"
            fi
        else
            echo -e "   ${RED}✗${NC} Claude: No configurado"
        fi
        
        # Gemini
        if [ -n "$gemini_api_key" ]; then
            echo -e "   ${GREEN}✓${NC} Gemini: API configurada"
            if [ "$llm_choice" == "gemini" ]; then
                echo -e "     ${BOLD}→ ACTIVO${NC} (Modelo: ${model:-gemini-2.5-flash})"
            fi
        else
            echo -e "   ${RED}✗${NC} Gemini: No configurado"
        fi
        
        echo ""
        echo -e "${YELLOW}${BOLD}📋 Opciones disponibles:${NC}"
        echo -e "${DIM}────────────────────────────────────────────────────────────────${NC}"
        echo -e "   ${CYAN}1.${NC} Cambiar LLM activo"
        echo -e "   ${CYAN}2.${NC} Configurar nueva API key"
        echo -e "   ${CYAN}3.${NC} Cambiar modelo"
        echo -e "   ${CYAN}4.${NC} Probar configuración"
        echo -e "   ${CYAN}5.${NC} Salir"
        
        echo ""
        read -p "$(echo -e "${YELLOW}Selecciona una opción (1-5): ${NC}")" config_option
        
        case $config_option in
            1)
                update_llm_choice
                ;;
            2)
                get_api_config
                update_api_token
                ;;
            3)
                get_api_config
                update_model
                ;;
            4)
                source "$CONFIG_DIR/../lib/api_validation.sh"
                probar_configuracion_api
                ;;
            5)
                echo "Saliendo de la configuración."
                ;;
            *)
                echo "Opción no válida."
                ;;
        esac
    else
        echo -e "${RED}❌ No se encontró archivo de configuración${NC}"
        echo -e "${YELLOW}💡 Ejecuta: ${CYAN}coder setup${NC} para configurar inicial"
    fi
}

# Función para verificar dependencias del sistema
check_dependencies() {
    local missing_deps=()
    
    # Verificar dependencias requeridas
    for cmd in curl jq file; do
        if ! command -v "$cmd" >/dev/null 2>&1; then
            missing_deps+=("$cmd")
        fi
    done
    
    if [ ${#missing_deps[@]} -ne 0 ]; then
        echo "❌ Dependencias faltantes: ${missing_deps[*]}"
        echo "💡 Instala las dependencias faltantes antes de continuar."
        return 1
    fi
    
    return 0
}

# Función para configurar el entorno
setup_environment() {
    init_config_directories
    
    # Verificar si el binario está en el PATH
    if ! echo "$PATH" | grep -q "$BIN_DIR"; then
        echo "export PATH=\"\$PATH:$BIN_DIR\"" >> "$HOME/.bashrc"
        echo "export PATH=\"\$PATH:$BIN_DIR\"" >> "$HOME/.zshrc" 2>/dev/null || true
        echo "💡 Se agregó $BIN_DIR al PATH. Reinicia tu terminal o ejecuta: source ~/.bashrc"
    fi
}

# Función de limpieza
cleanup() {
    # Limpiar archivos temporales
    rm -f /tmp/chatgpt_validation_*
    rm -f /tmp/claude_validation_*
    rm -f /tmp/gemini_validation_*
    rm -f /tmp/coder_temp_*
} 