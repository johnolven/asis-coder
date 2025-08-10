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
    echo -e "   🔹 15 $(get_text "models"): gpt-3.5-turbo → gpt-oss-20b"
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
    echo -e "${YELLOW}🌟 $(get_text "open_source_models"):${NC}"
    echo "15. gpt-oss-20b (Modelo de código abierto, 21B parámetros, razonamiento avanzado)"
    echo ""
    read -p "$(echo -e "${CYAN}$(get_text "select_model_number") (1-15): ${NC}")" model_choice

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
        15) 
            model="gpt-oss-20b" 
            # Verificar si el modelo ya está descargado
            if ! check_gpt_oss_installed; then
                show_gpt_oss_download_ui
                if [ $? -eq 0 ]; then
                    echo -e "${GREEN}✅ Modelo gpt-oss-20b descargado correctamente${NC}"
                else
                    echo -e "${YELLOW}⚠️ Descarga cancelada. Usando gpt-4o-mini por defecto.${NC}"
                    model="gpt-4o-mini"
                fi
            else
                echo -e "${GREEN}✅ gpt-oss-20b ya está instalado y listo para usar${NC}"
            fi
            ;;
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

# =======================================================
# FUNCIONES PARA GPT-OSS-20B (MODELO OPEN SOURCE)
# =======================================================

# Función para verificar si gpt-oss-20b está instalado
check_gpt_oss_installed() {
    # Verificar diferentes métodos de instalación
    
    # 1. Verificar Ollama
    if command -v ollama >/dev/null 2>&1; then
        if ollama list 2>/dev/null | grep -q "gpt-oss:20b"; then
            return 0
        fi
    fi
    
    # 2. Verificar Hugging Face CLI
    if command -v huggingface-cli >/dev/null 2>&1; then
        if [ -d "$HOME/.cache/huggingface/hub/models--openai--gpt-oss-20b" ]; then
            return 0
        fi
    fi
    
    # 3. Verificar directorio local
    if [ -d "$HOME/.local/share/asis-coder/models/gpt-oss-20b" ]; then
        return 0
    fi
    
    # 4. Verificar LM Studio
    if [ -d "$HOME/.cache/lm-studio/models/openai/gpt-oss-20b" ]; then
        return 0
    fi
    
    return 1
}

