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
        "api_key_hidden") echo "🔒 For security, the API key will not be displayed while typing" ;;
        "api_key_valid") echo "✅ Valid API key!" ;;
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
        "lines") echo "lines" ;;
        "creating_new_milestone") echo "📝 Creating new conversation milestone" ;;
        "next_conversation_new_milestone") echo "✅ Next conversation will be a new milestone" ;;
        "you") echo "You" ;;
        "assistant") echo "Assistant" ;;
        "thinking") echo "Thinking" ;;
        "exiting_interactive") echo "👋 Exiting interactive mode." ;;
        "project_type_not_detected_manual") echo "❓ Could not automatically detect project type." ;;
        "select_project_type") echo "Select project type:" ;;
        "other") echo "Other" ;;
        "enter_project_type_number") echo "Enter the project type number" ;;
        "invalid_option_selecting_other") echo "⚠️ Invalid option. Selecting 'Other' by default." ;;
        "generating_project_context") echo "Generating project context" ;;
        "project_directory") echo "Project directory" ;;
        "directories_to_analyze") echo "Directories to analyze" ;;
        "output_file") echo "Output file" ;;
        "warning_no_files_found") echo "⚠️ Warning: No files found to process" ;;
        "context_file_generated_successfully") echo "✅ Context file generated successfully" ;;
        "location") echo "Location" ;;
        "initializing_project_with_asis") echo "🚀 Initializing project with Asis-coder" ;;
        "creating_project_guide") echo "📋 Creating project guide" ;;
        "project_initialized_correctly") echo "✅ Project initialized correctly" ;;
        "suggestion_git_commit") echo "💡 Suggestion: Run 'git add CODER.md && git commit -m \"Add Coder project guide\"'" ;;
        "generating_project_guide") echo "Generating project guide" ;;
        "coder_md_file_created") echo "✅ CODER.md file created with project guide" ;;
        "context_file_not_found") echo "❌ Context file not found. Run 'coder -context' first" ;;
        "chatgpt_models_available") echo "🤖 AVAILABLE CHATGPT MODELS" ;;
        "classic_models") echo "📊 Classic Models" ;;
        "classic_fast_economic") echo "Classic, fast and economic" ;;
        "gpt4_base_model") echo "GPT-4 base model" ;;
        "price_performance_balance") echo "Price/performance balance" ;;
        "omni_models") echo "🚀 Omni Models" ;;
        "multimodal") echo "Multimodal" ;;
        "omni_multimodal_powerful") echo "Omni - Powerful multimodal" ;;
        "economic_and_fast") echo "Economic and fast" ;;
        "reasoning_models") echo "🧠 Reasoning Models" ;;
        "advanced_reasoning") echo "Advanced reasoning" ;;
        "fast_reasoning") echo "Fast reasoning" ;;
        "reasoning_preview") echo "Reasoning preview" ;;
        "new_reasoning_model") echo "New reasoning model" ;;
        "latest_compact_model") echo "Latest compact model" ;;
        "new_generation") echo "🆕 New Generation" ;;
        "new_generation_model") echo "New generation" ;;
        "compact_new_generation") echo "Compact new generation" ;;
        "ultra_compact") echo "Ultra compact" ;;
        "most_advanced_model") echo "Most advanced model" ;;
        "open_source_models") echo "🌟 Open Source Models" ;;
        "select_model_number") echo "Select the model number" ;;
        "invalid_option_default_gpt4o_mini") echo "⚠️ Invalid option. Selecting gpt-4o-mini by default." ;;
        "claude_models_available") echo "🎭 AVAILABLE CLAUDE MODELS" ;;
        "claude_4_latest_generation") echo "👑 Claude 4 (Latest Generation)" ;;
        "claude_4_most_powerful") echo "Claude 4 - Most powerful and intelligent" ;;
        "claude_4_high_performance") echo "Claude 4 - High performance" ;;
        "claude_37_extended_thinking") echo "🧠 Claude 3.7 (Extended Thinking)" ;;
        "claude_37_extended_thinking_desc") echo "Claude 3.7 - Extended thinking" ;;
        "claude_35_perfect_balance") echo "⚡ Claude 3.5 (Perfect Balance)" ;;
        "claude_35_v2_most_recent") echo "Claude 3.5 v2 - Most recent" ;;
        "claude_35_v1_stable") echo "Claude 3.5 v1 - Stable" ;;
        "fast_and_economic") echo "Fast and economic" ;;
        "claude_3_legacy") echo "📚 Claude 3 Legacy" ;;
        "smartest_legacy") echo "Smartest legacy" ;;
        "ultrafast_legacy") echo "Ultrafast legacy" ;;
        "invalid_option_default_claude") echo "⚠️ Invalid option. Selecting claude-3-5-sonnet-20241022 by default." ;;
        "gemini_models_available") echo "💎 AVAILABLE GEMINI MODELS" ;;
        "gemini_25_most_recent") echo "🚀 Gemini 2.5 (Most Recent)" ;;
        "most_powerful_with_thinking") echo "Most powerful with thinking" ;;
        "best_price_performance_balance") echo "Best price/performance balance" ;;
        "ultra_economic") echo "Ultra economic" ;;
        "gemini_20") echo "⚡ Gemini 2.0" ;;
        "generation_20_standard") echo "Generation 2.0 standard" ;;
        "generation_20_economic") echo "Generation 2.0 economic" ;;
        "gemini_15_legacy") echo "📚 Gemini 1.5 Legacy" ;;
        "legacy_pro") echo "Legacy Pro" ;;
        "legacy_flash") echo "Legacy Flash" ;;
        "legacy_compact") echo "Legacy compact" ;;
        "invalid_option_default_gemini") echo "⚠️ Invalid option. Selecting gemini-2.5-flash by default." ;;
        "query_received_in_llm") echo "Query received in consultar_llm" ;;
        "getting_api_config") echo "Getting API configuration" ;;
        "coder_cli_version") echo "Coder CLI version" ;;
        "current_config") echo "Current configuration" ;;
        "request_sent_to") echo "Request sent to" ;;
        "response_received") echo "Response received" ;;
        "error_extract_content") echo "Error: Could not extract content from response" ;;
        "complete_response") echo "Complete response" ;;
        "debug_prompt_configured") echo "DEBUG: Initial prompt configured" ;;
        "debug_history_file") echo "DEBUG: History file" ;;
        "debug_complete_prompt_sent") echo "DEBUG: Complete prompt sent to LLM" ;;
        "debug_sending_request") echo "DEBUG: Sending request to LLM" ;;
        "debug_response_received") echo "DEBUG: Response received from LLM" ;;
        "debug_history_updated_saved") echo "DEBUG: History updated and saved in" ;;
        "creating_new_milestone") echo "📝 Creating new conversation milestone" ;;
        "next_conversation_new_milestone") echo "✅ Next conversation will be a new milestone" ;;
        "lines") echo "lines" ;;
        "verifying_api") echo "⏳ Verifying API of" ;;
        "chatgpt_api_valid") echo "✅ ChatGPT API is valid" ;;
        "chatgpt_insufficient_credits") echo "❌ ChatGPT: Insufficient credits" ;;
        "visit_openai_billing") echo "💡 Go to platform.openai.com/account/billing" ;;
        "chatgpt_invalid_api_key") echo "❌ ChatGPT: Invalid API key" ;;
        "verify_openai_key") echo "💡 Verify your API key at platform.openai.com" ;;
        "claude_api_valid") echo "✅ Claude API is valid" ;;
        "claude_insufficient_credits") echo "❌ Claude: Insufficient credits" ;;
        "visit_anthropic_billing") echo "💡 Go to console.anthropic.com/settings/billing" ;;
        "claude_invalid_api_key") echo "❌ Claude: Invalid API key" ;;
        "verify_anthropic_key") echo "💡 Verify your API key at console.anthropic.com" ;;
        "gemini_api_valid") echo "✅ Gemini API is valid" ;;
        "gemini_quota_exceeded") echo "❌ Gemini: Quota exceeded" ;;
        "visit_google_quota") echo "💡 Go to console.cloud.google.com/apis/api/generativelanguage.googleapis.com" ;;
        "gemini_invalid_api_key") echo "❌ Gemini: Invalid API key" ;;
        "verify_google_key") echo "💡 Verify your API key at aistudio.google.com/app/apikey" ;;
        "no_api_key_configured") echo "❌ No API key configured for" ;;
        "no_llm_configured") echo "❌ No LLM configured" ;;
        "config_file_not_found") echo "❌ Configuration file not found" ;;
        "config_required_before_continue") echo "🔧 Configuration required before continuing" ;;
        "available_options") echo "Available options:" ;;
        "configure_from_scratch") echo "Configure from scratch" ;;
        "change_llm") echo "Change LLM" ;;
        "test_apis") echo "Test APIs" ;;
        "configuration_test") echo "🧪 CONFIGURATION TEST" ;;
        "testing_llm") echo "🤖 Testing" ;;
        "with_model") echo "with model" ;;
        "default") echo "default" ;;
        "test_query") echo "Answer briefly: Are you working correctly?" ;;
        "test_query_label") echo "Test query" ;;
        "sending_query") echo "⏳ Sending query" ;;
        "test_successful") echo "✅ Test successful!" ;;
        "response") echo "Response" ;;
        "config_working_correctly") echo "🎉 Your configuration is working correctly" ;;
        "asis_coder_configuration") echo "⚙️ ASIS-CODER CONFIGURATION" ;;
        "llm_configuration") echo "🤖 LLM Configuration" ;;
        "api_configured") echo "API configured" ;;
        "active") echo "ACTIVE" ;;
        "change_active_llm") echo "Change active LLM" ;;
        "configure_new_api_key") echo "Configure new API key" ;;
        "change_model") echo "Change model" ;;
        "test_configuration") echo "Test configuration" ;;
        "exit") echo "Exit" ;;
        "select_option") echo "Select an option" ;;
        "exiting_configuration") echo "Exiting configuration" ;;
        "run_setup") echo "Run" ;;
        "for_initial_config") echo "for initial configuration" ;;
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
        "dependencies_verified") echo "Dependencias verificadas" ;;
        "missing_dependency") echo "Dependencia faltante" ;;
        "current_project") echo "📁 Proyecto Actual" ;;
        "type_detected") echo "Tipo detectado" ;;
        "project_type_not_detected") echo "Tipo de proyecto no detectado" ;;
        "context_not_generated") echo "Contexto no generado" ;;
        "configure_llm") echo "Configura tu LLM" ;;
        "initialize_project") echo "Inicializa proyecto" ;;
        "global_install_available") echo "🚀 Instalación Global Disponible" ;;
        "currently_using_npx") echo "Actualmente estás usando npx para ejecutar asis-coder." ;;
        "would_you_like_global") echo "¿Te gustaría instalarlo globalmente para usar comandos más cortos?" ;;
        "with_global_install") echo "Con instalación global podrás usar:" ;;
        "initial_configuration") echo "Configuración inicial" ;;
        "install_globally_question") echo "¿Quieres instalar asis-coder globalmente? (y/n)" ;;
        "installing_globally") echo "📦 Instalando globalmente..." ;;
        "installed_successfully") echo "✅ ¡Asis-coder instalado globalmente exitosamente!" ;;
        "now_you_can_use") echo "🎉 Ahora puedes usar comandos cortos:" ;;
        "press_enter_continue") echo "Presiona Enter para continuar con la configuración..." ;;
        "could_not_install") echo "⚠️ No se pudo instalar globalmente. Continuando con npx..." ;;
        "ok_continue_npx") echo "💡 Está bien, puedes seguir usando npx cuando quieras." ;;
        "initial_setup_title") echo "🔧 Configuración Inicial de Asis-coder" ;;
        "step_1_dependencies") echo "📋 Paso 1: Verificando dependencias..." ;;
        "step_2_llm") echo "🤖 Paso 2: Configurando LLM..." ;;
        "step_3_project") echo "📁 Paso 3: Configuración del proyecto" ;;
        "initialize_project_question") echo "¿Quieres inicializar este proyecto con Asis-coder? (y/n)" ;;
        "setup_completed") echo "🎉 ¡Configuración completada exitosamente!" ;;
        "useful_commands") echo "💡 Comandos útiles para empezar:" ;;
        "interactive_chat_mode") echo "Modo chat interactivo" ;;
        "regenerate_context") echo "Regenerar contexto del proyecto" ;;
        "change_ai_model") echo "Cambiar modelo de IA" ;;
        "project_type_not_detected_manual") echo "❓ No se pudo detectar el tipo de proyecto automáticamente." ;;
        "select_project_type") echo "Selecciona el tipo de proyecto:" ;;
        "other") echo "Otro" ;;
        "enter_project_type_number") echo "Ingresa el número del tipo de proyecto" ;;
        "invalid_option_selecting_other") echo "⚠️ Opción no válida. Seleccionando 'Otro' por defecto." ;;
        "generating_project_context") echo "Generando contexto del proyecto" ;;
        "project_directory") echo "Directorio del proyecto" ;;
        "directories_to_analyze") echo "Directorios a analizar" ;;
        "output_file") echo "Archivo de salida" ;;
        "warning_no_files_found") echo "⚠️ Advertencia: No se encontraron archivos para procesar" ;;
        "context_file_generated_successfully") echo "✅ Archivo de contexto generado exitosamente" ;;
        "location") echo "Ubicación" ;;
        "initializing_project_with_asis") echo "🚀 Inicializando proyecto con Asis-coder" ;;
        "creating_project_guide") echo "📋 Creando guía del proyecto" ;;
        "project_initialized_correctly") echo "✅ Proyecto inicializado correctamente" ;;
        "suggestion_git_commit") echo "💡 Sugerencia: Ejecuta 'git add CODER.md && git commit -m \"Add Coder project guide\"'" ;;
        "generating_project_guide") echo "Generando guía del proyecto" ;;
        "coder_md_file_created") echo "✅ Archivo CODER.md creado con la guía del proyecto" ;;
        "context_file_not_found") echo "❌ No se encontró archivo de contexto. Ejecuta 'coder -contexto' primero" ;;
        "chatgpt_models_available") echo "🤖 MODELOS DE CHATGPT DISPONIBLES" ;;
        "classic_models") echo "📊 Modelos Clásicos" ;;
        "classic_fast_economic") echo "Clásico, rápido y económico" ;;
        "gpt4_base_model") echo "Modelo base GPT-4" ;;
        "price_performance_balance") echo "Equilibrio precio/rendimiento" ;;
        "omni_models") echo "🚀 Modelos Omni" ;;
        "multimodal") echo "Multimodal" ;;
        "omni_multimodal_powerful") echo "Omni - Multimodal potente" ;;
        "economic_and_fast") echo "Económico y rápido" ;;
        "reasoning_models") echo "🧠 Modelos de Razonamiento" ;;
        "advanced_reasoning") echo "Razonamiento avanzado" ;;
        "fast_reasoning") echo "Razonamiento rápido" ;;
        "reasoning_preview") echo "Vista previa de razonamiento" ;;
        "new_reasoning_model") echo "Nuevo modelo de razonamiento" ;;
        "latest_compact_model") echo "Último modelo compacto" ;;
        "new_generation") echo "🆕 Nueva Generación" ;;
        "new_generation_model") echo "Nueva generación" ;;
        "compact_new_generation") echo "Compacto nueva generación" ;;
        "ultra_compact") echo "Ultra compacto" ;;
        "most_advanced_model") echo "Modelo más avanzado" ;;
        "open_source_models") echo "🌟 Modelos de Código Abierto" ;;
        "select_model_number") echo "Selecciona el número del modelo" ;;
        "invalid_option_default_gpt4o_mini") echo "⚠️ Opción no válida. Seleccionando gpt-4o-mini por defecto." ;;
        "claude_models_available") echo "🎭 MODELOS DE CLAUDE DISPONIBLES" ;;
        "claude_4_latest_generation") echo "👑 Claude 4 (Última Generación)" ;;
        "claude_4_most_powerful") echo "Claude 4 - Más potente e inteligente" ;;
        "claude_4_high_performance") echo "Claude 4 - Alto rendimiento" ;;
        "claude_37_extended_thinking") echo "🧠 Claude 3.7 (Pensamiento Extendido)" ;;
        "claude_37_extended_thinking_desc") echo "Claude 3.7 - Pensamiento extendido" ;;
        "claude_35_perfect_balance") echo "⚡ Claude 3.5 (Equilibrio Perfecto)" ;;
        "claude_35_v2_most_recent") echo "Claude 3.5 v2 - Más reciente" ;;
        "claude_35_v1_stable") echo "Claude 3.5 v1 - Estable" ;;
        "fast_and_economic") echo "Rápido y económico" ;;
        "claude_3_legacy") echo "📚 Claude 3 Legacy" ;;
        "smartest_legacy") echo "Más inteligente legacy" ;;
        "ultrafast_legacy") echo "Ultrarrápido legacy" ;;
        "invalid_option_default_claude") echo "⚠️ Opción no válida. Seleccionando claude-3-5-sonnet-20241022 por defecto." ;;
        "gemini_models_available") echo "💎 MODELOS DE GEMINI DISPONIBLES" ;;
        "gemini_25_most_recent") echo "🚀 Gemini 2.5 (Más Reciente)" ;;
        "most_powerful_with_thinking") echo "Más potente con pensamiento" ;;
        "best_price_performance_balance") echo "Mejor equilibrio precio/rendimiento" ;;
        "ultra_economic") echo "Ultra económico" ;;
        "gemini_20") echo "⚡ Gemini 2.0" ;;
        "generation_20_standard") echo "Generación 2.0 estándar" ;;
        "generation_20_economic") echo "Generación 2.0 económico" ;;
        "gemini_15_legacy") echo "📚 Gemini 1.5 Legacy" ;;
        "legacy_pro") echo "Legacy Pro" ;;
        "legacy_flash") echo "Legacy Flash" ;;
        "legacy_compact") echo "Legacy compacto" ;;
        "invalid_option_default_gemini") echo "⚠️ Opción no válida. Seleccionando gemini-2.5-flash por defecto." ;;
        "query_received_in_llm") echo "Consulta recibida en consultar_llm" ;;
        "getting_api_config") echo "Obteniendo configuración de API" ;;
        "coder_cli_version") echo "Coder CLI versión" ;;
        "current_config") echo "Configuración actual" ;;
        "request_sent_to") echo "Petición enviada a" ;;
        "response_received") echo "Respuesta recibida" ;;
        "error_extract_content") echo "Error: No se pudo extraer el contenido de la respuesta" ;;
        "complete_response") echo "Respuesta completa" ;;
        "debug_prompt_configured") echo "DEBUG: Prompt inicial configurado" ;;
        "debug_history_file") echo "DEBUG: Archivo de historial" ;;
        "debug_complete_prompt_sent") echo "DEBUG: Prompt completo enviado al LLM" ;;
        "debug_sending_request") echo "DEBUG: Enviando petición al LLM" ;;
        "debug_response_received") echo "DEBUG: Respuesta recibida del LLM" ;;
        "debug_history_updated_saved") echo "DEBUG: Historial actualizado y guardado en" ;;
        "creating_new_milestone") echo "📝 Creando nuevo hito de conversación" ;;
        "next_conversation_new_milestone") echo "✅ Próxima conversación será un nuevo hito" ;;
        "lines") echo "líneas" ;;
        "verifying_api") echo "⏳ Verificando API de" ;;
        "chatgpt_api_valid") echo "✅ API de ChatGPT válida" ;;
        "chatgpt_insufficient_credits") echo "❌ ChatGPT: Sin créditos suficientes" ;;
        "visit_openai_billing") echo "💡 Ve a platform.openai.com/account/billing" ;;
        "chatgpt_invalid_api_key") echo "❌ ChatGPT: API key inválida" ;;
        "verify_openai_key") echo "💡 Verifica tu API key en platform.openai.com" ;;
        "claude_api_valid") echo "✅ API de Claude válida" ;;
        "claude_insufficient_credits") echo "❌ Claude: Sin créditos suficientes" ;;
        "visit_anthropic_billing") echo "💡 Ve a console.anthropic.com/settings/billing" ;;
        "claude_invalid_api_key") echo "❌ Claude: API key inválida" ;;
        "verify_anthropic_key") echo "💡 Verifica tu API key en console.anthropic.com" ;;
        "gemini_api_valid") echo "✅ API de Gemini válida" ;;
        "gemini_quota_exceeded") echo "❌ Gemini: Cuota excedida" ;;
        "visit_google_quota") echo "💡 Ve a console.cloud.google.com/apis/api/generativelanguage.googleapis.com" ;;
        "gemini_invalid_api_key") echo "❌ Gemini: API key inválida" ;;
        "verify_google_key") echo "💡 Verifica tu API key en aistudio.google.com/app/apikey" ;;
        "no_api_key_configured") echo "❌ No hay API key configurada para" ;;
        "no_llm_configured") echo "❌ No hay LLM configurado" ;;
        "config_file_not_found") echo "❌ No se encontró archivo de configuración" ;;
        "config_required_before_continue") echo "🔧 Se requiere configuración antes de continuar" ;;
        "available_options") echo "Opciones disponibles:" ;;
        "configure_from_scratch") echo "Configurar desde cero" ;;
        "change_llm") echo "Cambiar LLM" ;;
        "test_apis") echo "Probar APIs" ;;
        "configuration_test") echo "🧪 PRUEBA DE CONFIGURACIÓN" ;;
        "testing_llm") echo "🤖 Probando" ;;
        "with_model") echo "con modelo" ;;
        "default") echo "por defecto" ;;
        "test_query") echo "Responde brevemente: ¿Estás funcionando correctamente?" ;;
        "test_query_label") echo "Consulta de prueba" ;;
        "sending_query") echo "⏳ Enviando consulta" ;;
        "test_successful") echo "✅ ¡Prueba exitosa!" ;;
        "response") echo "Respuesta" ;;
        "config_working_correctly") echo "🎉 Tu configuración está funcionando correctamente" ;;
        "asis_coder_configuration") echo "⚙️ CONFIGURACIÓN DE ASIS-CODER" ;;
        "llm_configuration") echo "🤖 Configuración de LLMs" ;;
        "api_configured") echo "API configurada" ;;
        "active") echo "ACTIVO" ;;
        "change_active_llm") echo "Cambiar LLM activo" ;;
        "configure_new_api_key") echo "Configurar nueva API key" ;;
        "change_model") echo "Cambiar modelo" ;;
        "test_configuration") echo "Probar configuración" ;;
        "exit") echo "Salir" ;;
        "select_option") echo "Selecciona una opción" ;;
        "exiting_configuration") echo "Saliendo de la configuración" ;;
        "run_setup") echo "Ejecuta" ;;
        "for_initial_config") echo "para configurar inicial" ;;
        "you") echo "Tú" ;;
        "assistant") echo "Asistente" ;;
        "thinking") echo "Pensando" ;;
        "exiting_interactive") echo "👋 Saliendo del modo interactivo." ;;
        "debug_interactive_mode_started") echo "DEBUG: Modo interactivo iniciado" ;;
        "debug_context_file") echo "DEBUG: Archivo de contexto" ;;
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
    
    # Cargar idioma
    load_language
    
    clear
    echo -e "${CYAN}${BOLD}⚙️  $(get_text "asis_coder_configuration")${NC}"
    echo -e "${DIM}════════════════════════════════════════════════════════════════${NC}"
    echo ""
    
    if [ -f "$CONFIG_FILE" ]; then
        source "$CONFIG_FILE" 2>/dev/null || true
        
        echo -e "${YELLOW}${BOLD}🤖 $(get_text "llm_configuration"):${NC}"
        echo -e "${DIM}────────────────────────────────────────────────────────────────${NC}"
        
        # ChatGPT
        if [ -n "$chatgpt_api_key" ]; then
            echo -e "   ${GREEN}✓${NC} ChatGPT: $(get_text "api_configured")"
            if [ "$llm_choice" == "chatgpt" ]; then
                echo -e "     ${BOLD}→ $(get_text "active")${NC} ($(get_text "model"): ${model:-gpt-4o-mini})"
            fi
        else
            echo -e "   ${RED}✗${NC} ChatGPT: $(get_text "not_configured")"
        fi
        
        # Claude
        if [ -n "$claude_api_key" ]; then
            echo -e "   ${GREEN}✓${NC} Claude: $(get_text "api_configured")"
            if [ "$llm_choice" == "claude" ]; then
                echo -e "     ${BOLD}→ $(get_text "active")${NC} ($(get_text "model"): ${model:-claude-3-5-sonnet-20241022})"
            fi
        else
            echo -e "   ${RED}✗${NC} Claude: $(get_text "not_configured")"
        fi
        
        # Gemini
        if [ -n "$gemini_api_key" ]; then
            echo -e "   ${GREEN}✓${NC} Gemini: $(get_text "api_configured")"
            if [ "$llm_choice" == "gemini" ]; then
                echo -e "     ${BOLD}→ $(get_text "active")${NC} ($(get_text "model"): ${model:-gemini-2.5-flash})"
            fi
        else
            echo -e "   ${RED}✗${NC} Gemini: $(get_text "not_configured")"
        fi
        
        echo ""
        echo -e "${YELLOW}${BOLD}📋 $(get_text "available_options"):${NC}"
        echo -e "${DIM}────────────────────────────────────────────────────────────────${NC}"
        echo -e "   ${CYAN}1.${NC} $(get_text "change_active_llm")"
        echo -e "   ${CYAN}2.${NC} $(get_text "configure_new_api_key")"
        echo -e "   ${CYAN}3.${NC} $(get_text "change_model")"
        echo -e "   ${CYAN}4.${NC} $(get_text "test_configuration")"
        echo -e "   ${CYAN}5.${NC} $(get_text "exit")"
        
        echo ""
        read -p "$(echo -e "${YELLOW}$(get_text "select_option") (1-5): ${NC}")" config_option
        
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
                echo "$(get_text "exiting_configuration")."
                ;;
            *)
                echo "$(get_text "invalid_option")."
                ;;
        esac
    else
        echo -e "${RED}❌ $(get_text "config_file_not_found")${NC}"
        echo -e "${YELLOW}💡 $(get_text "run_setup"): ${CYAN}coder setup${NC} $(get_text "for_initial_config")"
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