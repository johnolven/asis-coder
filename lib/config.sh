#!/bin/bash

# ==========================================
# MÓDULO DE CONFIGURACIÓN - config.sh
# ==========================================
# Gestiona la configuración del sistema, variables de entorno,
# archivos de configuración y configuración inicial

# Variables globales de configuración
USER_HOME="$HOME"
CONFIG_DIR="$USER_HOME/.config/coder-cli"
BIN_DIR="$USER_HOME/.local/bin"
LOG_FILE="$CONFIG_DIR/coder.log"
CONFIG_FILE="$CONFIG_DIR/config.json"
LANG_FILE="$CONFIG_DIR/language.conf"
DEBUG=false
VERSION="1.0.1"

# Variables de idioma
DEFAULT_LANG="es"
CURRENT_LANG="es"

# Inicializar directorios necesarios
init_config_directories() {
    mkdir -p "$CONFIG_DIR"
    mkdir -p "$BIN_DIR"
}

# Función para detectar idioma del sistema
detect_system_language() {
    local sys_lang=""
    
    # Intentar detectar desde variables de entorno
    if [ -n "$LANG" ]; then
        sys_lang=$(echo "$LANG" | cut -d'_' -f1)
    elif [ -n "$LC_ALL" ]; then
        sys_lang=$(echo "$LC_ALL" | cut -d'_' -f1)
    elif [ -n "$LC_MESSAGES" ]; then
        sys_lang=$(echo "$LC_MESSAGES" | cut -d'_' -f1)
    fi
    
    # Verificar si es un idioma soportado
    case "$sys_lang" in
        "es"|"spa"|"spanish")
            echo "es"
            ;;
        "en"|"eng"|"english")
            echo "en"
            ;;
        *)
            echo "en"  # Por defecto inglés
            ;;
    esac
}

# Función para cargar idioma configurado
load_language() {
    if [ -f "$LANG_FILE" ]; then
        CURRENT_LANG=$(cat "$LANG_FILE")
    else
        # Si no hay configuración, detectar idioma del sistema
        CURRENT_LANG=$(detect_system_language)
        save_language "$CURRENT_LANG"
    fi
}

# Función para guardar idioma
save_language() {
    local lang="$1"
    echo "$lang" > "$LANG_FILE"
    CURRENT_LANG="$lang"
}

# Función para seleccionar idioma
select_language() {
    local CYAN='\033[0;36m'
    local GREEN='\033[0;32m'
    local YELLOW='\033[1;33m'
    local BOLD='\033[1m'
    local NC='\033[0m'
    
    clear
    echo -e "${CYAN}${BOLD}🌐 LANGUAGE SELECTION / SELECCIÓN DE IDIOMA${NC}"
    echo ""
    echo -e "${YELLOW}Please select your preferred language:${NC}"
    echo -e "${YELLOW}Por favor selecciona tu idioma preferido:${NC}"
    echo ""
    echo -e "${GREEN}1.${NC} English"
    echo -e "${GREEN}2.${NC} Español"
    echo ""
    
    while true; do
        read -p "$(echo -e "${CYAN}Select option / Selecciona opción (1-2): ${NC}")" lang_choice
        
        case $lang_choice in
            1)
                save_language "en"
                echo -e "${GREEN}✓ Language set to English${NC}"
                sleep 1
                break
                ;;
            2)
                save_language "es"
                echo -e "${GREEN}✓ Idioma configurado a Español${NC}"
                sleep 1
                break
                ;;
            *)
                echo -e "${YELLOW}Invalid option. Please select 1 or 2.${NC}"
                echo -e "${YELLOW}Opción inválida. Por favor selecciona 1 o 2.${NC}"
                ;;
        esac
    done
}

# Función para detectar si se está ejecutando con npx
is_running_with_npx() {
    # Verificar si el comando 'coder' está disponible globalmente
    if command -v coder >/dev/null 2>&1; then
        return 1  # coder está instalado globalmente
    else
        return 0  # probablemente ejecutándose con npx
    fi
}

