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
    
    # Cargar idioma
    load_language
    
    clear
    echo -e "${CYAN}${BOLD}$(get_text "llm_selection")${NC}"
    echo -e "${DIM}════════════════════════════════════════════════════════════════${NC}"
    echo ""
    echo -e "${YELLOW}$(get_text "select_ai_assistant")${NC}"
    echo ""
    echo -e "${GREEN}${BOLD}1. ChatGPT${NC} ${DIM}(OpenAI)${NC}"
    echo -e "   $(get_text "cost_medium") | $(get_text "very_smart") | $(get_text "fast")"
    echo -e "   🔹 14 $(get_text "models"): gpt-3.5-turbo → o4-mini"
    echo ""
    echo -e "${PURPLE}${BOLD}2. Claude${NC} ${DIM}(Anthropic)${NC}"
    echo -e "   $(get_text "premium") | $(get_text "creative") | $(get_text "excellent_writing")"
    echo -e "   🔹 8 $(get_text "models"): claude-3-haiku → claude-opus-4"
    echo ""
    echo -e "${CYAN}${BOLD}3. Gemini${NC} ${DIM}(Google)${NC}"
    echo -e "   $(get_text "free") | $(get_text "updated_data") | $(get_text "integrated_search")"
    echo -e "   🔹 8 $(get_text "models"): gemini-1.5-flash → gemini-2.5-pro"
    echo ""
    
    read -p "$(echo -e "${YELLOW}$(get_text "enter_choice") (1-3): ${NC}")" llm_choice_input
    
    case $llm_choice_input in
        1)
            llm_choice="chatgpt"
            echo -e "${GREEN}✅ ChatGPT $(get_text "selected")${NC}"
            ;;
        2)
            llm_choice="claude"
            echo -e "${PURPLE}✅ Claude $(get_text "selected")${NC}"
            ;;
        3)
            llm_choice="gemini"
            echo -e "${CYAN}✅ Gemini $(get_text "selected")${NC}"
            ;;
        *)
            echo -e "${YELLOW}$(get_text "invalid_option")${NC}"
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
        echo -e "${YELLOW}$(get_text "api_key_for") $llm_choice${NC}"
        update_api_token_internal
    else
        echo -e "${GREEN}$(get_text "already_configured") $llm_choice ya configurada${NC}"
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
        echo -e "${GREEN}$(get_text "already_configured") $llm_choice ya configurada${NC}"
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
    
    # Cargar idioma
    load_language
    
    echo ""
    echo -e "${CYAN}${BOLD}$(get_text "api_key_config")${NC}"
    echo -e "${YELLOW}────────────────────────────────────────────────────────────────${NC}"
    
    case "$llm_choice" in
        "chatgpt")
            echo -e "${GREEN}$(get_text "get_chatgpt_key")${NC}"
            echo -e "   1. Ve a: ${CYAN}https://platform.openai.com/api-keys${NC}"
            echo -e "   2. $(get_text "login_create_key")"
            echo -e "   3. $(get_text "copy_key") ($(get_text "starts_with") 'sk-')"
            echo ""
            echo -e "${CYAN}$(get_text "api_key_hidden")${NC}"
            read -s -p "$(echo -e "${YELLOW}$(get_text "enter_api_key_prompt") de ChatGPT: ${NC}")" api_key
            token_var="chatgpt_api_key"
            ;;
        "claude")
            echo -e "${GREEN}$(get_text "get_claude_key")${NC}"
            echo -e "   1. Ve a: ${CYAN}https://console.anthropic.com/settings/keys${NC}"
            echo -e "   2. $(get_text "login_create_key")"
            echo -e "   3. $(get_text "copy_key") ($(get_text "starts_with") 'sk-ant-api03-')"
            echo ""
            echo -e "${CYAN}$(get_text "api_key_hidden")${NC}"
            read -s -p "$(echo -e "${YELLOW}$(get_text "enter_api_key_prompt") de Claude: ${NC}")" api_key
            token_var="claude_api_key"
            ;;
        "gemini")
            echo -e "${GREEN}$(get_text "get_gemini_key")${NC}"
            echo -e "   1. Ve a: ${CYAN}https://aistudio.google.com/app/apikey${NC}"
            echo -e "   2. $(get_text "login_create_key")"
            echo -e "   3. $(get_text "copy_key")"
            echo ""
            echo -e "${CYAN}$(get_text "api_key_hidden")${NC}"
            read -s -p "$(echo -e "${YELLOW}$(get_text "enter_api_key_prompt") de Gemini: ${NC}")" api_key
            token_var="gemini_api_key"
            ;;
    esac
    
    echo ""
    if [ -n "$api_key" ]; then
        # Usar la nueva función para actualizar sin sobrescribir
        update_config_value "$token_var" "$api_key"
        eval "$token_var='$api_key'"
        log "Token de API para $llm_choice actualizado."
        echo -e "${GREEN}$(get_text "api_key_saved")${NC}"
    else
        echo -e "${RED}$(get_text "no_api_key")${NC}"
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
    echo -e "${GREEN}${BOLD}🤖 $(get_text "chatgpt_models_available")${NC}"
    echo -e "${DIM}────────────────────────────────────────────────────────────────${NC}"
    echo ""
    echo -e "${YELLOW}📊 $(get_text "classic_models"):${NC}"
    echo "1. gpt-3.5-turbo ($(get_text "classic_fast_economic"))"
    echo "2. gpt-4 ($(get_text "gpt4_base_model"))"
    echo "3. gpt-4-turbo ($(get_text "price_performance_balance"))"
    echo ""
    echo -e "${YELLOW}🚀 $(get_text "omni_models") ($(get_text "multimodal")):${NC}"
    echo "4. gpt-4o ($(get_text "omni_multimodal_powerful"))"
    echo "5. gpt-4o-mini ($(get_text "economic_and_fast"))"
    echo ""
    echo -e "${YELLOW}🧠 $(get_text "reasoning_models"):${NC}"
    echo "6. o1 ($(get_text "advanced_reasoning"))"
    echo "7. o1-mini ($(get_text "fast_reasoning"))"
    echo "8. o1-preview ($(get_text "reasoning_preview"))"
    echo "9. o3-mini ($(get_text "new_reasoning_model"))"
    echo "10. o4-mini ($(get_text "latest_compact_model"))"
    echo ""
    echo -e "${YELLOW}🆕 $(get_text "new_generation"):${NC}"
    echo "11. gpt-4.1 ($(get_text "new_generation_model"))"
    echo "12. gpt-4.1-mini ($(get_text "compact_new_generation"))"
    echo "13. gpt-4.1-nano ($(get_text "ultra_compact"))"
    echo "14. gpt-4.5 ($(get_text "most_advanced_model"))"
    echo ""
    read -p "$(echo -e "${CYAN}$(get_text "select_model_number") (1-14): ${NC}")" model_choice

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
            echo -e "${YELLOW}⚠️ $(get_text "invalid_option_default_gpt4o_mini")${NC}"
            model="gpt-4o-mini"
            ;;
    esac

    update_config_value "model" "$model"
    log "Modelo seleccionado: $model"
    echo -e "${GREEN}✅ $(get_text "model") ${BOLD}$model${NC}${GREEN} $(get_text "configured")${NC}"
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
    echo -e "${PURPLE}${BOLD}🎭 $(get_text "claude_models_available")${NC}"
    echo -e "${DIM}────────────────────────────────────────────────────────────────${NC}"
    echo ""
    echo -e "${YELLOW}👑 $(get_text "claude_4_latest_generation"):${NC}"
    echo "1. claude-opus-4-20250514 ($(get_text "claude_4_most_powerful"))"
    echo "2. claude-sonnet-4-20250514 ($(get_text "claude_4_high_performance"))"
    echo ""
    echo -e "${YELLOW}🧠 $(get_text "claude_37_extended_thinking"):${NC}"
    echo "3. claude-3-7-sonnet-20250219 ($(get_text "claude_37_extended_thinking_desc"))"
    echo ""
    echo -e "${YELLOW}⚡ $(get_text "claude_35_perfect_balance"):${NC}"
    echo "4. claude-3-5-sonnet-20241022 ($(get_text "claude_35_v2_most_recent"))"
    echo "5. claude-3-5-sonnet-20240620 ($(get_text "claude_35_v1_stable"))"
    echo "6. claude-3-5-haiku-20241022 ($(get_text "fast_and_economic"))"
    echo ""
    echo -e "${YELLOW}📚 $(get_text "claude_3_legacy"):${NC}"
    echo "7. claude-3-opus-20240229 ($(get_text "smartest_legacy"))"
    echo "8. claude-3-haiku-20240307 ($(get_text "ultrafast_legacy"))"
    echo ""
    read -p "$(echo -e "${CYAN}$(get_text "select_model_number") (1-8): ${NC}")" model_choice

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
            echo -e "${YELLOW}⚠️ $(get_text "invalid_option_default_claude")${NC}"
            model="claude-3-5-sonnet-20241022"
            ;;
    esac

    update_config_value "model" "$model"
    log "Modelo seleccionado: $model"
    echo -e "${PURPLE}✅ $(get_text "model") ${BOLD}$model${NC}${PURPLE} $(get_text "configured")${NC}"
}

