#!/bin/bash

# Configurar directorios y archivos
USER_HOME="$HOME"
CONFIG_DIR="$USER_HOME/.config/coder-cli"
BIN_DIR="$USER_HOME/.local/bin"
LOG_FILE="$CONFIG_DIR/coder.log"
CONFIG_FILE="$CONFIG_DIR/config.json"

# Variable de depuración y versión
DEBUG=false
VERSION="1.0.1"

# Crear directorios necesarios
mkdir -p "$CONFIG_DIR"
mkdir -p "$BIN_DIR"

# Función para escribir logs
log() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" >> "$LOG_FILE" 2>/dev/null || true
    if $DEBUG; then
        echo "LOG: $1"
    fi
}

# Función para validar API key de ChatGPT
validar_chatgpt_api() {
    local api_key="$1"
    local temp_file="/tmp/chatgpt_validation_$$"
    local test_response
    
    test_response=$(curl -s -w "%{http_code}" -o "$temp_file" \
        -H "Authorization: Bearer $api_key" \
        -H "Content-Type: application/json" \
        -d '{"model":"gpt-3.5-turbo","messages":[{"role":"user","content":"test"}],"max_tokens":1}' \
        https://api.openai.com/v1/chat/completions)
    
    if [[ "$test_response" == "200" ]]; then
        rm -f "$temp_file"
        return 0
    else
        # Leer el error para diagnóstico
        if [ -f "$temp_file" ]; then
            local error_content=$(cat "$temp_file" 2>/dev/null)
            if echo "$error_content" | grep -q "insufficient_quota"; then
                echo "ERROR_CREDITS"
            elif echo "$error_content" | grep -q "invalid_api_key"; then
                echo "ERROR_API_KEY"
            else
                echo "ERROR_UNKNOWN"
            fi
            rm -f "$temp_file"
        fi
        return 1
    fi
}

# Función para validar API key de Claude
validar_claude_api() {
    local api_key="$1"
    local temp_file="/tmp/claude_validation_$$"
    local test_response
    
    test_response=$(curl -s -w "%{http_code}" -o "$temp_file" \
        -H "x-api-key: $api_key" \
        -H "Content-Type: application/json" \
        -H "anthropic-version: 2023-06-01" \
        -d '{"model":"claude-3-5-sonnet-20241022","messages":[{"role":"user","content":"test"}],"max_tokens":1}' \
        https://api.anthropic.com/v1/messages)
    
    if [[ "$test_response" == "200" ]]; then
        rm -f "$temp_file"
        return 0
    else
        # Leer el error para diagnóstico
        if [ -f "$temp_file" ]; then
            local error_content=$(cat "$temp_file" 2>/dev/null)
            if echo "$error_content" | grep -q "credit balance is too low"; then
                echo "ERROR_CREDITS"
            elif echo "$error_content" | grep -q "invalid_request_error"; then
                echo "ERROR_API_KEY"
            else
                echo "ERROR_UNKNOWN"
            fi
            rm -f "$temp_file"
        fi
        return 1
    fi
}

# Función para validar API key de Gemini
validar_gemini_api() {
    local api_key="$1"
    local temp_file="/tmp/gemini_validation_$$"
    local test_response
    
    test_response=$(curl -s -w "%{http_code}" -o "$temp_file" \
        -H "Content-Type: application/json" \
        -d '{"contents":[{"parts":[{"text":"test"}]}]}' \
        "https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent?key=$api_key")
    
    if [[ "$test_response" == "200" ]]; then
        rm -f "$temp_file"
        return 0
    else
        # Leer el error para diagnóstico
        if [ -f "$temp_file" ]; then
            local error_content=$(cat "$temp_file" 2>/dev/null)
            if echo "$error_content" | grep -q "API_KEY_INVALID"; then
                echo "ERROR_API_KEY"
            elif echo "$error_content" | grep -q "QUOTA_EXCEEDED"; then
                echo "ERROR_CREDITS"
            else
                echo "ERROR_UNKNOWN"
            fi
            rm -f "$temp_file"
        fi
        return 1
    fi
}

# Función para mostrar estado de validación de API
mostrar_estado_validacion() {
    local CYAN='\033[0;36m'
    local GREEN='\033[0;32m'
    local RED='\033[0;31m'
    local YELLOW='\033[1;33m'
    local BOLD='\033[1m'
    local DIM='\033[2m'
    local NC='\033[0m'
    
    echo -e "${CYAN}${BOLD}🔍 Validando configuración de API...${NC}"
    echo -e "${DIM}────────────────────────────────────────────────────────────────${NC}"
    
    if [ -f "$CONFIG_FILE" ]; then
        source "$CONFIG_FILE" 2>/dev/null || true
        
        if [ -n "$llm_choice" ]; then
            echo -e "   ${YELLOW}⏳${NC} Verificando API de ${BOLD}$llm_choice${NC}..."
            
            if [ "$llm_choice" == "chatgpt" ] && [ -n "$chatgpt_api_key" ]; then
                local error_result=$(validar_chatgpt_api "$chatgpt_api_key")
                if [ $? -eq 0 ]; then
                    echo -e "   ${GREEN}✅ API de ChatGPT válida${NC}"
                    return 0
                else
                    case "$error_result" in
                        "ERROR_CREDITS")
                            echo -e "   ${RED}❌ ChatGPT: Sin créditos suficientes${NC}"
                            echo -e "   ${YELLOW}💡 Ve a platform.openai.com/account/billing${NC}"
                            ;;
                        "ERROR_API_KEY")
                            echo -e "   ${RED}❌ ChatGPT: API key inválida${NC}"
                            echo -e "   ${YELLOW}💡 Verifica tu API key en platform.openai.com${NC}"
                            ;;
                        *)
                            echo -e "   ${RED}❌ ChatGPT: Error desconocido${NC}"
                            ;;
                    esac
                    return 1
                fi
            elif [ "$llm_choice" == "claude" ] && [ -n "$claude_api_key" ]; then
                local error_result=$(validar_claude_api "$claude_api_key")
                if [ $? -eq 0 ]; then
                    echo -e "   ${GREEN}✅ API de Claude válida${NC}"
                    return 0
                else
                    case "$error_result" in
                        "ERROR_CREDITS")
                            echo -e "   ${RED}❌ Claude: Sin créditos suficientes${NC}"
                            echo -e "   ${YELLOW}💡 Ve a console.anthropic.com/settings/billing${NC}"
                            ;;
                        "ERROR_API_KEY")
                            echo -e "   ${RED}❌ Claude: API key inválida${NC}"
                            echo -e "   ${YELLOW}💡 Verifica tu API key en console.anthropic.com${NC}"
                            ;;
                        *)
                            echo -e "   ${RED}❌ Claude: Error desconocido${NC}"
                            ;;
                    esac
                    return 1
                fi
            elif [ "$llm_choice" == "gemini" ] && [ -n "$gemini_api_key" ]; then
                local error_result=$(validar_gemini_api "$gemini_api_key")
                if [ $? -eq 0 ]; then
                    echo -e "   ${GREEN}✅ API de Gemini válida${NC}"
                    return 0
                else
                    case "$error_result" in
                        "ERROR_CREDITS")
                            echo -e "   ${RED}❌ Gemini: Cuota excedida${NC}"
                            echo -e "   ${YELLOW}💡 Ve a console.cloud.google.com/apis/api/generativelanguage.googleapis.com${NC}"
                            ;;
                        "ERROR_API_KEY")
                            echo -e "   ${RED}❌ Gemini: API key inválida${NC}"
                            echo -e "   ${YELLOW}💡 Verifica tu API key en aistudio.google.com/app/apikey${NC}"
                            ;;
                        *)
                            echo -e "   ${RED}❌ Gemini: Error desconocido${NC}"
                            ;;
                    esac
                    return 1
                fi
            else
                echo -e "   ${RED}❌ API key no configurada para $llm_choice${NC}"
                return 1
            fi
        else
            echo -e "   ${RED}❌ LLM no configurado${NC}"
            return 1
        fi
    else
        echo -e "   ${RED}❌ Archivo de configuración no encontrado${NC}"
        return 1
    fi
}