# Función para obtener el comando base correcto
get_command_prefix() {
    # Siempre usar comandos cortos
    echo "coder"
}

# Función para obtener texto en el idioma actual
get_text() {
    local key="$1"
    
    case "$CURRENT_LANG" in
        "en")
            get_text_en "$key"
            ;;
        "es")
            get_text_es "$key"
            ;;
        *)
            get_text_en "$key"  # Por defecto inglés
            ;;
    esac
}

# Textos en inglés
get_text_en() {
    local key="$1"
    case "$key" in
        "welcome_title") echo "🎉 WELCOME! 🎉" ;;
        "welcome_subtitle") echo "ASIS-CODER - Initial Setup" ;;
        "welcome_desc") echo "Your AI development assistant is ready to help you code more efficiently" ;;
        "system_status") echo "🔍 System Status" ;;
        "llm_configured") echo "LLM configured" ;;
        "llm_not_configured") echo "LLM not configured" ;;
        "model") echo "Model" ;;
        "config_not_found") echo "Configuration not found" ;;
        "main_commands") echo "🚀 Main Commands" ;;
        "initial_setup") echo "Complete initial setup" ;;
        "interactive_mode") echo "Interactive chat mode" ;;
        "direct_query") echo "Direct query" ;;
        "generate_context") echo "Generate project context" ;;
        "init_project") echo "Initialize project" ;;
        "change_ai") echo "Change AI model" ;;
        "view_config") echo "View/change configuration" ;;
        "test_config") echo "Test configuration" ;;
        "usage_examples") echo "💡 Usage Examples" ;;
        "explain_project") echo "explain this project" ;;
        "find_bugs") echo "find bugs in my code" ;;
        "generate_tests") echo "generate tests for auth module" ;;
        "document_function") echo "document this function" ;;
        "interactive_welcome") echo "✻ Welcome to Asis-coder Interactive Mode!" ;;
        "project") echo "Project" ;;
        "ai") echo "AI" ;;
        "write_questions") echo "💬 Write your questions and press Enter" ;;
        "exit_commands") echo "Commands: exit, quit to finish" ;;
        "ai_assistant") echo "🤖Your AI Development Assistant" ;;
        "powered_by") echo "Powered by @JohnOlven" ;;
        "current_status") echo "📊 Current Status" ;;
        "configured") echo "Configured" ;;
        "not_configured") echo "Not configured" ;;
        "project_detected") echo "Project detected" ;;
        "project_not_detected") echo "Project not detected" ;;
        "context_available") echo "Context available" ;;
        "no_context") echo "No context" ;;
        "press_key") echo "Press any key to continue or Ctrl+C to exit" ;;
        "setup_title") echo "🚀 INITIAL SETUP" ;;
        "setup_desc") echo "Let's configure your AI assistant" ;;
        "select_llm") echo "Select your preferred LLM:" ;;
        "enter_api_key") echo "Enter your API key" ;;
        "api_key_hidden") echo "🔒 For security, the API key won't be displayed while typing" ;;
        "api_key_valid") echo "✅ API key is valid!" ;;
        "api_key_invalid") echo "❌ Invalid API key. Please try again." ;;
        "select_model") echo "Select a model:" ;;
        "setup_complete") echo "🎉 Setup completed successfully!" ;;
        "ready_to_use") echo "Asis-coder is ready to use!" ;;
        "first_steps") echo "📋 Next steps:" ;;
        "generate_context_step") echo "Generate project context: coder -context" ;;
        "interactive_step") echo "Start interactive mode: coder -i" ;;
        "direct_query_step") echo "Ask directly: coder \"your question\"" ;;
        "llm_selection") echo "🤖 LLM SELECTION" ;;
        "select_ai_assistant") echo "Select your preferred AI assistant:" ;;
        "cost_medium") echo "💰 Medium cost" ;;
        "very_smart") echo "🧠 Very smart" ;;
        "fast") echo "⚡ Fast" ;;
        "models") echo "models" ;;
        "premium") echo "💎 Premium" ;;
        "creative") echo "🎨 Creative" ;;
        "excellent_writing") echo "📝 Excellent for writing" ;;
        "free") echo "🆓 Free" ;;
        "updated_data") echo "📊 Updated data" ;;
        "integrated_search") echo "🔍 Integrated search" ;;
        "enter_choice") echo "Enter your choice" ;;
        "selected") echo "selected" ;;
        "invalid_option") echo "⚠️ Invalid option. Selecting ChatGPT by default." ;;
        "api_key_config") echo "🔑 API KEY CONFIGURATION" ;;
        "get_chatgpt_key") echo "📋 To get your ChatGPT API key:" ;;
        "get_claude_key") echo "📋 To get your Claude API key:" ;;
        "get_gemini_key") echo "📋 To get your Gemini API key:" ;;
        "login_create_key") echo "Log in and create a new API key" ;;
        "copy_key") echo "Copy the key" ;;
        "starts_with") echo "starts with" ;;
        "enter_api_key_prompt") echo "Enter your API key" ;;
        "api_key_saved") echo "✅ API key saved correctly" ;;
        "no_api_key") echo "❌ No API key provided" ;;
        "api_key_for") echo "💡 No API key found for" ;;
        "already_configured") echo "✅ API key for" ;;
        "interactive_mode_title") echo "🎮 INTERACTIVE MODE" ;;
        "project_context_loaded") echo "📄 Project context loaded" ;;
        "no_project_context") echo "⚠️ No project context. Use 'coder -context' to generate it." ;;
        "error_no_response") echo "❌ Error: Could not get a response from the server." ;;
        "check_connection") echo "💡 Check your internet connection and API key." ;;
        "no_credits") echo "🔥 It seems you don't have enough credits in your account." ;;
        "verify_api_key") echo "🔑 Verify that your API key is valid." ;;
        "history_cleaned") echo "🧹 Conversation history cleaned" ;;
        "no_history") echo "📭 No conversation history found" ;;
        "available_histories") echo "📚 Available conversation histories:" ;;
        "select_history") echo "Select a history to view (or 'q' to exit):" ;;
        "invalid_selection") echo "❌ Invalid selection" ;;
        "api_key_hidden") echo "🔒 For security, the API key will not be shown while typing" ;;
        "react_detected") echo "🔍 React project automatically detected" ;;
        "vue_detected") echo "🔍 Vue.js project automatically detected" ;;
        "angular_detected") echo "🔍 Angular project automatically detected" ;;
        "express_detected") echo "🔍 Express.js project automatically detected" ;;
        "node_detected") echo "🔍 Node.js project automatically detected" ;;
        "rails_detected") echo "🔍 Ruby on Rails project automatically detected" ;;
        "laravel_detected") echo "🔍 Laravel project automatically detected" ;;
        "flask_detected") echo "🔍 Flask project automatically detected" ;;
        "django_detected") echo "🔍 Django project automatically detected" ;;
        "spring_detected") echo "🔍 Spring Boot project automatically detected" ;;
        "flutter_detected") echo "🔍 Flutter project automatically detected" ;;
        "error_write_dir") echo "❌ Error: Cannot write to directory" ;;
        "error_generate_guide") echo "❌ Error generating project guide." ;;
        "validating_api_config") echo "🔍 Validating API configuration..." ;;
        "unknown_error") echo "Unknown error" ;;
        "config_error") echo "❌ Configuration Error" ;;
        "test_error") echo "❌ Test error" ;;
        *) echo "$key" ;;
    esac
}

