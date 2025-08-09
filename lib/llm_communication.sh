#!/bin/bash

# ==========================================
# MÓDULO DE COMUNICACIÓN CON LLMs - llm_communication.sh
# ==========================================
# Gestiona la comunicación con las APIs de LLMs, modo interactivo,
# consultas directas y manejo de respuestas

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

# Función para consultar al LLM
consultar_llm() {
    local pregunta="$1"
    if $DEBUG; then
        echo "$(get_text "query_received_in_llm"):"
        echo "$pregunta"
        echo "$(get_text "getting_api_config")..."
    fi
    
    # Validar configuración antes de hacer consulta
    if [ -z "$MODO_INTERACTIVO" ]; then
        # Si la configuración no es válida, obtener/configurar
        if ! is_config_valid; then
            get_api_config
            # Verificar nuevamente después de configurar
            if ! is_config_valid; then
                mostrar_error_configuracion
                return 1
            fi
        else
            # Si es válida, solo cargar
            source "$CONFIG_FILE"
        fi
    else
        get_api_config
    fi

    if $DEBUG; then
        echo "$(get_text "coder_cli_version"): $VERSION"
        echo "$(get_text "current_config"):"
        echo "LLM: $llm_choice"
        echo "$(get_text "model"): $model"
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
        echo "$(get_text "request_sent_to") $api_url:"
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
        echo "$(get_text "response_received"):"
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
            load_language
            echo "❌ $(get_text "error_extract_content")."
            if $DEBUG; then
                echo "$(get_text "complete_response"): $response"
            fi
            
            # Verificar errores específicos de la API
            local error_message=$(echo "$response" | jq -r '.error.message // .error.details // empty' 2>/dev/null)
            if [ -n "$error_message" ] && [ "$error_message" != "null" ]; then
                echo "💡 Error de API: $error_message"
                if echo "$error_message" | grep -qi "credit"; then
                    echo "$(get_text "no_credits")"
                elif echo "$error_message" | grep -qi "key"; then
                    echo "$(get_text "verify_api_key")"
                fi
            fi
        fi
    else
        load_language
        log "Error al recibir respuesta de $llm_choice."
        echo "$(get_text "error_no_response")"
        echo "$(get_text "check_connection")"
    fi
}

