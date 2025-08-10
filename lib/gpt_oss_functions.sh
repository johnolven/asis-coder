# =======================================================
# FUNCIONES COMPLEMENTARIAS PARA GPT-OSS-20B
# =======================================================

# Función para mostrar UI de descarga de gpt-oss-20b
show_gpt_oss_download_ui() {
    local CYAN='\033[0;36m'
    local GREEN='\033[0;32m'
    local YELLOW='\033[1;33m'
    local PURPLE='\033[0;35m'
    local BLUE='\033[0;34m'
    local BOLD='\033[1m'
    local DIM='\033[2m'
    local NC='\033[0m'
    
    clear
    echo -e "${CYAN}${BOLD}🌟 DESCARGA DE GPT-OSS-20B${NC}"
    echo -e "${YELLOW}═══════════════════════════════════════════════════════════════${NC}"
    echo ""
    echo -e "${GREEN}📋 Información del Modelo:${NC}"
    echo -e "   ${CYAN}•${NC} ${BOLD}Nombre:${NC} gpt-oss-20b"
    echo -e "   ${CYAN}•${NC} ${BOLD}Tamaño:${NC} 21B parámetros (3.6B activos)"
    echo -e "   ${CYAN}•${NC} ${BOLD}Licencia:${NC} Apache 2.0 (Código Abierto)"
    echo -e "   ${CYAN}•${NC} ${BOLD}Características:${NC} Razonamiento avanzado, Capacidades agenticas"
    echo -e "   ${CYAN}•${NC} ${BOLD}Memoria requerida:${NC} ~16GB RAM"
    echo ""
    
    echo -e "${BLUE}${BOLD}🛠️ Métodos de Descarga Disponibles:${NC}"
    echo -e "${DIM}───────────────────────────────────────────────────────────────${NC}"
    echo ""
    
    # Verificar qué herramientas están disponibles
    local ollama_available=false
    local hf_cli_available=false
    local lm_studio_available=false
    local option_count=0
    
    if command -v ollama >/dev/null 2>&1; then
        ollama_available=true
        option_count=$((option_count + 1))
        echo -e "${GREEN}${option_count}. ${BOLD}Ollama${NC} ${DIM}(Recomendado)${NC}"
        echo -e "   ${CYAN}•${NC} Fácil de usar, optimizado para consumidores"
        echo -e "   ${CYAN}•${NC} Gestión automática de memoria"
        echo -e "   ${CYAN}•${NC} Comando: ${YELLOW}ollama pull gpt-oss:20b${NC}"
        echo ""
    fi
    
    if command -v huggingface-cli >/dev/null 2>&1; then
        hf_cli_available=true
        option_count=$((option_count + 1))
        echo -e "${PURPLE}${option_count}. ${BOLD}Hugging Face CLI${NC} ${DIM}(Desarrolladores)${NC}"
        echo -e "   ${CYAN}•${NC} Acceso directo a modelos HF"
        echo -e "   ${CYAN}•${NC} Más control sobre la descarga"
        echo -e "   ${CYAN}•${NC} Comando: ${YELLOW}huggingface-cli download openai/gpt-oss-20b${NC}"
        echo ""
    fi
    
    # LM Studio (verificar si existe)
    if command -v lms >/dev/null 2>&1; then
        lm_studio_available=true
        option_count=$((option_count + 1))
        echo -e "${BLUE}${option_count}. ${BOLD}LM Studio${NC} ${DIM}(Interfaz Gráfica)${NC}"
        echo -e "   ${CYAN}•${NC} Interfaz gráfica amigable"
        echo -e "   ${CYAN}•${NC} Gestión visual de modelos"
        echo -e "   ${CYAN}•${NC} Comando: ${YELLOW}lms get openai/gpt-oss-20b${NC}"
        echo ""
    fi
    
    # Opción de instalación manual
    option_count=$((option_count + 1))
    echo -e "${YELLOW}${option_count}. ${BOLD}Instalación Manual${NC} ${DIM}(Avanzado)${NC}"
    echo -e "   ${CYAN}•${NC} Descarga directa desde Hugging Face"
    echo -e "   ${CYAN}•${NC} Control total del proceso"
    echo -e "   ${CYAN}•${NC} Requiere configuración adicional"
    echo ""
    
    option_count=$((option_count + 1))
    echo -e "${DIM}${option_count}. Cancelar${NC}"
    echo ""
    
    echo -e "${YELLOW}⚠️ Notas Importantes:${NC}"
    echo -e "   ${CYAN}•${NC} El modelo requiere aproximadamente ${BOLD}12-16GB${NC} de espacio en disco"
    echo -e "   ${CYAN}•${NC} La descarga puede tomar ${BOLD}10-30 minutos${NC} dependiendo de tu conexión"
    echo -e "   ${CYAN}•${NC} Se recomienda una conexión estable para evitar interrupciones"
    echo ""
    echo -e "${DIM}═══════════════════════════════════════════════════════════════${NC}"
    
    while true; do
        read -p "$(echo -e "${CYAN}Selecciona el método de descarga (1-$option_count): ${NC}")" download_choice
        
        case $download_choice in
            1)
                if $ollama_available; then
                    download_gpt_oss_ollama
                    return $?
                elif $hf_cli_available; then
                    download_gpt_oss_hf_cli
                    return $?
                elif $lm_studio_available; then
                    download_gpt_oss_lm_studio
                    return $?
                else
                    download_gpt_oss_manual
                    return $?
                fi
                ;;
            2)
                if $ollama_available && $hf_cli_available; then
                    download_gpt_oss_hf_cli
                    return $?
                elif $ollama_available && $lm_studio_available; then
                    download_gpt_oss_lm_studio
                    return $?
                elif $hf_cli_available; then
                    download_gpt_oss_manual
                    return $?
                else
                    download_gpt_oss_manual
                    return $?
                fi
                ;;
            3)
                if $ollama_available && $hf_cli_available && $lm_studio_available; then
                    download_gpt_oss_lm_studio
                    return $?
                elif ($ollama_available && $hf_cli_available) || ($ollama_available && $lm_studio_available) || ($hf_cli_available && $lm_studio_available); then
                    download_gpt_oss_manual
                    return $?
                else
                    echo -e "${YELLOW}⏹️ Descarga cancelada${NC}"
                    return 1
                fi
                ;;
            4)
                if $ollama_available && $hf_cli_available && $lm_studio_available; then
                    download_gpt_oss_manual
                    return $?
                else
                    echo -e "${YELLOW}⏹️ Descarga cancelada${NC}"
                    return 1
                fi
                ;;
            5)
                echo -e "${YELLOW}⏹️ Descarga cancelada${NC}"
                return 1
                ;;
            *)
                echo -e "${YELLOW}❌ Opción no válida. Selecciona entre 1-$option_count${NC}"
                ;;
        esac
    done
}

