#!/bin/bash

# ==========================================
# MÓDULO DE GESTIÓN DE LLMs - llm_models.sh
# ==========================================
# Gestiona la selección de LLMs, modelos disponibles,
# configuración de API keys y actualización de tokens

# Función para actualizar la elección de LLM
update_llm_choice() {
    local CYAN='\033[0;36m'
    local GREEN='\033[0;32m'
    local YELLOW='\033[1;33m'
    local PURPLE='\033[0;35m'
    local BOLD='\033[1m'
    local DIM='\033[2m'
    local NC='\033[0m'
    
    clear
    echo -e "${CYAN}${BOLD}🤖 SELECCIÓN DE LLM${NC}"
    echo -e "${DIM}════════════════════════════════════════════════════════════════${NC}"
    echo ""
    echo -e "${YELLOW}Selecciona tu asistente de IA preferido:${NC}"
    echo ""
    echo -e "${GREEN}${BOLD}1. ChatGPT${NC} ${DIM}(OpenAI)${NC}"
    echo -e "   💰 Costo medio | 🧠 Muy inteligente | ⚡ Rápido"
    echo -e "   🔹 14 modelos: gpt-3.5-turbo → o4-mini"
    echo ""
    echo -e "${PURPLE}${BOLD}2. Claude${NC} ${DIM}(Anthropic)${NC}"
    echo -e "   💎 Premium | 🎨 Creativo | 📝 Excelente para escritura"
    echo -e "   🔹 8 modelos: claude-3-haiku → claude-opus-4"
    echo ""
    echo -e "${CYAN}${BOLD}3. Gemini${NC} ${DIM}(Google)${NC}"
    echo -e "   🆓 Gratis | 📊 Datos actualizados | 🔍 Búsqueda integrada"
    echo -e "   🔹 8 modelos: gemini-1.5-flash → gemini-2.5-pro"
    echo ""
    
    read -p "$(echo -e "${YELLOW}Ingresa tu elección (1-3): ${NC}")" llm_choice_input
    
    case $llm_choice_input in
        1)
            llm_choice="chatgpt"
            echo -e "${GREEN}✅ ChatGPT seleccionado${NC}"
            ;;
        2)
            llm_choice="claude"
            echo -e "${PURPLE}✅ Claude seleccionado${NC}"
            ;;
        3)
            llm_choice="gemini"
            echo -e "${CYAN}✅ Gemini seleccionado${NC}"
            ;;
        *)
            echo -e "${YELLOW}⚠️ Opción no válida. Seleccionando ChatGPT por defecto.${NC}"
            llm_choice="chatgpt"
            ;;
    esac

    update_config_value "llm_choice" "$llm_choice"
    log "LLM seleccionado: $llm_choice"
    
    # Cargar configuración existente
    if [ -f "$CONFIG_FILE" ]; then
        source "$CONFIG_FILE"
    fi
    
    # Verificar si ya existe API key para el LLM seleccionado
    local api_key_exists=false
    case "$llm_choice" in
        "chatgpt")
            [ -n "$chatgpt_api_key" ] && api_key_exists=true
            ;;
        "claude")
            [ -n "$claude_api_key" ] && api_key_exists=true
            ;;
        "gemini")
            [ -n "$gemini_api_key" ] && api_key_exists=true
            ;;
    esac
    
    # Solo pedir API key si no existe
    if ! $api_key_exists; then
        echo -e "${YELLOW}💡 No se encontró API key para $llm_choice${NC}"
        update_api_token_internal
    else
        echo -e "${GREEN}✅ API key de $llm_choice ya configurada${NC}"
    fi
    
    # Seleccionar modelo
    update_model
}

# Función para actualizar API token (verifica si existe)
update_api_token() {
    # Cargar configuración existente
    if [ -f "$CONFIG_FILE" ]; then
        source "$CONFIG_FILE"
    fi
    
    # Verificar si ya existe API key para el LLM actual
    local api_key_exists=false
    case "$llm_choice" in
        "chatgpt")
            [ -n "$chatgpt_api_key" ] && api_key_exists=true
            ;;
        "claude")
            [ -n "$claude_api_key" ] && api_key_exists=true
            ;;
        "gemini")
            [ -n "$gemini_api_key" ] && api_key_exists=true
            ;;
    esac
    
    # Solo pedir API key si no existe
    if ! $api_key_exists; then
        update_api_token_internal
    else
        echo -e "${GREEN}✅ API key de $llm_choice ya configurada${NC}"
    fi
}

# Función para forzar actualización de API token (siempre pide)
force_update_api_token() {
    update_api_token_internal
}