# Textos en español
get_text_es() {
    local key="$1"
    case "$key" in
        "welcome_title") echo "🎉 ¡BIENVENIDO! 🎉" ;;
        "welcome_subtitle") echo "ASIS-CODER - Configuración Inicial" ;;
        "welcome_desc") echo "Tu asistente de desarrollo con IA está listo para ayudarte a programar más eficientemente" ;;
        "system_status") echo "🔍 Estado del Sistema" ;;
        "llm_configured") echo "LLM configurado" ;;
        "llm_not_configured") echo "LLM no configurado" ;;
        "model") echo "Modelo" ;;
        "config_not_found") echo "Configuración no encontrada" ;;
        "main_commands") echo "🚀 Comandos Principales" ;;
        "initial_setup") echo "Configuración inicial completa" ;;
        "interactive_mode") echo "Modo chat interactivo" ;;
        "direct_query") echo "Consulta directa" ;;
        "generate_context") echo "Generar contexto del proyecto" ;;
        "init_project") echo "Inicializar proyecto" ;;
        "change_ai") echo "Cambiar modelo de IA" ;;
        "view_config") echo "Ver/cambiar configuración" ;;
        "test_config") echo "Probar configuración" ;;
        "usage_examples") echo "💡 Ejemplos de Uso" ;;
        "explain_project") echo "explica este proyecto" ;;
        "find_bugs") echo "encuentra bugs en mi código" ;;
        "generate_tests") echo "genera tests para el módulo de auth" ;;
        "document_function") echo "documenta esta función" ;;
        "interactive_welcome") echo "✻ ¡Bienvenido al Modo Interactivo de Asis-coder!" ;;
        "project") echo "Proyecto" ;;
        "ai") echo "IA" ;;
        "write_questions") echo "💬 Escribe tus preguntas y presiona Enter" ;;
        "exit_commands") echo "Comandos: salir, exit, quit para terminar" ;;
        "ai_assistant") echo "🤖Tu Asistente de Desarrollo con IA" ;;
        "powered_by") echo "Powered by @JohnOlven" ;;
        "current_status") echo "📊 Estado Actual" ;;
        "configured") echo "Configurado" ;;
        "not_configured") echo "No configurado" ;;
        "project_detected") echo "Proyecto detectado" ;;
        "project_not_detected") echo "Proyecto no detectado" ;;
        "context_available") echo "Contexto disponible" ;;
        "no_context") echo "Sin contexto" ;;
        "press_key") echo "Presiona cualquier tecla para continuar o Ctrl+C para salir" ;;
        "setup_title") echo "🚀 CONFIGURACIÓN INICIAL" ;;
        "setup_desc") echo "Vamos a configurar tu asistente de IA" ;;
        "select_llm") echo "Selecciona tu LLM preferido:" ;;
        "enter_api_key") echo "Ingresa tu API key" ;;
        "api_key_hidden") echo "🔒 Por seguridad, la API key no se mostrará mientras escribes" ;;
        "api_key_valid") echo "✅ ¡API key válida!" ;;
        "api_key_invalid") echo "❌ API key inválida. Por favor intenta de nuevo." ;;
        "select_model") echo "Selecciona un modelo:" ;;
        "setup_complete") echo "🎉 ¡Configuración completada exitosamente!" ;;
        "ready_to_use") echo "¡Asis-coder está listo para usar!" ;;
        "first_steps") echo "📋 Próximos pasos:" ;;
        "generate_context_step") echo "Generar contexto del proyecto: coder -context" ;;
        "interactive_step") echo "Iniciar modo interactivo: coder -i" ;;
        "direct_query_step") echo "Preguntar directamente: coder \"tu pregunta\"" ;;
        "llm_selection") echo "🤖 SELECCIÓN DE LLM" ;;
        "select_ai_assistant") echo "Selecciona tu asistente de IA preferido:" ;;
        "cost_medium") echo "💰 Costo medio" ;;
        "very_smart") echo "🧠 Muy inteligente" ;;
        "fast") echo "⚡ Rápido" ;;
        "models") echo "modelos" ;;
        "premium") echo "💎 Premium" ;;
        "creative") echo "🎨 Creativo" ;;
        "excellent_writing") echo "📝 Excelente para escritura" ;;
        "free") echo "🆓 Gratis" ;;
        "updated_data") echo "📊 Datos actualizados" ;;
        "integrated_search") echo "🔍 Búsqueda integrada" ;;
        "enter_choice") echo "Ingresa tu elección" ;;
        "selected") echo "seleccionado" ;;
        "invalid_option") echo "⚠️ Opción no válida. Seleccionando ChatGPT por defecto." ;;
        "api_key_config") echo "🔑 CONFIGURACIÓN DE API KEY" ;;
        "get_chatgpt_key") echo "📋 Para obtener tu API key de ChatGPT:" ;;
        "get_claude_key") echo "📋 Para obtener tu API key de Claude:" ;;
        "get_gemini_key") echo "📋 Para obtener tu API key de Gemini:" ;;
        "login_create_key") echo "Inicia sesión y crea una nueva API key" ;;
        "copy_key") echo "Copia la key" ;;
        "starts_with") echo "empieza con" ;;
        "enter_api_key_prompt") echo "Ingresa tu API key" ;;
        "api_key_saved") echo "✅ API key guardada correctamente" ;;
        "no_api_key") echo "❌ No se proporcionó API key" ;;
        "api_key_for") echo "💡 No se encontró API key para" ;;
        "already_configured") echo "✅ API key de" ;;
        "interactive_mode_title") echo "🎮 MODO INTERACTIVO" ;;
        "project_context_loaded") echo "📄 Contexto del proyecto cargado" ;;
        "no_project_context") echo "⚠️ No hay contexto del proyecto. Usa 'coder -contexto' para generarlo." ;;
        "error_no_response") echo "❌ Error: No se pudo obtener una respuesta del servidor." ;;
        "check_connection") echo "💡 Verifica tu conexión a internet y tu API key." ;;
        "no_credits") echo "🔥 Parece que no tienes créditos suficientes en tu cuenta." ;;
        "verify_api_key") echo "🔑 Verifica que tu API key sea válida." ;;
        "history_cleaned") echo "🧹 Historial de conversaciones limpiado" ;;
        "no_history") echo "📭 No se encontró historial de conversaciones" ;;
        "available_histories") echo "📚 Historiales de conversación disponibles:" ;;
        "select_history") echo "Selecciona un historial para ver (o 'q' para salir):" ;;
        "invalid_selection") echo "❌ Selección inválida" ;;
        "api_key_hidden") echo "🔒 Por seguridad, la API key no se mostrará mientras escribes" ;;
        "react_detected") echo "🔍 Proyecto React detectado automáticamente" ;;
        "vue_detected") echo "🔍 Proyecto Vue.js detectado automáticamente" ;;
        "angular_detected") echo "🔍 Proyecto Angular detectado automáticamente" ;;
        "express_detected") echo "🔍 Proyecto Express.js detectado automáticamente" ;;
        "node_detected") echo "🔍 Proyecto Node.js detectado automáticamente" ;;
        "rails_detected") echo "🔍 Proyecto Ruby on Rails detectado automáticamente" ;;
        "laravel_detected") echo "🔍 Proyecto Laravel detectado automáticamente" ;;
        "flask_detected") echo "🔍 Proyecto Flask detectado automáticamente" ;;
        "django_detected") echo "🔍 Proyecto Django detectado automáticamente" ;;
        "spring_detected") echo "🔍 Proyecto Spring Boot detectado automáticamente" ;;
        "flutter_detected") echo "🔍 Proyecto Flutter detectado automáticamente" ;;
        "error_write_dir") echo "❌ Error: No se puede escribir en el directorio" ;;
        "error_generate_guide") echo "❌ Error al generar la guía del proyecto." ;;
        "validating_api_config") echo "🔍 Validando configuración de API..." ;;
        "unknown_error") echo "Error desconocido" ;;
        "config_error") echo "❌ Error de Configuración" ;;
        "test_error") echo "❌ Error en la prueba" ;;
        *) echo "$key" ;;
    esac
}