# Función para mostrar error de configuración y ofrecer setup
mostrar_error_configuracion() {
    local CYAN='\033[0;36m'
    local RED='\033[0;31m'
    local YELLOW='\033[1;33m'
    local BOLD='\033[1m'
    local DIM='\033[2m'
    local NC='\033[0m'
    
    clear
    echo -e "${RED}${BOLD}"
    echo "    ╔══════════════════════════════════════════════════════════════╗"
    echo "    ║                    ⚠️  CONFIGURACIÓN REQUERIDA                ║"
    echo "    ╚══════════════════════════════════════════════════════════════╝"
    echo -e "${NC}"
    
    echo -e "${YELLOW}${BOLD}🔧 Configuración Necesaria${NC}"
    echo -e "${DIM}────────────────────────────────────────────────────────────────${NC}"
    echo -e "   Para usar Asis-coder necesitas configurar una API válida."
    echo ""
    echo -e "${CYAN}${BOLD}📋 Opciones disponibles:${NC}"
    echo -e "   ${CYAN}1.${NC} ChatGPT (OpenAI) - Requiere API key de platform.openai.com"
    echo -e "   ${CYAN}2.${NC} Claude (Anthropic) - Requiere API key de console.anthropic.com"
    echo -e "   ${CYAN}3.${NC} Gemini (Google Generative Language) - Requiere API key de aistudio.google.com/app/apikey"
    echo ""
    echo -e "${YELLOW}💡 Pasos para obtener API keys:${NC}"
    echo -e "${DIM}────────────────────────────────────────────────────────────────${NC}"
    echo -e "   ${BOLD}ChatGPT:${NC}"
    echo -e "   • Ve a https://platform.openai.com/"
    echo -e "   • Crea una cuenta e inicia sesión"
    echo -e "   • Ve a 'API Keys' y crea una nueva"
    echo -e "   • Asegúrate de tener créditos en tu cuenta"
    echo ""
    echo -e "   ${BOLD}Claude:${NC}"
    echo -e "   • Ve a https://console.anthropic.com/"
    echo -e "   • Regístrate y obtén acceso a la API"
    echo -e "   • Genera tu API key en el dashboard"
    echo ""
    echo -e "   ${BOLD}Gemini:${NC}"
    echo -e "   • Ve a https://console.cloud.google.com/apis/api/generativelanguage.googleapis.com"
    echo -e "   • Regístrate y obtén acceso a la API"
    echo -e "   • Genera tu API key en el dashboard"
    echo ""
    echo -e "${DIM}────────────────────────────────────────────────────────────────${NC}"
    echo -e "${YELLOW}${BOLD}🛠️  Opciones disponibles:${NC}"
    echo -e "   ${CYAN}1.${NC} Configurar una nueva API"
    echo -e "   ${CYAN}2.${NC} Cambiar a otro LLM (ChatGPT/Claude/Gemini)"
    echo -e "   ${CYAN}3.${NC} Salir y configurar más tarde"
    echo ""
    echo -e "${YELLOW}¿Qué quieres hacer? (1/2/3)${NC}"
    read -p "$(echo -e "${CYAN}> ${NC}")" setup_choice
    
    case "$setup_choice" in
        1)
            configuracion_inicial_completa
            ;;
        2)
            echo -e "${CYAN}Cambiando configuración de LLM...${NC}"
            update_llm_choice
            ;;
        3|*)
            echo -e "${DIM}Puedes configurar más tarde con: ${CYAN}coder setup${NC}"
            exit 0
            ;;
    esac
}

# Función para obtener la configuración de API
get_api_config() {
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
    echo -e "${CYAN}${BOLD}⚙️  Estado de Configuración de Asis-coder${NC}"
    echo -e "${DIM}════════════════════════════════════════════════════════════════${NC}"
    
    if [ -f "$CONFIG_FILE" ]; then
        source "$CONFIG_FILE" 2>/dev/null || true
        
        echo -e "${YELLOW}${BOLD}🤖 LLM Configurado:${NC}"
        if [ -n "$llm_choice" ]; then
            echo -e "   ${GREEN}✓${NC} Activo: ${BOLD}$llm_choice${NC}"
        else
            echo -e "   ${RED}✗${NC} No configurado"
        fi
        
        echo ""
        echo -e "${YELLOW}${BOLD}🔑 API Keys:${NC}"
        if [ -n "$chatgpt_api_key" ]; then
            local chatgpt_masked="${chatgpt_api_key:0:10}...${chatgpt_api_key: -4}"
            echo -e "   ${GREEN}✓${NC} ChatGPT: $chatgpt_masked"
        else
            echo -e "   ${RED}✗${NC} ChatGPT: No configurado"
        fi
        
        if [ -n "$claude_api_key" ]; then
            local claude_masked="${claude_api_key:0:10}...${claude_api_key: -4}"
            echo -e "   ${GREEN}✓${NC} Claude: $claude_masked"
        else
            echo -e "   ${RED}✗${NC} Claude: No configurado"
        fi
        
        if [ -n "$gemini_api_key" ]; then
            local gemini_masked="${gemini_api_key:0:10}...${gemini_api_key: -4}"
            echo -e "   ${GREEN}✓${NC} Gemini: $gemini_masked"
        else
            echo -e "   ${RED}✗${NC} Gemini: No configurado"
        fi
        
        echo ""
        echo -e "${YELLOW}${BOLD}🎯 Modelo Activo:${NC}"
        if [ -n "$model" ]; then
            echo -e "   ${GREEN}✓${NC} $model"
        else
            echo -e "   ${RED}✗${NC} No configurado"
        fi
        
    else
        echo -e "${RED}❌ No se encontró archivo de configuración${NC}"
    fi
    
    echo ""
    echo -e "${DIM}════════════════════════════════════════════════════════════════${NC}"
    echo -e "${CYAN}${BOLD}🛠️  Opciones de Configuración:${NC}"
    echo -e "   ${CYAN}1.${NC} Cambiar LLM activo"
    echo -e "   ${CYAN}2.${NC} Configurar nueva API key"
    echo -e "   ${CYAN}3.${NC} Cambiar modelo"
    echo -e "   ${CYAN}4.${NC} Probar configuración actual"
    echo -e "   ${CYAN}5.${NC} Salir"
    echo ""
    read -p "$(echo -e "${YELLOW}¿Qué quieres hacer? (1-5): ${NC}")" config_choice
    
    case "$config_choice" in
        1)
            update_llm_choice
            ;;
        2)
            if [ -n "$llm_choice" ]; then
                update_api_token
            else
                echo -e "${RED}❌ Primero selecciona un LLM${NC}"
                update_llm_choice
            fi
            ;;
        3)
            if [ -n "$llm_choice" ]; then
                update_model
            else
                echo -e "${RED}❌ Primero selecciona un LLM${NC}"
                update_llm_choice
            fi
            ;;
        4)
            probar_configuracion_api
            ;;
        5|*)
            echo -e "${GREEN}👋 ¡Hasta luego!${NC}"
            ;;
    esac
}

