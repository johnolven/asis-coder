#!/bin/bash

# ==========================================
# MÓDULO DE CORE INTELIGENTE - intelligent_core.sh
# ==========================================
# Integración con core nativo compilado (propiedad intelectual)
# Este módulo actúa como bridge entre bash y el core propietario

# Variables globales para core inteligente
NATIVE_CORE_PATH=""
INTELLIGENT_FEATURES_ENABLED=false

# Función para detectar y configurar el core nativo
detect_and_setup_native_core() {
    local script_dir=$(dirname "${BASH_SOURCE[0]}")
    local project_root=$(dirname "$script_dir")
    
    # Detectar OS para seleccionar binario correcto
    local os_type=$(uname -s)
    local arch_type=$(uname -m)
    local binary_name=""
    
    case "$os_type" in
        "Darwin")
            if [ "$arch_type" = "arm64" ]; then
                binary_name="asis-core-macos-arm64"
            else
                binary_name="asis-core-macos-x64"
            fi
            ;;
        "Linux")
            binary_name="asis-core-linux"
            ;;
        "MINGW"*|"CYGWIN"*|"MSYS"*)
            binary_name="asis-core-windows.exe"
            ;;
        *)
            echo "⚠️ Sistema operativo no soportado para funciones avanzadas: $os_type"
            return 1
            ;;
    esac
    
    # Buscar binario en múltiples ubicaciones
    local possible_paths=(
        "$project_root/binaries/$binary_name"
        "$project_root/target/release/asis-core"
        "$project_root/native-core/target/release/asis-core"
        "$(which asis-core 2>/dev/null)"
    )
    
    for path in "${possible_paths[@]}"; do
        if [ -x "$path" ]; then
            NATIVE_CORE_PATH="$path"
            INTELLIGENT_FEATURES_ENABLED=true
            if $DEBUG; then
                echo "✅ Core inteligente encontrado en: $NATIVE_CORE_PATH"
            fi
            return 0
        fi
    done
    
    if $DEBUG; then
        echo "⚠️ Core inteligente no encontrado. Funciones avanzadas deshabilitadas."
        echo "   Ubicaciones buscadas:"
        for path in "${possible_paths[@]}"; do
            echo "   - $path"
        done
    fi
    
    return 1
}

# Función para verificar si las funciones inteligentes están disponibles
is_intelligent_core_available() {
    [ "$INTELLIGENT_FEATURES_ENABLED" = true ] && [ -x "$NATIVE_CORE_PATH" ]
}

# Función principal de procesamiento inteligente
process_with_intelligent_core() {
    local input="$1"
    local api_key="$2"
    local model="$3"
    local context_path="${4:-.}"
    
    if ! is_intelligent_core_available; then
        echo "❌ Funciones inteligentes no disponibles"
        return 1
    fi
    
    if $DEBUG; then
        echo "🧠 Ejecutando procesamiento inteligente..."
        echo "   Input: $input"
        echo "   Model: $model"
        echo "   Context: $context_path"
    fi
    
    # Ejecutar el binario nativo con procesamiento inteligente
    local result=$("$NATIVE_CORE_PATH" intelligent-process \
        --input "$input" \
        --api-key "$api_key" \
        --model "$model" \
        --context "$context_path" 2>/dev/null)
    
    local exit_code=$?
    
    if [ $exit_code -eq 0 ]; then
        echo "$result"
        return 0
    else
        if $DEBUG; then
            echo "❌ Error en procesamiento inteligente (código: $exit_code)"
        fi
        return $exit_code
    fi
}

# Función para generar contexto avanzado
generate_advanced_context() {
    local project_path="${1:-.}"
    
    if ! is_intelligent_core_available; then
        echo "❌ Análisis avanzado de contexto no disponible"
        return 1
    fi
    
    if $DEBUG; then
        echo "🔍 Generando contexto avanzado para: $project_path"
    fi
    
    local result=$("$NATIVE_CORE_PATH" analyze-context \
        --context "$project_path" 2>/dev/null)
    
    local exit_code=$?
    
    if [ $exit_code -eq 0 ]; then
        echo "$result"
        return 0
    else
        if $DEBUG; then
            echo "❌ Error en análisis de contexto (código: $exit_code)"
        fi
        return $exit_code
    fi
}

