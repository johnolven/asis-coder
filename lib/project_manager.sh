#!/bin/bash

# ==========================================
# MÓDULO DE GESTIÓN DE PROYECTOS - project_manager.sh
# ==========================================
# Gestiona la detección de tipos de proyecto, generación de contexto,
# lectura de archivos y configuración específica de proyectos

# Función para detectar automáticamente el tipo de proyecto
detectar_tipo_proyecto() {
    local directorio_actual=$(pwd)
    
    # Cargar idioma
    load_language
    
    # React
    if [[ -f "$directorio_actual/package.json" ]]; then
        local package_content=$(cat "$directorio_actual/package.json")
        if echo "$package_content" | grep -q "react"; then
            echo "$(get_text "react_detected")"
            tipo_proyecto=1
            return
        elif echo "$package_content" | grep -q "vue"; then
            echo "$(get_text "vue_detected")"
            tipo_proyecto=3
            return
        elif echo "$package_content" | grep -q "angular"; then
            echo "$(get_text "angular_detected")"
            tipo_proyecto=4
            return
        elif echo "$package_content" | grep -q "express"; then
            echo "$(get_text "express_detected")"
            tipo_proyecto=9
            return
        else
            echo "$(get_text "node_detected")"
            tipo_proyecto=2
            return
        fi
    fi
    
    # Ruby on Rails
    if [[ -f "$directorio_actual/Gemfile" ]] && grep -q "rails" "$directorio_actual/Gemfile"; then
        echo "$(get_text "rails_detected")"
        tipo_proyecto=5
        return
    fi
    
    # Laravel
    if [[ -f "$directorio_actual/composer.json" ]] && grep -q "laravel" "$directorio_actual/composer.json"; then
        echo "$(get_text "laravel_detected")"
        tipo_proyecto=6
        return
    fi
    
    # Flask/Django
    if [[ -f "$directorio_actual/requirements.txt" ]]; then
        if grep -q "flask" "$directorio_actual/requirements.txt"; then
            echo "$(get_text "flask_detected")"
            tipo_proyecto=7
            return
        elif grep -q "django" "$directorio_actual/requirements.txt"; then
            echo "$(get_text "django_detected")"
            tipo_proyecto=7
            return
        fi
    fi
    
    # Spring Boot
    if [[ -f "$directorio_actual/pom.xml" ]] && grep -q "spring-boot" "$directorio_actual/pom.xml"; then
        echo "$(get_text "spring_detected")"
        tipo_proyecto=8
        return
    fi
    
    # Flutter
    if [[ -f "$directorio_actual/pubspec.yaml" ]] && grep -q "flutter" "$directorio_actual/pubspec.yaml"; then
        echo "$(get_text "flutter_detected")"
        tipo_proyecto=10
        return
    fi
    
    # Si no se detecta automáticamente, preguntar al usuario
    preguntar_tipo_proyecto_manual
}

# Función para preguntar al usuario el tipo de proyecto
preguntar_tipo_proyecto_manual() {
    local YELLOW='\033[1;33m'
    local CYAN='\033[0;36m'
    local BOLD='\033[1m'
    local NC='\033[0m'
    
    echo -e "${YELLOW}❓ $(get_text "project_type_not_detected_manual")${NC}"
    echo -e "${CYAN}${BOLD}$(get_text "select_project_type"):${NC}"
    echo "1. React"
    echo "2. Node.js"
    echo "3. Vue.js"
    echo "4. Angular"
    echo "5. Ruby on Rails"
    echo "6. Laravel"
    echo "7. Python (Flask/Django)"
    echo "8. Spring Boot"
    echo "9. Express.js"
    echo "10. Flutter"
    echo "11. $(get_text "other")"
    
    read -p "$(echo -e "${CYAN}$(get_text "enter_project_type_number"): ${NC}")" tipo_proyecto
    
    if [[ ! "$tipo_proyecto" =~ ^[1-9]$|^1[01]$ ]]; then
        echo -e "${YELLOW}⚠️ $(get_text "invalid_option_selecting_other")${NC}"
        tipo_proyecto=11
    fi
}