# Función para mostrar UI de descarga de gpt-oss-20b
show_gpt_oss_download_ui() {
    local CYAN='\033[0;36m'
    local GREEN='\033[0;32m'
    local YELLOW='\033[1;33m'
    local PURPLE='\033[0;35m'
    local BLUE='\033[0;34m'
    local BOLD='\033[1m'
    local DIM='\033[2m'
    local NC='\033[0m'
    
    clear
    echo -e "${CYAN}${BOLD}🌟 DESCARGA DE GPT-OSS-20B${NC}"
    echo -e "${YELLOW}═══════════════════════════════════════════════════════════════${NC}"
    echo ""
    echo -e "${GREEN}📋 Información del Modelo:${NC}"
    echo -e "   ${CYAN}•${NC} ${BOLD}Nombre:${NC} gpt-oss-20b"
    echo -e "   ${CYAN}•${NC} ${BOLD}Tamaño:${NC} 21B parámetros (3.6B activos)"
    echo -e "   ${CYAN}•${NC} ${BOLD}Licencia:${NC} Apache 2.0 (Código Abierto)"
    echo -e "   ${CYAN}•${NC} ${BOLD}Características:${NC} Razonamiento avanzado, Capacidades agenticas"
    echo -e "   ${CYAN}•${NC} ${BOLD}Memoria requerida:${NC} ~16GB RAM"
    echo ""
    
    echo -e "${BLUE}${BOLD}🛠️ Métodos de Descarga Disponibles:${NC}"
    echo -e "${DIM}───────────────────────────────────────────────────────────────${NC}"
    echo ""
    
    # Verificar qué herramientas están disponibles
    local ollama_available=false
    local hf_cli_available=false
    local lm_studio_available=false
    local option_count=0
    
    if command -v ollama >/dev/null 2>&1; then
        ollama_available=true
        option_count=$((option_count + 1))
        echo -e "${GREEN}${option_count}. ${BOLD}Ollama${NC} ${DIM}(Recomendado)${NC}"
        echo -e "   ${CYAN}•${NC} Fácil de usar, optimizado para consumidores"
        echo -e "   ${CYAN}•${NC} Gestión automática de memoria"
        echo -e "   ${CYAN}•${NC} Comando: ${YELLOW}ollama pull gpt-oss:20b${NC}"
        echo ""
    fi
    
    if command -v huggingface-cli >/dev/null 2>&1; then
        hf_cli_available=true
        option_count=$((option_count + 1))
        echo -e "${PURPLE}${option_count}. ${BOLD}Hugging Face CLI${NC} ${DIM}(Desarrolladores)${NC}"
        echo -e "   ${CYAN}•${NC} Acceso directo a modelos HF"
        echo -e "   ${CYAN}•${NC} Más control sobre la descarga"
        echo -e "   ${CYAN}•${NC} Comando: ${YELLOW}huggingface-cli download openai/gpt-oss-20b${NC}"
        echo ""
    fi
    
    # LM Studio (verificar si existe)
    if command -v lms >/dev/null 2>&1; then
        lm_studio_available=true
        option_count=$((option_count + 1))
        echo -e "${BLUE}${option_count}. ${BOLD}LM Studio${NC} ${DIM}(Interfaz Gráfica)${NC}"
        echo -e "   ${CYAN}•${NC} Interfaz gráfica amigable"
        echo -e "   ${CYAN}•${NC} Gestión visual de modelos"
        echo -e "   ${CYAN}•${NC} Comando: ${YELLOW}lms get openai/gpt-oss-20b${NC}"
        echo ""
    fi
    
    # Opción de instalación manual
    option_count=$((option_count + 1))
    echo -e "${YELLOW}${option_count}. ${BOLD}Instalación Manual${NC} ${DIM}(Avanzado)${NC}"
    echo -e "   ${CYAN}•${NC} Descarga directa desde Hugging Face"
    echo -e "   ${CYAN}•${NC} Control total del proceso"
    echo -e "   ${CYAN}•${NC} Requiere configuración adicional"
    echo ""
    
    option_count=$((option_count + 1))
    echo -e "${DIM}${option_count}. Cancelar${NC}"
    echo ""
    
    echo -e "${YELLOW}⚠️ Notas Importantes:${NC}"
    echo -e "   ${CYAN}•${NC} El modelo requiere aproximadamente ${BOLD}12-16GB${NC} de espacio en disco"
    echo -e "   ${CYAN}•${NC} La descarga puede tomar ${BOLD}10-30 minutos${NC} dependiendo de tu conexión"
    echo -e "   ${CYAN}•${NC} Se recomienda una conexión estable para evitar interrupciones"
    echo ""
    echo -e "${DIM}═══════════════════════════════════════════════════════════════${NC}"
    
    while true; do
        read -p "$(echo -e "${CYAN}Selecciona el método de descarga (1-$option_count): ${NC}")" download_choice
        
        case $download_choice in
            1)
                if $ollama_available; then
                    download_gpt_oss_ollama
                    return $?
                elif $hf_cli_available; then
                    download_gpt_oss_hf_cli
                    return $?
                elif $lm_studio_available; then
                    download_gpt_oss_lm_studio
                    return $?
                else
                    download_gpt_oss_manual
                    return $?
                fi
                ;;
            2)
                if $ollama_available && $hf_cli_available; then
                    download_gpt_oss_hf_cli
                    return $?
                elif $ollama_available && $lm_studio_available; then
                    download_gpt_oss_lm_studio
                    return $?
                elif $hf_cli_available; then
                    download_gpt_oss_manual
                    return $?
                else
                    download_gpt_oss_manual
                    return $?
                fi
                ;;
            3)
                if $ollama_available && $hf_cli_available && $lm_studio_available; then
                    download_gpt_oss_lm_studio
                    return $?
                elif ($ollama_available && $hf_cli_available) || ($ollama_available && $lm_studio_available) || ($hf_cli_available && $lm_studio_available); then
                    download_gpt_oss_manual
                    return $?
                else
                    echo -e "${YELLOW}⏹️ Descarga cancelada${NC}"
                    return 1
                fi
                ;;
            4)
                if $ollama_available && $hf_cli_available && $lm_studio_available; then
                    download_gpt_oss_manual
                    return $?
                else
                    echo -e "${YELLOW}⏹️ Descarga cancelada${NC}"
                    return 1
                fi
                ;;
            5)
                echo -e "${YELLOW}⏹️ Descarga cancelada${NC}"
                return 1
                ;;
            *)
                echo -e "${YELLOW}❌ Opción no válida. Selecciona entre 1-$option_count${NC}"
                ;;
        esac
    done
}

