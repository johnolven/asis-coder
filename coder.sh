#!/bin/bash

# ==========================================
# ASIS-CODER - SCRIPT PRINCIPAL MODULAR
# ==========================================
# Asistente de desarrollo con IA - Versión Modular
# Autor: Tu Nombre
# Versión: 1.0.1

# Variables iniciales
DEBUG=false

# Obtener el directorio del script (resolviendo enlaces simbólicos y npm)
SCRIPT_PATH="${BASH_SOURCE[0]}"

# Resolver enlace simbólico si existe
if [ -L "$SCRIPT_PATH" ]; then
    SCRIPT_PATH="$(readlink "$SCRIPT_PATH")"
fi

# Obtener directorio del script
SCRIPT_DIR="$(cd "$(dirname "$SCRIPT_PATH")" && pwd)"

# Buscar el directorio lib (para instalación local, npm global y npx)
if [ -d "$SCRIPT_DIR/lib" ]; then
    # Instalación local o git clone
    LIB_DIR="$SCRIPT_DIR/lib"
else
    # Para npx e instalaciones npm, buscar en múltiples ubicaciones
    POSSIBLE_PATHS=(
        "$(npm root -g 2>/dev/null)/@johnolven/asis-coder/lib"
        "$(npm root 2>/dev/null)/@johnolven/asis-coder/lib"
        "$HOME/.npm/_npx/*/node_modules/@johnolven/asis-coder/lib"
        "/tmp/_npx/*/node_modules/@johnolven/asis-coder/lib"
        "$SCRIPT_DIR/../lib"
        "$(dirname "$SCRIPT_DIR")/lib"
    )
    
    LIB_DIR=""
    for path in "${POSSIBLE_PATHS[@]}"; do
        # Expandir wildcards si existen
        if [[ "$path" == *"*"* ]]; then
            for expanded_path in $path; do
                if [ -d "$expanded_path" ]; then
                    LIB_DIR="$expanded_path"
                    break 2
                fi
            done
        elif [ -d "$path" ]; then
            LIB_DIR="$path"
            break
        fi
    done
    
    # Si no se encontró, usar directorio por defecto
    if [ -z "$LIB_DIR" ]; then
        LIB_DIR="$SCRIPT_DIR/lib"
    fi
fi

# Verificar que el directorio lib existe
if [ ! -d "$LIB_DIR" ]; then
    echo "❌ Error: No se encontró el directorio lib en $LIB_DIR"
    echo "💡 Asegúrate de que todos los módulos estén en la carpeta lib/"
    exit 1
fi

# Importar todos los módulos
if $DEBUG; then
    echo "🔄 Cargando módulos..."
fi

# Módulo de configuración (debe ser el primero)
if [ -f "$LIB_DIR/config.sh" ]; then
    source "$LIB_DIR/config.sh"
    if $DEBUG; then echo "✅ Módulo de configuración cargado"; fi
else
    echo "❌ Error: No se encontró config.sh en $LIB_DIR"
    exit 1
fi

# Pasar información de npx al módulo de configuración
export ASIS_SCRIPT_PATH="$SCRIPT_PATH"

# Inicializar directorios de configuración
init_config_directories

# Módulo de validación de APIs
if [ -f "$LIB_DIR/api_validation.sh" ]; then
    source "$LIB_DIR/api_validation.sh"
    if $DEBUG; then echo "✅ Módulo de validación de APIs cargado"; fi
else
    echo "❌ Error: No se encontró api_validation.sh en $LIB_DIR"
    exit 1
fi

# Módulo de gestión de LLMs
if [ -f "$LIB_DIR/llm_models.sh" ]; then
    source "$LIB_DIR/llm_models.sh"
    if $DEBUG; then echo "✅ Módulo de gestión de LLMs cargado"; fi
else
    echo "❌ Error: No se encontró llm_models.sh en $LIB_DIR"
    exit 1
fi

# Módulo de gestión de proyectos
if [ -f "$LIB_DIR/project_manager.sh" ]; then
    source "$LIB_DIR/project_manager.sh"
    if $DEBUG; then echo "✅ Módulo de gestión de proyectos cargado"; fi
else
    echo "❌ Error: No se encontró project_manager.sh en $LIB_DIR"
    exit 1
fi

# Módulo de interfaz de usuario
if [ -f "$LIB_DIR/ui_interface.sh" ]; then
    source "$LIB_DIR/ui_interface.sh"
    if $DEBUG; then echo "✅ Módulo de interfaz de usuario cargado"; fi
else
    echo "❌ Error: No se encontró ui_interface.sh en $LIB_DIR"
    exit 1
fi

# Módulo de comunicación con LLMs
if [ -f "$LIB_DIR/llm_communication.sh" ]; then
    source "$LIB_DIR/llm_communication.sh"
    if $DEBUG; then echo "✅ Módulo de comunicación con LLMs cargado"; fi
else
    echo "❌ Error: No se encontró llm_communication.sh en $LIB_DIR"
    exit 1
fi

if $DEBUG; then
    echo "🎉 Todos los módulos cargados exitosamente"
    echo ""
fi

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
            force_update_api_token
            ;;
        "-config"|"config")
            mostrar_estado_configuracion
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
        "/init")
            inicializar_proyecto
            ;;
        "-setup"|"setup")
            configuracion_inicial_completa
            ;;
        "historial")
            mostrar_historiales
            ;;
        "-test"|"test")
            probar_configuracion_api
            ;;
        "-lang"|"--lang"|"-language"|"--language")
            # Cargar idioma primero
            load_language
            select_language
            ;;
        "")
            # Verificar si es primera vez (no hay idioma configurado)
            if [ ! -f "$LANG_FILE" ]; then
                select_language
            fi
            validar_y_mostrar_ui
            ;;
        *)
            consultar_llm "$*"
            ;;
    esac
}

# Configurar trap para limpieza
trap cleanup EXIT

# Ejecutar función principal con todos los argumentos
main "$@" 