# Función para generar unidades de contexto
generate_context_units() {
    local project_path="${1:-.}"
    
    if ! is_intelligent_core_available; then
        echo "❌ Generación de unidades no disponible"
        return 1
    fi
    
    if $DEBUG; then
        echo "📋 Generando unidades de contexto..."
    fi
    
    local result=$("$NATIVE_CORE_PATH" generate-units \
        --context "$project_path" 2>/dev/null)
    
    local exit_code=$?
    
    if [ $exit_code -eq 0 ]; then
        echo "$result"
        return 0
    else
        if $DEBUG; then
            echo "❌ Error en generación de unidades (código: $exit_code)"
        fi
        return $exit_code
    fi
}

# Función para modificación de código con agentes
modify_code_with_agents() {
    local input="$1"
    local api_key="$2" 
    local model="$3"
    local files="$4"  # Separados por coma
    
    if ! is_intelligent_core_available; then
        echo "❌ Modificación inteligente de código no disponible"
        return 1
    fi
    
    if $DEBUG; then
        echo "🤖 Iniciando modificación de código con agentes..."
        echo "   Descripción: $input"
        echo "   Archivos: $files"
    fi
    
    # Convertir lista de archivos separados por coma a argumentos múltiples
    local files_args=""
    if [ -n "$files" ]; then
        IFS=',' read -ra FILE_ARRAY <<< "$files"
        for file in "${FILE_ARRAY[@]}"; do
            files_args="$files_args --files $(echo "$file" | xargs)"
        done
    fi
    
    local result=$("$NATIVE_CORE_PATH" modify-code \
        --input "$input" \
        --api-key "$api_key" \
        --model "$model" \
        $files_args 2>/dev/null)
    
    local exit_code=$?
    
    if [ $exit_code -eq 0 ]; then
        echo "$result"
        return 0
    else
        if $DEBUG; then
            echo "❌ Error en modificación de código (código: $exit_code)"
        fi
        return $exit_code
    fi
}

# Función para análisis de código con IA avanzada
analyze_code_intelligent() {
    local target_path="${1:-.}"
    local analysis_type="${2:-complete}"
    
    if ! is_intelligent_core_available; then
        # Fallback al análisis básico existente
        if command -v ejecutar_analisis_completo >/dev/null 2>&1; then
            ejecutar_analisis_completo "$target_path"
        else
            echo "❌ Análisis de código no disponible"
            return 1
        fi
        return $?
    fi
    
    if $DEBUG; then
        echo "🔬 Ejecutando análisis inteligente de código..."
        echo "   Ruta: $target_path"
        echo "   Tipo: $analysis_type"
    fi
    
    local context_data=$(generate_advanced_context "$target_path")
    if [ $? -ne 0 ]; then
        echo "❌ Error obteniendo contexto para análisis"
        return 1
    fi
    
    # El análisis se hace dentro del procesamiento inteligente
    local analysis_prompt="Realiza un análisis completo del código en este proyecto. 
    Incluye:
    1. Análisis arquitectónico
    2. Calidad del código  
    3. Problemas identificados
    4. Recomendaciones de mejora
    5. Métricas de complejidad
    
    Tipo de análisis: $analysis_type"
    
    process_with_intelligent_core "$analysis_prompt" "$api_key" "$model" "$target_path"
}