# Función para descargar con Ollama
download_gpt_oss_ollama() {
    local GREEN='\033[0;32m'
    local CYAN='\033[0;36m'
    local YELLOW='\033[1;33m'
    local RED='\033[0;31m'
    local BOLD='\033[1m'
    local NC='\033[0m'
    
    echo -e "${CYAN}${BOLD}🐋 Descargando gpt-oss-20b con Ollama...${NC}"
    echo -e "${YELLOW}───────────────────────────────────────────────────────────${NC}"
    echo ""
    
    echo -e "${CYAN}📥 Iniciando descarga...${NC}"
    echo -e "${YELLOW}💡 Esto puede tomar varios minutos. Por favor espera...${NC}"
    echo ""
    
    # Ejecutar ollama pull con feedback visual
    if ollama pull gpt-oss:20b; then
        echo ""
        echo -e "${GREEN}✅ gpt-oss-20b descargado exitosamente con Ollama${NC}"
        echo -e "${CYAN}🚀 Puedes usar el modelo con: ${YELLOW}ollama run gpt-oss:20b${NC}"
        return 0
    else
        echo ""
        echo -e "${RED}❌ Error durante la descarga con Ollama${NC}"
        echo -e "${YELLOW}💡 Verifica tu conexión a internet e intenta nuevamente${NC}"
        return 1
    fi
}

# Función para descargar con Hugging Face CLI
download_gpt_oss_hf_cli() {
    local GREEN='\033[0;32m'
    local CYAN='\033[0;36m'
    local YELLOW='\033[1;33m'
    local RED='\033[0;31m'
    local BOLD='\033[1m'
    local NC='\033[0m'
    
    echo -e "${CYAN}${BOLD}🤗 Descargando gpt-oss-20b con Hugging Face CLI...${NC}"
    echo -e "${YELLOW}─────────────────────────────────────────────────────────────${NC}"
    echo ""
    
    echo -e "${CYAN}📥 Iniciando descarga desde Hugging Face...${NC}"
    echo -e "${YELLOW}💡 Descargando archivos del modelo...${NC}"
    echo ""
    
    # Crear directorio local para el modelo
    local model_dir="$HOME/.local/share/asis-coder/models/gpt-oss-20b"
    mkdir -p "$model_dir"
    
    # Ejecutar descarga
    if huggingface-cli download openai/gpt-oss-20b --include "original/*" --local-dir "$model_dir"; then
        echo ""
        echo -e "${GREEN}✅ gpt-oss-20b descargado exitosamente${NC}"
        echo -e "${CYAN}📍 Ubicación: ${YELLOW}$model_dir${NC}"
        return 0
    else
        echo ""
        echo -e "${RED}❌ Error durante la descarga${NC}"
        echo -e "${YELLOW}💡 Verifica tu conexión e intenta nuevamente${NC}"
        return 1
    fi
}