# Función para listar modelos de Gemini
list_gemini_models() {
    local CYAN='\033[0;36m'
    local YELLOW='\033[1;33m'
    local BOLD='\033[1m'
    local DIM='\033[2m'
    local NC='\033[0m'
    
    echo ""
    echo -e "${CYAN}${BOLD}💎 $(get_text "gemini_models_available")${NC}"
    echo -e "${DIM}────────────────────────────────────────────────────────────────${NC}"
    echo ""
    echo -e "${YELLOW}🚀 $(get_text "gemini_25_most_recent"):${NC}"
    echo "1. gemini-2.5-pro ($(get_text "most_powerful_with_thinking"))"
    echo "2. gemini-2.5-flash ($(get_text "best_price_performance_balance"))"
    echo "3. gemini-2.5-flash-lite ($(get_text "ultra_economic"))"
    echo ""
    echo -e "${YELLOW}⚡ $(get_text "gemini_20"):${NC}"
    echo "4. gemini-2.0-flash ($(get_text "generation_20_standard"))"
    echo "5. gemini-2.0-flash-lite ($(get_text "generation_20_economic"))"
    echo ""
    echo -e "${YELLOW}📚 $(get_text "gemini_15_legacy"):${NC}"
    echo "6. gemini-1.5-pro ($(get_text "legacy_pro"))"
    echo "7. gemini-1.5-flash ($(get_text "legacy_flash"))"
    echo "8. gemini-1.5-flash-8b ($(get_text "legacy_compact"))"
    echo ""
    read -p "$(echo -e "${CYAN}$(get_text "select_model_number") (1-8): ${NC}")" model_choice

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
            echo -e "${YELLOW}⚠️ $(get_text "invalid_option_default_gemini")${NC}"
            model="gemini-2.5-flash"
            ;;
    esac

    update_config_value "model" "$model"
    log "Modelo seleccionado: $model"
    echo -e "${CYAN}✅ $(get_text "model") ${BOLD}$model${NC}${CYAN} $(get_text "configured")${NC}"
} 