# Función para mostrar estado del core inteligente
show_intelligent_core_status() {
    local CYAN='\033[0;36m'
    local GREEN='\033[0;32m'
    local RED='\033[0;31m'
    local YELLOW='\033[1;33m'
    local BOLD='\033[1m'
    local NC='\033[0m'
    
    echo -e "${CYAN}${BOLD}🧠 Estado del Core Inteligente${NC}"
    echo -e "${YELLOW}──────────────────────────────────────────────────${NC}"
    
    if is_intelligent_core_available; then
        echo -e "   ${GREEN}✅ Core inteligente: ${BOLD}ACTIVADO${NC}"
        echo -e "   ${GREEN}📍 Ubicación: ${NC}$NATIVE_CORE_PATH"
        
        # Obtener versión del binario
        local version_info=$("$NATIVE_CORE_PATH" --version 2>/dev/null || echo "unknown")
        echo -e "   ${GREEN}📦 Versión: ${NC}$version_info"
        
        echo ""
        echo -e "${YELLOW}🚀 Funciones Avanzadas Disponibles:${NC}"
        echo -e "   ${CYAN}•${NC} Procesamiento inteligente con contexto"
        echo -e "   ${CYAN}•${NC} Análisis avanzado de código base"
        echo -e "   ${CYAN}•${NC} Generación automática de unidades"
        echo -e "   ${CYAN}•${NC} Modificación de código con agentes"
        echo -e "   ${CYAN}•${NC} Clustering semántico de código"
        echo -e "   ${CYAN}•${NC} Optimización de prompts propietaria"
    else
        echo -e "   ${RED}❌ Core inteligente: ${BOLD}DESACTIVADO${NC}"
        echo -e "   ${YELLOW}⚠️  Funcionando en modo básico${NC}"
        
        echo ""
        echo -e "${YELLOW}💡 Para activar funciones avanzadas:${NC}"
        echo -e "   ${CYAN}1.${NC} Compilar core nativo: ${BOLD}make build${NC}"
        echo -e "   ${CYAN}2.${NC} O descargar binarios: ${BOLD}make install-binaries${NC}"
        echo -e "   ${CYAN}3.${NC} Verificar instalación: ${BOLD}coder status${NC}"
    fi
    
    echo -e "${YELLOW}──────────────────────────────────────────────────${NC}"
}

# Función mejorada para consultar LLM con inteligencia
consultar_llm_inteligente() {
    local pregunta="$1"
    local usar_contexto_avanzado="${2:-true}"
    
    if $DEBUG; then
        echo "🔍 Consulta LLM inteligente iniciada..."
        echo "   Pregunta: $pregunta"
        echo "   Contexto avanzado: $usar_contexto_avanzado"
    fi
    
    # Si el core inteligente está disponible y se solicita contexto avanzado
    if is_intelligent_core_available && [ "$usar_contexto_avanzado" = "true" ]; then
        if $DEBUG; then
            echo "🧠 Usando procesamiento inteligente..."
        fi
        
        # Cargar configuración
        get_api_config
        
        local result=$(process_with_intelligent_core "$pregunta" "$api_key" "$model" ".")
        local exit_code=$?
        
        if [ $exit_code -eq 0 ]; then
            echo "$result"
            return 0
        else
            if $DEBUG; then
                echo "⚠️ Procesamiento inteligente falló, usando método básico..."
            fi
        fi
    fi
    
    # Fallback al método original
    if $DEBUG; then
        echo "📝 Usando consulta LLM básica..."
    fi
    consultar_llm "$pregunta"
}

# Función para verificar y reconstruir core si es necesario
ensure_intelligent_core() {
    if ! is_intelligent_core_available; then
        echo "🔧 Core inteligente no encontrado. Intentando compilar..."
        
        local script_dir=$(dirname "${BASH_SOURCE[0]}")
        local project_root=$(dirname "$script_dir")
        
        if [ -f "$project_root/Makefile" ]; then
            (cd "$project_root" && make build-core)
            detect_and_setup_native_core
        elif [ -f "$project_root/native-core/build.conf" ]; then
            echo "📦 Compilando core nativo..."
            echo "💡 Use 'make build' para compilar el core"
            detect_and_setup_native_core
        else
            echo "❌ No se puede compilar el core inteligente automáticamente"
            echo "💡 Ejecuta manualmente: make build"
            return 1
        fi
    fi
}

# Función de inicialización del módulo
init_intelligent_core() {
    if $DEBUG; then
        echo "🔄 Inicializando módulo de core inteligente..."
    fi
    
    detect_and_setup_native_core
    
    if is_intelligent_core_available && $DEBUG; then
        echo "✅ Core inteligente inicializado correctamente"
    fi
}

# ===============================================
# FUNCIONES DE ALTO NIVEL PARA COMANDOS
# ===============================================