# Función para escribir logs
log() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" >> "$LOG_FILE" 2>/dev/null || true
    if $DEBUG; then
        echo "LOG: $1"
    fi
}

# Función para actualizar un valor en el archivo de configuración
update_config_value() {
    local key="$1"
    local value="$2"
    
    # Crear archivo de configuración si no existe
    touch "$CONFIG_FILE"
    
    # Si la clave ya existe, actualizarla; si no, agregarla
    if grep -q "^${key}=" "$CONFIG_FILE"; then
        # Usar sed para actualizar la línea existente (compatible con macOS)
        sed -i '' "s|^${key}=.*|${key}='${value}'|" "$CONFIG_FILE"
    else
        # Agregar nueva línea
        echo "${key}='${value}'" >> "$CONFIG_FILE"
    fi
    
    chmod 600 "$CONFIG_FILE"
}

# Función para obtener un valor del archivo de configuración
get_config_value() {
    local key="$1"
    if [ -f "$CONFIG_FILE" ]; then
        grep "^${key}=" "$CONFIG_FILE" | cut -d"'" -f2
    fi
}

# Función para verificar si la configuración actual es válida
is_config_valid() {
    if [ ! -f "$CONFIG_FILE" ]; then
        return 1
    fi
    
    source "$CONFIG_FILE" 2>/dev/null || return 1
    
    # Verificar que hay un LLM seleccionado
    if [ -z "$llm_choice" ]; then
        return 1
    fi
    
    # Verificar que la API key correspondiente existe
    case "$llm_choice" in
        "chatgpt")
            [ -n "$chatgpt_api_key" ] || return 1
            ;;
        "claude")
            [ -n "$claude_api_key" ] || return 1
            ;;
        "gemini")
            [ -n "$gemini_api_key" ] || return 1
            ;;
        *)
            return 1
            ;;
    esac
    
    # Verificar que hay un modelo configurado
    if [ -z "$model" ]; then
        return 1
    fi
    
    return 0
}