# Función para descargar con Ollama
download_gpt_oss_ollama() {
    local GREEN='\033[0;32m'
    local CYAN='\033[0;36m'
    local YELLOW='\033[1;33m'
    local RED='\033[0;31m'
    local BOLD='\033[1m'
    local NC='\033[0m'
    
    echo -e "${CYAN}${BOLD}🐋 Descargando gpt-oss-20b con Ollama...${NC}"
    echo -e "${YELLOW}───────────────────────────────────────────────────────────${NC}"
    echo ""
    
    echo -e "${CYAN}📥 Iniciando descarga...${NC}"
    echo -e "${YELLOW}💡 Esto puede tomar varios minutos. Por favor espera...${NC}"
    echo ""
    
    # Ejecutar ollama pull con feedback visual
    if ollama pull gpt-oss:20b; then
        echo ""
        echo -e "${GREEN}✅ gpt-oss-20b descargado exitosamente con Ollama${NC}"
        echo -e "${CYAN}🚀 Puedes usar el modelo con: ${YELLOW}ollama run gpt-oss:20b${NC}"
        return 0
    else
        echo ""
        echo -e "${RED}❌ Error durante la descarga con Ollama${NC}"
        echo -e "${YELLOW}💡 Verifica tu conexión a internet e intenta nuevamente${NC}"
        return 1
    fi
}

# Función para descargar con Hugging Face CLI
download_gpt_oss_hf_cli() {
    local GREEN='\033[0;32m'
    local CYAN='\033[0;36m'
    local YELLOW='\033[1;33m'
    local RED='\033[0;31m'
    local BOLD='\033[1m'
    local NC='\033[0m'
    
    echo -e "${CYAN}${BOLD}🤗 Descargando gpt-oss-20b con Hugging Face CLI...${NC}"
    echo -e "${YELLOW}─────────────────────────────────────────────────────────────${NC}"
    echo ""
    
    echo -e "${CYAN}📥 Iniciando descarga desde Hugging Face...${NC}"
    echo -e "${YELLOW}💡 Descargando archivos del modelo...${NC}"
    echo ""
    
    # Crear directorio local para el modelo
    local model_dir="$HOME/.local/share/asis-coder/models/gpt-oss-20b"
    mkdir -p "$model_dir"
    
    # Ejecutar descarga
    if huggingface-cli download openai/gpt-oss-20b --include "original/*" --local-dir "$model_dir"; then
        echo ""
        echo -e "${GREEN}✅ gpt-oss-20b descargado exitosamente${NC}"
        echo -e "${CYAN}📍 Ubicación: ${YELLOW}$model_dir${NC}"
        return 0
    else
        echo ""
        echo -e "${RED}❌ Error durante la descarga${NC}"
        echo -e "${YELLOW}💡 Verifica tu conexión e intenta nuevamente${NC}"
        return 1
    fi
}