# Función para ejecutar fix inteligente
ejecutar_fix_inteligente() {
    local descripcion="$1"
    
    if [ -z "$descripcion" ]; then
        echo "❌ Error: Describe el problema a arreglar"
        echo "💡 Ejemplo: coder code fix \"el login no funciona con emails en mayúsculas\""
        return 1
    fi
    
    echo "🔧 Iniciando fix inteligente..."
    echo "📋 Problema: $descripcion"
    
    if is_intelligent_core_available; then
        # Usar agentes de modificación de código
        get_api_config
        
        # Detectar archivos relevantes automáticamente
        local archivos_relevantes=$(detectar_archivos_relevantes "$descripcion")
        
        echo "📁 Archivos detectados: $archivos_relevantes"
        echo "🤖 Ejecutando agentes de fix..."
        
        local resultado=$(modify_code_with_agents "Fix: $descripcion" "$api_key" "$model" "$archivos_relevantes")
        
        if [ $? -eq 0 ]; then
            echo "$resultado"
            echo ""
            echo "✅ Fix inteligente completado"
        else
            echo "❌ Error en fix inteligente, usando método básico..."
            ejecutar_fix_problema "$descripcion" "."
        fi
    else
        echo "⚠️ Core inteligente no disponible, usando método básico..."
        ejecutar_fix_problema "$descripcion" "."
    fi
}

# Función para ejecutar implementación inteligente
ejecutar_implementacion_inteligente() {
    local descripcion="$1"
    
    if [ -z "$descripcion" ]; then
        echo "❌ Error: Describe la funcionalidad a implementar"
        echo "💡 Ejemplo: coder code implement \"sistema de notificaciones push\""
        return 1
    fi
    
    echo "⚡ Iniciando implementación inteligente..."
    echo "📋 Feature: $descripcion"
    
    if is_intelligent_core_available; then
        get_api_config
        
        echo "🧠 Analizando arquitectura actual..."
        local contexto_proyecto=$(generate_advanced_context ".")
        
        echo "🤖 Ejecutando agentes de implementación..."
        local resultado=$(modify_code_with_agents "Implement: $descripcion" "$api_key" "$model" "")
        
        if [ $? -eq 0 ]; then
            echo "$resultado"
            echo ""
            echo "✅ Implementación inteligente completada"
            echo "💡 Revisa los cambios y ejecuta tests antes de commit"
        else
            echo "❌ Error en implementación inteligente"
            return 1
        fi
    else
        echo "⚠️ Core inteligente no disponible"
        echo "💡 Para implementación avanzada, compila el core: make build"
        return 1
    fi
}

# Función para ejecutar análisis inteligente
ejecutar_analisis_inteligente() {
    local ruta="${1:-.}"
    
    echo "🔬 Iniciando análisis inteligente..."
    echo "📁 Analizando: $ruta"
    
    if is_intelligent_core_available; then
        echo "🧠 Generando contexto avanzado..."
        local contexto=$(generate_advanced_context "$ruta")
        
        echo "📊 Ejecutando análisis con IA..."
        get_api_config
        local analisis=$(process_with_intelligent_core "Realiza un análisis completo y detallado de este proyecto. Incluye arquitectura, calidad, problemas y recomendaciones." "$api_key" "$model" "$ruta")
        
        if [ $? -eq 0 ]; then
            echo "$analisis"
            echo ""
            echo "✅ Análisis inteligente completado"
        else
            echo "❌ Error en análisis inteligente, usando método básico..."
            analyze_code_intelligent "$ruta"
        fi
    else
        echo "⚠️ Core inteligente no disponible, usando análisis básico..."
        analyze_code_intelligent "$ruta"
    fi
}

# Función para ejecutar refactor inteligente
ejecutar_refactor_inteligente() {
    local descripcion="$1"
    
    if [ -z "$descripcion" ]; then
        echo "❌ Error: Describe qué refactorizar"
        echo "💡 Ejemplo: coder code refactor \"optimizar queries de base de datos\""
        return 1
    fi
    
    echo "🔄 Iniciando refactor inteligente..."
    echo "📋 Objetivo: $descripcion"
    
    if is_intelligent_core_available; then
        get_api_config
        
        echo "🔍 Analizando código actual..."
        local contexto=$(generate_advanced_context ".")
        
        echo "🤖 Ejecutando agentes de refactorización..."
        local resultado=$(modify_code_with_agents "Refactor: $descripcion" "$api_key" "$model" "")
        
        if [ $? -eq 0 ]; then
            echo "$resultado"
            echo ""
            echo "✅ Refactor inteligente completado"
        else
            echo "❌ Error en refactor inteligente, usando método básico..."
            ejecutar_refactorizacion "$descripcion" "."
        fi
    else
        echo "⚠️ Core inteligente no disponible, usando método básico..."
        ejecutar_refactorizacion "$descripcion" "."
    fi
}