# Función para obtener configuración de API
get_api_config() {
    # Si la configuración es válida, solo cargarla
    if is_config_valid; then
        source "$CONFIG_FILE"
        return 0
    fi
    
    # Si no es válida, proceder con la configuración
    if [ -f "$CONFIG_FILE" ]; then
        source "$CONFIG_FILE"
    fi

    if [ -z "$llm_choice" ] || { [ -z "$chatgpt_api_key" ] && [ -z "$claude_api_key" ] && [ -z "$gemini_api_key" ]; }; then
        update_llm_choice
    fi

    if [ "$llm_choice" == "chatgpt" ] && [ -z "$chatgpt_api_key" ]; then
        update_api_token
    elif [ "$llm_choice" == "claude" ] && [ -z "$claude_api_key" ]; then
        update_api_token
    elif [ "$llm_choice" == "gemini" ] && [ -z "$gemini_api_key" ]; then
        update_api_token
    fi

    if [ -z "$model" ]; then
        update_model
    fi
}

# Función para mostrar el estado completo de configuración
mostrar_estado_configuracion() {
    local CYAN='\033[0;36m'
    local GREEN='\033[0;32m'
    local RED='\033[0;31m'
    local YELLOW='\033[1;33m'
    local BOLD='\033[1m'
    local DIM='\033[2m'
    local NC='\033[0m'
    
    clear
    echo -e "${CYAN}${BOLD}⚙️  CONFIGURACIÓN DE ASIS-CODER${NC}"
    echo -e "${DIM}════════════════════════════════════════════════════════════════${NC}"
    echo ""
    
    if [ -f "$CONFIG_FILE" ]; then
        source "$CONFIG_FILE" 2>/dev/null || true
        
        echo -e "${YELLOW}${BOLD}🤖 Configuración de LLMs:${NC}"
        echo -e "${DIM}────────────────────────────────────────────────────────────────${NC}"
        
        # ChatGPT
        if [ -n "$chatgpt_api_key" ]; then
            echo -e "   ${GREEN}✓${NC} ChatGPT: API configurada"
            if [ "$llm_choice" == "chatgpt" ]; then
                echo -e "     ${BOLD}→ ACTIVO${NC} (Modelo: ${model:-gpt-4o-mini})"
            fi
        else
            echo -e "   ${RED}✗${NC} ChatGPT: No configurado"
        fi
        
        # Claude
        if [ -n "$claude_api_key" ]; then
            echo -e "   ${GREEN}✓${NC} Claude: API configurada"
            if [ "$llm_choice" == "claude" ]; then
                echo -e "     ${BOLD}→ ACTIVO${NC} (Modelo: ${model:-claude-3-5-sonnet-20241022})"
            fi
        else
            echo -e "   ${RED}✗${NC} Claude: No configurado"
        fi
        
        # Gemini
        if [ -n "$gemini_api_key" ]; then
            echo -e "   ${GREEN}✓${NC} Gemini: API configurada"
            if [ "$llm_choice" == "gemini" ]; then
                echo -e "     ${BOLD}→ ACTIVO${NC} (Modelo: ${model:-gemini-2.5-flash})"
            fi
        else
            echo -e "   ${RED}✗${NC} Gemini: No configurado"
        fi
        
        echo ""
        echo -e "${YELLOW}${BOLD}📋 Opciones disponibles:${NC}"
        echo -e "${DIM}────────────────────────────────────────────────────────────────${NC}"
        echo -e "   ${CYAN}1.${NC} Cambiar LLM activo"
        echo -e "   ${CYAN}2.${NC} Configurar nueva API key"
        echo -e "   ${CYAN}3.${NC} Cambiar modelo"
        echo -e "   ${CYAN}4.${NC} Probar configuración"
        echo -e "   ${CYAN}5.${NC} Salir"
        
        echo ""
        read -p "$(echo -e "${YELLOW}Selecciona una opción (1-5): ${NC}")" config_option
        
        case $config_option in
            1)
                update_llm_choice
                ;;
            2)
                get_api_config
                update_api_token
                ;;
            3)
                get_api_config
                update_model
                ;;
            4)
                source "$CONFIG_DIR/../lib/api_validation.sh"
                probar_configuracion_api
                ;;
            5)
                echo "Saliendo de la configuración."
                ;;
            *)
                echo "Opción no válida."
                ;;
        esac
    else
        echo -e "${RED}❌ No se encontró archivo de configuración${NC}"
        echo -e "${YELLOW}💡 Ejecuta: ${CYAN}coder setup${NC} para configurar inicial"
    fi
}