# Función para definir directorios y archivos a ignorar según el tipo de proyecto
definir_directorios_y_ignorar() {
    case $tipo_proyecto in
        1)
            directorios=("src" "public" "components" "pages" "hooks" "utils" "styles" "assets")
            ;;
        2)
            directorios=("src" "lib" "routes" "controllers" "models" "middlewares" "utils" "config")
            ;;
        3)
            directorios=("src" "components" "views" "router" "store" "assets" "utils")
            ;;
        4)
            directorios=("src" "app" "components" "services" "models" "guards" "pipes" "assets")
            ;;
        5)
            directorios=("app" "config" "db" "lib" "spec" "test")
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
    local CYAN='\033[0;36m'
    local GREEN='\033[0;32m'
    local YELLOW='\033[1;33m'
    local BOLD='\033[1m'
    local NC='\033[0m'
    
    echo -e "${CYAN}${BOLD}📝 $(get_text "generating_project_context")...${NC}"
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
        echo -e "${RED}$(get_text "error_write_dir")${NC}"
        exit 1
    fi

    # Si el archivo de salida existe, eliminarlo
    [ -f "$archivo_salida" ] && rm "$archivo_salida"

    echo -e "${YELLOW}📁 $(get_text "project_directory"): $directorio_proyecto${NC}"
    echo -e "${YELLOW}🔍 $(get_text "directories_to_analyze"): ${directorios[@]}${NC}"
    echo -e "${YELLOW}📄 $(get_text "output_file"): $archivo_salida${NC}"

    # Llamar a la función recursiva para cada directorio especificado
    for dir in "${directorios[@]}"; do
        [ -d "${directorio_proyecto}/${dir}" ] && leer_archivos "${directorio_proyecto}/${dir}"
    done

    if [ ! -s "$archivo_salida" ]; then
        log "Advertencia: El archivo de contexto está vacío. No se encontraron archivos para procesar."
        echo -e "${YELLOW}⚠️ $(get_text "warning_no_files_found")${NC}"
    else
        log "Archivo de contexto generado con éxito en $archivo_salida"
        echo -e "${GREEN}✅ $(get_text "context_file_generated_successfully")${NC}"
        echo -e "${GREEN}📄 $(get_text "location"): ${BOLD}$archivo_salida${NC}"
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

# Función para detectar el tipo de proyecto actual (para UI)
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

# Función para inicializar proyecto
inicializar_proyecto() {
    local CYAN='\033[0;36m'
    local GREEN='\033[0;32m'
    local YELLOW='\033[1;33m'
    local BOLD='\033[1m'
    local NC='\033[0m'
    
    # Validar configuración antes de inicializar
    if ! is_config_valid; then
        get_api_config
        if ! is_config_valid; then
            mostrar_error_configuracion
            return 1
        fi
    else
        source "$CONFIG_FILE"
    fi
    
    echo -e "${CYAN}${BOLD}🚀 $(get_text "initializing_project_with_asis")...${NC}"
    
    # Generar contexto automáticamente
    echo -e "${YELLOW}📝 $(get_text "generating_project_context")...${NC}"
    generar_contexto
    
    # Crear archivo CODER.md con información del proyecto
    echo -e "${YELLOW}📋 $(get_text "creating_project_guide")...${NC}"
    crear_guia_proyecto
    
    # Sugerir commit del archivo
    echo -e "${GREEN}✅ $(get_text "project_initialized_correctly")!${NC}"
    echo -e "${YELLOW}💡 $(get_text "suggestion_git_commit")${NC}"
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

        echo "$(get_text "generating_project_guide")..."
        local guia=$(consultar_llm "$prompt")
        
        if [ -n "$guia" ]; then
            echo "$guia" > "CODER.md"
            echo "✅ $(get_text "coder_md_file_created")."
        else
            echo "$(get_text "error_generate_guide")"
        fi
    else
        echo "❌ $(get_text "context_file_not_found")."
    fi
} 