# Función para actualizar la elección del LLM
update_llm_choice() {
    # Cargar configuración existente
    if [ -f "$CONFIG_FILE" ]; then
        source "$CONFIG_FILE" 2>/dev/null || true
    fi
    
    echo -e "${CYAN}${BOLD}🤖 Selección de LLM${NC}"
    echo -e "${DIM}────────────────────────────────────────────────────────────────${NC}"
    
    # Mostrar APIs ya configuradas
    local chatgpt_configured=""
    local claude_configured=""
    local gemini_configured=""
    
    if [ -n "$chatgpt_api_key" ]; then
        chatgpt_configured=" ${GREEN}(✓ Configurado)${NC}"
    fi
    
    if [ -n "$claude_api_key" ]; then
        claude_configured=" ${GREEN}(✓ Configurado)${NC}"
    fi
    
    if [ -n "$gemini_api_key" ]; then
        gemini_configured=" ${GREEN}(✓ Configurado)${NC}"
    fi
    
    echo -e "1. ChatGPT${chatgpt_configured}"
    echo -e "2. Claude${claude_configured}"
    echo -e "3. Gemini${gemini_configured}"
    echo ""
    read -p "$(echo -e "${YELLOW}Selecciona el LLM que deseas usar (1/2/3): ${NC}")" choice

    case $choice in
        1)
            llm_choice="chatgpt"
            ;;
        2)
            llm_choice="claude"
            ;;
        3)
            llm_choice="gemini"
            ;;
        *)
            echo -e "${YELLOW}Opción no válida. Seleccionando ChatGPT por defecto.${NC}"
            llm_choice="chatgpt"
            ;;
    esac

    # Actualizar la elección del LLM sin sobrescribir el archivo
    update_config_value "llm_choice" "$llm_choice"
    log "LLM seleccionado: $llm_choice"
    
    # Solo pedir API token si no está configurado
    local current_api_key=""
    if [ "$llm_choice" == "chatgpt" ]; then
        current_api_key="$chatgpt_api_key"
    elif [ "$llm_choice" == "claude" ]; then
        current_api_key="$claude_api_key"
    elif [ "$llm_choice" == "gemini" ]; then
        current_api_key="$gemini_api_key"
    fi
    
    if [ -z "$current_api_key" ]; then
        echo -e "${YELLOW}⚠️  No tienes API key configurada para $llm_choice${NC}"
        update_api_token
    else
        echo -e "${GREEN}✅ API key ya configurada para $llm_choice${NC}"
    fi
    
    update_model
}

# Función para actualizar el token de API
update_api_token() {
    local token_var="${llm_choice}_api_key"
    
    echo -e "${YELLOW}🔑 Configuración de API Key para $llm_choice${NC}"
    echo -e "${DIM}────────────────────────────────────────────────────────────────${NC}"
    
    if [ "$llm_choice" == "chatgpt" ]; then
        echo -e "${CYAN}💡 Para obtener tu API key de ChatGPT:${NC}"
        echo -e "   1. Ve a https://platform.openai.com/api-keys"
        echo -e "   2. Crea una nueva API key"
        echo -e "   3. Asegúrate de tener créditos en tu cuenta"
    elif [ "$llm_choice" == "claude" ]; then
        echo -e "${CYAN}💡 Para obtener tu API key de Claude:${NC}"
        echo -e "   1. Ve a https://console.anthropic.com/settings/keys"
        echo -e "   2. Crea una nueva API key"
        echo -e "   3. Asegúrate de tener créditos en tu cuenta"
    elif [ "$llm_choice" == "gemini" ]; then
        echo -e "${CYAN}💡 Para obtener tu API key de Gemini:${NC}"
        echo -e "   1. Ve a https://aistudio.google.com/app/apikey"
        echo -e "   2. Crea una nueva API key"
        echo -e "   3. Gemini tiene cuota gratuita generosa"
    fi
    
    echo ""
    read -p "$(echo -e "${YELLOW}Por favor, introduce tu API token para $llm_choice: ${NC}")" api_key
    
    if [ -n "$api_key" ]; then
        # Usar la nueva función para actualizar sin sobrescribir
        update_config_value "$token_var" "$api_key"
        eval "$token_var='$api_key'"
        log "Token de API para $llm_choice actualizado."
        echo -e "${GREEN}✅ API key guardada correctamente${NC}"
    else
        echo -e "${RED}❌ No se proporcionó API key${NC}"
        return 1
    fi
}

# Función para actualizar el modelo
update_model() {
    if [ "$llm_choice" == "chatgpt" ]; then
        list_chatgpt_models
    elif [ "$llm_choice" == "claude" ]; then
        list_claude_models
    elif [ "$llm_choice" == "gemini" ]; then
        list_gemini_models
    fi
}

# Función para listar modelos de ChatGPT
list_chatgpt_models() {
    echo "Modelos disponibles de ChatGPT:"
    echo "1. gpt-3.5-turbo (Clásico, rápido y económico)"
    echo "2. gpt-4 (Modelo base GPT-4)"
    echo "3. gpt-4-turbo (Equilibrio precio/rendimiento)"
    echo "4. gpt-4o (Omni - Multimodal potente)"
    echo "5. gpt-4o-mini (Económico y rápido)"
    echo "6. o1 (Razonamiento avanzado)"
    echo "7. o1-mini (Razonamiento rápido)"
    echo "8. o1-preview (Vista previa de razonamiento)"
    echo "9. o3-mini (Nuevo modelo de razonamiento)"
    echo "10. o4-mini (Último modelo compacto)"
    echo "11. gpt-4.1 (Nueva generación)"
    echo "12. gpt-4.1-mini (Compacto nueva generación)"
    echo "13. gpt-4.1-nano (Ultra compacto)"
    echo "14. gpt-4.5 (Modelo más avanzado)"
    read -p "Selecciona el número del modelo que deseas usar: " model_choice

    case $model_choice in
        1)
            model="gpt-3.5-turbo"
            ;;
        2)
            model="gpt-4"
            ;;
        3)
            model="gpt-4-turbo"
            ;;
        4)
            model="gpt-4o"
            ;;
        5)
            model="gpt-4o-mini"
            ;;
        6)
            model="o1"
            ;;
        7)
            model="o1-mini"
            ;;
        8)
            model="o1-preview"
            ;;
        9)
            model="o3-mini"
            ;;
        10)
            model="o4-mini"
            ;;
        11)
            model="gpt-4.1"
            ;;
        12)
            model="gpt-4.1-mini"
            ;;
        13)
            model="gpt-4.1-nano"
            ;;
        14)
            model="gpt-4.5"
            ;;
        *)
            echo "Opción no válida. Seleccionando gpt-4o-mini por defecto."
            model="gpt-4o-mini"
            ;;
    esac

    update_config_value "model" "$model"
    log "Modelo seleccionado: $model"
}

# Función para listar modelos de Claude
list_claude_models() {
    echo "Modelos disponibles de Claude:"
    echo "1. claude-opus-4-20250514 (Claude 4 - Más potente e inteligente)"
    echo "2. claude-sonnet-4-20250514 (Claude 4 - Alto rendimiento)"
    echo "3. claude-3-7-sonnet-20250219 (Claude 3.7 - Pensamiento extendido)"
    echo "4. claude-3-5-sonnet-20241022 (Claude 3.5 v2 - Más reciente)"
    echo "5. claude-3-5-sonnet-20240620 (Claude 3.5 v1 - Estable)"
    echo "6. claude-3-5-haiku-20241022 (Rápido y económico)"
    echo "7. claude-3-opus-20240229 (Más inteligente legacy)"
    echo "8. claude-3-haiku-20240307 (Ultrarrápido legacy)"
    read -p "Selecciona el número del modelo que deseas usar: " model_choice

    case $model_choice in
        1)
            model="claude-opus-4-20250514"
            ;;
        2)
            model="claude-sonnet-4-20250514"
            ;;
        3)
            model="claude-3-7-sonnet-20250219"
            ;;
        4)
            model="claude-3-5-sonnet-20241022"
            ;;
        5)
            model="claude-3-5-sonnet-20240620"
            ;;
        6)
            model="claude-3-5-haiku-20241022"
            ;;
        7)
            model="claude-3-opus-20240229"
            ;;
        8)
            model="claude-3-haiku-20240307"
            ;;
        *)
            echo "Opción no válida. Seleccionando claude-3-5-sonnet-20241022 por defecto."
            model="claude-3-5-sonnet-20241022"
            ;;
    esac

    update_config_value "model" "$model"
    log "Modelo seleccionado: $model"
}

