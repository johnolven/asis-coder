#!/bin/bash

# Este script genera un archivo de contexto para diferentes tipos de proyectos y envía consultas a LLMs (ChatGPT o Claude)
# Puede ser ejecutado desde cualquier subdirectorio del proyecto
# Ejecuta el comando chmod +x coder.sh
# Luego ejecuta coder -contexto para generar el archivo de contexto
# O coder "tu pregunta" para enviar la pregunta al LLM seleccionado
# O coder -llm para seleccionar o cambiar el LLM
# O coder -model para ver y seleccionar modelos disponibles
# O coder -token para actualizar el token de API del LLM actual

# Obtener el directorio del script
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"

# Definir el archivo de log y configuración con rutas absolutas
log_file="$SCRIPT_DIR/coder.log"
config_file="$SCRIPT_DIR/coder_config.txt"

# Función para escribir logs
log() {
  echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" | tee -a "$log_file"
}

# Función para obtener la configuración de API
get_api_config() {
  if [ -f "$config_file" ]; then
    source "$config_file"
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

  echo "llm_choice=\"$llm_choice\"" > "$config_file"
  log "LLM seleccionado: $llm_choice"
  
  update_api_token
  update_model
}

# Función para actualizar el token de API
update_api_token() {
  local token_var="${llm_choice}_api_key"
  read -p "Por favor, introduce tu API token para $llm_choice: " api_key
  eval "$token_var=\"$api_key\""
  echo "${token_var}=\"$api_key\"" >> "$config_file"
  chmod 600 "$config_file"
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

  echo "model=\"$model\"" >> "$config_file"
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

  echo "model=\"$model\"" >> "$config_file"
  log "Modelo seleccionado: $model"
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

  # Llamar a la función recursiva para cada directorio especificado en el directorio del proyecto
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

  # Si no se encuentra el archivo de contexto
  echo "No se pudo encontrar el archivo de contexto en el directorio actual o en sus padres."
  return 1
}

# Función para escapar caracteres especiales en JSON
json_escape() {
  printf '%s' "$1" | python3 -c 'import json,sys; print(json.dumps(sys.stdin.read()))'
}

# Función para enviar la consulta al LLM seleccionado
consultar_llm() {
  local pregunta="$1"
  get_api_config
  local archivo_contexto=$(encontrar_archivo_contexto)

  if [ -z "$archivo_contexto" ]; then
    log "No se pudo encontrar el archivo de contexto. Ejecuta coder -contexto primero."
    exit 1
  fi

  local contexto="$(cat "$archivo_contexto")"
  local prompt="Contexto del proyecto:
$contexto

Pregunta: $pregunta"

  log "Enviando consulta a $llm_choice..."
  
  # Escapar caracteres especiales en el prompt
  local escaped_prompt=$(json_escape "$prompt")
  
  if [ "$llm_choice" == "chatgpt" ]; then
    local json_data='{
      "model": "'"$model"'",
      "messages": [{"role": "user", "content": '"$escaped_prompt"'}],
      "max_tokens": 1000,
      "temperature": 0.5
    }'
    local api_url="https://api.openai.com/v1/chat/completions"
    local api_key="$chatgpt_api_key"
    local auth_header="Authorization: Bearer $api_key"
  elif [ "$llm_choice" == "claude" ]; then
    local json_data='{
      "model": "'"$model"'",
      "messages": [{"role": "user", "content": '"$escaped_prompt"'}],
      "max_tokens": 1000,
      "temperature": 0.5
    }'
    local api_url="https://api.anthropic.com/v1/messages"
    local api_key="$claude_api_key"
    local auth_header="x-api-key: $api_key"
    local extra_header="anthropic-version: 2023-06-01"
  fi
  
  local temp_file=$(mktemp)
  
  curl -s -m 60 -w "\nHTTP_STATUS:%{http_code}" "$api_url" \
    -H "Content-Type: application/json" \
    -H "$auth_header" \
    ${extra_header:+-H "$extra_header"} \
    -d "$json_data" > "$temp_file" &

  curl_pid=$!

  while kill -0 $curl_pid 2>/dev/null; do
    echo -n "." 
    sleep 1
  done

  response=$(<"$temp_file")
  rm "$temp_file"
  
  http_status=$(echo "$response" | sed -n 's/.*HTTP_STATUS://p')
  body=$(echo "$response" | sed -e 's/HTTP_STATUS:.*//g')

  if [ "$http_status" -eq 200 ]; then
    log "Respuesta recibida de $llm_choice"
    echo "$body" | jq -r '.choices[0].message.content'
  else
    log "Error al recibir respuesta de $llm_choice. Código de estado HTTP: $http_status"
    error_message=$(echo "$body" | jq -r '.error.message // "Error desconocido"')
    echo "Error: $error_message"
  fi
}

# Función principal
main() {
  if [ "$1" == "-contexto" ]; then
    generar_contexto
  elif [ "$1" == "-llm" ]; then
    update_llm_choice
  elif [ "$1" == "-model" ]; then
    get_api_config
    update_model
  elif [ "$1" == "-token" ]; then
    get_api_config
    update_api_token
  elif [ -n "$1" ]; then
    consultar_llm "$*"
  else
    echo "Uso: coder -contexto | -llm | -model | -token | \"tu pregunta\""
  fi
}

# Ejecutar la función principal
main "$@"