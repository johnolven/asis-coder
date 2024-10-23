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

# Función para obtener la configuración de API
get_api_config() {
    if [ -f "$CONFIG_FILE" ]; then
        source "$CONFIG_FILE"
    fi

    if [ -z "$llm_choice" ] || { [ -z "$chatgpt_api_key" ] && [ -z "$claude_api_key" ]; }; then
        update_llm_choice
    fi

    if [ "$llm_choice" == "chatgpt" ] && [ -z "$chatgpt_api_key" ]; then
        update_api_token
    elif [ "$llm_choice" == "claude" ] && [ -z "$claude_api_key" ]; then
        update_api_token
    fi

    if [ -z "$model" ]; then
        update_model
    fi
}

# Función para actualizar la elección del LLM
update_llm_choice() {
    echo "Selecciona el LLM que deseas usar:"
    echo "1. ChatGPT"
    echo "2. Claude"
    read -p "Introduce el número correspondiente: " choice

    case $choice in
        1)
            llm_choice="chatgpt"
            ;;
        2)
            llm_choice="claude"
            ;;
        *)
            echo "Opción no válida. Seleccionando ChatGPT por defecto."
            llm_choice="chatgpt"
            ;;
    esac

    echo "llm_choice='$llm_choice'" > "$CONFIG_FILE"
    log "LLM seleccionado: $llm_choice"
    
    update_api_token
    update_model
}

# Función para actualizar el token de API
update_api_token() {
    local token_var="${llm_choice}_api_key"
    read -p "Por favor, introduce tu API token para $llm_choice: " api_key
    echo "${token_var}='$api_key'" >> "$CONFIG_FILE"
    chmod 600 "$CONFIG_FILE"
    eval "$token_var='$api_key'"
    log "Token de API para $llm_choice actualizado."
}

# Función para actualizar el modelo
update_model() {
    if [ "$llm_choice" == "chatgpt" ]; then
        list_chatgpt_models
    elif [ "$llm_choice" == "claude" ]; then
        list_claude_models
    fi
}

# Función para listar modelos de ChatGPT
list_chatgpt_models() {
    echo "Modelos disponibles de ChatGPT:"
    echo "1. gpt-3.5-turbo"
    echo "2. gpt-4"
    echo "3. gpt-4-32k"
    read -p "Selecciona el número del modelo que deseas usar: " model_choice

    case $model_choice in
        1)
            model="gpt-3.5-turbo"
            ;;
        2)
            model="gpt-4"
            ;;
        3)
            model="gpt-4-32k"
            ;;
        *)
            echo "Opción no válida. Seleccionando gpt-3.5-turbo por defecto."
            model="gpt-3.5-turbo"
            ;;
    esac

    echo "model='$model'" >> "$CONFIG_FILE"
    log "Modelo seleccionado: $model"
}

# Función para listar modelos de Claude
list_claude_models() {
    echo "Modelos disponibles de Claude:"
    echo "1. claude-3-5-sonnet-20240620"
    echo "2. claude-3-opus-20240229"
    read -p "Selecciona el número del modelo que deseas usar: " model_choice

    case $model_choice in
        1)
            model="claude-3-5-sonnet-20240620"
            ;;
        2)
            model="claude-3-opus-20240229"
            ;;
        *)
            echo "Opción no válida. Seleccionando claude-3-5-sonnet-20240620 por defecto."
            model="claude-3-5-sonnet-20240620"
            ;;
    esac

    echo "model='$model'" >> "$CONFIG_FILE"
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

# Función para preguntar al usuario el tipo de proyecto
preguntar_tipo_proyecto() {
    echo "Selecciona el tipo de proyecto:"
    echo "1. React"
    echo "2. Node.js"
    echo "3. Vue.js"
    echo "4. Angular"
    echo "5. Ruby on Rails"
    echo "6. Laravel"
    echo "7. Flask"
    echo "8. Spring Boot"
    echo "9. Express.js"
    echo "10. Flutter"
    echo "11. Bash"
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
    
    # Preguntar al usuario el tipo de proyecto
    preguntar_tipo_proyecto

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
    fi

    if $DEBUG; then
        echo "Petición enviada a $api_url:"
        echo "$json_data"
    fi

    local response=$(curl -s -H "Content-Type: application/json" \
                          -H "$auth_header" \
                          ${extra_header:+-H "$extra_header"} \
                          -d "$json_data" \
                          "$api_url")

    if $DEBUG; then
        echo "Respuesta recibida:"
        echo "$response"
    fi

    if [ $? -eq 0 ]; then
        if [ "$llm_choice" == "chatgpt" ]; then
            local content=$(echo "$response" | jq -r '.choices[0].message.content' 2>/dev/null)
        elif [ "$llm_choice" == "claude" ]; then
            local content=$(echo "$response" | jq -r '.content[0].text' 2>/dev/null)
        fi

        if [ -n "$content" ]; then
            echo "$content"
        else
            echo "Error: No se pudo extraer el contenido de la respuesta."
            echo "Respuesta completa: $response"
        fi
    else
        log "Error al recibir respuesta de $llm_choice."
        echo "Error: No se pudo obtener una respuesta del servidor."
    fi
}

# Función para el modo interactivo
modo_interactivo() {
    if $DEBUG; then
        echo "DEBUG: Modo interactivo iniciado con depuración activada."
    fi
    echo "Modo interactivo iniciado. Escribe 'salir' para terminar."
    
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
        
        if [ "$entrada" = "salir" ]; then
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
        "historial")
            mostrar_historiales
            ;;
        "")
            echo "Uso: coder [-debug] -contexto | -llm | -model | -token | -i | -v | -clean | -new | historial | \"tu pregunta\""
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