# Función para generar unidades de contexto
generar_unidades_contexto() {
    local ruta="${1:-.}"
    
    echo "📋 Generando unidades de contexto..."
    
    if is_intelligent_core_available; then
        echo "🧠 Ejecutando análisis semántico avanzado..."
        local unidades=$(generate_context_units "$ruta")
        
        if [ $? -eq 0 ]; then
            echo "$unidades"
            echo ""
            echo "✅ Unidades de contexto generadas exitosamente"
            
            # Guardar unidades en archivo
            echo "$unidades" > "contexto_unidades.json"
            echo "💾 Guardado en: contexto_unidades.json"
        else
            echo "❌ Error generando unidades de contexto"
            return 1
        fi
    else
        echo "⚠️ Generación de unidades requiere core inteligente"
        echo "💡 Compila con: make build"
        return 1
    fi
}

# Función para mostrar estado completo
mostrar_estado_completo() {
    local CYAN='\033[0;36m'
    local GREEN='\033[0;32m'
    local RED='\033[0;31m'
    local YELLOW='\033[1;33m'
    local BLUE='\033[0;34m'
    local BOLD='\033[1m'
    local NC='\033[0m'
    
    clear
    echo -e "${CYAN}${BOLD}📊 ESTADO COMPLETO DE ASIS-CODER${NC}"
    echo -e "${YELLOW}════════════════════════════════════════════════════════════${NC}"
    echo ""
    
    # Estado básico
    echo -e "${BLUE}${BOLD}🚀 Sistema Base:${NC}"
    echo -e "${YELLOW}──────────────────────────────────────────────────────────${NC}"
    echo -e "   ${GREEN}✅ Script principal: ${BOLD}coder.sh v$VERSION${NC}"
    echo -e "   ${GREEN}✅ Módulos Bash: ${BOLD}$(ls lib/*.sh 2>/dev/null | wc -l | tr -d ' ') módulos cargados${NC}"
    
    # Estado de configuración
    echo ""
    echo -e "${BLUE}${BOLD}⚙️ Configuración:${NC}"
    echo -e "${YELLOW}──────────────────────────────────────────────────────────${NC}"
    
    if [ -f "$CONFIG_FILE" ]; then
        source "$CONFIG_FILE" 2>/dev/null || true
        if [ -n "$llm_choice" ]; then
            echo -e "   ${GREEN}✅ LLM configurado: ${BOLD}$llm_choice${NC}"
            echo -e "   ${GREEN}✅ Modelo: ${BOLD}${model:-por defecto}${NC}"
        else
            echo -e "   ${RED}❌ LLM no configurado${NC}"
        fi
    else
        echo -e "   ${RED}❌ Configuración no encontrada${NC}"
    fi
    
    # Estado del core inteligente
    echo ""
    show_intelligent_core_status
    
    # Estado del proyecto actual
    echo ""
    echo -e "${BLUE}${BOLD}📁 Proyecto Actual:${NC}"
    echo -e "${YELLOW}──────────────────────────────────────────────────────────${NC}"
    local proyecto_detectado=$(detectar_proyecto_actual)
    if [ -n "$proyecto_detectado" ]; then
        echo -e "   ${GREEN}✅ Tipo detectado: ${BOLD}$proyecto_detectado${NC}"
    else
        echo -e "   ${YELLOW}⚠️  Tipo de proyecto no detectado${NC}"
    fi
    
    local contexto_existe=$(encontrar_archivo_contexto)
    if [ -n "$contexto_existe" ]; then
        echo -e "   ${GREEN}✅ Contexto disponible: ${NC}$(basename "$contexto_existe")"
    else
        echo -e "   ${YELLOW}⚠️  Contexto no generado${NC}"
    fi
    
    # Comandos disponibles
    echo ""
    echo -e "${BLUE}${BOLD}🎯 Comandos Disponibles:${NC}"
    echo -e "${YELLOW}──────────────────────────────────────────────────────────${NC}"
    echo -e "${GREEN}📋 Comandos Básicos:${NC}"
    echo -e "   ${CYAN}•${NC} coder setup              # Configuración inicial"
    echo -e "   ${CYAN}•${NC} coder -i                 # Modo interactivo"
    echo -e "   ${CYAN}•${NC} coder \"pregunta\"          # Consulta directa"
    echo -e "   ${CYAN}•${NC} coder -contexto          # Generar contexto"
    
    if is_intelligent_core_available; then
        echo -e "${GREEN}🤖 Comandos Inteligentes:${NC}"
        echo -e "   ${CYAN}•${NC} coder code fix \"problema\"    # Fix inteligente"
        echo -e "   ${CYAN}•${NC} coder code implement \"feature\" # Implementación"
        echo -e "   ${CYAN}•${NC} coder code analyze           # Análisis avanzado"  
        echo -e "   ${CYAN}•${NC} coder code refactor \"objetivo\" # Refactorización"
        echo -e "   ${CYAN}•${NC} coder units                  # Unidades de contexto"
    else
        echo -e "${YELLOW}⚠️  Comandos inteligentes no disponibles${NC}"
        echo -e "   ${CYAN}💡${NC} Compila con: ${BOLD}make build${NC}"
    fi
    
    echo -e "${YELLOW}════════════════════════════════════════════════════════════${NC}"
}

