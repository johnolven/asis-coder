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
        echo "Consulta recibida en consultar_llm:"
        echo "$pregunta"
        echo "Obteniendo configuración de API..."
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

# Función para modo interactivo
modo_interactivo() {
    local CYAN='\033[0;36m'
    local GREEN='\033[0;32m'
    local YELLOW='\033[1;33m'
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
    
    # Marcar que estamos en modo interactivo
    MODO_INTERACTIVO=true
    
    # Mostrar UI del modo interactivo
    mostrar_ui_interactivo
    
    # Configurar archivo de historial
    local archivo_historial="$CONFIG_DIR/historial_$(date +%Y%m%d_%H%M%S).txt"
    local archivo_contexto=$(encontrar_archivo_contexto)
    
    # Crear prompt inicial con contexto si existe
    local prompt_completo="Eres un asistente de desarrollo experto. "
    
    if [[ -n "$archivo_contexto" ]]; then
        echo -e "${GREEN}📄 Contexto del proyecto cargado${NC}"
        prompt_completo+="Aquí está el contexto del proyecto actual:

$(cat "$archivo_contexto")

Por favor, ayúdame con mis preguntas sobre este proyecto."
    else
        echo -e "${YELLOW}⚠️ No hay contexto del proyecto. Usa 'coder -contexto' para generarlo.${NC}"
        prompt_completo+="Ayúdame con mis preguntas de programación."
    fi
    
    if $DEBUG; then
        echo "DEBUG: Prompt inicial configurado:"
        echo "$prompt_completo"
        echo "DEBUG: Archivo de historial: $archivo_historial"
    fi
    
    # Loop del modo interactivo
    while true; do
        read -p "Tú: " entrada
        
        if [ "$entrada" = "salir" ] || [ "$entrada" = "exit" ] || [ "$entrada" = "quit" ]; then
            echo -e "${CYAN}👋 Saliendo del modo interactivo.${NC}"
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
    
    # Desmarcar modo interactivo
    unset MODO_INTERACTIVO
}

# Función para limpiar el historial
limpiar_historial() {
    local YELLOW='\033[1;33m'
    local GREEN='\033[0;32m'
    local NC='\033[0m'
    
    echo -e "${YELLOW}🧹 Limpiando historial de conversaciones...${NC}"
    rm -f "$CONFIG_DIR"/historial_*.txt
    echo -e "${GREEN}✅ Historial limpiado${NC}"
}

# Función para crear nuevo hito
nuevo_hito() {
    local CYAN='\033[0;36m'
    local GREEN='\033[0;32m'
    local NC='\033[0m'
    
    echo -e "${CYAN}📝 Creando nuevo hito de conversación...${NC}"
    # La próxima conversación empezará con un archivo de historial nuevo
    echo -e "${GREEN}✅ Próxima conversación será un nuevo hito${NC}"
}

# Función para mostrar historiales
mostrar_historiales() {
    local CYAN='\033[0;36m'
    local YELLOW='\033[1;33m'
    local DIM='\033[2m'
    local NC='\033[0m'
    
    echo -e "${CYAN}📚 Historiales de conversaciones:${NC}"
    echo -e "${DIM}────────────────────────────────────────────────────────────────${NC}"
    
    local count=0
    for archivo in "$CONFIG_DIR"/historial_*.txt; do
        if [ -f "$archivo" ]; then
            local fecha=$(basename "$archivo" | sed 's/historial_//' | sed 's/.txt//' | sed 's/_/ /')
            local tamaño=$(wc -l < "$archivo")
            echo -e "${YELLOW}📄${NC} $fecha (${tamaño} líneas)"
            count=$((count + 1))
        fi
    done
    
    if [ $count -eq 0 ]; then
        echo -e "${DIM}No hay historiales guardados${NC}"
    fi
} 