# Función interna para actualizar el token de API
update_api_token_internal() {
    local GREEN='\033[0;32m'
    local YELLOW='\033[1;33m'
    local CYAN='\033[0;36m'
    local RED='\033[0;31m'
    local BOLD='\033[1m'
    local NC='\033[0m'
    
    echo ""
    echo -e "${CYAN}${BOLD}🔑 CONFIGURACIÓN DE API KEY${NC}"
    echo -e "${YELLOW}────────────────────────────────────────────────────────────────${NC}"
    
    case "$llm_choice" in
        "chatgpt")
            echo -e "${GREEN}📋 Para obtener tu API key de ChatGPT:${NC}"
            echo -e "   1. Ve a: ${CYAN}https://platform.openai.com/api-keys${NC}"
            echo -e "   2. Inicia sesión y crea una nueva API key"
            echo -e "   3. Copia la key (empieza con 'sk-')"
            echo ""
            echo -e "${CYAN}🔒 Por seguridad, la API key no se mostrará mientras escribes${NC}"
            read -s -p "$(echo -e "${YELLOW}Ingresa tu API key de ChatGPT: ${NC}")" api_key
            token_var="chatgpt_api_key"
            ;;
        "claude")
            echo -e "${GREEN}📋 Para obtener tu API key de Claude:${NC}"
            echo -e "   1. Ve a: ${CYAN}https://console.anthropic.com/settings/keys${NC}"
            echo -e "   2. Inicia sesión y crea una nueva API key"
            echo -e "   3. Copia la key (empieza con 'sk-ant-api03-')"
            echo ""
            echo -e "${CYAN}🔒 Por seguridad, la API key no se mostrará mientras escribes${NC}"
            read -s -p "$(echo -e "${YELLOW}Ingresa tu API key de Claude: ${NC}")" api_key
            token_var="claude_api_key"
            ;;
        "gemini")
            echo -e "${GREEN}📋 Para obtener tu API key de Gemini:${NC}"
            echo -e "   1. Ve a: ${CYAN}https://aistudio.google.com/app/apikey${NC}"
            echo -e "   2. Inicia sesión con tu cuenta Google"
            echo -e "   3. Crea una nueva API key"
            echo ""
            echo -e "${CYAN}🔒 Por seguridad, la API key no se mostrará mientras escribes${NC}"
            read -s -p "$(echo -e "${YELLOW}Ingresa tu API key de Gemini: ${NC}")" api_key
            token_var="gemini_api_key"
            ;;
    esac
    
    echo ""
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
    local GREEN='\033[0;32m'
    local YELLOW='\033[1;33m'
    local CYAN='\033[0;36m'
    local BOLD='\033[1m'
    local DIM='\033[2m'
    local NC='\033[0m'
    
    echo ""
    echo -e "${GREEN}${BOLD}🤖 MODELOS DE CHATGPT DISPONIBLES${NC}"
    echo -e "${DIM}────────────────────────────────────────────────────────────────${NC}"
    echo ""
    echo -e "${YELLOW}📊 Modelos Clásicos:${NC}"
    echo "1. gpt-3.5-turbo (Clásico, rápido y económico)"
    echo "2. gpt-4 (Modelo base GPT-4)"
    echo "3. gpt-4-turbo (Equilibrio precio/rendimiento)"
    echo ""
    echo -e "${YELLOW}🚀 Modelos Omni (Multimodal):${NC}"
    echo "4. gpt-4o (Omni - Multimodal potente)"
    echo "5. gpt-4o-mini (Económico y rápido)"
    echo ""
    echo -e "${YELLOW}🧠 Modelos de Razonamiento:${NC}"
    echo "6. o1 (Razonamiento avanzado)"
    echo "7. o1-mini (Razonamiento rápido)"
    echo "8. o1-preview (Vista previa de razonamiento)"
    echo "9. o3-mini (Nuevo modelo de razonamiento)"
    echo "10. o4-mini (Último modelo compacto)"
    echo ""
    echo -e "${YELLOW}🆕 Nueva Generación:${NC}"
    echo "11. gpt-4.1 (Nueva generación)"
    echo "12. gpt-4.1-mini (Compacto nueva generación)"
    echo "13. gpt-4.1-nano (Ultra compacto)"
    echo "14. gpt-4.5 (Modelo más avanzado)"
    echo ""
    read -p "$(echo -e "${CYAN}Selecciona el número del modelo (1-14): ${NC}")" model_choice

    case $model_choice in
        1) model="gpt-3.5-turbo" ;;
        2) model="gpt-4" ;;
        3) model="gpt-4-turbo" ;;
        4) model="gpt-4o" ;;
        5) model="gpt-4o-mini" ;;
        6) model="o1" ;;
        7) model="o1-mini" ;;
        8) model="o1-preview" ;;
        9) model="o3-mini" ;;
        10) model="o4-mini" ;;
        11) model="gpt-4.1" ;;
        12) model="gpt-4.1-mini" ;;
        13) model="gpt-4.1-nano" ;;
        14) model="gpt-4.5" ;;
        *)
            echo -e "${YELLOW}⚠️ Opción no válida. Seleccionando gpt-4o-mini por defecto.${NC}"
            model="gpt-4o-mini"
            ;;
    esac

    update_config_value "model" "$model"
    log "Modelo seleccionado: $model"
    echo -e "${GREEN}✅ Modelo ${BOLD}$model${NC}${GREEN} configurado${NC}"
}