# Función para modo interactivo
modo_interactivo() {
    local CYAN='\033[0;36m'
    local GREEN='\033[0;32m'
    local YELLOW='\033[1;33m'
    local PURPLE='\033[0;35m'
    local BOLD='\033[1m'
    local DIM='\033[2m'
    local NC='\033[0m'
    
    # Validar configuración antes de entrar al modo interactivo
    if ! is_config_valid; then
        get_api_config
        if ! is_config_valid; then
            mostrar_error_configuracion
            return 1
        fi
    else
        source "$CONFIG_FILE"
    fi
    
    # Cargar idioma
    load_language
    
    # Mostrar UI del modo interactivo
    mostrar_ui_interactivo
    
    # Configurar archivo de historial único para esta sesión
    local timestamp=$(date +"%Y%m%d_%H%M%S")
    local archivo_historial="$CONFIG_DIR/historial_$timestamp.txt"
    
    # Buscar archivo de contexto
    local archivo_contexto=$(encontrar_archivo_contexto)
    
    if $DEBUG; then
        echo "$(get_text "debug_interactive_mode_started")"
        echo "$(get_text "debug_history_file"): $archivo_historial"
        echo "$(get_text "debug_context_file"): $archivo_contexto"
    fi
    
    # Marcar que estamos en modo interactivo
    MODO_INTERACTIVO=true
    
    # Crear prompt inicial con contexto si existe
    local prompt_completo=""
    if [ "$CURRENT_LANG" = "es" ]; then
        prompt_completo="Eres un asistente de desarrollo experto con capacidades de análisis avanzado. "
    else
        prompt_completo="You are an expert development assistant with advanced analysis capabilities. "
    fi
    
    if [[ -n "$archivo_contexto" ]]; then
        echo -e "${GREEN}$(get_text "project_context_loaded")${NC}"
        if [ "$CURRENT_LANG" = "es" ]; then
            prompt_completo+="Aquí está el contexto del proyecto actual:

$(cat "$archivo_contexto")

Tienes acceso a comandos especiales que empiezan con '/':
- /analyze: Análisis completo del código
- /refactor <archivo>: Sugerencias de refactorización  
- /review: Revisión de código con mejoras
- /security: Análisis de seguridad
- /performance: Análisis de rendimiento
- /test: Generar tests automáticos
- /docs: Generar documentación
- /fix <problema>: Arreglar problema específico
- /think <tema>: Pensamiento profundo sobre un tema
- /files: Listar archivos del proyecto
- /focus <archivo>: Enfocar en archivo específico
- /summary: Resumen del proyecto

Por favor, ayúdame con mis preguntas sobre este proyecto."
        else
            prompt_completo+="Here is the current project context:

$(cat "$archivo_contexto")

You have access to special commands starting with '/':
- /analyze: Complete code analysis
- /refactor <file>: Refactoring suggestions
- /review: Code review with improvements  
- /security: Security analysis
- /performance: Performance analysis
- /test: Generate automatic tests
- /docs: Generate documentation
- /fix <issue>: Fix specific issue
- /think <topic>: Deep thinking about topic
- /files: List project files
- /focus <file>: Focus on specific file
- /summary: Project summary

Please help me with my questions about this project."
        fi
    else
        echo -e "${YELLOW}$(get_text "no_project_context")${NC}"
        if [ "$CURRENT_LANG" = "es" ]; then
            prompt_completo+="Ayúdame con mis preguntas de programación. Tienes acceso a comandos especiales que empiezan con '/' para análisis avanzado."
        else
            prompt_completo+="Help me with my programming questions. You have access to special commands starting with '/' for advanced analysis."
        fi
    fi
    
    # Mostrar comandos disponibles
    echo -e "${PURPLE}${BOLD}📋 Comandos Especiales Disponibles:${NC}"
    echo -e "${DIM}────────────────────────────────────────────────────────────────${NC}"
    echo -e "  ${CYAN}/analyze${NC}           - Análisis completo del código"
    echo -e "  ${CYAN}/refactor <archivo>${NC} - Sugerencias de refactorización"
    echo -e "  ${CYAN}/review${NC}            - Revisión de código"
    echo -e "  ${CYAN}/security${NC}          - Análisis de seguridad"
    echo -e "  ${CYAN}/performance${NC}       - Análisis de rendimiento"
    echo -e "  ${CYAN}/test${NC}              - Generar tests"
    echo -e "  ${CYAN}/docs${NC}              - Generar documentación"
    echo -e "  ${CYAN}/think <tema>${NC}      - Pensamiento profundo"
    echo -e "  ${CYAN}/files${NC}             - Listar archivos"
    echo -e "  ${CYAN}/summary${NC}           - Resumen del proyecto"
    echo -e "${DIM}────────────────────────────────────────────────────────────────${NC}"
    echo ""
    
    if $DEBUG; then
        echo "$(get_text "debug_prompt_configured"):"
        echo "$prompt_completo"
        echo "$(get_text "debug_history_file"): $archivo_historial"
    fi
    
    # Loop del modo interactivo mejorado
    while true; do
        read -p "$(get_text "you"): " entrada
        
        if [ "$entrada" = "salir" ] || [ "$entrada" = "exit" ] || [ "$entrada" = "quit" ]; then
            echo -e "${CYAN}$(get_text "exiting_interactive")${NC}"
            break
        fi
        
        # Procesar comandos especiales
        if [[ "$entrada" == /* ]]; then
            procesar_comando_slash "$entrada" "$archivo_contexto" "$prompt_completo"
        else
            # Procesamiento normal de consulta
            if [ "$CURRENT_LANG" = "es" ]; then
                prompt_completo+="\nUsuario: $entrada"
            else
                prompt_completo+="\nUser: $entrada"
            fi
            
            procesar_consulta_normal "$prompt_completo" "$archivo_historial"
        fi
        
        # Actualizar prompt para próxima iteración
        if [[ ! "$entrada" == /* ]]; then
            prompt_completo+="\n$(get_text "assistant"): $(cat "$temp_file" 2>/dev/null || echo "")"
        fi
    done
    
    # Desmarcar modo interactivo
    unset MODO_INTERACTIVO
}

# Función para procesar comandos slash
procesar_comando_slash() {
    local comando="$1"
    local archivo_contexto="$2" 
    local prompt_base="$3"
    local CYAN='\033[0;36m'
    local GREEN='\033[0;32m'
    local YELLOW='\033[1;33m'
    local PURPLE='\033[0;35m'
    local BOLD='\033[1m'
    local DIM='\033[2m'
    local NC='\033[0m'
    
    # Extraer comando y argumentos
    local cmd=$(echo "$comando" | cut -d' ' -f1)
    local args=$(echo "$comando" | cut -d' ' -f2-)
    
    case "$cmd" in
        "/analyze")
            echo -e "${PURPLE}🔍 Iniciando análisis completo del código...${NC}"
            ejecutar_analisis_completo "$archivo_contexto"
            ;;
        "/refactor")
            echo -e "${PURPLE}🔧 Analizando oportunidades de refactorización...${NC}"
            ejecutar_refactorizacion "$args" "$archivo_contexto"
            ;;
        "/review")
            echo -e "${PURPLE}👀 Realizando revisión de código...${NC}"
            ejecutar_revision_codigo "$archivo_contexto"
            ;;
        "/security")
            echo -e "${PURPLE}🛡️ Analizando seguridad del código...${NC}"
            ejecutar_analisis_seguridad "$archivo_contexto"
            ;;
        "/performance")
            echo -e "${PURPLE}⚡ Analizando rendimiento...${NC}"
            ejecutar_analisis_rendimiento "$archivo_contexto"
            ;;
        "/test")
            echo -e "${PURPLE}🧪 Generando tests automáticos...${NC}"
            ejecutar_generacion_tests "$archivo_contexto"
            ;;
        "/docs")
            echo -e "${PURPLE}📚 Generando documentación...${NC}"
            ejecutar_generacion_docs "$archivo_contexto"
            ;;
        "/think")
            echo -e "${PURPLE}🧠 Pensamiento profundo activado...${NC}"
            ejecutar_pensamiento_profundo "$args" "$archivo_contexto"
            ;;
        "/files")
            echo -e "${PURPLE}📁 Listando archivos del proyecto...${NC}"
            listar_archivos_proyecto
            ;;
        "/focus")
            echo -e "${PURPLE}🎯 Enfocando en: $args${NC}"
            enfocar_archivo "$args"
            ;;
        "/summary")
            echo -e "${PURPLE}📋 Generando resumen del proyecto...${NC}"
            generar_resumen_proyecto "$archivo_contexto"
            ;;
        "/fix")
            echo -e "${PURPLE}🔨 Arreglando: $args${NC}"
            ejecutar_fix_problema "$args" "$archivo_contexto"
            ;;
        *)
            echo -e "${YELLOW}❓ Comando no reconocido: $cmd${NC}"
            echo -e "${DIM}Usa uno de los comandos disponibles o escribe tu pregunta normalmente.${NC}"
            ;;
    esac
}

# Función para procesar consulta normal
procesar_consulta_normal() {
    local prompt_completo="$1"
    local archivo_historial="$2"
    
    if $DEBUG; then
        echo "$(get_text "debug_complete_prompt_sent"):"
        echo "$prompt_completo"
        echo "$(get_text "debug_sending_request")..."
    fi
    
    echo -n "$(get_text "assistant"): $(get_text "thinking")..."
    
    # Usar un archivo temporal para almacenar la respuesta
    temp_file=$(mktemp)
    
    # Iniciar la consulta en segundo plano
    consultar_llm "$prompt_completo" > "$temp_file" &
    pid=$!
    
    mostrar_respuesta_streaming "$pid" "$temp_file"
    
    respuesta=$(cat "$temp_file")
    rm "$temp_file"
    
    if $DEBUG; then
        echo "$(get_text "debug_response_received"):"
        echo "$respuesta"
    fi
    
    # Guardar el historial actualizado
    echo "$prompt_completo" > "$archivo_historial"
    if $DEBUG; then
        echo "$(get_text "debug_history_updated_saved") $archivo_historial"
    fi
}

# Función para limpiar el historial
limpiar_historial() {
    local YELLOW='\033[1;33m'
    local GREEN='\033[0;32m'
    local NC='\033[0m'
    
    # Cargar idioma
    load_language
    
    echo -e "${YELLOW}🧹 Limpiando historial de conversaciones...${NC}"
    rm -f "$CONFIG_DIR"/historial_*.txt
    echo -e "${GREEN}$(get_text "history_cleaned")${NC}"
}

# Función para crear nuevo hito
nuevo_hito() {
    local CYAN='\033[0;36m'
    local GREEN='\033[0;32m'
    local NC='\033[0m'
    
    echo -e "${CYAN}📝 $(get_text "creating_new_milestone")...${NC}"
    # La próxima conversación empezará con un archivo de historial nuevo
    echo -e "${GREEN}✅ $(get_text "next_conversation_new_milestone")${NC}"
}

# Función para mostrar historiales
mostrar_historiales() {
    local CYAN='\033[0;36m'
    local YELLOW='\033[1;33m'
    local DIM='\033[2m'
    local NC='\033[0m'
    
    # Cargar idioma
    load_language
    
    echo -e "${CYAN}$(get_text "available_histories"):${NC}"
    echo -e "${DIM}────────────────────────────────────────────────────────────────${NC}"
    
    local count=0
    for archivo in "$CONFIG_DIR"/historial_*.txt; do
        if [ -f "$archivo" ]; then
            local fecha=$(basename "$archivo" | sed 's/historial_//' | sed 's/.txt//' | sed 's/_/ /')
            local tamaño=$(wc -l < "$archivo")
            echo -e "${YELLOW}📄${NC} $fecha (${tamaño} $(get_text "lines"))"
            count=$((count + 1))
        fi
    done
    
    if [ $count -eq 0 ]; then
        echo -e "${DIM}$(get_text "no_history")${NC}"
    fi
} 