# Función para verificar dependencias del sistema
check_dependencies() {
    local missing_deps=()
    
    # Verificar dependencias requeridas
    for cmd in curl jq file; do
        if ! command -v "$cmd" >/dev/null 2>&1; then
            missing_deps+=("$cmd")
        fi
    done
    
    if [ ${#missing_deps[@]} -ne 0 ]; then
        echo "❌ Dependencias faltantes: ${missing_deps[*]}"
        echo "💡 Instala las dependencias faltantes antes de continuar."
        return 1
    fi
    
    return 0
}

# Función para configurar el entorno
setup_environment() {
    init_config_directories
    
    # Verificar si el binario está en el PATH
    if ! echo "$PATH" | grep -q "$BIN_DIR"; then
        echo "export PATH=\"\$PATH:$BIN_DIR\"" >> "$HOME/.bashrc"
        echo "export PATH=\"\$PATH:$BIN_DIR\"" >> "$HOME/.zshrc" 2>/dev/null || true
        echo "💡 Se agregó $BIN_DIR al PATH. Reinicia tu terminal o ejecuta: source ~/.bashrc"
    fi
}

# Función de limpieza
cleanup() {
    # Limpiar archivos temporales
    rm -f /tmp/chatgpt_validation_*
    rm -f /tmp/claude_validation_*
    rm -f /tmp/gemini_validation_*
    rm -f /tmp/coder_temp_*
} 