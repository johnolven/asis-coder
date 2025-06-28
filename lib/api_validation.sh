#!/bin/bash

# ==========================================
# MÓDULO DE VALIDACIÓN DE APIs - api_validation.sh
# ==========================================
# Gestiona la validación de APIs de ChatGPT, Claude y Gemini,
# incluyendo manejo de errores y diagnósticos

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
    
    # Cargar idioma
    load_language
    
    echo -e "${CYAN}${BOLD}$(get_text "validating_api_config")${NC}"
    echo -e "${DIM}────────────────────────────────────────────────────────────────${NC}"
    
    if [ -f "$CONFIG_FILE" ]; then
        source "$CONFIG_FILE" 2>/dev/null || true
        
        if [ -n "$llm_choice" ]; then
            echo -e "   ${YELLOW}⏳${NC} $(get_text "verifying_api") ${BOLD}$llm_choice${NC}..."
            
            if [ "$llm_choice" == "chatgpt" ] && [ -n "$chatgpt_api_key" ]; then
                local error_result=$(validar_chatgpt_api "$chatgpt_api_key")
                if [ $? -eq 0 ]; then
                    echo -e "   ${GREEN}✅ $(get_text "chatgpt_api_valid")${NC}"
                    return 0
                else
                    case "$error_result" in
                        "ERROR_CREDITS")
                            echo -e "   ${RED}❌ $(get_text "chatgpt_insufficient_credits")${NC}"
                            echo -e "   ${YELLOW}💡 $(get_text "visit_openai_billing")${NC}"
                            ;;
                        "ERROR_API_KEY")
                            echo -e "   ${RED}❌ $(get_text "chatgpt_invalid_api_key")${NC}"
                            echo -e "   ${YELLOW}💡 $(get_text "verify_openai_key")${NC}"
                            ;;
                        *)
                            echo -e "   ${RED}❌ ChatGPT: $(get_text "unknown_error")${NC}"
                            ;;
                    esac
                    return 1
                fi
            elif [ "$llm_choice" == "claude" ] && [ -n "$claude_api_key" ]; then
                local error_result=$(validar_claude_api "$claude_api_key")
                if [ $? -eq 0 ]; then
                    echo -e "   ${GREEN}✅ $(get_text "claude_api_valid")${NC}"
                    return 0
                else
                    case "$error_result" in
                        "ERROR_CREDITS")
                            echo -e "   ${RED}❌ $(get_text "claude_insufficient_credits")${NC}"
                            echo -e "   ${YELLOW}💡 $(get_text "visit_anthropic_billing")${NC}"
                            ;;
                        "ERROR_API_KEY")
                            echo -e "   ${RED}❌ $(get_text "claude_invalid_api_key")${NC}"
                            echo -e "   ${YELLOW}💡 $(get_text "verify_anthropic_key")${NC}"
                            ;;
                        *)
                            echo -e "   ${RED}❌ Claude: $(get_text "unknown_error")${NC}"
                            ;;
                    esac
                    return 1
                fi
            elif [ "$llm_choice" == "gemini" ] && [ -n "$gemini_api_key" ]; then
                local error_result=$(validar_gemini_api "$gemini_api_key")
                if [ $? -eq 0 ]; then
                    echo -e "   ${GREEN}✅ $(get_text "gemini_api_valid")${NC}"
                    return 0
                else
                    case "$error_result" in
                        "ERROR_CREDITS")
                            echo -e "   ${RED}❌ $(get_text "gemini_quota_exceeded")${NC}"
                            echo -e "   ${YELLOW}💡 $(get_text "visit_google_quota")${NC}"
                            ;;
                        "ERROR_API_KEY")
                            echo -e "   ${RED}❌ $(get_text "gemini_invalid_api_key")${NC}"
                            echo -e "   ${YELLOW}💡 $(get_text "verify_google_key")${NC}"
                            ;;
                        *)
                            echo -e "   ${RED}❌ Gemini: $(get_text "unknown_error")${NC}"
                            ;;
                    esac
                    return 1
                fi
            else
                echo -e "   ${RED}❌ $(get_text "no_api_key_configured") $llm_choice${NC}"
                return 1
            fi
        else
            echo -e "   ${RED}❌ $(get_text "no_llm_configured")${NC}"
            return 1
        fi
    else
        echo -e "   ${RED}❌ $(get_text "config_file_not_found")${NC}"
        return 1
    fi
}

# Función para mostrar errores de configuración
mostrar_error_configuracion() {
    local RED='\033[0;31m'
    local YELLOW='\033[1;33m'
    local CYAN='\033[0;36m'
    local BOLD='\033[1m'
    local NC='\033[0m'
    
    echo -e "${RED}${BOLD}$(get_text "config_error")${NC}"
    echo -e "${YELLOW}🔧 $(get_text "config_required_before_continue").${NC}"
    echo ""
    echo -e "${YELLOW}$(get_text "available_options"):${NC}"
    echo -e "   ${CYAN}1.${NC} $(get_text "configure_from_scratch"): ${BOLD}coder setup${NC}"
    echo -e "   ${CYAN}2.${NC} $(get_text "change_llm"): ${BOLD}coder -llm${NC}"
    echo -e "   ${CYAN}3.${NC} $(get_text "view_config"): ${BOLD}coder config${NC}"
    echo -e "   ${CYAN}4.${NC} $(get_text "test_apis"): ${BOLD}coder test${NC}"
    echo ""
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
    
    clear
    echo -e "${CYAN}${BOLD}🧪 $(get_text "configuration_test")${NC}"
    echo -e "${DIM}════════════════════════════════════════════════════════════════${NC}"
    echo ""
    
    if [ -f "$CONFIG_FILE" ]; then
        source "$CONFIG_FILE" 2>/dev/null || true
        
        if [ -n "$llm_choice" ]; then
            echo -e "${YELLOW}🤖 $(get_text "testing_llm") ${BOLD}$llm_choice${NC} $(get_text "with_model") ${BOLD}${model:-$(get_text "default")}${NC}..."
            echo ""
            
            # Hacer consulta de prueba
            local test_query="$(get_text "test_query")"
            echo -e "${DIM}$(get_text "test_query_label"): $test_query${NC}"
            echo ""
            
            echo -e "${YELLOW}⏳ $(get_text "sending_query")...${NC}"
            local response=$(consultar_llm "$test_query")
            
            if [ $? -eq 0 ] && [ -n "$response" ]; then
                echo -e "${GREEN}${BOLD}✅ $(get_text "test_successful")!${NC}"
                echo ""
                echo -e "${BOLD}$(get_text "response"):${NC}"
                echo -e "${DIM}────────────────────────────────────────────────────────────────${NC}"
                echo "$response"
                echo -e "${DIM}────────────────────────────────────────────────────────────────${NC}"
                echo ""
                echo -e "${GREEN}🎉 $(get_text "config_working_correctly").${NC}"
            else
                echo -e "${RED}$(get_text "test_error")${NC}"
                echo ""
                mostrar_estado_validacion
            fi
        else
            echo -e "${RED}❌ $(get_text "no_llm_configured")${NC}"
            mostrar_error_configuracion
        fi
    else
        echo -e "${RED}❌ $(get_text "config_not_found")${NC}"
        mostrar_error_configuracion
    fi
    
    echo ""
    echo -e "${DIM}$(get_text "press_enter_continue")...${NC}"
    read
} 