# Función para descargar con LM Studio
download_gpt_oss_lm_studio() {
    local GREEN='\033[0;32m'
    local CYAN='\033[0;36m'
    local YELLOW='\033[1;33m'
    local RED='\033[0;31m'
    local BOLD='\033[1m'
    local NC='\033[0m'
    
    echo -e "${CYAN}${BOLD}🎨 Descargando gpt-oss-20b con LM Studio...${NC}"
    echo -e "${YELLOW}────────────────────────────────────────────────────────────${NC}"
    echo ""
    
    echo -e "${CYAN}📥 Iniciando descarga con LM Studio...${NC}"
    echo ""
    
    if lms get openai/gpt-oss-20b; then
        echo ""
        echo -e "${GREEN}✅ gpt-oss-20b descargado exitosamente con LM Studio${NC}"
        echo -e "${CYAN}💡 Puedes gestionar el modelo desde la interfaz de LM Studio${NC}"
        return 0
    else
        echo ""
        echo -e "${RED}❌ Error durante la descarga con LM Studio${NC}"
        return 1
    fi
}

# Función para instalación manual
download_gpt_oss_manual() {
    local GREEN='\033[0;32m'
    local CYAN='\033[0;36m'
    local YELLOW='\033[1;33m'
    local RED='\033[0;31m'
    local BLUE='\033[0;34m'
    local BOLD='\033[1m'
    local NC='\033[0m'
    
    echo -e "${BLUE}${BOLD}⚙️ Instalación Manual de gpt-oss-20b${NC}"
    echo -e "${YELLOW}═══════════════════════════════════════════════════════════${NC}"
    echo ""
    
    echo -e "${YELLOW}📋 Instrucciones para instalación manual:${NC}"
    echo ""
    echo -e "${CYAN}${BOLD}Opción 1: Instalar Ollama (Recomendado)${NC}"
    echo -e "   ${CYAN}1.${NC} Visita: ${YELLOW}https://ollama.com${NC}"
    echo -e "   ${CYAN}2.${NC} Descarga e instala Ollama para tu sistema"
    echo -e "   ${CYAN}3.${NC} Ejecuta: ${YELLOW}ollama pull gpt-oss:20b${NC}"
    echo ""
    
    echo -e "${CYAN}${BOLD}Opción 2: Instalar Hugging Face CLI${NC}"
    echo -e "   ${CYAN}1.${NC} Instala: ${YELLOW}pip install huggingface_hub[cli]${NC}"
    echo -e "   ${CYAN}2.${NC} Ejecuta: ${YELLOW}huggingface-cli download openai/gpt-oss-20b${NC}"
    echo ""
    
    echo -e "${CYAN}${BOLD}Opción 3: Usar con Transformers${NC}"
    echo -e "   ${CYAN}1.${NC} Instala: ${YELLOW}pip install transformers torch${NC}"
    echo -e "   ${CYAN}2.${NC} Usa en Python:"
    echo -e "      ${YELLOW}from transformers import pipeline${NC}"
    echo -e "      ${YELLOW}pipe = pipeline('text-generation', 'openai/gpt-oss-20b')${NC}"
    echo ""
    
    echo -e "${GREEN}💡 Después de instalar, ejecuta nuevamente:${NC}"
    echo -e "   ${YELLOW}coder -model${NC}"
    echo ""
    
    read -p "$(echo -e "${CYAN}¿Quieres abrir la documentación oficial? (y/n): ${NC}")" open_docs
    
    if [[ "$open_docs" =~ ^[Yy]$ ]]; then
        if command -v open >/dev/null 2>&1; then
            open "https://huggingface.co/openai/gpt-oss-20b"
        elif command -v xdg-open >/dev/null 2>&1; then
            xdg-open "https://huggingface.co/openai/gpt-oss-20b"
        else
            echo -e "${CYAN}📖 Documentación: ${YELLOW}https://huggingface.co/openai/gpt-oss-20b${NC}"
        fi
    fi
    
    return 1  # Manual installation requires user action
} 