#!/bin/bash

# ==========================================
# ASIS-CODER - SCRIPT PRINCIPAL MODULAR
# ==========================================
# Asistente de desarrollo con IA - Versión Modular
# Autor: Tu Nombre
# Versión: 1.0.1

# Obtener el directorio del script (resolviendo enlaces simbólicos)
SCRIPT_PATH="${BASH_SOURCE[0]}"
# Resolver enlace simbólico si existe
if [ -L "$SCRIPT_PATH" ]; then
    SCRIPT_PATH="$(readlink "$SCRIPT_PATH")"
fi
SCRIPT_DIR="$(cd "$(dirname "$SCRIPT_PATH")" && pwd)"
LIB_DIR="$SCRIPT_DIR/lib"

# Verificar que el directorio lib existe
if [ ! -d "$LIB_DIR" ]; then
    echo "❌ Error: No se encontró el directorio lib en $LIB_DIR"
    echo "💡 Asegúrate de que todos los módulos estén en la carpeta lib/"
    exit 1
fi

# Importar todos los módulos
echo "🔄 Cargando módulos..."

# Módulo de configuración (debe ser el primero)
if [ -f "$LIB_DIR/config.sh" ]; then
    source "$LIB_DIR/config.sh"
    echo "✅ Módulo de configuración cargado"
else
    echo "❌ Error: No se encontró config.sh"
    exit 1
fi

# Inicializar directorios de configuración
init_config_directories

# Módulo de validación de APIs
if [ -f "$LIB_DIR/api_validation.sh" ]; then
    source "$LIB_DIR/api_validation.sh"
    echo "✅ Módulo de validación de APIs cargado"
else
    echo "❌ Error: No se encontró api_validation.sh"
    exit 1
fi

# Módulo de gestión de LLMs
if [ -f "$LIB_DIR/llm_models.sh" ]; then
    source "$LIB_DIR/llm_models.sh"
    echo "✅ Módulo de gestión de LLMs cargado"
else
    echo "❌ Error: No se encontró llm_models.sh"
    exit 1
fi

# Módulo de gestión de proyectos
if [ -f "$LIB_DIR/project_manager.sh" ]; then
    source "$LIB_DIR/project_manager.sh"
    echo "✅ Módulo de gestión de proyectos cargado"
else
    echo "❌ Error: No se encontró project_manager.sh"
    exit 1
fi

# Módulo de interfaz de usuario
if [ -f "$LIB_DIR/ui_interface.sh" ]; then
    source "$LIB_DIR/ui_interface.sh"
    echo "✅ Módulo de interfaz de usuario cargado"
else
    echo "❌ Error: No se encontró ui_interface.sh"
    exit 1
fi

# Módulo de comunicación con LLMs
if [ -f "$LIB_DIR/llm_communication.sh" ]; then
    source "$LIB_DIR/llm_communication.sh"
    echo "✅ Módulo de comunicación con LLMs cargado"
else
    echo "❌ Error: No se encontró llm_communication.sh"
    exit 1
fi

echo "🎉 Todos los módulos cargados exitosamente"
echo ""

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
        "")
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