# Función para listar modelos de Gemini
list_gemini_models() {
    echo "Modelos disponibles de Gemini:"
    echo "1. gemini-2.5-pro (Más potente con pensamiento)"
    echo "2. gemini-2.5-flash (Mejor equilibrio precio/rendimiento)"
    echo "3. gemini-2.5-flash-lite (Ultra económico)"
    echo "4. gemini-2.0-flash (Generación 2.0 estándar)"
    echo "5. gemini-2.0-flash-lite (Generación 2.0 económico)"
    echo "6. gemini-1.5-pro (Legacy Pro)"
    echo "7. gemini-1.5-flash (Legacy Flash)"
    echo "8. gemini-1.5-flash-8b (Legacy compacto)"
    read -p "Selecciona el número del modelo que deseas usar: " model_choice

    case $model_choice in
        1)
            model="gemini-2.5-pro"
            ;;
        2)
            model="gemini-2.5-flash"
            ;;
        3)
            model="gemini-2.5-flash-lite"
            ;;
        4)
            model="gemini-2.0-flash"
            ;;
        5)
            model="gemini-2.0-flash-lite"
            ;;
        6)
            model="gemini-1.5-pro"
            ;;
        7)
            model="gemini-1.5-flash"
            ;;
        8)
            model="gemini-1.5-flash-8b"
            ;;
        *)
            echo "Opción no válida. Seleccionando gemini-2.5-flash por defecto."
            model="gemini-2.5-flash"
            ;;
    esac

    update_config_value "model" "$model"
    log "Modelo seleccionado: $model"
}

# Función mejorada para escapar JSON
json_escape() {
    local string="$1"
    string="${string//\\/\\\\}"
    string="${string//\"/\\\"}"
    string="${string//$'\n'/\\n}"
    string="${string//$'\r'/\\r}"
    string="${string//$'\t'/\\t}"
    echo "$string"
}

# Función para detectar automáticamente el tipo de proyecto
detectar_tipo_proyecto() {
    local directorio_actual=$(pwd)
    
    # React
    if [[ -f "$directorio_actual/package.json" ]]; then
        local package_content=$(cat "$directorio_actual/package.json")
        if echo "$package_content" | grep -q "react"; then
            echo "🔍 Proyecto React detectado automáticamente"
            tipo_proyecto=1
            return
        elif echo "$package_content" | grep -q "vue"; then
            echo "🔍 Proyecto Vue.js detectado automáticamente"
            tipo_proyecto=3
            return
        elif echo "$package_content" | grep -q "angular"; then
            echo "🔍 Proyecto Angular detectado automáticamente"
            tipo_proyecto=4
            return
        elif echo "$package_content" | grep -q "express"; then
            echo "🔍 Proyecto Express.js detectado automáticamente"
            tipo_proyecto=9
            return
        else
            echo "🔍 Proyecto Node.js detectado automáticamente"
            tipo_proyecto=2
            return
        fi
    fi
    
    # Ruby on Rails
    if [[ -f "$directorio_actual/Gemfile" ]] && grep -q "rails" "$directorio_actual/Gemfile"; then
        echo "🔍 Proyecto Ruby on Rails detectado automáticamente"
        tipo_proyecto=5
        return
    fi
    
    # Laravel
    if [[ -f "$directorio_actual/composer.json" ]] && grep -q "laravel" "$directorio_actual/composer.json"; then
        echo "🔍 Proyecto Laravel detectado automáticamente"
        tipo_proyecto=6
        return
    fi
    
    # Flask/Django
    if [[ -f "$directorio_actual/requirements.txt" ]]; then
        if grep -q "flask" "$directorio_actual/requirements.txt"; then
            echo "🔍 Proyecto Flask detectado automáticamente"
            tipo_proyecto=7
            return
        elif grep -q "django" "$directorio_actual/requirements.txt"; then
            echo "🔍 Proyecto Django detectado automáticamente"
            tipo_proyecto=7
            return
        fi
    fi
    
    # Spring Boot
    if [[ -f "$directorio_actual/pom.xml" ]] && grep -q "spring-boot" "$directorio_actual/pom.xml"; then
        echo "🔍 Proyecto Spring Boot detectado automáticamente"
        tipo_proyecto=8
        return
    fi
    
    # Flutter
    if [[ -f "$directorio_actual/pubspec.yaml" ]] && grep -q "flutter" "$directorio_actual/pubspec.yaml"; then
        echo "🔍 Proyecto Flutter detectado automáticamente"
        tipo_proyecto=10
        return
    fi
    
    # Si no se detecta automáticamente, preguntar al usuario
    preguntar_tipo_proyecto_manual
}

# Función para preguntar al usuario el tipo de proyecto
preguntar_tipo_proyecto_manual() {
    echo "❓ No se pudo detectar el tipo de proyecto automáticamente."
    echo "Selecciona el tipo de proyecto:"
    echo "1. React"
    echo "2. Node.js"
    echo "3. Vue.js"
    echo "4. Angular"
    echo "5. Ruby on Rails"
    echo "6. Laravel"
    echo "7. Flask/Django"
    echo "8. Spring Boot"
    echo "9. Express.js"
    echo "10. Flutter"
    echo "11. Bash"
    echo "12. Genérico (detectar automáticamente)"
    read -p "Introduce el número correspondiente: " tipo_proyecto
}

# Función para definir los directorios y archivos a ignorar según el tipo de proyecto
definir_directorios_y_ignorar() {
    case $tipo_proyecto in
        1)
            directorios=("src" "components" "utils" "hooks" "constants")
            ;;
        2)
            directorios=("src" "lib" "controllers" "models" "middlewares" "routes" "utils")
            ;;
        3)
            directorios=("src" "components" "views" "store" "router" "utils")
            ;;
        4)
            directorios=("src" "app" "components" "services" "shared" "utils")
            ;;
        5)
            directorios=("app" "lib" "config" "db" "models" "controllers" "views" "helpers" "assets")
            ;;
        6)
            directorios=("app" "resources" "config" "database" "routes" "public" "storage")
            ;;
        7)
            directorios=("app" "static" "templates" "utils" "migrations" "config")
            ;;
        8)
            directorios=("src" "main" "java" "resources" "config")
            ;;
        9)
            directorios=("src" "lib" "controllers" "models" "middlewares" "routes" "utils")
            ;;
        10)
            directorios=("lib" "assets" "test" "config")
            ;;
        11)
            directorios=("lib" "assets" "test" "config")
            ;;  
        *)
            log "Opción no válida. Saliendo..."
            exit 1
            ;;
    esac

    archivos_ignorar=("*.ico" "*.png" "*.jpg" "*.jpeg" "*.gif" "*.svg" "*.pyc" "*.pyo" "__pycache__" "*.class" "*.jar" "*.woff" "*.woff2" "*.ttf" "*.otf" "*.eot")
}

# Función para verificar si un archivo es de texto
es_archivo_texto() {
    local archivo="$1"
    if file "$archivo" | grep -qE 'text|ASCII|UTF-8'; then
        return 0
    else
        return 1
    fi
}