# Función para mostrar ayuda de comandos de código
mostrar_ayuda_code() {
    local CYAN='\033[0;36m'
    local GREEN='\033[0;32m'
    local YELLOW='\033[1;33m'
    local BOLD='\033[1m'
    local NC='\033[0m'
    
    echo -e "${CYAN}${BOLD}🤖 COMANDOS DE CODIFICACIÓN INTELIGENTE${NC}"
    echo -e "${YELLOW}════════════════════════════════════════════════════════${NC}"
    echo ""
    echo -e "${GREEN}Uso: ${BOLD}coder code <comando> [argumentos]${NC}"
    echo ""
    echo -e "${GREEN}Comandos disponibles:${NC}"
    echo -e "   ${CYAN}fix <descripción>${NC}        # Arreglar bugs automáticamente"
    echo -e "   ${CYAN}implement <feature>${NC}      # Implementar nueva funcionalidad"
    echo -e "   ${CYAN}analyze [ruta]${NC}           # Análisis avanzado de código"
    echo -e "   ${CYAN}refactor <objetivo>${NC}      # Refactorización inteligente"
    echo ""
    echo -e "${GREEN}Ejemplos:${NC}"
    echo -e "   ${YELLOW}coder code fix \"el login falla con emails en mayúsculas\"${NC}"
    echo -e "   ${YELLOW}coder code implement \"sistema de notificaciones push\"${NC}"
    echo -e "   ${YELLOW}coder code analyze src/${NC}"
    echo -e "   ${YELLOW}coder code refactor \"optimizar queries de base de datos\"${NC}"
    echo ""
    echo -e "${GREEN}💡 Nota:${NC} Estos comandos requieren el core inteligente compilado."
    echo -e "   Para compilar: ${BOLD}make build${NC}"
    echo -e "${YELLOW}════════════════════════════════════════════════════════${NC}"
}

# Función auxiliar para detectar archivos relevantes
detectar_archivos_relevantes() {
    local descripcion="$1"
    local archivos=""
    
    # Lógica simple para detectar archivos basada en palabras clave
    local descripcion_lower=$(echo "$descripcion" | tr '[:upper:]' '[:lower:]')
    
    if echo "$descripcion_lower" | grep -q "login\|auth\|authentication"; then
        archivos="$(find . -name "*auth*" -o -name "*login*" | head -5 | tr '\n' ',' | sed 's/,$//')"
    elif echo "$descripcion_lower" | grep -q "database\|query\|model"; then
        archivos="$(find . -name "*model*" -o -name "*db*" -o -name "*database*" | head -5 | tr '\n' ',' | sed 's/,$//')"
    elif echo "$descripcion_lower" | grep -q "api\|endpoint\|route"; then
        archivos="$(find . -name "*api*" -o -name "*route*" -o -name "*controller*" | head -5 | tr '\n' ',' | sed 's/,$//')"
    else
        # Detectar archivos principales del proyecto
        archivos="$(find . -maxdepth 2 -name "*.js" -o -name "*.ts" -o -name "*.py" -o -name "*.rs" | head -3 | tr '\n' ',' | sed 's/,$//')"
    fi
    
    echo "$archivos"
}