# Función para listar modelos de Claude
list_claude_models() {
    local PURPLE='\033[0;35m'
    local YELLOW='\033[1;33m'
    local CYAN='\033[0;36m'
    local BOLD='\033[1m'
    local DIM='\033[2m'
    local NC='\033[0m'
    
    echo ""
    echo -e "${PURPLE}${BOLD}🎭 MODELOS DE CLAUDE DISPONIBLES${NC}"
    echo -e "${DIM}────────────────────────────────────────────────────────────────${NC}"
    echo ""
    echo -e "${YELLOW}👑 Claude 4 (Última Generación):${NC}"
    echo "1. claude-opus-4-20250514 (Claude 4 - Más potente e inteligente)"
    echo "2. claude-sonnet-4-20250514 (Claude 4 - Alto rendimiento)"
    echo ""
    echo -e "${YELLOW}🧠 Claude 3.7 (Pensamiento Extendido):${NC}"
    echo "3. claude-3-7-sonnet-20250219 (Claude 3.7 - Pensamiento extendido)"
    echo ""
    echo -e "${YELLOW}⚡ Claude 3.5 (Equilibrio Perfecto):${NC}"
    echo "4. claude-3-5-sonnet-20241022 (Claude 3.5 v2 - Más reciente)"
    echo "5. claude-3-5-sonnet-20240620 (Claude 3.5 v1 - Estable)"
    echo "6. claude-3-5-haiku-20241022 (Rápido y económico)"
    echo ""
    echo -e "${YELLOW}📚 Claude 3 Legacy:${NC}"
    echo "7. claude-3-opus-20240229 (Más inteligente legacy)"
    echo "8. claude-3-haiku-20240307 (Ultrarrápido legacy)"
    echo ""
    read -p "$(echo -e "${CYAN}Selecciona el número del modelo (1-8): ${NC}")" model_choice

    case $model_choice in
        1) model="claude-opus-4-20250514" ;;
        2) model="claude-sonnet-4-20250514" ;;
        3) model="claude-3-7-sonnet-20250219" ;;
        4) model="claude-3-5-sonnet-20241022" ;;
        5) model="claude-3-5-sonnet-20240620" ;;
        6) model="claude-3-5-haiku-20241022" ;;
        7) model="claude-3-opus-20240229" ;;
        8) model="claude-3-haiku-20240307" ;;
        *)
            echo -e "${YELLOW}⚠️ Opción no válida. Seleccionando claude-3-5-sonnet-20241022 por defecto.${NC}"
            model="claude-3-5-sonnet-20241022"
            ;;
    esac

    update_config_value "model" "$model"
    log "Modelo seleccionado: $model"
    echo -e "${PURPLE}✅ Modelo ${BOLD}$model${NC}${PURPLE} configurado${NC}"
}

# Función para listar modelos de Gemini
list_gemini_models() {
    local CYAN='\033[0;36m'
    local YELLOW='\033[1;33m'
    local BOLD='\033[1m'
    local DIM='\033[2m'
    local NC='\033[0m'
    
    echo ""
    echo -e "${CYAN}${BOLD}💎 MODELOS DE GEMINI DISPONIBLES${NC}"
    echo -e "${DIM}────────────────────────────────────────────────────────────────${NC}"
    echo ""
    echo -e "${YELLOW}🚀 Gemini 2.5 (Más Reciente):${NC}"
    echo "1. gemini-2.5-pro (Más potente con pensamiento)"
    echo "2. gemini-2.5-flash (Mejor equilibrio precio/rendimiento)"
    echo "3. gemini-2.5-flash-lite (Ultra económico)"
    echo ""
    echo -e "${YELLOW}⚡ Gemini 2.0:${NC}"
    echo "4. gemini-2.0-flash (Generación 2.0 estándar)"
    echo "5. gemini-2.0-flash-lite (Generación 2.0 económico)"
    echo ""
    echo -e "${YELLOW}📚 Gemini 1.5 Legacy:${NC}"
    echo "6. gemini-1.5-pro (Legacy Pro)"
    echo "7. gemini-1.5-flash (Legacy Flash)"
    echo "8. gemini-1.5-flash-8b (Legacy compacto)"
    echo ""
    read -p "$(echo -e "${CYAN}Selecciona el número del modelo (1-8): ${NC}")" model_choice

    case $model_choice in
        1) model="gemini-2.5-pro" ;;
        2) model="gemini-2.5-flash" ;;
        3) model="gemini-2.5-flash-lite" ;;
        4) model="gemini-2.0-flash" ;;
        5) model="gemini-2.0-flash-lite" ;;
        6) model="gemini-1.5-pro" ;;
        7) model="gemini-1.5-flash" ;;
        8) model="gemini-1.5-flash-8b" ;;
        *)
            echo -e "${YELLOW}⚠️ Opción no válida. Seleccionando gemini-2.5-flash por defecto.${NC}"
            model="gemini-2.5-flash"
            ;;
    esac

    update_config_value "model" "$model"
    log "Modelo seleccionado: $model"
    echo -e "${CYAN}✅ Modelo ${BOLD}$model${NC}${CYAN} configurado${NC}"
} 