# Función para descargar con LM Studio
download_gpt_oss_lm_studio() {
    local GREEN='\033[0;32m'
    local CYAN='\033[0;36m'
    local YELLOW='\033[1;33m'
    local RED='\033[0;31m'
    local BOLD='\033[1m'
    local NC='\033[0m'
    
    echo -e "${CYAN}${BOLD}🎨 Descargando gpt-oss-20b con LM Studio...${NC}"
    echo -e "${YELLOW}────────────────────────────────────────────────────────────${NC}"
    echo ""
    
    echo -e "${CYAN}📥 Iniciando descarga con LM Studio...${NC}"
    echo ""
    
    if lms get openai/gpt-oss-20b; then
        echo ""
        echo -e "${GREEN}✅ gpt-oss-20b descargado exitosamente con LM Studio${NC}"
        echo -e "${CYAN}💡 Puedes gestionar el modelo desde la interfaz de LM Studio${NC}"
        return 0
    else
        echo ""
        echo -e "${RED}❌ Error durante la descarga con LM Studio${NC}"
        return 1
    fi
}

# Función para instalación manual
download_gpt_oss_manual() {
    local GREEN='\033[0;32m'
    local CYAN='\033[0;36m'
    local YELLOW='\033[1;33m'
    local RED='\033[0;31m'
    local BLUE='\033[0;34m'
    local BOLD='\033[1m'
    local NC='\033[0m'
    
    echo -e "${BLUE}${BOLD}⚙️ Instalación Manual de gpt-oss-20b${NC}"
    echo -e "${YELLOW}═══════════════════════════════════════════════════════════${NC}"
    echo ""
    
    echo -e "${YELLOW}📋 Instrucciones para instalación manual:${NC}"
    echo ""
    echo -e "${CYAN}${BOLD}Opción 1: Instalar Ollama (Recomendado)${NC}"
    echo -e "   ${CYAN}1.${NC} Visita: ${YELLOW}https://ollama.com${NC}"
    echo -e "   ${CYAN}2.${NC} Descarga e instala Ollama para tu sistema"
    echo -e "   ${CYAN}3.${NC} Ejecuta: ${YELLOW}ollama pull gpt-oss:20b${NC}"
    echo ""
    
    echo -e "${CYAN}${BOLD}Opción 2: Instalar Hugging Face CLI${NC}"
    echo -e "   ${CYAN}1.${NC} Instala: ${YELLOW}pip install huggingface_hub[cli]${NC}"
    echo -e "   ${CYAN}2.${NC} Ejecuta: ${YELLOW}huggingface-cli download openai/gpt-oss-20b${NC}"
    echo ""
    
    echo -e "${CYAN}${BOLD}Opción 3: Usar con Transformers${NC}"
    echo -e "   ${CYAN}1.${NC} Instala: ${YELLOW}pip install transformers torch${NC}"
    echo -e "   ${CYAN}2.${NC} Usa en Python:"
    echo -e "      ${YELLOW}from transformers import pipeline${NC}"
    echo -e "      ${YELLOW}pipe = pipeline('text-generation', 'openai/gpt-oss-20b')${NC}"
    echo ""
    
    echo -e "${GREEN}💡 Después de instalar, ejecuta nuevamente:${NC}"
    echo -e "   ${YELLOW}coder -model${NC}"
    echo ""
    
    read -p "$(echo -e "${CYAN}¿Quieres abrir la documentación oficial? (y/n): ${NC}")" open_docs
    
    if [[ "$open_docs" =~ ^[Yy]$ ]]; then
        if command -v open >/dev/null 2>&1; then
            open "https://huggingface.co/openai/gpt-oss-20b"
        elif command -v xdg-open >/dev/null 2>&1; then
            xdg-open "https://huggingface.co/openai/gpt-oss-20b"
        else
            echo -e "${CYAN}📖 Documentación: ${YELLOW}https://huggingface.co/openai/gpt-oss-20b${NC}"
        fi
    fi
    
    return 1  # Manual installation requires user action
}