# Función recursiva para leer archivos y agregar su contenido
leer_archivos() {
    local dir_actual="$1"
    log "Leyendo archivos en: $dir_actual"

    for entrada in "$dir_actual"/*; do
        if [ -d "$entrada" ]; then
            leer_archivos "$entrada"
        elif [ -f "$entrada" ]; then
            log "Procesando archivo: $entrada"
            for patron_ignorar in "${archivos_ignorar[@]}"; do
                if [[ "$entrada" == $patron_ignorar ]]; then
                    log "Ignorando archivo: $entrada"
                    continue 2
                fi
            done

            if es_archivo_texto "$entrada"; then
                ruta_relativa=${entrada#"$directorio_proyecto/"}
                log "Añadiendo al contexto: $ruta_relativa"
                echo "// Archivo: $ruta_relativa" >> "$archivo_salida"
                cat "$entrada" >> "$archivo_salida"
                echo "" >> "$archivo_salida"
            else
                log "No es un archivo de texto: $entrada"
            fi
        fi
    done
}

# Función para generar el archivo de contexto
generar_contexto() {
    log "Generando archivo de contexto..."
    
    # Detectar automáticamente el tipo de proyecto
    detectar_tipo_proyecto

    # Definir los directorios y archivos a ignorar según el tipo de proyecto
    definir_directorios_y_ignorar

    log "Tipo de proyecto seleccionado: $tipo_proyecto"
    log "Directorios definidos: ${directorios[*]}"

    # Buscar la carpeta raíz del proyecto
    local directorio_proyecto=$(pwd)

    # Establecer el nombre del archivo de salida en el directorio del proyecto
    archivo_salida="$directorio_proyecto/contexto_codigo.txt"

    log "Directorio del proyecto: $directorio_proyecto"
    log "Archivo de salida: $archivo_salida"

    if [ ! -w "$(dirname "$archivo_salida")" ]; then
        log "Error: No se puede escribir en el directorio $(dirname "$archivo_salida")"
        exit 1
    fi

    # Si el archivo de salida existe, eliminarlo
    [ -f "$archivo_salida" ] && rm "$archivo_salida"

    echo "Directorio del proyecto: $directorio_proyecto"
    echo "Directorios a buscar: ${directorios[@]}"
    echo "Archivo de salida: $archivo_salida"

    # Llamar a la función recursiva para cada directorio especificado
    for dir in "${directorios[@]}"; do
        [ -d "${directorio_proyecto}/${dir}" ] && leer_archivos "${directorio_proyecto}/${dir}"
    done

    if [ ! -s "$archivo_salida" ]; then
        log "Advertencia: El archivo de contexto está vacío. No se encontraron archivos para procesar."
    else
        log "Archivo de contexto generado con éxito en $archivo_salida"
    fi
}

# Función para encontrar el archivo de contexto
encontrar_archivo_contexto() {
    local directorio_actual=$(pwd)
    local archivo_contexto="contexto_codigo.txt"

    # Buscar en el directorio actual y padres hasta la raíz
    while [[ "$directorio_actual" != "/" ]]; do
        if [[ -f "$directorio_actual/$archivo_contexto" ]]; then
            echo "$directorio_actual/$archivo_contexto"
            return 0
        fi
        directorio_actual=$(dirname "$directorio_actual")
    done

    echo ""
    return 1
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

# Función para consultar al LLM
consultar_llm() {
    local pregunta="$1"
    if $DEBUG; then
        echo "Consulta recibida en consultar_llm:"
        echo "$pregunta"
        echo "Obteniendo configuración de API..."
    fi
    
    # Validar API antes de hacer consulta (solo si no estamos en modo interactivo)
    if [ -z "$MODO_INTERACTIVO" ]; then
        if ! mostrar_estado_validacion >/dev/null 2>&1; then
            mostrar_error_configuracion
            return 1
        fi
    fi
    
    get_api_config

    if $DEBUG; then
        echo "Coder CLI versión: $VERSION"
        echo "Configuración actual:"
        echo "LLM: $llm_choice"
        echo "Modelo: $model"
    fi
    
    log "Enviando consulta a $llm_choice..."
    local escaped_prompt=$(json_escape "$pregunta")
    
    if [ "$llm_choice" == "chatgpt" ]; then
        local json_data='{
            "model": "'"$model"'",
            "messages": [{"role": "user", "content": "'"$escaped_prompt"'"}],
            "max_tokens": 1000,
            "temperature": 0.5
        }'
        local api_url="https://api.openai.com/v1/chat/completions"
        local api_key="$chatgpt_api_key"
        local auth_header="Authorization: Bearer $api_key"
    elif [ "$llm_choice" == "claude" ]; then
        local json_data='{
            "model": "'"$model"'",
            "messages": [{"role": "user", "content": "'"$escaped_prompt"'"}],
            "max_tokens": 1000,
            "temperature": 0.5
        }'
        local api_url="https://api.anthropic.com/v1/messages"
        local api_key="$claude_api_key"
        local auth_header="x-api-key: $api_key"
        local extra_header="anthropic-version: 2023-06-01"
    elif [ "$llm_choice" == "gemini" ]; then
        local json_data='{
            "contents": [{
                "parts": [{"text": "'"$escaped_prompt"'"}]
            }],
            "generationConfig": {
                "maxOutputTokens": 1000,
                "temperature": 0.5
            }
        }'
        local api_url="https://generativelanguage.googleapis.com/v1beta/models/$model:generateContent?key=$gemini_api_key"
        local auth_header="Content-Type: application/json"
    fi

    if $DEBUG; then
        echo "Petición enviada a $api_url:"
        echo "$json_data"
    fi

    if [ "$llm_choice" == "gemini" ]; then
        local response=$(curl -s -H "Content-Type: application/json" \
                              -d "$json_data" \
                              "$api_url")
    else
        local response=$(curl -s -H "Content-Type: application/json" \
                              -H "$auth_header" \
                              ${extra_header:+-H "$extra_header"} \
                              -d "$json_data" \
                              "$api_url")
    fi

    if $DEBUG; then
        echo "Respuesta recibida:"
        echo "$response"
    fi

    if [ $? -eq 0 ]; then
        if [ "$llm_choice" == "chatgpt" ]; then
            local content=$(echo "$response" | jq -r '.choices[0].message.content' 2>/dev/null)
        elif [ "$llm_choice" == "claude" ]; then
            local content=$(echo "$response" | jq -r '.content[0].text' 2>/dev/null)
        elif [ "$llm_choice" == "gemini" ]; then
            local content=$(echo "$response" | jq -r '.candidates[0].content.parts[0].text' 2>/dev/null)
        fi

        if [ -n "$content" ] && [ "$content" != "null" ]; then
            echo "$content"
        else
            echo "❌ Error: No se pudo extraer el contenido de la respuesta."
            if $DEBUG; then
                echo "Respuesta completa: $response"
            fi
            
            # Verificar errores específicos de la API
            local error_message=$(echo "$response" | jq -r '.error.message // .error.details // empty' 2>/dev/null)
            if [ -n "$error_message" ] && [ "$error_message" != "null" ]; then
                echo "💡 Error de API: $error_message"
                if echo "$error_message" | grep -qi "credit"; then
                    echo "🔥 Parece que no tienes créditos suficientes en tu cuenta."
                elif echo "$error_message" | grep -qi "key"; then
                    echo "🔑 Verifica que tu API key sea válida."
                fi
            fi
        fi
    else
        log "Error al recibir respuesta de $llm_choice."
        echo "❌ Error: No se pudo obtener una respuesta del servidor."
        echo "💡 Verifica tu conexión a internet y tu API key."
    fi
}

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
    
    echo -e "${DIM}    ────────────────────────────────────────────────────────────────${NC}"
    echo ""
    echo -e "${GREEN}${BOLD}💡 Comandos de ejemplo:${NC}"
    echo -e "${DIM}    • \"explica la arquitectura de este proyecto\"${NC}"
    echo -e "${DIM}    • \"encuentra posibles bugs en mi código\"${NC}"
    echo -e "${DIM}    • \"genera tests para el módulo principal\"${NC}"
    echo -e "${DIM}    • \"cómo puedo optimizar el rendimiento?\"${NC}"
    echo -e "${DIM}    • \"documenta esta función\"${NC}"
    echo ""
    echo -e "${YELLOW}💬 Comandos de control:${NC}"
    echo -e "${DIM}    • 'salir', 'exit' o 'quit' para terminar${NC}"
    echo -e "${DIM}    • Ctrl+C para interrumpir${NC}"
    echo -e "${DIM}    ────────────────────────────────────────────────────────────────${NC}"
    echo ""
}

# Función para validar configuración antes de mostrar UI
validar_y_mostrar_ui() {
    # Validar API antes de mostrar la interfaz
    if ! mostrar_estado_validacion; then
        echo ""
        mostrar_error_configuracion
        return 1
    fi
    
    echo ""
    sleep 1
    mostrar_ui_principal
}

# Función para mostrar la UI principal (cuando se ejecuta coder sin argumentos)
mostrar_ui_principal() {
    clear
    
    # Colores
    local CYAN='\033[0;36m'
    local PURPLE='\033[0;35m'
    local GREEN='\033[0;32m'
    local YELLOW='\033[1;33m'
    local BLUE='\033[0;34m'
    local RED='\033[0;31m'
    local BOLD='\033[1m'
    local DIM='\033[2m'
    local NC='\033[0m'
    
    # Banner principal
    echo -e "${CYAN}${BOLD}"
    echo "    ╔══════════════════════════════════════════════════════════════╗"
    echo "    ║                    ASIS-CODER v$VERSION                        ║"
    echo "    ║              🤖 Tu Asistente de Desarrollo IA                ║"
    echo "    ╚══════════════════════════════════════════════════════════════╝"
    echo -e "${NC}"
    
    # Estado rápido
    local proyecto_detectado=$(detectar_proyecto_actual)
    local contexto_existe=$(encontrar_archivo_contexto)
    local configurado=false
    
    if [ -f "$CONFIG_FILE" ]; then
        source "$CONFIG_FILE" 2>/dev/null || true
        if [ -n "$llm_choice" ]; then
            configurado=true
        fi
    fi
    
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
    echo -e "${GREEN}${BOLD}🚀 Comandos Principales:${NC}"
    echo -e "${DIM}  ────────────────────────────────────────────────────────────────${NC}"
    
    if ! $configurado; then
        echo -e "  ${CYAN}coder setup${NC}                  # Configuración inicial"
    fi
    
    echo -e "  ${CYAN}coder -i${NC}                     # Modo chat interactivo"
    echo -e "  ${CYAN}coder \"tu pregunta\"${NC}          # Consulta directa"
    echo -e "  ${CYAN}coder -contexto${NC}              # Generar contexto del proyecto"
    echo -e "  ${CYAN}coder /init${NC}                  # Inicializar proyecto"
    
    echo ""
    echo -e "${PURPLE}${BOLD}⚙️  Configuración:${NC}"
    echo -e "${DIM}  ────────────────────────────────────────────────────────────────${NC}"
    echo -e "  ${CYAN}coder config${NC}                 # Estado y configuración completa"
    echo -e "  ${CYAN}coder -llm${NC}                   # Cambiar modelo de IA"
    echo -e "  ${CYAN}coder -model${NC}                 # Cambiar modelo específico"
    echo -e "  ${CYAN}coder -token${NC}                 # Actualizar API token"
    
    echo ""
    echo -e "${YELLOW}${BOLD}📚 Utilidades:${NC}"
    echo -e "${DIM}  ────────────────────────────────────────────────────────────────${NC}"
    echo -e "  ${CYAN}coder historial${NC}              # Ver historial de chats"
    echo -e "  ${CYAN}coder -clean${NC}                 # Limpiar historial"
    echo -e "  ${CYAN}coder -new${NC}                   # Nuevo hito de conversación"
    echo -e "  ${CYAN}coder -v${NC}                     # Ver versión"
    
    echo ""
    echo -e "${GREEN}${BOLD}💡 Ejemplos de Uso:${NC}"
    echo -e "${DIM}  ────────────────────────────────────────────────────────────────${NC}"
    echo -e '  📝 coder "explica este proyecto"'
    echo -e '  🔍 coder "encuentra bugs potenciales"'
    echo -e '  🧪 coder "genera tests unitarios"'
    echo -e '  📚 coder "documenta esta función"'
    echo -e '  🔧 coder "optimiza este código"'
    
    echo ""
    echo -e "${DIM}  ────────────────────────────────────────────────────────────────${NC}"
    echo -e "${DIM}  💡 Tip: Usa ${CYAN}coder setup${DIM} si es tu primera vez${NC}"
    echo -e "${DIM}  ────────────────────────────────────────────────────────────────${NC}"
}

# Función para probar la configuración de API
probar_configuracion_api() {
    local CYAN='\033[0;36m'
    local GREEN='\033[0;32m'
    local RED='\033[0;31m'
    local YELLOW='\033[1;33m'
    local BOLD='\033[1m'
    local DIM='\033[2m'
    local NC='\033[0m'
    
    echo -e "${CYAN}${BOLD}🧪 Probando Configuración de API${NC}"
    echo -e "${DIM}────────────────────────────────────────────────────────────────${NC}"
    
    if [ -f "$CONFIG_FILE" ]; then
        source "$CONFIG_FILE" 2>/dev/null || true
        
        if [ -n "$llm_choice" ]; then
            echo -e "   ${YELLOW}🤖 LLM configurado:${NC} ${BOLD}$llm_choice${NC}"
            if [ -n "$model" ]; then
                echo -e "   ${YELLOW}📋 Modelo:${NC} ${BOLD}$model${NC}"
            fi
            echo ""
            
            echo -e "   ${YELLOW}⏳ Realizando prueba de conexión...${NC}"
            
            if [ "$llm_choice" == "chatgpt" ] && [ -n "$chatgpt_api_key" ]; then
                local error_result=$(validar_chatgpt_api "$chatgpt_api_key")
                if [ $? -eq 0 ]; then
                    echo -e "   ${GREEN}✅ API de ChatGPT funciona correctamente${NC}"
                    echo ""
                    echo -e "   ${YELLOW}📝 Realizando prueba de consulta...${NC}"
                    local test_result=$(consultar_llm "Di solo 'Hola desde ChatGPT'")
                    echo -e "   ${GREEN}💬 Respuesta:${NC} $test_result"
                else
                    case "$error_result" in
                        "ERROR_CREDITS")
                            echo -e "   ${RED}❌ ChatGPT: Sin créditos suficientes${NC}"
                            echo -e "   ${YELLOW}💡 Ve a platform.openai.com/account/billing para agregar créditos${NC}"
                            ;;
                        "ERROR_API_KEY")
                            echo -e "   ${RED}❌ ChatGPT: API key inválida${NC}"
                            echo -e "   ${YELLOW}💡 Verifica tu API key en platform.openai.com${NC}"
                            ;;
                        *)
                            echo -e "   ${RED}❌ Error en la API de ChatGPT${NC}"
                            echo -e "   ${DIM}Verifica tu API key y créditos en platform.openai.com${NC}"
                            ;;
                    esac
                fi
            elif [ "$llm_choice" == "claude" ] && [ -n "$claude_api_key" ]; then
                local error_result=$(validar_claude_api "$claude_api_key")
                if [ $? -eq 0 ]; then
                    echo -e "   ${GREEN}✅ API de Claude funciona correctamente${NC}"
                    echo ""
                    echo -e "   ${YELLOW}📝 Realizando prueba de consulta...${NC}"
                    local test_result=$(consultar_llm "Di solo 'Hola desde Claude'")
                    echo -e "   ${GREEN}💬 Respuesta:${NC} $test_result"
                else
                    case "$error_result" in
                        "ERROR_CREDITS")
                            echo -e "   ${RED}❌ Claude: Sin créditos suficientes${NC}"
                            echo -e "   ${YELLOW}💡 Ve a console.anthropic.com/settings/billing para agregar créditos${NC}"
                            echo -e "   ${CYAN}💡 O ejecuta: ${BOLD}coder -llm${NC} ${CYAN}para cambiar a ChatGPT${NC}"
                            ;;
                        "ERROR_API_KEY")
                            echo -e "   ${RED}❌ Claude: API key inválida${NC}"
                            echo -e "   ${YELLOW}💡 Verifica tu API key en console.anthropic.com${NC}"
                            ;;
                        *)
                            echo -e "   ${RED}❌ Error en la API de Claude${NC}"
                            echo -e "   ${DIM}Verifica tu API key y acceso en console.anthropic.com${NC}"
                            ;;
                    esac
                fi
            elif [ "$llm_choice" == "gemini" ] && [ -n "$gemini_api_key" ]; then
                local error_result=$(validar_gemini_api "$gemini_api_key")
                if [ $? -eq 0 ]; then
                    echo -e "   ${GREEN}✅ API de Gemini funciona correctamente${NC}"
                    echo ""
                    echo -e "   ${YELLOW}📝 Realizando prueba de consulta...${NC}"
                    local test_result=$(consultar_llm "Di solo 'Hola desde Gemini'")
                    echo -e "   ${GREEN}💬 Respuesta:${NC} $test_result"
                else
                    case "$error_result" in
                        "ERROR_CREDITS")
                            echo -e "   ${RED}❌ Gemini: Cuota excedida${NC}"
                            echo -e "   ${YELLOW}💡 Ve a console.cloud.google.com/apis/api/generativelanguage.googleapis.com${NC}"
                            ;;
                        "ERROR_API_KEY")
                            echo -e "   ${RED}❌ Gemini: API key inválida${NC}"
                            echo -e "   ${YELLOW}💡 Verifica tu API key en aistudio.google.com/app/apikey${NC}"
                            ;;
                        *)
                            echo -e "   ${RED}❌ Error en la API de Gemini${NC}"
                            echo -e "   ${DIM}Verifica tu API key y acceso en aistudio.google.com/app/apikey${NC}"
                            ;;
                    esac
                fi
            else
                echo -e "   ${RED}❌ API key no configurada para $llm_choice${NC}"
            fi
        else
            echo -e "   ${RED}❌ No hay LLM configurado${NC}"
            echo -e "   ${YELLOW}💡 Ejecuta: ${CYAN}coder setup${NC}"
        fi
    else
        echo -e "   ${RED}❌ No se encontró archivo de configuración${NC}"
        echo -e "   ${YELLOW}💡 Ejecuta: ${CYAN}coder setup${NC}"
    fi
    
    echo ""
    echo -e "${DIM}────────────────────────────────────────────────────────────────${NC}"
}

# Función para el modo interactivo
modo_interactivo() {
    if $DEBUG; then
        echo "DEBUG: Modo interactivo iniciado con depuración activada."
    fi
    
    # Validar API antes de iniciar modo interactivo
    if ! mostrar_estado_validacion; then
        echo ""
        mostrar_error_configuracion
        return 1
    fi
    
    echo ""
    sleep 1
    mostrar_ui_interactivo
    
    # Marcar que estamos en modo interactivo
    export MODO_INTERACTIVO=1
    
    # Buscar y leer el archivo de contexto
    local archivo_contexto=$(encontrar_archivo_contexto)
    local contexto=""
    if [[ -n "$archivo_contexto" ]]; then
        contexto=$(cat "$archivo_contexto")
        echo "Archivo de contexto encontrado y cargado."
        if $DEBUG; then
            echo "DEBUG: Contenido del archivo de contexto:"
            echo "$contexto"
        fi
    else
        echo "No se encontró archivo de contexto. Continuando sin contexto inicial."
    fi

    # Cargar historial más reciente si existe
    local archivo_historial=$(ls -t "$CONFIG_DIR"/historial_chat*.txt 2>/dev/null | head -n1)
    local historial=""
    if [[ -f "$archivo_historial" ]]; then
        historial=$(cat "$archivo_historial")
        echo "Historial de chat cargado desde: $(basename "$archivo_historial")"
        if $DEBUG; then
            echo "DEBUG: Contenido del historial de chat:"
            echo "$historial"
        fi
    else
        archivo_historial="$CONFIG_DIR/historial_chat.txt"
        echo "No se encontró historial. Se creará uno nuevo."
    fi

    # Combinar contexto e historial
    local prompt_completo="Contexto del código:\n$contexto\n\nHistorial de la conversación:\n$historial"
    
    while true; do
        read -p "Tú: " entrada
        
        if [ "$entrada" = "salir" ] || [ "$entrada" = "exit" ] || [ "$entrada" = "quit" ]; then
            echo "Saliendo del modo interactivo."
            break
        fi
        
        prompt_completo+="\nUsuario: $entrada"
        if $DEBUG; then
            echo "DEBUG: Prompt completo enviado al LLM:"
            echo "$prompt_completo"
            echo "DEBUG: Enviando petición al LLM..."
        fi
        
        echo -n "Asistente: Pensando..."
        
        # Usar un archivo temporal para almacenar la respuesta
        temp_file=$(mktemp)
        
        # Iniciar la consulta en segundo plano
        consultar_llm "$prompt_completo" > "$temp_file" &
        pid=$!
        
        last_size=0
        pensando_mostrado=true
        respuesta_acumulada=""
        while kill -0 $pid 2>/dev/null; do
            current_size=$(wc -c < "$temp_file")
            if [ "$current_size" -gt "$last_size" ]; then
                if $pensando_mostrado; then
                    echo -ne "\r\033[K"  # Borrar la línea actual
                    echo -n "Asistente: "
                    pensando_mostrado=false
                fi
                nuevo_contenido=$(tail -c +$((last_size + 1)) "$temp_file")
                respuesta_acumulada+="$nuevo_contenido"
                
                # Detectar y formatear código
                if echo "$respuesta_acumulada" | grep -q '```'; then
                    IFS='```' read -ra ADDR <<< "$respuesta_acumulada"
                    for i in "${!ADDR[@]}"; do
                        if (( i % 2 == 1 )); then
                            echo -e "\n\033[36m```"  # Cyan
                            dar_formato_codigo "${ADDR[$i]}"
                            echo -e "```\033[0m"  # Reset color
                        else
                            echo -n "${ADDR[$i]}"
                        fi
                    done
                else
                    echo -n "$nuevo_contenido"
                fi
                
                last_size=$current_size
            fi
            sleep 0.1
        done
        
        # Asegurarse de que se muestre el contenido final
        if $pensando_mostrado; then
            echo -ne "\r\033[K"  # Borrar la línea actual
            echo -n "Asistente: "
        fi
        nuevo_contenido=$(tail -c +$((last_size + 1)) "$temp_file")
        respuesta_acumulada+="$nuevo_contenido"
        
        # Formatear el contenido final si es necesario
        if echo "$respuesta_acumulada" | grep -q '```'; then
            IFS='```' read -ra ADDR <<< "$respuesta_acumulada"
            for i in "${!ADDR[@]}"; do
                if (( i % 2 == 1 )); then
                    echo -e "\n\033[36m```"  # Cyan
                    dar_formato_codigo "${ADDR[$i]}"
                    echo -e "```\033[0m"  # Reset color
                else
                    echo -n "${ADDR[$i]}"
                fi
            done
        else
            echo -n "$nuevo_contenido"
        fi
        echo  # Nueva línea después de la respuesta completa
        
        respuesta=$(cat "$temp_file")
        rm "$temp_file"
        
        if $DEBUG; then
            echo "DEBUG: Respuesta recibida del LLM:"
            echo "$respuesta"
        fi
        
        prompt_completo+="\nAsistente: $respuesta"

        # Guardar el historial actualizado
        echo "$prompt_completo" > "$archivo_historial"
        if $DEBUG; then
            echo "DEBUG: Historial actualizado y guardado en $archivo_historial"
        fi
    done
}

# Función para limpiar el historial
limpiar_historial() {
    rm -f "$CONFIG_DIR/historial_chat.txt"
    echo "El historial de chat ha sido limpiado."
}

# Función para generar un nuevo hito de conversación
nuevo_hito() {
    local timestamp=$(date +"%Y%m%d_%H%M%S")
    local nuevo_archivo="$CONFIG_DIR/historial_chat_$timestamp.txt"
    touch "$nuevo_archivo"
    echo "Se ha creado un nuevo hito de conversación: historial_chat_$timestamp.txt"
}

# Función para mostrar el listado de historiales
mostrar_historiales() {
    echo "Listado de historiales de conversación:"
    local historiales=$(ls -1 "$CONFIG_DIR"/historial_chat*.txt 2>/dev/null)
    if [ -z "$historiales" ]; then
        echo "No se encontraron historiales de conversación."
    else
        echo "$historiales" | while read -r historial; do
            local nombre=$(basename "$historial")
            local fecha=$(echo "$nombre" | grep -oP '\d{8}_\d{6}')
            if [ -n "$fecha" ]; then
                fecha=$(date -d "${fecha:0:8} ${fecha:9:2}:${fecha:11:2}:${fecha:13:2}" "+%Y-%m-%d %H:%M:%S")
            else
                fecha="Fecha desconocida"
            fi
            echo "- $nombre (Creado: $fecha)"
        done
    fi
}

# Función para inicializar proyecto (como Claude Code)
inicializar_proyecto() {
    # Validar API antes de inicializar
    if ! mostrar_estado_validacion >/dev/null 2>&1; then
        mostrar_error_configuracion
        return 1
    fi
    
    echo "🚀 Inicializando proyecto con Asis-coder..."
    
    # Generar contexto automáticamente
    echo "📝 Generando contexto del proyecto..."
    generar_contexto
    
    # Crear archivo CODER.md con información del proyecto
    echo "📋 Creando guía del proyecto..."
    crear_guia_proyecto
    
    # Sugerir commit del archivo
    echo "✅ Proyecto inicializado correctamente!"
    echo "💡 Sugerencia: Ejecuta 'git add CODER.md && git commit -m \"Add Coder project guide\"'"
}

# Función para crear guía del proyecto
crear_guia_proyecto() {
    local archivo_contexto=$(encontrar_archivo_contexto)
    if [[ -n "$archivo_contexto" ]]; then
        local prompt="Analiza este proyecto y crea una guía completa en formato Markdown. Incluye:
1. Descripción del proyecto
2. Tecnologías utilizadas
3. Estructura de archivos
4. Instrucciones de instalación
5. Cómo usar el proyecto
6. Ejemplos de uso

Contexto del proyecto:
$(cat "$archivo_contexto")"
        
        echo "Generando guía del proyecto..."
        local guia=$(consultar_llm "$prompt")
        echo "$guia" > "CODER.md"
        echo "✅ Guía del proyecto creada: CODER.md"
    else
        echo "❌ Error: No se pudo encontrar el contexto del proyecto"
    fi
}

# Función para mostrar la UI de bienvenida
mostrar_ui_bienvenida() {
    clear
    
    # Colores
    local CYAN='\033[0;36m'
    local PURPLE='\033[0;35m'
    local GREEN='\033[0;32m'
    local YELLOW='\033[1;33m'
    local BLUE='\033[0;34m'
    local RED='\033[0;31m'
    local BOLD='\033[1m'
    local DIM='\033[2m'
    local NC='\033[0m'
    
    # Banner ASCII Art
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
    echo "    ║           🤖Tu Asistente de Desarrollo con IA                 ║"
    echo "    ║                                                               ║"
    echo "    ╚═══════════════════════════════════════════════════════════════╝"
    echo -e "${NC}"
    
    echo -e "${DIM}                           Versión $VERSION${NC}"
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

# Función para detectar el tipo de proyecto actual
detectar_proyecto_actual() {
    local directorio_actual=$(pwd)
    
    # React
    if [[ -f "$directorio_actual/package.json" ]]; then
        local package_content=$(cat "$directorio_actual/package.json" 2>/dev/null)
        if echo "$package_content" | grep -q "react"; then
            echo "React"
            return
        elif echo "$package_content" | grep -q "vue"; then
            echo "Vue.js"
            return
        elif echo "$package_content" | grep -q "angular"; then
            echo "Angular"
            return
        elif echo "$package_content" | grep -q "express"; then
            echo "Express.js"
            return
        else
            echo "Node.js"
            return
        fi
    fi
    
    # Ruby on Rails
    if [[ -f "$directorio_actual/Gemfile" ]] && grep -q "rails" "$directorio_actual/Gemfile" 2>/dev/null; then
        echo "Ruby on Rails"
        return
    fi
    
    # Laravel
    if [[ -f "$directorio_actual/composer.json" ]] && grep -q "laravel" "$directorio_actual/composer.json" 2>/dev/null; then
        echo "Laravel"
        return
    fi
    
    # Python
    if [[ -f "$directorio_actual/requirements.txt" ]]; then
        if grep -q "flask" "$directorio_actual/requirements.txt" 2>/dev/null; then
            echo "Flask"
            return
        elif grep -q "django" "$directorio_actual/requirements.txt" 2>/dev/null; then
            echo "Django"
            return
        else
            echo "Python"
            return
        fi
    fi
    
    # Spring Boot
    if [[ -f "$directorio_actual/pom.xml" ]] && grep -q "spring-boot" "$directorio_actual/pom.xml" 2>/dev/null; then
        echo "Spring Boot"
        return
    fi
    
    # Flutter
    if [[ -f "$directorio_actual/pubspec.yaml" ]] && grep -q "flutter" "$directorio_actual/pubspec.yaml" 2>/dev/null; then
        echo "Flutter"
        return
    fi
    
    # Git repository
    if [[ -d "$directorio_actual/.git" ]]; then
        echo "Git Repository"
        return
    fi
    
    echo ""
}

# Función para configuración inicial completa
configuracion_inicial_completa() {
    mostrar_ui_bienvenida
    
    # Esperar input del usuario
    read -n 1 -s
    clear
    
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

# Función principal
main() {
    if $DEBUG; then
        echo "Coder CLI versión: $VERSION"
    fi

    case "$1" in
        "-contexto")
            generar_contexto
            ;;
        "-llm")
            update_llm_choice
            ;;
        "-model")
            get_api_config
            update_model
            ;;
        "-token")
            get_api_config
            update_api_token
            ;;
        "-config"|"config")
            mostrar_estado_configuracion
            ;;
        "-i")
            modo_interactivo
            ;;
        "-debug")
            DEBUG=true
            shift
            main "$@"
            ;;
        "-v"|"-version")
            echo "Coder CLI versión: $VERSION"
            ;;
        "-clean")
            limpiar_historial
            ;;
        "-new")
            nuevo_hito
            ;;
        "/init")
            inicializar_proyecto
            ;;
        "-setup"|"setup")
            configuracion_inicial_completa
            ;;
        "historial")
            mostrar_historiales
            ;;
        "-test"|"test")
            probar_configuracion_api
            ;;
        "")
            validar_y_mostrar_ui
            ;;
        *)
            consultar_llm "$*"
            ;;
    esac
}

# Función para verificar dependencias
check_dependencies() {
    local missing_deps=()
    
    for cmd in curl jq file; do
        if ! command -v "$cmd" &> /dev/null; then
            missing_deps+=("$cmd")
        fi
    done
    
    if [ ${#missing_deps[@]} -ne 0 ]; then
        echo "Error: Faltan las siguientes dependencias:"
        printf '%s\n' "${missing_deps[@]}"
        echo "Por favor, instálalas antes de continuar."
        exit 1
    fi
}

# Función para configurar el entorno
setup_environment() {
    # Crear directorios si no existen
    mkdir -p "$CONFIG_DIR"
    mkdir -p "$BIN_DIR"

    # Establecer permisos
    chmod 700 "$CONFIG_DIR"
    chmod 755 "$BIN_DIR"

    # Crear archivo de configuración si no existe
    touch "$CONFIG_FILE"
    chmod 600 "$CONFIG_FILE"

    # Crear archivo de log si no existe
    touch "$LOG_FILE"
    chmod 644 "$LOG_FILE"

    # Agregar el directorio bin al PATH si no está ya
    if [[ ":$PATH:" != *":$BIN_DIR:"* ]]; then
        echo "export PATH=\"$BIN_DIR:\$PATH\"" >> "$HOME/.bashrc"
        echo "export PATH=\"$BIN_DIR:\$PATH\"" >> "$HOME/.zshrc"
        export PATH="$BIN_DIR:$PATH"
    fi
}

# Función de limpieza
cleanup() {
    # Eliminar archivos temporales si existen
    if [ -n "$temp_file" ] && [ -f "$temp_file" ]; then
        rm -f "$temp_file"
    fi
}

# Registrar la función de limpieza para que se ejecute al salir
trap cleanup EXIT

# Verificar dependencias
check_dependencies

# Configurar el entorno
setup_environment

# Ejecutar la función principal
main "$@"

